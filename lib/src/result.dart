import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'option.dart';

/// A type that represents either success ([Ok]) or failure ([Err]).
///
/// This is a 1:1 port of Rust's `std::result::Result<T, E>`.
///
/// Methods that are not applicable in Dart (e.g. `as_ref`, `as_mut`, `copied`,
/// `cloned`) are omitted. Methods requiring constrained type parameters
/// (`flatten`, `transpose`, `compareTo`) are provided via extensions.
@immutable
sealed class Result<T, E> {
  const Result();

  // ---------------------------------------------------------------------------
  // Querying the contained values
  // ---------------------------------------------------------------------------

  /// Returns `true` if the result is [Ok].
  ///
  /// Rust: `Result::is_ok`
  bool isOk() => this is Ok<T, E>;

  /// Returns `true` if the result is [Ok] and the value inside matches
  /// a predicate.
  ///
  /// Rust: `Result::is_ok_and`
  bool isOkAnd(bool Function(T) f) => switch (this) {
    Ok(value: final v) => f(v),
    Err() => false,
  };

  /// Returns `true` if the result is [Err].
  ///
  /// Rust: `Result::is_err`
  bool isErr() => this is Err<T, E>;

  /// Returns `true` if the result is [Err] and the error inside matches
  /// a predicate.
  ///
  /// Rust: `Result::is_err_and`
  bool isErrAnd(bool Function(E) f) => switch (this) {
    Ok() => false,
    Err(error: final e) => f(e),
  };

  /// Returns the contained [Ok] value.
  ///
  /// Throws [UnwrapException] with a message combining [msg] and the [Err]
  /// value if this is [Err].
  ///
  /// Rust: `Result::expect`
  T expect(String msg) => switch (this) {
    Ok(value: final v) => v,
    Err(error: final e) => throw UnwrapException('$msg: $e'),
  };

  /// Returns the contained [Ok] value.
  ///
  /// Throws [UnwrapException] if [Err].
  ///
  /// Rust: `Result::unwrap`
  T unwrap() => switch (this) {
    Ok(value: final v) => v,
    Err(error: final e) => throw UnwrapException(
      'called `Result::unwrap()` on an `Err` value: $e',
    ),
  };

  /// Returns the contained [Err] value.
  ///
  /// Throws [UnwrapException] with a message combining [msg] and the [Ok]
  /// value if this is [Ok].
  ///
  /// Rust: `Result::expect_err`
  E expectErr(String msg) => switch (this) {
    Ok(value: final v) => throw UnwrapException('$msg: $v'),
    Err(error: final e) => e,
  };

  /// Returns the contained [Err] value.
  ///
  /// Throws [UnwrapException] if [Ok].
  ///
  /// Rust: `Result::unwrap_err`
  E unwrapErr() => switch (this) {
    Ok(value: final v) => throw UnwrapException(
      'called `Result::unwrap_err()` on an `Ok` value: $v',
    ),
    Err(error: final e) => e,
  };

  /// Returns the contained [Ok] value or [defaultValue].
  ///
  /// Rust: `Result::unwrap_or`
  T unwrapOr(T defaultValue) => switch (this) {
    Ok(value: final v) => v,
    Err() => defaultValue,
  };

  /// Returns the contained [Ok] value or computes it from [f].
  ///
  /// Rust: `Result::unwrap_or_else`
  T unwrapOrElse(T Function(E) f) => switch (this) {
    Ok(value: final v) => v,
    Err(error: final e) => f(e),
  };

  /// Returns the contained [Ok] value without checking.
  ///
  /// **Dart note:** Dart has no `unsafe`; this will still throw at runtime
  /// if the result is [Err]. Provided for API completeness.
  ///
  /// Rust: `Result::unwrap_unchecked` (unsafe)
  T unwrapUnchecked() => switch (this) {
    Ok(value: final v) => v,
    Err(error: final e) => throw UnwrapException(
      'called `Result::unwrap_unchecked()` on an `Err` value: $e',
    ),
  };

