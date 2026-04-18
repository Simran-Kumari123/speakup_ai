import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/mock_interview_screen.dart';
import '../services/app_state.dart';
import '../services/resume_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ResumeModeScreen extends StatefulWidget {
  const ResumeModeScreen({super.key});

  @override
  State<ResumeModeScreen> createState() => _ResumeModeScreenState();
}

class _ResumeModeScreenState extends State<ResumeModeScreen> {
  bool _isUploading = false;
  String? _uploadError;

  Future<void> _uploadResume() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final text = ResumeService.extractText(file.bytes!);
      
      // Step 1: Heuristic Validation
      if (!ResumeService.isLikelyResume(text)) {
        setState(() {
          _isUploading = false;
          _uploadError = "This document doesn't look like a professional resume. Please ensure you upload your CV or Resume in PDF format.";
        });
        return;
      }

      // Step 2: AI Validation
      final analysis = await ResumeService.analyze(text);
      
      if (analysis['isValidResume'] == false) {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadError = analysis['validationMessage'] ?? "Resume content not detected.";
          });
        }
        return;
      }
      
      if (!mounted) return;
      
      await context.read<AppState>().addResume(file.name, text, analysis);
      
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Resume uploaded and analyzed!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString().replaceFirst('Exception: ', '');
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final activeResume = state.activeResume;
    final isModeActive = state.isResumeMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Career Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('What is Resume Mode?'),
                  content: const Text('When Resume Mode is ON, your AI Coach will exclusively use your professional summary, skills, and experience to tailor all mock interviews and speaking prompts.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it'))],
                ),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildModeToggle(context, state),
            if (activeResume != null) ...[
              _buildActiveResumeCard(theme, activeResume, isModeActive),
              _buildAnalysisSection(theme, activeResume),
            ] else ...[
              _buildEmptyState(theme),
            ],
            if (_uploadError != null) _buildFriendlyErrorCard(theme),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendlyErrorCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Coach Insight',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.orange.shade800),
                ),
              ),
              IconButton(onPressed: () => setState(() => _uploadError = null), icon: const Icon(Icons.close, size: 16))
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _uploadError!,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _uploadResume, 
            icon: const Icon(Icons.upload_file_rounded), 
            label: const Text('Try Again'),
          ),
        ],
      ),
    ).animate().fadeIn().shake();
  }

  Widget _buildModeToggle(BuildContext context, AppState state) {
    final isActive = state.isResumeMode;
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]
              : [theme.cardColor, theme.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          if (isActive) 
            BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
          else
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.rocket_launch_rounded, 
              color: isActive ? Colors.white : theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUME MODE',
                  style: GoogleFonts.outfit(
                    fontSize: 10, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: 2,
                    color: isActive ? Colors.white.withOpacity(0.7) : theme.colorScheme.primary,
                  ),
                ),
                Text(
                  isActive ? 'Active Career Focus' : 'General Practice',
                  style: GoogleFonts.outfit(
                    fontSize: 18, 
                    fontWeight: FontWeight.w800,
                    color: isActive ? Colors.white : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
            onChanged: (val) => state.setResumeMode(val),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActiveResumeCard(ThemeData theme, ResumeRecord resume, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isActive ? theme.colorScheme.primary.withOpacity(0.2) : theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: Center(child: Text('📄', style: TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resume.fileName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    Text(
                      'Uploaded ${DateFormat('MMM dd, yyyy').format(resume.date)}',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'switch') _showResumeSwitcher(context);
                  if (value == 'delete') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Resume?'),
                        content: Text('Are you sure you want to delete "${resume.fileName}"? This will also disable Resume Mode if it is the only resume.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () {
                              context.read<AppState>().deleteResume(resume.id);
                              Navigator.pop(ctx);
                            }, 
                            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'switch', child: Row(children: [Icon(Icons.swap_horiz_rounded, size: 18), SizedBox(width: 8), Text('Switch')])),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: theme.colorScheme.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: theme.colorScheme.error))])),
                ],
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showResumeSwitcher(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                    label: const Text('My Portfolio'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _uploadResume,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Coach Profile: Fully Synced with your Profile',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.primary.withOpacity(0.6)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(ThemeData theme, ResumeRecord resume) {
    final role = resume.roleTag ?? "Analyzing...";
    final skills = resume.skills;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('AI INSIGHTS', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const Spacer(),
              _isUploading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton.icon(
                    onPressed: _uploadResume, 
                    icon: const Icon(Icons.refresh_rounded, size: 14), 
                    label: const Text('Update'),
                  ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Target Role', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            role, 
                            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: theme.colorScheme.primary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStrengthIndicator(theme, resume),
                  ],
                ),
                const SizedBox(height: 24),
                
                Text('Key Competencies', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
                    ),
                    child: Text(s, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  )).toList(),
                ),
                
                const SizedBox(height: 24),
                _buildActionableTips(theme, resume),
                
                const SizedBox(height: 24),
                _buildMissingSections(theme, resume),
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (_) => const MockInterviewScreen())
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                    child: Text('Start Specialized Interview', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Text('📂', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('No Professional Resume', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Upload your PDF to unlock personalized Resume Mode.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 24),
          Tooltip(
            message: 'Requires standard PDF Resume/CV',
            child: ElevatedButton.icon(
              onPressed: _uploadResume,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload PDF'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementFooter(ThemeData theme, AppState state) {
    if (state.resumes.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Divider(color: theme.dividerColor.withOpacity(0.1)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showResumeSwitcher(context),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('View Resume Portfolio'),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthIndicator(ThemeData theme, ResumeRecord resume) {
    // Calculate a pseudo-score based on analysis depth
    final skillsCount = resume.skills.length;
    final hasExperience = (resume.analysis['experienceYears'] as num?) != null && (resume.analysis['experienceYears'] as num) > 0;
    final score = (skillsCount * 10 + (hasExperience ? 20 : 0) + 40).clamp(0, 100);
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50, height: 50,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 6,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            Text('$score', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Strength', style: theme.textTheme.bodySmall?.copyWith(fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionableTips(ThemeData theme, ResumeRecord resume) {
    final tips = List<String>.from(resume.analysis['actionableTips'] ?? []);
    if (tips.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actionable Coaching', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...tips.map((tip) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tip,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildMissingSections(ThemeData theme, ResumeRecord resume) {
    final missing = List<String>.from(resume.analysis['missingSections'] ?? []);
    if (missing.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Improvement Checklist', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
          ),
          child: Column(
            children: missing.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_box_outline_blank_rounded, size: 16, color: theme.colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Text(item, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _showResumeSwitcher(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final state = ctx.read<AppState>();
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Switch Career Profile', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.resumes.length,
                itemBuilder: (context, i) {
                  final r = state.resumes[i];
                  final isActive = r.id == state.activeResumeId;
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isActive ? theme.colorScheme.primary.withOpacity(0.1) : theme.dividerColor.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
                      child: Text(isActive ? '🎯' : '📄', style: const TextStyle(fontSize: 16)),
                    ),
                    title: Text(r.fileName, style: GoogleFonts.dmSans(fontWeight: isActive ? FontWeight.w900 : FontWeight.w600, fontSize: 14)),
                    subtitle: Text(r.roleTag ?? "Professional Profile", style: TextStyle(fontSize: 12)),
                    trailing: isActive 
                        ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20)
                        : IconButton(
                            icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error.withOpacity(0.5), size: 20),
                            onPressed: () {
                              state.deleteResume(r.id);
                              Navigator.pop(ctx);
                            },
                          ),
                    onTap: () {
                      state.setActiveResume(r.id);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _uploadResume();
                },
                child: const Text('Add New Resume'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
}
