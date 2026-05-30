# Source Files Vs Live Pharo Image State

Applies when an agent uses the Pharo MCP server to inspect, modify, or verify a
Pharo project.

## Goal

Keep source inspection, loaded image state, Iceberg state, and Git state
separate. Each one can answer different questions, and none should be treated
as a substitute for the others.

## Source-Only Checks

Source-only checks can confirm:

- files exist where expected;
- packages, classes, and methods are exported in Tonel;
- baseline files and package declarations look coherent;
- static documentation and scripts are present;
- Git diffs contain the expected source changes;
- formatting and whitespace checks pass.

Source-only checks cannot prove:

- the project loads in the image;
- classes and methods are currently loaded;
- tools see the expected image state;
- tests pass inside the image;
- image-side edits were exported to source;
- the running server or application behaves correctly.

## Live Image Checks

Use live image checks when the answer depends on image state:

- loading a baseline or package;
- listing loaded repositories, packages, classes, or methods;
- inspecting compiled methods or class definitions;
- running SUnit tests;
- starting or exercising a server/application in the image;
- applying image-side edits;
- exporting image-side changes to Tonel or Git.

Prefer dedicated `pharo` MCP tools for these checks. Use `evaluate` only when
no dedicated tool fits.

## Iceberg And Git

Remember:

- Tonel files are exported source.
- The loaded image can differ from Tonel files.
- Iceberg working-copy state can differ from both image state and Git state.
- Git commits record disk files, not unsaved image changes.

When these states disagree, report the mismatch and resolve it deliberately.
Do not claim a change is complete just because one layer looks correct.

## Blocked Live Verification

If the current context does not have a safe or approved live image:

- run only source-safe checks;
- say which live checks are still needed;
- do not use image-side evaluation or mutation as a workaround;
- do not claim live behavior is verified.

## Reporting

When finishing work, report:

- source checks run;
- live image checks run;
- live checks not run and why;
- any image/source/Iceberg/Git state mismatch observed.
