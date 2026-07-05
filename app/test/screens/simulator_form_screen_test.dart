import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/screens/simulator_form_screen.dart';
import 'package:app/screens/simulation_result_screen.dart';
import 'package:app/simulation/simulation_repository.dart';

void main() {
  group('SimulatorFormScreen Tests', () {
    late SharedPreferences prefs;
    late AuthProvider authProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'mock_token': 'mock_token',
        'auth_user_id': 'user_123',
        'auth_user_name': 'Carlos Souza',
        'auth_user_email': 'carlos@example.com',
      });
      prefs = await SharedPreferences.getInstance();
      authProvider = AuthProvider(prefs: prefs);
    });

    Widget buildTestWidget({SimulationRepository? repository}) {
      return MaterialApp(
        home: AuthProviderScope(
          notifier: authProvider,
          child: SimulatorFormScreen(
            repository: repository ?? const SimulationRepository(),
          ),
        ),
      );
    }

    void configureScreenSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('Renders step indicator and step 1 fields initially',
        (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Step indicator
      expect(find.byKey(const Key('step_indicator')), findsOneWidget);

      // Step 1 fields visible
      expect(find.byKey(const Key('valor_imovel_field')), findsOneWidget);
      expect(find.byKey(const Key('valor_entrada_field')), findsOneWidget);
      expect(find.byKey(const Key('valor_imovel_slider')), findsOneWidget);

      // Step 2 fields NOT visible yet
      expect(find.byKey(const Key('renda_mensal_field')), findsNothing);
      expect(find.byKey(const Key('data_nascimento_field')), findsNothing);

      // Navigate button
      expect(find.byKey(const Key('simulate_button')), findsOneWidget);
    });

    testWidgets('Shows error if entry value is less than 20% of property value',
        (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Step 1: Fill invalid entry (< 20%)
      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('valor_entrada_field')), '90000');
      await tester.pump();

      // Try to advance - should fail validation
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(find.text('Entrada mínima de 20% (R\$ 100.000)'), findsOneWidget);
    });

    testWidgets('Shows error if monthly income is zero or negative',
        (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Advance past step 1 with valid data
      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      // Now on step 2 - enter zero income
      await tester.enterText(
          find.byKey(const Key('renda_mensal_field')), '0');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('data_nascimento_field')), '15/05/1990');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(find.text('A renda deve ser maior que zero'), findsOneWidget);
    });

    testWidgets(
        'Shows error if birthdate represents age less than 18 or greater than 80',
        (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Advance past step 1
      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      // Step 2: fill income, then invalid birthdate (under 18)
      await tester.enterText(
          find.byKey(const Key('renda_mensal_field')), '10000');
      await tester.pump();
      final dateField = find.byKey(const Key('data_nascimento_field'));
      await tester.enterText(dateField, '15/05/2020');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();
      expect(find.text('O proponente deve ter entre 18 e 80 anos'),
          findsOneWidget);

      // Over 80
      await tester.enterText(dateField, '15/05/1930');
      await tester.pump();
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();
      expect(find.text('O proponente deve ter entre 18 e 80 anos'),
          findsOneWidget);
    });

    testWidgets('Shows error if birthdate has invalid format',
        (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Advance past step 1
      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      // Step 2: invalid date format
      await tester.enterText(
          find.byKey(const Key('renda_mensal_field')), '10000');
      await tester.pump();
      final dateField = find.byKey(const Key('data_nascimento_field'));
      await tester.enterText(dateField, '12/34/5678');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(find.text('Formato inválido (DD/MM/AAAA)'), findsOneWidget);
    });

    testWidgets(
        'Successful form submission navigates to SimulationResultScreen',
        (WidgetTester tester) async {
      configureScreenSize(tester);

      final mockSuccessClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['propertyValue'], 500000.0);
        expect(body['downPayment'], 150000.0);
        expect(body['monthlyIncome'], 12000.0);
        expect(body['term'], 360);
        expect(body.containsKey('age'), true);
        expect(body.containsKey('valorImovel'), false);

        final listJson = [
          {
            "institutionId": "caixa-id",
            "institutionName": "Caixa Econômica Federal",
            "logoUrl": null,
            "propertyValue": 500000.0,
            "downPayment": 150000.0,
            "financedAmount": 350000.0,
            "term": 360,
            "sac": {
              "rateValue": 0.0999,
              "monthlyRate": 0.008,
              "firstPayment": 3200.0,
              "lastPayment": 1200.0,
              "totalCost": 792000.0,
              "warnings": []
            },
            "price": {
              "rateValue": 0.0999,
              "monthlyRate": 0.008,
              "firstPayment": 3000.0,
              "lastPayment": 3000.0,
              "totalCost": 1080000.0,
              "warnings": []
            },
            "warnings": []
          }
        ];
        return http.Response(jsonEncode(listJson), 200);
      });
      final mockRepository = SimulationRepository(client: mockSuccessClient);

      await tester.pumpWidget(buildTestWidget(repository: mockRepository));

      // Step 1: valid property and entry values
      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      // Step 2: income and birthdate
      await tester.enterText(
          find.byKey(const Key('renda_mensal_field')), '12000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('data_nascimento_field')), '15/05/1990');
      await tester.pump();
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      // Step 3: prazo
      await tester.enterText(find.byKey(const Key('prazo_field')), '360');
      await tester.pump();

      // Submit
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(SimulationResultScreen), findsOneWidget);
      expect(find.text('Resultado da Simulação'), findsOneWidget);
      expect(find.text('SAC'), findsOneWidget);
      expect(find.text('PRICE'), findsOneWidget);
      expect(find.textContaining('R\$ 350.000,00'), findsOneWidget);

      final backButton = find.byKey(const Key('result_back_button'));
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(SimulatorFormScreen), findsOneWidget);
    });

    testWidgets('Quick percentage buttons update the entry value field',
        (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();

      await tester.tap(find.byKey(const Key('quick_pct_30')));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '150000'), findsOneWidget);

      await tester.tap(find.byKey(const Key('quick_pct_50')));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '250000'), findsOneWidget);
    });

    testWidgets(
        'Renders all steps on narrow screen (360px) without horizontal overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1
      expect(find.byKey(const Key('valor_imovel_field')), findsOneWidget);
      expect(find.byKey(const Key('valor_entrada_field')), findsOneWidget);
      expect(find.byKey(const Key('quick_pct_20')), findsOneWidget);
      expect(find.byKey(const Key('quick_pct_30')), findsOneWidget);
      expect(find.byKey(const Key('quick_pct_40')), findsOneWidget);
      expect(find.byKey(const Key('quick_pct_50')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.tap(find.byKey(const Key('quick_pct_20')));
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'Step 1 initial/entry');

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Step 1 transition');

      // Step 2
      expect(find.byKey(const Key('renda_mensal_field')), findsOneWidget);
      expect(find.byKey(const Key('data_nascimento_field')), findsOneWidget);
      expect(find.byKey(const Key('estado_civil_dropdown')), findsOneWidget);

      await tester.enterText(
          find.byKey(const Key('renda_mensal_field')), '10000');
      await tester.pump();
      await tester.enterText(
          find.byKey(const Key('data_nascimento_field')), '15/05/1990');
      await tester.pump();

      expect(tester.takeException(), isNull, reason: 'Step 2 inputs');

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'Step 2 transition');

      // Step 3
      expect(find.byKey(const Key('tipo_imovel_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('prazo_field')), findsOneWidget);

      await tester.enterText(find.byKey(const Key('prazo_field')), '360');
      await tester.pump();

      expect(find.byKey(const Key('back_button')), findsOneWidget);
      expect(find.byKey(const Key('simulate_button')), findsOneWidget);

      expect(tester.takeException(), isNull, reason: 'Step 3 final');
    });
  });
}
