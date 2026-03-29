import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'chat_screen.dart';
import 'interview_screen.dart';
import 'speaking_screen.dart';
import 'progress_screen.dart';
import 'profile_screen.dart';
import 'speaking_screen.dart';
import '../widgets/responsive_layout.dart';

import 'challenges_screen.dart';
import 'vocabulary_screen.dart';
import 'gd_screen.dart';

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
  void initState() {
    super.initState();
  }

  void _changeTab(int index) {
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _tab == 0 ? null : AppBar(
        title: Text(_getTabTitle()),
        actions: _getTabActions(),
      ),
      body: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: IndexedStack(
          index: _tab,
          children: [
            _Dashboard(
              key: const ValueKey('tab_home'),
              onProfileClick: () => _changeTab(4),
              onTabChange: _changeTab,
            ),
            const ChatScreen(key: ValueKey('tab_chat')),
            const InterviewScreen(key: ValueKey('tab_interview')),
            const ProgressScreen(key: ValueKey('tab_progress')),
            const ProfileScreen(key: ValueKey('tab_profile')),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        current: _tab,
        onTap: _changeTab,
      ),
    );
  }

  String _getTabTitle() {
    switch (_tab) {
      case 1: return 'AI Coach';
      case 2:
        return 'Mock Interview';
      case 3: return 'Your Progress';
      case 4: return 'Profile Settings';
      default: return '';
    }
  }

  List<Widget>? _getTabActions() {
    if (_tab == 2) { // Interview
      return [
        IconButton(
          icon: const Icon(Icons.help_outline_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Practice common interview questions with AI feedback!')),
            );
          },
        ),
        const SizedBox(width: 8),
      ];
    }
    return null;
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
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard),
        border: Border(top: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2), // Reduced from 4
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = current == i;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primary.withAlpha(26) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        items[i].$1,
                        color: active ? AppTheme.primary : AppTheme.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: active ? AppTheme.primary : AppTheme.textSecondary,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
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

class _Dashboard extends StatelessWidget {
  final VoidCallback onProfileClick;
  final Function(int) onTabChange;
  const _Dashboard({required this.onProfileClick, required this.onTabChange, super.key});

