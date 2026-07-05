import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/simulation/partner_repository.dart';
import 'package:app/screens/partners_screen.dart';

class MockPartnerRepo extends PartnerRepository {
  bool getPartnersCalled = false;

  @override
  Future<List<Partner>> getPartners({required String token}) async {
    getPartnersCalled = true;
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
      const Partner(
        id: 'p2',
        name: 'Ana Correspondente',
        email: 'ana@example.com',
        phone: '21988888888',
        company: 'Crédito Fácil',
        photoUrl: '',
        isActive: true,
      ),
    ];
  }
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('PartnersScreen Tests', () {
    testWidgets('Renders partners list with contact buttons', (WidgetTester tester) async {
      final mockRepo = MockPartnerRepo();
      final authProvider = AuthProvider(prefs: prefs);
      await authProvider.loginWithGoogle();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: PartnersScreen(repository: mockRepo),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(mockRepo.getPartnersCalled, isTrue);
      expect(find.text('Carlos Corretor'), findsOneWidget);
      expect(find.text('Imobiliária Sul'), findsOneWidget);
      expect(find.text('Ana Correspondente'), findsOneWidget);
      expect(find.text('Crédito Fácil'), findsOneWidget);

      expect(find.byKey(const Key('whatsapp_p1')), findsOneWidget);
      expect(find.byKey(const Key('phone_p1')), findsOneWidget);
      expect(find.byKey(const Key('email_p1')), findsOneWidget);
    });
  });
}
