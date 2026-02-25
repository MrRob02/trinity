sealed class AsyncValue<T> {
  const AsyncValue();
}

class AsyncData<T> extends AsyncValue<T> {
  final T? value;
  final bool isLoading;
  const AsyncData(this.value) : isLoading = false;
  const AsyncData.loading(this.value) : isLoading = true;
  const AsyncData.initial() : this(null);
}

class AsyncLoading<T> extends AsyncData<T> {
  const AsyncLoading() : super.loading(null);
}

class AsyncError<T> extends AsyncData<T> {
  final Object error;
  final StackTrace stackTrace;
  const AsyncError(this.error, this.stackTrace) : super(null);
}
