import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/resume_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'mock_interview_screen.dart';

class ResumeAnalysisScreen extends StatefulWidget {
  const ResumeAnalysisScreen({super.key});
  @override
  State<ResumeAnalysisScreen> createState() => _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState extends State<ResumeAnalysisScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _analysis;
  String? _resumeText;
  
  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    if (profile.resumeAnalysis != null) {
      _analysis = profile.resumeAnalysis;
      _resumeText = profile.resumeText;
    }
  }

  Future<void> _pickAndAnalyze() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.bytes == null) { 
        if (mounted) setState(() => _error = 'Could not read file.'); 
        return; 
      }

      if (mounted) setState(() => _loading = true);
      final text = ResumeService.extractText(file.bytes!);
      final analysis = await ResumeService.analyze(text);
      if (!mounted) return;
      setState(() { 
        _analysis = analysis; 
        _resumeText = text;
        _loading = false; 
      });
      context.read<AppState>().updateResume(text, analysis);
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Resume Analysis 📄')),
      body: _loading
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Analyzing your resume...', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ]))
          : _analysis == null ? _buildUpload(context) : _buildAnalysis(context),
    );
  }

  Widget _buildUpload(BuildContext context) {
    final theme = Theme.of(context);
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary.withOpacity(0.1), border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.3), width: 2)),
          child: Icon(Icons.analytics_rounded, size: 48, color: theme.colorScheme.secondary)),
        const SizedBox(height: 24),
        Text('Analyze Your Resume', style: GoogleFonts.dmSans(color: theme.textTheme.titleLarge?.color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('AI will identify your skills, experience\nand suggest a preparation plan.', textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: _pickAndAnalyze, 
          icon: const Icon(Icons.upload_file_rounded), 
          label: const Text('Upload Resume PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 16),
          child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.bold))),
      ]),
    ));
  }

  Widget _buildAnalysis(BuildContext context) {
    final theme = Theme.of(context);
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
          decoration: BoxDecoration(gradient: LinearGradient(colors: [theme.colorScheme.primary.withOpacity(0.08), theme.cardColor]),
            borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✅ Analysis Complete', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 8),
            _row('👤', 'Name', _analysis?['name'] ?? 'Not detected', context),
            _row('📊', 'Experience', '${_analysis?['experienceLevel'] ?? 'N/A'} (${_analysis?['experienceYears'] ?? 0} years)', context),
            _row('🎓', 'Education', _analysis?['education'] ?? 'N/A', context),
            _row('💼', 'Recommended Role', _analysis?['recommendedRole'] ?? 'N/A', context),
          ]),
        ).animate().fadeIn(),
        const SizedBox(height: 24),

        // Skills
        _sectionTitle('🛠️ Skills Detected', context),
        Wrap(spacing: 8, runSpacing: 8, children: skills.map((s) => Chip(
          label: Text(s, style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w800)),
          backgroundColor: theme.colorScheme.primary.withOpacity(0.05), side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.15)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )).toList()),
        const SizedBox(height: 20),

        // Strengths
        _sectionTitle('💪 Strengths', context),
        ...strengths.map((s) => _bulletItem(s, theme.colorScheme.primary, context)),
        const SizedBox(height: 16),

        // Weaknesses
        _sectionTitle('⚠️ Areas to Improve', context),
        ...weaknesses.map((w) => _bulletItem(w, AppTheme.danger, context)),
        const SizedBox(height: 20),

        // Preparation Plan
        _sectionTitle('📋 Personalized Preparation Plan', context),
        ...List.generate(plan.length, (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.05))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 32, height: 32,
              decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.secondary.withOpacity(0.1)),
              child: Center(child: Text('${i + 1}', style: GoogleFonts.dmSans(color: theme.colorScheme.secondary, fontWeight: FontWeight.w900, fontSize: 14)))),
            const SizedBox(width: 16),
            Expanded(child: Text(plan[i], style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500))),
          ]),
        ).animate().fadeIn(delay: (i * 80).ms)),
        const SizedBox(height: 24),

        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () {
            final questions = List<Map<String, dynamic>>.from(_analysis?['tailoredQuestions'] ?? []);
            final List<Question> parsedQs = questions.map((q) => Question(
              id: q['id'] ?? 'res_${DateTime.now().millisecondsSinceEpoch}',
              text: q['text'] ?? '',
              category: q['category'] ?? 'Resume',
              difficulty: q['difficulty'] ?? 'Match',
              type: 'interview',
              hints: List<String>.from(q['hints'] ?? []),
              estimatedTime: 120,
            )).toList();
            
            Navigator.push(context, MaterialPageRoute(builder: (_) => MockInterviewScreen(
              initialResumeData: _analysis,
              initialResumeText: _resumeText,
              preGeneratedQuestions: parsedQs.isNotEmpty ? parsedQs : null,
            )));
          },
          icon: const Icon(Icons.psychology_rounded),
          label: const Text('Start Tailored Interview'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _pickAndAnalyze,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Analyze Another Resume'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _sectionTitle(String title, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.w900, fontSize: 16)),
  );

  Widget _row(String emoji, String label, String value, BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 10),
      Text('$label: ', style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w600)),
      Expanded(child: Text(value, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.w800, fontSize: 13))),
    ]),
  );

  Widget _bulletItem(String text, Color color, BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 14, height: 1.5, fontWeight: FontWeight.bold))),
    ]),
  );
}
