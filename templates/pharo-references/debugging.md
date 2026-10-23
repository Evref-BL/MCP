# Debugging Tools

Applies when using MCP-Pharo to watch values while code runs, or to read and
repair a debugger a person already opened.

## Goal

See what running code is doing without guessing from source and without driving
the Morphic debugger by hand.

Debugger tools are discoverable, not part of the default static surface.

## Discovery Flow

1. Use `tool_search` with a query such as `watch` or `debug session`.
2. Use `tool_get` for the exact schema of the tool you plan to call.
3. If the current client exposes a catalog bridge, use `tool_call` to invoke
   the selected tool by name. Otherwise use the callable form exposed by the
   current client.

## Tool Map

| Tool | Use |
| --- | --- |
| `debug_watch` | Record what variables hold while an expression runs, without stopping it. |
| `debug_session` | List the debuggers open in the image, or answer one of them. |

Two more tools take a `frame` from `debug_session` and act inside it:

| Tool | With a `frame` |
| --- | --- |
| `image_evaluate` | Evaluates the code in that paused frame, where its variables are in scope. |
| `method_compile` | Replaces the method that frame stopped in, then proceeds. |

## Watching Values

`debug_watch` is print debugging without editing the method. Name the methods to
probe, the variables to record, and the expression to run. Every assignment to a
named variable is recorded as it happens, the expression runs to completion, and
the probes are removed before the call answers.

Name no variable and each method's arguments are recorded as it is entered.
Both `method` and `variable` take one value or a list, and a probe goes on every
pair that exists, so a variable a method never assigns simply has no series there.

Nothing is left installed and no debug session is created, so there is nothing to
clean up afterwards. Reach for it whenever the question is what a value became,
rather than where to intervene.

## Reading A Debugger

No tool starts a debug session. A session is a debugger somebody opened, and
`debug_session` is how you find and read it.

Called with nothing, it lists what is open: the debuggers MCP has attached to,
and the ones it has not. Called with a reference from that listing, it attaches
the debugger if it is not attached yet and answers its state — the stack, the
selected frame, its source, its variables and any repair actions. Attaching is
not a separate call.

To see why your own code failed, do not open a debugger for it. Call the tool
that runs the code and read the failure it reports: it names the frames nearest
the error and the values they held.

## Acting In A Frame

The state names a `frame` for each entry in the stack. Pass one to
`image_evaluate` to evaluate against that frame's receiver and temporaries, or
to `method_compile` to replace the method it stopped in and carry on.

Compiling into a frame takes the class and the selector from the frame, so only
the source is needed. It gates on critiques unless `force=true`, formats what it
compiles, and proceeds the computation when the edit is accepted. A frame names
one method, so that call takes one source rather than a list.

When a state offers repair actions, prefer them to inventing an edit target:
each one carries the arguments to pass straight back.

## State And References

Treat `stateId` and `frame` values as opaque and state-scoped. Editing or
proceeding invalidates them, so read the state again before acting on a frame a
second time.

Leave a person's debugger as you found it, and do not drive debugger windows or
mutate contexts through general `image_evaluate` code.

## Debugger-Driven Development

Read [Debugger-Driven Development](debugger-driven-development.md) before
repairing missing methods, `subclassResponsibility`, `shouldBeImplemented`,
`notYetImplemented`, or working through iterative repairs.

## Reporting

When finishing debugger work, report which tools were called, what the final
state of the person's debugger is, and anything left for them to clean up.
