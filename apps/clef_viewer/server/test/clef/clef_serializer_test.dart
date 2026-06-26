import 'package:clef_viewer_server/clef/clef_parser.dart';
import 'package:clef_viewer_server/clef/clef_serializer.dart';
import 'package:test/test.dart';

void main() {
  test('round-trip preserves CLEF fields', () {
    final parser = ClefParser(maxEventBytes: 1048576);
    final serializer = ClefSerializer();

    final original = {
      '@t': '2024-01-01T00:00:00.000Z',
      '@l': 'info',
      '@mt': 'Hello {name}',
      '@m': 'Hello John',
      '@x': 'stack',
      '@i': 'evt-1',
      'DeviceIdentifier': 'device-a',
      'name': 'John',
      '@r': [1, 2],
    };

    final entry = parser.parseObject(original);
    final clef = serializer.toClef(entry);

    expect(clef['@t'], original['@t']);
    expect(clef['@l'], original['@l']);
    expect(clef['@mt'], original['@mt']);
    expect(clef['@m'], original['@m']);
    expect(clef['@x'], original['@x']);
    expect(clef['@i'], original['@i']);
    expect(clef['DeviceIdentifier'], original['DeviceIdentifier']);
    expect(clef['name'], original['name']);
    expect(clef['@r'], original['@r']);
  });
}