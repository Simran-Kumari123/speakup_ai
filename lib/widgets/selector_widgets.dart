import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  const CategorySelector({
    super.key,
    required this.categories,
    this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Category',
            style: GoogleFonts.dmSans(
              color: theme.textTheme.bodySmall?.color ?? AppTheme.earthyText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _categoryButton(
                  context,
                  label: 'All',
                  emoji: '🎯',
                  isSelected: selectedCategory == null,
                  onTap: () => onChanged(null),
                ),
              ),
              ...categories.map((category) {
                final isSelected = selectedCategory == category;
                final emoji = categoryEmojis[category] ?? '📝';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _categoryButton(
                    context,
                    label: category.replaceFirst(
                      category[0],
                      category[0].toUpperCase(),
                    ),
                    emoji: emoji,
                    isSelected: isSelected,
                    onTap: () => onChanged(isSelected ? null : category),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryButton(
    BuildContext context, {
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                )
              : null,
          color: isSelected ? null : theme.cardColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : theme.dividerColor.withOpacity(0.05),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyMedium?.color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultySelector extends StatelessWidget {
  final String? selectedDifficulty;
  final ValueChanged<String?> onChanged;
  final List<String> difficulties;

  const DifficultySelector({
    super.key,
    this.selectedDifficulty,
    required this.onChanged,
    this.difficulties = const ['beginner', 'intermediate', 'advanced'],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Difficulty Level',
            style: GoogleFonts.dmSans(
              color: theme.textTheme.bodySmall?.color ?? AppTheme.earthyText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _difficultyButton(
                context,
                label: 'All',
                isSelected: selectedDifficulty == null,
                onTap: () => onChanged(null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _difficultyButton(
                context,
                label: 'Beginner',
                color: Colors.green,
                isSelected: selectedDifficulty == 'beginner',
                onTap: () => onChanged(
                  selectedDifficulty == 'beginner' ? null : 'beginner',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _difficultyButton(
                context,
                label: 'Inter',
                color: Colors.orange,
                isSelected: selectedDifficulty == 'intermediate',
                onTap: () => onChanged(
                  selectedDifficulty == 'intermediate' ? null : 'intermediate',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _difficultyButton(
                context,
                label: 'Advanced',
                color: Colors.red,
                isSelected: selectedDifficulty == 'advanced',
                onTap: () => onChanged(
                  selectedDifficulty == 'advanced' ? null : 'advanced',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _difficultyButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.12) : theme.cardColor.withOpacity(0.5),
          border: Border.all(
            color: isSelected ? accentColor : theme.dividerColor.withOpacity(0.05),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: isSelected ? accentColor : theme.textTheme.bodyMedium?.color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
