import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:speakup_ai/main.dart';
import 'package:speakup_ai/services/app_state.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create a mock state
    final state = AppState();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: const SpeakUpApp(firebaseEnabled: false),
      ),
    );

    // Verify that the splash screen or initial onboarding text appears
    // (Adjust this based on what actually shows up first in your UI)
    expect(find.text('SpeakUp'), findsOneWidget);
  });
}
