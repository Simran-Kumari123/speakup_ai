import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIG
//  ⚠️ SECURITY WARNING: Do not push this key to GitHub!
//  Consider moving this to a .env file using flutter_dotenv before publishing.
// ─────────────────────────────────────────────────────────────────────────────
class AIConfig {
  static const String geminiApiKey = 'AIzaSyCG-m6Z2YgeP_l76dBks2G9qX6LvXj4FiU';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  static const Duration timeout = Duration(seconds: 15);
}

class AIException implements Exception {
  final String message;
  final AIErrorType type;
  AIException(this.message, this.type);
  @override
  String toString() => message;
}

enum AIErrorType { noInternet, timeout, apiError, invalidKey, rateLimited, unknown }

class AIFeedbackService {

  // ── Public: Chat / Speaking feedback ─────────────────────────────────────
  static Future<ChatMessage> respondToSpeech({
    required String userText,
    required String context,
  }) async {
    try {
      // 👇 Updated to use the System Persona
      final result = await _callGemini(
        _buildSpeechPrompt(userText),
        systemPersona: _getSpeechPersona(context),
      );
      return _parseSpeechResponse(result, userText);
    } on AIException catch (e) {
      return _fallbackMessage(e);
    } catch (e) {
      return _fallbackMessage(AIException('Unexpected error: $e', AIErrorType.unknown));
    }
  }

  // ── Public: Interview answer evaluation ───────────────────────────────────
  static Future<Map<String, dynamic>> evaluateAnswer({
    required String question,
    required String answer,
  }) async {
    try {
      // 👇 Updated to use the System Persona
      final result = await _callGemini(
        _buildInterviewPrompt(question, answer),
        systemPersona: _getInterviewPersona(),
      );
      return _parseInterviewResponse(result);
    } on AIException catch (e) {
      return _fallbackEvaluation(e);
    } catch (e) {
      return _fallbackEvaluation(AIException('Unexpected error: $e', AIErrorType.unknown));
    }
  }

