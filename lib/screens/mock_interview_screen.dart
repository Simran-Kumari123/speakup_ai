import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/resume_service.dart';
import '../theme/app_theme.dart';

class MockInterviewScreen extends StatefulWidget {
  const MockInterviewScreen({super.key});
  @override
  State<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends State<MockInterviewScreen> {
  // Steps: 0=upload, 1=analysis, 2=interview, 3=report
  int _step = 0;
  bool _loading = false;
  String? _error;

  // Resume data
  Map<String, dynamic>? _resumeData;
  String _selectedCategory = 'HR';

  // Interview data
  List<Map<String, dynamic>> _questions = [];
  int _currentQ = 0;
  List<InterviewQA> _answers = [];

  // Voice
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final _answerCtrl = TextEditingController();
  bool _speechReady = false;
  bool _isListening = false;
  String _liveText = '';
  bool _evaluating = false;
  Map<String, dynamic>? _currentResult;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.48);
  }

  Future<void> _pickResume() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
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
      setState(() { _resumeData = analysis; _loading = false; _step = 1; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _startInterview() async {
    setState(() { _loading = true; });
    final skills = (_resumeData?['skills'] as List?)?.join(', ') ?? '';
    final level = _resumeData?['experienceLevel'] ?? 'Fresher';

    final questions = await ResumeService.generateQuestions(
      skills: skills, experienceLevel: level, category: _selectedCategory, count: 5,
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
      await _tts.speak(_questions[0]['question'] ?? '');
    }
  }

  Future<void> _submitAnswer() async {
    final answer = _answerCtrl.text.trim();
    if (answer.isEmpty) return;
    _answerCtrl.clear();

    setState(() { _evaluating = true; _currentResult = null; });

    final question = _questions[_currentQ]['question'] ?? '';
    final result = await AIFeedbackService.evaluateWithIdeal(
      question: question, answer: answer,
      personalityMode: context.read<AppState>().profile.personalityMode,
    );

    if (!mounted) return;
    final state = context.read<AppState>();
    state.addXP((result['xp'] as num).toInt());

    _answers.add(InterviewQA(
      question: question, answer: answer,
      score: (result['score'] as num).toDouble(),
      feedback: result['feedback'] ?? '',
      idealAnswer: result['idealAnswer'],
    ));

    setState(() { _evaluating = false; _currentResult = result; });
  }

  void _nextQuestion() {
    if (_currentQ < _questions.length - 1) {
      setState(() { _currentQ++; _currentResult = null; });
      _tts.speak(_questions[_currentQ]['question'] ?? '');
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
    context.read<AppState>().saveInterviewSession(session);
    context.read<AppState>().incrementSessions();
    setState(() => _step = 3);
  }

  Future<void> _startVoice() async {
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveText = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _stopVoice(send: true);
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      partialResults: true, localeId: 'en_US',
    );
  }

  Future<void> _stopVoice({bool send = false}) async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (send && _liveText.trim().isNotEmpty) {
      _answerCtrl.text = _liveText.trim();
      _submitAnswer();
    }
  }

  @override
  void dispose() { _answerCtrl.dispose(); _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Mock Interview 🎯')),
      body: _loading ? _buildLoading() : [_buildUpload, _buildAnalysis, _buildInterview, _buildReport][_step](),
    );
  }

  Widget _buildLoading() => const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    CircularProgressIndicator(color: AppTheme.primary),
    SizedBox(height: 16),
    Text('Processing...', style: TextStyle(color: Colors.white54)),
  ]));

  Widget _buildUpload() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.1), border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2)),
        child: const Icon(Icons.upload_file_rounded, size: 48, color: AppTheme.primary)),
      const SizedBox(height: 24),
      Text('Upload Your Resume', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('AI will analyze your resume and generate\npersonalized interview questions.', textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 14, height: 1.5)),
      const SizedBox(height: 28),
      ElevatedButton.icon(onPressed: _pickResume, icon: const Icon(Icons.picture_as_pdf_rounded), label: const Text('Choose PDF')),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
        child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
    ]),
  ));

  Widget _buildAnalysis() {
    final skills = List<String>.from(_resumeData?['skills'] ?? []);
    final categories = List<String>.from(_resumeData?['interviewCategories'] ?? ['HR', 'Technical']);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resume Analysis ✅', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 16),
        _infoCard('👤', 'Name', _resumeData?['name'] ?? 'Not detected'),
        _infoCard('📊', 'Experience', _resumeData?['experienceLevel'] ?? 'Fresher'),
        _infoCard('🎓', 'Education', _resumeData?['education'] ?? 'Not detected'),
        _infoCard('💼', 'Recommended Role', _resumeData?['recommendedRole'] ?? 'N/A'),
        const SizedBox(height: 16),
        Text('Skills Detected', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => Chip(
          label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: AppTheme.primary.withOpacity(0.15),
          side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
        )).toList()),
        const SizedBox(height: 20),
        Text('Select Interview Category', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: categories.map((c) => ChoiceChip(
          label: Text(c), selected: _selectedCategory == c,
          selectedColor: AppTheme.primary.withOpacity(0.2),
          labelStyle: TextStyle(color: _selectedCategory == c ? AppTheme.primary : Colors.white54),
          onSelected: (_) => setState(() => _selectedCategory = c),
        )).toList()),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _startInterview,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Interview'),
        )),
      ]),
    );
  }

  Widget _infoCard(String emoji, String label, String value) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 12),
      Text('$label: ', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
      Expanded(child: Text(value, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );

  Widget _buildInterview() {
    if (_questions.isEmpty) return const Center(child: Text('No questions generated.', style: TextStyle(color: Colors.white54)));
    final q = _questions[_currentQ];
    return Column(children: [
      // Progress
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Text('Question ${_currentQ + 1}/${_questions.length}', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700)),
        const Spacer(),
        Text('$_selectedCategory', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
      ])),
      LinearProgressIndicator(value: (_currentQ + 1) / _questions.length, backgroundColor: AppTheme.darkSurface, valueColor: const AlwaysStoppedAnimation(AppTheme.primary)),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🤖 Interviewer', style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(q['question'] ?? '', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600, height: 1.5)),
              if (q['hints'] != null) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 6, children: (q['hints'] as List).map<Widget>((h) =>
                  Chip(label: Text(h.toString(), style: const TextStyle(fontSize: 10, color: Colors.white54)), backgroundColor: AppTheme.darkSurface, visualDensity: VisualDensity.compact),
                ).toList()),
              ],
            ]),
          ),
          const SizedBox(height: 16),

          if (_isListening && _liveText.isNotEmpty)
            Container(width: double.infinity, padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
              child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14))),

          if (_evaluating)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppTheme.accent))),

          if (_currentResult != null) ...[
            _buildResultCard(_currentResult!),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(_currentQ < _questions.length - 1 ? 'Next Question →' : 'View Report 📊'),
            )),
          ],
        ]),
      )),

      // Input bar
      if (_currentResult == null && !_evaluating)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          decoration: const BoxDecoration(color: AppTheme.darkCard, border: Border(top: BorderSide(color: AppTheme.darkBorder))),
          child: SafeArea(child: Row(children: [
            GestureDetector(
              onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.darkSurface,
                  border: Border.all(color: _isListening ? AppTheme.danger : AppTheme.darkBorder)),
                child: Icon(_isListening ? Icons.stop : Icons.mic, color: _isListening ? AppTheme.danger : Colors.white54, size: 20)),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _answerCtrl, style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (_) => _submitAnswer(),
              decoration: InputDecoration(hintText: _isListening ? '🎤 Listening...' : 'Type your answer...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true))),
            const SizedBox(width: 8),
            GestureDetector(onTap: _submitAnswer,
              child: Container(width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
          ])),
        ),
    ]);
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
    final score = (result['score'] as num).toDouble();
    final color = score >= 8 ? AppTheme.primary : score >= 6 ? AppTheme.accent : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('AI Evaluation', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700)),
          Text('${score.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 10),
        _scoreRow('Fluency', (result['fluency'] as num?)?.toDouble() ?? 7.0),
        _scoreRow('Relevance', (result['relevance'] as num?)?.toDouble() ?? 7.0),
        _scoreRow('Confidence', (result['confidence'] as num?)?.toDouble() ?? 7.0),
        const SizedBox(height: 10),
        Text(result['feedback'] as String? ?? '', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
        if (result['strengths'] != null && (result['strengths'] as List).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('✅ Strengths', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ...(result['strengths'] as List).map((s) => Padding(padding: const EdgeInsets.only(top: 2),
            child: Text('  • $s', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)))),
        ],
        if (result['mistakes'] != null && (result['mistakes'] as List).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('⚠️ Areas to Improve', style: GoogleFonts.dmSans(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 12)),
          ...(result['mistakes'] as List).map((m) => Padding(padding: const EdgeInsets.only(top: 2),
            child: Text('  • $m', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)))),
        ],
        if (result['idealAnswer'] != null && (result['idealAnswer'] as String).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 Ideal Answer', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(result['idealAnswer'] as String, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12, height: 1.5)),
            ])),
        ],
        const SizedBox(height: 8),
        Text('+${result['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _scoreRow(String label, double val) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
      Expanded(child: LinearProgressIndicator(value: val / 10, backgroundColor: AppTheme.darkSurface,
        valueColor: AlwaysStoppedAnimation(val >= 8 ? AppTheme.primary : val >= 6 ? AppTheme.accent : AppTheme.danger),
        borderRadius: BorderRadius.circular(4), minHeight: 6)),
      const SizedBox(width: 8),
      Text(val.toStringAsFixed(1), style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11)),
    ]),
  );

  Widget _buildReport() {
    final overallScore = _answers.isEmpty ? 0.0 : _answers.map((a) => a.score).reduce((a, b) => a + b) / _answers.length;
    final color = overallScore >= 8 ? AppTheme.primary : overallScore >= 6 ? AppTheme.accent : AppTheme.danger;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Column(children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15), border: Border.all(color: color, width: 3)),
            child: Center(child: Text(overallScore.toStringAsFixed(1), style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900, fontSize: 28)))),
          const SizedBox(height: 12),
          Text('Overall Score', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          Text('$_selectedCategory Interview • ${_answers.length} Questions', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
        ])),
        const SizedBox(height: 24),
        Text('Question Breakdown', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...List.generate(_answers.length, (i) {
          final qa = _answers[i];
          final qColor = qa.score >= 8 ? AppTheme.primary : qa.score >= 6 ? AppTheme.accent : AppTheme.danger;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Q${i + 1}', style: GoogleFonts.dmSans(color: qColor, fontWeight: FontWeight.w800)),
                const SizedBox(width: 8),
                Expanded(child: Text(qa.question, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
                Text('${qa.score.toStringAsFixed(1)}', style: GoogleFonts.dmSans(color: qColor, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              Text(qa.feedback, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
            ]),
          );
        }),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() { _step = 1; _answers.clear(); _currentQ = 0; _currentResult = null; }),
            child: const Text('Try Again'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => setState(() { _step = 0; _resumeData = null; _answers.clear(); }),
            child: const Text('New Resume'))),
        ]),
      ]),
    );
  }
}
