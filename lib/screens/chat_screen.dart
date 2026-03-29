import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final SpeechToText _speech = SpeechToText();
  final FlutterTts   _tts    = FlutterTts();

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
    _speechReady = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') setState(() => _isListening = false); },
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
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
      );
      state.addMessage(reply);
      state.addXP(reply.xp);
      state.incrementSessions();
      await _tts.speak(reply.text);
    } catch (e) {
      state.addMessage(ChatMessage(id: DateTime.now().toIso8601String(),
        text: '⚠️ Could not get AI feedback. Please try again.', sender: MsgSender.ai));
    }

    setState(() => _loading = false);
    _scrollDown();
  }

  Future<void> _startVoice() async {
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveText = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _speech.stop();
          setState(() => _isListening = false);
          _send(r.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true, localeId: 'en_US',
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
  void dispose() { _ctrl.dispose(); _scroll.dispose(); _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.chatMessages;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('AI Chat Coach 💬'),
        actions: [
          // Personality mode indicator
          GestureDetector(
            onTap: () => _showPersonalityPicker(context, state),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.secondary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
              ),
              child: Text(
                '${_personalityEmoji(state.profile.personalityMode)} ${state.profile.personalityMode[0].toUpperCase()}${state.profile.personalityMode.substring(1)}',
                style: GoogleFonts.dmSans(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => state.clearChat()),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(child: ListView.builder(
          controller: _scroll, padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (_, i) => _buildMsg(messages[i], i),
        )),

        // Live speech text
        if (_isListening && _liveText.isNotEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.danger.withOpacity(0.2))),
            child: Row(children: [
              const Icon(Icons.mic, color: AppTheme.danger, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13))),
            ]),
          ),

        if (_loading) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2)),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(color: AppTheme.darkCard, border: Border(top: BorderSide(color: AppTheme.darkBorder))),
          child: SafeArea(child: Row(children: [
            GestureDetector(
              onTap: () => _isListening ? _speech.stop() : _startVoice(),
              child: Container(width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: _isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.darkSurface,
                  border: Border.all(color: _isListening ? AppTheme.danger : AppTheme.darkBorder)),
                child: Icon(_isListening ? Icons.stop : Icons.mic, color: _isListening ? AppTheme.danger : Colors.white54, size: 20)),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: _ctrl, style: const TextStyle(color: Colors.white, fontSize: 14),
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: _isListening ? '🎤 Listening...' : 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), isDense: true),
            )),
            const SizedBox(width: 8),
            GestureDetector(onTap: () => _send(),
              child: Container(width: 44, height: 44,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary])),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 18))),
          ])),
        ),
      ]),
    );
  }

  Widget _buildMsg(ChatMessage msg, int index) {
    final isUser = msg.sender == MsgSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary.withOpacity(0.12) : AppTheme.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16)),
          border: Border.all(color: isUser ? AppTheme.primary.withOpacity(0.25) : AppTheme.darkBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(msg.text, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, height: 1.5)),
          if (msg.feedback != null && msg.feedback!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.accent.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
              child: Text(msg.feedback!, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12, height: 1.5)),
            ),
          ],
          if (msg.score != null || msg.xp > 0) ...[
            const SizedBox(height: 6),
            Row(children: [
              if (msg.score != null) Text('${msg.score!.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(
                color: msg.score! >= 8 ? AppTheme.primary : msg.score! >= 6 ? AppTheme.accent : AppTheme.danger,
                fontWeight: FontWeight.w700, fontSize: 12)),
              const Spacer(),
              if (msg.xp > 0) Text('+${msg.xp} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 11)),
            ]),
          ],
        ]),
      ),
    ).animate().fadeIn(delay: (50).ms).slideX(begin: isUser ? 0.05 : -0.05);
  }

  String _personalityEmoji(String mode) =>
    {'friendly': '😊', 'strict': '👨‍🏫', 'hr': '👔', 'debate': '🤺'}[mode] ?? '🤖';

  void _showPersonalityPicker(BuildContext context, AppState state) {
    showModalBottomSheet(context: context, backgroundColor: AppTheme.darkCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('AI Personality', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          ...AIFeedbackService.personalityDescriptions.entries.map((e) {
            final mode = e.key;
            final selected = state.profile.personalityMode == mode;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(_personalityEmoji(mode), style: const TextStyle(fontSize: 24)),
              title: Text('${mode[0].toUpperCase()}${mode.substring(1)} Coach',
                style: GoogleFonts.dmSans(color: selected ? AppTheme.secondary : Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(e.value, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
              trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.secondary) : null,
              onTap: () { state.setPersonalityMode(mode); Navigator.pop(context); },
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}
