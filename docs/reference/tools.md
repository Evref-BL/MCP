# Tool Reference

MCP exposes tools through `tools/list` and `tools/call`. Tool names use
hyphenated MCP names.

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

## Repositories

| Tool | Use |
| --- | --- |
| `find-repositories` | List Iceberg repositories registered in the image, including location, branch/head metadata, exact head commit id, modified packages, remotes, and upstream details. |
| `edit-repository` | Create, update, diff, export, commit, fetch, pull, push, create branches, or switch branches through Iceberg. |
| `load-repository` | Load a Metacello baseline from a remote repository or an already-known baseline. |

Use `edit-repository` with `operation=diff` before exporting or committing image
changes.

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
| `find-methods` | List methods, find implementors, find senders, find class or variable references, query recursive predicates, or match equivalent ASTs. |
| `inspect-method` | Inspect one known method and return source plus structured variable-reference context. |
| `edit-method` | Create or update one method. Updates can rename selectors, add/remove arguments, reorder arguments, or recategorize protocols. |
| `rewrite-methods` | Preview or apply AST rewrite rules across a method scope. Applying requires `expectedChangeSetHash` from a preview. |
| `remove-methods` | Remove methods from one class as a batch without sender safety checks. |

Use `find-methods` with:

- `filterMode=exact` and `filterTargets=selector` for implementors
- `filterMode=selectorReference` for senders
- `filterMode=classReference` for class references
- `filterMode=variableReference` for variable references

`edit-method` returns selected Renraku critiques after method compilation when
they are relevant to review.

## History

| Tool | Use |
| --- | --- |
| `manage-change-history` | List Epicea `.ombu` files and entries, preview applying or reverting selected entries, and perform the selected action with `confirm=true`. |

## Tests

| Tool | Use |
| --- | --- |
| `run-tests` | Run SUnit test classes or individual methods. Use `operation=coverage` with an explicit method scope to collect method and node coverage. |

## UI

| Tool | Use |
| --- | --- |
| `capture-screenshot` | Capture the active Morphic world and return MCP image content with dimensions and MIME type metadata. |

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
load-repository
remove-classes
remove-methods
rewrite-methods when apply=true and changes were applied
manage-change-history when entries were performed
evaluate
```

`edit-repository` does not save for `operation=diff`.

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
