# Developing MCP-Pharo

Applies when changing MCP-Pharo source, tests, schemas, tools, packaging, or
developer documentation.

Read after:

- `templates/pharo.AGENTS.md`
- `templates/pharo-references/tool-reference.md`
- `templates/pharo-references/pharo-coding.md`

## Goal

Develop MCP as a live-image Pharo project while keeping exported source,
Iceberg state, Git state, and supported-version compatibility coherent.

## Development Surface

- Use Pharo 14 for normal day-to-day development and smoke checks.
- Keep Pharo 12, 13 and 15 compatibility intact.
- Verify affected supported versions when changing compatibility-sensitive
  behavior, PharoBackwardCompatibility backports, baseline loading, tool contracts, or
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

- Follow `templates/pharo-references/pharo-coding.md` for what is particular to
  Pharo, and the critiques a compile reports for the rest.
- Keep tool APIs explicit and testable through request, command, and result
  objects.
- Prefer dedicated query/edit command objects over broad evaluation hooks.
- Preserve structured error reporting; do not hide failures behind `nil`,
  strings, or broad exception swallowing.
- Keep schema and contract tests close to tool behavior changes.
- Keep discoverable-tool metadata current when adding or changing tool groups,
  keywords, standard tool annotations, or schema-inspection expectations.
- When changing tool registration or exposure, keep the distinction between the
  registry source of truth and MCP's cached `tools/list` surface explicit.
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

Use `docs/mcp-verification.md` for MCP-specific verification details.

## Skills Strategy

Keep always-on guidance in `AGENTS.md` and focused modules. Use skills for
repeatable workflows that have a clear trigger and multiple steps.

Reusable workflow skills under `templates/pharo-skills/` are already
workflow-oriented:

- project loading;
- image-to-Git handoff;
- CI/smalltalkCI reproduction;
- code profiling and performance optimization.

A generic Pharo clean-code skill can be useful if shared across repositories,
but for MCP development the Pharo coding guidance should remain in
`templates/pharo-references/pharo-coding.md` and be loaded by context
routing. Add a specialized skill only when a workflow needs
procedural steps, scripts, or tool-specific checks beyond ordinary reading.

## Guidance Maintenance

When updating Pharo coding rules, style heuristics, or reusable template
guidance, use `docs/pharo-guidance-bibliography.md` to keep public sources
separate from operational user instructions. Do not link that bibliography from
`templates/` or require it for agents that only use MCP in another project.

## Version Compatibility

The core baseline loads PharoBackwardCompatibility, JRPC, and PCRE2.
OpenTelemetry is loaded only by the optional `Telemetry` group. CI covers
Pharo 12, 13, 14, and 15. Code should target the Pharo 14 API;
PharoBackwardCompatibility backports supported APIs to older images. It has no
surface groups, so its default baseline is the whole of it:

```smalltalk
spec
   baseline: 'PharoBackwardCompatibility'
   with: [ spec repository: 'github://jecisc/PharoBackwardCompatibility:v1.x.x/src' ]
```

A difference it does not cover belongs in a package the baseline loads only
where it applies, the way `MCP-Compatibility-From13` is loaded when
`SystemVersion current major >= 13`. Offer a general difference upstream
instead of keeping it local, and verify on every version in the matrix: a shim
that loads is not a shim that works.
