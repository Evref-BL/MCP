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

The exporter is configured the standard way, by the `OTEL_*` variables
opentelemetry-pharo reads; see it for which. MCP's settings file gives them
when it gives any: `$XDG_CONFIG_HOME/pharo-mcp/otel.env` when
`XDG_CONFIG_HOME` is an absolute path, as Node reads one (on Windows, `C:\…`
and `C:/…` are), else `%APPDATA%\pharo-mcp\otel.env` on Windows and
`~/.config/pharo-mcp/otel.env` elsewhere. It holds `KEY=value` lines, of
which only `OTEL_*` ones count, written as a dotenv file writes them: a
leading `export`, quotes around a value, and `#` comments, on a line of their
own or after a value and a space; quotes keep a `#` in a value. The file is
read as UTF-8, or else as Latin-1, so that a byte another encoding wrote in a
comment does not cost the rest of the file. The file's
settings replace every `OTEL_*` variable the image was started with: the
program that starts an image, an agent host among them, may pass down
variables of its own, and whoever wrote the file chose where MCP's telemetry
goes. With no file, or a file that gives none, the environment decides. An
image started from a launcher's window never sees a shell's environment, so
the file is how to configure one.

To make every server of an image record so, the ones it makes later
included, evaluate once and save the image:

```smalltalk
MCP useOpenTelemetryObservabilityByDefault
```

A server made while a test runs records locally only, whatever the image's
servers record with: a test makes servers to see what they do, which is not
use, so running tests sends nothing.

Point the exporter at a collector on the same machine, OpenTelemetry's usual
deployment: the VM resolves a host name on its only thread, so a slow DNS
server holds the whole image while an export starts.

Nothing is sent while the settings do not ask for traces: the SDK disabled,
a traces exporter other than OTLP, or no setting naming where to send them,
an OTLP endpoint (`OTEL_EXPORTER_OTLP_ENDPOINT` or
`OTEL_EXPORTER_OTLP_TRACES_ENDPOINT`) or a configuration file
(`OTEL_CONFIG_FILE`). Without such a setting, with no file and an environment
that names none, no provider is made and nothing is sent, not even to the
SDK's default endpoint; the server still records its calls locally. A
backend nobody configured, made by hand rather than through
`useOpenTelemetryObservability`, records locally only. The image reads the file and its environment again each time it starts, and
rebuilds its providers from them, so a saved image sends where they say now,
or nothing once they are gone, never where they said when it was saved. While
it runs, the file's settings stay in its environment.

The providers belong to the whole image. They are rebuilt only when the
settings ask for traces or a server recorded through them, otherwise other
code's use of OpenTelemetry is left alone, and only when the settings are not
those they were made from, so that making or configuring another server leaves
them as they are. Configuring one server's recording configures every
server's that records through OpenTelemetry, so that none is left with
providers that were shut down. The providers replaced are shut down in the
background, so a collector that does not answer holds up neither the
reconfiguration nor the calls meanwhile. A call starting its span while they
are replaced waits for the replacement, and starts in the new ones. A call
already running ends in the provider that started its span, which is shut
down once the last such call has ended, and a call terminated before it
answers ends its span too, as failed. A call running when the settings stop
asking for traces sends nothing. A call running when the image is saved is
recorded by the session that saved it, once it ends there; each start of the
saved image goes on with it too, and records nothing when it ends, locally
included, since the time it took would be the time the image was not running.
A call that saves the image and quits it never ends, so nothing records it.
Stopping a server waits at most a second for what it holds to be sent.

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

## Spans

Each tool call is a server span named `tools/call <tool>`. A failed call's
span has the error status, without a description. A request whose
`params._meta` carries a W3C `traceparent` (SEP-414) makes the span a child of
the caller's, so a client that propagates its context sees the image's work
inside its own trace; the span keeps the caller's W3C `tracestate` with the
context it continues, as W3C Trace Context requires. A call made through
`tool_call` is a span of its own inside the `tool_call` span, whether or not
the server has a tool by that name.

A span has these attributes from its start:

- `mcp.method.name` `tools/call`, `gen_ai.operation.name` `execute_tool`,
  `network.transport` `tcp` and `network.protocol.name` `http`, as the
  OpenTelemetry conventions for MCP define them.
- `gen_ai.tool.name`, the tool's name; a name the server has no tool for is
  sent only when it reads as an identifier, else as `_OTHER`.
- `mcp.protocol.version`, for a request that declares its version in its
  `_meta`, as the 2026-07-28 revision does.
