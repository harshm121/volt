# llm-council

**A multi-round subagent debate before your top-level agent answers. Activated by the phrase `use council`.**

When you start a request with `use council`, your top-level agent stops being the answerer and becomes a **Moderator**. It dispatches subagents in up to four rounds of structured argument:

| Round | Subagent | What they do |
|-------|----------|--------------|
| 1 | **Proposer** | Concrete first answer with full reasoning. |
| 1 (parallel, conditional) | **Researcher** | Uses `WebSearch` / `WebFetch` to surface prior art, benchmarks, post-mortems, debates — quotes verbatim, doesn't opine. |
| 2 | **Critic** | Attacks the proposal's weakest points and provides at least one counter-proposal. |
| 2 (parallel, conditional) | **Implementer** | Mentally simulates building/running/shipping the proposal end-to-end and surfaces concrete gaps. |
| 3 | **Proposer (revising)** | Addresses each critique and gap point-by-point and produces a revised proposal. |
| 4 (optional) | **Critic (final)** | Only if the revised proposal introduces new substantive claims. |

Subagents don't talk to each other directly — the Moderator relays each round's full verbatim output into the next round's prompt. The Moderator never reveals its own opinion to a subagent and never summarizes what they said.

The Moderator may pass an explicit `model` argument per subagent to deliberately use **different models for different roles**, producing real cognitive diversity (different training data, different blind spots) on high-stakes questions.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/llm-council/install.sh | bash
```

Or, from a clone:

```bash
bash packs/llm-council/install.sh
```

## Uninstall

```bash
bash packs/llm-council/install.sh --uninstall
```

## What gets installed

| File | Destination |
|------|-------------|
| `rules/llm-council.mdc` | `~/.cursor/rules/llm-council.mdc` |

## Usage

Drop the phrase `use council` anywhere in your prompt. Example:

> use council — should I migrate this service from Postgres to DynamoDB? It's a write-heavy workload (~5k qps) with 3TB of relational data.

The Moderator will frame the question, dispatch a Proposer + Researcher in parallel, then a Critic + Implementer, then a revising round of the Proposer, and finally surface every subagent's response **in full and verbatim** alongside the Moderator's synthesized recommendation.

For trivial questions (one obvious answer), the council is skipped even when the trigger is present.

## Output shape

The user-facing reply has these moderator-authored sections — `## Question`, `## Council Debate (full transcripts)`, `## Key Disagreements`, `## Collective Answer`, `## Next Step` — with every round's complete subagent transcript embedded under the Council Debate section.

## Requirements

- [Cursor](https://cursor.com) with subagent / `Task` tool support
- `WebSearch` and `WebFetch` (only when the Researcher is spawned)
