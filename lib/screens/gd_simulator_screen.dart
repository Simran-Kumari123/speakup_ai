import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

class GDSimulatorScreen extends StatefulWidget {
  const GDSimulatorScreen({super.key});
  @override
  State<GDSimulatorScreen> createState() => _GDSimulatorScreenState();
}

class _GDSimulatorScreenState extends State<GDSimulatorScreen> {
  bool _loading = false;
  Map<String, dynamic>? _topic;
  int _round = 0;
  final List<Map<String, dynamic>> _rounds = [];
  bool _showResults = false;

  // Built-in random topics pool
  static final _topicsPool = [
    {'topic': 'Is social media more harmful than helpful?', 'description': 'Discuss the impact of social media on modern society.'},
    {'topic': 'Should artificial intelligence replace humans in jobs?', 'description': 'Debate the role of AI in the workforce.'},
    {'topic': 'Is remote work better than office work?', 'description': 'Compare the pros and cons of working from home vs office.'},
    {'topic': 'Should education be completely free?', 'description': 'Discuss the feasibility of free education for all.'},
    {'topic': 'Are electric vehicles the future of transportation?', 'description': 'Evaluate the impact of EVs on environment and economy.'},
    {'topic': 'Is technology making us less social?', 'description': 'Debate whether technology helps or hinders human connections.'},
    {'topic': 'Should there be stricter regulations on fast food?', 'description': 'Discuss government role in controlling unhealthy eating.'},
    {'topic': 'Is climate change the biggest threat to humanity?', 'description': 'Evaluate the urgency of climate action.'},
    {'topic': 'Should coding be a mandatory subject in schools?', 'description': 'Discuss the importance of programming education.'},
    {'topic': 'Are startups better than corporate jobs?', 'description': 'Compare career paths in startups vs established companies.'},
    {'topic': 'Is work-life balance a myth?', 'description': 'Discuss whether achieving true balance is possible.'},
    {'topic': 'Should social media influencers be regulated?', 'description': 'Debate accountability of online influencers.'},
    {'topic': 'Is online learning as effective as classroom learning?', 'description': 'Compare the quality of online vs traditional education.'},
    {'topic': 'Should plastic be completely banned?', 'description': 'Discuss the environmental impact of plastic usage.'},
    {'topic': 'Is space exploration worth the investment?', 'description': 'Debate funding priorities: space vs earth problems.'},
  ];

  // Input
  final _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _isListening = false;
  String _liveText = '';
  bool _evaluating = false;

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
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _generateTopic() async {
    setState(() { _loading = true; _topic = null; _round = 0; _rounds.clear(); _showResults = false; });
    try {
      final topic = await AIFeedbackService.generateGDTopic();
      if (!mounted) return;
      setState(() { _topic = topic; _loading = false; });
      await _tts.speak(topic['topic'] ?? '');
    } catch (_) {
      // Use random local topic as fallback
      final random = Random();
      final fallback = _topicsPool[random.nextInt(_topicsPool.length)];
      if (!mounted) return;
      setState(() { _topic = fallback; _loading = false; });
      await _tts.speak(fallback['topic'] ?? '');
    }
  }

  void _pickRandomTopic() {
    final random = Random();
    final fallback = _topicsPool[random.nextInt(_topicsPool.length)];
    setState(() { _topic = fallback; _round = 0; _rounds.clear(); _showResults = false; });
    _tts.speak(fallback['topic'] ?? '');
  }

  Future<void> _submitResponse([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() { _evaluating = true; });

    try {
      final result = await AIFeedbackService.evaluateGD(topic: _topic?['topic'] ?? '', response: text);
      if (!mounted) return;
      final state = context.read<AppState>();
      state.addXP((result['xp'] as num).toInt());
      _rounds.add({...result, 'userResponse': text});
      setState(() { _round++; _evaluating = false; });
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
    if (send && _liveText.isNotEmpty) _submitResponse(_liveText);
  }

  @override
  void dispose() { _ctrl.dispose(); _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('GD Simulator 🗣️')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _showResults ? _buildPerformance() : _topic == null ? _buildStart() : _buildGD(),
    );
  }

