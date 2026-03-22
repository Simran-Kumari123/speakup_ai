import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../models/question_model.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/question_service.dart';
import '../theme/app_theme.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/question_card.dart';
import '../widgets/selector_widgets.dart';
import '../widgets/ai_error_widget.dart';   // ✅ ADDED
import '../widgets/ai_loading_widget.dart'; // ✅ ADDED

class SpeakingScreen extends StatefulWidget {
  const SpeakingScreen({super.key});
  @override
  State<SpeakingScreen> createState() => _SpeakingScreenState();
}

class _SpeakingScreenState extends State<SpeakingScreen> with TickerProviderStateMixin {

  final SpeechToText _speech = SpeechToText();
  final FlutterTts   _tts    = FlutterTts();
  late QuestionService _questionService;

  bool   _speechAvailable = false;
  bool   _isListening     = false;
  bool   _processing      = false;
  String _spokenText      = '';
  String _liveText        = '';
  String _errorMessage    = '';
  ChatMessage? _feedback;
  double _soundLevel      = 0.0;

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  Question? _currentQuestion;
  String? _selectedCategory;
  String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    
    _questionService = QuestionService();
    _generateNewQuestion();
    
    _initSpeech();
    _initTts();
  }

  void _generateNewQuestion() {
    final question = _questionService.getRandomQuestion(
      type: 'speaking',
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
    );
    setState(() {
      _currentQuestion = question;
      _spokenText = '';
      _liveText = '';
      _feedback = null;
      _errorMessage = '';
    });
  }

  List<String> _getCategories() {
    return _questionService.getCategories(type: 'speaking');
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onError: (e) => _showError('Mic error: ${e.errorMsg}'),
      onStatus: (status) {
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _stopListening();
        }
      },
    );
    setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showError('Microphone not available. Please grant permission.');
      return;
    }
    setState(() { _isListening = true; _liveText = ''; _spokenText = ''; _feedback = null; });

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      onSoundLevelChange: (level) => setState(() => _soundLevel = level),
      localeId: 'en_US',
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_liveText.trim().isNotEmpty) {
      setState(() { _spokenText = _liveText; _processing = true; });
      await _processVoice();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() => _liveText = result.recognizedWords);
    if (result.finalResult && result.recognizedWords.isNotEmpty) {
      setState(() { _spokenText = result.recognizedWords; _isListening = false; _processing = true; });
      _processVoice();
    }
  }

  Future<void> _processVoice() async {
    setState(() => _errorMessage = '');
    try {
      final fb = await AIFeedbackService.respondToSpeech(
          userText: _spokenText, context: 'pronunciation');
      if (!mounted) return;
      final state = context.read<AppState>();
      state.addXP(fb.xp);
      state.addWordsSpoken(_spokenText.split(' ').length);
      state.addPracticeMinutes(1);
      setState(() { _feedback = fb; _processing = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _processing = false;
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
  }

  @override
  void dispose() { 
    _pulseCtrl.dispose(); 
    _speech.stop(); 
    _tts.stop(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityBanner(
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          title: const Text('Speaking Practice 🎤'),
          actions: [
            IconButton(
              icon: const Icon(Icons.shuffle_rounded), 
              onPressed: _generateNewQuestion,
              tooltip: 'New Question',
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            CategorySelector(
              categories: _getCategories(),
              selectedCategory: _selectedCategory,
              onChanged: (category) {
                setState(() => _selectedCategory = category);
                _generateNewQuestion();
              },
            ),
            const SizedBox(height: 16),
            DifficultySelector(
              selectedDifficulty: _selectedDifficulty,
              onChanged: (difficulty) {
                setState(() => _selectedDifficulty = difficulty);
                _generateNewQuestion();
              },
            ),
            const SizedBox(height: 24),

            if (_currentQuestion != null)
              QuestionCard(
                question: _currentQuestion!,
                onRefresh: _generateNewQuestion,
              )
            else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 32),

            Text(
              !_speechAvailable  ? '⚠️ Microphone not available'
                  : _isListening   ? '🔴 Listening... tap to stop'
                  : _processing    ? '⚙️  Analyzing your speech...'
                  : _feedback != null ? '✅ Done! Great job!'
                  : 'Tap the mic and start speaking',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14,
                  color: _isListening ? AppTheme.danger : _processing ? AppTheme.accent : Colors.white38),
            ),

            const SizedBox(height: 20),

            GestureDetector(
              onTap: () {
                if (!_speechAvailable || _processing) return;
                _isListening ? _stopListening() : _startListening();
              },
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _isListening ? _pulseAnim.value : 1.0,
                  child: Container(
                    width: 110, height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening   ? AppTheme.danger.withOpacity(0.15)
                          : _processing  ? AppTheme.accent.withOpacity(0.12)
                          : AppTheme.primary.withOpacity(0.12),
                      border: Border.all(
                        color: _isListening ? AppTheme.danger : _processing ? AppTheme.accent : AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _processing ? Icons.hourglass_top_rounded : _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isListening ? AppTheme.danger : _processing ? AppTheme.accent : AppTheme.primary,
                      size: 46,
                    ),
                  ),
                ),
              ),
            ),

            if (_isListening) ...[
              const SizedBox(height: 16),
              _SoundLevelBar(level: _soundLevel),
            ],

            const SizedBox(height: 24),

            if (_isListening && _liveText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
                ),
                child: Text(_liveText, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 15, height: 1.5)),
              ),

            if (_spokenText.isNotEmpty && !_isListening) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.darkBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('You said:', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_spokenText, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 15, height: 1.5)),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: AIErrorWidget(
                  message: _errorMessage,
                  onRetry: () {
                    setState(() { _errorMessage = ''; _processing = true; });
                    _processVoice();
                  },
                ),
              ),

            if (_processing)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: AILoadingWidget(),
              ),

            if (_feedback != null && !_processing) ...[
              _FeedbackCard(message: _feedback!),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() { _spokenText = ''; _feedback = null; _liveText = ''; }),
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateNewQuestion,
                    child: const Text('Next Prompt'),
                  ),
                ),
              ]),
            ],

            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}

class _SoundLevelBar extends StatelessWidget {
  final double level;
  const _SoundLevelBar({required this.level});
  @override
  Widget build(BuildContext context) {
    final normalized = ((level + 160) / 160).clamp(0.0, 1.0);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(20, (i) {
        final active = i / 20 < normalized;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 4, height: active ? 20.0 : 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active ? AppTheme.danger : AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final ChatMessage message;
  const _FeedbackCard({required this.message});
  @override
  Widget build(BuildContext context) {
    final score = message.score ?? 7.0;
    final color = score >= 8 ? AppTheme.primary : score >= 6 ? AppTheme.accent : AppTheme.danger;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🤖 AI Feedback', style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
          const Spacer(),
          Text('${score.toStringAsFixed(1)} / 10',
                style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        Text(message.text, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14, height: 1.6)),
        if (message.feedback != null) ...[
          const SizedBox(height: 10),
          Text(message.feedback!, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
        ],
        const SizedBox(height: 12),
        Text('+${message.xp} XP earned!',
              style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}
