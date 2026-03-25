import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIG
//  ⚠️ SECURITY WARNING: Do not push this key to GitHub!
//  Consider moving this to a .env file using flutter_dotenv before publishing.
// ─────────────────────────────────────────────────────────────────────────────
class AIConfig {
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';
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

  // ── Public: Resume-based question generation ───────────────────────────────
  static Future<List<Question>> generateResumeQuestions({
    required String resumeText,
  }) async {
    try {
      final result = await _callGemini(
        _buildResumePrompt(resumeText),
        systemPersona: _getResumePersona(),
      );
      return _parseResumeQuestions(result);
    } catch (e) {
      debugPrint('⚠️ Resume Gen Error: $e');
      return _fallbackResumeQuestions();
    }
  }

  // ── Public: General AI Call ───────────────────────────────────────────────
  static Future<String> callGeminiRaw(String prompt, {String? systemPersona, bool useJsonMode = true}) async {
    return _callGemini(prompt, systemPersona: systemPersona, useJsonMode: useJsonMode);
  }

  // ── Gemini API Call ───────────────────────────────────────────────────────
  static Future<String> _callGemini(String prompt, {String? systemPersona, bool useJsonMode = true}) async {
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
        'maxOutputTokens': 1024,
        'topP': 0.9,
        if (useJsonMode) 'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    if (systemPersona != null && !useJsonMode) {
      bodyMap['systemInstruction'] = {
        'parts': [{'text': systemPersona}]
      };
    } else if (systemPersona != null) {
      // For JSON mode, sometimes putting persona in the main prompt is more stable on some versions
       bodyMap['contents'].insert(0, {
        'role': 'user',
        'parts': [{'text': 'SYSTEM INSTRUCTION: $systemPersona'}]
      });
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
    debugPrint('🤖 AI Response: ${response.statusCode}');
    
    switch (response.statusCode) {
      case 200:
        try {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
          if (text == null || (text as String).isEmpty) {
            throw AIException('Empty response from AI.', AIErrorType.apiError);
          }
          return text;
        } catch (e) {
          throw AIException('Failed to parse AI response.', AIErrorType.apiError);
        }
      case 401:
      case 403: 
        throw AIException('Invalid API key.', AIErrorType.invalidKey);
      case 429: 
        throw AIException('Too many requests.', AIErrorType.rateLimited);
      default:  
        throw AIException('Error ${response.statusCode}', AIErrorType.apiError);
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
  "feedback": "string",
  "tip": "string",
  "score": number,
  "correction": "string or null",
  "xp": number
}
''';
  }

  static String _buildSpeechPrompt(String userText) => 'The student said: "$userText"';

  static String _getInterviewPersona() {
    return '''
You are an expert placement officer and interview coach evaluating a student's interview answer.
Respond using this EXACT JSON schema:
{
  "score": number,
  "fluency": number,
  "relevance": number,
  "confidence": number,
  "feedback": "string",
  "suggestions": ["string"],
  "wordCount": number,
  "xp": number
}
''';
  }

  static String _buildInterviewPrompt(String question, String answer) {
    return 'Interview Question: "$question"\nStudent\'s Answer: "$answer"';
  }

  static String _getResumePersona() {
    return '''
You are an expert technical recruiter. Analyze the provided resume text and generate 5 highly relevant interview questions.
Respond using this EXACT JSON schema:
{
  "questions": [
    {
      "id": "string",
      "text": "string",
      "category": "string",
      "difficulty": "string",
      "hints": ["string"]
    }
  ]
}
''';
  }

  static String _buildResumePrompt(String resumeText) => 'Resume Text: "$resumeText"';

  // ── Parsing ───────────────────────────────────────────────────────────────

  static ChatMessage _parseSpeechResponse(String raw, String userText) {
    try {
      final data = jsonDecode(raw);
      return ChatMessage(
        id:       DateTime.now().toIso8601String(),
        text:     data['feedback'] ?? 'Good effort!',
        sender:   MsgSender.ai,
        type:     MsgType.feedback,
        feedback: _buildFeedbackString(data),
        xp:       (data['xp'] as num?)?.toInt() ?? 10,
        score:    (data['score'] as num?)?.toDouble() ?? 7.0,
      );
    } catch (_) {
      return ChatMessage(id: DateTime.now().toIso8601String(), text: raw, sender: MsgSender.ai, type: MsgType.feedback, xp: 10, score: 7.0);
    }
  }

  static String _buildFeedbackString(Map<String, dynamic> data) {
    final parts = <String>[];
    if (data['tip'] != null) parts.add('💡 ${data["tip"]}');
    if (data['correction'] != null && data['correction'] != 'null') parts.add('✏️ Correction: ${data["correction"]}');
    return parts.join('\n\n');
  }

  static Map<String, dynamic> _parseInterviewResponse(String raw) {
    try {
      final data = jsonDecode(raw);
      return {
        'score': (data['score'] as num?)?.toDouble() ?? 7.0,
        'fluency': (data['fluency'] as num?)?.toDouble() ?? 7.0,
        'relevance': (data['relevance'] as num?)?.toDouble() ?? 7.0,
        'confidence': (data['confidence'] as num?)?.toDouble() ?? 7.0,
        'feedback': data['feedback'] ?? 'Good answer!',
        'suggestions': List<String>.from(data['suggestions'] ?? []),
        'xp': (data['xp'] as num?)?.toInt() ?? 20,
        'error': false,
      };
    } catch (_) {
      return {'score': 7.0, 'fluency': 7.0, 'relevance': 7.0, 'confidence': 7.0, 'feedback': raw, 'suggestions': [], 'xp': 10, 'error': false};
    }
  }

  static List<Question> _parseResumeQuestions(String raw) {
    try {
      final data = jsonDecode(raw);
      return (data['questions'] as List).map((q) => Question(
        id: q['id'] ?? 'res_${DateTime.now().millisecondsSinceEpoch}',
        text: q['text'] ?? '',
        category: 'Resume',
        difficulty: 'Intermediate',
        type: 'interview',
        hints: List<String>.from(q['hints'] ?? []),
        estimatedTime: 120,
      )).toList();
    } catch (_) {
      return _fallbackResumeQuestions();
    }
  }

  static List<Question> _fallbackResumeQuestions() => [
    Question(id: 'res_fb', text: 'Tell me about your most proud project.', category: 'Resume', difficulty: 'Intermediate', type: 'interview', hints: ['Details'], estimatedTime: 120),
  ];

  static ChatMessage _fallbackMessage(AIException e) => ChatMessage(
    id: DateTime.now().toIso8601String(), text: '⚠️ ${e.message}', sender: MsgSender.ai, type: MsgType.feedback, feedback: '', xp: 0, score: null,
  );

  static Map<String, dynamic> _fallbackEvaluation(AIException e) => {
    'score': 0.0, 'fluency': 0.0, 'relevance': 0.0, 'confidence': 0.0, 'feedback': '⚠️ ${e.message}', 'suggestions': [], 'xp': 0, 'error': true,
  };

  static String _fallbackTip() => '💡 AI feedback is unavailable offline.';

  static (String, String) _errorDisplay(AIErrorType type) => ('⚠️', 'Error');
}