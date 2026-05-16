---
name: pharo-project-load
description: Load Pharo projects into an image from local or remote Tonel/Metacello/Iceberg repositories, choose the correct baseline, branch, source directory, and load group, and diagnose project load failures such as missing BaselineOf packages, wrong src paths, Metacello conflicts, or Pharo-version load differences. Use when asked to load, smoke test, or debug loading a Pharo project in a fresh or existing image.
---

# Pharo Project Load

## Overview

Use this skill when the task is to load a Pharo project into an image, especially
from a Tonel repository with a `src` directory or when reproducing how CI/users
load the project.

Prefer the Pharo MCP tools when a live image is available. Use Smalltalk snippets
only when no dedicated tool fits.

## Workflow

1. Identify the load target:
   - Pharo version.
   - Repository URL or local path.
   - Branch, tag, or commit.
   - Source directory, usually `src`.
   - Baseline name, without the `BaselineOf` prefix.
   - Load group, if one is truly needed.

2. Inspect the repository layout before loading:
   - Confirm where `BaselineOf<name>` lives.
   - Confirm that Tonel package directories are under the selected source
     directory.
   - Check `.smalltalk.ston` or project docs for the CI load path.
   - If the repo recently moved to `src`, make sure URLs and `.project`
     metadata agree.

3. Load the project:
   - With Pharo MCP, use `load_repository` for remote Metacello loads.
   - For local Tonel paths, evaluate a small Metacello snippet if needed.
   - Prefer the default load first. Specify groups only when the task or project
     docs require them.

4. Verify the image:
   - List loaded packages/classes with MCP tools.
   - Run focused tests or the project test package when present.
   - Check Iceberg repository state if the task cares about later edits.

5. Diagnose failures by phase:
   - Baseline/package not found: branch or source directory is wrong, or the
     baseline package is not committed where Metacello is looking.
   - Undeclared globals/selectors during load: target Pharo version lacks an API
     expected by the project or one of its dependencies.
   - Metacello conflict/upgrade failure: dependency registration differs from
     the image state; use the simplest conflict policy that exists in the target
     Pharo version.
   - Native crash during load: rerun once, then use the `pharo-ci-repro` skill
     if smalltalkCI/Docker conditions matter.

## Examples

Remote Tonel repository:

```smalltalk
Metacello new
  baseline: 'MyProject';
  repository: 'github://Owner/MyProject:main/src';
  load
```

Local Tonel repository:

```smalltalk
Metacello new
  baseline: 'MyProject';
  repository: 'tonel:///absolute/path/to/MyProject/src';
  load
```

Explicit group, only when needed:

```smalltalk
Metacello new
  baseline: 'MyProject';
  repository: 'github://Owner/MyProject:main/src';
  load: 'Tests'
```

## Common Checks

- `NotFound: BaselineOfMyProject` usually means Metacello is looking in the
  wrong source directory or branch.
- If the project uses `src`, the repository URL usually needs to end in `/src`.
- The branch in the URL should match the branch containing the desired layout.
- Do not assume Metacello helper selectors exist in every supported Pharo
  version; prefer plain `load` unless a compatibility wrapper is already
  provided.
- When using a local path, use an absolute path to avoid command-line working
  directory surprises.

## Reporting

Report the Pharo version, repository path/URL, branch, source directory,
baseline, group, load result, verification result, and the first meaningful
error if loading failed.
