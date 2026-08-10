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
- Use `tool_search`, then `tool_get`, for less common tools. Invoke a catalog
  tool through `tool_call` when the client does not expose it directly.
- Prefer the least-mutating dedicated tool. Use `image_evaluate` only when no
  dedicated tool fits.
- Start list/search calls with the default page or a small `limit`. Continue
  only when the result contains `nextOffset`.

See [Tool reference](tool-reference.md) for tool groups and common workflows.

## Choose Specialized Lookups

Use `method_metadata_search` for metadata, `method_source_search` for source,
`method_equivalent_search` for equivalent ASTs, and the implementor, sender,
class-reference, or variable-reference search matching the question.

For repository work, inspect with `repository_search`, verify identity before
mutation, and inspect `repository_change_list` before export or commit. Read
[Safety and ecosystem integration](safety-and-ecosystem.md) for mutation
boundaries.

For history recovery, inspect files and entries before applying or reverting.
For debugger sessions, breakpoints, or repairs, read [Debugging tools](debugging.md).

## Image Mutation

Successful mutating tools save the image. Use a copied or disposable image for
broad or risky edits, preview changes when the tool supports it, and run focused
tests after source changes.

Report incomplete or failing tool results clearly. Never silently fall back to
exported source for a question about the live image.

## Reusable Workflows

Copy `templates/` into the target project to install context-routed skills for
project loading, version compatibility, image-to-Git handoff, CI reproduction,
and standalone MCP recovery.

## Custom Tools

Define custom tools as subclasses of `MCPTool` in your own package. At minimum,
provide the class-side tool name and the instance-side metadata, schema, and
execution protocol expected by `MCPTool`:

```smalltalk
MCPTool subclass: #MyProjectMCPTool
	instanceVariableNames: ''
	classVariableNames: ''
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

MyProjectMCPTool >> buildOutputSchema

	^ self standardOutputSchemaForDataProperties: #(  ) required: #(  )

MyProjectMCPTool >> executeWithRequest: request

	^ self
		successResultText: 'Operation completed.'
		data: Dictionary new
```

By default, tools outside the MCP package are not auto-registered. If your
package intentionally publishes a tool whenever it is loaded, opt in:

```smalltalk
MyProjectMCPTool class >> shouldAutoRegister

	^ true
```

Auto-registered external tools are discoverable by default. Agents can find
them with `tool_search`, inspect them with `tool_get`, and call them through
`tool_call`.

For per-server configuration, register tools explicitly before starting the
server:

```smalltalk
mcp := MCP new.
mcp registerToolClass: MyProjectMCPTool.
mcp start.
```

You can also register several classes, register an already-created tool, or
remove a tool from one server instance:

```smalltalk
mcp registerToolClasses: { MyProjectMCPTool. MyOtherMCPTool }.
mcp registerTool: MyProjectMCPTool new.
mcp unregisterToolNamed: 'my_project_tool'.
```

Use `defaultExposure` to decide whether a registered tool is directly
advertised in `tools/list` (`'static'`) or kept discoverable through the catalog
tools (`'discoverable'`, the default).
