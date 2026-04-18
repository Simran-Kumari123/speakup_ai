import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';
import 'history_screen.dart';
import 'help_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  String _role  = 'roleSoftwareEngineer';
  String _level = 'levelFresher';

  final _roles  = ['roleSoftwareEngineer', 'roleDataAnalyst', 'roleProductManager', 'roleBusinessAnalyst', 'roleFinance', 'roleExplorer', 'roleOther'];
  final _levels = ['levelBeginner', 'levelFresher', 'levelYears12', 'levelYears35', 'levelYears5Plus'];

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _nameCtrl  = TextEditingController(text: p.name);
    _emailCtrl = TextEditingController(text: p.email);
    
    // Safety check: ensure role and level exist in the dropdown lists to prevent crashes
    _role  = _roles.contains(p.targetRole) ? p.targetRole : _roles.last; // Default to 'Other'
    _level = _levels.contains(p.experienceLevel) ? p.experienceLevel : _levels.first; // Default to 'Beginner'
  }

  void _revert() {
    final p = context.read<AppState>().profile;
    setState(() {
      _nameCtrl.text = p.name;
      _emailCtrl.text = p.email;
      _role = p.targetRole;
      _level = p.experienceLevel;
      _editMode = false;
    });
  }

  void _save() {
    final name  = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final l     = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.nameValidation), backgroundColor: theme.colorScheme.error));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.emailValidation), backgroundColor: theme.colorScheme.error));
      return;
    }

    context.read<AppState>().updateProfile(name: name, email: email, role: _role, level: _level);
    
    if (mounted) {
      setState(() => _editMode = false);
      final l2 = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l2.profileSaved), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(AppState state, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source, 
      imageQuality: 50, 
      maxWidth: 500, 
      maxHeight: 500,
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final base64 = base64Encode(bytes);
      state.updateProfilePic(base64);
      final l2 = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l2.avatarUpdated), behavior: SnackBarBehavior.floating));
    }
  }

  void _showImageSourceSheet(AppState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Change Profile Photo', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(ctx, Icons.camera_alt_rounded, 'Camera', Colors.blue, () {
                  Navigator.pop(ctx);
                  _pickImage(state, ImageSource.camera);
                }),
                _sourceButton(ctx, Icons.photo_library_rounded, 'Gallery', Colors.purple, () {
                  Navigator.pop(ctx);
                  _pickImage(state, ImageSource.gallery);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final profile = state.profile;
    final theme   = Theme.of(context);
    final l       = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l.profile, style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18)),
        centerTitle: true,
        actions: [
          if (_editMode)
            IconButton(
              onPressed: _revert,
              tooltip: l.cancel,
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.error),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () {
                if (_editMode) {
                  _save();
                } else {
                  setState(() => _editMode = true);
                }
              },
              tooltip: _editMode ? l.save : l.editProfile,
              icon: Icon(_editMode ? Icons.check_circle_rounded : Icons.edit_note_rounded, 
                  color: theme.colorScheme.primary, size: 28),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Top Card ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary, // Sage Green
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(children: [
              Stack(children: [
                GestureDetector(
                  onTap: () => _editMode ? _showImageSourceSheet(state) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.1), blurRadius: 20, spreadRadius: 5)],
                    ),
                    child: CircleAvatar(
                      radius: 54, 
                      backgroundColor: theme.inputDecorationTheme.fillColor,
                      backgroundImage: profile.profilePicBase64 != null 
                        ? MemoryImage(base64Decode(profile.profilePicBase64!)) : null,
                      child: profile.profilePicBase64 == null 
                        ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                          style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontSize: 44, fontWeight: FontWeight.w900)) : null,
                    ),
                  ),
                ),
                if (_editMode) Positioned(bottom: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => _showImageSourceSheet(state),
                      child: Container(width: 32, height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary),
                          child: Icon(Icons.camera_alt_rounded, size: 16, color: theme.colorScheme.onPrimary)),
                    )),
              ]),
              const SizedBox(height: 18),
              if (_editMode) ...[
                _field(context, _nameCtrl, l.name, Icons.person_outline),
                const SizedBox(height: 12),
                _field(context, _emailCtrl, l.email, Icons.email_outlined),
                const SizedBox(height: 12),
                _dropdown(context, _roles, _role, (v) => setState(() => _role = v!)),
                const SizedBox(height: 12),
                _dropdown(context, _levels, _level, (v) => setState(() => _level = v!)),
              ] else ...[
                Text(profile.name.isNotEmpty ? profile.name : 'Learner',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(_getRoleLabel(_role, l), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
              ],
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _chip(context, 'Level ${profile.level}', theme.colorScheme.secondary.withOpacity(0.2), theme.colorScheme.primary, Icons.star_rounded),
                const SizedBox(width: 12),
                _chip(context, '${NumberFormat('#,###').format(profile.totalXP)} XP', theme.colorScheme.tertiary.withOpacity(0.1), theme.colorScheme.tertiary, Icons.stars_rounded),
              ]),
            ]),
          ),

          const SizedBox(height: 32),

          // ── Account Information ──────────────────────────────────────────────
          _sectionHeader(context, Icons.info_outline_rounded, l.accountInformation),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor, 
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.02), blurRadius: 10)],
            ),
            child: Column(children: [
              _infoTile(context, Icons.person_outline, l.name, profile.name.isEmpty ? l.notSet : profile.name),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.05), indent: 56),
              _infoTile(context, Icons.email_outlined, l.email, profile.email.isEmpty ? l.notSet : profile.email),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.05), indent: 56),
              _infoTile(context, Icons.work_outline, l.targetRole, _getRoleLabel(profile.targetRole, l)),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.05), indent: 56),
              _infoTile(context, Icons.calendar_today_rounded, l.memberSince, DateFormat('dd MMM yyyy').format(profile.joinDate)),
            ]),
          ),

          const SizedBox(height: 32),

          // ── Activity Overview ────────────────────────────────────────────────
          _sectionHeader(context, Icons.analytics_outlined, l.activityOverview),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1,
            children: [
              _activityCard(context, Icons.record_voice_over_rounded, state.practiceSessions.where((s) => s.type == 'Speaking').length.toString(), 'Speaking', theme.colorScheme.primary, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialTab: 0)))),
              _activityCard(context, Icons.assignment_turned_in_outlined, state.interviewSessions.length.toString(), l.interviews, Colors.green.shade600, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialTab: 1)))),
              _activityCard(context, Icons.timer_outlined, state.quizHistory.length.toString(), l.quizzes, Colors.orange.shade600, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialTab: 2)))),
              _activityCard(context, Icons.book_outlined, state.profile.wordsLearned.toString(), l.vocabulary, theme.colorScheme.tertiary, () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen(initialTab: 3)))),
            ],
          ),

          const SizedBox(height: 32),

          // ── App Settings ─────────────────────────────────────────────────────
          _sectionHeader(context, Icons.settings_outlined, l.appSettings),
          _standaloneTile(context, Icons.auto_fix_high_rounded, l.preferences, l.preferencesDesc, () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),

          const SizedBox(height: 32),

          // ── Help & Support ───────────────────────────────────────────────────
          _sectionHeader(context, Icons.help_outline_rounded, l.helpAndSupport),
          _simpleTile(context, Icons.menu_book_rounded, l.howToUse, l.howToUseDesc, () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()))),
          const SizedBox(height: 12),
          _simpleTile(context, Icons.star_outline_rounded, l.rateOnPlayStore, l.rateOnPlayStoreDesc, () => _rateApp()),

          const SizedBox(height: 32),

          // ── Account ──────────────────────────────────────────────────────────
          _sectionHeader(context, Icons.logout_rounded, l.account),
          SizedBox(width: double.infinity, height: 60,
            child: OutlinedButton(
              onPressed: () => _confirmLogout(state),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.error.withOpacity(0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                backgroundColor: theme.colorScheme.error.withOpacity(0.04),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout_rounded, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 12),
                Text(l.signOut, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ]),
            ),
          ),

          const SizedBox(height: 48),
          Center(child: Text('© 2024 SpeakUp AI. All rights reserved.', 
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withOpacity(0.3)))),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }

  // ── UI Helper Methods ──────────────────────────────────────────────────────

  Widget _sectionHeader(BuildContext context, IconData icon, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 4),
    child: Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      const SizedBox(width: 10),
      Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, letterSpacing: 0.8)),
    ]),
  );

  Widget _chip(BuildContext context, String text, Color bg, Color textCol, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: textCol, size: 14),
      const SizedBox(width: 8),
      Text(text, style: GoogleFonts.dmSans(color: textCol, fontWeight: FontWeight.w900, fontSize: 12)),
    ]),
  );

  Widget _infoTile(BuildContext context, IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(children: [
      Container(width: 40, height: 40,
        decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
      ),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
      ])),
    ]),
  );

  Widget _activityCard(BuildContext context, IconData icon, String val, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(val, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w900), maxLines: 1),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  Widget _standaloneTile(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          Text(sub, style: Theme.of(context).textTheme.bodySmall),
        ])),
        Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ]),
    ),
  );

  Widget _simpleTile(BuildContext context, IconData icon, String title, String sub, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          Text(sub, style: Theme.of(context).textTheme.bodySmall),
        ])),
        Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ]),
    ),
  );

  Widget _field(BuildContext context, TextEditingController ctrl, String hint, IconData icon) => TextField(
    controller: ctrl, style: Theme.of(context).textTheme.bodyMedium,
    decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18), isDense: true),
  );

  String _getRoleLabel(String role, AppLocalizations l) {
    switch (role) {
      case 'roleSoftwareEngineer': return l.roleSoftwareEngineer;
      case 'roleDataAnalyst': return l.roleDataAnalyst;
      case 'roleProductManager': return l.roleProductManager;
      case 'roleBusinessAnalyst': return l.roleBusinessAnalyst;
      case 'roleFinance': return l.roleFinance;
      case 'roleExplorer': return l.roleExplorer;
      default: return l.roleOther;
    }
  }

  String _getLevelLabel(String level, AppLocalizations l) {
    switch (level) {
      case 'levelBeginner': return l.levelBeginner;
      case 'levelFresher': return l.levelFresher;
      case 'levelYears12': return l.levelYears12;
      case 'levelYears35': return l.levelYears35;
      case 'levelYears5Plus': return l.levelYears5Plus;
      default: return level;
    }
  }

  Widget _dropdown(BuildContext context, List<String> items, String value, void Function(String?) onChange) {
    final l = AppLocalizations.of(context)!;
    final isRole = items == _roles;
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).inputDecorationTheme.fillColor, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: Theme.of(context).cardColor,
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(isRole ? _getRoleLabel(e, l) : _getLevelLabel(e, l), style: Theme.of(context).textTheme.bodyMedium))).toList(),
          onChanged: onChange,
        ),
      ),
    );
  }

  Future<void> _rateApp() async {
    const url = 'https://play.google.com/store/apps/details?id=com.marwadiuniversity.speakup_ai';
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not open Play Store'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _confirmLogout(AppState state) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l.signOutConfirm,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        content: Text(l.signOutMessage, style: Theme.of(context).textTheme.bodySmall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              await state.logout();
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(l.signOut,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}