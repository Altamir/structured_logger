import 'package:clef_viewer_ui/models/filter_constants.dart';
import 'package:clef_viewer_ui/widgets/property_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tap on primitive triggers onFilter', (tester) async {
    String? filtered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyChip(
            propertyKey: 'UserId',
            value: 42,
            onFilter: (param) => filtered = param,
          ),
        ),
      ),
    );

    await tester.tap(find.text('UserId: 42'));
    await tester.pump();

    expect(filtered, 'UserId=42');
  });

  testWidgets('tap on null value triggers empty sentinel filter', (tester) async {
    String? filtered;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyChip(
            propertyKey: 'Screen',
            value: null,
            onFilter: (param) => filtered = param,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Screen: (empty)'));
    await tester.pump();

    expect(filtered, 'Screen=${FilterConstants.emptySentinel}');
  });

  testWidgets('complex value chip is not tappable', (tester) async {
    var filtered = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PropertyChip(
            propertyKey: 'Meta',
            value: {'a': 1},
            onFilter: (_) => filtered = true,
          ),
        ),
      ),
    );

    final chip = tester.widget<ActionChip>(find.byType(ActionChip));
    expect(chip.onPressed, isNull);

    await tester.tap(find.textContaining('Meta:'));
    await tester.pump();
    expect(filtered, isFalse);
  });
}