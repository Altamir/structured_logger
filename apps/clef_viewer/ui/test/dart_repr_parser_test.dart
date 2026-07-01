import 'package:clef_viewer_ui/utils/dart_repr_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DartReprParser', () {
    const customerAddress =
        'CustomerAddress({id: 34990995, principal: false, street: Rua João Felipe Fritzen, number: 55, complement: Fc, district: Santa Lúcia, zipCode: 93711670, city: Campo Bom, state: RS, storeId: null, customerId: 7402050, store: null, dateCreated: 2025-08-12T09:58:06.135116, dateDeleted: null, dateUpdated: null, description: rua, idLocal: cc2b5085-8dd3-4c2a-b0f0-57fb1ee6216b})';

    const cartItem =
        'CartItemDTO({productId: 1532, name: Coturno Preto Couro Tratorado Básico, sku: A1201700010001, image: http://imagens.arezzo.com.br/SAP/Arezzo/foto_pequena/A1201700010001.jpg, quantity: 1, size: 37, unitPrice: 399.9, unitPriceWithDiscount: 159.96, discount: 0, discountValue: 0.0, brand: 1, uuid: 69dcb89a-0faf-4d30-b90e-509659294bfb, hasStock: null, hasEmployeeDiscount: false, discountMarkdown: 239.93999999999997})';

    const brand =
        'Brand({id: 1, organizationId: 3, name: AREZZO, codeBrand: 1, url: , status: , dateCreated: null, dateDeleted: null, dateUpdated: null, campaigns: null})';

    test('parses CustomerAddress repr', () {
      final parsed = DartReprParser.tryParseDartRepr(customerAddress);

      expect(parsed, isNotNull);
      expect(parsed!['_type'], 'CustomerAddress');
      expect(parsed['id'], 34990995);
      expect(parsed['principal'], isFalse);
      expect(parsed['street'], 'Rua João Felipe Fritzen');
      expect(parsed['number'], 55);
      expect(parsed['storeId'], isNull);
      expect(parsed['idLocal'], 'cc2b5085-8dd3-4c2a-b0f0-57fb1ee6216b');
    });

    test('parses CartItemDTO repr with url and decimals', () {
      final parsed = DartReprParser.tryParseDartRepr(cartItem);

      expect(parsed, isNotNull);
      expect(parsed!['_type'], 'CartItemDTO');
      expect(parsed['productId'], 1532);
      expect(parsed['name'], 'Coturno Preto Couro Tratorado Básico');
      expect(
        parsed['image'],
        'http://imagens.arezzo.com.br/SAP/Arezzo/foto_pequena/A1201700010001.jpg',
      );
      expect(parsed['unitPrice'], 399.9);
      expect(parsed['discountMarkdown'], 239.93999999999997);
      expect(parsed['hasStock'], isNull);
    });

    test('parses Brand repr with empty string fields', () {
      final parsed = DartReprParser.tryParseDartRepr(brand);

      expect(parsed, isNotNull);
      expect(parsed!['_type'], 'Brand');
      expect(parsed['name'], 'AREZZO');
      expect(parsed['url'], '');
      expect(parsed['status'], '');
      expect(parsed['campaigns'], isNull);
    });

    test('normalizeValue converts repr strings inside lists', () {
      final normalized = DartReprParser.normalizeValue({
        'addresses': [customerAddress],
        'cartItems': [cartItem],
      });

      final addresses = normalized['addresses'] as List<dynamic>;
      expect(addresses, hasLength(1));
      expect(addresses.first, isA<Map<String, dynamic>>());
      expect(addresses.first['_type'], 'CustomerAddress');
    });

    test('keeps Instance of strings unchanged', () {
      const value = "Instance of 'UpsellRecommendationResponse'";
      expect(DartReprParser.normalizeValue(value), value);
      expect(DartReprParser.tryParseDartRepr(value), isNull);
    });

    test('keeps regular strings unchanged', () {
      expect(DartReprParser.normalizeValue('hello world'), 'hello world');
      expect(DartReprParser.tryParseDartRepr('not a repr'), isNull);
    });
  });
}