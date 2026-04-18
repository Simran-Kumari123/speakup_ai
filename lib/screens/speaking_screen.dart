import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/question_card.dart';
import '../widgets/ai_error_widget.dart';
import '../widgets/ai_loading_widget.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/voice_wave.dart';
import '../widgets/confidence_meter.dart';
import 'gd_screen.dart';
import '../services/speech_service.dart';

class SpeakingScreen extends StatefulWidget {
  final PracticeTopic? topic;
  final Question? question;

  const SpeakingScreen({super.key, this.topic, this.question});

  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> with TickerProviderStateMixin {
  final FlutterTts _tts = AppState.tts;
  late QuestionService _questionService;

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _processing = false;
  bool _isStopping = false; // Add guard
  String _spokenText = '';
  String _liveText = '';
  String _errorMessage = '';
  ChatMessage? _feedback;
  double _soundLevel = 0.0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  Question? _currentQuestion;
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.15).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _questionService = QuestionService();

    if (widget.topic != null) {
      _selectedCategory = widget.topic!.title;
    }

    if (widget.question != null) {
      _currentQuestion = widget.question;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateNewQuestion(useAI: true);
      });
    }
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final speechService = context.read<SpeechService>();
    _speechAvailable = await speechService.init(
      onError: (e) {
        if (e.errorMsg != 'error_no_match' && e.errorMsg != 'error_speech_timeout') {
          _showError(SpeechService.getFriendlyError(e));
        }
        if (_isListening) _stopListening();
      },
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _stopListening();
        }
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('Microphone not available.');
      return;
    }
    setState(() {
      _isListening = true;
      _isStopping = false; // Reset guard
      _liveText = '';
      _spokenText = '';
      _feedback = null;
    });

    final speechService = context.read<SpeechService>();
    await speechService.listen(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() => _liveText = text);
          if (isFinal && text.trim().isNotEmpty) {
            _stopListening();
          }
        }
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      onSoundLevelChange: (level) {
        if (mounted) setState(() => _soundLevel = level);
      },
    );
  }

  Future<void> _stopListening() async {
    if (_isStopping) return; // Guard against double calls
    _isStopping = true;

    final speechService = context.read<SpeechService>();
    if (speechService.isListening) await speechService.stop();
    
    if (!mounted) return;
    setState(() => _isListening = false);

    if (_liveText.trim().isNotEmpty && !_processing) {
      setState(() {
        _spokenText = _liveText;
        _processing = true;
        _liveText = '';
      });
      await _processVoice();
    }
  }

  Future<void> _processVoice() async {
    if (_spokenText.isEmpty) {
      setState(() => _processing = false);
      return;
    }
    try {
      final state = context.read<AppState>();
      final fb = await AIFeedbackService.respondToSpeech(
        userText: _spokenText,
        personalityMode: state.profile.personalityMode,
        difficulty: state.profile.difficulty,
        context: 'chat',
      );

      if (!mounted) return;

      state.addXP(fb.xp);
      state.addWordsSpoken(_spokenText.split(' ').length);
      state.addPracticeMinutes(1);
      state.addSession(PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        topic: _currentQuestion?.text ?? 'Speaking Practice',
        type: 'Speaking',
        score: fb.score ?? 7.5,
        xp: fb.xp,
      ));

      setState(() {
        _feedback = fb;
        _processing = false;
      });
      _showFeedbackModal(fb);
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection lost. Please try again.';
        _processing = false;
      });
    }
  }

  void _showFeedbackModal(ChatMessage fb) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor.withOpacity(0.1), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('AI ANALYSIS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1.5, fontSize: 11)),
              ),
              const SizedBox(height: 24),
              ConfidenceMeter(score: fb.score ?? 7.5),
              const SizedBox(height: 24),
              Text(fb.text, textAlign: TextAlign.center, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 18, height: 1.4)),
              if (fb.feedback != null && fb.feedback!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
                  child: Text(fb.feedback!, style: GoogleFonts.dmSans(fontSize: 14, height: 1.6, color: Colors.black.withOpacity(0.7))),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('CONTINUE PRACTICE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  Future<void> _generateNewQuestion({bool useAI = false}) async {
    final state = context.read<AppState>();
    if (useAI) {
      final q = await state.generateDynamicQuestion(category: _selectedCategory, difficulty: _selectedDifficulty);
      if (q != null && mounted) {
        setState(() => _currentQuestion = q);
        return;
      }
    }
    if (mounted) {
      setState(() {
        _currentQuestion = _questionService.getRandomQuestion(type: 'speaking', category: _selectedCategory, difficulty: _selectedDifficulty);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();

    return ConnectivityBanner(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('Speaking Practice', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
          actions: [
            IconButton(
              icon: state.isGeneratingQuestion 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.auto_fix_high_rounded, color: theme.colorScheme.primary),
              onPressed: () => _generateNewQuestion(useAI: true),
              tooltip: 'Career-Aware Generation',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildModernSelectors(theme),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: state.isGeneratingQuestion
                    ? Container(
                        height: 260,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : _currentQuestion != null
                        ? QuestionCard(question: _currentQuestion!, onRefresh: () => _generateNewQuestion(useAI: true))
                        : const SizedBox(height: 240, child: Center(child: CircularProgressIndicator())),
              ),
              const SizedBox(height: 32),
              _buildMicOrb(theme),
              const SizedBox(height: 32),
              _buildLiveTranscript(theme),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSelectors(ThemeData theme) {
    final cats = ['All', 'Career', 'Education', 'Lifestyle', 'Technical'];
    final diffs = ['Beginner', 'Intermediate', 'Advanced'];

    return Column(
      children: [
        _horizontalChipList(cats, _selectedCategory ?? 'All', (val) {
          setState(() => _selectedCategory = val == 'All' ? null : val);
          _generateNewQuestion(useAI: true);
        }),
        const SizedBox(height: 12),
        _horizontalChipList(diffs, _selectedDifficulty ?? 'Intermediate', (val) {
          setState(() => _selectedDifficulty = val);
          _generateNewQuestion(useAI: true);
        }),
      ],
    );
  }

  Widget _horizontalChipList(List<String> items, String selected, Function(String) onSelect) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items.map((item) {
          final isSelected = item == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(item, style: GoogleFonts.outfit(fontSize: 12, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700)),
              selected: isSelected,
              onSelected: (_) => onSelect(item),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMicOrb(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Text(
            _isListening ? 'LISTENING NOW' : _processing ? 'COACH IS ANALYZING' : 'READY TO PRACTICE',
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () {
              if (_processing || _isStopping) return;
              _isListening ? _stopListening() : _startListening();
            },
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (ctx, child) => Container(
                width: 120, height: 120,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _isListening ? Colors.red.withOpacity(0.3) : theme.colorScheme.primary.withOpacity(0.2), width: 2),
                ),
                child: Transform.scale(
                  scale: _isListening ? _pulseAnim.value : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening 
                            ? [Colors.red, Colors.redAccent] 
                            : [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.red : theme.colorScheme.primary).withOpacity(0.4),
                          blurRadius: 20, spreadRadius: 5
                        )
                      ],
                    ),
                    child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 48),
                  ),
                ),
              ),
            ),
          ),
          if (_isListening) ...[
            const SizedBox(height: 16),
            VoiceWave(soundLevel: _soundLevel, isListening: _isListening),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveTranscript(ThemeData theme) {
    if (!_isListening && _liveText.isEmpty && _spokenText.isEmpty) return const SizedBox();
    final text = _isListening ? _liveText : _spokenText;
    if (text.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Row(children: [
              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 16),
              const SizedBox(width: 8),
              Text('REAL-TIME GLOW', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: theme.colorScheme.primary)),
            ]),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 16, height: 1.6, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.8)),
            ).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).shimmer(duration: 2000.ms, color: theme.colorScheme.primary.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}