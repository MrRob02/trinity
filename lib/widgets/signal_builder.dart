import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trinity/models/signal.dart';
import 'package:trinity/trinity_scope.dart';

class SignalBuilder<N extends NodeInterface, S> extends StatefulWidget {
  final ReadableSignal<S> Function(N) signal;
  final Widget Function(BuildContext context, S value) builder;

  const SignalBuilder({super.key, required this.signal, required this.builder});

  @override
  State<SignalBuilder<N, S>> createState() => _SignalBuilderState<N, S>();
}

class _SignalBuilderState<N extends NodeInterface, S>
    extends State<SignalBuilder<N, S>> {
  StreamSubscription? _subscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant SignalBuilder<N, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    final node = context.findNode<N>();
    _subscription = widget.signal(node).stream.listen((_) {
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
    final node = context.findNode<N>();
    final signal = widget.signal(node);

    assert(node.isSignalRegistered(signal.source), '''
      Signal is not registered
      This might be because you created the signals directly instead of using [registerSignal]
      In order to fix this, you need to use [registerSignal] to register your signals.
''');

    return widget.builder(context, signal.value);
  }
}

class SignalBuilderMany<N extends NodeInterface<R>, R> extends StatefulWidget {
  final Set<Signal> Function(N) signals;

  ///IMPORTANT!!
  ///
  ///Even though you have access to all signals in the node through the readable
  ///the widget will only rebuild when one of the [signals] in the list changes.
  ///
  ///This widget was created for cases where you need to listen to many (more than 2) signals.
  ///We strongly recommend you to use [SignalBuilder] instead if you only need to listen to one or two signals.
  final Widget Function(BuildContext context, R readable) builder;

  const SignalBuilderMany({
    super.key,
    required this.signals,
    required this.builder,
  });

  @override
  State<SignalBuilderMany<N, R>> createState() =>
      _SignalBuilderManyState<N, R>();
}

class _SignalBuilderManyState<N extends NodeInterface<R>, R>
    extends State<SignalBuilderMany<N, R>> {
  List<StreamSubscription> _subscriptions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant SignalBuilderMany<N, R> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _subscribe();
  }

  void _subscribe() {
    _cancelSubscriptions();
    final node = context.findNode<N>();
    _subscriptions = widget
        .signals(node)
        .map(
          (s) => s.stream.listen((_) {
            if (mounted) setState(() {});
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
    final node = context.findNode<N>();

    assert(
      widget.signals(node).every((s) => node.isSignalRegistered(s)),
      'One or more signals are not registered. Use [registerSignal].',
    );

    return widget.builder(context, node.readable as R);
  }
}
