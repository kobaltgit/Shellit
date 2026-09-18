import 'package:meta/meta.dart';
import 'failures.dart';

/// Sealed functional Result type for error-handling without unhandled exceptions.
@sealed
abstract class Result<T, F extends Failure> {
  const Result();

  /// Creates a successful result holding [value].
  const factory Result.success(T value) = Success<T, F>;

  /// Creates an error result holding [failure].
  const factory Result.error(F failure) = Error<T, F>;

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T, F>;

  /// Returns true if this is an [Error].
  bool get isError => this is Error<T, F>;

  /// Extracts the success value or null if error.
  T? get valueOrNull => isSuccess ? (this as Success<T, F>).value : null;

  /// Extracts the failure or null if success.
  F? get failureOrNull => isError ? (this as Error<T, F>).failure : null;

  /// Pattern matching handler.
  R when<R>({
    required R Function(T value) success,
    required R Function(F failure) error,
  }) {
    if (this is Success<T, F>) {
      return success((this as Success<T, F>).value);
    } else if (this is Error<T, F>) {
      return error((this as Error<T, F>).failure);
    }
    throw StateError('Unknown Result state');
  }

  /// Maps the success value using [fn].
  Result<R, F> map<R>(R Function(T value) fn) {
    if (this is Success<T, F>) {
      return Result.success(fn((this as Success<T, F>).value));
    }
    return Result.error((this as Error<T, F>).failure);
  }

  /// Maps the failure using [fn].
  Result<T, R> mapError<R extends Failure>(R Function(F failure) fn) {
    if (this is Error<T, F>) {
      return Result.error(fn((this as Error<T, F>).failure));
    }
    return Result.success((this as Success<T, F>).value);
  }

  /// Flat-maps the success value to another [Result].
  Result<R, F> flatMap<R>(Result<R, F> Function(T value) fn) {
    if (this is Success<T, F>) {
      return fn((this as Success<T, F>).value);
    }
    return Result.error((this as Error<T, F>).failure);
  }

  /// Returns the value or throws [Exception] if this is an [Error].
  T getOrThrow() {
    if (this is Success<T, F>) {
      return (this as Success<T, F>).value;
    }
    throw (this as Error<T, F>).failure;
  }
}

/// Representation of a successful [Result].
class Success<T, F extends Failure> extends Result<T, F> {
  final T value;
  const Success(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T, F> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Result.success($value)';
}

/// Representation of a failed [Result].
class Error<T, F extends Failure> extends Result<T, F> {
  final F failure;
  const Error(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Error<T, F> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Result.error($failure)';
}
