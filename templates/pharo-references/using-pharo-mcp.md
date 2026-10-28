# Using The Pharo MCP Server

Applies when an agent or user interacts with a running Pharo image through MCP.
Load, start and connect the server as the project serving it documents.

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
[Tool safety](tool-safety.md) for mutation boundaries.

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

When a call, a connection, or the image itself behaves unexpectedly, read
[Troubleshooting](troubleshooting.md).

## Reusable Workflows

Run `npx @evref-bl/pharo-mcp install --host <host>` in the target project to
install context-routed skills for project loading, image-to-Git handoff, CI
reproduction, code profiling, and standalone MCP recovery.

## Serving Your Own

An image can serve tools, resources and prompts a project defines itself,
from that project's own package and without changing the server. The server's
own documentation describes the server-only load, what a tool, a resource and
a prompt each need, and how the surface a client sees is shaped.
