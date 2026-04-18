import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/speech_service.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DAILY CHALLENGE SCREEN – Hub that shows today's 3 quests
// ─────────────────────────────────────────────────────────────────────────────
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureChallenges());
  }

  Future<void> _ensureChallenges() async {
    final state = context.read<AppState>();
    final today = DateTime.now();
    final todaysChallenges = state.dailyChallenges.where((c) =>
        c.date.year == today.year && c.date.month == today.month && c.date.day == today.day);
    
    if (todaysChallenges.isEmpty) {
      setState(() => _isGenerating = true);
      try {
        final quests = await AIFeedbackService.generateDailyQuests(
          role: state.profile.targetRole,
          difficulty: state.profile.difficulty,
        );

        if (quests.isNotEmpty) {
          state.setDailyChallenges(quests.map((q) => DailyChallenge(
            id: const Uuid().v4(),
            type: q['type'],
            title: q['title'],
            description: q['description'],
            xpReward: q['xp'] ?? 30,
            dynamicContent: q,
          )).toList());
        } else {
          // Fallback to static if AI fails
          state.setDailyChallenges([
            DailyChallenge(
              id: const Uuid().v4(), type: 'shadow',
              title: 'Echo Mimic',
              description: 'Listen to the audio clip and repeat it perfectly.',
              xpReward: 30,
              dynamicContent: {'content': 'The early bird catches the worm.'},
            ),
            DailyChallenge(
              id: const Uuid().v4(), type: 'detective',
              title: 'Error Hunt',
              description: 'Find the 3 hidden grammar mistakes in the paragraph.',
              xpReward: 25,
              dynamicContent: {
                'content': ['She', 'go', 'to', 'school', 'everyday', 'and', 'they', 'enjoys', 'it', 'too'],
                'errors': {'1': 'goes', '7': 'enjoy', '4': 'every day'}
              },
            ),
            DailyChallenge(
              id: const Uuid().v4(), type: 'connect',
              title: 'Word Link',
              description: 'Connect 2 random words into a spoken story.',
              xpReward: 35,
              dynamicContent: {'content': ['ocean', 'clock']},
            ),
          ]);
        }
      } catch (e) {
        debugPrint('Quest generation error: $e');
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todaysChallenges = state.dailyChallenges.where((c) =>
        c.date.year == today.year && c.date.month == today.month && c.date.day == today.day).toList();
    final completed = todaysChallenges.where((c) => c.completed).length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Daily Challenges', style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
      ),
      body: _isGenerating
        ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text('Generating today\'s quests...', style: theme.textTheme.bodyMedium),
            ],
          ))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Streak + Progress Card ───────────────────────────────────────────
          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              Column(children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Text('🔥', style: TextStyle(fontSize: 32)),
                ),
                const SizedBox(height: 8),
                Text('${state.profile.challengeStreak}', style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary, fontSize: 24)),
                const SizedBox(height: 4),
                Text('DAY STREAK', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary.withOpacity(0.6), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1.2)),
              ]),
              const SizedBox(width: 32),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Daily Progress', style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text('$completed of ${todaysChallenges.length} complete', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 16),
                Stack(children: [
                  Container(height: 10, decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(5))),
                  FractionallySizedBox(
                    widthFactor: todaysChallenges.isEmpty ? 0 : completed / todaysChallenges.length,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 8)],
                      ),
                    ),
                  ),
                ]),
              ])),
            ]),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 40),
          _sectionHeader(context, 'TODAY\'S QUESTS'),
          const SizedBox(height: 16),

          ...todaysChallenges.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final meta = _challengeMeta(c.type);

            return GestureDetector(
              onTap: c.completed ? null : () => _openChallenge(c),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: c.completed ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05)),
                  boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: (c.completed ? AppTheme.primary : meta['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(child: Text(c.completed ? '✅' : meta['emoji'] as String, style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: theme.textTheme.titleMedium?.copyWith(
                      color: c.completed ? theme.colorScheme.primary : theme.textTheme.titleMedium?.color,
                      fontWeight: FontWeight.w800, fontSize: 15,
                      decoration: c.completed ? TextDecoration.lineThrough : null,
                    )),
                    const SizedBox(height: 4),
                    Text(c.description, style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, height: 1.3, fontWeight: FontWeight.w500)),
                  ])),
                  const SizedBox(width: 12),
                  Column(children: [
                    Text('+${c.xpReward}', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                    Text('XP', style: GoogleFonts.dmSans(color: theme.colorScheme.primary.withOpacity(0.5), fontWeight: FontWeight.w800, fontSize: 10)),
                  ]),
                ]),
              ),
            ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.05);
          }),

          const SizedBox(height: 24),

          if (completed == todaysChallenges.length && todaysChallenges.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 40),
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(children: [
                const Text('🏆', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text('CHAMPION!', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('You\'ve cleared all challenges for today.', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Map<String, dynamic> _challengeMeta(String type) {
    switch (type) {
      case 'shadow':   return {'emoji': '🔊', 'color': Colors.orange};
      case 'detective': return {'emoji': '🔍', 'color': Colors.redAccent};
      case 'connect':  return {'emoji': '🔗', 'color': Colors.teal};
      default:         return {'emoji': '⭐', 'color': AppTheme.primary};
    }
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Row(children: [
      Text(title, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: theme.colorScheme.onSurface.withOpacity(0.4))),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: theme.dividerColor.withOpacity(0.1), thickness: 1)),
    ]);
  }

  void _openChallenge(DailyChallenge challenge) async {
    final passed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) {
        final content = challenge.dynamicContent?['content'];
        switch (challenge.type) {
          case 'shadow':    
            return _EchoMimicChallenge(sentence: content as String? ?? 'Practice makes perfect.');
          case 'detective': 
            return _ErrorHuntChallenge(
              words: List<String>.from(content as List? ?? []),
              errors: Map<int, String>.from((challenge.dynamicContent?['errors'] as Map?)?.map((k, v) => MapEntry(int.parse(k.toString()), v.toString())) ?? {}),
            );
          case 'connect':   
            return _WordLinkChallenge(pair: List<String>.from(content as List? ?? ['ocean', 'clock']));
          default:          
            return _EchoMimicChallenge(sentence: content as String? ?? 'Practice makes perfect.');
        }
      }),
    );

    if (passed == true && mounted) {
      final state = context.read<AppState>();
      state.completeDailyChallenge(challenge.id);
      state.addXP(challenge.xpReward);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${challenge.title} completed! +${challenge.xpReward} XP ⭐'),
        backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating,
      ));
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHALLENGE 1 — ECHO MIMIC  (audio_similarity > 0.8)
// ═════════════════════════════════════════════════════════════════════════════
class _EchoMimicChallenge extends StatefulWidget {
  final String sentence;
  const _EchoMimicChallenge({required this.sentence});
  @override
  State<_EchoMimicChallenge> createState() => _EchoMimicChallengeState();
}

