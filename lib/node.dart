// ─────────────────────────────────────────────
// Base Node
// ─────────────────────────────────────────────

// ignore_for_file: unintended_html_in_doc_comment

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trinity/models/base_bridge_signal.dart';
import 'package:trinity/models/base_signal.dart';
import 'package:trinity/node_anatomy.dart';

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
  void attach(InheritedTrinityScope scope) {
    assert(!_initialized, 'Node ya fue inicializado.');
    _scope = scope; //*
    for (final bridge in _bridges) {
      bridge.connect(scope); // busca el Node B y se suscribe
    }
    _initialized = true;
  }

  //*
  // // API pública para buscar otros Nodes desde dentro del Node
  // N _findNode<N extends Node>() {
  //   assert(_initialized, 'No puedes llamar findNode antes de onReady.');
  //   return _scope.findByType<N>();
  // }

  final List<BaseBridgeSignal> _bridges = [];
  final List<BaseSignal> _signals = [];

  @protected
  void registerManyBridges(List<BaseBridgeSignal> bridges) {
    _bridges.addAll(bridges);
    if (_initialized) {
      for (final bridge in bridges) {
        bridge.connect(_scope);
      }
    }
  }

  @protected
  S registerSignal<S extends BaseSignal>(S signal) {
    if (signal is BaseBridgeSignal) {
      _bridges.add(signal);
      if (_initialized) {
        signal.connect(_scope);
      }
    }
    _signals.add(signal);
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
  ///You will use it for the [ManSignalBuilder]
  ///
  ///You can generate it with build_runner and the value
  ///should be Readable<YourNodeName>(this)
  @protected
  dynamic get readable;
}
