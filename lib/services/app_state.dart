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

  // ── Auth ───────────────────────────────────────────────────────────────────
  void login(String name, String email,
      {String role = 'Software Engineer', String level = 'Fresher'}) {
    _profile = UserProfile(
        name: name, email: email, targetRole: role, experienceLevel: level);
    _isLoggedIn = true;
    _saveProfile();
    notifyListeners();
  }

  // ✅ UPDATED: now async so Navigator.pushAndRemoveUntil can await it
  Future<void> logout() async {
    _isLoggedIn = false;
    final p = await SharedPreferences.getInstance();
    await p.setBool('loggedIn', false);
    // Progress (XP, streaks, badges) is kept — only auth flag is cleared.
    // Call clearAllData() if user explicitly wants to wipe everything.
    notifyListeners();
  }

  // ── XP & Progress ──────────────────────────────────────────────────────────
  void addXP(int xp) {
    final before = _profile.totalXP;
    _profile.totalXP += xp;
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

  // ✅ KEPT EXACTLY — matches how profile_screen.dart calls it:
  //    state.updateProfile(name: ..., email: ..., role: ..., level: ...)
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
    notifyListeners();
  }

  void clearChat() {
    _chatMessages.clear();
    notifyListeners();
  }

  // ── Settings ───────────────────────────────────────────────────────────────
  // ✅ KEPT EXACTLY — profile_screen.dart calls: state.toggleNotifications(bool)
  void toggleNotifications(bool v) {
    _notificationsOn = v;
    _savePrefs();
    notifyListeners();
  }

  // ✅ KEPT EXACTLY — profile_screen.dart calls: state.setReminderTime(String)
  void setReminderTime(String t) {
    _reminderTime = t;
    _savePrefs();
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
    if (_profile.sessionsCompleted >= 1)
      award('🎯 First Session',  'You completed your first practice session!');
    if (_profile.sessionsCompleted >= 5)
      award('🎯 5 Sessions',    'You completed 5 practice sessions!');
    if (_profile.sessionsCompleted >= 10)
      award('💎 10 Sessions',   'You\'re on a roll! 10 sessions done!');
    if (_profile.streakDays >= 3)
      award('🔥 3-Day Streak',  'You\'re on fire! 3 days in a row!');
    if (_profile.streakDays >= 7)
      award('🔥 7-Day Streak',  'One full week of practice! Amazing!');
  }

  void _checkXPMilestones(int before, int after) {
    for (final milestone in [100, 500, 1000, 2000]) {
      if (before < milestone && after >= milestone) {
        NotificationService.sendXPMilestone(milestone);
      }
    }
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  // ✅ ADDED: main.dart calls `await appState.init()` — just an alias for load()
  Future<void> init() => load();

  // ✅ KEPT EXACTLY — your original load logic
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
        _profile = UserProfile(); // safe fallback if data is corrupted
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

  // ✅ ADDED: Called from Settings screen → "Clear App Data" button
  Future<void> clearAllData() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    _profile         = UserProfile();
    _chatMessages    = [];
    _notificationsOn = true;
    _reminderTime    = '08:00';
    _isLoggedIn      = false;
    notifyListeners();
  }
}