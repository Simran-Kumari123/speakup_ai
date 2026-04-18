import 'dart:async';
import 'package:flutter/material.dart';
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

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  String _quizType = 'mcq';
  String _difficulty = 'beginner';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final profile = context.read<AppState>().profile;
    _difficulty = profile.difficulty;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && _quizStarted && !_answered && !_quizFinished) {
      _startTimer(); // Resume the race
    }
  }
  bool _quizStarted = false;
  bool _quizFinished = false;
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score = 0;
  int _total = 0;
  bool _answered = false;
  int? _selectedOption;
  final _fillCtrl = TextEditingController();

  Timer? _timer;
  int _timeLeft = 0;
  static const int _timePerQuestion = 30;

  List<Map<String, dynamic>> _answerHistory = [];
  List<String> _currentTopics = [];

  static const List<String> _masterTopics = [
    'Tenses (Past, Present, Future)', 'Conditional Sentences (If-clauses)', 'Passive Voice',
    'Phrasal Verbs (Work & Business)', 'Modal Verbs (Necessity, Ability)', 'Prepositions of Place & Time',
    'Gerunds vs Infinitives', 'Relative Clauses', 'Reported Speech', 'Articles (A, An, The)',
    'Business Idioms', 'Social Networking Vocabulary', 'Travel & Tourism Phrasal Verbs',
    'Academic Vocabulary', 'Medical Terms for Daily Life', 'Technology & Innovation',
    'Environmental Issues', 'Nuances of "Used to" vs "Would"', 'Subjunctive Mood',
    'Connectors & Transitions', 'Collocations with "Do" and "Make"', 'Adjectives vs Adverbs',
    'Quantifiers (Few, Little, Some, Any)', 'Question Tags', 'Irregular Past Tenses',
    'Negotiation Phrases', 'Customer Service English', 'Job Interview Etiquette',
    'Email Writing Phrases', 'Presenting Data & Charts', 'Expressing Opinion & Debate',
    'Agreeing & Disagreeing Naturally', 'Indirect Questions', 'Causative Verbs (Have/Get)',
    'Compound Nouns & Adjectives', 'Synonyms for Common Words', 'Antonyms in Context',
    'Prefixes & Suffixes', 'Abstract Nouns', 'Collective Nouns', 'Standard British vs American usage',
    'Formal vs Informal Tone', 'Inversion for Emphasis', 'Participle Clauses',
    'Homophones & Confusing Words', 'Exclamatory Sentences', 'Imperative Mood in Instructions',
    'Describing People & Personalities', 'Describing Places & Atmosphere', 'Giving Directions',
    'Ordering at a Restaurant', 'Emergency Phrases'
  ];

  Future<void> _generateQuiz() async {
    setState(() { _loading = true; _quizFinished = false; _answerHistory = []; });
    
    final state = context.read<AppState>();
    
    // 1. Pick 5 random topics from master list
    final List<String> randomTopics = (List<String>.from(_masterTopics)..shuffle()).take(5).toList();
    
    // 2. Add user's unique context
    if (state.profile.weakWords.isNotEmpty) {
      randomTopics.add('Vocabulary the user previously struggled with: ${state.profile.weakWords.join(", ")}');
    }
    if (state.vocabulary.isNotEmpty) {
      final learned = state.vocabulary.where((v) => v.learned).map((v) => v.word).toList();
      if (learned.isNotEmpty) {
        randomTopics.add('Reinforce learned words: ${(List<String>.from(learned)..shuffle()).take(3).join(", ")}');
      }
    }
    
    _currentTopics = randomTopics;

    final questions = await AIFeedbackService.generateQuizQuestions(
      type: _quizType, 
      difficulty: _difficulty, 
      count: 5,
      topics: _currentTopics
    );

    if (!mounted) return;
    if (questions.isEmpty) {
      setState(() {
        _questions = _getFallbackQuestions();
        _current = 0; _score = 0; _total = _questions.length;
        _answered = false; _selectedOption = null; _loading = false;
        _quizStarted = true; _timeLeft = _timePerQuestion;
      });
    } else {
      setState(() {
        _questions = questions;
        _current = 0; _score = 0; _total = questions.length;
        _answered = false; _selectedOption = null; _loading = false;
        _quizStarted = true; _timeLeft = _timePerQuestion;
      });
    }
    _startTimer();
  }

  List<Map<String, dynamic>> _getFallbackQuestions() {
    if (_quizType == 'mcq') {
      return [
        {'question': 'Choose the correct word: She ___ to school every day.', 'options': ['go', 'goes', 'going', 'gone'], 'correct': 1, 'explanation': '"Goes" is used with third person singular.'},
        {'question': 'Which sentence is correct?', 'options': ['I have went there.', 'I have gone there.', 'I has goes there.', 'I has gone there.'], 'correct': 1, 'explanation': 'Present perfect uses "have gone".'},
      ];
    } else {
      return [
        {'sentence': 'She is very ___ at painting.', 'answer': 'good', 'hint': 'Describes ability', 'explanation': 'Adjective form.'},
        {'sentence': 'I ___ to the store yesterday.', 'answer': 'went', 'hint': 'Past of go', 'explanation': 'Irregular past tense.'},
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
      'type': _quizType,
      'question': _questions[_current]['question'] ?? _questions[_current]['sentence'] ?? '',
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'correct': correct,
      'explanation': _questions[_current]['explanation'] ?? '',
      'options': _quizType == 'mcq' ? _questions[_current]['options'] : null,
      'selectedIdx': _quizType == 'mcq' ? answer : null,
      'correctIdx': _quizType == 'mcq' ? _questions[_current]['correct'] : null,
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
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); 
    _fillCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Quiz Challenge 🧠')),
      body: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Generating questions...', style: theme.textTheme.bodyMedium),
            ]))
          : _quizFinished ? _buildResults() : _quizStarted ? _buildQuiz() : _buildSetup(),
    );
  }

  Widget _buildSetup() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('PREPARATION', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
        ]),
        const SizedBox(height: 16),
        Text('Knowledge Hub 🧠', style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('Challenge yourself with AI-generated questions.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        
        Text('CHOOSE QUIZ TYPE', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        ...[
          {'id': 'mcq', 'emoji': '🔘', 'title': 'Multiple Choice', 'desc': 'Identify the correct option'},
          {'id': 'fill_blank', 'emoji': '✏️', 'title': 'Sentence Completion', 'desc': 'Fill in the missing words'},
        ].map((t) {
          final isSel = _quizType == t['id'];
          return GestureDetector(
            onTap: () => setState(() => _quizType = t['id']!),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isSel ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05)),
              ),
              child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: (isSel ? theme.colorScheme.primary : theme.inputDecorationTheme.fillColor!).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text(t['emoji']!, style: const TextStyle(fontSize: 22)))),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['title']!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: isSel ? theme.colorScheme.primary : null)),
                  Text(t['desc']!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                ])),
                if (isSel) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
              ]),
            ),
          );
        }),

        const SizedBox(height: 32),
        Text('SELECT DIFFICULTY', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(children: ['beginner', 'intermediate', 'advanced'].map((d) => Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: d != 'advanced' ? 12 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _difficulty == d ? theme.colorScheme.primary.withOpacity(0.1) : theme.cardColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _difficulty == d ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05))),
              child: Center(child: Text(d[0].toUpperCase() + d.substring(1),
                style: theme.textTheme.bodySmall?.copyWith(color: _difficulty == d ? theme.colorScheme.primary : null, fontWeight: FontWeight.w900, fontSize: 11))),
            ),
          ),
        )).toList()),

        const SizedBox(height: 48),
        SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _generateQuiz, child: const Text('Generate Quiz →'))),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildQuiz() {
    final theme = Theme.of(context);
    if (_questions.isEmpty) return const Center(child: Text('No questions available.'));
    final q = _questions[_current];

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
        Text('Question ${_current + 1} of $_total', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _timeLeft <= 10 ? AppTheme.danger.withOpacity(0.1) : theme.cardColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _timeLeft <= 10 ? AppTheme.danger.withOpacity(0.4) : theme.dividerColor.withOpacity(0.05))),
          child: Row(children: [
            Icon(Icons.timer_rounded, color: _timeLeft <= 10 ? AppTheme.danger : theme.colorScheme.primary, size: 16),
            const SizedBox(width: 8),
            Text('${_timeLeft}s', style: theme.textTheme.bodySmall?.copyWith(color: _timeLeft <= 10 ? AppTheme.danger : theme.colorScheme.primary, fontWeight: FontWeight.w900)),
          ]),
        ),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (_current+1)/_total, minHeight: 6, backgroundColor: theme.dividerColor.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary)))),
      
      if (_currentTopics.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 0, 4),
          child: SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _currentTopics.length,
              itemBuilder: (context, idx) {
                final t = _currentTopics[idx];
                if (t.contains(':')) return const SizedBox.shrink(); // Hide complex internal topics
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Text(t, style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.w800, color: theme.colorScheme.primary.withOpacity(0.7))),
                );
              },
            ),
          ),
        ),

      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1))),
          child: Text(q['question'] ?? q['sentence'] ?? '', style: theme.textTheme.titleLarge?.copyWith(height: 1.4, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 32),

        if (_quizType == 'mcq')
          ...List.generate((q['options'] as List).length, (i) {
            final option = q['options'][i].toString();
            final correct = q['correct'] as int? ?? 0;
            final isSelected = _selectedOption == i;
            final isCorrect = i == correct;
            Color borderColor = theme.dividerColor.withOpacity(0.05);
            Color shadowColor = Colors.transparent;
            if (_answered) {
              if (isCorrect) { borderColor = theme.colorScheme.primary; }
              else if (isSelected) { borderColor = AppTheme.danger; }
            } else if (isSelected) {
              borderColor = theme.colorScheme.primary;
              shadowColor = theme.colorScheme.primary.withOpacity(0.1);
            }
            return GestureDetector(
              onTap: () => _answered ? null : _checkAnswer(i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(0.5), 
                  borderRadius: BorderRadius.circular(20), 
                  border: Border.all(color: borderColor, width: isSelected || (_answered && isCorrect) ? 2 : 1),
                  boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10)],
                ),
                child: Row(children: [
                  Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: borderColor.withOpacity(0.1)),
                    child: Center(child: Text(String.fromCharCode(65 + i), style: theme.textTheme.bodySmall?.copyWith(color: borderColor, fontWeight: FontWeight.w900)))),
                  const SizedBox(width: 16),
                  Expanded(child: Text(option, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500))),
                  if (_answered && isCorrect) Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 24),
                  if (_answered && isSelected && !isCorrect) const Icon(Icons.cancel_rounded, color: AppTheme.danger, size: 24),
                ]),
              ),
            );
          }),

        if (_quizType == 'fill_blank') ...[
          if (q['hint'] != null) Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: AppTheme.earthyAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Row(children: [
                const Icon(Icons.lightbulb_rounded, color: AppTheme.earthyAccent, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('HINT: ${q['hint']}', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5))),
          ])),
          TextField(controller: _fillCtrl, enabled: !_answered, style: theme.textTheme.bodyLarge, decoration: InputDecoration(hintText: 'Type your answer...', filled: true, fillColor: theme.cardColor.withOpacity(0.5))),
          const SizedBox(height: 20),
          if (!_answered) SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: () => _checkAnswer(_fillCtrl.text), child: const Text('Check Answer'))),
          if (_answered) Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(children: [
                  Icon(Icons.stars_rounded, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('CORRECT ANSWER', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('${q['answer']}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  ])),
          ])),
        ],

        if (_answered && q['explanation'] != null) ...[
          const SizedBox(height: 24),
          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.menu_book_rounded, color: AppTheme.earthyAccent, size: 18),
                const SizedBox(width: 10),
                Text('LEARNING NOTE', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ]),
              const SizedBox(height: 12),
              Text(q['explanation'], style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontWeight: FontWeight.w500)),
          ])),
        ],

        if (_answered) ...[
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _nextQuestion, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.primary, foregroundColor: theme.colorScheme.onPrimary), child: Text(_current < _questions.length - 1 ? 'Next Question →' : 'Finish Quiz ✨'))),
          const SizedBox(height: 48),
        ],
      ]))),
    ]);
  }

  Widget _buildResults() {
    final theme = Theme.of(context);
    final percentage = _total > 0 ? (_score / _total * 100) : 0.0;
    final passed = percentage >= 60;
    final color = passed ? theme.colorScheme.primary : AppTheme.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08), 
            borderRadius: BorderRadius.circular(40), 
            border: Border.all(color: color.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(children: [
            Text(passed ? '🏆' : '💪', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(passed ? 'EXCELLENT!' : 'KEEP GOING', 
              style: theme.textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
            const SizedBox(height: 40),
            SizedBox(width: 140, height: 140, child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 140, height: 140, child: CircularProgressIndicator(value: percentage/100, strokeWidth: 12, backgroundColor: theme.dividerColor.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(color))),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${percentage.toStringAsFixed(0)}%', style: theme.textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 36)),
                Text('SCORE', style: theme.textTheme.bodySmall?.copyWith(color: color.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              ]),
            ])),
            const SizedBox(height: 32),
            Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: BoxDecoration(color: theme.colorScheme.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('$_score', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: color)),
                Text(' / $_total Correct', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ])),
            const SizedBox(height: 16),
            Text('+${_score * 10} XP EARNED ⭐', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ]),
        ),
        const SizedBox(height: 32),
        Text('Question Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
        const SizedBox(height: 16),
        ..._answerHistory.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          final correct = a['correct'] == true;
          final qColor = correct ? theme.colorScheme.primary : AppTheme.danger;
          final isMcq = a['type'] == 'mcq';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(28), 
              border: Border.all(color: qColor.withOpacity(0.1))
            ),
            child: ExpansionTile(
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(width: 32, height: 32, decoration: BoxDecoration(color: qColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Center(child: Icon(correct ? Icons.check_rounded : Icons.close_rounded, color: qColor, size: 18))),
              title: Text('Question ${i + 1}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1, color: qColor)),
              subtitle: Text(a['question'], style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    if (isMcq && a['options'] != null) ...[
                      ...List.generate((a['options'] as List).length, (idx) {
                        final opt = a['options'][idx].toString();
                        final isUserChoice = a['selectedIdx'] == idx;
                        final isCorrectChoice = a['correctIdx'] == idx;
                        Color statusColor = Colors.transparent;
                        IconData? statusIcon;
                        if (isCorrectChoice) { statusColor = theme.colorScheme.primary; statusIcon = Icons.check_circle_rounded; }
                        else if (isUserChoice) { statusColor = AppTheme.danger; statusIcon = Icons.cancel_rounded; }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.2))),
                          child: Row(children: [
                            Text(String.fromCharCode(65 + idx), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: statusColor.withOpacity(0.5))),
                            const SizedBox(width: 12),
                            Expanded(child: Text(opt, style: theme.textTheme.bodySmall?.copyWith(fontWeight: isUserChoice || isCorrectChoice ? FontWeight.w700 : FontWeight.w500))),
                            if (statusIcon != null) Icon(statusIcon, color: statusColor, size: 16),
                          ]),
                        );
                      }),
                    ] else ...[
                       Text('Your answer: ${a['userAnswer']}', style: theme.textTheme.bodySmall?.copyWith(color: correct ? theme.colorScheme.primary : AppTheme.danger, fontWeight: FontWeight.w700)),
                       const SizedBox(height: 4),
                       Text('Expected: ${a['correctAnswer']}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                    ],
                    if (a['explanation'] != null && a['explanation'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.earthyAccent.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.earthyAccent.withOpacity(0.1))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.lightbulb_outline_rounded, color: AppTheme.earthyAccent, size: 14),
                            const SizedBox(width: 8),
                            Text('LEARNING NOTE', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)),
                          ]),
                          const SizedBox(height: 8),
                          Text(a['explanation'], style: theme.textTheme.bodySmall?.copyWith(height: 1.5, fontStyle: FontStyle.italic)),
                        ])),
                    ],
                  ]),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 100 * i)).slideY(begin: 0.1, curve: Curves.easeOut);
        }),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() { _quizFinished = false; _quizStarted = false; }), child: const Text('Back to Setup'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: _generateQuiz, child: const Text('New Quiz'))),
        ]),
        const SizedBox(height: 48),
      ]),
    );
  }
}
