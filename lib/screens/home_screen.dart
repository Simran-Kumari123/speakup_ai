import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'chat_screen.dart';
import 'interview_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'speaking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _Dashboard(),
      const ChatScreen(),
      const InterviewScreen(),
      const ProgressScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tab, children: tabs),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final void Function(int) onTap;
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.chat_bubble_rounded, 'Chat'),
      (Icons.mic_rounded, 'Interview'),
      (Icons.bar_chart_rounded, 'Progress'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        border: const Border(top: BorderSide(color: AppTheme.darkBorder)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = current == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1, color: active ? AppTheme.primary : Colors.white30, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: active ? AppTheme.primary : Colors.white30,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ================= DASHBOARD =================

class _Dashboard extends StatelessWidget {
  const _Dashboard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          // 1. HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${profile.name.split(' ').first.isEmpty ? "there" : profile.name.split(' ').first}! 👋',
                            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 14),
                          ),
                          Text(
                            'Ready to practice?',
                            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ]),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: Text(
                      profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. XP & PROGRESS CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [AppTheme.primary.withOpacity(0.2), AppTheme.darkCard],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    CircularPercentIndicator(
                      radius: 45,
                      lineWidth: 8,
                      percent: (profile.totalXP % 200) / 200,
                      progressColor: AppTheme.primary,
                      backgroundColor: AppTheme.darkSurface,
                      circularStrokeCap: CircularStrokeCap.round,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${profile.level}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                          const Text('LVL', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${profile.totalXP} Total XP', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text('${profile.xpToNext} XP to next level', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12)),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (profile.totalXP % 200) / 200,
                              backgroundColor: AppTheme.darkSurface,
                              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. QUICK ACTIONS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Practice', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _quickAction(context, '🎤', 'Speaking', AppTheme.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeakingScreen()))),
                      const SizedBox(width: 12),
                      _quickAction(context, '💼', 'Interview', AppTheme.secondary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterviewScreen()))),
                      const SizedBox(width: 12),
                      _quickAction(context, '💬', 'AI Chat', AppTheme.accent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. STATS GRID
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
              child: Text('Performance', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              delegate: SliverChildListDelegate([
                _statCard('📚', 'Sessions', '${profile.sessionsCompleted}', 'done', AppTheme.secondary),
                _statCard('⏱️', 'Time', '${profile.practiceMinutes}', 'mins', AppTheme.accent),
                _statCard('🔤', 'Vocabulary', '${profile.wordsSpoken}', 'words', AppTheme.primary),
                _statCard('🏅', 'Badges', '${profile.badges.length}', 'earned', Colors.orange),
              ]),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),

          // 5. PRACTICE TOPICS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Text('Curated Topics', style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _topicRow(ctx, kPracticeTopics[i]),
              childCount: kPracticeTopics.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // WIDGET: Quick Action Button
  Widget _quickAction(BuildContext ctx, String emoji, String label, Color color, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.25)),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Text(label, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );

  // WIDGET: Stat Card
  Widget _statCard(String emoji, String label, String value, String unit, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                Icon(Icons.trending_up_rounded, color: color.withOpacity(0.5), size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                Text('$label $unit', style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );

  // WIDGET: Topic Progress Row
  Widget _topicRow(BuildContext ctx, PracticeTopic t) => Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(t.emoji, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: GoogleFonts.dmSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: t.progress / 100,
                      backgroundColor: AppTheme.darkSurface,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text('${t.progress}%', style: GoogleFonts.dmSans(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      );
}
