# Using The Pharo MCP Server

Applies when an agent or user wants to interact with a running Pharo image
through MCP tools.

## Goal

Use the server as the source of truth for live Pharo image state. Source files
and memory are useful context, but the running image decides what classes,
methods, packages, repositories, and tests currently exist.

## Start And Connect

Load MCP in a Pharo image:

```smalltalk
Metacello new
	baseline: 'MCP';
	repository: 'github://Evref-BL/MCP:main/src';
	load
```

Start the server:

```smalltalk
mcp := MCP new.
mcp port: 4000.
mcp start
```

Keep the image running while clients use the server. If a different port is
used, update the client configuration accordingly.

## Tool Discovery

Do not rely on memory for exact MCP tool names. First inspect the available
`pharo` MCP tools exposed by the current client, then read the matching tool
description and input schema.

When the client exposes catalog tools, use them first:

- discover tools by `group` or `query`;
- inspect the chosen tool's schema before calling it;
- call discoverable tools through the catalog bridge when they are not exposed
  directly by the client.

Use single search terms like these to find the right tool:

| Task | Search Terms |
| --- | --- |
| Source control | repository, repo, Iceberg, Tonel, Git, export, diff, branch, commit, pull, push, fetch |
| Project load | load, baseline, Metacello, repository, package |
| Package | package, tag |
| Class | class, inspect, superclass, subclass, slot, trait, comment |
| Method | method, selector, protocol, source, implementor, sender, reference, variable |
| Edit | edit, create, update, rename, remove, rewrite, preview, apply |
| Test | test, SUnit, coverage, timeout |
| Code history | history, change, entry, browse, list, apply, revert, recover |
| Screenshot | screenshot, window, display |
| Debugging | debug, session, state, variable, breakpoint, capture, control, repair |
| Evaluation | evaluate, expression |

Prefer the least-mutating tool that answers the question. Use query or inspect
tools before edit tools, preview or diff before export or commit operations,
and use `evaluate` only when no dedicated tool covers the task.

For debugger work, discover the `debugging` tool group and inspect the selected
tool schema before invoking it. Read `debugging.md` before using debug
sessions, breakpoints, frame-scoped evaluation, or debugger-driven repair.

## Lookup Rules

For method lookup:

- discover the method/reference tool from the current client;
- use `find-method-implementors` for selector implementors;
- use `find-method-senders` for selector sends;
- use `find-class-references` for class binding references;
- use `find-variable-references` for variable references;
- use `find-methods` for method metadata/source search, `where` predicates,
  and equivalent-AST matching.

If a client does not expose the focused lookup tools yet, use the compatible
`find-methods` modes: exact selector filtering for implementors,
`selectorReference` for senders, `classReference` for class references, and
`variableReference` for variable references.

Report incomplete or failing tool results clearly. Do not silently guess from
memory or exported source when the question depends on image state.

## Image State

The image is saved automatically after each tool call that can change image
state.

Remember:

- loaded image state can differ from Tonel files on disk;
- Iceberg state can differ from both the image and Git checkout;
- source inspection cannot prove the server starts or tools run in the image.

When image access is unavailable, say which live check is blocked.

## Reusable Skills

The `templates/skills/` directory contains reusable skills. After copying the
template into a project, those skills live under `skills/` in the target
project.

Use these skills when the task matches:

- `pharo-project-load`: load Pharo projects from Tonel, Metacello, or Iceberg
  repositories.
- `pharo-version-compat`: make projects run across supported Pharo versions
  with PharoCompatibility.
- `pharo-image-git-handoff`: turn image-side changes into clean Tonel/Git
  changes.
- `pharo-ci-repro`: reproduce GitHub/smalltalkCI failures locally.
