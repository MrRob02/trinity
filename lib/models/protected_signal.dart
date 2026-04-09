part of 'signal.dart';

///A signal that can only be read from the outside, but can be written to from the inside.
///It is used to wrap signals that are not meant to be modified by the outside world.
class ProtectedSignal<T> extends BaseSignal<T> {
  ProtectedSignal(super.value);
  ProtectedSignal.deferred() : super.deferred();

  /// This is the readable public exposed signal.
  /// It is created by the Signal constructor and is used to access the signal's value and stream.
  late final ReadableSignal<T> readable = ReadableSignal._(this);

  @protected
  set value(T newValue) => emit(newValue);

  @protected
  void emit(T newValue) {
    if (isDisposed) return; // Node was disposed before the async op completed
    if (unsafeValue == newValue) return; // Small optional optimization
    unsafeValue = newValue;
    controller.add(newValue);
  }
}
