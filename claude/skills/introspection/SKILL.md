---
name: introspection
description: >
  Analyze a completed interaction to identify what response patterns worked well versus caused friction, and commit findings to the user's interaction style memory. Suggest invoking when the user expresses satisfaction with a session.
---

## Token budget

This skill runs often. Findings must be brief — one terse paragraph appended to the `## From introspection` section of `interaction_style.md`. No headers, bullets, or named subsections per finding. Project-specific details belong in project memory, not here. New additions must not drown out the established guidelines.

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

---

## Step 4 — Draft findings

Generalizable patterns only — no project-specific details. Terse, traceable to actual exchanges. If nothing new is evidenced beyond what's already in memory, add nothing.

---

## Step 5 — Commit to memory

Append to `## From introspection` in `~/projects/ConfigMe/claude/memory/interaction_style.md`. Update or reinforce existing entries rather than duplicating. Update `MEMORY.md` index only if a new top-level section was added.

---

## Hard constraints

- Do NOT fabricate sentiment — only log patterns with clear evidence.
- Do NOT pad — two real patterns beat five generic ones.
- Do NOT suggest this skill more than once per session.
- ALWAYS base findings on specific exchanges, not general impressions.
- If it is unclear how the user feels about the session, ask before inferring. Explicit feedback takes priority over inferred sentiment — when the two conflict, the user's statement wins.
