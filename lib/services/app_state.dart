import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  UserProfile _profile = UserProfile();
  UserProfile get profile => _profile;

  List<ChatMessage> _chatMessages = [];
  List<ChatMessage> get chatMessages => _chatMessages;

  bool _notificationsOn = true;
  bool get notificationsOn => _notificationsOn;

  String _reminderTime = '08:00';
  String get reminderTime => _reminderTime;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  // ── New: Vocabulary ─────────────────────────────────────────────────────────
  List<VocabularyWord> _vocabulary = [];
  List<VocabularyWord> get vocabulary => _vocabulary;

  // ── New: Quiz History ───────────────────────────────────────────────────────
  List<QuizResult> _quizHistory = [];
  List<QuizResult> get quizHistory => _quizHistory;

  // ── New: Interview Sessions ─────────────────────────────────────────────────
  List<InterviewSession> _interviewSessions = [];
  List<InterviewSession> get interviewSessions => _interviewSessions;

  // ── New: Daily Challenges ───────────────────────────────────────────────────
  List<DailyChallenge> _dailyChallenges = [];
  List<DailyChallenge> get dailyChallenges => _dailyChallenges;

  // ── New: Weak Areas ─────────────────────────────────────────────────────────
  List<WeakArea> _weakAreas = [];
  List<WeakArea> get weakAreas => _weakAreas;

  // ── Computed Getters ────────────────────────────────────────────────────────
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

  // ── Auth ───────────────────────────────────────────────────────────────────
  void login(String name, String email,
      {String role = 'Software Engineer', String level = 'Fresher'}) {
    _profile = UserProfile(
        name: name, email: email, targetRole: role, experienceLevel: level);
    _isLoggedIn = true;
    _saveProfile();
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    final p = await SharedPreferences.getInstance();
    await p.setBool('loggedIn', false);
    notifyListeners();
  }

  // ── XP & Progress ──────────────────────────────────────────────────────────
  void addXP(int xp) {
    final before = _profile.totalXP;
    _profile.totalXP += xp;
    // Update weekly XP for today
    final dayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    if (dayIndex >= 0 && dayIndex < 7) {
      _profile.weeklyXP[dayIndex] += xp;
    }
    _profile.lastActiveDate = DateTime.now();
    _checkBadges();
    _checkXPMilestones(before, _profile.totalXP);
    _saveProfile();
    notifyListeners();
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
    if (name  != null) _profile.name            = name;
    if (email != null) _profile.email           = email;
    if (role  != null) _profile.targetRole      = role;
    if (level != null) _profile.experienceLevel = level;
    _saveProfile();
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
    final idx = _vocabulary.indexWhere((w) => w.id == wordId);
    if (idx != -1) {
      _vocabulary[idx].learned = true;
      _profile.wordsLearned += 1;
      if (!_profile.learnedVocabIds.contains(wordId)) {
        _profile.learnedVocabIds.add(wordId);
      }
      _saveVocabulary();
      _saveProfile();
      notifyListeners();
    }
  }

  // ── Quiz ───────────────────────────────────────────────────────────────────
  void completeQuiz(QuizResult result) {
    _quizHistory.add(result);
    _profile.quizzesCompleted += 1;
    // Update accuracy
    final totalCorrect = _quizHistory.fold<int>(0, (s, q) => s + q.score);
    final totalQuestions = _quizHistory.fold<int>(0, (s, q) => s + q.total);
    _profile.accuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100 : 0;
    _saveQuizHistory();
    _saveProfile();
    notifyListeners();
  }

  // ── Interview Sessions ─────────────────────────────────────────────────────
  void saveInterviewSession(InterviewSession session) {
    _interviewSessions.add(session);
    _saveInterviewSessions();
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
      _saveDailyChallenges();
      _saveProfile();
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
  void toggleNotifications(bool v) {
    _notificationsOn = v;
    _savePrefs();
    notifyListeners();
  }

  void setReminderTime(String t) {
    _reminderTime = t;
    _savePrefs();
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
    notifyListeners();
  }

  void setLanguage(String lang) {
    _profile.language = lang;
    _saveProfile();
    notifyListeners();
  }

  // ── Badges ─────────────────────────────────────────────────────────────────
  void _checkBadges() {
    void award(String badge, String msg) {
      if (!_profile.badges.contains(badge)) {
        _profile.badges.add(badge);
        NotificationService.sendAchievement(badge, msg);
      }
    }

    if (_profile.totalXP >= 100)
      award('🥉 100 XP',        'You\'ve earned your first 100 XP!');
    if (_profile.totalXP >= 500)
      award('🥈 500 XP',        'Amazing! You\'ve reached 500 XP!');
    if (_profile.totalXP >= 1000)
      award('🥇 1000 XP',       'Incredible! 1000 XP reached!');
    if (_profile.totalXP >= 2000)
      award('💎 2000 XP',       'Legendary! 2000 XP milestone!');
    if (_profile.sessionsCompleted >= 1)
      award('🎯 First Session',  'You completed your first practice session!');
    if (_profile.sessionsCompleted >= 5)
      award('🎯 5 Sessions',    'You completed 5 practice sessions!');
    if (_profile.sessionsCompleted >= 10)
      award('💎 10 Sessions',   'You\'re on a roll! 10 sessions done!');
    if (_profile.sessionsCompleted >= 25)
      award('👑 25 Sessions',   'Quarter century of sessions!');
    if (_profile.streakDays >= 3)
      award('🔥 3-Day Streak',  'You\'re on fire! 3 days in a row!');
    if (_profile.streakDays >= 7)
      award('🔥 7-Day Streak',  'One full week of practice! Amazing!');
    if (_profile.streakDays >= 30)
      award('🏆 30-Day Streak', 'A full month streak! Incredible!');
    if (_profile.wordsLearned >= 10)
      award('📚 10 Words',      'You\'ve learned 10 vocabulary words!');
    if (_profile.wordsLearned >= 50)
      award('📖 50 Words',      'Amazing vocabulary! 50 words learned!');
    if (_profile.quizzesCompleted >= 5)
      award('🧠 Quiz Master',   'You\'ve completed 5 quizzes!');
    if (_profile.challengeStreak >= 7)
      award('⚡ Challenge Week', 'One full week of daily challenges!');
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

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isLoggedIn      = p.getBool('loggedIn')      ?? false;
    _notificationsOn = p.getBool('notifications')  ?? true;
    _reminderTime    = p.getString('reminderTime') ?? '08:00';
    final raw = p.getString('profile');
    if (raw != null) {
      try {
        _profile = UserProfile.fromJson(jsonDecode(raw));
      } catch (_) {
        _profile = UserProfile();
      }
    }

    // Load chat messages
    final chatRaw = p.getString('chatMessages');
    if (chatRaw != null) {
      try {
        final List<dynamic> chatList = jsonDecode(chatRaw);
        _chatMessages = chatList.map((j) => ChatMessage.fromJson(j)).toList();
      } catch (_) {
        _chatMessages = [];
      }
    }

    // Load vocabulary
    final vocabRaw = p.getString('vocabulary');
    if (vocabRaw != null) {
      try {
        final List<dynamic> vocabList = jsonDecode(vocabRaw);
        _vocabulary = vocabList.map((j) => VocabularyWord.fromJson(j)).toList();
      } catch (_) {
        _vocabulary = [];
      }
    }

    // Load quiz history
    final quizRaw = p.getString('quizHistory');
    if (quizRaw != null) {
      try {
        final List<dynamic> quizList = jsonDecode(quizRaw);
        _quizHistory = quizList.map((j) => QuizResult.fromJson(j)).toList();
      } catch (_) {
        _quizHistory = [];
      }
    }

    // Load interview sessions
    final intRaw = p.getString('interviewSessions');
    if (intRaw != null) {
      try {
        final List<dynamic> intList = jsonDecode(intRaw);
        _interviewSessions = intList.map((j) => InterviewSession.fromJson(j)).toList();
      } catch (_) {
        _interviewSessions = [];
      }
    }

    // Load daily challenges
    final dcRaw = p.getString('dailyChallenges');
    if (dcRaw != null) {
      try {
        final List<dynamic> dcList = jsonDecode(dcRaw);
        _dailyChallenges = dcList.map((j) => DailyChallenge.fromJson(j)).toList();
      } catch (_) {
        _dailyChallenges = [];
      }
    }

    // Load weak areas
    final waRaw = p.getString('weakAreas');
    if (waRaw != null) {
      try {
        final List<dynamic> waList = jsonDecode(waRaw);
        _weakAreas = waList.map((j) => WeakArea.fromJson(j)).toList();
      } catch (_) {
        _weakAreas = [];
      }
    }

    notifyListeners();
  }

  Future<void> _saveProfile() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('loggedIn', _isLoggedIn);
    await p.setString('profile', jsonEncode(_profile.toJson()));
  }

  Future<void> _savePrefs() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('notifications',  _notificationsOn);
    await p.setString('reminderTime', _reminderTime);
  }

  Future<void> _saveChatMessages() async {
    final p = await SharedPreferences.getInstance();
    final chatJson = jsonEncode(_chatMessages.map((m) => m.toJson()).toList());
    await p.setString('chatMessages', chatJson);
  }

  Future<void> _saveVocabulary() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('vocabulary', jsonEncode(_vocabulary.map((v) => v.toJson()).toList()));
  }

  Future<void> _saveQuizHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('quizHistory', jsonEncode(_quizHistory.map((q) => q.toJson()).toList()));
  }

  Future<void> _saveInterviewSessions() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('interviewSessions', jsonEncode(_interviewSessions.map((s) => s.toJson()).toList()));
  }

  Future<void> _saveDailyChallenges() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('dailyChallenges', jsonEncode(_dailyChallenges.map((c) => c.toJson()).toList()));
  }

  Future<void> _saveWeakAreas() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('weakAreas', jsonEncode(_weakAreas.map((w) => w.toJson()).toList()));
  }

  Future<void> clearAllData() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    _profile         = UserProfile();
    _chatMessages    = [];
    _vocabulary      = [];
    _quizHistory     = [];
    _interviewSessions = [];
    _dailyChallenges = [];
    _weakAreas       = [];
    _notificationsOn = true;
    _reminderTime    = '08:00';
    _isLoggedIn      = false;
    notifyListeners();
  }
}