  /// Returns the contained [Err] value without checking.
  ///
  /// **Dart note:** Dart has no `unsafe`; this will still throw at runtime
  /// if the result is [Ok]. Provided for API completeness.
  ///
  /// Rust: `Result::unwrap_err_unchecked` (unsafe)
  E unwrapErrUnchecked() => switch (this) {
    Ok(value: final v) => throw UnwrapException(
      'called `Result::unwrap_err_unchecked()` on an `Ok` value: $v',
    ),
    Err(error: final e) => e,
  };

  /// Maps a `Result<T, E>` to `Result<U, E>` by applying [f] to the [Ok]
  /// value, leaving [Err] untouched.
  ///
  /// Rust: `Result::map`
  Result<U, E> map<U>(U Function(T) f) => switch (this) {
    Ok(value: final v) => Ok(f(v)),
    Err(error: final e) => Err<U, E>(e),
  };

  /// Returns [defaultValue] if [Err], otherwise applies [f] to the [Ok] value.
  ///
  /// Rust: `Result::map_or`
  U mapOr<U>(U defaultValue, U Function(T) f) => switch (this) {
    Ok(value: final v) => f(v),
    Err() => defaultValue,
  };

  /// Returns the result of [defaultF] if [Err], otherwise applies [f] to the
  /// [Ok] value.
  ///
  /// Rust: `Result::map_or_else`
  U mapOrElse<U>(U Function(E) defaultF, U Function(T) f) => switch (this) {
    Ok(value: final v) => f(v),
    Err(error: final e) => defaultF(e),
  };

  /// Maps a `Result<T, E>` to `Result<T, F>` by applying [f] to the [Err]
  /// value, leaving [Ok] untouched.
  ///
  /// Rust: `Result::map_err`
  Result<T, F> mapErr<F>(F Function(E) f) => switch (this) {
    Ok(value: final v) => Ok<T, F>(v),
    Err(error: final e) => Err(f(e)),
  };

  /// Calls [f] with the [Ok] value (if any), then returns `this` unchanged.
  ///
  /// Rust: `Result::inspect`
  Result<T, E> inspect(void Function(T) f) {
    if (this case Ok(value: final v)) f(v);
    return this;
  }

  /// Calls [f] with the [Err] value (if any), then returns `this` unchanged.
  ///
  /// Rust: `Result::inspect_err`
  Result<T, E> inspectErr(void Function(E) f) {
    if (this case Err(error: final e)) f(e);
    return this;
  }

  /// Returns [res] if this is [Ok], otherwise returns the [Err] value of
  /// `this`.
  ///
  /// Rust: `Result::and`
  Result<U, E> and<U>(Result<U, E> res) => switch (this) {
    Ok() => res,
    Err(error: final e) => Err<U, E>(e),
  };

  /// Returns [res] if this is [Ok], otherwise returns the [Err] value of
  /// `this`. Calls [f] only if [Ok].
  ///
  /// Rust: `Result::and_then`
  Result<U, E> andThen<U>(Result<U, E> Function(T) f) => switch (this) {
    Ok(value: final v) => f(v),
    Err(error: final e) => Err<U, E>(e),
  };

  /// Returns [res] if this is [Err], otherwise returns the [Ok] value of
  /// `this`.
  ///
  /// Rust: `Result::or`
  Result<T, F> or<F>(Result<T, F> res) => switch (this) {
    Ok(value: final v) => Ok<T, F>(v),
    Err() => res,
  };

  /// Returns [res] if this is [Err], otherwise returns the [Ok] value of
  /// `this`. Calls [f] only if [Err].
  ///
  /// Rust: `Result::or_else`
  Result<T, F> orElse<F>(Result<T, F> Function(E) f) => switch (this) {
    Ok(value: final v) => Ok<T, F>(v),
    Err(error: final e) => f(e),
  };

