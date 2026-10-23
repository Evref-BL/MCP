# Debugging Tools

Applies when using MCP-Pharo to watch values while code runs, or to see what
debuggers a person has open.

## Goal

See what running code is doing without guessing from source and without driving
the Morphic debugger by hand.

Debugger tools are discoverable, not part of the default static surface.

## Discovery Flow

1. Use `tool_search` with a query such as `watch` or `debugger`.
2. Use `tool_get` for the exact schema of the tool you plan to call.
3. If the current client exposes a catalog bridge, use `tool_call` to invoke
   the selected tool by name. Otherwise use the callable form exposed by the
   current client.

## Tool Map

| Tool | Use |
| --- | --- |
| `debug_watch` | Record what variables hold while an expression runs, without stopping it. |
| `debug_search` | Answer the debuggers open in the image, read-only. |

Neither tool keeps anything. No session is started, attached or registered, so
there is no reference to carry between calls and nothing to clean up.

## Watching Values

`debug_watch` is print debugging without editing the method. Name the methods to
probe, the variables to record, and the expression to run. Every assignment to a
named variable is recorded as it happens, the expression runs to completion, and
the probes are removed before the call answers.

Name no variable and each method's arguments are recorded as it is entered.
Both `method` and `variable` take one value or a list, and a probe goes on every
pair that exists, so a variable a method never assigns simply has no series there.

Reach for it whenever the question is what a value became, rather than where to
intervene.

## Seeing A Person's Debuggers

`debug_search` answers the debuggers open in the image: each one's name, the
exception it stopped on, and the frames nearest the stop with what those frames
hold. Pass a `query` to keep only the debuggers whose name or exception matches.

It is a query and nothing else. It attaches to nothing, changes nothing, and
remembers nothing, so the picture it gives is whatever is open at that moment.
Ask again for a fresh one.

Act on what it shows with the ordinary tools: read the method with `method_get`,
change it with `method_compile`, run something with `image_evaluate`. Stepping,
resuming and repairing from inside a frame belong to the person at the debugger,
not to the agent.

## To Debug Your Own Code

Do not open a debugger for it. Call the tool that runs the code and read the
failure it reports: it names the frames nearest the error and the values they
held. When that is not enough, `debug_watch` shows how a value got there.

## Do Not

- Do not drive debugger windows or mutate contexts through general
  `image_evaluate` code.
- Do not resume, step or terminate a person's debugger. It is theirs.
