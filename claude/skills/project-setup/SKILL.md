---
name: project-setup
description: Set up or assess a repo against my project standards. Triggers - "new project", "set up the repo", "init", "scaffold", "bootstrap", "add CI", "set up docs", "project structure", "how should this repo be organized", a repo gaining collaborators or a remote.
---

The standards themselves are in `~/projects/ConfigMe/github-templates/project-standards.md`:
directory structure, branches and PRs, CI, versioning, regression testing,
reproducibility, docs, writing style, comments, the project log. Read it; don't
work from memory. Doc content and placement follow the `docs-audience` skill.

## Apply proportionally

A solo script needs a README and a lockfile, not rulesets and a runbook. Scale
up as the project gains collaborators, non-coder editors, or a deploy target.
Say what you're skipping and why, so it's a decision rather than an omission.

## New repo

1. Settle the directory layout and the entry docs (README, AGENTS.md with a
   one-line `CLAUDE.md` import, `docs/PROJECT_LOG.md`) before writing code. Moving
   files later rewrites history, and every doc and test path has to follow.
2. Commit linter, formatter, and type-check config first, with versions pinned.
3. Write one pre-commit command, make CI run exactly that, and put it in the
   README quick start and AGENTS.md.
4. When there's a remote, add the PR-title check and branch protection, and copy
   `github-templates/pull_request_template.md` into `.github/`.
   Protection is a repo setting: confirm it with the user before changing it.

## Existing repo

Assess against the standards and report the gaps, ranked by how much each one
risks a silent failure: rules that live only in docs, docs that describe unbuilt
things, CI that doesn't match the local checks, unpinned versions. Propose the
fixes; don't restructure without agreement. Layout and doc moves surface in
review and touch every path.

## Verify

- A fresh clone plus the documented quick start runs with nothing else installed.
- Every convention that matters is backed by a check that fails when it's broken.
  Try breaking one on purpose if unsure.
- Each doc passes the `docs-audience` verification for its reader.
