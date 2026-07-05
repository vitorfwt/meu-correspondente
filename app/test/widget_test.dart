import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/widgets/custom_button.dart';

void main() {
  testWidgets('Styleguide renders successfully with custom buttons when logged in', (WidgetTester tester) async {
    // Set up SharedPreferences mock with a fake token so that it goes straight to StyleguideScreen
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake_token',
      'auth_user_name': 'João Silva',
    });
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Verify that the title is rendered.
    expect(find.text('Olá, João Silva'), findsOneWidget);
    expect(find.text('Styleguide & Design System'), findsOneWidget);

    // Verify that there are CustomButtons on screen.
    expect(find.byType(CustomButton), findsAtLeastNWidgets(1));
  });
}
