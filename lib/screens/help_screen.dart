import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.helpSupport),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Getting Started ──────────────────────────────────────────
            _sectionHeader(context, l.gettingStarted),
            _helpCard(context, 'https://assets10.lottiefiles.com/packages/lf20_at6mdfbe.json',
                l.helpAppBasicsTitle, l.helpAppBasicsDesc)
                .animate().fadeIn(delay: 0.ms).slideY(begin: 0.08),
            _helpCard(context, 'https://assets5.lottiefiles.com/packages/lf20_8jsSsc.json',
                l.helpSpeechTitle, l.helpSpeechDesc)
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
            _helpCard(context, 'https://assets8.lottiefiles.com/packages/lf20_qpwb7v16.json',
                l.helpProgressTitle, l.helpProgressDesc)
                .animate().fadeIn(delay: 200.ms).slideY(begin: 0.08),

            const SizedBox(height: 32),

            // ── Common Questions ─────────────────────────────────────────
            _sectionHeader(context, l.commonQuestions),
            _faqTile(context, l.faqAccuracyQ, l.faqAccuracyA)
                .animate().fadeIn(delay: 0.ms).slideX(begin: 0.05),
            _faqTile(context, l.faqOfflineQ, l.faqOfflineA)
                .animate().fadeIn(delay: 80.ms).slideX(begin: 0.05),
            _faqTile(context, l.faqResetQ, l.faqResetA)
                .animate().fadeIn(delay: 160.ms).slideX(begin: 0.05),
            _faqTile(context, l.faqSecurityQ, l.faqSecurityA)
                .animate().fadeIn(delay: 240.ms).slideX(begin: 0.05),
            _faqTile(context, l.faqVoiceQ, l.faqVoiceA)
                .animate().fadeIn(delay: 320.ms).slideX(begin: 0.05),

            const SizedBox(height: 32),

            // ── Troubleshooting ──────────────────────────────────────────
            _sectionHeader(context, l.troubleshooting),
            _helpCard(context, '🔇', l.troubleMicTitle, l.troubleMicDesc)
                .animate().fadeIn(delay: 0.ms).slideY(begin: 0.08),
            _helpCard(context, '⏳', l.troubleSlowTitle, l.troubleSlowDesc)
                .animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),

            const SizedBox(height: 32),

            // ── Contact & Community ──────────────────────────────────────
            _sectionHeader(context, l.contactCommunity),
            _contactCard(context, Icons.email_outlined, l.contactEmail, l.contactEmailValue,
                () => _launch('mailto:support@speakup.ai'))
                .animate().fadeIn(delay: 0.ms).slideX(begin: -0.05),
            _contactCard(context, Icons.help_center_outlined, l.contactHelpCenter, l.contactHelpCenterValue,
                () => _launch('https://help.speakup.ai'))
                .animate().fadeIn(delay: 80.ms).slideX(begin: -0.05),
            _contactCard(context, Icons.play_circle_outline_rounded, l.contactYouTube, l.contactYouTubeValue,
                () => _launch('https://youtube.com/c/speakupai'))
                .animate().fadeIn(delay: 160.ms).slideX(begin: -0.05),

            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Text(l.appVersion, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(l.madeWithLove,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withOpacity(0.4))),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 16, left: 4),
    child: Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.8)),
  );

  Widget _helpCard(BuildContext context, String asset, String title, String desc) {
    final theme = Theme.of(context);
    final bool isLottieUrl = asset.startsWith('http');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
            child: isLottieUrl
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Lottie.network(
                      asset, height: 40, fit: BoxFit.contain, repeat: true,
                      errorBuilder: (_, __, ___) => Center(child: Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 28)),
                    ),
                  )
                : Center(child: Text(asset, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 6),
                Text(desc, style: theme.textTheme.bodySmall?.copyWith(height: 1.5, fontSize: 12, fontWeight: FontWeight.w500, color: theme.textTheme.bodySmall?.color?.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqTile(BuildContext context, String q, String a) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.02), blurRadius: 10)],
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.03)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.primary.withOpacity(0.4),
          title: Text(q, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 14)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Text(a, style: theme.textTheme.bodySmall?.copyWith(height: 1.6, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(BuildContext context, IconData icon, String title, String val, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
                  Text(val, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.primary, fontSize: 14)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.primary.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}
