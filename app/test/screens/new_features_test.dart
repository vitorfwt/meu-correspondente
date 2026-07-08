import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/auth/auth_repository.dart';
import 'package:app/simulation/indicator_repository.dart';
import 'package:app/screens/creci_setup_screen.dart';
import 'package:app/screens/home_screen.dart';
import 'package:app/screens/simulation_result_screen.dart';
import 'package:app/simulation/simulation_repository.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MockAuthRepo extends AuthRepository {
  bool updateProfileCalled = false;
  String? lastCreci;
  String? lastUf;

  @override
  Future<(User, String)> loginWithGoogle() async {
    return (
      const User(id: 'google_123', name: 'João Silva', email: 'joao.silva@example.com', role: 'client'),
      'mock_google_token'
    );
  }

  @override
  Future<(User, String)> loginWithApple() async {
    return (
      const User(id: 'apple_123', name: 'João Silva', email: 'joao.silva@example.com', role: 'broker'),
      'mock_apple_token'
    );
  }

  @override
  Future<User> updateProfile(String token, String creci, String uf) async {
    updateProfileCalled = true;
    lastCreci = creci;
    lastUf = uf;
    return User(
      id: 'apple_123',
      name: 'João Silva',
      email: 'joao.silva@example.com',
      role: 'broker',
      creci: creci,
      uf: uf,
    );
  }
}

class MockIndicatorRepo extends IndicatorRepository {
  final List<MacroeconomicIndicator>? customIndicators;
  MockIndicatorRepo({this.customIndicators});

