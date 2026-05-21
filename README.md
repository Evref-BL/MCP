[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
![Build Info](https://github.com/Evref-BL/MCP/workflows/CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Evref-BL/MCP/badge.svg?branch=main)](https://coveralls.io/github/Evref-BL/MCP?branch=main)

# MCP for Pharo Smalltalk

MCP is an in-image server for the Model Context Protocol in Pharo Smalltalk.

Load it into a Pharo image, start its HTTP server, and an MCP client can inspect and change the live image through Pharo-aware tools. The server exposes packages, classes, methods, tests, repositories, change history, screenshots, and a bounded `evaluate` escape hatch.

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

For Codex, copy [user/codex/.codex](user/codex/.codex) into your agent workspace as `.codex`, and copy [user/AGENTS.md](user/AGENTS.md) as `AGENTS.md`. If you use a different port, update `.codex/config.toml`.

## First Tools

Start with read-only discovery:

```text
tools/list
find-packages
find-classes
find-methods
inspect-class
inspect-method
find-repositories
```

Then use dedicated operations before falling back to `evaluate`:

```text
edit-class
edit-method
rewrite-methods
run-tests
edit-repository
manage-change-history
capture-screenshot
```

`evaluate` can run arbitrary Smalltalk. Use it only for short inspection or glue code when no dedicated tool fits.

## Safety Model

The server keeps raw MCP arguments at the transport boundary. Each tool owns its JSON schema, parses requests into typed request objects, dispatches command or query objects, and returns structured content with `status`, `summary`, `warnings`, and either `data` or `error`.

Image-changing tools save the image after a successful mutation. Read-only tools do not.

The safer edit paths use Pharo facilities:

- `edit-class` and `edit-method` use Refactoring Browser and Refactoring Engine operations for renames, slot changes, argument changes, moves, and removals where Pharo provides them.
- `force=false` stops on `RBRefactoringWarning` and returns `impactMessages`, `howToProceed`, and `forceSupported=true`. Rerun with `force=true` only after reviewing the impact.
- `edit-method` returns selected Renraku critiques after method compilation, including error-severity critiques and selected non-error rules.
- `rewrite-methods` previews AST rewrite changes first and returns a `changeSetHash`; applying the rewrite requires `expectedChangeSetHash`.
- `run-tests` uses SUnit and can collect CoverageCollector method and node coverage for an explicit method scope.
- `edit-repository` works through Iceberg. Use `diff` to inspect image-side repository changes before exporting, committing, pulling, or pushing.
- `manage-change-history` previews Epicea apply/revert operations and performs them only with `confirm=true`.

This does not remove the normal responsibility of working in a safe image. Use disposable or copied images for automation and risky edits.

## Dashboard

Inspect an `MCP` instance in a graphical image and open the dashboard tab. The Spec dashboard shows server status, port and debug-mode controls, registered tools, optional observability, metrics, traces, and recent logs. The tool catalog uses the same tool metadata exposed to MCP clients.

## Documentation

- [Getting started](docs/user/getting-started.md) covers loading, starting, and connecting an MCP client.
- [Safety and ecosystem integration](docs/user/safety-and-ecosystem.md) explains the refactoring, critique, test, repository, change-history, and dashboard boundaries.
- [Tool reference](docs/reference/tools.md) lists the MCP tool groups and their intended use.
- [Troubleshooting](docs/troubleshooting.md) maps common startup, connection, and image-state problems to checks.
- [Source vs live image checks](docs/dev/source-vs-live-image-checks.md) explains what can be verified from exported source and what needs a live image.

## Development

CI loads the project with smalltalkCI and runs `MCP-Tests` and `MCP-Spec-Tests` on Pharo 12, 13, and 14.

Static checks from source are useful for documentation and package layout, but tool execution must be verified in a live image. See [Source vs live image checks](docs/dev/source-vs-live-image-checks.md).
