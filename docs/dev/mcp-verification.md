# MCP-Pharo Verification

Applies when verifying changes to this MCP repository.

Read after:

- `docs/user/source-vs-live-image.md`
- `docs/dev/developing-mcp.md`

## Goal

Map generic Pharo source/live-image verification rules to this repository's
packages, baseline, tests, and server behavior.

## Static Checks For This Repository

These checks do not require a running Pharo image:

- `git status --short --branch`
- `git diff --check`
- file layout inspection under `src/`
- review of `src/BaselineOfMCP/BaselineOfMCP.class.st`
- search for expected tool classes and test classes in exported source files
- review of `AGENTS.md`, `templates/AGENTS.md`, `README.md`, and `docs/`
- review of package dependencies, baseline groups, and test package names

These checks can confirm that exported source, package declarations, and docs
are coherent. They cannot prove the image has loaded the code, that the HTTP
server starts, or that MCP tool execution works in a live image.

## Live Image Boundary

Use Pharo 13 as the default disposable development image for MCP live smoke
checks.

Use Pharo 12 and Pharo 14 for compatibility verification when a change touches
version-sensitive behavior.

If the current work context is not approved to launch or mutate a live image,
stop at static verification and report the live checks as blocked.

Do not use image-side evaluation, image-side test execution, image saves, or
image export commands in a static-only verification pass.

## MCP Live Checks

These checks require an explicitly approved disposable or safe live image:

- loading `BaselineOfMCP` into a clean image;
- starting `MCP` over HTTP;
- verifying tool listing;
- running `MCP-Tests` or `MCP-UI-Tests` inside the image;
- package, class, method, or test queries against the running image;
- debugger capture, attach, state, control, breakpoint, and repair smoke calls
  when debugger behavior changes;
- edit, rewrite, export, or repository operation tools;
- image save or image-local Git operations.

## Disposable Inputs Required For Live Verification

A live verification plan should name:

- the source image or template;
- the copied image or disposable image naming policy;
- the MCP port allocation policy;
- the exact test packages or smoke calls;
- the cleanup sequence for stopping the image, deleting disposable artifacts,
  and retaining logs.

## Reporting

When verification is static-only, say so explicitly.

When live verification runs, report:

- image version;
- source checkout or loaded repository;
- smoke calls or test packages run;
- result;
- cleanup performed.
