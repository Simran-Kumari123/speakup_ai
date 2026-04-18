import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/speech_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'dart:ui';
import '../models/models.dart';

class ScenarioScreen extends StatefulWidget {
  const ScenarioScreen({super.key});
  @override
  State<ScenarioScreen> createState() => _ScenarioScreenState();
}

class _ScenarioScreenState extends State<ScenarioScreen> {
  int? _selectedScenario;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshScenarios();
    });
  }

  final _scenarios = [
    {'emoji': '🍔', 'title': 'Ordering Food', 'desc': 'Restaurant & Cafe interactions', 'color': Colors.orangeAccent,
      'prompts': ['Could I see the menu, please?', 'I\'d like to order a chicken burger and a soda.', 'How would you ask for the check?', 'Does this dish contain any nuts?']},
    {'emoji': '📞', 'title': 'Phone Conversation', 'desc': 'Booking & Customer Support', 'color': Colors.lightBlueAccent,
      'prompts': ['I\'d like to book a table for two at 7 PM.', 'Can you help me with my order status?', 'I\'m calling to reschedule my appointment.', 'How do you politely end a professional call?']},
    {'emoji': '👔', 'title': 'Job Interview', 'desc': 'Practice common interview questions', 'color': Colors.indigoAccent,
      'prompts': ['Why should we hire you?', 'What is your greatest achievement?', 'How do you handle pressure at work?', 'Describe a time you solved a difficult problem.']},
    {'emoji': '🛍️', 'title': 'Shopping', 'desc': 'Mall & Store role-play', 'color': Colors.pinkAccent,
      'prompts': ['Do you have this in a larger size?', 'Where is the fitting room?', 'I\'d like to return this item, please.', 'Is there a discount on this product?']},
    {'emoji': '🙋', 'title': 'Self Introduction', 'desc': 'Practice introducing yourself', 'color': AppTheme.primary,
      'prompts': ['Tell me about yourself.', 'What are your hobbies?', 'Describe your educational background.', 'What are your career goals?']},
    {'emoji': '✈️', 'title': 'Travel', 'desc': 'Travel-related English', 'color': Colors.teal,
      'prompts': ['How do you book a hotel?', 'Ask for directions to a famous landmark.', 'Order food at a restaurant abroad.', 'Describe your dream vacation.']},
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final List<Map<String, dynamic>> combinedScenarios = [
      ..._scenarios,
      ...state.dynamicScenarios,
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Scenario Practice 🎭'),
        actions: [
          IconButton(
            icon: state.isRefreshingScenarios 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
            onPressed: state.isRefreshingScenarios ? null : () => state.refreshScenarios(force: true),
            tooltip: 'Refresh Scenarios',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showHowItWorks(context, l),
          ),
        ],
      ),
      body: _selectedScenario == null 
          ? _buildScenarioList(combinedScenarios) 
          : _ScenarioPractice(
              scenario: combinedScenarios[_selectedScenario!],
              onBack: () => setState(() => _selectedScenario = null),
            ),
    );
  }

  void _showHowItWorks(BuildContext context, AppLocalizations l) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor.withAlpha(50), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text(l.howScenarioWorks, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
            const SizedBox(height: 20),
            _stepTile(context, Icons.ads_click_rounded, l.scenarioStep1Title, l.scenarioStep1Desc),
            _stepTile(context, Icons.psychology_rounded, l.scenarioStep2Title, l.scenarioStep2Desc),
            _stepTile(context, Icons.mic_external_on_rounded, l.scenarioStep3Title, l.scenarioStep3Desc),
            _stepTile(context, Icons.auto_fix_high_rounded, l.scenarioStep4Title, l.scenarioStep4Desc),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: const Text('Got it!'),
            )),
            const SizedBox(height: 12),
          ]),
        ),
      ),
    );
  }

  Widget _stepTile(BuildContext context, IconData icon, String title, String desc) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(desc, style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _buildScenarioList(List<Map<String, dynamic>> scenarios) {
    final theme = Theme.of(context);
    if (scenarios.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: scenarios.length,
      itemBuilder: (_, i) {
        final s = scenarios[i];
        
        Color sColor = Colors.grey;
        if (s['color'] is Color) {
          sColor = s['color'];
        } else if (s['color'] is String) {
          try {
            final hex = (s['color'] as String).replaceFirst('#', '');
            sColor = Color(int.parse('FF$hex', radix: 16));
          } catch (_) {}
        }

        return GestureDetector(
          onTap: () => setState(() => _selectedScenario = i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: sColor.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: sColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(s['emoji'] as String? ?? '🎭', style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['title'] as String? ?? 'Scenario', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(s['desc'] as String? ?? 'Practice your English skills.', style: theme.textTheme.bodySmall),
              ])),
              Icon(Icons.arrow_forward_ios_rounded, color: sColor, size: 16),
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

class _ScenarioPracticeState extends State<_ScenarioPractice> with WidgetsBindingObserver {
  final _ctrl = TextEditingController();
  bool _isListening = false;
  bool _processing = false;
  String _liveText = '';
  int _currentPrompt = 0;
  bool _isFinished = false;
  final FlutterTts _tts = AppState.tts;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _tts.stop();
      if (_isListening) _stopVoice();
    }
  }

  Future<void> _initTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
  }

  List<String> get _prompts => List<String>.from(widget.scenario['prompts'] ?? []);

  Future<void> _submit([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    setState(() { _processing = true; _result = null; });

    try {
      final p = context.read<AppState>().profile;
      final reply = await AIFeedbackService.respondToSpeech(
        userText: text, context: 'scenario',
        personalityMode: p.personalityMode,
        difficulty: p.difficulty,
      );
      final state = context.read<AppState>();
      state.addXP(reply.xp);
      state.addSession(PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: widget.scenario['title'] as String? ?? 'Unknown',
        type: 'Scenario',
        score: reply.score ?? 5.0,
        fluency: reply.fluency ?? reply.score ?? 5.0,
        grammar: reply.grammar ?? reply.score ?? 5.0,
        confidence: reply.confidence ?? reply.score ?? 5.0,
        xp: reply.xp,
      ));
      if (!mounted) return;
      setState(() { _processing = false; _result = {'feedback': reply.text, 'score': reply.score, 'xp': reply.xp, 'tip': reply.feedback}; });
      await _tts.speak(reply.text);
    } catch (e) {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _startVoice() async {
    final speechService = context.read<SpeechService>();
    bool ok = await speechService.init(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
    if (!ok) return;

    setState(() { _isListening = true; _liveText = ''; });
    await speechService.listen(
      onResult: (text, isFinal) {
        if (mounted) setState(() => _liveText = text);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> _stopVoice({bool send = false}) async {
    final speechService = context.read<SpeechService>();
    await speechService.stop();
    setState(() => _isListening = false);
    if (send && _liveText.trim().isNotEmpty) _submit(_liveText.trim());
  }

  void _finishScenario() {
    final state = context.read<AppState>();
    state.addXP(50);
    setState(() => _isFinished = true);
    _tts.speak("Excellent work! You have completed this scenario.");
  }

  @override
  void dispose() { 
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose(); 
    _tts.stop(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color color = Colors.grey;
    if (widget.scenario['color'] is Color) {
      color = widget.scenario['color'];
    } else if (widget.scenario['color'] is String) {
      try {
        final hex = (widget.scenario['color'] as String).replaceFirst('#', '');
        color = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    
    final l = AppLocalizations.of(context)!;
    if (_isFinished) return _buildSuccess(color);

    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        child: Row(children: [
          IconButton(icon: Icon(Icons.arrow_back_ios, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), size: 18), onPressed: widget.onBack),
          Text(widget.scenario['emoji'] as String? ?? '🎭', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(widget.scenario['title'] as String? ?? 'Practice', style: theme.textTheme.titleLarge),
        ]),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Prompt ${_currentPrompt + 1}/${_prompts.length}', style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text(_prompts.isNotEmpty ? _prompts[_currentPrompt] : 'Loading prompt...', key: ValueKey(_currentPrompt), style: theme.textTheme.titleMedium?.copyWith(height: 1.4, fontWeight: FontWeight.w700)).animate(key: ValueKey(_currentPrompt)).fadeIn().slideX(begin: 0.05),
          ]),
        ),
      ),

      const SizedBox(height: 16),

      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            if (_isListening && _liveText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
                child: Text(_liveText, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
              ),

            if (_processing)
              const Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()),

            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text('🤖 AI Feedback', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    if (_result!['score'] != null)
                      Text('${(_result!['score'] as double).toStringAsFixed(1)}/10', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 12),
                  Text(_result!['feedback'] as String? ?? '', style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontWeight: FontWeight.w500)),
                  if (_result!['tip'] != null && (_result!['tip'] as String).isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(_result!['tip'] as String, style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                  ],
                  const SizedBox(height: 8),
                  Text('+${_result!['xp']} XP ⭐', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900)),
                ]),
              ).animate().fadeIn().scale(begin: const Offset(0.98, 0.98)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => setState(() => _result = null),
                  child: const Text('Try Again'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  onPressed: () {
                    if (_currentPrompt == _prompts.length - 1) {
                      _finishScenario();
                    } else {
                      setState(() {
                        _currentPrompt++;
                        _result = null;
                      });
                    }
                  },
                  child: Text(_prompts.isNotEmpty && _currentPrompt == _prompts.length - 1 ? 'Finish & Collect ✨' : 'Next Prompt'),
                )),
              ]),
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ),

      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.05))),
        ),
        child: SafeArea(child: Row(children: [
          GestureDetector(
            onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: _isListening ? AppTheme.danger.withOpacity(0.15) : theme.inputDecorationTheme.fillColor,
                border: Border.all(color: _isListening ? AppTheme.danger : theme.dividerColor.withOpacity(0.1))),
              child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: _isListening ? AppTheme.danger : theme.colorScheme.primary, size: 20)),
          ),
          const SizedBox(width: 8),
          Expanded(child: TextField(
            controller: _ctrl,
            style: theme.textTheme.bodyMedium,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(hintText: _isListening ? '🎤 Listening...' : 'Type your message...', contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _submit(),
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary])),
              child: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary, size: 18)),
          ),
        ])),
      ),
    ]);
  }

  Widget _buildSuccess(Color color) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.12)),
            child: Text(widget.scenario['emoji'] as String? ?? '🎉', style: const TextStyle(fontSize: 56)),
          ).animate().scale(delay: 200.ms).then().shake(),
          const SizedBox(height: 32),
          Text('Scenario Complete! 🎉', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 12),
          Text('You successfully practiced "${widget.scenario['title']}" with AI coaching.', 
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Column(children: [
                Text('50', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.earthyAccent)),
                Text('Bonus XP', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(width: 32),
              Column(children: [
                Text('${_prompts.length}', style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
                Text('Prompts', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
          const SizedBox(height: 48),
          SizedBox(width: double.infinity, height: 60, child: ElevatedButton(
            onPressed: widget.onBack,
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: const Text('Back to Situations'),
          )),
        ]),
      ),
    );
  }
}
