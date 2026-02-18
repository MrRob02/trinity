part of 'signal.dart';

class FutureSignal<T> extends Signal<AsyncValue<T>> {
  final Future<T> Function() _future;

  FutureSignal(this._future) : super(AsyncData.initial());

  Future<void> fetch() async {
    _emit(const AsyncLoading());
    try {
      final data = await _future();
      _emit(AsyncData(data));
    } catch (e, st) {
      _emit(AsyncError(e, st));
    }
  }

  void _emit(AsyncValue<T> newValue) {
    value = newValue;
    _controller.add(newValue);
  }
}
