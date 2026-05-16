---
name: pharo-ci-repro
description: Recreate Pharo smalltalkCI and GitHub Actions conditions locally with Docker, capture logs from flaky Pharo CI failures, isolate failing Smalltalk test classes or methods, and distinguish project failures from Pharo VM/Iceberg/libgit2/external-service issues. Use when asked to reproduce, debug, stress, or understand Pharo CI failures locally, especially with smalltalkCI, Docker, Pharo version matrices, intermittent segfaults, or GitHub Actions logs.
---

# Pharo CI Repro

## Overview

Use this skill to reproduce a Pharo CI run locally with Docker and
smalltalkCI, then preserve enough evidence to understand failures that are
hard to diagnose from GitHub logs alone.

Prefer matching the CI runner first, then narrowing. Do not jump straight to a
hand-written Pharo script unless smalltalkCI itself is not involved in the
failure.

## Workflow

1. Identify the CI facts:
   - Pharo platform, for example `Pharo64-13` or `Pharo64-12`.
   - smalltalkCI config path, usually `.smalltalk.ston`.
   - Branch/commit under test.
   - Whether the failure happens during image download, dependency load, project
     load, tests, coverage, or teardown.

2. Check the local repo state:
   - Run `git status --short --branch`.
   - If reproducing GitHub exactly, use a clean checkout of the failing commit.
   - If testing a local fix, copy the working tree into a scratch directory and
     accept that smalltalkCI may print harmless "not a git repository" messages
     if `.git` is excluded.

3. Run a full local Docker reproduction:
   - Use `scripts/run-smalltalkci-docker.sh` when available.
   - Store logs outside the repo, usually under `/tmp`.
   - Keep the first failing log; do not overwrite it during later narrowing.

4. Narrow only after one faithful run:
   - Create a temporary `.smalltalk-*.ston` that loads the same baseline but
     runs a single suspect class or package.
   - Repeat the focused run a few times for flakes.
   - Compare crash stacks across failures. For VM crashes, the Smalltalk stack
     just before the native stack is often the clue.

5. Decide the diagnosis class:
   - Project failure: deterministic Smalltalk failure/error with useful stack.
   - Compatibility failure: load/test failure varies by Pharo version and names
     missing globals/selectors/classes.
   - Native/VM failure: segfault, stack overflow aftermath, or C stack in VM,
     libgit2, FFI, Cairo, etc.
   - External factor: download timeout, GitHub/network/auth/server issue before
     project code runs.

6. Verify the fix against all relevant Pharo versions before reporting:
   - Run the fixed full suite for every CI platform touched by the change.
   - For flakes, also rerun the focused suspect class/method.

## Helper Script

Run:

```sh
user/skills/pharo-ci-repro/scripts/run-smalltalkci-docker.sh \
  --repo /path/to/repo \
  --platform Pharo64-13 \
  --attempts 3
```

Useful flags:

- `--spec .smalltalk-editrepo.ston` to run a focused temporary config.
- `--out /tmp/my-repro` to choose the scratch/log directory.
- `--include-git` to copy `.git` too. Use only for ordinary checkouts, not
  worktrees whose `.git` file points outside the copied tree.
- `--keep-going` to continue after failures and collect several failing logs.

The script stops at the first failure by default and prints the log path.

## Pharo-Specific Guidance

Read `references/pharo-smalltalkci.md` when diagnosing a captured log,
especially for Pharo 13, Iceberg, libgit2, or image/cache issues.

Watch for these local reproduction traps:

- The Docker image `hpiswa/smalltalkci:24.04` may run as `linux/amd64`; on Apple
  Silicon, pass Docker's `--platform linux/amd64`.
- Missing SSH keys in Docker often produce Metacello/Iceberg auth warnings and
  HTTPS fallback. That can still match GitHub closely enough if dependencies
  load.
- A scratch copy without `.git` may print Git discovery warnings before Pharo
  starts. Treat them as noise unless the CI failure itself involves Git metadata.
- smalltalkCI can reuse caches inside one container, but separate Docker runs
  usually redownload Pharo images/VMs. This is slower but closer to GitHub.

## Reporting

Report:

- exact command(s) run;
- Pharo image build and VM version from the log;
- first failing phase;
- key Smalltalk and native stack frames;
- log paths;
- what was changed or ruled out;
- verification commands and results.

Keep conclusions cautious for native crashes. Say "triggered by our test path"
when the evidence points to an upstream VM/libgit2 issue but the project can
avoid the unstable path.
