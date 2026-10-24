---
name: pharo-code-profiling
description: Profile running Pharo code to find where its time goes, and read the sampling report it answers. Use for slow code, before-and-after comparisons, and whenever a single `#timeToRun` number would not say why.
---

# Pharo Code Profiling

## Model

`#timeToRun` answers how long, never why, and one run is noisy: JIT warm-up, GC
and scheduling all move it. A sampling profiler interrupts execution every
millisecond and records the stack, so what it answers is a distribution. Trust
the ranking and the proportions, not the individual numbers.

Two samplers answer text in a headless image, and they differ in what they can
see, not only in how much:

- `MessageTally` is a Smalltalk process that wakes on a delay and records what
  it preempted. Spied on a block, its tree is rooted at that block, so the
  report holds the workload and nothing else. Start here.
- `AndreasSystemProfiler` is driven by the VM. It samples every process,
  including those running above the priority at which a Smalltalk sampler would
  itself be starved, and it records which primitive the VM is executing, which
  `MessageTally` can only lump together as `primitives`. Its tree is rooted at
  the image.

## Workflow

1. Build a workload that runs for one to five seconds: long enough for a
   thousand samples, short enough to answer inside the client's timeout, since
   `image_evaluate` has none of its own. Fork a longer one instead, as below.
   Run the workload once before measuring so the JIT is warm.
2. Profile it and keep the tally, which is what renders the report:

```smalltalk
| workload tally |
workload := [ 200 timesRepeat: [ "..." ] ].
workload value.
tally := MessageTally
	         spyOn: workload
	         reportOtherProcesses: false
	         cutoff: 2
	         openResultWindow: false
	         closeAfter: false.
String streamContents: [ :stream | tally report: stream cutoff: 2 ]
```

3. Read the report.
4. Change one thing, re-profile the same workload at the same cutoff, and
   compare shapes. Verify behavior with focused tests.

## Choosing The Cutoff

The cutoff is the percentage of all samples a node must hold to be printed, in
the tree and in the leaves alike. Use 2 and read the report once. Over a
2400-sample run of the same workload it printed 79 lines where 5% printed 52
and 1% printed 84, so it is close enough to the whole tree that a second look
rarely pays, and still under a thousand tokens.

Raise it when the report is larger than the question. Rendering again costs no
new run, because the tally is still in hand:

```smalltalk
String streamContents: [ :stream | tally report: stream cutoff: 10 ]
```

Do not lower it to find a workload whose methods are missing from the report.
A node printed at cutoff *c* over *n* samples holds `n * c / 100` of them, and
under about 25 samples that is noise rather than a measurement, so 2% means
nothing below some 1250 samples. Lengthen the run instead.

The `cutoff:` passed to the spy call only feeds the window it is not opening.
The one that decides the report is on `report:cutoff:`.

## Profiling A Workload Longer Than The Call

Fork the run, write the report to a file, and come back for it. The fork
returns the call immediately and leaves the image answering, so the profile can
take as long as the workload needs. Keep the report out of a global: a file
survives, is readable from outside the image, and needs no cleanup inside it.

```smalltalk
| path |
path := FileLocator imageDirectory / 'profile-report.txt'.
path ensureDelete.
[
| tally |
tally := MessageTally
	         spyOn: [ "..." ]
	         reportOtherProcesses: false
	         cutoff: 2
	         openResultWindow: false
	         closeAfter: false.
path writeStreamDo: [ :out |
	out << ((String streamContents: [ :stream | tally report: stream cutoff: 2 ])
			 copyReplaceAll: String cr with: String lf) ] ]
	forkAt: Processor userBackgroundPriority
	named: 'pharo-profile'.
path fullName
```

The file is written only once the run ends, so `path exists` answers whether it
is done. To tell a slow run from a dead one, look for the process by the name
it was forked under:

```smalltalk
Process allInstances anySatisfy: [ :each |
	each name = 'pharo-profile' and: [ each isTerminated not ] ]
```

Pharo writes CR line endings, so convert to LF as above, or the report arrives
as a single line everywhere outside the image.

The tally dies with the fork, so this report is written once and cannot be
rendered again at another cutoff. The file costs nothing to keep, and it can be
read in parts rather than whole.

Forking at `userBackgroundPriority` keeps the image answering calls while the
profile runs. The samples it loses to those calls are charged to another
process and dropped from the report, which lowers every percentage by the same
factor: read the proportions between nodes, not their absolute values.

## Reading The Report

```
 - 933 tallies, 933 msec.

**Tree**
Process: (60) ...
63.9% {596ms} Array(SequenceableCollection)>>shuffle
  63.9% {596ms} Array(SequenceableCollection)>>shuffleBy:
    62.7% {585ms} Random>>nextInteger:
      34.2% {319ms} Random>>privateNextValue
        |34.2% {319ms} Random class>>primitiveRandomNumber:
        |  17.8% {166ms} LargePositiveInteger(Integer)>>>>
        |    |17.6% {164ms} primitives
```

- `933 tallies` is the sample count. Below a few hundred, small differences
  mean nothing.
- A percentage is of the whole spied block and includes everything below it.
  Own time is a node's percentage minus its children's.
- `Receiver(DefiningClass)>>selector` names where an inherited method is
  defined: `Array(SequenceableCollection)>>shuffle` runs on an `Array` and is
  defined on `SequenceableCollection`.
- `primitives` is not a method. It is the part of the parent's time no child
  accounts for: its own work, primitives and inlined code included.
- The `|` bars are tree drawing. A node gets one when a sibling follows it at
  that level, and carries it down its subtree. They mean nothing else.
- `**Leaves**` ranks by own time and is usually what to act on. The tree says
  who is responsible, the leaves say what is expensive.
- `**Memory**` is the allocation delta over the run and `**GCs**` the
  collections and the share of the run spent in them. Heavy incremental GC with
  a large young delta is an allocation problem, and optimizing the leaves will
  not touch it.

## Whole-Image Profiling

Use it when the work happens in another process, or when the question is about
the image rather than one block.

```smalltalk
| profiler |
profiler := AndreasSystemProfiler new.
profiler spyOn: [ "..." ].
String streamContents: [ :stream | profiler report: stream cutoff: 2 ]
```

Never send `spyOn:` to the class: it ends in `doReport`, which opens a window.
The instance-side `spyOn:` is the headless path.

Its tree is rooted at the image, so a report taken through MCP opens with the
frames of the server handling the call. Find the workload's entry method and
read the percentages from that node down.

## Measuring Instead Of Profiling

A profile ranks, it does not measure. For a before-and-after number:

```smalltalk
"one run, as a Duration"
[ "..." ] timeToRun

"iterations per second over five seconds, which absorbs the noise"
[ "..." ] bench
```

Time the same thing at least three times and report the minimum rather than the
mean: the minimum is the run least disturbed by GC and scheduling.

## Stop Before

- Profiling forks a process and leaves state behind. Run it inside an approved
  image boundary and never save the image.
- Only one `MessageTally` can run at a time; a second answers "it seems a tally
  is already running". Let a forked profile finish before starting another.
- Do not trust a report whose tree does not contain the workload's own methods:
  it was too short, or it waited instead of computing.
- Do not compare numbers across different workloads or cutoffs. Compare shapes.

## Report

Report the workload and how long it ran, the sampler and cutoff, the top tree
nodes and leaves with their percentages, the change made, the before-and-after
comparison, and the tests that showed behavior unchanged.
