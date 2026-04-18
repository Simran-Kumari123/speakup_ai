import 'dart:math';
import '../models/models.dart';


class QuestionService {
  static final QuestionService _instance = QuestionService._internal();
  static Random random = Random();

  QuestionService._internal();

  factory QuestionService() {
    return _instance;
  }

  // Get all questions
  List<Question> getAllQuestions() => _allQuestions;

  // Get questions by type
  List<Question> getQuestionsByType(String type) =>
      _allQuestions.where((q) => q.type == type).toList();

  // Get questions by category
  List<Question> getQuestionsByCategory(String category) =>
      _allQuestions.where((q) => q.category == category).toList();

  // Get questions by difficulty
  List<Question> getQuestionsByDifficulty(String difficulty) =>
      _allQuestions.where((q) => q.difficulty == difficulty).toList();

  // Get filtered questions
  List<Question> getFiltered({
    String? type,
    String? category,
    String? difficulty,
  }) {
    return _allQuestions.where((q) {
      if (type != null && q.type != type) return false;
      if (category != null && q.category != category) return false;
      if (difficulty != null && q.difficulty != difficulty) return false;
      return true;
    }).toList();
  }

  // Get random question
  Question getRandomQuestion({
    String? type,
    String? category,
    String? difficulty,
  }) {
    final filtered = getFiltered(type: type, category: category, difficulty: difficulty);
    if (filtered.isEmpty) return _allQuestions[random.nextInt(_allQuestions.length)];
    return filtered[random.nextInt(filtered.length)];
  }

  // Get N random questions
  List<Question> getRandomQuestions(int count, {
    String? type,
    String? category,
    String? difficulty,
  }) {
    final filtered = getFiltered(type: type, category: category, difficulty: difficulty);
    final source = filtered.isEmpty ? _allQuestions : filtered;
    final questions = <Question>[];
    final used = <int>{};

    while (questions.length < count && used.length < source.length) {
      final idx = random.nextInt(source.length);
      if (!used.contains(idx)) {
        questions.add(source[idx]);
        used.add(idx);
      }
    }
    return questions;
  }

  // Get unique categories
  List<String> getCategories({String? type}) {
    final categories = <String>{};
    for (var q in _allQuestions) {
      if (type != null && q.type != type) continue;
      categories.add(q.category);
    }
    return categories.toList()..sort();
  }

  // ===================== QUESTIONS DATABASE =====================

