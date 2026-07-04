---
name: project-compliance
description: Review a project based on applicable skills and project context.
paths:
  - "**"
applyTo: "**"
---

# Project Compliance Audit & Context

## Context
This skill empowers the agent to act as a compliance auditor, scanning legacy or active codebases to verify they conform to the user's active paradigm skills (e.g., `git-rules`, `anti-stub-enforcement`, `rust-paradigms`, `go-paradigms`, `python-paradigms`, etc.). The review must be agent-driven, using the active guidelines as an inspection checklist, and prioritizing scalability on large codebases.

## Trigger Conditions
Activate this skill when the user requests a compliance review, paradigm audit, or codebase check (e.g., using phrases like "review this project for compliance", "run a paradigm audit", "check if this project passes my bounds", "audit the codebase against active skills").

## Core Directives & Lifecycle Invariants
1. **Technology & Skill Mapping**: Scan the project structure and configuration files (e.g., `Cargo.toml`, `go.mod`, `requirements.txt`, `.git`, `helics.json`, etc.) to auto-detect active languages, frameworks, and tools.
2. **Retrieve Guidelines**: Map the detected technologies to the corresponding active paradigm skills in `botfiles/.gemini/antigravity-cli/skills/` (and any local/project-specific bounds).
3. **Scoped Inspection**: To prevent token exhaustion in large codebases, prioritize auditing entry points, public API boundaries, and recent modifications first. If necessary, use subagents in a divide-and-conquer structure to review module-by-module to prevent context/token limits.
4. **Agent-Driven Gap Analysis**: Run static inspections and semantic checks against the loaded skills' hard constraints and core directives. Look for common violations such as anti-patterns, stubs, improper Git commit styles, or violated lifecycle invariants.
5. **Generate Compliance Report**: Output a structured Markdown report in the conversation or as a workspace artifact (e.g., `project_compliance_report.md`):
   - **Summary Table**: List of detected technologies, active skills loaded, and overall status.
   - **Violations**: A detailed list of found violations categorized by skill, including severity, specific file links (using `file://` line ranges), and explanation.
   - **Remediation Plans**: Pre-drafted Git diffs or refactoring proposals for the violating code blocks, designed to be easily copy-pasted or approved.

## Hard Constraints & Banned Actions
- Do NOT perform automated file modifications or refactoring on the target codebase without explicit user confirmation.
- Do NOT read the entire codebase into context at once. Always chunk, search, and target files systematically.
- Do NOT ignore any active paradigm skill that maps to the detected technology stack.

## Verification & Triage Protocol
1. Verify that all links in the generated report point to valid files and lines.
2. Ensure any proposed remediation diff is syntax-valid and addresses the specific paradigm violation.
