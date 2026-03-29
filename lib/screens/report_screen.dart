import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;
  const ReportScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final grade = reportData['overallGrade'] ?? 'B';
    final summary = reportData['summary'] ?? 'Session completed.';
    final breakdown = reportData['scoreBreakdown'] as Map<String, dynamic>? ?? {};
    final strengths = List<String>.from(reportData['topStrengths'] ?? []);
    final improvements = List<String>.from(reportData['areasToImprove'] ?? []);
    final tips = List<String>.from(reportData['tips'] ?? []);
    final nextSteps = reportData['nextSteps'] ?? '';

    final gradeColor = {'A': AppTheme.primary, 'B': AppTheme.secondary, 'C': AppTheme.accent, 'D': AppTheme.danger, 'F': AppTheme.danger};

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
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
            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14, height: 1.5))),
          const SizedBox(height: 24),

          // Score Breakdown
          _sectionTitle('Score Breakdown'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
            child: Column(children: [
              _scoreBar('Grammar',    (breakdown['grammar']    as num?)?.toDouble() ?? 7.0),
              _scoreBar('Vocabulary', (breakdown['vocabulary'] as num?)?.toDouble() ?? 7.0),
              _scoreBar('Fluency',    (breakdown['fluency']    as num?)?.toDouble() ?? 7.0),
              _scoreBar('Confidence', (breakdown['confidence'] as num?)?.toDouble() ?? 7.0),
            ]),
          ),
          const SizedBox(height: 20),

          // Strengths
          if (strengths.isNotEmpty) ...[
            _sectionTitle('💪 Strengths'),
            ...strengths.asMap().entries.map((e) => _listItem(e.value, AppTheme.primary, e.key)),
            const SizedBox(height: 16),
          ],

          // Improvements
          if (improvements.isNotEmpty) ...[
            _sectionTitle('⚠️ Areas to Improve'),
            ...improvements.asMap().entries.map((e) => _listItem(e.value, AppTheme.danger, e.key)),
            const SizedBox(height: 16),
          ],

          // Tips
          if (tips.isNotEmpty) ...[
            _sectionTitle('💡 Tips'),
            ...tips.asMap().entries.map((e) => _listItem(e.value, AppTheme.accent, e.key)),
            const SizedBox(height: 16),
          ],

          // Next steps
          if (nextSteps.isNotEmpty) ...[
            _sectionTitle('📋 Next Steps'),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.secondary.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.secondary.withOpacity(0.2))),
              child: Text(nextSteps, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5)),
            ),
          ],
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
  );

  Widget _scoreBar(String label, double value) {
    final color = value >= 8 ? AppTheme.primary : value >= 6 ? AppTheme.accent : AppTheme.danger;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13))),
      Expanded(child: LinearProgressIndicator(value: value / 10, backgroundColor: AppTheme.darkSurface,
        valueColor: AlwaysStoppedAnimation(color), borderRadius: BorderRadius.circular(4), minHeight: 8)),
      const SizedBox(width: 10),
      Text(value.toStringAsFixed(1), style: GoogleFonts.dmSans(color: color, fontWeight: FontWeight.w700)),
    ]));
  }

  Widget _listItem(String text, Color color, int i) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5))),
    ]),
  ).animate().fadeIn(delay: (i * 60).ms);
}
