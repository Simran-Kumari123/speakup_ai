import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Real-time translation service using Gemini API
class TranslationService {
  static const Duration _timeout = Duration(seconds: 12);
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Supported languages with display name + flag
  static const Map<String, Map<String, String>> supportedLanguages = {
    'none':    {'name': 'English (No Translation)', 'flag': '🇬🇧'},
    'hi':      {'name': 'Hindi',     'flag': '🇮🇳'},
    'es':      {'name': 'Spanish',   'flag': '🇪🇸'},
    'fr':      {'name': 'French',    'flag': '🇫🇷'},
    'de':      {'name': 'German',    'flag': '🇩🇪'},
    'ja':      {'name': 'Japanese',  'flag': '🇯🇵'},
    'zh':      {'name': 'Chinese',   'flag': '🇨🇳'},
    'ar':      {'name': 'Arabic',    'flag': '🇸🇦'},
    'pt':      {'name': 'Portuguese','flag': '🇧🇷'},
    'ko':      {'name': 'Korean',    'flag': '🇰🇷'},
    'ta':      {'name': 'Tamil',     'flag': '🇮🇳'},
    'bn':      {'name': 'Bengali',   'flag': '🇧🇩'},
    'te':      {'name': 'Telugu',    'flag': '🇮🇳'},
    'mr':      {'name': 'Marathi',   'flag': '🇮🇳'},
  };

  /// Translate [text] to [targetLangCode] using Gemini API.
  /// Returns a map with 'translated' text and 'original' text.
  static Future<Map<String, String>> translate({
    required String text,
    required String targetLangCode,
  }) async {
    if (targetLangCode == 'none' || text.trim().isEmpty) {
      return {'original': text, 'translated': text};
    }

    final langName = supportedLanguages[targetLangCode]?['name'] ?? targetLangCode;
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return {'original': text, 'translated': '[Translation unavailable — API key missing]'};
    }

    final uri = Uri.parse('$_geminiBaseUrl?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Translate the following English text to $langName. '
                  'Return ONLY the translated text, nothing else. '
                  'Do not add any explanation or quotation marks.\n\n$text',
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 512,
      },
    });

    int maxRetries = 3;
    Duration baseDelay = const Duration(seconds: 4);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(_timeout);

        if (response.statusCode == 429 && attempt < maxRetries) {
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          final jitter = DateTime.now().millisecond % 500;
          await Future.delayed(Duration(milliseconds: delayMs + jitter));
          continue;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final translated =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
          return {
            'original': text,
            'translated': translated.toString().trim(),
          };
        }
        
        if (attempt == maxRetries) {
          return {'original': text, 'translated': '[Translation failed: ${response.statusCode}]'};
        }
      } on TimeoutException {
        if (attempt < maxRetries) {
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        return {'original': text, 'translated': '[Translation timed out]'};
      } catch (e) {
        if (attempt < maxRetries) {
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        return {'original': text, 'translated': '[Translation error: $e]'};
      }
    }
    return {'original': text, 'translated': '[Translation failed globally]'};
  }
}
