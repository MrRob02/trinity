import 'package:flutter/material.dart';
import 'package:trinity/node_anatomy.dart';

class TrinityScope extends StatefulWidget {
  final Widget child;
  const TrinityScope({super.key, required this.child});

  @override
  State<TrinityScope> createState() => _TrinityScopeState();
}

class _TrinityScopeState extends State<TrinityScope> {
  final NodeRegistry _registry = NodeRegistry();

  @override
  void dispose() {
    _registry.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InheritedTrinityScope(registry: _registry, child: widget.child);
  }
}
