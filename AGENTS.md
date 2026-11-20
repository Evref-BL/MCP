# Agent Guide For MCP-Pharo

This repository implements the image-side MCP server for Pharo. These rules are
for developing MCP itself; users of a released server should start with
`docs/user/getting-started.md` or install the published template package.

## Read First

- Preserve unrelated local changes.
- Image, Tonel, Iceberg and Git are separate states. Do not infer live-image
  behavior from Tonel source alone.
- Prefer dedicated Pharo MCP tools over `evaluate`, and find them with
  `tool_search`.
- Use live images or externally mutating workflows only with an approved image,
  repository, and cleanup boundary.

## Context Loading

- Before MCP source, tests, schemas, packaging, developer docs, or
  verification: read `docs/developing-mcp.md`.
- Before Pharo source changes: read
  `templates/pharo-references/pharo-coding.md`.
- Before calling the tools: read `templates/pharo-references/tool-reference.md`,
  which says how they answer and what they do when a call is not simply a
  success.
- For a tool's own contract, ask the server with `tool_search` and `tool_get`.
- `templates/pharo-references/` holds the guidance this repository installs
  into other projects, and `templates/pharo-skills/` the workflows with their
  own triggers. Neither says anything about this project in particular.
- That guidance and `README.md` describe behavior, not the implementation as it
  stands. Counting the classes in a group, the tools in a package or the
  entries in a page, and listing the advertised tools, all go stale without
  failing anything. Name what answers the question — the baseline group,
  `tools/list`, the tool's own contract through `tool_get` — and leave the
  number to whoever asks. A number is fine in a test whose assertion states it.

## Project Facts

- Source: `src/`; baseline: `src/BaselineOfMCP/BaselineOfMCP.class.st`.
- Supported versions and the checks to run: `docs/developing-mcp.md`.

## Workflow

1. Load the matching context and inspect source plus approved image state.
2. Make the narrowest change and update focused tests for behavior changes.
3. Run static checks, then the relevant live checks.
4. Report changed files, checks run or skipped, and remaining risk.

Optional gitignored overrides may live in `AGENTS.local.md` or
`CLAUDE.local.md`.
