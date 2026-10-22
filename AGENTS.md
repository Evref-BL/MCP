# Agent Guide For MCP-Pharo

This repository implements the image-side MCP server for Pharo. These rules are
for developing MCP itself; users of a released server should start with
`templates/pharo-references/using-pharo-mcp.md` or install the published
template package.

## Read First

- Preserve unrelated local changes.
- Image, Tonel, Iceberg and Git are separate states. Do not infer live-image
  behavior from Tonel source alone.
- Prefer dedicated Pharo MCP tools over `image_evaluate`, and find them with
  `tool_search`.
- No tool saves the image. A change lives in the running image until someone
  saves it, so closing the image discards it and a mistake costs the session.
- A notification does not fail a call: the tool boundary resumes it. A
  refactoring warning is the exception and stops an unforced mutation.
- Method source in the image separates lines with CR. `method_compile`
  normalizes it; a bare `compile:` does not.
- Use live images or externally mutating workflows only with an approved image,
  repository, and cleanup boundary.

## Context Loading

- Before MCP source, tests, schemas, packaging, or developer docs: read
  `docs/developing-mcp.md`, and `docs/mcp-verification.md` before verifying.
- Before Pharo source changes: read
  `templates/pharo-references/pharo-coding-rules.md` and
  `templates/pharo-references/pharo-coding-style.md`.
- Before debugger work: read `templates/pharo-references/debugging.md`; for
  repair flows also read
  `templates/pharo-references/debugger-driven-development.md`.
- For a tool's own contract, ask the server with `tool_search` and `tool_get`.
- `templates/pharo-references/` holds the user-facing guidance this repository
  ships, and `templates/pharo-skills/` the workflows with their own triggers:
  project loading, version compatibility, image-to-Git handoff, CI reproduction.

## Project Facts

- Source: `src/`; baseline: `src/BaselineOfMCP/BaselineOfMCP.class.st`.
- Supported versions: Pharo 12, 13, and 14; default development image: Pharo 14.
- Static checks: `git diff --check` and source/package inspection.
- Live checks: baseline load, server startup, MCP calls, and image-side tests.

## Workflow

1. Load the matching context and inspect source plus approved image state.
2. Make the narrowest change and update focused tests for behavior changes.
3. Run static checks, then the relevant live checks.
4. Report changed files, checks run or skipped, and remaining risk.

Optional gitignored overrides may live in `AGENTS.local.md` or
`CLAUDE.local.md`.
