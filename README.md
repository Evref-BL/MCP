# MCP for Pharo

[![Pharo version](https://img.shields.io/badge/Pharo-10%20%7C%2011%20%7C%2012%20%7C%2013%20%7C%2014%20%7C%2015-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
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

Pharo 10, 11, 12, 13, 14, and 15 are supported.

Protocol revisions `2025-03-26`, `2025-06-18`, `2025-11-25` and `2026-07-28`
are supported, each answered in its own shape.

## Install And Start

Load MCP in a supported image:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:v4.x.x/src';
   onConflictUseIncoming;
   load.
```

That loads the `default` group. To choose the groups, send `load:` with their
names in place of `load`. The baseline groups are:

- `Core`: the server, its transport and schema machinery, and the catalog
  tools it dispatches through
- `IDE`: the image tools — classes, methods, packages, tests, critiques,
  repositories, change history, debugging
- `UI`: the world-menu windows and the inspector tabs
- `Telemetry`: the OpenTelemetry backend
- `Tests`: the tests of `Core` and `IDE`; `UI Tests` and `Telemetry Tests` hold
  those of `UI` and `Telemetry`
- `default`: `Core`, `IDE` and `UI`
- `all`: every group, the tests included

An image without a display has no use for `UI` and loads `#( 'Core' 'IDE' )`.
A project embedding the server and serving tools of its own loads `Core` alone,
which leaves out the image tools and everything behind them. Loading its package
is all its tools need: a tool that names itself is in the catalog.
[Building on MCP](docs/user/building-on-mcp.md) walks through
a tool, a resource and a prompt of your own, and shows how a project's baseline
depends on a release of MCP.

Start the Streamable HTTP server:

```smalltalk
MCP startOnPort: 4000.
```

[Getting started](docs/user/getting-started.md#start-and-stop) says what it
answers when the image already has a server there.

Connect a local MCP client to `http://127.0.0.1:4000`. Client configuration
formats differ; see [Getting started](docs/user/getting-started.md) for setup
and first calls.

## Documentation

- [Documentation index](docs/README.md)
- [Getting started](docs/user/getting-started.md)
- [Building on MCP](docs/user/building-on-mcp.md)
- [Observability and UI](docs/user/observability.md)
- [Tool reference](templates/pharo-references/tool-reference.md)
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

An integration that places those files itself reads them from
`templateDirectory()`, the package's `templates` directory, which holds:

- `pharo.AGENTS.md`, the guide;
- `pharo-references/<name>.md`, the references it routes to;
- `pharo-skills/<name>/SKILL.md`, the skills.

The guide routes to them as `pharo-references/<name>.md` and
`skills/<name>/SKILL.md`; an integration that installs the skills under other
paths rewrites those routes.

## Contributing

Live behavior must be verified in an image; source inspection alone is not
enough. Start with [AGENTS.md](AGENTS.md) and
[Developing MCP](docs/developing-mcp.md).
