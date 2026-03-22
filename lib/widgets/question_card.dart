import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/question_model.dart';
import '../theme/app_theme.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final VoidCallback? onRefresh;
  final VoidCallback? onStart;
  final bool showHints;

  const QuestionCard({
    super.key,
    required this.question,
    this.onRefresh,
    this.onStart,
    this.showHints = false,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  bool _showHints = false;

  @override
  Widget build(BuildContext context) {
    final difficulty = widget.question.difficulty;
    final difficultyColor = difficulty == 'beginner'
        ? Colors.green
        : difficulty == 'intermediate'
            ? Colors.orange
            : Colors.red;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkCard,
            AppTheme.darkCard.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.darkBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category + Difficulty
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                categoryEmojis[widget.question.category] ?? '📝',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.question.category.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  color: Colors.white60,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: difficultyColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: difficultyColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                widget.question.difficulty.toUpperCase(),
                                style: GoogleFonts.dmSans(
                                  color: difficultyColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
                    tooltip: 'Get new question',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Question Text
              Text(
                widget.question.text,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ).animate().fadeIn(duration: 500.ms),

              const SizedBox(height: 24),

              // Timer + Stats Row
              Row(
                children: [
                  // Estimated Time
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.blue, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.question.estimatedTime}s',
                          style: GoogleFonts.dmSans(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Question Type
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic_rounded, color: AppTheme.secondary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          widget.question.type.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.dmSans(
                            color: AppTheme.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hints Section
              if (widget.question.hints.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showHints = !_showHints),
                      child: Row(
                        children: [
                          Icon(
                            _showHints ? Icons.expand_less : Icons.expand_more,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tips & Hints',
                            style: GoogleFonts.dmSans(
                              color: Colors.amber,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showHints) ...[
                      const SizedBox(height: 12),
                      ...widget.question.hints.asMap().entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${e.key + 1}',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                ),

              if (widget.question.hints.isNotEmpty) const SizedBox(height: 20),

              // Follow-up Question
              if (widget.question.followUp != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.question_mark, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Follow-up: ${widget.question.followUp}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 12,
                            height: 1.4,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action Button
              if (widget.onStart != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_arrow_rounded),
                        const SizedBox(width: 8),
                        Text(
                          'Start Practice',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().scaleXY(begin: 0.8, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
