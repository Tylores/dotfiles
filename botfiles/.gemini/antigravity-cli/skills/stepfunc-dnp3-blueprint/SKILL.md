---
name: stepfunc-dnp3-blueprint
description: Step Function I/O DNP3 asynchronous outstation/master blueprints, trade-offs, and database configuration.
paths:
  - "**/*.rs"
applyTo: "**/*.rs"
---

# Step Function I/O DNP3 Blueprint & Context

## Context
This playbook outlines the architectural best practices, core design patterns, and engineering trade-offs when implementing DNP3 Masters and Outstations in Rust using the asynchronous, Tokio-based `stepfunc/dnp3` library. 

---

## Trigger Conditions
This skill triggers automatically when:
*   Modifying files containing imports or usages of the `dnp3` crate.
*   Implementing or refactoring outstation database setups or transactions.
*   Implementing or modifying `ControlSupport<T>` or `ControlHandler` traits.
*   Writing master command dispatching logic or outstation control loop integrations.

---

## 1. First-Principles Architecture & Mechanics

### The Asynchronous Runtime & Thread Starvation
The `stepfunc/dnp3` library is fully asynchronous and runs its core protocol engines (link-layer confirmation, TCP/TLS state machines, and session-level keep-alives) on background tasks inside a shared `tokio` runtime. 

When a Master sends a control request, the library calls the Outstation's command handler callbacks (e.g., `operate`) synchronously from the stack's event loop to get a `CommandStatus`.
*   **The Consequence of Blocking:** If you block inside a control handler method (e.g., via `std::thread::sleep` or waiting on a physical relay contact to close), you starve the DNP3 stack's event loop. 
*   **The Chain Reaction:** Stalling the event loop halts TCP keep-alive heartbeats, fails to respond to concurrent SCADA polls, blocks inbound alarms, and leads the SCADA Master to assume the Outstation has crashed, resulting in complete session teardowns.

### The Points Database Transaction Model
The Outstation's point database (telemetry input/output arrays) is shared between the protocol runner tasks (which read points to build SCADA poll responses) and the application tasks (which write telemetry updates).
*   **Safety via `DatabaseHandle`:** All database mutations must happen within a transactional closure:
    ```rust
    database_handle.transaction(|db| {
        db.update(index, &BinaryInput::new(true, Flags::ONLINE, timestamp), UpdateOptions::detect_event());
    });
    ```
*   **Transaction Invariants:** Transactions ensure thread safety, memory integrity, and atomic event generation. However, closures must be minimal, fast, and entirely non-blocking to prevent locking up the event loop.

---

## 2. Core Directives & Lifecycle Invariants

### 1. Pre-Session Database Configuration & Sizing
The database schema must be defined statically *before* spawning the communication channels. You cannot dynamically add points once the outstation starts. The layout is configured via `DatabaseConfig` and per-point configuration types:

```rust
use dnp3::app::PointClass;
use dnp3::outstation::database::{
    DatabaseConfig, BinaryConfig, AnalogConfig, CounterConfig, 
    StaticAnalogVariation, EventAnalogVariation
};

fn configure_outstation_database() -> DatabaseConfig {
    // Each index in the vector corresponds to that DNP3 point index (0-based)
    DatabaseConfig {
        // Configure Binary Inputs (e.g., status contacts, limit switches)
        binary_inputs: vec![
            // Point Index 0: Default configuration
            BinaryConfig::default(),
            // Point Index 1: Explicitly assigned to Class 1 for event scans
            BinaryConfig {
                clazz: PointClass::Class1,
                ..Default::default()
            },
        ],

        // Configure Analog Inputs (e.g., measurements, voltages, flows)
        analog_inputs: vec![
            // Point Index 0: Detailed class, variation, and deadband setup
            AnalogConfig {
                clazz: PointClass::Class2, // Generate Class 2 events on change
                deadband: 0.5,             // Only trigger event if change >= 0.5
                static_variation: StaticAnalogVariation::Group30Var5, // Double precision float
                event_variation: EventAnalogVariation::Group32Var7,   // Double precision event
            }
        ],

        // Configure Counters (e.g., pulse accumulation, energy meters)
        counters: vec![
            CounterConfig {
                clazz: PointClass::Class3,
                ..Default::default()
            }
        ],

        ..Default::default() // Handles double-binary, octet-strings, etc.
    }
}
```

#### Point Configuration Parameters:
*   **`clazz` (PointClass):** Class 0 represents static data. Classes 1, 2, and 3 represent event classes. Assigning a point to Class 1/2/3 enables the generation of change events that the Master can fetch during class scans.
*   **`deadband`:** For Analog points, event generation is throttled by a deadband threshold. An event is only queued if `|new_value - last_event_value| >= deadband`.
*   **`static_variation` & `event_variation`:** Sets the default DNP3 group/variation data format (e.g., 16-bit integer, 32-bit float, or double-precision float) returned during polls.

---

### 2. Outstation Control Handler (Asynchronous Delegation Pattern)
To execute control operations (such as CROB commands) without blocking the event loop, you must delegate the physical operation to a background task and return immediately:

