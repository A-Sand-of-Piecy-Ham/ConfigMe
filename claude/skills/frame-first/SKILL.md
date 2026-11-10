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
5. **Checkpoint reviews** as the milestones land.

Repo layout and commits follow `project-setup` and `git-workflow`.

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
- An agent rules file in the repo gives milestone order, exact commands, what
  is frozen (public signatures, tests), and where to log a deviation.
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
| Checkpoint review | strongest | high |
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

Read the diff, not the test summary. Look for:

- edited, skipped or deleted tests
- bodies special-cased to the test inputs
- stubs still present (grep for the stub marker)
- helpers duplicated across modules
- contract clauses no test covers
- frozen signatures changed with no log entry

Fix findings by amending the frame (a new test, a tighter contract, a line in
the rules file) and sending the work back. Hand-fixing in the strong model ends
the cheap loop. If the finding is that the architecture is wrong, change the
frame rather than letting patches collect around it.

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
Handoff, checkpoint review, the test split and the effort table have not been
run: treat them as hypotheses and revise them from the first full run.
