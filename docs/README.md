# MCP Docs

Start with the README when you need the purpose, install snippet, and first MCP
client connection. Use these docs for the details behind each workflow.

## User Docs

- [Getting started](user/getting-started.md) covers loading MCP into an
  image, starting the server, connecting a client, and making first read-only
  calls.
- [Safety and ecosystem integration](user/safety-and-ecosystem.md) explains how
  MCP uses Pharo's existing refactoring, critique, test, repository,
  change-history, compatibility, and UI systems.

## Reference

- [Tool reference](reference/tools.md) lists tool groups, common workflows, and
  mutation boundaries.
- [Troubleshooting](troubleshooting.md) covers startup, connection, schema,
  refactoring, repository, and image-state problems.

## Agent Task Guides

- [Smalltalk practices](agents/smalltalk-practices.md) explains object-first
  design, nil/precondition boundaries, and reflective-check guidance.
- [Debugging tools](agents/debugging.md) explains the discoverable debugger
  tool family.
- [Debugger-driven development](agents/debugger-driven-development.md) explains
  live debugger repair workflows.

## Development

- [Source vs live image checks](dev/source-vs-live-image-checks.md) separates
  static source verification from checks that require a running image.
