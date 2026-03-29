import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/question_card.dart';
import '../widgets/selector_widgets.dart';
import '../widgets/ai_error_widget.dart';
import '../widgets/ai_loading_widget.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/voice_wave.dart';
import '../widgets/confidence_meter.dart';
import 'gd_screen.dart';
import 'dart:ui';

class SpeakingScreen extends StatefulWidget {
  final PracticeTopic? topic;
  final Question? question;

  const SpeakingScreen({super.key, this.topic, this.question});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> with TickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  late QuestionService _questionService;

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _processing = false;
  String _spokenText = '';
  String _liveText = '';
  String _errorMessage = '';
  ChatMessage? _feedback;
  double _soundLevel = 0.0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Question? _currentQuestion;
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _questionService = QuestionService();

    if (widget.topic != null) {
      _selectedCategory = widget.topic!.title;
    }

    if (widget.question != null) {
      _currentQuestion = widget.question;
    } else {
      _generateNewQuestion();
    }
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    if (!kIsWeb) {
      final status = await Permission.microphone.status;
      if (!status.isGranted) {
        final result = await Permission.microphone.request();
        if (!result.isGranted) {
          _showError('Microphone permission denied.');
          return;
        }
      }
    }

    _speechAvailable = await _speech.initialize(
      onError: (e) => _showError('Mic error: ${e.errorMsg}'),
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _stopListening();
        }
      },
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    final state = context.read<AppState>();
    final speed = {'slow': 0.35, 'normal': 0.5, 'fast': 0.65}[state.profile.voicePreference] ?? 0.5;
    await _tts.setSpeechRate(speed);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('Microphone not available.');
      return;
    }
    setState(() { _isListening = true; _liveText = ''; _spokenText = ''; _feedback = null; });

    await _speech.listen(
      onResult: (r) {
        setState(() => _recognizedText = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _stopListening(autoSubmit: true);
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      partialResults: true, localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    setState(() => _isListening = false);
    
    if (_liveText.trim().isNotEmpty && !_processing) {
      setState(() { 
        _spokenText = _liveText; 
        _processing = true; 
        _liveText = ''; 
      });
      await _processVoice();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _liveText = result.recognizedWords);
    if (result.finalResult && result.recognizedWords.isNotEmpty && !_processing) {
      _stopListening();
    }
  }

    try {
      final state = context.read<AppState>();
      state.addXP(fb.xp);
      state.addWordsSpoken(_spokenText.split(' ').length);
      state.addPracticeMinutes(1);
      state.addSession(PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: _currentQuestion?.text ?? 'Speaking Practice',
        type: 'Speaking',
        score: fb.score ?? 0.0,
        xp: fb.xp,
        topicId: widget.topic?.id,
      ));
      setState(() { _feedback = fb; _processing = false; });
      _showFeedbackModal(fb);
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString(); _processing = false; });
    }
  }

  void _showFeedbackModal(ChatMessage fb) {
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
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.textSecondary.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('ANALYSIS COMPLETE', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              ConfidenceMeter(score: fb.score ?? 7.5),
              const SizedBox(height: 16),
              Text(fb.text, textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 16, height: 1.5)),
              const SizedBox(height: 24),
              if (fb.feedback != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                  child: Text(fb.feedback!, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14)),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: Text('CONTINUE PRACTICE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.topic != null ? '${widget.topic!.title} Practice' : 'Speaking Practice',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              onPressed: _generateNewQuestion,
              tooltip: 'New Question',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
            CategorySelector(
              categories: _getCategories(),
              selectedCategory: _selectedCategory,
              onChanged: (category) {
                setState(() => _selectedCategory = category);
                _generateNewQuestion();
              },
            ),
            const SizedBox(height: 16),
            DifficultySelector(
              selectedDifficulty: _selectedDifficulty,
              onChanged: (difficulty) {
                setState(() => _selectedDifficulty = difficulty);
                _generateNewQuestion();
              },
            ),
            const SizedBox(height: 24),

            // AI Group Simulation Launch Button (Integrated)
            if (_selectedCategory == 'Group Discussion')
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('🗣️', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AI Group Simulation', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
                                Text('Practice with 4 virtual participants in a real-time GD round.', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GDScreen())),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('LAUNCH SIMULATION', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideX(),

            if (_currentQuestion != null)
              SizedBox(
                height: 380, // Fixed height for swipe area
                child: PageView.builder(
                  onPageChanged: (_) => _generateNewQuestion(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: QuestionCard(
                        question: _currentQuestion!,
                        onRefresh: _generateNewQuestion,
                      ),
                    );
                  },
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 32),

            Text(
              !_speechAvailable  ? '⚠️ Microphone not available'
                  : _isListening   ? '🔴 Listening... tap to stop'
                  : _processing    ? '⚙️  Analyzing your speech...'
                  : _feedback != null ? '✅ Done! Great job!'
                  : 'Tap the mic and start speaking',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _isListening ? AppTheme.danger : _processing ? AppTheme.accent : AppTheme.textSecondary,
              ),
            ).animate(target: _isListening ? 1 : 0).shimmer(duration: 1200.ms),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                if (!_speechAvailable || _processing) return;
                _isListening ? _stopListening() : _startListening();
              },
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _isListening ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening   ? AppTheme.danger.withValues(alpha: 0.1)
                          : _processing  ? AppTheme.accent.withValues(alpha: 0.1)
                          : AppTheme.primary.withValues(alpha: 0.1),
                      border: Border.all(
                        color: _isListening ? AppTheme.danger : _processing ? AppTheme.accent : AppTheme.primary,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? AppTheme.danger : _processing ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                    child: Icon(
                      _processing ? Icons.hourglass_top_rounded : _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                       color: _isListening ? AppTheme.danger : _processing ? AppTheme.accent : AppTheme.primary,
                      size: 40,
                    ),
                  ),
                ]),
              ]),
            ),
          const SizedBox(height: 24),

          // Record button
          Center(child: GestureDetector(
            onTap: () => _isListening ? _stopListening(autoSubmit: true) : _startListening(),
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.primary.withOpacity(0.12),
                border: Border.all(color: _isListening ? AppTheme.danger : AppTheme.primary, width: 3),
              ),
            ).animate(target: _processing ? 1 : 0).custom(duration: 2000.ms, builder: (context, value, child) => RotationTransition(turns: AlwaysStoppedAnimation(value), child: child)),

            if (_isListening) ...[
              const SizedBox(height: 16),
              VoiceWave(soundLevel: _soundLevel, isListening: _isListening),
            ],

            const SizedBox(height: 24),

            if (_isListening && _liveText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppTheme.danger.withValues(alpha: 0.1) : AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _liveText,
                  style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

            if (_processing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AILoadingWidget(),
              ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: AIErrorWidget(
                  message: _errorMessage,
                  onRetry: () {
                    setState(() { _errorMessage = ''; _processing = true; });
                    _processVoice();
                  },
                ),
              ),

            if (_spokenText.isNotEmpty && !_isListening && _feedback == null && !_processing) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YOU SAID', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Text(_spokenText, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
                ]),
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 32),
          ]),
        ),
      ),
    ),
  );
}
}

// --- MISSING WIDGETS ADDED BELOW ---

class _FeedbackCard extends StatelessWidget {
  final ChatMessage message;
  const _FeedbackCard({required this.message});
  @override
  Widget build(BuildContext context) {
    final score = message.score ?? 7.0;
    final color = score >= 8 ? AppTheme.primary : score >= 6 ? AppTheme.accent : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🤖 AI Feedback', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('${score.toStringAsFixed(1)} / 10',
              style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Text(message.text, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14, height: 1.6)),
        if (message.feedback != null) ...[
          const SizedBox(height: 10),
          Text(message.feedback!, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7), fontSize: 13, height: 1.5)),
        ],
        const SizedBox(height: 12),
        Text('+${message.xp} XP earned!',
            style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}
