# Agent Behavior Guidelines

## Just-In-Time (JIT) Skill Activation Protocol
You are strictly forbidden from eagerly loading domain or workflow skills at the start of a turn. Instead, you must evaluate and load skills reactively right before invoking a tool, matching these dynamic execution triggers:

### 1. Dynamic Gateway Dispatcher (Resolution Protocol)
Instead of a rigid mapping matrix, resolve and activate skills dynamically based on the action context:

* **File-Bound Triggers:**
  * **Language-Specific:** When about to read or edit a file, dynamically match its extension to the corresponding language paradigms skill if available (e.g., `*.go` -> `go-paradigms`, `*.rs` -> `rust-paradigms`, `*.py` -> `python-paradigms`, `*.zsh` / `*.sh` -> `zsh-skills`).
  * **Domain-Specific:** Scan the target file for library imports or framework keywords to match domain skills (e.g., imports containing `helics` -> `helics-blueprint`/`helics-bounds`; imports/references containing `dnp3` -> `stepfunc-dnp3-blueprint`/`stepfunc-dnp3-bounds`; references to `oedisi` -> `oedisi-blueprint`/`oedisi-components-bounds`).
* **Tool-Bound Triggers:**
  * Match CLI command prefixes or tool names directly to workflow skills (e.g., commands starting with `git ` -> `git-rules`; large text file edits or modifications -> `token-saver`).
* **Interactive/Context Triggers:**
  * Match user commands or interaction modes to interactive skills (e.g., `/plan` -> `concise-planning`, `/grill-me` -> `grill-me`, `/learn` -> `teach-me`).

### 2. Deduplication & Context Awareness
To minimize context bloat and prevent redundant operations:
* **Check Conversation History:** Before calling `view_file` on a resolved skill, verify if the skill's instructions are already loaded in the conversation history of the current session.
* **Skip Reloading:** If the skill is already present in the context, do NOT call `view_file` again and do NOT print a duplicate JIT activation attestation log.

### 3. Execution Pipeline (The JIT Gate)
Immediately before invoking any tool (excluding `view_file` calls targeting a skill's `SKILL.md` file to prevent recursive activation loops):
1. **Audit:** Determine if the tool, command, or target file matches any dynamic trigger.
2. **Deduplicate:** Check if the matched skill is already present in the active conversation context.
3. **Load:** If NOT already present, execute `view_file` on the corresponding `<skill-name>/SKILL.md` file. Once loaded, proceed directly to executing the original target tool in the next step.
4. **Log Attestation:** Print a single-line indicator to the console output immediately before the tool execution:
   `[JIT Activation: skill-name bound to tool-action]`
5. **Execute:** Run the target tool.

## Multi-Turn Isolation & Command Chaining Ban
* **The Turn-2 Reset:** You must treat every single user prompt as a brand-new authorization boundary. A successful execution on a previous turn does NOT grant you implicit permission to execute downstream actions autonomously.
* **No Multi-Command Chains:** You are strictly prohibited from combining code modifications, staging, committing, and pushing into a single autonomous loop. 
* **The Intercept Protocol:** For any task after the initial setup, you must present your plan, list the exact files you intend to touch, and print an explicit `[AWAITING USER CONFIRMATION]` block. Stop execution immediately and wait for user input before executing any local workspace changes.
