import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/speech_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  bool _showDetails = false;
  final TextEditingController _practiceCtrl = TextEditingController();
  final FlutterTts _tts = AppState.tts;
  bool _isListening = false;
  String _liveText = '';
  bool _evaluating = false;
  Map<String, dynamic>? _evalResult;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final speechService = context.read<SpeechService>();
    await speechService.init(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
  }

  Future<void> _initTts() async {
    final state = context.read<AppState>();
    await AppState.configureTts(_tts, state);
  }

  Future<void> _evaluateUsage() async {
    final state = context.read<AppState>();
    final wordObj = state.wordOfTheDay;
    final sentence = _practiceCtrl.text.trim();
    if (sentence.isEmpty) return;
    
    setState(() { _evaluating = true; _evalResult = null; });
    try {
      final result = await AIFeedbackService.evaluateVocabUsage(word: wordObj.word, example: sentence);
      if (!mounted) return;
      
      state.addXP((result['xp'] as num).toInt());
      if (result['isCorrect'] == true) {
        state.markVocabLearned(wordObj.id);
      }
      
      if (mounted) {
        setState(() { 
          _evalResult = result; 
          _evaluating = false; 
        });
      }
      
      // Feedback Audio Tip
      if (result['isCorrect'] == true) {
        _speakSafe("Perfectly used!");
      }
    } catch (_) {
      if (mounted) setState(() => _evaluating = false);
    }
  }

  Future<void> _speakSafe(String text) async {
    if (!mounted || _isSpeaking) return;
    try {
      _isSpeaking = true;
      await _tts.speak(text);
      _isSpeaking = false;
    } catch (_) {
      _isSpeaking = false;
    }
  }

  Future<void> _startVoice() async {
    final speechService = context.read<SpeechService>();
    setState(() { _isListening = true; _liveText = ''; });
    await speechService.listen(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _liveText = text;
            if (isFinal) {
              _isListening = false;
              _checkPronunciation(text);
            }
          });
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  Future<void> _checkPronunciation(String text) async {
    final state = context.read<AppState>();
    final targetWord = state.wordOfTheDay.word.toLowerCase().trim();
    final spokenText = text.toLowerCase().trim();
    
    // Simple check: does the spoken text contain the target word?
    final bool match = spokenText.contains(targetWord);
    
    setState(() {
      _evalResult = {
        'isCorrect': match,
        'xp': match ? 10 : 2,
        'feedback': match 
            ? "Great pronunciation! I heard you say '$text'." 
            : "I heard '$text', but I was listening for '$targetWord'. Try again!",
        'improvedExample': match ? null : "Try to emphasize the '${targetWord[0]}' sound."
      };
    });

    if (match) {
      state.addXP(10);
      _speakSafe("Well done!");
    } else {
      state.addXP(2);
      _speakSafe("Let's try that again.");
    }
  }

  Future<void> _stopVoice({bool send = false}) async {
    final speechService = context.read<SpeechService>();
    await speechService.stop();
    if (mounted) setState(() => _isListening = false);
    if (send && _liveText.isNotEmpty) {
      _practiceCtrl.text = _liveText;
      _evaluateUsage();
    }
  }

  @override
  void dispose() { 
    _practiceCtrl.dispose(); 
    _tts.stop(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final word = state.wordOfTheDay;
    

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Vocabulary Explorer', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories_rounded), // Distinguishable from refresh
            onPressed: () {}, // History view
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.secondary.withOpacity(0.2),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: state.isRefreshingWord
            ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildStatsBar(theme, state),
                  const SizedBox(height: 32),
                  
                  // Main Content Card
                  _buildMainWordCard(theme, word),
                  
                  const SizedBox(height: 16),
                  
                  _buildDetailsToggle(theme),
                  
                  if (_showDetails) 
                    _buildDetailsExpansion(theme, word).animate().fadeIn(),
                    
                  const SizedBox(height: 40),
                  
                  _buildPracticeSection(theme, word),
                  
                  if (_evalResult != null)
                    _buildEvalResult(theme).animate().fadeIn().slideY(begin: 0.1),
                    
                  const SizedBox(height: 40),
                  
                  _buildHistorySection(theme, state),
                ]),
              ),
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme, AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('📚', state.profile.wordsLearned, 'Learned'),
              _statItem('🔥', state.profile.streakDays, 'Streak'),
              _statItem('⭐', state.profile.totalXP, 'Total XP'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String emoji, int val, String label) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(height: 4),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: val.toDouble()),
        duration: const Duration(seconds: 1),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Text(
            value.toInt().toString(),
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
          );
        },
      ),
      Text(label, style: GoogleFonts.outfit(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
    ]);
  }

  Widget _buildMainWordCard(ThemeData theme, VocabularyWord word) {
    final bool hasViz = word.imageUrl != null && word.imageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          if (hasViz)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Image.network(
                word.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  height: 200, 
                  color: theme.colorScheme.primary.withOpacity(0.05),
                  child: Center(child: Icon(Icons.image_outlined, color: theme.colorScheme.primary.withOpacity(0.2), size: 48)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Text('WORD OF THE DAY', 
                  style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
                const SizedBox(height: 16),
                FittedBox(
                  child: Text(word.word.toUpperCase(), 
                    style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1, color: theme.colorScheme.onSurface)),
                ),
                const SizedBox(height: 12),
                _buildPronunciationBadge(theme, word),
                const SizedBox(height: 24),
                Text(word.meaning, textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500)),
                if (word.translatedMeaning != null && word.translatedMeaning != word.meaning)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                      child: Text(word.translatedMeaning!, 
                        style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, fontSize: 13)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
  }

  Widget _buildPronunciationBadge(ThemeData theme, VocabularyWord word) {
    return GestureDetector(
      onTap: () => _speakSafe(word.word),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_up_rounded, color: theme.colorScheme.primary, size: 16),
            const SizedBox(width: 8),
            Text(word.pronunciation, 
              style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsToggle(ThemeData theme) {
    return GestureDetector(
      onTap: () => setState(() => _showDetails = !_showDetails),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_showDetails ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(_showDetails ? 'Hide Details' : 'Synonyms, Antonyms & Examples',
              style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsExpansion(ThemeData theme, VocabularyWord word) {
    return Column(children: [
      const SizedBox(height: 12),
      if (word.synonyms.isNotEmpty) _detailBox('Synonyms', word.synonyms.join(', '), theme.colorScheme.primary),
      if (word.antonyms.isNotEmpty) _detailBox('Antonyms', word.antonyms.join(', '), AppTheme.danger),
      if (word.example.isNotEmpty) _detailBox('Real-world Example', word.example, theme.colorScheme.tertiary),
    ]);
  }

  Widget _detailBox(String title, String val, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildPracticeSection(ThemeData theme, VocabularyWord word) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Practice Mastery', 
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Build a professional sentence using "${word.word}"', 
          style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),
        
        if (_isListening && _liveText.isNotEmpty)
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.danger.withOpacity(0.1))),
            child: Text(_liveText, style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.danger, fontWeight: FontWeight.w600)),
          ).animate().shake(),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _practiceCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'I will use this logic in my next...',
                  fillColor: Colors.white,
                  filled: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: _isListening ? AppTheme.danger : theme.colorScheme.primary, shape: BoxShape.circle),
                child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _evaluating ? null : _evaluateUsage,
            child: _evaluating 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('Evaluate Sentence', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _buildEvalResult(ThemeData theme) {
    final correct = _evalResult!['isCorrect'] == true;
    final color = correct ? theme.colorScheme.primary : AppTheme.danger;

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)), child: Text(correct ? 'EXCELLENT' : 'NEEDS WORK', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))),
              const Spacer(),
              Text('+${_evalResult!['xp']} XP', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          Text(_evalResult!['feedback'] ?? '', style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, height: 1.5)),
          if (_evalResult!['improvedExample'] != null) ...[
            const SizedBox(height: 16),
            Text('BETTER VERSION:', style: GoogleFonts.outfit(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w900, fontSize: 10)),
            const SizedBox(height: 4),
            Text(_evalResult!['improvedExample'], style: GoogleFonts.dmSans(fontStyle: FontStyle.italic, color: theme.colorScheme.tertiary)),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme, AppState state) {
    // Show last 3 learned words
    final learned = state.vocabulary.where((v) => v.learned).toList().reversed.take(3).toList();
    if (learned.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mastered Recent', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: learned.length,
            itemBuilder: (context, index) {
              final v = learned[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1))),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(v.word, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Learned ✅', style: GoogleFonts.outfit(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
