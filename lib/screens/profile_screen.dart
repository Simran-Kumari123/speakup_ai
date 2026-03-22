import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_state.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  String _role  = 'Software Engineer';
  String _level = 'Fresher';

  final _roles  = ['Software Engineer', 'Data Analyst', 'Product Manager', 'Business Analyst', 'Finance', 'Other'];
  final _levels = ['Fresher', '1-2 Years', '3-5 Years', '5+ Years'];

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _nameCtrl  = TextEditingController(text: p.name);
    _emailCtrl = TextEditingController(text: p.email);
    _role  = p.targetRole;
    _level = p.experienceLevel;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        actions: [
          TextButton(
            onPressed: () {
              if (_editMode) {
                state.updateProfile(name: _nameCtrl.text, email: _emailCtrl.text, role: _role, level: _level);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved ✅'), backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating));
              }
              setState(() => _editMode = !_editMode);
            },
            child: Text(_editMode ? 'Save' : 'Edit',
                style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Avatar + name
          Center(child: Column(children: [
            Stack(children: [
              CircleAvatar(
                radius: 44, backgroundColor: AppTheme.primary.withOpacity(0.12),
                child: Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                    style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 36, fontWeight: FontWeight.w800)),
              ),
              if (_editMode) Positioned(bottom: 0, right: 0,
                  child: Container(width: 26, height: 26,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                      child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black))),
            ]),
            const SizedBox(height: 12),
            Text(profile.name.isNotEmpty ? profile.name : 'Set your name',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
            Text(profile.targetRole, style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 13)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: Text('Level ${profile.level}  •  ${profile.totalXP} XP',
                  style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ])),

          const SizedBox(height: 28),

          // Edit form
          if (_editMode) ...[
            _section('Personal Info'),
            _label('Name'), _field(_nameCtrl, 'Your full name', Icons.person_outline),
            const SizedBox(height: 12),
            _label('Email'), _field(_emailCtrl, 'your@email.com', Icons.email_outlined),
            const SizedBox(height: 12),
            _label('Target Role'), _dropdown(_roles, _role, (v) => setState(() => _role = v!)),
            const SizedBox(height: 12),
            _label('Experience'), _dropdown(_levels, _level, (v) => setState(() => _level = v!)),
            const SizedBox(height: 24),
          ],

          // Info (read only)
          if (!_editMode) ...[
            _section('Account Info'),
            _infoRow(Icons.person_outline,        'Name',         profile.name.isEmpty ? 'Tap Edit to set' : profile.name),
            _infoRow(Icons.email_outlined,        'Email',        profile.email.isEmpty ? 'Not set' : profile.email),
            _infoRow(Icons.work_outline,          'Target Role',  profile.targetRole),
            _infoRow(Icons.trending_up_rounded,   'Experience',   profile.experienceLevel),
            _infoRow(Icons.calendar_today_rounded,'Member Since', '${profile.joinDate.day}/${profile.joinDate.month}/${profile.joinDate.year}'),
            const SizedBox(height: 24),
          ],

          // Notifications
          _section('Notifications'),
          _toggleRow('Daily Practice Reminder', state.notificationsOn, state.toggleNotifications),
          _tileRow(Icons.access_time_outlined, 'Reminder Time', state.reminderTime, () async {
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (ctx, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.primary,
                    surface: AppTheme.darkCard,
                    onSurface: Colors.white,
                  ),
                  timePickerTheme: const TimePickerThemeData(
                    backgroundColor: AppTheme.darkCard,
                  ),
                ),
                child: child!,
              ),
            );
            if (t != null && mounted) {
              state.setReminderTime(
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Reminder set ✅'),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
              ));
            }
          }),

          const SizedBox(height: 20),

          // Help
          _section('Help & Info'),
          _tileRow(Icons.help_outline,          'How to Use SpeakUp', '', () => _showHelp(context)),

          _tileRow(Icons.star_outline,          'Rate the App',        '', () => _rateApp()),

          _tileRow(Icons.share_outlined,        'Share with Friends',  '', () => _shareApp()),

          _tileRow(Icons.privacy_tip_outlined,  'Privacy Policy',      '', () => _openPrivacyPolicy()),

          const SizedBox(height: 20),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
              label: const Text('Sign Out', style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () => _confirmLogout(state),
            ),
          ),

          const SizedBox(height: 12),
          Center(child: Text('SpeakUp v2.0 — English & Interview Prep',
              style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 11))),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t.toUpperCase(), style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
  );

  Widget _field(TextEditingController ctrl, String hint, IconData icon) => TextField(
    controller: ctrl, style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: AppTheme.primary, size: 18), isDense: true),
  );

  Widget _dropdown(List<String> items, String value, void Function(String?) onChange) =>
      Container(
        decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.darkBorder)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true,
            dropdownColor: AppTheme.darkCard, style: const TextStyle(color: Colors.white, fontSize: 14),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChange,
          ),
        ),
      );

  Widget _infoRow(IconData icon, String label, String value) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder)),
    child: Row(children: [
      Icon(icon, color: AppTheme.primary, size: 18),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13)),
      const Spacer(),
      Flexible(child: Text(value, textAlign: TextAlign.right,
          style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
    ]),
  );

  Widget _toggleRow(String label, bool value, void Function(bool) onChanged) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder)),
    child: Row(children: [
      const Icon(Icons.notifications_outlined, color: AppTheme.primary, size: 18),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
      const Spacer(),
      Switch(value: value, onChanged: onChanged, activeColor: AppTheme.primary),
    ]),
  );

  Widget _tileRow(IconData icon, String label, String trailing, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder)),
    child: ListTile(
      dense: true,
      leading: Icon(icon, color: AppTheme.primary, size: 18),
      title: Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13)),
      trailing: trailing.isNotEmpty
          ? Text(trailing, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12))
          : const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      onTap: onTap,
    ),
  );

  Future<void> _rateApp() async {
    const url = 'https://play.google.com/store/apps/details?id=com.speakup.ai';
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

  void _shareApp() {
    Share.share(
      '🎤 I\'m using SpeakUp to prepare for placement interviews with AI coaching!\n\n'
          '✅ Mock interviews\n'
          '✅ Real-time feedback\n\n'
          '📲 Download free: https://play.google.com/store/apps/details?id=com.speakup.ai',
      subject: 'SpeakUp — Interview Prep App',
    );
  }

  void _openPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _PrivacyPolicyScreen()),
    );
  }

  void _confirmLogout(AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out?',
            style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Your progress and XP are saved. You can sign back in anytime.',
          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.dmSans(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.signOut();
              await state.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: Text('Sign Out',
                style: GoogleFonts.dmSans(color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext ctx) => showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.darkCard,
      title: Text('How to Use SpeakUp', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _helpItem('🏠', 'Home',      'Dashboard with your progress, stats and quick access to practice'),
        _helpItem('💬', 'Chat',      'AI chat coach — type or speak, get instant grammar & fluency feedback'),
        _helpItem('💼', 'Interview', 'Practice real interview questions with AI scoring'),
        _helpItem('🎤', 'Speaking',  'Record yourself speaking on prompts, get pronunciation feedback'),
        _helpItem('📈', 'Progress',  'Track XP, streaks, badges and topic progress'),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx),
          child: const Text('Got it!', style: TextStyle(color: AppTheme.primary)))],
    ),
  );

  Widget _helpItem(String e, String t, String d) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(e, style: const TextStyle(fontSize: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        Text(d, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, height: 1.4)),
      ])),
    ]),
  );
}

class _PrivacyPolicyScreen extends StatelessWidget {
  const _PrivacyPolicyScreen();

  static const _sections = [
    {
      'title': '1. Information We Collect',
      'body': '• Name & email you enter during setup\n• Practice answers sent to Gemini API\n• Usage data: sessions, XP, streaks',
    },
    {
      'title': '2. AI & Gemini API',
      'body': 'SpeakUp uses Google\'s Gemini API to generate feedback.\n• Your answer text is sent to Gemini for analysis\n• We do not store raw answers on our servers',
    },
    {
      'title': '3. Data Storage',
      'body': '• All profile data is stored locally on your device\n• Data is deleted when you uninstall or clear app data',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _sections.map((s) => _buildTile(s['title']!, s['body']!)).toList(),
      ),
    );
  }

  Widget _buildTile(String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder)),
    child: ExpansionTile(
      title: Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(body, style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13, height: 1.6)),
        ),
      ],
    ),
  );
}
