import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});
  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final _questionService = QuestionService();
  bool _speechReady = false;
  bool _isListening = false;
  bool _evaluating = false;
  String _liveText = '';

  // Filter
  String _category = 'hr';
  String _difficulty = 'beginner';
  late List<dynamic> _questions;
  int _currentQ = 0;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _initSpeech();
    _initTts();
  }

  void _loadQuestions() {
    _questions = _questionService.getQuestionsByCategory(_category)
        .where((q) => q.difficulty == _difficulty)
        .toList();
    if (_questions.isEmpty) {
      _questions = _questionService.getQuestionsByCategory(_category);
    }
    _currentQ = 0;
    _result = null;
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

  Future<void> _submit([String? override]) async {
    final answer = (override ?? _ctrl.text).trim();
    if (answer.isEmpty || _questions.isEmpty) return;
    _ctrl.clear();

    setState(() { _evaluating = true; _result = null; });
    final question = _questions[_currentQ % _questions.length].text;
    final state = context.read<AppState>();

    try {
      final result = await AIFeedbackService.evaluateWithIdeal(
        question: question, answer: answer, personalityMode: state.profile.personalityMode,
      );
      if (!mounted) return;
      state.addXP((result['xp'] as num).toInt());
      state.addWordsSpoken(answer.split(' ').length);
      state.incrementSessions();
      setState(() { _evaluating = false; _result = result; });
      await _tts.speak(result['feedback'] ?? '');
    } catch (_) {
      setState(() => _evaluating = false);
    }
  }

  Future<void> _startVoice() async {
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveText = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) _stopVoice(send: true);
      },
      listenFor: const Duration(seconds: 60), pauseFor: const Duration(seconds: 4),
      partialResults: true, localeId: 'en_US',
    );
  }

  Future<void> _stopVoice({bool send = false}) async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (send && _liveText.isNotEmpty) _submit(_liveText);
  }

  @override
  void dispose() { _ctrl.dispose(); _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = _questions.isNotEmpty ? _questions[_currentQ % _questions.length] : null;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Interview Practice 💼')),
      body: Column(children: [
        // Filters
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(children: [
            _filterChip('HR', 'hr'), _filterChip('Technical', 'technical'),
            _filterChip('Behavioral', 'behavioral'),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.tune, color: Colors.white54, size: 18),
              color: AppTheme.darkCard,
              onSelected: (d) => setState(() { _difficulty = d; _loadQuestions(); }),
              itemBuilder: (_) => ['beginner', 'intermediate', 'advanced'].map((d) =>
                PopupMenuItem(value: d, child: Text(d[0].toUpperCase() + d.substring(1),
                  style: TextStyle(color: _difficulty == d ? AppTheme.primary : Colors.white)))).toList(),
            ),
          ]),
        ),

        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Question
            if (q != null)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('🤵 Interviewer', style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('Q${_currentQ + 1}', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
                  ]),
                  const SizedBox(height: 10),
                  Text(q.text, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
                  if (q.hints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: q.hints.map<Widget>((h) =>
                      Chip(label: Text(h, style: const TextStyle(fontSize: 10, color: Colors.white54)), backgroundColor: AppTheme.darkSurface, visualDensity: VisualDensity.compact),
                    ).toList()),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _tts.speak(q.text),
                    child: Row(children: [
                      const Icon(Icons.volume_up_rounded, color: AppTheme.accent, size: 16),
                      const SizedBox(width: 4),
                      Text('Listen', style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 12)),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 16),

            if (_isListening && _liveText.isNotEmpty)
              Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13))),

            if (_evaluating)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppTheme.accent))),

            // Result
            if (_result != null) ...[
              _buildResult(_result!),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => setState(() => _result = null),
                  child: const Text('Try Again'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () => setState(() { _currentQ++; _result = null; }),
                  child: const Text('Next Question'))),
              ]),
            ],
            const SizedBox(height: 100),
          ]),
        )),

        // Input bar
        if (_result == null && !_evaluating)
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
              Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(hintText: _isListening ? '🎤 Listening...' : 'Type your answer...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true))),
              const SizedBox(width: 8),
              GestureDetector(onTap: () => _submit(),
                child: Container(width: 44, height: 44,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.primary])),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
            ])),
          ),
      ]),
    );
  }

  Widget _filterChip(String label, String cat) {
    final selected = _category == cat;
    return GestureDetector(
      onTap: () => setState(() { _category = cat; _loadQuestions(); }),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withOpacity(0.12) : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? AppTheme.accent : AppTheme.darkBorder)),
        child: Text(label, style: GoogleFonts.dmSans(color: selected ? AppTheme.accent : Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildResult(Map<String, dynamic> r) {
    final score = (r['score'] as num).toDouble();
    final color = score >= 8 ? AppTheme.primary : score >= 6 ? AppTheme.accent : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('AI Evaluation', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text('${score.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 10),
        _bar('Fluency', (r['fluency'] as num?)?.toDouble() ?? 7),
        _bar('Relevance', (r['relevance'] as num?)?.toDouble() ?? 7),
        _bar('Confidence', (r['confidence'] as num?)?.toDouble() ?? 7),
        const SizedBox(height: 10),
        Text(r['feedback'] ?? '', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
        if (r['strengths'] != null && (r['strengths'] as List).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('✅ Strengths', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ...(r['strengths'] as List).map((s) => Text('  • $s', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
        ],
        if (r['mistakes'] != null && (r['mistakes'] as List).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('⚠️ Mistakes', style: GoogleFonts.dmSans(color: AppTheme.danger, fontWeight: FontWeight.w700, fontSize: 12)),
          ...(r['mistakes'] as List).map((m) => Text('  • $m', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
        ],
        if (r['idealAnswer'] != null && (r['idealAnswer'] as String).isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 Ideal Answer', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(r['idealAnswer'], style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 12, height: 1.5)),
            ])),
        ],
        const SizedBox(height: 8),
        Text('+${r['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
      ]),
    ).animate().fadeIn();
  }

  Widget _bar(String label, double val) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
    SizedBox(width: 90, child: Text(label, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
    Expanded(child: LinearProgressIndicator(value: val / 10, backgroundColor: AppTheme.darkSurface,
      valueColor: AlwaysStoppedAnimation(val >= 8 ? AppTheme.primary : val >= 6 ? AppTheme.accent : AppTheme.danger),
      borderRadius: BorderRadius.circular(4), minHeight: 6)),
    const SizedBox(width: 8),
    Text(val.toStringAsFixed(1), style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11)),
  ]));
}
