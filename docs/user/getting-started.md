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
tool_search
tool_get
```

Then inspect the image with read-only package, class, method, and repository
tools:

```text
package_search
class_search
method_metadata_search
method_source_search
method_implementor_search
method_sender_search
class_get
method_get
```

Useful first questions:

- list packages loaded in the image
- search implementors of a selector with `method_implementor_search`
- search senders with `method_sender_search`
- get one class before editing it
- discover repository tools before exporting or committing
- discover change-history tools before recovering changes

## First Mutating Calls

Prefer dedicated tools over `image_evaluate`:

```text
class_create
method_create
method_selector_update
method_protocol_update
test_run
```

Use `tool_search` for less common class-structure changes, method reference
lookups, coverage, repository operations, and change-history recovery.

Use a copied or disposable image before asking an agent to make broad edits.
MCP saves the image after successful mutating tools, so a successful
operation changes the running image state.

## Dashboard

In a graphical image, inspect the `mcp` object and open the dashboard tab. The
dashboard shows server status, port/debug controls, registered tools, optional
observability, metrics, traces, and recent logs.

Enable observability only when you need call timing, traces, and logs for the
current image session.
