# Pharo MCP Agent Guide

Use the `pharo` MCP server whenever a task depends on the running image.
Preserve unrelated changes, and say which live check you could not run rather
than letting source stand in for it.

## Read First

- Look tools up rather than recall them: `tool_search` finds what the image
  does not advertise, `tool_get` gives a tool's schema.
- Prefer the least-mutating dedicated tool; `image_evaluate` only when none
  fits.
- Image, Tonel, Iceberg and Git are separate states; none proves anything
  about another.
- An image takes one writer: it has no branches, so two agents in it share
  every edit.
- Tools never save the image.
- The user may commit through Iceberg unseen: ask the image and the checkout
  before calling any work uncommitted.

## Context Loading

- Changing Pharo code: the project's coding guidance, or else
  [Pharo coding](pharo-references/pharo-coding.md).
- Reading an answer closely, rewriting methods, or acting on a warning:
  [tool reference](pharo-references/tool-reference.md).
- Loading a project: `skills/pharo-project-load/SKILL.md`.
- Moving code between the image and its files, or saying what is committed:
  `skills/pharo-image-sync/SKILL.md`.
- Reproducing smalltalkCI or GitHub failures: `skills/pharo-ci-repro/SKILL.md`.
- Profiling: `skills/pharo-code-profiling/SKILL.md`.
- Recovering a stopped standalone image: `skills/pharo-mcp-recovery/SKILL.md`.

## Workflow

1. Inspect with read-only calls.
2. Verify identity before a risky change.
3. Make the narrowest change in the image.
4. Run focused tests.
5. Use the image-sync skill before exporting or committing.
