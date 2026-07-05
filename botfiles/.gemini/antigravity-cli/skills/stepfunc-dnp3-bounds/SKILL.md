---
name: stepfunc-dnp3-bounds
description: Step Function I/O DNP3 Library (IEEE 1815) Lifecycle and API Invariant Guardrails.
paths:
  - "**/*.rs"
  - "**/*.cpp"
  - "**/*.h"
  - "**/*.cs"
  - "**/*.java"
applyTo: "**/*.rs"
---

# Step Function I/O DNP3 API & Lifecycle Bounds

## Context
Step Function I/O DNP3 is an asynchronous, high-performance DNP3 (IEEE 1815) protocol stack implemented in Rust with FFI bindings for C, C++, .NET, and Java. It operates within a Tokio-based asynchronous runtime context. Proper usage requires careful sequencing of configuration, database initialization, session spawning, and transaction-safe updates to prevent deadlock, thread blocking, connection flooding, and protocol state divergence.

## Trigger Conditions
This skill triggers automatically when:
- Modifying files containing `dnp3::` or importing DNP3 packages (e.g., `io.stepfunc.dnp3` or `#include <opendnp3/` / stepfunc-specific headers).
- Adding or modifying configurations for DNP3 Masters or Outstations.
- Refactoring communication channels (TCP, TLS, or Serial) or data points (Binary, Analog, Counter, etc.).

## Core Directives & Lifecycle Invariants
Code interacting with the DNP3 stack must adhere to the following sequence and invariants:

1. **Pre-Session Configuration**: 
   - Define database points (Binary, Analog, Counter, etc.) and their configurations (such as class assignments, event variations, deadbands) *before* spawning the channel.
   - Configure Outstation parameters via `OutstationConfig` or Master parameters via `MasterConfig` (e.g., link addresses, timeouts, retries).
2. **Channel Instantiation**:
   - Initialize channels asynchronously within a active Tokio runtime using the library’s connection manager or spawning helper functions (e.g., `spawn_master_tcp_client`, `spawn_outstation_tcp_server`).
   - Define link-layer behavior by setting the appropriate `LinkErrorMode` and reconnect strategies using native `ConnectStrategy` config.
3. **Database Transactions**:
   - Perform all updates to outstation points exclusively using the transactional API on `DatabaseHandle` (e.g., calling `database_handle.transaction(|db| { db.update(...) })`).
   - Keep transaction closures minimal, fast, and completely non-blocking to prevent thread exhaustion or locking out the SCADA event loop.
4. **Control Request Handling**:
   - Implement the `ControlHandler` trait to process incoming SELECT/OPERATE commands from a Master.
   - Ensure callback methods in the handler execute asynchronously or hand off long-running operations to task spawners without blocking the DNP3 worker thread.
5. **Session Teardown**:
   - Explicitly drop or close communication tasks and clean up socket/serial descriptors to prevent connection leakage or socket bind errors upon restart.

## Hard Constraints & Banned Actions
- **NO direct/non-transactional database updates**: Never attempt to modify the outstation point states outside a transactional closure block.
- **NO blocking calls inside transactions**: Never execute synchronous network calls, file I/O, or thread sleep operations within `DatabaseHandle.transaction(...)` closures.
- **NO manual infinite reconnection loops**: Reconnection must rely on native DNP3 library settings (`ConnectStrategy` or `RetryStrategy`). Do not implement raw retry loops wrapping channel creation functions.
- **NO recursive or nested transactions**: Never call a transaction acquisition from within an existing transaction on the same `DatabaseHandle` to avoid self-deadlock.
- **NO unvalidated point index access**: Always validate point indices against configured database dimensions before pushing updates to prevent FFI boundaries or Rust runtime panics.

## Verification & Triage Protocol
- **Compilation Check**: Verify compilation with target transport flags enabled (e.g., `tls`, `serial`) using `cargo check` / `cargo clippy`.
- **Loopback Integration Test**: Validate outstation and master synchronization using a local loopback test connecting to `127.0.0.1` and checking standard handshake logs.
- **Log Diagnostics**: Check trace and debug logs for `LinkError`, connection status transitions, and transaction timing warnings to identify resource contention.
