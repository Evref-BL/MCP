# Debugging Tools

Use this file when working with MCP-Pharo debugger tools. These tools are
discoverable, not part of the default static surface.

Start with:

1. `discover-tools` with `group=debugging` to find available debugger tools.
2. `inspect-tool` for the exact schema of the tool you plan to call.
3. `call-tool` to invoke the selected debugger tool by name.

## Tool Map

| Tool | Use |
| --- | --- |
| `debug-capture` | Evaluate a Smalltalk expression in a bounded worker process and capture runtime exceptions as tracked debug sessions. |
| `debug-sessions` | List, describe, forget, discover, or attach tracked sessions and open debugger candidates. |
| `debug-state` | Return the current session snapshot: stack, selected frame, source, scopes, repair actions, and state-scoped refs. |
| `debug-variables` | Expand scope and variable refs returned by `debug-state`. |
| `debug-evaluate` | Evaluate a Smalltalk expression in a selected debug frame. |
| `debug-control` | Step, restart, resume, or terminate a tracked session. |
| `debug-breakpoints` | Manage transient DebugPoint breakpoints. |
| `debug-edit` | Create or hot-recompile the method implied by a paused debug state, then proceed when possible. |

## Session Workflow

Use `debug-capture` when the agent should run code and capture its own
failure. If execution completes normally, there is no debugger session. If a
runtime exception is captured, use the returned `sessionId` and `state`.

Use `debug-sessions` with `operation=discover` when a human already opened a
debugger. It returns unattached candidates with identifying details. Attach by
passing the candidate's `candidateRef` to `operation=attach`.

Use `debug-sessions` with `operation=forget` when you are done. Forgetting an
agent-owned captured session can terminate its worker process. Forgetting an
attached human debugger only removes it from the MCP registry.

## State And References

Treat `stateId`, `frameRef`, and `variableRef` values as state-scoped opaque
references. After `debug-control` or `debug-edit`, old frame and variable refs
can be stale. Use the new returned state before evaluating, expanding
variables, or controlling execution again.

Use `debug-state` as the main context-loading tool. Keep stack and variable
limits small first, then expand details with `debug-variables` only when needed.

Use `debug-evaluate` only for expressions that need the selected frame's
receiver or temporaries. Prefer normal code tools for project edits.

## Control

`debug-control` supports `stepInto`, `stepOver`, `stepThrough`, `restart`,
`resume`, and `terminate`. It can return a post-action `debug-state` snapshot
for paused operations. When the user asks for a bounded action, such as
"step into twice", perform those control calls and stop.

For externally attached debuggers, control should operate through the attached
debugger controller so the visible debugger remains the owner of its UI. Do not
manipulate debugger windows or contexts with general `evaluate` code.

## Breakpoints

Use `debug-breakpoints` for temporary method-entry or source-interval
DebugPoint breakpoints. It supports `list`, `set`, `remove`, `enable`,
`disable`, and `clear`. Clear breakpoints when the debugging task ends.

File/line breakpoints are intentionally not emulated. Resolve source intervals
from the relevant method when source-interval precision is needed.

## Debugger-Driven Development

When a debug state offers repair actions, prefer `debug-edit` over separate
manual edits. It can create missing methods or recompile stub/selected methods,
formats the compiled method, reports critiques, and proceeds when the edit is
accepted.

Read [Debugger-Driven Development](debugger-driven-development.md) before using
`debug-edit` for missing methods, `subclassResponsibility`,
`shouldBeImplemented`, `notYetImplemented`, or iterative repair workflows.
