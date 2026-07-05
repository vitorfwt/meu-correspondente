import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/main.dart';
import 'package:app/screens/simulator_form_screen.dart';
import 'package:app/screens/main_navigation_screen.dart';

void main() {
  testWidgets('App renders MainNavigationScreen when logged in', (WidgetTester tester) async {
    // Set up SharedPreferences mock with a fake token so that it goes straight to MainNavigationScreen
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake_token',
      'auth_user_name': 'João Silva',
    });
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pumpAndSettle();

    // Verify that the MainNavigationScreen and SimulatorFormScreen are rendered.
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.byType(SimulatorFormScreen), findsOneWidget);
    expect(find.text('Faça uma Simulação'), findsOneWidget);
  });
}
