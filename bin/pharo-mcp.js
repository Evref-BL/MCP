#!/usr/bin/env node

import { install } from "../node/index.js";

function usage() {
  return "Usage: pharo-mcp install --host <claude|codex|opencode>";
}

const [command, option, host, ...extra] = process.argv.slice(2);

if (command !== "install" || option !== "--host" || !host || extra.length > 0) {
  console.error(usage());
  process.exitCode = 1;
} else {
  try {
    const result = install({ host });
    console.log(`Installed Pharo MCP templates for ${result.host} in ${result.cwd}.`);
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
