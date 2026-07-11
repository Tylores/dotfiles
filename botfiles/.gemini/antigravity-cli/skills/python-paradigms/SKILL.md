---
name: python-paradigms
description: "Global Python Execution, Type Safety, and Modern Best Practices."
paths:
  - "**/*.py"
applyTo: "**/*.py"
---

# Global Python Execution & Type Safety

## Context
Guidelines for building modern, modular, production-ready Python applications. Every line of Python must prioritize type safety, deterministic resource cleanup, robust exception hierarchies, and clear concurrency boundaries.

## Trigger Conditions
Activated automatically when reading, writing, or editing Python source files (`*.py`), tests, configuration, or package metadata.

## Directives

### 1. Strict Type Hinting & Static Analysis
* **Mandatory Annotations**: Every function and method signature must include explicit type hints for all parameters and return values (e.g., use modern union syntax `int | None` rather than `Optional[int]`).
* **No Untyped Generics**: Do not use raw container types. Always specify child types (e.g., `list[str]`, `dict[str, int]`).
* **Avoid `Any`**: Use precise types, `TypeVar` (generics), `Protocol` (structural subtyping/interfaces), or abstract base classes (`abc.ABC`) to resolve design requirements without resorting to `Any`.
* **Explicit Casting**: If external library boundaries lack types, use `typing.cast` explicitly rather than suppressing checker warnings.

### 2. Defensive State & Resource Management
* **No Mutable Defaults**: Never define default arguments as mutable objects (e.g., `def func(x=[])`). Use `None` as the default and initialize the object inside the function body.
* **Immutability by Default**: Prefer `frozen=True` dataclasses, `NamedTuple`, or read-only properties for configuration and value objects to avoid unintended side effects.
* **Deterministic Cleanup**: Force the use of context managers (`with` or `async with` blocks) for all I/O operations (file reads/writes, HTTP requests, database transactions, sockets). Never rely on garbage collection for closing resources.

### 3. Error Handling & Logging
* **No Bare Exceptions**: Never write `except:` or `except Exception:`. Catch the specific exceptions that are expected (e.g., `ValueError`, `KeyError`, `FileNotFoundError`).
* **Exception Chaining**: Always use `raise CustomError(...) from err` when wrapping or translating exceptions to preserve the stack trace.
* **Structured Logging**: Use a structured logger (`logging` or `structlog`) with appropriate levels (`DEBUG`, `INFO`, `WARNING`, `ERROR`). Do not use `print()` statements for diagnostic logs.

### 4. Asynchronous & Concurrency Guidelines
* **Non-blocking Event Loops**: In `async def` routines, never call synchronous blocking calls (e.g., `time.sleep`, synchronous database drivers, file system reads/writes) directly. Offload these calls to a separate executor using `asyncio.to_thread` or `loop.run_in_executor`.
* **Explicit Task Lifecycles**: Always await tasks or use Task Groups (PEP 654 / Python 3.11+) to run tasks concurrently. Avoid "fire-and-forget" tasks unless they are explicitly managed by an active background task tracker.

### 5. Pythonic Style & Modern APIs
* **Docstring Standards**: Follow Google style docstrings for all classes, methods, and modules. Include a brief summary, arguments with types, return descriptions, and exceptions raised.
* **Standard Library Over Custom Code**: Leverage specialized standard library tools (e.g., `collections.deque` for queues, `collections.Counter` for counting, `pathlib.Path` for file path manipulation, `enum.Enum` for constants).
* **Generator Expressions**: Prefer generators or `yield` for memory-efficient stream processing over generating massive lists in-memory.

### 6. Testing & Testability
* **Modular Testing with Pytest**: Design functions with dependency injection (e.g., pass db connections/clients as arguments) to facilitate simple mocking.
* **Avoid Global Mocks**: Prefer `pytest` fixtures for setup/teardown and scope isolation. Use `unittest.mock` cleanly and narrow its scope to the execution boundary of the test.

### 7. Environment & Dependency Management
* **Tool Detection**: Prioritize project-specific dependency managers by detecting lockfiles:
  * If `uv.lock` is present, always use `uv` commands (e.g., `uv pip install`, `uv run`).
  * If `poetry.lock` is present, always use `poetry` commands.
  * If `requirements.txt` is present, use standard `pip` within a virtual environment.
* **Declarative Configuration**: Define dependencies, metadata, and tool settings in `pyproject.toml` (following PEP 518 / PEP 621) rather than legacy `setup.py` or multiple standalone config files.
