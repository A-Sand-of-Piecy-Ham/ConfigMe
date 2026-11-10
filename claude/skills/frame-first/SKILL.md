---
name: frame-first
description: Plan a build as a strong-model frame that weaker models fill in. Triggers - "one shot this", "agentic code", "design the structure, not the implementation", "frame for a weaker model", "stub it out", "leave out implementation", "hand off to sonnet/opus/haiku", "which model for which part", "when do I swap models", "checkpoint review", "review what the other model built".
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

Check the session's model before designing. If it is not the strongest
available, stop and tell the user; design only if they say to go on. A frame's
mistakes are inherited by every milestone built on it.

Tiers here are relative: "strongest", "mid" and "small" mean what is
available today, not model names. When the top model is weaker than the one
this was written with, keep the method and shrink the steps: smaller
milestones, a checkpoint after each of the first three, and one end-to-end
path implemented before any handoff.

At a checkpoint, or when reviewing what another model built, read
`review.md` in this directory and work from it. When writing a frame's agent
rules file, start from `agents-template.md`. Neither is needed otherwise.

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
   milestones, the model for each, and the checkpoints. Nothing goes on disk
   before a yes.
4. **Build the frame**, then tell the user plainly: swap models now, and come
   back at these named points.
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
   file in the repo (decisions with reasons, module list, milestones, model
   and checkpoint assignments). Then tell the user to start a fresh session
   pointed at that file, or to compact. Build the frame from the file.
2. **After the frame is committed.** The repo is now the whole state. This is
   the model swap anyway.
3. **After each milestone**, which the one-milestone-per-session rule covers.

Skip a boundary only when the user says the live context is worth its cost.

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
- An agent rules file in the repo, built from `agents-template.md`: milestone
  order, exact commands, what is frozen (public signatures, tests), where to
  log a deviation, what to read and what to report.
- **One finish command that can pass at every milestone.** It runs that
  milestone's tests and every earlier one, nothing later, and prints a
  PASS or FAIL line. Run it against the bare frame before handoff. The first
  frame said "all tests pass", which could not be true until the last
  milestone; the implementer worked around it and reported the expected
  failures at length.
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
  become a sub-milestone for the smallest model.
- **Watch for it while writing.** About to write a third instance of the same
  shape: stop, add the sub-milestone, move on. This has to be caught live; the
  plan will not have foreseen every repetition.
- **Estimate output at plan review.** List what the frame will contain and
  roughly how long each piece is. Anything long and repetitive is assigned to
  a cheaper model before writing starts, and the plan shown to the user says
  so.
- **Tests split the same way, with more care.** They are the oracle, so a
  weaker model writing all of them weakens everything downstream. The strong
  model writes the list of cases for each suite (name plus the one thing it
  asserts) and the cases that encode a design decision. A mid-tier model
  writes out the rest; the strong model reads them at the first checkpoint.
  Untested as of this writing.
- **Stubs split the same way.** The strong model keeps what cannot be
  recovered from a wrong guess: signatures, formulas, the order of
  operations, invariants, and the list of test cases. A mid-tier session
  expands that into compiling files: field docs, stub bodies, test bodies,
  the rules file. The first frame's strong model typed about seventy stubs
  with their comments itself. Untested.
- **A number to notice overspend by.** The plan's estimate gives each piece a
  length. While writing, at twice the estimate for a piece, stop, hand the
  remainder to a cheaper model as a sub-milestone, and tell the user. Without
  a number there is nothing to notice against.
- **Checking is not the strong model's work either.** Pipe test, lint and
  build output through a filter so only failures reach the context (`-q`,
  `tail`, a grep for errors); unfiltered runs were a large share of the
  first frame's input. A compile-and-fix loop expected to take more than
  two rounds goes to a cheaper subagent or session, with the error list as
  its brief.

## What a weak model writes, a strong model reads

Every line an implementer writes into a log, a commit or a report is later
input for the review tier, at the review tier's price and trust. So choose
what it writes:

- Fixed-format lines with a length cap: a gaps row, a friction line, the
  report fields. The template has them.
- No free prose in docs. Design docs, contracts and READMEs beyond a status
  cell are written or approved by the tier that owns them.
- Unstated duties are not done. The first small-model implementer followed
  every numbered step and none of the implied ones ("keep the log true"
  produced a false line). If the reviewer needs something recorded, the rules
  need a step, a format and a check for it.

Relative cost per token when this was written (2026-11): the strongest model
about 2x the mid tier and 4x the small one. Check current prices before
relying on the ratio; the point is that it is large, and that it counts
against both the short and the weekly usage limits.

## Reasoning effort

Effort buys the most where the output is short and a mistake is expensive, and
the least where a test will catch the mistake anyway. These are starting
points reasoned from that, not measurements:

| Step | Model | Effort |
|---|---|---|
| Probe and drill | strongest | medium |
| Architecture and plan review | strongest | high |
| Writing the frame (the design is already decided) | strongest | medium |
| Bulk fill from examples | small | low |
| Tight-oracle milestones | small | medium |
| Milestones with judgment, or where modules first meet | mid | high |
| UI and framework wiring | small or mid | medium; look up the API instead of thinking harder |
| Checkpoint review | strongest | medium (one run: findings came from reading and running, not from thinking longer) |
| Tuning with the user | strongest | medium |

## Splitting work across models

Assign by how much judgment the oracle leaves open, not by size.

- Tight oracle, mechanical (data entry, derived-value functions, UI wired to a
  spec): the smallest model.
- The contract leaves choices, or several modules interact: mid tier.
- No oracle (architecture, feel, UX, balance, review, any change to something
  frozen): the strongest model, or the user.

A milestone fits one session and ends with its tests green and a commit. One
that runs into context compaction loses its contract.

## Checkpoints

Set them at plan time, not when trouble shows: after the first milestone (is
the frame fillable at all?), at the first end-to-end runnable result, wherever
quality has no test, and on any request to change something frozen.

How to run one is in `review.md`: what to read, the code checklist, the
process review that fixes the frame and this skill without being asked, and
what to do with each kind of finding. In short: read the diff, not the
summary, and fix findings by amending the frame, not by hand-fixing code in
the review model.

## Footguns

- **The frame outgrows the job.** A contract that dictates the body has already
  paid for the implementation. Specify interfaces and invariants.
- **Wrong tests.** The designer wrote them without running anything. The
  implementer logs a disputed test and stops on it; it never bends code to the
  test or edits the test.
- **Green read as done.** Tests cover what was foreseen. That is why the
  checkpoint reads code.
- **A judgment task in a weak model's milestone** ("make it feel heavy") with
  no proxy metric and no checkpoint behind it.
- **Drilling past usefulness.** A question with a conventional default costs
  the user a round trip for nothing.

## Status

First used 2026-11-10 on a Rust/Bevy mech game. Probe, drill and plan review
ran and were well received. The frame was built and compiled, but overspent:
that run produced "Budget the frame itself". It also skipped the thin
end-to-end path, so whether that step earns its cost is still unknown.

First handoff and checkpoint ran the same day: one tight-oracle milestone, a
small model, reviewed by the strongest. The code was correct and to
standard, so the split by oracle tightness held for that case. What failed
was around the code, and produced `review.md`, `agents-template.md`, the
finish-command rule and "What a weak model writes".

Still hypotheses, never run: the thin end-to-end path, the test split and
stub split, the overspend number, the review ladder, milestones for the mid
tier, and everything in `review.md` when the reviewer is not the model that
wrote it. The effort table has one data point (checkpoint review). Revise
from the next run.
