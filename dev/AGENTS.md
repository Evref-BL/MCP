# Pharo MCP Development Guidance

Use the `pharo` MCP server for Pharo and Smalltalk work when the answer
depends on the live image. Prefer dedicated `pharo` tools over memory or
exported source files for image state.

Use dedicated tools for:
- listing repositories, packages, classes, and methods
- inspecting classes and methods
- finding implementors, senders, and selector/class/variable references
- listing, diffing, and managing Git repositories
- running tests
- triggering actions already exposed by the server

For method lookup:
- use `find_methods` with exact selector filtering for implementors
- use `filterMode: selectorReference` for senders
- use `filterMode: classReference` or `variableReference` for class or variable references

Use `evaluate` only for short one-off inspection or glue code when no dedicated
`pharo` tool fits.

If a `pharo` tool fails or returns incomplete data, report that clearly instead
of guessing or silently falling back.

The image is saved automatically after each tool call that can change the image
state.

## Working On MCP Itself

The MCP tools report the state of the running image. When changing MCP, keep in
mind that disk source, Iceberg state, and loaded image state can differ.

Stay in the image for image-dependent inspection and tests. Do not export image
changes to disk just to inspect or summarize work; export only when preparing a
Git/Tonel handoff or when a concrete source workflow requires files on disk.

When compatibility behavior changes, verify against the supported Pharo
versions affected by the change. Do not assume that APIs, globals, notices, or
Metacello behavior are identical across supported Pharo versions.

For self-hosted changes, work in small steps: inspect the current implementation,
make the narrow change, run focused tests or smoke checks, then check repository
diffs before committing.
