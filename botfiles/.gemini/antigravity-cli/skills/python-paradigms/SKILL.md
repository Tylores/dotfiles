---
name: python-paradigms
description: Global Python Execution & Type Safety. Use when working on Python files, scripts, libraries, or virtual environments.
---

# Global Python Execution & Type Safety

## Context
The user writes modular, high-throughput Python applications. Code must prioritize explicit configuration, type safety, and clean resource boundaries.

## Directives

### 1. Strict Type Hinting
* **Mandatory Annotations:** Every function signature must include complete type hints for both input arguments and return values (using the native `typing` module or modern `|` syntax).
* **No Ambiguity:** Avoid using `Any` wherever possible. Define explicit `Union` or generic types instead.

### 2. Defensive State Management
* **No Mutable Defaults:** Never use mutable data structures (like lists `[]` or dicts `{}`) as default arguments in function definitions. Use `None` and initialize them safely inside the function body.
* **Resource Cleanup:** Force the use of context managers (`with` statements) for all file system I/O, network sockets, and database connections to ensure clean resource disposal.

### 3. Async & Event Loops
* **Non-Blocking I/O:** In asynchronous blocks, ensure all network or disk boundaries use explicit `await` gates. Do not mix blocking synchronous libraries inside an `async def` runtime loop.
