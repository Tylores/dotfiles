# Agent Behavior Guidelines

## Skill Verification Protocol
- At the start of every turn, you MUST review the `<skills>` section in your instructions.
- If any listed skill is relevant to the user's request (e.g., `triage`, `git-rules`, etc.), you MUST read its `SKILL.md` file using `view_file` BEFORE calling any other tools (like `replace_file_content` or `run_command`).
- In your initial output, state which skills you detected as active and how they constrain your behavior (e.g. `[Active Skill: triage - Read-Only Analysis]`).
