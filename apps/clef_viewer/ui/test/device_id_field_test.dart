import 'package:clef_viewer_ui/models/filter_constants.dart';
import 'package:clef_viewer_ui/services/device_suggestion_cache.dart';
import 'package:clef_viewer_ui/services/log_api_client.dart';
import 'package:clef_viewer_ui/widgets/device_id_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  late DeviceSuggestionCache cache;
  late TextEditingController controller;

  setUp(() async {
    controller = TextEditingController();
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'groups': [
            {'key': 'device-a', 'count': 1},
            {'key': '(empty)', 'count': 1},
          ],
        }),
        200,
      );
    });
    cache = DeviceSuggestionCache(
      api: LogApiClient(baseUrl: 'http://test', client: client),
    );
    await cache.load();
  });

  tearDown(() => controller.dispose());

  Future<void> pumpField(
    WidgetTester tester, {
    required void Function(String?) onSelected,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeviceIdField(
            controller: controller,
            cache: cache,
            onDeviceSelected: onSelected,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('selecting (empty) maps to empty sentinel', (tester) async {
    String? selected;
    await pumpField(tester, onSelected: (v) => selected = v);

    await tester.enterText(find.byType(TextField), '(emp');
    await tester.pump();
    await tester.tap(find.text('(empty)'));
    await tester.pump();

    expect(selected, FilterConstants.emptySentinel);
    expect(controller.text, '(empty)');
  });

  testWidgets('selecting device fills controller and callback', (tester) async {
    String? selected;
    await pumpField(tester, onSelected: (v) => selected = v);

    await tester.enterText(find.byType(TextField), 'device');
    await tester.pump();
    await tester.tap(find.text('device-a'));
    await tester.pump();

    expect(selected, 'device-a');
    expect(controller.text, 'device-a');
  });
}