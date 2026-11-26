---
name: pharo-mcp-recovery
description: Recover a Pharo MCP image that takes no calls or crashed, or the changes a stop without saving lost, while preserving logs, image files, changes, repository state, and Epicea history. Use for an unreachable image, a replacement image, and image-side change recovery.
---

# Pharo MCP Recovery

When a tool manages the image's lifecycle, recover through it: its list says
why an image takes no calls, its stop ends the VM, its start brings the image
back as it was last saved, and its create makes a replacement with MCP loaded.
An image you did not start is the user's to recover. Steps 2 to 4 are for an
image launched by hand; steps 1, 5 and 6 hold for every image.

## Workflow

1. Determine whether the failure is the client route, MCP server, image, or
   process. A client that cannot reach the server says nothing yet about the
   image.
2. Preserve the image, changes, sources, VM logs, launch command, MCP URL, and
   repository/Git facts before mutation.
3. Restart the same image first. Inspect `isRunning`, `isListening`, and
   `localUrlString`; restart the existing MCP instance when possible.
4. Create a replacement image only after preserving the original. Use
   `pharo-project-load` to restore MCP and the target project.
5. Recover what the stop lost with `history_lost_change_list`, in the image
   restarted from its last save, before `history_lost_change_restore`
   installs any of it. For anything else the history holds, or a replacement
   image, `history_file_list` finds the history's files and
   `history_entry_list` reads one. A change the image lost may be committed
   all the same: check it against the checkout's `git log` before naming it
   as lost, as `pharo-image-sync` says. Do this before repository attachment
   or Tonel export.
6. Verify the recovered behavior with focused inspection or tests.

## Stop And Ask

Ask before deleting images, resetting repositories, discarding changes,
checking out a branch that changes loaded packages, or applying ambiguous
history entries.

## Report

Report the failure boundary, evidence preserved, image used, restart/recovery
actions, recovered behavior, checks run, and unrecovered state.
