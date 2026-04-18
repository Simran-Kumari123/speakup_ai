import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/resume_service.dart';
import '../services/speech_service.dart';

class MockInterviewScreen extends StatefulWidget {
  final Map<String, dynamic>? initialResumeData;
  final String? initialResumeText;
  final List<Question>? preGeneratedQuestions;

  const MockInterviewScreen({
    super.key,
    this.initialResumeData,
    this.initialResumeText,
    this.preGeneratedQuestions,
  });

  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  int _step = 0;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? _resumeData;
  String? _resumeText;
  String _selectedCategory = 'HR';

  List<Question> _questions = [];
  int _currentQ = 0;
  List<InterviewQA> _answers = [];

  final FlutterTts _tts = AppState.tts;
  final _answerCtrl = TextEditingController();
  bool _speechReady = false;
  bool _isListening = false;
  String _liveText = '';
  bool _evaluating = false;
  Map<String, dynamic>? _currentResult;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    
    // Auto-load if Resume Mode is ON
    if (state.isResumeMode && state.activeResume != null) {
      _resumeData = state.activeResume!.analysis;
      _resumeText = state.activeResume!.text;
      _step = 1; // Skip picking, go to category selection

      // Auto-set category based on resume context
      if (_resumeData?['interviewCategories'] != null && (_resumeData!['interviewCategories'] as List).isNotEmpty) {
        _selectedCategory = _resumeData!['interviewCategories'][0];
      } else {
        // Fallback: If it's a technical role, default to Technical
        final role = state.activeResume!.roleTag?.toLowerCase() ?? '';
        if (role.contains('developer') || role.contains('engineer') || role.contains('tech')) {
          _selectedCategory = 'Technical';
        }
      }
    } else {
      _resumeData = widget.initialResumeData;
      _resumeText = widget.initialResumeText;
    }
    
    if (widget.preGeneratedQuestions != null) {
      _questions = widget.preGeneratedQuestions!;
      _step = 2;
    } else if (_resumeData != null) {
      _step = 1;
    }

    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final speechService = context.read<SpeechService>();
    _speechReady = await speechService.init(
      onError: (e) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
  }

