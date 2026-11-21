# Test coverage

Find `test_coverage_run` with `tool_search`, and ask `tool_get` for its current
schema. It uses the same test selections, validation and timeout behavior as
`test_run`, while measuring a separate, explicit method scope:

```json
{
  "classes": ["MyProjectTest"],
  "coverage": {
    "scope": {"packages": ["MyProject"], "side": "both"},
    "includeCoveredMethods": true
  }
}
```

The coverage scope uses the shared method search scope. Its entries add up;
`side` applies to all of them. A missing or empty scope is refused, so forgetting
a scope never instruments the whole image. Missing names produce warnings
and are left out, as they are in method search. Check those warnings before
interpreting a percentage.

Coverage records method entry and entry to each sequence of statements (a
method body or block body). The percentage is the share of sequences entered,
not line coverage or branch coverage. A covered method can be partial when
one of its blocks did not run. Test classes, abstract methods and methods
marked `<ignoreForCoverage>` are excluded. An empty coverable scope has no
percentage.

The answer includes the ordinary test summary, coverage counts, and lists of
uncovered and partially executed methods. `includeCoveredMethods` adds the
executed methods; `methodLimit` bounds each list, with a truncation flag when
more exist. A limit of zero returns counts without method entries. These
limits change the answer's size, not what is measured.

A timeout returns what ran, what remains to run, and coverage collected so far,
including code reached by an interrupted test. Treat that as partial evidence.
Instrumentation is removed on completion, timeout or error; links and execution
annotations owned by another collector are preserved. Coverage is image-wide
while the tests run, so other processes executing the selected methods can
contribute to it. Use an otherwise idle image for reproducible measurements.
