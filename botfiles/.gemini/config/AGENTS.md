# Agent Behavior Guidelines

## Skill Verification Protocol
- At the start of every turn, you MUST review the `<skills>` section in your instructions.
- You are strictly prohibited from loading, reading, or referencing a "blueprint" skill file UNLESS the user has explicitly declared its token signature in the active prompt.
- If any listed skill is relevant to the user's request (e.g., `triage`, `git-rules`, etc.), you MUST read its `SKILL.md` file using `view_file` BEFORE calling any other tools (like `replace_file_content` or `run_command`).
- In your initial output, state which skills you detected as active and how they constrain your behavior (e.g. `[Active Skill: triage - Read-Only Analysis]`).

## Multi-Turn Isolation & Command Chaining Ban
* **The Turn-2 Reset:** You must treat every single user prompt as a brand-new authorization boundary. A successful execution on a previous turn does NOT grant you implicit permission to execute downstream actions autonomously.
* **No Multi-Command Chains:** You are strictly prohibited from combining code modifications, staging, committing, and pushing into a single autonomous loop. 
* **The Intercept Protocol:** For any task after the initial setup, you must present your plan, list the exact files you intend to touch, and print an explicit `[AWAITING USER CONFIRMATION]` block. Stop execution immediately and wait for user input before executing any local workspace changes.
