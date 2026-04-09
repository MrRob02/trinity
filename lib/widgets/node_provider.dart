// ─────────────────────────────────────────────
// NodeProvider — registra y desecha un Node
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:trinity/node_anatomy.dart';
import 'package:trinity/trinity.dart';

class NodeProvider<N extends NodeInterface> extends StatefulWidget {
  final List<N Function()> nodes;
  final Widget? child;
  final Widget Function(BuildContext context, N node)? builder;
  final bool reuse;

  ///Use this widget to create a node and provide it to the widget tree
  NodeProvider({
    super.key,
    required N Function() create,
    required this.child,
    this.onInit,
  }) : builder = null,
       nodes = [create],
       reuse = false;
  const NodeProvider.many({super.key, required this.nodes, required this.child})
    : builder = null,
      reuse = false,
      onInit = null;

  ///This callback will be triggered when the widget is created
  ///No matter if the node is created or reused
  final void Function(N node)? onInit;

  ///If the node you want to use might be created in a parent scope
  ///but you don't want to recreate it,use this constructor.
  ///
  ///If node does not exist, it will be created.
  ///
  ///**❌ Don't do this:**
  ///
  ///```dart
  ///final yourNode = YourNode();
  ///NodeProvider.reuse(
  ///  create: () => yourNode,
  ///  builder: (context, node) => MyWidget(node: yourNode),
  ///);
  ///```
  ///The node returned by the builder might not be the one you created.
  ///
  ///**✅ Do this:**
  ///
  ///```dart
  ///NodeProvider.reuse(
  ///  create: () => YourNode(),
  ///  builder: (context, node) => MyWidget(node: node),
  ///);
  ///```
  NodeProvider.reuse({
    super.key,
    required N Function() create,
    required this.builder,
    this.onInit,
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
    this.onInit,
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
    if (_registry != null) return; // already initialized

    final scope = InheritedTrinityScope.of(context);
    _registry = scope.registry;

    // We always create the node to know its concrete runtimeType
    final createdNodes = widget.nodes.map((factory) => factory()).toList();
    final resolvedNodes = <N>[];

    for (final node in createdNodes) {
      if (widget.reuse) {
        //Search for a node with the same key
        final existing = _registry!.getByKey(node.runtimeKey);
        if (existing != null && existing is N) {
          // Ya existe el mismo nodo → reutilizar
          resolvedNodes.add(existing);
          _shouldDispose[existing] = false;
          continue;
        }
      }

      // Node does not exist (or reuse is false) → register
      resolvedNodes.add(node);
      _shouldDispose[node] = true;
      node.attach(scope);
      _registry!.register<N>(node);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        node.onReady();
      });
    }

    _nodes = resolvedNodes;
    //This will be called only once, only when there is only one node
    if (widget.nodes.length == 1) {
      widget.onInit?.call(_nodes!.first);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    onPopInvokedWithResult: (didPop, result) {
      //* We do it here because the dispose takes a long time to be removed
      if (didPop) {
        for (final node in _nodes ?? []) {
          if (_shouldDispose[node] == true) {
            _registry?.dispose<N>(node); // ← llama onDispose internamente
          }
        }
      }
    },
    child: widget.builder != null
        ? widget.builder!(context, _nodes!.first)
        : widget.child!,
  );
}
