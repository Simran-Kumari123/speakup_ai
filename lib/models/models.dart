// ── User Profile ─────────────────────────────────────────────────────────────
enum ChallengeType { oneMinute, rapidFire, storyCompletion }

// ── Vocabulary Word ───────────────────────────────────────────────────────────
class VocabularyWord {
  final String id;
  final String word;
  final String meaning;
  final String partOfSpeech;
  final List<String> synonyms;
  final List<String> antonyms;
  final String example;
  final String pronunciation;
  final String category;
  bool learned;
  DateTime date;
  final String? translatedMeaning;
  final String? translatedExample;
  final String? imageUrl;

  VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.partOfSpeech = '',
    this.synonyms = const [],
    this.antonyms = const [],
    this.example = '',
    this.pronunciation = '',
    this.category = 'general',
    this.learned = false,
    DateTime? date,
    this.translatedMeaning,
    this.translatedExample,
    this.imageUrl,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'meaning': meaning,
    'partOfSpeech': partOfSpeech,
    'synonyms': synonyms,
    'antonyms': antonyms,
    'example': example,
    'pronunciation': pronunciation,
    'category': category,
    'learned': learned,
    'date': date.toIso8601String(),
    'translatedMeaning': translatedMeaning,
    'translatedExample': translatedExample,
    'imageUrl': imageUrl,
  };

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => VocabularyWord(
    id: json['id'] ?? '',
    word: json['word'] ?? '',
    meaning: json['meaning'] ?? '',
    partOfSpeech: json['partOfSpeech'] ?? '',
    synonyms: List<String>.from(json['synonyms'] ?? []),
    antonyms: List<String>.from(json['antonyms'] ?? []),
    example: json['example'] ?? '',
    pronunciation: json['pronunciation'] ?? '',
    category: json['category'] ?? 'general',
    learned: json['learned'] ?? false,
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    translatedMeaning: json['translatedMeaning'],
    translatedExample: json['translatedExample'],
    imageUrl: json['imageUrl'],
  );

  VocabularyWord copyWith({
    String? translatedMeaning,
    String? translatedExample,
    String? imageUrl,
  }) =>
      VocabularyWord(
        id: id,
        word: word,
        meaning: meaning,
        partOfSpeech: partOfSpeech,
        synonyms: synonyms,
        antonyms: antonyms,
        example: example,
        pronunciation: pronunciation,
        category: category,
        learned: learned,
        date: date,
        translatedMeaning: translatedMeaning ?? this.translatedMeaning,
        translatedExample: translatedExample ?? this.translatedExample,
        imageUrl: imageUrl ?? this.imageUrl,
      );
}


class UserProfile {
  String name;
  String email;
  String targetRole;
  String experienceLevel;
  int totalXP;
  int streakDays;
  int practiceMinutes;
  int sessionsCompleted;
  int wordsSpoken;
  int dailyGoalMinutes;
  List<AchievementBadge> badges;
  List<String> attemptedQuestionIds; 
  DateTime joinDate;
  DateTime? lastPracticeDate;
  List<PracticeSession> recentSessions;
  Map<String, int> topicProgress;
  List<String> masteredWords;
  List<String> difficultWords;
  List<WeakArea> weakAreas;

  // ── AI Chat Coach Fields ──
  int wordsLearned;
  int quizzesCompleted;
  double accuracy;
  List<int> weeklyXP; 
  DateTime lastActiveDate;
  int challengeStreak;
  String personalityMode;
  String difficulty; 
  String voicePreference;
  String language;
  List<String> learnedVocabIds;
  List<String> weakWords;
  String voiceStyle; 
  double voicePitch;
  String? preferredVoiceId;
  String? profilePicBase64;
  String? resumeText;
  Map<String, dynamic>? resumeAnalysis;
  List<ResumeRecord> resumes;
  String? activeResumeId;
  bool isResumeMode;

