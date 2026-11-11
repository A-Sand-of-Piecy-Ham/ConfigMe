---
name: smart-compact
description: Prepare a compaction or clear so nothing needed is lost and the context comes back small. Triggers - "compact", "/compact", "clear context", "context is getting big", "taking a break", "back later", "done for today", a phase boundary reached (plan approved, frame committed, milestone done), a hook note that an automatic compaction is near or that the context is past its window.
---

## What this is for

Compaction swaps the conversation for a summary. Left alone, the summary
keeps finished work in detail and can lose the thing in progress. The aim:
nothing still needed is gone, and what comes back is small. The steps below
are the current way of getting that; change them when one fails.

A compaction is not a saving to reach for early. Costs are in claws (one
uncached input token of the strongest model; `session-cost` prints them).
Each call re-reads the context at a fortieth of that price on the strongest
model and a twentieth on the next two, so 100k of context costs 2.5k or 5k
claws per call. A compaction writes everything it keeps again at twice price
and pays for the summary as output: 150k to 250k measured. It repays only
over some 40 to 60 further calls, and the automatic one comes at about
four-fifths of the window anyway. So let the automatic compaction happen
when it happens, and spend the effort on what survives it.

The agent cannot start a compaction. It prepares one, and the user types
`/compact`.

## 1. Clear or compact

Ask the cold-start question: could a new session continue from the files on
disk alone?

- **Yes: offer a clear.** It is the cheapest option: no summary to write, and
  no files re-attached. If the session has a tool that clears itself, use it
  (the user approves it); otherwise the user types `/clear`. Say which file
  the next session should start from.
- **Nearly: write the missing part to a file** (a decision, a caveat, the
  state of a half-done task), then offer the clear.
- **No**, because recent discussion is still needed and is not worth writing
  up: compact, using the notes below.

## 2. Write the notes

Write to `~/.claude/compact-notes/$CLAUDE_CODE_SESSION_ID.md` (create the
directory if missing). The PreCompact hook `bin/compact-notes-hook` feeds this
file into the next compaction of this session, of any kind, and then retires
it.

Three lists. Name content, never turn counts: the note text only shapes the
summary, and how many messages survive word for word is the harness's choice.
"Keep the last 3 turns in detail" was tried on 2026-11-10 and only one message
survived.

```
Keep in detail:
- the open question about the save-file format, and both options with their costs
- the failing test's exact error text
Reduce to one line:
- the frame design: "frame is built, see AGENTS.md"
Drop:
- the detour into editor config
```

```
Keep in detail:
- the three review findings not yet fixed, with file and line
Reduce to one line:
- findings already fixed: "fixed in commits a1b2c3d..e4f5a6b"
Drop:
- nothing
```

What varies is the content. Keep the three headings. Stay under about fifteen
lines; the hook cuts notes off at 8,000 characters.

The hook already tells every summary to collapse committed work to a path and
to keep unfinished state, so the notes only need what is specific to this
session.

## 3. Tell the user

One line: the notes are written, type `/compact`. No arguments are needed.

If they are leaving for more than about 50 minutes and the context is over
about 150k, say to compact before leaving. The prompt cache lasts about an
hour; after that the first call writes the whole context again at twice
price (300k claws at 150k). Compacting first costs its 150k to 250k and then
only the small context is written again on return, so below about 150k the
two come out even and the detail is worth more.

## When to raise it unprompted

- The hook says an automatic compaction is near, and something still needed
  exists only in the conversation: write the notes (step 2), or set a hold
  if the task is about to write the thing to a file. Do not tell the user to
  type `/compact`; the automatic one will use the notes.
- A phase boundary is reached, the cold-start question answers yes, and many
  calls remain: offer the clear. A clear writes about 50k tokens, a third of
  what a compaction costs.
- The user says they are stepping away for an hour or more and the context
  is over about 150k.
- The hook says the context is past its window: a hold is still set, or
  compaction is off. Say which, and what to do.

Otherwise leave it. To read the current size, use the session's usage tool
if it has one, or the last `usage` record in the session transcript. The
window is `autoCompactWindow` in `~/.claude/settings.json`, or
`modelSettings.<model>.autoCompactWindow` where one is set for the model.

## Holding an automatic compaction

When the conversation holds something not yet on disk and the task is about
to write it (review findings, a plan mid-approval), an automatic compaction
at that moment loses it. Hold it off:

```bash
mkdir -p ~/.claude/compact-notes && echo "<what is not yet written>" > ~/.claude/compact-notes/"${CLAUDE_CODE_SESSION_ID:?}".hold
```

Delete the file as soon as the thing is written. While it exists the
PreCompact hook refuses automatic compactions; a typed `/compact` still
runs, and the hold expires after two hours. Use it for a stretch of work,
never for a session: every call made while held is paid at the full context
size. Writing the thing to a file sooner is always the better fix.

## What cannot be controlled

After a compaction the harness re-reads up to five files, most recently
modified first (files over 5,000 tokens come back as a path only). There is no
setting for this. Skill bodies loaded before the compaction come back too.
Measured over three automatic compactions on 2026-11-11: `postTokens` of
27k, 30k and 58k, and the first call afterwards wrote 51k, 57k and 99k
tokens to the cache (the 99k carried one very large skill body). Only a
clear avoids it. A large skill loaded for one lookup is paid for again at
every later compaction, which is one more reason to load skills late.

## Check

After the user compacts, read the result:

```bash
grep -h '"compact_boundary"' ~/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl | tail -1 | grep -o '"preTokens":[0-9]*\|"postTokens":[0-9]*'
```

Success is a summary that has the "keep" items in detail, and `postTokens`
under about 60k. Over that, look at what came back (a large skill body, big
re-attached files) and note it here. If a "keep" item is missing, ask the
user for it now, while they still remember, and add a line here saying what
kind of item was lost.

## Status

Written 2026-11-10 from one manual compaction (366k to 26k). The notes file
and hook have not yet been through a real compaction. The first version's
thresholds (compact at a phase boundary over 150k, before leaving over 100k)
rested on a cache-read price four times too high; they were redone on
2026-11-11 from one session's measured compactions, and the 150k to 250k
cost of a compaction is an estimate from those three. The hold was added the same
day after a review lost its place to a mid-task compaction; the hook's exit
codes are tested, but no real automatic compaction has met a hold yet, so
what the session and the user see when one is refused is unknown. Record it
here the first time it happens. A separate idea, a small tool
that types `/compact` into an idle terminal session before the cache expires,
is recorded in `claude/SELF-GENERATION.md` and not built.
