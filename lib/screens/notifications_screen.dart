import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = false;
  int  _pendingCount = 0;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadPending();
    // Sync with saved time
    final state = context.read<AppState>();
    final parts  = state.reminderTime.split(':');
    if (parts.length == 2) {
      _selectedTime = TimeOfDay(
        hour:   int.tryParse(parts[0]) ?? 8,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
  }

  Future<void> _loadPending() async {
    final pending = await NotificationService.getPending();
    setState(() => _pendingCount = pending.length);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.darkCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      final state = context.read<AppState>();
      state.setReminderTime('${picked.hour.toString().padLeft(2, "0")}:${picked.minute.toString().padLeft(2, "0")}');
      if (state.notificationsOn) await _saveReminder();
    }
  }

  Future<void> _saveReminder() async {
    setState(() => _loading = true);
    final state = context.read<AppState>();
    try {
      await NotificationService.scheduleDailyReminder(
        hour:     _selectedTime.hour,
        minute:   _selectedTime.minute,
        userName: state.profile.name.split(' ').first,
      );
      await _loadPending();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Reminder set for ${_selectedTime.format(context)}!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _cancelReminder() async {
    await NotificationService.cancelDailyReminder();
    await _loadPending();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔕 Reminder cancelled'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _testNotification() async {
    await NotificationService.sendInstant(
      title: '🎤 Smart Talk Test',
      body: 'Notifications are working! Your daily reminder is set. 🚀',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('📬 Test notification sent! Check your status bar.'),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(title: const Text('Notifications 🔔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Status banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                (state.notificationsOn ? AppTheme.primary : Colors.grey).withOpacity(0.15),
                AppTheme.darkCard,
              ]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: (state.notificationsOn ? AppTheme.primary : Colors.grey).withOpacity(0.3),
              ),
            ),
            child: Row(children: [
              Text(state.notificationsOn ? '🔔' : '🔕', style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  state.notificationsOn ? 'Notifications ON' : 'Notifications OFF',
                  style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  state.notificationsOn
                      ? 'You\'ll get daily reminders at ${state.reminderTime}'
                      : 'Enable to get daily practice reminders',
                  style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12),
                ),
              ])),
              Switch(
                value: state.notificationsOn,
                activeColor: AppTheme.primary,
                onChanged: (val) async {
                  state.toggleNotifications(val);
                  if (val) {
                    await _saveReminder();
                  } else {
                    await _cancelReminder();
                  }
                },
              ),
            ]),
          ),

          const SizedBox(height: 28),
          _sectionTitle('Daily Reminder Time'),
          const SizedBox(height: 12),

          // Time picker card
          GestureDetector(
            onTap: state.notificationsOn ? _pickTime : null,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.access_time_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Reminder Time', style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12)),
                  Text(
                    _selectedTime.format(context),
                    style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                  ),
                ])),
                if (state.notificationsOn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                    ),
                    child: Text('Change', style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // Save button
          if (state.notificationsOn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.darkBg))
                    : const Icon(Icons.alarm_on_rounded, size: 18),
                label: Text(_loading ? 'Saving...' : 'Save Reminder'),
                onPressed: _loading ? null : _saveReminder,
              ),
            ),

          const SizedBox(height: 28),
          _sectionTitle('Notification Types'),
          const SizedBox(height: 12),

          // Notification types
          ...[
            _NotifType(emoji: '⏰', title: 'Daily Practice Reminder',  subtitle: 'Reminds you to practice every day',         active: state.notificationsOn),
            _NotifType(emoji: '🔥', title: 'Streak Alert',             subtitle: 'Warns when your streak is at risk',          active: state.notificationsOn),
            _NotifType(emoji: '🏅', title: 'Achievement Unlocked',     subtitle: 'Celebrates when you earn a badge',           active: state.notificationsOn),
            _NotifType(emoji: '⭐', title: 'XP Milestone',             subtitle: 'Notifies on 100, 500, 1000 XP milestones',   active: state.notificationsOn),
          ].map((n) => _notifTypeCard(n)),

          const SizedBox(height: 28),
          _sectionTitle('Test & Status'),
          const SizedBox(height: 12),

          // Pending count
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Row(children: [
              const Icon(Icons.pending_actions_rounded, color: AppTheme.secondary, size: 20),
              const SizedBox(width: 12),
              Text('Scheduled notifications', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$_pendingCount active',
                    style: GoogleFonts.dmSans(color: AppTheme.secondary, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),

          const SizedBox(height: 12),

          // Test button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 16, color: AppTheme.secondary),
              label: Text('Send Test Notification Now',
                  style: GoogleFonts.dmSans(color: AppTheme.secondary, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.secondary.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _testNotification,
            ),
          ),

          const SizedBox(height: 32),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.accent.withOpacity(0.2)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡 Tips', style: GoogleFonts.dmSans(color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 10),
              _tip('Set a reminder for a time you\'re free — morning or evening works best'),
              _tip('Consistency beats intensity — even 10 minutes daily builds fluency'),
              _tip('If you miss a day, just restart — don\'t give up!'),
            ]),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String t) =>
      Text(t.toUpperCase(), style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.1));

  Widget _notifTypeCard(_NotifType n) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.darkBorder),
    ),
    child: Row(children: [
      Text(n.emoji, style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(n.title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        Text(n.subtitle, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
      ])),
      Icon(n.active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: n.active ? AppTheme.primary : Colors.white24, size: 20),
    ]),
  );

  Widget _tip(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('• ', style: TextStyle(color: AppTheme.accent)),
      Expanded(child: Text(text, style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 12, height: 1.4))),
    ]),
  );
}

class _NotifType {
  final String emoji, title, subtitle;
  final bool active;
  const _NotifType({required this.emoji, required this.title, required this.subtitle, required this.active});
}