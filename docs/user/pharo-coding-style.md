# Pharo Coding Style

Applies when writing or reviewing the shape of Pharo source code after loading
[Pharo coding rules](pharo-coding-rules.md).

## Goal

Keep Pharo code readable, scannable, and idiomatic. These are readability
heuristics, not mechanical laws. Prefer the shape that makes dependencies,
main operations, and exceptional paths easiest to understand.

## Main Send

- Make the main send easy to see. When both branches of a conditional perform
  the same operation, lift the branch-invariant send out of the branches and
  use the conditional only for the receiver or argument that varies.
- This applies to return expressions, assigned values, message arguments, and
  nested expressions.
- Do not over-compress multi-step domain logic into one expression.

Prefer:

```smalltalk
result := self transform: (condition
	ifTrue: [ selectedValue ]
	ifFalse: [ nil ])
```

over duplicating the same `transform:` send inside both conditional branches.

## Guards

- Guard before dependent work. If `nil`, invalid bounds, failed lookup, or
  missing capability exits early or returns a fallback, check it before sends,
  computations, or mutations that assume the value is present.
- Keep the normal path visible. Use early returns for local exceptional or
  fallback cases when they keep the main path low-indentation.
- Do not mechanically move every condition to the top. Choose the order that
  makes dependencies and intent clearest.
- Prefer "win fast" when the successful case is tiny, obvious, and safe to
  attempt before fallback work.

## Temporaries

- Prefer short supporting expressions for simple receiver or argument
  computation.
- Use a temporary when the value has domain meaning, is reused, names an
  important step, or helps debugging and review.
- Keep temporaries near their use.

## Conditions

- Avoid assignment inside boolean conditions. Conditions should decide control
  flow, not also mutate state.
- Keep questions pure: predicates should answer questions, not mutate state.
- Use `ifNotNil:` for local nil traversal when a boundary API can genuinely
  return `nil` and the next step is asking the non-nil object for a value.
- Avoid defensive type or protocol checks in private helpers unless the helper
  is an explicit boundary. Let incorrect callers fail or validate at the
  boundary with a named policy.

## Review Smells

Scan for:

- duplicated sends in both conditional branches when only one receiver or
  argument changes;
- dependent work performed before a guard proves the value is present or valid;
- assignment embedded inside boolean conditions;
- repeated `isNotNil` checks where `ifNotNil:` would express local nil
  traversal;
- defensive type checks in private helpers that hide caller bugs;
- dense nested expressions that would be clearer with a temporary or extracted
  method.
