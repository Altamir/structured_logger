import 'package:clef_viewer_ui/models/filter_constants.dart';
import 'package:clef_viewer_ui/models/log_filter.dart';
import 'package:clef_viewer_ui/utils/active_filter_chip_factory.dart';
import 'package:clef_viewer_ui/widgets/active_filter_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('removing chip invokes onApply with updated filter', (tester) async {
    LogFilter? applied;
    const filter = LogFilter(
      levels: ['error'],
      deviceId: 'my-app',
      property: 'Screen=Home',
      search: 'timeout',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final chips = ActiveFilterChipFactory.fromFilter(
                filter,
                (updated) => applied = updated,
              );
              return ActiveFilterChips(chips: chips);
            },
          ),
        ),
      ),
    );

    expect(find.text('level: error'), findsOneWidget);
    expect(find.text('device: my-app'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear).first);
    await tester.pump();

    expect(applied, isNotNull);
    expect(applied!.levels, isEmpty);
    expect(applied!.deviceId, 'my-app');
  });

  test('factory shows empty sentinel as (empty)', () {
    const filter = LogFilter(deviceId: FilterConstants.emptySentinel);
    final chips = ActiveFilterChipFactory.fromFilter(filter, (_) {});
    expect(chips.single.label, 'device: (empty)');
  });
}