# DevNexus Verification Boundary

This document maps which MCP-Pharo checks can run during DevNexus dogfood
planning without launching a live image, and which checks require a future
isolated PLexus runner.

## Safe Static Verification

These checks do not require a running Pharo image:

- `git status --short --branch`
- `git diff --check`
- file layout inspection for expected package directories
- review of `BaselineOfMCP/BaselineOfMCP.class.st`
- search for expected tool classes and test classes in exported source files
- review of `AGENTS.md`, `readme.md`, and this boundary document
- review of package dependencies, baseline groups, and test package names

These checks can confirm that source files, package declarations, and
documentation are coherent. They cannot prove the image has loaded the code,
that the HTTP server starts, or that tool execution works in a live image.

## Boundary For Pharo MCP Tools

The repository `AGENTS.md` says to use the `pharo` MCP server when the answer
depends on live image state. In this DevNexus dogfood target, live image access
is not authorized. If an answer depends on image state, the correct result is a
blocked follow-up that requires the isolated runner and human approval.

Do not use `pharo` MCP tools, `evaluate`, image-side test execution, image
saves, or image export commands in a planning-only cycle.

## Checks Requiring The Isolated Runner

These checks require a disposable image, PLexus cleanup hooks, and explicit
approval:

- loading `BaselineOfMCP` into a clean image
- starting `MCP` over HTTP
- verifying `tools/list`
- running `MCP-Tests` or `MCP-Spec-Tests` inside the image
- routed PLexus `pharo` calls such as package, class, method, or test queries
- edit, rewrite, export, or repository mutation tools
- image save or image-local Git operations

The runner must pass an explicit `imageId` for routed calls and must not grant
agents raw host-wide launcher access.

## Disposable Inputs Required For Live Verification

A future live verification must name:

- the source image or template
- the copied image name pattern
- the PLexus `workspaceId`, `targetId`, and `stateRoot`
- the MCP port allocation policy
- the exact test packages or smoke calls
- the cleanup sequence for image close, process stop, copied image deletion,
  and retained logs

## Follow-Up Work

The component-owned follow-up after this boundary is to run the MCP-Pharo live
verification through the approved isolated runner. Until that runner exists and
approval is recorded, MCP-Pharo verification remains limited to static source
inspection.
