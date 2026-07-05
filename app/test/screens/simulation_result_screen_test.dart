import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:app/screens/simulation_result_screen.dart';
import 'package:app/simulation/simulation_repository.dart';

void main() {
  group('SimulationResultScreen Widget Tests', () {
    final mockInput = SimulationInput(
      valorImovel: 500000.0,
      valorEntrada: 150000.0,
      rendaMensal: 10000.0,
      tipoImovel: 'Residencial',
      estadoCivil: 'Solteiro(a)',
      prazoMeses: 360,
      dataNascimento: DateTime(1990, 5, 15),
    );

    Widget buildTestWidget(SimulationRepository repository) {
      return MaterialApp(
        home: SimulationResultScreen(
          input: mockInput,
          repository: repository,
        ),
      );
    }

    testWidgets('Renders simulation results list with normal data',
        (WidgetTester tester) async {
      final mockSuccessClient = MockClient((request) async {
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
          },
          {
            "institutionId": "bb-id",
            "institutionName": "Banco do Brasil",
            "logoUrl": null,
            "propertyValue": 500000.0,
            "downPayment": 150000.0,
            "financedAmount": 350000.0,
            "term": 360,
            "sac": {
              "rateValue": 0.1045,
              "monthlyRate": 0.0083,
              "firstPayment": 3350.0,
              "lastPayment": 1250.0,
              "totalCost": 828000.0,
              "warnings": []
            },
            "price": {
              "rateValue": 0.1045,
              "monthlyRate": 0.0083,
              "firstPayment": 3150.0,
              "lastPayment": 3150.0,
              "totalCost": 1134000.0,
              "warnings": []
            },
            "warnings": []
          }
        ];
        return http.Response(jsonEncode(listJson), 200);
      });

      final repository = SimulationRepository(client: mockSuccessClient);
      await tester.pumpWidget(buildTestWidget(repository));

      // Initially shows loading spinner
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Updated loading text
      expect(find.text('Buscando as melhores propostas...'), findsOneWidget);

      await tester.pumpAndSettle();

      // Should hide loading and show results
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Resultado da Simulação'), findsOneWidget);
      expect(find.text('Propostas Disponíveis'), findsOneWidget);

      // Financing summary
      expect(find.textContaining('R\$ 350.000,00'), findsOneWidget);
      expect(find.text('360 meses'), findsOneWidget);

      // Both bank cards
      expect(find.text('Caixa Econômica Federal'), findsOneWidget);
      expect(find.text('Banco do Brasil'), findsOneWidget);

      // Rates — displayed inline with full suffix
      expect(find.textContaining('9.99%'), findsAtLeastNWidgets(1));
      expect(find.textContaining('10.45%'), findsAtLeastNWidgets(1));

      // SAC and PRICE labels (one per card)
      expect(find.text('SAC'), findsNWidgets(2));
      expect(find.text('PRICE'), findsNWidgets(2));

      // Best option badge
      expect(find.text('Melhor Opção'), findsOneWidget);

      // "Ver Detalhes" button per card
      expect(find.text('Ver Detalhes'), findsNWidgets(2));

      // CET chip label appears
      expect(find.text('CET Estimado'), findsNWidgets(2));

      // Entrada chip label appears
      expect(find.text('Valor de Entrada'), findsNWidgets(2));
    });

    testWidgets(
        'Renders visual tags of credit restrictions when returned by API',
        (WidgetTester tester) async {
      final mockRestrictionClient = MockClient((request) async {
        final listJson = [
          {
            "institutionId": "itau-id",
            "institutionName": "Itaú Unibanco",
            "logoUrl": null,
            "propertyValue": 500000.0,
            "downPayment": 150000.0,
            "financedAmount": 350000.0,
            "term": 360,
            "sac": {
              "rateValue": 0.1099,
              "monthlyRate": 0.0087,
              "firstPayment": 3500.0,
              "lastPayment": 1300.0,
              "totalCost": 864000.0,
              "warnings": ["Restrição: Parcela excede 30% da renda"]
            },
            "price": {
              "rateValue": 0.1099,
              "monthlyRate": 0.0087,
              "firstPayment": 3300.0,
              "lastPayment": 3300.0,
              "totalCost": 1188000.0,
              "warnings": []
            },
            "warnings": ["Restrição: Idade + Prazo excede 80 anos"]
          }
        ];
        return http.Response(jsonEncode(listJson), 200);
      });

      final repository = SimulationRepository(client: mockRestrictionClient);
      await tester.pumpWidget(buildTestWidget(repository));
      await tester.pumpAndSettle();

      expect(find.text('Itaú Unibanco'), findsOneWidget);
      expect(find.text('Restrição: Parcela excede 30% da renda'),
          findsOneWidget);
      expect(
          find.text('Restrição: Idade + Prazo excede 80 anos'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNWidgets(2));
    });

    testWidgets(
        'Renders error layout and retries fetch simulation on retry button press',
        (WidgetTester tester) async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          return http.Response('Connection refused', 500);
        } else {
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
        }
      });

      final repository = SimulationRepository(client: mockClient);
      await tester.pumpWidget(buildTestWidget(repository));
      await tester.pumpAndSettle();

      // Updated error title
      expect(find.text('Falha na conexão'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pumpAndSettle();

      expect(find.text('Caixa Econômica Federal'), findsOneWidget);
      expect(callCount, 2);
    });
  });
}
