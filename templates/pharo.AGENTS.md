# Pharo MCP Agent Guide

Use the configured `pharo` MCP server whenever a task depends on the running
image. Preserve unrelated changes, and say which live check you could not run
rather than letting source stand in for it.

## Read First

- Inspect the tools and schemas exposed by the current client; do not rely on
  remembered names. `tool_search` finds what is not advertised, and `tool_get`
  answers one tool's schema.
- Prefer the least-mutating dedicated tool. Use `image_evaluate` only when no
  dedicated tool fits.
- Treat image, Tonel, Iceberg, and Git state as separate. None of them proves
  anything about the others.
- The image is one workspace. It has no branches and no worktrees, so two
  agents working in it at once share every edit, and one export writes both
  their changes into one diff. One writer at a time.
- Tools change the running image but never save it; use a safe image boundary.

## Context Loading

- Before Pharo source changes: read the project's Pharo coding and testing
  guidance. If none exists, use the local
  [Pharo coding](pharo-references/pharo-coding.md) reference.
- Before reading an answer closely, rewriting methods, or acting on a warning a
  call came back with: read
  [tool reference](pharo-references/tool-reference.md).
- Before loading a project: use `skills/pharo-project-load/SKILL.md`.
- Before moving code between the image and its files: use
  `skills/pharo-image-sync/SKILL.md`.
- Before reproducing smalltalkCI or GitHub failures: use
  `skills/pharo-ci-repro/SKILL.md`.
- Before profiling or optimizing Pharo code: use
  `skills/pharo-code-profiling/SKILL.md`.
- Before recovering a stopped standalone image: use
  `skills/pharo-mcp-recovery/SKILL.md`.

## Workflow

1. Discover the exact tool and inspect the target with read-only calls.
2. Preview or verify identity before risky mutation.
3. Make the narrowest image-side change.
4. Run focused SUnit tests and inspect the result.
5. Use the image-sync skill before exporting or committing Tonel changes.

For repository work, verify repository identity before mutation and inspect the
image-side diff before export or commit.
