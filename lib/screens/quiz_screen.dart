import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String _quizType = 'mcq';
  String _difficulty = 'beginner';
  bool _loading = false;
  bool _quizStarted = false;
  bool _quizFinished = false;
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score = 0;
  int _total = 0;
  bool _answered = false;
  int? _selectedOption;
  final _fillCtrl = TextEditingController();

  // Timer
  Timer? _timer;
  int _timeLeft = 0;
  static const int _timePerQuestion = 30;

  // Track answers for results
  List<Map<String, dynamic>> _answerHistory = [];

  Future<void> _generateQuiz() async {
    setState(() { _loading = true; _quizFinished = false; _answerHistory = []; });
    final questions = await AIFeedbackService.generateQuizQuestions(type: _quizType, difficulty: _difficulty, count: 5);
    if (!mounted) return;
    if (questions.isEmpty) {
      // Provide fallback questions if API fails
      setState(() {
        _questions = _getFallbackQuestions();
        _current = 0;
        _score = 0;
        _total = _questions.length;
        _answered = false;
        _selectedOption = null;
        _loading = false;
        _quizStarted = true;
        _timeLeft = _timePerQuestion;
      });
    } else {
      setState(() {
        _questions = questions;
        _current = 0;
        _score = 0;
        _total = questions.length;
        _answered = false;
        _selectedOption = null;
        _loading = false;
        _quizStarted = true;
        _timeLeft = _timePerQuestion;
      });
    }
    _startTimer();
  }

  List<Map<String, dynamic>> _getFallbackQuestions() {
    if (_quizType == 'mcq') {
      return [
        {'question': 'Choose the correct word: She ___ to school every day.', 'options': ['go', 'goes', 'going', 'gone'], 'correct': 1, 'explanation': '"Goes" is used with third person singular (she/he/it) in simple present tense.'},
        {'question': 'Which sentence is grammatically correct?', 'options': ['I have went there.', 'I have gone there.', 'I have go there.', 'I has gone there.'], 'correct': 1, 'explanation': '"Have gone" is the correct present perfect form.'},
        {'question': 'Choose the correct preposition: He arrived ___ the airport.', 'options': ['in', 'on', 'at', 'to'], 'correct': 2, 'explanation': 'We use "at" with specific locations like airport, station, etc.'},
        {'question': 'What is the past tense of "write"?', 'options': ['writed', 'writed', 'wrote', 'wrotten'], 'correct': 2, 'explanation': '"Write" is an irregular verb. Past tense is "wrote", past participle is "written".'},
        {'question': 'Choose the correct article: ___ apple a day keeps the doctor away.', 'options': ['A', 'An', 'The', 'No article'], 'correct': 1, 'explanation': '"An" is used before words starting with a vowel sound.'},
      ];
    } else {
      return [
        {'sentence': 'She is very ___ at painting.', 'answer': 'good', 'hint': 'Describes ability', 'explanation': '"Good" is the adjective used to describe skill at something.'},
        {'sentence': 'I ___ to the store yesterday.', 'answer': 'went', 'hint': 'Past tense of go', 'explanation': '"Went" is the past tense of the irregular verb "go".'},
        {'sentence': 'They have been ___ for two hours.', 'answer': 'waiting', 'hint': 'Present participle', 'explanation': 'Present perfect continuous uses "have been + -ing form".'},
        {'sentence': 'Can you ___ me a favor?', 'answer': 'do', 'hint': 'Common phrase', 'explanation': '"Do me a favor" is a fixed expression meaning to help someone.'},
        {'sentence': 'She speaks English ___ than me.', 'answer': 'better', 'hint': 'Comparative form', 'explanation': '"Better" is the comparative form of "good/well".'},
      ];
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _timePerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        if (!_answered) _checkAnswer(-1);
      }
    });
  }

  void _checkAnswer(dynamic answer) {
    if (_answered) return;
    _timer?.cancel();
    setState(() => _answered = true);

    bool correct = false;
    String userAnswer = '';
    String correctAnswer = '';

    if (_quizType == 'mcq') {
      final correctIdx = _questions[_current]['correct'] as int? ?? 0;
      correct = answer == correctIdx;
      setState(() => _selectedOption = answer as int);
      final options = _questions[_current]['options'] as List?;
      userAnswer = (answer >= 0 && options != null && answer < options.length) ? options[answer].toString() : 'No answer';
      correctAnswer = (options != null && correctIdx < options.length) ? options[correctIdx].toString() : '';
    } else if (_quizType == 'fill_blank') {
      correctAnswer = (_questions[_current]['answer'] as String? ?? '').trim();
      userAnswer = _fillCtrl.text.trim();
      correct = userAnswer.toLowerCase() == correctAnswer.toLowerCase();
    }

    if (correct) setState(() => _score++);

    _answerHistory.add({
      'question': _questions[_current]['question'] ?? _questions[_current]['sentence'] ?? '',
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'correct': correct,
      'explanation': _questions[_current]['explanation'] ?? '',
    });
  }

  void _nextQuestion() {
    if (_current < _questions.length - 1) {
      setState(() { _current++; _answered = false; _selectedOption = null; _fillCtrl.clear(); });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    final result = QuizResult(id: const Uuid().v4(), quizType: _quizType, score: _score, total: _total, timeTaken: _total * _timePerQuestion);
    final state = context.read<AppState>();
    state.completeQuiz(result);
    state.addXP(_score * 10);
    state.incrementSessions();
    setState(() { _quizStarted = false; _quizFinished = true; });
  }

  @override
  void dispose() { _timer?.cancel(); _fillCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Quiz Challenge 🧠')),
      body: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Generating questions...', style: TextStyle(color: Colors.white54)),
            ]))
          : _quizFinished ? _buildResults() : _quizStarted ? _buildQuiz() : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quiz Type', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...[
          {'id': 'mcq', 'emoji': '🔘', 'title': 'Multiple Choice', 'desc': 'Choose the correct answer'},
          {'id': 'fill_blank', 'emoji': '✏️', 'title': 'Fill in the Blanks', 'desc': 'Complete the sentence'},
        ].map((t) => GestureDetector(
          onTap: () => setState(() => _quizType = t['id']!),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _quizType == t['id'] ? AppTheme.primary.withOpacity(0.1) : AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _quizType == t['id'] ? AppTheme.primary : AppTheme.darkBorder)),
            child: Row(children: [
              Text(t['emoji']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['title']!, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(t['desc']!, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
              ])),
              if (_quizType == t['id']) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
            ]),
          ),
        )),

        const SizedBox(height: 20),
        Text('Difficulty', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Row(children: ['beginner', 'intermediate', 'advanced'].map((d) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = d),
            child: Container(
              margin: EdgeInsets.only(right: d != 'advanced' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _difficulty == d ? AppTheme.primary.withOpacity(0.12) : AppTheme.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _difficulty == d ? AppTheme.primary : AppTheme.darkBorder)),
              child: Center(child: Text(d[0].toUpperCase() + d.substring(1),
                style: GoogleFonts.dmSans(color: _difficulty == d ? AppTheme.primary : Colors.white54, fontWeight: FontWeight.w600, fontSize: 13))),
            ),
          ),
        )).toList()),

        const SizedBox(height: 28),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _generateQuiz,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Quiz'),
        )),
      ]),
    );
  }

  Widget _buildQuiz() {
    if (_questions.isEmpty) return const Center(child: Text('No questions', style: TextStyle(color: Colors.white54)));
    final q = _questions[_current];

    return Column(children: [
      // Progress + Timer
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Text('${_current + 1}/$_total', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _timeLeft <= 10 ? AppTheme.danger.withOpacity(0.12) : AppTheme.darkCard,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: _timeLeft <= 10 ? AppTheme.danger : AppTheme.darkBorder)),
          child: Row(children: [
            Icon(Icons.timer, color: _timeLeft <= 10 ? AppTheme.danger : Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text('${_timeLeft}s', style: GoogleFonts.dmSans(color: _timeLeft <= 10 ? AppTheme.danger : Colors.white, fontWeight: FontWeight.w700)),
          ]),
        ),
      ])),
      LinearProgressIndicator(value: (_current + 1) / _total, backgroundColor: AppTheme.darkSurface, valueColor: const AlwaysStoppedAnimation(AppTheme.primary)),

      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Question
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
          child: Text(q['question'] ?? q['sentence'] ?? '', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
        ),
        const SizedBox(height: 20),

        // MCQ Options
        if (_quizType == 'mcq' && q['options'] != null)
          ...List.generate((q['options'] as List).length, (i) {
            final option = q['options'][i].toString();
            final correct = q['correct'] as int? ?? 0;
            final isSelected = _selectedOption == i;
            final isCorrect = i == correct;
            Color optColor = AppTheme.darkCard;
            Color borderColor = AppTheme.darkBorder;
            if (_answered) {
              if (isCorrect) { optColor = AppTheme.primary.withOpacity(0.12); borderColor = AppTheme.primary; }
              else if (isSelected) { optColor = AppTheme.danger.withOpacity(0.12); borderColor = AppTheme.danger; }
            } else if (isSelected) {
              optColor = AppTheme.primary.withOpacity(0.08);
              borderColor = AppTheme.primary;
            }
            return GestureDetector(
              onTap: () => _answered ? null : _checkAnswer(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: optColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
                child: Row(children: [
                  Container(width: 28, height: 28,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: borderColor.withOpacity(0.2)),
                    child: Center(child: Text(String.fromCharCode(65 + i), style: GoogleFonts.dmSans(color: borderColor, fontWeight: FontWeight.w700)))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14))),
                  if (_answered && isCorrect) const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
                  if (_answered && isSelected && !isCorrect) const Icon(Icons.cancel, color: AppTheme.danger, size: 20),
                ]),
              ),
            ).animate().fadeIn(delay: (i * 60).ms);
          }),

        // Fill in blank
        if (_quizType == 'fill_blank') ...[
          if (q['hint'] != null)
            Padding(padding: const EdgeInsets.only(bottom: 8),
              child: Text('💡 Hint: ${q['hint']}', style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 13))),
          TextField(
            controller: _fillCtrl, enabled: !_answered,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(hintText: 'Type your answer...'),
            onSubmitted: (_) => _checkAnswer(_fillCtrl.text),
          ),
          const SizedBox(height: 12),
          if (!_answered)
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _checkAnswer(_fillCtrl.text), child: const Text('Submit'))),
          if (_answered) ...[
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(
              color: (_fillCtrl.text.toLowerCase().trim() == (q['answer'] ?? '').toString().toLowerCase().trim()) ? AppTheme.primary.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Icon(
                  (_fillCtrl.text.toLowerCase().trim() == (q['answer'] ?? '').toString().toLowerCase().trim()) ? Icons.check_circle : Icons.cancel,
                  color: (_fillCtrl.text.toLowerCase().trim() == (q['answer'] ?? '').toString().toLowerCase().trim()) ? AppTheme.primary : AppTheme.danger,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('Correct answer: ${q['answer']}', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
              ])),
          ],
        ],

        // Explanation
        if (_answered && q['explanation'] != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('📖 Explanation', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(q['explanation'], style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
            ])),
        ],

        if (_answered) ...[
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _nextQuestion,
            child: Text(_current < _questions.length - 1 ? 'Next Question →' : 'View Results 🏆'),
          )),
        ],
      ]))),
    ]);
  }

  // ── Results Screen with percentage, pass/fail, breakdown ──
  Widget _buildResults() {
    final percentage = _total > 0 ? (_score / _total * 100) : 0.0;
    final passed = percentage >= 60;
    final color = passed ? AppTheme.primary : AppTheme.danger;
    final grade = percentage >= 90 ? 'A+' : percentage >= 80 ? 'A' : percentage >= 70 ? 'B' : percentage >= 60 ? 'C' : percentage >= 50 ? 'D' : 'F';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Result Header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), AppTheme.darkCard]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4))),
          child: Column(children: [
            Text(passed ? '🎉' : '😔', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(passed ? 'PASSED!' : 'FAILED', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900, fontSize: 28)),
            const SizedBox(height: 8),
            // Percentage ring
            SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: percentage / 100, strokeWidth: 8,
                backgroundColor: AppTheme.darkSurface,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${percentage.toStringAsFixed(0)}%', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900, fontSize: 24)),
                Text('Grade: $grade', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
              ]),
            ])),
            const SizedBox(height: 12),
            Text('$_score out of $_total correct', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16)),
            Text('${_quizType.toUpperCase()} • ${_difficulty[0].toUpperCase()}${_difficulty.substring(1)}',
              style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 8),
            Text('+${_score * 10} XP earned ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ]),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 20),

        // Answer Breakdown
        Text('Question Breakdown', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...List.generate(_answerHistory.length, (i) {
          final a = _answerHistory[i];
          final correct = a['correct'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: correct ? AppTheme.primary.withOpacity(0.05) : AppTheme.danger.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (correct ? AppTheme.primary : AppTheme.danger).withOpacity(0.25))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? AppTheme.primary : AppTheme.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Q${i + 1}: ${a['question']}', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 6),
              if (!correct) ...[
                Text('Your answer: ${a['userAnswer']}', style: GoogleFonts.dmSans(color: AppTheme.danger, fontSize: 12)),
                Text('Correct: ${a['correctAnswer']}', style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 12)),
              ],
              if (a['explanation'] != null && (a['explanation'] as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('📖 ${a['explanation']}', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11)),
              ],
            ]),
          ).animate().fadeIn(delay: (i * 60).ms);
        }),

        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => setState(() { _quizFinished = false; _quizStarted = false; }),
            child: const Text('New Quiz'),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: _generateQuiz,
            child: const Text('Try Again'),
          )),
        ]),
        const SizedBox(height: 24),
      ]),
    );
  }
}
