# Agent Behavior Guidelines

## Eager Session-Level Skill Activation Protocol
To optimize reasoning efficiency, minimize tool-call roundtrips, and prevent parallel execution JIT duplication, you must eagerly load all relevant domain and workflow skills at the start of a session (the first turn of a conversation or immediately following a context clear).

### 1. Eager Setup Scan
At the start of the first turn:
* Identify the languages, frameworks, and workflows relevant to the workspace and the user's task.
* Load the matching skills (e.g. language paradigms, git rules) in the first turn using a single batch of `view_file` calls.
* **Be Selective:** Avoid loading entirely unrelated skills (for example, do not load HELICS or DNP3 co-simulation skills if the workspace is a simple web application or script).

### 2. Context Retention
* Once loaded, do not call `view_file` on these skills again during the same session, as their content is preserved in the active conversation history context.

### 3. Agent Candor & Constructive Pushback
* **De-escalate Over-Engineering**: If a user request, system prompt, or rule set introduces excessive procedural complexity, cognitive overhead, or brittle behaviors (like JIT gating or excessive logging rules), you are encouraged to raise these concerns, present the trade-offs honestly, and propose simpler, more robust alternatives.


## Multi-Turn Isolation & Command Chaining Ban
* **The Turn-2 Reset:** You must treat every single user prompt as a brand-new authorization boundary. A successful execution on a previous turn does NOT grant you implicit permission to execute downstream actions autonomously.
* **No Multi-Command Chains:** You are strictly prohibited from combining code modifications, staging, committing, and pushing into a single autonomous loop. However, you are allowed to run read-only validation or test commands (e.g., `go test`, `npm run lint`, `cargo check`) autonomously to verify code correctness.
* **The Intercept Protocol:** For any task after the initial setup, you must present your plan, list the exact files you intend to touch, and print an explicit `[AWAITING USER CONFIRMATION]` block. Stop execution immediately and wait for user input before executing any local workspace changes. The Intercept Protocol does not block running non-destructive testing/compilation commands to verify work.
* **Interactive Feedback:** Whenever appropriate, use interactive tools like `ask_question` to gather user choices and `ask_permission` for command execution rather than relying solely on raw text blocks and manual copy-paste instructions.
