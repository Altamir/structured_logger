import 'package:clef_viewer_server/clef/clef_parser.dart';
import 'package:test/test.dart';

void main() {
  late ClefParser parser;

  setUp(() {
    parser = ClefParser(maxEventBytes: 1024);
  });

  test('parses reserved fields and properties', () {
    final entry = parser.parseObject({
      '@t': '2024-01-01T00:00:00.000Z',
      '@l': 'info',
      '@mt': 'Hello {name}',
      'name': 'John',
      'DeviceIdentifier': 'my-device',
    });

    expect(entry.timestamp, '2024-01-01T00:00:00.000Z');
    expect(entry.level, 'info');
    expect(entry.messageTemplate, 'Hello {name}');
    expect(entry.deviceId, 'my-device');
    expect(entry.properties['name'], 'John');
    expect(entry.properties.containsKey('@t'), isFalse);
  });

  test('defaults missing @t and @l', () {
    final before = DateTime.now().toUtc();
    final entry = parser.parseObject({'@mt': 'test'});
    final after = DateTime.now().toUtc();

    final ts = DateTime.parse(entry.timestamp).toUtc();
    expect(ts.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
    expect(ts.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    expect(entry.level, 'information');
  });

  test('stores @r in properties', () {
    final entry = parser.parseObject({
      '@mt': 'msg',
      '@r': ['a', 'b'],
    });
    expect(entry.properties['@r'], ['a', 'b']);
  });

  test('parses NDJSON skipping blank lines', () {
    const body = '''
{"@mt":"one","@l":"info"}
{"@mt":"two","@l":"error"}

{"@mt":"three","@l":"warning"}
''';
    final entries = parser.parseNdjson(body);
    expect(entries, hasLength(3));
    expect(entries[0].messageTemplate, 'one');
    expect(entries[2].messageTemplate, 'three');
  });

  test('rejects invalid JSON', () {
    expect(
      () => parser.parseJsonString('not-json'),
      throwsA(isA<ClefParseException>()),
    );
  });

  test('rejects oversized event', () {
    final parserSmall = ClefParser(maxEventBytes: 10);
    expect(
      () => parserSmall.parseObject({'@mt': 'x' * 100}),
      throwsA(isA<PayloadTooLargeException>()),
    );
  });
}