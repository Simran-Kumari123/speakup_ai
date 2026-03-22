import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Wrap any screen with this to auto-show an offline banner
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});
  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  bool _isOnline = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  Future<void> _check() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted && online != _isOnline) setState(() => _isOnline = online);
    } catch (_) {
      if (mounted && _isOnline) setState(() => _isOnline = false);
    }
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isOnline ? 0 : 40,
      color: AppTheme.danger,
      child: _isOnline ? null : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text('No internet — AI feedback unavailable',
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
    Expanded(child: widget.child),
  ]);
}
