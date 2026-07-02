---
name: go-paradigms
description: "Global Go (Golang) Architecture & Safety."
applyTo: "**/*.go"
---

# Global Go (Golang) Architecture & Safety

## Context
The user writes highly concurrent, performance-critical Go services. Code must be idiomatic, strictly typed, and completely thread-safe.

## Trigger Conditions
Use when working on Go files, libraries, concurrent services, or compiling Go programs.

## Directives

### 1. Robust Error Handling
* **Immediate Checking:** Never defer or ignore an error. Check `if err != nil` immediately after assignment.
* **Wrap Context:** When bubbling up errors, wrap them with meaningful system context using `fmt.Errorf("context: %w", err)` rather than returning the raw error.

### 2. Concurrency & Channel Safety
* **Prevent Goroutine Leaks:** Every goroutine spawned must have a deterministic lifecycle. Always ensure channels have a clear owner responsible for closing them.
* **Thread-Safe Data:** Restrict concurrent map access. Force the use of `sync.Mutex`, `sync.RWMutex`, or native atomic operations when data pools cross thread boundaries.

### 3. Structural Integrity
* **No Naked Returns:** Do not use named return values with naked `return` statements in functions longer than 5 lines. It degrades readability.
