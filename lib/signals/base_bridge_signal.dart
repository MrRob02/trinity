import 'package:trinity/signals/signal.dart';
import 'package:trinity/node_anatomy.dart';

abstract class BaseBridgeSignal<V> extends Signal<V> {
  BaseBridgeSignal() : super.deferred();

  void connect(InheritedTrinityScope scope);
}
