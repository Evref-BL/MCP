---
name: pharo-project-load
description: Load or smoke-test a Pharo project from Tonel, Metacello, or Iceberg and diagnose baseline, branch, source-directory, group, dependency, or version-specific load failures. Use for fresh-image loads and CI-equivalent project loading.
---

# Pharo Project Load

## Context

Before loading, read the project README, baseline, `.smalltalk.ston`, and any
repository-specific agent guidance. In a live image, load with Metacello
through `evaluate`, as below; `repository_attach` registers a checkout without
loading it.

## Workflow

1. Identify the Pharo version, repository URL/path, branch or commit, source
   directory, baseline name, and required load group.
2. Confirm that `BaselineOf<Name>` and the Tonel packages exist under the
   selected source directory. Check that repository URLs and `.project` agree.
3. Load the default baseline first. Specify a group only when project or CI
   configuration requires it.
4. Verify loaded packages/classes and run focused or project tests.
5. Inspect Iceberg state when later edits or export are in scope.

Minimal remote load:

```smalltalk
Metacello new
  baseline: 'MyProject';
  repository: 'github://Owner/MyProject:main/src';
  load
```

For local Tonel, use an absolute `tonel:///.../src` URL.

## A Load Longer Than The Call

`evaluate` stops its code at its time limit, `timeoutSeconds`, whose default
its schema gives, and a limit longer than the client waits loses the answer.
What a stopped load loaded stays loaded: an answer that begins `Evaluation
stopped` leaves the image half loaded, so load again before relying on it. A
load that may take longer runs forked, and writes how it ended to a file:

```smalltalk
| file |
file := FileLocator imageDirectory / 'load-result.txt'.
file ensureDelete.
[ | result |
result := [
	[ Metacello new
		baseline: 'MyProject';
		repository: 'github://Owner/MyProject:main/src';
		load.
	'loaded' ]
		on: Warning
		do: [ :warning | warning resume ] ]
	on: Error
	do: [ :error | error description ].
file writeStreamDo: [ :out | out nextPutAll: result ] ]
	forkAt: Processor userBackgroundPriority
	named: 'project-load'.
file fullName
```

The call answers at once and the image keeps answering while the fork loads.
The file appears when the load ends, holding `loaded` or the error that ended
it; until then a process named `project-load` is alive. The fork resumes
warnings, as `evaluate` does for the code it runs itself. Without that
handler, a warning such as Monticello's about missing dependencies stops the
fork at a debugger, and the file never appears.

## Diagnose By Phase

- Baseline/package not found: verify branch and source directory.
- Missing global/class/selector: compare the project API surface with the
  target Pharo version. Version-specific code belongs in a package the
  baseline loads only where it applies.
- Metacello conflict: reproduce the project's documented or CI conflict policy.
- Native or CI-only failure: reproduce once, then use `pharo-ci-repro`.

## Report

Report the Pharo version, repository and revision, source directory, baseline,
group, load result, verification result, and first meaningful failure.
