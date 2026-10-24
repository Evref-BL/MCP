# Getting Started

This is the canonical guide for loading MCP, starting its HTTP endpoint, and
connecting a client.

## Requirements

- Pharo 12, 13, 14, or 15
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

## Load Groups

The default load includes the server, optional UI, and their tests.

| Group | Contents |
| --- | --- |
| `default` | `Core`, `UI`, `Tests`, and `UI Tests` |
| `Core` | The `MCP` server package |
| `UI` | `MCP-UI` and its required core package |
| `Tests` | Core server tests and test resources |
| `UI Tests` | UI tests and their required test dependencies |
| `OpenTelemetry` | Optional OpenTelemetry backend |
| `all` | Every package, including the optional OpenTelemetry backend |

For a headless image, load only the core server:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   load: 'Core'.
```

Dependencies can select the same group with `loads: #( 'Core' )`.

## Start And Stop

```smalltalk
mcp := MCP startOnPort: 4000.
```

That answers the server already on 4000 when the image has one, rather than
failing on the port it holds. Build one by hand when it needs configuring
before it starts:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

Tool calls return canonical LLM-facing `content` by default. If a client or
integration needs programmatic payloads, configure the response fields before
starting:

```smalltalk
mcp useStructuredContentOnlyToolResponses.
mcp useContentAndStructuredContentToolResponses.
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

Install the supplied guide, local references, workflow skills, and direct MCP
configuration into the current agent project:

```sh
npx @evref-bl/pharo-mcp install --host codex
```

Use `--host claude` or `--host opencode` for those hosts. The direct MCP
configuration expects port `4000`; update it when the image uses another port.

## First Calls

Start with catalog discovery:

```text
tools/list
tool_search
tool_get
```

Then inspect the image with focused read-only tools such as:

```text
class_search
class_get
method_search
method_source_search
method_reference_search
method_get
```

`package_search` and the specialized tools are found with `tool_search`.

Before mutation, inspect the target and use a copied or disposable image.
Prefer dedicated tools such as `class_create`, `method_compile`, refactoring
tools, and `test_run` over `image_evaluate`.

Continue with:

- [Using MCP from an agent](using-pharo-mcp.md)
- [Tool reference](tool-reference.md)
- [Safety and ecosystem integration](safety-and-ecosystem.md)
- [Troubleshooting](troubleshooting.md)