class _EchoMimicChallengeState extends State<_EchoMimicChallenge> with WidgetsBindingObserver {
  final FlutterTts _tts = AppState.tts;
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _hasPlayed = false;
  String _spokenText = '';
  String _liveText = '';
  double? _similarity;
  bool _passed = false;

  late String _currentClip;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentClip = widget.sentence;
    _configureTts();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _tts.stop();
      if (_isRecording) _stopRecording();
    }
  }

  Future<void> _configureTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _playClip() async {
    setState(() { _isPlaying = true; _hasPlayed = true; });
    await _tts.speak(_currentClip);
  }

  Future<void> _startRecording() async {
    setState(() { _isRecording = true; _liveText = ''; _spokenText = ''; _similarity = null; _passed = false; });
    final speech = context.read<SpeechService>();
    await speech.listen(
      onResult: (text, isFinal) => setState(() => _liveText = text),
      listenFor: const Duration(seconds: 15),
      partialResults: true,
    );
  }

  Future<void> _stopRecording() async {
    final speech = context.read<SpeechService>();
    await speech.stop();
    setState(() {
      _isRecording = false;
      _spokenText = _liveText;
    });
    _evaluate();
  }

  void _evaluate() {
    final sim = _calculateSimilarity(
      _currentClip.toLowerCase().trim(),
      _spokenText.toLowerCase().trim(),
    );
    setState(() {
      _similarity = sim;
      _passed = sim >= 0.8;
    });
  }

  double _calculateSimilarity(String reference, String spoken) {
    if (spoken.isEmpty) return 0.0;
    final refWords = reference.replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    final spkWords = spoken.replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
    if (refWords.isEmpty) return 0.0;

    int matched = 0;
    int spkIdx = 0;
    for (final rw in refWords) {
      for (int j = spkIdx; j < spkWords.length; j++) {
        if (_wordMatch(rw, spkWords[j])) {
          matched++;
          spkIdx = j + 1;
          break;
        }
      }
    }
    return matched / refWords.length;
  }

  bool _wordMatch(String a, String b) {
    if (a == b) return true;
    if (a.length > 3 && b.length > 3) {
      int diff = 0;
      final minL = min(a.length, b.length);
      final maxL = max(a.length, b.length);
      for (int i = 0; i < minL; i++) {
        if (a[i] != b[i]) diff++;
      }
      diff += maxL - minL;
      return diff <= 1;
    }
    return false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = ((_similarity ?? 0) * 100).toInt();
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Echo Mimic 🔊', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.orange.withOpacity(0.15)),
            ),
            child: Column(children: [
              Text('STEP 1: LISTEN', style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Tap play to hear the sentence, then repeat it as accurately as you can.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ]),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 28),

          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.02), blurRadius: 10)],
            ),
            child: _similarity != null
              ? Text('"$_currentClip"', textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontStyle: FontStyle.italic))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.visibility_off_rounded, color: theme.colorScheme.onSurface.withOpacity(0.15), size: 20),
                  const SizedBox(width: 8),
                  Text('Sentence hidden until attempt', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.3))),
                ]),
          ),

          const SizedBox(height: 32),

          GestureDetector(
            onTap: _isPlaying || _isRecording ? null : _playClip,
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(_isPlaying ? 0.2 : 0.08),
                border: Border.all(color: Colors.orange, width: 3),
                boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.15), blurRadius: 15)],
              ),
              child: Icon(_isPlaying ? Icons.volume_up_rounded : Icons.play_arrow_rounded,
                color: Colors.orange, size: 44),
            ),
          ).animate(target: _isPlaying ? 1 : 0).shimmer(duration: 1200.ms),

          const SizedBox(height: 12),
          Text(_isPlaying ? 'Playing...' : 'Listen', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),

          const SizedBox(height: 40),

          if (_hasPlayed && _similarity == null) ...[
            Text('STEP 2: REPEAT', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _isPlaying ? null : (_isRecording ? _stopRecording : _startRecording),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_isRecording ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.08),
                  border: Border.all(color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary, width: 3),
                  boxShadow: [BoxShadow(color: (_isRecording ? theme.colorScheme.error : theme.colorScheme.primary).withOpacity(0.15), blurRadius: 15)],
                ),
                child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: _isRecording ? theme.colorScheme.error : theme.colorScheme.primary, size: 48),
              ),
            ).animate(target: _isRecording ? 1 : 0).shimmer(duration: 1000.ms),
            const SizedBox(height: 12),
            Text(_isRecording ? 'Listening...' : 'Speak Now', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
            if (_liveText.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(_liveText, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.7))),
            ],
          ],

          if (_similarity != null) ...[
            const SizedBox(height: 32),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: (_passed ? theme.colorScheme.primary : theme.colorScheme.error).withOpacity(0.3)),
                boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Column(children: [
                Text(_passed ? '🎉' : '😅', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(_passed ? 'EXCELLENT!' : 'PRACTICE MORE', style: theme.textTheme.titleLarge?.copyWith(
                  color: _passed ? theme.colorScheme.primary : theme.colorScheme.error,
                  fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                const SizedBox(height: 24),
                Text('$pct%', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 48)),
                Text('ACCURACY', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 24),
                if (_spokenText.isNotEmpty) ...[
                  const Divider(height: 32),
                  Text('YOU SAID', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('"$_spokenText"', textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                ],
                const SizedBox(height: 32),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (!_passed)
                    Expanded(child: OutlinedButton(onPressed: () => setState(() { _similarity = null; _spokenText = ''; _liveText = ''; }), child: const Text('Try Again'))),
                  if (_passed)
                    Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Claim Reward →'))),
                ]),
              ]),
            ).animate().scale(begin: const Offset(0.95, 0.95)).fadeIn(),
          ],
          const SizedBox(height: 48),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHALLENGE 2 — ERROR HUNT  (errors_found == 3)
