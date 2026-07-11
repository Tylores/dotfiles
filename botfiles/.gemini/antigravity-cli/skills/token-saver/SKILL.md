---
name: token-saver
description: "Context Minimizer & Hunk Diff Protocol."
paths:
  - "**"
applyTo: "**"
---

# Context Minimizer & Hunk Diff Protocol

## Context
The user interacts via a lightweight CLI shell. Dumping massive raw context blocks fills the scrollback buffer and slows down terminal performance.

## Trigger Conditions
Activate automatically whenever the agent is displaying file changes, refactoring code blocks, or performing file comparisons.

## Directives
1. **Hunk Diffs Only:** Never output the untouched sections of a file. Show only the exact multi-line hunk that changed, using standard unified diff format (`+` and `-` markers) with at most 3 lines of surrounding context.
2. **Targeted Reading:** Use pinpoint tools (`grep`, `sed` lines) to read specific areas of a file rather than executing sweeping reads of massive asset logs or database profiles.
3. **Pinpoint Line Ranges**: Always specify `StartLine` and `EndLine` parameters when calling `view_file` to only fetch the exact block of interest (usually 30-80 lines).
4. **Deduplication**: Keep track of previously read files during the current turn. Do not call `view_file` multiple times on the same path unless the file content has changed.
