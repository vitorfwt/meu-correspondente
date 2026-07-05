import 'package:app/components/buttons/secondary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SecondaryButton renders text and triggers callback', (WidgetTester tester) async {
    bool wasPressed = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecondaryButton(
            text: 'Test Button',
            onPressed: () {
              wasPressed = true;
            },
          ),
        ),
      ),
    );

    // Verify text is rendered
    expect(find.text('Test Button'), findsOneWidget);
    
    // Verify tap triggers callback
    await tester.tap(find.text('Test Button'));
    expect(wasPressed, isTrue);
  });

  testWidgets('SecondaryButton shows loading indicator when isLoading is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecondaryButton(
            text: 'Test Button',
            isLoading: true,
            onPressed: () {},
          ),
        ),
      ),
    );

    // Verify text is NOT rendered when loading
    expect(find.text('Test Button'), findsNothing);
    
    // Verify CircularProgressIndicator is rendered
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SecondaryButton shows icon when provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SecondaryButton(
            text: 'Test Button',
            icon: Icons.add,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('Test Button'), findsOneWidget);
  });

  testWidgets('SecondaryButton is disabled when onPressed is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SecondaryButton(
            text: 'Disabled',
            onPressed: null,
          ),
        ),
      ),
    );

    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(button.enabled, isFalse);
  });
}
