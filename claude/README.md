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

`skill-forge`, `introspection` and `memory-write` pin `model: opus` with raised
`effort` in their frontmatter, so meta-work runs on the strongest model
regardless of the session setting.

## Rules

`claude/rules/` is linked to `~/.claude/rules`. Rules load every session, one
file per topic, and support `paths:` frontmatter to load only alongside matching
files. This is the right home for always-true behaviour that should stay in
separate files rather than being merged into `CLAUDE.md`.

## Settings and hooks

`claude/settings.json` is linked to `~/.claude/settings.json`: preferences
(theme, vim mode, effort) and hooks. Hooks are the harness enforcing something
rather than Claude remembering it:

| Hook | Does |
|---|---|
| `InstructionsLoaded` → `bin/log-instructions-loaded` | Logs every instruction file that loads, so "do rules actually load?" is checkable |
| `PreToolUse` on `Edit\|Write` → `bin/docs-audience-hook` | Editing a project doc injects "load docs-audience first". The skill's trigger alone missed doc edits made in passing during code changes |

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
