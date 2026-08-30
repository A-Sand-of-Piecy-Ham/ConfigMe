# Self-generating skills and memory

Working notes on making an agent accumulate its own operating knowledge, and on
what that costs. Written while building the skills in `claude/skills/`; also the
starting material for the paper thread with Prof Woodley.

## The cost asymmetry that drives everything

A skill has two parts loaded at different times:

| Part | Loaded | Cost |
|---|---|---|
| `description` | Every session, always | Permanent |
| Body | Only when triggered | Occasional |

This is the whole design constraint. Descriptions are a standing tax paid on
every conversation regardless of relevance; bodies are paid only when already
relevant. So descriptions are compressed to fragments — verb first, then trigger
phrases verbatim from the user, articles dropped — while bodies stay readable
prose. Compressing the six current descriptions cut them roughly 60% with no
loss of trigger coverage.

The general form: **context cost should be proportional to the probability the
content is needed.** Anything always-loaded must justify itself against every
conversation, not against the conversation where it happens to matter.

## Two shapes of skill

**Procedure** — a workflow easy to get wrong. Value is in the body.
`dotfiles-change` is one: a running tmux server never re-reads its config, so
the file can be right while the session is wrong.

**Shim** — the capability already exists, but nothing surfaces it at the right
moment. Value is almost entirely in the trigger list; the body is short.
`todo-capture` is one: the TickTick tools were always callable, but a task
mentioned in passing produced "noted" and no task.

Shims are higher-leverage, for a reason worth stating plainly: **a missing
capability announces itself and an unused one does not.** A tool that does not
exist produces an error. A tool that exists and is never reached for produces a
plausible answer instead of an action, and nobody notices. Shims target that
silent failure class.

## When something earns a skill

Two signals, both retrospective:

- The same correction landed twice.
- A step fails silently — nothing errors, the result is quietly wrong.

Not every lesson is a skill. The split that matters:

| Content | Home |
|---|---|
| A procedure, triggered by a task | Skill |
| A fact or preference, needed regardless of task | Memory |
| A rule that must hold in every session | `CLAUDE.md` |

Procedures go in skills because they are only relevant when the task arrives.
Facts go in memory because there is no trigger phrase for "know this". Rules go
in `CLAUDE.md` because a rule that only sometimes loads is not a rule.

Misfiling is the common error, and it always costs the same way: a procedure in
`CLAUDE.md` is permanent tax on every session, and a rule in a skill is silently
absent whenever it did not trigger.

## The two memory systems

Discovered while writing this. There are two unrelated stores and only one is
read:

| Path | Read automatically |
|---|---|
| `~/.claude/projects/<slug>/memory/` | Yes — injected each session, per project |
| `~/.claude/memory/` → `claude/memory/` | **No** — nothing reads this path |

`claude/CLAUDE.md` → `~/.claude/CLAUDE.md` does load, so the instructions half of
this repo works and the memory half has been inert. The seven curated files in
`claude/memory/` have never reached a session automatically.

Resolved by splitting rather than relocating. `~/.claude/rules/` loads every
session, keeps one file per topic, supports symlinks, and supports `paths:`
frontmatter to load only alongside matching files — so the three always-on
behavioural files moved there and stayed separate rather than being merged into
`CLAUDE.md`.

`@path` imports were considered and rejected: the documentation states that
imported files still load at launch, so imports organise without reducing cost.

The rest of `claude/memory/` turned out not to need a home. `user_instructions.md`
duplicated `CLAUDE.md` line for line; `dotfiles.md` and `project_standards.md`
were already covered by the `dotfiles-change` and `git-workflow` skills, with
only their unique fragments folded in. The directory was removed.

A general lesson worth keeping: **an inert store accumulates content that looks
maintained.** Those files were edited and indexed for months while never being
read by anything. Whatever holds memory should be verifiable — the `--doctor`
check now asserts the skills and rules links actually resolve.

## Open questions

For the paper, and for experiments here:

- **Trigger precision.** Descriptions are matched semantically. What does a
  false-negative rate look like in practice, and does adding sloppy phrasings to
  the trigger list improve recall without pulling in unrelated tasks?
- **Where does compression break?** Descriptions went 60% smaller with no
  apparent loss. There is a floor. Finding it empirically — the point where
  triggers start being missed — is a measurable result.
- **Can the two signals be detected automatically?** "Corrected twice" and
  "failed silently" are both visible in a transcript. An agent that proposes its
  own skills from its own session history is the interesting version of this.
- **Aggregation.** Six skills with six descriptions cost more than three skills
  with three. When is merging two skills better than keeping their triggers
  distinct, and does a merged description lose recall?
- **Decay and tombstoning.** Nothing currently removes a skill, so one for a
  workflow that no longer exists charges its description cost forever. Deletion
  is not obviously right either: a removed entry invites the next session to
  rediscover the same dead end. `doc-lookup` marks dead entries rather than
  deleting them, on the theory that "this was tried and led nowhere" is itself
  information. Whether that generalises, and what the right staleness horizon
  is, are open.
- **Transfer.** Do skills written for one project help another, or does
  specificity make them dead weight elsewhere?

## Observations

Evidence noticed while doing other work, appended by the `research-log` skill.
Dated, one entry each; observations rather than conclusions.

**2026-08-30 — a shim existed and did not fire.** Diagnosing why a nested
`claude -p` failed took a long bisect and ended somewhere non-obvious. That is
precisely the case `doc-lookup` says to cache, and the skill was installed at
the time. It did not trigger and the answer was not cached until the user
pointed it out. Bears on trigger precision. The trigger list is phrased around
*looking things up* ("how does X work in <lib>"), and this was *debugging that
produced a reusable finding* — a shape the description does not describe. This
is a false negative from description scope rather than from matching slack.
Suggests trigger lists should cover the moment a lesson is *produced*, not only
the moment information is *sought*.

**2026-08-30 — `InstructionsLoaded` makes load questions empirical.** "Do rules
load?" had been asserted from documentation three times before being measured.
The hook answers it in one probe run, and revealed the symlink is followed
(`file_path` resolves to the repo). Bears on the automatic-detection question:
some claims about the system are cheaply testable, and the reflex to test rather
than cite is worth building into skills that make such claims.

**2026-08-30 — a null result was reported as evidence.** After deleting
`~/.claude/memory/`, its absence from the load log was offered as proof it never
loaded. The user rejected this correctly: an absent directory cannot load. The
real test needed the directory recreated with a canary. Bears on nothing in the
open list directly, but worth recording as a failure mode: **verification run
after a change cannot establish what was true before it.**

## Prior art to check

Whether this pattern is used deliberately elsewhere is genuinely unknown to me
and worth establishing before claiming novelty. Adjacent literature: retrieval-
augmented generation for the load-on-demand idea, Voyager-style skill libraries
for agents accumulating reusable procedures, and the memory/reflection loops in
generative-agent work. What looks less covered is the *cost-aware* framing —
treating an always-loaded description as a budgeted resource and optimising
trigger phrasing against it.
