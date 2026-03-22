import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../models/question_model.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';
import '../widgets/selector_widgets.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});
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
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Mock Interview 💼'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            onPressed: _generateNewQuestion,
            tooltip: 'New Question',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
            if (_currentQuestion != null)
              _InterviewQuestionCard(q: _currentQuestion!, onRefresh: _generateNewQuestion)
            else
              const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _InterviewQuestionCard extends StatefulWidget {
  final Question q;
  final VoidCallback onRefresh;
  const _InterviewQuestionCard({required this.q, required this.onRefresh});
  @override
  State<_InterviewQuestionCard> createState() => _InterviewQuestionCardState();
}

class _InterviewQuestionCardState extends State<_InterviewQuestionCard> {
  bool _expanded    = true;
  bool _practicing  = false;
  bool _processing  = false;
  Map<String, dynamic>? _result;
  final _ctrl = TextEditingController();

  void _submitAnswer() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _processing = true);
    final res = await AIFeedbackService.evaluateAnswer(
      question: widget.q.text, answer: _ctrl.text,
    );
    if (!mounted) return;
    context.read<AppState>().addXP((res['xp'] as int));
    context.read<AppState>().incrementSessions();
    setState(() { _result = res; _processing = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                child: Text(widget.q.category.toUpperCase(), style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                child: Text(widget.q.difficulty.toUpperCase(), style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              IconButton(onPressed: widget.onRefresh, icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20)),
            ]),
            const SizedBox(height: 12),
            Text(widget.q.text,
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, height: 1.4)),
            
            const SizedBox(height: 16),
            if (widget.q.hints.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('💡 ', style: TextStyle(fontSize: 14)),
                  Expanded(child: Text(widget.q.hints.first,
                      style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5))),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            if (!_practicing && _result == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Practice Answer'),
                  onPressed: () => setState(() => _practicing = true),
                ),
              ),

            if (_practicing && _result == null) ...[
              TextField(
                controller: _ctrl,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processing ? null : _submitAnswer,
                  child: _processing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkBg))
                      : const Text('Get AI Feedback 🤖'),
                ),
              ),
            ],

            if (_result != null) ...[
              _ResultCard(result: _result!),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() { _result = null; _practicing = false; _ctrl.clear(); }),
                child: Text('Try Again', style: TextStyle(color: Colors.white38)),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = (result['score'] as double);
    final color = score >= 8 ? AppTheme.primary : score >= 6 ? AppTheme.accent : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('AI Evaluation', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700)),
          Text('${score.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 12),
        _scoreRow('Fluency',   result['fluency']   as double),
        _scoreRow('Relevance', result['relevance'] as double),
        _scoreRow('Confidence',result['confidence']as double),
        const SizedBox(height: 10),
        Text(result['feedback'] as String,
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
        const SizedBox(height: 10),
        ...((result['suggestions'] as List<String>).map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('→ ', style: TextStyle(color: AppTheme.primary)),
            Expanded(child: Text(s, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
          ]),
        ))),
        const SizedBox(height: 8),
        Text('+${result['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _scoreRow(String label, double val) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
      Expanded(
        child: LinearProgressIndicator(
          value: val / 10,
          backgroundColor: AppTheme.darkSurface,
          valueColor: AlwaysStoppedAnimation(val >= 8 ? AppTheme.primary : val >= 6 ? AppTheme.accent : AppTheme.danger),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ),
      const SizedBox(width: 8),
      Text(val.toStringAsFixed(1), style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11)),
    ]),
  );
}
