// ─────────────────────────────────────────────
// NodeProvider — registra y desecha un Node
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:trinity/node_interface.dart';
import 'package:trinity/node_anatomy.dart';

class NodeProvider<N extends NodeInterface> extends StatefulWidget {
  final List<N Function()> nodes;
  final Widget? child;
  final Widget Function(BuildContext context, N node)? builder;
  final bool reuse;

  ///Use this widget to create a node and provide it to the widget tree
  NodeProvider({super.key, required N Function() create, required this.child})
    : builder = null,
      nodes = [create],
      reuse = false;
  const NodeProvider.many({super.key, required this.nodes, required this.child})
    : builder = null,
      reuse = false;

  ///If the node you want to use might be created in a parent scope
  ///use this constructor.
  ///
  ///If node exists, it won't be recreated.
  NodeProvider.reuse({
    super.key,
    required N Function() create,
    required this.builder,
  }) : child = null,
       nodes = [create],
       reuse = true;

  ///You can use [NodeProvider.builder] if you need to build the widget tree
  ///and access directly to the node.
  ///
  ///**It won't rebuild the widget tree**
  NodeProvider.builder({
    super.key,
    required N Function() create,
    required this.builder,
  }) : child = null,
       reuse = false,
       nodes = [create];

  @override
  State<NodeProvider<N>> createState() => NodeProviderState<N>();
}

class NodeProviderState<N extends NodeInterface>
    extends State<NodeProvider<N>> {
  List<N>? _nodes;
  final Map<N, bool> _shouldDispose = {};
  NodeRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_registry != null) return; // ya inicializado

    final scope = InheritedTrinityScope.of(context);
    _registry = scope.registry;

    // Siempre creamos el nodo para conocer su runtimeType concreto
    _nodes = widget.nodes.map((factory) => factory()).toList();

    for (final node in _nodes!) {
      if (widget.reuse) {
        // Busca si ya existe un nodo con el mismo tipo concreto
        final existing = _registry!.getByRuntimeType(node.runtimeType);
        if (existing != null && existing is N) {
          // Ya existe el mismo tipo concreto → reutilizar
          _nodes = [existing];
          _shouldDispose[existing] = false;
          return;
        }
      }

      // No existe (o no es reuse) → registrar
      _shouldDispose[node] = true;
      node.attach(scope);
      _registry!.register<N>(node);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        node.onReady();
      });
    }
  }

  @override
  void dispose() {
    for (final node in _nodes ?? []) {
      if (_shouldDispose[node] == true) {
        node.dispose();
        _registry?.unregister<N>(node); // ← llama onDispose internamente
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder != null
      ? widget.builder!(context, _nodes!.first)
      : widget.child!;
}
