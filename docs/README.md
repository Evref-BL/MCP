# MCP Docs

Start with the README when you need the purpose, install snippet, and first MCP
client connection. Use these docs for the details behind each workflow.

## User Docs

- [Getting started](user/getting-started.md) covers loading MCP into an
  image, starting the server, connecting a client, and making first read-only
  calls.
- [Using MCP from an agent](user/using-pharo-mcp.md) explains tool discovery,
  image-state rules, and reusable agent skills.
- [Safety and ecosystem integration](user/safety-and-ecosystem.md) explains how
  MCP uses Pharo's existing refactoring, critique, test, repository,
  change-history, compatibility, and UI systems.
- [Pharo coding rules](user/pharo-coding-rules.md) explains object-first
  Smalltalk design and review checks.
- [Source vs live image](user/source-vs-live-image.md) separates source,
  image, Iceberg, and Git state.
- [Debugging with MCP](user/debugging.md) explains the discoverable debugger
  tool family.
- [Debugger-driven development](user/debugger-driven-development.md) explains
  live debugger repair workflows.
- [Tool reference](user/tool-reference.md) lists tool groups, common workflows,
  and mutation boundaries.
- [Troubleshooting](user/troubleshooting.md) covers startup, connection,
  schema, refactoring, repository, and image-state problems.

## Development

- [Developing MCP-Pharo](dev/developing-mcp.md) explains repository-specific
  source, image, compatibility, and skill boundaries.
- [MCP-Pharo verification](dev/mcp-verification.md) maps generic live-image
  verification rules to this repository's packages, baseline, and tests.
