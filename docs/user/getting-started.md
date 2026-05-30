# Getting Started

This guide loads MCP into a Pharo image, starts the HTTP endpoint, and
connects an MCP client.

## Requirements

- Pharo 12, Pharo 13, or Pharo 14
- Network access from the MCP client to the image host
- An MCP client that supports remote HTTP MCP servers

For local use, run the image and the client on the same machine and bind to
`127.0.0.1`.

## Load MCP

Open a supported Pharo image and evaluate:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   load.
```

To load only the core packages from a baseline dependency:

```smalltalk
spec
   baseline: 'MCP'
   with: [ spec repository: 'github://Evref-BL/MCP:main/src' ].
```

## Start The Server

Evaluate:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

Check the endpoint:

```smalltalk
mcp localUrlString.
mcp isRunning.
mcp isListening.
```

Stop or restart it:

```smalltalk
mcp stop.
mcp restart.
```

The server lives in the image. If the image quits, the MCP server stops too.

## Connect A Client

Use the image endpoint:

```text
http://127.0.0.1:4000
```

A generic remote MCP configuration looks like this:

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

For Codex, copy the supplied support files into the agent workspace:

```sh
cp -R templates/. /path/to/your/project/
```

The template includes `AGENTS.md`, `.codex/config.toml`, and reusable skills.

The supplied Codex config expects port `4000`:

```toml
[mcp_servers.pharo]
enabled = true
required = true
url = "http://127.0.0.1:4000"
```

If you started the server on another port, update the URL.

## First Read-Only Calls

Ask the client to list tools first. In clients that expose the discoverable
catalog, start with tool discovery and schema inspection:

```text
tools/list
discover-tools
inspect-tool
```

Then inspect the image with read-only package, class, method, and repository
tools:

```text
find-packages
find-classes
find-methods
find-method-implementors
find-method-senders
find-class-references
find-variable-references
inspect-class
inspect-method
find-repositories
```

Useful first questions:

- list packages loaded in the image
- find implementors of a selector with `find-method-implementors`
- find senders with `find-method-senders`
- inspect one class before editing it
- inspect repository status before exporting or committing

## First Mutating Calls

Prefer dedicated tools over `evaluate`:

```text
edit-class
edit-method
rewrite-methods
run-tests
edit-repository
manage-change-history
```

Use a copied or disposable image before asking an agent to make broad edits.
MCP saves the image after successful mutating tools, so a successful
operation changes the running image state.

## Dashboard

In a graphical image, inspect the `mcp` object and open the dashboard tab. The
dashboard shows server status, port/debug controls, registered tools, optional
observability, metrics, traces, and recent logs.

Enable observability only when you need call timing, traces, and logs for the
current image session.
