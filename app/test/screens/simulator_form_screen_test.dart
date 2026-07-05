import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/auth/auth_provider.dart';
import 'package:app/screens/simulator_form_screen.dart';
import 'package:app/screens/simulation_result_screen.dart';

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

    Widget buildTestWidget() {
      return MaterialApp(
        home: AuthProviderScope(
          notifier: authProvider,
          child: const SimulatorFormScreen(),
        ),
      );
    }

    void configureScreenSize(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    testWidgets('Renders all inputs, sliders, and submit button', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Fields
      expect(find.byKey(const Key('valor_imovel_field')), findsOneWidget);
      expect(find.byKey(const Key('valor_entrada_field')), findsOneWidget);
      expect(find.byKey(const Key('renda_mensal_field')), findsOneWidget);
      expect(find.byKey(const Key('data_nascimento_field')), findsOneWidget);
      expect(find.byKey(const Key('estado_civil_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('tipo_imovel_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('prazo_field')), findsOneWidget);

      // Sliders
      expect(find.byKey(const Key('valor_imovel_slider')), findsOneWidget);
      expect(find.byKey(const Key('prazo_slider')), findsOneWidget);

      // Action button
      expect(find.byKey(const Key('simulate_button')), findsOneWidget);
    });

    testWidgets('Shows error if entry value is less than 20% of property value', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Configure a R$ 500.000 property and R$ 90.000 entry (which is 18%, i.e. < 20%)
      await tester.enterText(find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('valor_entrada_field')), '90000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('renda_mensal_field')), '10000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('data_nascimento_field')), '15/05/1990');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('prazo_field')), '360');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      // Should show the validation error
      expect(find.text('Entrada mínima de 20% (R\$ 100.000)'), findsOneWidget);
    });

    testWidgets('Shows error if monthly income is zero or negative', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('renda_mensal_field')), '0');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('data_nascimento_field')), '15/05/1990');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(find.text('A renda familiar mensal deve ser maior que zero'), findsOneWidget);
    });

    testWidgets('Shows error if birthdate represents age less than 18 or greater than 80', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      await tester.enterText(find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('renda_mensal_field')), '10000');
      await tester.pump();
      
      // Proponent under 18 (e.g. born in 2020)
      final dateField = find.byKey(const Key('data_nascimento_field'));
      await tester.enterText(dateField, '15/05/2020');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();
      expect(find.text('O proponente deve ter entre 18 e 80 anos'), findsOneWidget);

      // Proponent over 80 (e.g. born in 1930)
      await tester.enterText(dateField, '15/05/1930');
      await tester.pump();
      
      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();
      expect(find.text('O proponente deve ter entre 18 e 80 anos'), findsOneWidget);
    });

    testWidgets('Shows error if birthdate has invalid format', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      final dateField = find.byKey(const Key('data_nascimento_field'));
      await tester.enterText(dateField, '12/34/5678');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      await tester.pumpAndSettle();

      expect(find.text('Formato inválido (DD/MM/AAAA)'), findsOneWidget);
    });

    testWidgets('Successful form submission calculates simulation and redirects to SimulationResultScreen', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Correct values
      await tester.enterText(find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('valor_entrada_field')), '150000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('renda_mensal_field')), '12000');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('data_nascimento_field')), '15/05/1990');
      await tester.pump();
      await tester.enterText(find.byKey(const Key('prazo_field')), '360');
      await tester.pump();

      await tester.tap(find.byKey(const Key('simulate_button')));
      
      // Pump initial navigation / state changes
      await tester.pump();
      
      // Wait for repository delay (600ms)
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Now we should be on the SimulationResultScreen
      expect(find.byType(SimulationResultScreen), findsOneWidget);
      expect(find.text('Resultado da Simulação'), findsOneWidget);
      
      // Verify values on the result screen
      expect(find.text('SAC'), findsOneWidget);
      expect(find.text('PRICE'), findsOneWidget);
      
      // Financed: 500.000 - 150.000 = 350.000
      expect(find.textContaining('R\$ 350.000,00'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byKey(const Key('result_back_button')));
      await tester.pumpAndSettle();

      // Should be back on the SimulatorFormScreen
      expect(find.byType(SimulatorFormScreen), findsOneWidget);
    });

    testWidgets('Quick percentage buttons update the entry value field', (WidgetTester tester) async {
      configureScreenSize(tester);
      await tester.pumpWidget(buildTestWidget());

      // Set property value
      await tester.enterText(find.byKey(const Key('valor_imovel_field')), '500000');
      await tester.pump();

      // Tap 30% button
      await tester.tap(find.byKey(const Key('quick_pct_30')));
      await tester.pump();

      // Value should be 500000 * 0.3 = 150000
      expect(find.widgetWithText(TextFormField, '150000'), findsOneWidget);
      
      // Tap 50% button
      await tester.tap(find.byKey(const Key('quick_pct_50')));
      await tester.pump();

      // Value should be 500000 * 0.5 = 250000
      expect(find.widgetWithText(TextFormField, '250000'), findsOneWidget);
    });
  });
}
