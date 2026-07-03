# Tmux Session & Window Management

This directory manages the Tmux configuration and session initialization templates.

## Architecture

Instead of managing complex, cluttered split-pane layouts where terminal buffer space is constrained, our environment prioritizes **full-screen modular windows** per project session.

When launching a workspace using the `scry` session-picker, a new Tmux session is initialized with three pre-configured windows mapping to the key developer roles:

```text
+-----------------------------------------------------------+
| [my-project]                                              |
|                                                           |
|  * 1: editor  (runs nvim)                                  |
|    2: agent   (runs agent-cli/llm interactions)           |
|    3: shell   (general command execution & build tasks)    |
|                                                           |
+-----------------------------------------------------------+
```

## Window Directory

### 1. `editor` (Window 1)
- **Startup Action**: Automatically runs `nvim` targeting the project root directory.
- **Purpose**: Your primary IDE view.
- **Flow**: Exiting Neovim returns you to a clean shell prompt in the project directory rather than destroying the window.

### 2. `agent` (Window 2)
- **Startup Action**: Opens to a blank shell prompt targeting the project root.
- **Purpose**: Run LLM agent sessions (`agy`, `copilot`, `claude`, etc.).
- **Benefits**: Isolates heavy LLM text stream output, diff generation, and agent execution logs from your main development shell.

### 3. `shell` (Window 3)
- **Startup Action**: Opens to a blank shell prompt targeting the project root.
- **Purpose**: Running compilation, tests, git commands, and general system administration.

---

## Window Navigation Cheat Sheet

Use these standard Tmux bindings to jump between your workspaces:

| Binding | Action |
| --- | --- |
| `<Ctrl-b> 1` | Switch to **editor** window |
| `<Ctrl-b> 2` | Switch to **agent** window |
| `<Ctrl-b> 3` | Switch to **shell** window |
| `<Ctrl-b> n` | Go to the next window |
| `<Ctrl-b> p` | Go to the previous window |
| `<Ctrl-b> w` | Interactively list and switch windows |
| `<Ctrl-b> d` | Detach from the session |

## Session Picker (`scry`)
To search for projects and launch or attach to this session:
```bash
scry
```
If the session already exists, `scry` attaches to it exactly as you left it without resetting your window configuration.
