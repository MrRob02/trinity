import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:trinity/models/async_value.dart';
part 'future_signal.dart';
part 'stream_signal.dart';

/// Internal base class containing the "raw" state and stream logic.
/// Signal extends this, but ReadableSignal only wraps it.
abstract class BaseSignal<T> {
  T _value;
  final _controller = StreamController<T>.broadcast();

  BaseSignal(this._value);

  T get value => _value;

  @protected
  T get unsafeValue => _value;

  Stream<T> get stream => _controller.stream;

  Stream<T> get streamTriggerImmediatly => _controller.stream.startWith(_value);

  @mustCallSuper
  void dispose() {
    _controller.close();
  }
}

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

  void emit(T newValue) {
    if (_value == newValue) return; // Small optional optimization
    _value = newValue;
    _controller.add(newValue);
  }
}

class NullableSignal<T> extends BaseSignal<T?> {
  NullableSignal([super.value]);

  @protected
  set value(T? newValue) => emit(newValue);

  void emit(T? newValue) {
    if (_value == newValue) return; // Small optional optimization
    _value = newValue;
    _controller.add(newValue);
  }

  /// This is the readable public exposed signal.
  /// It is created by the Signal constructor and is used to access the signal's value and stream.
  late final ReadableSignal<T?> readable = ReadableSignal._(this);
}
