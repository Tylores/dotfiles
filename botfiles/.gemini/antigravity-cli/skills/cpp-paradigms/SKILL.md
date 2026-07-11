---
name: cpp-paradigms
description: Modern C++ (C++17/C++20/C++23) Architecture, Memory Safety, and Best Practices.
paths:
  - "**/*.cpp"
  - "**/*.hpp"
  - "**/*.cc"
  - "**/*.h"
  - "**/*.cxx"
  - "**/CMakeLists.txt"
applyTo: "**/*.cpp"
---

# C++ Paradigms & Context

This skill defines the rules, paradigms, and safety guardrails for writing and refactoring C++ code. The target is modern C++ (C++17/C++20/C++23), focusing on memory safety, resource management, performance, and clear API design.

All agents must adhere to these directives to prevent memory leaks, undefined behavior (UB), race conditions, and build system degradation.

## Trigger Conditions
Activate this skill dynamically when reading, writing, or editing files matching:
* File extensions: `.cpp`, `.hpp`, `.cc`, `.h`, `.cxx`, `.ixx`
* Build files: `CMakeLists.txt`, `*.cmake`
* Key C++ include headers or keywords (e.g., `#include <iostream>`, `#include <memory>`, `std::`, `class `, `template <`)

## Core Directives & Lifecycle Invariants

### 1. Resource Management (RAII)
* **Strict Ownership:** Every resource (memory, file descriptors, sockets, mutexes) must be owned by an RAII object.
* **Smart Pointers over Raw Pointers:**
  * Use `std::unique_ptr` for exclusive ownership. Prefer `std::make_unique<T>()`.
  * Use `std::shared_ptr` and `std::weak_ptr` for shared ownership. Prefer `std::make_shared<T>()`.
  * Raw pointers (`T*`) are allowed ONLY as non-owning observers. They must never call `delete` or own the resource lifetime.
* **Rule of Zero/Three/Five:**
  * Prefer the **Rule of Zero**: design classes such that they don't need custom destructors, copy/move constructors, or copy/move assignment operators (by using standard components like `std::string`, `std::vector`, smart pointers).
  * If a custom destructor is needed, explicitly declare or delete all five special member functions (Destructor, Copy Constructor, Copy Assignment, Move Constructor, Move Assignment).

### 2. Concurrency and Thread Safety
* **Mutex Guarding:** Always use `std::lock_guard` or `std::unique_lock` to manage mutex lifetimes. Never call `mutex.lock()` and `mutex.unlock()` manually.
* **Avoid Deadlocks:** When acquiring multiple mutexes, use `std::lock` or C++17 `std::scoped_lock`.
* **Thread-Safe Data Structures:** Ensure shared state is protected against concurrent read-write access. Prefer using standard synchronization primitives (`std::atomic`, `std::shared_mutex`).

### 3. Modern Language Features & Type Safety
* **Const Correctness:** Make member functions `const` if they do not modify state. Mark variables `const` or `constexpr` by default.
* **Auto Type Deduction:** Use `auto` when the type is redundant, long, or returned by a factory/iterator. Ensure it doesn't obscure the code's readability.
* **Type-Safe Casts:** Use `static_cast`, `const_cast`, `reinterpret_cast`, or `dynamic_cast`. Never use C-style casts `(Type)value`.
* **Zero Initialization:** Always initialize variables immediately upon declaration.

### 4. Build System (CMake) Integration
* **Modern CMake (Target-Based):** Use `target_link_libraries`, `target_include_directories`, and `target_compile_options` instead of directory-level commands (`include_directories`, `link_libraries`).
* **Warning Levels:** Set compiler warning levels high (e.g., `-Wall -Wextra -Wpedantic -Wconversion`) and treat warnings as errors in CI/CD.

## Hard Constraints & Banned Actions

* **No Raw Memory Allocation:** Never use `malloc`, `calloc`, `realloc`, or `free`. Never use raw `new` or `delete` unless writing custom low-level data structures (which must be wrapped in RAII classes).
* **No `using namespace std;` in Headers:** Never use `using namespace std;` (or any other namespace) in the global scope of header files.
* **No C-Style Arrays:** Never use raw arrays (e.g., `int arr[10];`). Use `std::array` or `std::vector` instead.
* **No Raw C Strings:** Avoid `char*` and `const char*` for string manipulation. Use `std::string` or `std::string_view` (C++17) for read-only string parameters.
* **No Preprocessor Macros for Constants/Functions:** Use `constexpr` or `const` for constants, and `inline` or `constexpr` functions/templates instead of `#define` macros.
* **No Undefined Behavior (UB):** Avoid returning references or pointers to local/temporary variables, accessing out-of-bounds container indices, or dereferencing null pointers.

## Verification & Triage Protocol

Before declaring a change or fix complete:
1. **Compile cleanly:** Compile the project using the configured build tool (e.g., `cmake --build build`). Ensure zero warnings.
2. **Run Clang-Tidy / Static Analysis:** If available, run static analysis to check for guideline violations:
   ```bash
   clang-tidy -p build/ path/to/file.cpp
   ```
3. **Execute Unit Tests:** Run the test suite (e.g., `ctest --test-dir build` or direct executable invocation) to verify that no functional regressions were introduced.
4. **Sanitizer Checks:** If compiling with sanitizers (ASan, UBSan, TSan), run tests to ensure no memory leaks, buffer overflows, or data races are flagged.
