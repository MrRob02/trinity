part of 'signal.dart';

class BoolSignal extends Signal<bool> {
  BoolSignal(super.value);
  BoolSignal.deferred() : super.deferred();

  /// Toggle the value of the signal
  ///
  /// Example:
  /// ```dart
  /// final signal = BoolSignal(false);
  /// signal.toggle();
  /// print(signal.value); // true
  /// ```
  void toggle() {
    value = !value;
  }
}
