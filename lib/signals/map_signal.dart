import 'dart:collection';

import 'package:trinity/signals/nullable_signal.dart';
import 'package:trinity/signals/signal.dart';

mixin MapSignalOperationsMixin<K, V> on MapMixin<K, V> {
  /// The internal map from which to copy elements for mutation.
  Map<K, V> get _internalMap;

  /// Emits the newly modified map back to the signal.
  void _emitMap(Map<K, V> map);

  // ── MapMixin required overrides ───────────────────────────────────────────

  @override
  V? operator [](Object? key) => _internalMap[key];

  /// Copies the internal map before mutating so it detects the new reference.
  @override
  void operator []=(K key, V value) {
    final copy = {..._internalMap};
    copy[key] = value;
    _emitMap(copy);
  }

  @override
  void clear() => _emitMap({});

  @override
  Iterable<K> get keys => _internalMap.keys;

  @override
  V? remove(Object? key) {
    final copy = {..._internalMap};
    final removed = copy.remove(key);
    if (copy.length != _internalMap.length) {
      _emitMap(copy);
    }
    return removed;
  }

  // ── Bulk & common mutation overrides ─────────────────────────────────────
  // Override to emit exactly once per operation instead of per-key mutation.

  @override
  void addAll(Map<K, V> other) => _emitMap({..._internalMap, ...other});

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    final copy = {..._internalMap};
    copy.addEntries(newEntries);
    _emitMap(copy);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    if (_internalMap.containsKey(key)) {
      return _internalMap[key] as V;
    }
    final value = ifAbsent();
    final copy = {..._internalMap};
    copy[key] = value;
    _emitMap(copy);
    return value;
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final copy = {..._internalMap};
    final result = copy.update(key, update, ifAbsent: ifAbsent);
    _emitMap(copy);
    return result;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    final copy = {..._internalMap};
    copy.updateAll(update);
    _emitMap(copy);
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    final copy = {..._internalMap};
    copy.removeWhere(test);
    _emitMap(copy);
  }

  void assignAll(Map<K, V> other) => _emitMap(Map<K, V>.from(other));
}

class MapSignal<K, V> extends ProtectedSignal<Map<K, V>>
    with MapMixin<K, V>, MapSignalOperationsMixin<K, V> {
  MapSignal(super.value);

  /// Returns an unmodifiable view of the internal map.
  ///
  /// ⚠️ Calling mutations on this directly will throw `UnsupportedError`.
  /// Use the signal's own methods instead: `operator[]=`, `addAll`, `remove`, etc.
  @override
  Map<K, V> get value => UnmodifiableMapView(unsafeValue);

  /// A safe way to set the value of the signal.
  @override
  set value(Map<K, V> newValue) {
    emit(newValue);
  }

  @override
  Map<K, V> get _internalMap => unsafeValue;

  @override
  void _emitMap(Map<K, V> map) => emit(map);
}

class NullableMapSignal<K, V> extends NullableSignal<Map<K, V>>
    with MapMixin<K, V>, MapSignalOperationsMixin<K, V> {
  NullableMapSignal([super.value]);

  @override
  Map<K, V>? get value {
    if (unsafeValue == null) return null;
    return UnmodifiableMapView(unsafeValue!);
  }

  @override
  set value(Map<K, V>? newValue) {
    emit(newValue);
  }

  @override
  Map<K, V> get _internalMap => unsafeValue ?? {};

  @override
  void _emitMap(Map<K, V> map) => emit(map);
}
