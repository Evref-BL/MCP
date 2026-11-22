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

[Getting started](getting-started.md#start-and-stop) says what it answers.

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

OpenTelemetry support is optional. Load the `Telemetry` group, as the README's
[Install And Start](../../README.md#install-and-start) says, then enable the
OpenTelemetry backend for an MCP instance:

```smalltalk
mcp useOpenTelemetryObservability
```

The exporter is configured the standard way, through the `OTEL_*` environment
variables the image was started with; see opentelemetry-pharo for the ones it
reads.

Nothing is recorded while they do not ask for traces: no traces exporter other
than OTLP, and an OTLP endpoint (or an `OTEL_CONFIG_FILE`). The image reads
its environment again each time it starts, and rebuilds its providers from it,
so a saved image sends where its environment says now, or nothing once the
variables are gone, never where they said when it was saved.

Enabling it sets the image's OpenTelemetry resource, for every provider in
the image and those made later, to what describes the server: `service.name`
`pharo-mcp`, `service.version` (the version the server reports), the SDK's
`telemetry.sdk.*`, `os.type`, and `process.runtime.name` with the Pharo version
and its build (`process.runtime.version`) and the VM's
(`process.runtime.description`). `OTEL_RESOURCE_ATTRIBUTES` can add attributes
but not replace these, and `OTEL_SERVICE_NAME` is not read. The host name, the
process and its command line, which the SDK would otherwise detect and which
name the user and the image, are not sent. An attribute Pharo cannot tell is
left out, and the calls are recorded anyway. A configuration file named by
`OTEL_CONFIG_FILE` that sets a resource is used as it is.

Each tool call is a server span named `tools/call <tool>`, with the attributes
the OpenTelemetry conventions for MCP define (`mcp.method.name`,
`gen_ai.tool.name`, `error.type`, ...) and MCP's own under `pharo.mcp.`. A
request whose `params._meta` carries a W3C `traceparent` (SEP-414) makes the
span a child of the caller's, so a client that propagates its context sees the
image's work inside its own trace.

The spans carry no values: argument names but not arguments, sizes but not
results, and no exception message or stack. An exception is named by its
nearest class in Pharo's kernel or in MCP, and a name the caller chose is
exported only when it reads as an identifier. Recording never fails a tool
call: anything that goes wrong while recording leaves the call unrecorded.
