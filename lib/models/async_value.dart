sealed class AsyncValue<T> {
  const AsyncValue();
}

class AsyncData<T> extends AsyncValue<T> {
  final T? value;
  const AsyncData(this.value);
  const AsyncData.initial() : this(null);
}

class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

class AsyncError<T> extends AsyncValue<T> {
  final Object error;
  final StackTrace stackTrace;
  const AsyncError(this.error, this.stackTrace);
}
