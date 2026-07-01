# Strict Implementation & Anti-Stub Policy

## Context
The user requires complete, production-ready source text. Code placeholders break linting trees and require manual human intervention.

## Trigger Conditions
Activate whenever the agent is formatting a patch file, generating code blocks, or refactoring existing modules.

## Directives
1. **Zero Placeholders:** You are strictly forbidden from inserting placeholders, ellipsis (`...`), or `// TODO` blocks inside written files or proposed code blocks. 
2. **Complete Functions:** Every function, struct, loop, or match pattern you alter must be written out completely with real, operational logic.
3. **Surcharging Self-Critique:** If a code block is too long to generate without truncating, halt and ask the user to split the file up rather than emitting half-implemented blocks.
