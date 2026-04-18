import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'ai_feedback_service.dart';
import '../models/models.dart';

/// Service for PDF resume analysis
class ResumeService {
  /// Extract text from PDF bytes
  static String extractText(Uint8List bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final StringBuffer textBuffer = StringBuffer();

      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i);
        textBuffer.writeln(pageText);
      }

      document.dispose();

      final text = textBuffer.toString().trim();
      if (text.isEmpty) {
        throw Exception('We couldn\'t find any readable text in this PDF. Please ensure it\'s not a scanned image.');
      }
      return text;
    } catch (e) {
      if (e.toString().contains('scanned image')) rethrow;
      throw Exception('Failed to read PDF. Please ensure the file is not corrupted.');
    }
  }

  /// Heuristic check if text looks like a resume
  static bool isLikelyResume(String text) {
    final t = text.toLowerCase();
    final indicators = [
      'experience', 'work', 'education', 'skills', 'summary', 
      'projects', 'contact', 'objective', 'professional', 'curriculum vitae'
    ];
    int score = 0;
    for (var ind in indicators) {
      if (t.contains(ind)) score++;
    }
    // At least 3 standard resume sections usually exist
    return score >= 3;
  }

  /// Analyze resume using AI
  static Future<Map<String, dynamic>> analyze(String resumeText) async {
    return AIFeedbackService.analyzeResume(resumeText: resumeText);
  }

  /// Generate interview questions based on resume
  static Future<List<Question>> generateQuestions({
    String? resumeText,
    String? skills,
    String? experienceLevel,
    String? category,
    int count = 5,
  }) async {
    return AIFeedbackService.generateResumeQuestions(
      resumeText: resumeText,
      skills: skills,
      experienceLevel: experienceLevel,
      category: category,
      count: count,
    );
  }
}
