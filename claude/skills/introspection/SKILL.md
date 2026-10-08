---
name: introspection
description: >
  Analyze a completed interaction to identify what response patterns worked well versus caused friction, and file each finding where it belongs (interaction style, engineering practice, a skill, or project standards). Suggest invoking when the user expresses satisfaction with a session.
model: opus
effort: high
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
| A workflow a skill already covers (docs, git, project setup, …) | That skill's `SKILL.md` (use `skill-forge` for anything beyond a line) |
| A convention every repo should follow | `~/projects/ConfigMe/github-templates/project-standards.md` |
| One project only | That project's memory or docs |

Check the destination for an existing entry and update it rather than duplicating. If a finding is already covered where it belongs, add nothing.

---

## Hard constraints

- Do NOT fabricate sentiment — only log patterns with clear evidence.
- Do NOT pad — two real patterns beat five generic ones.
- Do NOT suggest this skill more than once per session.
- ALWAYS base findings on specific exchanges, not general impressions.
- If it is unclear how the user feels about the session, ask before inferring. Explicit feedback takes priority over inferred sentiment — when the two conflict, the user's statement wins.
