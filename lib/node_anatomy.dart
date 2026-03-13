import 'package:flutter/material.dart';
import 'package:trinity/node.dart';
import 'package:trinity/node_interface.dart';
// ─────────────────────────────────────────────
// _NodeRegistry — registro interno del scope
// ─────────────────────────────────────────────

class NodeRegistry {
  final Map<Key, Node> _nodes = {};

  void register<N extends Node>(N node) {
    final key = node.runtimeKey;
    assert(
      !_nodes.containsKey(key),
      'Node of type $key already exists in this scope.\n\n'
      'Solutions:\n'
      '1. Find the anscestor node using [context.findNode<YourNode>()].\n'
      '2. Force creation by adding a key to your node using [key] parameter in constructor.\n'
      '3. Create a new node or use the existing one by using [NodeProvider.reuse].\n',
    );
    _nodes[key] = node;
    node.onInit();
  }

  void dispose<N extends Node>(N node) {
    _nodes.remove(node.runtimeKey);
    node.dispose();
  }

  /// Looks up a node by type compatibility (supports interfaces).
  N? getOrNull<N extends Node>({Key? key}) {
    if (key != null) {
      final exact = getByKey(key);
      if (exact is N) return exact;
      return null;
    }
    // Exact match first
    final exact = _nodes[Key(N.toString())];
    if (exact is N) return exact;
    // Subtype match (e.g. find ProductsNode via CatalogueControllerInterface)
    for (final node in _nodes.values) {
      if (node is N) return node;
    }
    return null;
  }

  /// Checks if a node with this exact [runtimeType] already exists.
  Node? getByRuntimeType(Type type) => _nodes[Key(type.toString())];

  /// Checks if a node with this exact [runtimeKey] already exists.
  Node? getByKey(Key key) => _nodes[key];

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
    final element = context
        .getElementForInheritedWidgetOfExactType<InheritedTrinityScope>();
    assert(
      element != null,
      'Couldn\'t find a TrinityScope in the widget tree. Did you wrap your app with TrinityScope?',
    );
    return element!.widget as InheritedTrinityScope;
  }

  /// Busca N desde el scope más cercano hacia arriba
  N find<N extends NodeInterface>(BuildContext context, {Key? key}) {
    final node = registry.getOrNull<N>(key: key);
    if (node != null) return node;

    // Sube al siguiente scope
    final parent = _findParentScope(context);
    if (parent != null) return parent.find<N>(context, key: key);

    throw FlutterError(
      'Node of type $N ${key != null ? 'with key $key ' : ''}not found in any TrinityScope.\n'
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
  N findByType<N extends NodeInterface>({Key? key}) {
    final node = registry.getOrNull<N>(key: key);
    if (node != null) return node;

    // Sube al scope padre si existe
    // Como el scope es global único por ahora, esto simplemente falla
    throw FlutterError(
      'Node of type $N ${key != null ? 'with key $key ' : ''}not found in the TrinityScope.\n'
      'Make sure to register it with a NodeProvider.',
    );
  }
}
// ─────────────────────────────────────────────
// Extension para acceso limpio desde el contexto
// ─────────────────────────────────────────────

extension TrinityContextExtension on BuildContext {
  N findNode<N extends NodeInterface>({Key? key}) =>
      InheritedTrinityScope.of(this).find<N>(this, key: key);
  N? findNodeOrNull<N extends NodeInterface>({Key? key}) =>
      InheritedTrinityScope.of(this).registry.getOrNull<N>(key: key);
}
