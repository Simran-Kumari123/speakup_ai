import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Settings ⚙️')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Difficulty ──────────────────────────────────────────────────
          _section('DIFFICULTY LEVEL'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(children: [
              ...['beginner', 'intermediate', 'advanced'].map((d) {
                final emoji = {'beginner': '🌱', 'intermediate': '🌿', 'advanced': '🌳'}[d]!;
                final desc = {'beginner': 'Simple vocabulary, slow pacing', 'intermediate': 'Professional language', 'advanced': 'Complex structures, fast pacing'}[d]!;
                final selected = profile.difficulty == d;
                return GestureDetector(
                  onTap: () => state.setDifficulty(d),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppTheme.primary : Colors.transparent)),
                    child: Row(children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(d[0].toUpperCase() + d.substring(1), style: GoogleFonts.dmSans(color: selected ? AppTheme.primary : Colors.white, fontWeight: FontWeight.w600)),
                        Text(desc, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
                      ])),
                      if (selected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 18),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),

          // ── AI Personality ──────────────────────────────────────────────
          _section('AI PERSONALITY'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(children: [
              ...AIFeedbackService.personalityDescriptions.entries.map((e) {
                final mode = e.key;
                final emoji = {'friendly': '😊', 'strict': '👨‍🏫', 'hr': '👔', 'debate': '🤺'}[mode] ?? '🤖';
                final title = mode[0].toUpperCase() + mode.substring(1);
                final selected = profile.personalityMode == mode;
                return GestureDetector(
                  onTap: () => state.setPersonalityMode(mode),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.secondary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? AppTheme.secondary : Colors.transparent)),
                    child: Row(children: [
                      Text(emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('$title Coach', style: GoogleFonts.dmSans(color: selected ? AppTheme.secondary : Colors.white, fontWeight: FontWeight.w600)),
                        Text(e.value, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      if (selected) const Icon(Icons.check_circle, color: AppTheme.secondary, size: 18),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Voice Preference ────────────────────────────────────────────
          _section('VOICE SPEED'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Row(children: ['slow', 'normal', 'fast'].map((v) {
              final emoji = {'slow': '🐢', 'normal': '🚶', 'fast': '🏃'}[v]!;
              final selected = profile.voicePreference == v;
              return Expanded(child: GestureDetector(
                onTap: () => state.setVoicePreference(v),
                child: Container(
                  margin: EdgeInsets.only(right: v != 'fast' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accent.withOpacity(0.12) : AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppTheme.accent : AppTheme.darkBorder)),
                  child: Column(children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(v[0].toUpperCase() + v.substring(1),
                      style: GoogleFonts.dmSans(color: selected ? AppTheme.accent : Colors.white54, fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
              ));
            }).toList()),
          ),
          const SizedBox(height: 20),

          // ── Language ────────────────────────────────────────────────────
          _section('TRANSLATION LANGUAGE'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(children: TranslationService.supportedLanguages.entries.map((e) {
              final code = e.key;
              final langData = e.value;
              final selected = profile.language == code;
              return GestureDetector(
                onTap: () => state.setLanguage(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.darkBorder.withOpacity(0.5)))),
                  child: Row(children: [
                    Text(langData['flag'] ?? '🌐', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 12),
                    Text(langData['name'] ?? code, style: GoogleFonts.dmSans(color: selected ? AppTheme.primary : Colors.white70, fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                    const Spacer(),
                    if (selected) const Icon(Icons.check_circle, color: AppTheme.primary, size: 16),
                  ]),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 20),

          // ── Notifications ──────────────────────────────────────────────
          _section('NOTIFICATIONS'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 18),
                const SizedBox(width: 12),
                Text('Practice Reminders', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
                const Spacer(),
                Switch(value: state.notificationsOn, onChanged: state.toggleNotifications, activeColor: AppTheme.primary),
              ]),
              if (state.notificationsOn)
                Padding(padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.access_time, color: Colors.white38, size: 16),
                    const SizedBox(width: 12),
                    Text('Reminder Time', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
                    const Spacer(),
                    Text(state.reminderTime, style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Data ──────────────────────────────────────────────────────
          _section('DATA'),
          Container(
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
              title: Text('Clear All Data', style: GoogleFonts.dmSans(color: AppTheme.danger, fontSize: 13)),
              subtitle: Text('Reset all progress and settings', style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
              onTap: () => _confirmClear(context, state),
            ),
          ),
          const SizedBox(height: 32),
          Center(child: Text('AI Chat Coach v3.0', style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 11))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Clear All Data?', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
      content: Text('This will reset all your progress, XP, streaks, and settings. This cannot be undone.',
        style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Cancel', style: GoogleFonts.dmSans(color: Colors.white38))),
        TextButton(onPressed: () { Navigator.pop(ctx); state.clearAllData(); },
          child: Text('Clear All', style: GoogleFonts.dmSans(color: AppTheme.danger, fontWeight: FontWeight.w700))),
      ],
    ));
  }
}
