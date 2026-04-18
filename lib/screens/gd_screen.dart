import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/speech_service.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/gd_service.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_loading_widget.dart';
import '../widgets/premium_button.dart';

enum GDPhase { topicSelection, loadingParticipants, participantPreview, discussion, feedback }

class GDScreen extends StatefulWidget {
  const GDScreen({super.key});

  @override
  State<GDScreen> createState() => _GDScreenState();
}

class _GDScreenState extends State<GDScreen> with WidgetsBindingObserver {
  GDPhase _phase = GDPhase.topicSelection;
  String _selectedTopic = '';
  List<GDParticipant> _participants = [];
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _topicCtrl = TextEditingController();
  late SpeechService _speechService;
  final List<Timer> _timers = [];
  final TextEditingController _messageCtrl = TextEditingController();
  bool _speechReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speechService.init(
      onError: (e) { if (mounted) setState(() => _isListening = false); },
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && _isListening) {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _speechService = context.read<SpeechService>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (var t in _timers) { t.cancel(); }
    _timers.clear();
    _autoTimer?.cancel();
    _scrollController.dispose();
    _topicCtrl.dispose();
    _messageCtrl.dispose();
    _speechService.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopVoice();
      setState(() {
        _autoMode = false;
        _aiThinking = false;
        _activeAIIndex = -1;
      });
      for (var t in _timers) { t.cancel(); }
      _timers.clear();
      _autoTimer?.cancel();
    }
  }

  bool _isListening = false;
  double _soundLevel = 0.0;
  bool _aiThinking = false;
  int _activeAIIndex = -1;
  bool _isStarting = false;
  bool _autoMode = false;
  Timer? _autoTimer;
  String _liveText = '';
  int _earnedBonus = 0;
  int _userContributionCount = 0;
  double _totalSessionScore = 0.0;
  bool _generatingMagicTopic = false;

  final List<String> _presetTopics = [
    'Impact of Social Media on Mental Health',
    'AI: A Boon or a Bane for Jobs?',
    'Work from Home vs. Office Culture',
    'Crypto Currency: Future of Finance?',
    'Electric Vehicles: The Green Transition',
    'AI: The Future of Space Travel?',
  ];

  void _generateMagicTopic() async {
    final state = context.read<AppState>();
    setState(() => _generatingMagicTopic = true);
    
    final topic = await GDService.generateTopic(
      role: state.profile.targetRole,
      resumeContext: state.isResumeMode ? state.activeResume?.roleTag : null,
    );
    
    if (mounted) {
      setState(() {
        _selectedTopic = topic;
        _generatingMagicTopic = false;
      });
      _startGeneration();
    }
  }

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
    if (_isStarting) return;
    
    setState(() {
      _isStarting = true;
      _phase = GDPhase.discussion;
    });

    for (var p in _participants) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          id: 'join_${p.name}',
          text: "${p.avatarEmoji} ${p.name} (${p.role}) has joined as a speaker.",
          sender: MsgSender.ai,
        ));
      });
      _scrollToBottom();
    }

    // Add User join message
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          id: 'join_user',
          text: "👤 You (User) have joined the discussion.",
          sender: MsgSender.ai,
        ));
      });
      _scrollToBottom();
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(
          id: 'system_2',
          text: "The floor is open. Please share your opening statements.",
          sender: MsgSender.ai,
        ));
        _isStarting = false;
      });
      _scrollToBottom();
      final t = Timer(const Duration(seconds: 2), () => _triggerNextAISpeaker());
      _timers.add(t);
    }
  }

  void _triggerNextAISpeaker() async {
    if (_phase != GDPhase.discussion || _aiThinking || _isListening || _participants.isEmpty) return;

    setState(() {
      _aiThinking = true;
      final eligible = List.generate(_participants.length, (i) => i)
          .where((i) => i != _activeAIIndex)
          .toList();
      
      if (eligible.isEmpty) {
        _activeAIIndex = _participants.length > 0 ? 0 : -1;
      } else {
        _activeAIIndex = eligible[DateTime.now().millisecond % eligible.length];
      }
    });

    if (_activeAIIndex == -1) {
      setState(() => _aiThinking = false);
      return;
    }

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
        _autoTimer?.cancel();
        _autoTimer = Timer(const Duration(seconds: 4), () => _triggerNextAISpeaker());
      }
    }
  }

  Future<void> _startVoice() async {
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    await _speechService.listen(
      onResult: (text, isFinal) => setState(() {
        _liveText = text;
        if (isFinal) {
          _messageCtrl.text = text;
        }
      })
    );
  }

  Future<void> _stopVoice() async {
    await _speechService.stop();
    setState(() => _isListening = false);
  }

  void _handleUserSpeech() async {
    _autoTimer?.cancel();
    setState(() => _autoMode = false);

    if (_isListening) {
      await _stopVoice();
      if (_messageCtrl.text.trim().isNotEmpty) {
        _addUserMessage(_messageCtrl.text.trim());
        _messageCtrl.clear();
      }
    } else {
      final available = await _speechService.init(
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && _isListening) {
             if (mounted) {
               setState(() => _isListening = false);
               if (_liveText.trim().isNotEmpty) {
                 _addUserMessage(_liveText.trim());
                 _liveText = '';
               }
             }
          }
        },
      );
      if (available) {
        setState(() {
          _isListening = true;
          _liveText = '';
        });
        await _speechService.listen(
          onResult: (text, isFinal) {
            if (mounted) {
              setState(() => _liveText = text);
              if (isFinal && text.trim().isNotEmpty) {
                // Short delay to ensure state reconciles
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && _isListening) {
                    _addUserMessage(text.trim());
                    setState(() {
                      _isListening = false;
                      _liveText = '';
                    });
                  }
                });
              }
            }
          },
          onSoundLevelChange: (level) {
            if (mounted) setState(() => _soundLevel = level);
          },
        );
      }
    }
  }

  void _addUserMessage(String text) async {
    setState(() {
      _aiThinking = true;
      _messages.add(ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: text,
        sender: MsgSender.user,
      ));
    });
    _scrollToBottom();
    _autoTimer?.cancel();

    try {
      final p = context.read<AppState>().profile;
      final feedback = await AIFeedbackService.respondToSpeech(
        userText: text,
        context: 'gd',
        personalityMode: p.personalityMode,
        difficulty: p.difficulty,
      );

      if (mounted) {
        final state = context.read<AppState>();
        state.addXP(feedback.xp);
        setState(() {
          final index = _messages.lastIndexWhere((m) => m.sender == MsgSender.user && m.text == text);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: _messages[index].id, text: text, sender: MsgSender.user,
              feedback: feedback.feedback, score: feedback.score,
              fluency: feedback.fluency, grammar: feedback.grammar,
              confidence: feedback.confidence, xp: feedback.xp,
            );
          }
          _aiThinking = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _aiThinking = false);
    }
    Future.delayed(const Duration(seconds: 2), () => _triggerNextAISpeaker());
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Group Discussion'),
        centerTitle: true,
        leading: _phase != GDPhase.topicSelection 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _phase = GDPhase.topicSelection))
          : null,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: _buildPhaseContent()),
      ),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case GDPhase.topicSelection:     return _buildTopicSelection();
      case GDPhase.loadingParticipants: return _buildLoadingParticipants();
      case GDPhase.participantPreview:  return _buildParticipantPreview();
      case GDPhase.discussion:         return _buildDiscussionView();
      case GDPhase.feedback:           return _buildFeedbackView();
    }
  }

  Widget _buildTopicSelection() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
              child: Text('SIMULATION', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))),
          ]),
          const SizedBox(height: 16),
          Text('Group Discussion 🗣️', style: theme.textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Practice collaboration and debate with virtual participants.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 48),
          
          const SizedBox(height: 24),
          Row(
            children: [
              Text('SELECT A TOPIC', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
              const Spacer(),
              TextButton.icon(
                icon: Icon(Icons.shuffle_rounded, size: 16, color: theme.colorScheme.primary),
                label: Text('SHUFFLE', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10)),
                onPressed: () => setState(() => _presetTopics.shuffle()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._presetTopics.take(4).map((t) => _topicCard(t)),
          
          const SizedBox(height: 24),
          Text('OR EXPLORE DYNAMICALLY', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 16),
          
          // Magic Topic Card
          GestureDetector(
            onTap: _generatingMagicTopic ? null : _generateMagicTopic,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.secondary]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), 
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: _generatingMagicTopic 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI MAGIC TOPIC', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                        Text(
                          _generatingMagicTopic ? 'Thinking of a topic...' : 'Generate Industry Topic', 
                          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(delay: 2.seconds, duration: 2.seconds, color: Colors.white24),

          const SizedBox(height: 24),
          Text('OR ENTER CUSTOM', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 16),
          TextField(
            controller: _topicCtrl,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'e.g., Is AI making us lazy?',
              suffixIcon: IconButton(icon: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary), onPressed: () {
                if (_topicCtrl.text.isNotEmpty) {
                  setState(() => _selectedTopic = _topicCtrl.text);
                  _startGeneration();
                }
              }),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _topicCard(String topic) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () { setState(() => _selectedTopic = topic); _startGeneration(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.forum_rounded, color: theme.colorScheme.primary, size: 20)),
            const SizedBox(width: 16),
            Expanded(child: Text(topic, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded, color: theme.textTheme.bodySmall?.color?.withOpacity(0.3)),
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
          Text('Generating Virtual Participants...', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Setting up diverse perspectives for your GD', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildParticipantPreview() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('MEET THE GROUP', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Determine responsive aspect ratio based on available height and width
                final double cardWidth = (constraints.maxWidth - 16) / 2;
                final double cardHeight = (constraints.maxHeight - 16) / 2;
                // Clamp target ratio to ensure cards don't get too squashed or too stretched
                final double targetRatio = (cardWidth / cardHeight).clamp(0.65, 0.85);

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _participants.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 16, 
                    mainAxisSpacing: 16, 
                    childAspectRatio: targetRatio,
                  ),
                  itemBuilder: (ctx, i) {
                    final p = _participants[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 10)],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12), 
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: Text(p.avatarEmoji, style: const TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(height: 8),
                          FittedBox(fit: BoxFit.scaleDown, child: Text(p.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                          const SizedBox(height: 2),
                          Text(
                            p.role, 
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10), 
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getOpinionColor(p.opinion).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(p.opinion.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: _getOpinionColor(p.opinion), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 200).ms).scale(begin: const Offset(0.9, 0.9));
                  },
                );
              }
            ),
          ),
          const SizedBox(height: 16),
          PremiumButton(
            label: _isStarting ? 'Loading...' : 'Start Simulation ✨', 
            isLoading: _isStarting,
            onPressed: _isStarting ? null : _startDiscussion
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Color _getOpinionColor(String opinion) {
    final theme = Theme.of(context);
    return opinion == 'Support' ? const Color(0xFF00C896) : opinion == 'Oppose' ? theme.colorScheme.error : theme.colorScheme.primary;
  }

  Widget _buildDiscussionView() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          height: 95, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.05)),
          child: ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: _participants.length,
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
                        border: Border.all(color: active ? theme.colorScheme.primary : Colors.transparent, width: 2)
                      ),
                      child: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1), 
                        child: Text(p.avatarEmoji)
                      ),
                    ).animate(target: active ? 1 : 0).shimmer(color: theme.colorScheme.primary.withOpacity(0.3)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                    const SizedBox(height: 4),
                    Text(p.name, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: active ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color, fontWeight: active ? FontWeight.w900 : FontWeight.w600)),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController, padding: const EdgeInsets.all(20),
            itemCount: _messages.length + (_aiThinking ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _messages.length) return _buildThinkingBubble();
              return _buildMessageBubble(_messages[i]);
            },
          ),
        ),
        _buildDiscussionControls(),
      ],
    );
  }

  Widget _buildThinkingBubble() {
    final theme = Theme.of(context);
    final speaker = _activeAIIndex != -1 ? _participants[_activeAIIndex] : null;
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (speaker != null)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 8),
              child: Row(children: [
                Text(speaker.avatarEmoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                Text('${speaker.name} is typing...', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontStyle: FontStyle.italic, fontWeight: FontWeight.w700)),
              ]),
            ),
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [ _dot(0), _dot(1), _dot(2) ]),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) => Container(
      margin: const EdgeInsets.symmetric(horizontal: 2), width: 6, height: 6,
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), delay: (delay * 200).ms, duration: 600.ms);

  Widget _buildMessageBubble(ChatMessage m) {
    final theme = Theme.of(context);
    final isUser = m.sender == MsgSender.user;
    final isSystem = m.id.startsWith('system');

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Text(m.text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5), textAlign: TextAlign.center),
        ),
      );
    }

    final participant = m.participantName != null 
        ? _participants.firstWhere((p) => p.name == m.participantName, orElse: () => _participants.first)
        : null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary.withOpacity(0.12) : theme.cardColor,
          borderRadius: BorderRadius.circular(24).copyWith(
            bottomLeft: isUser ? const Radius.circular(24) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(24),
          ),
          border: Border.all(color: isUser ? theme.colorScheme.primary.withOpacity(0.1) : theme.dividerColor.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && participant != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(participant.avatarEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Flexible(child: Text(participant.name, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            Text(m.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontWeight: isUser ? FontWeight.w600 : FontWeight.w500)),
            if (isUser && m.score != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                Text('Score: ${m.score!.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11)),
                const Spacer(),
                Text('+${m.xp} XP', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 11)),
              ]),
            ]
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildDiscussionControls() {
    final theme = Theme.of(context);
    final isSmall = MediaQuery.of(context).size.width < 390;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: theme.cardColor, 
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.05))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mode Toggle
          _roundAction(
            icon: _autoMode ? Icons.auto_mode_rounded : Icons.play_arrow_rounded,
            active: _autoMode,
            onTap: () { 
              setState(() => _autoMode = !_autoMode); 
              if (_autoMode && !_aiThinking) _triggerNextAISpeaker(); 
            },
          ),
          const SizedBox(width: 4),
          
          // Next AI
          Flexible(
            flex: 2,
            child: _pillButton(
              label: 'Next',
              icon: Icons.skip_next_rounded,
              color: theme.colorScheme.secondary,
              onPressed: _aiThinking ? null : () { 
                _autoTimer?.cancel(); 
                _triggerNextAISpeaker(); 
              },
            ),
          ),
          
          // Mic
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: _handleUserSpeech,
              child: Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  color: _isListening ? theme.colorScheme.error : theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.35), 
                      blurRadius: 15, 
                      offset: const Offset(0, 4)
                    )
                  ],
                ),
                child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: theme.colorScheme.onPrimary, size: 26),
              ).animate(target: _isListening ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15)),
            ),
          ),
          
          // Finish
          Flexible(
            flex: 2,
            child: _pillButton(
              label: 'Finish',
              icon: Icons.check_circle_outline_rounded,
              color: AppTheme.success,
              onPressed: () async {
                final userMessages = _messages.where((m) => m.sender == MsgSender.user).toList();
                
                if (userMessages.isEmpty) {
                   final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Finish Discussion?'),
                      content: const Text('You haven\'t participated yet. Do you want to finish without earning any rewards?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Wait, Stay')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Finish')),
                      ],
                    ),
                  );
                  if (confirm != true) return;
                }

                _autoTimer?.cancel();
                _userContributionCount = userMessages.length;
                
                if (userMessages.isNotEmpty) {
                  final avgScore = userMessages.map((m) => m.score ?? 7.0).reduce((a, b) => a + b) / userMessages.length;
                  final totalXP = userMessages.map((m) => m.xp).fold(0, (a, b) => a + b);
                  _totalSessionScore = avgScore;
                  
                  final bonus = (userMessages.length >= 3 ? 50 : 0);
                  _earnedBonus = bonus;

                  final state = context.read<AppState>();
                  state.addSession(PracticeSession(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    topic: 'GD: $_selectedTopic', type: 'GD', score: avgScore,
                    fluency: avgScore, grammar: avgScore, confidence: avgScore, 
                    xp: totalXP + bonus,
                  ));
                  if (bonus > 0) {
                    state.addXP(bonus);
                  }
                } else {
                  _earnedBonus = 0;
                  _totalSessionScore = 0.0;
                }
                setState(() => _phase = GDPhase.feedback);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundAction({required IconData icon, required bool active, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.primary.withOpacity(0.12) : theme.dividerColor.withOpacity(0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? theme.colorScheme.primary.withOpacity(0.2) : theme.dividerColor.withOpacity(0.08)),
          ),
          child: Icon(icon, color: active ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color?.withOpacity(0.4), size: 18),
        ),
      ),
    );
  }

  Widget _pillButton({required String label, required IconData icon, required Color color, required VoidCallback? onPressed}) {
    final theme = Theme.of(context);
    final disabled = onPressed == null;
    final isSmall = MediaQuery.of(context).size.width < 390;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(disabled ? 0.04 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(disabled ? 0.05 : 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color.withOpacity(disabled ? 0.2 : 1.0), size: 16),
              if (!isSmall) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label, 
                      style: theme.textTheme.titleSmall?.copyWith(color: color.withOpacity(disabled ? 0.3 : 1.0), fontWeight: FontWeight.w900, fontSize: 13),
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackView() {
    final theme = Theme.of(context);
    final hasBonus = _earnedBonus > 0;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Text(hasBonus ? '🏆' : '💪', style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 32),
          Text(hasBonus ? 'Session Complete!' : 'Nice Effort!', style: theme.textTheme.displayMedium),
          const SizedBox(height: 12),
          Text(hasBonus 
            ? 'Excellent participation! You addressed key points and maintained a balanced tone.'
            : 'You participated $_userContributionCount ${_userContributionCount == 1 ? 'time' : 'times'}. Speak at least 3 times to earn a completion bonus!', 
            textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 48),
          
          if (hasBonus)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.2)),
              ),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.stars_rounded, color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Text('+$_earnedBonus XP', style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
                ]),
                const SizedBox(height: 8),
                Text('COMPLETION BONUS', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
              ]),
            ),
          
          if (!hasBonus && _userContributionCount > 0)
            Text('Score: ${_totalSessionScore.toStringAsFixed(1)} / 10', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity, height: 60,
            child: OutlinedButton(
               onPressed: () => Navigator.pop(context),
               child: Text('Return to Home', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }
}
