import 'package:clef_viewer_ui/models/level_options.dart';
import 'package:clef_viewer_ui/widgets/group_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GroupPanel shows Levels above Groups', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 600,
            child: GroupPanel(
              selectedLevels: LevelOptions.all.toSet(),
              onLevelsChanged: (_) {},
              groupBy: 'level',
              timeBucket: 'hour',
              propertyName: 'Screen',
              groups: const [],
              groupByChanged: (_) {},
              timeBucketChanged: (_) {},
              propertyNameChanged: (_) {},
              onGroupSelected: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Groups'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Levels')).dy,
      lessThan(tester.getTopLeft(find.text('Groups')).dy),
    );
  });

  testWidgets('deselected level notifies parent', (tester) async {
    Set<String>? changed;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 600,
            child: GroupPanel(
              selectedLevels: LevelOptions.all.toSet(),
              onLevelsChanged: (v) => changed = v,
              groupBy: 'level',
              timeBucket: 'hour',
              propertyName: 'Screen',
              groups: const [],
              groupByChanged: (_) {},
              timeBucketChanged: (_) {},
              propertyNameChanged: (_) {},
              onGroupSelected: (_) {},
              onRefresh: () {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('debug'));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed, isNot(contains('debug')));
  });
}