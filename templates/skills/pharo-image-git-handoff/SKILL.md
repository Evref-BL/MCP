---
name: pharo-image-git-handoff
description: Turn image-side Pharo changes into clean Tonel/Git changes safely. Use when changes were made in a live Pharo image and need to be exported, reviewed, committed, pushed, or reconciled with Iceberg state; when Iceberg shows detached or dirty repository state; or when diagnosing mismatches between image packages, Tonel files, .project metadata, branches, remotes, and Git diffs.
---

# Pharo Image Git Handoff

## Mental Model

Pharo image state, Tonel files, Iceberg working copies, and Git refs are related
but distinct.

- The image contains the live classes, methods, packages, and repository
  registrations.
- Tonel files are the disk serialization of packages.
- Iceberg tracks package membership, source directory, repository metadata, and
  the image-side loaded version.
- Git tracks files, commits, branches, remotes, and upstreams.
- A linked Git worktree has a `.git` file that points to the actual worktree
  Git directory instead of a `.git` directory at the checkout root.
- `.project` records project/package metadata that should agree with the
  Iceberg source directory and disk layout.

Do not assume that a clean Git worktree means the image is clean, or that an
Iceberg dirty state means Git has file changes.

## Workflow

1. Inspect before changing disk:
   - Use Pharo MCP repository tools to list the image-side repository.
   - Check repository name, path, branch, head, upstream, source directory,
     managed packages, modified packages, and missing/detached state.
   - Use shell Git only for disk facts: `git status --short --branch`, `git
     diff`, `git remote -v`, and branch tracking.

2. Decide whether export is needed:
   - If the task is inspection, summary, or live-image verification, do not
     export.
   - Export only when preparing a real Tonel/Git handoff or when another
     workflow truly needs files on disk.

3. Preflight the handoff:
   - Confirm the intended repository, branch, remote, source directory, and
     package set.
   - Stop and diagnose detached working copies, missing branch/head, mismatched
     source directory, unexpected package membership, or duplicate repository
     names.
   - If the image-side loaded version is stale but the image contents match
     current Git HEAD, adopting the current commit can be safe; otherwise get
     explicit user judgment.

4. Export and verify:
   - Export through the Pharo MCP repository tool when possible.
   - After export, re-check image-side repository state.
   - Check `git status --short --branch` and `git diff`.
   - Make sure the diff contains only intended Tonel/project/documentation
     changes.

5. Commit and push only after review:
   - Do not commit stale image state, wrong-repo changes, unrelated files, or
     generated churn.
   - Commit only after repository identity, branch, remote, source directory,
     package set, and diff all line up.
   - Push only when the user asked for it or clearly approved it.

## Stop And Diagnose

Pause before mutating disk or Git history when you see:

- detached working copy or missing loaded commit;
- missing branch/head/upstream;
- `.project` source directory differs from Iceberg source directory;
- packages loaded in the image are not managed by the repository;
- repository name is duplicated in the image;
- Git branch or remote is not the intended target;
- Git is clean but Iceberg says all packages are modified;
- Iceberg is clean but Git has unexpected Tonel changes.

## Common Repairs

Use repairs only when the evidence is strong.

- Reattach/adopt current HEAD only when loaded package contents match that
  commit.
- Set the Iceberg source directory from `.project` only when the disk layout
  confirms it.
- Re-add managed packages only when they belong to the repository and are
  present under the source directory.
- For wrong remote, wrong branch, duplicate repository, or real divergent
  history, ask the user instead of guessing.

## Reporting

Report:

- image repository state before export;
- whether export was needed and why;
- export action taken;
- image repository state after export;
- Git branch/status and diff summary;
- tests or smoke checks run;
- any unresolved Iceberg/Git ambiguity.
