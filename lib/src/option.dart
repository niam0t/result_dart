import 'package:meta/meta.dart';

import 'exceptions.dart';
import 'result.dart';

/// A type that represents either a value ([Some]) or no value ([None]).
///
/// Mirrors Rust's `std::option::Option<T>`.
@immutable
sealed class Option<T> {
  const Option();

  /// Returns `true` if the option is a [Some] value.
  ///
  /// Rust: `Option::is_some`
  bool isSome() => this is Some<T>;

  /// Returns `true` if the option is a [Some] and the value inside matches
  /// a predicate.
  ///
  /// Rust: `Option::is_some_and`
  bool isSomeAnd(bool Function(T) f) => switch (this) {
    Some(value: final v) => f(v),
    None() => false,
  };

  /// Returns `true` if the option is a [None] value.
  ///
  /// Rust: `Option::is_none`
  bool isNone() => this is None<T>;

  /// Returns the contained [Some] value.
  ///
  /// Throws [UnwrapException] with [msg] if [None].
  ///
  /// Rust: `Option::expect`
  T expect(String msg) => switch (this) {
    Some(value: final v) => v,
    None() => throw UnwrapException(msg),
  };

  /// Returns the contained [Some] value.
  ///
  /// Throws [UnwrapException] if [None].
  ///
  /// Rust: `Option::unwrap`
  T unwrap() => switch (this) {
    Some(value: final v) => v,
    None() => throw UnwrapException(
      'called `Option::unwrap()` on a `None` value',
    ),
  };

  /// Returns the contained [Some] value or [defaultValue].
  ///
  /// Rust: `Option::unwrap_or`
  T unwrapOr(T defaultValue) => switch (this) {
    Some(value: final v) => v,
    None() => defaultValue,
  };

  /// Returns the contained [Some] value or computes it from [f].
  ///
  /// Rust: `Option::unwrap_or_else`
  T unwrapOrElse(T Function() f) => switch (this) {
    Some(value: final v) => v,
    None() => f(),
  };

  /// Maps an `Option<T>` to `Option<U>` by applying [f] to the contained value.
  ///
  /// Rust: `Option::map`
  Option<U> map<U>(U Function(T) f) => switch (this) {
    Some(value: final v) => Some(f(v)),
    None() => None<U>(),
  };

  /// Returns [defaultValue] if [None], otherwise applies [f] to the value.
  ///
  /// Rust: `Option::map_or`
  U mapOr<U>(U defaultValue, U Function(T) f) => switch (this) {
    Some(value: final v) => f(v),
    None() => defaultValue,
  };

  /// Returns the result of [defaultF] if [None], otherwise applies [f].
  ///
  /// Rust: `Option::map_or_else`
  U mapOrElse<U>(U Function() defaultF, U Function(T) f) => switch (this) {
    Some(value: final v) => f(v),
    None() => defaultF(),
  };

  /// Calls [f] with the contained value (if [Some]), then returns `this`.
  ///
  /// Rust: `Option::inspect`
  Option<T> inspect(void Function(T) f) {
    if (this case Some(value: final v)) f(v);
    return this;
  }

  /// Returns [None] if this is [None], otherwise returns [optb].
  ///
  /// Rust: `Option::and`
  Option<U> and<U>(Option<U> optb) => switch (this) {
    Some() => optb,
    None() => None<U>(),
  };

  /// Returns [None] if this is [None], otherwise calls [f] with the value.
  ///
  /// Rust: `Option::and_then`
  Option<U> andThen<U>(Option<U> Function(T) f) => switch (this) {
    Some(value: final v) => f(v),
    None() => None<U>(),
  };

  /// Returns this if [Some], otherwise returns [optb].
  ///
  /// Rust: `Option::or`
  Option<T> or(Option<T> optb) => switch (this) {
    Some() => this,
    None() => optb,
  };

  /// Returns this if [Some], otherwise calls [f].
  ///
  /// Rust: `Option::or_else`
  Option<T> orElse(Option<T> Function() f) => switch (this) {
    Some() => this,
    None() => f(),
  };

