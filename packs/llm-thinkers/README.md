# llm-thinkers

**A breadth-first ideation panel that fans out to three thinkers on different fixed models, then hands the merged option set off to the `llm-council` pack for ranking. Activated by the phrase `use thinkers`.**

When you start a request with `use thinkers`, your top-level agent stops being the answerer and becomes a **Moderator**. It elaborates the question, dispatches three thinkers **in parallel** on three fixed models so their cognitive blind spots differ, then merges and de-duplicates their options without dropping any, and finally hands the merged set to the **LLM Council** protocol for ranking.

| Stage | Subagent / Model | What they do |
|-------|------------------|--------------|
| 1 (parallel) | **Thinker A** — `gpt-5.5-medium` | Independently produces multiple framings/options/approaches for the elaborated question. |
| 1 (parallel) | **Thinker B** — `claude-opus-4-7-thinking-xhigh` | Independently produces multiple framings/options/approaches for the elaborated question. |
| 1 (parallel) | **Thinker C** — `gemini-3.1-pro` | Independently produces multiple framings/options/approaches for the elaborated question. |
| 2 | **Moderator** | Pools every option, de-duplicates substantively identical ideas, preserves every distinct option verbatim, and re-numbers — no ranking. |
| 3 | **LLM Council** | Receives the merged, source-anonymized option list and ranks it from most relevant to least relevant per its own Proposer / Critic / Revised-Proposer protocol. |

## What it does

- **Breadth-first, no debate.** Unlike the council (which debates), the thinkers do **not** talk to each other and do **not** see each other's work. The diversity comes from the model, not from the prompt — each thinker receives the same elaborated problem statement and independently generates multiple ways of looking at it.
- **Three fixed models, no substitutions.** `gpt-5.5-medium`, `claude-opus-4-7-thinking-xhigh`, and `gemini-3.1-pro`. The Moderator must pass `model` explicitly on every `Task` call — omitting it would collapse the panel into a single perspective. If any model is unavailable, the protocol halts rather than silently degrading.
- **Verbatim preservation during merge.** Thinker responses are preserved internally **in full, verbatim**. Combining two options that mean the same thing is allowed; deleting an option is not.
- **File-access allow-list defaults to none.** Subagents are forbidden from reading, searching, or globbing local files (including `llm-thinkers.mdc` and `llm-council.mdc`) unless the Moderator explicitly grants exact paths.
- **No inter-thinker communication.** Thinker prompts never mention the existence of other thinkers, parallelism, panels, or coordination — only the problem and the output expectations.
- **One round, hard stop.** One parallel ideation round + one council pass. No looping, no fourth thinker.

The final user-facing output is the council's full ranked output (verbatim, per `llm-council.mdc`'s output spec), preceded by a header that shows the elaborated question and each thinker's complete raw response so you can audit what was generated before ranking.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/llm-thinkers/install.sh | bash
```

Or, from a clone:

```bash
bash packs/llm-thinkers/install.sh
```

## Uninstall

```bash
bash packs/llm-thinkers/install.sh --uninstall
```

## Dependency on llm-council

**Step 3 of this protocol invokes the `llm-council` rule (`llm-council.mdc`) to rank the merged option set.** This pack does **not** vendor the council rule — you should install the `llm-council` pack as well so the ranking handoff resolves cleanly. The installer prints a soft warning at the end if it doesn't see `~/.cursor/rules/llm-council.mdc`.

Install `llm-council` with:

```bash
curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/llm-council/install.sh | bash
```

Or, from a clone:

```bash
bash packs/llm-council/install.sh
```

## What gets installed

| File | Destination |
|------|-------------|
| `rules/llm-thinkers.mdc` | `~/.cursor/rules/llm-thinkers.mdc` |

## Usage

Drop the phrase `use thinkers` anywhere in your prompt. Example:

> use thinkers — what are the different framings for cutting our training loss in half on a fixed compute budget? Production model is a 7B transformer on text; current loss plateau is at 2.3 nats.

The Moderator will elaborate the question, dispatch all three thinkers in a single parallel `Task` batch on their fixed models, merge their option sets without dropping any options, and then run the merged list through the `llm-council` protocol for a complete relevance-ranked output.

For trivial questions (one obvious answer, or a yes/no factual lookup), the protocol is skipped even when the trigger phrase is present.

## Output shape

The user-facing reply contains, in order: `## Question (elaborated)`, `## Thinkers Stage — Raw Options (verbatim, by source)` with one subsection per thinker, `## Merged Option Set (de-duplicated, no options dropped)`, and `## Council Ranking` (the entire output of the `llm-council` protocol, verbatim — including its `## Question`, `## Council Debate (full transcripts)`, `## Key Disagreements`, `## Collective Answer`, and `## Next Step` sections).

## Requirements

- [Cursor](https://cursor.com) with subagent / `Task` tool support
- The three model slugs available in your Cursor environment: `gpt-5.5-medium`, `claude-opus-4-7-thinking-xhigh`, `gemini-3.1-pro`
- The [`llm-council`](../llm-council/) pack installed (Step 3 hands off to its rule)
