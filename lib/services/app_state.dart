import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'notification_service.dart';
import 'ai_feedback_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'translation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  static final FlutterTts tts = FlutterTts();
  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;

  bool _notificationsOn = true;
  bool get notificationsOn => _notificationsOn;

  String _reminderTime = '08:00';
  String get reminderTime => _reminderTime;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _hasSeenOnboarding = false;
  bool get hasSeenOnboarding => _hasSeenOnboarding;

  // ── Vocabulary ──────────────────────────────────────────────────────────────
  List<VocabularyWord> _vocabulary = [];
  List<VocabularyWord> get vocabulary => _vocabulary;

  // ── Quiz History ────────────────────────────────────────────────────────────
  List<QuizResult> _quizHistory = [];
  List<QuizResult> get quizHistory => _quizHistory;

  // ── Interview Sessions ──────────────────────────────────────────────────────
  List<InterviewSession> _interviewSessions = [];
  List<InterviewSession> get interviewSessions => _interviewSessions;

  // ── Practice Sessions ───────────────────────────────────────────────────────
  List<PracticeSession> _practiceSessions = [];
  List<PracticeSession> get practiceSessions => _practiceSessions;

  // ── Daily Challenges ────────────────────────────────────────────────────────
  List<DailyChallenge> _dailyChallenges = [];
  List<DailyChallenge> get dailyChallenges => _dailyChallenges;

  // ── Weak Areas ──────────────────────────────────────────────────────────────
  List<WeakArea> _weakAreas = [];
  List<WeakArea> get weakAreas => _weakAreas;

  // ── Scenarios ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _dynamicScenarios = [];
  List<Map<String, dynamic>> get dynamicScenarios => _dynamicScenarios;
  bool _isRefreshingScenarios = false;
  bool get isRefreshingScenarios => _isRefreshingScenarios;

  bool _isGeneratingQuestion = false;
  bool get isGeneratingQuestion => _isGeneratingQuestion;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  Future<Question?> generateDynamicQuestion({String? category, String? difficulty}) async {
    _isGeneratingQuestion = true;
    notifyListeners();
    try {
      final role = _profile.isResumeMode && activeResume != null 
          ? (activeResume!.roleTag ?? _profile.targetRole)
          : _profile.targetRole;
          
      final question = await AIFeedbackService.generateDynamicSpeakingQuestion(
        role: role,
        difficulty: difficulty ?? _profile.difficulty,
        category: category ?? 'General',
        resumeContext: _profile.isResumeMode && activeResume != null ? activeResume!.text : null,
      );
      return question;
    } catch (e) {
      debugPrint('Error generating dynamic question: $e');
      return null;
    } finally {
      _isGeneratingQuestion = false;
      notifyListeners();
    }
  }

  Future<void> refreshScenarios({bool force = false}) async {
    if (_dynamicScenarios.isEmpty || force) {
      _isRefreshingScenarios = true;
      notifyListeners();
      try {
        final data = await AIFeedbackService.generateScenarios(role: _profile.targetRole);
        if (data.isNotEmpty) {
          _dynamicScenarios = data;
          await _saveScenarios();
        }
      } catch (e) {
        debugPrint('Error refreshing scenarios: $e');
      } finally {
        _isRefreshingScenarios = false;
        notifyListeners();
      }
    }
  }

  Future<void> _saveScenarios() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dynamic_scenarios', jsonEncode(_dynamicScenarios));
  }

  // ── UI Helpers ──────────────────────────────────────────────────────────────
  int get todayMinutes => _profile.practiceMinutes;
  String? get profilePicBase64 => _profile.profilePicBase64;

  VocabularyWord? _dailyWord;
  DateTime? _lastWordDate;
  bool _isRefreshingWord = false;

  bool get isRefreshingWord => _isRefreshingWord;

  List<Map<String, String>> _availableVoices = [];
  List<Map<String, String>> get availableVoices => _availableVoices;

  VocabularyWord get wordOfTheDay {
    _dailyWord ??= VocabularyWord(
        id: 'daily_1',
        word: 'articulate',
        meaning: 'expressing oneself clearly and effectively',
        example: 'She gave an articulate presentation.',
        category: 'general',
      );
    return _dailyWord!;
  }

  Future<void> refreshDailyWord({bool force = false}) async {
    final now = DateTime.now();
    bool needsRefresh = force || _dailyWord == null || _lastWordDate == null ||
        _lastWordDate!.year != now.year ||
        _lastWordDate!.month != now.month ||
        _lastWordDate!.day != now.day;

    if (needsRefresh) {
      // Defer state update to prevent 'setState() called during build' exception
      await Future.microtask(() {});
      _isRefreshingWord = true;
      notifyListeners();
      try {
        final data = await AIFeedbackService.generateDailyWord(
          role: _profile.targetRole,
          targetLang: _profile.language,
          difficulty: _profile.difficulty,
        );
        _dailyWord = VocabularyWord.fromJson({
          ...data,
          'id': 'daily_${now.millisecondsSinceEpoch}',
        });
        _lastWordDate = now;
        await _saveDailyWord();
      } catch (e) {
        debugPrint('Error refreshing daily word: $e');
      } finally {
        _isRefreshingWord = false;
        notifyListeners();
      }
    }
  }

  // ── Computed Getters ────────────────────────────────────────────────────────
  int get chatSessionCount {
    final userMsgs = _chatMessages.where((m) => m.sender == MsgSender.user).toList();
    if (userMsgs.isEmpty) return 0;
    
    int sessions = 1;
    for (int i = 1; i < userMsgs.length; i++) {
      // If gap between messages is more than 30 minutes, count as new session
      if (userMsgs[i].time.difference(userMsgs[i-1].time).inMinutes > 30) {
        sessions++;
      }
    }
    return sessions;
  }

  int get todaysChallengesCompleted =>
      _dailyChallenges.where((c) {
        final now = DateTime.now();
        return c.completed &&
            c.date.year == now.year &&
            c.date.month == now.month &&
            c.date.day == now.day;
      }).length;

  List<int> get weeklyXPData => _profile.weeklyXP;
  double get accuracyPercent => _profile.accuracy;

  /// Returns a 7-day XP array (Mon-Sun) filtered by category index:
  /// 0: Speaking, 1: Interviews, 2: Quizzes, 3: Vocabulary, 4: Chat Bits
  List<int> getWeeklyXPByCategory(int index) {
    List<int> week = [0, 0, 0, 0, 0, 0, 0];
    final now = DateTime.now();

    switch (index) {
      case 0: // Speaking
        for (var s in _practiceSessions) {
          if (_isSameWeek(s.date, now)) {
            week[s.date.weekday - 1] += s.xp;
          }
        }
        break;
      case 1: // Interviews
        for (var s in _interviewSessions) {
          if (_isSameWeek(s.timestamp, now)) {
            // XP for interview is 50 as defined in saveInterviewSession
            week[s.timestamp.weekday - 1] += 50; 
          }
        }
        break;
      case 2: // Quizzes
        for (var r in _quizHistory) {
          if (_isSameWeek(r.timestamp, now)) {
            // XP formula from completeQuiz: 30 + (score * 5)
            week[r.timestamp.weekday - 1] += (30 + (r.score * 5));
          }
        }
        break;
      case 3: // Vocabulary
        for (var w in _vocabulary) {
          if (w.learned && _isSameWeek(w.date, now)) {
            // XP for vocab is 10 as defined in markVocabLearned
            week[w.date.weekday - 1] += 10;
          }
        }
        break;
      case 4: // Chat Bits
        for (var m in _chatMessages) {
          if (m.sender == MsgSender.user && _isSameWeek(m.time, now)) {
            week[m.time.weekday - 1] += m.xp;
          }
        }
        break;
      default:
        return _profile.weeklyXP;
    }
    return week;
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  void updateResume(String text, Map<String, dynamic> analysis) {
    _profile.resumeText = text;
    _profile.resumeAnalysis = analysis;
    
    // Also save to our new multi-resume list if not already there
    final resumeId = Uuid().v4();
    final newResume = ResumeRecord(
      id: resumeId,
      fileName: analysis['name'] ?? 'Resume_${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      analysis: analysis,
      roleTag: analysis['recommendedRole'],
      skills: List<String>.from(analysis['skills'] ?? []),
    );
    
    _profile.resumes.add(newResume);
    if (_profile.activeResumeId == null) {
      _profile.activeResumeId = resumeId;
    }
    
    _saveProfile();
    notifyListeners();
  }

  // ── Multi-Resume Management ───────────────────────────────────────────────
  
  List<ResumeRecord> get resumes => _profile.resumes;
  String? get activeResumeId => _profile.activeResumeId;
  bool get isResumeMode => _profile.isResumeMode;

  Future<void> setResumeMode(bool value) async {
    if (value && activeResume == null) {
      // Don't allow turning on if no resume exists
      _profile.isResumeMode = false;
    } else {
      _profile.isResumeMode = value;
    }
    notifyListeners();
    await _saveProfile();
  }
  
  ResumeRecord? get activeResume {
    if (_profile.activeResumeId == null) return null;
    try {
      return _profile.resumes.firstWhere((r) => r.id == _profile.activeResumeId);
    } catch (e) {
      return null;
    }
  }

  Future<void> addResume(String fileName, String text, Map<String, dynamic> analysis) async {
    final newResume = ResumeRecord(
      id: Uuid().v4(),
      fileName: fileName,
      text: text,
      analysis: analysis,
      roleTag: analysis['recommendedRole'],
      skills: List<String>.from(analysis['skills'] ?? []),
    );
    
    _profile.resumes.add(newResume);
    // If it's the first resume, set it as active
    if (_profile.resumes.length == 1) {
      _profile.activeResumeId = newResume.id;
    }
    
    notifyListeners();
    await _saveProfile();
    await _syncResumesToFirestore();
  }

  Future<void> deleteResume(String id) async {
    _profile.resumes.removeWhere((r) => r.id == id);
    if (_profile.activeResumeId == id) {
      _profile.activeResumeId = _profile.resumes.isNotEmpty ? _profile.resumes.first.id : null;
      // If the active resume was deleted, turn off resume mode to prevent logic errors
      if (_profile.activeResumeId == null) {
        _profile.isResumeMode = false;
      }
    }
    notifyListeners();
    await _saveProfile();
    await _syncResumesToFirestore();
  }

  Future<void> setActiveResume(String id) async {
    _profile.activeResumeId = id;
    final r = activeResume;
    if (r != null) {
      _profile.resumeAnalysis = r.analysis;
    }
    notifyListeners();
    await _saveProfile();
  }

  Future<void> _syncResumesToFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).update({
        'resumes': _profile.resumes.map((r) => r.toJson()).toList(),
        'activeResumeId': _profile.activeResumeId,
      });
    } catch (e) {
      debugPrint('Error syncing resumes to Firestore: $e');
    }
  }

  Future<void> login(String name, String email,
      {String role = 'roleSoftwareEngineer', String level = 'levelFresher'}) async {
    // Only clear if switching from a different account
    if (_profile.email != email && _profile.email.isNotEmpty) {
      await clearAllData();
    }

    _profile = UserProfile(
        name: name, email: email, targetRole: role, experienceLevel: level);
    _isLoggedIn = true;
    _hasSeenOnboarding = true;
    await completeOnboarding();
    
    // Initial local save
    await _saveProfile();
    
    // Sync with cloud for this user
    await syncWithCloud();
    
    notifyListeners();
  }

  Future<void> continueAsGuest() async {
    // If we already have a profile (e.g. from previous guest session), just continue
    if (_profile.email == 'guest@example.com') {
      _isLoggedIn = true;
      _hasSeenOnboarding = true;
      await completeOnboarding();
      notifyListeners();
      return;
    }

    // Otherwise initialize fresh guest
    // Avoid clearAllData if current profile is already essentially empty/guest
    if (_profile.email.isNotEmpty && _profile.email != 'guest@example.com') {
      await clearAllData();
    }
    
    _profile = UserProfile(
      name: 'Guest Learner',
      email: 'guest@example.com',
      targetRole: 'Explorer',
      experienceLevel: 'Beginner',
    );
    _isLoggedIn = true;
    _hasSeenOnboarding = true;
    await completeOnboarding();
    await _saveProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await AuthService.signOut();
      await clearAllData();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
      await clearAllData();
      notifyListeners();
    }
  }

  // ── XP & Progress ──────────────────────────────────────────────────────────
  void addXP(int xp) {
    _checkAndResetWeeklyXP();
    _updateStreakLogic();

    final before = _profile.totalXP;
    _profile.totalXP += xp;
    
    final dayIndex = DateTime.now().weekday - 1;
    if (dayIndex >= 0 && dayIndex < 7) {
      _profile.weeklyXP[dayIndex] += xp;
    }
    
    _checkBadges();
    _checkXPMilestones(before, _profile.totalXP);
    _saveProfile();
    notifyListeners();
  }

  void _updateStreakLogic() {
    final now = DateTime.now();
    final lastActive = _profile.lastActiveDate;
    
    final today = DateTime(now.year, now.month, now.day);
    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    
    if (today.isAtSameMomentAs(lastActiveDay)) return;

    final difference = today.difference(lastActiveDay).inDays;
    
    if (difference == 1) {
      _profile.streakDays += 1;
    } else if (difference > 1) {
      _profile.streakDays = 1;
    } else if (_profile.streakDays == 0) {
      _profile.streakDays = 1;
    }
    
    _profile.lastActiveDate = now;
    _profile.lastPracticeDate = now;
    syncNotifications();
  }

  void _checkAndResetWeeklyXP() {
    final now = DateTime.now();
    final lastActive = _profile.lastActiveDate;
    
    // ISO week number check (simple approach: if last active was more than 7 days ago, or if current weekday is less than last active weekday and they are in different weeks)
    // A better way: check if they are in the same ISO week
    if (!_isSameWeek(now, lastActive)) {
      _profile.weeklyXP = [0, 0, 0, 0, 0, 0, 0];
    }
  }

  bool _isSameWeek(DateTime d1, DateTime d2) {
    final w1 = _getWeekNumber(d1);
    final w2 = _getWeekNumber(d2);
    return w1 == w2 && d1.year == d2.year;
  }

  int _getWeekNumber(DateTime date) {
    // ISO 8601 week number
    int dayOfYear = int.parse(DateFormat("D").format(date));
    int w = ((dayOfYear - date.weekday + 10) / 7).floor();
    return w;
  }

  void incrementSessions() {
    _profile.sessionsCompleted += 1;
    _saveProfile();
    notifyListeners();
  }

  void addPracticeMinutes(int mins) {
    _profile.practiceMinutes += mins;
    _saveProfile();
    notifyListeners();
  }

  void addWordsSpoken(int words) {
    _profile.wordsSpoken += words;
    _saveProfile();
    notifyListeners();
  }

  void updateStreak() {
    _profile.streakDays += 1;
    _saveProfile();
    notifyListeners();
  }

  void updateProfile(
      {String? name, String? email, String? role, String? level}) {
    if (name != null) _profile.name = name;
    if (email != null) _profile.email = email;
    if (role != null) _profile.targetRole = role;
    if (level != null) _profile.experienceLevel = level;
    _saveProfile();
    notifyListeners();
  }

  // ── Practice Sessions ───────────────────────────────────────────────────────
  void addSession(PracticeSession session) {
    _practiceSessions.add(session);
    _profile.recentSessions.add(session);
    // Keep recentSessions to last 20 only
    if (_profile.recentSessions.length > 20) {
      _profile.recentSessions.removeAt(0);
    }
    _profile.sessionsCompleted += 1;

    // Update Topic Progress
    // We match by topic name since topicId might be null in some legacy calls
    final String topicName = session.topic;
    final int currentProgress = _profile.topicProgress[topicName] ?? 0;
    if (currentProgress < 100) {
      // Increment by 20% per session (5 sessions to master)
      _profile.topicProgress[topicName] = (currentProgress + 20).clamp(0, 100);
    }

    _checkBadges();
    _saveProfile();
    _savePracticeSessions();
    syncNotifications();
    notifyListeners();
  }

  // ── Chat ───────────────────────────────────────────────────────────────────
  void addMessage(ChatMessage msg) {
    _chatMessages.add(msg);
    _saveChatMessages();
    notifyListeners();
  }

  void clearChat() {
    _chatMessages.clear();
    _saveChatMessages();
    notifyListeners();
  }

  // ── Vocabulary ─────────────────────────────────────────────────────────────
  void addVocabWord(VocabularyWord word) {
    _vocabulary.add(word);
    _saveVocabulary();
    notifyListeners();
  }

  void markVocabLearned(String wordId) {
    bool newlyLearned = false;

    // 1. Check if it's the current daily word
    if (_dailyWord != null && _dailyWord!.id == wordId) {
      if (!_dailyWord!.learned) {
        _dailyWord!.learned = true;
        newlyLearned = true;
        
        // Add to main vocabulary if not already there
        if (!_vocabulary.any((w) => w.word.toLowerCase() == _dailyWord!.word.toLowerCase())) {
          _vocabulary.add(_dailyWord!);
        } else {
          final existingIdx = _vocabulary.indexWhere((w) => w.word.toLowerCase() == _dailyWord!.word.toLowerCase());
          if (existingIdx != -1) _vocabulary[existingIdx].learned = true;
        }
      }
    } else {
      // 2. Check in historical vocabulary
      final idx = _vocabulary.indexWhere((w) => w.id == wordId);
      if (idx != -1 && !_vocabulary[idx].learned) {
        _vocabulary[idx].learned = true;
        newlyLearned = true;
      }
    }

    if (newlyLearned) {
      if (!_profile.learnedVocabIds.contains(wordId)) {
        _profile.learnedVocabIds.add(wordId);
      }
      _profile.wordsLearned = _profile.learnedVocabIds.length;
      addXP(10); // Reward for mastering a word
    }
    
    _saveVocabulary();
    _saveProfile();
    notifyListeners();
  }

  // ── Quiz ───────────────────────────────────────────────────────────────────
  void completeQuiz(QuizResult result) {
    _quizHistory.add(result);
    _profile.quizzesCompleted += 1;
    final totalCorrect = _quizHistory.fold<int>(0, (s, q) => s + q.score);
    final totalQuestions = _quizHistory.fold<int>(0, (s, q) => s + q.total);
    _profile.accuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0;
    
    // Reward XP: Base 30 + (Correct answers * 5)
    addXP(30 + (result.score * 5));
    
    _saveQuizHistory();
    _saveProfile();
    syncNotifications();
    notifyListeners();
  }

  // ── Interview Sessions ─────────────────────────────────────────────────────
  void saveInterviewSession(InterviewSession session) {
    _interviewSessions.add(session);
    // Reward for completed interview only if it had meaningful content
    if (session.qaPairs.length >= 3) {
      addXP(50);
    }
    _saveInterviewSessions();
    syncNotifications();
    notifyListeners();
  }

  // ── Daily Challenges ───────────────────────────────────────────────────────
  void setDailyChallenges(List<DailyChallenge> challenges) {
    _dailyChallenges = challenges;
    _saveDailyChallenges();
    notifyListeners();
  }

  void completeDailyChallenge(String challengeId) {
    final idx = _dailyChallenges.indexWhere((c) => c.id == challengeId);
    if (idx != -1) {
      _dailyChallenges[idx].completed = true;
      _profile.challengeStreak += 1;
      addXP(25); // Reward for reaching a daily challenge goal
      _saveDailyChallenges();
      _saveProfile();
      syncNotifications();
      notifyListeners();
    }
  }

  // ── Weak Areas ─────────────────────────────────────────────────────────────
  void addWeakArea(WeakArea area) {
    final idx = _weakAreas.indexWhere((w) => w.category == area.category);
    if (idx != -1) {
      _weakAreas[idx].errorCount += area.errorCount;
      _weakAreas[idx].recommendations.addAll(area.recommendations);
      _weakAreas[idx].exampleMistakes.addAll(area.exampleMistakes);
    } else {
      _weakAreas.add(area);
    }
    _saveWeakAreas();
    notifyListeners();
  }

  void addWeakWord(String word) {
    if (!_profile.weakWords.contains(word)) {
      _profile.weakWords.add(word);
      _saveProfile();
      notifyListeners();
    }
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  Future<void> toggleNotifications(bool v) async {
    _notificationsOn = v;
    _savePrefs();
    await syncNotifications();
    notifyListeners();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _reminderTime = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    _savePrefs();
    await syncNotifications();
    notifyListeners();
  }

  Future<void> syncNotifications() async {
    if (!_notificationsOn) {
      await NotificationService.cancelAll();
      return;
    }

    final parts = _reminderTime.split(':');
    final h = int.tryParse(parts[0]) ?? 8;
    final m = int.tryParse(parts[1]) ?? 0;

    // 1. Practice Reminder
    final now = DateTime.now();
    final hasPracticedToday = _practiceSessions.any((s) =>
        s.date.year == now.year && s.date.month == now.month && s.date.day == now.day);

    if (hasPracticedToday) {
      // Already practiced, move reminder to tomorrow
      await NotificationService.scheduleDailyReminder(hour: h, minute: m, userName: _profile.name, skipToday: true);
    } else {
      // Haven't practiced, schedule for today (or tomorrow if time passed)
      await NotificationService.scheduleDailyReminder(hour: h, minute: m, userName: _profile.name, skipToday: false);
    }

    // 2. Weekly Test Reminder (Sunday)
    await NotificationService.scheduleWeeklyTestReminder(hour: h, minute: m);
  }

  void updateProfilePic(String? base64) {
    _profile.profilePicBase64 = base64;
    _saveProfile();
    notifyListeners();
  }

  void setPersonalityMode(String mode) {
    _profile.personalityMode = mode;
    _saveProfile();
    notifyListeners();
  }

  void setDifficulty(String d) {
    _profile.difficulty = d;
    _saveProfile();
    notifyListeners();
  }

  void setVoicePreference(String pref) {
    _profile.voicePreference = pref;
    _saveProfile();
    configureTts(tts, this, force: true);
    notifyListeners();
  }

  void setVoiceStyle(String style) {
    _profile.voiceStyle = style;
    _saveProfile();
    configureTts(tts, this, force: true);
    notifyListeners();
  }

  void setVoicePitch(double pitch) {
    _profile.voicePitch = pitch;
    _saveProfile();
    configureTts(tts, this, force: true);
    notifyListeners();
  }

  void setPreferredVoiceId(String? id) {
    _profile.preferredVoiceId = id;
    _saveProfile();
    configureTts(tts, this, force: true);
    notifyListeners();
  }

  // ── Voice Discovery ────────────────────────────────────────────────────────
  Future<void> initTtsVoices(FlutterTts tts) async {
    try {
      final List<dynamic>? voices = await tts.getVoices;
      if (voices == null || voices.isEmpty) return;

      final String targetLang = _profile.language == 'hi' ? 'hi' : 'en';
      final List<Map<String, dynamic>> filtered = [];

      for (var v in voices) {
        final name = v['name']?.toString().toLowerCase() ?? '';
        final locale = v['locale']?.toString().toLowerCase() ?? '';
        
        // Match base language (hi or en) across any region (US, GB, IN, etc.)
        if (!locale.startsWith(targetLang)) continue;

        // Categorize
        String category = 'other';
        String labelBase = 'AI Voice';
        
        if (name.contains('female') || name.contains('zira') || name.contains('samantha') || name.contains('aria')) {
          category = 'female';
          labelBase = 'Female';
        } else if (name.contains('male') || name.contains('david') || name.contains('guy')) {
          category = 'male';
          labelBase = 'Male';
        }

        if (locale.contains('in')) {
          labelBase = _profile.language == 'hi' ? 'Hindi' : 'Indian English';
          category = 'indian';
        }

        // Check for premium (Network/Neural)
        final isPremium = name.contains('natural') || name.contains('neural') || name.contains('network') || name.contains('enhanced');
        String qualitySuffix = isPremium ? ' (HD)' : '';

        filtered.add({
          'name': v['name'],
          'locale': v['locale'],
          'label': labelBase,
          'category': category,
          'quality': isPremium ? 'high' : 'standard',
          'qualitySuffix': qualitySuffix,
        });
      }

      // Group and prioritize high quality
      filtered.sort((a, b) => b['quality']!.compareTo(a['quality']!));
      
      // Assign unique labels with numbers (e.g., Male 1, Male 2)
      final Map<String, int> labelCounts = {};
      final List<Map<String, String>> finalVoices = [];
      
      for (var v in filtered) {
        final base = v['label']!;
        labelCounts[base] = (labelCounts[base] ?? 0) + 1;
        
        finalVoices.add({
          'name': v['name']!,
          'locale': v['locale']!,
          'label': '$base ${labelCounts[base]}${v['qualitySuffix']}',
          'category': v['category']!,
        });
      }

      _availableVoices = finalVoices;
      notifyListeners();
    } catch (e) {
      debugPrint('Error discovery voices: $e');
    }
  }

  static bool _isTtsConfigured = false;
  static bool _isTtsConfiguring = false;

  static Future<void> configureTts(FlutterTts tts, AppState state, {bool force = false}) async {
    if (!force && _isTtsConfigured) return;
    if (_isTtsConfiguring) return;
    _isTtsConfiguring = true;
    
    try {
      final profile = state.profile;
    
    // ── Android Optimization ──
    if (!kIsWeb) {
       try {
         await tts.setEngine("com.google.android.tts");
       } catch (_) {}
    }

    final lang = profile.language == 'hi' ? 'hi-IN' : 'en-US';
    await tts.setLanguage(lang);
    
    final speedBase = {'slow': 0.35, 'normal': 0.5, 'fast': 0.65}[profile.voicePreference] ?? 0.5;
    final pitchBase = profile.voicePitch;

    // ── Dynamic Persona Tone ──
    double toneRate = 0.0;
    double tonePitch = 0.0;

    switch (profile.personalityMode) {
      case 'friendly': tonePitch = 0.08; break; // Lighter/Cheerful
      case 'strict': tonePitch = -0.05; toneRate = 0.05; break; // Sharper/Authoritative
      case 'hr': tonePitch = -0.1; toneRate = -0.05; break; // Calm/Formal
      case 'debate': toneRate = 0.08; break; // Intense/Fast
    }

    await tts.setSpeechRate(speedBase + toneRate);
    await tts.setPitch(pitchBase + tonePitch);

    if (profile.preferredVoiceId != null) {
      try {
        final List<dynamic>? voices = await tts.getVoices;
        if (voices != null) {
          final voice = voices.firstWhere((v) => v['name'] == profile.preferredVoiceId, orElse: () => null);
          if (voice != null) {
            await tts.setVoice(Map<String, String>.from(voice));
            return;
          }
        }
      } catch (_) {}
    }

    // Fallback logic if no preferred voice or it fails
    try {
      final List<dynamic>? voices = await tts.getVoices;
      if (voices == null || voices.isEmpty) return;
      
      final style = profile.voiceStyle;
      for (var v in voices) {
        final name = v['name']?.toString().toLowerCase() ?? '';
        final locale = v['locale']?.toString().toLowerCase() ?? '';
        if (!locale.contains(lang.toLowerCase().split('-')[0])) continue;

        if (style == 'male' && (name.contains('male') || name.contains('david'))) {
          await tts.setVoice(Map<String, String>.from(v)); break;
        }
        if (style == 'female' && (name.contains('female') || name.contains('zira'))) {
          await tts.setVoice(Map<String, String>.from(v)); break;
        }
      }
    } catch (_) {}
    
    _isTtsConfigured = true;
    } finally {
      _isTtsConfiguring = false;
    }
  }

  void setLanguage(String lang) {
    _profile.language = lang;
    _profile.lastActiveDate = DateTime.now();
    _saveProfile();
    configureTts(tts, this, force: true);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    final p = await SharedPreferences.getInstance();
    await p.setBool('hasSeenOnboarding', true);
    await p.setBool('loggedIn', _isLoggedIn); // Ensure login state is also persisted
    notifyListeners();
  }

  // ── Badges ─────────────────────────────────────────────────────────────────
  void _checkBadges() {
    void award(String badgeName, String msg) {
      if (!_profile.badges.any((b) => b.name == badgeName)) {
        _profile.badges
            .add(AchievementBadge(name: badgeName, description: msg));
        NotificationService.sendAchievement(badgeName, msg);
      }
    }

    if (_profile.totalXP >= 100) {
      award('🥉 100 XP', 'You\'ve earned your first 100 XP!');
    }
    if (_profile.totalXP >= 500) {
      award('🥈 500 XP', 'Amazing! You\'ve reached 500 XP!');
    }
    if (_profile.totalXP >= 1000) {
      award('🥇 1000 XP', 'Incredible! 1000 XP reached!');
    }
    if (_profile.totalXP >= 2000) {
      award('💎 2000 XP', 'Legendary! 2000 XP milestone!');
    }
    if (_profile.sessionsCompleted >= 1) {
      award('🎯 First Session', 'You completed your first practice session!');
    }
    if (_profile.sessionsCompleted >= 5) {
      award('🎯 5 Sessions', 'You completed 5 practice sessions!');
    }
    if (_profile.sessionsCompleted >= 10) {
      award('💎 10 Sessions', 'You\'re on a roll! 10 sessions done!');
    }
    if (_profile.sessionsCompleted >= 25) {
      award('👑 25 Sessions', 'Quarter century of sessions!');
    }
    if (_profile.streakDays >= 3) {
      award('🔥 3-Day Streak', 'You\'re on fire! 3 days in a row!');
    }
    if (_profile.streakDays >= 7) {
      award('🔥 7-Day Streak', 'One full week of practice! Amazing!');
    }
    if (_profile.streakDays >= 30) {
      award('🏆 30-Day Streak', 'A full month streak! Incredible!');
    }
    if (_profile.wordsLearned >= 10) {
      award('📚 10 Words', 'You\'ve learned 10 vocabulary words!');
    }
    if (_profile.wordsLearned >= 50) {
      award('📖 50 Words', 'Amazing vocabulary! 50 words learned!');
    }
    if (_profile.quizzesCompleted >= 5) {
      award('🧠 Quiz Master', 'You\'ve completed 5 quizzes!');
    }
    if (_profile.challengeStreak >= 7) {
      award('⚡ Challenge Week', 'One full week of daily challenges!');
    }
  }

  void _checkXPMilestones(int before, int after) {
    for (final milestone in [100, 500, 1000, 2000, 5000]) {
      if (before < milestone && after >= milestone) {
        NotificationService.sendXPMilestone(milestone);
      }
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> init() => load();

  // ── Parallel Safe Loading ──────────────────────────────────────────────
  Future<T?> _safeCall<T>(Future<T> future) async {
    try { return await future; } catch (e) {
      debugPrint('⚠️ AppState SafeCall Error: $e');
      return null;
    }
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    
    // 1. Load basic preferences synchronously (fast local read)
    _isLoggedIn = p.getBool('loggedIn') ?? false;
    _notificationsOn = p.getBool('notifications') ?? true;
    _reminderTime = p.getString('reminderTime') ?? '08:00';
    _hasSeenOnboarding = p.getBool('hasSeenOnboarding') ?? false;

    // 2. Load Local Cached Data (Rapid)
    final profileRaw = p.getString('profile');
    if (profileRaw != null) {
      try { _profile = UserProfile.fromJson(jsonDecode(profileRaw)); } catch (_) {}
    }

    void loadLocalList<T>(String key, void Function(List<T>) setter, T Function(Map<String, dynamic>) fromJson) {
      final raw = p.getString(key);
      if (raw != null) {
        try {
          final List<dynamic> list = jsonDecode(raw);
          setter(list.map((j) => fromJson(j)).toList());
        } catch (e) {
          debugPrint('⚠️ Error loading local list $key: $e');
          setter([]); // Reset to empty if corrupted
        }
      }
    }

    loadLocalList('chatMessages', (l) => _chatMessages = l, (j) => ChatMessage.fromJson(j));
    loadLocalList('vocabulary', (l) => _vocabulary = l, (j) => VocabularyWord.fromJson(j));
    loadLocalList('quizHistory', (l) => _quizHistory = l, (j) => QuizResult.fromJson(j));
    loadLocalList('interviewSessions', (l) => _interviewSessions = l, (j) => InterviewSession.fromJson(j));
    loadLocalList('practiceSessions', (l) => _practiceSessions = l, (j) => PracticeSession.fromJson(j));
    loadLocalList('dailyChallenges', (l) => _dailyChallenges = l, (j) => DailyChallenge.fromJson(j));
    loadLocalList('weakAreas', (l) => _weakAreas = l, (j) => WeakArea.fromJson(j));

    final dwRaw = p.getString('dailyWord');
    if (dwRaw != null) {
      try { _dailyWord = VocabularyWord.fromJson(jsonDecode(dwRaw)); } catch (_) {}
    }
    final dwdRaw = p.getString('lastWordDate');
    if (dwdRaw != null) _lastWordDate = DateTime.tryParse(dwdRaw);

    notifyListeners();
    
    // Trigger non-blocking cloud sync if logged in
    unawaited(syncWithCloud());
  }

  Future<void> syncWithCloud() async {
    final user = _auth.currentUser;
    if (!_isLoggedIn || user == null || _isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await Future.wait([
        _safeCall(_db.collection('users').doc(user.uid).get().then((doc) {
          if (doc.exists && doc.data() != null) {
            _profile = UserProfile.fromJson(doc.data()!);
          }
        })),
        _safeCall(_db.collection('users').doc(user.uid).collection('vocabulary').get().then((snap) {
          if (snap.docs.isNotEmpty) _vocabulary = snap.docs.map((d) => VocabularyWord.fromJson(d.data())).toList();
        })),
        _safeCall(_db.collection('users').doc(user.uid).collection('practice_sessions').get().then((snap) {
          if (snap.docs.isNotEmpty) _practiceSessions = snap.docs.map((d) => PracticeSession.fromJson(d.data())).toList();
        })),
        _safeCall(_db.collection('users').doc(user.uid).collection('quiz_history').get().then((snap) {
          if (snap.docs.isNotEmpty) _quizHistory = snap.docs.map((d) => QuizResult.fromJson(d.data())).toList();
        })),
        _safeCall(_db.collection('users').doc(user.uid).collection('interview_sessions').get().then((snap) {
          if (snap.docs.isNotEmpty) _interviewSessions = snap.docs.map((d) => InterviewSession.fromJson(d.data())).toList();
        })),
        _safeCall(_db.collection('users').doc(user.uid).collection('chat_messages').get().then((snap) {
          if (snap.docs.isNotEmpty) {
            var msgs = snap.docs.map((d) => ChatMessage.fromJson(d.data())).toList();
            msgs.sort((a, b) => a.id.compareTo(b.id));
            _chatMessages = msgs;
          }
        })),
      ]);
      await syncNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Cloud Hydration Error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveProfile() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('loggedIn', _isLoggedIn);
    await p.setString('profile', jsonEncode(_profile.toJson()));

    // Sync to Firestore if logged in
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        await _db.collection('users').doc(user.uid).set(_profile.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore Profile Save Error: $e');
      }
    }
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications', _notificationsOn);
    await p.setString('reminderTime', _reminderTime);
  }

  Future<void> _saveChatMessages() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('chatMessages',
        jsonEncode(_chatMessages.map((m) => m.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final collection = _db.collection('users').doc(user.uid).collection('chat_messages');
        for (var i = 0; i < _chatMessages.length; i += 500) {
          final batch = _db.batch();
          final end = (i + 500 < _chatMessages.length) ? i + 500 : _chatMessages.length;
          for (var j = i; j < end; j++) {
            final m = _chatMessages[j];
            batch.set(collection.doc(m.id), m.toJson());
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Firestore Chat Save Error: $e');
      }
    }
  }

  Future<void> _saveVocabulary() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('vocabulary',
        jsonEncode(_vocabulary.map((v) => v.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final collection = _db.collection('users').doc(user.uid).collection('vocabulary');
        for (var i = 0; i < _vocabulary.length; i += 500) {
          final batch = _db.batch();
          final end = (i + 500 < _vocabulary.length) ? i + 500 : _vocabulary.length;
          for (var j = i; j < end; j++) {
            final v = _vocabulary[j];
            batch.set(collection.doc(v.id), v.toJson());
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Firestore Vocab Save Error: $e');
      }
    }
  }

  Future<void> _saveQuizHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('quizHistory',
        jsonEncode(_quizHistory.map((q) => q.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final batch = _db.batch();
        for (var q in _quizHistory) {
          batch.set(_db.collection('users').doc(user.uid).collection('quiz_history').doc(q.id), q.toJson());
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore Quiz Save Error: $e');
      }
    }
  }

  Future<void> _saveInterviewSessions() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('interviewSessions',
        jsonEncode(_interviewSessions.map((s) => s.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final batch = _db.batch();
        for (var s in _interviewSessions) {
          batch.set(_db.collection('users').doc(user.uid).collection('interview_sessions').doc(s.id), s.toJson());
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore Interview Save Error: $e');
      }
    }
  }

  Future<void> _savePracticeSessions() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('practiceSessions',
        jsonEncode(_practiceSessions.map((s) => s.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final batch = _db.batch();
        for (var s in _practiceSessions) {
          batch.set(_db.collection('users').doc(user.uid).collection('practice_sessions').doc(s.id), s.toJson());
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore Sessions Save Error: $e');
      }
    }
  }

  Future<void> _saveDailyChallenges() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('dailyChallenges',
        jsonEncode(_dailyChallenges.map((c) => c.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final batch = _db.batch();
        for (var c in _dailyChallenges) {
          batch.set(_db.collection('users').doc(user.uid).collection('daily_challenges').doc(c.id), c.toJson());
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore Challenges Save Error: $e');
      }
    }
  }

  Future<void> _saveWeakAreas() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('weakAreas',
        jsonEncode(_weakAreas.map((w) => w.toJson()).toList()));

    // Sync to Firestore
    final user = _auth.currentUser;
    if (_isLoggedIn && user != null) {
      try {
        final batch = _db.batch();
        for (var w in _weakAreas) {
          batch.set(_db.collection('users').doc(user.uid).collection('weak_areas').doc(w.category), w.toJson());
        }
        await batch.commit();
      } catch (e) {
        debugPrint('Firestore WeakAreas Save Error: $e');
      }
    }
  }

  Future<void> _saveDailyWord() async {
    final p = await SharedPreferences.getInstance();
    if (_dailyWord != null) {
      await p.setString('dailyWord', jsonEncode(_dailyWord!.toJson()));
    }
    if (_lastWordDate != null) {
      await p.setString('lastWordDate', _lastWordDate!.toIso8601String());
    }
  }

  Future<void> clearAllData() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    _profile = UserProfile();
    _chatMessages = [];
    _vocabulary = [];
    _quizHistory = [];
    _interviewSessions = [];
    _practiceSessions = [];
    _dailyChallenges = [];
    _weakAreas = [];
    _notificationsOn = true;
    _reminderTime = '08:00';
    _isLoggedIn = false;
    _hasSeenOnboarding = false;
    notifyListeners();
  }

  Future<void> translateMessage(String id) async {
    final index = _chatMessages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final msg = _chatMessages[index];
    final targetLang = _profile.language;
    if (targetLang == 'none') return;

    try {
      final result = await TranslationService.translate(
        text: msg.text,
        targetLangCode: targetLang,
      );
      
      final translated = result['translated'] ?? '';
      if (translated.isNotEmpty) {
        _chatMessages[index] = msg.copyWith(translatedText: translated);
        notifyListeners();
        _saveChatMessages();
      }
    } catch (e) {
      debugPrint('Translation error: $e');
    }
  }

  Future<void> translateDailyWord() async {
    final word = wordOfTheDay;
    final targetLang = _profile.language;
    if (targetLang == 'none') return;

    try {
      final resultMeaning = await TranslationService.translate(
        text: word.meaning,
        targetLangCode: targetLang,
      );
      
      final resultExample = await TranslationService.translate(
        text: word.example,
        targetLangCode: targetLang,
      );

      _dailyWord = word.copyWith(
        translatedMeaning: resultMeaning['translated'] ?? '',
        translatedExample: resultExample['translated'] ?? '',
      );
      
      notifyListeners();
      await _saveDailyWord();
    } catch (e) {
      debugPrint('Vocabulary translation error: $e');
    }
  }
}