class Question {
  final String id;
  final String text;
  final String category;
  final String difficulty; // beginner, intermediate, advanced
  final String type; // speaking, interview, conversation
  final List<String> hints;
  final int estimatedTime; // in seconds
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
