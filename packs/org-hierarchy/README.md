# org-hierarchy

**A Director / Manager / 10-SDE org chart for your Cursor agent. Activated by the phrase `use org`.**

When you start a request with `use org`, your top-level agent becomes the **Director**. It spawns a **Manager** subagent that decomposes the work and dispatches up to **10 specialist SDE subagents in parallel**, each one constrained to a single role with a strict contract:

- **1× Data Engineer** — dataset conversion, tokenization, sharding
- **3× General MLE** (interchangeable) — training code, ablations, analysis
- **1× Run Triage & Debugger** — root-cause failing or regressing runs
- **1× Environment & Packaging Steward** — Python / CUDA / image churn
- **1× Literature / Prior-art Scout** (readonly explore) — papers, blog posts, prior work
- **1× Job Monitor** (readonly explore) — observe live runs without touching them
- **1× Job Launcher** (shell) — submit cluster jobs / start runs
- **1× Sweep / Experiment Designer** — scaffold sweep configs and hypothesis specs

The Manager and SDEs **never talk to the user**. Manager-level questions return a `blocked` JSON block to the Director, who decides internally; SDE-level out-of-scope tasks return `out_of_scope` with a suggested role for the Manager to re-dispatch.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/org-hierarchy/install.sh | bash
```

Or, from a clone:

```bash
bash packs/org-hierarchy/install.sh
```

## Uninstall

```bash
bash packs/org-hierarchy/install.sh --uninstall
```

## What gets installed

| File | Destination |
|------|-------------|
| `rules/org-hierarchy.mdc` | `~/.cursor/rules/org-hierarchy.mdc` |
| `data/org/roles/*.md` (8 contracts) | `~/.cursor/org/roles/*.md` |

The rule references each role contract by **absolute path** (e.g. `~/.cursor/org/roles/data-engineer.md`). The installer **rewrites those paths to your actual `$HOME`** during install so the rule works on any machine.

## Usage

Drop the phrase `use org` anywhere in your prompt. Example:

> use org — set up a tinyllama-style 200M pretraining run on the c4 100B subset, target 4 nodes × 8 H100s, with eval on hellaswag and arc-easy. budget: 12 hours.

The Director will assemble a charter, dispatch the Manager, who will spawn the relevant SDEs (likely Data Engineer → Sweep Designer → General MLE → Job Launcher → Job Monitor) in parallel where possible, and report a consolidated result back to you.

For trivial requests, the Director will skip the hierarchy and answer directly even when the trigger phrase is present.

## Customizing roles

Each role file is a self-contained contract: mission, required inputs, operating rules, out-of-scope behavior, and the JSON return shape. Edit them in place at `~/.cursor/org/roles/` to tune what each SDE does. The Manager is forbidden from inventing new roles — if your work needs a role that doesn't exist, add a new contract file under `data/org/roles/` and reference it in the rule's roster table.

## Requirements

- [Cursor](https://cursor.com) with subagent / `Task` tool support
- `python3` (for the install-time path rewrite)
