import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/screens/main_navigation_screen.dart';
import 'package:app/screens/simulator_form_screen.dart';
import 'package:app/main.dart';
import 'package:app/simulation/indicator_repository.dart';
import 'package:app/simulation/partner_repository.dart';

class MockIndicatorRepo extends IndicatorRepository {
  @override
  Future<List<MacroeconomicIndicator>> getIndicators({required String token}) async {
    return [
      MacroeconomicIndicator(
        id: '1',
        name: 'SELIC',
        value: 0.105,
        updatedAt: DateTime(2026, 7, 5),
      ),
    ];
  }
}

class MockPartnerRepo extends PartnerRepository {
  @override
  Future<List<Partner>> getPartners({required String token}) async {
    return [
      const Partner(
        id: 'p1',
        name: 'Carlos Corretor',
        email: 'carlos@example.com',
        phone: '11999999999',
        company: 'Imobiliária Sul',
        photoUrl: '',
        isActive: true,
      ),
    ];
  }
}

void main() {
  group('MainNavigationScreen Tests', () {
    late SharedPreferences prefs;
    late AuthProvider authProvider;
    final mockIndicatorRepo = MockIndicatorRepo();
    final mockPartnerRepo = MockPartnerRepo();

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
          home: MainNavigationScreen(
            initialIndex: initialIndex,
            indicatorRepository: mockIndicatorRepo,
            partnerRepository: mockPartnerRepo,
          ),
        ),
      );
    }

    testWidgets('Renders BottomNavigationBar with 4 tabs and loads Simulation tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottom_navigation_bar')), findsOneWidget);

      expect(find.text('Início'), findsOneWidget);
      expect(find.text('Simulações'), findsOneWidget);
      expect(find.text('Parceiros'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);

      expect(find.byType(SimulatorFormScreen), findsOneWidget);
      expect(find.text('Faça uma Simulação'), findsOneWidget);
    });

    testWidgets('Navega para a aba Início e mostra o placeholder correspondente', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Início'));
      await tester.pumpAndSettle();

      expect(find.text('Olá, Carlos Souza'), findsOneWidget);
      expect(find.text('Bem-vindo ao Meu Correspondente!'), findsOneWidget);
      expect(find.text('Nova Simulação'), findsOneWidget);
    });

    testWidgets('Navega para a aba Parceiros e mostra o placeholder correspondente', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.business_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Parceiros'), findsNWidgets(2));
      expect(find.text('Carlos Corretor'), findsOneWidget);
    });

    testWidgets('Navega para a aba Perfil, mostra info do usuário e botões de ação', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      expect(find.text('Meu Perfil'), findsOneWidget);
      expect(find.text('Carlos Souza'), findsOneWidget);
      expect(find.text('carlos@example.com'), findsOneWidget);
      expect(find.byKey(const Key('profile_styleguide_button')), findsOneWidget);
      expect(find.byKey(const Key('profile_logout_button')), findsOneWidget);
    });

    testWidgets('Perfil: Abre a tela do Styleguide e consegue voltar', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget(initialIndex: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_styleguide_button')));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(StyleguideScreen), findsOneWidget);
      expect(find.text('Styleguide & Design System'), findsOneWidget);

      await tester.tap(find.byKey(const Key('logout_button')));
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(authProvider.isAuthenticated, isFalse);
    });
  });
}
