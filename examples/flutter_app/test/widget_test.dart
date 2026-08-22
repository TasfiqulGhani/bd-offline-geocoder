import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bd_offline_geocoder_example/main.dart';

void main() {
  testWidgets('shows a reverse geocoded address', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Offline Bangladesh Address Lookup'), findsOneWidget);
    expect(
      find.text(
        'Ward No-43, Dhaka North City Corporation, Dhaka, Dhaka, Bangladesh',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(EditableText).first, '22.0');
    await tester.enterText(find.byType(EditableText).last, '89.0');
    await tester.tap(find.text('Reverse Geocode'));
    await tester.pumpAndSettle();

    expect(find.text('No Layer Match'), findsOneWidget);
    expect(find.text('Bangladesh'), findsOneWidget);
  });
}
