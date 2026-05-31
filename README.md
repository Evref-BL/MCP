[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
[![CI](https://github.com/Evref-BL/MCP/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/Evref-BL/MCP/actions/workflows/ci.yml?query=branch%3Amain+event%3Apush)
[![Coverage Status](https://coveralls.io/repos/github/Evref-BL/MCP/badge.svg?branch=main)](https://coveralls.io/github/Evref-BL/MCP?branch=main)

# MCP for Pharo Smalltalk

MCP is an in-image server for the Model Context Protocol in Pharo Smalltalk.

Load it into a Pharo image, start its HTTP server, and an MCP client can inspect and change the live image through Pharo-aware tools. The server exposes packages, classes, methods, tests, repositories, change history, screenshots, and a bounded `image_evaluate` escape hatch.

The main design point is integration with the existing Pharo ecosystem. Edits use Pharo compilation, Refactoring Browser and Refactoring Engine operations, Renraku critiques, SUnit, CoverageCollector, Iceberg, Metacello, Epicea change history, Spec dashboards, and PharoCompatibility where those systems own the behavior. MCP is not a text patcher over Tonel files; it works with the running image and returns structured MCP results.

## Supported Pharo Versions

MCP supports Pharo 12, Pharo 13, and Pharo 14. Mainline development targets the Pharo 13 API surface and uses PharoCompatibility to keep the supported range loadable and tested.

## Install

Download and open a supported [Pharo](https://pharo.org/download) image, then load MCP:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   load.
```

To use MCP as a dependency, reference the baseline from your project:

```smalltalk
spec
   baseline: 'MCP'
   with: [ spec repository: 'github://Evref-BL/MCP:main/src' ].
```

## Quick Start

Start the HTTP server from a Playground or Workspace:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

The server runs while the image runs. Stop it with:

```smalltalk
mcp stop.
```

Connect an MCP client to:

```text
http://127.0.0.1:4000
```

A generic remote MCP client entry looks like this:

```json
{
  "mcp": {
    "pharo": {
      "type": "remote",
      "url": "http://127.0.0.1:4000",
      "enabled": true
    }
  }
}
```

For Codex, copy the contents of [templates](templates) into your own project
root:

```sh
cp -R templates/. /path/to/your/project/
```

The template includes `AGENTS.md`, `.codex/config.toml`, and reusable skills
for Pharo MCP workflows. If you use a different port, update the copied
`.codex/config.toml`.

## First Tools

Start with read-only discovery:

```text
tools/list
tool_search
tool_get
package_search
class_search
method_metadata_search
method_source_search
method_equivalent_search
method_implementor_search
method_sender_search
method_class_reference_search
method_variable_reference_search
class_get
method_get
repository_search
repository_identity_verify
repository_change_list
history_file_list
history_entry_list
```

Use `tool_search` with `group=debugging` to find debugger tools and inspect
their schemas before calling them.

Then use dedicated operations before falling back to `image_evaluate`:

```text
class_create
class_name_update
class_superclass_update
class_package_update
class_comment_update
class_slots_update
class_traits_update
class_side_traits_update
class_shared_variables_update
class_shared_pools_update
class_layout_update
class_slot_add
class_slot_remove
class_slot_name_update
class_slot_pull_up
class_slot_push_down
method_create
method_selector_update
method_protocol_update
method_rewrite
test_run
repository_create
repository_attach
repository_update
repository_export
repository_commit
history_entry_apply
history_entry_revert
screenshot_capture
```

`image_evaluate` can run arbitrary Smalltalk. Use it only for short inspection or glue code when no dedicated tool fits.

## Safety Model

The server keeps raw MCP arguments at the transport boundary. Each tool owns its JSON schema, parses requests into typed request objects, dispatches command or query objects, and returns structured content with `status`, `summary`, `warnings`, and either `data` or `error`.

Image-changing tools save the image after a successful mutation. Read-only tools do not.

The safer edit paths use Pharo facilities:

- Focused `class_*` mutation tools use Refactoring Browser and Refactoring
  Engine operations for class renames, slot changes, moves, and removals where
  Pharo provides them.
- `method_selector_update` uses the Refactoring Engine for selector renames, argument additions/removals, and argument reordering.
- `method_protocol_update` recategorizes existing methods into regular or extension protocols.
- `force=false` stops on `RBRefactoringWarning` and returns `impactMessages`, `howToProceed`, and `forceSupported=true`. Rerun with `force=true` only after reviewing the impact.
- `method_create` returns selected Renraku critiques after method compilation, including error-severity critiques and selected non-error rules.
- `method_rewrite` previews AST rewrite changes first and returns a `changeSetHash`; applying the rewrite requires `expectedChangeSetHash`.
- `test_run` uses SUnit and can collect CoverageCollector method and node coverage for an explicit method scope.
- Repository tools work through Iceberg. Use `repository_identity_verify` to
  assert repository identity before edits or exports, and
  `repository_change_list` to inspect image-side changes before exporting,
  committing, pulling, or pushing. Use `repository_create`,
  `repository_attach`, and `repository_update` for repository registration
  workflows.
- Use `history_file_list` and `history_entry_list` to browse Epicea history.
  `history_entry_apply` and `history_entry_revert` preview selected entries
  and perform changes only with `confirm=true`.

This does not remove the normal responsibility of working in a safe image. Use disposable or copied images for automation and risky edits.

## Dashboard

Inspect an `MCP` instance in a graphical image and open the dashboard tab. The Spec dashboard shows server status, port and debug-mode controls, registered tools, optional observability, metrics, traces, and recent logs. The tool catalog uses the same tool metadata exposed to MCP clients.

## Documentation

- [Getting started](docs/user/getting-started.md) covers loading, starting, and connecting an MCP client.
- [Using MCP from an agent](docs/user/using-pharo-mcp.md) explains tool
  discovery, image-state rules, and reusable agent skills.
- [Safety and ecosystem integration](docs/user/safety-and-ecosystem.md) explains the refactoring, critique, test, repository, change-history, and dashboard boundaries.
- [Pharo coding rules](docs/user/pharo-coding-rules.md) explains
  object-first Smalltalk design and correctness-oriented review checks.
- [Pharo coding style](docs/user/pharo-coding-style.md) explains readability
  heuristics for expression shape, guards, temporaries, and conditions.
- [Tool reference](docs/user/tool-reference.md) lists MCP tool groups and
  their intended use.
- [Debugging with MCP](docs/user/debugging.md) explains debugger sessions,
  breakpoints, debug_state_get references, and debugger-driven repair.
- [Troubleshooting](docs/user/troubleshooting.md) maps common startup,
  connection, and image-state problems to checks.
- [Source vs live image](docs/user/source-vs-live-image.md) explains what can
  be verified from exported source and what needs a live image.

## Contributing

Use Pharo 13 as the default development image for MCP changes. Keep Pharo 12
and Pharo 14 compatibility intact, and run the supported-version matrix when a
change touches compatibility-sensitive behavior.

Agent-facing repository guidance is split by audience:

- `templates/` contains copyable agent-client guidance for people using MCP
  from their own project.
- `docs/user/` explains how to use a running Pharo MCP server from an agent or
  human client.
- `AGENTS.md` and `docs/dev/` explain how to develop this MCP repository.

## Development

CI loads the project with smalltalkCI and runs `MCP-Tests` and `MCP-Spec-Tests` on Pharo 12, 13, and 14.

Static checks from source are useful for documentation and package layout, but
tool execution must be verified in a live image. See
[MCP-Pharo verification](docs/dev/mcp-verification.md).
