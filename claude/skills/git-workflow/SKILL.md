---
name: git-workflow
description: Commit, branch, PR, or push in any repo. Triggers - "commit this", "make a PR", "push", "open an issue", writing a commit message, or finishing a change that should be recorded.
---

## Scope

`CLAUDE.md` already carries the standing rules -- never push unasked, never
touch in-repo config or `.gitignore` without discussion -- and is loaded every
session, so they are not restated here beyond one reminder: **approval to push
once is not approval to push again.** Branch first if on the default branch.

Repo conventions -- branch naming, CI expectations, versioning, review norms --
live in `github-templates/project-standards.md`. Read that when setting up or
assessing a repo rather than duplicating it here. This skill covers only the
mechanics of making a change land.

When a new repo is being set up, or an existing one grows collaborators,
suggest copying `github-templates/pull_request_template.md` into `.github/` and
applying the standards proportionally to project size. Flag when a growing
project would benefit from branch protection or CI it does not yet have.

## Commit messages

Subject line under ~72 characters, imperative mood, no trailing period.

The body explains **why**, not what — the diff already shows what. A message
that says "fixed the bug" is worthless six months on; one that says which
symptom, under what conditions, and why the chosen fix rather than the obvious
one, is not.

Wrap the body at ~72 characters. Backticks in a bash heredoc get
command-substituted, so avoid them or use a quoted heredoc.

End with:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

## PRs

Body ends with:

```
🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Reference issues and PRs as full markdown links using the owner/repo from the
actual remote. Never a bare `#123`, and never assume a default repository.

## gh versus the GitHub MCP

Both are available. `gh` is faster for one-shot commands and is already
authenticated. The MCP is better for multi-step work against the API — reading
a PR's review threads, walking issues, batching file changes — where shelling
out repeatedly is clumsier.

The MCP authenticates from `gh auth token` through `bin/github-mcp`, so both
carry the same permissions. That token has `repo` scope: the MCP can write to
repositories. The no-push rule applies to it exactly as it applies to `git`.

## Before committing

Verify claims rather than asserting them. If tests were run, say what happened,
including failures. Do not describe work as done when a step was skipped.

Never modify in-repo config or `.gitignore` without asking first — those
surface in review. The global gitignore is machine state and is exempt.
