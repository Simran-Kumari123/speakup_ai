import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Premium Header & Level Indicator ──
          _buildHeader(profile, context),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Dashboard Stats ──
                _buildStatsGrid(profile, context),
                const SizedBox(height: 32),

                // ── Weekly Activity Chart ──
                _sectionHeader('WEEKLY ACTIVITY', context),
                _WeeklyActivityChart(weeklyXP: state.weeklyXPData),
                const SizedBox(height: 32),

                // ── Skill Matrix ──
                _sectionHeader('SKILL MATRIX', context),
                _SkillBreakdown(
                  fluency: profile.fluencyScore,
                  grammar: profile.grammarScore,
                  confidence: profile.confidenceScore,
                ),
                const SizedBox(height: 32),

                // ── Achievements ──
                _sectionHeader('ACHIEVEMENTS', context),
                if (profile.badges.isEmpty)
                  _emptyState(context, 'Complete sessions to earn badges!')
                else
                  _buildBadgeGrid(profile.badges, context),
                const SizedBox(height: 32),

                // ── Recent Activity ──
                _sectionHeader('RECENT SESSIONS', context),
                _RecentActivity(sessions: profile.recentSessions),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile profile, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          CircularPercentIndicator(
            radius: 80,
            lineWidth: 12,
            percent: (profile.totalXP % 200) / 200,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LEVEL', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
                Text('${profile.level}', style: GoogleFonts.dmSans(color: theme.textTheme.displaySmall?.color, fontWeight: FontWeight.w900, fontSize: 44)),
              ],
            ),
            circularStrokeCap: CircularStrokeCap.round,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
            linearGradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
            animation: true,
            animationDuration: 1500,
          ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          Text(profile.experienceLevel.toUpperCase(), style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text('${profile.xpToNext} XP to Level ${profile.level + 1}', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserProfile profile, BuildContext context) {
    return Row(
      children: [
        _statCard('🔥', profile.streakDays.toString(), 'Streak', AppTheme.primary, context),
        const SizedBox(width: 12),
        _statCard('🏆', profile.totalXP.toString(), 'Total XP', AppTheme.secondary, context),
        const SizedBox(width: 12),
        _statCard('📈', profile.practiceMinutes.toString(), 'Mins', AppTheme.accent, context),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1);
  }

  Widget _statCard(String emoji, String val, String label, Color color, BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(val, style: GoogleFonts.dmSans(color: theme.textTheme.titleLarge?.color, fontWeight: FontWeight.w900, fontSize: 20)),
            Text(label.toUpperCase(), style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeGrid(List<AchievementBadge> badges, BuildContext context) {
    final theme = Theme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length > 4 ? 4 : badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4),
      itemBuilder: (ctx, i) {
        final b = badges[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.earthyAccent.withOpacity(0.05), shape: BoxShape.circle),
                child: Text(b.icon.isEmpty ? '🏅' : b.icon, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 10),
              Expanded(child: Text(b.name, style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color, fontWeight: FontWeight.w700, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionHeader(String title, BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 16),
    child: Text(title, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
  );

  Widget _emptyState(BuildContext context, String msg) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05))),
    child: Text(msg, textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w500)),
  );
}

class _WeeklyActivityChart extends StatelessWidget {
  final List<int> weeklyXP;
  const _WeeklyActivityChart({required this.weeklyXP});

  @override
  Widget build(BuildContext context) {
    final double maxVal = weeklyXP.isEmpty ? 100 : weeklyXP.reduce((a, b) => a > b ? a : b).toDouble();
    final maxXP = maxVal.clamp(100.0, 5000.0);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final height = (weeklyXP[i] / maxXP * 100).clamp(5.0, 100.0);
              final isToday = DateTime.now().weekday - 1 == i;
              return Column(
                children: [
                  Container(
                    width: 28, height: height,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: isToday ? [AppTheme.primary, AppTheme.secondary] : [theme.scaffoldBackgroundColor, theme.scaffoldBackgroundColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: isToday ? null : Border.all(color: theme.dividerColor.withOpacity(0.05)),
                    ),
                  ).animate().scaleY(begin: 0, duration: 1000.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 8),
                  Text(days[i], style: GoogleFonts.dmSans(color: isToday ? AppTheme.primary : theme.textTheme.bodySmall?.color?.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900)),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart_rounded, color: AppTheme.primary, size: 14),
              const SizedBox(width: 8),
              Text('XP per day over the last week', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillBreakdown extends StatelessWidget {
  final double fluency, grammar, confidence;
  const _SkillBreakdown({required this.fluency, required this.grammar, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(28), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
      child: Column(
        children: [
          _skillRow('Fluency', fluency / 10, AppTheme.primary, context),
          const SizedBox(height: 20),
          _skillRow('Grammar', grammar / 10, AppTheme.secondary, context),
          const SizedBox(height: 20),
          _skillRow('Confidence', confidence / 10, AppTheme.earthyAccent, context),
        ],
      ),
    );
  }

  Widget _skillRow(String label, double val, Color color, BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.dmSans(color: theme.textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w700)),
            Text('${(val * 100).toInt()}%', style: GoogleFonts.dmSans(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: val.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<PracticeSession> sessions;
  const _RecentActivity({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (sessions.isEmpty) {
      return Container(
        width: double.infinity, padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
        child: Column(children: [
          Icon(Icons.history_rounded, color: theme.dividerColor.withOpacity(0.1), size: 32),
          const SizedBox(height: 12),
          Text('No recent activity', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      );
    }

    return Column(
      children: sessions.take(5).map((s) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(s.type == 'Interview' ? Icons.business_center_rounded : Icons.record_voice_over_rounded, color: AppTheme.primary, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.topic, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(s.type.toUpperCase(), style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ]),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('+${s.xp} XP', style: GoogleFonts.dmSans(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                Text('${s.score.toInt()}/10', style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        );
      }).toList(),
    );
  }
}
