# result_dart

> Rust's `Result<T, E>` and `Option<T>` for Dart: explicit, composable, and fast.

`result_dart` brings Rust's two most important error-handling and nullability types to Dart, with the same names, the same methods, and the same semantics. If you know Rust, you already know this library. If you don't, the [tutorial](#wiki) will teach you gradually.

- **Rust-faithful API**: `Ok`, `Err`, `Some`, `None`, `map`, `and_then`-style chaining, `unwrap_or`, `?`-like early return, and more. The long-term goal is 1:1 parity with Rust's `std`.
- **Idiomatic Dart**: methods are `camelCase` (`unwrapOr`, `andThen`, `mapErr`), and the types work with Dart 3 sealed classes and pattern matching.
- **Fast**: designed so the abstraction has minimal overhead. Benchmarks are part of the repo and are verified, not assumed.
- **Well tested**: expressive, assertive tests double as documentation of the exact behavior.

---

## Table of contents

1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Quick start](#quick-start)
4. [Usage](#usage)
5. [Paradigms](#paradigms)
6. [API cheat sheet](#api-cheat-sheet)
7. [Performance](#performance)
8. [Testing and benchmarks](#testing-and-benchmarks)
9. [Wiki](#wiki)
10. [Roadmap](#roadmap)
11. [Contributing](#contributing)
12. [License](#license)

---

## Introduction

Dart handles absence with `null` and failure with exceptions. Both are *invisible in the type signature*:

```dart
User findUser(String id);        // Can this throw? Can it return null? Who knows.
int parsePort(String input);     // Throws FormatException... sometimes.
```

Rust solves both problems with two small types:

| Type          | Meaning                              | Variants          |
| ------------- | ------------------------------------ | ----------------  |
| `Option<T>`   | A value that **may be absent**       | `Some(T)`, `None` |
| `Result<T, E>`| An operation that **may fail**       | `Ok(T)`, `Err(E)` |

With `result_dart`, the possibility of absence or failure is part of the function's signature, and the compiler makes sure you handle it:

```dart
Option<User> findUser(String id);
Result<int, ParseError> parsePort(String input);
```

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  result_dart: ^0.1.0   # or a path/git dependency while in development
```

Then:

```sh
dart pub get
```

Import it:

```dart
import 'package:result_dart/result_dart.dart';
```

> Requires Dart 3.0 or newer (sealed classes and pattern matching).

---

## Quick start

```dart
import 'package:result_dart/result_dart.dart';

Result<int, String> parsePort(String input) {
  final n = int.tryParse(input);
  if (n == null) return Err('"$input" is not a number');
  if (n < 1 || n > 65535) return Err('$n is out of range');
  return Ok(n);
}

void main() {
  final port = parsePort('8080')
      .map((p) => p + 1)
      .unwrapOr(80);

  print(port); // 8081
}
```

---

## Usage

### Creating values

```dart
final a = Ok<int, String>(42);
final b = Err<int, String>('boom');

final c = Some(7);
final d = None<int>();
```

### Inspecting values

```dart
a.isOk;          // true
b.isErr;         // true
c.isSome;        // true
d.isNone;        // true
```

### Extracting values

```dart
a.unwrap();                 // 42; throws if Err
b.unwrapOr(0);              // 0
b.unwrapOrElse((e) => e.length);
a.expect('must be ok');     // throws with your message if Err
```

### Transforming values

```dart
Ok<int, String>(2).map((x) => x * 10);            // Ok(20)
Err<int, String>('bad').mapErr((e) => e.length);  // Err(3)
Some(4).map((x) => x + 1);                        // Some(5)
```

### Chaining fallible steps

```dart
Result<Config, String> load(String path) =>
    readFile(path)                // Result<String, String>
        .andThen(parseJson)       // Result<Json, String>
        .andThen(validate);       // Result<Config, String>
```

The first `Err` short-circuits the whole chain, and no `try`/`catch` is needed.

### Converting between types

```dart
Ok<int, String>(1).ok();      // Some(1)
Err<int, String>('x').ok();   // None
Err<int, String>('x').err();  // Some('x')
Some(1).okOr('missing');      // Ok(1)
None<int>().okOr('missing');  // Err('missing')
```

### Wrapping code that throws

```dart
final r = Result.guard(() => jsonDecode(input));   // Result<dynamic, Object>
```

### Pattern matching (Dart 3)

`Result` and `Option` are sealed, so `switch` is exhaustive:

```dart
final message = switch (parsePort(input)) {
  Ok(:final value) => 'Listening on $value',
  Err(:final error) => 'Invalid port: $error',
};
```

---

## Paradigms

This section explains *how to think* when using these types.

### 1. Make failure part of the type

If a function can fail in a way the caller should care about, return `Result`. If a value can legitimately be missing, return `Option`. Reserve exceptions for bugs and truly unrecoverable situations (Rust's `panic!` equivalent).

| Situation                              | Use                  |
| -------------------------------------- | -------------------- |
| Missing map key, empty list `first`    | `Option<T>`          |
| Parse error, I/O error, validation     | `Result<T, E>`       |
| Programmer error, broken invariant     | Throw / `unwrap`     |

### 2. Railway-oriented programming

Think of a pipeline as two tracks: the **success track** (`Ok`/`Some`) and the **failure track** (`Err`/`None`). `map` and `andThen` only run on the success track; once you're on the failure track, you stay there until you explicitly recover (`orElse`, `unwrapOr`).

```txt
input ──► parse ──► validate ──► save ──► Ok(result)
             │          │          │
             └──────────┴──────────┴────► Err(reason)
```

### 3. Handle errors at the boundary

Pass `Result` values through your layers untouched, and decide what to do (log, retry, show UI) in one place near the edge of the system. Avoid calling `unwrap()` in the middle of the code.

### 4. Use typed errors

`E` can be anything: a `String` for quick scripts, or a sealed class hierarchy for real applications:

```dart
sealed class AppError {}
class NotFound extends AppError { final String id; NotFound(this.id); }
class Unauthorized extends AppError {}

Result<User, AppError> fetchUser(String id);
```

Exhaustive `switch` over `AppError` then guarantees every failure case is handled.

### 5. `map` vs `andThen`

- Use **`map`** when your function returns a plain value: `T -> U`.
- Use **`andThen`** when your function itself returns a `Result`/`Option`: `T -> Result<U, E>`.

Using `map` with a fallible function gives you a nested `Result<Result<...>>`, which is usually a sign you wanted `andThen`.

### 6. Prefer combinators, fall back to `switch`

Combinators (`map`, `andThen`, `unwrapOr`) read well for linear flows. When different branches need different logic, pattern matching is clearer.

### 7. Be explicit about unsafe extraction

`unwrap()` and `expect()` throw. Use them only in tests, scripts, or where you can prove the invariant. Prefer `expect('why this cannot fail')` over `unwrap()` so the failure message is useful.

---

## API cheat sheet

### `Result<T, E>`

| Method                            | Description                                           |
| ----------------------            | ----------------------------------------------------- |
| `isOk` / `isErr`                  | Variant checks                                        |
| `unwrap()` / `expect(msg)`        | Get the `Ok` value, throw on `Err`                    |
| `unwrapErr()`                     | Get the `Err` value, throw on `Ok`                    |
| `unwrapOr(d)` / `unwrapOrElse(f)` | Get the value or a default                            |
| `map(f)` / `mapErr(f)`            | Transform the `Ok` / `Err` value                      |
| `andThen(f)` / `orElse(f)`        | Chain on success / recover from failure               |
| `ok()` / `err()`                  | Convert to `Option`                                   |
| `and(r)` / `or(r)`                | Combine with another `Result`                         |

### `Option<T>`

| Method                            | Description                                           |
| ----------------------            | ----------------------------------------------------- |
| `isSome` / `isNone`               | Variant checks                                        |
| `unwrap()` / `expect(msg)`        | Get the value, throw on `None`                        |
| `unwrapOr(d)` / `unwrapOrElse(f)` | Get the value or a default                            |
| `map(f)` / `andThen(f)`           | Transform / chain                                     |
| `filter(p)`                       | Keep `Some` only if the predicate holds               |
| `okOr(e)`                         | Convert to `Result`                                   |
| `orElse(f)`                       | Provide an alternative `Option`                       |

> The exact method list grows toward full Rust parity. See the [API reference](#wiki) for the current state.

---

## Performance

Abstractions have a cost, and this library treats that cost as a bug to be measured and fixed.

Design goals:

- Keep the public interface simple and Rust-like.
- Minimize allocations and virtual dispatch on hot paths.
- Use implementation techniques (and code generation where it helps) rather than complicating the API.

Every performance claim is backed by a benchmark you can run yourself:

```sh
dart run benchmark/run_all.dart
```

---

## Testing and benchmarks

**Tests** are written to be expressive and assertive: each test names the behavior it checks and asserts the exact outcome.

```sh
dart test
```

```dart
test('map on Err leaves the error untouched', () {
  final r = Err<int, String>('boom').map((x) => x + 1);
  expect(r, isErr('boom'));
});
```

**Benchmarks** are testable, verifiable, and repeatable. They compare the library against plain Dart (`null` checks, `try`/`catch`) and report results in a readable table.

```sh
dart run benchmark/run_all.dart
```

---

## Wiki

The wiki is a tutorial that teaches gradually, from your first `Ok` to advanced composition. Suggested page layout (`/wiki` or the GitHub Wiki):

| Page | What you'll learn |
| ---- | ----------------- |
| **Home** | Overview and where to start |
| **1. Why Result and Option?** | The problems with `null` and exceptions |
| **2. Your first Option** | `Some`, `None`, `unwrapOr`, `map` |
| **3. Your first Result** | `Ok`, `Err`, `isOk`, `unwrap`, `expect` |
| **4. Transforming values** | `map`, `mapErr`, `filter` |
| **5. Chaining operations** | `andThen`, `orElse`, short-circuiting |
| **6. Pattern matching** | Exhaustive `switch` with Dart 3 |
| **7. Designing error types** | Sealed class hierarchies |
| **8. Interop with exceptions** | `Result.guard`, async functions, `Future<Result>` |
| **9. Real-world recipes** | Parsing, I/O, HTTP, validation |
| **10. Rust to Dart map** | Side-by-side Rust and Dart for every method |
| **11. Performance notes** | How the implementation stays fast |
| **API reference** | Every type and method |

Each page builds on the previous one and ends with a small exercise.

---

## Roadmap

- [x] Core `Result` and `Option` types
- [x] Initial benchmarks
- [ ] Performance rewrite (implementation changes and/or code generation)
- [ ] Expressive, assertive test suite
- [ ] Verifiable, improvable benchmark suite
- [ ] Tutorial-style examples
- [ ] Full 1:1 parity with Rust's `Result` and `Option` APIs

---

## Contributing

Issues and pull requests are welcome. Please:

1. Add or update tests for any behavior change.
2. Run the benchmarks if you touch core types, and include before/after numbers.
3. Keep the API Rust-like: if Rust has a method, prefer the same name (in `camelCase`) and the same semantics.

---

## License

Apache-2.0
