# Pharo Guidance Bibliography

Applies when maintaining MCP-Pharo's Pharo coding guidance:

- `docs/user/pharo-coding-rules.md`
- `docs/user/pharo-coding-style.md`
- Pharo-related guidance in `templates/AGENTS.md`

This file records the public sources behind the guidance. It is developer
maintenance context, not required reading for agents that only use MCP.

## Pharo And Smalltalk Sources

- [Pharo with Style](https://books.pharo.org/booklet-WithStyle/) and
  [Booklet-PharoWithStyle](https://github.com/SquareBracketAssociates/Booklet-PharoWithStyle):
  naming, selectors, comments, formatting, initialization, streams, printing,
  globals, and hook-oriented message sends.
- [Pharo by Example 9](https://books.pharo.org/pharo-by-example9/)
  and [NewPharoByExample9](https://github.com/SquareBracketAssociates/NewPharoByExample9):
  syntax, object model, message precedence, cascades, collections, streams,
  reflection, Iceberg basics, and IDE behavior.
- [Learning Object-Oriented Programming, Design and TDD with Pharo](https://books.pharo.org/learning-oop/):
  responsibilities, delegation, message sends as choice, polymorphism, "tell,
  do not ask", tests, and refactoring.
- [Pharo MOOC repositories](https://github.com/pharo-mooc/): broad grounding
  in Pharo syntax, live-object development, tools, tests, and environment.
- [Advanced OO Design MOOC](https://advanced-design-mooc.pharo.org/):
  dispatch, "let the receiver decide", self-sends as reuse hooks, objects vs
  data, delegation vs inheritance, blocks vs objects, nil avoidance, double
  dispatch, class-side APIs, and dual interfaces.
- [Testing in Pharo](https://books.pharo.org/booklet-Testing/) and
  [Booklet-TestingInPharo](https://github.com/SquareBracketAssociates/Booklet-TestingInPharo):
  SUnit, test-first design, fixture style, debugger-led repair, and good test
  properties.
- [Deep Into Pharo](https://github.com/SquareBracketAssociates/DeepIntoPharo):
  filesystem and exception-handling guidance.

## Tooling And Ecosystem Sources

- [Booklet-ManagingCode](https://github.com/SquareBracketAssociates/Booklet-ManagingCode):
  package and code-management context.
- [Booklet-uFFI](https://github.com/SquareBracketAssociates/Booklet-uFFI):
  FFI concepts and boundary behavior.
- [Iceberg](https://github.com/pharo-vcs/iceberg) and
  [Iceberg wiki](https://github.com/pharo-vcs/iceberg/wiki): repository,
  working-copy, authentication, recovery, and Metacello integration behavior.
- [Metacello](https://github.com/Metacello/metacello): baseline and project
  loading behavior.
- [Pharo open documentation wiki](https://github.com/pharo-open-documentation/pharo-wiki):
  additional baseline and ecosystem notes.

## Cross-Language Style And Refactoring Sources

These sources back the readability heuristics in
`docs/user/pharo-coding-style.md`. They are not Pharo authorities, but they
confirm that the guidance is consistent with established style and refactoring
practice.

- [Kent Beck, "Guard Clause" from Implementation Patterns](https://www.informit.com/articles/article.aspx?p=1149121&seqNum=11):
  guard clauses for simple local exceptional flows and keeping the main flow
  visible.
- [Go Code Review Comments: Indent Error Flow](https://go.googlesource.com/wiki/+/6a941f07bde0a8939058c1fc3610dc4cba782a06/CodeReviewComments.md):
  handling exceptional/error flow first so normal code remains minimally
  indented.
- [Martin Fowler, Refactoring second edition changes](https://martinfowler.com/articles/refactoring-2nd-changes.html):
  guard clauses, replacing conditionals with polymorphism, replacing temps
  with queries, separating query from modifier, and related conditional
  simplification refactorings.
- [Google Python Style Guide](https://google.github.io/styleguide/pyguide.html):
  compact expressions only for simple cases, and readability over conciseness.
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):
  clarity at the point of use, clarity over brevity, and role-based naming.
- [Rust Style Guide principles](https://doc.rust-lang.org/stable/style-guide/principles.html):
  readability, scanability, plain-text review contexts, preventing rightward
  drift, and merge-friendly formatting.
- [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html):
  expression forms for `if`, `when`, and `try`, grouping related code, named
  arguments, nullable handling, and avoiding complex higher-order chains when a
  loop is clearer.
- [PEP 20 / The Zen of Python](https://pep20.org/): readability, flatness,
  explicitness, and practicality over purity.
- [Airbnb JavaScript Style Guide](https://javascript.airbnb.tech/): consistent
  style, avoiding confusing complex conditionals, and using immutability where
  it makes data flow clearer.

## Maintenance Rule

When changing user-facing Pharo coding guidance, prefer updating the
operational rule first and this bibliography only when a new source changes the
justification. Do not link this file from `templates/` or require it for agents
that only use MCP in another project.
