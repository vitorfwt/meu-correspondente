import 'package:app/design_system/colors.dart';
import 'package:app/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CustomButton renders text and triggers callback', (WidgetTester tester) async {
    bool wasPressed = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
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

  testWidgets('CustomButton shows loading indicator when isLoading is true', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
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

  testWidgets('CustomButton shows icon when provided', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
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

  testWidgets('CustomButton renders with correct colors based on type', (WidgetTester tester) async {
    // 1. Primary Button
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Primary',
            type: CustomButtonType.primary,
            onPressed: () {},
          ),
        ),
      ),
    );

    ElevatedButton getButtonWidget() {
      return tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    }

    expect(
      getButtonWidget().style?.backgroundColor?.resolve({}),
      AppColors.primary,
    );

    // 2. Secondary Button
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Secondary',
            type: CustomButtonType.secondary,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      getButtonWidget().style?.backgroundColor?.resolve({}),
      AppColors.secondary,
    );

    // 3. Accent Button
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Accent',
            type: CustomButtonType.accent,
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(
      getButtonWidget().style?.backgroundColor?.resolve({}),
      AppColors.accent,
    );
  });

  testWidgets('CustomButton is disabled when onPressed is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Disabled',
            onPressed: null,
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.enabled, isFalse);
  });
}
