import 'package:flutter/material.dart';
import 'package:trinity/models/base_signal.dart';
import 'package:trinity/node_anatomy.dart';
import 'package:trinity/trinity.dart';

class SignalListener<N extends NodeInterface, S> extends StatefulWidget {
  ///You can choose any Node that is an ancestor of the current widget.
  ///No matter how far away it is, just make it explicit like this:
  ///
  ///```dart
  ///SignalListener(
  ///  signal: (YourNode node) => node.yourSignal,
  ///  listener: (previousValue, newValue) {
  ///    print(newValue);
  ///  },
  ///  child: Text('Hello World'),
  ///)
  ///```
  final BaseSignal<S> Function(N) signal;
  final Function(S previousValue, S newValue)? listener;
  final Widget child;

  const SignalListener({
    super.key,
    required this.signal,
    required this.listener,
    required this.child,
  });

  @override
  State<SignalListener<N, S>> createState() => _SignalListenerState<N, S>();
}

class _SignalListenerState<N extends NodeInterface, S>
    extends State<SignalListener<N, S>> {
  @override
  Widget build(BuildContext context) {
    final node = context.findNode<N>();
    final signal = widget.signal(node);

    assert(node.isSignalRegistered(signal), '''
      Signal is not registered
      This might be because you created the signals directly instead of using [registerSignal]
      In order to fix this, you need to use [registerSignal] to register your signals.
''');

    return SignalBuilder.listener(
      signal: widget.signal,
      listener: widget.listener,
      builder: (_, _) {
        return widget.child;
      },
    );
  }
}

class SignalListenerMany<N extends NodeInterface<R>, R> extends StatefulWidget {
  final Set<BaseSignal> Function(N) signals;
  final Widget child;
  final Function()? listener;

  ///IMPORTANT!!
  ///
  ///Even though you have access to all signals in the node through the readable
  ///the widget will only rebuild when one of the [signals] in the list changes.
  ///
  ///This widget was created for cases where you need to listen to many (more than 2) signals.
  ///We strongly recommend you to use [SignalListener] instead if you only need to listen to one or two signals.
  const SignalListenerMany({
    super.key,
    required this.signals,
    required this.child,
    this.listener,
  });

  @override
  State<SignalListenerMany<N, R>> createState() =>
      _SignalListenerManyState<N, R>();
}

class _SignalListenerManyState<N extends NodeInterface<R>, R>
    extends State<SignalListenerMany<N, R>> {
  @override
  Widget build(BuildContext context) {
    final node = context.findNode<N>();

    assert(
      widget.signals(node).every((s) => node.isSignalRegistered(s)),
      'One or more signals are not registered. Use [registerSignal].',
    );

    return SignalBuilderMany(
      signals: widget.signals,
      listener: widget.listener,
      builder: (_, _) {
        return widget.child;
      },
    );
  }
}
