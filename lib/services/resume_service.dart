import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'ai_feedback_service.dart';

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
        throw Exception('No text found in PDF. The PDF may contain only images.');
      }
      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Analyze resume using AI
  static Future<Map<String, dynamic>> analyze(String resumeText) async {
    return AIFeedbackService.analyzeResume(resumeText: resumeText);
  }

  /// Generate interview questions based on resume
  static Future<List<Map<String, dynamic>>> generateQuestions({
    required String skills,
    required String experienceLevel,
    required String category,
    int count = 5,
  }) async {
    return AIFeedbackService.generateResumeQuestions(
      skills: skills,
      experienceLevel: experienceLevel,
      category: category,
      count: count,
    );
  }
}
