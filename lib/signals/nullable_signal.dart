import 'package:trinity/signals/signal.dart';

///
class NullableSignal<T> extends Signal<T?> {
  NullableSignal([super.value]);

  R? use<R>(R Function(T value) builder) {
    if (value == null) return null;
    return builder(value as T);
  }
}
