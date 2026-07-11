---
name: go-paradigms
description: "Global Go (Golang) Architecture, Safety, and Best Practices."
paths:
  - "**/*.go"
applyTo: "**/*.go"
---

# Global Go (Golang) Architecture & Safety

## Context
Guidelines for building high-performance, robust, and highly concurrent Go services. Code must be idiomatic, simple, explicit, type-safe, and compile cleanly without race conditions.

## Trigger Conditions
Activated automatically when reading, writing, or editing Go source files (`*.go`), tests, or `go.mod` configuration.

## Directives

### 1. Robust & Idiomatic Error Handling
* **Immediate Checking**: Always inspect returned errors immediately (`if err != nil`). Never defer or ignore error checking.
* **Error Wrapping**: Wrap errors with meaningful context using `fmt.Errorf("context: %w", err)` to preserve the original error chain. Do not return raw sentinel errors from internal package boundaries.
* **Inspection**: Use `errors.Is` and `errors.As` for checking sentinel errors or custom error types. Avoid directly comparing errors with `==` unless checking simple internal sentinel variables.
* **No Library Panics**: Avoid using `panic` for control flow or standard error reporting. Use `panic` only for unrecoverable startup issues (e.g., failed to bind port) or developer errors (e.g., out-of-bounds).

### 2. Defensive Concurrency & Memory Hygiene
* **Context Propagation**: Always pass a `context.Context` to network calls, database transactions, and long-running operations. Respect context cancellation and timeouts (`ctx.Done()`).
* **Goroutine Lifetime Management**: Every spawned goroutine must have a deterministic termination condition. Avoid fire-and-forget goroutines that could leak memory or file descriptors.
* **Race Condition Prevention**: Synchronize shared access to maps, slices, and variables. Use `sync.Mutex` or `sync.RWMutex` for compound structures, and `sync/atomic` for simple counters. Use `go test -race` for verification.
* **Channel Safety**: 
  * Only the sender should close a channel to prevent panics on sending to a closed channel.
  * Check the ok-idiom (`v, ok := <-ch`) when reading from a channel that can close.
  * Use `sync.WaitGroup` or `golang.org/x/sync/errgroup` for coordinating parallel tasks.

### 3. Type Safety & API Design
* **Avoid Interface{} / any**: Do not use `interface{}` or `any` unless strictly necessary (e.g., generic encoders). Leverage Go generics (`[T any]`) for reusable types and algorithms.
* **Struct Initialization**: Always initialize structs using keyed fields (`MyStruct{Field: value}`) to prevent breaking changes when fields are added or rearranged.
* **Slice and Map Preallocation**: Use `make([]T, 0, capacity)` or `make(map[K]V, capacity)` when the size of the collection is known beforehand to avoid unnecessary allocations.

### 4. Project Layout & Export Hygiene
* **Go Style Package Layout**: Keep the public API surface area of packages minimal. Keep internal implementation details package-private (lowercase fields, functions, and types) unless they must be exported.
* **No init() Magic**: Avoid using `init()` functions for side effects or complex state setup. Prefer explicit initialization functions (e.g., `NewClient()`) to ensure deterministic startup.

### 5. Testing & Verification
* **Table-Driven Tests**: Write Go-standard table-driven tests for complex logic. Use `t.Run()` for executing subtests.
* **Assert Helpers**: Keep assert helper functions simple, and call `t.Helper()` inside them to print correct file/line numbers on test failures.
* **Mock Isolation**: Keep dependencies interfaces minimal (single-method interfaces where possible, e.g. `io.Reader`) to enable simple, local mock implementations rather than giant global mock generators.
