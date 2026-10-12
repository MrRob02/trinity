import 'dart:collection';

import 'package:trinity/signals/nullable_signal.dart';
import 'package:trinity/signals/signal.dart';

mixin SetSignalOperationsMixin<T> on SetBase<T> {
  /// The internal set from which to copy elements for mutation.
  Set<T> get _internalSet;

  /// Emits the newly modified set back to the signal.
  void _emitSet(Set<T> set);

  // ── SetMixin required overrides ───────────────────────────────────────────

  @override
  bool contains(Object? element) => _internalSet.contains(element);

  @override
  Iterator<T> get iterator => _internalSet.iterator;

  @override
  int get length => _internalSet.length;

  @override
  T? lookup(Object? element) => _internalSet.lookup(element);

  @override
  Set<T> toSet() => _internalSet.toSet();

  /// Copies the internal set before mutating so it detects the new reference.
  @override
  bool add(T value) {
    final copy = {..._internalSet};
    final added = copy.add(value);
    if (added) _emitSet(copy);
    return added;
  }

  /// Copies the internal set before mutating so it detects the new reference.
  @override
  bool remove(Object? value) {
    final copy = {..._internalSet};
    final removed = copy.remove(value);
    if (removed) _emitSet(copy);
    return removed;
  }

  @override
  void clear() => _emitSet({});

  // ── Bulk & common mutation overrides ─────────────────────────────────────
  // Override to emit exactly once per operation instead of per-element mutation.

  @override
  void addAll(Iterable<T> elements) {
    final copy = {..._internalSet};
    final initialLength = copy.length;
    copy.addAll(elements);
    if (copy.length != initialLength) {
      _emitSet(copy);
    }
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    final copy = {..._internalSet};
    final initialLength = copy.length;
    copy.removeAll(elements);
    if (copy.length != initialLength) {
      _emitSet(copy);
    }
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    final copy = {..._internalSet};
    final initialLength = copy.length;
    copy.retainAll(elements);
    if (copy.length != initialLength) {
      _emitSet(copy);
    }
  }

  @override
  void removeWhere(bool Function(T element) test) {
    final copy = {..._internalSet};
    final initialLength = copy.length;
    copy.removeWhere(test);
    if (copy.length != initialLength) {
      _emitSet(copy);
    }
  }

  @override
  void retainWhere(bool Function(T element) test) {
    final copy = {..._internalSet};
    final initialLength = copy.length;
    copy.retainWhere(test);
    if (copy.length != initialLength) {
      _emitSet(copy);
    }
  }

  void assignAll(Iterable<T> elements) => _emitSet(elements.toSet());
}

class SetSignal<T> extends ProtectedSignal<Set<T>>
    with SetMixin<T>, SetSignalOperationsMixin<T> {
  SetSignal(super.value);

  /// Returns an unmodifiable view of the internal set.
  ///
  /// ⚠️ Calling mutations on this directly will throw `UnsupportedError`.
  /// Use the signal's own methods instead: `add`, `remove`, `addAll`, etc.
  @override
  Set<T> get value => UnmodifiableSetView(unsafeValue);

  /// A safe way to set the value of the signal.
  @override
  set value(Set<T> newValue) {
    emit(newValue);
  }

  @override
  Set<T> get _internalSet => unsafeValue;

  @override
  void _emitSet(Set<T> set) => emit(set);
}

class NullableSetSignal<T> extends NullableSignal<Set<T>>
    with SetMixin<T>, SetSignalOperationsMixin<T> {
  NullableSetSignal([super.value]);

  @override
  Set<T>? get value {
    if (unsafeValue == null) return null;
    return UnmodifiableSetView(unsafeValue!);
  }

  @override
  set value(Set<T>? newValue) {
    emit(newValue);
  }

  @override
  Set<T> get _internalSet => unsafeValue ?? {};

  @override
  void _emitSet(Set<T> set) => emit(set);
}
