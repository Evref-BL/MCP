---
name: pharo-version-compat
description: Use PharoCompatibility to load and test a project across supported Pharo versions. Use for missing or renamed Pharo globals, classes, selectors, packages, notices, or semantics; baseline surface selection; and reusable cross-version shims.
---

# Pharo Version Compatibility

## Model

`PharoCompatibility` handles Pharo-version differences, not library-specific
workarounds. A project declares the Pharo API surface its source expects; the
runtime loads the compatibility packages needed by the current image.

Known source surfaces include `Pharo12Surface` and `Pharo13Surface`. Omit a
surface only when the project needs the core helper API alone.

## Workflow

1. Read the project baseline, supported-version policy, and CI matrix.
2. Identify the source Pharo surface and target runtime versions.
3. Load the matching surface from the project baseline:

```smalltalk
spec
  baseline: 'PharoCompatibility'
  with: [
    spec
      repository: 'github://Evref-BL/PharoCompatibility:main/src';
      loads: #( 'Pharo13Surface' ) ]
```

4. Reproduce on every affected Pharo version and classify the failure: missing
   binding, missing selector, rename, semantic change, notice behavior, or
   native/tooling failure.
5. Choose the narrowest owner:
   - transparent shim for equivalent APIs;
   - explicit PharoCompatibility helper for reusable behavior;
   - project abstraction for irreducible semantic differences;
   - project-local fix for library-specific behavior.
6. Verify both PharoCompatibility and the consuming project across the matrix.

## Extending PharoCompatibility

- Confirm the difference is general and assign it to a source surface and
  runtime version.
- Put runtime code in the matching conditional package and baseline group.
- Use late lookup for optional globals.
- Keep shims additive when possible and test the compatibility contract, not
  only package loading.

Use `pharo-project-load` for load-path failures and `pharo-ci-repro` for
smalltalkCI or runner-specific failures.

## Report

Report source surface, runtimes tested, failure classification, shim owner,
packages changed, and matrix results.
