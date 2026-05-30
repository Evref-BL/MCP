# Debugger-Driven Development

Applies when using MCP-Pharo to repair code from a live debugger state.

Debugger-driven development keeps execution paused at the failure, edits the
relevant method, and continues from the debugger instead of restarting the
whole scenario.

## Goal

Repair code from the paused execution context while preserving the debugger as
the source of truth for receiver, selector, class side, selected frame, and
repair action.

## Main Flow

1. Get a state with `debug_state_get`, `debug_capture`, or
   `debug_candidate_attach`.
2. Check `repairActions` before inventing an edit target.
3. Call `debug_method_repair` with the action's `sessionId`, `stateId`, and `frameRef`.
4. Review returned `critiques`.
5. If the edit is blocked by critiques and the critiques are acceptable, retry
   with `ignoreCritiques=true`.
6. Continue with the returned state when execution pauses again.

## Must Do

- Use the repair action's frame reference instead of selecting a target class or
  method by hand.
- Review critiques before allowing the repaired computation to proceed.
- Treat returned states and references as fresh; discard older state-scoped
  references after each edit or control action.
- Stop after the bounded action the user requested and report the resulting
  state.

## Do Not

- Do not guess the receiver class, target behavior, selector, or class side for
  missing-method repair.
- Do not use general `image_evaluate` code to mutate contexts or drive
  debugger UI.
- Do not continue issuing frame commands when the repair outcome is running,
  timed out, completed, or blocked by critiques.

## Missing Methods

For `MessageNotUnderstood`, `debug_method_repair` creates the method implied by the
paused message send. The target behavior, selector, class side, and frame are
derived from the debug state; do not guess them in the request.

You may omit `methodSource` when the default generated source is acceptable.
Provide `methodSource` when the method should do real work. The compiled method
is formatted before it is returned or used to continue execution.

## Stub Methods

For `subclassResponsibility`, `shouldBeImplemented`, and `notYetImplemented`,
`debug_method_repair` recompiles the method associated with the selected repair frame.
Use the repair action's frame reference instead of selecting a target class by
hand.

## Critiques

`debug_method_repair` uses the same critique gate expected from method-editing tools. It
stops before proceeding when critiques are reported unless
`ignoreCritiques=true`.

Use `ignoreCritiques=true` only after reading the critiques and deciding that
continuing the suspended computation is still the right next step.

## Proceeding

After a successful accepted edit, `debug_method_repair` attempts to proceed the repaired
computation. Outcomes include completed, paused, running, timed out, or blocked
by critiques.

When the outcome is paused, use the returned state and repair actions. When it
is completed, inspect the result class and print string. When it is running or
timed out, avoid issuing stale frame commands.

## Human-Owned Debuggers

For debugger windows opened by a human, discover candidates with
`debug_candidate_search`, attach with `debug_candidate_attach`, and let the
debugger controller perform control actions. The visible debugger remains the
UI owner. Do not use general `image_evaluate` code to drive Morphic debugger
widgets or mutate contexts directly.

When the user asks you to perform a bounded action and give control back, run
only the requested debugger calls, then stop and report the resulting state.

## Reporting

When finishing a debugger-driven repair, report:

- repair action used;
- method created or recompiled, when any;
- critiques returned and whether they were accepted;
- proceed outcome;
- final state or why no fresh state is available;
- cleanup still needed.
