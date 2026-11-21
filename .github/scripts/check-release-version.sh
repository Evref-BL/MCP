#!/usr/bin/env bash
# Refuses a release whose tag is not the version its code declares, which
# serverInfo and the telemetry resource report. A release made by hand skips
# the release pull request that sets MCP class >> version.
set -euo pipefail

release=${1:?Give a release tag of the form vX.Y.Z}
declared=$(git show "$release^{commit}:src/MCP/MCP.class.st" | awk '/^MCP class >> version \[/ { found = 1 }
  found && match($0, /[0-9]+\.[0-9]+\.[0-9]+/) { print substr($0, RSTART, RLENGTH); exit }')

if [[ "v$declared" != "$release" ]]; then
  echo "Release $release declares version ${declared:-none} in MCP class >> version." >&2
  echo "Release through the release pull request, which sets it." >&2
  exit 1
fi
echo "Release $release declares $declared."
