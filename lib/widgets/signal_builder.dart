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

      You might have something like:

      class MyNode extends NodeInterface {
        final mySignal = Signal<String>();
      }

      Instead of:

      class MyNode extends NodeInterface {
        late final mySignal = registerSignal(Signal<String>());
      }

      In order to fix this, you need to use [registerSignal] to register your signals.
''');
    return widget.builder(context, signal.value);
  }
}
