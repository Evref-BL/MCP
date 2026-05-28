# Smalltalk Practices

Use this file before designing or editing non-trivial Smalltalk code.

## Object Design

Model behavior with objects and messages. Prefer a collaborator with a clear
protocol over string/symbol switches, large conditional dispatch, or defensive
reflection.

Internal and public APIs are under project control. Do not guard ordinary
accessors or command/request collaborators as if clients may send arbitrary
objects. Validate at tool/request boundaries, then let typed project objects
talk to each other.

## Nil And Preconditions

Use `ifNil:` only when nil is a meaningful state in the domain or an external
API can genuinely omit a value. Do not begin every method by checking all
arguments for nil.

Use explicit command errors at user/tool boundaries. Inside the model, prefer
small methods with clear assumptions.

## Reflective Checks

Avoid `respondsTo:` in ordinary code. Prefer, in order:

1. A testing protocol such as `isMissing`, `isAbstract`, or domain-specific
   `is*` messages.
2. `isKindOf:` when the useful distinction is a real class hierarchy.
3. `PharoCompatibility` when Pharo versions expose different selectors or
   globals for the same concept.
4. `respondsTo:` only for truly reflective external APIs where no stronger
   protocol or compatibility helper is available.

When a `respondsTo:` critique is legitimate, either redesign the collaboration
or isolate the compatibility concern behind a named helper.
