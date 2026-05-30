# Troubleshooting

Most failures fall into one of three groups: the image is not reachable, the
requested tool input is invalid, or the live image state differs from what the
caller expected.

## The Client Cannot Connect

Check the server in the image:

```smalltalk
mcp isRunning.
mcp isListening.
mcp localUrlString.
```

Confirm that the client URL uses the same host and port:

```text
http://127.0.0.1:4000
```

If you changed the port in Pharo, update the MCP client configuration.

MCP currently handles MCP calls over HTTP POST. Unsupported HTTP methods
return method-not-allowed instead of hanging.

## `tools/list` Is Empty Or Stale

Run:

```smalltalk
mcp refreshToolsList.
```

Then call `tools/list` again. If you loaded new MCP code into the image, restart
the server:

```smalltalk
mcp restart.
```

## A Tool Rejects Input

Each tool validates arguments against its input schema. Call `tools/list` and
inspect the tool's `inputSchema`.

Common causes:

- missing required operation fields
- extra fields rejected by `additionalProperties: false`
- `operation=update` with more than one patch action
- `method_rewrite` with `apply=true` but no `expectedChangeSetHash`
- `history_entry_apply` or `history_entry_revert` without `confirm=true`

## A Refactoring Stops With A Warning

This is expected for Pharo refactoring warnings. With `force=false`, the edit
tool stops and returns impact details.

Read:

```text
impactMessages
howToProceed
forceSupported
```

Rerun with `force=true` only when the impact is acceptable.

## A Method Compiles But Returns Critiques

`method_create` can return Renraku critiques after compilation. The method exists,
but Pharo found review issues. Inspect the critique rule class, title,
description, and source interval if present.

Use a follow-up `method_create`, `method_selector_update`, `test_run`, or
`method_get` call depending on the critique.

## Repository State Looks Wrong

MCP reads repository state from Iceberg in the running image. The exported
Tonel files, the image's loaded packages, and Iceberg's working-copy state can
differ.

Start with:

```text
repository_search
repository_identity_verify
repository_change_list
```

Use `repository_export` only when you mean to write image changes to files.
Export updates the Iceberg index but does not stage or commit Git changes.

## Tests Do Not Prove The Edited Scope

`test_run` tells you whether selected tests passed. Use `test_coverage_run` with
an explicit coverage scope when you need to know whether the edited methods
executed.

Coverage scopes should be narrow: package, class, hierarchy, or method names.

## The Image Changed Unexpectedly

Image-changing tools save the image after successful mutation. If you are using
an automation or agent, run it against a copied or disposable image.

Use `history_file_list` and `history_entry_list` to inspect
Epicea history. Apply or revert operations stay in `history_entry_apply` and
`history_entry_revert`, where they can be previewed first and performed with
`confirm=true`.

## Debugger References Are Stale

Debugger `stateId`, `frameRef`, and `variableRef` values are scoped to one
debug_state_get snapshot. After a control action, debugger edit, or resume, discard
old references and use the newly returned state.

If a human opened the debugger, attach through the debugging tools and let the
debugger controller own UI actions. Do not drive debugger windows with raw
`image_evaluate` code.

## Source Checks Are Not Enough

Exported source files can confirm package layout, class definitions, and docs.
They cannot prove that the running image has loaded the latest code or that an
MCP tool works over HTTP.

Use [Source vs live image](source-vs-live-image.md) to decide which checks are
valid for the current work boundary.
