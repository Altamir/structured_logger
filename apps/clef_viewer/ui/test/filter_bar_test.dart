import 'package:clef_viewer_ui/models/log_filter.dart';
import 'package:clef_viewer_ui/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FilterBar shows validation when from is after to', (tester) async {
    var applied = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            initialFilter: LogFilter(
              from: DateTime.utc(2024, 2, 1),
              to: DateTime.utc(2024, 1, 1),
            ),
            onApply: (_) => applied = true,
            onClear: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(find.text('From date must be before to date'), findsOneWidget);
    expect(applied, isFalse);
  });
}