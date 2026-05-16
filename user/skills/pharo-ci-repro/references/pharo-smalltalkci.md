# Pharo smalltalkCI Log Reading Notes

Use this reference after a local Docker/smalltalkCI run has produced logs.

## Phase Boundaries

smalltalkCI logs usually split into:

1. Preparing folders.
2. Starting Pharo build.
3. Downloading image and VM.
4. Preparing image and loading SmalltalkCI.
5. Loading project.
6. Testing project.
7. Coverage/upload/teardown.

If the crash happens after `Testing project...`, project code loaded. If it
happens during `Loading project...`, inspect the last Metacello package loaded
and the first missing global/class/selector.

## Useful Evidence To Extract

- `Image Information`, including `Pharo13.1.0SNAPSHOT` or similar.
- Build information SHA.
- VM version, when printed.
- The first test class/method named before a failure.
- The first Smalltalk exception, before any secondary cleanup failure.
- For segfaults, both the native C frames and the Smalltalk frames immediately
  above the crash.

## Focused Config Pattern

To narrow a failing class while preserving the same load path, create a
temporary config next to `.smalltalk.ston`:

```ston
SmalltalkCISpec {
  #loading : [
    SCIMetacelloLoadSpec {
      #baseline : 'MyProject',
      #directory : 'src',
      #ignoreImage : true,
      #onConflict : #useIncoming,
      #onUpgrade : #useIncoming
    }
  ],
  #testing : {
    #classes : [
      #MyProjectSuspectTest
    ],
    #hidePassingTests : true,
    #failOnZeroTests : true
  }
}
```

Adjust the baseline, directory, and class for the project under test.

## Pharo 13 / Iceberg / libgit2 Pattern

In a Pharo MCP investigation on 2026-05-16, a P13 flaky CI crash reproduced
locally inside Docker. It was not a dependency download issue: loading
completed and testing had started.

Crash signatures included:

- C stack in `libgit2.so.1.4.4`
- `git_repository_head_unborn`
- `git_commit_lookup`
- Smalltalk frames through `IceLibgitRepository`, `IceRepository>>headCommit`,
  or `IceRepository>>validateCanCommit`
- Test frames in a repository-management test

The practical mitigation was to avoid unnecessary test-side `repository
headCommit` reads and skip a P13 test that deliberately forced empty libgit2
config values for a P12-only fallback path.

General lesson: if a Pharo 13 Linux CI segfault points into libgit2 while
testing fresh temporary repositories, treat it as a native stability surface.
Avoid poking Iceberg head/commit metadata in tests unless the assertion is
essential.

## Interpreting Common Noise

- `fatal: not a git repository`: often harmless when running smalltalkCI from a
  scratch copy without `.git`. It matters only if the failing behavior depends
  on Git metadata.
- Metacello SSH authentication warnings followed by HTTPS fallback: often
  harmless in Docker if the dependency eventually loads.
- `StackOverflow` after a segfault: often VM aftermath, not the root cause.
- `NewUndeclaredWarning`: can be benign during dependency load, but if it names
  a project class/global required by the current package, investigate.

## Verification Discipline

After a fix:

- Run the failing Pharo platform full suite.
- Run adjacent supported platforms, usually P12 and P13 for MCP.
- Run focused repeats for the flaky class/method if the original failure was
  intermittent.
- Keep the captured failing log path in the report.
