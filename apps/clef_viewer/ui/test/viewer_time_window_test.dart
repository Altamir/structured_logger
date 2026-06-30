import 'package:clef_viewer_ui/config/viewer_config.dart';
import 'package:clef_viewer_ui/models/log_filter.dart';
import 'package:clef_viewer_ui/models/viewer_time_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewerTimeWindow', () {
    test('liveNow boot uses boot window', () {
      final now = DateTime(2026, 6, 30, 12, 0, 0);
      const base = LogFilter();
      const window = ViewerTimeWindow(liveSteady: false);

      final effective = window.applyTo(base, now);

      expect(
        effective.from,
        now.subtract(ViewerConfig.liveWindowBoot),
      );
      expect(effective.to, isNull);
    });

    test('liveNow steady uses steady window', () {
      final now = DateTime(2026, 6, 30, 12, 0, 0);
      const base = LogFilter();
      const window = ViewerTimeWindow(liveSteady: true);

      final effective = window.applyTo(base, now);

      expect(
        effective.from,
        now.subtract(ViewerConfig.liveWindowSteady),
      );
    });

    test('customRange applies from and to', () {
      final from = DateTime.utc(2026, 1, 1);
      final to = DateTime.utc(2026, 1, 2);
      final window = ViewerTimeWindow(
        kind: TimeWindowKind.customRange,
        customFrom: from,
        customTo: to,
      );

      final effective = window.applyTo(const LogFilter(), DateTime.utc(2026, 6, 1));

      expect(effective.from, from);
      expect(effective.to, to);
    });

    test('validate rejects from after to', () {
      final window = ViewerTimeWindow(
        kind: TimeWindowKind.customRange,
        customFrom: DateTime.utc(2026, 2, 1),
        customTo: DateTime.utc(2026, 1, 1),
      );

      expect(window.validate(), isNotNull);
    });
  });
}