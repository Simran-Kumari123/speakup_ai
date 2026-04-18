import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../widgets/responsive_layout.dart';
import 'interview_screen.dart';
import 'speaking_screen.dart';
import 'vocabulary_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'progress_screen.dart';
import 'daily_challenge_screen.dart';
import 'quiz_screen.dart';
import 'gd_screen.dart';
import 'challenges_screen.dart';
import 'scenario_screen.dart';
import 'resume_mode_screen.dart';
import 'interview_screen.dart';
import '../models/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() => _tabIndex = index);
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _DashboardTab(animation: _animController),
                const SpeakingScreen(),
                const InterviewScreen(),
                const VocabularyScreen(),
                const ChatScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop 
        ? Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
            ),
            child: BottomNavigationBar(
              currentIndex: _tabIndex,
              onTap: _onTabChanged,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.4),
              selectedLabelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w500),
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 22), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.mic_rounded, size: 22), label: 'Speak'),
                BottomNavigationBarItem(icon: Icon(Icons.business_center_rounded, size: 22), label: 'Interview'),
                BottomNavigationBarItem(icon: Icon(Icons.book_rounded, size: 22), label: 'Vocab'),
                BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded, size: 22), label: 'Coach'),
              ],
            ),
          )
        : null,
    );
  }

  Widget _buildSidebar() {
    final theme = Theme.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary, // Sage Green sidebar
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 24),
                ),
                const SizedBox(width: 14),
                Text(
                  'SpeakUp AI',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          _sidebarItem(0, Icons.dashboard_rounded, 'Dashboard'),
          _sidebarItem(1, Icons.mic_rounded, 'Speaking Practice'),
          _sidebarItem(2, Icons.business_center_rounded, 'Mock Interviews'),
          _sidebarItem(null, Icons.rocket_launch_rounded, 'Resume Mode', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResumeModeScreen()))),
          _sidebarItem(3, Icons.book_rounded, 'Vocabulary Builder'),
          _sidebarItem(null, Icons.groups_rounded, 'Group Discussion', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GDScreen()))),
          _sidebarItem(null, Icons.quiz_rounded, 'Quiz Challenge', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizScreen()))),
          _sidebarItem(null, Icons.flash_on_rounded, 'Daily Challenges', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyChallengeScreen()))),
          _sidebarItem(4, Icons.chat_bubble_rounded, 'AI Chat Coach'),
          const Spacer(),
          _sidebarItem(null, Icons.analytics_outlined, 'Statistics', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProgressScreen()))),
          _sidebarItem(null, Icons.person_outline, 'Profile', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _sidebarItem(int? index, IconData icon, String label, {VoidCallback? onTap}) {
    final isSelected = index != null && _tabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap ?? () => _onTabChanged(index!),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.3), size: 22),
        title: Text(label, style: GoogleFonts.dmSans(fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600, color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Animation<double> animation;
  const _DashboardTab({required this.animation});

  static const _motivations = [
    'Consistency is your superpower! 🎙️',
    'Ready to master a new skill today? 🚀',
    'Your dream job is waiting. Practice hard! 💼',
    'Fluent English is within your reach. ✨',
    'Small wins every day lead to big success! 🏆'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final profile = state.profile;
    final motivation = _motivations[profile.streakDays % _motivations.length];
    
    return FadeTransition(
      opacity: animation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(profile.name.isNotEmpty ? profile.name : 'Learner', 
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 6),
                        Text(motivation, style: GoogleFonts.dmSans(color: Theme.of(context).colorScheme.primary.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                        if (state.isResumeMode && state.activeResume != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8)],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.rocket_launch_rounded, size: 12, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'CAREER FOCUS: ${state.activeResume!.roleTag?.toUpperCase() ?? "ACTIVE"}',
                                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 2)),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Theme.of(context).inputDecorationTheme.fillColor,
                        backgroundImage: profile.profilePicBase64 != null 
                            ? MemoryImage(base64Decode(profile.profilePicBase64!)) : null,
                        child: profile.profilePicBase64 == null 
                            ? Text(profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                              style: GoogleFonts.dmSans(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 18)) : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Dashboard Content ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildAnimatedDailyGoal(context, profile),
                const SizedBox(height: 24),
                _buildQuickChallengeTeaser(context, state),
                const SizedBox(height: 32),
                _sectionHeader(context, 'YOUR PROGRESS'),
                const SizedBox(height: 16),
                _buildStatsGrid(context, profile),
                const SizedBox(height: 32),
                _sectionHeader(context, 'PRACTICE MODES'),
                const SizedBox(height: 16),
                _buildPracticeGrid(context),
                const SizedBox(height: 32),
                _buildWordOfTheDay(context, state),
                const SizedBox(height: 32),
                _sectionHeader(context, 'RECOMMENDED TOPICS'),
                const SizedBox(height: 16),
                _buildTopicsList(context),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) => Row(
    children: [
      Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 11)),
      const SizedBox(width: 12),
      Expanded(child: Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), thickness: 1)),
    ],
  );

  // ── 1. Animated Daily Goal with Gradient ─────────────────────────────
  Widget _buildAnimatedDailyGoal(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    final progress = (profile.practiceMinutes / profile.dailyGoalMinutes).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Practice Goal', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: Theme.of(context).colorScheme.primary.withOpacity(0.8))),
                    const SizedBox(height: 4),
                    Text('Keep the momentum going! 🔥', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('$percentage%', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 24)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Gradient Progress Bar
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(color: theme.textTheme.titleSmall?.color?.withOpacity(0.05), borderRadius: BorderRadius.circular(99)),
              ),
              LayoutBuilder(
                builder: (context, constraints) => TweenAnimationBuilder<double>(
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: progress),
                  builder: (context, value, _) => Container(
                    height: 12,
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)]),
                      borderRadius: BorderRadius.circular(99),
                      boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 10)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // CTA Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                // Switch to Speaking Practice tab (index 1)
                context.findAncestorStateOfType<_HomeScreenState>()?._onTabChanged(1);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa_rounded, size: 20), // Leaf icon like screenshot
                  const SizedBox(width: 10),
                  Text('Start Daily Practice', style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ── 1.5 Quick Challenge Teaser ──────────────────────────────────────
  Widget _buildQuickChallengeTeaser(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final completed = state.dailyChallenges.where((c) => c.completed).length;
    final total = state.dailyChallenges.length;
    final progress = total > 0 ? completed / total : 0.0;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyChallengeScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
        ),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            child: const Center(child: Text('⚡', style: TextStyle(fontSize: 22)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Daily Challenges', style: theme.textTheme.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text('$completed of $total challenges complete', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ])),
          SizedBox(width: 40, height: 40, child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: progress, strokeWidth: 4, backgroundColor: theme.colorScheme.primary.withOpacity(0.05), valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary)),
            Text('${(progress * 100).toInt()}%', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w800, fontSize: 10)),
          ])),
          const SizedBox(width: 4),
        ]),
      ),
    );
  }

  // ── 2. Stats Grid with Tints & Hierarchy ─────────────────────────────
  Widget _buildStatsGrid(BuildContext context, UserProfile profile) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _statCard(context, 'Streak', '${profile.streakDays}', Icons.local_fire_department_rounded, const Color(0xFFFFAB00)),
        _statCard(context, 'Total XP', NumberFormat('#,###').format(profile.totalXP), Icons.stars_rounded, const Color(0xFF7C4DFF)),
        _statCard(context, 'Badges', '${profile.badges.length}', Icons.emoji_events_rounded, const Color(0xFF00B0FF)),
        _statCard(context, 'Sessions', '${profile.sessionsCompleted}', Icons.check_circle_rounded, const Color(0xFF00E676)),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, IconData icon, Color tint) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: tint.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: tint, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22)),
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
  // ── 2.5 Practice Grid ──────────────────────────────────────────────
  Widget _buildPracticeGrid(BuildContext context) {
    final theme = Theme.of(context);
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _practiceCard(context, 'Speak Blitz', '⚡', theme.colorScheme.primary, const ChallengesScreen()),
        _practiceCard(context, 'Situations', '🎭', theme.colorScheme.secondary, const ScenarioScreen()),
        _practiceCard(context, 'Resume Mode', '🚀', const Color(0xFF00E676), const ResumeModeScreen(), 
            isHighlight: context.watch<AppState>().isResumeMode),
        _practiceCard(context, 'Mock Interviews', '🎤', theme.colorScheme.primary, const InterviewScreen()),
        _practiceCard(context, 'Group Discussion', '👥', const Color(0xFF00B0FF), const GDScreen()),
        _practiceCard(context, 'Quiz Challenge', '🧠', const Color(0xFF7C4DFF), const QuizScreen()),
      ],
    );
  }

  Widget _practiceCard(BuildContext context, String title, String emoji, Color color, Widget screen, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isHighlight ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
          boxShadow: [
            if (isHighlight)
              BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 15)
            else
              BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(emoji, style: const TextStyle(fontSize: 18))),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13, 
              fontWeight: FontWeight.w800,
              color: isHighlight ? theme.colorScheme.primary : null,
            )),
          ),
        ]),
      ),
    );
  }

  // ── 3. Word of the Day & Topics ──────────────────────────────────────
  Widget _buildWordOfTheDay(BuildContext context, AppState state) {
    final word = state.wordOfTheDay;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Word of the Day', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(word.word, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(word.meaning, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VocabularyScreen())),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add to Vocabulary'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
              side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsList(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final role = state.profile.targetRole.toLowerCase();

    // Create a copy and sort based on role relevance for a "real app" recommendation feel
    final sortedTopics = List<PracticeTopic>.from(kPracticeTopics);
    final activeResume = state.activeResume;
    final resumeRole = activeResume?.roleTag?.toLowerCase() ?? '';
    final resumeSkills = activeResume?.skills.map((s) => s.toLowerCase()).toList() ?? [];

    sortedTopics.sort((a, b) {
      if (state.isResumeMode && activeResume != null) {
        // Boost topics that match the resume role or skills
        bool aMatches = a.title.toLowerCase().contains(resumeRole) || 
                         a.description.toLowerCase().contains(resumeRole) ||
                         resumeSkills.any((s) => a.description.toLowerCase().contains(s));
        bool bMatches = b.title.toLowerCase().contains(resumeRole) || 
                         b.description.toLowerCase().contains(resumeRole) ||
                         resumeSkills.any((s) => b.description.toLowerCase().contains(s));
        
        if (aMatches && !bMatches) return -1;
        if (!aMatches && bMatches) return 1;
      }

      // Default prioritization (workplace/intro topics)
      bool aRelevant = a.title.toLowerCase().contains('workplace') || 
                       a.description.toLowerCase().contains('meeting') ||
                       a.title.toLowerCase().contains('intro');
      bool bRelevant = b.title.toLowerCase().contains('workplace') || 
                       b.description.toLowerCase().contains('meeting') ||
                       b.title.toLowerCase().contains('intro');
      
      if (aRelevant && !bRelevant) return -1;
      if (!aRelevant && bRelevant) return 1;
      return 0;
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedTopics.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final topic = sortedTopics[index];
        final color = Color(int.parse(topic.colorHex, radix: 16));
        final progress = state.profile.topicProgress[topic.title] ?? 0;
        
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.02), blurRadius: 10)],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(topic.emoji, style: const TextStyle(fontSize: 26)),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(topic.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                if (progress > 0)
                  Text('$progress%', style: GoogleFonts.dmSans(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 12)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(topic.description, 
                   style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: theme.textTheme.bodySmall?.color?.withOpacity(0.5))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress / 100,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation(progress == 100 ? Colors.green : theme.colorScheme.primary),
                        ),
                      ),
                    ),
                    if (progress == 100) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ],
                  ],
                ),
              ],
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScenarioScreen())),
          ),
        );
      },
    );
  }
}
