part of 'signal.dart';

class StreamSignal<T> extends Signal<T?> {
  final Stream<T> _source;
  StreamSubscription<T>? _subscription;

  StreamSignal(this._source) : super(null) {
    _listen();
  }

  T? get rawValue => value;

  void _listen() {
    _subscription?.cancel();
    _emit(null);
    _subscription = _source.listen(
      (data) => _emit(data),
      onError: (e, StackTrace st) => _emit(null),
    );
  }

  void _emit(T? newValue) {
    value = newValue;
    controller.add(newValue);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
