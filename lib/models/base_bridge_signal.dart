import 'package:trinity/models/signal.dart';
import 'package:trinity/node_anatomy.dart';

abstract class BaseBridgeSignal<V> extends Signal<V?> {
  BaseBridgeSignal(super.value);

  void connect(InheritedTrinityScope scope);
}