  UserProfile({
    this.name = '',
    this.email = '',
    this.targetRole = 'roleSoftwareEngineer',
    this.experienceLevel = 'levelFresher',
    this.totalXP = 0,
    this.streakDays = 0,
    this.practiceMinutes = 0,
    this.sessionsCompleted = 0,
    this.wordsSpoken = 0,
    this.dailyGoalMinutes = 15,
    List<AchievementBadge>? badges,
    List<String>? attemptedQuestionIds,
    DateTime? joinDate,
    this.lastPracticeDate,
    List<PracticeSession>? recentSessions,
    Map<String, int>? topicProgress,
    List<String>? masteredWords,
    List<String>? difficultWords,
    this.wordsLearned = 0,
    this.quizzesCompleted = 0,
    this.accuracy = 0.0,
    List<int>? weeklyXP,
    DateTime? lastActiveDate,
    this.challengeStreak = 0,
    this.personalityMode = 'friendly',
    this.difficulty = 'beginner',
    this.voicePreference = 'normal',
    this.voiceStyle = 'female',
    this.voicePitch = 1.0,
    this.preferredVoiceId,
    this.language = 'en',
    List<String>? learnedVocabIds,
    List<String>? weakWords,
    List<WeakArea>? weakAreas,
    this.profilePicBase64,
    this.resumeText,
    this.resumeAnalysis,
    List<ResumeRecord>? resumes,
    this.activeResumeId,
    this.isResumeMode = false,
  })  : resumes = resumes ?? [],
        badges = badges ?? [],
        attemptedQuestionIds = attemptedQuestionIds ?? [],
        joinDate = joinDate ?? DateTime.now(),
        recentSessions = recentSessions ?? [],
        topicProgress = topicProgress ?? {},
        masteredWords = masteredWords ?? [],
        difficultWords = difficultWords ?? [],
        weeklyXP = weeklyXP ?? [0, 0, 0, 0, 0, 0, 0],
        lastActiveDate = lastActiveDate ?? DateTime.now(),
        learnedVocabIds = learnedVocabIds ?? [],
        weakWords = weakWords ?? [],
        weakAreas = weakAreas ?? [];

  int get level => (totalXP / 200).floor() + 1;
  int get xpToNext => 200 - (totalXP % 200);

  double get fluencyScore => recentSessions.isEmpty ? 0.0 : (recentSessions.map((e) => e.fluency).reduce((a, b) => a + b) / recentSessions.length).clamp(0.0, 10.0);
  double get grammarScore => recentSessions.isEmpty ? 0.0 : (recentSessions.map((e) => e.grammar).reduce((a, b) => a + b) / recentSessions.length).clamp(0.0, 10.0);
  double get confidenceScore => recentSessions.isEmpty ? 0.0 : (recentSessions.map((e) => e.confidence).reduce((a, b) => a + b) / recentSessions.length).clamp(0.0, 10.0);

