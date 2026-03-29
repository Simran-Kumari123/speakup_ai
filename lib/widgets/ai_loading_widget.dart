import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AILoadingWidget extends StatelessWidget {
  const AILoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40, height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
          const SizedBox(height: 20),
          Text(
            'AI IS ANALYZING',
            style: GoogleFonts.outfit(
              color: AppTheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds, color: AppTheme.secondary.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            'Generating personalized feedback...',
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}