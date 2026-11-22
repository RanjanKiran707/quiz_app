import 'package:quiz_app/core/errors/failure.dart';

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess) =>
      switch (this) {
        Ok<T>(:final value) => onSuccess(value),
        Err<T>(:final failure) => onFailure(failure),
      };

  Result<R> map<R>(R Function(T) transform) => switch (this) {
        Ok<T>(value: final value) => Ok(transform(value)),
        Err<T>(failure: final failure) => Err(failure),
      };

  Result<R> flatMap<R>(Result<R> Function(T) transform) => switch (this) {
        Ok<T>(value: final value) => transform(value),
        Err<T>(failure: final failure) => Err(failure),
      };

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
