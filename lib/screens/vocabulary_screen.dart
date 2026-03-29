import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});
  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  bool _loading = false;
  VocabularyWord? _currentWord;
  bool _showDetails = false;

  // Practice
  final _practiceCtrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechReady = false;
  bool _isListening = false;
  String _liveText = '';
  bool _evaluating = false;
  Map<String, dynamic>? _evalResult;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadDailyWord();
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (s) { if (s == 'done' || s == 'notListening') _stopVoice(); },
    );
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _loadDailyWord() async {
    setState(() { _loading = true; _showDetails = false; _evalResult = null; });
    try {
      final data = await AIFeedbackService.generateDailyWord();
      if (!mounted) return;
      final word = VocabularyWord(
        id: const Uuid().v4(),
        word: data['word'] ?? 'articulate',
        meaning: data['meaning'] ?? '',
        partOfSpeech: data['partOfSpeech'] ?? '',
        synonyms: List<String>.from(data['synonyms'] ?? []),
        antonyms: List<String>.from(data['antonyms'] ?? []),
        example: data['example'] ?? '',
        pronunciation: data['pronunciation'] ?? '',
      );
      final state = context.read<AppState>();
      state.addVocabWord(word);
      setState(() { _currentWord = word; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _evaluateUsage() async {
    final sentence = _practiceCtrl.text.trim();
    if (sentence.isEmpty || _currentWord == null) return;
    setState(() { _evaluating = true; _evalResult = null; });
    try {
      final result = await AIFeedbackService.evaluateVocabUsage(word: _currentWord!.word, userSentence: sentence);
      if (!mounted) return;
      final state = context.read<AppState>();
      state.addXP((result['xp'] as num).toInt());
      if (result['correct'] == true) {
        state.markVocabLearned(_currentWord!.id);
      }
      setState(() { _evalResult = result; _evaluating = false; });
    } catch (_) {
      setState(() => _evaluating = false);
    }
  }

  Future<void> _startVoice() async {
    if (!_speechReady) return;
    setState(() { _isListening = true; _liveText = ''; });
    await _speech.listen(
      onResult: (r) {
        setState(() => _liveText = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _stopVoice(send: true);
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      partialResults: true, localeId: 'en_US',
    );
  }

  Future<void> _stopVoice({bool send = false}) async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (send && _liveText.isNotEmpty) {
      _practiceCtrl.text = _liveText;
      _evaluateUsage();
    }
  }

  @override
  void dispose() { _practiceCtrl.dispose(); _speech.stop(); _tts.stop(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Vocabulary Builder 📖'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadDailyWord, tooltip: 'New Word'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _currentWord == null
              ? const Center(child: Text('Error loading word', style: TextStyle(color: Colors.white54)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Stats bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _miniStat('📚', '${state.profile.wordsLearned}', 'Learned'),
                        _miniStat('🔥', '${state.profile.challengeStreak}', 'Streak'),
                        _miniStat('⭐', '${state.profile.totalXP}', 'Total XP'),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Word Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.12), AppTheme.secondary.withOpacity(0.08)]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(children: [
                        Text('Word of the Day', style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Text(_currentWord!.word.toUpperCase(), style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: 2)),
                        if (_currentWord!.pronunciation.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _tts.speak(_currentWord!.word),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.volume_up_rounded, color: AppTheme.accent, size: 16),
                              const SizedBox(width: 4),
                              Text(_currentWord!.pronunciation, style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 13)),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(_currentWord!.partOfSpeech, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 12),
                        Text(_currentWord!.meaning, textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, height: 1.5)),
                      ]),
                    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                    const SizedBox(height: 16),

                    // Show/Hide details
                    GestureDetector(
                      onTap: () => setState(() => _showDetails = !_showDetails),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_showDetails ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 6),
                          Text(_showDetails ? 'Hide Details' : 'Show Synonyms, Antonyms & Example',
                            style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),

                    if (_showDetails) ...[
                      const SizedBox(height: 12),
                      if (_currentWord!.synonyms.isNotEmpty) _detailRow('Synonyms', _currentWord!.synonyms.join(', '), AppTheme.primary),
                      if (_currentWord!.antonyms.isNotEmpty) _detailRow('Antonyms', _currentWord!.antonyms.join(', '), AppTheme.danger),
                      if (_currentWord!.example.isNotEmpty) _detailRow('Example', _currentWord!.example, AppTheme.accent),
                    ],

                    const SizedBox(height: 24),

                    // Practice Section
                    Text('Practice: Use it in a sentence', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Type or speak a sentence using "${_currentWord!.word}"',
                      style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
                    const SizedBox(height: 12),

                    if (_isListening && _liveText.isNotEmpty)
                      Container(
                        width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                        child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13)),
                      ),

                    Row(children: [
                      Expanded(child: TextField(
                        controller: _practiceCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(hintText: 'Type your sentence...', isDense: true),
                      )),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _isListening ? _stopVoice(send: true) : _startVoice(),
                        child: Container(width: 40, height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: _isListening ? AppTheme.danger.withOpacity(0.15) : AppTheme.darkSurface),
                          child: Icon(_isListening ? Icons.stop : Icons.mic, color: _isListening ? AppTheme.danger : Colors.white54, size: 18)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: ElevatedButton(
                      onPressed: _evaluating ? null : _evaluateUsage,
                      child: _evaluating
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkBg))
                          : const Text('Check Usage 🤖'),
                    )),

                    if (_evalResult != null) ...[
                      const SizedBox(height: 16),
                      _buildEvalResult(),
                    ],
                    const SizedBox(height: 24),
                  ]),
                ),
    );
  }

  Widget _miniStat(String emoji, String value, String label) => Column(children: [
    Text(emoji, style: const TextStyle(fontSize: 18)),
    Text(value, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    Text(label, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10)),
  ]);

  Widget _detailRow(String label, String value, Color color) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.dmSans(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(value, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
    ]),
  );

  Widget _buildEvalResult() {
    final correct = _evalResult!['correct'] == true;
    final score = (_evalResult!['score'] as num?)?.toDouble() ?? 7.0;
    final color = correct ? AppTheme.primary : AppTheme.danger;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(correct ? '✅ Correct!' : '❌ Try Again', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
          const Spacer(),
          Text('${score.toStringAsFixed(1)}/10', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Text(_evalResult!['feedback'] ?? '', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
        if ((_evalResult!['betterExample'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text('💡 Better example:', style: GoogleFonts.dmSans(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w700)),
          Text(_evalResult!['betterExample'], style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
        if ((_evalResult!['tip'] as String?)?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Text('📝 ${_evalResult!['tip']}', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Text('+${_evalResult!['xp']} XP ⭐', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700)),
      ]),
    ).animate().fadeIn();
  }
}
