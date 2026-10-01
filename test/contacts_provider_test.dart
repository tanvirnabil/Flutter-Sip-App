import 'package:flutter_test/flutter_test.dart';
import 'package:aura_voip/models/contact_item.dart';

void main() {
  group('ContactItem Model Tests', () {
    test('ContactItem serialization and copyWith', () {
      final item = ContactItem(
        id: '123',
        name: 'Alice',
        extension: '101',
        email: 'alice@ranksitt.net',
        isFavorite: false,
      );

      final map = item.toMap();
      expect(map['id'], equals('123'));
      expect(map['name'], equals('Alice'));
      expect(map['extension'], equals('101'));
      expect(map['isFavorite'], equals(0));

      final restored = ContactItem.fromMap(map);
      expect(restored.name, equals('Alice'));
      expect(restored.isFavorite, isFalse);

      final favoriteCopy = item.copyWith(isFavorite: true);
      expect(favoriteCopy.isFavorite, isTrue);
      expect(favoriteCopy.toMap()['isFavorite'], equals(1));
    });
  });
}

