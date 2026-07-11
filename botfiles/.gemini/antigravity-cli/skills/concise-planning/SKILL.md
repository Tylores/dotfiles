---
name: concise-planning
description: Concise Checklist Planning.
paths:
  - "**"
applyTo: "**"
---

# Concise Checklist Planning

## Context
The user works in a high-velocity terminal environment. Sprawling multi-paragraph explanations degrade reading efficiency and pollute terminal scrollback.

## Trigger Conditions
Activate automatically when the user asks for a plan, requests a feature scaffold, or passes a multi-file tracking task.

## Directives
1. **The Rule of 5:** When mapping out a solution, provide a maximum of 5 distinct, atomic checkboxes.
2. **Action-Oriented Verbs:** Every list item must start with a direct action verb (e.g., `Modify`, `Add`, `Delete`, `Expose`).
3. **Progress Checklist States**: Use standard checklist states for multi-turn tasks:
   * `[ ]` for planned/pending tasks
   * `[~]` for currently active/in-progress tasks
   * `[x]` for completed tasks
4. **No Conversational Noise:** Drop all conversational prefaces and post-list summaries. Output the checklist immediately and halt execution until the user gives the go-ahead.
