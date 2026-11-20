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
- Keep Pharo 10, 11, 12, 13 and 15 compatibility intact.
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
- A tool is one class. Its input schema declares each argument once, with its
  default and limits, and `executeWithRequest:` reads the arguments from the
  `MCPToolRequest` it receives. `argumentOrDefaultNamed:`,
  `stringArgumentOrDefaultNamed:` and the typed accessors built on them answer
  the schema's default; the other accessors answer only what the caller
  supplied, for code that must know whether an argument was given.
- Work on the image goes in an operation object when it is long, has tests of
  its own, or several tools use it. It takes plain arguments, answers image
  objects or a report, and knows nothing of the tool, the request or the
  answer's text.
- Describe image objects with the shared describers (the `*Info` classes). A
  result class exists only when it computes something.
- Prefer dedicated tools and operations over broad evaluation hooks.
- Preserve structured error reporting; do not hide failures behind `nil`,
  strings, or broad exception swallowing.
- Keep schema and contract tests close to tool behavior changes.
- Keep discoverable-tool metadata current when adding or changing tool groups,
  keywords, standard tool annotations, or schema-inspection expectations.
- When changing tool registration or exposure, keep the distinction between the
  registry source of truth and MCP's cached `tools/list` surface explicit.
- Keep UI changes separate from core MCP tool behavior unless the task
  needs both.

## Verification

Static checks that do not require a live image:

- `git status --short --branch`
- `git diff --check`
- review of package directories under `src/`
- review of `src/BaselineOfMCP/BaselineOfMCP.class.st`
- search for affected classes and tests in exported source

They show that the exported source and the package declarations agree. They
cannot show that the image loaded the code, that the server starts, or that a
tool works.

Live checks require an approved safe image boundary:

- loading `BaselineOfMCP`'s `all` group, which holds the tests, into a clean
  image;
- starting `MCP` over HTTP;
- verifying MCP tool listing and specific tool calls;
- running the test packages `.smalltalk.ston` lists under `#testing`;
- exercising edit/export/repository operation tools;
- `debug_search` and `debug_watch` calls when debugger behavior changes.

When the work is not approved to launch or change a live image, stop at the
static checks, say the verification is static only, and name the live checks
left undone. When live checks run, report the image version, the checkout or
repository loaded, the calls or test packages run, the result, and the cleanup
done.

## Skills Strategy

Add a skill under `templates/pharo-skills/` only for a workflow with a clear
trigger and procedural steps.

## Guidance Maintenance

The public sources behind the Pharo guidance are in
`docs/pharo-guidance-bibliography.md`.

## Version Compatibility

The `Core` group loads PharoBackwardCompatibility and JRPC, `IDE` adds PCRE2,
and OpenTelemetry is loaded only by the optional `Telemetry` group. Code should
target the Pharo 14 API; PharoBackwardCompatibility backports supported APIs to
older images. It has no surface groups, so its default baseline is the whole of
it:

```smalltalk
spec
   baseline: 'PharoBackwardCompatibility'
   with: [ spec repository: 'github://jecisc/PharoBackwardCompatibility:v1.x.x/src' ]
```

A difference it does not cover belongs in a package the baseline loads only
where it applies, the way `MCP-IDE-Compatibility-From13` is loaded when
`SystemVersion current major >= 13`. Code written against a newer Pharo stays
as it is: what an older version needs another body for is a method of its own,
which a `From` package holds as written and its `Before` counterpart answers
for the older versions under the same selector, as `MCP-Compatibility-From12`
and `MCP-Compatibility-Before12` do, and `MCP-IDE-Compatibility-From12` and
`MCP-IDE-Compatibility-Before12` for MCP-IDE. Offer a general difference upstream
instead of keeping it local, and verify on every version in the matrix: a shim
that loads is not a shim that works.
