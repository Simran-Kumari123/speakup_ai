// ── User Profile ─────────────────────────────────────────────────────────────
enum ChallengeType { oneMinute, rapidFire, storyCompletion }

class VocabularyWord {
  final String id;
  final String word;
  final String meaning;
  final String example;
  final String pronunciation;
  final String category;

  VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    required this.example,
    this.pronunciation = '',
    this.category = 'general',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'word': word,
    'meaning': meaning,
    'example': example,
    'pronunciation': pronunciation,
    'category': category,
  };

  factory VocabularyWord.fromJson(Map<String, dynamic> json) => VocabularyWord(
    id: json['id'] ?? '',
    word: json['word'] ?? '',
    meaning: json['meaning'] ?? '',
    example: json['example'] ?? '',
    pronunciation: json['pronunciation'] ?? '',
    category: json['category'] ?? 'general',
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

  UserProfile({
    this.name = '',
    this.email = '',
    this.targetRole = 'Software Engineer',
    this.experienceLevel = 'Fresher',
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
  })  : badges = badges ?? [],
        attemptedQuestionIds = attemptedQuestionIds ?? [],
        joinDate = joinDate ?? DateTime.now(),
        recentSessions = recentSessions ?? [],
        topicProgress = topicProgress ?? {},
        masteredWords = masteredWords ?? [],
        difficultWords = difficultWords ?? [];

  int get level => (totalXP / 200).floor() + 1;
  int get xpToNext => 200 - (totalXP % 200);

  // Helper getters for progress visualization
  double get fluencyScore => recentSessions.isEmpty ? 0.0 : (recentSessions.map((e) => e.score).reduce((a, b) => a + b) / recentSessions.length).clamp(0.0, 10.0);
  double get grammarScore => recentSessions.isEmpty ? 0.0 : (recentSessions.map((e) => (e.score * 0.85).clamp(0.0, 10.0)).reduce((a, b) => a + b) / recentSessions.length);
  double get confidenceScore => recentSessions.isEmpty ? 0.0 : (recentSessions.map((e) => (e.score * 0.95).clamp(0.0, 10.0)).reduce((a, b) => a + b) / recentSessions.length);

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
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '', email: j['email'] ?? '',
        targetRole: j['targetRole'] ?? 'Software Engineer',
        experienceLevel: j['experienceLevel'] ?? 'Fresher',
        totalXP: j['totalXP'] ?? 0, streakDays: j['streakDays'] ?? 0,
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
      );
}

// ── Practice Session ────────────────────────────────────────────────────────
class PracticeSession {
  final String id;
  final String topic;
  final String? topicId; 
  final String type;
  final double score;
  final int xp;
  final DateTime date;

  PracticeSession({
    required this.id, required this.topic, required this.type,
    required this.score, required this.xp, DateTime? date, this.topicId,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id, 'topic': topic, 'topicId': topicId, 'type': type,
    'score': score, 'xp': xp, 'date': date.toIso8601String(),
  };

  factory PracticeSession.fromJson(Map<String, dynamic> j) => PracticeSession(
    id: j['id'] ?? '', topic: j['topic'] ?? '', type: j['type'] ?? '',
    topicId: j['topicId'],
    score: (j['score'] as num?)?.toDouble() ?? 0.0,
    xp: j['xp'] ?? 0,
    date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
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
  final String? participantName;

  ChatMessage({
    required this.id, required this.text, required this.sender,
    this.type = MsgType.text, DateTime? time,
    this.feedback, this.xp = 0, this.score,
    this.participantName,
  }) : time = time ?? DateTime.now();
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
  int progress;
  final int xpReward;
  final String colorHex;

  PracticeTopic({
    required this.id, required this.title, required this.emoji,
    required this.description, required this.level,
    this.progress = 0, this.xpReward = 50,
    this.colorHex = 'FF6366F1', // Default Indigo
  });
}

// ── Static Data ───────────────────────────────────────────────────────────────
final List<PracticeTopic> kPracticeTopics = [
  PracticeTopic(id: 'p1', title: 'Self Introduction',  emoji: '🙋', description: 'Tell me about yourself', level: 'Beginner', progress: 70, xpReward: 30, colorHex: 'FF6366F1'),
  PracticeTopic(id: 'p2', title: 'Workplace English',  emoji: '💼', description: 'Emails, meetings & more', level: 'Beginner', progress: 40, xpReward: 40, colorHex: 'FF10B981'),
  PracticeTopic(id: 'p3', title: 'Group Discussion',   emoji: '🗣️', description: 'GD tips & practice',      level: 'Intermediate', progress: 20, xpReward: 50, colorHex: 'FFF59E0B'),
  PracticeTopic(id: 'p4', title: 'Vocabulary Builder', emoji: '📖', description: 'Power words for success', level: 'Intermediate', progress: 30, xpReward: 45, colorHex: 'FF3ABEF9'),
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
