# The frame template

For the frame's author. `template/` beside this file holds what every frame
repo starts from. Copy it in, then fill the `<...>` slots:

```bash
~/.claude/skills/frame-first/new-frame <repo dir>
```

| File | What it is | Fill in |
|---|---|---|
| `AGENTS.md` | The implementer's rules | Design-doc name, stub marker, frozen list, project rules, commands |
| `frame.toml` | Milestone order, tier, effort, test commands, status; the `[check]` table | Every milestone; the `[check]` regexes for the language |
| `scripts/check` | The finish check. Reads `frame.toml` and `docs/log.jsonl`; nothing in it is project-specific | Nothing |
| `docs/log.jsonl` | Rows implementers write: gap, dispute, subtask, deviation, friction | Nothing |
| `docs/PROJECT_LOG.md` | Decisions, TODO, done: the reviewer's and owner's prose | The design decisions, with reasons |

The repo still needs its own milestone doc (what each milestone asks for,
its files, its `Read:` line) and design doc. Those are not templated: they
are the design.

Before handoff, run `scripts/check M1` against the bare frame and confirm it
fails only on M1's stubs and its missing log row.

## The copies diverge, on purpose

A repo's copies are its own. Change them when the project needs it; nothing
syncs them back. At each checkpoint the reviewer asks of every change made to
a copied file: would another repo want this? If yes, it goes into `template/`
in the same session. That question is the whole upstream process.

Do not pull other files into `AGENTS.md` with `@` links: those load for every
model, every session. The reviewer's instructions stay in `review.md`, so an
implementer never pays for them.

## Why each part exists

| Part | What happened without it |
|---|---|
| "Normal here" list | The first report was mostly about stubs failing and the repo being a frame |
| Branch per milestone | Work was committed on the default branch; the reviewer had no `main...branch` diff |
| Reading list | The implementer read the whole architecture doc; the milestone used none of it |
| Edit tool, not shell | Files were changed with `sed` and a script, so the hook that loads the docs guidance never ran |
| Log rows, written when made | Four silent contract choices; the log said there were none |
| One check command | The stated finish command (the full test run) could not pass until the last milestone |
| Fixed report | Free-form summary, read later by the dearer model |
| `HELD` and dispute rows | A wrong frame test left M2 unable to pass; it marked itself "done; 1 test awaits a decision" |
| Subtask rows | Asked for by the user: an implementer that must wait for review to step outside its file list stalls |
| `frame.toml` and JSONL rows | The first check script hard-coded one project's milestones and grepped a markdown table |
| Tier names, not model names | Model assignments were written as "Sonnet" and "Opus" and were stale within the project's first day |

All from one project (2026-11-10, a Rust game; a small model on M1, a
mid-tier model at low effort on M2). The JSONL rows, `HELD` and subtask
rules had not been used by an implementer when this was written.
