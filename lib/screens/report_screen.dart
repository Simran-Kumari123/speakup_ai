import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;
  const ReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String grade = reportData['grade'] ?? 'B+';
    final String summary = reportData['summary'] ?? '';
    final Map<String, dynamic> breakdown = reportData['breakdown'] ?? {};
    final List<String> strengths = List<String>.from(reportData['strengths'] ?? []);
    final List<String> improvements = List<String>.from(reportData['improvements'] ?? []);
    final List<String> tips = List<String>.from(reportData['tips'] ?? []);
    final String nextSteps = reportData['nextSteps'] ?? '';

    final Map<String, Color> gradeColor = {
      'S': AppTheme.secondary,
      'A': AppTheme.primary,
      'B': Colors.orangeAccent,
      'C': AppTheme.danger,
    };

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Session Report 📊')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Grade
          Center(child: Container(
            width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: (gradeColor[grade] ?? AppTheme.primary).withOpacity(0.12),
              border: Border.all(color: gradeColor[grade] ?? AppTheme.primary, width: 3)),
            child: Center(child: Text(grade, style: GoogleFonts.dmSans(color: gradeColor[grade] ?? AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 40))),
          )).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 16),
          Center(child: Text(summary, textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 15, height: 1.5, fontWeight: FontWeight.w500))),
          const SizedBox(height: 24),

          // Score Breakdown
          _sectionTitle('Score Breakdown', context),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
            child: Column(children: [
              _scoreBar('Grammar',    (breakdown['grammar']    as num?)?.toDouble() ?? 7.0, context),
              _scoreBar('Vocabulary', (breakdown['vocabulary'] as num?)?.toDouble() ?? 7.0, context),
              _scoreBar('Fluency',    (breakdown['fluency']    as num?)?.toDouble() ?? 7.0, context),
              _scoreBar('Confidence', (breakdown['confidence'] as num?)?.toDouble() ?? 7.0, context),
            ]),
          ),
          const SizedBox(height: 20),

          // Strengths
          if (strengths.isNotEmpty) ...[
            _sectionTitle('💪 Strengths', context),
            ...strengths.asMap().entries.map((e) => _listItem(e.value, AppTheme.primary, e.key, context)),
            const SizedBox(height: 16),
          ],

          // Improvements
          if (improvements.isNotEmpty) ...[
            _sectionTitle('⚠️ Areas to Improve', context),
            ...improvements.asMap().entries.map((e) => _listItem(e.value, AppTheme.danger, e.key, context)),
            const SizedBox(height: 16),
          ],

          // Tips
          if (tips.isNotEmpty) ...[
            _sectionTitle('💡 Tips', context),
            ...tips.asMap().entries.map((e) => _listItem(e.value, AppTheme.accent, e.key, context)),
            const SizedBox(height: 16),
          ],

          // Next steps
          if (nextSteps.isNotEmpty) ...[
            _sectionTitle('📋 Next Steps', context),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.15))),
              child: Text(nextSteps, style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.bold)),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(t, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.w900, fontSize: 16)),
  );

  Widget _scoreBar(String label, double value, BuildContext context) {
    final theme = Theme.of(context);
    final color = value >= 8 ? theme.colorScheme.primary : value >= 6 ? AppTheme.earthyAccent : AppTheme.danger;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: value / 10, backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
        valueColor: AlwaysStoppedAnimation(color), minHeight: 10))),
      const SizedBox(width: 12),
      Text(value.toStringAsFixed(1), style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w900)),
    ]));
  }

  Widget _listItem(String text, Color color, int i, BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.bold))),
    ]),
  ).animate().fadeIn(delay: (i * 60).ms);
}
