import 'package:flutter_test/flutter_test.dart';
import 'package:trinity/trinity.dart';

void main() {
  group('SetSignal', () {
    test('mutations emit copy with new reference', () {
      final setSignal = SetSignal<int>({1});

      final emissions = <Set<int>>[];
      setSignal.stream.listen((v) => emissions.add(v));

      final added = setSignal.add(2);
      expect(added, isTrue);
      expect(setSignal.contains(2), isTrue);
      expect(setSignal.value, {1, 2});

      // Adding existing element does not emit
      final addedAgain = setSignal.add(2);
      expect(addedAgain, isFalse);

      final removed = setSignal.remove(1);
      expect(removed, isTrue);
      expect(setSignal.contains(1), isFalse);

      // Removing non-existent element does not emit
      final removedAgain = setSignal.remove(999);
      expect(removedAgain, isFalse);

      setSignal.addAll([3, 4]);
      expect(setSignal.value, {2, 3, 4});

      setSignal.removeAll([3]);
      expect(setSignal.value, {2, 4});

      setSignal.retainAll([4]);
      expect(setSignal.value, {4});

      setSignal.clear();
      expect(setSignal.isEmpty, isTrue);
    });

    test('removeWhere and retainWhere emit correctly', () {
      final setSignal = SetSignal<int>({1, 2, 3, 4, 5});

      setSignal.removeWhere((e) => e.isOdd);
      expect(setSignal.value, {2, 4});

      setSignal.retainWhere((e) => e == 2);
      expect(setSignal.value, {2});
    });

    test('assignAll replaces entire set', () {
      final setSignal = SetSignal<String>({'a'});
      setSignal.assignAll(['x', 'y']);
      expect(setSignal.value, {'x', 'y'});
    });

    test('value getter returns unmodifiable set', () {
      final setSignal = SetSignal<int>({1, 2});
      expect(() => setSignal.value.add(3), throwsUnsupportedError);
    });
  });

  group('NullableSetSignal', () {
    test('handles mutations and nullable state', () {
      final setSignal = NullableSetSignal<String>();
      expect(setSignal.value, isNull);

      setSignal.add('item1');
      expect(setSignal.value, {'item1'});
      expect(setSignal.contains('item1'), isTrue);

      setSignal.assignAll(['a', 'b']);
      expect(setSignal.value, {'a', 'b'});
    });
  });
}