  @override
  Future<List<MacroeconomicIndicator>> getIndicators({required String token}) async {
    if (customIndicators != null) {
      return customIndicators!;
    }
    return [
      MacroeconomicIndicator(
        id: '1',
        name: 'SELIC',
        value: 0.105,
        updatedAt: DateTime(2026, 7, 5),
      ),
      MacroeconomicIndicator(
        id: '2',
        name: 'IPCA',
        value: 0.045,
        updatedAt: DateTime(2026, 7, 5),
      ),
      MacroeconomicIndicator(
        id: '3',
        name: 'TR',
        value: 0.0012,
        updatedAt: DateTime(2026, 7, 5),
      ),
      MacroeconomicIndicator(
        id: '4',
        name: 'POUPANCA',
        value: 0.0617,
        updatedAt: DateTime(2026, 7, 5),
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

  group('CreciSetupScreen Tests', () {
    testWidgets('Validation error if CRECI is empty, too short, or invalid', (WidgetTester tester) async {
      final mockRepo = MockAuthRepo();
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);
      
      await authProvider.loginWithApple();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: const CreciSetupScreen(),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('creci_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Por favor, informe seu CRECI.'), findsOneWidget);
      expect(find.text('Por favor, selecione a UF.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('creci_field')), '123');
      await tester.tap(find.byKey(const Key('creci_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('O CRECI deve ter entre 4 e 8 dígitos.'), findsOneWidget);
    });

    testWidgets('Valid CRECI and UF submission calls saveProfile', (WidgetTester tester) async {
      final mockRepo = MockAuthRepo();
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);
      
      await authProvider.loginWithApple();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: const CreciSetupScreen(),
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('creci_field')), '123456');
      
      await tester.tap(find.byKey(const Key('creci_uf_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('CE').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('creci_submit_button')));
      await tester.pumpAndSettle();

      expect(mockRepo.updateProfileCalled, isTrue);
      expect(mockRepo.lastCreci, '123456');
      expect(mockRepo.lastUf, 'CE');
    });
  });

  group('HomeScreen Tests', () {
    testWidgets('Renders Broker Badge and Client Badge conditionally', (WidgetTester tester) async {
      final mockRepo = MockAuthRepo();
      final mockIndicatorRepo = MockIndicatorRepo();
      
      final authProviderClient = AuthProvider(repository: mockRepo, prefs: prefs);
      await authProviderClient.loginWithGoogle();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProviderClient,
            child: HomeScreen(
              onNavigateToSimulations: () {},
              repository: mockIndicatorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('client_badge')), findsOneWidget);
      expect(find.byKey(const Key('broker_badge')), findsNothing);

      final authProviderBroker = AuthProvider(repository: mockRepo, prefs: prefs);
      await authProviderBroker.loginWithApple();
      await authProviderBroker.saveProfile(creci: '77777', uf: 'RJ');

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProviderBroker,
            child: HomeScreen(
              onNavigateToSimulations: () {},
              repository: mockIndicatorRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('broker_badge')), findsOneWidget);
      expect(find.byKey(const Key('client_badge')), findsNothing);
      expect(find.textContaining('Corretor • CRECI: 77777-RJ'), findsOneWidget);
    });

    testWidgets('Renders Macroeconomic Indicators correctly', (WidgetTester tester) async {
      final mockRepo = MockAuthRepo();
      final mockIndicatorRepo = MockIndicatorRepo();
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);
      await authProvider.loginWithGoogle();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: HomeScreen(
              onNavigateToSimulations: () {},
              repository: mockIndicatorRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SELIC'), findsOneWidget);
      expect(find.text('10,50%'), findsOneWidget);
      expect(find.text('IPCA'), findsOneWidget);
      expect(find.text('4,50%'), findsOneWidget);
      expect(find.text('TR'), findsOneWidget);
      expect(find.text('0,1200%'), findsOneWidget);
      expect(find.text('Poupança'), findsOneWidget);
      expect(find.text('6,17%'), findsOneWidget);
    });

    testWidgets('Renders COPOM card with "Faltam 10 dias" when COPOM indicator is 10 days in the future', (WidgetTester tester) async {
      final mockRepo = MockAuthRepo();
      final targetDate = DateTime.now().add(const Duration(days: 10, minutes: 5));
      final copomIndicator = MacroeconomicIndicator(
        id: '5',
        name: 'COPOM',
        value: targetDate.millisecondsSinceEpoch.toDouble(),
        updatedAt: DateTime.now(),
      );

      final mockIndicatorRepo = MockIndicatorRepo(
        customIndicators: [
          copomIndicator,
        ],
      );
      
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);
      await authProvider.loginWithGoogle();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: HomeScreen(
              onNavigateToSimulations: () {},
              repository: mockIndicatorRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copom_card')), findsOneWidget);
      expect(find.text('Próxima reunião do COPOM'), findsOneWidget);
      expect(find.textContaining('Faltam 10 dias'), findsOneWidget);
    });

    testWidgets('Does not render COPOM card when COPOM indicator is in the past', (WidgetTester tester) async {
      final mockRepo = MockAuthRepo();
      final targetDate = DateTime.now().subtract(const Duration(days: 1));
      final copomIndicator = MacroeconomicIndicator(
        id: '5',
        name: 'COPOM',
        value: targetDate.millisecondsSinceEpoch.toDouble(),
        updatedAt: DateTime.now(),
      );

      final mockIndicatorRepo = MockIndicatorRepo(
        customIndicators: [
          copomIndicator,
        ],
      );
      
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);
      await authProvider.loginWithGoogle();

      await tester.pumpWidget(
        MaterialApp(
          home: AuthProviderScope(
            notifier: authProvider,
            child: HomeScreen(
              onNavigateToSimulations: () {},
              repository: mockIndicatorRepo,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('copom_card')), findsNothing);
    });
  });

  group('Sharing proposal Bottom Sheet Tests', () {
    testWidgets('Renders Disclaimer Card and Share Bottom Sheet on Result Screen', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final mockRepo = MockAuthRepo();
      final authProvider = AuthProvider(repository: mockRepo, prefs: prefs);
      await authProvider.loginWithGoogle();

      final mockClient = MockClient((request) async {
        final listJson = [
          {
            "institutionId": "mock-id",
            "institutionName": "Banco Teste",
            "logoUrl": null,
            "propertyValue": 300000.0,
            "downPayment": 100000.0,
            "financedAmount": 200000.0,
            "term": 360,
            "sac": {
              "rateValue": 0.105,
              "monthlyRate": 0.0083,
              "firstPayment": 2200.0,
              "lastPayment": 600.0,
              "totalCost": 504000.0,
              "warnings": []
            },
            "price": {
              "rateValue": 0.105,
              "monthlyRate": 0.0083,
              "firstPayment": 1800.0,
              "lastPayment": 1800.0,
              "totalCost": 648000.0,
              "warnings": []
            }
          }
        ];
        return http.Response(jsonEncode(listJson), 200);
      });

      final simRepo = SimulationRepository(client: mockClient);

      final testInput = SimulationInput(
        valorImovel: 300000,
        valorEntrada: 100000,
        rendaMensal: 8000,
        tipoImovel: 'residencial',
        estadoCivil: 'solteiro',
        prazoMeses: 360,
        dataNascimento: DateTime(1990, 5, 15),
      );

      await tester.pumpWidget(
        AuthProviderScope(
          notifier: authProvider,
          child: MaterialApp(
            home: Scaffold(
              body: SimulationResultScreen(
                input: testInput,
                repository: simRepo,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('simulation_disclaimer_card')), findsOneWidget);
      expect(find.textContaining('Atenção: Os valores exibidos são simulações aproximadas'), findsOneWidget);

      final verDetalhes = find.text('Ver Detalhes');
      await tester.ensureVisible(verDetalhes);
      await tester.pumpAndSettle();
      await tester.tap(verDetalhes);
      await tester.pumpAndSettle();

      final shareButton = find.text('Compartilhar Proposta');
      expect(shareButton, findsOneWidget);
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      expect(find.text('Compartilhar Proposta'), findsNWidgets(2));
      expect(find.byKey(const Key('share_whatsapp_option')), findsOneWidget);
      expect(find.byKey(const Key('share_copy_option')), findsOneWidget);
      expect(find.byKey(const Key('share_pdf_option')), findsOneWidget);

      await tester.tap(find.byKey(const Key('share_copy_option')));
      await tester.pumpAndSettle();
      
      expect(find.byKey(const Key('share_copy_option')), findsNothing);
    });
  });
}
