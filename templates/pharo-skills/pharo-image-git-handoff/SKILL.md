---
name: pharo-image-git-handoff
description: Reconcile live Pharo, Iceberg, Tonel, and Git state before exporting, reviewing, committing, or pushing image-side changes. Use for dirty or detached Iceberg state, linked worktrees, package-membership mismatches, and image-to-Git delivery.
---

# Pharo Image Git Handoff

Image objects, Tonel files, Iceberg working copies, and Git refs are distinct.
A clean Git worktree does not prove the image is clean, and an Iceberg diff does
not prove files changed on disk.

## Workflow

1. Inspect the image repository with Pharo MCP tools: identity, location,
   branch/head, source directory, package membership, and modified packages.
2. Inspect disk with read-only Git commands: `git status --short --branch`,
   `git diff`, and `git remote -v`.
3. Export only for an intended Tonel/Git handoff. Verify repository identity and
   inspect the image-side change list first.
4. After export, recheck Iceberg and Git. Review every changed Tonel, project,
   and documentation path.
5. Commit only the intended diff. Push only when explicitly requested or
   clearly approved.

## Stop Before Mutation

Stop and diagnose detached or missing heads, wrong branches/remotes, duplicate
repository names, source-directory or package-membership mismatches, linked
worktree confusion, and unexplained disagreement between Git and Iceberg.

Adopt the current Git HEAD only when the image contents are known to match it.
Ask the user before resolving real divergence or discarding image changes.

## Report

Report image repository state before and after export, why export was needed,
Git branch/status and diff summary, checks run, and unresolved ambiguity.
