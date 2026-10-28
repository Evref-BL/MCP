# Observability And UI

The servers an image holds are listed under `Library → MCP Servers` in the
world menu, and on the `Servers` tab of an inspected `MCP` class. From there a
server can be started, stopped, or opened in its dashboard, and a new one
created on a port, where 0 asks for a free one. The tool catalog sits beside it
under `Library → MCP Tool Catalog`, since it describes the image rather than
any one server. The same list in a script:

```smalltalk
MCP allServers
```

It is taken from the heap rather than from a registry, so a server is never
kept alive for being listable, and one that is still holding a port after its
owner forgot it is shown rather than hidden.

To reach the server on a port, whether or not this script is the one that
started it, ask for the port rather than for a new server:

```smalltalk
MCP startOnPort: 4000
```

That answers the server already on 4000, starting it if it was stopped, and
makes one only when the image has none there. Starting a second server on a
taken port fails after a couple of seconds, and the error now says when the
port is held by another MCP in the same image.

An inspected `MCP` object has a dashboard tab and an observability tab. The
dashboard runs the server:

- server status, endpoint and port
- debug mode
- every tool the server could run, with `Enabled` for whether it has the tool
  at all and `Listed` for whether `tools/list` shows it; an unlisted tool is
  still found by `tool_search` and still runs

The observability tab shows what the server recorded about itself:

- per-tool timing metrics
- traces for errors, outliers, and output overruns
- recent logs
- auto-refresh while the tab is displayed

MCP starts with the built-in JSON observability backend enabled. Disable it for
a specific server when its local metrics, traces, and logs are not wanted:

```smalltalk
mcp observabilityEnabled: false
```

By default, JSON observability exports under the image-local
`pharo-local/mcp/observability` directory. Configure
`mcp observabilityExportDirectory: aDirectory` to override that export root for
instance metadata, `logs.jsonl`, `metrics.json`, and `traces.jsonl`.

OpenTelemetry support is optional. Load the `Telemetry` group, then enable
the OpenTelemetry backend for an MCP instance:

```smalltalk
Metacello new
   baseline: 'MCP';
   repository: 'github://Evref-BL/MCP:main/src';
   load: 'Telemetry'.

mcp useOpenTelemetryObservability
```
