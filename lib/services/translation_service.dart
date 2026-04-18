import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Real-time translation service using Groq API (Migrated from Gemini)
class TranslationService {
  static const Duration _timeout = Duration(seconds: 15);
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';

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

  /// Translate [text] to [targetLangCode] using Groq API.
  static Future<Map<String, String>> translate({
    required String text,
    required String targetLangCode,
  }) async {
    if (targetLangCode == 'none' || text.trim().isEmpty) {
      return {'original': text, 'translated': text};
    }

    final langName = supportedLanguages[targetLangCode]?['name'] ?? targetLangCode;
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return {'original': text, 'translated': '[Translation unavailable — API key missing]'};
    }

    final uri = Uri.parse(_groqUrl);

    final body = jsonEncode({
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {
          'role': 'system',
          'content': 'You are a professional translator. Translate everything to $langName. Return ONLY the translated text.'
        },
        {'role': 'user', 'content': text},
      ],
      'temperature': 0.3,
      'max_tokens': 1024,
    });

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['choices'][0]['message']['content'] ?? '';
        return {
          'original': text,
          'translated': translated.toString().trim(),
        };
      } else if (response.statusCode == 429) {
        return {'original': text, 'translated': '[Translation rate limited]'};
      } else {
        return {'original': text, 'translated': '[Translation failed: ${response.statusCode}]'};
      }
    } on SocketException {
      return {'original': text, 'translated': '[No internet connection]'};
    } on TimeoutException {
      return {'original': text, 'translated': '[Translation timed out]'};
    } catch (e) {
      return {'original': text, 'translated': '[Translation error: $e]'};
    }
  }
}
