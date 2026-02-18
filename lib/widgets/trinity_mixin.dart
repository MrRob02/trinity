import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trinity/models/signal.dart';
import 'package:trinity/trinity_scope.dart';

mixin TrinityMixin<T extends StatefulWidget> on State<T> {
  List<Signal> get signals;

  final List<StreamSubscription> _subscriptions = [];

  // Acceso limpio al Node desde el State
  N node<N extends NodeInterface>() => context.findNode<N>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final signal in signals) {
        _subscriptions.add(signal.stream.listen((_) => setState(() {})));
      }
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
