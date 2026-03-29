import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/resume_service.dart';
import '../theme/app_theme.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  const ResumeAnalysisScreen({super.key});
  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _analysis;

  Future<void> _pickAndAnalyze() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) { setState(() => _error = 'Could not read file.'); return; }

      setState(() { _loading = true; _error = null; });
      final text = ResumeService.extractText(file.bytes!);
      final analysis = await ResumeService.analyze(text);
      if (!mounted) return;
      setState(() { _analysis = analysis; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Resume Analysis 📄')),
      body: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 16),
              Text('Analyzing your resume...', style: TextStyle(color: Colors.white54)),
            ]))
          : _analysis == null ? _buildUpload() : _buildAnalysis(),
    );
  }

  Widget _buildUpload() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 100, height: 100,
        decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.secondary.withOpacity(0.1), border: Border.all(color: AppTheme.secondary.withOpacity(0.3), width: 2)),
        child: const Icon(Icons.analytics_rounded, size: 48, color: AppTheme.secondary)),
      const SizedBox(height: 24),
      Text('Analyze Your Resume', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text('AI will identify your skills, experience\nand suggest a preparation plan.', textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 14, height: 1.5)),
      const SizedBox(height: 28),
      ElevatedButton.icon(onPressed: _pickAndAnalyze, icon: const Icon(Icons.upload_file_rounded), label: const Text('Upload Resume PDF')),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
        child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
    ]),
  ));

  Widget _buildAnalysis() {
    final skills = List<String>.from(_analysis?['skills'] ?? []);
    final strengths = List<String>.from(_analysis?['strengths'] ?? []);
    final weaknesses = List<String>.from(_analysis?['weaknesses'] ?? []);
    final plan = List<String>.from(_analysis?['preparationPlan'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.15), AppTheme.darkCard]),
            borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✅ Analysis Complete', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            _row('👤', 'Name', _analysis?['name'] ?? 'Not detected'),
            _row('📊', 'Experience', '${_analysis?['experienceLevel'] ?? 'N/A'} (${_analysis?['experienceYears'] ?? 0} years)'),
            _row('🎓', 'Education', _analysis?['education'] ?? 'N/A'),
            _row('💼', 'Recommended Role', _analysis?['recommendedRole'] ?? 'N/A'),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 20),

        // Skills
        _sectionTitle('🛠️ Skills Detected'),
        Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => Chip(
          label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
          backgroundColor: AppTheme.primary.withOpacity(0.12), side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
        )).toList()),
        const SizedBox(height: 20),

        // Strengths
        _sectionTitle('💪 Strengths'),
        ...strengths.map((s) => _bulletItem(s, AppTheme.primary)),
        const SizedBox(height: 16),

        // Weaknesses
        _sectionTitle('⚠️ Areas to Improve'),
        ...weaknesses.map((w) => _bulletItem(w, AppTheme.danger)),
        const SizedBox(height: 20),

        // Preparation Plan
        _sectionTitle('📋 Personalized Preparation Plan'),
        ...List.generate(plan.length, (i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.secondary.withOpacity(0.15)),
              child: Center(child: Text('${i + 1}', style: GoogleFonts.dmSans(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 13)))),
            const SizedBox(width: 12),
            Expanded(child: Text(plan[i], style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5))),
          ]),
        ).animate().fadeIn(delay: (i * 80).ms)),
        const SizedBox(height: 20),

        // Action button
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _pickAndAnalyze,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Analyze Another Resume'),
        )),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
  );

  Widget _row(String emoji, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 8),
      Text('$label: ', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
      Expanded(child: Text(value, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );

  Widget _bulletItem(String text, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.5))),
    ]),
  );
}
