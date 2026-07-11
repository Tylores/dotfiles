---
name: anti-stub-enforcement
description: "Strict Implementation & Anti-Stub Policy."
paths:
  - "**"
applyTo: "**"
---

# Strict Implementation & Anti-Stub Policy

## Context
The user requires complete, production-ready source text. Code placeholders break linting trees and require manual human intervention.

## Trigger Conditions
Activate whenever the agent is formatting a patch file, generating code blocks, or refactoring existing modules.

## Directives
1. **Zero Placeholders:** You are strictly forbidden from inserting placeholders, ellipsis (`...`), `// TODO` blocks, or `/* unchanged code */` inside written files or proposed code blocks.
2. **Complete Functions:** Every function, struct, loop, or match pattern you alter must be written out completely with real, operational logic.
3. **Precision Hunks over Sweeping Rewrites**: Prefer targeted replacements using line ranges (`replace_file_content`) to modify code rather than rewriting large files.
4. **Self-Critique Checklist**: Prior to rendering code, do a mental compilation check to confirm that all referenced imports, variables, and utility methods are fully declared and operational.
5. **No Nesting Truncation**: When editing code blocks with nested braces or conditional blocks, do not skip the inner blocks or inner statements.
