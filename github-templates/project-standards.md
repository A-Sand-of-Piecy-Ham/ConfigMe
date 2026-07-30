# Project Standards

Reference guidance for setting up a professional project. Apply proportionally — a solo script doesn't need all of this, but anything with collaborators or longevity should.

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

## Versioning

- Tag releases semantically: `v<major>.<minor>.<patch>`
- Tags are immutable — never move a published tag
- For breaking changes: bump major; for new features: minor; for fixes: patch
- Maintain a `CHANGELOG.md` or use GitHub releases

## Testing standards

- New features need tests before merge
- Bug fixes need a regression test
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

## Commit hygiene

- Strip temporary comments (debug notes, `// TODO: fix this`, `// temp`) before pushing non-WIP commits — they erode signal in the codebase
- Persistent `TODO`/`FIXME` comments must reference a ticket; bare ones are noise that never gets resolved
- Squash merge PRs into main where possible — keeps history linear and each commit meaningful. Reserve merge commits for long-running branches where individual commit history has value

## Code review norms

- Reviewer approves logic and design, not just style (linters handle style)
- Author resolves all comments before merge, or explicitly defers with justification
- Small PRs get faster, better reviews — keep them focused

## Documentation

- Public APIs need doc-comments
- Non-obvious decisions need inline comments explaining *why*, not *what*
- README covers: purpose, setup, how to run tests, how to contribute
