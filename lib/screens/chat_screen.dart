import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../models/question_model.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/selector_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl        = TextEditingController();
  final _scroll      = ScrollController();
  final SpeechToText _speech = SpeechToText();
  late QuestionService _questionService;

  bool _aiTyping       = false;
  bool _isListening    = false;
  bool _speechReady    = false;
  String _liveVoice    = '';
  
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _questionService = QuestionService();
    _initSpeech();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendWelcome());
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
    setState(() {});
  }

  @override
  void dispose() { _ctrl.dispose(); _scroll.dispose(); _speech.stop(); super.dispose(); }

  void _sendWelcome() {
    final state = context.read<AppState>();
    if (state.chatMessages.isEmpty) {
      state.addMessage(ChatMessage(
        id: const Uuid().v4(),
        text: 'Hi ${state.profile.name.split(" ").first}! 👋  I\'m your AI English coach.\n\nI\'ll help you practice:\n• Professional English\n• Grammar corrections\n• Interview conversation\n\nType or use the 🎤 mic — I\'ll give instant feedback!',
        sender: MsgSender.ai, type: MsgType.tip,
      ));
    }
  }

  Future<void> _send([String? override]) async {
    final msg = (override ?? _ctrl.text).trim();
    if (msg.isEmpty) return;
    _ctrl.clear();
    setState(() => _liveVoice = '');

    final state = context.read<AppState>();
    state.addMessage(ChatMessage(id: const Uuid().v4(), text: msg, sender: MsgSender.user));
    setState(() => _aiTyping = true);
    _scrollDown();

    final reply = await AIFeedbackService.respondToSpeech(userText: msg, context: 'chat');
    state.addMessage(reply);
    state.addXP(reply.xp);
    setState(() => _aiTyping = false);
    _scrollDown();
  }

  void _suggestQuestion() {
    final q = _questionService.getRandomQuestion(
      type: 'conversation',
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );
    _send('Let\'s talk about: ${q.text}');
  }

  List<String> _getCategories() {
    return _questionService.getCategories(type: 'conversation');
  }

  Future<void> _startVoice() async {
    if (!_speechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mic not available — check permissions'), backgroundColor: AppTheme.danger));
      return;
    }
    setState(() { _isListening = true; _liveVoice = ''; });
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveVoice = r.recognizedWords);
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
    if (send && _liveVoice.trim().isNotEmpty) {
      _send(_liveVoice.trim());
    }
  }

  void _scrollDown() => Future.delayed(const Duration(milliseconds: 100), () {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final msgs  = state.chatMessages;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Row(children: [
          Container(width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.15)),
              child: const Center(child: Text('🤖', style: TextStyle(fontSize: 16)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            const Text('AI English Coach', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text('Online', style: GoogleFonts.dmSans(fontSize: 11, color: AppTheme.primary)),
          ]),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () { state.clearChat(); _sendWelcome(); }),
        ],
      ),
      body: Column(children: [
        // Topic chips and Filters
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.darkCard.withOpacity(0.5),
            border: const Border(bottom: BorderSide(color: AppTheme.darkBorder, width: 0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CategorySelector(
                  categories: _getCategories(),
                  selectedCategory: _selectedCategory,
                  onChanged: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: DifficultySelector(
                        selectedDifficulty: _selectedDifficulty,
                        onChanged: (diff) => setState(() => _selectedDifficulty = diff),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _suggestQuestion,
                      icon: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                      label: const Text('Suggest'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.primary, width: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: msgs.length + (_aiTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == msgs.length) return _typingIndicator();
              return _bubble(msgs[i]);
            },
          ),
        ),

        // Live voice preview
        if (_isListening && _liveVoice.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: AppTheme.danger.withOpacity(0.08),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.danger)),
              const SizedBox(width: 8),
              Expanded(child: Text(_liveVoice,
                  style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 13))),
            ]),
          ),

        // Input bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
          decoration: const BoxDecoration(
            color: AppTheme.darkCard,
            border: Border(top: BorderSide(color: AppTheme.darkBorder)),
          ),
          child: SafeArea(
            child: Row(children: [
              // Mic button
              GestureDetector(
                onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.darkSurface,
                    border: Border.all(color: _isListening ? AppTheme.danger : AppTheme.darkBorder),
                  ),
                  child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? AppTheme.danger : Colors.white54, size: 20),
                ),
              ),
              const SizedBox(width: 8),

              // Text field
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: _isListening ? '🎤 Listening...' : 'Type your message...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              GestureDetector(
                onTap: () => _send(),
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _bubble(ChatMessage msg) {
    final isUser = msg.sender == MsgSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
        child: Column(crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser ? const LinearGradient(colors: [AppTheme.primary, Color(0xFF00A87A)]) : null,
              color: isUser ? null : AppTheme.darkCard,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(msg.text, style: GoogleFonts.dmSans(
                  color: isUser ? AppTheme.darkBg : Colors.white, fontSize: 14, height: 1.5)),
              if (!isUser && msg.feedback != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(8)),
                  child: Text(msg.feedback!, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12, height: 1.4)),
                ),
              ],
            ]),
          ),
          if (!isUser && msg.xp > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('+${msg.xp} XP ⭐',
                  style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }

  Widget _typingIndicator() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppTheme.darkCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16),
          ), border: Border.all(color: AppTheme.darkBorder)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🤖 ', style: TextStyle(fontSize: 12)),
        Text('Analyzing...', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
      ]),
    ),
  ).animate().fadeIn(duration: 300.ms);
}