// ═════════════════════════════════════════════════════════════════════════════
class _ErrorHuntChallenge extends StatefulWidget {
  final List<String> words;
  final Map<int, String> errors;
  const _ErrorHuntChallenge({required this.words, required this.errors});
  @override
  State<_ErrorHuntChallenge> createState() => _ErrorHuntChallengeState();
}

class _ErrorHuntChallengeState extends State<_ErrorHuntChallenge> {
  int _correctFound = 0;
  Map<String, dynamic> _passage = {};
  bool _submitted = false;
  final Set<int> _tappedIndices = {};

  @override
  void initState() {
    super.initState();
    _passage = {
      'words': widget.words,
      'errors': widget.errors,
    };
  }

  void _onWordTap(int index) {
    if (_submitted) return;
    setState(() {
      if (_tappedIndices.contains(index)) {
        _tappedIndices.remove(index);
      } else {
        if (_tappedIndices.length < 3) {
          _tappedIndices.add(index);
        } else {
          _tappedIndices.remove(_tappedIndices.first);
          _tappedIndices.add(index);
        }
      }
    });
  }

  void _submit() {
    final errorIndices = (_passage['errors'] as Map<int, String>).keys.toSet();
    final correct = _tappedIndices.intersection(errorIndices).length;
    setState(() {
      _submitted = true;
      _correctFound = correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final words = _passage['words'] as List<String>;
    final errorMap = _passage['errors'] as Map<int, String>;
    final errorIndices = errorMap.keys.toSet();
    final passed = _submitted && _correctFound == 3;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Error Hunt 🔍', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.error.withOpacity(0.15)),
            ),
            child: Column(children: [
              Text('FIND THE ERRORS', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('This paragraph has exactly 3 grammar mistakes. Tap on the wrong words to highlight them.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 14, height: 14, decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.3), borderRadius: BorderRadius.circular(4), border: Border.all(color: theme.colorScheme.primary))),
                const SizedBox(width: 8),
                Text('Selected: ${_tappedIndices.length}/3', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
              ]),
            ]),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 32),

          Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor, borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 15)],
            ),
            child: Wrap(
              spacing: 6, runSpacing: 12,
              children: List.generate(words.length, (i) {
                final isSelected = _tappedIndices.contains(i);
                final isError = errorIndices.contains(i);
                Color bg = Colors.transparent;
                Color textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
                BoxBorder? border;

                if (_submitted) {
                  if (isError && isSelected) {
                    bg = theme.colorScheme.primary.withOpacity(0.15);
                    textColor = theme.colorScheme.primary;
                    border = Border.all(color: theme.colorScheme.primary, width: 2);
                  } else if (isError && !isSelected) {
                    bg = theme.colorScheme.error.withOpacity(0.1);
                    textColor = theme.colorScheme.error;
                    border = Border.all(color: theme.colorScheme.error, width: 2);
                  } else if (!isError && isSelected) {
                    bg = theme.colorScheme.primary.withOpacity(0.1);
                    textColor = theme.colorScheme.primary;
                    border = Border.all(color: theme.colorScheme.primary, width: 1.5);
                  }
                } else if (isSelected) {
                  bg = theme.colorScheme.primary.withOpacity(0.15);
                  textColor = theme.colorScheme.primary;
                  border = Border.all(color: theme.colorScheme.primary, width: 2);
                }

                return GestureDetector(
                  onTap: () => _onWordTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: border),
                    child: Text(words[i], style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, fontSize: 16, height: 1.5,
                    )),
                  ),
                );
              }),
            ),
          ),

          if (_submitted) ...[
            const SizedBox(height: 32),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor, borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CORRECTIONS', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                ...errorMap.entries.map((e) {
                  final found = _tappedIndices.contains(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Icon(found ? Icons.check_circle : Icons.cancel, color: found ? theme.colorScheme.primary : theme.colorScheme.error, size: 20),
                      const SizedBox(width: 12),
                      Text(words[e.key], style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.onSurface.withOpacity(0.2), size: 16),
                      const SizedBox(width: 12),
                      Text(e.value, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                    ]),
                  );
                }),
              ]),
            ).animate().fadeIn().slideY(begin: 0.1),
          ],

          const SizedBox(height: 48),

          if (!_submitted && _tappedIndices.length == 3)
            SizedBox(width: double.infinity, height: 60, child: ElevatedButton(onPressed: _submit, child: const Text('Check My Selection →'))).animate().fadeIn().scale(),

          if (_submitted) ...[
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: (passed ? theme.colorScheme.primary : theme.colorScheme.error).withOpacity(0.3)),
                boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Column(children: [
                Text(
                  _correctFound == 3 ? '🥇' : _correctFound == 2 ? '🥈' : '🥉', 
                  style: const TextStyle(fontSize: 48)
                ),
                const SizedBox(height: 12),
                Text(
                  passed ? 'EXPERT UNLOCKED!' : 'GOOD EFFORT!', 
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: passed ? theme.colorScheme.primary : theme.colorScheme.error, 
                    fontWeight: FontWeight.w900
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  'Found $_correctFound of 3 errors',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (!passed)
                    Expanded(child: OutlinedButton(onPressed: () => setState(() { _submitted = false; _tappedIndices.clear(); _correctFound = 0; }), child: const Text('Try Again'))),
                  if (passed)
                    Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Claim Reward →'))),
                ]),
              ]),
            ).animate().scale().fadeIn(),
          ],
          const SizedBox(height: 48),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHALLENGE 3 — WORD LINK  (transcript.contains(word1 && word2))
