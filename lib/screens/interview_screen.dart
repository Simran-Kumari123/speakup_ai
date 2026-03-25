import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_loading_widget.dart';
import '../widgets/ai_error_widget.dart';
import '../widgets/selector_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/premium_button.dart';
import '../widgets/confidence_meter.dart';
import '../widgets/voice_wave.dart';
import 'dart:ui';
import 'resume_screen.dart';

class InterviewScreen extends StatefulWidget {
  final PracticeTopic? topic;

  const InterviewScreen({super.key, this.topic});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  late QuestionService _questionService;
  Question? _currentQuestion;
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _questionService = QuestionService();

    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    final question = _questionService.getRandomQuestion(
      type: 'interview',
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );
    setState(() {
      _currentQuestion = question;
    });
  }

  List<String> _getCategories() {
    return _questionService.getCategories(type: 'interview');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Tab Header Action
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.shuffle_rounded, size: 20),
                  label: const Text('New Question'),
                  onPressed: _generateNewQuestion,
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeScreen())),
                  icon: const Icon(Icons.description_rounded, size: 18),
                  label: const Text('Resume Prep'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                    foregroundColor: AppTheme.accent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ResponsiveContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CategorySelector(
                      categories: _getCategories(),
                      selectedCategory: _selectedCategory,
                      onChanged: (category) {
                        setState(() => _selectedCategory = category);
                        _generateNewQuestion();
                      },
                    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 16),
                    DifficultySelector(
                      selectedDifficulty: _selectedDifficulty,
                      onChanged: (difficulty) {
                        setState(() => _selectedDifficulty = difficulty);
                        _generateNewQuestion();
                      },
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideX(begin: -0.1),
                    const SizedBox(height: 24),
                    if (_currentQuestion != null)
                      SizedBox(
                        height: 480, // Height to accommodate input area
                        child: PageView.builder(
                          onPageChanged: (_) => _generateNewQuestion(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _InterviewQuestionCard(
                                  key: ValueKey('${_currentQuestion!.text}_$index'),
                                  q: _currentQuestion!,
                                  onRefresh: _generateNewQuestion
                              ),
                            );
                          },
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 500.ms).slideY(begin: 0.1)
                    else
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewQuestionCard extends StatefulWidget {
  final Question q;
  final VoidCallback onRefresh;
  const _InterviewQuestionCard({required this.q, required this.onRefresh, super.key});
  @override
  State<_InterviewQuestionCard> createState() => _InterviewQuestionCardState();
}

class _InterviewQuestionCardState extends State<_InterviewQuestionCard> {
  bool _practicing  = false;
  bool _processing  = false;
  bool _isListening = false;
  double _soundLevel = 0.0;
  bool _speechReady = false;
  String _liveVoice = '';
  String _errorMessage = '';
  Map<String, dynamic>? _result;

  final _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  @override
  void initState() {
    super.initState();
  }

  void _stopVoice({bool send = false}) async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      if (send) {
        _ctrl.text = _liveVoice;
        _submitAnswer();
      }
    });
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      // Lazy initialization of speech
      if (!_speech.isAvailable) {
        if (!kIsWeb) {
          final status = await Permission.microphone.status;
          if (!status.isGranted) {
            final result = await Permission.microphone.request();
            if (!result.isGranted) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Microphone permission denied 🎤'), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating),
                );
              }
              return;
            }
          }
        }
        bool retryAvailable = await _speech.initialize();
          if (!retryAvailable) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Speech recognition not available'), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating),
              );
            }
            return;
          }
        }
      }

      setState(() { _isListening = true; _liveVoice = ''; });
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveVoice = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) _stopVoice(send: true);
      },
      onSoundLevelChange: (level) => setState(() => _soundLevel = level),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  void _submitAnswer() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      _processing = true;
      _errorMessage = '';
    });

    try {
      final res = await AIFeedbackService.evaluateAnswer(
        question: widget.q.text,
        answer: _ctrl.text,
      );

      if (!mounted) return;

      context.read<AppState>().addXP((res['xp'] as int));
      context.read<AppState>().addSession(PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: widget.q.text,
        type: 'Interview',
        score: (res['score'] as num).toDouble(),
        xp: res['xp'] as int,
      ));

      setState(() {
        _result = res;
        _processing = false;
      });
      _showResultModal(res);
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to evaluate answer. Please try again.";
        _processing = false;
      });
    }
  }

  void _showResultModal(Map<String, dynamic> res) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color?.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('INTERVIEW FEEDBACK', style: GoogleFonts.outfit(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              ConfidenceMeter(score: (res['score'] as num).toDouble()),
              const SizedBox(height: 20),
              Text(res['feedback'] as String, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 15, height: 1.6)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('CONTINUE PREP', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.5),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _tag(widget.q.category.toUpperCase(), AppTheme.primary),
              const SizedBox(width: 8),
              _tag(widget.q.difficulty.toUpperCase(), AppTheme.accent),
              const Spacer(),
              IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.shuffle_rounded, color: AppTheme.primary, size: 22)),
            ]),
            const SizedBox(height: 20),
            Text(widget.q.text,
                style: GoogleFonts.outfit(color: Theme.of(context).textTheme.headlineMedium?.color, fontWeight: FontWeight.w700, fontSize: 20, height: 1.4)),

            const SizedBox(height: 16),

            if (widget.q.hints.isNotEmpty)
              _hintBox(widget.q.hints.first),

            const SizedBox(height: 16),

            if (!_practicing && _result == null)
              PremiumButton(
                label: 'Start Practice Session',
                icon: Icons.mic_none_rounded,
                onPressed: () => setState(() => _practicing = true),
              ),

            if (_practicing && _result == null) ...[
              if (_isListening)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: VoiceWave(soundLevel: _soundLevel, isListening: _isListening),
            ),
              TextField(
                controller: _ctrl,
                maxLines: 4,
                style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Speak or type your response...',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(_isListening ? Icons.stop_circle : Icons.mic_rounded),
                      color: _isListening ? AppTheme.danger : AppTheme.primary,
                      onPressed: _toggleListening,
                    ).animate(target: _isListening ? 1 : 0, onPlay: (c) => c.repeat(reverse: true)).scale(end: const Offset(1.2, 1.2)),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface.withValues(alpha: 0.3) : AppTheme.lightSurface,
                ),
              ),
              const SizedBox(height: 12),
              if (_processing)
                const AILoadingWidget()
              else if (_errorMessage.isNotEmpty)
                AIErrorWidget(message: _errorMessage, onRetry: _submitAnswer)
              else
                PremiumButton(
                  label: 'Analyze Interview Answer 🤖',
                  onPressed: _submitAnswer,
                  color: AppTheme.primary,
                  isLoading: _processing,
                ),
            ],

            if (_result != null)
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() { _result = null; _practicing = false; _ctrl.clear(); }),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Re-try this Question'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Text(label, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
  );

  Widget _hintBox(String hint) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.accent.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('💡 ', style: TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Expanded(child: Text(hint, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] as num).toDouble();
    final color = score >= 8 ? AppTheme.success : score >= 6 ? AppTheme.accent : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface.withValues(alpha: 0.3) : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Text('AI EVALUATION', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1)),
            ],
          ),
          Text('${score.toStringAsFixed(1)} / 10', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 24)),
        ]),
        const SizedBox(height: 24),
        _scoreRow(context, Icons.volume_up_rounded, 'Fluency', result['fluency'] as double),
        const SizedBox(height: 12),
        _scoreRow(context, Icons.ads_click_rounded, 'Relevance', result['relevance'] as double),
        const SizedBox(height: 12),
        _scoreRow(context, Icons.psychology_rounded, 'Confidence', result['confidence'] as double),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(result['feedback'] as String,
              style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14, height: 1.6)),
        ),
        const SizedBox(height: 20),
        Text('SUGGESTIONS', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...((result['suggestions'] as List).map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check_circle_outline_rounded, color: AppTheme.success, size: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(s.toString(), style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, height: 1.4))),
          ]),
        ))),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: AppTheme.accent, size: 20),
              const SizedBox(width: 10),
              Text('+${result['xp']} XP Earned', style: GoogleFonts.outfit(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ),
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }
  Widget _scoreRow(BuildContext context, IconData icon, String label, double val) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Icon(icon, color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3), size: 16),
      const SizedBox(width: 8),
      SizedBox(width: 80, child: Text(label, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12, fontWeight: FontWeight.w600))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (val / 10).clamp(0.0, 1.0),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : AppTheme.lightSurface,
            valueColor: AlwaysStoppedAnimation(val >= 8 ? AppTheme.primary : val >= 6 ? AppTheme.accent : AppTheme.danger),
            minHeight: 6,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text(val.toStringAsFixed(1), style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.w700)),
    ]),
  );
}
