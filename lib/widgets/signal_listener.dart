import 'package:flutter/material.dart';
import 'package:trinity/models/base_signal.dart';
import 'package:trinity/trinity.dart';

class SignalListener<S> extends StatefulWidget {
  ///You can choose any Node that is an ancestor of the current widget.
  ///No matter how far away it is, just make it explicit like this:
  ///
  ///```dart
  ///SignalListener(
  ///  signal: node.yourSignal,
  ///  listener: (previousValue, newValue) {
  ///    print(newValue);
  ///  },
  ///  child: Text('Hello World'),
  ///)
  ///```
  final BaseSignal<S> signal;
  final Function(S previousValue, S newValue)? listener;
  final Widget child;

  const SignalListener({
    super.key,
    required this.signal,
    required this.listener,
    required this.child,
  });

  @override
  State<SignalListener<S>> createState() => _SignalListenerState<S>();
}

class _SignalListenerState<S> extends State<SignalListener<S>> {
  @override
  Widget build(BuildContext context) {
    final node = widget.signal.attachedNode;

    assert(node.isSignalRegistered(widget.signal), '''
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

class SignalListenerItem {
  final Widget Function(Widget child) _builder;

  SignalListenerItem._({required Widget Function(Widget child) builder})
      : _builder = builder;

  static SignalListenerItem of<R>({
    required BaseSignal<R> signal,
    void Function(R previousValue, R newValue)? listener,
  }) {
    return SignalListenerItem._(
      builder: (child) => SignalListener<R>(
        signal: signal,
        listener: listener,
        child: child,
      ),
    );
  }
}

class SignalListenerMany extends StatelessWidget {
  final List<SignalListenerItem> listeners;
  final Widget child;

  ///Listens to multiple signals, each with its own typed callback.
  ///
  ///Similar to MultiBlocListener, each [SignalListenerItem] independently
  ///listens to its signal without affecting the others.
  ///
  ///```dart
  ///SignalListenerMany(
  ///  listeners: [
  ///    SignalListenerItem.of(
  ///      signal: node.signalA,
  ///      listener: (prev, next) { ... },
  ///    ),
  ///    SignalListenerItem.of(
  ///      signal: node.signalB,
  ///      listener: (prev, next) { ... },
  ///    ),
  ///  ],
  ///  child: MyWidget(),
  ///)
  ///```
  const SignalListenerMany({
    super.key,
    required this.listeners,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return listeners.reversed.fold(
      child,
      (child, item) => item._builder(child),
    );
  }
}
