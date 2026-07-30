---
name: project_standards
description: User's preferred project structure, PR format, branching, CI, and code review standards
metadata:
  type: reference
---

Standards live at `~/projects/dotfiles/github-templates/`. Apply proportionally to project size.

**PRs:** Always via PR once collaborators exist. Use the template (Background / Problem / Solution / Not Done / Testing / Reviewers). Scoped to one concern. Reference issue ID.

**Branches:** Protected main — no direct pushes, CI required. Branch from last stable tag. Naming: `<user>/<issue>/<description>`. Short-lived.

**CI:** Lint + typecheck + unit tests on every PR. Integration tests on merge. Set up early.

**Versioning:** Semver tags (`v<major>.<minor>.<patch>`). Tags immutable. CHANGELOG or GitHub releases.

**Testing:** New features and bug fixes require tests. Integration over mocks where feasible.

**Docs:** Doc-comments on public APIs. Inline comments explain *why*. README covers setup, test, contribute.

**How to apply:** When starting a new project or repo, suggest copying `github-templates/pull_request_template.md` to `.github/` and applying relevant standards from `project-standards.md`. Flag when a growing project would benefit from branch protection or CI setup.
