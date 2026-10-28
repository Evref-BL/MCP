---
name: pharo-image-sync
description: Move code between a live Pharo image and its Tonel files, and tell the two apart. Use before exporting image changes, after a checkout moves under the image, and whenever Iceberg, the image and the files disagree.
---

# Pharo Image Sync

The image holds objects, the repository holds files, and Iceberg holds its own
idea of both. A clean `git status` does not mean the image is clean, and an
Iceberg diff does not mean anything was written to disk.

Git itself is ordinary shell work. These tools only cross the boundary between
the image and the files.

## Out Of The Image

1. Verify which repository you are about to write to: `repository_search` for
   its location, branch and packages, then `repository_identity_verify` with
   what you expect, which fails rather than guessing.
2. Read the image-side diff with `repository_change_list` before writing
   anything.
3. `repository_export` writes the changed packages to Tonel and updates the
   Iceberg index. It stages and commits nothing.
4. Read the files it touched with `git diff`. Export writes what the image
   holds, which includes anything loaded into it that you did not put there.

## Into The Image

A checkout that moves under a running image leaves it running the old code.
After a branch switch, a pull, a merge or a rebase, `repository_reload` loads
the packages from the files again.

Reloading can leave classes behind in `Undeclared` when a superclass moved,
with subclasses still parented to an obsolete one. The symptom is tests failing
on classes nobody edited. Load that package again by name to repair it.

## Stop And Ask

Stop when two registrations claim the same packages, when the branch, source
directory or package membership is not what you expect, when a head is detached
or missing, or when Iceberg and the files disagree for no reason you can name.
Resolving real divergence, or discarding image changes, is the user's call.

## Report

Say what the image held, what was written, which files changed, and what you
did not verify.
