---
name: helics-blueprint
description: HELICS Co-Simulation Architectural Blueprint and Structural Decisions.
paths:
  - "**/*.py"
  - "**/static_inputs.json"
  - "**/input_mapping.json"
applyTo: "**/*.py"
---

# HELICS Co-Simulation Structural Blueprint

## 1. Context & Architecture Guidance
This skill provides the architectural guidelines, topological blueprints, and structural design pattern choices for establishing a HELICS (Hierarchical Engine for Large-scale Infrastructure Co-Simulation) federation. Agents must use this to make critical architectural decisions before writing or refactoring federates.

* **Live Documentation Reference**: If you encounter advanced or undocumented API needs, fetch official docs from `https://docs.helics.org` or inspect the HELICS GitHub repository at `https://github.com/GMLC-TDC/HELICS`.

---

## 2. Trigger Conditions
This skill triggers automatically when:
- Designing or implementing co-simulation federates, brokers, or orchestrators.
- Creating configurations for multi-agent or multi-host systems.
- Modifying timing behaviors, data interfaces (values/messages), or iterative coupling loops.

---

## 3. Core Directives & Lifecycle Invariants

### Topology & Component Isolation
- **Federates**: Keep domain solvers fully isolated. Do not allow direct socket, file, or thread communication between simulators; all coupling data must flow through HELICS interfaces.
- **Cores**: Define core types explicitly. Use `zmq` for network/multi-host environments, and `ipc` or in-process cores for single-host performance.
- **Brokers**: Route all control and timing sync through a central or hierarchical broker tree.

### Data Interface Selection Pattern
1. Use **Value Interfaces** (Publications & Inputs) for physical signals (continuous voltages, currents, temperatures) that must persist across time steps.
2. Use **Message Interfaces** (Endpoints) for discrete, directed signals, packets, or commands (breaker trip events, SCADA setpoints).
3. Use **Filters** exclusively on Message Interfaces to model communication network phenomena (propagation latency, packet drop rates).
4. Use **Translators** to bridge physical measurements to cyber packets (e.g., Publication → Translator → Endpoint).

### Timing Loop Control Invariants
1. Use **Iterative Convergence** via `helicsFederateRequestTimeIterative` when two federates have mutual dependencies at the same time step (algebraic loop). Always specify a convergence tolerance and limit iterations locally to prevent deadlock.
2. Use `uninterruptible = True` for fixed-time-step simulators to optimize network performance.
3. Use `uninterruptible = False` only for event-driven controllers or reactive network components that must act on intermediate updates.

---

## 4. Hard Constraints & Banned Actions
- **NO runtime interface registration**: Do not register Publications, Subscriptions, or Endpoints after entering Executing Mode. All interfaces must be registered in the Defining State.
- **NO circular timing steps without iteration**: Do not step through time sequences sequentially if algebraic feedback loops exist. Use iterative timing requests.
- **NO unbuffered subscriptions**: Always set defaults for inputs (`helicsInputSetDefaultDouble`) during the Defining State to prevent startup solver failures.
- **NO direct thread block/time.sleep**: Time progress must be coordinated exclusively via `helicsFederateRequestTime`.

---

## 5. Reference Blueprints & Code Templates

### A. Topology Design Reference
- **Single-Machine Coupling**: Use an `ipc` core to bypass network serialization overhead.
- **Cluster/HPC Deployment**: Use ZMQ/TCP with a multi-level Broker Hierarchy to balance coordination traffic and avoid single-broker network bottlenecks.

### B. Python Value Registration & Data Exchange Template
```python
import logging
import helics as h

logger = logging.getLogger(__name__)

# 1. Registering (Defining state - MUST do before entering execution)
pub = h.helicsFederateRegisterGlobalTypePublication(
    vfed, "grid_voltage", h.HELICS_DATA_TYPE_DOUBLE, "V"
)
sub = h.helicsFederateRegisterSubscription(vfed, "grid_voltage", "V")

# Invariant: Always set default values immediately after registration
h.helicsInputSetDefaultDouble(sub, 120.0)

# ... Transition to Executing Mode happens here ...

# 2. Publishing and Getting Data (Executing state)
# Invariant: Must request and get time grant before performing I/O
granted_time = h.helicsFederateRequestTime(vfed, requested_time)

# Get subscription data (check if updated first)
if h.helicsInputIsUpdated(sub):
    voltage_reading = h.helicsInputGetDouble(sub)

# Publish data
h.helicsPublicationPublishDouble(pub, 120.1)
```

### C. Python Message Interface & Endpoint Exchange Template
```python
import logging
import helics as h

logger = logging.getLogger(__name__)

# 1. Registering Endpoints (Defining state - MUST do before entering execution)
ep_tx = h.helicsFederateRegisterGlobalEndpoint(vfed, "controller_tx", "")
ep_rx = h.helicsFederateRegisterGlobalEndpoint(vfed, "actuator_rx", "")

# ... Transition to Executing Mode happens here ...

# 2. Sending & Receiving Messages (Executing state)
# Invariant: Must request and get time grant before performing I/O
granted_time = h.helicsFederateRequestTime(vfed, requested_time)

# Send message (directed payload)
h.helicsEndpointSendBytesTo(ep_tx, b"ACTIVATE_BREAKER", "actuator_rx")

# Drain incoming queue (check and pop)
while h.helicsEndpointHasMessage(ep_rx):
    msg = h.helicsEndpointGetMessage(ep_rx)
    payload = msg.data.decode()  # Decodes bytes to string
    source = msg.source          # Source endpoint name
    message_time = msg.time      # Simulation time the message was sent
```

### D. Python Iterative Convergence Template
```python
import logging
import helics as h

logger = logging.getLogger(__name__)

# To resolve circular dependencies at time t:
iteration_state = h.helics_iteration_result_iterating
iteration_count = 0
max_iterations = 50  # Hard invariant to prevent infinite algebraic loop deadlock

while iteration_state == h.helics_iteration_result_iterating:
    if iteration_count >= max_iterations:
        raise RuntimeError(f"HELICS iteration failed to converge at t={requested_time} after {max_iterations} cycles.")

    # Invariant: RequestTimeIterative returns (granted_time, iteration_state)
    granted_time, iteration_state = h.helicsFederateRequestTimeIterative(
        vfed, requested_time, h.helics_iteration_request_iterate
    )
    
    # Read/Write loop
    val = h.helicsInputGetDouble(sub)
    out = compute_physics(val)
    h.helicsPublicationPublishDouble(pub, out)
    iteration_count += 1
    
    # Check convergence condition
    if check_convergence(val, previous_val):
        granted_time, iteration_state = h.helicsFederateRequestTimeIterative(
            vfed, requested_time, h.helics_iteration_request_no_iteration
        )
```
