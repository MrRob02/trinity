import 'package:flutter/material.dart';
import 'package:trinity/node.dart';
import 'package:trinity/node_interface.dart';
// ─────────────────────────────────────────────
// _NodeRegistry — registro interno del scope
// ─────────────────────────────────────────────

class NodeRegistry {
  final Map<Type, Node> _nodes = {};
  void register<N extends Node>(N node) {
    assert(
      !_nodes.containsKey(N),
      'Type $N Node already exists in this scope. '
      'Use a nested TrinityScope if you need a separate instance.',
    );
    _nodes[N] = node;
    node.onInit();
  }

  void unregister<N extends Node>(N node) {
    _nodes.remove(N);
    node.dispose();
  }

  N? get<N extends Node>() => _nodes[N] as N?;

  void disposeAll() {
    for (final node in _nodes.values) {
      node.onDispose();
    }
    _nodes.clear();
  }
}

// ─────────────────────────────────────────────
// TrinityScope
// ─────────────────────────────────────────────

class InheritedTrinityScope extends InheritedWidget {
  final NodeRegistry registry;

  const InheritedTrinityScope({
    super.key,
    required this.registry,
    required super.child,
  });

  static InheritedTrinityScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InheritedTrinityScope>();
    assert(
      scope != null,
      'Couldn\'t find a TrinityScope in the widget tree. Did you wrap your app with TrinityScope?',
    );
    return scope!;
  }

  /// Busca N desde el scope más cercano hacia arriba
  N find<N extends NodeInterface>(BuildContext context) {
    final node = registry.get<N>();
    if (node != null) return node;

    // Sube al siguiente scope
    final parent = _findParentScope(context);
    if (parent != null) return parent.find<N>(context);

    throw FlutterError(
      'Node of type $N not found in any TrinityScope.\n'
      'Make sure to register it with a NodeProvider.',
    );
  }

  InheritedTrinityScope? _findParentScope(BuildContext context) {
    InheritedTrinityScope? result;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is InheritedTrinityScope && widget != this) {
        result = widget;
        return false; // detiene la búsqueda
      }
      return true;
    });
    return result;
  }

  @override
  bool updateShouldNotify(InheritedTrinityScope old) => false;

  // Dentro de TrinityScope
  N findByType<N extends NodeInterface>() {
    final node = registry.get<N>();
    if (node != null) return node;

    // Sube al scope padre si existe
    // Como el scope es global único por ahora, esto simplemente falla
    throw FlutterError(
      'Node of type $N not found in the TrinityScope.\n'
      'Make sure to register it with a NodeProvider.',
    );
  }
}
// ─────────────────────────────────────────────
// Extension para acceso limpio desde el contexto
// ─────────────────────────────────────────────

extension TrinityContextExtension on BuildContext {
  N findNode<N extends NodeInterface>() =>
      InheritedTrinityScope.of(this).find<N>(this);
}
