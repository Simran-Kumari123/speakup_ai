import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/app_state.dart';
import '../services/ai_feedback_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/translation_service.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts _tts = AppState.tts;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initTtsVoices(_tts);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _testVoice(AppState state) async {
    setState(() => _isTesting = true);
    await AppState.configureTts(_tts, state);
    final l = AppLocalizations.of(context)!;
    String sample = state.profile.language == 'hi' 
      ? l.practiceCoachHindi
      : l.practiceCoachEnglish;
    
    await _tts.speak(sample);
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) setState(() => _isTesting = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(l.settings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Difficulty ──────────────────────────────────────────────────
          _section(context, l.difficultyLevel),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(children: [
              ...['beginner', 'intermediate', 'advanced'].map((d) {
                final emoji = {'beginner': '🌱', 'intermediate': '🌿', 'advanced': '🌳'}[d]!;
                final desc = {
                  'beginner': l.beginnerDesc,
                  'intermediate': l.intermediateDesc,
                  'advanced': l.advancedDesc,
                }[d]!;
                final title = {
                  'beginner': l.beginner,
                  'intermediate': l.intermediate,
                  'advanced': l.advanced,
                }[d]!;
                final selected = profile.difficulty == d;
                
                return GestureDetector(
                  onTap: () => state.setDifficulty(d),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? theme.colorScheme.primary : Colors.transparent)),
                    child: Row(children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: theme.textTheme.titleSmall?.copyWith(color: selected ? theme.colorScheme.primary : null, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(desc, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                      ])),
                      if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 28),

          // ── AI Personality ──────────────────────────────────────────────
          _section(context, l.aiPersonality),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.1)),
            ),
            child: Column(children: [
              ...AIFeedbackService.personalityDescriptions.entries.map((e) {
                final mode = e.key;
                final emoji = {'friendly': '😊', 'strict': '👨‍🏫', 'hr': '👔', 'debate': '🤺'}[mode] ?? '🤖';
                final title = {
                  'friendly': l.personalityFriendly,
                  'strict': l.personalityStrict,
                  'hr': l.personalityHR,
                  'debate': l.personalityDebate,
                }[mode] ?? mode;
                final selected = profile.personalityMode == mode;
                
                return GestureDetector(
                  onTap: () => state.setPersonalityMode(mode),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? theme.colorScheme.primary : Colors.transparent)),
                    child: Row(children: [
                      Text(emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: theme.textTheme.titleSmall?.copyWith(color: selected ? theme.colorScheme.primary : null, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(e.value, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ])),
                      if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20),
                    ]),
                  ),
                );
              }),
            ]),
          ),
          const SizedBox(height: 28),

          // ── Voice Quality & Tone ──────────────────────────────────────────
          _section(context, l.voiceQuality),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(l.neuralVoiceDesc, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary))),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Text(l.vocalTone, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => state.setVoicePitch(1.0), 
                  icon: const Icon(Icons.refresh, size: 14), 
                  label: Text(l.reset, style: const TextStyle(fontSize: 10)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                ),
              ]),
              Row(children: [
                const Text('🔈', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: profile.voicePitch,
                    min: 0.5, max: 1.5,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (v) => state.setVoicePitch(v),
                  ),
                ),
                const Text('🔊', style: TextStyle(fontSize: 12)),
              ]),
              const SizedBox(height: 12),
              
              SizedBox(width: double.infinity, height: 54, 
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : () => _testVoice(state), 
                  icon: _isTesting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_circle_filled_rounded),
                  label: Text(l.testVoice, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // ── AI Voice Gallery ──────────────────────────────────────────
          if (state.availableVoices.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _section(context, l.aiVoiceGallery),
                TextButton.icon(
                  onPressed: () => state.initTtsVoices(AppState.tts),
                  icon: Icon(Icons.refresh_rounded, size: 16, color: theme.colorScheme.primary),
                  label: Text(l.refreshVoiceList, style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.availableVoices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) {
                  final v = state.availableVoices[i];
                  final isSelected = profile.preferredVoiceId == v['name'];
                  final Color accent = {
                    'male': Colors.blue,
                    'female': Colors.pink,
                    'indian': Colors.orange,
                  }[v['category']] ?? theme.colorScheme.primary;

                  return GestureDetector(
                    onTap: () => state.setPreferredVoiceId(v['name'] ?? 'Voice'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 160,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? accent.withOpacity(0.15) : theme.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSelected ? accent : theme.colorScheme.primary.withOpacity(0.05), width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isSelected ? 'Selected' : 'Select', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isSelected ? accent : Colors.grey)),
                              GestureDetector(
                                onTap: () async {
                                  await _tts.setVoice(Map<String, String>.from(v));
                                  await _tts.speak("Hello, this is a sample of my voice.");
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: accent.withOpacity(0.2), shape: BoxShape.circle),
                                  child: Icon(Icons.play_arrow_rounded, size: 16, color: accent),
                                ),
                              ),
                            ],
                          ),
                          Text(v['label'] ?? 'AI Voice', style: theme.textTheme.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.w900)),
                          Text(v['locale']?.toUpperCase() ?? '', style: const TextStyle(fontSize: 9, letterSpacing: 1, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Voice Speed ─────────────────────────────────────────────────
          _section(context, l.voiceSpeed),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Row(children: ['slow', 'normal', 'fast'].map((v) {
              final emoji = {'slow': '🐢', 'normal': '🚶', 'fast': '🏃'}[v]!;
              final label = {
                'slow': l.slow,
                'normal': l.normal,
                'fast': l.fast,
              }[v]!;
              final selected = profile.voicePreference == v;
              return Expanded(child: GestureDetector(
                onTap: () => state.setVoicePreference(v),
                child: Container(
                  margin: EdgeInsets.only(right: v != 'fast' ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: selected ? theme.colorScheme.tertiary.withOpacity(0.12) : theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? theme.colorScheme.tertiary : Colors.transparent)),
                  child: Column(children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(height: 6),
                    Text(label,
                      style: theme.textTheme.bodySmall?.copyWith(color: selected ? theme.colorScheme.tertiary : null, fontWeight: FontWeight.w900, fontSize: 11)),
                  ]),
                ),
              ));
            }).toList()),
          ),
          const SizedBox(height: 28),

          // ── Language ────────────────────────────────────────────────────
          _section(context, l.translationLanguage),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(children: TranslationService.supportedLanguages.entries.map((e) {
              final code = e.key;
              final langData = e.value;
              final selected = profile.language == code;
              return GestureDetector(
                onTap: () => state.setLanguage(code),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.dividerColor.withOpacity(0.05)))),
                  child: Row(children: [
                    Text(langData['flag'] ?? '🌐', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        langData['name'] ?? code,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                          color: selected ? theme.colorScheme.primary : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 18),
                    ],
                  ]),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 28),

          // ── Notifications ──────────────────────────────────────────────
          _section(context, l.notifications),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Column(children: [
              // 1. Toggle Row
              InkWell(
                onTap: () => state.toggleNotifications(!state.notificationsOn),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary, size: 18)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(l.practiceReminders, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
                    Switch(
                      value: state.notificationsOn, 
                      onChanged: (v) => state.toggleNotifications(v), 
                      activeThumbColor: theme.colorScheme.primary,
                      activeTrackColor: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),

              // 2. Time Picker
              Opacity(
                opacity: state.notificationsOn ? 1.0 : 0.4,
                child: AbsorbPointer(
                  absorbing: !state.notificationsOn,
                  child: InkWell(
                    onTap: () async {
                      final parts = state.reminderTime.split(':');
                      final initialTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 8, minute: int.tryParse(parts[1]) ?? 0);
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: initialTime,
                        builder: (context, child) => Theme(
                          data: theme.copyWith(
                            colorScheme: theme.colorScheme.copyWith(primary: theme.colorScheme.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        state.setReminderTime(picked.hour, picked.minute);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: theme.colorScheme.primary.withOpacity(0.5), size: 18),
                          const SizedBox(width: 16),
                          Text(l.reminderTime, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                            child: Text(
                              "Set for ${state.reminderTime}", 
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 13)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
              
              // 3. Test Notification
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                leading: Icon(Icons.send_rounded, color: theme.colorScheme.primary.withOpacity(0.4), size: 18),
                title: Text(l.testNotification, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.primary.withOpacity(0.2), size: 16),
                onTap: () async {
                  await NotificationService.sendInstant(
                    title: '🔔 Notification Test',
                    body: 'Your notification system is working correctly! 🎉',
                  );
                },
              ),
            ]),
          ),
          const SizedBox(height: 28),

          // ── Data ──────────────────────────────────────────────────────
          _section(context, l.data),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.5), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.colorScheme.error.withOpacity(0.1)),
            ),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.error.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 18)),
              title: Text(l.clearAllData, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w700)),
              subtitle: Text(l.clearAllDataDesc, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error.withOpacity(0.3), size: 18),
              onTap: () => _confirmClear(context, theme, state),
            ),
          ),
          const SizedBox(height: 48),
          Center(child: Text(l.privacyFirst, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600))),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }

  Widget _section(BuildContext context, String t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(t, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2)),
  );

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _confirmClear(BuildContext context, ThemeData theme, AppState state) {
    final l = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(l.clearAllDataConfirm, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      content: Text(l.clearAllDataMessage, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel, style: theme.textTheme.bodySmall)),
        TextButton(onPressed: () { Navigator.pop(ctx); state.clearAllData(); },
          child: Text(l.clearAll, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w900))),
      ],
    ));
  }
}
