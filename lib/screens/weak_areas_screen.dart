import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class WeakAreasScreen extends StatelessWidget {
  const WeakAreasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final areas = state.weakAreas;
    final weakWords = state.profile.weakWords;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Weak Areas 🎯')),
      body: areas.isEmpty && weakWords.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No weak areas detected yet!', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Complete more practice sessions\nto track your progress.', textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 14)),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Summary
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.danger.withOpacity(0.1), AppTheme.darkCard]),
                    borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('📊 Your Weak Areas Summary', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('${areas.length} areas detected • ${weakWords.length} weak words',
                      style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
                  ]),
                ).animate().fadeIn(),
                const SizedBox(height: 20),

                // Areas
                if (areas.isNotEmpty) ...[
                  Text('Skill Areas', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...areas.asMap().entries.map((entry) {
                    final i = entry.key;
                    final a = entry.value;
                    final emoji = {'grammar': '📝', 'pronunciation': '🗣️', 'vocabulary': '📖', 'fluency': '🌊'}[a.category] ?? '⚠️';
                    final color = {'grammar': AppTheme.danger, 'pronunciation': AppTheme.accent, 'vocabulary': AppTheme.secondary, 'fluency': Colors.purple}[a.category] ?? AppTheme.danger;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(a.category[0].toUpperCase() + a.category.substring(1),
                            style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700, fontSize: 15)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(99)),
                            child: Text('${a.errorCount} errors', style: GoogleFonts.dmSans(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        if (a.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(a.description, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13, height: 1.5)),
                        ],
                        if (a.exampleMistakes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Example Mistakes:', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700)),
                          ...a.exampleMistakes.take(3).map((m) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('  ✗ $m', style: GoogleFonts.dmSans(color: AppTheme.danger.withOpacity(0.7), fontSize: 12)),
                          )),
                        ],
                        if (a.recommendations.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('Recommendations:', style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                          ...a.recommendations.take(3).map((r) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text('  💡 $r', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
                          )),
                        ],
                      ]),
                    ).animate().fadeIn(delay: (i * 80).ms);
                  }),
                  const SizedBox(height: 20),
                ],

                // Weak words
                if (weakWords.isNotEmpty) ...[
                  Text('Words to Practice', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: weakWords.map((w) => Chip(
                    label: Text(w, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    backgroundColor: AppTheme.danger.withOpacity(0.12),
                    side: BorderSide(color: AppTheme.danger.withOpacity(0.3)),
                  )).toList()),
                ],
                const SizedBox(height: 24),
              ]),
            ),
    );
  }
}
