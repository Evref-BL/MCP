---
name: pharo-mcp-recovery
description: Recover stopped Pharo MCP images with restart, reload, and history rescue.
---

# Pharo MCP Recovery

Use this skill when a standalone Pharo MCP server or image is unreachable,
crashed, or restarted and the agent must recover access or image-side changes.
This skill is for standalone MCP use. When a project has managed lifecycle
tools, use that environment's scoped start, stop, reset, and route commands
instead of host-wide manual recovery.

## Recovery Order

1. Identify the failure boundary:
   - MCP client cannot connect: check URL, host, port, and whether the Pharo
     image is still running.
   - Image is running but MCP is stale: evaluate whether the server instance
     can answer, refresh tools, or restart MCP inside the image.
   - Image process stopped or crashed: preserve files and logs before creating
     a replacement.

2. Preserve evidence before mutation:
   - Record image name, image directory, `.image`, `.changes`, `.sources`, VM
     log, launch command, MCP URL, and any repository directories.
   - Record Git branch, head commit, dirty files, and Iceberg repository paths
     when accessible.
   - Do not delete, reset, or overwrite the crashed image until recovery is
     complete or the user approves loss.

3. Restart the same image when possible:
   - Open or start the existing image with the normal launcher or lifecycle
     surface available to the user.
   - If the image opens, inspect MCP state in a Playground:

```smalltalk
mcp isRunning.
mcp isListening.
mcp localUrlString.
```

   - If the object exists but the server is stale, use:

```smalltalk
mcp restart.
mcp refreshToolsList.
```

   - If no server object is available, start a new one:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start.
```

4. Create a replacement image only after preserving the original:
   - Use the available environment mechanism, such as Pharo Launcher,
     `pharo_launcher_*` MCP tools, or another user-approved lifecycle tool.
   - Load MCP and the target project again. Use the `pharo-project-load` skill
     for baseline, repository, branch, source directory, and load-group choices.

5. Recover image-side changes:
   - Use `history_file_list` to find Epicea `.ombu` history files from the old
     image or project directory.
   - Use `history_entry_list` to inspect candidate entries before applying.
   - Use `history_entry_apply` with `confirm=true` only for entries that were
     reviewed and match the intended project.
   - Use repository tools to reattach repositories, verify identity, inspect
     changes, export, and commit. Use the `pharo-image-git-handoff` skill before
     writing Tonel changes to Git.

6. Verify and report:
   - Run focused tests or inspection tools that prove the recovered behavior.
   - Report what was recovered, which image and history files were used, what
     could not be recovered, and any remaining uncertainty.

## Stop And Ask

Stop and ask the user before destructive cleanup, image deletion, repository
reset, branch checkout that would discard image changes, or history application
whose package/class/method target is ambiguous.
