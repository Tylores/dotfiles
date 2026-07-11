---
name: helics-bounds
description: HELICS Co-Simulation Lifecycle and API Invariant Guardrails.
paths:
  - "**/*.py"
  - "**/static_inputs.json"
  - "**/input_mapping.json"
applyTo: "**/*.py"
---

# HELICS Co-Simulation Bounds & Context
HELICS (Hierarchical Engine for Large-scale Infrastructure Co-Simulation) coordinates simulation time steps and data exchange across multiple federates. In Python (`pyhelics`), it operates as a strictly synchronized state machine transitioning through specific lifecycles. Any agent modifying or adding HELICS-based components must strictly respect these synchronization states and lifecycle phases to avoid deadlock, memory leaks, and co-simulation divergence.

* **Live Documentation Reference**: If you encounter advanced or undocumented API needs, fetch official docs from `https://docs.helics.org` or inspect the HELICS GitHub repository at `https://github.com/GMLC-TDC/HELICS`.

## Trigger Conditions
This skill triggers automatically when:
- Modifying files containing `import helics` or `import helics as h`.
- Modifying configuration parameters in `static_inputs.json` or `input_mapping.json`.
- Implementing or refactoring co-simulation orchestrators, timing loops, or data publication/subscription handlers.

## Core Directives & Lifecycle Invariants
Code interacting with HELICS must strictly execute lifecycle steps in the following order:

1. **Setup Federate Info**: Configure broker IP, broker port, core name, core type, and properties (e.g. `helics_property_time_delta`) on `helicsCreateFederateInfo()`.
2. **Federate Creation**: Initialize the federate (e.g., `helicsCreateValueFederate` or `helicsCreateCombinationFederate`).
3. **Register Publications & Subscriptions**: Declare all publications and subscriptions *before* transitioning past the Creation state. Always set defaults (e.g., `sub.set_default(...)`) and connection options (e.g., `sub.option["CONNECTION_OPTIONAL"] = True`) immediately after subscription.
4. **Transition to Executing Mode**: Call `helicsFederateEnterExecutingMode(...)`.
5. **Timing Synchronization Loop**:
   - Always request the next time step using `helicsFederateRequestTime(...)`.
   - **Boundary Condition Check**: Check if `granted_time > end_time` (or matches the `HELICS_TIME_MAXTIME` sentinel) to break the loop *before* executing that timestep's physics or solver.
   - Process subscription updates, execute solver steps, and publish new outputs in that sequence.
6. **Resource Finalization**:
   - Cleanly exit using `helicsFederateDisconnect(vfed)`.
   - Free memory resources with `helicsFederateFree(vfed)`.
   - Always unload helper libraries with `helicsCloseLibrary()` to prevent zombie processes.

## Hard Constraints & Banned Actions
- **NO runtime registration**: Registering publications, subscriptions, endpoints, or filters after calling `helicsFederateEnterExecutingMode` is strictly forbidden.
- **NO missing cleanup**: Every federate creation MUST have matching `helicsFederateDisconnect`, `helicsFederateFree`, and `helicsCloseLibrary` execution paths (using try-finally blocks or structured cleanup).
- **NO thread sleep/block synchronization**: Do not use `time.sleep` or blocking operating system calls inside the timing loop; all time progress must be synchronized via `helicsFederateRequestTime`.
- **NO raw unvalidated JSON parses**: Subscription payloads must be parsed with strict schemas/type-validators (such as Pydantic) to fail-fast.

## Verification & Triage Protocol
- **Dry-run Co-Simulation**: Run target federates against a local broker instance (`helics_broker`) or using `helics-cli` configuration targets to check for synchronization or timing errors.
- **Log Inspection**: Verify that setup state, time requests/grants, and finalization sequences are clearly printed to debug/info logs.
