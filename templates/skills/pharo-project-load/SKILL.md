---
name: pharo-project-load
description: Load or smoke-test a Pharo project from Tonel, Metacello, or Iceberg and diagnose baseline, branch, source-directory, group, dependency, or version-specific load failures. Use for fresh-image loads and CI-equivalent project loading.
---

# Pharo Project Load

## Context

Before loading, read the project README, baseline, `.smalltalk.ston`, and any
repository-specific agent guidance. Prefer dedicated Pharo MCP load tools when
a live image is available.

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

## Diagnose By Phase

- Baseline/package not found: verify branch and source directory.
- Missing global/class/selector: compare the project API surface with the
  target Pharo version; use `pharo-version-compat` when appropriate.
- Metacello conflict: reproduce the project's documented or CI conflict policy.
- Native or CI-only failure: reproduce once, then use `pharo-ci-repro`.

## Report

Report the Pharo version, repository and revision, source directory, baseline,
group, load result, verification result, and first meaningful failure.
