import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../services/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final int initialTab;
  const HistoryScreen({super.key, this.initialTab = 0});
  
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this, initialIndex: widget.initialTab);
    _tabCtrl.addListener(() {
      // Rebuild on both clicks and swipes to ensure the header chart syncs
      if (mounted) setState(() {});
    });
    // Refresh data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().load();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.scaffoldBackgroundColor,
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 320,
              floating: false,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: _buildHeader(context, state),
              ),
              title: Text('Activity History', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              centerTitle: true,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverTabDelegate(
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.textTheme.bodySmall?.color?.withOpacity(0.4),
                  indicatorWeight: 4,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Speaking'),
                    Tab(text: 'Interviews'),
                    Tab(text: 'Quizzes'),
                    Tab(text: 'Vocabulary'),
                    Tab(text: 'Chat Bits'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _SpeakingHistory(sessions: state.practiceSessions.where((s) => ['Speaking', 'Scenario', 'GD', 'Blitz', 'Story'].contains(s.type)).toList()),
              _InterviewHistory(sessions: state.interviewSessions),
              _QuizHistory(results: state.quizHistory),
              _VocabHistory(words: state.vocabulary.where((w) => w.learned).toList()),
              _ChatHistory(messages: state.chatMessages),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppState state) {
    final theme = Theme.of(context);
    final categoryNames = ['SPEAKING', 'INTERVIEW', 'QUIZ', 'VOCABULARY', 'CHAT'];
    final currentCategory = categoryNames[_tabCtrl.index];
    final categoryXP = state.getWeeklyXPByCategory(_tabCtrl.index);
    final totalCategoryXP = categoryXP.isEmpty ? 0 : categoryXP.reduce((a, b) => a + b);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$currentCategory ACTIVITY', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text('$totalCategoryXP XP THIS WEEK', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.auto_graph_rounded, color: theme.colorScheme.primary, size: 16),
                  const SizedBox(width: 4),
                  Text('Filtered', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: theme.colorScheme.primary, fontSize: 12)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: _WeeklyActivityChart(
            key: ValueKey('chart_${_tabCtrl.index}'),
            xpData: categoryXP,
          )),
        ],
      ),
    );
  }
}

class _SpeakingHistory extends StatelessWidget {
  final List<PracticeSession> sessions;
  const _SpeakingHistory({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return _emptyState(context, 'No speaking practice yet.');
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[sessions.length - 1 - i];
        return _SessionCard(
          title: s.topic,
          subtitle: '${s.type} Practice',
          date: s.date,
          score: s.score,
          icon: Icons.record_voice_over_rounded,
          color: theme.colorScheme.primary,
          onTap: () {},
        ).animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.1);
      },
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final List<int> xpData;
  const _WeeklyActivityChart({super.key, required this.xpData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final double maxVal = xpData.isEmpty ? 100 : xpData.reduce((a, b) => a > b ? a : b).toDouble();
    final maxXP = maxVal.clamp(100.0, 10000.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final heightPct = (xpData[i] / maxXP).clamp(0.1, 1.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 120 * heightPct,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.5)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ).animate().scaleY(begin: 0, duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 8),
            Text(days[i], style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
          ],
        );
      }),
    );
  }
}

class _InterviewHistory extends StatelessWidget {
  final List<InterviewSession> sessions;
  const _InterviewHistory({required this.sessions});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return _emptyState(context, 'No interviews practiced yet.');
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      itemBuilder: (context, i) {
        final s = sessions[sessions.length - 1 - i];
        return _SessionCard(
          title: s.type.toUpperCase(),
          subtitle: '${s.qaPairs.length} Questions Asked',
          date: s.timestamp,
          score: s.overallScore,
          icon: Icons.mic_rounded,
          color: theme.colorScheme.primary,
          onTap: () {}, // Detail view
        ).animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.1);
      },
    );
  }
}

class _QuizHistory extends StatelessWidget {
  final List<QuizResult> results;
  const _QuizHistory({required this.results});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return _emptyState(context, 'No quizzes completed yet.');
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final r = results[results.length - 1 - i];
        return _SessionCard(
          title: r.quizType.toUpperCase(),
          subtitle: 'Score: ${r.score}/${r.total}',
          date: r.timestamp,
          score: (r.score / r.total) * 10,
          icon: Icons.quiz_rounded,
          color: theme.colorScheme.secondary,
          onTap: () {},
        ).animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.1);
      },
    );
  }
}

class _VocabHistory extends StatelessWidget {
  final List<VocabularyWord> words;
  const _VocabHistory({required this.words});

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return _emptyState(context, 'Master some words to see them here!');
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: words.length,
      itemBuilder: (context, i) {
        final w = words[words.length - 1 - i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.tertiary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Text('✨', style: TextStyle(fontSize: 18))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.word, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(w.meaning, style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 20),
            ],
          ),
        ).animate().fadeIn(delay: (i * 100).ms);
      },
    );
  }
}

class _ChatHistory extends StatelessWidget {
  final List<ChatMessage> messages;
  const _ChatHistory({required this.messages});

  @override
  Widget build(BuildContext context) {
    final userMsgs = messages.where((m) => m.sender == MsgSender.user).toList();
    if (userMsgs.isEmpty) return _emptyState(context, 'Start a chat with AI Coach!');
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: userMsgs.length,
      itemBuilder: (context, i) {
        final m = userMsgs[userMsgs.length - 1 - i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.text, style: GoogleFonts.dmSans(fontWeight: FontWeight.w500, height: 1.5)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('MMM dd • HH:mm').format(m.time), style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4))),
                  if (m.feedback != null) Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 14),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(delay: (i * 100).ms);
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final DateTime date;
  final double score;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SessionCard({required this.title, required this.subtitle, required this.date, required this.score, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(date), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: color.withOpacity(0.5))),
                      Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900)),
                      Text(subtitle, style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                    ],
                  ),
                ),
                _CircularScore(score: score, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  final double score;
  final Color color;
  const _CircularScore({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.15), width: 4)),
      child: Center(
        child: Text(score.toStringAsFixed(1), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: color, fontSize: 14)),
      ),
    );
  }
}

class _SliverTabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverTabDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabDelegate oldDelegate) => false;
}

Widget _emptyState(BuildContext context, String msg) {
  final theme = Theme.of(context);
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off_rounded, color: theme.colorScheme.primary.withOpacity(0.05), size: 100),
        const SizedBox(height: 24),
        Text(msg, style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3))),
      ],
    ),
  );
}
