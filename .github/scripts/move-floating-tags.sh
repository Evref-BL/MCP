#!/usr/bin/env bash
set -euo pipefail

release=${1:?Give a release tag of the form vX.Y.Z}
remote=${2:-origin}

if [[ ! $release =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "$release is not a stable version tag; no floating tags move."
  exit 0
fi
major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
commit=$(git rev-parse --verify "$release^{commit}")

for floating in "v$major.$minor.x" "v$major.x.x"; do
  latest=$(git tag --list "${floating//x/*}" --sort=-version:refname |
    awk '/^v[0-9]+\.[0-9]+\.[0-9]+$/ && !latest { latest = $0 } END { print latest }')
  if [[ $release == "$latest" ]]; then
    previous=$(git rev-parse --verify --quiet "refs/tags/$floating" || true)
    git tag --force "$floating" "$commit"
    git push --force-with-lease="refs/tags/$floating:$previous" "$remote" "refs/tags/$floating"
    echo "$floating -> $release ($commit)"
  fi
done
