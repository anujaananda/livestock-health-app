import 'package:flutter_test/flutter_test.dart';
import 'package:livestock_health_app/main.dart';

void main() {
  testWidgets(
    'FarmCare app starts successfully',
    (WidgetTester tester) async {
      // Start the FarmCare application
      await tester.pumpWidget(const MyApp());

      // Check whether the splash screen is displayed
      expect(
        find.text('Livestock Health'),
        findsOneWidget,
      );

      expect(
        find.text('HERD COMPANION'),
        findsOneWidget,
      );
    },
  );
}
