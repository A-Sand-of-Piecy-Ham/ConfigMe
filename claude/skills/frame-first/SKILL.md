---
name: frame-first
description: Plan a build as a strong-model frame that weaker models fill in. Triggers - "one shot this", "agentic code", "design the structure, not the implementation", "frame for a weaker model", "stub it out", "leave out implementation", "hand off to sonnet/opus/haiku", "which model for which part", "when do I swap models", "checkpoint review", "review what the other model built", "could a cheaper model do this", "run it on both and compare", "A/B the milestone", "which milestones can run in parallel".
---

## What this is for

Spend expensive tokens only where a mistake is expensive, and shape the work so
cheap tokens cannot make expensive mistakes. The strong model decides what is
hard to change later: boundaries, data shapes, contracts, the order of work.
Weaker models write bodies against checks that tell them when they are done.

Everything below is the current way of getting that, not the point of it. When
a step is not serving the goal on the task at hand, drop or change it and say
so. When a session shows a better step, add it here.

Scale to the task. If one model would finish the job in one session, a frame
costs more than it saves; do the work directly.

## Tiers

Work is assigned to a tier, never to a model name. Names went stale within
the first project's first day; a tier does not.

| Tier | Is | Does |
|---|---|---|
| T1 | The strongest model in regular use | Design, the frame, checkpoint review, anything frozen |
| T2 | The main implementation model | Milestones where the contract leaves choices or modules meet |
| T3 | The weakest model in use | Tight-oracle milestones, data entry, copying from examples |
| T0 | A model billed outside the normal allowance | Nothing, unless the user says so |

Which model each tier is today is in `~/.claude/rules/model-tiers.md`, and
nowhere else: not in this skill, not in a repo. "The strong model" below
means T1. Effort is a second axis, written `T2-high`.

Check the session's tier before designing. If it is not T1, stop and tell
the user; design only if they say to go on. A frame's mistakes are inherited
by every milestone built on it.

When T1 is weaker than the model this was written with, keep the method and
shrink the steps: smaller milestones, a checkpoint after each of the first
three, and one end-to-end path implemented before any handoff.

At a checkpoint, or when reviewing what another model built, read
`review.md` in this directory and work from it. When setting up a frame
repo, read `agents-template.md` and copy `template/` in with `new-frame`.
Neither is needed otherwise.

## Sequence

1. **Probe, then drill.** Read the environment first (toolchains, versions,
   hardware, existing code) so the questions are about real constraints. Ask
   only what changes the structure; give each option its consequence and mark a
   recommendation. Decide everything else and state each decision in one line
   so it can be overruled. Ungrounded questions get answers the machine later
   contradicts, and unstated defaults turn into surprises at review.
2. **Design for the implementer's errors, not only for the software.** At each
   boundary ask where a weaker model would go wrong and remove the opportunity
   (see below).
3. **Plan review.** Present the modules, each decision with its reason, the
   milestones, the tier and starting effort for each, and the checkpoints.
   Nothing goes on disk before a yes.
4. **Build the frame**, then tell the user plainly: swap to this tier now,
   and come back at these named points.
5. **Checkpoint reviews** as the milestones land, from `review.md`.

Repo layout and commits follow `project-setup` and `git-workflow`.

## Shed context at phase boundaries

Every tool call re-reads the whole conversation, so a long session makes each
later call expensive however small it is. In the first run, the drilling and
design discussion stayed in context through the entire frame build; by the
end each call was reading several hundred thousand tokens, and usage went
mostly to that, not to output.

Boundaries where the conversation so far can be dropped:

1. **After plan approval.** Before building, write the approved plan to a
   file in the repo (decisions with reasons, module list, milestones, tier
   and checkpoint assignments). Then tell the user to start a fresh session
   pointed at that file, or to compact. Build the frame from the file.
2. **After the frame is committed.** The repo is now the whole state. This is
   the model swap anyway.
3. **After each milestone**, which the one-milestone-per-session rule covers.

Skip a boundary only when the user says the live context is worth its cost.

Weigh a boundary by price, not by token count: uncached input costs about
a fifth of output per token, and cached input far less again. A fresh
session that re-reads 30k of repo is cheap; a compaction pays for a summary
as output. So re-reading files beats summarising them, and neither is a
reason to keep a 300k conversation alive.

