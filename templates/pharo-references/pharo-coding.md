# Pharo Coding

Applies when using MCP to inspect, write, review, or refactor Pharo source in
any project.

This is what is particular to Pharo. General programming practice is not
repeated here, and neither are the smells a rule recognises: compiling a method
reports the critiques the image already owns.

## Dispatch Over Inspection

Pharo code communicates through messages and protocols. Send a domain message
to the receiver, or add the protocol to the object that owns the behavior,
rather than asking what the receiver is.

Avoid in application behavior:

- `class = ...`;
- `isKindOf:` and `isMemberOf:`;
- `respondsTo:` as control flow;
- `perform:` as a disguised switch;
- method dictionary or instance-variable reflection.

Reflection is acceptable for tools, proxies, compatibility shims, and explicit
framework boundaries. Keep it isolated and named as tooling or boundary
behavior; do not spread it through ordinary domain logic.

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

## Collections And Streams

- Prefer collection protocol such as `collect:`, `select:`, `reject:`,
  `detect:ifNone:`, `inject:into:`, `anySatisfy:`, and `allSatisfy:`.
- Do not mutate a collection while iterating it unless iterating a copy is
  intentional.
- Do not rely on `add:` answering the collection; use a variable, or cascade
  with `yourself`.
- Override `hash` when overriding `=`.
- Use `String streamContents:` or `Array streamContents:` when code
  conditionally appends values, or would otherwise need a temporary
  `OrderedCollection`. Do not concatenate with `,` in loops or recursive code.

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
