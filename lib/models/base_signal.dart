import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:trinity/trinity.dart';

/// Internal base class containing the "raw" state and stream logic.
/// Signal extends this, but ReadableSignal only wraps it.
abstract class BaseSignal<T> {
  late T _value;
  bool _isInitialized = false;
  final controller = StreamController<T>.broadcast();

  late final Node attachedNode;

  BaseSignal(T value) {
    _value = value;
    _isInitialized = true;
  }

  BaseSignal.deferred();

  T get value => _value;

  @protected
  T get unsafeValue => _value;

  @protected
  set unsafeValue(T v) {
    _value = v;
    _isInitialized = true;
  }

  Stream<T> get stream => controller.stream;

  Stream<T> get streamTriggerImmediatly => _isInitialized 
      ? controller.stream.startWith(_value)
      : controller.stream;

  @mustCallSuper
  void dispose() {
    controller.close();
  }
}
