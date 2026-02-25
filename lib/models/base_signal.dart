import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

/// Internal base class containing the "raw" state and stream logic.
/// Signal extends this, but ReadableSignal only wraps it.
abstract class BaseSignal<T> {
  T _value;
  final controller = StreamController<T>.broadcast();

  BaseSignal(this._value);

  T get value => _value;

  @protected
  T get unsafeValue => _value;

  @protected
  set unsafeValue(T v) => _value = v;

  Stream<T> get stream => controller.stream;

  Stream<T> get streamTriggerImmediatly => controller.stream.startWith(_value);

  @mustCallSuper
  void dispose() {
    controller.close();
  }
}
