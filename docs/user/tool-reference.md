# Tool Reference

MCP exposes tools through `tools/list` and `tools/call`. Common tools can be
advertised directly; less common tools can be found through the catalog tools.
Tool names use hyphenated MCP names.

Every tool returns MCP call content plus structured content. Structured content
uses this common shape:

```text
status: ok | error
summary: human-readable summary
warnings: array of warning strings
data: structured success payload
error: structured error payload
```

`data` is present on success. `error` is present on failure.

## Tool Catalog

| Tool | Use |
| --- | --- |
| `discover-tools` | Search the tool catalog by group, keyword, title, or description. |
| `inspect-tool` | Return the full schema and metadata for one catalog tool. |
| `call-tool` | Invoke a catalog tool that is not exposed directly by the current client. |

Use `discover-tools` before calling less common or high-risk tools. Inspect the
schema before invoking a discoverable tool.

## Repositories

| Tool | Use |
| --- | --- |
| `find-repositories` | List Iceberg repositories registered in the image, including location, branch/head metadata, exact head commit id, modified packages, remotes, and upstream details. |
| `verify-repository-identity` | Assert expected Iceberg repository identity fields before edits, exports, commits, pulls, or pushes. |
| `find-repository-changes` | Inspect Iceberg `workingCopyDiff` without writing files. |
| `edit-repository` | Create, attach, update, or use the legacy broad repository operation surface through Iceberg. |
| `export-repository` | Export image-side package changes to Tonel files and update the Iceberg index without staging or committing Git changes. |
| `commit-repository` | Commit Iceberg repository changes with a message. |
| `fetch-repository` | Fetch repository remotes through Iceberg. |
| `pull-repository` | Pull through Iceberg. |
| `push-repository` | Push through Iceberg. |
| `create-repository-branch` | Create and switch to a new repository branch through Iceberg. |
| `switch-repository-branch` | Switch to an existing repository branch through Iceberg. |
| `adopt-repository-head` | Adopt the current repository head as the Iceberg working-copy reference after verifying the image and Git state. |
| `load-repository` | Load a Metacello baseline from a remote repository or an already-known baseline. |

Use `verify-repository-identity` before edits or exports, and
`find-repository-changes` before exporting or committing image changes.
Identity verification requires at least one expected identity field, such as
`location`, `branchName`, `subdirectory`, `packageNames`,
`modifiedPackageNames`, or `isModified`.

## Packages

| Tool | Use |
| --- | --- |
| `find-packages` | List packages and filter by project names, package names, metadata, and recursive `where` predicates. |

## Classes

| Tool | Use |
| --- | --- |
| `find-classes` | List classes and filter by class metadata, package, hierarchy, scope, and `where` predicates. |
| `inspect-class` | Inspect one class by name and return structured class metadata with optional superclass and subclass context. |
| `edit-class` | Create classes and apply one class update action at a time: rename, move, recategorize, reparent, edit comment, replace slots, replace traits, replace shared variables, replace shared pools, replace layout, or perform slot actions. |
| `remove-classes` | Remove classes as one batch. Refactoring warnings stop removal unless `force=true`. |

`edit-class` and `remove-classes` use Pharo refactoring support where available.
With `force=false`, refactoring warnings return impact details instead of
continuing.

## Methods

| Tool | Use |
| --- | --- |
| `find-methods` | List/search methods by selector, class, package, protocol, source, scope, recursive predicates, or equivalent ASTs. |
| `find-method-implementors` | Find methods that implement a selector. |
| `find-method-senders` | Find methods that send a selector. |
| `find-class-references` | Find methods that reference a class binding. |
| `find-variable-references` | Find methods that reference a variable. |
| `inspect-method` | Inspect one known method and return source plus structured variable-reference context. |
| `edit-method` | Create or update one method. Updates can rename selectors, add/remove arguments, reorder arguments, or recategorize protocols. |
| `rewrite-methods` | Preview or apply AST rewrite rules across a method scope. Applying requires `expectedChangeSetHash` from a preview. |
| `remove-methods` | Remove methods from one class as a batch without sender safety checks. |

Prefer the focused lookup tools for navigation tasks. Keep `find-methods` for
method metadata/source search, `where` predicates, and equivalent-AST matching.

The legacy `find-methods` lookup modes remain supported for compatibility:

- `filterMode=exact` and `filterTargets=selector` for implementors
- `filterMode=selectorReference` for senders
- `filterMode=classReference` for class references
- `filterMode=variableReference` for variable references

`edit-method` returns selected Renraku critiques after method compilation when
they are relevant to review.

## History

| Tool | Use |
| --- | --- |
| `find-change-history-files` | List Epicea `.ombu` change-history files, including the current history file. |
| `find-change-history-entries` | List entries from the current image change history or a selected `.ombu` file. |
| `manage-change-history` | Preview applying or reverting selected entries, and perform the selected action with `confirm=true`. |

Prefer the focused read-only tools when browsing history. Use
`manage-change-history` when you need apply/revert preview or confirmation.

## Tests

| Tool | Use |
| --- | --- |
| `run-tests` | Run SUnit test classes or individual methods. Use `operation=coverage` with an explicit method scope to collect method and node coverage. |

## UI

| Tool | Use |
| --- | --- |
| `capture-screenshot` | Capture the active Morphic world and return MCP image content with dimensions and MIME type metadata. |

## Debugging

The debugger tools are discoverable under the `debugging` group. Read
[Debugging with MCP](debugging.md) before using them.

| Tool | Use |
| --- | --- |
| `debug-capture` | Evaluate a Smalltalk expression in a bounded worker process and capture runtime exceptions as tracked debug sessions. |
| `debug-test` | Run one SUnit test method under debugger control and capture failures or errors as tracked debug sessions. |
| `debug-sessions` | List, describe, forget, discover, or attach tracked sessions and open debugger candidates. |
| `debug-state` | Return a debug-session snapshot with stack, selected frame, source, scopes, repair actions, and state-scoped references. |
| `debug-variables` | Expand scope and variable references returned by `debug-state`. |
| `debug-evaluate` | Evaluate a Smalltalk expression in a selected debug frame. |
| `debug-control` | Step, restart, resume, or terminate a tracked debug session. |
| `debug-breakpoints` | Manage transient DebugPoint breakpoints. |
| `debug-edit` | Create or hot-recompile the method implied by a paused debug state, then proceed when possible. |

## Scripting

| Tool | Use |
| --- | --- |
| `evaluate` | Evaluate arbitrary Smalltalk and return a bounded preview of the result. |

Use `evaluate` only when no dedicated tool fits. A successful evaluation can
mutate and save the image.

## Mutation And Saving

Most query tools are read-only and do not save the image. Mutating tools save
the image after a successful call.

Tools that can save after success include:

```text
edit-class
edit-method
edit-repository
export-repository
commit-repository
fetch-repository
pull-repository
push-repository
create-repository-branch
switch-repository-branch
adopt-repository-head
load-repository
remove-classes
remove-methods
rewrite-methods when apply=true and changes were applied
manage-change-history when entries were performed
debug-control
debug-breakpoints
debug-edit when a method is accepted
evaluate
```

`verify-repository-identity` and `find-repository-changes` are read-only.

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
