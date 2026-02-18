// ─────────────────────────────────────────────
// Base Node
// ─────────────────────────────────────────────

part of 'trinity_scope.dart';

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
abstract class _Node {
  late final TrinityScope _scope; //*
  bool _initialized = false;

  // Llamado por NodeProvider al registrar
  void _attach(TrinityScope scope) {
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
  void _dispose() {
    for (final bridge in _bridges) {
      bridge.dispose();
    }
    for (final signal in _signals) {
      signal.dispose();
    }
    onDispose();
    log('$runtimeType and signals disposed');
  }
}

///You can use this class to add loading and error states to your nodes
///```dart
/// ReadableSignal<bool> isLoading
///
/// ReadableSignal<Object?> error
///
/// //A separate signal for full screen loading
/// ReadableSignal<bool> fullScreenLoading
///
/// //You can use the [loading] method to wrap any async operation
/// //so you don't have to handle the loading state yourself
/// Future<T> loading<T>(
///    Future<T> future, {
///    bool invokeLoading = true,
///    //If you want to show a full screen loading, just set this to true
///    bool fullScreen = false,
///  })
///```
abstract class NodeInterface extends _Node {
  late final _isLoading = registerSignal(Signal<bool>(false));
  late final _fullScreenLoading = registerSignal(Signal<bool>(false));
  late final _error = registerSignal(NullableSignal<Object>());
  ReadableSignal<bool> get isLoading => _isLoading.readable;
  ReadableSignal<bool> get fullScreenLoading => _fullScreenLoading.readable;
  ReadableSignal<Object?> get error => _error.readable;

  Future<T> loading<T>(
    Future<T> future, {
    bool invokeLoading = true,
    bool fullScreen = false,
  }) async {
    if (invokeLoading) {
      if (fullScreen) {
        _fullScreenLoading.value = true;
      } else {
        _isLoading.value = true;
      }
    }
    try {
      return await future;
    } catch (e) {
      _error.emit(e);
      rethrow;
    } finally {
      if (invokeLoading) {
        if (fullScreen) {
          _fullScreenLoading.value = false;
        } else {
          _isLoading.value = false;
        }
      }
    }
  }
}
