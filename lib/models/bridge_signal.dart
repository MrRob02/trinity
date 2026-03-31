import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trinity/models/base_bridge_signal.dart';
import 'package:trinity/models/signal.dart';
import 'package:trinity/node_interface.dart';
import 'package:trinity/node_anatomy.dart';

/// A bridge that mirrors a parent node's signal with no transformation.
///
/// [N] is the parent node type where the source signal lives.
///
/// [S] is both the source signal type and the bridge's value type (V == S).
///
/// The value setter writes directly back to the parent signal.
///
/// ```dart
/// late final edad = registerSignal(
///   BridgeSignal(select: (FormNode node) => node.edad),
/// );
/// ```
class BridgeSignal<N extends NodeInterface, V> extends BaseBridgeSignal<V> {
  StreamSubscription<V>? _subscription;
  late final N _parentNode;

  final Signal<V> Function(N node) _select;

  BridgeSignal({required Signal<V> Function(N) select})
    : _select = select;

  @override
  set value(covariant V newValue) {
    _select(_parentNode).value = newValue;
  }

  @override
  V get value => _select(_parentNode).value;

  @override
  @protected
  void connect(InheritedTrinityScope scope) {
    final node = _parentNode = scope.findByType<N>();
    final parentSignal = _select(node);

    emit(parentSignal.value);

    _subscription = parentSignal.streamTriggerImmediatly.listen((data) {
      emit(data);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// A bridge that transforms a parent signal's value into a different type.
///
/// [N] is the parent node type.
///
/// [S] is the source signal type.
///
/// [V] is the transformed value type (can differ from S, value is nullable).
///
/// ```dart
/// late final order = registerSignal(
///   TransformBridgeSignal(
///     select: (OrdersNode node) => node.orders,
///     transform: (orders) => orders.firstWhereOrNull((o) => o.id == id),
///     update: (node, value) {
///       if (value == null) return;
///       node.updateOrder(value);
///     },
///   ),
/// );
/// ```
class TransformBridgeSignal<N extends NodeInterface, S, V>
    extends BaseBridgeSignal<V> {
  StreamSubscription<S>? _subscription;
  late final N _parentNode;

  final Signal<S> Function(N node) _select;
  final V Function(S value) _transform;
  final void Function(N node, V value)? _update;

  TransformBridgeSignal({
    required Signal<S> Function(N node) select,
    required V Function(S value) transform,
    void Function(N node, V value)? update,
  }) : _select = select,
       _transform = transform,
       _update = update;

  @override
  set value(covariant V newValue) {
    assert(_update != null, 'You didn\'t provide an update function');
    _update?.call(_parentNode, newValue);
  }

  @override
  @protected
  void connect(InheritedTrinityScope scope) {
    final node = _parentNode = scope.findByType<N>();
    final parentSignal = _select(node);
    final initialValue = _transform(parentSignal.value);

    emit(initialValue);

    _subscription = parentSignal.streamTriggerImmediatly.listen((data) {
      final transformed = _transform(data);
      emit(transformed);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