// ═════════════════════════════════════════════════════════════════════════════
class _WordLinkChallenge extends StatefulWidget {
  final List<String> pair;
  const _WordLinkChallenge({required this.pair});
  @override
  State<_WordLinkChallenge> createState() => _WordLinkChallengeState();
}

class _WordLinkChallengeState extends State<_WordLinkChallenge> with WidgetsBindingObserver {
  bool _isRecording = false;
  String _liveText = '';
  String _spokenText = '';
  bool? _word1Found;
  bool? _word2Found;
  bool _evaluated = false;

  late String _word1;
  late String _word2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _word1 = widget.pair[0]; _word2 = widget.pair[1];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive) && _isRecording) {
      _stopRecording();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() { _isRecording = true; _liveText = ''; _spokenText = ''; _evaluated = false; _word1Found = null; _word2Found = null; });
    final speech = context.read<SpeechService>();
    await speech.listen(onResult: (text, isFinal) => setState(() => _liveText = text), listenFor: const Duration(seconds: 30), partialResults: true);
  }

  Future<void> _stopRecording() async {
    final speech = context.read<SpeechService>();
    await speech.stop();
    setState(() { _isRecording = false; _spokenText = _liveText; });
    _evaluate();
  }

  void _evaluate() {
    final lower = _spokenText.toLowerCase();
    setState(() { _word1Found = lower.contains(_word1.toLowerCase()); _word2Found = lower.contains(_word2.toLowerCase()); _evaluated = true; });
  }

  bool get _passed => _word1Found == true && _word2Found == true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Word Link 🔗', style: theme.textTheme.titleLarge),
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, false)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.teal.withOpacity(0.2)),
            ),
            child: Column(children: [
              Text('YOUR MISSION', style: theme.textTheme.bodySmall?.copyWith(color: Colors.teal, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text('Create a short story or sentence that uses BOTH of the words below.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
            ]),
          ).animate().fadeIn().slideY(begin: 0.1),

          const SizedBox(height: 32),

          Row(children: [
            Expanded(child: _wordCard(context, _word1, _word1Found)),
            const SizedBox(width: 16),
            Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: theme.cardColor, border: Border.all(color: Colors.teal.withOpacity(0.2))), child: const Center(child: Text('🔗', style: TextStyle(fontSize: 20)))),
            const SizedBox(width: 16),
            Expanded(child: _wordCard(context, _word2, _word2Found)),
          ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 48),

          if (!_evaluated) ...[
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (_isRecording ? theme.colorScheme.error : Colors.teal).withOpacity(0.08),
                  border: Border.all(color: _isRecording ? theme.colorScheme.error : Colors.teal, width: 3),
                  boxShadow: [BoxShadow(color: (_isRecording ? theme.colorScheme.error : Colors.teal).withOpacity(0.15), blurRadius: 20)],
                ),
                child: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded, color: _isRecording ? theme.colorScheme.error : Colors.teal, size: 48),
              ),
            ).animate(target: _isRecording ? 1 : 0).shimmer(duration: 1200.ms),
            const SizedBox(height: 12),
            Text(_isRecording ? 'Listening...' : 'Hold to Speak', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
          ],

          if (_liveText.isNotEmpty && !_evaluated) ...[
            const SizedBox(height: 32),
            Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: theme.cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withOpacity(0.05))), child: Text(_liveText, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic))),
          ],

          if (_evaluated) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.1))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('YOUR TRANSCRIPT', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _highlightedTranscript(context),
            ])),
            const SizedBox(height: 32),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor, borderRadius: BorderRadius.circular(24),
                border: Border.all(color: (_passed ? theme.colorScheme.primary : theme.colorScheme.error).withOpacity(0.3)),
                boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20)],
              ),
              child: Column(children: [
                Text(_passed ? '🎉' : '🔗', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(_passed ? 'LINK CREATED!' : 'TRY AGAIN', style: theme.textTheme.titleLarge?.copyWith(color: _passed ? theme.colorScheme.primary : theme.colorScheme.error, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (!_passed)
                    Expanded(child: OutlinedButton(onPressed: () => setState(() { _evaluated = false; _spokenText = ''; _liveText = ''; _word1Found = null; _word2Found = null; }), child: const Text('New Attempt'))),
                  if (_passed)
                    Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Claim Reward →'))),
                ]),
              ]),
            ).animate().scale().fadeIn(),
          ],
          const SizedBox(height: 48),
        ]),
      ),
    );
  }

  Widget _wordCard(BuildContext context, String word, bool? found) {
    final theme = Theme.of(context);
    final color = found == null ? Colors.teal : (found ? theme.colorScheme.primary : theme.colorScheme.error);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4), width: 2)),
      child: Column(children: [
        if (found != null) Icon(found ? Icons.check_circle : Icons.cancel, color: color, size: 24),
        if (found != null) const SizedBox(height: 8),
        Text(word.toUpperCase(), textAlign: TextAlign.center, style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
      ]),
    );
  }

  Widget _highlightedTranscript(BuildContext context) {
    final theme = Theme.of(context);
    final words = _spokenText.split(RegExp(r'\s+'));
    return Wrap(
      spacing: 4, runSpacing: 4,
      children: words.map((w) {
        final clean = w.toLowerCase().replaceAll(RegExp(r'[^\w]'), '');
        final highlight = clean == _word1.toLowerCase() || clean == _word2.toLowerCase();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(color: highlight ? Colors.teal.withOpacity(0.15) : null, borderRadius: BorderRadius.circular(4)),
          child: Text(w, style: theme.textTheme.bodyMedium?.copyWith(color: highlight ? Colors.teal : theme.textTheme.bodyMedium?.color, fontWeight: highlight ? FontWeight.w900 : FontWeight.w500)),
        );
      }).toList(),
    );
  }
}
