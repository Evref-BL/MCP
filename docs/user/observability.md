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

The server keeps recording locally as well: its dashboard, metrics and JSON
exports work as they do without OpenTelemetry.

The exporter is configured the standard way, through the `OTEL_*` environment
variables the image was started with; see opentelemetry-pharo for the ones it
reads. An image started from a launcher's window never sees a shell's
environment, so when the environment sets no `OTEL_*` variable, the image
reads MCP's settings file instead: `$XDG_CONFIG_HOME/pharo-mcp/otel.env`
(`~/.config/pharo-mcp/otel.env`, `%APPDATA%\pharo-mcp\otel.env` on Windows),
`KEY=value` lines of which only `OTEL_*` ones count.

To make every server of an image record so, the ones it makes later
included, evaluate once and save the image:

```smalltalk
MCP useOpenTelemetryObservabilityByDefault
```

Point the exporter at a collector on the same machine, OpenTelemetry's usual
deployment: the VM resolves a host name on its only thread, so a slow DNS
server holds the whole image while an export starts.

Nothing is sent while they do not ask for traces: no traces exporter other
than OTLP, and an OTLP endpoint (or an `OTEL_CONFIG_FILE`). The image reads
its environment again each time it starts, and rebuilds its providers from it,
so a saved image sends where its environment says now, or nothing once the
variables are gone, never where they said when it was saved. The providers
belong to the whole image, so they are rebuilt only when the environment asks
for traces or a server recorded through them; otherwise other code's use of
OpenTelemetry is left alone. Stopping a server waits at most a second for what
it holds to be sent.

Enabling it sets the image's OpenTelemetry resource, for every provider in
the image and those made later, to what describes the server: `service.name`
`pharo-mcp`, `service.version` (the version the server reports), the SDK's
`telemetry.sdk.*`, `os.type`, and `process.runtime.name` with the Pharo version
and its build (`process.runtime.version`) and the VM's
(`process.runtime.description`). `OTEL_RESOURCE_ATTRIBUTES` can add attributes
but not replace these, and `OTEL_SERVICE_NAME` is not read. The host name, the
process and its command line, which the SDK would otherwise detect and which
name the user and the image, are not sent. An attribute Pharo cannot tell is
left out, and the calls are recorded anyway; but when a provider will not take
this description, which would leave it describing the machine, nothing is
sent. A configuration file named by
`OTEL_CONFIG_FILE` that sets a resource is used as it is.

Each tool call is a server span named `tools/call <tool>`, with the attributes
the OpenTelemetry conventions for MCP define (`mcp.method.name`,
`gen_ai.tool.name`, `error.type`, ...) and MCP's own under `pharo.mcp.`. A
request whose `params._meta` carries a W3C `traceparent` (SEP-414) makes the
span a child of the caller's, so a client that propagates its context sees the
image's work inside its own trace. `session.id` is the session the call
belongs to: the `session.id` entry of its W3C `baggage` when that reads as an
id, else the server's own, a random id that starts at the server's first such
call and is replaced after 30 minutes without one. `pharo.mcp.tool.origin` says whose tool
the call went to: `mcp` for one of MCP's own, `other` for one another package
registered, `unknown` for a name the server has no tool for.

A call also reports the options it chose among those its tool's schema
offers (`pharo.mcp.argument.options`: an optional property it gave, an
enumerated value other than the default as `side=class`, the list form of a
property that also takes one value as `packages[]`). A call the input schema
refused reports the JSON Schema keywords it broke and where, as JSON pointers
(`pharo.mcp.error.schema.keywords`, `.paths`). A result that lists entries
reports how many matched and whether it showed them all
(`pharo.mcp.result.count`, `.more`); a test run, how many tests ran and how it
ended (`pharo.mcp.test.count`, `.outcome`: `passed`, `failed`, `errored`,
`none`); a tool search or description, the tools it named
(`pharo.mcp.tool.refs`).

The spans carry no values: argument names but not arguments, sizes but not
results, and no exception message or stack. An exception is named by its
nearest class in Pharo's kernel or in one of MCP's own packages, and a name
the caller chose is exported only when it reads as an identifier. Recording never fails a tool
call: anything that goes wrong while recording leaves the call unrecorded.
