import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:ui';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/gd_service.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_loading_widget.dart';
import '../widgets/voice_wave.dart';
import '../widgets/premium_button.dart';
import '../widgets/responsive_layout.dart';

enum GDPhase { topicSelection, loadingParticipants, participantPreview, discussion, feedback }

class GDScreen extends StatefulWidget {
  const GDScreen({super.key});

  @override
  State<GDScreen> createState() => _GDScreenState();
}

class _GDScreenState extends State<GDScreen> {
  GDPhase _phase = GDPhase.topicSelection;
  String _selectedTopic = '';
  List<GDParticipant> _participants = [];
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _topicCtrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  
  bool _isListening = false;
  double _soundLevel = 0.0;
  bool _aiThinking = false;
  int _activeAIIndex = -1;
  bool _autoMode = false;
  Timer? _autoTimer;

  final List<String> _presetTopics = [
    'Impact of Social Media on Mental Health',
    'AI: A Boon or a Bane for Jobs?',
    'Work from Home vs. Office Culture',
    'Crypto Currency: Future of Finance?',
    'Electric Vehicles: The Green Transition',
  ];

  void _startGeneration() async {
    if (_selectedTopic.isEmpty) return;
    setState(() => _phase = GDPhase.loadingParticipants);
    
    final participants = await GDService.generateParticipants(_selectedTopic);
    setState(() {
      _participants = participants;
      _phase = GDPhase.participantPreview;
    });
  }

