# Debugging Tools

Applies when using MCP-Pharo to capture exceptions, inspect debug sessions,
control paused execution, manage breakpoints, or repair code from a debugger
state.

## Goal

Use debugger tools without guessing from source, driving Morphic debugger UI by
hand, or issuing stale frame and variable references.

Debugger tools are discoverable, not part of the default static surface.

## Discovery Flow

1. Use `tool_search` with `group=debugging` to find available debugger
   tools.
2. Use `tool_get` for the exact schema of the tool you plan to call.
3. If the current client exposes a catalog bridge, use `tool_call` to invoke
   the selected debugger tool by name. Otherwise use the callable form exposed
   by the current client.

## Must Do

- Treat `stateId`, `frameRef`, and `variableRef` values as opaque and
  state-scoped.
- Use the newest returned state after every control or edit action.
- Keep stack and variable limits small first, then expand only what is needed.
- Clear temporary breakpoints and forget agent-owned sessions when the task is
  done.
- Report the exact debugger tool names used and the final session state.

## Do Not

- Do not drive debugger windows or mutate contexts through general `image_evaluate`
  code.
- Do not reuse frame or variable references after stepping, restarting,
  resuming, terminating, or editing.
- Do not leave breakpoints or captured sessions behind without reporting them.
- Do not use debugger editing as a substitute for normal source tools when
  there is no paused debugger state.

## Tool Map

| Tool | Use |
| --- | --- |
| `debug_capture` | Evaluate a Smalltalk expression in a bounded worker process and capture runtime exceptions as tracked debug sessions. |
| `debug_test_run` | Run one SUnit test method in a bounded worker process and capture failures or errors as tracked debug sessions. |
| `debug_session_list` | List tracked debug sessions. |
| `debug_session_get` | Inspect one tracked debug session summary. |
| `debug_session_remove` | Remove a tracked debug session from the registry. |
| `debug_candidate_search` | Search unattached open debugger candidates. |
| `debug_candidate_attach` | Attach an open debugger candidate and return its debug state. |
| `debug_state_get` | Return the current session snapshot: stack, selected frame, source, scopes, repair actions, and state-scoped refs. |
| `debug_variable_get` | Expand scope and variable refs returned by `debug_state_get`. |
| `debug_expression_evaluate` | Evaluate a Smalltalk expression in a selected debug frame. |
| `debug_session_step_into` | Step into the selected frame of a tracked session. |
| `debug_session_step_over` | Step over the selected frame of a tracked session. |
| `debug_session_step_through` | Step through the selected frame of a tracked session. |
| `debug_session_restart` | Restart the selected frame of a tracked session. |
| `debug_session_resume` | Resume a tracked session. |
| `debug_session_terminate` | Terminate a tracked session. |
| `debug_breakpoint_list` | List tracked transient DebugPoint breakpoints. |
| `debug_breakpoint_set` | Install a transient method-entry or source-interval DebugPoint breakpoint. |
| `debug_breakpoint_remove` | Remove one tracked transient DebugPoint breakpoint. |
| `debug_breakpoint_enable` | Enable one tracked transient DebugPoint breakpoint. |
| `debug_breakpoint_disable` | Disable one tracked transient DebugPoint breakpoint. |
| `debug_breakpoint_clear` | Remove all tracked transient DebugPoint breakpoints. |
| `debug_method_update` | Update the method associated with a paused debug state, then proceed when possible. |

## Session Workflow

Use `debug_capture` when the agent should run code and capture its own
failure. If execution completes normally, there is no debugger session. If a
runtime exception is captured, use the returned `sessionId` and `state`.

Use `debug_test_run` when the failure is already expressed as one SUnit test method.
If the test passes, there is no debugger session. If it fails or errors, use the
returned `sessionId` and `state`.

Use `debug_candidate_search` when a human already opened a debugger. It returns
unattached candidates with identifying details. Attach by passing the
candidate's `candidateRef` to `debug_candidate_attach`.

Use `debug_session_remove` when you are done. Removing an agent-owned captured
session can terminate its worker process. Removing an attached human debugger
only removes it from the MCP registry.

## State And References

Treat `stateId`, `frameRef`, and `variableRef` values as state-scoped opaque
references. After a debug-session control tool or `debug_method_update`, old
frame and variable refs can be stale. Use the new returned state before
evaluating, expanding variables, or controlling execution again.

Use `debug_state_get` as the main context-loading tool. Keep stack and variable
limits small first, then expand details with `debug_variable_get` only when needed.

Use `debug_expression_evaluate` only for expressions that need the selected frame's
receiver or temporaries. Prefer normal code tools for project edits.

## Control

Use `debug_session_step_into`, `debug_session_step_over`,
`debug_session_step_through`, `debug_session_restart`,
`debug_session_resume`, and `debug_session_terminate` for control actions.
Control tools can return a `debug_state_get` snapshot when execution pauses.
Set `returnState=true` when the next step needs that snapshot inline;
otherwise call `debug_state_get` after the control action.
When the user asks for a bounded action, such as "step into twice", perform
those control calls and stop.

For externally attached debuggers, control should operate through the attached
debugger controller so the visible debugger remains the owner of its UI. Do not
manipulate debugger windows or contexts with general `image_evaluate` code.

## Breakpoints

Use the `debug_breakpoint_*` tools for temporary method-entry or
source-interval DebugPoint breakpoints. Clear breakpoints when the debugging
task ends.

File/line breakpoints are intentionally not emulated. Resolve source intervals
from the relevant method when source-interval precision is needed.

## Debugger-Driven Development

When a debug state offers repair actions, prefer `debug_method_update` over separate
manual edits. It can create missing methods or recompile stub/selected methods,
formats the compiled method, reports critiques, and proceeds when the edit is
accepted.

Read [Debugger-Driven Development](debugger-driven-development.md) before using
`debug_method_update` for missing methods, `subclassResponsibility`,
`shouldBeImplemented`, `notYetImplemented`, or iterative repair workflows.

## Reporting

When finishing debugger work, report:

- how the session was obtained: capture, test, discovered debugger, or attached
  debugger;
- debugger tools called;
- final session outcome: completed, paused, running, terminated, forgotten, or
  still open;
- breakpoints created, cleared, or left in place;
- cleanup performed or still needed.
