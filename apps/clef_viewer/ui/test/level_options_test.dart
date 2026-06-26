import 'package:clef_viewer_ui/models/level_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelOptions', () {
    test('uiSelectionFromFilter returns all when filter levels empty', () {
      expect(
        LevelOptions.uiSelectionFromFilter([]),
        LevelOptions.all.toSet(),
      );
    });

    test('uiSelectionFromFilter returns subset when filter has levels', () {
      expect(
        LevelOptions.uiSelectionFromFilter(['error', 'warning']),
        {'error', 'warning'},
      );
    });

    test('filterFromUiSelection returns empty when all selected', () {
      expect(
        LevelOptions.filterFromUiSelection(LevelOptions.all.toSet()),
        isEmpty,
      );
    });

    test('filterFromUiSelection returns subset when not all selected', () {
      expect(
        LevelOptions.filterFromUiSelection({'error', 'fatal'}),
        ['error', 'fatal'],
      );
    });
  });
}