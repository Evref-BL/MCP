# Pharo MCP Guidance

Use this file as a copyable root `AGENTS.md` for a Pharo project that uses MCP.
The rules below are self-contained after copying this file into another
repository.

Use the `pharo` MCP server for Pharo and Smalltalk work when the answer
depends on the live image. Prefer dedicated `pharo` tools over memory or
exported source files for image state.

Do not rely on memory for exact MCP tool names. Inspect the available `pharo`
tools exposed by the current client, then read the matching tool description
and input schema.

When catalog tools are available, discover tools by `group` or `query`, inspect
the chosen schema, then call discoverable tools through the catalog bridge when
they are not exposed directly by the client.

Use single search terms like:
- repository, repo, Iceberg, Tonel, Git, export, diff, branch, commit, pull,
  push, fetch
- load, baseline, Metacello, package
- class, inspect, superclass, subclass, slot, trait, comment
- method, selector, protocol, source, implementor, sender, reference, variable
- edit, create, update, rename, remove, rewrite, preview, apply
- test, SUnit, coverage, timeout
- history, change, entry, browse, list, apply, revert, recover
- screenshot, window, display
- debug, session, state, variable, breakpoint, capture, control, repair
- evaluate, expression

For method lookup, discover the method/reference tool from the current client.
Use exact selector filtering for implementors, sender/reference filtering for
senders, class-reference filtering for class references, and variable-reference
filtering for variable references.

Use `evaluate` only for short one-off inspection or glue code when no dedicated
`pharo` tool fits.

If a `pharo` tool fails or returns incomplete data, report that clearly instead
of guessing or silently falling back.

For debugger work, discover the `debugging` group first. Treat debug `state`,
`frame`, and `variable` references as opaque and state-scoped; after stepping,
editing, or resuming, use the newly returned state before evaluating or
expanding variables again.

For Pharo source changes:
- prefer message sends and polymorphism over class checks or reflection
- tell objects what to do instead of extracting their state into client logic
- return empty collections, null objects, or structured errors instead of
  routine `nil`
- keep methods small and give meaningful domain steps names
- keep the main send visible and lift duplicated branch-invariant sends out of
  conditionals
- guard optional or invalid values before work that depends on them, without
  treating guard order as a mechanical law
- avoid assignment inside boolean conditions
- initialize with `super initialize` and sensible defaults
- use collection protocol and streams instead of index loops and repeated
  string concatenation
- add or update SUnit tests for behavior changes

For loading Pharo projects from Tonel/Metacello repositories, use the
repo-local `pharo-project-load` skill in `skills/pharo-project-load`.

For making Pharo projects run across supported Pharo versions with
PharoCompatibility, use the repo-local `pharo-version-compat` skill in
`skills/pharo-version-compat`.

For turning image-side Pharo changes into clean Tonel/Git changes, use the
repo-local `pharo-image-git-handoff` skill in
`skills/pharo-image-git-handoff`.

For local reproduction of GitHub/smalltalkCI failures in projects that use
Pharo MCP, use the repo-local `pharo-ci-repro` skill in
`skills/pharo-ci-repro`.

The image is saved automatically after each tool call that can change image
state.
