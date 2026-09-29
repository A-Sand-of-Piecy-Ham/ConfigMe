# Project Standards

Reference guidance for setting up a professional project. Apply proportionally — a solo script doesn't need all of this, but anything with collaborators or longevity should.

The theme throughout: **rules that matter are enforced by a check, not remembered.** A convention only in a doc drifts; the same convention in a test, lint rule, or CI job holds.

## Directory structure

One purpose per top-level directory, named for what's in it:

| Dir | Holds |
|---|---|
| `src/` | Runtime code |
| `scripts/` | CLI tools and build steps CI or maintainers run |
| `tests/` | Test suites (plural, mirroring what they cover) |
| `docs/` | Maintainer and contributor docs (see Documentation) |
| `content/` or `config/` | Data and settings, kept out of code so non-coders and CI can read them |
| `vendor/` | Third-party code **exactly as published**. Never edit it; update by replacing the whole folder, override from your own files. First-party code never goes here, and vendored code never goes anywhere else |

- Assets are grouped by class (e.g. `images/members/`, `images/teams/`), each with its own limits and naming rule, enforced by a check.
- Names are readable and stable. Replace generated or builder names (`cid-4a2f`, `display-7`) with names that say what the thing is.
- Settings live in one file and are referenced by name; never hard-code a value that lives in settings. An unknown name fails the build.
- Root holds the entry docs only: `README.md`, `AGENTS.md` (agent instructions; `CLAUDE.md` just imports it), and a non-coder guide such as `EDITING.md` if the project has editors.

## Branch strategy

- `main`/`master` is protected: no direct pushes, requires PR + review + passing CI
- Branch from the last successful build tag or a stable base, not HEAD, to avoid broken bases
- Branch naming: `<user>/<issue-id>/<short-description>`
- Short-lived branches — merge or close within days/weeks, not months

## Pull requests

- Every change goes through a PR, no matter how small once the project has collaborators
- PR title: concise, references issue ID if applicable
- Use `.github/pull_request_template.md` (see sibling file) for consistent structure
- PRs should be reviewable — scope them to one concern; avoid mixing refactors with features
- Link to the issue/ticket in the PR description

## CI / workflows

Set these up early — retrofitting is painful:

- **On push / PR:** lint, typecheck, unit tests — must pass before merge
- **On merge to main:** build artifact, run integration tests
- **Nightly (optional):** extended/slow tests, dependency audits, security scans
- Block merges on failing checks; don't let red builds linger
- The local pre-commit command is **the same set of checks CI runs**, written in one place (README quick start and AGENTS.md), so "passes locally" means "passes CI".
- Checks that depend on an outside service (a live form, a third-party API) run on a schedule and on relevant PRs, but aren't required: an outage elsewhere shouldn't block merges.
- Never weaken or bypass a check to get a change in. If a check is wrong, fix the check in its own PR.
- Pin third-party actions to a full commit SHA with a `# vX.Y.Z` comment; first-party (`actions/*`) to a major tag. Dependabot keeps both current.
- Required-check job names are referenced by branch protection; renaming one silently disables it. Change both together.
- PR titles use Conventional Commits and are checked in CI; the title becomes the squash commit and decides the release.

## Versioning

- Tag releases semantically: `v<major>.<minor>.<patch>`
- **Bump by regression risk, not by whether code changed.** Anything that could change what users see or get, even by accident (content, refactors, build and dependency changes), gets at least a patch, so a regression maps to a release. Tests, CI, docs, and formatting can't, so they don't release.
- **Breaking = a contract breaks**, not "a big change": a schema or config key others rely on, a public URL, or a deploy step. A large rewrite that keeps every contract is a patch or minor.
- Never edit the version by hand; derive it from commit types.
- Tags are immutable — never move a published tag
- For breaking changes: bump major; for new features: minor; for fixes: patch
- Maintain a `CHANGELOG.md` or use GitHub releases

## Testing standards

- New features need tests before merge
- Bug fixes need a regression test
- **Encode policies as tests**: ordering rules, naming rules, size limits, contrast, link validity. A reviewer forgets; a test doesn't. Exceptions go in a tracked list with a reason each, and an exception for something that no longer exists fails.
- **Docs drift is a test failure** where it's cheap: e.g. every script, test file, and commit type must appear in the runbook's tables.
- **Verify refactors against the real thing.** For a visual or structural refactor, compare before/after (element geometry, computed styles) rather than eyeballing. When local tooling imitates a host or service, compare it against the host's own emulator.
- Aim for coverage on critical paths, not 100% coverage theater
- Integration tests over mocks where feasible — mocks diverge from reality

## Linting and formatting

Solve style once at project setup — mid-project additions poison blame history with noisy diffs.

