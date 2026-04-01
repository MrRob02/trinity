// ─────────────────────────────────────────────
// Base Node
// ─────────────────────────────────────────────

// ignore_for_file: unintended_html_in_doc_comment

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trinity/models/base_bridge_signal.dart';
import 'package:trinity/models/base_signal.dart';
// import 'package:trinity/models/node_link.dart';
import 'package:trinity/node_anatomy.dart';
import 'package:trinity/trinity.dart';

///The base class for all nodes.
///
///It is used to create nodes that can be used to store data and perform actions.
///
///If you want a more complete node you can use [NodeInterface].
///
//Uncomment the //*
//inside the Node class
//in case you need to find other nodes from inside the node.
//Right now we're not going to let developers access the scope from the node.
abstract class Node {
  late final InheritedTrinityScope _scope; //*
  bool _initialized = false;
  // Llamado por NodeProvider al registrar
  ///Returns true if the node was previously initialized, false otherwise
  bool attach(InheritedTrinityScope scope) {
    assert(
      !_initialized,
      'Node already initialized. If you want to reuse it, set the reuse parameter of your NodeProvider to true.',
    );
    _scope = scope; //*
    for (final bridge in _bridges) {
      bridge.connect(scope); // busca el Node B y se suscribe
    }
    for (final link in _links) {
      link.connect(scope); // resuelve y vincula la referencia
    }
    _initialized = true;
    return true;
  }

  final Key? key;
  @protected
  Key get runtimeKey {
    return key ?? Key(runtimeType.toString());
  }

  // API pública para buscar otros Nodes desde dentro del Node
  @protected
  N findNode<N extends NodeInterface>() {
    assert(_initialized, 'No puedes llamar findNode antes de onInit.');
    return _scope.findByType<N>();
  }

  N? findNodeOrNull<N extends NodeInterface>() {
    assert(_initialized, 'No puedes llamar findNode antes de onInit.');
    return _scope.findByTypeOrNull<N>();
  }

  final List<BaseBridgeSignal> _bridges = [];
  final List<_NodeLink> _links = [];
  final List<BaseSignal> _signals = [];

  Node({required this.key});

  // @protected
  // L _linkNode<L extends _NodeLink>(L link) {
  //   _links.add(link);
  //   if (_initialized) {
  //     link.connect(_scope);
  //   }
  //   return link;
  // }

  @protected
  S registerSignal<S extends BaseSignal>(S signal) {
    if (signal is BaseBridgeSignal) {
      _bridges.add(signal);
      if (_initialized) {
        signal.connect(_scope);
      }
    }
    _signals.add(signal);
    signal.attachedNode = this;
    return signal;
  }

  ///We use this to improve optimization
  bool isSignalRegistered(BaseSignal signal) {
    return _signals.contains(signal);
  }

  // ── Ciclo de vida ──────────────────────────

  /// Primer punto de entrada, el scope ya está disponible
  void onInit() {}

  /// Después del primer frame, contexto de UI listo
  @protected
  void onReady() {}

  /// Cuando el NodeProvider se desmonta
  void onDispose() {}

  /// Método interno llamado por el framework para limpiar recursos
  void dispose() {
    for (final bridge in _bridges) {
      bridge.dispose();
    }
    for (final signal in _signals) {
      signal.dispose();
    }
    onDispose();
    log('$runtimeType and signals disposed');
  }

  ///This is the readable version of the node
  ///It is used to access the signals of the node directly by its value.
  ///
  ///You will use it for the `ManySignalBuilder`
  ///
  ///In order to use it you need to generate it with
  ///`build_runner` and the value should be
  ///```dart
  ///ReadableYourNode get readable => ReadableYourNode(this)
  ///```
  @protected
  dynamic get readable => null;

  bool get initialized => _initialized;
}

/// A link to another node in the Trinity widget tree.
/// It automatically resolves the selected node when the parent node connects.
///
/// ```dart
/// late final userNode = linkNode(NodeLink<UserNode>());
///
/// void doSomething() {
///   userNode.value.logout();
/// }
/// ```
class _NodeLink<N extends NodeInterface> {
  late final N value;

  void connect(InheritedTrinityScope scope) {
    value = scope.findByType<N>();
  }
}
