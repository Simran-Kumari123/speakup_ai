import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/speech_service.dart';
import '../models/models.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  String? _activeChallenge; // 'blitz', 'image', 'story'
  
  final List<Map<String, dynamic>> _challengeTypes = [
    {
      'id': 'blitz',
      'title': '30s Blitz',
      'desc': 'Speak about a random topic for 30 seconds straight.',
      'icon': '⚡',
      'color': Colors.orange,
      'duration': 30,
    },
    {
      'id': 'image',
      'title': 'Describe Image',
      'desc': 'Detailed description of a scene in 45 seconds.',
      'icon': '🖼️',
      'color': Colors.blue,
      'duration': 45,
    },
    {
      'id': 'story',
      'title': 'Story Teller',
      'desc': 'Continue a story from a creative opening line.',
      'icon': '📖',
      'color': Colors.purple,
      'duration': 60,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Speaking Challenges ⚡'),
        centerTitle: true,
      ),
      body: _activeChallenge == null 
        ? _buildChallengeSelector() 
        : _ChallengeActiveSession(
            type: _challengeTypes.firstWhere((c) => c['id'] == _activeChallenge),
            onExit: () => setState(() => _activeChallenge = null),
          ),
    );
  }

  Widget _buildChallengeSelector() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _challengeTypes.length,
      itemBuilder: (context, i) {
        final c = _challengeTypes[i];
        final accentColor = c['color'] as Color;
        return GestureDetector(
          onTap: () => setState(() => _activeChallenge = c['id']),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: accentColor.withOpacity(0.1), width: 1.5),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))
              ]
            ),
            child: Row(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(child: Text(c['icon'], style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['title'], style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(c['desc'], style: theme.textTheme.bodySmall?.copyWith(height: 1.4, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('${c['duration']} Seconds', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
                ]),
              ])),
            ]),
          ),
        ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1);
      },
    );
  }
}

class _ChallengeActiveSession extends StatefulWidget {
  final Map<String, dynamic> type;
  final VoidCallback onExit;
  const _ChallengeActiveSession({required this.type, required this.onExit});

  @override
  State<_ChallengeActiveSession> createState() => _ChallengeActiveSessionState();
}

class _ChallengeActiveSessionState extends State<_ChallengeActiveSession> {
  late Timer _timer;
  int _timeLeft = 0;
  bool _isRecording = false;
  bool _processing = false;
  String _currentPrompt = '';
  String? _imagePath;
  String _spokenText = '';
  String _liveText = '';
  ChatMessage? _feedback;
  String? _error;
  bool _isGenerating = false;

  final List<String> _blitzPrompts = [
    'Your favorite childhood memory.',
    'The importance of traveling.',
    'Why learning English is important for you.',
    'Describe your dream job.',
    'The best piece of advice you ever received.',
    'What would you do if you won a million dollars?',
    'If you could travel back in time, when would you go?',
    'Describe your perfect day from morning to night.',
  ];

  final List<String> _storyStarters = [
    'It was a rainy Tuesday when the mysterious letter arrived...',
    'I stepped into the elevator, but when the doors opened, I wasn\'t in the lobby anymore...',
    'The old key I found in the attic actually fit the strange door in the basement...',
    'I woke up this morning with the ability to hear people\'s thoughts...',
    'The robot looked at me and said something I never expected...',
  ];

