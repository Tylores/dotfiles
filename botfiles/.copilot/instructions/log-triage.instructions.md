---
name: log-triage
description: "Diagnostic Log Triage & Root Cause Analysis."
applyTo: "**"
---

# Diagnostic Log Triage & Root Cause Analysis

## Context
The user passes raw terminal scrollbacks, integration test logs, or multi-component stdout outputs to diagnose execution crashes.

## Trigger Conditions
Activate immediately whenever the user inputs a text block containing compiler panics, stack traces, test framework failures, or execution log output.

## Directives

### 1. Isolate the Primary Fault Line
* **Locate the First Panic:** Ignore superficial warnings or post-crash exit codes. Search the log text to find the absolute *first* occurrence of a runtime exception, compiler failure, or hardware panic.
* **Extract the Stack Trace:** Output only the relevant stack frame lines showing the file path, line number, and function where the violation originated.

### 2. Suppress Ambient Noise
* **Omit Success Telemetry:** Completely strip out routine initialization messages, heartbeats, status updates, or successful test indicators from your analysis display.
* **Focus on Context Changes:** Look for the precise moment where a variable state or environment flag changed immediately preceding the failure.

### 3. Provide an Actionable Remedy
* Do not just restate the error message. Provide a concise explanation of *why* the failure occurred based on the log architecture, followed by the exact code modification or shell command required to fix it.