  void _startDiscussion() async {
    setState(() {
      _phase = GDPhase.discussion;
      _messages.add(ChatMessage(
        id: 'system_1',
        text: "DISCUSSION STARTED: '$_selectedTopic'",
        sender: MsgSender.ai,
      ));
    });

    // Staggered joining messages
    for (var p in _participants) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: 'join_${p.name}',
          text: "${p.avatarEmoji} ${p.name} (${p.opinion}) has joined the room.",
          sender: MsgSender.ai,
        ));
      });
      _scrollToBottom();
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _messages.add(ChatMessage(
        id: 'system_2',
        text: "The floor is open. Please share your opening statements.",
        sender: MsgSender.ai,
      ));
      _scrollToBottom();
      
      // Trigger first random speaker
       Future.delayed(const Duration(seconds: 2), () => _triggerNextAISpeaker());
    }
  }

  void _triggerNextAISpeaker() async {
    if (_phase != GDPhase.discussion || _aiThinking) return;

    setState(() {
      _aiThinking = true;
      // Pick a random speaker who isn't the last one
      final eligible = List.generate(_participants.length, (i) => i)
          .where((i) => i != _activeAIIndex)
          .toList();
      _activeAIIndex = eligible[DateTime.now().millisecond % eligible.length];
    });

    final speaker = _participants[_activeAIIndex];
    final response = await GDService.getParticipantResponse(
      topic: _selectedTopic,
      participants: _participants,
      history: _messages,
      speakingParticipant: speaker,
    );

    if (mounted) {
      setState(() {
        _messages.add(response);
        _aiThinking = false;
        _activeAIIndex = -1;
      });
      _scrollToBottom();

      if (_autoMode && _phase == GDPhase.discussion) {
        _autoTimer = Timer(const Duration(seconds: 4), () => _triggerNextAISpeaker());
      }
    }
  }

  void _handleUserSpeech() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult && result.recognizedWords.isNotEmpty) {
              _addUserMessage(result.recognizedWords);
              setState(() => _isListening = false);
            }
          },
          onSoundLevelChange: (level) => setState(() => _soundLevel = level),
        );
      }
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: text,
        sender: MsgSender.user,
      ));
    });
    _scrollToBottom();
    _autoTimer?.cancel();
    // After user speaks, let an AI participant react after a short delay
    Future.delayed(const Duration(seconds: 3), () => _triggerNextAISpeaker());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _speech.stop();
    _topicCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Group Discussion', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: _phase != GDPhase.topicSelection 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _phase = GDPhase.topicSelection))
          : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _buildPhaseContent(),
        ),
      ),
      bottomNavigationBar: _phase == GDPhase.discussion ? _buildDiscussionControls() : null,
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case GDPhase.topicSelection:
        return _buildTopicSelection();
      case GDPhase.loadingParticipants:
        return _buildLoadingParticipants();
      case GDPhase.participantPreview:
        return _buildParticipantPreview();
      case GDPhase.discussion:
        return _buildDiscussionView();
      case GDPhase.feedback:
        return _buildFeedbackView();
    }
  }

  Widget _buildTopicSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ResponsiveContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOOSE A TOPIC', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            ..._presetTopics.map((t) => _topicCard(t)),
            const SizedBox(height: 24),
            Text('OR ENTER CUSTOM', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            TextField(
              controller: _topicCtrl,
              decoration: InputDecoration(
                hintText: 'e.g., Is AI making us lazy?',
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () {
                  if (_topicCtrl.text.isNotEmpty) {
                    setState(() => _selectedTopic = _topicCtrl.text);
                    _startGeneration();
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicCard(String topic) {
    final isSelected = _selectedTopic == topic;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTopic = topic);
        _startGeneration();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withAlpha(26) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.darkBorder.withAlpha(50)),
        ),
        child: Row(
          children: [
            const Icon(Icons.topic_rounded, color: AppTheme.primary),
            const SizedBox(width: 16),
            Expanded(child: Text(topic, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16))),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingParticipants() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AILoadingWidget(),
          const SizedBox(height: 24),
          Text('Generating Virtual Participants...', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Setting up diverse perspectives for your GD', style: GoogleFonts.outfit(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildParticipantPreview() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MEET THE GROUP', style: GoogleFonts.outfit(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              itemCount: _participants.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9),
              itemBuilder: (ctx, i) {
                final p = _participants[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.darkBorder.withAlpha(50)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(p.avatarEmoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 12),
                      Text(p.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(p.role, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getOpinionColor(p.opinion).withAlpha(38),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p.opinion, style: GoogleFonts.outfit(color: _getOpinionColor(p.opinion), fontWeight: FontWeight.w800, fontSize: 10)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (i * 200).ms).slideY(begin: 0.2);
              },
            ),
          ),
          PremiumButton(label: 'START SIMULATION', onPressed: _startDiscussion, color: AppTheme.primary),
        ],
      ),
    );
  }

  Color _getOpinionColor(String opinion) {
    if (opinion == 'Support') return AppTheme.success;
    if (opinion == 'Oppose') return AppTheme.danger;
    return AppTheme.accent;
  }

  Widget _buildDiscussionView() {
    return Column(
      children: [
        // Participant Bar
        Container(
          height: 95, // Increased to avoid 2.0px overflow
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor.withAlpha(128)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _participants.length,
            itemBuilder: (ctx, i) {
              final active = _activeAIIndex == i;
              final p = _participants[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: active ? AppTheme.primary : Colors.transparent, width: 2),
                      ),
                      child: CircleAvatar(backgroundColor: AppTheme.primary.withAlpha(26), child: Text(p.avatarEmoji)),
                    ),
                    const SizedBox(height: 4),
                    Text(p.name, style: GoogleFonts.outfit(fontSize: 10, color: active ? AppTheme.primary : AppTheme.textSecondary, fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
                  ],
                ),
              );
            },
          ),
        ),
        // Discussion Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length + (_aiThinking ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _messages.length) {
                return _buildThinkingBubble();
              }
              final m = _messages[i];
              return _buildMessageBubble(m);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThinkingBubble() {
    final speaker = _activeAIIndex != -1 ? _participants[_activeAIIndex] : null;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (speaker != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text('${speaker.name} is typing...', style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(26), borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0), _dot(1), _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6, height: 6,
      decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), delay: (delay * 200).ms, duration: 600.ms);
  }

  Widget _buildMessageBubble(ChatMessage m) {
    final isUser = m.sender == MsgSender.user;
    final isSystem = m.id.startsWith('system');

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppTheme.accent.withAlpha(26), borderRadius: BorderRadius.circular(12)),
          child: Text(m.text, style: GoogleFonts.outfit(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ),
      );
    }

    final participant = m.participantName != null 
        ? _participants.firstWhere((p) => p.name == m.participantName, orElse: () => _participants.first)
        : null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: isUser ? null : Border.all(color: AppTheme.darkBorder.withAlpha(50)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && participant != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(participant.avatarEmoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      participant.name,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(participant.opinion, style: GoogleFonts.outfit(fontSize: 9, color: _getOpinionColor(participant.opinion), fontWeight: FontWeight.w700)),
                ],
              ),
            if (!isUser) const SizedBox(height: 6),
            Text(m.text, style: GoogleFonts.outfit(color: isUser ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color, fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionControls() {
    final isSmall = MediaQuery.of(context).size.width < 400;
    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: AppTheme.darkBorder.withAlpha(50))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_autoMode ? Icons.auto_mode_rounded : Icons.play_arrow_rounded, 
                       color: _autoMode ? AppTheme.primary : AppTheme.textSecondary),
            onPressed: () {
              setState(() => _autoMode = !_autoMode);
              if (_autoMode && !_aiThinking) _triggerNextAISpeaker();
            },
            tooltip: 'Auto Mode',
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: isSmall ? 2 : 3,
            child: PremiumButton(
              label: isSmall ? 'Next AI' : 'Next AI Speaker',
              icon: Icons.skip_next_rounded,
              onPressed: _aiThinking ? null : () {
                _autoTimer?.cancel();
                _triggerNextAISpeaker();
              },
              color: AppTheme.secondary,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 16),
            child: GestureDetector(
              onTap: _handleUserSpeech,
              child: Container(
                padding: EdgeInsets.all(isSmall ? 12 : 16),
                decoration: BoxDecoration(
                  color: _isListening ? AppTheme.danger : AppTheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: (_isListening ? AppTheme.danger : AppTheme.primary).withAlpha(77), blurRadius: 15)],
                ),
                child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: isSmall ? 20 : 24),
              ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ),
          ),
          Expanded(
            flex: isSmall ? 2 : 3,
            child: PremiumButton(
              label: isSmall ? 'Finish' : 'Finish GD',
              icon: Icons.check_circle_rounded,
              onPressed: () => setState(() => _phase = GDPhase.feedback),
              color: AppTheme.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text('GD Completed!', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('Excellent participation! You addressed 3 key points and maintained a balanced tone.', 
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textSecondary, height: 1.5)
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.accent.withAlpha(26), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded, color: AppTheme.accent),
                  const SizedBox(width: 12),
                  Text('+50 XP Earned', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.accent)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            PremiumButton(label: 'BACK TO HOME', onPressed: () => Navigator.pop(context), color: AppTheme.primary),
          ],
        ),
      ).animate().fadeIn().scale(),
    );
  }
}