  final List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&q=80&w=600', // Modern Office
    'https://images.unsplash.com/photo-1449034446853-66c86144b0ad?auto=format&fit=crop&q=80&w=600', // Golden Gate Bridge
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=600', // Cozy Cafe
    'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&q=80&w=600', // Landscape
  ];

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.type['duration'];
    _generatePrompt();
  }

  Future<void> _generatePrompt() async {
    setState(() {
      _isGenerating = true;
      _currentPrompt = '';
      _imagePath = null;
    });

    try {
      final state = context.read<AppState>();
      final result = await AIFeedbackService.generateSpeakingChallenge(
        type: widget.type['id'],
        role: state.profile.targetRole,
        difficulty: state.profile.difficulty,
      );

      if (mounted) {
        setState(() {
          _currentPrompt = result['prompt'] ?? 'Speak about your day.';
          _imagePath = result['imageUrl'];
          _isGenerating = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating prompt: $e');
      // Fallback to local
      final rand = Random();
      if (mounted) {
        setState(() {
          if (widget.type['id'] == 'blitz') {
            _currentPrompt = _blitzPrompts[rand.nextInt(_blitzPrompts.length)];
          } else if (widget.type['id'] == 'image') {
            _currentPrompt = 'Describe this scene in detail.';
            _imagePath = _imageUrls[rand.nextInt(_imageUrls.length)];
          } else {
            _currentPrompt = _storyStarters[rand.nextInt(_storyStarters.length)];
          }
          _isGenerating = false;
        });
      }
    }
  }

  void _startChallenge() async {
    setState(() {
      _isRecording = true;
      _timeLeft = widget.type['duration'];
      _liveText = '';
      _spokenText = '';
      _feedback = null;
      _error = null;
    });

    // Start Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _stopChallenge();
      }
    });

    // Start Recording
    final speech = context.read<SpeechService>();
    await speech.listen(
      onResult: (text, isFinal) => setState(() => _liveText = text),
      listenFor: Duration(seconds: widget.type['duration'] + 5),
      partialResults: true,
    );
  }

  void _stopChallenge() async {
    _timer.cancel();
    final speech = context.read<SpeechService>();
    await speech.stop();

    setState(() {
      _isRecording = false;
      _spokenText = _liveText;
      _processing = true;
    });

    if (_spokenText.trim().isNotEmpty) {
      _processFeedback();
    } else {
      setState(() {
        _processing = false;
        _error = 'No speech detected. Please try again!';
      });
    }
  }

  Future<void> _processFeedback() async {
    try {
      final p = context.read<AppState>().profile;
      final fb = await AIFeedbackService.respondToSpeech(
        userText: _spokenText,
        personalityMode: p.personalityMode,
        difficulty: p.difficulty,
        context: 'speaking_challenge',
      );

      final state = context.read<AppState>();
      state.addXP(fb.xp);
      state.incrementSessions();

      if (mounted) {
        setState(() {
          _feedback = fb;
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _processing = false;
          _error = 'Failed to get AI feedback. Please check your connection.';
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isRecording) _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.type['color'] as Color;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Progress / Timer
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.4)), onPressed: widget.onExit),
          Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _timeLeft / widget.type['duration'],
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                strokeWidth: 6,
              ),
              Text('$_timeLeft', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(width: 48), // Balance
        ]),
        const SizedBox(height: 32),

        // Challenge Display
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 120),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accentColor.withValues(alpha: 0.1)),
            boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
          ),
          child: _isGenerating 
            ? Center(child: Column(
                children: [
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text('Thinking of a challenge...', style: theme.textTheme.bodySmall),
                ],
              ))
            : Column(children: [
                if (_imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(_imagePath!, width: double.infinity, height: 180, fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        height: 180, color: accentColor.withValues(alpha: 0.1),
                        child: Icon(Icons.broken_image_rounded, color: accentColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(widget.type['title'].toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(color: accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Text(_currentPrompt, textAlign: TextAlign.center, style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, height: 1.4, fontWeight: FontWeight.w800)),
              ]),
        ).animate().fadeIn().slideY(begin: 0.05),

        const SizedBox(height: 32),

        // Mic Section
        if (!_processing && _feedback == null)
          GestureDetector(
            onTap: _isRecording ? _stopChallenge : _startChallenge,
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? theme.colorScheme.error.withOpacity(0.1) : theme.colorScheme.primary.withOpacity(0.1),
                border: Border.all(color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary, width: 3),
                boxShadow: [
                  BoxShadow(color: (_isRecording ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.2), blurRadius: 20, spreadRadius: 2)
                ]
              ),
              child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary, size: 48),
            ),
          ).animate(target: _isRecording ? 1 : 0).shimmer(duration: 1000.ms),

        if (_isRecording)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(_liveText.isEmpty ? 'Waiting for you to speak...' : _liveText, 
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          ),

        if (_processing)
          Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Column(children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text('Evaluating your response...', style: theme.textTheme.bodySmall),
          ])),

        if (_error != null && !_processing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
            ),
          ).animate().shake(),

        // Feedback Section
        if (_feedback != null)
          _buildFeedbackCard(_feedback!),

        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildFeedbackCard(ChatMessage fb) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: [
        const Text('👏', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text('CHALLENGE COMPLETE', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statItem('Score', '${fb.score ?? 7.5}/10', theme.colorScheme.primary),
          _statItem('XP', '+${fb.xp}', theme.colorScheme.primary),
        ]),
        const Divider(height: 40),
        Text(fb.text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, fontWeight: FontWeight.w500)),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
          onPressed: () { setState(() { _feedback = null; _generatePrompt(); }); },
          child: const Text('Try Another Challenge'),
        )),
      ]),
    ).animate().scale(begin: const Offset(0.9, 0.9)).fadeIn();
  }

  Widget _statItem(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(value, style: theme.textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 24)),
    ]);
  }
}
