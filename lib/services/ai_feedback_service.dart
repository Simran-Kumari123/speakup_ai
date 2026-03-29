import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIG — API key loaded from .env file
// ─────────────────────────────────────────────────────────────────────────────
class AIConfig {
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 2);
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

  // ── Personality modes ───────────────────────────────────────────────────────
  static const Map<String, String> personalityDescriptions = {
    'friendly': 'a friendly, encouraging English coach who motivates the student',
    'strict': 'a strict, demanding interviewer who pushes for perfection',
    'hr': 'a professional HR manager conducting a formal interview',
    'debate': 'a debate partner who challenges arguments and pushes critical thinking',
  };

  // ── Public: Chat / Speaking feedback ─────────────────────────────────────
  static Future<ChatMessage> respondToSpeech({
    required String userText,
    required String context,
    String personalityMode = 'friendly',
  }) async {
    try {
      final result = await _callGemini(
        _buildSpeechPrompt(userText),
        systemPersona: _getSpeechPersona(context, personalityMode),
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
    String personalityMode = 'friendly',
  }) async {
    try {
      final result = await _callGemini(
        _buildInterviewPrompt(question, answer),
        systemPersona: _getInterviewPersona(personalityMode),
      );
      return _parseInterviewResponse(result);
    } on AIException catch (e) {
      return _fallbackEvaluation(e);
    } catch (e) {
      return _fallbackEvaluation(AIException('Unexpected error: $e', AIErrorType.unknown));
    }
  }

  // ── Public: Grammar explanation ─────────────────────────────────────────
  static Future<Map<String, dynamic>> generateGrammarExplanation({
    required String sentence,
  }) async {
    try {
      final result = await _callGemini(
        'Analyze this sentence for grammar: "$sentence"',
        systemPersona: '''
You are an expert English grammar teacher. Analyze the given sentence and respond with this EXACT JSON:
{
  "original": "the original sentence",
  "corrected": "the corrected sentence (same if no errors)",
  "hasErrors": boolean,
  "errors": [{"error": "description", "rule": "grammar rule", "fix": "how to fix"}],
  "improved": "an improved, more professional version",
  "explanation": "brief grammar explanation",
  "score": double (0-10)
}
''',
      );
      return jsonDecode(result);
    } catch (_) {
      return {'original': sentence, 'corrected': sentence, 'hasErrors': false, 'errors': [], 'improved': sentence, 'explanation': '', 'score': 7.0};
    }
  }

  // ── Public: Group Discussion evaluation ─────────────────────────────────
  static Future<Map<String, dynamic>> evaluateGD({
    required String topic,
    required String response,
  }) async {
    try {
      final result = await _callGemini(
        'GD Topic: "$topic"\nUser\'s Response: "$response"',
        systemPersona: '''
You are a Group Discussion evaluator. Evaluate the user's response to the given topic.
Respond with this EXACT JSON:
{
  "clarity": double (0-10),
  "argumentStrength": double (0-10),
  "communication": double (0-10),
  "overallScore": double (0-10),
  "feedback": "2-3 sentence feedback",
  "strengths": ["strength1", "strength2"],
  "improvements": ["area1", "area2"],
  "counterArgument": "A counter-argument the user could consider",
  "xp": int (10-40)
}
''',
        maxTokens: 800,
      );
      final data = jsonDecode(result);
      return {
        'clarity': (data['clarity'] as num?)?.toDouble() ?? 7.0,
        'argumentStrength': (data['argumentStrength'] as num?)?.toDouble() ?? 7.0,
        'communication': (data['communication'] as num?)?.toDouble() ?? 7.0,
        'overallScore': (data['overallScore'] as num?)?.toDouble() ?? 7.0,
        'feedback': data['feedback'] ?? 'Good response!',
        'strengths': List<String>.from(data['strengths'] ?? []),
        'improvements': List<String>.from(data['improvements'] ?? []),
        'counterArgument': data['counterArgument'] ?? '',
        'xp': (data['xp'] as num?)?.toInt() ?? 20,
      };
    } catch (_) {
      return {'clarity': 7.0, 'argumentStrength': 7.0, 'communication': 7.0, 'overallScore': 7.0, 'feedback': 'Good effort!', 'strengths': <String>[], 'improvements': <String>[], 'counterArgument': '', 'xp': 15};
    }
  }

  // ── Public: Resume analysis ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> analyzeResume({
    required String resumeText,
  }) async {
    try {
      final result = await _callGemini(
        'Resume text:\n$resumeText',
        systemPersona: '''
You are an expert career counselor and resume analyst. Analyze the resume and respond with this EXACT JSON:
{
  "name": "candidate name if found",
  "skills": ["skill1", "skill2", "skill3"],
  "experienceLevel": "Fresher/Junior/Mid/Senior",
  "experienceYears": int,
  "education": "highest education",
  "strengths": ["strength1", "strength2"],
  "weaknesses": ["weakness1", "weakness2"],
  "recommendedRole": "most suitable role",
  "interviewCategories": ["Technical", "HR", "Behavioral"],
  "suggestedDifficulty": "beginner/intermediate/advanced",
  "preparationPlan": ["step1", "step2", "step3", "step4", "step5"]
}
''',
        maxTokens: 1024,
      );
      return jsonDecode(result);
    } catch (_) {
      return {
        'name': '', 'skills': <String>[], 'experienceLevel': 'Fresher',
        'experienceYears': 0, 'education': '', 'strengths': <String>[],
        'weaknesses': <String>[], 'recommendedRole': '',
        'interviewCategories': ['HR', 'Technical'],
        'suggestedDifficulty': 'beginner',
        'preparationPlan': <String>[],
      };
    }
  }

  // ── Public: Generate resume-based interview questions ────────────────────
  static Future<List<Map<String, dynamic>>> generateResumeQuestions({
    required String skills,
    required String experienceLevel,
    required String category,
    int count = 5,
  }) async {
    try {
      final result = await _callGemini(
        'Skills: $skills\nExperience: $experienceLevel\nCategory: $category',
        systemPersona: '''
You are an expert interviewer. Generate $count interview questions based on the candidate's skills and experience.
Respond with this EXACT JSON array:
[
  {
    "question": "interview question",
    "category": "$category",
    "difficulty": "based on experience level",
    "hints": ["hint1", "hint2"],
    "idealAnswer": "what a good answer looks like"
  }
]
''',
        maxTokens: 1500,
      );
      final List<dynamic> questions = jsonDecode(result);
      return questions.map<Map<String, dynamic>>((q) => Map<String, dynamic>.from(q)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Public: Evaluate vocabulary usage ────────────────────────────────────
  static Future<Map<String, dynamic>> evaluateVocabUsage({
    required String word,
    required String userSentence,
  }) async {
    try {
      final result = await _callGemini(
        'Word: "$word"\nUser\'s sentence: "$userSentence"',
        systemPersona: '''
You are an English vocabulary coach. Evaluate if the user correctly used the given word in their sentence.
Respond with this EXACT JSON:
{
  "correct": boolean,
  "score": double (0-10),
  "feedback": "brief feedback on usage",
  "betterExample": "a better example sentence using the word",
  "tip": "grammar or usage tip",
  "xp": int (5-20)
}
''',
      );
      return jsonDecode(result);
    } catch (_) {
      return {'correct': true, 'score': 7.0, 'feedback': 'Good usage!', 'betterExample': '', 'tip': '', 'xp': 10};
    }
  }

  // ── Public: Generate daily vocabulary word ──────────────────────────────
  static Future<Map<String, dynamic>> generateDailyWord() async {
    try {
      final result = await _callGemini(
        'Generate a useful English vocabulary word for an English learner.',
        systemPersona: '''
You are a vocabulary expert. Generate a word that would be useful for an English learner preparing for job interviews.
Respond with this EXACT JSON:
{
  "word": "the word",
  "meaning": "clear definition",
  "partOfSpeech": "noun/verb/adjective/adverb",
  "synonyms": ["syn1", "syn2", "syn3"],
  "antonyms": ["ant1", "ant2"],
  "example": "example sentence using the word",
  "pronunciation": "phonetic pronunciation"
}
''',
      );
      return jsonDecode(result);
    } catch (_) {
      return {
        'word': 'articulate', 'meaning': 'to express clearly and effectively',
        'partOfSpeech': 'verb', 'synonyms': ['express', 'convey', 'communicate'],
        'antonyms': ['mumble', 'stammer'], 'example': 'She articulated her ideas clearly during the presentation.',
        'pronunciation': '/ɑːrˈtɪkjuleɪt/',
      };
    }
  }

  // ── Public: Generate quiz questions ──────────────────────────────────────
  static Future<List<Map<String, dynamic>>> generateQuizQuestions({
    required String type, // mcq, fill_blank, matching
    required String difficulty,
    int count = 5,
  }) async {
    try {
      String format;
      if (type == 'mcq') {
        format = '{"question": "...", "options": ["A", "B", "C", "D"], "correct": 0, "explanation": "..."}';
      } else if (type == 'fill_blank') {
        format = '{"sentence": "The ___ was impressive.", "answer": "performance", "hint": "starts with p", "explanation": "..."}';
      } else {
        format = '{"words": ["word1", "word2", "word3"], "meanings": ["meaning1", "meaning2", "meaning3"], "correctPairs": [[0,0],[1,1],[2,2]]}';
      }

      final result = await _callGemini(
        'Generate $count $type English quiz questions at $difficulty level.',
        systemPersona: '''
You are an English quiz generator. Generate $count $type questions at $difficulty level for English learners.
Respond with a EXACT JSON array. Each item should follow this format:
$format
''',
        maxTokens: 1500,
      );
      final List<dynamic> questions = jsonDecode(result);
      return questions.map<Map<String, dynamic>>((q) => Map<String, dynamic>.from(q)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Public: Generate session report ─────────────────────────────────────
  static Future<Map<String, dynamic>> generateReport({
    required String sessionType,
    required double score,
    required List<String> strengths,
    required List<String> weaknesses,
  }) async {
    try {
      final result = await _callGemini(
        'Session: $sessionType\nScore: $score/10\nStrengths: ${strengths.join(", ")}\nWeaknesses: ${weaknesses.join(", ")}',
        systemPersona: '''
You are an English learning report generator. Based on the session data, create a comprehensive report.
Respond with this EXACT JSON:
{
  "summary": "2-3 sentence session summary",
  "overallGrade": "A/B/C/D/F",
  "scoreBreakdown": {"grammar": double, "vocabulary": double, "fluency": double, "confidence": double},
  "topStrengths": ["str1", "str2"],
  "areasToImprove": ["area1", "area2"],
  "tips": ["tip1", "tip2", "tip3"],
  "nextSteps": "what to practice next"
}
''',
        maxTokens: 800,
      );
      return jsonDecode(result);
    } catch (_) {
      return {
        'summary': 'Session completed.', 'overallGrade': 'B',
        'scoreBreakdown': {'grammar': 7.0, 'vocabulary': 7.0, 'fluency': 7.0, 'confidence': 7.0},
        'topStrengths': strengths, 'areasToImprove': weaknesses,
        'tips': ['Keep practicing daily'], 'nextSteps': 'Continue with more practice sessions.',
      };
    }
  }

  // ── Public: Detect weak areas ───────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> detectWeakAreas({
    required List<String> recentFeedback,
  }) async {
    try {
      final result = await _callGemini(
        'Recent feedback from practice sessions:\n${recentFeedback.join("\n")}',
        systemPersona: '''
You are a learning analytics expert. Analyze the feedback to detect patterns and weak areas.
Respond with this EXACT JSON array:
[
  {
    "category": "grammar/pronunciation/vocabulary/fluency",
    "description": "description of the weak area",
    "errorCount": int,
    "recommendations": ["exercise1", "exercise2"],
    "exampleMistakes": ["mistake1", "mistake2"]
  }
]
''',
        maxTokens: 800,
      );
      final List<dynamic> areas = jsonDecode(result);
      return areas.map<Map<String, dynamic>>((a) => Map<String, dynamic>.from(a)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Public: Generate GD topic ───────────────────────────────────────────
  static Future<Map<String, dynamic>> generateGDTopic() async {
    try {
      final result = await _callGemini(
        'Generate a group discussion topic suitable for college students or job seekers.',
        systemPersona: '''
You are a GD moderator. Generate an engaging discussion topic.
Respond with this EXACT JSON:
{
  "topic": "the discussion topic",
  "description": "brief context or background",
  "pointsFor": ["supporting point 1", "supporting point 2"],
  "pointsAgainst": ["opposing point 1", "opposing point 2"],
  "timeLimit": 120
}
''',
      );
      return jsonDecode(result);
    } catch (_) {
      return {
        'topic': 'Is social media more harmful than helpful?',
        'description': 'Discuss the impact of social media on modern society.',
        'pointsFor': ['Connects people globally', 'Platform for business'],
        'pointsAgainst': ['Mental health concerns', 'Misinformation spread'],
        'timeLimit': 120,
      };
    }
  }

  // ── Public: Evaluate with ideal answer ──────────────────────────────────
  static Future<Map<String, dynamic>> evaluateWithIdeal({
    required String question,
    required String answer,
    String personalityMode = 'friendly',
  }) async {
    try {
      final result = await _callGemini(
        'Interview Question: "$question"\nStudent\'s Answer: "$answer"',
        systemPersona: '''
You are an expert interview coach (${personalityDescriptions[personalityMode] ?? 'friendly coach'}).
Evaluate the answer and provide an ideal answer.
Respond with this EXACT JSON:
{
  "score": double (0-10),
  "fluency": double (0-10),
  "relevance": double (0-10),
  "confidence": double (0-10),
  "feedback": "specific feedback under 80 words",
  "strengths": ["strength1", "strength2"],
  "mistakes": ["mistake1", "mistake2"],
  "idealAnswer": "what a perfect answer would look like (under 100 words)",
  "suggestions": ["suggestion1", "suggestion2"],
  "xp": int (10-50)
}
''',
        maxTokens: 1024,
      );
      final data = jsonDecode(result);
      return {
        'score': (data['score'] as num?)?.toDouble() ?? 7.0,
        'fluency': (data['fluency'] as num?)?.toDouble() ?? 7.0,
        'relevance': (data['relevance'] as num?)?.toDouble() ?? 7.0,
        'confidence': (data['confidence'] as num?)?.toDouble() ?? 7.0,
        'feedback': data['feedback'] ?? 'Good answer!',
        'strengths': List<String>.from(data['strengths'] ?? []),
        'mistakes': List<String>.from(data['mistakes'] ?? []),
        'idealAnswer': data['idealAnswer'] ?? '',
        'suggestions': List<String>.from(data['suggestions'] ?? []),
        'xp': (data['xp'] as num?)?.toInt() ?? 20,
        'error': false,
      };
    } on AIException catch (e) {
      return _fallbackEvaluation(e);
    } catch (e) {
      return _fallbackEvaluation(AIException('Unexpected error: $e', AIErrorType.unknown));
    }
  }

  // ── Gemini API Call with retry logic ─────────────────────────────────────
  static Future<String> _callGemini(String prompt, {String? systemPersona, int maxTokens = 512}) async {
    await _checkConnectivity();

    if (AIConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE' ||
        AIConfig.geminiApiKey.isEmpty) {
      throw AIException(
        'Gemini API key not set. Check your .env file.',
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
        'maxOutputTokens': maxTokens,
        'topP': 0.9,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT',  'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
      ],
    };

    if (systemPersona != null) {
      bodyMap['systemInstruction'] = {
        'parts': [{'text': systemPersona}]
      };
    }

    final body = jsonEncode(bodyMap);

    // Retry loop for rate limiting
    for (int attempt = 0; attempt <= AIConfig.maxRetries; attempt++) {
      try {
        final response = await http
            .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(AIConfig.timeout);

        if (response.statusCode == 429 && attempt < AIConfig.maxRetries) {
          // Rate limited – wait and retry
          await Future.delayed(AIConfig.retryDelay * (attempt + 1));
          continue;
        }

        return _handleHttpResponse(response);

      } on TimeoutException {
        if (attempt < AIConfig.maxRetries) {
          await Future.delayed(AIConfig.retryDelay);
          continue;
        }
        throw AIException('The request timed out.', AIErrorType.timeout);
      } catch (e) {
        if (e is AIException) {
          if (e.type == AIErrorType.rateLimited && attempt < AIConfig.maxRetries) {
            await Future.delayed(AIConfig.retryDelay * (attempt + 1));
            continue;
          }
          rethrow;
        }
        final msg = e.toString().toLowerCase();
        if (msg.contains('socket') || msg.contains('connection') || msg.contains('network')) {
          throw AIException('No internet connection.', AIErrorType.noInternet);
        }
        throw AIException('Network error: $e', AIErrorType.apiError);
      }
    }
    throw AIException('Too many requests. Please wait and try again.', AIErrorType.rateLimited);
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

  static String _getSpeechPersona(String context, [String personalityMode = 'friendly']) {
    final contextDesc = {
      'chat':          'casual English conversation practice',
      'pronunciation': 'spoken English fluency and pronunciation practice',
      'interview':     'job interview preparation',
    }[context] ?? 'English practice';

    final personality = personalityDescriptions[personalityMode] ?? personalityDescriptions['friendly']!;

    return '''
You are $personality helping a student prepare for job placements and improve spoken English during $contextDesc.
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

  static String _getInterviewPersona([String personalityMode = 'friendly']) {
    final personality = personalityDescriptions[personalityMode] ?? personalityDescriptions['friendly']!;
    return '''
You are $personality evaluating a student's interview answer.
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
        'strengths':   List<String>.from(data['strengths'] ?? []),
        'mistakes':    List<String>.from(data['mistakes'] ?? []),
        'idealAnswer': data['idealAnswer'] ?? '',
        'wordCount':   data['wordCount']   ?? 0,
        'xp':          (data['xp'] as num?)?.toInt() ?? 20,
        'error':       false,
      };
    } catch (_) {
      return {
        'score': 7.0, 'fluency': 7.0, 'relevance': 7.0, 'confidence': 7.0,
        'feedback': raw.length > 200 ? raw.substring(0, 200) : raw,
        'suggestions': <String>[], 'strengths': <String>[], 'mistakes': <String>[],
        'idealAnswer': '', 'wordCount': 0, 'xp': 10, 'error': false,
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
      'score': 5.0, 'fluency': 5.0, 'relevance': 5.0, 'confidence': 5.0,
      'feedback': '$icon $msg',
      'suggestions': ['Please check your internet connection and try again.'],
      'strengths': <String>[], 'mistakes': <String>[], 'idealAnswer': '',
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