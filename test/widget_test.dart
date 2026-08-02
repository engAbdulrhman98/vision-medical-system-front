import 'package:flutter_test/flutter_test.dart';
import 'package:vision_medical_system_app/main.dart';
import 'package:vision_medical_system_app/screens/login_screen.dart';

void main() {
  testWidgets('App renders login screen by default', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for route transition
    await tester.pumpAndSettle();

    // Verify LoginScreen is in the widget tree
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
