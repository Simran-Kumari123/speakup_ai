import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({super.key});
  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen> {

  @override
  void initState() {
    super.initState();
    _ensureChallenges();
  }

  void _ensureChallenges() {
    final state = context.read<AppState>();
    final today = DateTime.now();
    final todaysChallenges = state.dailyChallenges.where((c) =>
        c.date.year == today.year && c.date.month == today.month && c.date.day == today.day);
    if (todaysChallenges.isEmpty) {
      state.setDailyChallenges([
        DailyChallenge(id: const Uuid().v4(), type: 'speaking', title: '1-Minute Speaking Challenge',
          description: 'Record yourself speaking about your strengths for 1 minute.', xpReward: 25),
        DailyChallenge(id: const Uuid().v4(), type: 'vocab', title: 'Vocabulary Challenge',
          description: 'Learn today\'s word and use it in a sentence.', xpReward: 20),
        DailyChallenge(id: const Uuid().v4(), type: 'quiz', title: 'Quick Quiz',
          description: 'Answer 5 grammar questions correctly.', xpReward: 30),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final today = DateTime.now();
    final todaysChallenges = state.dailyChallenges.where((c) =>
        c.date.year == today.year && c.date.month == today.month && c.date.day == today.day).toList();
    final completed = todaysChallenges.where((c) => c.completed).length;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Daily Challenges ⚡')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Streak + Progress
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.accent.withOpacity(0.12), AppTheme.darkCard]),
              borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.accent.withOpacity(0.3))),
            child: Row(children: [
              Column(children: [
                Text('🔥', style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text('${state.profile.challengeStreak}', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 28)),
                Text('Day Streak', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
              ]),
              const SizedBox(width: 24),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Today\'s Progress', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 6),
                Text('$completed/${todaysChallenges.length} challenges completed', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: todaysChallenges.isEmpty ? 0 : completed / todaysChallenges.length,
                  backgroundColor: AppTheme.darkSurface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  borderRadius: BorderRadius.circular(4), minHeight: 8,
                ),
              ])),
            ]),
          ).animate().fadeIn(),
          const SizedBox(height: 24),

          Text('Today\'s Challenges', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),

          ...todaysChallenges.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final emoji = {'speaking': '🎤', 'vocab': '📖', 'quiz': '🧠'}[c.type] ?? '⭐';
            final color = {'speaking': AppTheme.primary, 'vocab': AppTheme.secondary, 'quiz': Colors.purple}[c.type] ?? AppTheme.primary;

            return GestureDetector(
              onTap: c.completed ? null : () => _goToChallenge(c),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.completed ? AppTheme.primary.withOpacity(0.05) : AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.completed ? AppTheme.primary.withOpacity(0.3) : AppTheme.darkBorder)),
                child: Row(children: [
                  Container(width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: (c.completed ? AppTheme.primary : color).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14)),
                    child: Center(child: Text(c.completed ? '✅' : emoji, style: const TextStyle(fontSize: 22)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.title, style: GoogleFonts.dmSans(
                      color: c.completed ? AppTheme.primary : Colors.white,
                      fontWeight: FontWeight.w700, fontSize: 14,
                      decoration: c.completed ? TextDecoration.lineThrough : null)),
                    const SizedBox(height: 2),
                    Text(c.description, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
                  ])),
                  Column(children: [
                    Text('+${c.xpReward}', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('XP', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10)),
                  ]),
                ]),
              ),
            ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.05);
          }),

          const SizedBox(height: 24),

          // Bonus rewards
          if (completed == todaysChallenges.length && todaysChallenges.isNotEmpty)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.15), AppTheme.secondary.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.primary.withOpacity(0.4))),
              child: Column(children: [
                const Text('🏆', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text('All Challenges Complete!', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Great job! Come back tomorrow for more.', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
              ]),
            ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
        ]),
      ),
    );
  }

  void _goToChallenge(DailyChallenge challenge) {
    final state = context.read<AppState>();
    // Mark as complete and award XP
    state.completeDailyChallenge(challenge.id);
    state.addXP(challenge.xpReward);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${challenge.title} completed! +${challenge.xpReward} XP ⭐'),
      backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating,
    ));
  }
}
