part of 'signal.dart';

class ComputedSignal<T, V> extends Signal<V> {
  StreamSubscription<T>? _subscription;
  final BaseSignal<T> source;
  final V Function(T) transform;

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
  ComputedSignal({required this.source, required this.transform})
    : super(transform(source.value)) {
    _subscription = source.stream.listen((data) {
      final newValue = transform(data);
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
  final Set<BaseSignal> source;
  final V Function() transform;

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
  ComputedSignalMany({required this.source, required this.transform})
    : super(transform()) {
    _subscription.addAll(
      source
          .map(
            (s) => s.stream.listen((data) {
              final newValue = transform();
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
