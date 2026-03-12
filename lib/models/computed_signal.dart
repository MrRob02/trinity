part of 'signal.dart';

class ComputedSignal<T, V> extends Signal<V> {
  StreamSubscription<T>? _subscription;
  final BaseSignal<T> _source;
  final V Function(T) _transform;

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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class ComputedSignalMany<V> extends Signal<V> {
  final Set<StreamSubscription> _subscription = {};
  final Set<BaseSignal> _source;
  final V Function() _transform;

  /// A read-only signal whose value is derived from a set of signals.
  ///
  /// Use this when you need a computed/derived value from signals
  /// that live in the **same node**, without the verbosity of
  /// `TransformBridgeSignal`.
  ///
  /// ```dart
  /// late final total = registerSignal(
  ///   ComputedSignalMany(
  ///     {products, anotherSignal, ...},
  ///     () => products.value.fold<double>(
  ///       0.0, (prev, e) => prev + e.price,
  ///     ),
  ///   ),
  /// );
  /// ```
  ComputedSignalMany(this._source, this._transform) : super(_transform()) {
    _subscription.addAll(
      _source
          .map(
            (s) => s.stream.listen((data) {
              final newValue = _transform();
              if (unsafeValue != newValue) {
                unsafeValue = newValue;
                controller.add(newValue);
              }
            }),
          )
          .toList(),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscription) {
      sub.cancel();
    }
    super.dispose();
  }
}