```rust
use dnp3::app::{Group12Var1, CommandStatus, BinaryInput, Flags};
use dnp3::outstation::{ControlSupport, OperateType, DatabaseHandle, UpdateOptions};
use std::time::SystemTime;

struct MyControlHandler {
    // Maintain a cloneable DatabaseHandle inside the handler struct
    db_handle: DatabaseHandle, 
}

impl ControlSupport<Group12Var1> for MyControlHandler {
    fn select(
        &mut self,
        _control: Group12Var1,
        index: u16,
        _db: &mut DatabaseHandle,
    ) -> CommandStatus {
        // Perform fast, synchronous validation checks against database boundaries
        if index > MAX_VALVE_INDEX {
            return CommandStatus::NotSupported;
        }
        CommandStatus::Success
    }

    fn operate(
        &mut self,
        _control: Group12Var1,
        index: u16,
        _op_type: OperateType,
        _db: &mut DatabaseHandle, // DO NOT move or capture this borrowed reference!
    ) -> CommandStatus {
        // 1. Clone the thread-safe DatabaseHandle held by the struct
        let mut db_clone = self.db_handle.clone();
        
        // 2. Spawn a background task to manage physical latency
        tokio::spawn(async move {
            // Simulate slow hardware movement (e.g. 5 seconds to open a valve)
            tokio::time::sleep(std::time::Duration::from_secs(5)).await;
            
            // 3. Update the database asynchronously from the background task
            db_clone.transaction(|db| {
                db.update(
                    VALVE_LIMIT_SWITCH_INDEX,
                    &BinaryInput::new(true, Flags::ONLINE, SystemTime::now().into()),
                    UpdateOptions::detect_event()
                );
            });
        });

        // 4. Acknowledge command receipt immediately to keep communication alive
        CommandStatus::Success
    }
}
```

---

### 3. Master Closed-Loop Control Verification
Since the Outstation returns `CommandStatus::Success` immediately upon command delegation, the Master must implement a verification loop:

```rust
// 1. Locally verify state pre-command to save bandwidth
if current_telemetry_state(STATUS_INDEX) == TargetState {
    return Ok(());
}

// 2. Dispatch command asynchronously
let cmd_status = master.select_and_operate(control, cmd_index).await?;
if cmd_status != CommandStatus::Success {
    return Err(CommandError::Rejected(cmd_status));
}

// 3. Monitor for state change under a timeout (Verification Window)
let verification_timeout = std::time::Duration::from_secs(15);
let start_time = std::time::Instant::now();

while start_time.elapsed() < verification_timeout {
    if current_telemetry_state(STATUS_INDEX) == TargetState {
        return Ok(()); // Success verified!
    }
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;
}

Err(CommandError::ExecutionTimeout)
```

---

## 3. Engineering Trade-Off Matrices

### Database Access Models
| Strategy | Benefits (Gains) | Costs (Sacrifices) |
| :--- | :--- | :--- |
| **Transactional Closure** | Thread safety, memory integrity, atomic state commits, guaranteed event registration. | Stalls protocol stack if blocked, prone to self-deadlock if nested. |
| **Raw/Unsynchronized** | High performance, direct array reads/writes. | Race conditions, dirty reads, missing or misordered event generation. |

### Control Operations State Verification
| Strategy | Benefits (Gains) | Costs (Sacrifices) |
| :--- | :--- | :--- |
| **Async Task + Cloned Handle** | Zero communication jitter, stack is always responsive to polls, events, and keep-alives. | Temporary telemetry inconsistency (Master gets Success before physical completion). |
| **Synchronous Blocking** | Direct consistency (command result is physical result). | Network timeouts, dropped connections, blocked alarms. |

### Master Verification Strategies
| Strategy | Benefits (Gains) | Costs (Sacrifices) |
| :--- | :--- | :--- |
| **Event-Driven Verification** | Low network overhead, instant notifications. | Requires state mapping tables on SCADA Master. |
| **Active Telemetry Polling** | Simpler Master logic. | High poll bandwidth overhead. |

---

## 4. Hard Constraints & Banned Actions
*   **NO Synchronous Blocking in Callbacks:** Absolutely ban `std::thread::sleep`, synchronous mutex locks (unless fast/non-blocking), or blocking socket operations inside `select`, `operate`, or `direct_operate` methods.
*   **NO Borrow Capture in Spawn:** Never attempt to capture, move, or clone the `&mut DatabaseHandle` parameter from event loop callbacks into a `tokio::spawn` closure. Always capture a clone of the setup-level `DatabaseHandle`.
*   **NO Nested/Recursive Transactions:** Never call `.transaction(...)` within an existing transaction closure block on the same `DatabaseHandle` to avoid self-deadlock.

---

## 5. Verification & Triage Protocol
*   **Compilation Check:** Compile the crate and run `cargo clippy` to ensure no blockages occur.
*   **Session Stability Loopback:** Connect a local Master to a local Outstation at `127.0.0.1`. Fire a sequence of 10 rapid CROB commands while executing a Class 0 poll on another thread. Verify that no TCP timeouts or keep-alive packet losses occur.
*   **Log Verification:** Monitor for warnings like `LinkError` or transaction lock timing alerts to identify lock contention.
