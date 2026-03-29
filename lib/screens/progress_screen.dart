import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../widgets/responsive_layout.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ResponsiveContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Overall Level Card
            _DashboardCard(profile: profile),
            const SizedBox(height: 32),

            // 2. Skill Breakdown
            _sectionHeader('SKILL ANALYSIS'),
            _SkillBreakdown(
              fluency: profile.fluencyScore,
              grammar: profile.grammarScore,
              confidence: profile.confidenceScore,
            ),
            const SizedBox(height: 32),

            // 3. Badges & Achievements
            _sectionHeader('ACHIEVEMENTS'),
            if (profile.badges.isEmpty)
              _emptyState(context, 'Complete sessions to earn badges!')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profile.badges.length,
                itemBuilder: (context, index) => _BadgeTile(badge: profile.badges[index]),
              ),
            const SizedBox(height: 32),

            _sectionHeader('RECENT SESSIONS'),
            _RecentActivity(sessions: profile.recentSessions),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 16),
    child: Text(
      title,
      style: GoogleFonts.outfit(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _emptyState(BuildContext context, String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
    ),
    child: Text(
      msg,
      textAlign: TextAlign.center,
      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
    ),
  );
}

class _DashboardCard extends StatelessWidget {
  final UserProfile profile;
  const _DashboardCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global Proficiency', style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                    Text(
                      profile.experienceLevel.toUpperCase(),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _statItem('🔥', '${profile.streakDays}', 'Streak')),
              Expanded(child: _statItem('🏆', '${profile.totalXP}', 'Total XP')),
              Expanded(child: _statItem('📈', '${profile.practiceMinutes}', 'Mins')),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Share.share(
                  'I\'ve reached Level ${profile.level} on SpeakUp AI! 🚀\n'
                  'Streak: ${profile.streakDays} days 🔥\n'
                  'Total XP: ${profile.totalXP} 🏆\n'
                  'Join me in mastering English! #SpeakUpAI #PlacementPrep',
                );
              },
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
              label: const Text('Share My Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _statItem(String emoji, String val, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 6),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(val, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
    ],
  );
}

class _SkillBreakdown extends StatelessWidget {
  final double fluency, grammar, confidence;
  const _SkillBreakdown({required this.fluency, required this.grammar, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        children: [
          _skillRow(context, 'Fluency', fluency / 10, AppTheme.primary),
          const SizedBox(height: 16),
          _skillRow(context, 'Grammar', grammar / 10, AppTheme.secondary),
          const SizedBox(height: 16),
          _skillRow(context, 'Confidence', confidence / 10, AppTheme.success),
        ],
      ),
    );
  }

  Widget _skillRow(BuildContext context, String label, double val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('${(val * 100).toInt()}%', style: GoogleFonts.outfit(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 6,
          percent: val.clamp(0.0, 1.0),
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : AppTheme.lightSurface,
          progressColor: color,
          barRadius: const Radius.circular(3),
          padding: EdgeInsets.zero,
          animation: true,
          animationDuration: 1200,
          curve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchievementBadge badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(badge.icon.isEmpty ? '🏅' : badge.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.name, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(badge.description, style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<PracticeSession> sessions;
  const _RecentActivity({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.history_rounded, color: AppTheme.darkBorder, size: 32),
            const SizedBox(height: 12),
            Text('No recent activity', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final s = sessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (s.type == 'Interview' ? AppTheme.secondary : AppTheme.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  s.type == 'Interview' ? Icons.business_center_rounded : Icons.record_voice_over_rounded,
                  color: s.type == 'Interview' ? AppTheme.secondary : AppTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.topic,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(s.type.toUpperCase(),
                        style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+${s.xp} XP', style: GoogleFonts.outfit(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 13)),
                  Text('${s.score.toInt()}/10', style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
