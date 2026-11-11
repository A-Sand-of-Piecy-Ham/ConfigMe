# Claude Code configuration

Linked into `~/.claude/` by the installer. Four pieces: instructions that load
every session, rules that load every session as separate files, skills that
load only when their description matches the task, and settings, whose hooks
run whether or not Claude remembers anything.

## Skills

`claude/skills/` is linked to `~/.claude/skills`. A skill's `description` is its
trigger -- Claude matches the task against it -- so descriptions are written
with the phrases that should invoke them, not as summaries. They are also
written tersely on purpose: a description is loaded into context for every
session whether or not the skill ever fires, while the body is loaded only on
trigger. The description is permanent context cost; the body is not.

| Skill | Triggers on |
|---|---|
| `web-browsing` | Reading, searching, or interacting with a page; routes between WebFetch and chrome-devtools rather than reaching for a browser first |
| `todo-capture` | "create a todo", "add a task", "remind me to" -- captures into TickTick instead of replying that it was noted |
| `dotfiles-change` | Editing anything this repo manages; covers the steps that fail silently, like a running tmux server never re-reading its config |
| `introspection` | Reviewing a finished session for what worked |
| `skill-forge` | Writing or revising a skill |
| `git-workflow` | Commits, branches, PRs -- the habits easy to skip under momentum |
| `doc-lookup` | Library and API questions; caches hard-won answers, tombstones dead ones |
| `calendar-check` | Availability and scheduling |
| `memory-write` | "always", "never", "from now on" -- persists rather than just complying |
| `research-log` | Evidence bearing on the SELF-GENERATION open questions |
| `docs-audience` | Any edit to a project doc; picks the depth and tone for whoever reads that file |
| `project-setup` | Setting up or assessing a repo against the project standards |
| `frame-first` | Planning a build so the strongest model designs the structure and cheaper models fill it in, with tests and review checkpoints. Carries a `template/` of repo files (rules, milestone file, finish check) and `new-frame <repo>` to copy it in |
| `smart-compact` | Compacting or clearing a large session; writes notes on what the summary must keep, since the agent cannot start a compaction itself |

Skills are drafts. A session that finds one wrong or incomplete amends it then
and there; `skill-forge` says which changes any model may make and which wait
for the strongest one.

No skill pins a model. Four of them used to carry `model: opus` so meta-work
would run on the strongest model, and once a stronger model shipped the pin
quietly downgraded every session that loaded them. Some still set `effort`.

## Rules

`claude/rules/` is linked to `~/.claude/rules`. Rules load every session, one
file per topic, and support `paths:` frontmatter to load only alongside matching
files. This is the right home for always-true behaviour that should stay in
separate files rather than being merged into `CLAUDE.md`.

`model-tiers.md` is the one place that says which model is T1, T2 and T3.
Skills and repos name tiers only, so a model change is a one-line edit there.

## Settings and hooks

`claude/settings.json` is linked to `~/.claude/settings.json`: preferences
(theme, vim mode, effort, when auto-compaction starts) and hooks. Hooks are the harness enforcing something
rather than Claude remembering it:

| Hook | Does |
|---|---|
| `InstructionsLoaded` → `bin/log-instructions-loaded` | Logs every instruction file that loads, so "do rules actually load?" is checkable |
| `PreToolUse` on `Edit\|Write` → `bin/docs-audience-hook` | Editing a project doc injects "load docs-audience first". The skill's trigger alone missed doc edits made in passing during code changes |
| `PreToolUse` on `Bash` → `bin/bash-skill-hook` | A shell command that commits or pushes injects "load git-workflow first"; one that writes a project doc (`sed -i`, a redirect, a script) injects "load docs-audience first". A session that did all its edits and commits through the shell had loaded neither |
| `SessionStart` → `bin/claude-version-watch` | When Claude Code has updated since the last session, prompts a changelog check for features ConfigMe should adopt. Once per version |
| `PreCompact` → `bin/compact-notes-hook` | Gives every compaction standing instructions on what to keep, plus the session's own notes when the `smart-compact` skill wrote some |

Hook commands use `$HOME`, not absolute paths, so the file works on any machine.
Permission approvals granted mid-session go to `~/.claude/settings.local.json`,
which stays machine-local and untracked. Changing a setting in `/config`
rewrites the linked file, so it shows up as a diff here; `install.sh --doctor`
flags it if Claude Code ever replaces the link with a plain file.

`bin/claude-config-check` (run by the doctor) checks what actually loads, not just
what's linked: the load log must show `CLAUDE.md` and every rule in the last
session, every recent session must have logged loads (proof the hooks fire),
skills need a description, and each auto-memory folder needs a `MEMORY.md` index
that matches its files. Auto-memory itself isn't reported by the load hook, so
memory only gets the static checks.

## Memory

`claude/memory/` was removed. It symlinked to `~/.claude/memory/`, which nothing
reads -- auto-memory lives in `~/.claude/projects/<slug>/memory/`, which is
machine-local and not trackable. The behavioural files moved to `rules/`; the
rest was either a duplicate of `CLAUDE.md` or already covered by a skill.

## Design

[SELF-GENERATION.md](SELF-GENERATION.md) covers the reasoning behind all of the
above: why a description is permanent context cost while a body is not, the
procedure-vs-shim distinction, and where a lesson belongs -- skill, memory, or
`CLAUDE.md`.
