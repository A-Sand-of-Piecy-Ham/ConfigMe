---
name: research-log
description: Record evidence bearing on the open questions in claude/SELF-GENERATION.md. Triggers - a skill fired or failed to fire unexpectedly, a description change altered behaviour, a memory was missed or misfiled, "that worked", "turns out", "that answers".
model: opus
effort: medium
---

## What this is for

`claude/SELF-GENERATION.md` carries open questions about how skills and memory
should be built. Most evidence for them arrives sideways, as a side effect of
doing something else — a skill fires when it should not, a compressed
description still triggers reliably, a correction gets caught the second time it
lands. That evidence is worth more than it costs to write down, and it is lost
by default.

Interrupting the task briefly to record it is explicitly wanted. Note the
observation, then return to what was being done.

## What counts

Anything that bears on a listed open question:

- A skill triggered when it should not have, or failed to when it should.
- A description was shortened and triggering did or did not survive.
- The "corrected twice" or "failed silently" signal fired, correctly or not.
- A lesson went to the wrong place — skill, rule, or memory — and it showed.
- Two skills competed for the same trigger.
- A skill loaded and turned out to be irrelevant, so its body was wasted context.

Single observations count. This is a log, not a study; the point is to
accumulate instances until a pattern is visible.

## How to record it

Append under `## Observations` in `claude/SELF-GENERATION.md`, dated, one entry:
what happened, which question it bears on, and what it suggests. State it as an
observation, not a conclusion — one instance is not a result.

If it suggests a new question, add that to the open questions list too. A
question raised by evidence is worth more than one raised by speculation.

Tell the user in one line: what was observed and where it was noted. Then
continue the original task.

## What not to do

Do not log a skill working as designed. That is the null result, and logging it
buries the informative entries.

Do not rewrite an open question to match a single observation. Questions close
on accumulated evidence, and closing one early is worse than leaving it open.
