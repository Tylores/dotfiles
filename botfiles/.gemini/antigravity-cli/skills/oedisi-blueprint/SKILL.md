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

## 1. FastAPI Component Wrapper (`server.py`)
```python
from fastapi import BackgroundTasks, FastAPI
from oedisi.types.common import BrokerConfig, ServerReply
import json

app = FastAPI()

@app.post("/configure")
async def configure(config: dict):
    # Save input/static configs to disk for the solver background task
    with open("input_mapping.json", "w") as f:
        json.dump(config.get("input_mapping", {}), f)
    with open("static_inputs.json", "w") as f:
        json.dump(config.get("static_inputs", {}), f)
    return ServerReply(status="configured")

@app.post("/run")
async def run(broker_config: BrokerConfig, background_tasks: BackgroundTasks):
    from .federate import run_simulator
    background_tasks.add_task(run_simulator, broker_config)
    return ServerReply(status="running")
```

## 2. HELICS Logic & Timing Loop (`federate.py`)
```python
import json
import helics as h
from oedisi.types.data_types import VoltagesMagnitude, PowersReal

def run_simulator(broker_config):
    with open("static_inputs.json") as f: static = json.load(f)
    with open("input_mapping.json") as f: mappings = json.load(f)

    # Initialize Federate
    fed_info = h.helicsCreateFederateInfo()
    h.helicsFederateInfoSetCoreTypeFromString(fed_info, "zmq")
    h.helicsFederateInfoSetCoreInitString(
        fed_info, f"--broker_address=tcp://{broker_config.broker_ip}:{broker_config.broker_port} --federates=1"
    )
    vfed = h.helicsCreateValueFederate(static["name"], fed_info)

    try:
        # Register dynamic subscriptions from mappings
        subs = {name: h.helicsFederateRegisterSubscription(vfed, pub, "") for name, pub in mappings.items()}
        for sub in subs.values():
            h.helicsInputSetOption(sub, h.HELICS_HANDLE_OPTION_CONNECTION_OPTIONAL, 1)

        # Register publications
        pub = h.helicsFederateRegisterPublication(vfed, f"{static['name']}/output", h.HELICS_DATA_TYPE_STRING, "")
        
        h.helicsFederateEnterExecutingMode(vfed)
        
        current_time = 0.0
        while current_time < static["end_time"]:
            granted_time = h.helicsFederateRequestTime(vfed, current_time + static["step_size"])
            if granted_time >= static["end_time"]: 
                break
            
            # Read & Validate Inputs using Pydantic Models
            if h.helicsInputIsUpdated(subs["grid_voltages"]):
                raw = h.helicsInputGetString(subs["grid_voltages"])
                voltages = VoltagesMagnitude.model_validate_json(raw)
            
            # Perform Math/Control Solver and Publish Outputs
            output = PowersReal(values=[5.0], ids=["node_1"])
            h.helicsPublicationPublishString(pub, output.model_dump_json())
            
            current_time = granted_time
    finally:
        # Guaranteed cleanup block prevents deadlocks
        h.helicsFederateDisconnect(vfed)
        h.helicsFederateFree(vfed)
        h.helicsCloseLibrary()
```
