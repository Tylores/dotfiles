---
name: oedisi-blueprint
description: Code blueprints and templates for OEDISI component implementation.
paths:
  - "Components/**"
  - "scenarios/**"
applyTo: "Components/**/component_definition.json, Components/**/*.py, scenarios/**/*.json"
---

# OEDISI Component Blueprint

This skill contains the minimal code patterns required to build compliant OEDISI FastAPI components and HELICS federates.

* **Live Documentation Reference**: If you encounter advanced or undocumented OEDISI component or orchestrator needs, inspect the openEDI GitHub repository at `https://github.com/openEDI/oedisi`.

## 1. Declarative Configuration Validation Schemas
Always define explicit Pydantic models for configuration files at startup to fail-fast with clean validation exceptions.

```python
from pydantic import BaseModel, Field

class StaticInputs(BaseModel):
    name: str
    end_time: float
    step_size: float
    # Add optional fields with defaults
    port: int | None = None

class InputMapping(BaseModel):
    grid_voltages: str = Field(description="Subscription topic for grid voltages")
    # Add other mapping targets
```

## 2. FastAPI Component Wrapper (`server.py`)
Ensure configuration is validated using the defined schemas at config time, and manage background task thread execution.

```python
import json
import logging
from fastapi import BackgroundTasks, FastAPI, HTTPException
from oedisi.types.common import BrokerConfig, ServerReply
from .schemas import StaticInputs

logger = logging.getLogger(__name__)
app = FastAPI()

@app.post("/configure")
async def configure(config: dict):
    try:
        # Validate static_inputs against schema before writing to disk
        StaticInputs.model_validate(config.get("static_inputs", {}))
        
        with open("input_mapping.json", "w") as f:
            json.dump(config.get("input_mapping", {}), f)
        with open("static_inputs.json", "w") as f:
            json.dump(config.get("static_inputs", {}), f)
            
        return ServerReply(status="configured")
    except Exception as e:
        logger.error(f"Configuration validation failed: {e}")
        raise HTTPException(status_code=400, detail=f"Invalid configuration: {e}")

@app.post("/run")
async def run(broker_config: BrokerConfig, background_tasks: BackgroundTasks):
    from .federate import run_simulator
    background_tasks.add_task(run_simulator, broker_config)
    return ServerReply(status="running")
```

## 3. HELICS Logic & Timing Loop (`federate.py`)
The simulation thread MUST wrap its body in a try-except block to capture and log unhandled exceptions with traceback to stderr. It must also verify loop exit boundaries and limit iterations.

```python
import json
import logging
import traceback
import helics as h
from oedisi.types.data_types import VoltagesMagnitude, PowersReal
from .schemas import StaticInputs

logger = logging.getLogger(__name__)

def run_simulator(broker_config):
    # Setup state logs
    logger.info("Starting simulator background task thread...")
    vfed = None
    
    try:
        # Read and validate inputs using Pydantic
        with open("static_inputs.json") as f:
            static_data = json.load(f)
            static = StaticInputs.model_validate(static_data)
            
        with open("input_mapping.json") as f:
            mappings = json.load(f)

        # Initialize Federate
        fed_info = h.helicsCreateFederateInfo()
        h.helicsFederateInfoSetCoreTypeFromString(fed_info, "zmq")
        h.helicsFederateInfoSetCoreInitString(
            fed_info, f"--broker_address=tcp://{broker_config.broker_ip}:{broker_config.broker_port} --federates=1"
        )
        vfed = h.helicsCreateValueFederate(static.name, fed_info)

        # Register dynamic subscriptions from mappings
        subs = {name: h.helicsFederateRegisterSubscription(vfed, pub, "") for name, pub in mappings.items()}
        for sub in subs.values():
            h.helicsInputSetOption(sub, h.HELICS_HANDLE_OPTION_CONNECTION_OPTIONAL, 1)

        # Register publications
        pub = h.helicsFederateRegisterPublication(vfed, f"{static.name}/output", h.HELICS_DATA_TYPE_STRING, "")
        
        h.helicsFederateEnterExecutingMode(vfed)
        logger.info("Simulator successfully entered HELICS execution mode.")
        
        current_time = 0.0
        while current_time < static.end_time:
            granted_time = h.helicsFederateRequestTime(vfed, current_time + static.step_size)
            
            # Boundary check: Exit loop if granted time exceeds requested limits
            if granted_time > static.end_time:
                logger.info(f"Granted time {granted_time} exceeds end time {static.end_time}. Breaking loop.")
                break
            
            # Read & Validate Inputs using Pydantic Models
            if h.helicsInputIsUpdated(subs["grid_voltages"]):
                raw = h.helicsInputGetString(subs["grid_voltages"])
                voltages = VoltagesMagnitude.model_validate_json(raw)
            
            # Perform Math/Control Solver and Publish Outputs
            output = PowersReal(values=[5.0], ids=["node_1"])
            h.helicsPublicationPublishString(pub, output.model_dump_json())
            
            current_time = granted_time
            
    except Exception as e:
        # Relentless Structured Logging: Wrap all exceptions with tracebacks
        logger.exception("Simulator background task failed with unhandled exception:")
        raise
        
    finally:
        # Guaranteed cleanup block prevents deadlocks
        if vfed is not None:
            logger.info("Cleaning up HELICS federate allocations...")
            h.helicsFederateDisconnect(vfed)
            h.helicsFederateFree(vfed)
        h.helicsCloseLibrary()
        logger.info("Simulator background task thread terminated.")
```
