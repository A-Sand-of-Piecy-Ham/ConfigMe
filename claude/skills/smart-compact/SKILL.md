---
name: smart-compact
description: Prepare a compaction or clear so nothing needed is lost and the context comes back small. Triggers - "compact", "/compact", "clear context", "context is getting big", "taking a break", "back later", "done for today", a phase boundary reached (plan approved, frame committed, milestone done), context over ~150k.
---

## What this is for

Every tool call re-reads the whole conversation, so a large context makes each
call expensive. Compaction swaps the conversation for a summary. Left alone,
the summary keeps finished work in detail and can lose the thing in progress.
The aim: the next call is small, and nothing still needed is gone. The steps
below are the current way of getting that; change them when one fails.

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
100k, say to compact before leaving. The prompt cache lasts about an hour;
after that the first call re-reads everything at full price, and a compaction
run then pays that price too.

## When to raise it unprompted

- A phase boundary is reached and the context is over about 150k.
- The user says they are stepping away and the context is over about 100k.

Under about 100k, leave it: a compaction costs a summary's worth of output and
loses detail, and the saving per call is small. To read the current size, use
the session's usage tool if it has one, or the last `usage` record in the
session transcript.

## What cannot be controlled

After a compaction the harness re-reads up to five files, most recently
modified first (files over 5,000 tokens come back as a path only). There is no
setting for this. Expect a floor of 20-30k tokens after a compaction. Only a
clear avoids it.

## Check

After the user compacts, read the result:

```bash
grep -h '"compact_boundary"' ~/.claude/projects/*/"$CLAUDE_CODE_SESSION_ID".jsonl | tail -1 | grep -o '"preTokens":[0-9]*\|"postTokens":[0-9]*'
```

Success is `postTokens` under about 30k, and a summary that has the "keep"
items in detail. If a "keep" item is missing, ask the user for it now, while
they still remember, and add a line here saying what kind of item was lost.

## Status

Written 2026-11-10 from one manual compaction (366k to 26k). The notes file
and hook have not yet been through a real compaction, and the size thresholds
are reasoned from cache prices, not measured. A separate idea, a small tool
that types `/compact` into an idle terminal session before the cache expires,
is recorded in `claude/SELF-GENERATION.md` and not built.
