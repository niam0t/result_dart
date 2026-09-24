/// Exception thrown when unwrapping a [Result] or [Option] of the wrong variant.
///
/// Mirrors Rust's panic messages from `unwrap()` and `expect()`.
class UnwrapException implements Exception {
  final String message;

  const UnwrapException(this.message);

  @override
  String toString() => 'UnwrapException: $message';
}
