part of 'signal.dart';

/// A read-only signal whose value is derived from another signal.
///
/// Use this when you need a computed/derived value from a signal
/// that lives in the **same node**, without the verbosity of
/// [TransformBridgeSignal].
///
/// ```dart
/// late final total = registerSignal(
///   ComputedSignal(products, (list) => list.fold<double>(
///     0.0, (prev, e) => prev + e.price,
///   )),
/// );
/// ```
class ComputedSignal<T, V> extends BaseSignal<V> {
  StreamSubscription<T>? _subscription;
  final BaseSignal<T> _source;
  final V Function(T) _transform;

  ComputedSignal(this._source, this._transform)
    : super(_transform(_source.value)) {
    _subscription = _source.stream.listen((data) {
      final newValue = _transform(data);
      if (unsafeValue != newValue) {
        unsafeValue = newValue;
        controller.add(newValue);
      }
    });
  }

  /// Readable proxy for use with generated Readable* classes.
  late final ReadableSignal<V> readable = ReadableSignal._(this);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
