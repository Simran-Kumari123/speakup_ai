import 'dart:async';
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

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});
  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _isListening = false;
  bool _processing = false;
  String _recognizedText = '';
  Map<String, dynamic>? _result;

  // Current prompt
  final _questionService = QuestionService();
  late List<dynamic> _questions;
  int _currentQ = 0;

  // Timer + WPM
  DateTime? _startTime;
  int _wpm = 0;

  @override
  void initState() {
    super.initState();
    _questions = _questionService.getQuestionsByType('speaking');
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopListening(autoSubmit: true); },
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
    if (!_speechReady) return;
    setState(() { _isListening = true; _recognizedText = ''; _result = null; });
    _startTime = DateTime.now();
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

  Future<void> _stopListening({bool autoSubmit = false}) async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (autoSubmit && _recognizedText.trim().isNotEmpty) _analyze();
  }

  Future<void> _analyze() async {
    if (_recognizedText.trim().isEmpty) return;
    setState(() => _processing = true);

    // Calc WPM
    final duration = DateTime.now().difference(_startTime ?? DateTime.now()).inSeconds;
    final wordCount = _recognizedText.trim().split(RegExp(r'\s+')).length;
    _wpm = duration > 0 ? (wordCount / duration * 60).round() : 0;

    try {
      final state = context.read<AppState>();
      final reply = await AIFeedbackService.respondToSpeech(
        userText: _recognizedText, context: 'pronunciation',
        personalityMode: state.profile.personalityMode,
      );
      state.addXP(reply.xp);
      state.addWordsSpoken(wordCount);
      state.incrementSessions();
      state.addPracticeMinutes(duration ~/ 60 + 1);

      setState(() {
        _processing = false;
        _result = {
          'feedback': reply.text,
          'score': reply.score ?? 7.0,
          'xp': reply.xp,
          'tip': reply.feedback,
          'wordCount': wordCount,
          'wpm': _wpm,
          'duration': duration,
        };
      });
      await _tts.speak(reply.text);
    } catch (_) {
      setState(() => _processing = false);
    }
  }

  @override
  void dispose() { _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final q = _questions.isNotEmpty ? _questions[_currentQ % _questions.length] : null;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Speaking Practice 🎤'),
        actions: [
          IconButton(icon: const Icon(Icons.skip_next_rounded), onPressed: () => setState(() {
            _currentQ = (_currentQ + 1) % _questions.length;
            _recognizedText = ''; _result = null;
          })),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Prompt
          if (q != null)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.secondary.withOpacity(0.3))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                    child: Text(q.category.toUpperCase(), style: GoogleFonts.dmSans(color: AppTheme.secondary, fontSize: 10, fontWeight: FontWeight.w700))),
                  const Spacer(),
                  Text('${_currentQ + 1}/${_questions.length}', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
                ]),
                const SizedBox(height: 10),
                Text(q.text, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
                const SizedBox(height: 8),
                Row(children: [
                  GestureDetector(
                    onTap: () => _tts.speak(q.text),
                    child: Row(children: [
                      const Icon(Icons.volume_up_rounded, color: AppTheme.accent, size: 16),
                      const SizedBox(width: 4),
                      Text('Listen', style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 12)),
                    ]),
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
              child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded,
                color: _isListening ? AppTheme.danger : AppTheme.primary, size: 40),
            ),
          ).animate(onPlay: (c) { if (_isListening) c.repeat(reverse: true); })
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 800.ms)),
          const SizedBox(height: 8),
          Center(child: Text(_isListening ? '🔴 Recording... Tap to stop' : 'Tap to start speaking',
            style: GoogleFonts.dmSans(color: _isListening ? AppTheme.danger : Colors.white38, fontSize: 13))),
          const SizedBox(height: 20),

          // Recognized text
          if (_recognizedText.isNotEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('📝 Your Speech', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(_recognizedText, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, height: 1.5)),
              ]),
            ),

          if (_processing) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),

          // Result
          if (_result != null) ...[
            const SizedBox(height: 16),
            // Score + WPM row
            Row(children: [
              _metricCard('Score', '${(_result!['score'] as double).toStringAsFixed(1)}/10',
                _result!['score'] >= 8 ? AppTheme.primary : _result!['score'] >= 6 ? AppTheme.accent : AppTheme.danger),
              const SizedBox(width: 10),
              _metricCard('WPM', '${_result!['wpm']}', AppTheme.secondary),
              const SizedBox(width: 10),
              _metricCard('Words', '${_result!['wordCount']}', AppTheme.accent),
            ]),
            const SizedBox(height: 16),
            // Feedback
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.07), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.primary.withOpacity(0.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🤖 AI Feedback', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(_result!['feedback'] as String, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, height: 1.6)),
                if (_result!['tip'] != null && (_result!['tip'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_result!['tip'] as String, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
                ],
                const SizedBox(height: 8),
                Text('+${_result!['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
              ]),
            ).animate().fadeIn(),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() { _recognizedText = ''; _result = null; }),
                child: const Text('Try Again'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => setState(() {
                _currentQ = (_currentQ + 1) % _questions.length; _recognizedText = ''; _result = null;
              }), child: const Text('Next Prompt'))),
            ]),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(children: [
      Text(value, style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
      Text(label, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
    ]),
  ));
}
