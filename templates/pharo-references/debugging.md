# Debugging Tools

Applies when using MCP-Pharo to watch values while code runs, or to take over a
debugger a person already opened: inspecting its state, controlling paused
execution, or repairing code from a debugger state.

## Goal

Use debugger tools without guessing from source, driving Morphic debugger UI by
hand, or issuing stale frame and variable references.

Debugger tools are discoverable, not part of the default static surface.

## Discovery Flow

1. Use `tool_search` with a query such as `debug session` to find available
   debugger tools.
2. Use `tool_get` for the exact schema of the tool you plan to call.
3. If the current client exposes a catalog bridge, use `tool_call` to invoke
   the selected debugger tool by name. Otherwise use the callable form exposed
   by the current client.

## Must Do

- Treat `stateId`, `frameRef`, and `variableRef` values as opaque and
  state-scoped.
- Use the newest returned state after every control or edit action.
- Keep stack and variable limits small first, then expand only what is needed.
- Leave a person's debugger as you found it.
- Report the exact debugger tool names used and the final session state.

## Do Not

- Do not drive debugger windows or mutate contexts through general `image_evaluate`
  code.
- Do not reuse frame or variable references after stepping, restarting,
  resuming, terminating, or editing.
- Do not use debugger editing as a substitute for normal source tools when
  there is no paused debugger state.

## Tool Map

| Tool | Use |
| --- | --- |
| `debug_watch` | Record what variables hold while an expression runs, without stopping it. |
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
| `debug_method_update` | Update the method associated with a paused debug state, then proceed when possible. |

## Session Workflow

A debug session comes from a debugger a person already opened. No tool starts
one on the agent's behalf: to see why your own code failed, call the tool that
runs it and read the failure it reports, which names the frames nearest the
error and the values they held.

Use `debug_candidate_search` when a human already opened a debugger. It returns
unattached candidates with identifying details. Attach by passing the
candidate's `candidateRef` to `debug_candidate_attach`.

Use `debug_session_remove` when you are done. It only removes the session from
the MCP registry; the person's debugger stays open.

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

## Watching Values

`debug_watch` is print debugging without editing the method. Name the methods to
probe, the variables to record, and the expression to run. Every assignment to a
named variable is recorded as it happens, the expression runs to completion, and
the probes are removed before the call answers.

Name no variable and each method's arguments are recorded as it is entered.
Both `method` and `variable` take one value or a list, and a probe goes on every
pair that exists, so a variable a method never assigns simply has no series there.

Nothing is left installed and no debug session is created, so there is nothing to
clean up afterwards. Prefer it to stopping execution whenever the question is
what a value became rather than where to intervene.

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

- how the session was obtained: discovered debugger, or attached debugger;
- debugger tools called;
- final session outcome: completed, paused, running, terminated, forgotten, or
  still open;
- cleanup performed or still needed.
