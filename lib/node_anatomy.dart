import 'package:flutter/material.dart';
import 'package:trinity/node.dart';
import 'package:trinity/node_interface.dart';
// ─────────────────────────────────────────────
// _NodeRegistry — registro interno del scope
// ─────────────────────────────────────────────

class NodeRegistry {
  final Map<Type, Node> _nodes = {};

  void register<N extends Node>(N node) {
    final key = node.runtimeType;
    assert(
      !_nodes.containsKey(key),
      'Node of type $key already exists in this scope.\n\n'
      'Solutions:\n'
      '1. Use context.findNode<YourNode>().\n'
      '2. Use a nested TrinityScope if you need a separate instance.\n'
      '3. Use NodeProvider.reuse\n',
    );
    _nodes[key] = node;
    node.onInit();
  }

  void unregister<N extends Node>(N node) {
    _nodes.remove(node.runtimeType);
    node.dispose();
  }

  /// Looks up a node by type compatibility (supports interfaces).
  N? getOrNull<N extends Node>() {
    // Exact match first
    final exact = _nodes[N];
    if (exact != null) return exact as N;
    // Subtype match (e.g. find ProductsNode via CatalogueControllerInterface)
    for (final node in _nodes.values) {
      if (node is N) return node;
    }
    return null;
  }

  /// Checks if a node with this exact [runtimeType] already exists.
  Node? getByRuntimeType(Type type) => _nodes[type];

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
    final node = registry.getOrNull<N>();
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
    final node = registry.getOrNull<N>();
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
  N? findNodeOrNull<N extends NodeInterface>() =>
      InheritedTrinityScope.of(this).registry.getOrNull<N>();
}
