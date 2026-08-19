import 'package:trinity/signals/base_signal.dart';
import 'package:trinity/node_anatomy.dart';

abstract class BaseBridgeSignal<V> extends BaseSignal<V> {
  BaseBridgeSignal() : super.deferred();

  void connect(InheritedTrinityScope scope);
}
