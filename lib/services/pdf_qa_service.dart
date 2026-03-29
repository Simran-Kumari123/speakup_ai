import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service to extract text from PDFs and generate Q&A using Gemini API
class PdfQaService {
  static const Duration _timeout = Duration(seconds: 30);
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// Extract text from PDF bytes (works cross-platform)
  static String extractTextFromBytes(Uint8List bytes) {
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

  /// Generate Q&A pairs from extracted text using Gemini API
  static Future<List<Map<String, String>>> generateQA(String pdfText) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('API key not set. Add GEMINI_API_KEY to .env file.');
    }

    // Truncate text if too long (Gemini has token limits)
    final truncated = pdfText.length > 8000 ? pdfText.substring(0, 8000) : pdfText;

    final uri = Uri.parse('$_geminiBaseUrl?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {
              'text': '''
Read the following text extracted from a PDF document and generate 8-10 meaningful questions and detailed answers based on the content.

Return a JSON array of objects, each with "question" and "answer" keys. The questions should test understanding of key concepts.

Example format:
[
  {"question": "What is ...?", "answer": "It is ..."},
  {"question": "How does ...?", "answer": "It works by ..."}
]

Here is the PDF text:

$truncated
'''
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.5,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      },
    });

    int maxRetries = 3;
    Duration baseDelay = const Duration(seconds: 4);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(_timeout);

        if (response.statusCode == 429 && attempt < maxRetries) {
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          final jitter = DateTime.now().millisecond % 500;
          await Future.delayed(Duration(milliseconds: delayMs + jitter));
          continue;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final rawText =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '[]';

          final List<dynamic> qaList = jsonDecode(rawText);
          return qaList.map<Map<String, String>>((item) {
            return {
              'question': (item['question'] ?? '').toString(),
              'answer': (item['answer'] ?? '').toString(),
            };
          }).toList();
        }

        if (attempt == maxRetries) {
          throw Exception('Gemini API error: ${response.statusCode}');
        }
      } on TimeoutException {
        if (attempt < maxRetries) {
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        throw Exception('Request timed out. The PDF might be too large.');
      } catch (e) {
        if (e is Exception && e.toString().contains('Exception:') && !e.toString().contains('Too Many Requests') && !e.toString().contains('Network')) {
            rethrow;
        }
        if (attempt < maxRetries) {
          final delayMs = baseDelay.inMilliseconds * (1 << attempt);
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }
        throw Exception('Network error: $e');
      }
    }
    throw Exception('Failed to generate Q&A');
  }
}
