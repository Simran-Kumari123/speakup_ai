import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VoiceWave extends StatefulWidget {
  final double soundLevel;
  final bool isListening;

  const VoiceWave({
    super.key,
    required this.soundLevel,
    required this.isListening,
  });

  @override
  State<VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<VoiceWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _amplitudes = List.generate(15, (index) => 0.0);
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Normalize sound level (usually -160 to 0 or 0 to 10 depending on implementation)
    // Here we assume a normalized input or we normalize it ourselves
    double normalizedLevel = (widget.soundLevel + 40).clamp(0, 100) / 100;
    if (!widget.isListening) normalizedLevel = 0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (index) {
              // Create some organic movement
              double targetHeight = 5 + (normalizedLevel * 40 * (_random.nextDouble() * 0.5 + 0.5));
              if (!widget.isListening) targetHeight = 4;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: targetHeight,
                decoration: BoxDecoration(
                  color: widget.isListening 
                      ? AppTheme.primary.withValues(alpha: 0.8 - (index.toDouble() - 7).abs() * 0.05)
                      : AppTheme.earthyText.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: widget.isListening ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    )
                  ] : [],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
