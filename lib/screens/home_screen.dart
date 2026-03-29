import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'chat_screen.dart';
import 'interview_screen.dart';
import 'speaking_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'scenario_screen.dart';
import 'mock_interview_screen.dart';
import 'resume_analysis_screen.dart';
import 'vocabulary_screen.dart';
import 'quiz_screen.dart';
import 'gd_simulator_screen.dart';
import 'daily_challenge_screen.dart';
import 'weak_areas_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final _screens = const [
    _DashboardBody(),
    ChatScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: _screens[_tabIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.darkCard,
          border: Border(top: BorderSide(color: AppTheme.darkBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _navItem(0, Icons.home_rounded,     'Home'),
              _navItem(1, Icons.chat_rounded,     'Chat'),
              _navItem(2, Icons.bar_chart_rounded,'Progress'),
              _navItem(3, Icons.person_rounded,   'Profile'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? AppTheme.primary : Colors.white38, size: 22),
          if (active) ...[
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ]),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final profile = state.profile;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Greeting ────────────────────────────────────────────────────
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13)),
              Text(profile.name.isNotEmpty ? profile.name : 'Learner',
                style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
            ])),
            StreakBadge(streak: profile.streakDays),
          ]),
          const SizedBox(height: 20),

          // ── Level + XP Card ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.12), AppTheme.secondary.withOpacity(0.06)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.primary.withOpacity(0.25)),
            ),
            child: Row(children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.15),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.4))),
                child: Center(child: Text('${profile.level}', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 20))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Level ${profile.level}', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (profile.totalXP % 200) / 200,
                  backgroundColor: AppTheme.darkSurface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  borderRadius: BorderRadius.circular(4), minHeight: 6,
                ),
                const SizedBox(height: 4),
                Text('${profile.totalXP} XP  •  ${profile.xpToNext} to next level',
                  style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11)),
              ])),
            ]),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          // ── Quick Stats ─────────────────────────────────────────────────
          Row(children: [
            _quickStat('🔥', '${profile.streakDays}', 'Streak'),
            const SizedBox(width: 10),
            _quickStat('📚', '${profile.sessionsCompleted}', 'Sessions'),
            const SizedBox(width: 10),
            _quickStat('📖', '${profile.wordsLearned}', 'Words'),
            const SizedBox(width: 10),
            _quickStat('🧠', '${profile.quizzesCompleted}', 'Quizzes'),
          ]),
          const SizedBox(height: 24),

          // ── Daily Challenges ────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyChallengeScreen())),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppTheme.accent.withOpacity(0.12), AppTheme.darkCard]),
                borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.accent.withOpacity(0.25))),
              child: Row(children: [
                const Text('⚡', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Daily Challenges', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('${state.todaysChallengesCompleted}/3 completed today', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
                ])),
                const Icon(Icons.arrow_forward_ios, color: AppTheme.accent, size: 14),
              ]),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // ── Practice Modules ────────────────────────────────────────────
          Text('Practice Modules', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.78,
            children: [
              FeatureCard(emoji: '💬', title: 'AI Chat', description: 'Conversation coach',
                color: AppTheme.primary, onTap: () => _go(context, const ChatScreen())),
              FeatureCard(emoji: '🎤', title: 'Speaking', description: 'Voice practice',
                color: AppTheme.secondary, onTap: () => _go(context, const SpeakingScreen())),
              FeatureCard(emoji: '💼', title: 'Interview', description: 'Mock Q&A',
                color: AppTheme.accent, onTap: () => _go(context, const InterviewScreen())),
              FeatureCard(emoji: '🎭', title: 'Scenarios', description: 'Guided practice',
                color: Colors.purple, onTap: () => _go(context, const ScenarioScreen())),
              FeatureCard(emoji: '🎯', title: 'Mock Int.', description: 'Resume-based',
                color: Colors.teal, onTap: () => _go(context, const MockInterviewScreen())),
              FeatureCard(emoji: '📖', title: 'Vocabulary', description: 'Daily words',
                color: AppTheme.primary, onTap: () => _go(context, const VocabularyScreen())),
              FeatureCard(emoji: '🧠', title: 'Quiz', description: 'Test knowledge',
                color: AppTheme.danger, onTap: () => _go(context, const QuizScreen())),
              FeatureCard(emoji: '🗣️', title: 'GD Sim', description: 'Group discussion',
                color: Colors.deepPurple, onTap: () => _go(context, const GDSimulatorScreen())),
              FeatureCard(emoji: '📄', title: 'Resume', description: 'Resume analysis',
                color: AppTheme.secondary, onTap: () => _go(context, const ResumeAnalysisScreen())),
            ].asMap().entries.map((e) =>
              e.value.animate().fadeIn(delay: (e.key * 50).ms).scale(begin: const Offset(0.9, 0.9))
            ).toList().cast<Widget>(),
          ),
          const SizedBox(height: 24),

          // ── Tools & Insights ────────────────────────────────────────────
          Text('Tools & Insights', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          _toolTile(context, '🎯', 'Weak Areas', 'See your improvement areas', Colors.orange, const WeakAreasScreen()),
          _toolTile(context, '⚙️', 'Settings', 'AI personality, difficulty & more', Colors.blueGrey, const SettingsScreen()),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌅';
    if (h < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }

  static Widget _quickStat(String emoji, String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.darkBorder)),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(value, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 10)),
      ]),
    ),
  );

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _toolTile(BuildContext context, String emoji, String title, String desc, Color color, Widget screen) =>
    GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.darkBorder)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(desc, style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 14),
        ]),
      ),
    );
}
