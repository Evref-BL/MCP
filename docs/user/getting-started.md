# Getting Started

This page starts MCP's HTTP endpoint in an image and connects a client to it.

## Requirements

- A Pharo version the [README](../../README.md#supported-versions) supports
- An MCP client that supports Streamable HTTP directly or through a local bridge
- Network access from the client to the image host

For local use, keep the image and client on the same machine and use
`127.0.0.1`.

## Load MCP

Load MCP as the README's [Install And Start](../../README.md#install-and-start)
shows, which also says what each baseline group holds. A project whose baseline
depends on MCP declares it as [Building on MCP](building-on-mcp.md#load-the-server-alone)
shows.

## Start And Stop

```smalltalk
mcp := MCP startOnPort: 4000.
```

That answers the server already on 4000 when the image has one, starting it if
it was stopped, and makes one only when the image has none there, so running it
again after a restart is safe. Port 0 asks the operating system for a free port,
so it names no particular server and always makes a new one. Starting a second
server on a port another MCP in the image listens on fails without retrying, and
the error says how to reach it; on a port held by anything else it fails after a
couple of seconds.

Build one by hand when it needs configuring before it starts:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

Starting it on a port that is taken fails, and the error says so when the port
is held by another MCP in the same image.

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

To install the guide, references, skills and MCP configuration for an agent
host into a project, see the README's [Agent Templates](../../README.md#agent-templates).

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
method_search
method_source_search
method_reference_search
method_get
```

The specialized tools are found with `tool_search`.

Before mutation, inspect the target and use a copied or disposable image.
Prefer dedicated tools such as `class_create`, `method_compile`, refactoring
tools, and `test_run` over `evaluate`.

Continue with:

- [Test coverage](test-coverage.md)
- [Building on MCP](building-on-mcp.md)
- [Observability and UI](observability.md)

The guidance installed into a project covers the rest, and is published under
`templates/pharo-references/`:

- [Tool reference](../../templates/pharo-references/tool-reference.md)
- [Pharo coding](../../templates/pharo-references/pharo-coding.md)
