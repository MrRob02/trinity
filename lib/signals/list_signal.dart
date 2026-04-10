import 'dart:collection';

import 'package:trinity/signals/nullable_signal.dart';
import 'package:trinity/signals/signal.dart';

mixin ListSignalOperationsMixin<T> on ListMixin<T> {
  /// The internal list from which to copy elements for mutation.
  List<T> get _internalList;

  /// Emits the newly modified list back to the signal.
  void _emitList(List<T> list);

  // ── ListMixin required overrides ──────────────────────────────────────────

  @override
  Iterator<T> get iterator => _internalList.iterator;

  @override
  int get length => _internalList.length;

  @override
  T operator [](int index) => _internalList[index];

  /// Copies the internal list before mutating so it detects the new reference.
  @override
  void operator []=(int index, T v) {
    final copy = [..._internalList];
    copy[index] = v;
    _emitList(copy);
  }

  /// Copies the internal list before mutating so it detects the new reference.
  @override
  set length(int newLength) {
    final copy = [..._internalList];
    copy.length = newLength;
    _emitList(copy);
  }

  // ── Bulk overrides ────────────────────────────────────────────────────────
  // ListMixin defaults call operator[]= per element → multiple emits.
  // These override to emit exactly once per operation.

  @override
  void add(T element) => _emitList([..._internalList, element]);

  @override
  void addAll(Iterable<T> iterable) => _emitList([..._internalList, ...iterable]);

  @override
  void clear() => _emitList([]);

  @override
  void insert(int index, T element) {
    final copy = [..._internalList];
    copy.insert(index, element);
    _emitList(copy);
  }

  @override
  void insertAll(int index, Iterable<T> iterable) {
    final copy = [..._internalList];
    copy.insertAll(index, iterable);
    _emitList(copy);
  }

  @override
  bool remove(Object? element) {
    final copy = [..._internalList];
    final removed = copy.remove(element);
    if (removed) _emitList(copy);
    return removed;
  }

  @override
  void removeWhere(bool Function(T element) test) {
    final copy = [..._internalList];
    copy.removeWhere(test);
    _emitList(copy);
  }

  @override
  void retainWhere(bool Function(T element) test) {
    final copy = [..._internalList];
    copy.retainWhere(test);
    _emitList(copy);
  }

  @override
  void sort([Comparator<T>? compare]) {
    final copy = [..._internalList];
    copy.sort(compare);
    _emitList(copy);
  }

  void assignAll(Iterable<T> elements) => _emitList(elements.toList());
}

class ListSignal<T> extends ProtectedSignal<List<T>>
    with ListMixin<T>, ListSignalOperationsMixin<T> {
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

  @override
  List<T> get _internalList => unsafeValue;

  @override
  void _emitList(List<T> list) => emit(list);
}

class NullableListSignal<T> extends NullableSignal<List<T>>
    with ListMixin<T>, ListSignalOperationsMixin<T> {
  NullableListSignal([super.value]);

  @override
  List<T>? get value {
    if (unsafeValue == null) return null;
    return UnmodifiableListView(unsafeValue!);
  }

  @override
  set value(List<T>? newValue) {
    emit(newValue);
  }

  @override
  List<T> get _internalList => unsafeValue ?? [];

  @override
  void _emitList(List<T> list) => emit(list);
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
