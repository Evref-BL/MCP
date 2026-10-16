# Tool Reference

MCP exposes tools through `tools/list` and `tools/call`. Common tools can be
advertised directly; less common tools can be found through the catalog tools.
Tool names use `snake_case` names that generally put the domain before the
action.

By default, every tool returns MCP call `content` as the canonical response for
LLMs. The text block contains the complete tool payload encoded as JSON using
this common shape:

```text
status: ok | error
summary: human-readable summary
warnings: array of warning strings
data: structured success payload
error: structured error payload
```

`data` is present on success. `error` is present on failure.

For clients or integrations that need programmatic payloads, configure the
server response fields before `start`:

```smalltalk
mcp useContentOnlyToolResponses. "default"
mcp useStructuredContentOnlyToolResponses.
mcp useContentAndStructuredContentToolResponses.
```

## Compact Paging

List and search tools are optimized for low token usage. Broad tools return a
small page by default and put only the entry array in `data`. When another page
exists, `data` includes `nextOffset`; call the same tool again with that
`offset` to continue.

Use the returned array size for the current page and follow `nextOffset` when
present. Request larger pages only when the next step truly needs more entries.

## Tool Catalog

| Tool | Use |
| --- | --- |
| `tool_search` | Search the tool catalog by group, keyword, title, or description. |
| `tool_get` | Return input schema and metadata for one catalog tool. |
| `tool_call` | Invoke a catalog tool that is not exposed directly by the current client. |

Use `tool_search` before calling less common or high-risk tools. Inspect the
schema before invoking a discoverable tool.

## Repositories

| Tool | Use |
| --- | --- |
| `repository_search` | List Iceberg repositories registered in the image, including location, branch/head metadata, exact head commit id, modified packages, remotes, and upstream details. |
| `repository_identity_verify` | Assert expected Iceberg repository identity fields before edits, exports, commits, pulls, or pushes. |
| `repository_change_list` | Inspect Iceberg `workingCopyDiff` without writing files. |
| `repository_create` | Create a new Iceberg repository directory and optionally attach initial packages. |
| `repository_attach` | Register an existing Git checkout, including a linked Git worktree checkout, and optionally attach packages. |
| `repository_update` | Change image-side repository subdirectory or package membership without exporting packages. |
| `repository_export` | Export image-side package changes to Tonel files and update the Iceberg index without staging or committing Git changes. |
| `repository_commit` | Commit Iceberg repository changes with a message. |
| `repository_fetch` | Fetch repository remotes through Iceberg. |
| `repository_pull` | Pull through Iceberg. |
| `repository_push` | Push through Iceberg. |
| `repository_branch_create` | Create and switch to a new repository branch through Iceberg. |
| `repository_branch_switch` | Switch the Iceberg repository head to an existing branch without loading package changes into the image. |
| `repository_branch_checkout` | Check out an existing repository branch and load changes for packages already loaded in the image. |
| `repository_head_adopt` | Adopt the current repository head as the Iceberg working-copy reference after verifying the image and Git state. |
| `baseline_load` | Load an already-known Metacello baseline available in the image. |
| `repository_load` | Load a Metacello baseline from a remote repository. |

Use `repository_identity_verify` before edits or exports, and
`repository_change_list` before exporting or committing image changes.
Identity verification requires at least one expected identity field, such as
`location`, `branchName`, `subdirectory`, `packageNames`,
`modifiedPackageNames`, or `isModified`.

Use plural fields such as `repositoryNames`, `directoryPaths`, and
`packageNames` for exact repository scope. Use singular text filters such as
`repositoryName`, `branchName`, `headCommitId`, `remoteUrl`, and
`upstreamBranchName` for field-specific matching.

## Packages

| Tool | Use |
| --- | --- |
| `package_search` | List packages by project/package scope, with optional `packageName`, `projectName`, and `tag` filters. |

## Classes

