import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/question_model.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Category',
            style: GoogleFonts.dmSans(
              color: Colors.white,
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
                    label: category.replaceFirst(
                      category[0],
                      category[0].toUpperCase(),
                    ),
                    emoji: emoji,
                    isSelected: isSelected,
                    onTap: () => onChanged(isSelected ? null : category),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryButton({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
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
          color: isSelected ? null : AppTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppTheme.darkBorder,
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
                color: isSelected ? Colors.white : Colors.white70,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Difficulty Level',
            style: GoogleFonts.dmSans(
              color: Colors.white,
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
                label: 'All',
                isSelected: selectedDifficulty == null,
                onTap: () => onChanged(null),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _difficultyButton(
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

  Widget _difficultyButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final bgColor = color ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? bgColor.withOpacity(0.25) : AppTheme.darkCard,
          border: Border.all(
            color: isSelected ? bgColor : AppTheme.darkBorder,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: isSelected ? bgColor : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
