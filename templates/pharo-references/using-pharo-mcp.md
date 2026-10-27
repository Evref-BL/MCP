# Using The Pharo MCP Server

Applies when an agent or user interacts with a running Pharo image through MCP.
Follow [Getting started](getting-started.md) to load, start, and connect first.

## Source Of Truth

Use the running image for live classes, methods, packages, repositories, and
tests. Tonel source, Iceberg, and Git are separate state layers; read
[Source files vs live image state](source-vs-live-image.md) before reasoning
across them.

If image access is unavailable, state which live check is blocked instead of
guessing from source or memory.

## Discover Before Calling

- Inspect the tools exposed by the current client; do not rely on remembered
  names or schemas.
- Use `tool_search`, then `tool_get`, for less common tools. Call one by name
  like any other, or through `tool_call` when the client will only send a name
  its own list holds.
- Prefer the least-mutating dedicated tool. Use `image_evaluate` only when no
  dedicated tool fits.
- Start list/search calls with the default page or a small `limit`. Continue
  only when the result contains `nextOffset`.

See [Tool reference](tool-reference.md) for tool groups and common workflows.

## Choose Specialized Lookups

Use `method_search` for metadata, `method_source_search` for source,
`method_equivalent_search` for equivalent ASTs, and the implementor, sender,
class-reference, or variable-reference search matching the question.

For repository work, inspect with `repository_search`, verify identity before
mutation, and inspect `repository_change_list` before export or commit. Read
[Safety and ecosystem integration](safety-and-ecosystem.md) for mutation
boundaries.

`method_get` and `class_get` read several targets in one call when their
`selector` or `name` holds a list, and `method_compile` and `class_create`
write several the same way. See [Tool reference](tool-reference.md).

For history recovery, inspect files and entries before applying or reverting.
For watching values, debugger sessions, or repairs, read the installed local
debugging guide.

## Image Mutation

Mutating tools change the running image and never save it, so closing the image
discards everything since its last save. Saving is the caller's responsibility:
evaluate `Smalltalk saveSession` when a change should survive, or leave it to
whoever owns the image lifecycle. Use a copied or disposable image for broad or
risky edits, preview changes when the tool supports it, and run focused tests
after source changes.

Report incomplete or failing tool results clearly. Never silently fall back to
exported source for a question about the live image.

## Failures And Notifications

A notification is not a failure. Pharo signals them for remarks rather than
faults, and every `Warning` is one, so a deprecated send or an undeclared
variable during a load is resumed and the call proceeds. A refactoring warning
is the exception: it reports a change that breaks something, so it stops the
call until you rerun with `force=true`.

A failed call reports the error class, the message and the frames of the failing
code; the server's own frames are left out. For `image_evaluate` a compilation
failure also names the line and shows it, and a `MessageNotUnderstood` suggests
selectors the receiver does understand.

## Reusable Workflows

Run `npx @evref-bl/pharo-mcp install --host <host>` in the target project to
install context-routed skills for project loading, version compatibility,
image-to-Git handoff, CI reproduction, and standalone MCP recovery.

## Custom Tools

Define custom tools as subclasses of `MCPTool` in your own package. At minimum,
provide the class-side tool name and the instance-side metadata, schema, and
execution protocol expected by `MCPTool`:

```smalltalk
MCPTool << #MyProjectMCPTool
	slots: {};
	package: 'MyProject-MCP'
```

```smalltalk
MyProjectMCPTool class >> toolName

	^ 'my_project_tool'

MyProjectMCPTool >> description

	^ 'Do one project-specific operation.'

MyProjectMCPTool >> buildInputSchema

	^ MCPStructureInputSchema new
		type: 'object';
		properties: #(  );
		required: #(  );
		additionalProperties: false;
		yourself

MyProjectMCPTool >> executeWithRequest: request

	^ self
		successResultText: 'Operation completed.'
		data: Dictionary new
```

A tool is served because its package is loaded: name your tool and every
server in the image has it, wherever the class lives. A tool that must stay
out of every catalog says so itself:

```smalltalk
MyProjectMCPTool class >> shouldAutoRegister

	^ false
```

It is the tool's own name that serves it, not an inherited one, so
specialising an existing tool does not claim the name it already holds.

Tools from other packages are discoverable rather than advertised. Agents
find them with `tool_search`, inspect them with `tool_get`, and call them by
name.

`MCPToolRegistry` is the server's source of truth for registered tools. In
normal use, configure it through the `MCP` instance messages below. The
`tools/list` response contains only the static tool surface cached by the MCP
instance; discoverable tools remain callable, and are found with `tool_search`
and `tool_get`.

Two words govern the surface. A **registered** tool is in the catalog, found
with `tool_search` and `tool_get`, and callable. An **advertised** tool is also
in `tools/list`. Advertising decides what a client is shown, not what it may
call.

For a server with only your own tools:

```smalltalk
mcp := MCP onlyTools: { MyProjectMCPTool }.
mcp start.
```

`onlyTools:` replaces the catalog with exactly those tools and advertises all of
them. Advertise a subset when some registered tools should stay discoverable
through the catalog tools instead:

```smalltalk
mcp := MCP onlyTools: { MyProjectMCPTool. MyOtherMCPTool }.
mcp advertiseTools: { MyProjectMCPTool }.
```

To add to the tools a server already has, rather than replacing them:

```smalltalk
mcp := MCP new.
mcp addTool: MyProjectMCPTool.
mcp start.
```

`addTool:` takes a class or a ready instance, and `addTools:` takes several.
`removeTool:` takes one back out by name. `advertiseTools:` accepts classes,
instances or names, and registers anything not in the catalog yet, so it can be
called before or after adding. `advertiseAllTools` advertises everything, and
`advertiseToolDefaults` returns to each tool's own default exposure.

Use `defaultExposure` to decide whether a registered tool is directly
advertised in `tools/list` (`'static'`) or kept discoverable through the catalog
tools (`'discoverable'`, the default).
