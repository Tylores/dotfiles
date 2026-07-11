---
name: oedisi-components-bounds
description: OEDISI Component Structure & Co-Simulation Lifecycle Guardrails.
paths:
  - "Components/**"
  - "scenarios/**"
applyTo: "Components/**/component_definition.json, Components/**/*.py, scenarios/**/*.json"
---

# OEDISI Components Guardrails & Context

This skill governs the development, modification, and verification of co-simulation components (federates) and scenarios in the OEDISI (Open Energy Data Initiative - Simulation Infrastructure) framework. 

OEDISI components are containerized HELICS federates wrapped in a FastAPI server executing REST actions. The co-simulation orchestrates value exchanges across federates under the coordination of a central broker.

* **Live Documentation Reference**: If you encounter advanced or undocumented OEDISI component or orchestrator needs, inspect the openEDI GitHub repository at `https://github.com/openEDI/oedisi`.

---

## Trigger Conditions

Activate this skill when:
- Editing or creating files under `Components/` or `scenarios/`.
- Working with component structural configuration files (`component_definition.json`, `pyproject.toml`, `Dockerfile`, `server.py`, or `<federate_logic>.py`).
- Performing simulation builds or runs (`oedisi build` or `oedisi run`).
- Working with `oedisi.types` Pydantic models (e.g., `VoltagesMagnitude`, `PowersReal`, `MeasurementArray`, `BrokerConfig`).

---

## Core Directives & Lifecycle Invariants

### 1. Component Directory Structure
Every component must follow this directory layout:
- `component_definition.json`: Specifies directory name, legacy execution commands, static inputs, and typed dynamic inputs/outputs.
- `Dockerfile`: Container image definition, exposing a unique TCP port, running standard FastAPI server.
- `pyproject.toml`: Modern packaging containing dependencies (`helics>=3.4.0`, `fastapi`, `uvicorn`, `oedisi~=3.0`), with console script endpoint mapped to `<package>.server:main`.
- `mypy.ini` & `pytest.ini`: Configured for typing and testing.
- `src/<package_name>/`: Contains `__init__.py`, `server.py` (FastAPI), `schemas.py` (Pydantic configurations), and `<federate_logic>.py` (HELICS simulation logic).
- `tests/`: Component-level test suites containing unit/integration tests.

### 2. FastAPI Interface Lifecycle & Configuration Validation
Each component's server (`server.py`) must implement and expose three standard REST endpoints:
- `GET /`: Health check returning a `HeathCheck` object with `hostname` and `host_ip`.
- `POST /configure`: Receives a configuration payload, validates it using a strict Pydantic model at startup, and writes `input_mapping.json` and `static_inputs.json` to the filesystem.
- `POST /run`: Accepts `BrokerConfig`, triggers the simulator background task using `BackgroundTasks.add_task`, and immediately returns `{"status": "running"}`.

### 3. Simulation Logic & HELICS Lifecycle
The simulation entry point (`run_simulator(broker_config)`) must strictly follow this HELICS sequence:
1. **Config Validation**: Load and validate configuration inputs (`static_inputs.json`, `input_mapping.json`) using Pydantic models.
2. **Federate Init**: Create value federate (`helicsCreateValueFederate`).
3. **Register I/O**: Register subscriptions and publications mapping to `input_mapping.json`.
4. **Time Request Loop**: Enters execution mode and requests times sequentially via `helicsFederateRequestTime`.
   - **Boundary Check**: Exit loop if `granted_time > end_time` (or matches `HELICS_TIME_MAXTIME`).
   - **Iterative Limits**: If using iterative updates, implement a local iteration counter (limit to 50 or 100) to prevent algebraic loop deadlocks.
5. **Data Handling**: On every timestep, retrieve subscriptions, deserialize JSON into OEDISI Pydantic types, perform logic, serialize, and publish outputs.
6. **Thread Exception Wrapping**: The entire simulator background thread body must run in a `try-except Exception` block, logging unhandled exceptions with full stack traces (`logger.exception`) to stderr.
7. **Cleanup**: Guaranteed cleanup calling `helicsFederateDisconnect`, `helicsFederateFree`, and `helicsCloseLibrary` inside a `finally` block to prevent zombie processes.

---

## Hard Constraints & Banned Actions

- **No Blocked /run Responses**: Never run the simulation loop synchronously inside the FastAPI endpoint. It must always be run as a background task.
- **No Ad-Hoc Data Structures**: Always utilize `oedisi.types.data_types` Pydantic models for parsing, processing, and publishing data. Do not use plain dicts or custom models.
- **Port Collisions**: Do not duplicate TCP ports across components. Check `component-structure.md` and `scenarios/` for existing ports (e.g., Broker `8766`, LocalFeeder `5678`, wls_federate `5683`).
- **No Stubbing / Bypassing Submodules**: When adding features to components, do not bypass git submodule structures or leave mock/stub endpoints without logic.

---

## Verification & Triage Protocol

### 1. Static Validation & Formatting
- **Linter & Formatter**: Run `pre-commit run --all-files` or `ruff check` on modified component files.
- **Type Check**: Run `mypy` inside the component directory to ensure strict type compliance.

### 2. Testing & Simulation Verification
- **Unit Testing**: Run `pytest Components/<component_name>/tests/` to run component-specific tests.
- **Scenario Build Verification**: Verify configuration builds using:
  ```bash
  oedisi build --system scenarios/<scenario>.json
  ```
- **Scenario Execution**: Run the simulation end-to-end to confirm it completes successfully:
  ```bash
  oedisi run
  ```
