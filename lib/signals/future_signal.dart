part of 'signal.dart';

class FutureSignal<T> extends ProtectedSignal<AsyncData<T>> {
  final Future<T> _future;

  FutureSignal(this._future) : super(AsyncData.initial());
  // bool get isLoading => value is AsyncLoading;
  // bool get isError => value is AsyncError;
  // bool get hasData => value.hasValue;
  Future<T?> fetch() async {
    _emit(const AsyncLoading());
    try {
      final data = await _future;
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
