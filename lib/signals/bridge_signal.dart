import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trinity/signals/base_signal.dart';
import 'package:trinity/signals/signal.dart';
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
class BridgeSignal<N extends NodeInterface, V> extends ProtectedSignal<V> {
  StreamSubscription<V>? _subscription;
  late final N _parentNode;

  final BaseSignal<V> Function(N node) _select;

  BridgeSignal({required BaseSignal<V> Function(N) select})
    : _select = select,
      super.deferred();

  @override
  V get value => _select(_parentNode).value;

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
    extends ProtectedSignal<V> {
  StreamSubscription<S>? _subscription;

  final BaseSignal<S> Function(N node) _select;
  final V Function(S value) _transform;

  TransformBridgeSignal({
    required BaseSignal<S> Function(N node) select,
    required V Function(S value) transform,
    void Function(N node, V value)? update,
  }) : _select = select,
       _transform = transform,
       super.deferred();

  @protected
  void connect(InheritedTrinityScope scope) {
    final node = scope.findByType<N>();
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
