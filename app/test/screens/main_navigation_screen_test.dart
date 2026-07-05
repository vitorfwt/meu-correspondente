import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/screens/main_navigation_screen.dart';
import 'package:app/screens/simulator_form_screen.dart';
import 'package:app/main.dart';

void main() {
  group('MainNavigationScreen Tests', () {
    late SharedPreferences prefs;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock_token',
        'auth_user_id': 'user_123',
        'auth_user_name': 'Carlos Souza',
        'auth_user_email': 'carlos@example.com',
      });
      prefs = await SharedPreferences.getInstance();
      authProvider = AuthProvider(prefs: prefs);
    });

    Widget buildTestWidget({int initialIndex = 1}) {
      return AuthProviderScope(
        notifier: authProvider,
        child: MaterialApp(
          home: MainNavigationScreen(initialIndex: initialIndex),
        ),
      );
    }

    testWidgets('Renders BottomNavigationBar with 4 tabs and loads Simulation tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Check BottomNavigationBar exists
      expect(find.byKey(const Key('bottom_navigation_bar')), findsOneWidget);

      // Verify active tab items
      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Simulações'), findsOneWidget);
      expect(find.text('Parceiros'), findsOneWidget); // only 1 visible (bottom bar item) when not on partners tab
      expect(find.text('Perfil'), findsOneWidget);

      // SimulatorFormScreen should be active and shown by default (initialIndex = 1)
      expect(find.byType(SimulatorFormScreen), findsOneWidget);
      expect(find.text('Faça uma Simulação'), findsOneWidget);
    });

    testWidgets('Navega para a aba Início e mostra o placeholder correspondente', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Home tab using its label text (avoids icon ambiguity with IndexedStack)
      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      // Verify HomeScreenPlaceholder is shown
      expect(find.text('Olá, Carlos Souza'), findsOneWidget);
      expect(find.text('Bem-vindo de volta ao Meu Correspondente!'), findsOneWidget);
      expect(find.text('Tudo pronto para simular?'), findsOneWidget);
    });

    testWidgets('Navega para a aba Parceiros e mostra o placeholder correspondente', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Partners tab (index 2)
      await tester.tap(find.byIcon(Icons.business_outlined));
      await tester.pumpAndSettle();

      // Verify PartnersScreenPlaceholder is shown
      expect(find.text('Parceiros'), findsNWidgets(2)); // bottom bar label + page header
      expect(find.text('Novas parcerias em breve'), findsOneWidget);
    });

    testWidgets('Navega para a aba Perfil, mostra info do usuário e botões de ação', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Profile tab (index 3)
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // Verify ProfileScreen is shown
      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Carlos Souza'), findsOneWidget);
      expect(find.text('carlos@example.com'), findsOneWidget);
      expect(find.byKey(const Key('profile_styleguide_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
    });

    testWidgets('Perfil: Abre a tela do Styleguide e consegue voltar', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 3));
      await tester.pumpAndSettle();

      // Tap Styleguide button
      await tester.tap(find.byKey(const Key('profile_styleguide_button')));
      
      // In order to push the route in tests, we need a pump to trigger the navigation,
      // and then another pump with duration to run the routing transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should now be on StyleguideScreen
      expect(find.byType(StyleguideScreen), findsOneWidget);
      expect(find.text('Styleguide & Design System'), findsOneWidget);

      // Trigger logout button in Styleguide to verify auth provider interaction
      // (Styleguide has a logout button at the top)
      await tester.tap(find.byKey(const Key('logout_button')));
      
      // Use pump sequence to handle navigation back clean and avoid timeouts due to infinite animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(authProvider.isAuthenticated, isFalse);
    });
  });
}
