# Source vs Live Image Checks

This document maps which checks for this repository can run from source only
and which checks require a live Pharo image. It does not define or depend on
any external orchestration project.

## Safe Static Verification

These checks do not require a running Pharo image:

- `git status --short --branch`
- `git diff --check`
- file layout inspection for expected package directories
- review of `src/BaselineOfMCP/BaselineOfMCP.class.st`
- search for expected tool classes and test classes in exported source files
- review of `dev/AGENTS.md`, `user/AGENTS.md`, `readme.md`, and this document
- review of package dependencies, baseline groups, and test package names

These checks can confirm that source files, package declarations, and
documentation are coherent. They cannot prove the image has loaded the code,
that the HTTP server starts, or that tool execution works in a live image.

## Live Image Boundary

Use live image checks when the answer depends on image state. If the current
work context is not approved to launch or mutate a live image, stop at static
verification and record the live check as blocked.

Do not use image-side evaluation, image-side test execution, image saves, or
image export commands in a static-only verification pass.

## Checks Requiring A Live Image

These checks require an explicitly approved disposable or safe live image:

- loading `BaselineOfMCP` into a clean image
- starting `MCP` over HTTP
- verifying `tools/list`
- running `MCP-Tests` or `MCP-Spec-Tests` inside the image
- package, class, method, or test queries against the running image
- edit, rewrite, export, or repository mutation tools
- image save or image-local Git operations

## Disposable Inputs Required For Live Verification

A future live verification should name:

- the source image or template
- the copied image or disposable image naming policy
- the MCP port allocation policy
- the exact test packages or smoke calls
- the cleanup sequence for stopping the image, deleting disposable image
  artifacts, and retaining logs

## Follow-Up Work

Until a live image boundary is approved for the current work context,
verification remains limited to static source inspection.
