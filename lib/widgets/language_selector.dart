import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';

/// Dropdown widget for selecting a translation language
class LanguageSelector extends StatelessWidget {
  final String selectedLangCode;
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    super.key,
    required this.selectedLangCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languages = TranslationService.supportedLanguages;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLangCode,
          dropdownColor: AppTheme.darkCard,
          icon: const Icon(Icons.translate_rounded, color: AppTheme.primary, size: 18),
          isDense: true,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                '${entry.value['flag']} ${entry.value['name']}',
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
