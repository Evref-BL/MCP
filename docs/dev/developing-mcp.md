# Developing MCP-Pharo

Applies when changing MCP-Pharo source, tests, schemas, tools, packaging, or
developer documentation.

Read after:

- `docs/user/using-pharo-mcp.md`
- `docs/user/source-vs-live-image.md`
- `docs/user/pharo-coding-rules.md`
- `docs/user/pharo-coding-style.md`

Also read `docs/user/debugging.md` when changing debugger tools, debug-session
state, breakpoints, or debugger-driven repair behavior.

## Goal

Develop MCP as a live-image Pharo project while keeping exported source,
Iceberg state, Git state, and supported-version compatibility coherent.

## Development Surface

- Use Pharo 13 for normal day-to-day development and smoke checks.
- Keep Pharo 12 and Pharo 14 compatibility intact.
- Verify affected supported versions when changing compatibility-sensitive
  behavior, PharoCompatibility shims, baseline loading, tool contracts, or
  APIs that differ by Pharo version.

## Source And Image Model

MCP tools report the state of the running image. Tonel files are exported
source. Iceberg and Git are separate state layers.

Rules:

- Do not claim live behavior from disk-only edits.
- Do not export image changes just to inspect or summarize them.
- Export image changes when preparing a Tonel/Git handoff.
- Check repository diffs before committing or publishing source changes.
- If the image, Iceberg, and Git disagree, resolve the state deliberately
  before claiming the code is ready.

## Implementation Rules

- Follow `docs/user/pharo-coding-rules.md` for Pharo object design and
  correctness rules.
- Follow `docs/user/pharo-coding-style.md` for readability heuristics around
  expression shape, guards, temporaries, and conditions.
- Keep tool APIs explicit and testable through request, command, and result
  objects.
- Prefer dedicated query/edit command objects over broad evaluation hooks.
- Preserve structured error reporting; do not hide failures behind `nil`,
  strings, or broad exception swallowing.
- Keep schema and contract tests close to tool behavior changes.
- Keep discoverable-tool metadata current when adding or changing tool groups,
  keywords, mutability, risk, or schema-inspection expectations.
- For debugger tools, keep state references opaque and scoped to the debug
  state that returned them.
- Keep UI changes separate from core MCP tool behavior unless the task
  needs both.

## Verification

Static checks that do not require a live image:

- `git status --short --branch`
- `git diff --check`
- review of package directories under `src/`
- review of `src/BaselineOfMCP/BaselineOfMCP.class.st`
- search for affected classes and tests in exported source

Live checks require an approved safe image boundary:

- loading `BaselineOfMCP` into a clean image;
- starting `MCP` over HTTP;
- verifying MCP tool listing and specific tool calls;
- running `MCP-Tests` or `MCP-UI-Tests` in the image;
- exercising edit/export/repository operation tools;
- exercising debugger tools against a captured or attached debug session when
  debugger behavior changes.

Use `docs/dev/mcp-verification.md` for MCP-specific verification details.

## Skills Strategy

Keep always-on guidance in `AGENTS.md` and focused modules. Use skills for
repeatable workflows that have a clear trigger and multiple steps.

Reusable workflow skills under `templates/skills/` are already
workflow-oriented:

- project loading;
- supported-version compatibility;
- image-to-Git handoff;
- CI/smalltalkCI reproduction.

A generic Pharo clean-code skill can be useful if shared across repositories,
but for MCP development the coding rules and style heuristics should remain in
`docs/user/pharo-coding-rules.md` and `docs/user/pharo-coding-style.md` and be
loaded by context routing. Add a specialized skill only when a workflow needs
procedural steps, scripts, or tool-specific checks beyond ordinary reading.

## Guidance Maintenance

When updating Pharo coding rules, style heuristics, or reusable template
guidance, use `docs/dev/pharo-guidance-bibliography.md` to keep public sources
separate from operational user instructions. Do not link that bibliography from
`templates/` or require it for agents that only use MCP in another project.
