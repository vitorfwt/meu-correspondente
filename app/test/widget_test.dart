import 'package:flutter_test/flutter_test.dart';
import 'package:app/main.dart';
import 'package:app/widgets/custom_button.dart';

void main() {
  testWidgets('Styleguide renders successfully with custom buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title is rendered.
    expect(find.text('Meu Correspondente'), findsOneWidget);
    expect(find.text('Styleguide & Design System'), findsOneWidget);

    // Verify that there are CustomButtons on screen.
    expect(find.byType(CustomButton), findsAtLeastNWidgets(1));
  });
}