  /// Converts from `Result<T, E>` to `Option<T>`, discarding the error.
  ///
  /// Rust: `Result::ok`
  Option<T> ok() => switch (this) {
    Ok(value: final v) => Some(v),
    Err() => None<T>(),
  };

  /// Converts from `Result<T, E>` to `Option<E>`, discarding the success
  /// value.
  ///
  /// Rust: `Result::err`
  Option<E> err() => switch (this) {
    Ok() => None<E>(),
    Err(error: final e) => Some(e),
  };

  /// Returns the contained [Ok] value, consuming the result.
  ///
  /// **Dart note:** Equivalent to [unwrap] (Dart has no move semantics).
  /// Included for API completeness. Unstable in Rust.
  ///
  /// Rust: `Result::into_ok` (nightly)
  T intoOk() => unwrap();

  /// Returns the contained [Err] value, consuming the result.
  ///
  /// **Dart note:** Equivalent to [unwrapErr] (Dart has no move semantics).
  /// Included for API completeness. Unstable in Rust.
  ///
  /// Rust: `Result::into_err` (nightly)
  E intoErr() => unwrapErr();

  /// Yields the [Ok] value as a single-element iterable, or nothing if [Err].
  ///
  /// Rust: `Result::into_iter` / `IntoIterator for Result`

  Iterator<T> get iterator => switch (this) {
    Ok(value: final v) => [v].iterator,
    Err() => <T>[].iterator,
  };

  @override
  String toString() => switch (this) {
    Ok(value: final v) => 'Ok($v)',
    Err(error: final e) => 'Err($e)',
  };
}

/// Represents a successful outcome containing a [value].
///
/// Rust: `Result::Ok`
@immutable
class Ok<T, E> extends Result<T, E> {
  final T value;

  const Ok(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Ok<T, E> && other.value == value);

  @override
  int get hashCode => Object.hash(Ok, value);
}

/// Represents a failed outcome containing an [error].
///
/// Rust: `Result::Err`
@immutable
class Err<T, E> extends Result<T, E> {
  final E error;

  const Err(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Err<T, E> && other.error == error);

  @override
  int get hashCode => Object.hash(Err, error);
}

// =============================================================================
// Extension methods requiring constrained type parameters
// =============================================================================

/// Rust: `Result<Result<T, E>, E>::flatten`
extension ResultFlatten<T, E> on Result<Result<T, E>, E> {
  /// Converts from `Result<Result<T, E>, E>` to `Result<T, E>`.
  Result<T, E> flatten() => switch (this) {
    Ok(value: final inner) => inner,
    Err(error: final e) => Err<T, E>(e),
  };
}

/// Rust: `Result<Option<T>, E>::transpose`
extension ResultTranspose<T, E> on Result<Option<T>, E> {
  /// Transposes a `Result<Option<T>, E>` into an `Option<Result<T, E>>`.
  ///
  /// - `Ok(Some(v))` → `Some(Ok(v))`
  /// - `Ok(None)` → `None`
  /// - `Err(e)` → `Some(Err(e))`
  Option<Result<T, E>> transpose() => switch (this) {
    Ok(value: Some(value: final v)) => Some(Ok(v)),
    Ok(value: None()) => None<Result<T, E>>(),
    Err(error: final e) => Some(Err<T, E>(e)),
  };
}

/// Provides [compareTo] when both type parameters are [Comparable].
///
/// Rust: `impl Ord for Result<T, E> where T: Ord, E: Ord` (`Ok < Err`)
extension ResultComparable<T extends Comparable<T>, E extends Comparable<E>>
    on Result<T, E> {
  /// Compares two results. [Ok] is ordered before [Err].
  int compareTo(Result<T, E> other) => switch ((this, other)) {
    (Ok(value: final a), Ok(value: final b)) => a.compareTo(b),
    (Ok(), Err()) => -1,
    (Err(), Ok()) => 1,
    (Err(error: final a), Err(error: final b)) => a.compareTo(b),
  };
}
