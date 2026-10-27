# MCP for Pharo

[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014%20%7C%2015-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
[![CI](https://github.com/Evref-BL/MCP/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/Evref-BL/MCP/actions/workflows/ci.yml?query=branch%3Amain+event%3Apush)
[![Coverage Status](https://coveralls.io/repos/github/Evref-BL/MCP/badge.svg?branch=main)](https://coveralls.io/github/Evref-BL/MCP?branch=main)

MCP is an in-image [Model Context Protocol](https://modelcontextprotocol.io/)
server for Pharo. It lets MCP clients inspect and change the running image
through Pharo-aware tools for packages, classes, methods, tests, repositories,
change history, debugging, and UI inspection.

MCP works through the Pharo ecosystem—compilation, refactorings, Renraku,
SUnit, Iceberg, Metacello, Epicea, and Spec—rather than patching exported Tonel
files as plain text.

## Supported Versions

Pharo 12, 13, 14, and 15 are supported.

Protocol revisions `2025-03-26`, `2025-06-18`, `2025-11-25` and `2026-07-28`
are supported, each answered in its own shape.

## Install And Start

Load MCP in a supported image:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   onConflictUseIncoming;
   load.
```

The baseline groups are:

- `Core`: the server, its transport and schema machinery, and the catalog
  tools it dispatches through
- `IDE`: the image tools — classes, methods, packages, tests, critiques,
  repositories, change history, debugging
- `UI`: the world-menu server list
- `Telemetry`: the OpenTelemetry backend
- `default`: `Core`, `IDE`, `UI` and their tests

A project embedding the server and serving tools of its own loads `Core` alone,
which leaves out the image tools and everything behind them. Loading its package
is all its tools need: a tool that names itself is in the catalog, the way the
`pifs_` tools are in
[pharo-image-fs](https://github.com/Evref-BL/pharo-image-fs).
[Building on MCP](templates/pharo-references/building-on-mcp.md) walks through
a tool, a resource and a prompt of your own.

Start the Streamable HTTP server:

```smalltalk
MCP startOnPort: 4000.
```

That answers the server already on 4000 when the image has one, so running it
again after a restart is safe. `MCP allServers` lists what the image holds, and
`Library → MCP Servers` in the world menu shows the same list.

Connect a local MCP client to `http://127.0.0.1:4000`. Client configuration
formats differ; see [Getting started](templates/pharo-references/getting-started.md) for setup
and first calls.

## Documentation

- [Documentation index](docs/README.md)
- [Getting started](templates/pharo-references/getting-started.md)
- [Using MCP from an agent](templates/pharo-references/using-pharo-mcp.md)
- [Building on MCP](templates/pharo-references/building-on-mcp.md)
- [Tool reference](templates/pharo-references/tool-reference.md)
- [Safety and ecosystem integration](templates/pharo-references/safety-and-ecosystem.md)
- [Troubleshooting](templates/pharo-references/troubleshooting.md)
- [Developing MCP](docs/developing-mcp.md)

## Agent Templates

Install the guide, local references, workflow skills, and direct MCP
configuration for an agent host into the current project:

```sh
npx @evref-bl/pharo-mcp install --host claude
```

Use `--host codex` or `--host opencode` for those hosts. The direct MCP
configuration expects port `4000`; update it when the image uses another port.

Node integrations that provide their own MCP transport can install only the
guide, skills, references, and soft-loading instruction block:

```js
import { installGuidance } from "@evref-bl/pharo-mcp";

installGuidance({ host: "codex", cwd: process.cwd() });
```

## Contributing

Use Pharo 14 for normal development and preserve Pharo 12, 13 and 15
compatibility. Live behavior must be verified in an image; source inspection
alone is not enough. Start with [AGENTS.md](AGENTS.md) and
[MCP verification](docs/mcp-verification.md).
