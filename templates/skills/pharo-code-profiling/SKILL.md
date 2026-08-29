---
name: pharo-code-profiling
description: Profile running Pharo code to find where time is spent and drive performance optimization. Use when diagnosing slow methods, comparing before/after timings, or when a single `#timeToRun` measurement would be too noisy or too coarse to act on.
---

# Pharo Code Profiling

## Model

A sampling profiler periodically snapshots the running process, so it answers
"not how long" and "where the time went": call distribution, leaf hotspots,
own vs. child time, GC, and process activity. A single `#timeToRun` sample only
returns one noisy wall-clock number (JIT warm-up, GC, and scheduling skew it)
and gives no reason *why* the time went there.

Two profilers ship in the `Tool-Profilers` package of every supported Pharo:

- `AndreasSystemProfiler` — VM-supported sampling that answers a textual report
  (`report` returns a `String`). Preferred for agent-driven optimization.
- `TimeProfiler` — a graphical tree browser and a front end for `MessageTally`.
  Useful only when a human will browse the profile interactively.

`MessageTally` is the sampling engine underneath `TimeProfiler`; use it directly
only when you need its process-aware variants (`spyAllOn:`, `tallySendsTo:`).

## Workflow

1. Choose a representative, CPU-bound workload and run it enough times to last
   a few seconds. Do a warm-up run before measuring so the JIT is hot.
2. Profile and read the report as text:

```smalltalk
report := (AndreasSystemProfiler new spyOn: [ workload ]; report).
```

   The cascade `; report` is required: `spyOn:` returns the block's value, not
   the profiler. Do not use `AndreasSystemProfiler spyOn:`; it routes through
   `doReport`, which opens a text editor window instead of returning text.
3. If the report is too large, re-render it with a higher cutoff percentage
   instead of dumping the whole tree:

```smalltalk
reportShort := String streamContents: [ :s | profiler report: s cutoff: 2 ].
```

4. Read the tree top-down: separate each method's own time from the time spent
   in its children, and check the GC and process stats at the end. A hotspot in
   a leaf is actionable; a large own-time caller is where micro-optimization
   usually starts.
5. For interactive human browsing only, open the graphical profiler:

```smalltalk
TimeProfiler spyOn: [ workload ].
```

6. Make the narrowest change, re-profile the same workload with the same cutoff,
   and verify behavior with focused SUnit tests.

## Token Efficiency

- Profile a workload that runs for seconds, not milliseconds, to collect enough
  samples. A block that ends too soon leaves the sampler catching unrelated
  processes.
- Warm up before profiling; compare shapes, not exact numbers, between runs.
- Prefer `report:cutoff:` over printing the full `report` string.
- Summarize the report yourself: top entries with percentages, not the raw tree.
  Write the report to a file only when a full copy is needed.

## Stop Before

- Do not leave profiler windows open or call `doReport` on a headless image.
- Sampling covers the whole image, including the MCP server process serving the
  tool call and other background processes. Verify the report actually shows
  your workload's methods; otherwise lengthen or CPU-bind the block.
- Profiling forks a background process and mutates image state; run it inside a
  safe image boundary, and remember that a successful `image_evaluate` can save
  the image.
- Sampling approximates execution. Primitives and machine-code paths are charged
  to their callers, so trust the ranking and proportions, not exact numbers.

## Report

Report the workload, profiler used, cutoff, top entries with own vs. child
percentages, the change made, the before/after comparison, and the tests run.