  static final List<Question> _allQuestions = [
    // ==================== SPEAKING PRACTICE ====================
    
    // General - Beginner
    Question(
      id: 'speak_gen_b_001',
      text: 'Tell me about yourself and your daily routine.',
      category: 'general',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Start with your name', 'Talk about your morning', 'Mention what you do'],
      estimatedTime: 60,
      followUp: 'What is your favorite part of the day?',
    ),
    Question(
      id: 'speak_gen_b_002',
      text: 'Describe your favorite hobby and why you enjoy it.',
      category: 'hobbies',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Name the hobby', 'Explain why you like it', 'When do you do it?'],
      estimatedTime: 60,
    ),
    Question(
      id: 'speak_gen_b_003',
      text: 'What\'s your favorite food and how often do you eat it?',
      category: 'food',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Name the food', 'Describe how it tastes', 'Why do you like it?'],
      estimatedTime: 45,
    ),
    Question(
      id: 'speak_gen_b_004',
      text: 'Talk about a place you\'d like to visit someday.',
      category: 'travel',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Where do you want to go?', 'Why is it interesting?', 'What would you do there?'],
      estimatedTime: 60,
    ),
    Question(
      id: 'speak_gen_b_005',
      text: 'Describe your best friend and what you like about them.',
      category: 'relationships',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Their name', 'How long have you known them?', 'What do you do together?'],
      estimatedTime: 60,
    ),
    Question(
      id: 'speak_gen_b_006',
      text: 'What\'s your favorite season and why?',
      category: 'general',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Which season?', 'What\'s special about it?', 'What activities do you do?'],
      estimatedTime: 45,
    ),
    Question(
      id: 'speak_gen_b_007',
      text: 'Tell me about your family.',
      category: 'relationships',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['How many members?', 'What do they do?', 'Tell a story about them'],
      estimatedTime: 60,
    ),
    Question(
      id: 'speak_gen_b_008',
      text: 'What\'s your favorite movie or TV show?',
      category: 'movies',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Title', 'What\'s it about?', 'Why did you like it?'],
      estimatedTime: 60,
    ),
    Question(
      id: 'speak_gen_b_009',
      text: 'Describe what you did during your last vacation.',
      category: 'travel',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Where did you go?', 'Who was with you?', 'What did you do?'],
      estimatedTime: 75,
    ),
    Question(
      id: 'speak_gen_b_010',
      text: 'What sport do you like to play or watch?',
      category: 'sports',
      difficulty: 'beginner',
      type: 'speaking',
      hints: ['Which sport?', 'Do you play or watch?', 'Why do you like it?'],
      estimatedTime: 60,
    ),

    // General - Intermediate
    Question(
      id: 'speak_gen_i_001',
      text: 'Discuss how technology has changed your daily life in the past 5 years.',
      category: 'technology',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Smartphones/social media', 'Work communication', 'Entertainment changes'],
      estimatedTime: 90,
      followUp: 'What concerns do you have about technology?',
    ),
    Question(
      id: 'speak_gen_i_002',
      text: 'What are the challenges of modern education and how would you solve them?',
      category: 'education',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Traditional vs online', 'Student engagement', 'Accessibility'],
      estimatedTime: 90,
    ),
    Question(
      id: 'speak_gen_i_003',
      text: 'Explain the pros and cons of social media.',
      category: 'technology',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Connection benefits', 'Mental health issues', 'Privacy concerns'],
      estimatedTime: 90,
    ),
    Question(
      id: 'speak_gen_i_004',
      text: 'How do you think climate change should be addressed?',
      category: 'environment',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Government policy', 'Individual responsibility', 'Alternative energy'],
      estimatedTime: 90,
    ),
    Question(
      id: 'speak_gen_i_005',
      text: 'What role does art and culture play in society?',
      category: 'general',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Preservation of heritage', 'Social expression', 'Economic value'],
      estimatedTime: 90,
    ),
    Question(
      id: 'speak_gen_i_006',
      text: 'Discuss the balance between work and personal life.',
      category: 'career',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Work hours', 'Family time', 'Mental health'],
      estimatedTime: 90,
    ),
    Question(
      id: 'speak_gen_i_007',
      text: 'What makes a good leader?',
      category: 'career',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Communication', 'Decision-making', 'Team management'],
      estimatedTime: 75,
    ),
    Question(
      id: 'speak_gen_i_008',
      text: 'How has the pandemic changed the way people work?',
      category: 'career',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Remote work', 'Work-life balance', 'Job market changes'],
      estimatedTime: 90,
    ),
    Question(
      id: 'speak_gen_i_009',
      text: 'Discuss the importance of learning a second language.',
      category: 'education',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Career opportunities', 'Cultural understanding', 'Personal growth'],
      estimatedTime: 75,
    ),
    Question(
      id: 'speak_gen_i_010',
      text: 'What is your philosophy on life and happiness?',
      category: 'general',
      difficulty: 'intermediate',
      type: 'speaking',
      hints: ['Personal values', 'Goals and dreams', 'Overcoming challenges'],
      estimatedTime: 90,
    ),

    // General - Advanced
    Question(
      id: 'speak_gen_a_001',
      text: 'Analyze the impact of artificial intelligence on employment and society.',
      category: 'technology',
      difficulty: 'advanced',
      type: 'speaking',
      hints: ['Job displacement', 'New opportunities', 'Ethical considerations', 'Regulation'],
      estimatedTime: 120,
    ),
    Question(
      id: 'speak_gen_a_002',
      text: 'Discuss economic inequality and potential solutions.',
      category: 'general',
      difficulty: 'advanced',
      type: 'speaking',
      hints: ['Root causes', 'Government policies', 'Education and opportunity'],
      estimatedTime: 120,
    ),
    Question(
      id: 'speak_gen_a_003',
      text: 'What is the relationship between mental health and productivity?',
      category: 'career',
      difficulty: 'advanced',
      type: 'speaking',
      hints: ['Stress management', 'Work environment', 'Prevention and treatment'],
      estimatedTime: 120,
    ),
    Question(
      id: 'speak_gen_a_004',
      text: 'How should governments balance security and privacy in the digital age?',
      category: 'technology',
      difficulty: 'advanced',
      type: 'speaking',
      hints: ['Data collection', 'Surveillance', 'Individual rights', 'Public safety'],
      estimatedTime: 120,
    ),
    Question(
      id: 'speak_gen_a_005',
      text: 'Debate the value and limitations of standardized testing in education.',
      category: 'education',
      difficulty: 'advanced',
      type: 'speaking',
      hints: ['Measurement validity', 'Equity issues', 'Alternative assessments'],
      estimatedTime: 120,
    ),

    // ==================== INTERVIEW QUESTIONS ====================

    // HR - Beginner
    Question(
      id: 'int_hr_b_001',
      text: 'Tell me about yourself and your background.',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Education', 'Work experience', 'Key achievements'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_b_002',
      text: 'Why are you interested in this position?',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Job description match', 'Company values', 'Career goals'],
      estimatedTime: 45,
    ),
    Question(
      id: 'int_hr_b_003',
      text: 'What are your main strengths?',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Technical skills', 'Soft skills', 'Relevant examples'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_b_004',
      text: 'What are your areas for improvement?',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Be honest', 'Show learning mindset', 'Provide examples'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_b_005',
      text: 'Where do you see yourself in 5 years?',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Career growth', 'Skill development', 'Role progression'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_b_006',
      text: 'What salary are you expecting?',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Market research', 'Negotiation skills', 'Be realistic'],
      estimatedTime: 45,
    ),
    Question(
      id: 'int_hr_b_007',
      text: 'How do you handle stress and pressure?',
      category: 'behavioral',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Coping strategies', 'Work-life balance', 'Examples'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_b_008',
      text: 'Tell me about a time you failed and what you learned.',
      category: 'behavioral',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Specific example', 'What went wrong?', 'How did you recover?'],
      estimatedTime: 75,
    ),
    Question(
      id: 'int_hr_b_009',
      text: 'How do you work in a team?',
      category: 'behavioral',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Collaboration', 'Communication', 'Conflict resolution'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_b_010',
      text: 'Do you have any questions for us?',
      category: 'hr',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Company culture', 'Role details', 'Team dynamics'],
      estimatedTime: 45,
    ),

    // HR - Intermediate
    Question(
      id: 'int_hr_i_001',
      text: 'Describe a situation where you had to manage conflicting priorities.',
      category: 'situational',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Time management', 'Problem-solving', 'Communication with stakeholders'],
      estimatedTime: 90,
    ),
    Question(
      id: 'int_hr_i_002',
      text: 'Tell me about a time you showed leadership.',
      category: 'behavioral',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Initiative', 'Decision-making', 'Impact on team'],
      estimatedTime: 90,
    ),
    Question(
      id: 'int_hr_i_003',
      text: 'How do you handle criticism or negative feedback?',
      category: 'behavioral',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Openness to growth', 'Emotional intelligence', 'Action taken'],
      estimatedTime: 75,
    ),
    Question(
      id: 'int_hr_i_004',
      text: 'Tell me about your experience working with difficult colleagues.',
      category: 'behavioral',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Interpersonal skills', 'Problem-solving', 'Positive outcome'],
      estimatedTime: 90,
    ),
    Question(
      id: 'int_hr_i_005',
      text: 'Describe a project you\'re proud of and your role in it.',
      category: 'behavioral',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Responsibility', 'Team contribution', 'Results and impact'],
      estimatedTime: 90,
    ),
    Question(
      id: 'int_hr_i_006',
      text: 'How do you approach continuous learning and professional development?',
      category: 'hr',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Courses and certifications', 'Reading', 'Mentorship'],
      estimatedTime: 75,
    ),
    Question(
      id: 'int_hr_i_007',
      text: 'What motivates you at work?',
      category: 'hr',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Intrinsic motivation', 'Career growth', 'Impact'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_hr_i_008',
      text: 'Tell me about a time you had to adapt to change quickly.',
      category: 'situational',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Flexibility', 'Problem-solving', 'Results'],
      estimatedTime: 90,
    ),

    // HR - Advanced
    Question(
      id: 'int_hr_a_001',
      text: 'Tell me about the most complex project you\'ve managed.',
      category: 'behavioral',
      difficulty: 'advanced',
      type: 'interview',
      hints: ['Scale and scope', 'Challenges faced', 'Strategic decisions'],
      estimatedTime: 120,
    ),
    Question(
      id: 'int_hr_a_002',
      text: 'How would you handle a situation where you disagreed with your manager?',
      category: 'situational',
      difficulty: 'advanced',
      type: 'interview',
      hints: ['Professional communication', 'Respect hierarchy', 'Evidence-based arguments'],
      estimatedTime: 105,
    ),

    // Technical - Beginner
    Question(
      id: 'int_tech_b_001',
      text: 'Explain what Object-Oriented Programming is.',
      category: 'technical',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Classes and objects', 'Encapsulation', 'Inheritance'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_tech_b_002',
      text: 'What is the difference between a list and a dictionary?',
      category: 'technical',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Data structure', 'Access methods', 'Use cases'],
      estimatedTime: 45,
    ),
    Question(
      id: 'int_tech_b_003',
      text: 'Explain the concept of APIs.',
      category: 'technical',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Interface', 'Communication', 'Endpoints'],
      estimatedTime: 60,
    ),
    Question(
      id: 'int_tech_b_004',
      text: 'What is version control and why is it important?',
      category: 'technical',
      difficulty: 'beginner',
      type: 'interview',
      hints: ['Git/GitHub', 'Collaboration', 'History tracking'],
      estimatedTime: 60,
    ),

    // Technical - Intermediate
    Question(
      id: 'int_tech_i_001',
      text: 'Describe the difference between SQL and NoSQL databases.',
      category: 'technical',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['Data structure', 'Scalability', 'Use cases'],
      estimatedTime: 90,
    ),
    Question(
      id: 'int_tech_i_002',
      text: 'Explain how REST APIs work.',
      category: 'technical',
      difficulty: 'intermediate',
      type: 'interview',
      hints: ['HTTP methods', 'Request/Response', 'Status codes'],
      estimatedTime: 75,
    ),

    // ==================== CONVERSATIONAL CHAT ====================

    // General - Beginner
    Question(
      id: 'chat_gen_b_001',
      text: 'What\'s your favorite way to spend free time?',
      category: 'hobbies',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Name activity', 'How long?', 'Why do you enjoy it?'],
      estimatedTime: 45,
    ),
    Question(
      id: 'chat_gen_b_002',
      text: 'How was your day today?',
      category: 'general',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Morning', 'Afternoon', 'Evening activities'],
      estimatedTime: 45,
    ),
    Question(
      id: 'chat_gen_b_003',
      text: 'What\'s your favorite kind of music?',
      category: 'hobbies',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Genre', 'Artists', 'Why you like it'],
      estimatedTime: 45,
    ),
    Question(
      id: 'chat_gen_b_004',
      text: 'What\'s the best meal you\'ve ever had?',
      category: 'food',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Type of food', 'Where was it?', 'Who was with you?'],
      estimatedTime: 60,
    ),
    Question(
      id: 'chat_gen_b_005',
      text: 'Do you prefer coffee or tea? Why?',
      category: 'food',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Choice', 'Table preference', 'When do you drink it?'],
      estimatedTime: 30,
    ),
    Question(
      id: 'chat_gen_b_006',
      text: 'What book or movie do you recommend?',
      category: 'books',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Title', 'What it\'s about', 'Why you recommend it'],
      estimatedTime: 60,
    ),
    Question(
      id: 'chat_gen_b_007',
      text: 'Have you traveled anywhere interesting? Where?',
      category: 'travel',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Destination', 'How long?', 'What did you do there?'],
      estimatedTime: 75,
    ),
    Question(
      id: 'chat_gen_b_008',
      text: 'What\'s something new you learned recently?',
      category: 'education',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['What was it?', 'How did you learn?', 'How will you use it?'],
      estimatedTime: 60,
    ),
    Question(
      id: 'chat_gen_b_009',
      text: 'Do you prefer morning or evening? Why?',
      category: 'general',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Your preference', 'Reason', 'What do you do then?'],
      estimatedTime: 45,
    ),
    Question(
      id: 'chat_gen_b_010',
      text: 'What\'s your favorite app or website?',
      category: 'technology',
      difficulty: 'beginner',
      type: 'conversation',
      hints: ['Name', 'What it does', 'Why you use it'],
      estimatedTime: 45,
    ),

    // General - Intermediate
    Question(
      id: 'chat_gen_i_001',
      text: 'How has social media changed how you stay connected with friends?',
      category: 'technology',
      difficulty: 'intermediate',
      type: 'conversation',
      hints: ['Positive aspects', 'Challenges', 'Personal experience'],
      estimatedTime: 75,
    ),
    Question(
      id: 'chat_gen_i_002',
      text: 'What\'s the most important quality in a friend?',
      category: 'relationships',
      difficulty: 'intermediate',
      type: 'conversation',
      hints: ['Trait', 'Why is it important?', 'Example from your life'],
      estimatedTime: 60,
    ),
    Question(
      id: 'chat_gen_i_003',
      text: 'How do you think artificial intelligence will change our lives?',
      category: 'technology',
      difficulty: 'intermediate',
      type: 'conversation',
      hints: ['Positive changes', 'Concerns', 'Personal opinion'],
      estimatedTime: 90,
    ),
    Question(
      id: 'chat_gen_i_004',
      text: 'What\'s one habit you\'d like to change or develop?',
      category: 'general',
      difficulty: 'intermediate',
      type: 'conversation',
      hints: ['Current situation', 'Why you want to change', 'How you\'ll do it'],
      estimatedTime: 75,
    ),
    Question(
      id: 'chat_gen_i_005',
      text: 'How does exercise benefit your mental health?',
      category: 'general',
      difficulty: 'intermediate',
      type: 'conversation',
      hints: ['Physical activity', 'Mental benefits', 'Personal experience'],
      estimatedTime: 60,
    ),
  ];
}