- Commit linter and formatter config at project start; pin versions to prevent surprise CI failures on rule updates
- Formatting is a dev choice, not enforced on save — but CI must enforce it. A preflight/pre-merge workflow should run lint, format check, and typecheck as blocking checks; warnings that don't block get ignored
- Never mix formatting changes with logic in a PR — isolate them in a dedicated commit so diffs stay readable
- Disable rules in-file sparingly and always with a comment explaining why
- Explicit rule config beats inherited defaults — extend a shared config, then override intentionally rather than drifting with upstream changes

| Language | Formatter | Linter |
|----------|-----------|--------|
| TypeScript/JS | Prettier | ESLint |
| Python | Ruff | Ruff |
| Rust | `rustfmt` | Clippy |
| C/C++ | `clang-format` | `clang-tidy` |
| Lua | StyLua | Selene |

## Reproducibility

- Lockfile committed; install with the exact-versions command (`npm ci`, not `npm install`). Pin tool versions and list them, with install and check commands, in the runbook.
- Local dev mirrors production: the dev server behaves like the host (URLs, redirects, 404s, caching headers), so bugs show up locally first.
- Prefer no build step for tooling where the runtime allows it; fewer moving parts to reproduce.
- Deterministic outputs: content-hashed asset URLs, generated files derived only from the repo.
- Optimize binary assets **before** committing (git keeps every version forever); limits enforced by a check.
- No secrets in the repo; create them out-of-band and document the step. Machine-local junk goes in the global gitignore, not the project's.
- Optional deployment paths (containers, Kubernetes) are documented separately so the main path stays simple.

## Commit hygiene

- Strip temporary comments (debug notes, `// TODO: fix this`, `// temp`) before pushing non-WIP commits — they erode signal in the codebase
- Persistent `TODO`/`FIXME` comments must reference a ticket; bare ones are noise that never gets resolved
- Squash merge PRs into main where possible — keeps history linear and each commit meaningful. Reserve merge commits for long-running branches where individual commit history has value

## Code review norms

- Reviewer approves logic and design, not just style (linters handle style)
- Author resolves all comments before merge, or explicitly defers with justification
- Small PRs get faster, better reviews — keep them focused

## Documentation

Docs exist to get information across, not to store it. Write each doc for one reader, at that reader's depth (the `docs-audience` skill has the details and failure modes):

| Doc | Reader | Contains |
|---|---|---|
| `README.md` | Anyone arriving | Contents, quick start first, how it works in a paragraph, layout, short contributing, an explained index of the other docs, a separate "Planned" section for high-priority work only |
| `EDITING.md` (if there are non-coder editors) | Editors | What to do, what not to do, who to ask. No jargon, no mechanisms |
| `docs/RUNBOOK.md` | Maintainers (basic developer) | Every command, deploy, setup step, test, and CI failure, each with *why* it exists |
| `docs/ARCHITECTURE.md` | Contributors | Stack (today vs planned), design rationale, conventions with their reasons |
| `docs/PROJECT_LOG.md` | Contributors | See Project log below |
| `AGENTS.md` | AI agents | Conventions and hard rules, with a "keep this and the docs above in sync in the same change" clause |

- Only describe what exists. Planned work is labelled as planned, in its own section.
- Keep docs in sync **in the same change** that makes them wrong.

### Writing style

- Plain, direct, conversational. No legalese or RFC-style MUST/SHALL; say "never" or "always" when it matters.
- Explain why, briefly. A rule whose reason is known survives cases the rule didn't anticipate.
- Precise terms for technical readers; none for editors.
- Jokes and jabs are welcome in comments, docs, and content (e.g. "so no one gets hurt fee-fees :P"). A review or cleanup pass keeps them: don't reword them into formal prose or strip them as noise. Fix only a joke that's factually wrong or hides the point.

### Comments

- Brief, and about *why*: intent, constraints, the non-obvious. Don't narrate what the code says.
- Don't duplicate descriptions that belong in docs; point to the section instead ("rules: ARCHITECTURE → Theme"). One place to update means no stale copy.
- Avoid facts that rot: counts, version numbers, lists of callers, "currently". If it must change when unrelated code changes, it doesn't belong in a comment.
- Doc-comments on exported and non-obvious functions.

## Project log

`docs/PROJECT_LOG.md`, the project's memory of decisions and open work:

- **Decisions** table, newest first: date, decision, rationale. Superseded decisions are marked and replaced, not deleted.
- **Decisions needed**: open questions waiting on someone.
- **TODO** grouped by area. Items waiting on something are marked **on hold** and not implemented until released.
- **Done**, dated. Move finished TODOs here instead of deleting them.
- Deferred work found mid-task is added here, not left in a comment or a chat.
