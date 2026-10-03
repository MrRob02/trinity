import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:trinity/signals/base_signal.dart';
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
  final Function(S previous, S current)? listener;
  final bool isListener;

  const SignalBuilder({super.key, required this.signal, required this.builder})
    : isListener = false,
      listener = null;

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
      _previousValue = widget.signal.value;
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

class ManySignalsBuilder<R> extends StatefulWidget {
  final Set<BaseSignal> signals;
  final Widget Function(BuildContext context, R readable)? readableBuilder;
  final Widget Function(BuildContext context)? builder;
  final Function()? listener;

  ///Creates a `ManySignalsBuilder` for a given set of signals.
  ///Use this constructor when you need to listen to a specific subset of signals
  ///from a node or when you are working with signals that are not part of a node.
  ///
  ///If you need to listen to all signals in a node, use `ManySignalsBuilder.all`.
  ///
  ///If you need to listen to all signals in a node and have access to the node's readable,
  ///use `ManySignalsBuilder.readable`.
  const ManySignalsBuilder({
    super.key,
    required this.signals,
    required Widget Function(BuildContext context) this.builder,
    this.listener,
  }) : readableBuilder = null;

  ///Creates a `ManySignalsBuilder` for all the signals in a node.
  ///
  ///You can also use `ManySignalsBuilder.readable` to create a `ManySignalsBuilder` for a node
  ///that provides access to all signals in the node through the readable.
  ManySignalsBuilder.all({
    super.key,
    required Node node,
    required Widget Function(BuildContext context) this.builder,
    this.listener,
  }) : readableBuilder = null,
       signals = node.signals.toSet();

  ///IMPORTANT!!
  ///
  ///Even though you have access to all signals in the node through the readable
  ///the widget will only rebuild when one of the `signals` in the list changes.
  ///
  ///This widget was created for cases where you need to listen to many (more than 2) signals.
  ///We strongly recommend you to use `SignalBuilder` instead if you only need to listen to one or two signals.
  const ManySignalsBuilder.readable({
    super.key,
    required this.signals,
    required Widget Function(BuildContext context, R readable) builder,
    this.listener,
  }) : readableBuilder = builder,
       builder = null;

  @override
  State<ManySignalsBuilder<R>> createState() => _ManySignalsBuilderState<R>();
}

class _ManySignalsBuilderState<R> extends State<ManySignalsBuilder<R>> {
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
  void didUpdateWidget(covariant ManySignalsBuilder<R> oldWidget) {
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
    if (widget.builder != null) {
      return widget.builder!(context);
    }
    assert(
      widget.signals.isNotEmpty,
      'Signals set cannot be empty in ManySignalsBuilder.readable.',
    );
    return widget.readableBuilder!(
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

@Deprecated('Use ManySignalsBuilder.readable instead')
class SignalBuilderMany<R> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ManySignalsBuilder<R>.readable(
      signals: signals,
      builder: builder,
      listener: listener,
    );
  }
}
