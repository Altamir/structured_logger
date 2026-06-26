import 'dart:convert';

import 'package:clef_viewer_ui/models/log_entry.dart';
import 'package:clef_viewer_ui/services/device_suggestion_cache.dart';
import 'package:clef_viewer_ui/services/log_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('DeviceSuggestionCache', () {
    late DeviceSuggestionCache cache;

    setUp(() {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/api/events/group')) {
          return http.Response(
            jsonEncode({
              'groups': [
                {'key': 'device-a', 'count': 3},
                {'key': '(empty)', 'count': 1},
              ],
            }),
            200,
          );
        }
        return http.Response('', 404);
      });
      cache = DeviceSuggestionCache(
        api: LogApiClient(baseUrl: 'http://test', client: client),
      );
    });

    test('load populates suggestions', () async {
      await cache.load();
      expect(cache.isLoaded, isTrue);
      expect(cache.suggestions, ['device-a', '(empty)']);
    });

    test('search is case-insensitive substring', () async {
      await cache.load();
      expect(cache.search('DEVICE'), ['device-a']);
      expect(cache.search('empty'), ['(empty)']);
    });

    test('mergeFromEvent adds new device', () async {
      await cache.load();
      cache.mergeFromEvent(
        const LogEntry(
          timestamp: '2024-01-01T12:00:01.000Z',
          level: 'info',
          deviceId: 'device-b',
        ),
      );
      expect(cache.suggestions, contains('device-b'));
    });

    test('load handles API failure gracefully', () async {
      final failingCache = DeviceSuggestionCache(
        api: LogApiClient(
          baseUrl: 'http://test',
          client: MockClient((_) async => http.Response('', 500)),
        ),
      );
      await failingCache.load();
      expect(failingCache.isLoaded, isTrue);
      expect(failingCache.suggestions, isEmpty);
      expect(failingCache.search('any'), isEmpty);
    });

    test('mergeFromEvent skips when at cap', () async {
      final cappedCache = DeviceSuggestionCache(
        api: LogApiClient(
          baseUrl: 'http://test',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'groups': List.generate(
                  100,
                  (i) => {'key': 'device-$i', 'count': 1},
                ),
              }),
              200,
            ),
          ),
        ),
      );
      await cappedCache.load();
      expect(cappedCache.suggestions.length, 100);

      cappedCache.mergeFromEvent(
        const LogEntry(
          timestamp: '2024-01-01T12:00:01.000Z',
          level: 'info',
          deviceId: 'device-new',
        ),
      );
      expect(cappedCache.suggestions, isNot(contains('device-new')));
      expect(cappedCache.suggestions.length, 100);
    });

    test('mergeFromEvent maps empty device to (empty)', () async {
      await cache.load();
      final before = cache.suggestions.length;
      cache.mergeFromEvent(
        const LogEntry(
          timestamp: '2024-01-01T12:00:01.000Z',
          level: 'info',
        ),
      );
      expect(cache.suggestions.length, before);
    });
  });
}