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

  ///Use this widget to create a node and provide it to the widget tree,
  ///you can use [NodeProvider.builder] if you need to build the widget tree
  ///and access directly to the node.
  NodeProvider({super.key, required N Function() create, required this.child})
    : builder = null,
      nodes = [create];
  const NodeProvider.many({super.key, required this.nodes, required this.child})
    : builder = null;

  NodeProvider.builder({
    super.key,
    required N Function() create,
    required this.builder,
  }) : child = null,
       nodes = [create];

  @override
  State<NodeProvider<N>> createState() => NodeProviderState<N>();
}

class NodeProviderState<N extends NodeInterface>
    extends State<NodeProvider<N>> {
  late final List<N> _nodes;
  NodeRegistry? _registry;

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
      _registry = scope.registry;
      for (final node in _nodes) {
        node.attach(scope); // ← inyecta el scope
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
