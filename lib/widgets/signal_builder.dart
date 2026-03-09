import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trinity/models/base_signal.dart';
import 'package:trinity/trinity.dart';

class SignalBuilder<S> extends StatefulWidget {
  ///You can choose any Node that is an ancestor of the current widget.
  ///No matter how far away it is, just make it explicit like this:
  ///
  ///```dart
  ///SignalBuilder(
  ///  signal: node.yourSignal,
  ///  builder: (context, value) {
  ///    return Text(value);
  ///  },
  ///)
  ///```
  final BaseSignal<S> signal;
  final Widget Function(BuildContext context, S value) builder;
  final Function(S previousValue, S newValue)? listener;
  final bool isListener;

  const SignalBuilder({super.key, required this.signal, required this.builder})
    : isListener = false,
      listener = null;

  ///Use `SignalListener` instead.
  ///
  ///This is only an internal package constructor.
  ///You're not supposed to use this constructor directly.
  @protected
  const SignalBuilder.listener({
    super.key,
    required this.signal,
    required this.listener,
    required this.builder,
  }) : isListener = true;

  @override
  State<SignalBuilder<S>> createState() => _SignalBuilderState<S>();
}

class _SignalBuilderState<S> extends State<SignalBuilder<S>> {
  StreamSubscription? _subscription;
  S? _previousValue;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initFutures({widget.signal});
      });
    }
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant SignalBuilder<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription = widget.signal.stream.listen((value) {
      widget.listener?.call(_previousValue as S, value);
      _previousValue = value;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.signal.attachedNode;
    assert(
      node.initialized,
      'The node ${node.runtimeType} is not initialized. Use [NodeProvider] to provide the node to the scope.',
    );
    assert(node.isSignalRegistered(widget.signal), '''
      Signal is not registered
      This might be because you created the signals directly instead of using [registerSignal]
      In order to fix this, you need to use [registerSignal] to register your signals.
''');

    return widget.builder(context, widget.signal.value);
  }
}

class SignalBuilderMany<R> extends StatefulWidget {
  final Set<BaseSignal> signals;
  final Widget Function(BuildContext context, R readable) builder;
  final Function()? listener;

  ///IMPORTANT!!
  ///
  ///Even though you have access to all signals in the node through the readable
  ///the widget will only rebuild when one of the [signals] in the list changes.
  ///
  ///This widget was created for cases where you need to listen to many (more than 2) signals.
  ///We strongly recommend you to use [SignalBuilder] instead if you only need to listen to one or two signals.
  const SignalBuilderMany({
    super.key,
    required this.signals,
    required this.builder,
    this.listener,
  });

  @override
  State<SignalBuilderMany<R>> createState() => _SignalBuilderManyState<R>();
}

class _SignalBuilderManyState<R> extends State<SignalBuilderMany<R>> {
  List<StreamSubscription> _subscriptions = [];
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initFutures(widget.signals);
      });
    }
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant SignalBuilderMany<R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe();
  }

  void _subscribe() {
    _cancelSubscriptions();
    _subscriptions = widget.signals
        .map(
          (s) => s.stream.listen((_) {
            if (mounted) {
              setState(() {});
              widget.listener?.call();
            }
          }),
        )
        .toList();
  }

  void _cancelSubscriptions() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.signals.every((s) => s.attachedNode.initialized),
      'One or more nodes are not initialized. Use [NodeProvider] to provide the node to the scope.',
    );
    assert(
      widget.signals.every((s) => s.attachedNode.isSignalRegistered(s)),
      'One or more signals are not registered. Use [registerSignal].',
    );

    return widget.builder(
      context,
      widget.signals.first.attachedNode.readable as R,
    );
  }
}

void _initFutures<S>(Set<BaseSignal<S>> signals) {
  for (var signal in signals) {
    if (signal is FutureSignal) {
      (signal as FutureSignal).fetch();
    }
  }
}
