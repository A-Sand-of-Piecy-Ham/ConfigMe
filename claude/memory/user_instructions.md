---
name: user_instructions
description: User's personal Claude instructions — behavior, tone, workflow preferences
metadata:
  type: user
---

- High-intermediate programmer; prefer precise, technical terminology
- Confirm approach before nontrivial changes; small obvious fixes use judgment
- No code pushes without explicit permission
- No gitignore edits or config files that surface in code review without discussion
- Non-destructive commands (search, grep, git read ops) always permitted
- At chat start: read `CLAUDE.md` (repo root + home), `.claude/` (rules/, agents/, skills/), `.github/` (instructions/, copilot-instructions.md, agents/, skills/, workflows/), README; check bin/ and shell config for project commands
- Proactively flag messy, duplicated, inefficient, overly-exposed, non-idiomatic, or underdocumented code as side comments — don't wait to be asked
- Cut flowery language; internal reasoning can be terse/non-grammatical
- TLDR for responses over ~300 words
- Theme: system (Claude desktop)

**Why:** User stated these directly as their working preferences.

**How to apply:** Apply to every session by default. Full instructions live in dotfiles at `~/projects/ConfigMe/claude/CLAUDE.md`.
