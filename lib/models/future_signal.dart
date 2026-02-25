part of 'signal.dart';

class FutureSignal<T> extends Signal<AsyncData<T>> {
  final Future<T> _future;

  FutureSignal(this._future) : super(AsyncData.initial());

  Future<void> fetch() async {
    _emit(const AsyncLoading());
    try {
      final data = await _future;
      _emit(AsyncData(data));
    } catch (e, st) {
      _emit(AsyncError(e, st));
    }
  }

  void _emit(AsyncData<T> newValue) {
    value = newValue;
    controller.add(newValue);
  }
}
