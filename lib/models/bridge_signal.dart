import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trinity/models/signal.dart';
import 'package:trinity/trinity_scope.dart';

abstract class BaseBridgeSignal<V> extends Signal<V?> {
  BaseBridgeSignal(super.value);

  void connect(InheritedTrinityScope scope);
}

///[N] is the refrence node where we'll search the reference signal.
///
///[S] is the type of the reference signal.
///
///[V] is the type of the bridge signal.
///
///When you create a bridge on your child Node you must register inside the bridges using
///[registerBridge] or [registerManyBridges].
///
///You should never expose it to widgets, in order to read the state you need to use
///[readableSignal] through any [SignalBuilder] available.
class BridgeSignal<N extends NodeInterface, S, V> extends BaseBridgeSignal<V> {
  StreamSubscription<S>? _subscription;
  late final N _parentNode;

  ///[select] is a function that will select the reference signal from the node.
  final ReadableSignal<S> Function(N node) select;

  ///[transform] is a function that will transform the value of the reference signal
  ///and then emit it.
  final V? Function(S value) transform;

  ///[_update] is a function that will update the value of the bridge signal.
  ///
  ///You should use Signal function value(newValue) to update
  ///
  ///You're not supposed to call this function outside the BridgeSignal constructor.
  ///This is only a reference to update value directly from father.
  final Function(N node, V? value) _update;

  BridgeSignal({
    required this.select,
    required this.transform,
    required Function(N, V?) update,
  }) : _update = update,
       super(null);

  @override
  set value(V? newValue) => _update(_parentNode, newValue);
  @override
  @protected
  void connect(InheritedTrinityScope scope) {
    final node = _parentNode = scope.findByType<N>();
    final parentSignal = select(node);
    final initialValue = transform(parentSignal.value);

    emit(initialValue);

    _subscription = parentSignal.streamTriggerImmediatly.listen((data) {
      final transformed = transform(data);
      emit(transformed);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
