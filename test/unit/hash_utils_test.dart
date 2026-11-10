import 'package:flutter_test/flutter_test.dart';
import 'package:sharetime/core/utils/hash_utils.dart';

void main() {
  group('FNV-1a Hash Deterministico 32-bit', () {
    test('restituisce sempre lo stesso valore per lo stesso seed', () {
      const seed = 'test_user_seed_123';
      final h1 = fnv1a32(seed);
      final h2 = fnv1a32(seed);
      expect(h1, equals(h2));
      expect(h1, isNot(equals(0)));
    });

    test('restituisce valori diversi per seed differenti', () {
      final h1 = fnv1a32('seed_alice');
      final h2 = fnv1a32('seed_bob');
      expect(h1, isNot(equals(h2)));
    });

    test('valori entro il range unsigned 32-bit', () {
      final h = fnv1a32('long_arbitrary_string_seed_with_unicode_radar_🛰️');
      expect(h >= 0, isTrue);
      expect(h <= 0xFFFFFFFF, isTrue);
    });
  });
}
