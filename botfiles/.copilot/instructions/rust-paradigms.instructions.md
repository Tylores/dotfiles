---
name: rust-paradigms
description: "Global Rust Architecture & Memory Safety."
applyTo: "**/*.rs"
---

# Global Rust Architecture & Memory Safety

## Context
The user writes highly efficient, memory-safe, and concurrent Rust systems. Code must be deeply idiomatic, leverage the type system defensively, and pass the borrow checker without lazy performance bypasses.

## Trigger Conditions
Use when working on Rust codebases, cargo configurations, or debugging borrow checker issues.

## Directives

### 1. Zero-Cost Abstractions & Memory Efficiency
* **Avoid Lazy Cloning:** Do not insert `.clone()` or `.to_owned()` simply to bypass borrow checker constraints. Emphasize standard references, explicit lifetimes, and short scoping blocks instead.
* **Idiomatic Slice Passing:** Prefer passing read-only collections as slices (`&[T]`) rather than full vector references (`&Vec<T>`), and strings as string slices (`&str`) rather than owning string references (`&String`).

### 2. Explicit & Defensive Error Handling
* **Production-Safe Logic:** Never use `.unwrap()` or `.expect()` in non-test code blocks. Propagate errors natively using the `?` operator, or manage them using functional combinators like `.unwrap_or_else()`.
* **Type-Driven Domain Modeling:** Leverage the compiler to enforce correctness. Prefer strongly-typed custom enums or structs over primitive tracking variables (`String`, `i32`) to represent distinct system states.

### 3. Idiomatic Pattern Matching & Expressions
* **Match Over Conditions:** Use complete, expressive `match` structures rather than nested `if/else` logic trees. Use `if let` or `let-else` statements for single-branch extraction paths.
* **Expression-Driven Code:** Write assignments, return statements, and conditional blocks as native expressions to minimize mutable state initialization (`let mut`).

### 4. Safety & Parallel Execution
* **No Unsafe Code:** The use of `unsafe` blocks is strictly prohibited unless explicitly requested by the user.
* **Concurreny Hygiene:** Ensure concurrent primitives use optimal locking boundaries. Prefer lock-free types (`std::sync::atomic`) or minimal critical sections via standard Mutex types over heavy architectural abstractions.
