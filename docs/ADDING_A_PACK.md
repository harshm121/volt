# Adding a new pack

A "pack" is a self-contained folder under `packs/` with everything needed to install one Cursor add-on (a rule, a hook, a skill, supporting data files, or any combination). Each pack ships its own standalone `install.sh` that works two ways:

1. From a clone of this repo: `bash packs/<name>/install.sh`
2. From a fresh machine via `curl ... | bash`

The included `_template/` pack is your starting point. You should be able to add a new pack in under five minutes.

## 1. Copy the template

```bash
cp -r packs/_template packs/your-pack
```

## 2. Drop in your assets

Pick whichever subdirectories apply — leave the others empty (or delete them, the installer skips empty arrays).

| Subdirectory | What goes here | Installs to |
|--------------|----------------|-------------|
| `rules/` | `*.mdc` Cursor rule files | `~/.cursor/rules/` |
| `hooks/` | Bash scripts (referenced from `hooks.json`) | `~/.cursor/hooks/` (chmod +x) |
| `skills/<name>/` | A skill folder containing at minimum a `SKILL.md` | `~/.cursor/skills-cursor/<name>/` |
| `data/<rest>` | Anything else that should land under `~/.cursor/<rest>` (mirrored 1:1) | `~/.cursor/<rest>` |
| `hooks.json` | Fragment to merge into the user's `~/.cursor/hooks.json` | `~/.cursor/hooks.json` (merged, deduped per event) |

## 3. Edit `install.sh`

The only thing to change is the **edit-this** block at the top:

```bash
PACK_NAME="your-pack"

RULES=("rules/your-rule.mdc")
HOOKS=("hooks/your-hook.sh")
SKILLS=("skills/your-skill")
DATA_FILES=("data/your-namespace/your-file.md")
HOOKS_JSON_FRAGMENT="hooks.json"   # or "" if no hook config
```

Everything else in the script is generic boilerplate — local-or-curl asset fetching, hooks.json merge/unmerge, install/uninstall flow.

### About `DATA_FILES`

`DATA_FILES` is for arbitrary files that have to live somewhere under `~/.cursor/` outside the standard rules / hooks / skills locations (for example `org-hierarchy` puts role contracts under `~/.cursor/org/roles/`). The destination is computed by stripping the leading `data/` from the path:

| Source path | Destination |
|-------------|-------------|
| `data/org/roles/data-engineer.md` | `~/.cursor/org/roles/data-engineer.md` |
| `data/foo/bar.txt` | `~/.cursor/foo/bar.txt` |

## 4. Edit `manifest.json`

Mirror the file lists from `install.sh` here. The manifest is what the top-level `install.sh --list` command reads to print descriptions, and it's the canonical record of what the pack contains.

```json
{
  "name": "your-pack",
  "version": "0.1.0",
  "description": "One-line description.",
  "trigger": "phrase: `use foo` (case-insensitive)",
  "components": {
    "rules": ["rules/your-rule.mdc"],
    "hooks": ["hooks/your-hook.sh"],
    "hooks_json": "hooks.json",
    "skills": ["skills/your-skill"],
    "data": ["data/your-namespace/your-file.md"]
  },
  "requires": ["python3"]
}
```

## 5. Edit `README.md`

Document what your pack does and how to use it. Replace `REPLACE_ME` with your pack name.

## 6. (Optional) Add to the top-level README

Append a row to the "What's in the box" table at the root `README.md`. The dispatcher and `--list` flag pick up new packs automatically — no other wiring needed.

## Conventions

- **Idempotent installs.** Re-running the installer should be safe and should upgrade in place.
- **Reversible installs.** Every install action must have a matching uninstall path. The template handles this automatically as long as you only declare assets via the lists at the top.
- **Touch only `~/.cursor/`.** Don't write outside the user's Cursor directory.
- **Pin nothing.** Don't hardcode the packaging machine's `$HOME`. If the rule file has to reference a file by absolute path (like role contracts), follow `org-hierarchy`'s lead and rewrite the path with `python3` at install time.
- **`bash` 3.2 minimum.** macOS still ships bash 3.2 by default — no associative arrays, no `mapfile`.
- **Standalone via curl.** Each `install.sh` must work when invoked as `curl ... | bash` with no other files present. The `fetch_or_copy` helper in the template handles this.

## Testing

```bash
# install
bash packs/your-pack/install.sh

# verify
ls -la ~/.cursor/rules/ ~/.cursor/hooks/ ~/.cursor/skills-cursor/

# uninstall
bash packs/your-pack/install.sh --uninstall
```

The top-level dispatcher should also see the new pack:

```bash
./install.sh --list
```
