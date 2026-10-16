---
name: pharo-ci-repro
description: Reproduce Pharo smalltalkCI or GitHub Actions failures locally, preferably in Docker; preserve logs; narrow flaky tests; and distinguish project, compatibility, VM/native, and external-service failures.
---

# Pharo CI Repro

## Context

Read the failing workflow, `.smalltalk.ston`, project load instructions, commit,
and supported Pharo matrix. Read `references/pharo-smalltalkci.md` after a run
produces logs.

## Workflow

1. Record platform, config path, revision, and failing phase: download, load,
   tests, coverage, or teardown.
2. Check `git status --short --branch`. Use a clean failing revision for exact
   reproduction or an isolated scratch copy for local fixes.
3. Run one faithful Docker/smalltalkCI reproduction and preserve its first
   failing log. Confirm the Docker CLI and daemon before falling back.
4. Use local smalltalkCI only when containers are unavailable or OS/runtime
   fidelity is irrelevant; isolate its checkout/home per parallel job.
5. After reproducing, narrow with a temporary smalltalkCI config for one class
   or package. Repeat focused runs for flakes.
6. Classify the result as project, compatibility, VM/native, or external.
7. Verify the fix on every affected CI platform and repeat the flaky target.

## Helper

```sh
skills/pharo-ci-repro/scripts/run-smalltalkci-docker.sh \
  --repo /path/to/repo \
  --platform Pharo64-13 \
  --attempts 3
```

Use `--spec` for a focused config, `--out` for logs, and `--keep-going` to
collect multiple failures. Use `--include-git` only for ordinary checkouts;
linked worktree `.git` files point outside a copied tree.

## Report

Report exact commands, image/VM versions, first failing phase, relevant
Smalltalk/native frames, log paths, diagnosis class, changes made, and matrix
verification. Keep native-crash conclusions cautious.
