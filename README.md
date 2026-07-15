[![Pharo version](https://img.shields.io/badge/Pharo-12%20%7C%2013%20%7C%2014-%23aac9ff.svg)](https://github.com/pharo-project/Pharo)
[![CI](https://github.com/Evref-BL/MCP/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/Evref-BL/MCP/actions/workflows/ci.yml?query=branch%3Amain+event%3Apush)
[![Coverage Status](https://coveralls.io/repos/github/Evref-BL/MCP/badge.svg?branch=main)](https://coveralls.io/github/Evref-BL/MCP?branch=main)

# MCP for Pharo

MCP is an in-image [Model Context Protocol](https://modelcontextprotocol.io/)
server for Pharo. It lets MCP clients inspect and change the running image
through Pharo-aware tools for packages, classes, methods, tests, repositories,
change history, debugging, and UI inspection.

MCP works through the Pharo ecosystem—compilation, refactorings, Renraku,
SUnit, Iceberg, Metacello, Epicea, and Spec—rather than patching exported Tonel
files as plain text.

## Supported Versions

Pharo 12, 13, and 14 are supported. Development targets Pharo 13 while CI
checks the full matrix.

## Install And Start

Load MCP in a supported image:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   load.
```

Start the Streamable HTTP server:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

Connect a local MCP client to `http://127.0.0.1:4000`. Client configuration
formats differ; see [Getting started](docs/user/getting-started.md) for setup,
first calls, and the copyable Codex template.

## Documentation

- [Documentation index](docs/README.md)
- [Getting started](docs/user/getting-started.md)
- [Using MCP from an agent](docs/user/using-pharo-mcp.md)
- [Tool reference](docs/user/tool-reference.md)
- [Safety and ecosystem integration](docs/user/safety-and-ecosystem.md)
- [Troubleshooting](docs/user/troubleshooting.md)
- [Developing MCP](docs/dev/developing-mcp.md)

## Agent Template

Copy the supplied MCP configuration, agent guide, and workflow skills into a
Pharo project:

```sh
cp -R templates/. /path/to/your/project/
```

Update `.codex/config.toml` when the image uses a port other than `4000`.

## Contributing

Use Pharo 13 for normal development and preserve Pharo 12/14 compatibility.
Live behavior must be verified in an image; source inspection alone is not
enough. Start with [AGENTS.md](AGENTS.md) and
[MCP verification](docs/dev/mcp-verification.md).
