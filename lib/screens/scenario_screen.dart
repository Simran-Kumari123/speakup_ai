import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key});
  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  int? _selectedScenario;

  final _scenarios = [
    {'emoji': '🙋', 'title': 'Self Introduction', 'desc': 'Practice introducing yourself', 'color': AppTheme.primary,
      'prompts': ['Tell me about yourself.', 'What are your hobbies?', 'Describe your educational background.', 'What are your career goals?']},
    {'emoji': '💼', 'title': 'Workplace', 'desc': 'Office communication skills', 'color': AppTheme.secondary,
      'prompts': ['How do you write a professional email?', 'Describe how you handle a team conflict.', 'How do you give a presentation?', 'How do you ask for feedback from your manager?']},
    {'emoji': '🗣️', 'title': 'Daily Conversation', 'desc': 'Everyday English practice', 'color': AppTheme.accent,
      'prompts': ['How was your weekend?', 'Can you recommend a good restaurant?', 'What do you think about the weather today?', 'Tell me about a movie you watched recently.']},
    {'emoji': '✈️', 'title': 'Travel', 'desc': 'Travel-related English', 'color': Colors.orange,
      'prompts': ['How do you book a hotel?', 'Ask for directions to a famous landmark.', 'Order food at a restaurant abroad.', 'Describe your dream vacation.']},
    {'emoji': '🗣️', 'title': 'Group Discussion', 'desc': 'GD practice scenarios', 'color': Colors.purple,
      'prompts': ['Should social media be regulated?', 'Is AI a threat to jobs?', 'Is remote work better than office work?', 'Should education be free?']},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Scenario Practice 🎭')),
      body: _selectedScenario == null ? _buildScenarioList() : _ScenarioPractice(
        scenario: _scenarios[_selectedScenario!],
        onBack: () => setState(() => _selectedScenario = null),
      ),
    );
  }

  Widget _buildScenarioList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scenarios.length,
      itemBuilder: (_, i) {
        final s = _scenarios[i];
        return GestureDetector(
          onTap: () => setState(() => _selectedScenario = i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: (s['color'] as Color).withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: (s['color'] as Color).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(s['emoji'] as String, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['title'] as String, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                Text(s['desc'] as String, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, color: (s['color'] as Color), size: 16),
            ]),
          ),
        ).animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.1);
      },
    );
  }
}

class _ScenarioPractice extends StatefulWidget {
  final Map<String, dynamic> scenario;
  final VoidCallback onBack;
  const _ScenarioPractice({required this.scenario, required this.onBack});
  @override
  State<_ScenarioPractice> createState() => _ScenarioPracticeState();
}

class _ScenarioPracticeState extends State<_ScenarioPractice> {
  final _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _isListening = false;
  bool _processing = false;
  String _liveText = '';
  int _currentPrompt = 0;
  Map<String, dynamic>? _result;

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
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  List<String> get _prompts => List<String>.from(widget.scenario['prompts']);

  Future<void> _submit([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() { _processing = true; _result = null; });

    try {
      final reply = await AIFeedbackService.respondToSpeech(
        userText: text, context: 'chat',
        personalityMode: context.read<AppState>().profile.personalityMode,
      );
      final state = context.read<AppState>();
      state.addXP(reply.xp);
      state.incrementSessions();
      setState(() { _processing = false; _result = {'feedback': reply.text, 'score': reply.score, 'xp': reply.xp, 'tip': reply.feedback}; });
      await _tts.speak(reply.text);
    } catch (e) {
      setState(() => _processing = false);
    }
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
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> _stopVoice({bool send = false}) async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (send && _liveText.trim().isNotEmpty) _submit(_liveText.trim());
  }

  @override
  void dispose() { _ctrl.dispose(); _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.scenario['color'] as Color;
    return Column(children: [
      // Back button + title
      Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 18), onPressed: widget.onBack),
          Text(widget.scenario['emoji'] as String, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(widget.scenario['title'] as String, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
        ]),
      ),

      // Prompt card
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Prompt ${_currentPrompt + 1}/${_prompts.length}', style: GoogleFonts.dmSans(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_prompts[_currentPrompt], style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
          ]),
        ),
      ),

      const SizedBox(height: 16),

      // Result
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            if (_isListening && _liveText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
                child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
              ),

            if (_processing)
              const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primary)),

            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('🤖 AI Feedback', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    if (_result!['score'] != null)
                      Text('${(_result!['score'] as double).toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  Text(_result!['feedback'] as String, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, height: 1.6)),
                  if (_result!['tip'] != null && (_result!['tip'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_result!['tip'] as String, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13)),
                  ],
                  const SizedBox(height: 8),
                  Text('+${_result!['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => setState(() => _result = null),
                  child: const Text('Try Again'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () => setState(() {
                    _currentPrompt = (_currentPrompt + 1) % _prompts.length;
                    _result = null;
                  }),
                  child: const Text('Next Prompt'),
                )),
              ]),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ),

      // Input bar
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          border: Border(top: BorderSide(color: AppTheme.darkBorder)),
        ),
        child: SafeArea(child: Row(children: [
          GestureDetector(
            onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.darkSurface,
                border: Border.all(color: _isListening ? AppTheme.danger : AppTheme.darkBorder)),
              child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: _isListening ? AppTheme.danger : Colors.white54, size: 20)),
          ),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: _isListening ? '🎤 Listening...' : 'Type your response...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _submit(),
            child: Container(width: 44, height: 44,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
          ),
        ])),
      ),
    ]);
  }
}
