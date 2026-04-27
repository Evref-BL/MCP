# Pharo MCP Guidance

Use the `pharo` MCP server for Pharo and Smalltalk work when the answer depends on the live image. Prefer dedicated `pharo` tools over memory or exported source files for image state.

Use dedicated tools for:
- listing repositories, packages, classes, and methods
- inspecting classes and methods
- finding implementors, senders, and selector/class/variable references
- listing, diffing, exporting, and managing Git repositories
- running tests
- triggering actions already exposed by the server

For method lookup:
- use `find_methods` with exact selector filtering for implementors
- use `filterMode: selectorReference` for senders
- use `filterMode: classReference` or `variableReference` for class or variable references

Use `evaluate` only for short one-off inspection or glue code when no dedicated `pharo` tool fits.

If a `pharo` tool fails or returns incomplete data, report that clearly instead of guessing or silently falling back.

The image is saved automatically after each tool call that can change the image state.