| Tool | Use |
| --- | --- |
| `class_search` | List classes by package/class/hierarchy scope, with optional `className`, `tag`, `instanceSlot`, and `classSlot` filters. |
| `class_get` | Get one class by name and return structured class metadata with optional superclass and subclass context. |
| `class_create` | Create one class definition. |
| `class_name_update` | Rename one class through the Refactoring Engine. |
| `class_superclass_update` | Change one class superclass. |
| `class_package_update` | Move one class to a package and/or recategorize it under a package tag. |
| `class_comment_update` | Set or clear one class comment. |
| `class_slots_update` | Replace instance-side and/or class-side slot definitions. |
| `class_traits_update` | Replace instance-side trait composition. |
| `class_side_traits_update` | Replace class-side trait composition. |
| `class_shared_variables_update` | Replace class variables. |
| `class_shared_pools_update` | Replace shared pools. |
| `class_layout_update` | Replace the layout class. |
| `class_slot_add` | Add one instance-side or class-side slot. |
| `class_slot_remove` | Remove one instance-side or class-side slot. |
| `class_slot_name_update` | Rename one instance-side or class-side slot. |
| `class_slot_pull_up` | Pull one instance-side or class-side slot up to a superclass. |
| `class_slot_push_down` | Push one instance-side or class-side slot down to subclasses. |
| `class_remove` | Remove classes as one batch. Refactoring warnings stop removal unless `force=true`. |

Class mutation tools and `class_remove` use Pharo refactoring support
where available. With `force=false`, refactoring warnings return impact details
instead of continuing.

## Methods

| Tool | Use |
| --- | --- |
| `method_metadata_search` | List/search methods by class/package/hierarchy scope, with optional `selector` and `protocol` filters. |
| `method_source_search` | Search methods by source text. |
| `method_equivalent_search` | Search methods whose AST is equivalent to a referenced method. |
| `method_implementor_search` | Search methods that implement a selector. |
| `method_sender_search` | Search methods that send a selector. |
| `method_class_reference_search` | Search methods that reference a class binding. |
| `method_variable_reference_search` | Search methods that reference a variable. |
| `method_get` | Get one known method and return source plus structured variable-reference context. |
| `method_compile` | Create or replace one method from source. |
| `method_selector_update` | Rename selectors, add/remove arguments, or reorder arguments through the Refactoring Engine. |
| `method_protocol_update` | Move one method to another regular or extension protocol. |
| `method_rewrite` | Preview or apply AST rewrite rules across a method scope. Applying requires `expectedChangeSetHash` from a preview. |
| `critique_run` | Run selected or all Renraku critiques over a scope and return hits grouped by rule class. |
| `method_remove` | Remove methods from one class as a batch without sender safety checks. |

Prefer the specialized lookup tools for navigation tasks. Use
`method_source_search` for source text and `method_equivalent_search` for
equivalent-AST matches. Keep `method_metadata_search` for method metadata
search. Top-level `method_metadata_search` filtering is limited to `selector`
and `protocol` fields (`substring`, `prefix`, `exact`, or `regex`); use
specialized tools for source, equivalent methods, implementors, senders, class
references, and variable references.

`method_compile` returns selected Renraku critiques after method compilation when
they are relevant to review.

## History

| Tool | Use |
| --- | --- |
| `history_file_list` | List Epicea `.ombu` change-history files, including the current history file. |
| `history_entry_list` | List entries from the current image change history or a selected `.ombu` file. |
| `history_entry_apply` | Preview applying selected entries, and apply them with `confirm=true`. |
| `history_entry_revert` | Preview reverting selected entries, and revert them with `confirm=true`. |

Prefer the read-only tools when browsing history. Use
`history_entry_apply` or `history_entry_revert` when you need apply/revert
preview or confirmation.

## Tests

| Tool | Use |
| --- | --- |
| `test_run` | Run SUnit test classes or individual methods. |
| `test_coverage_run` | Run SUnit test classes or individual methods while collecting method and node coverage for an explicit method scope. |

