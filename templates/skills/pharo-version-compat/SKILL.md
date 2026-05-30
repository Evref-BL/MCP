---
name: pharo-version-compat
description: Use PharoCompatibility to make a Pharo project run across supported Pharo versions, especially when a project developed against one Pharo API surface must load on another. Use when adding PharoCompatibility to a baseline, diagnosing missing globals/selectors/classes across Pharo versions, deciding between shims and project abstractions, or extending PharoCompatibility with general per-Pharo-version compatibility behavior.
---

# Pharo Version Compatibility

## Mental Model

`PharoCompatibility` is for Pharo-version compatibility, not per-library shims.
A consuming project declares the Pharo API surface its source expects, then the
library loads the runtime-specific compatibility packages needed by the image.

Current public surfaces include:

- `Pharo12Surface`: for projects whose source expects the Pharo 12 API surface.
- `Pharo13Surface`: for projects whose source expects the Pharo 13 API surface.

Omit `loads:` only when the project needs the core helper API but no surface.

## Baseline Examples

Project source expects the Pharo 12 surface:

```smalltalk
spec
  baseline: 'PharoCompatibility'
  with: [
    spec
      repository: 'github://Evref-BL/PharoCompatibility:main/src';
      loads: #( 'Pharo12Surface' ) ]
```

Project source expects the Pharo 13 surface:

```smalltalk
spec
  baseline: 'PharoCompatibility'
  with: [
    spec
      repository: 'github://Evref-BL/PharoCompatibility:main/src';
      loads: #( 'Pharo13Surface' ) ]
```

Require `PharoCompatibility` from packages that use its APIs.

## Consumer Workflow

1. Identify the source surface:
   - Which Pharo version is the project developed against?
   - Which Pharo versions should load it?

2. Add the matching `PharoCompatibility` surface to the baseline.

3. Load and test on every supported Pharo version.

4. Classify failures:
   - missing global/class;
   - missing selector;
   - renamed class or package;
   - semantic API change;
   - deprecation/notice behavior difference;
   - native/tooling failure outside ordinary compatibility.

5. Choose the fix:
   - Transparent shim for equivalent globals, classes, or selectors.
   - Explicit `PharoCompatibility` helper API for behavior multiple projects
     can share.
   - Project abstraction when behavior differs and cannot be hidden safely.
   - Project-local fix when the issue is specific to that library.

6. Verify both the compatibility library and the consuming project.

## Existing Helper APIs

Useful current helpers include:

- `PharoCompatibility resumeDeprecationsDuring:`
- `PharoCompatibility withNonInteractiveAuthorNamed:during:`
- `PharoCompatibility syntaxErrorNoticeClassName`
- `PharoCompatibility loadedSurfaces`
- `PharoCompatibility runtimeVersionString`

Use helpers for behavior that should be explicit. Use transparent shims only
when the old and new contracts are equivalent.

## Extending PharoCompatibility

When a Pharo-version difference is not handled yet:

1. Confirm it is a general Pharo version difference, not a project-specific
   workaround.
2. Decide which source surface needs support and which runtime image is missing
   it.
3. Put runtime-specific code in a matching package, such as
   `PharoCompatibility-Pharo13Surface-Pharo12`.
4. Extend the baseline group conditionally for the affected Pharo versions.
5. Add installer behavior only when globals or startup aliases must be created
   after load.
6. Guard optional classes with late lookup through `Smalltalk at:ifAbsent:`.
7. Add tests for the compatibility surface contract, not only that packages
   load.

Keep shims additive when possible. Avoid changing existing runtime behavior
unless there is no safer compatibility path.

## Known Difference Shapes

The current library already handles examples like:

- syntax error notice class name differences;
- RB/Re refactoring class renames;
- `Author` availability and non-interactive author handling;
- legacy `FileStream` binding when a P13-shaped project loads on older Pharo;
- semaphore timeout protocol compatibility.

These are examples, not a closed list.

## Verification

- Run `PharoCompatibility` tests across the supported Pharo matrix.
- Run the consuming project's tests across the same matrix.
- Use `pharo-project-load` for load or baseline failures.
- Use `pharo-ci-repro` for smalltalkCI/GitHub CI reproduction.
- Keep P12/P13 or newer/older directions separate in the diagnosis; a forward
  shim and a backward shim may need different fixes.
