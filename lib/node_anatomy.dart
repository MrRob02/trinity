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
      'Node de tipo $N ya existe en este scope. '
      'Usa un TrinityScope anidado si necesitas una instancia separada.',
    );
    _nodes[N] = node;
    node.onInit();
  }

  void unregister(Node node) {
    _nodes.remove(node.runtimeType);
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
    assert(scope != null, 'No se encontró ningún TrinityScope en el árbol.');
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
      'Node de tipo $N no encontrado en ningún TrinityScope.\n'
      'Asegúrate de registrarlo con un NodeProvider.',
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
      'Node de tipo $N no encontrado en el TrinityScope.\n'
      'Asegúrate de registrarlo con un NodeProvider.',
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
