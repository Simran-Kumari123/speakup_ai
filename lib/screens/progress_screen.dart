import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('My Progress 📈')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Level + XP ring
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Row(children: [
              CircularPercentIndicator(
                radius: 56, lineWidth: 8,
                percent: (profile.totalXP % 200) / 200,
                center: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${profile.level}', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                  Text('LEVEL', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 9)),
                ]),
                progressColor: AppTheme.primary,
                backgroundColor: AppTheme.darkSurface,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${profile.name}', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                Text(profile.targetRole, style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 12)),
                const SizedBox(height: 10),
                Text('${profile.totalXP} XP total', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (profile.totalXP % 200) / 200,
                  backgroundColor: AppTheme.darkSurface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text('${profile.xpToNext} XP to Level ${profile.level + 1}',
                    style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          // Stats
          Text('Your Stats', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
            children: [
              _stat('🔥', 'Day Streak',      '${profile.streakDays}',        'days',    AppTheme.danger),
              _stat('📚', 'Sessions',        '${profile.sessionsCompleted}', 'done',    AppTheme.secondary),
              _stat('⏱️', 'Practice Time',   '${profile.practiceMinutes}',  'minutes', AppTheme.accent),
              _stat('🔤', 'Words Spoken',    '${profile.wordsSpoken}',       'words',   AppTheme.primary),
            ],
          ),

          const SizedBox(height: 24),

          // Weekly activity
          Text('This Week', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar('M', 0.6, false), _bar('T', 0.8, false), _bar('W', 1.0, false),
                _bar('T', 0.4, false), _bar('F', 0.7, false), _bar('S', 0.3, false),
                _bar('S', 0.5, true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Topic progress
          Text('Topic Progress', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...kPracticeTopics.map((t) => _topicRow(t)).toList(),

          const SizedBox(height: 24),

          // Badges
          Text('Badges', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _badge('🌟', 'First Session',  profile.sessionsCompleted >= 1),
            _badge('🔥', '3-Day Streak',   profile.streakDays >= 3),
            _badge('🥉', '100 XP',         profile.totalXP >= 100),
            _badge('🥈', '500 XP',         profile.totalXP >= 500),
            _badge('🎯', '5 Sessions',     profile.sessionsCompleted >= 5),
            _badge('🏆', 'Interview Pro',  profile.sessionsCompleted >= 10),
          ]),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _stat(String emoji, String label, String value, String unit, Color color) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(value, style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
          Text('$label', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
        ]),
      );

  Widget _bar(String day, double h, bool isToday) => Column(mainAxisSize: MainAxisSize.min, children: [
    Container(
      width: 26, height: (60 * h).clamp(4, 60),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: isToday ? AppTheme.primary : AppTheme.primary.withOpacity(0.35),
      ),
    ),
    const SizedBox(height: 6),
    Text(day, style: GoogleFonts.dmSans(fontSize: 11,
        color: isToday ? AppTheme.primary : Colors.white38,
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400)),
  ]);

  Widget _topicRow(PracticeTopic t) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder)),
    child: Row(children: [
      Text(t.emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: t.progress / 100,
          backgroundColor: AppTheme.darkSurface,
          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
          borderRadius: BorderRadius.circular(4), minHeight: 5,
        ),
      ])),
      const SizedBox(width: 10),
      Text('${t.progress}%', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );

  Widget _badge(String emoji, String label, bool earned) => Column(mainAxisSize: MainAxisSize.min, children: [
    AnimatedOpacity(
      opacity: earned ? 1.0 : 0.25,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: earned ? AppTheme.primary.withOpacity(0.15) : AppTheme.darkSurface,
          border: Border.all(color: earned ? AppTheme.primary.withOpacity(0.4) : AppTheme.darkBorder),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 26))),
      ),
    ),
    const SizedBox(height: 4),
    SizedBox(width: 64, child: Text(label, textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(color: earned ? AppTheme.primary : Colors.white30, fontSize: 10, fontWeight: FontWeight.w600))),
  ]);
}
