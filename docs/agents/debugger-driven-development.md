# Debugger-Driven Development

Use this file when using MCP-Pharo to repair code from a live debugger state.

Debugger-driven development keeps execution paused at the failure, edits the
relevant method, and continues from the debugger instead of restarting the
whole scenario.

## Main Flow

1. Get a state with `debug-state`, or from `debug-capture` /
   `debug-sessions attach`.
2. Check `repairActions` before inventing an edit target.
3. Call `debug-edit` with the action's `sessionId`, `stateId`, and `frameRef`.
4. Review returned `critiques`.
5. If critiques are acceptable, retry with `ignoreCritiques=true`.
6. Continue with the returned state when execution pauses again.

## Missing Methods

For `MessageNotUnderstood`, `debug-edit` creates the method implied by the
paused message send. The target behavior, selector, class side, and frame are
derived from the debug state; do not guess them in the request.

You may omit `methodSource` when the default generated source is acceptable.
Provide `methodSource` when the method should do real work. The compiled method
is formatted before it is returned or used to continue execution.

## Stub Methods

For `subclassResponsibility`, `shouldBeImplemented`, and `notYetImplemented`,
`debug-edit` recompiles the method associated with the selected repair frame.
Use the repair action's frame reference instead of selecting a target class by
hand.

## Critiques

`debug-edit` uses the same critique gate expected from method-editing tools. It
stops before proceeding when critiques are reported unless
`ignoreCritiques=true`.

Use `ignoreCritiques=true` only after reading the critiques and deciding that
continuing the suspended computation is still the right next step.

## Proceeding

After a successful accepted edit, `debug-edit` attempts to proceed the repaired
computation. Outcomes include completed, paused, running, timed out, or blocked
by critiques.

When the outcome is paused, use the returned state and repair actions. When it
is completed, inspect the result class and print string. When it is running or
timed out, avoid issuing stale frame commands.

## Human-Owned Debuggers

For debugger windows opened by a human, attach with `debug-sessions` and let
the debugger controller perform control actions. The visible debugger remains
the UI owner. Do not use general `evaluate` code to drive Morphic debugger
widgets or mutate contexts directly.

When the user asks you to perform a bounded action and give control back, run
only the requested debugger calls, then stop and report the resulting state.