  Future<void> _initTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
  }

  @override
  void dispose() {
    _tts.stop();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) {
        setState(() => _error = 'Could not read file.');
        return;
      }

      setState(() { _loading = true; _error = null; });
      final text = ResumeService.extractText(file.bytes!);
      final analysis = await ResumeService.analyze(text);

      if (!mounted) return;
      setState(() { 
        _resumeData = analysis; 
        _resumeText = text; // Save the text!
        _loading = false; 
        _step = 1; 
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _startInterview() async {
    setState(() { _loading = true; });
    final skills = (_resumeData?['skills'] as List?)?.join(', ') ?? '';
    final level = _resumeData?['experienceLevel'] ?? 'Fresher';

    final questions = await ResumeService.generateQuestions(
      resumeText: _resumeText,
      skills: skills, 
      experienceLevel: level, 
      category: _selectedCategory, 
      count: 5,
    );

    if (!mounted) return;
    setState(() {
      _questions = questions;
      _answers = [];
      _currentQ = 0;
      _currentResult = null;
      _loading = false;
      _step = 2;
    });

    if (_questions.isNotEmpty) {
      await _tts.speak(_questions[0].text);
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty || _evaluating) return;
    _answerCtrl.clear();

    setState(() { _evaluating = true; _currentResult = null; });

    final question = _questions[_currentQ].text;
    final p = context.read<AppState>().profile;
    final result = await AIFeedbackService.evaluateAnswer(
      question: question, answer: answer,
      personalityMode: p.personalityMode,
      difficulty: p.difficulty,
    );

    if (!mounted) return;
    final state = context.read<AppState>();
    state.addXP((result['xp'] as num).toInt());

    _answers.add(InterviewQA(
      question: question, answer: answer,
      score: (result['score'] as num).toDouble(),
      feedback: result['feedback'] ?? '',
      idealAnswer: result['suggestions']?.isNotEmpty == true ? result['suggestions'][0] : null,
    ));

    setState(() { _evaluating = false; _currentResult = result; });
  }

  void _nextQuestion() {
    if (_currentQ < _questions.length - 1) {
      setState(() { _currentQ++; _currentResult = null; });
      _tts.speak(_questions[_currentQ].text);
    } else {
      _generateReport();
    }
  }

  void _generateReport() {
    final overallScore = _answers.isEmpty ? 0.0 : _answers.map((a) => a.score).reduce((a, b) => a + b) / _answers.length;
    final session = InterviewSession(
      id: const Uuid().v4(),
      type: _selectedCategory.toLowerCase(),
      difficulty: _resumeData?['suggestedDifficulty'] ?? 'beginner',
      qaPairs: _answers,
      overallScore: overallScore,
      strengths: _currentResult?['strengths']?.cast<String>() ?? [],
      weaknesses: _currentResult?['mistakes']?.cast<String>() ?? [],
      resumeSkills: (_resumeData?['skills'] as List?)?.join(', '),
    );

    final state = context.read<AppState>();
    state.saveInterviewSession(session);
    state.addSession(PracticeSession(
      id: session.id, topic: 'Mock Interview: $_selectedCategory', type: 'Interview',
      score: overallScore, fluency: overallScore, grammar: overallScore, confidence: overallScore,
      xp: _answers.length * 20,
    ));
    state.incrementSessions();
    setState(() => _step = 3);
  }

  Future<void> _startVoice() async {
    final speechService = context.read<SpeechService>();
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    await speechService.listen(onResult: (text, isFinal) {
      if (mounted) setState(() => _liveText = text);
    });
  }

  Future<void> _stopVoice({bool send = false}) async {
    final speechService = context.read<SpeechService>();
    await speechService.stop();
    setState(() => _isListening = false);
    if (send && _liveText.trim().isNotEmpty) {
      _answerCtrl.text = _liveText.trim();
      _submitAnswer();
    }
  }

  @override

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mock Interview 🎯')),
      body: _loading ? _buildLoading() : [_buildUpload, _buildAnalysis, _buildInterview, _buildReport][_step](),
    );
  }

  Widget _buildLoading() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const CircularProgressIndicator(),
    const SizedBox(height: 16),
    Text('Processing...', style: Theme.of(context).textTheme.bodySmall),
  ]));

  Widget _buildUpload() {
    final theme = Theme.of(context);
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withOpacity(0.1), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2)),
          child: Icon(Icons.upload_file_rounded, size: 48, color: theme.colorScheme.primary)),
        const SizedBox(height: 24),
        Text('Upload Your Resume', style: theme.textTheme.displaySmall?.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text('AI will analyze your resume and generate\npersonalized interview questions.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        ElevatedButton.icon(onPressed: _pickResume, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('Choose PDF')),
        if (_error != null) 
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.error.withOpacity(0.1))),
            child: Row(
              children: [
                const Text('💡', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(_error!, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.error))),
                IconButton(onPressed: () => setState(() => _error = null), icon: const Icon(Icons.close, size: 14, color: Colors.grey)),
              ],
            ),
          ).animate().shake(),
      ]),
    ));
  }

  Widget _buildAnalysis() {
    final theme = Theme.of(context);
    final skills = List<String>.from(_resumeData?['skills'] ?? []);
    final categories = List<String>.from(_resumeData?['interviewCategories'] ?? ['HR', 'Technical', 'Behavioral']);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
            child: Text('PREPARATION', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
        ]),
        const SizedBox(height: 16),
        Text('Interview Strategy 🎯', style: theme.textTheme.displaySmall),
        const SizedBox(height: 8),
        Text('AI has customized this session based on your profile.', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        _infoCard('👤', 'Candidate', _resumeData?['name'] ?? 'Guest'),
        _infoCard('📊', 'Experience', _resumeData?['experienceLevel'] ?? 'Fresher'),
        const SizedBox(height: 32),
        Text('Skills Focus', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor.withOpacity(0.1))),
          child: Text(s, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
        )).toList()),
        const SizedBox(height: 32),
        Text('Select Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: categories.map((c) {
          final sel = _selectedCategory == c;
          return ChoiceChip(
            label: Text(c, style: theme.textTheme.bodySmall?.copyWith(fontWeight: sel ? FontWeight.w900 : FontWeight.w600, color: sel ? theme.colorScheme.onPrimary : theme.colorScheme.primary)),
            selected: sel, onSelected: (_) => setState(() => _selectedCategory = c),
            selectedColor: theme.colorScheme.primary, backgroundColor: theme.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
        }).toList()),
        const SizedBox(height: 48),
        SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _startInterview, child: const Text('Start Session Now →'))),
      ]),
    );
  }

  Widget _infoCard(String emoji, String label, String value) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 16),
        Text('$label: ', style: theme.textTheme.bodySmall),
        Expanded(child: Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary))),
      ]),
    );
  }

  Widget _buildInterview() {
    final theme = Theme.of(context);
    if (_questions.isEmpty) return Center(child: Text('No questions available.', style: theme.textTheme.bodyLarge));
    final q = _questions[_currentQ];
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 8), child: Row(children: [
        Text('Question ${_currentQ + 1} of ${_questions.length}', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
        const Spacer(),
        Consumer<AppState>(
          builder: (context, state, _) {
            if (!state.isResumeMode || state.activeResume == null) {
              return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(_selectedCategory.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)));
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.rocket_launch_rounded, size: 10, color: Colors.white),
                   const SizedBox(width: 4),
                   Text(
                     'CAREER MODE: ${state.activeResume!.roleTag?.toUpperCase() ?? "ACTIVE"}', 
                     style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 0.5)
                   ),
                ],
              ),
            );
          },
        ),
      ])),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (_currentQ + 1) / _questions.length, minHeight: 6, backgroundColor: theme.dividerColor.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary)))),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.psychology_rounded, color: theme.colorScheme.primary, size: 20)),
              const SizedBox(width: 12),
              Text('AI INTERVIEWER', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ]),
            const SizedBox(height: 20),
            Text(q.text, style: theme.textTheme.titleLarge?.copyWith(height: 1.4, fontWeight: FontWeight.w800)),
            if (q.hints.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('HINTS & KEYWORDS', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: q.hints.map((h) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.dividerColor.withOpacity(0.05))), child: Text(h, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w600)))).toList()),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        if (_isListening && _liveText.isNotEmpty) Container(width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.06), borderRadius: BorderRadius.circular(12)), child: Text(_liveText, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        if (_evaluating) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
        if (_currentResult != null) ...[ _buildResultCard(_currentResult!), const SizedBox(height: 16), SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _nextQuestion, child: Text(_currentQ < _questions.length - 1 ? 'Next Question →' : 'View Report 📊')))],
        const SizedBox(height: 80), // Offset for bottom bar
      ]))),
      if (_currentResult == null && !_evaluating) Container(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32), decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.05)))), child: Row(children: [
        GestureDetector(onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(), child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: _isListening ? theme.colorScheme.error : theme.colorScheme.primary, boxShadow: [BoxShadow(color: (_isListening ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.3), blurRadius: 15)]), child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 28))),
        const SizedBox(width: 12),
        Expanded(child: TextField(controller: _answerCtrl, style: theme.textTheme.bodyMedium, onSubmitted: (_) => _submitAnswer(), decoration: InputDecoration(hintText: _isListening ? 'Listening...' : 'Type your answer...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
        const SizedBox(width: 12),
        GestureDetector(onTap: _submitAnswer, child: Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]), boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12)]), child: const Icon(Icons.send_rounded, color: Colors.white, size: 24))),
      ])),
    ]);
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final theme = Theme.of(context);
    final score = (result['score'] as num).toDouble();
    final color = score >= 8 ? theme.colorScheme.primary : score >= 6 ? theme.colorScheme.primary : theme.colorScheme.error;
    return Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.12)), boxShadow: [BoxShadow(color: color.withOpacity(0.03), blurRadius: 20)]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('AI FEEDBACK', style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
        Text('${score.toStringAsFixed(1)}/10', style: theme.textTheme.displaySmall?.copyWith(color: color, fontSize: 28)),
      ]),
      const SizedBox(height: 20),
      _scoreRow('Fluency', (result['fluency'] as num?)?.toDouble() ?? 7.0, color),
      _scoreRow('Relevance', (result['relevance'] as num?)?.toDouble() ?? 7.0, color),
      const SizedBox(height: 20),
      Text(result['feedback'] as String? ?? '', style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontWeight: FontWeight.w500)),
      if (result['strengths'] != null && (result['strengths'] as List).isNotEmpty) ...[
        const SizedBox(height: 16),
        ...(result['strengths'] as List).map((s) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 16), const SizedBox(width: 10), Expanded(child: Text(s, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)))]))),
      ],
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('+${result['xp']} XP REWARDED ⭐', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900))),
    ]));
  }

  Widget _scoreRow(String label, double val, Color color) {
    final theme = Theme.of(context);
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: theme.textTheme.bodySmall)),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: val / 10, backgroundColor: theme.dividerColor.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(color), minHeight: 6))),
      const SizedBox(width: 12),
      Text(val.toStringAsFixed(1), style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900)),
    ]));
  }

  Widget _buildReport() {
    final theme = Theme.of(context);
    final overallScore = _answers.isEmpty ? 0.0 : _answers.map((a) => a.score).reduce((a, b) => a + b) / _answers.length;
    final color = overallScore >= 8 ? theme.colorScheme.primary : overallScore >= 6 ? theme.colorScheme.primary : theme.colorScheme.error;
    
    return SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Column(children: [
          Container(width: 130, height: 130, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2), width: 8)), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(overallScore.toStringAsFixed(1), style: theme.textTheme.displayMedium?.copyWith(color: color, fontSize: 42)),
            Text('TOTAL', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: color, fontSize: 10, letterSpacing: 1)),
          ]))),
          const SizedBox(height: 24),
          Text('Session Summary ✅', style: theme.textTheme.displaySmall),
          Text('${_answers.length} Questions Answered', style: theme.textTheme.bodySmall),
        ])),
        const SizedBox(height: 40),
        Text('Q&A Breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        ...List.generate(_answers.length, (i) {
          final qa = _answers[i];
          final qColor = qa.score >= 8 ? theme.colorScheme.primary : qa.score >= 6 ? theme.colorScheme.primary : theme.colorScheme.error;
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withOpacity(0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: qColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Text('Q${i+1}', style: theme.textTheme.bodySmall?.copyWith(color: qColor, fontWeight: FontWeight.w900, fontSize: 10))),
              const SizedBox(width: 12),
              Expanded(child: Text(qa.question, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(qa.score.toStringAsFixed(1), style: theme.textTheme.titleSmall?.copyWith(color: qColor, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Text(qa.feedback, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
          ]));
        }),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() { _step = 1; _answers.clear(); _currentQ = 0; _currentResult = null; }), child: const Text('Try Again'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => setState(() { _step = 0; _resumeData = null; _answers.clear(); }), child: const Text('New Resume'))),
        ]),
        const SizedBox(height: 40),
    ]));
  }
}
