---
name: skill-generator
description: Agent Skill Generator (Meta-Skill).
paths:
  - "**"
applyTo: "**"
---

# Agent Skill Generator (Meta-Skill)

## Context
This is a global utility playbook designed to autonomously build, format, and deploy specialized, defensive project-level `SKILL.md` guardrails to prevent agent runaway and API misuse.

## Trigger Conditions
Activate this skill automatically when the user issues commands containing phrases like: "generate a skill for", "create a skill for", "build a guardrail playbook for", or "make a skill for".

## Directives

### 1. Framework & Context Extraction
* Identify the exact language and library/API the user is targeting.
* If a URL is explicitly appended to the prompt, use web/browser tools to skim its core lifecycle methods, initialization steps, and structural configuration targets.

### 2. Formulate the 5-Part Defensive Structure
Draft the target content by rigorously populating these exact sections:
1. **# [Skill Name] & Context:** Detail the exact execution paradigm (e.g., event loops, solvers, async hooks) the agent must respect.
2. **## Trigger Conditions:** Specify file extensions, imports, or config shapes that should trigger it.
3. **## Core Directives & Lifecycle Invariants:** Set precise sequential step requirements (e.g., initialization -> execution -> cleanup).
4. **## Hard Constraints & Banned Actions:** List strictly forbidden mutations, optimizations, or file edits.
5. **## Verification & Triage Protocol:** Define fast, localized linting/testing patterns to run before declaring a fix complete.

### 3. Direct Workspace Deployment
* Do not merely dump the raw markdown to the terminal pane. 
* Determine the deployment location:
  - For **general-purpose skills**, save the skill directory to the shared dotfiles directory: `botfiles/.gemini/antigravity-cli/skills/<target-name>/` and write to `SKILL.md`.
  - For **project-specific/API boundary guardrails**, create the directory `.agents/skills/<target-name>-bounds/` inside the active local project root and write to `SKILL.md`.
* Write the generated content directly into a clean `SKILL.md` file within the chosen path.
* Print a success confirmation summary in the terminal indicating the path where the file was written.

