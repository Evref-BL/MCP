# Getting Started

This is the canonical guide for loading MCP, starting its HTTP endpoint, and
connecting a client.

## Requirements

- Pharo 12, 13, or 14
- An MCP client that supports Streamable HTTP directly or through a local bridge
- Network access from the client to the image host

For local use, keep the image and client on the same machine and use
`127.0.0.1`.

## Load MCP

Evaluate in a supported image:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   load.
```

As a project dependency:

```smalltalk
spec
   baseline: 'MCP'
   with: [ spec repository: 'github://Evref-BL/MCP:main/src' ].
```

## Start And Stop

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

Inspect or control the server with:

```smalltalk
mcp localUrlString.
mcp isRunning.
mcp isListening.
mcp restart.
mcp stop.
```

The server lives in the image and stops when the image exits.

## Connect A Client

The endpoint above is:

```text
http://127.0.0.1:4000
```

Client configuration formats differ. Configure a Streamable HTTP MCP server
using the client documentation rather than copying another client's JSON.
Loopback addresses work only when the client connects from the local machine;
cloud-brokered connectors cannot reach `127.0.0.1`.

For Codex, copy the supplied configuration, agent guide, and skills into the
agent workspace:

```sh
cp -R templates/. /path/to/your/project/
```

The copied `.codex/config.toml` expects port `4000`; update its URL when the
image uses another port.

## First Calls

Start with catalog discovery:

```text
tools/list
tool_search
tool_get
```

Then inspect the image with focused read-only tools such as:

```text
package_search
class_search
class_get
method_metadata_search
method_source_search
method_implementor_search
method_sender_search
method_get
```

Before mutation, inspect the target and use a copied or disposable image.
Prefer dedicated tools such as `class_create`, `method_compile`, refactoring
tools, and `test_run` over `image_evaluate`.

Continue with:

- [Using MCP from an agent](using-pharo-mcp.md)
- [Tool reference](tool-reference.md)
- [Safety and ecosystem integration](safety-and-ecosystem.md)
- [Troubleshooting](troubleshooting.md)
