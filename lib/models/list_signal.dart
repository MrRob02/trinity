import 'dart:collection';

import 'package:trinity/models/signal.dart';

class ListSignal<T> extends ProtectedSignal<List<T>> with ListMixin<T> {
  ListSignal(super.value);

  /// Returns an unmodifiable view of the internal list.
  ///
  /// ⚠️ Calling mutations like `.removeWhere()` on this will throw `UnsupportedError`.
  /// Use the signal's own methods instead: `add`, `remove`, `removeWhere`, etc.
  @override
  List<T> get value => UnmodifiableListView(unsafeValue);

  ///A safe way to set the value of the signal.
  @override
  set value(List<T> newValue) {
    emit(newValue);
  }

  // ── ListMixin required overrides ──────────────────────────────────────────

  @override
  Iterator<T> get iterator => unsafeValue.iterator;

  @override
  int get length => unsafeValue.length;

  @override
  T operator [](int index) => unsafeValue[index];

  /// Copies the internal list before mutating so [emit] detects the new reference.
  @override
  void operator []=(int index, T v) {
    final copy = [...unsafeValue];
    copy[index] = v;
    emit(copy);
  }

  /// Copies the internal list before mutating so [emit] detects the new reference.
  @override
  set length(int newLength) {
    final copy = [...unsafeValue];
    copy.length = newLength;
    emit(copy);
  }

  // ── Bulk overrides ────────────────────────────────────────────────────────
  // ListMixin defaults call operator[]= per element → multiple emits.
  // These override to emit exactly once per operation.

  @override
  void add(T element) => emit([...unsafeValue, element]);

  @override
  void addAll(Iterable<T> iterable) => emit([...unsafeValue, ...iterable]);

  @override
  void clear() => emit([]);

  @override
  void insert(int index, T element) {
    final copy = [...unsafeValue];
    copy.insert(index, element);
    emit(copy);
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    final copy = [...unsafeValue];
    copy.insertAll(index, iterable);
    emit(copy);
  }

  @override
  bool remove(Object? element) {
    final copy = [...unsafeValue];
    final removed = copy.remove(element);
    if (removed) emit(copy);
    return removed;
  }

  @override
  void removeWhere(bool Function(T element) test) {
    final copy = [...unsafeValue];
    copy.removeWhere(test);
    emit(copy);
  }

  @override
  void retainWhere(bool Function(T element) test) {
    final copy = [...unsafeValue];
    copy.retainWhere(test);
    emit(copy);
  }

  @override
  void sort([Comparator<T>? compare]) {
    final copy = [...unsafeValue];
    copy.sort(compare);
    emit(copy);
  }

  void assignAll(Iterable<T> elements) => emit(elements.toList());
}

class IterableSignal<T> extends ProtectedSignal<Iterable<T>>
    with IterableMixin<T> {
  IterableSignal(super.value);

  @override
  Iterator<T> get iterator => value.iterator;

  @override
  int get length => value.length;

  @override
  set value(Iterable<T> newValue) {
    emit(newValue);
  }
}
