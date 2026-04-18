import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/resume_service.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'resume_analysis_screen.dart';

class ResumeManagerScreen extends StatefulWidget {
  const ResumeManagerScreen({super.key});

  @override
  State<ResumeManagerScreen> createState() => _ResumeManagerScreenState();
}

class _ResumeManagerScreenState extends State<ResumeManagerScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';
  String? _selectedRole;
  bool _isUploading = false;
  String? _uploadError;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addNewResume() async {
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
      final analysis = await ResumeService.analyze(text);
      
      if (!mounted) return;
      
      await context.read<AppState>().addResume(file.name, text, analysis);
      
      setState(() => _isUploading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resume added successfully!')),
      );
    } catch (e) {
      setState(() {
        _uploadError = e.toString().replaceFirst('Exception: ', '');
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final resumes = state.resumes;
    
    // Get unique roles for AI filtering
    final roles = resumes
        .where((r) => r.roleTag != null)
        .map((r) => r.roleTag!)
        .toSet()
        .toList()
        .cast<String>();

    // Filtered List
    final filteredResumes = resumes.where((r) {
      final matchesSearch = r.fileName.toLowerCase().contains(_filter.toLowerCase());
      final matchesRole = _selectedRole == null || r.roleTag == _selectedRole;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Resume Portfolio 💼'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewResume,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Resume'),
      ),
      body: Column(
        children: [
          _buildHeader(theme),
          if (_uploadError != null)
            _buildErrorBanner(theme),
          _buildSearchAndFilters(theme, roles),
          Expanded(
            child: filteredResumes.isEmpty
                ? _buildEmptyState(theme, resumes.isEmpty)
                : _buildResumeList(theme, filteredResumes, state.activeResumeId),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Your Profiles', 
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          Text('Upload multiple resumes for different career paths and target roles.', 
            style: theme.textTheme.bodySmall?.copyWith(height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.danger.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(_uploadError!, 
              style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.danger, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppTheme.danger),
            onPressed: () => setState(() => _uploadError = null),
          )
        ],
      ),
    ).animate().shake();
  }

  Widget _buildSearchAndFilters(ThemeData theme, List<String> roles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _filter = val),
            decoration: InputDecoration(
              hintText: 'Search by file name...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _filter.isNotEmpty 
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _filter = '');
                    })
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          if (roles.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All Roles'),
                    selected: _selectedRole == null,
                    onSelected: (_) => setState(() => _selectedRole = null),
                  ),
                  const SizedBox(width: 8),
                  ...roles.map((role) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: _selectedRole == role,
                      onSelected: (_) => setState(() => _selectedRole = role),
                      avatar: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                        child: const Text('🖋️', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isActuallyEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isActuallyEmpty ? '📂' : '🕵️', style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            isActuallyEmpty ? 'No resumes uploaded yet' : 'No resumes match your filter',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isActuallyEmpty 
              ? 'Add your first resume to get started.' 
              : 'Try clearing your search or role filters.',
            style: theme.textTheme.bodySmall,
          ),
          if (isActuallyEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ElevatedButton(onPressed: _addNewResume, child: const Text('Upload PDF')),
            ),
        ],
      ),
    );
  }

  Widget _buildResumeList(ThemeData theme, List<ResumeRecord> list, String? activeId) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        final isActive = r.id == activeId;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActive ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05),
              width: isActive ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.onSurface.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: InkWell(
            onTap: () => context.read<AppState>().setActiveResume(r.id),
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(isActive ? '🎯' : '📄', style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.fileName, 
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(r.roleTag ?? 'General Profile', 
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('ACTIVE', 
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(DateFormat('MMM dd, yyyy').format(r.date), 
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (val) {
                          if (val == 'delete') {
                            context.read<AppState>().deleteResume(r.id);
                          } else if (val == 'view') {
                             // Handle view logic or share
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Details')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete Resume', style: TextStyle(color: AppTheme.danger))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
      },
    );
  }
}