  Map<String, dynamic> toJson() => {
    'name': name, 'email': email,
    'targetRole': targetRole, 'experienceLevel': experienceLevel,
    'totalXP': totalXP, 'streakDays': streakDays,
    'practiceMinutes': practiceMinutes, 'sessionsCompleted': sessionsCompleted,
    'wordsSpoken': wordsSpoken, 'dailyGoalMinutes': dailyGoalMinutes,
    'badges': badges.map((e) => e.toJson()).toList(),
    'attemptedQuestionIds': attemptedQuestionIds,
    'joinDate': joinDate.toIso8601String(),
    'lastPracticeDate': lastPracticeDate?.toIso8601String(),
    'recentSessions': recentSessions.map((e) => e.toJson()).toList(),
    'topicProgress': topicProgress,
    'masteredWords': masteredWords,
    'difficultWords': difficultWords,
    'wordsLearned': wordsLearned,
    'quizzesCompleted': quizzesCompleted,
    'accuracy': accuracy,
    'weeklyXP': weeklyXP,
    'lastActiveDate': lastActiveDate.toIso8601String(),
    'challengeStreak': challengeStreak,
    'personalityMode': personalityMode,
    'difficulty': difficulty,
    'voicePreference': voicePreference,
    'voiceStyle': voiceStyle,
    'voicePitch': voicePitch,
    'preferredVoiceId': preferredVoiceId,
    'language': language,
    'learnedVocabIds': learnedVocabIds,
    'weakWords': weakWords,
    'weakAreas': weakAreas.map((e) => e.toJson()).toList(),
    'profilePicBase64': profilePicBase64,
    'resumeText': resumeText,
    'resumeAnalysis': resumeAnalysis,
    'resumes': resumes.map((e) => e.toJson()).toList(),
    'activeResumeId': activeResumeId,
    'isResumeMode': isResumeMode,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] ?? '', email: j['email'] ?? '',
    targetRole: j['targetRole'] ?? 'Software Engineer',
    experienceLevel: j['experienceLevel'] ?? 'Fresher',
    totalXP: j['totalXP'] ?? 0, 
    streakDays: j['streakDays'] ?? 0,
    practiceMinutes: j['practiceMinutes'] ?? 0,
    sessionsCompleted: j['sessionsCompleted'] ?? 0,
    wordsSpoken: j['wordsSpoken'] ?? 0,
    dailyGoalMinutes: j['dailyGoalMinutes'] ?? 15,
    badges: (j['badges'] as List?)?.map((e) => AchievementBadge.fromJson(e)).toList() ?? [],
    attemptedQuestionIds: List<String>.from(j['attemptedQuestionIds'] ?? []),
    joinDate: DateTime.tryParse(j['joinDate'] ?? '') ?? DateTime.now(),
    lastPracticeDate: DateTime.tryParse(j['lastPracticeDate'] ?? ''),
    recentSessions: (j['recentSessions'] as List?)
        ?.map((e) => PracticeSession.fromJson(e))
        .toList(),
    topicProgress: Map<String, int>.from(j['topicProgress'] ?? {}),
    masteredWords: List<String>.from(j['masteredWords'] ?? []),
    difficultWords: List<String>.from(j['difficultWords'] ?? []),
    wordsLearned: j['wordsLearned'] ?? 0,
    quizzesCompleted: j['quizzesCompleted'] ?? 0,
    accuracy: (j['accuracy'] as num?)?.toDouble() ?? 0.0,
    weeklyXP: List<int>.from(j['weeklyXP'] ?? [0, 0, 0, 0, 0, 0, 0]),
    lastActiveDate: DateTime.tryParse(j['lastActiveDate'] ?? '') ?? DateTime.now(),
    challengeStreak: j['challengeStreak'] ?? 0,
    personalityMode: j['personalityMode'] ?? 'friendly',
    difficulty: j['difficulty'] ?? 'beginner',
    voicePreference: j['voicePreference'] ?? 'normal',
    voiceStyle: j['voiceStyle'] ?? 'female',
    voicePitch: (j['voicePitch'] as num?)?.toDouble() ?? 1.0,
    preferredVoiceId: j['preferredVoiceId'],
    language: j['language'] ?? 'en',
    learnedVocabIds: List<String>.from(j['learnedVocabIds'] ?? []),
    weakWords: List<String>.from(j['weakWords'] ?? []),
    weakAreas: (j['weakAreas'] as List?)?.map((e) => WeakArea.fromJson(e)).toList() ?? [],
    profilePicBase64: j['profilePicBase64'],
    resumeText: j['resumeText'],
    resumeAnalysis: j['resumeAnalysis'] != null ? Map<String, dynamic>.from(j['resumeAnalysis']) : null,
    resumes: (j['resumes'] as List?)?.map((e) => ResumeRecord.fromJson(e)).toList() ?? [],
    activeResumeId: j['activeResumeId'],
    isResumeMode: j['isResumeMode'] ?? false,
  );
}

// ── Practice Session ────────────────────────────────────────────────────────
class PracticeSession {
  final String id;
  final String topic;
  final String? topicId; 
  final String type;
  final double score;
  final double fluency;
  final double grammar;
  final double confidence;
  final int xp;
  final DateTime date;

  PracticeSession({
    required this.id, required this.topic, required this.type,
    required this.score, required this.xp, DateTime? date, this.topicId,
    this.fluency = 0.0, this.grammar = 0.0, this.confidence = 0.0,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'topic': topic, 'topicId': topicId, 'type': type,
    'score': score, 'xp': xp, 'date': date.toIso8601String(),
    'fluency': fluency, 'grammar': grammar, 'confidence': confidence,
  };

  factory PracticeSession.fromJson(Map<String, dynamic> j) => PracticeSession(
    id: j['id'] ?? '', topic: j['topic'] ?? '', type: j['type'] ?? '',
    topicId: j['topicId'],
    score: (j['score'] as num?)?.toDouble() ?? 0.0,
    xp: j['xp'] ?? 0,
    date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
    fluency: (j['fluency'] as num?)?.toDouble() ?? (j['score'] as num?)?.toDouble() ?? 0.0,
    grammar: (j['grammar'] as num?)?.toDouble() ?? (j['score'] as num?)?.toDouble() ?? 0.0,
    confidence: (j['confidence'] as num?)?.toDouble() ?? (j['score'] as num?)?.toDouble() ?? 0.0,
  );
}

// ── Badge Model ──────────────────────────────────────────────────────────────
class AchievementBadge {
  final String name;
  final String description;
  final String icon;

