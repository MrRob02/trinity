part of 'signal.dart';

class FutureSignal<T> extends ProtectedSignal<AsyncData<T>> {
  final Future<T> Function() _future;
  final bool autoInitialize;

  FutureSignal(this._future, {this.autoInitialize = true})
    : super(AsyncData.initial());

  Future<T?> fetch({bool resetValue = false}) async {
    if (resetValue) {
      this.resetValue();
    }
    _emit(const AsyncLoading());
    try {
      final data = await _future();
      _emit(AsyncData(data));
      return data;
    } catch (e, st) {
      _emit(AsyncError(e, st));
    }
    return null;
  }

  void _emit(AsyncData<T> newValue) {
    value = newValue;
    controller.add(newValue);
  }

  void resetValue() => _emit(AsyncData.initial());

  W when<W>({
    required W Function(AsyncData<T> value) builder,
    required W Function() loading,
    required W Function(AsyncError<T> value) error,
  }) {
    if (value is AsyncLoading) {
      return loading();
    }
    if (value is AsyncError) {
      return error(value as AsyncError<T>);
    }
    return builder(value);
  }
}
