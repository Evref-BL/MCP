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

- Run the failing Pharo platform's full suite.
- Run the adjacent versions in the project's matrix.
- Run focused repeats for the flaky class or method when the original failure
  was intermittent.
- Keep the captured failing log path in the report.