  AchievementBadge({required this.name, required this.description, this.icon = '🏅'});

  Map<String, dynamic> toJson() => {'name': name, 'description': description, 'icon': icon};
  factory AchievementBadge.fromJson(Map<String, dynamic> j) => AchievementBadge(
    name: j['name'] ?? '',
    description: j['description'] ?? '',
    icon: j['icon'] ?? '🏅',
  );
}

// ── Chat & Group Discussion Message ──────────────────────────────────────────
enum MsgSender { user, ai, participant }
enum MsgType   { text, voice, feedback, tip, question }

class ChatMessage {
  final String id;
  final String text;
  final MsgSender sender;
  final MsgType type;
  final DateTime time;
  final String? feedback;
  final int xp;
  final double? score;      
  final double? fluency;
  final double? grammar;
  final double? confidence;
  final String? participantName;
  final String? translatedText;

  ChatMessage({
    required this.id, required this.text, required this.sender,
    this.type = MsgType.text, DateTime? time,
    this.feedback, this.xp = 0, this.score,
    this.fluency, this.grammar, this.confidence,
    this.participantName,
    this.translatedText,
  }) : time = time ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'text': text,
    'sender': sender.index, 'type': type.index,
    'time': time.toIso8601String(),
    'feedback': feedback, 'xp': xp, 'score': score,
    'fluency': fluency, 'grammar': grammar, 'confidence': confidence,
    'participantName': participantName, 'translatedText': translatedText,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] ?? '',
    text: j['text'] ?? '',
    sender: MsgSender.values[j['sender'] ?? 0],
    type: MsgType.values[j['type'] ?? 0],
    time: DateTime.tryParse(j['time'] ?? ''),
    feedback: j['feedback'],
    xp: j['xp'] ?? 0,
    score: (j['score'] as num?)?.toDouble(),
    fluency: (j['fluency'] as num?)?.toDouble(),
    grammar: (j['grammar'] as num?)?.toDouble(),
    confidence: (j['confidence'] as num?)?.toDouble(),
    participantName: j['participantName'],
    translatedText: j['translatedText'],
  );

  ChatMessage copyWith({String? translatedText}) => ChatMessage(
    id: id, text: text, sender: sender, type: type, time: time,
    feedback: feedback, xp: xp, score: score,
    fluency: fluency, grammar: grammar, confidence: confidence,
    participantName: participantName,
    translatedText: translatedText ?? this.translatedText,
  );
}

// ── Quiz Result ───────────────────────────────────────────────────────────────
class QuizResult {
  final String id;
  final String quizType; // mcq, fill_blank, matching
  final int score;
  final int total;
  final int timeTaken; // seconds
  final DateTime timestamp;
  final List<Map<String, dynamic>> answers;

  QuizResult({
    required this.id,
    required this.quizType,
    required this.score,
    required this.total,
    this.timeTaken = 0,
    DateTime? timestamp,
    List<Map<String, dynamic>>? answers,
  })  : timestamp = timestamp ?? DateTime.now(),
        answers = answers ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'quizType': quizType,
    'score': score, 'total': total,
    'timeTaken': timeTaken,
    'timestamp': timestamp.toIso8601String(),
    'answers': answers,
  };

  factory QuizResult.fromJson(Map<String, dynamic> j) => QuizResult(
    id: j['id'] ?? '',
    quizType: j['quizType'] ?? 'mcq',
    score: j['score'] ?? 0,
    total: j['total'] ?? 0,
    timeTaken: j['timeTaken'] ?? 0,
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    answers: List<Map<String, dynamic>>.from(j['answers'] ?? []),
  );
}

// ── Interview Session ─────────────────────────────────────────────────────────
class InterviewSession {
  final String id;
  final String type; // technical, hr, resume_based
  final String difficulty;
  final DateTime timestamp;
  final List<InterviewQA> qaPairs;
  final double overallScore;
  final List<String> strengths;
  final List<String> weaknesses;
  final String? resumeSkills;

