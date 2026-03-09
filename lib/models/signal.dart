import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trinity/models/async_value.dart';
import 'package:trinity/models/base_signal.dart';
part 'future_signal.dart';
part 'stream_signal.dart';
part 'computed_signal.dart';

/// This class is just a read-only "view".
/// It does NOT extend BaseSignal to avoid inheriting internal behaviors,
/// acting instead as a proxy to the original signal.
class ReadableSignal<T> {
  final BaseSignal<T> _source;

  @protected
  BaseSignal<T> get source => _source;

  // Private constructor: Only a Signal can create its Readable counterpart.
  ReadableSignal._(this._source);

  T get value => _source.value;
  Stream<T> get stream => _source.stream;
  Stream<T> get streamTriggerImmediatly => _source.streamTriggerImmediatly;

  // Optional: hashcode and equals so they point to the original source
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadableSignal &&
          runtimeType == other.runtimeType &&
          _source == other._source;

  @override
  int get hashCode => _source.hashCode;
}

class Signal<T> extends BaseSignal<T> {
  Signal(super.value);

  /// This is the readable public exposed signal.
  /// It is created by the Signal constructor and is used to access the signal's value and stream.
  late final ReadableSignal<T> readable = ReadableSignal._(this);

  set value(T newValue) => emit(newValue);

  @protected
  void emit(T newValue) {
    if (unsafeValue == newValue) return; // Small optional optimization
    unsafeValue = newValue;
    controller.add(newValue);
  }
}

///
class NullableSignal<T> extends Signal<T?> {
  NullableSignal([super.value]);

  /// This is the readable public exposed signal.
  /// It is created by the Signal constructor and is used to access the signal's value and stream.
  late final ReadableSignal<T?> readable = ReadableSignal._(this);
}
