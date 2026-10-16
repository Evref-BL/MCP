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
result := self transform: (condition ifTrue: [ selectedValue ])
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

## Collections

Common collection families, as a protocol reminder rather than a reason to
branch on concrete collection classes:

```text
Collection
  HashedCollection
    Dictionary
    Set
  OrderedDictionary
  SequenceableCollection
    OrderedCollection
      SortedCollection
    ArrayedCollection
      Array
      String
```

- Build the collection you mean to return. When the result type matters, use
  messages such as `collect:as:`, `select:as:`, or `flatCollect:as:` instead
  of collecting into one species and immediately converting to another.
- Avoid intermediate collections. Prefer fused messages such as
  `select:thenCollect:` and `reject:thenCollect:` when filtering and
  transforming. When a filtered or transformed collection exists only to feed
  iteration, use `select:thenDo:`, `reject:thenDo:`, or `collect:thenDo:`.
  Use `groupedBy:` for simple grouping.
- Prefer direct queries over filtered collections. Use `detect:ifNone:` for a
  first match with fallback, and `anySatisfy:`, `allSatisfy:`, or
  `noneSatisfy:` when asking a boolean question.
- Use streaming constructors such as `Array streamContents:` and
  `String streamContents:` when code conditionally appends values or would
  otherwise need a temporary `OrderedCollection`.
- Avoid conversion chains that exist only to sort or change species, such as
  `asSortedCollection asArray`. Sort a `SequenceableCollection` in-place with
  `sort`/`sort:`, or make a copy with `sorted`/`sorted:`.

## Conditions

- Avoid assignment inside boolean conditions. Conditions should decide control
  flow, not also mutate state.
- Keep questions pure: predicates should answer questions, not mutate state.
- When the fallback value is `nil`, prefer a one-arm conditional. In Pharo,
  `ifTrue:` answers `nil` when the condition is false, and `ifFalse:` answers
  `nil` when the condition is true.
- Use `ifNotNil:` for local nil traversal when a boundary API can genuinely
  return `nil` and the next step is asking the non-nil object for a value.
- Prefer presence-aware lookup messages over lookup-to-nil followed by a nil
  check. Use `ifPresent:` or `ifPresent:ifAbsent:` variants when they keep the
  present case local; add `ifAbsent: [ ]` when absence should be an explicit
  no-op.
- Keep simple boolean predicates simple. Expressions such as
  `value notNil and: [ value isReady ]` are idiomatic when the result is a
  boolean. Do not rewrite them into `ifNil:/ifNotNil:` only to return a
  boolean literal from one branch.
- Remove nil-only branches from nil traversal. Both `receiver ifNil: [ nil ]
  ifNotNil: [ ... ]` and `receiver ifNotNil: [ ... ] ifNil: [ nil ]` should
  normally become `receiver ifNotNil: [ ... ]`.
- Avoid defensive type or protocol checks in private helpers unless the helper
  is an explicit boundary. Let incorrect callers fail or validate at the
  boundary with a named policy.
- Prefer a direct send to a known collaborator over a defensive wrapper. Add a
  wrapper or extension after concrete variation appears, not before.

## Review Smells

Scan for:

- duplicated sends in both conditional branches when only one receiver or
  argument changes;
- dependent work performed before a guard proves the value is present or valid;
- assignment embedded inside boolean conditions;
- repeated `isNotNil` checks where `ifNotNil:` would express local nil
  traversal;
- lookup with `ifAbsent: [ nil ]` followed by a nil check where an
  `ifPresent:` variant can express the positive path directly;
- `ifNil:/ifNotNil:` expressions that return only `true` or `false` from one
  branch and would read more directly as a boolean condition;
- `ifNil: [ nil ] ifNotNil: [...]` or `ifNotNil: [...] ifNil: [ nil ]`
  branches where plain `ifNotNil:` communicates the same behavior;
- collection pipelines that allocate intermediate collections only to
  immediately convert, sort, query emptiness, take a first match, or group
  values manually;
- `select:`, `reject:`, or `collect:` immediately followed by `do:` when a
  `thenDo:` variant would avoid the intermediate collection;
- sorting through conversion chains instead of sorting a result array directly;
- defensive type checks in private helpers that hide caller bugs;
- wrapper methods or extensions that exist only because a collaborator might be
  wrong someday;
- dense nested expressions that would be clearer with a temporary or extracted
  method.