  InterviewSession({
    required this.id,
    required this.type,
    this.difficulty = 'beginner',
    DateTime? timestamp,
    List<InterviewQA>? qaPairs,
    this.overallScore = 0.0,
    List<String>? strengths,
    List<String>? weaknesses,
    this.resumeSkills,
  })  : timestamp = timestamp ?? DateTime.now(),
        qaPairs = qaPairs ?? [],
        strengths = strengths ?? [],
        weaknesses = weaknesses ?? [];

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'difficulty': difficulty,
    'timestamp': timestamp.toIso8601String(),
    'qaPairs': qaPairs.map((q) => q.toJson()).toList(),
    'overallScore': overallScore,
    'strengths': strengths, 'weaknesses': weaknesses,
    'resumeSkills': resumeSkills,
  };

  factory InterviewSession.fromJson(Map<String, dynamic> j) => InterviewSession(
    id: j['id'] ?? '',
    type: j['type'] ?? 'hr',
    difficulty: j['difficulty'] ?? 'beginner',
    timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
    qaPairs: (j['qaPairs'] as List?)?.map((q) => InterviewQA.fromJson(q)).toList() ?? [],
    overallScore: (j['overallScore'] as num?)?.toDouble() ?? 0.0,
    strengths: List<String>.from(j['strengths'] ?? []),
    weaknesses: List<String>.from(j['weaknesses'] ?? []),
    resumeSkills: j['resumeSkills'],
  );
}

class InterviewQA {
  final String question;
  final String answer;
  final double score;
  final String feedback;
  final String? idealAnswer;

  InterviewQA({
    required this.question,
    required this.answer,
    this.score = 0.0,
    this.feedback = '',
    this.idealAnswer,
  });

  Map<String, dynamic> toJson() => {
    'question': question, 'answer': answer,
    'score': score, 'feedback': feedback,
    'idealAnswer': idealAnswer,
  };

  factory InterviewQA.fromJson(Map<String, dynamic> j) => InterviewQA(
    question: j['question'] ?? '',
    answer: j['answer'] ?? '',
    score: (j['score'] as num?)?.toDouble() ?? 0.0,
    feedback: j['feedback'] ?? '',
    idealAnswer: j['idealAnswer'],
  );
}

// ── Daily Challenge ───────────────────────────────────────────────────────────
class DailyChallenge {
  final String id;
  final String type; // shadow, detective, connect
  final String title;
  final String description;
  final int xpReward;
  bool completed;
  final DateTime date;
  final Map<String, dynamic>? dynamicContent;

  DailyChallenge({
    required this.id,
    required this.type,
    required this.title,
    this.description = '',
    this.xpReward = 20,
    this.completed = false,
    DateTime? date,
    this.dynamicContent,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'title': title,
    'description': description, 'xpReward': xpReward,
    'completed': completed, 'date': date.toIso8601String(),
    'dynamicContent': dynamicContent,
  };

  factory DailyChallenge.fromJson(Map<String, dynamic> j) => DailyChallenge(
    id: j['id'] ?? '',
    type: j['type'] ?? 'speaking',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    xpReward: j['xpReward'] ?? 20,
    completed: j['completed'] ?? false,
    date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
    dynamicContent: j['dynamicContent'],
  );
}

// ── Weak Area ─────────────────────────────────────────────────────────────────
class WeakArea {
  final String category; // grammar, pronunciation, vocabulary, fluency
  final String description;
  int errorCount;
  final List<String> recommendations;
  final List<String> exampleMistakes;

  WeakArea({
    required this.category,
    this.description = '',
    this.errorCount = 0,
    List<String>? recommendations,
    List<String>? exampleMistakes,
  })  : recommendations = recommendations ?? [],
        exampleMistakes = exampleMistakes ?? [];

  Map<String, dynamic> toJson() => {
    'category': category, 'description': description,
    'errorCount': errorCount,
    'recommendations': recommendations,
    'exampleMistakes': exampleMistakes,
  };

  factory WeakArea.fromJson(Map<String, dynamic> j) => WeakArea(
    category: j['category'] ?? '',
    description: j['description'] ?? '',
    errorCount: j['errorCount'] ?? 0,
    recommendations: List<String>.from(j['recommendations'] ?? []),
    exampleMistakes: List<String>.from(j['exampleMistakes'] ?? []),
  );
}

class GDParticipant {
  final String name;
  final String role; 
  final String opinion; // 'Support', 'Oppose', 'Neutral'
  final String avatarEmoji;
  final String personality; 

