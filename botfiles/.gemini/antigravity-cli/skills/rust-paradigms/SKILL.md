---
name: rust-paradigms
description: "Global Rust Architecture, Memory Safety, and Concurrency."
paths:
  - "**/*.rs"
applyTo: "**/*.rs"
---

# Global Rust Architecture & Memory Safety

## Context
Guidelines for building high-performance, memory-safe, and concurrent Rust systems. Code must be deeply idiomatic, leverage type-level constraints defensively, pass the borrow checker without unnecessary clones, and handle errors robustly.

## Trigger Conditions
Activated automatically when reading, writing, or editing Rust source files (`*.rs`), tests, or `Cargo.toml` configuration.

## Directives

### 1. Lifetime Management & Zero-Cost Abstractions
* **Avoid Lazy Cloning**: Do not insert `.clone()` or `.to_owned()` to bypass borrow checker constraints. Leverage references, explicit lifetimes (`'a`), or structural changes to minimize data duplication.
* **Borrowing Conversions**: Use `Cow<'a, str>` or `Cow<'a, [T]>` when a function can accept both borrowed and owned data. Passing slice parameters (`&str` or `&[T]`) is mandatory over owned configurations (`&String` or `&Vec<T>`).
* **Efficient Memory Reuse**: Use `std::mem::take` or `std::mem::replace` to extract value out of a mutable reference without allocating new memory.

### 2. Explicit & Defensive Error Handling
* **Production-Safe Logic**: Never use `.unwrap()`, `.expect()`, or `panic!` in non-test production code paths. Handle failure states explicitly.
* **Idiomatic Propagation**: Use the `?` operator to bubble up errors. Combine functional combinators (`.map_err()`, `.and_then()`, `.unwrap_or_else()`) for expressive pipeline control.
* **Domain Error Types**: Standardize error categorization:
  * For libraries, use `thiserror` to define precise, type-safe custom error enums with individual `#[error(...)]` formats.
  * For applications, use `anyhow` or similar wrapper frameworks for rich, high-level context tracing (`.context()`).

### 3. Asynchronous Execution & Concurrency
* **Executor Safety**: Never block the async thread pool (e.g. Tokio). Offload synchronous, blocking operations (heavy CPU math, blocking file system I/O, synchronous network calls) to a blocking thread using `tokio::task::spawn_blocking` or `std::thread`.
* **Lock Safety**: 
  * Avoid holding synchronization guards (like `std::sync::MutexGuard`) across `await` points. Use `tokio::sync::Mutex` if a lock must be held across yields, or restructure code to keep critical sections strictly synchronous.
  * Prefer lock-free atomic primitives (`std::sync::atomic`) for simple variables and flag checks.

### 4. Idiomatic Pattern Matching & Expressive APIs
* **Match Expression Safety**: Prefer exhaustive `match` blocks over complex `if/else` logic. Use `if let` or `let-else` (diverging `else { return ... }` statements) to isolate single-pattern extractions cleanly.
* **Expression-Driven Assignments**: Declare variables directly from the evaluation of statements (`let val = if condition { x } else { y };`) to minimize mutable variable declarations (`let mut`).
* **Safe Unsafe Policy**: The use of `unsafe` blocks is strictly prohibited unless explicitly requested by the user.

### 5. Testing & Verification
* **Test Isolation**: Utilize `cargo test` framework. Keep unit tests in the same module file within `mod tests` blocks, and integration tests in the `tests/` directory.
* **Document Testing**: Provide compile-checked examples inside doc comments using `/// ```rust ... ``` ` to serve as both documentation and tests.
