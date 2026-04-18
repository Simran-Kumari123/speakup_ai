import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIG — API key loaded from .env file
// ─────────────────────────────────────────────────────────────────────────────
class AIConfig {
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';
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

  // ── Personality modes ───────────────────────────────────────────────────────
  static const Map<String, String> personalityDescriptions = {
    'friendly': 'a friendly, encouraging English coach who motivates the student',
    'strict': 'a strict, demanding interviewer who pushes for perfection',
    'hr': 'a professional HR manager conducting a formal interview',
    'debate': 'a debate partner who challenges arguments and pushes critical thinking',
  };

  // ── Difficulty descriptions ─────────────────────────────────────────────────
  static const Map<String, String> difficultyDescriptions = {
    'beginner': 'The student is a beginner. Use simple vocabulary, short sentences, and be very encouraging. Grade leniently and focus on building confidence.',
    'intermediate': 'The student is at an intermediate level. Use professional vocabulary, expect decent grammar, and provide constructive corrections.',
    'advanced': 'The student is advanced. Use complex structures, idiomatic expressions, and grade strictly. Push for near-native fluency and precision.',
  };

  // ── Public: Chat / Speaking feedback ─────────────────────────────────────
  static Future<ChatMessage> respondToSpeech({
    required String userText,
    required String context,
    String personalityMode = 'friendly',
    String difficulty = 'intermediate',
  }) async {
    try {
      final result = await _callGroq(
        _buildSpeechPrompt(userText),
        systemPersona: _getSpeechPersona(context, personalityMode, difficulty),
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
    String difficulty = 'intermediate',
  }) async {
    try {
      final result = await _callGroq(
        _buildInterviewPrompt(question, answer),
        systemPersona: _getInterviewPersona(personalityMode, difficulty),
      );
      return _parseInterviewResponse(result);
    } on AIException catch (e) {
      return _fallbackEvaluation(e);
    } catch (e) {
      return _fallbackEvaluation(AIException('Unexpected error: $e', AIErrorType.unknown));
    }
  }

  // ── Public: Vocabulary usage evaluation ─────────────────────────────────────
  static Future<Map<String, dynamic>> evaluateVocabUsage({
    required String word,
    required String example,
  }) async {
    try {
      final result = await _callGroq(
        'Word: "$word"\nUser Example: "$example"',
        systemPersona: '''
You are an English teacher. Evaluate the usage of the vocabulary word in the example sentence.
Respond using this EXACT JSON schema:
{
  "isCorrect": boolean,
  "feedback": "string",
  "score": number,
  "improvedExample": "string",
  "xp": number
}
''',
      );
      return _parseVocabResponse(result);
    } catch (e) {
      return {'isCorrect': false, 'feedback': 'Error evaluating. Please try again.', 'score': 0, 'xp': 5};
    }
  }

  static Map<String, dynamic> _parseVocabResponse(String raw) {
    try {
      final data = jsonDecode(raw);
      return {
        'isCorrect': data['isCorrect'] ?? false,
        'feedback': data['feedback'] ?? 'Reviewed.',
        'score': (data['score'] as num?)?.toDouble() ?? 5.0,
        'improvedExample': data['improvedExample'],
        'xp': (data['xp'] as num?)?.toInt() ?? 10,
      };
    } catch (_) {
      return {'isCorrect': false, 'feedback': 'Evaluation error.', 'score': 0.0, 'xp': 5};
    }
  }

  // ── Public: Resume analysis ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> analyzeResume({
    required String resumeText,
  }) async {
    try {
      final result = await _callGroq(
        _buildResumePrompt(resumeText),
        systemPersona: '''
You are an AI career coach. Analyze the resume text and extract key information.
CRITICAL: If the document is clearly NOT a resume (e.g. it's a story, a list of random items, or generic text), set "isValidResume" to false.

Respond using this EXACT JSON schema:
{
  "isValidResume": boolean,
  "validationMessage": "string (A super friendly, encouraging but firm message if not a resume)",
  "name": "string",
  "experienceLevel": "string (e.g., Junior, Mid, Senior)",
  "experienceYears": number,
  "education": "string",
  "recommendedRole": "string",
  "skills": ["string (max 8 key skills)"],
  "strengths": ["string (2-3 key strengths)"],
  "actionableTips": ["string (specific, measurable tips to improve this resume, e.g., 'Add metrics like % improvement to your marketing experience')"],
  "missingSections": ["string (essential sections missing, e.g., 'Summary', 'Projects', 'Certifications')"],
  "tailoredQuestions": [
    {
       "id": "string",
       "text": "string",
       "category": "Experience" | "Behavioral" | "Culture",
       "difficulty": "Match",
       "hints": ["string"]
    }
  ]
}
''',
      );
      final Map<String, dynamic> data = jsonDecode(result);
      if (data['isValidResume'] == false) {
        throw Exception(data['validationMessage'] ?? 'This document doesn\'t look like a professional resume. Please upload a valid resume PDF.');
      }
      return data;
    } catch (e) {
      debugPrint('⚠️ Resume Analysis Error: $e');
      return {
        'name': 'Not detected',
        'experienceLevel': 'Fresher',
        'experienceYears': 0,
        'education': 'N/A',
        'recommendedRole': 'Software Engineer',
        'skills': [],
        'strengths': ['Resilient mindset'],
        'weaknesses': ['Resume missing details'],
        'preparationPlan': ['Complete your profile', 'Practice daily speaking'],
        'tailoredQuestions': [],
      };
    }
  }

  // ── Public: Resume-based question generation ───────────────────────────────
  static Future<List<Question>> generateResumeQuestions({
    String? resumeText,
    String? skills,
    String? experienceLevel,
    String? category,
    int count = 5,
  }) async {
    try {
      final prompt = resumeText != null 
          ? _buildResumePrompt(resumeText)
          : 'Skills: $skills\nExperience: $experienceLevel\nCategory: $category';
          
      final result = await _callGroq(
        prompt,
        systemPersona: _getResumePersona(count: count, resumeText: resumeText),
      );
      return _parseResumeQuestions(result);
    } catch (e) {
      debugPrint('⚠️ Resume Gen Error: $e');
      return _fallbackResumeQuestions();
    }
  }

  // ── Public: GD Topic generation ──────────────────────────────────────────
  static Future<String> generateGDTopic({String? role, String? difficulty}) async {
    try {
      final roleContext = role != null ? ' relevant to a $role professional' : '';
      final diffContext = difficulty != null ? ' at $difficulty level' : '';
      final seed = DateTime.now().millisecondsSinceEpoch;

      final result = await _callGroq(
        'Generate a single provocative and interesting topic for a group discussion$roleContext$diffContext. Return JUST the topic string, no quotes or metadata. [Session Seed: $seed]',
        useJsonMode: false,
      );
      return result.trim().replaceAll('"', '');
    } catch (e) {
      return 'The impact of AI on human creativity';
    }
  }

  // ── Public: AI Quiz generation ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> generateQuizQuestions({
    required String type,
    required String difficulty,
    List<String>? topics,
    int count = 5,
  }) async {
    try {
      final topicStr = (topics != null && topics.isNotEmpty) ? ' focusing on these topics: ${topics.join(", ")}.' : '';
      final seed = DateTime.now().millisecondsSinceEpoch;
      final prompt = 'Generate $count unique $type questions for English learners at $difficulty level$topicStr. Use real-world, conversational, or professional contexts. Avoid repetitive, common textbook sentences. [Session Seed: $seed]';
      final result = await _callGroq(
        prompt,
        systemPersona: _getQuizPersona(type: type, difficulty: difficulty, count: count, topics: topics),
      );
      return _parseQuizQuestions(result, type);
    } catch (e) {
      debugPrint('⚠️ Quiz Gen Error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> generateScenarios({String? role}) async {
    try {
      final roleContext = role != null ? ' relevant to a $role career' : '';
      final result = await _callGroq(
        'Generate 5 diverse conversation practice scenarios for an English learner$roleContext. Categories should include things like Meetings, Technical Discussions, Networking, or Daily Work.',
        systemPersona: '''
You are a career coach. Respond using this EXACT JSON schema:
{
  "scenarios": [
    {
      "title": "string",
      "emoji": "string",
      "desc": "string",
      "color": "string", (hex with #)
      "prompts": ["string"] (4 prompts per scenario)
    }
  ]
}
''',
      );
      final data = jsonDecode(result);
      return List<Map<String, dynamic>>.from(data['scenarios'] ?? []);
    } catch (e) {
      debugPrint('⚠️ Scenario Gen Error: $e');
      return [];
    }
  }

  // ── Public: Daily Vocabulary Word ──────────────────────────────────────────
  static Future<Map<String, dynamic>> generateDailyWord({
    String? role,
    String? targetLang,
    String? difficulty,
  }) async {
    try {
      final roleContext = role != null ? ' relevant to a $role career' : '';
      final diffContext = difficulty != null ? ' at $difficulty level' : '';
      
      String langName = 'plain English';
      if (targetLang == 'hi') langName = 'Hindi';
      else if (targetLang == 'es') langName = 'Spanish';
      else if (targetLang == 'fr') langName = 'French';
      else if (targetLang == 'de') langName = 'German';

      final result = await _callGroq(
        'Generate a "Word of the Day" for an English learner$roleContext$diffContext. Focus on useful, professional, or academic vocabulary. [Session Seed: ${DateTime.now().millisecondsSinceEpoch}]',
        systemPersona: '''
You are a vocabulary expert. Provide the meaning and an example sentence in English.
Additionally, provide the "translatedMeaning" and "translatedExample" in $langName.
If $langName is "plain English", just repeat the meaning and example there.

Respond using this EXACT JSON schema:
{
  "word": "string",
  "meaning": "string",
  "translatedMeaning": "string",
  "partOfSpeech": "string",
  "synonyms": ["string"],
  "antonyms": ["string"],
  "example": "string",
  "translatedExample": "string",
  "pronunciation": "string",
  "imageUrl": "string (high-quality Unsplash source URL, e.g. https://images.unsplash.com/photo-XXX?auto=format&fit=crop&q=80&w=800)"
}
''',
      );
      return jsonDecode(result);
    } catch (e) {
      debugPrint('⚠️ Daily Word Error: $e');
      return {
        'word': 'articulate',
        'meaning': 'having or showing the ability to speak fluently and coherently',
        'partOfSpeech': 'adjective',
        'synonyms': ['fluent', 'eloquent', 'lucid'],
        'antonyms': ['unintelligible', 'inarticulate'],
        'example': 'She is an articulate speaker who can convey complex ideas easily.',
        'pronunciation': '/ärˈtikyələt/',
      };
    }
  }

  // ── Public: Daily Challenges (Quests) Generation ───────────────────────────
  static Future<List<Map<String, dynamic>>> generateDailyQuests({
    String? role,
    String? difficulty,
  }) async {
    try {
      final roleContext = role != null ? ' relevant to a $role professional' : '';
      final diffContext = difficulty != null ? ' at $difficulty level' : '';
      final seed = DateTime.now().millisecondsSinceEpoch;

      final result = await _callGroq(
        'Generate 3 unique English learning quests for today$roleContext$diffContext. [Seed: $seed]',
        systemPersona: '''
You are an English coach. Generate 3 specific challenge types.
1. "shadow": A slightly challenging sentence (12-18 words) for pronunciation practice.
2. "detective": A paragraph (30-40 words) with EXACTLY 3 intentional grammar/spelling errors.
3. "connect": Two unrelated but interesting words that must be linked in a story.

Respond using this EXACT JSON schema:
{
  "quests": [
    {
      "type": "shadow",
      "title": "Echo Mimic",
      "description": "string (short instruction)",
      "content": "string (the sentence)",
      "xp": 30
    },
    {
      "type": "detective",
      "title": "Error Hunt",
      "description": "string (short instruction)",
      "content": ["word1", "word2", "word3..."], (list of all words in paragraph)
      "errors": { "index": "correct_word", "index": "correct_word" }, (exactly 3 error indices/corrections)
      "xp": 25
    },
    {
      "type": "connect",
      "title": "Word Link",
      "description": "string (short instruction)",
      "content": ["word1", "word2"],
      "xp": 35
    }
  ]
}
''',
      );
      final data = jsonDecode(result);
      return List<Map<String, dynamic>>.from(data['quests'] ?? []);
    } catch (e) {
      debugPrint('⚠️ Quest Gen Error: $e');
      return [];
    }
  }

  // ── Public: Speaking Challenge Prompt Generation ───────────────────────────
  static Future<Map<String, dynamic>> generateSpeakingChallenge({
    required String type, // 'blitz', 'image', 'story'
    String? role,
    String? difficulty,
  }) async {
    try {
      final roleContext = role != null ? ' relevant to a $role career' : '';
      final diffContext = difficulty != null ? ' at $difficulty level' : '';
      final seed = DateTime.now().millisecondsSinceEpoch;

      String promptRequest = '';
      if (type == 'blitz') {
        promptRequest = 'a random provocative topic or question to speak about for 30-60 seconds';
      } else if (type == 'image') {
        promptRequest = 'a detailed description of a visually interesting scene (e.g. "A busy futuristic market in Tokyo")';
      } else {
        promptRequest = 'a creative story starter or opening line';
      }

      final result = await _callGroq(
        'Generate a $type speaking challenge prompt$roleContext$diffContext. $promptRequest. [Seed: $seed]',
        systemPersona: '''
You are a speaking coach. Respond using this EXACT JSON schema:
{
  "prompt": "string",
  "imageUrl": "string or null", (only provide a high-quality Unsplash source URL if type is image, e.g. https://images.unsplash.com/photo-XXX?auto=format&fit=crop&q=80&w=800)
  "hints": ["string", "string"]
}
''',
      );
      return jsonDecode(result);
    } catch (e) {
      debugPrint('⚠️ Speaking Challenge Gen Error: $e');
      return {
        'prompt': 'Talk about your most significant professional achievement.',
        'hints': ['Use the STAR method', 'Focus on impact']
      };
    }
  }

  // ── Public: Dynamic Speaking Question ──────────────────────────────────────
  static Future<Question> generateDynamicSpeakingQuestion({
    required String role,
    required String difficulty,
    required String category,
    String? resumeContext,
  }) async {
    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final contextSnippet = resumeContext != null 
          ? "Target Role & Experience (from resume): ${_truncate(resumeContext, 1500)}" 
          : "General Role: $role";
          
      final result = await _callGroq(
        'Generate a unique and interesting speaking practice question for someone at $difficulty level. $contextSnippet. Category: $category. [Session Seed: $seed]',
        systemPersona: '''
You are an expert English tutor and career coach. Return ONLY a JSON object matching this schema:
{
  "id": "ai_gen_${DateTime.now().millisecondsSinceEpoch}",
  "text": "string (the question)",
  "category": "$category",
  "difficulty": "$difficulty",
  "type": "speaking",
  "hints": ["string", "string", "string"],
  "estimatedTime": 60
}
''',
      );
      return Question.fromJson(jsonDecode(result));
    } catch (e) {
      debugPrint('⚠️ Dynamic Question Gen Error: $e');
      throw Exception('Failed to generate AI question');
    }
  }

  // ── Public: General AI Call ───────────────────────────────────────────────
  static Future<String> callAIRaw(String prompt, {String? systemPersona, bool useJsonMode = true}) async {
    return _callGroq(prompt, systemPersona: systemPersona, useJsonMode: useJsonMode);
  }

  // ── Groq API Call ───────────────────────────────────────────────────────
  static Future<String> _callGroq(String prompt, {String? systemPersona, bool useJsonMode = true}) async {
    await _checkConnectivity();

    if (AIConfig.groqApiKey.isEmpty) {
      throw AIException(
        'Groq API key not set. Check your .env file.',
        AIErrorType.invalidKey,
      );
    }

    final uri = Uri.parse(AIConfig.groqUrl);

    final Map<String, dynamic> bodyMap = {
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        if (systemPersona != null) {'role': 'system', 'content': systemPersona},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 1024,
      'top_p': 0.9,
      if (useJsonMode) 'response_format': {'type': 'json_object'},
    };

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AIConfig.groqApiKey}',
        },
        body: jsonEncode(bodyMap),
      ).timeout(AIConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 429) {
        throw AIException('Rate limit exceeded. Please try again later.', AIErrorType.rateLimited);
      } else {
        throw AIException('API Error: ${response.statusCode}', AIErrorType.apiError);
      }
    } on Exception catch (e) {
      if (e.toString().contains('SocketException')) {
        throw AIException('No internet connection.', AIErrorType.noInternet);
      }
      rethrow;
    } on TimeoutException {
      throw AIException('Request timed out.', AIErrorType.timeout);
    }
  }

  static Future<void> _checkConnectivity() async {
    // In a real app, use connectivity_plus. For now, assume connected.
    return;
  }

  // ── Prompt Building ────────────────────────────────────────────────────────
  static String _getSpeechPersona(String context, String personalityMode, [String difficulty = 'intermediate']) {
    const contextDesc = {
      'chat': 'an informal spoken conversation',
      'interview': 'a professional job interview',
      'gd': 'a group discussion',
      'scenario': 'a real-world role-play scenario (e.g., ordering food, shopping)',
    };
    final desc = contextDesc[context] ?? 'English practice';
    final personality = personalityDescriptions[personalityMode] ?? personalityDescriptions['friendly']!;
    final difficultyGuide = difficultyDescriptions[difficulty] ?? difficultyDescriptions['intermediate']!;

    return '''
You are $personality helping a student prepare for job placements and improve spoken English during $desc.

CRITICAL: You MUST provide a numerical score (0.0 to 10.0) for EVERY response, even for short greetings like "Hello" (which should score around 6.0-7.0 for correctness). Avoid generic 5.0 scores unless the input is completely incoherent.
Respond using this EXACT JSON schema:
{
  "feedback": "string",
  "tip": "string",
  "score": number,
  "fluency": number,
  "grammar": number,
  "confidence": number,
  "correction": "string or null",
  "xp": number
}
''';
  }

  static String _buildSpeechPrompt(String userText) => 'The student said: "${_truncate(userText, 1000)}"';

  static String _getInterviewPersona([String personalityMode = 'friendly', String difficulty = 'intermediate']) {
    final personality = personalityDescriptions[personalityMode] ?? personalityDescriptions['friendly']!;
    final difficultyGuide = difficultyDescriptions[difficulty] ?? difficultyDescriptions['intermediate']!;
    return '''
You are $personality evaluating a student's interview answer.

Difficulty Level: ${difficulty.toUpperCase()}
$difficultyGuide

Respond using this EXACT JSON schema:
{
  "score": number,
  "fluency": number,
  "grammar": number,
  "confidence": number,
  "relevance": number,
  "feedback": "string",
  "suggestions": ["string"],
  "wordCount": number,
  "xp": number
}
''';
  }

  static String _buildInterviewPrompt(String question, String answer) {
    return 'Interview Question: "$question"\nStudent\'s Answer: "${_truncate(answer, 2000)}"';
  }

  static String _getResumePersona({int count = 5, String? resumeText}) {
    return '''
You are an expert technical recruiter. Analyze the provided resume or skills and generate $count highly relevant interview questions.
${resumeText != null ? 'CRITICAL: Specifically look for the projects, individual achievements, and technical roles mentioned in the resume. Ask probing, deep questions about them (e.g., "In your project [X], why did you choose [Y]..."). Avoid generic HR questions.' : 'Focus heavily on the skills and experience level listed.'}
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

  static String _buildResumePrompt(String resumeText) => 'Resume Text: "${_truncate(resumeText, 2500)}"';

  static String _getQuizPersona({required String type, required String difficulty, int count = 5, List<String>? topics}) {
    final topicContext = (topics != null && topics.isNotEmpty) ? 'The student is currently focusing on: ${topics.join(", ")}.' : '';
    if (type == 'mcq') {
      return '''
You are an expert English language examiner. Generate $count unique and challenging multiple-choice questions (MCQ) for $difficulty level.
$topicContext
CRITICAL: Use varied sentence structures and diverse real-world scenarios (Work, Travel, Technology, Social, Literature).
Respond using this EXACT JSON schema:
{
  "questions": [
    {
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "correct": number (index 0-3),
      "explanation": "string describing the nuance or grammar rule used"
    }
  ]
}
''';
    } else {
      return '''
You are an expert English language examiner. Generate $count unique and challenging "fill in the blank" sentences for $difficulty level.
$topicContext
CRITICAL: Replace only the most critical word (Verb, Adjective, Phrasal Verb, or Idiomatic part). Avoid basic words.
Respond using this EXACT JSON schema:
{
  "questions": [
    {
      "sentence": "string with ___ for the blank",
      "answer": "string",
      "hint": "short pedagogical hint",
      "explanation": "string describing the grammar rule or contextual nuance"
    }
  ]
}
''';
    }
  }

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
        fluency:  (data['fluency'] as num?)?.toDouble() ?? (data['score'] as num?)?.toDouble() ?? 7.0,
        grammar:  (data['grammar'] as num?)?.toDouble() ?? (data['score'] as num?)?.toDouble() ?? 7.0,
        confidence: (data['confidence'] as num?)?.toDouble() ?? (data['score'] as num?)?.toDouble() ?? 7.0,
      );
    } catch (_) {
      return ChatMessage(id: DateTime.now().toIso8601String(), text: 'AI Thinking: ' + raw, sender: MsgSender.ai, type: MsgType.feedback, xp: 10, score: 7.0, fluency: 7.0, grammar: 7.0, confidence: 7.0);
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
        'grammar': (data['grammar'] as num?)?.toDouble() ?? (data['score'] as num?)?.toDouble() ?? 7.0,
        'confidence': (data['confidence'] as num?)?.toDouble() ?? 7.0,
        'relevance': (data['relevance'] as num?)?.toDouble() ?? 7.0,
        'feedback': data['feedback'] ?? 'Good answer!',
        'suggestions': List<String>.from(data['suggestions'] ?? []),
        'xp': (data['xp'] as num?)?.toInt() ?? 20,
        'error': false,
      };
    } catch (_) {
      return {'score': 7.0, 'fluency': 7.0, 'grammar': 7.0, 'confidence': 7.0, 'relevance': 7.0, 'feedback': raw, 'suggestions': [], 'xp': 10, 'error': false};
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

  static List<Map<String, dynamic>> _parseQuizQuestions(String raw, String type) {
    try {
      final data = jsonDecode(raw);
      return List<Map<String, dynamic>>.from(data['questions'] ?? []);
    } catch (_) {
      return [];
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

  // ── Utils ───────────────────────────────────────────────────────────────
  static String _truncate(String text, [int maxChars = 2000]) {
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars) + "... (truncated)";
  }
}