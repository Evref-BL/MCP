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

For loading Pharo projects from Tonel/Metacello repositories, use the
repo-local `pharo-project-load` skill in `user/skills/pharo-project-load`.

For making Pharo projects run across supported Pharo versions with
PharoCompatibility, use the repo-local `pharo-version-compat` skill in
`user/skills/pharo-version-compat`.

For turning image-side Pharo changes into clean Tonel/Git changes, use the
repo-local `pharo-image-git-handoff` skill in
`user/skills/pharo-image-git-handoff`.

For local reproduction of GitHub/smalltalkCI failures in projects that use
Pharo MCP, use the repo-local `pharo-ci-repro` skill in
`user/skills/pharo-ci-repro`.

The image is saved automatically after each tool call that can change the image state.
