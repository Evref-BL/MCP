---
name: pharo-version-compat
description: Use PharoBackwardCompatibility to load and test a project developed on a later Pharo across supported older versions. Use for missing APIs, selectors, packages, notices, or semantics and reusable upstream backports.
---

# Pharo Version Compatibility

## Model

`PharoBackwardCompatibility` backports later Pharo APIs to older supported
images. Develop against the newest supported Pharo and let the dependency load
the packages needed by the current image.

It has no source-surface group: load its default baseline.

## Workflow

1. Read the project baseline, supported-version policy, and CI matrix.
2. Identify the newest source Pharo version and target runtime versions.
3. Load PBC from the project baseline:

```smalltalk
spec
  baseline: 'PharoBackwardCompatibility'
  with: [
    spec repository: 'github://jecisc/PharoBackwardCompatibility:v1.x.x/src' ]
```

4. Reproduce on every affected Pharo version and classify the failure: missing
   binding, missing selector, rename, semantic change, notice behavior, or
   native/tooling failure.
5. Choose the narrowest owner:
   - transparent shim for equivalent APIs;
   - an upstream PharoBackwardCompatibility backport for general APIs;
   - project abstraction for irreducible semantic differences;
   - project-local fix for library-specific behavior.
6. Verify both PharoBackwardCompatibility and the consuming project across the matrix.

## Extending PharoBackwardCompatibility

- Confirm the difference is general, originates in a newer Pharo API, and
  affects an older supported runtime.
- Put runtime code in the matching conditional package and baseline group.
- Use late lookup for optional globals.
- Keep backports additive when possible and test the compatibility contract,
  not only package loading.

Use `pharo-project-load` for load-path failures and `pharo-ci-repro` for
smalltalkCI or runner-specific failures.

## Report

Report source surface, runtimes tested, failure classification, shim owner,
packages changed, and matrix results.