  // ── Gemini API Call ───────────────────────────────────────────────────────
  static Future<String> _callGemini(String prompt, {String? systemPersona}) async {
    await _checkConnectivity();

    if (AIConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' ||
        AIConfig.geminiApiKey.isEmpty) {
      throw AIException(
        'Gemini API key not set.',
        AIErrorType.invalidKey,
      );
    }

    final uri = Uri.parse('${AIConfig.geminiUrl}?key=${AIConfig.geminiApiKey}');

    final Map<String, dynamic> bodyMap = {
      'contents': [
        {
          'parts': [{'text': prompt}]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 512,
        'topP': 0.9,
        // 👇 THIS GUARANTEES PURE JSON OUTPUT
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    // 👇 ADD SYSTEM INSTRUCTION IF PROVIDED
    if (systemPersona != null) {
      bodyMap['systemInstruction'] = {
        'parts': [{'text': systemPersona}]
      };
    }

    final body = jsonEncode(bodyMap);

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(AIConfig.timeout);

      return _handleHttpResponse(response);

    } on TimeoutException {
      throw AIException('The request timed out.', AIErrorType.timeout);
    } on SocketException {
      throw AIException('No internet connection.', AIErrorType.noInternet);
    }
  }

  // ── Handle HTTP Response ──────────────────────────────────────────────────
  static String _handleHttpResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text == null || (text as String).isEmpty) {
            throw AIException('Empty response from AI.', AIErrorType.apiError);
          }
          return text;
        } catch (_) {
          throw AIException('Failed to parse AI response.', AIErrorType.apiError);
        }
      case 400: throw AIException('Bad request sent to Gemini.', AIErrorType.apiError);
      case 401:
      case 403: throw AIException('Invalid API key.', AIErrorType.invalidKey);
      case 429: throw AIException('Too many requests.', AIErrorType.rateLimited);
      case 500:
      case 503: throw AIException('Gemini server error.', AIErrorType.apiError);
      default:  throw AIException('Error ${response.statusCode}', AIErrorType.apiError);
    }
  }

  // ── Connectivity Check ────────────────────────────────────────────────────
  static Future<void> _checkConnectivity() async {
    if (kIsWeb) return;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw AIException('No internet connection.', AIErrorType.noInternet);
      }
    } on SocketException {
      throw AIException('No internet connection.', AIErrorType.noInternet);
    } on TimeoutException {
      throw AIException('Network check timed out.', AIErrorType.noInternet);
    } catch (_) {}
  }

  // ── Prompt Builders & Personas ─────────────────────────────────────────────

  static String _getSpeechPersona(String context) {
    final contextDesc = {
      'chat':          'casual English conversation practice',
      'pronunciation': 'spoken English fluency and pronunciation practice',
      'interview':     'job interview preparation',
    }[context] ?? 'English practice';

    return '''
You are an expert English language coach helping a student prepare for job placements and improve spoken English during $contextDesc.
Respond using this EXACT JSON schema:
{
  "feedback": "2-3 sentence encouraging feedback. Mention one strength.",
  "tip": "One actionable grammar or fluency tip.",
  "score": double (0-10 based on grammar, fluency, vocabulary),
  "correction": "Corrected sentence if there is a mistake, otherwise null",
  "xp": int (5-25 based on score)
}
''';
  }

  static String _buildSpeechPrompt(String userText) {
    return 'The student said: "$userText"';
  }

  static String _getInterviewPersona() {
    return '''
You are an expert placement officer and interview coach evaluating a student's interview answer.
Respond using this EXACT JSON schema:
{
  "score": double (0-10),
  "fluency": double (0-10),
  "relevance": double (0-10),
  "confidence": double (0-10),
  "feedback": "String (Under 80 words. Be specific about what was good and what to improve)",
  "suggestions": ["String", "String"],
  "wordCount": int,
  "xp": int (10-50 based on score)
}
''';
  }

  static String _buildInterviewPrompt(String question, String answer) {
    return '''
Interview Question: "$question"
Student's Answer: "$answer"
''';
  }

  // ── Parse Gemini Responses ────────────────────────────────────────────────
  // Because we force JSON output via responseMimeType, parsing is much safer now.

  static ChatMessage _parseSpeechResponse(String raw, String userText) {
    try {
      final data = jsonDecode(raw);
      return ChatMessage(
        id:       DateTime.now().toIso8601String(),
        text:     data['feedback'] ?? 'Good effort! Keep practicing.',
        sender:   MsgSender.ai,
        type:     MsgType.feedback,
        feedback: _buildFeedbackString(data),
        xp:       (data['xp'] as num?)?.toInt() ?? 10,
        score:    (data['score'] as num?)?.toDouble() ?? 7.0,
      );
    } catch (_) {
      return ChatMessage(
        id:     DateTime.now().toIso8601String(),
        text:   raw.length > 300 ? raw.substring(0, 300) : raw,
        sender: MsgSender.ai,
        type:   MsgType.feedback,
        xp:     10,
        score:  7.0,
      );
    }
  }

  static String _buildFeedbackString(Map<String, dynamic> data) {
    final parts = <String>[];
    if (data['tip'] != null)        parts.add('💡 ${data["tip"]}');
    if (data['correction'] != null && data['correction'] != 'null') {
      parts.add('✏️ Correction: ${data["correction"]}');
    }
    return parts.join('\n\n');
  }

  static Map<String, dynamic> _parseInterviewResponse(String raw) {
    try {
      final data = jsonDecode(raw);
      return {
        'score':       (data['score']      as num?)?.toDouble() ?? 7.0,
        'fluency':     (data['fluency']    as num?)?.toDouble() ?? 7.0,
        'relevance':   (data['relevance']  as num?)?.toDouble() ?? 7.0,
        'confidence':  (data['confidence'] as num?)?.toDouble() ?? 7.0,
        'feedback':    data['feedback']    ?? 'Good answer! Keep practicing.',
        'suggestions': List<String>.from(data['suggestions'] ?? []),
        'wordCount':   data['wordCount']   ?? 0,
        'xp':          (data['xp'] as num?)?.toInt() ?? 20,
        'error':       false,
      };
    } catch (_) {
      return {
        'score': 7.0, 'fluency': 7.0, 'relevance': 7.0, 'confidence': 7.0,
        'feedback': raw.length > 200 ? raw.substring(0, 200) : raw,
        'suggestions': <String>[], 'wordCount': 0, 'xp': 10, 'error': false,
      };
    }
  }

  // ── Fallback Messages (shown when AI fails) ───────────────────────────────
  static ChatMessage _fallbackMessage(AIException e) {
    final (icon, msg) = _errorDisplay(e.type);
    return ChatMessage(
      id:       DateTime.now().toIso8601String(),
      text:     '$icon $msg',
      sender:   MsgSender.ai,
      type:     MsgType.feedback,
      feedback: _fallbackTip(),
      xp:       0,
      score:    null,
    );
  }

  static Map<String, dynamic> _fallbackEvaluation(AIException e) {
    final (icon, msg) = _errorDisplay(e.type);
    return {
      'score': 0.0, 'fluency': 0.0, 'relevance': 0.0, 'confidence': 0.0,
      'feedback': '$icon $msg',
      'suggestions': ['Please check your internet connection and try again.'],
      'wordCount': 0, 'xp': 0, 'error': true,
    };
  }

  static (String, String) _errorDisplay(AIErrorType type) {
    switch (type) {
      case AIErrorType.noInternet:
        return ('📶', 'No internet connection. Please connect to WiFi or mobile data and try again.');
      case AIErrorType.timeout:
        return ('⏱️', 'The request timed out. Please check your connection speed and try again.');
      case AIErrorType.invalidKey:
        return ('🔑', 'AI API key not configured. Please add your Gemini API key in the app settings.');
      case AIErrorType.rateLimited:
        return ('⏳', 'Too many requests. Please wait a few seconds and try again.');
      case AIErrorType.apiError:
        return ('⚠️', 'AI service is temporarily unavailable. Please try again shortly.');
      case AIErrorType.unknown:
        return ('❓', 'Something went wrong. Please restart the app and try again.');
    }
  }

  static String _fallbackTip() =>
      '💡 While offline, you can still practice by recording yourself and reviewing your transcript. '
          'AI feedback will be available when you reconnect.';
}