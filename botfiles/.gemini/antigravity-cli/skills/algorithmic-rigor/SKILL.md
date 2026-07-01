---
name: algorithmic-rigor
description: Algorithmic Rigor & Mathematical Invariants. Activate automatically when the user asks to implement, refactor, or debug optimization steps, convergence logic, state-space representations, or numerical components.
---

# Algorithmic Rigor & Mathematical Invariants

## Context
The user works on complex systems modeling, distributed optimization algorithms, and multi-component simulations. Code correctness depends on strict adherence to mathematical formulations and boundary boundaries.

## Trigger Conditions
Activate automatically when the user asks to implement, refactor, or debug optimization steps, convergence logic, state-space representations, or numerical components.

## Directives

### 1. Explicit Mathematical Formulations
* **No Hand-Waving:** Before proposing an optimization or simulation adjustment, clearly state the mathematical formulation using standard LaTeX block notation ($$display$$ for standalone equations).
* **Define Variables:** Provide a brief, dense definition list of all parameters, state variables, and indices used in the equation.

### 2. Guard State Invariants & Boundary Bounds
* **Identify Constraints:** Explicitly call out any physical or numerical constraints (e.g., upper/lower limits, step sizes, timing synchronization thresholds).
* **Assert Invariants:** Ensure the code contains explicit assertions or error-bounds handling for these invariants to prevent out-of-bounds array operations or numerical divergence.

### 3. Convergence & Termination Safety
* **Max Iteration Caps:** Every iterative loop or solver routine proposed must include a strict maximum iteration exit condition to prevent infinite background executions.
* **Tolerance Scaling:** Ensure numerical tolerances are parameterized rather than hardcoded into the loop.
