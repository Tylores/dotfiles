---
name: triage
description: "Global Triage & Diagnostics Protocol."
---

# Global Triage & Diagnostics Protocol

## Trigger
Whenever the user passes a stack trace, error message, failing test result, or asks to "identify an issue".

## Directives
1. **Read-Only Analysis:** Restrict execution strictly to reading files and analyzing code context. Do not call tool mutations (`write`, `delete`, `patch`) unless explicitly told to fix it.
2. **No Auto-Implementation:** Halt immediately after the text analysis phase. Do not spawn subagents or generate multi-step Implementation Plans.
3. **Succinct Explanations:** Provide a maximum 3-bullet breakdown of the root cause in the terminal view, showing expected vs. actual behavior.
