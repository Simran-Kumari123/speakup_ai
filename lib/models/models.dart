// ── User Profile ─────────────────────────────────────────────────────────────
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
  List<String> badges;
  List<String> attemptedQuestionIds; 
  DateTime joinDate;

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
    List<String>? badges,
    List<String>? attemptedQuestionIds,
    DateTime? joinDate,
  })  : badges = badges ?? [],
        attemptedQuestionIds = attemptedQuestionIds ?? [],
        joinDate = joinDate ?? DateTime.now();

  int get level => (totalXP / 200).floor() + 1;
  int get xpToNext => 200 - (totalXP % 200);

  Map<String, dynamic> toJson() => {
        'name': name, 'email': email,
        'targetRole': targetRole, 'experienceLevel': experienceLevel,
        'totalXP': totalXP, 'streakDays': streakDays,
        'practiceMinutes': practiceMinutes, 'sessionsCompleted': sessionsCompleted,
        'wordsSpoken': wordsSpoken, 'badges': badges,
        'attemptedQuestionIds': attemptedQuestionIds,
        'joinDate': joinDate.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name'] ?? '', email: j['email'] ?? '',
        targetRole: j['targetRole'] ?? 'Software Engineer',
        experienceLevel: j['experienceLevel'] ?? 'Fresher',
        totalXP: j['totalXP'] ?? 0, streakDays: j['streakDays'] ?? 0,
        practiceMinutes: j['practiceMinutes'] ?? 0,
        sessionsCompleted: j['sessionsCompleted'] ?? 0,
        wordsSpoken: j['wordsSpoken'] ?? 0,
        badges: List<String>.from(j['badges'] ?? []),
        attemptedQuestionIds: List<String>.from(j['attemptedQuestionIds'] ?? []),
        joinDate: DateTime.tryParse(j['joinDate'] ?? '') ?? DateTime.now(),
      );
}

// ── Chat Message ──────────────────────────────────────────────────────────────
enum MsgSender { user, ai }
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

  ChatMessage({
    required this.id, required this.text, required this.sender,
    this.type = MsgType.text, DateTime? time,
    this.feedback, this.xp = 0, this.score,
  }) : time = time ?? DateTime.now();
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

  PracticeTopic({
    required this.id, required this.title, required this.emoji,
    required this.description, required this.level,
    this.progress = 0, this.xpReward = 50,
  });
}

// ── Static Data ───────────────────────────────────────────────────────────────
final List<PracticeTopic> kPracticeTopics = [
  PracticeTopic(id: 'p1', title: 'Self Introduction',  emoji: '🙋', description: 'Tell me about yourself', level: 'Beginner', progress: 70, xpReward: 30),
  PracticeTopic(id: 'p2', title: 'Workplace English',  emoji: '💼', description: 'Emails, meetings & more', level: 'Beginner', progress: 40, xpReward: 40),
  PracticeTopic(id: 'p3', title: 'Group Discussion',   emoji: '🗣️', description: 'GD tips & practice',      level: 'Intermediate', progress: 20, xpReward: 50),
  PracticeTopic(id: 'p4', title: 'Vocabulary Builder', emoji: '📖', description: 'Power words for success', level: 'Intermediate', progress: 30, xpReward: 45),
];