- `pharo.mcp.tool.origin`, whose tool the call went to: `mcp` for one of
  MCP's own, `other` for one another package registered, `unknown` for a name
  the server has no tool for.
- `pharo.mcp.dispatch_path`: `direct`, or `via_tool_call` for a call
  `tool_call` made.
- `session.id`, the session the call belongs to: the `session.id` entry of
  its W3C `baggage` when that reads as an id, else the server's own, a random
  id that starts at the server's first such call and is replaced after 30
  minutes without one, when the image starts again, so that a saved image and
  each copy of it start a session of their own, or when the clock goes back
  by a minute or more.
- `pharo.mcp.client.name` and `pharo.mcp.client.version`, which client made
  the call, as it names itself: from the `io.modelcontextprotocol/clientInfo`
  a request's `_meta` carries under the 2026-07-28 revision, else from the
  last `initialize` the server answered, since a client of an earlier
  revision says who it is only there and the server keeps no session. Only a
  name that reads as a product's, and a version that starts with a digit, are
  sent.
- `pharo.mcp.argument.names`, the names of the arguments the call was given
  that its tool declares, and `pharo.mcp.argument.unknown_names`, the others,
  all of them for a name the server has no tool for.
- `pharo.mcp.argument.options`, the options the call chose among those its
  tool's schema offers: an optional property it gave, an enumerated value
  other than the default as `side=class`, the list form of a property that
  also takes one value as `packages[]`.

And these from its end:

- `pharo.mcp.input.bytes` and `pharo.mcp.output.bytes`, the size of the
  arguments and of the answer, and `pharo.mcp.output_budget.exceeded`,
  whether the answer was larger than the server's output budget; when it was,
  the span also has the event `pharo.mcp.output_budget_exceeded`.
- `pharo.mcp.result.count` and `pharo.mcp.result.more`, for a result that
  lists entries: how many matched and whether it showed them all.
- `pharo.mcp.test.count` and `pharo.mcp.test.outcome`, for a test run: how
  many tests ran and how it ended, `passed`, `failed`, `errored` or `none`.
- `pharo.mcp.tool.refs`, for a tool search or description: the tools it named.

A failed call also has:

- `error.type`, as the conventions for MCP spell it: the JSON-RPC code of a
  protocol error, else `tool_error`.
- `pharo.mcp.error.kind`, how it failed: `input_schema` when its input schema
  refused it, `json_rpc` when a protocol error answered it, `exception` when
  any other exception escaped the tool, `domain` when the tool refused it
  with a command error or answered an error with a code, and `tool_result`
  when it answered an error without one.
- `pharo.mcp.error.code`, the code the error carries, when it carries one
  (`ToolNotFound`, `CompileSyntaxError`, ...). When the call `tool_call` made
  fails, the `tool_call` span fails too, with the code `DispatchedToolFailed`:
  the inner span says why.
- `pharo.mcp.exception.type`, the class of the exception the call raised or,
  when none escaped, the one its answer names.
- For a call its input schema refused, `pharo.mcp.error.schema.violation_count`,
  how many violations, `pharo.mcp.error.schema.keywords`, the JSON Schema
  keywords it broke, and `pharo.mcp.error.schema.paths`, where, as JSON
  pointers. A path names only what the schema declares: a missing required
  property is pointed at, not the object that misses it, while a property the
  schema does not declare is not, but the object that holds it is, the
  arguments themselves being the empty pointer.

## Metrics and logs

Each call is also counted in these metrics, with `mcp.method.name`,
`gen_ai.operation.name`, `gen_ai.tool.name`, `pharo.mcp.tool.origin` and, for
a failed call, `error.type`:

- `mcp.server.operation.duration`, a histogram of the call's duration in
  seconds.
- `pharo.mcp.tool.input.size` and `pharo.mcp.tool.output.size`, histograms of
  the size of the arguments and of the answer in bytes.
- `pharo.mcp.tool.output_budget.exceeded`, a counter of the calls whose
  answer was larger than the output budget.

The log events `mcp.session.start` and `mcp.session.end` say when a server
started and stopped recording.

## What is never sent

The attributes carry no values: argument names but not arguments, sizes but
not results, and no exception message or stack. An exception is named by its
nearest class in Pharo's own packages, those Pharo's baselines list, or in
MCP's, and a name the caller chose for an argument or a tool is sent only
when it reads as an identifier. Recording never fails
a tool call: anything that goes wrong while recording leaves out what could
not be read, and a span that started still ends.
