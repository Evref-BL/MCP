# Pharo MCP Agent Guide

Use the configured `pharo` MCP server whenever a task depends on the running
image. Preserve unrelated changes and report unavailable live checks instead of
guessing from source.

## Read First

- Inspect the tools and schemas exposed by the current client; do not rely on
  remembered names.
- Prefer the least-mutating dedicated tool. Use `image_evaluate` only when no
  dedicated tool fits.
- Treat image, Tonel, Iceberg, and Git state as separate.
- Successful mutating tools save the image; use a safe image boundary.

## Context Loading

- Before Pharo source changes: read the project's Pharo coding and testing
  guidance. If none exists, use the MCP
  [coding rules](https://github.com/Evref-BL/MCP/blob/main/docs/user/pharo-coding-rules.md)
  and [coding style](https://github.com/Evref-BL/MCP/blob/main/docs/user/pharo-coding-style.md).
- Before loading a project: use `skills/pharo-project-load/SKILL.md`.
- Before cross-version work: use `skills/pharo-version-compat/SKILL.md`.
- Before exporting image changes or changing Git state: use
  `skills/pharo-image-git-handoff/SKILL.md`.
- Before reproducing smalltalkCI or GitHub failures: use
  `skills/pharo-ci-repro/SKILL.md`.
- Before profiling or optimizing Pharo code: use
  `skills/pharo-code-profiling/SKILL.md`.
- Before recovering a stopped standalone image: use
  `skills/pharo-mcp-recovery/SKILL.md`.
- Before debugger sessions or repairs: read the MCP
  [debugging guide](https://github.com/Evref-BL/MCP/blob/main/docs/user/debugging.md).

## Workflow

1. Discover the exact tool and inspect the target with read-only calls.
2. Preview or verify identity before risky mutation.
3. Make the narrowest image-side change.
4. Run focused SUnit tests and inspect the result.
5. Use the handoff skill before exporting or committing Tonel changes.

For repository work, verify repository identity before mutation and inspect the
image-side diff before export or commit.
