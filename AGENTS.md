# Agent Guide For MCP-Pharo

This repository implements the image-side MCP server for Pharo. These rules are
for developing MCP itself; users of a released server should start with
`docs/user/getting-started.md` or install the published template package.

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
- `method_get`, `method_compile`, `class_get` and `class_create` take one
  target or a list of them in the argument that names it, and attempt every
  one.
- Use live images or externally mutating workflows only with an approved image,
  repository, and cleanup boundary.

## Context Loading

- Before MCP source, tests, schemas, packaging, or developer docs: read
  `docs/developing-mcp.md`, and `docs/mcp-verification.md` before verifying.
- Before Pharo source changes: read
  `templates/pharo-references/pharo-coding.md`.
- For a tool's own contract, ask the server with `tool_search` and `tool_get`.
- `templates/pharo-references/` holds the guidance this repository installs
  into other projects, and `templates/pharo-skills/` the workflows with their
  own triggers: project loading, image sync, CI reproduction, code profiling,
  standalone recovery. Neither says anything about this project in particular.
- That guidance and `README.md` describe behavior, not the implementation as it
  stands. Counting the classes in a group, the tools in a package or the
  entries in a page, and listing the advertised tools, all go stale without
  failing anything. Name what answers the question — the baseline group,
  `tools/list`, the tool's own contract through `tool_get` — and leave the
  number to whoever asks. A number is fine in a test whose assertion states it.

## Project Facts

- Source: `src/`; baseline: `src/BaselineOfMCP/BaselineOfMCP.class.st`.
- Supported versions: Pharo 12, 13, 14, and 15; default development image:
  Pharo 14.
- Static checks: `git diff --check` and source/package inspection.
- Live checks: baseline load, server startup, MCP calls, and image-side tests.

## Workflow

1. Load the matching context and inspect source plus approved image state.
2. Make the narrowest change and update focused tests for behavior changes.
3. Run static checks, then the relevant live checks.
4. Report changed files, checks run or skipped, and remaining risk.

Optional gitignored overrides may live in `AGENTS.local.md` or
`CLAUDE.local.md`.