  GDParticipant({
    required this.name,
    required this.role,
    required this.opinion,
    required this.avatarEmoji,
    required this.personality,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'role': role, 'opinion': opinion, 
    'avatarEmoji': avatarEmoji, 'personality': personality,
  };

  factory GDParticipant.fromJson(Map<String, dynamic> j) => GDParticipant(
    name: j['name'] ?? '', role: j['role'] ?? '', opinion: j['opinion'] ?? '',
    avatarEmoji: j['avatarEmoji'] ?? '🤖', personality: j['personality'] ?? '',
  );
}

// ── Practice Topic (Dashboard) ────────────────────────────────────────────────
class PracticeTopic {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final String level;
  final int xpReward;
  final String colorHex;

  PracticeTopic({
    required this.id, 
    required this.title, 
    required this.emoji,
    required this.description, 
    required this.level,
    this.xpReward = 50,
    this.colorHex = 'FF6366F1', // Default Indigo
  });
}

// ── Static Data ───────────────────────────────────────────────────────────────
final List<PracticeTopic> kPracticeTopics = [
  PracticeTopic(id: 'p5', title: 'Ordering Food', emoji: '🍔', description: 'Restaurant & Cafe role-play', level: 'Beginner', xpReward: 35, colorHex: 'FFFFA726'),
  PracticeTopic(id: 'p6', title: 'Phone Calls', emoji: '📞', description: 'Appointments & Support', level: 'Intermediate', xpReward: 40, colorHex: 'FF29B6F6'),
  PracticeTopic(id: 'p7', title: 'Shopping', emoji: '🛍️', description: 'Buying & Returning items', level: 'Beginner', xpReward: 30, colorHex: 'FFEC407A'),
  PracticeTopic(id: 'p1', title: 'Self Introduction',  emoji: '🙋', description: 'Tell me about yourself', level: 'Beginner', xpReward: 30, colorHex: 'FF6366F1'),
  PracticeTopic(id: 'p2', title: 'Workplace English',  emoji: '💼', description: 'Emails, meetings & more', level: 'Beginner', xpReward: 40, colorHex: 'FF10B981'),
];

// ── Question Model ──────────────────────────────────────────────────────────
class Question {
  final String id;
  final String text;
  final String category;
  final String difficulty;
  final String type;
  final List<String> hints;
  final int estimatedTime;
  final String? followUp;

  Question({
    required this.id,
    required this.text,
    required this.category,
    required this.difficulty,
    required this.type,
    required this.hints,
    required this.estimatedTime,
    this.followUp,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'beginner',
      type: json['type'] ?? 'speaking',
      hints: List<String>.from(json['hints'] ?? []),
      estimatedTime: json['estimatedTime'] ?? 60,
      followUp: json['followUp'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'category': category,
    'difficulty': difficulty,
    'type': type,
    'hints': hints,
    'estimatedTime': estimatedTime,
    'followUp': followUp,
  };
}

// ── Resume Record ───────────────────────────────────────────────────────────
class ResumeRecord {
  final String id;
  final String fileName;
  final String text;
  final Map<String, dynamic> analysis;
  final String? roleTag;
  final List<String> skills;
  final DateTime date;

  ResumeRecord({
    required this.id,
    required this.fileName,
    required this.text,
    required this.analysis,
    this.roleTag,
    this.skills = const [],
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'text': text,
    'analysis': analysis,
    'roleTag': roleTag,
    'skills': skills,
    'date': date.toIso8601String(),
  };

  factory ResumeRecord.fromJson(Map<String, dynamic> json) => ResumeRecord(
    id: json['id'] ?? '',
    fileName: json['fileName'] ?? '',
    text: json['text'] ?? '',
    analysis: Map<String, dynamic>.from(json['analysis'] ?? {}),
    roleTag: json['roleTag'],
    skills: List<String>.from(json['skills'] ?? []),
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
  );
}

// Practice categories
const Map<String, String> categoryEmojis = {
  'general': '🌍',
  'hobbies': '🎮',
  'travel': '✈️',
  'food': '🍕',
  'technology': '💻',
  'sports': '⚽',
  'movies': '🎬',
  'books': '📚',
  'career': '💼',
  'education': '🎓',
  'environment': '🌱',
  'relationships': '👥',
  'hr': '🏢',
  'behavioral': '🤝',
  'technical': '⚙️',
  'situational': '🎯',
};

const Map<String, String> difficultyColors = {
  'beginner': '#4CAF50',
  'intermediate': '#FF9800',
  'advanced': '#F44336',
};
