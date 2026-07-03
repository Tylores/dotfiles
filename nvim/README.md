# Neovim Workflow & Motion Guide

This guide compiles essential keyboard motions and IDE workflows for navigating codebases efficiently. 

---

## 1. Class & Function Block Navigation

Jumping between functions and method boundaries is highly efficient when using native Neovim AST/regex-aware motions.

| Motion | Scope | Description |
| --- | --- | --- |
| `]]` | Class / Func | Move forward to the **next** function/class start boundary |
| `[[` | Class / Func | Move backward to the **previous** function/class start boundary |
| `][` | Class / Func | Move forward to the **next** function/class end boundary |
| `[]` | Class / Func | Move backward to the **previous** function/class end boundary |
| `]m` | Method | Move forward to the **next** method start (in object-oriented code) |
| `[m` | Method | Move backward to the **previous** method start |
| `]M` | Method | Move forward to the **next** method end |
| `[M` | Method | Move backward to the **previous** method end |

*Tip: Combine with operators! For example, `v]m` visual-selects up to the next method start.*

---

## 2. Page & Paragraph Navigation

Instead of pressing `j` and `k` repeatedly, use vertical jump motions to cover large spans of text.

### Page Scrolling (Large Jumps)
- `<Ctrl-d>`: Scroll half-page **down** (preserves cursor relative screen position).
- `<Ctrl-u>`: Scroll half-page **up** (preserves cursor relative screen position).
- `<Ctrl-f>`: Scroll full-page **down**.
- `<Ctrl-b>`: Scroll full-page **up**.

### Paragraph Blocks (Medium Jumps)
- `}`: Jump forward to the next empty line/paragraph end.
- `{`: Jump backward to the previous empty line/paragraph start.

### Relative Line Adjustments
- `H`: Move cursor to the **H**igh (top) of the screen.
- `M`: Move cursor to the **M**iddle of the screen.
- `L`: Move cursor to the **L**ow (bottom) of the screen.
- `zz`: Centering the screen around the current cursor line.

---

## 3. Precision Search Jumps

Instead of scrolling manually, search for your target directly to jump there instantly.

### Document-Wide Search
- `/pattern`: Search forward in the document for `pattern`. Press `Enter` to jump, then:
  - `n`: Jump to the next match.
  - `N`: Jump to the previous match.
- `?pattern`: Search backward in the document for `pattern`.

### Word Under Cursor
- `*`: Search forward for the word currently under the cursor.
- `#`: Search backward for the word currently under the cursor.

### Inline (Single-Line) Jumps
- `f<char>`: Find and jump forward to the next occurrence of `<char>` on the current line.
- `F<char>`: Find and jump backward to the previous occurrence of `<char>` on the current line.
- `t<char>`: Jump forward *till* (just before) the next occurrence of `<char>`.
- `T<char>`: Jump backward *till* (just after) the previous occurrence of `<char>`.
- `;`: Repeat the last inline find motion in the same direction.
- `,`: Repeat the last inline find motion in the opposite direction.

---

## 4. IDE Navigation & LSP

Leverage Neovim's Language Server Protocol (LSP) and Telescope mappings to move across files.

- `gd`: Go to definition of the symbol under the cursor.
- `gr`: Go to references of the symbol under the cursor.
- `gI`: Go to implementation of the symbol under the cursor.
- `<Space>sf`: [S]earch [F]iles (FZF/Telescope find file in current workspace).
- `<Space>sg`: [S]earch by [G]rep (Ripgrep live grep across the project).
- `<Space><Space>`: Search existing buffers.

---

## 5. Muscle Memory Exercises

To break the habit of using standard arrow keys or single line `j`/`k` navigation:
1. **The Page Sweep**: When opening a file, use `<Ctrl-d>` or `}` to scan downwards instead of `j`.
2. **The Function Leap**: Use `]]` and `[[` to jump directly into the body of functions when exploring code.
3. **The Target Jump**: Locate a word 5 lines down, use `/word` to jump directly to it instead of navigating to that line manually.
