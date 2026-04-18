import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ConfidenceMeter extends StatelessWidget {
  final double score;
  final double size;

  const ConfidenceMeter({
    super.key,
    required this.score,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Score is 0-10
    final Color color = score >= 8
        ? AppTheme.primary
        : score >= 6
            ? AppTheme.earthyAccent
            : AppTheme.danger;

    final String label = score >= 8
        ? 'Excellent'
        : score >= 6
            ? 'Good'
            : 'Needs Practice';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutQuart,
            builder: (context, value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Track
                  CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(color.withOpacity(0.1)),
                  ),
                  // Progress
                  CircularProgressIndicator(
                    value: value / 10,
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                  // Score text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value.toStringAsFixed(1),
                        style: GoogleFonts.outfit(
                          color: color,
                          fontSize: size * 0.32,
                          fontWeight: FontWeight.w900,
                          height: 1.1, // Increased height slightly for spacing
                        ),
                      ),
                      const SizedBox(height: 2), // Added small gap
                      Text(
                        'SCORE / 10',
                        style: GoogleFonts.outfit(
                          color: color.withOpacity(0.5),
                          fontSize: size * 0.08,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
