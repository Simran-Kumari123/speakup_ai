import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../services/speech_service.dart';
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
  bool _speechReady = false;
  final FlutterTts _tts = AppState.tts;
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
  bool _evaluating = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final speechService = context.read<SpeechService>();
    _speechReady = await speechService.init(
      onError: (e) {
        setState(() => _isListening = false);
        if (e.errorMsg != 'error_no_match' && e.errorMsg != 'error_speech_timeout') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(SpeechService.getFriendlyError(e)),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && _isListening) {
          _stopVoice();
        }
      },
    );
  }

  Future<void> _initTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
  }

  Future<void> _generateTopic() async {
    setState(() { _loading = true; _topic = null; _round = 0; _rounds.clear(); _showResults = false; });
    try {
      final state = context.read<AppState>();
      final result = await AIFeedbackService.generateGDTopic(
        role: state.profile.targetRole,
        difficulty: state.profile.difficulty,
      );
      if (!mounted) return;
      setState(() { 
        _topic = {'topic': result, 'description': 'AI generated topic relevant to your ${state.profile.targetRole} career.'}; 
        _loading = false; 
      });
      await _tts.speak(result);
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
      final p = context.read<AppState>().profile;
      final result = await AIFeedbackService.respondToSpeech(
        userText: text,
        context: 'gd',
        personalityMode: p.personalityMode,
        difficulty: p.difficulty,
      );
      if (!mounted) return;
      final state = context.read<AppState>();
      state.addXP(result.xp);
      _rounds.add({
        'overallScore': result.score ?? 7.0,
        'feedback': result.text,
        'userResponse': text,
        'xp': result.xp,
        // Mocking GD-specific fields that ChatMessage doesn't have
        'clarity': 7.5,
        'argumentStrength': 7.0,
        'communication': 8.0,
      });
      setState(() { _round++; _evaluating = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _evaluating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('AI Coach is temporarily busy. Please try again.'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _startVoice() async {
    final speechService = context.read<SpeechService>();
    bool ok = await speechService.init(
      onError: (e) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
    if (!ok) return;
    setState(() { _isListening = true; _liveText = ''; });
    await speechService.listen(
      onResult: (words) {
        setState(() => _liveText = words);
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> _stopVoice({bool send = false}) async {
    final speechService = context.read<SpeechService>();
    await speechService.stop();
    setState(() => _isListening = false);
    if (send && _liveText.isNotEmpty) _submitResponse(_liveText);
  }

  @override
  void dispose() { _ctrl.dispose(); context.read<SpeechService>().stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('GD Simulator 🗣️')),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _showResults ? _buildPerformance() : _topic == null ? _buildStart() : _buildGD(),
    );
  }

  Widget _buildStart() {
    final theme = Theme.of(context);
    return Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withOpacity(0.1), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2)),
          child: Icon(Icons.groups_rounded, size: 48, color: theme.colorScheme.primary)),
        const SizedBox(height: 24),
        Text('Group Discussion', style: GoogleFonts.dmSans(color: theme.textTheme.displaySmall?.color, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('AI will provide a topic and evaluate your\ndiscussion skills in multiple rounds.', textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 14, height: 1.5)),
        const SizedBox(height: 28),
        ElevatedButton.icon(onPressed: _generateTopic, icon: const Icon(Icons.auto_awesome_rounded), label: const Text('AI Generated Topic')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _pickRandomTopic, icon: const Icon(Icons.shuffle_rounded), label: const Text('Random Topic')),
      ]),
    ));
  }

  Widget _buildGD() {
    final theme = Theme.of(context);
    return Column(children: [
      // Rounds and Topic Card
      Expanded(child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), children: [
        // Topic Card
        Container(
          margin: const EdgeInsets.only(top: 16, bottom: 16),
          width: double.infinity, padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.earthyAccent.withOpacity(0.08), theme.cardColor]),
            borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.earthyAccent.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('📋 Topic', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12)),
              const Spacer(),
              Text('Round ${_round + 1}/3', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 12)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _pickRandomTopic,
                child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.shuffle_rounded, color: theme.colorScheme.primary, size: 14)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(_topic?['topic'] ?? '', style: GoogleFonts.dmSans(color: theme.textTheme.titleMedium?.color, fontSize: 16, fontWeight: FontWeight.w800, height: 1.4)),
            if (_topic?['description'] != null) ...[
              const SizedBox(height: 6),
              Text(_topic!['description'], style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 13)),
            ],
          ]),
        ),

        ..._rounds.asMap().entries.map((e) {
          final r = e.value;
          final i = e.key;
          final score = (r['overallScore'] as num).toDouble();
          final color = score >= 8 ? theme.colorScheme.primary : score >= 6 ? theme.colorScheme.primary : theme.colorScheme.error;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Response (Round ${i + 1})', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(r['userResponse'] ?? '', style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color, fontSize: 14, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(children: [
                _scoreChip('Clarity', (r['clarity'] as num).toDouble(), context),
                const SizedBox(width: 8),
                _scoreChip('Argument', (r['argumentStrength'] as num).toDouble(), context),
                const SizedBox(width: 8),
                _scoreChip('Communication', (r['communication'] as num).toDouble(), context),
              ]),
              const SizedBox(height: 12),
              Text(r['feedback'] ?? '', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7), fontSize: 13, height: 1.5)),
              if (r['counterArgument'] != null && (r['counterArgument'] as String).isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.earthyAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💭 ', style: TextStyle(fontSize: 14)),
                    Expanded(child: Text(r['counterArgument'], style: GoogleFonts.dmSans(color: AppTheme.earthyText.withOpacity(0.7), fontSize: 12, height: 1.5, fontStyle: FontStyle.italic))),
                  ])),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Text('${score.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('+${r['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, fontSize: 12)),
              ]),
            ]),
          ).animate().fadeIn(delay: (i * 80).ms);
        }),

        if (_evaluating)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                const SizedBox(height: 12),
                Text('AI Advisor is evaluating your argument...', 
                  style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary.withOpacity(0.7))),
              ],
            ),
          ),

        if (_isListening && _liveText.isNotEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: Text(_liveText, style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500)),
          ),

        if (_round >= 3) ...[
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(
            onPressed: () {
              final avgScore = _rounds.isEmpty ? 0.0 : _rounds.map((r) => (r['overallScore'] as num).toDouble()).reduce((a, b) => a + b) / _rounds.length;
              final totalXP = _rounds.isEmpty ? 0 : _rounds.map((r) => (r['xp'] as num).toInt()).reduce((a, b) => a + b);
              
              final state = context.read<AppState>();
              state.addSession(PracticeSession(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                topic: 'GD: ${_topic?['topic'] ?? 'Group Discussion'}',
                type: 'GD',
                score: avgScore,
                fluency: avgScore,
                grammar: avgScore,
                confidence: avgScore,
                xp: totalXP + 50,
              ));
              state.addXP(50);
              state.incrementSessions();
              
              setState(() => _showResults = true);
            },
            icon: const Icon(Icons.assessment_rounded),
            label: const Text('View Performance Report 📊'),
          )),
        ],
        const SizedBox(height: 100),
      ])),

      // Input
      if (_round < 3 && !_evaluating)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1)))),
          child: SafeArea(child: Row(children: [
            GestureDetector(
              onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _isListening ? theme.colorScheme.error.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.05),
                  border: Border.all(color: _isListening ? theme.colorScheme.error : theme.colorScheme.primary.withOpacity(0.2))),
                child: Icon(_isListening ? Icons.stop : Icons.mic, color: _isListening ? theme.colorScheme.error : theme.colorScheme.primary, size: 20)),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _ctrl, style: theme.textTheme.bodyMedium,
              onSubmitted: (_) => _submitResponse(),
              decoration: InputDecoration(hintText: _isListening ? '🎤 Listening...' : 'Share your argument...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true))),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _submitResponse(),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
          ])),
        ),
    ]);
  }

  // ── Performance Report ─────────────────────────────────────
  Widget _buildPerformance() {
    final theme = Theme.of(context);
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

    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.08), theme.cardColor]),
            borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Text(passed ? '🎉' : '💪', style: const TextStyle(fontSize: 42)),
            const SizedBox(height: 8),
            Text('GD Performance', style: GoogleFonts.dmSans(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.w900, fontSize: 20)),
            Text('"${_topic?['topic'] ?? ''}"', textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 12, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            // Score ring
            SizedBox(width: 100, height: 100, child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: avgScore / 10, strokeWidth: 10, backgroundColor: theme.colorScheme.primary.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(color), strokeCap: StrokeCap.round),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${percentage.toStringAsFixed(0)}%', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900, fontSize: 24)),
                Text('Grade: $grade', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ])),
            const SizedBox(height: 16),
            Text('${avgScore.toStringAsFixed(1)}/10 Average', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text('+$totalXP XP earned ⭐', style: GoogleFonts.dmSans(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900)),
          ]),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        const SizedBox(height: 24),

        // Skill Breakdown
        Text('Skill Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
          child: Column(children: [
            _perfBar('Clarity', avgClarity, context),
            _perfBar('Argument Strength', avgArg, context),
            _perfBar('Communication', avgComm, context),
            _perfBar('Overall', avgScore, context),
          ]),
        ),
        const SizedBox(height: 20),

        // Round breakdown
        Text('Round Details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...List.generate(_rounds.length, (i) {
          final r = _rounds[i];
          final s = (r['overallScore'] as num).toDouble();
          final c = s >= 8 ? theme.colorScheme.primary : s >= 6 ? AppTheme.earthyAccent : AppTheme.danger;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: c.withOpacity(0.1)),
                child: Center(child: Text('${i + 1}', style: GoogleFonts.dmSans(color: c, fontWeight: FontWeight.w900)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Round ${i + 1}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text(r['feedback'] ?? '', style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ])),
              Text(s.toStringAsFixed(1), style: theme.textTheme.titleMedium?.copyWith(color: c, fontWeight: FontWeight.w900)),
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

  Widget _scoreChip(String label, double score, BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(6), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05))),
    child: Text('$label: ${score.toStringAsFixed(1)}', style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w800)),
  );

  Widget _perfBar(String label, double val, BuildContext context) {
    final theme = Theme.of(context);
    final color = val >= 8 ? theme.colorScheme.primary : val >= 6 ? AppTheme.earthyAccent : AppTheme.danger;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: val / 10, backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
        valueColor: AlwaysStoppedAnimation(color), minHeight: 8))),
      const SizedBox(width: 12),
      Text(val.toStringAsFixed(1), style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900)),
    ]));
  }
}
