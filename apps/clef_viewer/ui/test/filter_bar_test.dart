import 'package:clef_viewer_ui/models/log_filter.dart';
import 'package:clef_viewer_ui/models/viewer_time_window.dart';
import 'package:clef_viewer_ui/widgets/filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required LogFilter initialFilter,
  required ValueChanged<LogFilter> onApply,
  VoidCallback? onClear,
  ViewerTimeWindow timeWindow = const ViewerTimeWindow(),
  ValueChanged<ViewerTimeWindow>? onTimeWindowChanged,
  GlobalKey<FilterBarState>? key,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: FilterBar(
        key: key,
        initialFilter: initialFilter,
        timeWindow: timeWindow,
        onTimeWindowChanged: onTimeWindowChanged ?? (_) {},
        onApply: onApply,
        onClear: onClear ?? () {},
      ),
    ),
  );
}

void main() {
  testWidgets('FilterBar does not show Apply button', (tester) async {
    await tester.pumpWidget(
      _harness(initialFilter: const LogFilter(), onApply: (_) {}),
    );

    expect(find.text('Apply'), findsNothing);
    expect(find.text('Now'), findsOneWidget);
  });

  testWidgets('FilterBar shows validation when custom range from is after to',
      (tester) async {
    var applied = false;
    await tester.pumpWidget(
      _harness(
        initialFilter: const LogFilter(),
        onApply: (_) => applied = true,
        timeWindow: ViewerTimeWindow(
          kind: TimeWindowKind.customRange,
          customFrom: DateTime.utc(2024, 2, 1),
          customTo: DateTime.utc(2024, 1, 1),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).last, 'x');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('From date must be before to date'), findsOneWidget);
    expect(applied, isFalse);
  });

  testWidgets('FilterBar does not show Property text field', (tester) async {
    await tester.pumpWidget(
      _harness(initialFilter: const LogFilter(), onApply: (_) {}),
    );

    expect(find.text('Property (k=v; k2=v2)'), findsNothing);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('FilterBar does not show Event ID field', (tester) async {
    await tester.pumpWidget(
      _harness(initialFilter: const LogFilter(), onApply: (_) {}),
    );

    expect(find.text('Event ID'), findsNothing);
    expect(find.bySemanticsLabel('Event ID'), findsNothing);
  });

  testWidgets('active filter chips are removable', (tester) async {
    LogFilter? applied;
    await tester.pumpWidget(
      _harness(
        initialFilter: const LogFilter(
          levels: ['error'],
          search: 'timeout',
        ),
        onApply: (f) => applied = f,
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
      _harness(
        key: key,
        initialFilter: const LogFilter(),
        onApply: (_) => applyCount++,
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

  testWidgets('search field applies filter after debounce', (tester) async {
    LogFilter? applied;

    await tester.pumpWidget(
      _harness(
        initialFilter: const LogFilter(),
        onApply: (f) => applied = f,
      ),
    );

    await tester.enterText(find.byType(TextField).last, 'timeout');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(applied?.search, 'timeout');
  });

  testWidgets('applyPropertyFilter sets property and applies', (tester) async {
    LogFilter? applied;
    final key = GlobalKey<FilterBarState>();

    await tester.pumpWidget(
      _harness(
        key: key,
        initialFilter: const LogFilter(),
        onApply: (f) => applied = f,
      ),
    );

    key.currentState!.applyPropertyFilter('UserId=42');
    await tester.pump();

    expect(applied?.properties, ['UserId=42']);
    expect(find.text('property: UserId=42'), findsOneWidget);
  });

  testWidgets('applyPropertyFilter accumulates multiple properties', (tester) async {
    LogFilter? applied;
    final key = GlobalKey<FilterBarState>();

    await tester.pumpWidget(
      _harness(
        key: key,
        initialFilter: const LogFilter(properties: ['UserId=42']),
        onApply: (f) => applied = f,
      ),
    );

    key.currentState!.applyPropertyFilter('Screen=Home');
    await tester.pump();

    expect(applied?.properties, containsAll(['UserId=42', 'Screen=Home']));
    expect(find.text('property: UserId=42'), findsOneWidget);
    expect(find.text('property: Screen=Home'), findsOneWidget);
  });
}