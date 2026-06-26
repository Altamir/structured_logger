import 'package:clef_viewer_ui/utils/property_filter_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PropertyFilterCodec', () {
    test('parseField splits on semicolon', () {
      expect(
        PropertyFilterCodec.parseField('UserId=42;Screen=Home'),
        ['UserId=42', 'Screen=Home'],
      );
    });

    test('upsert replaces same key', () {
      final result = PropertyFilterCodec.upsert(
        ['UserId=42', 'Screen=Home'],
        'UserId=99',
      );
      expect(result, ['Screen=Home', 'UserId=99']);
    });

    test('removeKey drops one property', () {
      final result = PropertyFilterCodec.removeKey(
        ['UserId=42', 'Screen=Home'],
        'UserId',
      );
      expect(result, ['Screen=Home']);
    });
  });
}