  Widget _buildStart() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.purple.withOpacity(0.12), border: Border.all(color: Colors.purple.withOpacity(0.3), width: 2)),
        child: const Icon(Icons.groups_rounded, size: 48, color: Colors.purple)),
      const SizedBox(height: 24),
      Text('Group Discussion', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('AI will provide a topic and evaluate your\ndiscussion skills in multiple rounds.', textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 14, height: 1.5)),
      const SizedBox(height: 28),
      ElevatedButton.icon(onPressed: _generateTopic, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('AI Generated Topic')),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: _pickRandomTopic, icon: const Icon(Icons.shuffle_rounded), label: const Text('Random Topic')),
    ]),
  ));

  Widget _buildGD() {
    return Column(children: [
      // Topic Card
      Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.12), AppTheme.darkCard]),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.withOpacity(0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('📋 Topic', style: GoogleFonts.dmSans(color: Colors.purple, fontWeight: FontWeight.w700, fontSize: 12)),
              const Spacer(),
              Text('Round ${_round + 1}/3', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickRandomTopic,
                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.purple.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.shuffle_rounded, color: Colors.purple, size: 14)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(_topic?['topic'] ?? '', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, height: 1.4)),
            if (_topic?['description'] != null) ...[
              const SizedBox(height: 6),
              Text(_topic!['description'], style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
            ],
          ]),
        ),
      ),

      // Rounds
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        ..._rounds.asMap().entries.map((e) {
          final r = e.value;
          final i = e.key;
          final score = (r['overallScore'] as num).toDouble();
          final color = score >= 8 ? AppTheme.primary : score >= 6 ? AppTheme.accent : AppTheme.danger;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Response (Round ${i + 1})', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(r['userResponse'] ?? '', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
              Row(children: [
                _scoreChip('Clarity', (r['clarity'] as num).toDouble()),
                const SizedBox(width: 8),
                _scoreChip('Argument', (r['argumentStrength'] as num).toDouble()),
                const SizedBox(width: 8),
                _scoreChip('Communication', (r['communication'] as num).toDouble()),
              ]),
              const SizedBox(height: 8),
              Text(r['feedback'] ?? '', style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12, height: 1.5)),
              if (r['counterArgument'] != null && (r['counterArgument'] as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💭 ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(r['counterArgument'], style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, height: 1.4))),
                  ])),
              ],
              const SizedBox(height: 6),
              Row(children: [
                Text('${score.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('+${r['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ]),
          ).animate().fadeIn(delay: (i * 80).ms);
        }),

        if (_evaluating)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: Colors.purple))),

        if (_isListening && _liveText.isNotEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
          ),

        if (_round >= 3) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () => setState(() => _showResults = true),
            icon: const Icon(Icons.assessment_rounded),
            label: const Text('View Performance Report 📊'),
          )),
        ],
        const SizedBox(height: 100),
      ])),

      // Input
      if (_round < 3 && !_evaluating)
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
            Expanded(child: TextField(controller: _ctrl, style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (_) => _submitResponse(),
              decoration: InputDecoration(hintText: _isListening ? '🎤 Listening...' : 'Share your argument...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true))),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _submitResponse(),
              child: Container(width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Colors.purple, AppTheme.secondary])),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
          ])),
        ),
    ]);
  }

  // ── Performance Report ─────────────────────────────────────
  Widget _buildPerformance() {
    if (_rounds.isEmpty) return const SizedBox();
    final avgScore = _rounds.map((r) => (r['overallScore'] as num).toDouble()).reduce((a, b) => a + b) / _rounds.length;
    final avgClarity = _rounds.map((r) => (r['clarity'] as num).toDouble()).reduce((a, b) => a + b) / _rounds.length;
    final avgArg = _rounds.map((r) => (r['argumentStrength'] as num).toDouble()).reduce((a, b) => a + b) / _rounds.length;
    final avgComm = _rounds.map((r) => (r['communication'] as num).toDouble()).reduce((a, b) => a + b) / _rounds.length;
    final totalXP = _rounds.map((r) => (r['xp'] as num).toInt()).reduce((a, b) => a + b);
    final percentage = (avgScore / 10 * 100);
    final grade = percentage >= 90 ? 'A+' : percentage >= 80 ? 'A' : percentage >= 70 ? 'B' : percentage >= 60 ? 'C' : 'D';
    final passed = percentage >= 60;
    final color = passed ? AppTheme.primary : AppTheme.danger;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), AppTheme.darkCard]),
            borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
          child: Column(children: [
            Text(passed ? '🎉' : '💪', style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text('GD Performance', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            Text('"${_topic?['topic'] ?? ''}"', textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 16),
            // Score ring
            SizedBox(width: 90, height: 90, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: avgScore / 10, strokeWidth: 8, backgroundColor: AppTheme.darkSurface, valueColor: AlwaysStoppedAnimation(color)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${percentage.toStringAsFixed(0)}%', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
                Text('Grade: $grade', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10)),
              ]),
            ])),
            const SizedBox(height: 12),
            Text('${avgScore.toStringAsFixed(1)}/10 Average', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
            Text('+$totalXP XP earned ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ]),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 20),

        // Skill Breakdown
        Text('Skill Breakdown', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
          child: Column(children: [
            _perfBar('Clarity', avgClarity),
            _perfBar('Argument Strength', avgArg),
            _perfBar('Communication', avgComm),
            _perfBar('Overall', avgScore),
          ]),
        ),
        const SizedBox(height: 20),

        // Round breakdown
        Text('Round Details', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...List.generate(_rounds.length, (i) {
          final r = _rounds[i];
          final s = (r['overallScore'] as num).toDouble();
          final c = s >= 8 ? AppTheme.primary : s >= 6 ? AppTheme.accent : AppTheme.danger;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.12)),
                child: Center(child: Text('${i + 1}', style: GoogleFonts.dmSans(color: c, fontWeight: FontWeight.w800)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Round ${i + 1}', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(r['feedback'] ?? '', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Text('${s.toStringAsFixed(1)}', style: GoogleFonts.dmSans(color: c, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          );
        }),
        const SizedBox(height: 20),

        Row(children: [
          Expanded(child: OutlinedButton(onPressed: _pickRandomTopic, child: const Text('New Topic'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: _generateTopic, child: const Text('AI Topic'))),
        ]),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _scoreChip(String label, double score) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(6)),
    child: Text('$label: ${score.toStringAsFixed(1)}', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  Widget _perfBar(String label, double val) {
    final color = val >= 8 ? AppTheme.primary : val >= 6 ? AppTheme.accent : AppTheme.danger;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12))),
      Expanded(child: LinearProgressIndicator(value: val / 10, backgroundColor: AppTheme.darkSurface,
        valueColor: AlwaysStoppedAnimation(color), borderRadius: BorderRadius.circular(4), minHeight: 8)),
      const SizedBox(width: 10),
      Text('${val.toStringAsFixed(1)}', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700)),
    ]));
  }
}
