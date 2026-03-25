import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'ai_feedback_service.dart';

class GDService {
  static Future<List<GDParticipant>> generateParticipants(String topic) async {
    final prompt = '''
    Topic for Group Discussion: "$topic"
    Generate exactly 4 diverse virtual participants for this GD.
    Each should have a name, a professional or student role, a specific opinion (Support, Oppose, or Neutral), an avatar emoji, and a personality trait (e.g., Analytical, Aggressive, Calm, Encouraging, Evidence-based).
    Ensure a mix of opinions (at least one Support, one Oppose, and one Neutral).
    Respond with ONLY the JSON in this format:
    {
      "participants": [
        {
          "name": "string",
          "role": "string",
          "opinion": "Support" | "Oppose" | "Neutral",
          "avatarEmoji": "string",
          "personality": "string"
        }
      ]
    }
    ''';

    try {
      final response = await AIFeedbackService.callGeminiRaw(prompt);
      final cleanJson = _extractJson(response);
      final data = jsonDecode(cleanJson);
      return (data['participants'] as List).map((p) => GDParticipant.fromJson(p)).toList();
    } catch (e) {
      debugPrint('⚠️ GD Participant Gen Error: $e');
      return _fallbackParticipants();
    }
  }

  static Future<ChatMessage> getParticipantResponse({
    required String topic,
    required List<GDParticipant> participants,
    required List<ChatMessage> history,
    required GDParticipant speakingParticipant,
  }) async {
    final otherParticipants = participants.where((p) => p.name != speakingParticipant.name).toList();
    final otherStats = otherParticipants.map((p) => '${p.name} (${p.role}, ${p.opinion} stance)').join(', ');
    
    final historyText = history.map((m) {
      final name = m.sender == MsgSender.user ? 'User' : (m.participantName ?? 'AI');
      return '$name: ${m.text}';
    }).join('\n');

    final prompt = '''
    CONVERSATION CONTEXT:
    Topic: "$topic"
    Other Participants: $otherStats
    Current Speaker Profile:
    - Name: ${speakingParticipant.name}
    - Role: ${speakingParticipant.role}
    - Stance: ${speakingParticipant.opinion} (IMPORTANT: Stay true to this)
    - Personality: ${speakingParticipant.personality}
    
    DISCUSSION HISTORY:
    $historyText
    
    ROLEPLAY TASK:
    Provide the next contribution as ${speakingParticipant.name}. 
    - MANDATORY: Begin by briefly acknowledging or rebutting the point made by the last speaker (User or AI).
    - Address other participants by name if you disagree or build on their points.
    - Use natural fillers like "I see your point...", "Building on that...", "I strongly disagree with Rahul because...".
    - Express your opinion clearly based on your "${speakingParticipant.opinion}" stance.
    - Keep it concise (max 2-3 impactful sentences).
    - Avoid being generic; be specific to the topic and history.
    
    Respond with ONLY the JSON in this format:
    {
      "response": "string"
    }
    ''';

    try {
      final response = await AIFeedbackService.callGeminiRaw(prompt);
      final cleanJson = _extractJson(response);
      final data = jsonDecode(cleanJson);
      return ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: data['response'] ?? '...',
        sender: MsgSender.participant,
        participantName: speakingParticipant.name,
      );
    } catch (e) {
      debugPrint('⚠️ GD Participant Response Error: $e');
      return ChatMessage(
        id: DateTime.now().toIso8601String(),
        text: "I agree with the previous points and would like to add that we should consider the practical implications as well.",
        sender: MsgSender.participant,
        participantName: speakingParticipant.name,
      );
    }
  }

  static String _extractJson(String raw) {
    if (raw.contains('```json')) {
      final start = raw.indexOf('```json') + 7;
      final end = raw.lastIndexOf('```');
      return raw.substring(start, end).trim();
    }
    return raw.trim();
  }

  static List<GDParticipant> _fallbackParticipants() => [
    GDParticipant(name: 'Rahul', role: 'Engineering Student', opinion: 'Support', avatarEmoji: '👨‍💻', personality: 'Analytical'),
    GDParticipant(name: 'Priya', role: 'MBA Aspirant', opinion: 'Oppose', avatarEmoji: '👩‍💼', personality: 'Aggressive'),
    GDParticipant(name: 'Anish', role: 'Software Developer', opinion: 'Neutral', avatarEmoji: '👨‍🔬', personality: 'Calm'),
    GDParticipant(name: 'Sneha', role: 'Design Student', opinion: 'Support', avatarEmoji: '👩‍🎨', personality: 'Creative'),
  ];
}