Before any clear, check that nothing needed exists only in chat: a decision,
a caveat, a half-finished thought. If it does, it goes in the file first. The
test is the cold-start check: could a session with only the repo continue?

Side tasks cost at the session's current size. A skill edit or an unrelated
question asked at 300k context pays for 300k on every call it makes. Suggest
a new session for them once the context is large.

**One model per session.** The prompt cache is kept per model, so changing
model mid-session re-reads the whole conversation at full price, and the new
model inherits context written for another tier. The first handoff and its
review shared one session across two models (2026-11-10); the review paid
for the implementer's context. At a model change, start a new session, or
clear and continue from the repo. Prefer a clear to a compaction: compacting
costs a summarising call, and after a milestone the repo already holds the
state.

## Designing for a weaker implementer

- Logic lives in plain functions over plain data. Frameworks stay in a thin
  shell, because their wiring rules are where weaker models stall, and their
  API churn then cannot reach the logic.
- Each body can be written with only its own file and its contract open.
- One way to do each thing, and one place for tuning values.
- Content is data files behind schema types the compiler checks.
- Anything normally judged by eye or hand gets a headless path (a harness, a
  CLI, a snapshot). The implementer cannot see a window.

## The frame

- Every public type and signature, with a doc contract carrying units,
  formulas, invariants and error cases. Bodies fail loudly (`todo!()`,
  `raise NotImplementedError`). A stub that returns a default passes for
  implemented.
- It compiles or type-checks at handoff. Framework-facing code is compiled
  against the pinned version, never written from memory.
- One thin path is implemented end to end across the riskiest seam. Signatures
  nobody has called can be unimplementable (data out of reach, ownership that
  cannot work), and the implementer will find out mid-milestone and redesign on
  its own.
- Tests are written with the frame and grouped by milestone, so one command
  shows one milestone's state. Prefer invariants and several cases to a single
  golden number: one expected value invites hard-coding and enshrines the
  designer's arithmetic slip.
