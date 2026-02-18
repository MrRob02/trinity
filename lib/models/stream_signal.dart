part of 'signal.dart';

class StreamSignal<T> extends Signal<AsyncValue<T>> {
  final Stream<T> _source;
  StreamSubscription<T>? _subscription;

  StreamSignal(this._source) : super(AsyncData.initial()) {
    _listen();
  }

  void _listen() {
    _subscription?.cancel();
    _emit(const AsyncLoading());
    _subscription = _source.listen(
      (data) => _emit(AsyncData(data)),
      onError: (e, StackTrace st) => _emit(AsyncError(e, st)),
    );
  }

  @override
  @protected
  void emit(AsyncValue<T> newValue) {
    _emit(newValue);
  }

  void _emit(AsyncValue<T> newValue) {
    _value = newValue;
    _controller.add(newValue);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
