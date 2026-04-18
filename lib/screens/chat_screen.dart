import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/speech_service.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl       = TextEditingController();
  final _scroll     = ScrollController();
  final FlutterTts   _tts    = AppState.tts;

  bool _speechReady = false;
  bool _isListening = false;
  bool _loading     = false;
  String _liveText  = '';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msgs = context.read<AppState>().chatMessages;
      if (msgs.isEmpty) _addWelcome();
    });
  }

  Future<void> _initSpeech() async {
    final speechService = context.read<SpeechService>();
    _speechReady = await speechService.init(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _isListening = false); },
    );
  }

  Future<void> _initTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
  }

  void _addWelcome() {
    final state = context.read<AppState>();
    state.addMessage(ChatMessage(
      id: DateTime.now().toIso8601String(),
      text: 'Hi ${state.profile.name}! 👋 I\'m your AI English Coach. You can type or speak — I\'ll help with grammar, fluency, and vocabulary. Let\'s practice! 🚀',
      sender: MsgSender.ai, type: MsgType.text,
    ));
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _ctrl.text).trim();
    if (text.isEmpty) return;
    _ctrl.clear();

    final state = context.read<AppState>();
    final personalityMode = state.profile.personalityMode;

    state.addMessage(ChatMessage(id: DateTime.now().toIso8601String(), text: text, sender: MsgSender.user));
    state.addWordsSpoken(text.split(' ').length);
    setState(() => _loading = true);
    _scrollDown();

    try {
      final reply = await AIFeedbackService.respondToSpeech(
        userText: text, context: 'chat', personalityMode: personalityMode,
        difficulty: state.profile.difficulty,
      );
      if (!mounted) return;
      state.addMessage(reply);
      state.addXP(reply.xp);
      state.incrementSessions();
      await _tts.speak(reply.text);
    } catch (e) {
      if (mounted) {
        state.addMessage(ChatMessage(id: DateTime.now().toIso8601String(),
          text: '⚠️ Could not get AI feedback. Please try again.', sender: MsgSender.ai));
      }
    }

    if (mounted) setState(() => _loading = false);
    _scrollDown();
  }

  Future<void> _startVoice() async {
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    final speechService = context.read<SpeechService>();
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

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); context.read<SpeechService>().stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.chatMessages;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Chat Coach 💬'),
        actions: [
          GestureDetector(
            onTap: () => _showPersonalityPicker(context, state),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3)),
              ),
              child: Text(
                '${_personalityEmoji(state.profile.personalityMode)} ${state.profile.personalityMode[0].toUpperCase()}${state.profile.personalityMode.substring(1)}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 10),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => state.clearChat()),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scroll, padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) => _buildMsg(messages[i], i),
        )),

        if (_isListening && _liveText.isNotEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.mic, color: AppTheme.danger, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_liveText, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
            ]),
          ),

        if (_loading) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)),

        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.05),
            border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.1))),
          ),
          child: SafeArea(child: Row(children: [
            GestureDetector(
              onTap: () => _isListening ? context.read<SpeechService>().stop() : _startVoice(),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _isListening ? AppTheme.danger.withOpacity(0.15) : theme.inputDecorationTheme.fillColor,
                  border: Border.all(color: _isListening ? AppTheme.danger : theme.dividerColor.withOpacity(0.1))),
                child: Icon(_isListening ? Icons.stop : Icons.mic, color: _isListening ? AppTheme.danger : theme.colorScheme.primary, size: 20)),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _ctrl, style: theme.textTheme.bodyMedium,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: _isListening ? '🎤 Listening...' : 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true),
            )),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _send(),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                ),
                child: Icon(Icons.send_rounded, color: theme.colorScheme.onPrimary, size: 18))),
          ])),
        ),
      ]),
    );
  }

  Widget _buildMsg(ChatMessage msg, int index) {
    final isUser = msg.sender == MsgSender.user;
    final theme = Theme.of(context);
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary.withOpacity(0.12) : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20)),
          border: Border.all(color: isUser ? theme.colorScheme.primary.withOpacity(0.1) : theme.dividerColor.withOpacity(0.1)),
          boxShadow: [
            if (!isUser) BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(msg.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontWeight: isUser ? FontWeight.w600 : FontWeight.w500))),
              if (!isUser && context.read<AppState>().profile.language != 'none')
                GestureDetector(
                  onTap: () => context.read<AppState>().translateMessage(msg.id),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Icon(Icons.translate_rounded, color: theme.colorScheme.primary.withOpacity(0.6), size: 16),
                  ),
                ),
            ],
          ),
          if (msg.translatedText != null && msg.translatedText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TRANSLATION', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(msg.translatedText!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
          if (msg.feedback != null && msg.feedback!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Text(msg.feedback!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            ),
          ],
          if (msg.score != null || msg.xp > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (msg.score != null) Text('${msg.score!.toStringAsFixed(1)}/10', style: theme.textTheme.bodySmall?.copyWith(
                color: msg.score! >= 8 ? theme.colorScheme.primary : msg.score! >= 6 ? theme.colorScheme.primary : theme.colorScheme.error,
                fontWeight: FontWeight.w900, fontSize: 11)),
              const Spacer(),
              if (msg.xp > 0) Text('+${msg.xp} XP ⭐', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 10)),
            ]),
          ],
        ]),
      ),
    ).animate().fadeIn(delay: (50).ms).slideX(begin: isUser ? 0.05 : -0.05);
  }

  String _personalityEmoji(String mode) =>
    {'friendly': '😊', 'strict': '👨‍🏫', 'hr': '👔', 'debate': '🤺'}[mode] ?? '🤖';

  void _showPersonalityPicker(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    showModalBottomSheet(context: context, backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text('AI Personality', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ...AIFeedbackService.personalityDescriptions.entries.map((e) {
            final mode = e.key;
            final selected = state.profile.personalityMode == mode;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(_personalityEmoji(mode), style: const TextStyle(fontSize: 24)),
              title: Text('${mode[0].toUpperCase()}${mode.substring(1)} Coach',
                style: theme.textTheme.titleSmall?.copyWith(color: selected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color, fontWeight: selected ? FontWeight.w900 : FontWeight.w600)),
              subtitle: Text(e.value, style: theme.textTheme.bodySmall),
              trailing: selected ? Icon(Icons.check_circle, color: theme.colorScheme.primary) : null,
              onTap: () { state.setPersonalityMode(mode); Navigator.pop(context); },
            );
          }),
          const SizedBox(height: 16),
        ]),
      ),
      ),
    );
  }
}
