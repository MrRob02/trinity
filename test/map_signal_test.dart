import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/trinity.dart';

void main() {
  group('MapSignal', () {
    test('mutations emit copy with new reference', () {
      final mapSignal = MapSignal<String, int>({'a': 1});

      final emissions = <Map<String, int>>[];
      mapSignal.stream.listen((v) => emissions.add(v));

      mapSignal['b'] = 2;
      expect(mapSignal['b'], 2);
      expect(mapSignal.containsKey('b'), true);
      expect(mapSignal.value, {'a': 1, 'b': 2});

      mapSignal.remove('a');
      expect(mapSignal.containsKey('a'), false);

      mapSignal.addAll({'c': 3, 'd': 4});
      expect(mapSignal.value, {'b': 2, 'c': 3, 'd': 4});

      mapSignal.clear();
      expect(mapSignal.isEmpty, true);
    });

    test('assignAll replaces entire map', () {
      final mapSignal = MapSignal<String, int>({'a': 1});
      mapSignal.assignAll({'x': 10, 'y': 20});
      expect(mapSignal.value, {'x': 10, 'y': 20});
    });
  });

  group('NullableMapSignal', () {
    test('handles mutations and nullable state', () {
      final mapSignal = NullableMapSignal<String, int>();
      expect(mapSignal.value, isNull);

      mapSignal['a'] = 1;
      expect(mapSignal.value, {'a': 1});
      expect(mapSignal['a'], 1);
    });
  });
}
