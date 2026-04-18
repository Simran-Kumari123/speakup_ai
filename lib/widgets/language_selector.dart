import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/translation_service.dart';

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
    const languages = TranslationService.supportedLanguages;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedLangCode,
          dropdownColor: theme.cardColor,
          icon: Icon(Icons.translate_rounded, color: theme.colorScheme.primary, size: 18),
          isDense: true,
          style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600),
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(
                '${entry.value['flag']} ${entry.value['name']}',
                style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w600),
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
