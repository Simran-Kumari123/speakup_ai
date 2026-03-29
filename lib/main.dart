import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // 1. Lock to portrait (Mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // 2. Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.darkBg,
  ));

  bool firebaseInitialized = false;
  // 3. Init Firebase with correct options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint('✅ Firebase Initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase Initialization Failed: $e');
  }

  // 4. Init notifications (Mobile only)
  if (!kIsWeb) {
    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('⚠️ Notification Init Failed: $e');
    }
  }

  // 5. Load saved state (Preferences, XP, etc.)
  final state = AppState();
  await state.load();

  // 6. Re-schedule reminder if previously ON (Mobile only)
  if (!kIsWeb && state.notificationsOn) {
    try {
      final parts = state.reminderTime.split(':');
      if (parts.length == 2) {
        await NotificationService.scheduleDailyReminder(
          hour:     int.tryParse(parts[0]) ?? 8,
          minute:   int.tryParse(parts[1]) ?? 0,
          userName: state.profile.name.isNotEmpty
              ? state.profile.name.split(' ').first
              : 'there',
        );
      }
    } catch (_) {}
  }

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: SpeakUpApp(firebaseEnabled: firebaseInitialized),
    ),
  );
}

class SpeakUpApp extends StatelessWidget {
  final bool firebaseEnabled;
  const SpeakUpApp({super.key, required this.firebaseEnabled});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Coach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      // Decides initial screen based on Firebase Auth state
      home: !firebaseEnabled
          ? const OnboardingScreen()
          : StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashScreen();
          }
          // If user is logged in, show Home, otherwise show Onboarding
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}

// ── Splash Screen (shown during initial auth check) ──────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                ),
              ),
              child: const Center(
                child: Text('🎤', style: TextStyle(fontSize: 40)),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI Chat Coach',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
