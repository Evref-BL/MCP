# Agent Guide For MCP-Pharo

This repository implements the image-side MCP server for Pharo. These rules are
for developing MCP itself; users of a released server should start with
`docs/user/using-pharo-mcp.md` or copy `templates/`.

## Read First

- Preserve unrelated local changes.
- Do not infer live-image behavior from Tonel source alone.
- Prefer dedicated Pharo MCP tools over `image_evaluate`.
- Use live images or externally mutating workflows only with an approved image,
  repository, and cleanup boundary.

## Context Loading

Apply every matching route, reading user guidance before developer guidance.

- Before using Pharo MCP tools: read `docs/user/using-pharo-mcp.md`.
- Before MCP source, tests, schemas, packaging, or developer docs: read
  `docs/dev/developing-mcp.md`.
- Before Pharo source changes: also read `docs/user/pharo-coding-rules.md` and
  `docs/user/pharo-coding-style.md`.
- Before reasoning across image, Iceberg, Tonel, or Git: read
  `docs/user/source-vs-live-image.md`.
- Before debugger work: read `docs/user/debugging.md`; for repair flows also
  read `docs/user/debugger-driven-development.md`.
- Before verifying MCP changes: read `docs/dev/mcp-verification.md`.
- Before image-to-Git handoff: use
  `templates/skills/pharo-image-git-handoff/SKILL.md`.
- For project loading, compatibility, CI reproduction, or code profiling, use
  the matching skill under `templates/skills/`.

## Project Facts

- Source: `src/`; baseline: `src/BaselineOfMCP/BaselineOfMCP.class.st`.
- Supported versions: Pharo 12, 13, and 14; default development image: Pharo 13.
- Static checks: `git diff --check` and source/package inspection.
- Live checks: baseline load, server startup, MCP calls, and image-side tests.

## Workflow

1. Load the matching context and inspect source plus approved image state.
2. Make the narrowest change and update focused tests for behavior changes.
3. Run static checks, then the relevant live checks.
4. Report changed files, checks run or skipped, and remaining risk.

Optional gitignored overrides may live in `AGENTS.local.md` or
`CLAUDE.local.md`.
