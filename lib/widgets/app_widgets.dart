import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class FeatureCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
          const Spacer(),
          Text(title, style: GoogleFonts.dmSans(color: theme.textTheme.titleSmall?.color, fontWeight: FontWeight.w900, fontSize: 13),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}

class ScoreDisplay extends StatelessWidget {
  final double score;
  final double size;
  final Color? color;
  final String? label;

  const ScoreDisplay({super.key, required this.score, this.size = 56, this.color, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? (score >= 8 ? theme.colorScheme.primary : score >= 6 ? AppTheme.earthyAccent : AppTheme.danger);
    return Column(children: [
      SizedBox(
        width: size, height: size,
        child: Stack(alignment: Alignment.center, children: [
          CircularProgressIndicator(
            value: score / 10,
            strokeWidth: 4,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
            valueColor: AlwaysStoppedAnimation(c),
            strokeCap: StrokeCap.round,
          ),
          Text(score.toStringAsFixed(1), style: GoogleFonts.dmSans(color: c, fontWeight: FontWeight.w900, fontSize: size * 0.28)),
        ]),
      ),
      if (label != null) ...[
        const SizedBox(height: 6),
        Text(label!, style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    ]);
  }
}

class StreakBadge extends StatelessWidget {
  final int streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.earthyAccent.withOpacity(0.08), AppTheme.danger.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppTheme.earthyAccent.withOpacity(0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔥', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text('$streak day${streak != 1 ? 's' : ''}',
          style: GoogleFonts.dmSans(color: AppTheme.earthyAccent, fontWeight: FontWeight.w900, fontSize: 13)),
      ]),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2000.ms, color: AppTheme.earthyAccent.withOpacity(0.1));
  }
}
