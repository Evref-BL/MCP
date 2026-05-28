# Pharo MCP Guidance

Use the `pharo` MCP server for Pharo and Smalltalk work when the answer depends on the live image. Prefer dedicated `pharo` tools over memory or exported source files for image state.

Use default static tools for common image work:
- `find_packages`, `find_classes`, and `find_methods` for image enumeration
  and search
- `inspect_class` and `inspect_method` when a class or method is already known
- `find_methods` reference modes for implementors, senders, and
  selector/class/variable references
- `edit_class` and `edit_method` for source changes
- `run_tests` for class and method test execution
- `discover_tools`, `inspect_tool`, and `call_tool` for tools outside the
  static tool surface

## Context Loading

Load the following instruction files based on your current task:

- Before designing or editing **non-trivial Smalltalk code**: read
  `docs/agents/smalltalk-practices.md`.
- When working with **debuggers, debug sessions, breakpoints, or captured
  exceptions**: read `docs/agents/debugging.md`.
- When using **debug-edit** for missing methods or stub-method repair: read
  `docs/agents/debugger-driven-development.md`.

For method lookup:
- use `find_methods` with exact selector filtering for implementors
- use `filterMode: selectorReference` for senders
- use `filterMode: classReference` or `variableReference` for class or variable references

Use `evaluate` only as an escape hatch when no dedicated or discoverable
`pharo` tool fits. Keep snippets small and explain why a tool was not enough.

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
