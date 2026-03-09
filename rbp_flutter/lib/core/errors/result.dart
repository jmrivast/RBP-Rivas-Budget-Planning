import 'failures.dart';

/// A lightweight Result type that wraps success [T] or [Failure].
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  T get valueOrThrow {
    return switch (this) {
      Success(:final value) => value,
      Err(:final failure) => throw Exception(failure.message),
    };
  }

  T? get valueOrNull {
    return switch (this) {
      Success(:final value) => value,
      Err() => null,
    };
  }

  Failure? get failureOrNull {
    return switch (this) {
      Success() => null,
      Err(:final failure) => failure,
    };
  }

  Result<R> map<R>(R Function(T) transform) {
    return switch (this) {
      Success(:final value) => Success(transform(value)),
      Err(:final failure) => Err(failure),
    };
  }
}
