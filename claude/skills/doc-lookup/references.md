# Cached lookups

Answers that were slow to find, ended somewhere non-obvious, or came from source
rather than docs. Format:

```
<topic> | <where> | <verified YYYY-MM-DD> | <note>
```

Entries older than roughly six months are hints, not facts: follow them, confirm
the answer still holds, then restamp the date. Wrong entries get tombstoned
rather than deleted -- see the skill body for why.

---

Nested `claude -p` fails inside a Claude Code session | unset `CLAUDE_CODE_ENTRYPOINT` | 2026-08-30 | Fails with "OAuth session expired and could not be refreshed", which is wrong on both counts: the credential is valid and nothing expired. The value is inherited as `claude-desktop`, so the nested CLI assumes the desktop app brokers auth in-process and never reads `~/.claude/.credentials.json`. Bisected: unsetting `CLAUDECODE`, `CLAUDE_CODE_CHILD_SESSION`, `CLAUDE_CODE_SDK_HAS_*`, `CLAUDE_CODE_OAUTH_SCOPES` or `ANTHROPIC_BASE_URL` individually all still failed. Wrapper: `bin/claude-probe`. Do NOT reach for `setup-token` or a re-login; both were tried first and were wrong.

Which instruction paths actually load | `InstructionsLoaded` hook -> `~/.claude/instructions-loaded.log` | 2026-08-30 | `~/.claude/CLAUDE.md` and every `.md` in `~/.claude/rules/` load at `session_start`, symlinks followed (`file_path` resolves to the repo). `~/.claude/memory/` does NOT load -- confirmed twice, by absence from the log and by a behavioural canary a session declined to act on. Do not reason about this from documentation; the log answers it in one probe run.

`@path` imports resolve from rules files, not just CLAUDE.md | tested via the load log | 2026-08-30 | A rule containing `@../file.md` loads that file with `load_reason: include`, distinct from `session_start`. Relative paths resolve against the importing file. Caveat when testing: a probe target placed inside `rules/` loads anyway because the whole directory is read, which confounds the result -- put the target outside `rules/`.

Imports do not reduce context | Claude Code memory docs | 2026-08-30 | "Imported files still load and enter the context window at launch." Splitting a large CLAUDE.md into `@` imports organises but does not save tokens. Use path-scoped rules (`paths:` frontmatter) or a skill for that.

SKILL.md supports `model` and `effort` frontmatter | Claude Code skills docs, frontmatter table | 2026-08-30 | Not obvious from the skill authoring guides. `model` accepts `/model` values or `inherit` and applies for the rest of the turn; `effort` takes low/medium/high/xhigh/max. Used to pin meta-skills to opus.

kitty config questions | `~/.local/kitty.app/share/doc/kitty/html/` | 2026-08-30 | Bundled docs match the installed version, which web docs may not. Settled `hints --type linenum` behaviour and the `globinclude` relative-path requirement faster than searching. `kitty +runpy` also loads the real config for verification: `from kitty.config import load_config`.
