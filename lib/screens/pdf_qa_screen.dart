import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/pdf_qa_service.dart';
import '../services/ai_feedback_service.dart';
import '../theme/app_theme.dart';

class PdfQaScreen extends StatefulWidget {
  const PdfQaScreen({super.key});
  @override
  State<PdfQaScreen> createState() => _PdfQaScreenState();
}

class _PdfQaScreenState extends State<PdfQaScreen> {
  bool _loading = false;
  String? _fileName;
  String? _errorMessage;
  List<Map<String, String>> _qaList = [];

  Future<void> _pickAndProcess() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null && file.path == null) {
        setState(() => _errorMessage = 'Could not read the selected file.');
        return;
      }

      setState(() {
        _loading = true;
        _fileName = file.name;
        _errorMessage = null;
        _qaList = [];
      });

      // Extract text from PDF
      if (file.bytes == null) {
        setState(() {
          _errorMessage = 'Could not read file bytes. Try selecting the file again.';
          _loading = false;
        });
        return;
      }
      final pdfText = PdfQaService.extractTextFromBytes(file.bytes!);

      // Generate Q&A from extracted text
      final qaList = await PdfQaService.generateQA(pdfText);
      
      if (!mounted) return;
      setState(() {
        _qaList = qaList;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PDF Q&A Generator 📄'),
      ),
      body: _loading
          ? _buildLoading()
          : _qaList.isEmpty
              ? _buildUploadPrompt()
              : _buildQAList(),
    );
  }

  Widget _buildUploadPrompt() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withOpacity(0.1),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 28),
            Text(
              'Upload a PDF Document',
              style: GoogleFonts.dmSans(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AI will extract text from your PDF and generate\nmeaningful questions & answers for you to study.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _pickAndProcess,
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: const Text('Choose PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.dmSans(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withOpacity(0.12),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing PDF...',
            style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Extracting text and generating Q&A',
            style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_rounded, color: AppTheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(_fileName!, style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQAList() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withOpacity(0.5),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05), width: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.description_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'Document',
                      style: GoogleFonts.dmSans(color: Theme.of(context).textTheme.titleSmall?.color, fontSize: 14, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_qaList.length} questions generated',
                      style: GoogleFonts.dmSans(color: AppTheme.primary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _pickAndProcess,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('New PDF'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),

        // Q&A List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _qaList.length,
            itemBuilder: (_, i) => _QACard(
              index: i + 1,
              question: _qaList[i]['question'] ?? '',
              answer: _qaList[i]['answer'] ?? '',
            ).animate().fadeIn(delay: (i * 80).ms, duration: 300.ms).slideY(begin: 0.1),
          ),
        ),
      ],
    );
  }
}

class _QACard extends StatefulWidget {
  final int index;
  final String question;
  final String answer;

  const _QACard({
    required this.index,
    required this.question,
    required this.answer,
  });

  @override
  State<_QACard> createState() => _QACardState();
}

class _QACardState extends State<_QACard> {
  bool _showAnswer = false;
  bool _practicing = false;
  final _ctrl = TextEditingController();
  bool _evaluating = false;
  Map<String, dynamic>? _result;

  Future<void> _evaluateAnswer() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _evaluating = true);
    try {
      final res = await AIFeedbackService.evaluateAnswer(
        question: widget.question,
        answer: _ctrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = res;
        _evaluating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _evaluating = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primary.withOpacity(0.15),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.index}',
                          style: GoogleFonts.dmSans(
                            color: AppTheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: GoogleFonts.dmSans(
                          color: theme.textTheme.titleSmall?.color,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _showAnswer = !_showAnswer),
                        icon: Icon(
                          _showAnswer ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 16,
                        ),
                        label: Text(_showAnswer ? 'Hide Answer' : 'Show Answer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.earthyAccent,
                          side: BorderSide(color: AppTheme.earthyAccent.withOpacity(0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _practicing = !_practicing;
                          _result = null;
                          _ctrl.clear();
                        }),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: Text(_practicing ? 'Cancel' : 'Practice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Answer section
          if (_showAnswer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📖 Answer', style: GoogleFonts.dmSans(
                      color: AppTheme.earthyAccent, fontSize: 12, fontWeight: FontWeight.w900,
                    )),
                    const SizedBox(height: 8),
                    Text(widget.answer, style: GoogleFonts.dmSans(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500,
                    )),
                  ],
                ),
              ),
            ),

          // Practice section
          if (_practicing)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  TextField(
                    controller: _ctrl,
                    maxLines: 4,
                    style: theme.textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Type your answer here...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _evaluating ? null : _evaluateAnswer,
                      child: _evaluating
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimary),
                            )
                          : const Text('Get AI Feedback 🤖'),
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🤖 AI Evaluation', style: GoogleFonts.dmSans(
                                color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13,
                              )),
                              Text(
                                '${(_result!['score'] as double).toStringAsFixed(1)}/10',
                                style: GoogleFonts.dmSans(
                                  color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _result!['feedback'] as String,
                            style: GoogleFonts.dmSans(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '+${_result!['xp']} XP ⭐',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
