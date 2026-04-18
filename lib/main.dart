import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'services/app_state.dart';
import 'services/speech_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Prevent GoogleFonts from throwing network errors or Noto complaints when fetching
  GoogleFonts.config.allowRuntimeFetching = true;

  // 1. Lock to portrait (Mobile only)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  // 2. Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: AppTheme.earthyBg,
  ));

  bool firebaseInitialized = false;
  // 3. Init Firebase with correct options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Google Sign-In (v7.x requirement)
    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint('⚠️ Google Sign-In Initialization Failed: $e');
    }
    
    // Pass all uncaught errors from the framework to Crashlytics (Mobile only).
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    }
    
    // Enable Analytics collection
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    
    firebaseInitialized = true;
    debugPrint('✅ Firebase Initialized (Crashlytics & Analytics included)');
    
    // 3.5. Quick Backend Connection Check (Firestore)
    _checkBackendConnection(); 
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

  // 5. Initialize state and start basic loading
  final state = AppState();
  // load() is now non-blocking for cloud data but awaits local prefs
  await state.load();

  // refreshDailyWord() is now moved to RootController to avoid blocking startup

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider(create: (_) => SpeechService()),
      ],
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
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return _GlobalErrorScreen(details: details);
        };
        return child!;
      },
      home: const RootController(),
    );
  }
}

class _GlobalErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const _GlobalErrorScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.earthyBg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🍵', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Something went quiet...',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.earthyText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our AI coach is taking a short break. Let\'s try restarting the session.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: AppTheme.earthyText.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => SystemNavigator.pop(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Restart App'),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Health Check ─────────────────────────────────────────────────────────────
void _checkBackendConnection() {
  FirebaseFirestore.instance
      .collection('health')
      .doc('check')
      .get()
      .timeout(const Duration(seconds: 5))
      .then((doc) {
    debugPrint('📡 Backend Status: ONLINE');
  }).catchError((e) {
    debugPrint('📡 Backend Status: OFFLINE or TIMEOUT ($e)');
  });
}

class RootController extends StatefulWidget {
  const RootController({super.key});

  @override
  State<RootController> createState() => _RootControllerState();
}

class _RootControllerState extends State<RootController> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final state = context.read<AppState>();
    
    // Trigger background tasks that don't need to block UI
    unawaited(state.refreshDailyWord());
    
    // Force splash for at least 2 seconds for branding
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _showSplash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return const _SplashScreen();

    final state = context.watch<AppState>();
    
    // Show HomeScreen if user is logged in and has seen onboarding
    if (state.isLoggedIn && state.hasSeenOnboarding) {
      return const HomeScreen();
    }
    
    return const OnboardingScreen();
  }
}

// ── Splash Screen ─────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.earthyBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                color: AppTheme.earthyCard.withOpacity(0.3),
                border: Border.all(color: AppTheme.earthyAccent.withOpacity(0.2), width: 2),
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'SpeakUp AI',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.earthyText,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Consistency is your superpower',
              style: GoogleFonts.dmSans(
                color: AppTheme.earthyText.withOpacity(0.5),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              color: AppTheme.earthyAccent,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}