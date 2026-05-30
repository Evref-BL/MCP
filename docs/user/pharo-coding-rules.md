# Pharo Coding Rules For MCP Users

Applies when using MCP to inspect, write, review, or refactor Pharo source in
any project.

## First Principle

Pharo code should communicate through messages and protocols. Prefer normal
dispatch over representation checks, class checks, reflective lookup, or
dynamic selector tricks.

## Dispatch Over Inspection

Do:

- send a domain message to the receiver;
- add or refine a protocol on the object that owns the behavior;
- use polymorphic collaborators, strategy objects, double dispatch, or visitors
  when behavior varies by object role.

Avoid in application behavior:

- `class = ...`;
- `isKindOf:` and `isMemberOf:`;
- `respondsTo:` as control flow;
- `perform:` as a disguised switch;
- method dictionary or instance-variable reflection.

Reflection is acceptable for tools, proxies, compatibility shims, and explicit
framework boundaries. Keep reflective behavior isolated and named as tooling
or boundary behavior; do not spread it through ordinary domain logic.

## Tell, Do Not Ask

Do not pull state out of an object, compute externally, then push state back
when the object can own the behavior.

Prefer:

- `aCommand executeOn: aModel`;
- `aDocument writeOn: aStream`;
- `aPolicy accepts: anObject`.

over clients branching on concrete classes or internal fields.

## Object APIs, Not Data Bags

- Keep domain objects behavior-rich instead of using them only as data bags.
- Avoid dictionaries or arrays as internal domain models unless the data is
  genuinely unstructured external input.
- If several clients repeat the same extraction and calculation, move the
  behavior to the object with the knowledge.
- Avoid long message chains through internals; add a meaningful domain method.

## Small Methods And Hooks

- Extract meaningful steps into small named methods.
- Use self-send hooks when subclass or compatibility variation is plausible.
- Keep block bodies short; move domain logic from blocks into methods.
- Do not add wrappers that only rename obvious library calls unless the wrapper
  captures a domain concept or extension hook.

## Nil And Error Handling

- Return empty collections for "no elements".
- Use a null object when "do nothing" is valid behavior.
- Signal or return structured domain errors for exceptional cases.
- Do not use `nil` as a normal status code.
- Do not swallow broad `Error` silently.
- Catch the most specific exception class that matches the recovery policy.
- Use `ensure:` for cleanup.

## Initialization

- Instance-side `initialize` starts with `super initialize`.
- Initialize sensible defaults.
- Do not redefine class-side `new` just to call `initialize`.
- Use class-side creation messages such as `on:`, `with:`, or domain-specific
  constructors when required data exists.
- Use `basicNew` only when deliberately bypassing initialization.

## Names And Selectors

- Use domain vocabulary.
- Getter selector is the variable name; setter selector is `name:`.
- Do not use `getName` or `setName:`.
- Predicates should read as predicates: `isReady`, `hasErrors`,
  `canHandle:`.
- Action selectors should use verbs: `parseRequest:`, `registerTool:`,
  `writeResponseOn:`.
- Conversion selectors should start with `as`.

## Collections And Streams

- Prefer collection protocol such as `collect:`, `select:`, `reject:`,
  `detect:ifNone:`, `inject:into:`, `anySatisfy:`, and `allSatisfy:`.
- Do not mutate a collection while iterating it unless iterating a copy is
  intentional.
- Do not rely on `add:` answering the collection; use a variable or cascade
  with `yourself`.
- Override `hash` when overriding `=`.
- Use `String streamContents:` or writer streams for string construction.
- Do not concatenate strings with `,` in loops or recursive code.

## Tests

- Add or update SUnit tests for behavior changes.
- Use `assert:equals:` for comparisons when possible.
- Use `deny:` for negative assertions.
- Use `should:raise:` and `shouldnt:raise:` with blocks for exception
  behavior.
- Prefer focused tests around the public protocol.
- Use memory filesystems, fakes, or injected collaborators for unit tests when
  possible.
- Keep live-image and external-state tests separate from source-only checks.

## Review Checklist

Before finishing a Pharo source change, scan for:

- class checks or reflection used as ordinary dispatch;
- `perform:` selector registries;
- normal control flow through `nil`;
- repeated client-side extraction from an object;
- long methods or blocks hiding named domain steps;
- missing `super initialize`;
- stream/file cleanup without `ensure:`;
- string concatenation in loops;
- overridden `=` without `hash`;
- broad exception handlers that hide failures;
- missing tests for changed public behavior.
