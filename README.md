# Volt

**Plug-and-play hooks, rules, and skills for [Cursor](https://cursor.com).**

Volt is a small marketplace of self-contained Cursor add-ons. Each "pack" is a folder you can install on its own with one bash command, or pick a few and install them together. Adding a new pack is a copy-paste job — see [`docs/ADDING_A_PACK.md`](docs/ADDING_A_PACK.md).

## What's in the box

| Pack | Type | What it does |
|------|------|--------------|
| [`glassbox`](packs/glassbox/) | rule + stop hook | Auto-generates `.vis.md` mermaid diagrams alongside every code file your agent touches, so you can review intent visually instead of reading raw code. |
| [`org-hierarchy`](packs/org-hierarchy/) | rule + role contracts | Activated by the phrase `use org`. Spins up a Director → Manager → 10 specialist SDE hierarchy that decomposes ML/eng work and dispatches subagents in parallel. |
| [`llm-council`](packs/llm-council/) | rule | Activated by the phrase `use council`. Runs a multi-round Proposer / Critic / Implementer / Researcher debate before answering, with full verbatim transcripts. |

## Install

### Quick install (one pack)

Each pack ships its own standalone installer. From a fresh machine:

```bash
# glassbox
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/glassbox/install.sh | bash

# org-hierarchy
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/org-hierarchy/install.sh | bash

# llm-council
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/llm-council/install.sh | bash
```

Each installer is idempotent — re-running it upgrades in place.

### Clone & install

```bash
git clone https://github.com/harshm121/volt.git
cd volt

# install one pack
./install.sh glassbox

# install several
./install.sh glassbox org-hierarchy

# install everything
./install.sh all

# list available packs
./install.sh --list

# uninstall
./install.sh --uninstall glassbox
```

### What gets touched

Every pack writes only to your `~/.cursor/` directory:

- Rules → `~/.cursor/rules/<name>.mdc`
- Hook scripts → `~/.cursor/hooks/<name>.sh`
- Hook config → merged into `~/.cursor/hooks.json` (existing entries are preserved)
- Skills → `~/.cursor/skills-cursor/<name>/`
- Pack-specific data (e.g. `org/roles/`) → `~/.cursor/<dir>/`

Nothing outside `~/.cursor/` is modified.

After installing or uninstalling, **restart Cursor** (or open a new window) to pick up the changes.

## Repo layout

```
volt/
├── install.sh              # top-level dispatcher
├── lib/
│   └── common.sh           # shared install helpers (info/warn, hooks.json merge)
├── packs/
│   ├── glassbox/
│   │   ├── install.sh      # standalone (works via curl too)
│   │   ├── manifest.json
│   │   ├── README.md
│   │   ├── rules/
│   │   ├── hooks/
│   │   ├── hooks.json
│   │   └── examples/
│   ├── org-hierarchy/
│   │   ├── install.sh
│   │   ├── manifest.json
│   │   ├── README.md
│   │   ├── rules/
│   │   └── data/org/roles/
│   └── llm-council/
│       ├── install.sh
│       ├── manifest.json
│       ├── README.md
│       └── rules/
└── docs/
    └── ADDING_A_PACK.md
```

## Adding your own pack

See [`docs/ADDING_A_PACK.md`](docs/ADDING_A_PACK.md). The short version:

1. `cp -r packs/_template packs/your-pack`
2. Drop your `.mdc` rule into `rules/`, your hook script into `hooks/`, your skill into `skills/<name>/SKILL.md`, and any extra files into `data/`.
3. List those files in `manifest.json`.
4. Edit `README.md`.
5. The included `install.sh` works as-is — the manifest drives everything.

## Requirements

- [Cursor](https://cursor.com) with hooks support
- `bash` 3.2+
- `python3` (used to merge `hooks.json` safely)
- `git` and `curl` (only needed for the curl-style remote installer)

## License

MIT — see [`LICENSE`](LICENSE).
