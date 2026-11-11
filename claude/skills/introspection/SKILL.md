---
name: introspection
description: >
  Analyze a completed interaction to identify what response patterns worked well versus caused friction, and file each finding where it belongs (interaction style, engineering practice, a skill, or project standards). Load without being asked at the end of a task in which a hook noted a user correction. Also - reviewing how an agent, model or earlier session performed; "did the skill work", "how did sonnet/opus do", "assess the process"; the user says a session used too many tokens or too much of a usage limit.
---

## Token budget

This skill runs often. Findings must be brief: one terse paragraph or bullet per finding, in the file it belongs to (Step 5). No headers, bullets, or named subsections per finding. Project-specific details belong in project memory, not here. New additions must not drown out the established guidelines.

---

## Step 1 — Identify the interaction window

Default to the most recent contiguous task if unspecified. Confirm scope only if ambiguous.

---

## Step 2 — Scan for sentiment signals

| Signal | Indicators |
|--------|-----------|
| **Resolved quickly** | User accepted without pushback, moved on immediately, explicit approval |
| **Positive but refined** | Right direction, execution corrected — approach was sound |
| **Friction / dwelling** | User had to repeat or restate, corrected a wrong assumption, expressed frustration, interaction stalled |
| **Neutral** | Informational exchange — skip |

---

## Step 3 — Identify decision patterns behind each outcome

For each friction or positive exchange, ask: what did Claude do just before that determined the outcome?

- Did Claude fix a clear bug immediately, or ask for permission first?
- Did Claude investigate existing config before proposing new tools?
- Did Claude read the file before claiming something didn't exist?
- Did Claude present options before implementing on a design question?
- Did Claude stay precisely scoped, or expand beyond the request?
- Did Claude correctly read whether the question was practical or conceptual — and calibrate depth accordingly?
- Did Claude verify the user's stated facts, or contradict them without checking?
- Did Claude respect constraints the user named (cost, performance, irreversibility) for the rest of the session?
- Did a loaded skill help, mislead, or get misfollowed? If misfollowed, was the step written so that only a stronger model than this session's would have read it correctly?
- Did the session learn something a skill should now say, and was the skill amended at the time or left as it was?

---

## Step 4 — Draft findings

Generalizable patterns only — no project-specific details. Terse, traceable to actual exchanges. If nothing new is evidenced beyond what's already in memory, add nothing.

---

## Step 5 — File each finding where it belongs

Classify first. `interaction-style.md` is only for the user and how to work *with* them; most lessons about the work itself go elsewhere.

| Finding is about | Goes in |
|---|---|
| The user: preferences, how they communicate, what to ask vs. do, reading intent | `~/projects/ConfigMe/claude/rules/interaction-style.md`, `## From introspection` |
| How to do engineering work: verification, safe edits, cleanup depth | `~/projects/ConfigMe/claude/rules/engineering-practice.md` |
| A workflow a skill already covers (docs, git, project setup, …) | That skill's `SKILL.md`, now. A line any model may add; anything structural follows the `skill-forge` split (strongest model, or a `## Pending` line) |
| A skill that was misfollowed or hard to follow | That skill's `SKILL.md`: rewrite the step with a condition, a default and an observable check. Name the session's model in the evidence clause |
| A convention every repo should follow | `~/projects/ConfigMe/github-templates/project-standards.md` |
| One project only | That project's memory or docs |

Check the destination for an existing entry and update it rather than duplicating. If a finding is already covered where it belongs, add nothing.

---

## When the complaint is token cost

The transcript is the ground truth, not the usage meter and not anyone's
impression. The meter tells the user that a window was spent; it does not
say which turn, call or tool spent it. The user may also name the wrong
cause, since the kinds of token differ in price two-hundredfold (the
user's own correction, 2026-11-11). So take the complaint as the signal to
measure, and let the numbers say what happened, including when they
contradict the user. The first guesses that day, the user's and the
session's (one big file, overthinking, over-logging), were all wrong. So
was the first measurement: it weighted cache reads at 0.1 for every model
and blamed the number of calls. With the weight the strongest model
actually has (0.025), the same turn was 55% cache write, 33% output and
12% re-reading. Check a weight against the price table before building on
it.

Costs are counted in **claws**, our own name for the unit: one claw is the
price of one uncached input token on the script's reference model. Calls
on other models are converted by the ratio of input prices, so sessions on
different models compare. A turn over about 15% of
a five-hour window is a large one. A session
can also run step 1 unasked after a turn it suspects was large (many
calls, a long review); it does not need the complaint.

1. One command, on the session's transcript (no argument means this
   session):

   ```bash
   session-cost; t=$(ls ~/.claude/projects/*/$CLAUDE_CODE_SESSION_ID.jsonl)
   echo ---; grep -o '"effort":"[a-z]*"' "$t" | uniq -c
   echo ---; jq -r 'select(.type=="assistant")|.message.content[]?|select(.type=="tool_use")|.name' "$t" | sort | uniq -c | sort -rn | head -6
   echo ---; jq -r 'select(.type=="user")|.message.content[]?|select(.type=="tool_result")|(.content|tostring|length)' "$t" | sort -rn | head -3
   ```

   `session-cost` prints one row per user turn: calls, claws, the share
   that was cache read, cache write and output, the peak context, and an
   estimated share of the window, with `!` on a large turn. The window's
   size is an estimate from one reading; the script's header says how
   rough. Then: the order in which effort levels ran (the counts are
   lines, not calls), the tools used most, and the three largest tool
   results in characters.
2. Take the costliest turn and say which share is largest.
3. Match it to a cause:

   | Shows | Cause | Fix goes in |
   |---|---|---|
   | `read` largest; `calls` far above what the task needed | One tool call per message, upkeep done one item at a time | `rules/call-economy.md` |
   | `write` largest, in a turn of one or two calls that starts "This session is being continued" | A compaction: it writes everything it keeps again at twice price (50k to 100k tokens each, 22% of one session) | Fewer compactions: tell the user the count and what they cost. The threshold is the user's setting |
   | `write` largest, spread over many calls | Large tool results, or a skill body loaded early | The same file's size limits; the skill that asked for the early load |
   | A tool result over about 16,000 characters | A whole file or unbounded command output | The same file's size limits |
   | An effort level the user did not set | An `effort:` line in a loaded skill's header | Delete the line (`skill-forge` forbids it) |
   | `out` largest | Long replies or long reasoning | `rules/interaction-style.md`, reply length |

4. Tell the user the numbers and the cause in three lines, then make the
   fix. One row in `claude/SELF-GENERATION.md` under Observations.

## Hard constraints

- Do NOT fabricate sentiment — only log patterns with clear evidence.
- Do NOT pad — two real patterns beat five generic ones.
- Do NOT suggest this skill more than once per session.
- ALWAYS base findings on specific exchanges, not general impressions.
- If it is unclear how the user feels about the session, ask before inferring. Explicit feedback takes priority over inferred sentiment — when the two conflict, the user's statement wins.
