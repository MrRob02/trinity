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
    return widget.builder(context, widget.signal(node).value);
  }
}