## UI

| Tool | Use |
| --- | --- |
| `screenshot_capture` | Capture the active Morphic world and return MCP image content with dimensions and MIME type metadata. |

## Debugging

The debugger tools are discoverable under the `debugging` group. Read
[Debugging with MCP](debugging.md) before using them.

| Tool | Use |
| --- | --- |
| `debug_capture` | Evaluate a Smalltalk expression in a bounded worker process and capture runtime exceptions as tracked debug sessions. |
| `debug_test_run` | Run one SUnit test method under debugger control and capture failures or errors as tracked debug sessions. |
| `debug_session_list` | List tracked debug sessions. |
| `debug_session_get` | Inspect one tracked debug session summary. |
| `debug_session_remove` | Remove a tracked debug session from the registry. |
| `debug_candidate_search` | Search unattached open debugger candidates. |
| `debug_candidate_attach` | Attach an open debugger candidate and return its debug state. |
| `debug_state_get` | Return a debug-session snapshot with stack, selected frame, source, scopes, repair actions, and state-scoped references. |
| `debug_variable_get` | Expand scope and variable references returned by `debug_state_get`. |
| `debug_expression_evaluate` | Evaluate a Smalltalk expression in a selected debug frame. |
| `debug_session_step_into` | Step into the selected frame of a tracked debug session. |
| `debug_session_step_over` | Step over the selected frame of a tracked debug session. |
| `debug_session_step_through` | Step through the selected frame of a tracked debug session. |
| `debug_session_restart` | Restart the selected frame of a tracked debug session. |
| `debug_session_resume` | Resume a tracked debug session. |
| `debug_session_terminate` | Terminate a tracked debug session. |
| `debug_breakpoint_list` | List tracked transient DebugPoint breakpoints. |
| `debug_breakpoint_set` | Install a transient method-entry or source-interval DebugPoint breakpoint. |
| `debug_breakpoint_remove` | Remove one tracked transient DebugPoint breakpoint. |
| `debug_breakpoint_enable` | Enable one tracked transient DebugPoint breakpoint. |
| `debug_breakpoint_disable` | Disable one tracked transient DebugPoint breakpoint. |
| `debug_breakpoint_clear` | Remove all tracked transient DebugPoint breakpoints. |
| `debug_method_update` | Update the method associated with a paused debug state, then proceed when possible. |

## Scripting

| Tool | Use |
| --- | --- |
| `image_evaluate` | Evaluate arbitrary Smalltalk and return a bounded preview of the result. |

Use `image_evaluate` only when no dedicated tool fits. A successful evaluation can
mutate and save the image.

## Mutation And Saving

Most search and inspection tools are read-only and do not save the image.
Mutating tools save the image after a successful call.

Tools that can save after success include:

```text
class_create
class_name_update
class_package_update
class_comment_update
class_slot_add
class_slot_remove
class_slot_name_update
method_compile
method_selector_update
method_protocol_update
repository_create
repository_attach
repository_update
repository_export
repository_commit
repository_fetch
repository_pull
repository_push
repository_branch_create
repository_branch_switch
repository_branch_checkout
repository_head_adopt
baseline_load
repository_load
class_remove
method_remove
method_rewrite when apply=true and changes were applied
history_entry_apply when entries were performed
history_entry_revert when entries were performed
debug_expression_evaluate
debug_capture
debug_test_run
debug_method_update when a method is accepted
image_evaluate
```

`repository_identity_verify` and `repository_change_list` are read-only.

## Refactoring Warnings

For edit tools that use refactoring operations, `force=false` is the default.
When Pharo raises `RBRefactoringWarning`, the tool returns an error with:

```text
impactMessages
howToProceed
forceSupported: true
```

Rerun with `force=true` only after reviewing the impact. Forced warnings are
returned as normal warnings in the successful result.
