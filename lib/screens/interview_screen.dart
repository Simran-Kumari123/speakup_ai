import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/speech_service.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

import '../services/question_service.dart';
import '../services/ai_feedback_service.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/ai_loading_widget.dart';
import '../widgets/selector_widgets.dart';
import '../widgets/app_widgets.dart';
import '../widgets/voice_wave.dart';
import '../widgets/premium_button.dart';

class InterviewScreen extends StatefulWidget {
  final PracticeTopic? topic;
  const InterviewScreen({super.key, this.topic});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final QuestionService _questionService = QuestionService();
  
  String? _selectedCategory = 'hr';
  String? _selectedDifficulty = 'beginner';
  Question? _currentQuestion;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
  }

  void _generateNewQuestion() {
    setState(() {
      _currentQuestion = _questionService.getRandomQuestion(
        type: 'interview',
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
      );
    });
  }

  List<String> _getCategories() {
    return _questionService.getCategories(type: 'interview');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.interviewPrep),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: _generateNewQuestion,
            tooltip: 'New Question',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.practiceSettings, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CategorySelector(
                  categories: _getCategories(),
                  selectedCategory: _selectedCategory,
                  onChanged: (cat) {
                    setState(() => _selectedCategory = cat);
                    _generateNewQuestion();
                  },
                ).animate().fadeIn().slideX(begin: -0.1),
                const SizedBox(height: 16),
                DifficultySelector(
                  selectedDifficulty: _selectedDifficulty,
                  onChanged: (diff) {
                    setState(() => _selectedDifficulty = diff);
                    _generateNewQuestion();
                  },
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
                  const SizedBox(height: 24),
                  if (_currentQuestion != null)
                    _InterviewQuestionCard(
                      key: ValueKey(_currentQuestion!.id),
                      q: _currentQuestion!,
                      onRefresh: _generateNewQuestion,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1)
                  else
                    const Center(child: CircularProgressIndicator()),
                ],
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
  final TextEditingController _ctrl = TextEditingController();
  
  bool _isListening = false;
  double _soundLevel = 0.0;
  bool _processing = false;
  String _errorMessage = '';
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    final speechService = context.read<SpeechService>();
    if (_isListening) {
      await speechService.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await speechService.init(
        onError: (e) => setState(() => _isListening = false),
        onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _isListening = false); },
      );
      if (available) {
        setState(() { _isListening = true; _errorMessage = ''; });
        await speechService.listen(
          onResult: (text, isFinal) {
            if (mounted) setState(() => _ctrl.text = text);
          },
          onSoundLevelChange: (level) => setState(() => _soundLevel = level),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: 'en_US',
        );
      } else {
        setState(() => _errorMessage = 'Speech recognition not available');
      }
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _ctrl.text.trim();
    if (answer.isEmpty) return;
    
    setState(() { _processing = true; _errorMessage = ''; _result = null; });
    
    try {
      final res = await AIFeedbackService.evaluateAnswer(
        question: widget.q.text,
        answer: answer,
      );
      
      if (!mounted) return;
      
      final state = context.read<AppState>();
      state.addXP(res['xp'] ?? 20);
      state.addPracticeMinutes(5); // Typical interview answer + thought time
      state.addSession(PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: widget.q.text,
        type: 'Interview',
        score: (res['score'] as num?)?.toDouble() ?? 5.0,
        fluency: (res['fluency'] as num?)?.toDouble() ?? 5.0,
        grammar: (res['grammar'] as num?)?.toDouble() ?? 5.0,
        confidence: (res['confidence'] as num?)?.toDouble() ?? 5.0,
        xp: res['xp'] ?? 20,
      ));
      
      setState(() {
        _result = res;
        _processing = false;
      });
      _showResultModal(res);
    } catch (e) {
      setState(() {
        _errorMessage = "Evaluation failed. Please try again.";
        _processing = false;
      });
    }
  }

  void _showResultModal(Map<String, dynamic> res) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: SingleChildScrollView(
          child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('AI EVALUATION', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              ScoreDisplay(score: (res['score'] as num?)?.toDouble() ?? 5.0, size: 80, label: 'Overall Score'),
              const SizedBox(height: 20),
              Text(res['feedback'] as String? ?? 'Evaluation complete.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _miniScore('Fluency', (res['fluency'] as num?)?.toDouble() ?? 5.0),
                  _miniScore('Relevance', (res['relevance'] as num?)?.toDouble() ?? 5.0),
                  _miniScore('Confidence', (res['confidence'] as num?)?.toDouble() ?? 5.0),
                ],
              ),
              const SizedBox(height: 24),
              PremiumButton(
                label: 'CONTINUE TRAINING',
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
              Text('+${res['xp']} XP earned ⭐', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _miniScore(String label, double val) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(val.toStringAsFixed(1), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
      Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05), width: 1.5),
        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tag(widget.q.category.toUpperCase(), theme.colorScheme.primary),
                  _tag(widget.q.difficulty.toUpperCase(), theme.colorScheme.primary),
                ],
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.topRight,
              onPressed: widget.onRefresh, 
              icon: Icon(Icons.refresh_rounded, color: theme.textTheme.bodySmall?.color?.withOpacity(0.3), size: 20),
            ),
        ]),
        const SizedBox(height: 20),
        Text(widget.q.text, style: theme.textTheme.displaySmall?.copyWith(fontSize: 22, height: 1.3)),
        const SizedBox(height: 16),
        if (widget.q.hints.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Text('💡 ', style: TextStyle(fontSize: 14)),
              Expanded(child: Text(widget.q.hints.first, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600))),
            ]),
          ),
        const SizedBox(height: 24),
        if (_isListening) 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: VoiceWave(soundLevel: _soundLevel, isListening: _isListening),
          ),
        TextField(
          controller: _ctrl,
          maxLines: 4,
          style: theme.textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Speak or type your answer...',
            suffixIcon: IconButton(
              icon: Icon(_isListening ? Icons.stop_circle_rounded : Icons.mic_rounded),
              color: _isListening ? AppTheme.danger : theme.colorScheme.primary,
              onPressed: _toggleListening,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_errorMessage, style: TextStyle(color: theme.colorScheme.error, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        if (_processing)
          const Center(child: AILoadingWidget())
        else
          PremiumButton(
            label: 'Submit for Review 🤖',
            onPressed: _submitAnswer,
            isLoading: _processing,
          ),
      ]),
    );
  }

  Widget _tag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: GoogleFonts.dmSans(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    ),
  );
}
