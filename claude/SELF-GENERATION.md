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
- **Task-framed vs. action-framed triggers.** A description matches the task as
  Claude frames it ("I'm fixing the CSS"), not each action inside it ("I'm editing
  RUNBOOK.md"). Skills whose subject is an *object* (a file type, a doc) rather
  than a task may need a harness hook on the action, not a better description.
  Does an action-worded description ("ANY edit to a project doc") fire on
  side-effect edits by itself, or only with a hook?
- **Writer tier vs. reader tier.** Skills are mostly written by the strongest
  model and often loaded by a weaker one. Which features of a body survive that
  gap (explicit conditions and defaults, observable checks, ordering) and which
  do not (stated intent, "use judgment")? And in the other direction: are
  amendments made by a mid-tier session net improvements, or do they need the
  additive-only limit `skill-forge` now puts on them?
- **Pinned values that go stale.** Anything in a skill that names the current
  best of something (a model, a tool version) is correct only until it is
  superseded. What else in the setup has this shape?
- **Routing around a harness limit.** Some things an agent cannot do are gaps
  (nothing starts a compaction), and some are deliberate (permission prompts).
  A workaround for the first kind is often a general channel that also defeats
  the second: a tool that types into the session can type "yes". What makes a
  workaround safe to put in a skill: a fixed function, a precondition it
  checks, a note in the skill saying a limit is being routed around?
- **Effort against tier.** Can T2 at high effort stand in for T1 (on a
  checkpoint review, on a frame), and can T3 at high effort stand in for T2?
  Tiers and effort draw on the same usage limits, so the cheaper cell that
  gives the same findings is the one to use. The table below collects the
  cases; the tier names are defined in `rules/model-tiers.md`.
- **Do sub-files of a skill survive compaction?** A sub-file is read once on
  a "read X when Y" line. After a compaction the skill body is re-attached
  but the sub-file is not, and nothing prompts a re-read.
- **What makes the smallest tier keep the record?** Twice now T3 has
  written passing code and dropped what surrounds it (gap rows, formatting,
  the tool rule). It will be the main implementer whenever the strongest
  affordable model moves down a tier. Which of these holds it: a gate in
  the finish check, a hook, a shorter rules file, a cheap review after each
  milestone?
- **When does convention cost more than it saves?** Each rule added after a
  failure is read on every later milestone. Nothing yet measures a rule's
  cost against what it prevents.
- **How much of a session's context is spent before it starts?** And how
  much of that can a per-project or per-role setup remove?

## Effort and tier, measured

One row per milestone or review in a `frame-first` project, added by the
reviewer. "Rounds" is runs of the finish check before it passed. Models are
named here because this is a record of what ran, not an assignment.

"Cost" is model calls, output tokens, and context at the start and at its
peak (the command is in `frame-first/review.md`).

| Date | Work | Tier (model) | Effort | Rounds | Cost | Review found |
|---|---|---|---|---|---|---|
| 2026-11-10 | M1, tight oracle, ~250 lines | T3 (Sonnet 5.5) | not recorded | not recorded | not recorded | Code correct. 4 gaps filled silently, false "none" in the log, commit on the default branch |
| 2026-11-10 | Checkpoint A review of M1 | T1 (Fable 5.2) | medium | n/a | not recorded | Every finding came from the diff or a command; medium sufficed |
| 2026-11-10 | M2, judgment, movement and energy | T2 (Opus 5.5) | low | not recorded | not recorded | No code findings. 4 gaps logged before the code, 1 frame test correctly disputed |
| 2026-11-10 | Review of M2 | T1 (Fable 5.2) | medium | n/a | not recorded | As Checkpoint A. Confirmed the dispute by hand; two feel questions deferred to the user |
| 2026-11-10 | M3, lock-on, weapons, damage, heat; ~640 lines | T2 (Opus 5.5) | medium | 2 reported, 3 in the transcript | 36 calls, 38k out | Pass. 7 gaps logged before the code; one row disagrees with its code (target cycling); formatted |
| 2026-11-10 | M3 again, sealed copy | T3 (Sonnet 5.5) | medium | 1 reported, 2 in the transcript | 23 calls, 26k out | Pass. 5+ gaps unlogged, one a missed event the contract asks for; rows by heredoc after the code; unformatted |
| 2026-11-11 | Findings-only review of both M3 builds | T1 (Fable 5.2) | low | n/a | 17 calls, 23k out, 65k to 167k, compacted once after committing | Ran a throwaway test on both branches: the only reviewer to find the row that disagrees with its code. One weak finding |
| 2026-11-11 | The same review, sealed copy | T2 (Opus 5.5) | medium | n/a | 27 calls, 20k out, 63k to 148k | Same verdict. Found one duplicated rule the other missed; two statements the code contradicts; no test run, no list of missing tests |
| 2026-11-11 | The real M3 review, from the checked list: merge, settle 8 rows, 14 tests, send-back, format gate | T1 (Fable 5.2) | high, some medium | n/a | 35 calls (110 tool calls), 56k out, 48k to 164k, compacted once mid-fix | T2 build merged and sent back with 5 failing tests and 4 clean-ups. The fixes, tried in a scratch clone, came to 25 changed lines and passed first time |

The two M3 reviews differ in tier and in effort, so the pair does not
separate them either.

M1 and M2 ran under different rules files (M2's required log rows and gave
a reading list), so the pair does not separate tier from rules.

## Observations

Evidence noticed while doing other work, appended by the `research-log` skill.
Dated, one entry each; observations rather than conclusions.

**2026-11-10 — compaction instructions shape the summary, not what survives.**
A manual `/compact keep the last 3 turns in detail; reduce the game design to
"frame is built, see AGENTS.md"` took a session from 366k to 26k tokens. The
content half was followed. The turn-count half was not: one message survived
word for word, and the harness re-attached five recently modified files, one
of which the instruction meant to drop. Suggests instructions have to name
content. Led to the `smart-compact` skill and a PreCompact hook
(`bin/compact-notes-hook`) that feeds agent-written notes into any compaction.
Neither has been through a real compaction yet. To check: does the summary
honour the notes, and does the standing "do not quote user messages in full"
line survive the built-in summary template?

**2026-11-10 — option not built: a tmux tool that types `/compact`.** Nothing
documented lets a hook, the agent or another session start a compaction. The
user found a tool that does it from outside: it watches a Claude Code session
in tmux and sends `/compact` with preservation notes and a continuation
message before the session grows too large. Analysis at the time:

- Only the trigger needs tmux. The notes can go through a PreCompact hook and
  the continuation through a SessionStart hook matching `compact`, and those
  also work in the desktop app, which has no pane to type into.
- What the trigger buys is timing: compacting at about 50 minutes idle, while
  the one-hour prompt cache is warm, saves one full uncached read per long
  break (up to roughly 230k input-equivalents at a 200k window).
- The risk is that `send-keys` types with the user's authority into whatever
  the pane shows: Enter on a permission prompt approves it, text at a shell
  runs, text into a half-typed message corrupts it. A safe version is
  fixed-function (sends only `/compact`) and fires only after a hook reports
  the session idle with no prompt pending. It should not be a general channel
  the agent can call.
- It cannot fire when the machine is asleep or off. A server does not fix
  that, since nothing remote can type into a local session. Cheaper: trigger
  on suspend, or after 10 to 15 idle minutes above the threshold, or accept a
  cold resume, which the 200k window now caps.
- Built-in idle compaction exists (`idleCompaction`,
  `CLAUDE_CODE_IDLE_COMPACT_MIN_TOKENS`) but the setting's own description
  says true "does not turn idle compaction on", so it looks gated. If it
  starts firing, most of the case for the tmux tool goes.

Revisit if long CLI sessions keep resuming cold. Bears on the new question
about routing around a harness limit: the user's point was that persistence
gets past limits on what an agent can do, which is useful and dangerous for
the same reason.

**2026-11-10 — a model pin downgraded the session it was meant to upgrade.**
`skill-forge`, `introspection`, `memory-write` and `research-log` carried
`model: opus` so meta-work would run on the strongest model. In a session
running a newer, stronger model, invoking `skill-forge` switched it down to
Opus for that turn. Nothing errored; it was noticed only because the commit
attribution trailer changed. The skill written in that turn was therefore
authored a tier below what the pin intended. Pins removed. Bears on the new
pinned-values question, and on writer tier: the mechanism meant to control who
writes skills was the thing that got it wrong.

**2026-11-10 — writing a skill changed the skill-writing skill.** `frame-first`
was drafted under `skill-forge`'s rules and departed from them in two places
(an intent section, a status note for unrun parts). Both went back into
`skill-forge` the same session, at the user's prompting for the general case.
First instance of a skill being revised by its own use. Suggests amendment
needs an always-loaded prompt, since the session using a skill has not loaded
`skill-forge`; a line was added to `rules/engineering-practice.md` for that.

**2026-09-09 — the harness cannot test what it was built to test.** `claude-probe`
was built to answer questions about what a session loads. It turns out headless
`-p` sessions load `CLAUDE.md`, `~/.claude/rules/` and skills, but not
auto-memory. So the harness validates two of the three mechanisms and silently
cannot speak to the third. Bears on the automatic-detection question: a
verification tool needs to declare what it cannot observe, or its silence reads
as a pass. The `InstructionsLoaded` hook has the same shape of limit -- it
observes instruction files only, never memory injection.

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

**2026-10-08 — docs-audience never fired on side-effect doc edits.** In one
session AGENTS.md, RUNBOOK.md and PROJECT_LOG.md were edited about six times as
"keep docs in sync" steps of code changes; the skill loaded zero times. Its
description named doc-writing as the task ("update the README", "write docs"),
and the task was always framed as code. The lesson it encodes had been recorded
twice (in interaction-style, and in the skill itself) and still didn't apply,
since neither location triggers on the action. Moving the always-loaded copy out
of interaction-style made it worse: the lesson then lived only in the skill that
wasn't firing. Bears on trigger precision (a false negative with a clear cause)
and on where lessons go. Changes made together, so their effects can't be
separated yet: description reworded to "ANY edit to a project doc, including
side-effect updates", and a PreToolUse hook (`bin/docs-audience-hook`, Edit|Write
on README/EDITING/AGENTS/CONTRIBUTING/docs/*.md) that injects a reminder. The
hook was verified firing on a test write. Suggests the new open question above.
To check later: in sessions with side-effect doc edits, does the skill load
before the hook's reminder appears?

**2026-11-10 — first frame-first handoff and checkpoint.** One tight-oracle
milestone (Rust, about 250 lines against 13 tests) went to the small model
with only the repo's AGENTS.md; the strongest model reviewed. The code was
correct and idiomatic on the first pass, with only small repetition. What
failed was everything the rules did not make a numbered step: four contract
gaps were filled sensibly and the log then said "no contract or test needed
guessing"; the commit went to the default branch; the whole architecture doc
was read though the milestone used none of it; and the report dwelt on later
milestones' stubs failing, because the stated finish command (`cargo test`)
could not pass until the final milestone. Bears on writer tier vs. reader
tier: explicit steps survived the gap completely, and implied duties ("keep
the log true") did not survive at all. Suggests the unit of instruction for a
small model is step + format + check, and that a false "nothing to report"
is the likely failure where a report is free-form. Changes made: a per-milestone
check script that gates on a log row, fixed report fields, a reading list per
milestone. Their effect is unmeasured until the next milestone runs.

**2026-11-10 — shell edits walked around the Edit|Write hook.** In the same
handoff the small model changed code and docs with `sed -i` and python
heredocs through Bash. The docs-audience hook matches Edit|Write only, so it
never ran, and `docs-audience` and `git-workflow` both loaded zero times in
a session that edited three project docs and committed. Answers part of
"task-framed vs. action-framed triggers": a hook on the action works only if
it covers every tool that can perform the action, and the action-worded
description ("ANY edit to a project doc") did not fire by itself here, in a
mid-tier session framed as "implement M1". Changes: a second PreToolUse hook
on Bash (`bin/bash-skill-hook`) for commits, pushes and doc writes, and a
rules-file line asking for the Edit tool. The Bash doc match is a regex over
command text and will miss paths held in variables. To check: how often it
fires falsely, and whether weaker models reach for shell edits generally or
this was one session's habit.

**2026-11-10 — the reviewing skill took the trigger; the recording skills
did not fire.** The user asked the strongest model to review the handoff
"against the skill's untested hypotheses" and assess the other model's
process. `frame-first` loaded on "review what the other model built".
`research-log` and `introspection` did not, though the turn was a skill's
first run being evaluated, which is exactly their material; the user noticed
and asked why. Their descriptions were worded around user-Claude friction and
surprise ("fired unexpectedly", "user expresses satisfaction"), not around
reviewing an agent or a skill. Bears on trigger precision and on aggregation:
when one skill matches strongly, adjacent skills that should co-load seem to
be suppressed rather than added. Changes: review phrasings added to both
descriptions, and an explicit "load these two" step in `frame-first`'s review
file. Two changes at once again, so which one works will not be separable;
the explicit chain is the one to trust.

**2026-11-10 — first three-file skill.** `frame-first` was split along a
phase seam, not a trigger seam: `SKILL.md` (design and build), `review.md`
(read at a checkpoint) and `agents-template.md` (read when writing a rules
file), all under one description. `skill-forge` describes splitting only
into separate skills. Bears on aggregation: sub-files cost no description
tokens and no trigger competition, but depend on the reader following a
"read X when Y" line in the body. To check at the next checkpoint: was
`review.md` actually opened, and by which tier.

**2026-11-10 — second milestone: explicit rules held at T2-low, and the
frame was the thing that was wrong.** A judgment milestone (movement and
energy, 21 tests) went to T2 at low effort under the rules file rewritten
after the first checkpoint. Every numbered step was followed: branch, fixed
report, four gap rows written before the code they concern. One frame test
contradicted its own contract (a sight line passing under a wall's top); the
implementer worked the geometry, logged it, left the frozen test alone and
did not special-case it. The review confirmed it by hand. Bears on writer
tier vs. reader tier: step + format + check worked again, at a different
tier and effort. What the rules lacked was a state for "finished except for
a test I dispute": the milestone marked itself done with a caveat in prose
and the commit message grew a paragraph. Changes: a `HELD` result in the
check, keyed on a `test` field in the dispute row. Not separable: tier,
effort and rules all changed between the first and second milestone. Still
bypassed: it read files with `cat` through Bash, and made no `Skill` call.

**2026-11-10 — a sub-file was not re-read after compaction, and the
reviewer broke the rule it was reviewing.** The M2 review opened `review.md`
at the start (first check of the entry above: yes, by T1, its author). The
session then compacted. The summary carried the task list but not the
file's steps, and the last third of the review ran without it. In that
stretch the reviewer edited two project docs with `sed -i` and a python
heredoc, the exact behaviour the first checkpoint had written a rule and a
hook against; the Bash hook flagged it both times, which is its first
recorded true positive. Suggests the new open question on sub-files, and
that a rule aimed at "the implementer" is not read by a reviewer as applying
to itself. Changes: a "re-read after a compaction" line and a reviewer tool
rule in `review.md`.

**2026-11-10 — model names in a skill went stale within the day.** The
frame's milestone table said "Sonnet" and "Opus", and `frame-first` said
"small", "mid" and "strongest". By the second milestone the user had moved
the models between roles. Same shape as the model-pin entry above; bears on
pinned values. Change: tiers T1 to T3 everywhere, with the mapping in one
always-loaded rules file. To check: does a session reliably know its own
tier from that file, and does it speak up when a milestone names another.

**2026-11-10 — first process files generated from a template.** The frame's
rules file, milestone file and check script were generalised into
`frame-first/template/` with a copy script, on the user's decision that
copies may diverge and the checkpoint review upstreams what recurs. Bears
on transfer. Nothing measured: the template has been copied into no second
repo, and its non-Rust check examples have never run.

**2026-11-10 — option deferred: a routine that works T2 and T3 milestones
while the user is busy.** The user's aim is to spend usage allowance that
would otherwise go unused, on implementation tiers only; reviews stay
attended. Open at the time: whether cloud routines can reach a private
GitHub repo (the project then had no remote), that a cloud Linux session
cannot build the Windows-only shell crate, and that the frame rules had not
yet been through an implementer. A local trigger was the fallback idea. The
user will research it. The frame already gives such a routine its stopping
rule: `scripts/check` names the next milestone and tier, and an implementer
stops at `HELD` or a checkpoint. Revisit after two more attended milestones.

**2026-11-10 — an optional log row fired unprompted on T2.** The third
milestone (T2, medium effort, not yet reviewed) wrote a `friction` row with
two real findings (a README line its rules forbade it to correct, no format
gate in the check) although nothing requires one. The required `gap` kind
produced seven rows in the same run. One instance; suggests an optional row
with a clear "add one when" clause is used by a mid-tier model, and that
requiring it would add filler. Not yet seen on T3. Same day, a sealed clone
was cut to rerun that milestone on a cheaper tier (`frame-first/ab.md`);
the comparison has not run.

**2026-11-11 — the same milestone on T2 and T3, mechanical comparison
only.** Both at medium effort, same commit, same one-line request. Both
passed the finish check with 84 tests. T2: 36 model calls, 38k output
tokens, 3 check runs, 7 gap rows, 1 friction row, rows written before the
code, formatted. T3: 23 calls, 26k output tokens, 2 check runs, 5 gap rows,
no friction row although a push failed for want of a remote (it said so in
its report only), rows appended through a shell heredoc after the code,
unformatted. At least one gap T2 logged, T3 met and filled without a row.
Bears on tiering and on whether optional rows work on T3: one instance
says the tests held T3 to a passing body, and that what T3 drops is the
record around it, the same pattern as the first milestone. No T1 read of
either diff yet, so nothing here says the T3 code is as good.

**2026-11-11 — the T1 read of that pair: T3 fails on discipline, not on
code.** Two reviewers and a check of their findings against the code. T3's
bodies were equal or better in the single-module, formula-led files and
worse where two modules meet (lock state between `fcs` and `weapons`): one
event the contract asks for is never sent, and four more choices went
unlogged. Every rule T3 dropped had no gate (rows before the code, Edit
only, formatting); every gate it met, it passed. The user's reading: T3
needs a stronger harness, not retirement, because it becomes the
implementer tier when Opus is T1 again. Suggests moving each dropped rule
into the check or a hook and testing that with a third run of the same
milestone. Bears on the new "smallest tier" question.

**2026-11-11 — two reviewers on that pair; the comparison was confounded.**
T1 at low effort against T2 at medium, so tier and effort moved together.
Same verdict. T1-low ran a throwaway test on both branches and found a log
row that contradicts its code; T2-medium read only, trusted the row, and
wrote two statements the code contradicts. One instance says running code
beat reading it, and that low effort did not stop the stronger model from
choosing to. The skill's own status note had named three findings to both
reviewers. Neither set the compaction hold, because the request said to
change nothing outside one file; T1-low was compacted at 167k, after its
commit. Neither loaded `introspection`; the user reports it was offered
to them at the end, which the transcripts' text and tool calls do not
show, so where that offer comes from is not yet known.

**2026-11-11 — a session holds about 63k tokens before its first tool
call.** Measured in both review sessions (desktop app). Roughly: 37k tool
definitions, of which one built-in page-publishing tool is about 15k;
about 8k names of deferred connector tools (mail, tasks, calendar, drive,
browser); 6k skill descriptions for 31 skills; 6k rules and the repo's
agent file; 4k system prompt; 3k connector instructions. Every call
re-reads it, and a two-branch review then reached the compaction threshold
with only 85k to 95k of its own reading. Under a third of it is this
repo's doing. Not yet measured: the same session started from the terminal
CLI, or with connectors off. Bears on "descriptions are permanent cost":
tool definitions are the larger permanent cost and no skill controls them.

**2026-11-11 — the user asked whether the method's conventions now slow
the work.** Each rule so far was added after a failure and none has been
removed. `review.md` gained reviewer friction rows, a cost measurement and
a duty to cut one thing per review. Untested; the first real use is the M3
review.

**2026-11-11 — first use of "What the method itself costs": one cut, one
rule moved into a gate.** The M3 review cut the run count from the
implementer's report (both builds misreported it, so it was read at T1
price and carried nothing) and moved formatting from a rule into
`scripts/check` (the T3 build broke the rule; it broke no gate). One
reviewer friction row was written. So the section paid for itself once.
One instance.

**2026-11-11 — `scripts/check` does not show a review that is owed.** M3
was merged-pending with its branch present, so the list said `busy` and
named a T3 milestone as next. The T1 step the user asked for was found
only through an untracked brief file in `docs/`. Suggests a state for
"built, waiting on review" in the listing, so "run the next T1 step" can
be answered from the repo. Not built.

**2026-11-11 — proving a send-back satisfiable means writing the fix.**
`review.md` forbids hand-fixing in the review tier, and a send-back test
that was never run against fixed code is a guess, so the reviewer applied
the five fixes in a scratch clone: 25 changed lines, about ten calls,
`PASS` first time. The implementer's tier now spends a session
rediscovering a patch that exists. Question raised: below some size, is
applying the proven patch cheaper than the send-back, and what does the
implementer's tier learn from a send-back that a patch would lose? Decided
by the user the same day: a proven patch under about 50 lines is applied.

**2026-11-11 — the desktop app's auto mode refused a deletion the skill
asks for.** `rm` of the untracked review brief was denied as irreversible.
`ab.md` step 5 and `review.md` both end in deletions (brief, losing
branch, sealed copies), so in that mode a review cannot finish its own
clean-up; the reviewer listed the commands for the user instead.

**2026-11-10 — starting context measured from the terminal CLI, and what
removes it.** `claude -p` on the small model, no repo agent file: 47.6k
with everything, 43.9k without MCP servers (so all connectors together are
3.7k), 42.6k without skills as well (1.3k), 31.6k with the page-publishing
tool denied (12.2k for one tool), 23.8k with eighteen unused built-in tools
denied. A deny rule, by flag or by `permissions.deny`, removes the
definition, not only the permission. Not yet tested in the desktop app.

**2026-11-10 — five of fourteen skills have never been invoked in 33 saved
sessions, and the two most used are the two with a hook.** Counts:
docs-audience 9 and git-workflow 6 (both hooked); frame-first 6,
dotfiles-change 6, skill-forge 4, research-log 3, web-browsing 2,
introspection 2, memory-write 1; calendar-check, doc-lookup, todo-capture,
project-setup and smart-compact 0. The work of three of the unused ones
did happen without them: context7 was called 10 times (doc-lookup),
TickTick 5 times (todo-capture), and this session compacted twice
(smart-compact). Bears on whether a description alone triggers reliably:
here a hook on the tool call looks like what makes a skill fire.

**2026-11-11 — a skill's `effort:` header overrode the session's effort
for a whole turn.** `introspection` (`effort: high`) was loaded in the
first seconds of a review set to medium. The request log shows medium for
4 calls, high for the next 41, and medium again from the user's next
message. Inferred from timing, not from documentation. Three other skills
carried `effort:` lines; all four are removed and `skill-forge` forbids
them. Bears on the cost of loading a skill: the body is not the only
thing a load brings.

**2026-11-11 — where one review turn's cost went, at price weights.** 46
model calls, 110 tool calls, context 48k at start and 164k at peak. Cache
writes 295k, all one-hour (weight 2): about 590k. Cache reads 5.07M
(weight 0.1): about 507k. Output 67k (weight 5): about 335k. Eighteen
calls were one Bash command each; about fifteen were upkeep done one item
at a time. The largest tool results were oversized Bash output spilled to
a file and read back. Suggests calls times context is the thing to cut,
ahead of output; `rules/call-economy.md` is the attempt. Unmeasured:
whether an always-loaded rule changes the call count.

**2026-11-11 — the user reports turns "much faster" after
`call-economy.md` was written.** Same session, the turns after the rule:
four turns of 3 to 5 model calls each, with a dozen edits in one message.
Confounded three ways: the session had just compacted (smaller context),
the effort setting had been lowered, and the rule was in context because
the session wrote it, not because it loaded as a rule. The first clean
test is a new session where it loads by itself.

**2026-11-11 — for cost, the transcript outranks the user's meter, and the
user may name the wrong cause.** The user first called their usage meter
the ground truth, then withdrew it: the meter gives one percentage per
window and no breakdown by turn, call or tool, while the transcript has
every call's usage. A user may also say "tokens" when the cost was calls,
not knowing that cached reads, cache writes and output are priced far
apart. One of the few cases where the user's assessment can be wrong and
the session should say so from numbers. `bin/session-cost` prints the
per-turn breakdown; a turn over 15% of a five-hour window counts as large
(the user's threshold, Pro plan). The numbers first written here used a
wrong weight; the next entry has the corrected ones.

**2026-11-11 — the first cost measurement was itself wrong, by one
weight.** The script weighted cache reads at 0.1 of an input token for
every model. The price table says 0.025 on the strongest model and 0.05
on the next two; only older models have 0.1. Found when the user said
costs on different models should compare, which sent the session to the
table: input, output and cache writes do scale by one factor per model,
cache reads do not. Corrected, the same session reads differently: the
review was 1.0M over 45 calls at 55% cache write, 33% output, 12%
re-reading, where the first count had re-reading largest and blamed the
number of calls. Four calls made half of all cache writes: the session
start (48k tokens) and three compactions (51k to 99k), together 22% of
the session. So a compaction costs about what 40 calls of re-reading the
dropped context would, and the advice to compact at 150k may cost more
than it saves on the strongest model. `call-economy.md` and the
introspection skill were built on the wrong weight and are corrected. The
unit is now called a claw (the user's name): the price of one uncached
input token on the reference model. The window is taken as about 2.5M
claws, between two readings: 1.0M moved the meter by "30%+" (at most
3.4M), and the meter read 85% with 1.5M spent in this session (at least
1.8M, if nothing else ran). Untested throughout: that the usage limit
counts by API price weights at all.

**2026-11-11 — the correction hook fired for real on its first chance.**
The user's message withdrawing "usage is ground truth" matched the phrase
list on "hour limit" alone, and the note arrived. A true positive by
luck: "I was wrong about", the part that made it a correction, is not in
the list (now added). The lesson was the skill edit itself, so the skill
was not loaded.

**2026-11-11 — advice to compact early was costing, not saving.** With the
corrected read weight, the per-call overhead of a session that compacts at
size W back to K is about r(K+W)/2 + C·g/(W−K): r the read weight, C one
compaction (150k to 250k claws, estimated from three), g growth per call
(about 3k tokens). The minimum is flat and sits near W = 230k to 285k on
the strongest model and near 195k on the next two; this session's automatic
point was 163k to 168k under a 200k window. Compacting at 150k as
`smart-compact` and the size hook advised is worse on every model. Both now
prepare for the automatic compaction instead of asking for an earlier one.
Bears on the cost asymmetry: a threshold reasoned from a wrong price
survived a day in two files. Untested: a window above 200k, and whether the
automatic point is a fraction of the window or a fixed margin under it.

## Prior art to check

Whether this pattern is used deliberately elsewhere is genuinely unknown to me
and worth establishing before claiming novelty. Adjacent literature: retrieval-
augmented generation for the load-on-demand idea, Voyager-style skill libraries
for agents accumulating reusable procedures, and the memory/reflection loops in
generative-agent work. What looks less covered is the *cost-aware* framing —
treating an always-loaded description as a budgeted resource and optimising
trigger phrasing against it.
