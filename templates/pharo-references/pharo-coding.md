# Pharo Coding

What is particular to Pharo, for writing, reviewing or refactoring its code
with whatever tool is at hand: through MCP, through a source projection, or in
the files themselves.

General programming practice is not repeated here, and neither are the smells a
rule recognises: Pharo's own critiques report those.

## Dispatch Over Inspection

Pharo code communicates through messages and protocols. Send a domain message
to the receiver, or add the protocol to the object that owns the behavior,
rather than asking what the receiver is.

The reflective escapes are not equally defensible:

- `respondsTo:` as control flow is almost never right. It asks whether a send
  would work instead of sending it. Keep it for genuinely reflexive code that
  reads a protocol as data.
- `isKindOf:` and `isMemberOf:` are fine where a type really must be checked
  and nothing else can say it, such as a boundary receiving foreign objects.
- `perform:` is fine where the selector is data rather than a disguised
  switch, such as turning a transport message into a send.
- `class = ...`, method dictionary and instance-variable reflection belong to
  tools, proxies and compatibility shims.

Keep reflective behavior isolated and named as tooling or boundary behavior;
do not spread it through ordinary domain logic.

## The Main Send

A Pharo conditional is an expression, so the send can stand outside it. When
both branches perform the same operation, lift it out and let the conditional
answer only the receiver or argument that varies.

```smalltalk
result := self transform: (condition ifTrue: [ selectedValue ])
```

This applies to return expressions, assigned values, message arguments, and
nested expressions.

## Nil

- Use `ifNotNil:` for local nil traversal when a boundary API can genuinely
  return `nil` and the next step is asking the non-nil object for a value.
- Keep simple boolean predicates simple. Expressions such as
  `value isNotNil and: [ value isReady ]` are idiomatic when the result is a
  boolean. Do not rewrite them into `ifNil:`/`ifNotNil:` only to return a
  boolean literal from one branch.

## Intermediate Objects

A step that builds a collection or a string only to hand it to the next step
allocates something nobody asked for. Pharo's fused messages exist for that:
`collect:as:` rather than `collect:` and a conversion, `select:thenDo:` rather
than a filtered copy to iterate over, `String streamContents:` rather than a
chain of `,`, where every comma copies everything to its left.

Sorting is the usual case. `sorted` and `sorted:` answer a sorted copy as an
Array; `sort` and `sort:` sort a `SequenceableCollection` in place and answer
it. So `values sorted` says what `values asSortedCollection asArray` says, with
no `SortedCollection` in between. One earns its keep when a collection must
*stay* sorted as things are added to it — not for sorting something once.

## Initialization

- Initialize sensible defaults in `initialize`.
- Do not redefine class-side `new` just to call `initialize`.
- Use class-side creation messages such as `on:`, `with:`, or domain-specific
  constructors when required data exists.
- Use `basicNew` only when deliberately bypassing initialization.

## Selectors

- The getter selector is the variable name; the setter selector is `name:`.
  Not `getName` or `setName:`.
- Predicates read as predicates: `isReady`, `hasErrors`, `canHandle:`.
- Action selectors use verbs: `parseRequest:`, `addTool:`, `writeResponseOn:`.
- Conversion selectors start with `as`.

## Collections

- Prefer collection protocol such as `collect:`, `select:`, `reject:`,
  `detect:ifNone:`, `inject:into:`, `anySatisfy:`, and `allSatisfy:`.
- Do not mutate a collection while iterating it unless iterating a copy is
  intentional.
- Do not rely on `add:` answering the collection; use a variable, or cascade
  with `yourself`.

## Class Extensions

Be conservative with extensions on broad system classes such as `Object`,
`Behavior`, `String`, or `Exception`. They should model a real boundary
protocol, not hypothetical defense against wrong callers.

## Tests

- Use `assert:equals:` for comparisons, and `deny:` for negative assertions.
- Use `should:raise:` and `shouldnt:raise:` with blocks for exception
  behavior.
- Use memory filesystems, fakes, or injected collaborators where a unit test
  would otherwise reach outside the image.
- Keep live-image and external-state tests separate from source-only checks.