  /// Returns [Some] if exactly one of `this` or [optb] is [Some].
  ///
  /// Rust: `Option::xor`
  Option<T> xor(Option<T> optb) => switch ((this, optb)) {
    (Some(), None()) => this,
    (None(), Some()) => optb,
    _ => None<T>(),
  };

  /// Returns [None] if this is [None], otherwise calls [predicate] and
  /// returns [Some] if it returns `true`, or [None] if `false`.
  ///
  /// Rust: `Option::filter`
  Option<T> filter(bool Function(T) predicate) => switch (this) {
    Some(value: final v) => predicate(v) ? this : None<T>(),
    None() => None<T>(),
  };

  /// Transforms the `Option<T>` into a `Result<T, E>`, mapping [Some(v)] to
  /// [Ok(v)] and [None] to [Err(err)].
  ///
  /// Rust: `Option::ok_or`
  Result<T, E> okOr<E>(E err) => switch (this) {
    Some(value: final v) => Ok(v),
    None() => Err(err),
  };

  /// Transforms the `Option<T>` into a `Result<T, E>`, mapping [Some(v)] to
  /// [Ok(v)] and [None] to [Err(err())].
  ///
  /// Rust: `Option::ok_or_else`
  Result<T, E> okOrElse<E>(E Function() err) => switch (this) {
    Some(value: final v) => Ok(v),
    None() => Err(err()),
  };

  /// Yields the contained value as a single-element iterator, or nothing if [None].
  ///
  /// This allows [Option] to be used in `for-in` loops, mirroring Rust's
  /// `IntoIterator` implementation.
  Iterator<T> get iterator => switch (this) {
    Some(value: final v) => [v].iterator,
    None() => <T>[].iterator,
  };

  @override
  String toString() => switch (this) {
    Some(value: final v) => 'Some($v)',
    None() => 'None',
  };
}

/// Represents the presence of a value.
///
/// Rust: `Option::Some`
@immutable
class Some<T> extends Option<T> {
  final T value;

  const Some(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Some<T> && other.value == value);

  @override
  int get hashCode => Object.hash(Some, value);
}

/// Represents the absence of a value.
///
/// Rust: `Option::None`
@immutable
class None<T> extends Option<T> {
  const None();

  @override
  bool operator ==(Object other) => identical(this, other) || other is None<T>;

  @override
  int get hashCode => 'None'.hashCode;
}

/// Rust: `Option<Option<T>>::flatten`
extension OptionFlatten<T> on Option<Option<T>> {
  /// Flattens a nested `Option<Option<T>>` into `Option<T>`.
  Option<T> flatten() => switch (this) {
    Some(value: final inner) => inner,
    None() => None<T>(),
  };
}

/// Rust: `Option<Result<T, E>>::transpose`
extension OptionTranspose<T, E> on Option<Result<T, E>> {
  /// Transposes an `Option<Result<T, E>>` into a `Result<Option<T>, E>`.
  Result<Option<T>, E> transpose() => switch (this) {
    Some(value: Ok(value: final v)) => Ok(Some(v)),
    Some(value: Err(error: final e)) => Err(e),
    None() => Ok(None<T>()),
  };
}

/// Rust: `Option::zip`
extension OptionZip<T> on Option<T> {
  /// Zips `this` with [other]. If both are [Some], returns [Some((a, b))].
  Option<(T, U)> zip<U>(Option<U> other) => switch ((this, other)) {
    (Some(value: final a), Some(value: final b)) => Some((a, b)),
    _ => None<(T, U)>(),
  };
}

/// Provides [compareTo] when both type parameters are [Comparable].
///
/// Rust: `impl Ord for Option<T> where T: Ord` (`None < Some`)
extension OptionComparable<T extends Comparable<T>> on Option<T> {
  int compareTo(Option<T> other) => switch ((this, other)) {
    (None(), None()) => 0,
    (None(), Some()) => -1,
    (Some(), None()) => 1,
    (Some(value: final a), Some(value: final b)) => a.compareTo(b),
  };
}
