# glassbox

**See inside your AI-written code without reading it.**

Glassbox auto-generates a mermaid-diagram companion file (`.vis.md`) for every code file your agent edits. Instead of reading raw diffs, you scan four diagrams: a change timeline, a structure diagram, a control-flow diagram, and a dependency graph. Spend 30 seconds instead of 10 minutes.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/glassbox/install.sh | bash
```

Or, from a clone:

```bash
bash packs/glassbox/install.sh
```

## Uninstall

```bash
bash packs/glassbox/install.sh --uninstall
```

## What gets installed

| File | Destination |
|------|-------------|
| `rules/glassbox.mdc` | `~/.cursor/rules/glassbox.mdc` |
| `hooks/check-vis-md.sh` | `~/.cursor/hooks/check-vis-md.sh` (chmod +x) |
| `hooks.json` (merged) | `~/.cursor/hooks.json` (a `stop` hook entry is appended) |

## How it works

Two layers, working together:

| Layer | What it does |
|-------|--------------|
| **Rule** (`glassbox.mdc`) | Always-applied instruction that tells Cursor to create / update `.vis.md` files alongside every code edit. Includes the mermaid template and section-by-section guidelines. |
| **Stop hook** (`check-vis-md.sh`) | Safety net. After the agent stops, the hook diffs git for changed code files, compares each one's MD5 against the `source-hash` stamped into the matching `.vis.md`, and sends the agent back to fix any missing or stale companions. |

The `.vis.md` files live under a `.vis/` directory that mirrors your source tree:

```
project/
  src/
    auth.py
    utils.py
  .vis/
    src/
      auth.py.vis.md
      utils.py.vis.md
```

The `.vis/` directory is designed to be committed.

## Example

See [`examples/auth.py`](examples/auth.py) and its companion [`examples/auth.py.vis.md`](examples/auth.py.vis.md).

## Requirements

- [Cursor](https://cursor.com) with hooks support
- `python3` (used by the hook for safe JSON escaping of follow-up messages)
- `git` (the hook uses git to detect changed files)
- `md5` (macOS) or `md5sum` (Linux)
