# Agent Guide For MCP-Pharo

This repository implements the image-side Model Context Protocol server for
Pharo. This file is for agents developing this repository, not for agents only
using a released MCP server from another workspace.

## Read First

- Preserve unrelated local changes.
- Do not claim live-image behavior is verified from Tonel/source inspection
  alone.
- Prefer dedicated `pharo` MCP tools over `image_evaluate` when a tool exists.
- Do not launch or mutate live images, run image-local repository mutation
  tools, or trigger externally mutating workflows unless the current task has
  an approved safe image and cleanup boundary.

## Context Loading

- Apply every matching route; read matching `docs/user/` guidance before
  MCP-specific `docs/dev/` guidance.
- Before using a running Pharo MCP server or MCP tools: read
  `docs/user/using-pharo-mcp.md`.
- Before MCP source, test, schema, package, or developer-doc changes: read
  `docs/dev/developing-mcp.md`.
- Before Pharo/Smalltalk source changes in this repository: read
  `docs/user/pharo-coding-rules.md` and
  `docs/user/pharo-coding-style.md`.
- Before reasoning about source files vs loaded image state: read
  `docs/user/source-vs-live-image.md`.
- Before debugger tool, debug-session, breakpoint, or debugger-driven repair
  work: read `docs/user/debugging.md`. For `debug_method_repair` repair flows, also
  read `docs/user/debugger-driven-development.md`.
- Before verifying MCP repository changes: read `docs/dev/mcp-verification.md`.
- Before project loading work: use
  `templates/skills/pharo-project-load/SKILL.md`.
- Before compatibility work: use
  `templates/skills/pharo-version-compat/SKILL.md`.
- Before CI reproduction work: use
  `templates/skills/pharo-ci-repro/SKILL.md`.
- Before image-to-Git handoff work: use
  `templates/skills/pharo-image-git-handoff/SKILL.md`.

User-facing guidance for agents that only use MCP lives in
`docs/user/using-pharo-mcp.md` and `templates/AGENTS.md`; do not make the
root repository guide a general user manual.

## Project Facts

- Source root: `src/`.
- Baseline: `src/BaselineOfMCP/BaselineOfMCP.class.st`.
- Main packages: `MCP`, `MCP-Tests`, `MCP-Spec`, and `MCP-Spec-Tests`.
- Supported Pharo versions: Pharo 12, Pharo 13, and Pharo 14.
- Default development surface: Pharo 13 unless the task targets
  compatibility.
- Static verification: `git diff --check` and source/package inspection.
- Live verification for MCP itself: baseline load, MCP server startup, MCP
  tool calls, and image-side test execution in an approved safe image.

## Workflow

1. Load the development context above.
2. Inspect current source and, when approved, current image state.
3. Make the narrowest change that solves the task.
4. Add or update focused tests when behavior changes.
5. Run static checks first.
6. Run live image checks only when the task has an approved safe image
   boundary.
7. Report files changed, checks run, checks skipped, and remaining risk.

## Local Overrides

- Optional personal instructions may live in `AGENTS.local.md` or
  `CLAUDE.local.md`.
- Local overrides are gitignored and must not be required by shared workflows.