  @override
  Widget build(BuildContext context) {
    final state   = context.watch<AppState>();
    final profile = state.profile;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header with Profile Action
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WELCOME BACK',
                            style: GoogleFonts.outfit(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.name.split(' ').first.isEmpty ? "Simran" : profile.name.split(' ').first,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ],
                      ),
                  ),
                  GestureDetector(
                    onTap: onProfileClick,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary.withAlpha(51), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primary.withAlpha(26),
                        backgroundImage: state.profilePicBase64 != null
                            ? MemoryImage(base64Decode(state.profilePicBase64!))
                            : null,
                        child: state.profilePicBase64 == null
                            ? Text(
                                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'S',
                                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 20),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. XP & Goal Tracker Card
          SliverToBoxAdapter(
            child: ResponsiveContainer(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard),
                  border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 77 : 13),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${profile.streakDays} DAY STREAK',
                                  style: GoogleFonts.outfit(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your Daily Goal',
                            style: GoogleFonts.outfit(color: Theme.of(context).textTheme.headlineMedium?.color, fontWeight: FontWeight.w900, fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Progress: ${state.todayMinutes} / ${profile.dailyGoalMinutes} mins',
                            style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CircularPercentIndicator(
                          radius: 45,
                          lineWidth: 10,
                          percent: (profile.dailyGoalMinutes > 0 ? (state.todayMinutes / profile.dailyGoalMinutes) : 0.0).clamp(0.0, 1.0),
                          progressColor: AppTheme.primary,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : AppTheme.lightSurface,
                          circularStrokeCap: CircularStrokeCap.round,
                          animation: true,
                          center: Text(
                            '${(profile.dailyGoalMinutes > 0 ? (state.todayMinutes / profile.dailyGoalMinutes) * 100 : 0).toInt()}%',
                            style: GoogleFonts.outfit(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2.5 Word of the Day
          SliverToBoxAdapter(
            child: ResponsiveContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _wordOfTheDay(context, state),
            ),
          ),

          // 3. Quick Actions Header
          _sectionHeader('QUICK START'),
          SliverToBoxAdapter(
            child: ResponsiveContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _quickAction(context, '🎤', 'Speaking', AppTheme.primary, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeakingScreen()))),
                  const SizedBox(width: 16),
                  _quickAction(context, '💼', 'Interview', AppTheme.secondary, () => onTabChange(2)),
                  const SizedBox(width: 16),
                  _quickAction(context, '💬', 'AI Chat', AppTheme.accent, () => onTabChange(1)),
                ],
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

          // 3.2 Daily Challenges Preview
          _sectionHeader('DAILY CHALLENGES'),
          SliverToBoxAdapter(
            child: ResponsiveContainer(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _challengesPreview(context),
            ),
          ),

          // 3.5 Daily Tip / Word of the Day
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withAlpha(77), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'DAILY TIP',
                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getDailyTip(profile.name),
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),

          // 4. Performance Header
          _sectionHeader('PERFORMANCE'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: ResponsiveContainer(
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: ResponsiveLayout.isPhone(context) ? 2 : 4,
                  childAspectRatio: ResponsiveLayout.isPhone(context) ? 1.4 : 1.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _statCard(context, '📚', 'Sessions', '${profile.sessionsCompleted}', 'done', AppTheme.secondary),
                    _statCard(context, '⏱️', 'Time', '${profile.practiceMinutes}', 'mins', AppTheme.accent),
                    _statCard(context, '🔤', 'Vocabulary', '${profile.wordsSpoken}', 'words', AppTheme.primary),
                    _statCard(context, '🏅', 'Badges', '${profile.badges.length}', 'earned', Colors.orange),
                  ],
                ),
              ),
            ),
          ),

          // 5. Curated Topics Header
          _sectionHeader('CURATED TOPICS'),
          SliverPadding(
            padding: const EdgeInsets.all(0),
            sliver: SliverToBoxAdapter(
              child: ResponsiveContainer(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: kPracticeTopics.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveLayout.isPhone(context) ? 1 : 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (ctx, i) {
                    final topic = kPracticeTopics[i];
                    final progress = state.profile.topicProgress[topic.id] ?? 0;
                    return _topicRow(ctx, topic, progress, () {
                      if (topic.id == 'p3') {
                        Navigator.push(ctx, MaterialPageRoute(builder: (_) => const GDScreen()));
                      } else {
                        Navigator.push(ctx, MaterialPageRoute(builder: (_) => SpeakingScreen(topic: topic)));
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _wordOfTheDay(BuildContext context, AppState state) {
    final word = state.wordOfTheDay;
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen())),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.accent.withAlpha(26),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.accent.withAlpha(51)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('WORD OF THE DAY', style: GoogleFonts.outfit(color: AppTheme.accent, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const Icon(Icons.arrow_forward_rounded, color: AppTheme.accent, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(word.word, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 4),
            Text(word.meaning, style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            Text('"${word.example}"', style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.accent, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _challengesPreview(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.secondary.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                child: const Text('⚡', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Boost your verbal skills', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800)),
                    Text('Try today\'s mini challenges', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Start Challenges', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  String _getDailyTip(String name) {
    final tips = [
      'Try thinking in English for 5 minutes today!',
      'Record yourself and listen for areas to improve.',
      'Practice "Self Introduction" topic to boost confidence.',
      'Focus on clarity over speed while speaking.',
      'Try using one new vocabulary word in a meeting.',
    ];
    return tips[DateTime.now().day % tips.length];
  }

  // --- Helper Widgets ---

  Widget _sectionHeader(String title) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  Widget _quickAction(BuildContext context, String emoji, String label, Color color, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color ?? (Theme.of(context).brightness == Brightness.dark ? AppTheme.darkCard : AppTheme.lightCard),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 51 : 8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(38),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );

  Widget _statCard(BuildContext context, String emoji, String label, String value, String unit, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(Theme.of(context).brightness == Brightness.dark ? 51 : 8),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            Icon(Icons.auto_graph_rounded, color: color.withAlpha(128), size: 14),
          ],
        ),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.headlineMedium?.color, fontWeight: FontWeight.w800, fontSize: 22, height: 1)),
        ),
        const SizedBox(height: 2),
        Text(
          '$label $unit'.toUpperCase(),
          style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );

  Widget _topicRow(BuildContext context, PracticeTopic t, int progress, VoidCallback onTap) {
    final cardColor = Color(int.parse(t.colorHex, radix: 16));
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkBorder : AppTheme.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(t.emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.title, style: GoogleFonts.outfit(color: Theme.of(context).textTheme.titleLarge?.color, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : AppTheme.lightSurface,
                      valueColor: AlwaysStoppedAnimation(cardColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text(
              '$progress%',
              style: GoogleFonts.outfit(color: cardColor, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
