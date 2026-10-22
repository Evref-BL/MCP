# Tool Reference

MCP exposes tools through `tools/list` and `tools/call`. Common tools can be
advertised directly; less common tools can be found through the catalog tools.
Tool names use `snake_case` names that generally put the domain before the
action.

Every tool returns MCP call `content` as the canonical response for LLMs, in
plain text: the summary first, then any warnings, then the payload as lines.
The fields that identify one record share a line as `key=value` pairs, and a
value carrying spaces is quoted, as in `protocol="private - results"`. A record
that names a method opens with the method, written the way Pharo writes it:
`MCPTool>>batchSummaryNoun`, or `MCPTool class>>toolName` on the class side. A
list of plain values is bracketed, as in `required: [name, slotName]`, and a
list of records is named before its entries. Text with its own lines, such as
method source, follows under its own label. `tool_get` answers a tool's
contract as YAML.

A result does not repeat itself: what the summary states in prose, and what a
record already says another way, is left out of the lines.

The same payload is also carried as `structuredContent`:

```text
summary: human-readable summary
warnings: array of warning strings
data: structured success payload
error: structured error payload
```

`data` is present on success. `error` is present on failure, where the call is
also flagged with the protocol's own `isError`.

For clients or integrations that need programmatic payloads, configure the
server response fields before `start`:

```smalltalk
mcp useContentOnlyToolResponses. "default"
mcp useStructuredContentOnlyToolResponses.
mcp useContentAndStructuredContentToolResponses.
```

## Compact Paging

List and search tools are optimized for low token usage. Broad tools return a
small page by default and put only the entry array in `data`. When another page
exists, `data` includes `nextOffset`; call the same tool again with that
`offset` to continue.

Use the returned array size for the current page and follow `nextOffset` when
present. Request larger pages only when the next step truly needs more entries.

## Naming Several Targets

Four tools act on several targets in one call. The argument that names the
target holds either one value or a list of them, and every other argument
applies to all of them:

| Tool | Argument | One call covers |
| --- | --- | --- |
| `method_get` | `selector` | Methods of one class, on one side. |
| `method_compile` | `source` | Sources compiled into one class, under one protocol. |
| `class_get` | `name` | Classes read with the same options. |
| `class_create` | `name` | Classes sharing a superclass, package and slots. |

Every target is attempted. The summary states how many succeeded, each target
then reads as it would have read on its own, and `data` carries one entry per
target under `results`, in request order. An entry that failed carries its
`error`. The call is flagged `isError` only when every target failed.

A call naming one target answers exactly what it answers when the argument
holds a single value.

## The Advertised Surface

Fifteen tools are advertised directly: `tool_search`, `tool_get`, `tool_call`, `class_search`, `class_get`, `class_create`, `class_remove`, `method_metadata_search`, `method_source_search`, `method_reference_search`, `method_get`, `method_compile`, `method_remove`, `test_run` and `image_evaluate`. Every other tool is found with `tool_search` and called through `tool_call`.

A server chooses its own surface before `start`:

```smalltalk
mcp staticToolNames: #( 'tool_search' 'tool_get' 'tool_call' 'method_get' ).
```

## Finding A Tool

The server answers for its own catalogue. `tool_search` ranks it by keyword,
best match first, and answers the closest tools even when none matches every
word; add words to narrow the ranking. With no query it answers the catalogue's
size and its groups. `tool_get` returns one tool's metadata and input schema,
and `tool_call` invokes a tool the current client does not advertise directly.

Search before calling anything less common or high-risk, and read the schema
before invoking it.

Tools are named `domain_action`, and the domains are:

| Group | Covers |
| --- | --- |
| `classes` | Defining classes and changing their slots, traits, shared variables, pools, layout, package and comment, including the slot refactorings. |
| `methods` | Compiling, reading, removing and rewriting methods, renaming selectors and protocols, and searching by source, metadata, senders, implementors, references or equivalence. |
| `repositories` | Iceberg repositories: identity, remotes, branches, changes, export, commit, fetch, pull, push, and Metacello loads. |
| `debugging` | Debug sessions, their state and variables, stepping and control, breakpoints, evaluation in a frame, and method repair. |
| `history` | Epicea change history: locating files, listing entries, and applying or reverting them. |
| `tests` | Running tests and running them under coverage. |
| `packages` | Searching packages. |
| `runtime` | `image_evaluate`, the escape hatch. |
| `ui` | Capturing the Morphic world. |
| `tool-catalog` | `tool_search`, `tool_get` and `tool_call`. |

## Scripting

Use `image_evaluate` only when no dedicated tool fits. A successful evaluation
can mutate the running image.

## Mutation And Saving

No tool saves the image. Mutating tools change the running image only, so
closing it discards every change since its last save, and a mistake costs the
session rather than the image file. Saving is the caller's responsibility:
evaluate `Smalltalk saveSession` when a change should survive, or leave it to
whoever owns the image lifecycle.

Use `history_entry_list` to see what changed and `history_entry_revert` to undo
a change in the running image; both preview first and perform with
`confirm=true`.

`repository_identity_verify` and `repository_change_list` are read-only.

## Refactoring Warnings

For edit tools that use refactoring operations, `force=false` is the default.
When Pharo raises `RBRefactoringWarning`, the tool returns an error with:

```text
impactMessages
howToProceed
forceSupported: true
```

Rerun with `force=true` only after reviewing the impact. Forced warnings are
returned as normal warnings in the successful result.
