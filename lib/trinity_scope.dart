import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trinity/models/bridge_signal.dart';
import 'package:trinity/models/signal.dart';
part 'node.dart';
// ─────────────────────────────────────────────
// _NodeRegistry — registro interno del scope
// ─────────────────────────────────────────────

class _NodeRegistry {
  final Map<Type, _Node> _nodes = {};
  void register<N extends _Node>(N node) {
    assert(
      !_nodes.containsKey(N),
      'Node de tipo $N ya existe en este scope. '
      'Usa un TrinityScope anidado si necesitas una instancia separada.',
    );
    _nodes[N] = node;
    node.onInit();
  }

  void unregister(_Node node) {
    _nodes.remove(node.runtimeType);
    node._dispose();
  }

  N? get<N extends _Node>() => _nodes[N] as N?;

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
  final _NodeRegistry _registry;

  const InheritedTrinityScope._({
    required _NodeRegistry registry,
    required super.child,
  }) : _registry = registry;

  static InheritedTrinityScope of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<InheritedTrinityScope>();
    assert(scope != null, 'No se encontró ningún TrinityScope en el árbol.');
    return scope!;
  }

  /// Busca N desde el scope más cercano hacia arriba
  N find<N extends NodeInterface>(BuildContext context) {
    final node = _registry.get<N>();
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
    final node = _registry.get<N>();
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
// Widget público que crea el scope
// ─────────────────────────────────────────────

class TrinityScope extends StatefulWidget {
  final Widget child;
  const TrinityScope({super.key, required this.child});

  @override
  State<TrinityScope> createState() => _TrinityScopeState();
}

class _TrinityScopeState extends State<TrinityScope> {
  final _NodeRegistry _registry = _NodeRegistry();

  @override
  void dispose() {
    _registry.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedTrinityScope._(registry: _registry, child: widget.child);
  }
}

// ─────────────────────────────────────────────
// NodeProvider — registra y desecha un Node
// ─────────────────────────────────────────────

class NodeProvider<N extends NodeInterface> extends StatefulWidget {
  final List<N Function()> nodes;
  final Widget? child;
  final Widget Function(BuildContext context, N node)? builder;

  ///Use this widget to create a node and provide it to the widget tree,
  ///you can use [NodeProvider.builder] if you need to build the widget tree
  ///and access directly to the node.
  NodeProvider({super.key, required N Function() create, required this.child})
    : builder = null,
      nodes = [create];
  const NodeProvider.multiple({
    super.key,
    required this.nodes,
    required this.child,
  }) : builder = null;

  NodeProvider.builder({
    super.key,
    required N Function() create,
    required this.builder,
  }) : child = null,
       nodes = [create];

  @override
  State<NodeProvider<N>> createState() => _NodeProviderState<N>();
}

class _NodeProviderState<N extends NodeInterface>
    extends State<NodeProvider<N>> {
  late final List<N> _nodes;
  _NodeRegistry? _registry;

  @override
  void initState() {
    super.initState();
    _nodes = widget.nodes.map((e) => e()).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registry == null) {
      final scope = InheritedTrinityScope.of(context);
      _registry = scope._registry;
      for (final node in _nodes) {
        node._attach(scope); // ← inyecta el scope
        _registry!.register(node); // ← llama onInit internamente
        WidgetsBinding.instance.addPostFrameCallback((_) {
          node.onReady(); // ← después del primer frame
        });
      }
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      _registry?.unregister(node); // ← llama onDispose internamente
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder != null
      ? widget.builder!(context, _nodes.first)
      : widget.child!;
}

// ─────────────────────────────────────────────
// Extension para acceso limpio desde el contexto
// ─────────────────────────────────────────────

extension TrinityContextExtension on BuildContext {
  N findNode<N extends NodeInterface>() =>
      InheritedTrinityScope.of(this).find<N>(this);
}
