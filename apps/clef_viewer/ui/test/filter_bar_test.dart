import 'package:clef_viewer_ui/models/level_options.dart';
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

  testWidgets('FilterBar does not show Event ID field', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            initialFilter: const LogFilter(),
            onApply: (_) {},
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.text('Event ID'), findsNothing);
    expect(find.bySemanticsLabel('Event ID'), findsNothing);
  });

  testWidgets('active filter chips are removable', (tester) async {
    LogFilter? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            initialFilter: const LogFilter(
              levels: ['error'],
              search: 'timeout',
            ),
            onApply: (f) => applied = f,
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.text('level: error'), findsOneWidget);
    expect(find.text('search: timeout'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.pump();

    expect(applied, isNotNull);
    expect(applied!.levels, isEmpty);
    expect(applied!.search, 'timeout');
  });

  testWidgets('applyExternalFilter syncs chips and controllers', (tester) async {
    final key = GlobalKey<FilterBarState>();
    var applyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            key: key,
            initialFilter: const LogFilter(),
            onApply: (_) => applyCount++,
            onClear: () {},
          ),
        ),
      ),
    );

    key.currentState!.applyExternalFilter(
      const LogFilter(levels: ['error'], deviceId: 'group-device'),
    );
    await tester.pump();

    expect(applyCount, 0);
    expect(find.text('level: error'), findsOneWidget);
    expect(find.text('device: group-device'), findsOneWidget);
    expect(key.currentState!.buildFilter().deviceId, 'group-device');
  });

  testWidgets('all levels selected by default produces empty filter', (tester) async {
    LogFilter? applied;
    final key = GlobalKey<FilterBarState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            key: key,
            initialFilter: const LogFilter(),
            onApply: (f) => applied = f,
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.text('Levels'), findsOneWidget);
    expect(key.currentState!.buildFilter().levels, isEmpty);

    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(applied?.levels, isEmpty);
  });

  testWidgets('deselected level is included in applied filter', (tester) async {
    LogFilter? applied;
    final key = GlobalKey<FilterBarState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: FilterBar(
            key: key,
            initialFilter: const LogFilter(),
            onApply: (f) => applied = f,
            onClear: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('debug'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(applied, isNotNull);
    expect(applied!.levels, isNot(contains('debug')));
    expect(applied!.levels.length, LevelOptions.all.length - 1);
  });

  testWidgets('applyPropertyFilter sets property and applies', (tester) async {
    LogFilter? applied;
    final key = GlobalKey<FilterBarState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilterBar(
            key: key,
            initialFilter: const LogFilter(),
            onApply: (f) => applied = f,
            onClear: () {},
          ),
        ),
      ),
    );

    key.currentState!.applyPropertyFilter('UserId=42');
    await tester.pump();

    expect(applied?.property, 'UserId=42');
    expect(find.text('property: UserId=42'), findsOneWidget);
  });
}