- The files in `template/`, copied in and filled: `AGENTS.md` (the
  implementer's loop, what is frozen, the log rows, the fixed report),
  `frame.toml` (milestone order, tier, effort, test commands, status) and
  `docs/log.jsonl` (what implementers record, one JSON row each). The build
  order lives in `frame.toml` only, so the check script and the docs cannot
  disagree about it.
- **One finish command that can pass at every milestone**: `scripts/check Mx`
  from the template. It runs that milestone's tests and every earlier one,
  nothing later, checks stubs, lint and the log, and ends in `PASS`, `FAIL`,
  or `HELD` (the only failing test is one the implementer disputed in the
  log). Run it against the bare frame before handoff. The first frame said
  "all tests pass", which could not be true until the last milestone; the
  implementer worked around it and reported the expected failures at length.
- **The implementer may step outside its file list.** When a milestone
  cannot be finished otherwise, it does the smallest thing that lets it
  continue and logs a `subtask` row; T1 may undo it at the checkpoint. A
  frozen item in the way is a `dispute`, never a subtask. The user's rule
  (2026-11-10): waiting for a review to ask permission is "review hell".
- Cold-start check: could a fresh session start milestone N from the repo
  alone? The implementer never sees the planning chat, so the reasons have to
  be in the repo.

## Budget the frame itself

The strong model's tokens go to decisions, not volume. Building the frame is
the most expensive stretch of the whole method, and it is easy to spend it on
typing. In the first run the strong model wrote all 43 catalog parts, every
enemy, the level, and about a hundred tests by hand, and hit the usage limit
before the handoff was finished.

- **Two examples, then delegate.** For anything repeated (catalog entries,
  level geometry, test cases of one shape, per-item visuals), the strong model
  writes the schema, two instances that differ, and a check that validates the
  rest (parses, cross-references, stays in range). The remaining instances
  become a sub-milestone for T3.
- **Watch for it while writing.** About to write a third instance of the same
  shape: stop, add the sub-milestone, move on. This has to be caught live; the
  plan will not have foreseen every repetition.
- **Estimate output at plan review.** List what the frame will contain and
  roughly how long each piece is. Anything long and repetitive is assigned to
  a lower tier before writing starts, and the plan shown to the user says so.
- **Tests split the same way, with more care.** They are the oracle, so a
  weaker model writing all of them weakens everything downstream. The strong
  model writes the list of cases for each suite (name plus the one thing it
  asserts) and the cases that encode a design decision. T2 writes out the
  rest; the strong model reads them at the first checkpoint. Untested as of
  this writing.
- **Where a lower tier's mistake is acceptable.** Reading costs less than
  writing, so it is cheaper for T1 to find a mistake in T2's work than to
  write the work itself, provided the mistake stays where it was made. One
  test body is like that: a wrong one fails or is disputed, and the fix is
  local. Give those to T2, or to T3 when the expected value is copied from
  the contract and needs no arithmetic. Keep with T1 what compounds: public
  signatures, formulas, shared fixtures and acceptance bands, and any test
  whose expected value takes real maths to derive. One data point: the
  first frame's only wrong test so far was a T1-written geometry case.
- **Stubs split the same way.** The strong model keeps what cannot be
  recovered from a wrong guess: signatures, formulas, the order of
  operations, invariants, and the list of test cases. A T2 session
  expands that into compiling files: field docs, stub bodies, test bodies,
  the rules file. The first frame's strong model typed about seventy stubs
  with their comments itself. Untested.
- **A number to notice overspend by.** The plan's estimate gives each piece a
  length. While writing, at twice the estimate for a piece, stop, hand the
  remainder to a lower tier as a sub-milestone, and tell the user. Without
  a number there is nothing to notice against.
- **Checking is not the strong model's work either.** Pipe test, lint and
  build output through a filter so only failures reach the context (`-q`,
  `tail`, a grep for errors); unfiltered runs were a large share of the
  first frame's input. A compile-and-fix loop expected to take more than
  two rounds goes to a lower-tier subagent or session, with the error list
  as its brief.

## What a weak model writes, a strong model reads

Every line an implementer writes into a log, a commit or a report is later
input for the review tier, at the review tier's price and trust. So choose
what it writes:

- Fixed-format rows with a length cap: the JSONL log rows and the report
  fields. The template has them, and `scripts/check` refuses a milestone
  whose rows do not parse or are missing.
- No free prose in docs. Design docs, contracts and READMEs beyond a status
  cell are written or approved by the tier that owns them.
- Unstated duties are not done. The first T3 implementer followed
  every numbered step and none of the implied ones ("keep the log true"
  produced a false line). If the reviewer needs something recorded, the rules
  need a step, a format and a check for it.

Each tier costs a multiple of the one below it per token, and all of it
counts against the short and weekly usage limits. The user's concern
(2026-11-10) is those limits, not money.

## Reasoning effort

Effort buys the most where the output is short and a mistake is expensive, and
the least where a test will catch the mistake anyway. These are starting
points; the measured rows are in the table under "Effort and tier, measured"
in `claude/SELF-GENERATION.md`. Each milestone's starting effort goes in
`frame.toml`, and the implementer's report says what was actually used.

| Step | Tier | Effort |
|---|---|---|
| Probe and drill | T1 | medium |
| Architecture and plan review | T1 | high |
| Writing the frame (the design is already decided) | T1 | medium |
| Bulk fill from examples | T3 | low |
| Tight-oracle milestones | T3 | medium |
| Milestones with judgment, or where modules first meet | T2 | medium to high (one run at low was clean: a movement milestone with 4 contract gaps and a wrong frame test) |
| UI and framework wiring | T3 or T2 | medium; look up the API instead of thinking harder |
| Checkpoint review | T1 | medium (two runs: findings came from reading and running, not from thinking longer) |
| Tuning with the user | T1 | medium |

Whether T2 at high effort can stand in for T1 on a review is an open
question in the research log. Do not assume it either way.

## Splitting work across tiers

Assign by how much judgment the oracle leaves open, not by size. Be generous
to T3 (the user's instruction, 2026-11-10): give it the milestone when
unsure, and let the checkpoint show whether that held.

- Tight oracle, mechanical (data entry, derived-value functions, copying
  from two examples, UI wired to a spec): T3.
- The contract leaves choices, or several modules interact: T2.
- No oracle (architecture, feel, UX, balance, review, any change to something
  frozen): T1, or the user.

T3 is weak at creative work: designing models, inventing equipment that is
fun, anything judged by taste (the user's experience). Such a milestone
given to T3 anyway needs a checkpoint that judges it by eye, named in the
plan.

A milestone fits one session and ends with its tests green and a commit. One
that runs into context compaction loses its contract.

### What can run at the same time

Give every milestone a `needs` list in `frame.toml`: the milestones whose
code it calls, plus any that edit the same file. Write it from what the
milestone uses, not from where it sits in the plan. `scripts/check` then
shows everything whose needs are done as `ready`, and ready milestones can
be given to separate agents at once. The first frame was planned as a
sequence; when the lists were written, three T3 milestones turned out to
need nothing after the first checkpoint and could have run beside the T2
work from the start.

Parallel work needs three things the template now carries: each agent in
its own worktree (one checkout has one `HEAD`, so a branch alone does not
separate them; the check refuses a milestone branch in the main checkout),
a union merge for the log, and a merge of each passed milestone into the
default branch before its checkpoint, so that what needs it can start.
Merging is not acceptance; the checkpoint reads each merge's diff.

### Testing whether a cheaper tier would do

The tiers and efforts in a plan are guesses. To measure one, run a real
milestone a second time on the cheaper setting in a sealed copy and compare:
`ab.md` has the steps, and `ab-clone` makes the copy. Prefer this to
invented side tasks, which say little about the frame in hand.

## Checkpoints

Set them at plan time, not when trouble shows: after the first milestone (is
the frame fillable at all?), at the first end-to-end runnable result, wherever
quality has no test, and on any request to change something frozen.

Tag one checkpoint as the **first playable** (first usable, for something
that is not a game): the earliest point where it runs without crashing and
someone other than the builder can try it. It is not the finished version.
Name it in the plan shown to the user and set `first_playable = true` on
that checkpoint in `frame.toml`, so the user knows from the start when
outside testing can begin (asked for 2026-11-10).

How to run one is in `review.md`: what to read, the code checklist, the
process review that fixes the frame and this skill without being asked, and
what to do with each kind of finding. In short: read the diff, not the
summary, and fix findings by amending the frame, not by hand-fixing code in
the review model.

## Footguns

- **The frame outgrows the job.** A contract that dictates the body has already
  paid for the implementation. Specify interfaces and invariants.
- **Wrong tests.** The designer wrote them without running anything. The
  implementer logs a `dispute` row naming the test and stops on it; it never
  bends code to the test or edits the test. The check then ends in `HELD`,
  which is a finished milestone waiting on the reviewer. The second
  milestone of the first project met one, and the implementer was right.
- **Green read as done.** Tests cover what was foreseen. That is why the
  checkpoint reads code.
- **A judgment task in a T3 milestone** ("make it feel heavy") with no proxy
  metric and no checkpoint behind it.
- **Drilling past usefulness.** A question with a conventional default costs
  the user a round trip for nothing.

## Status

First used 2026-11-10 on a Rust/Bevy mech game. Probe, drill and plan review
ran and were well received. The frame was built and compiled, but overspent:
that run produced "Budget the frame itself". It also skipped the thin
end-to-end path, so whether that step earns its cost is still unknown.

First handoff and checkpoint ran the same day: one tight-oracle milestone on
T3, reviewed by T1. The code was correct and to standard, so the split by
oracle tightness held for that case. What failed was around the code, and
produced `review.md`, the rules template, the finish-command rule and "What
a weak model writes".

Second milestone, same day: a judgment milestone on T2 at low effort,
reviewed by T1 from `review.md`. No code findings; it logged four gaps
before writing the code and correctly disputed a wrong frame test. That run
produced `HELD`, the subtask rule, `frame.toml`, the JSONL log and the tier
names.

Third milestone, same day: T2 at medium effort, not yet reviewed. It logged
seven gaps and an unprompted `friction` row with two real findings, so the
friction kind stays optional: requiring one would buy filler. Added after
it: `needs` lists, the ready/busy/waits listing, the worktree gate, the
early merge and `ab.md`. The gate and the listing were tested by hand; no
implementer has yet followed the worktree step, no two agents have run at
once, and the comparison in `ab.md` has only had its first step run.

Still hypotheses, never run: the thin end-to-end path, the test split and
stub split, the overspend number, the review ladder, `new-frame` on a second
repo, the template's non-Rust `[check]` examples, and the JSONL rows, `HELD`
and subtask rules as an implementer meets them. `review.md` has only been
followed by the model that wrote it. Revise from the next run.
