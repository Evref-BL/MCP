#!/usr/bin/env bash
set -u

usage() {
  cat <<'USAGE'
Usage:
  run-smalltalkci-docker.sh --repo REPO_DIR [options]

Options:
  --repo DIR          Source repository or working tree to test.
  --platform NAME    smalltalkCI platform, default Pharo64-13.
  --spec FILE        smalltalkCI spec file, default .smalltalk.ston.
  --attempts N       Number of attempts, default 1.
  --out DIR          Scratch/log directory, default /tmp/pharo-ci-repro-<timestamp>.
  --image IMAGE      Docker image, default hpiswa/smalltalkci:24.04.
  --docker-platform PLATFORM
                      Docker platform, default linux/amd64.
  --include-git      Copy .git into each scratch tree.
  --keep-going       Continue after failures instead of stopping at first one.
  --help             Show this help.

Each attempt gets a fresh copied work tree and a log at OUT/logs/attempt-N.log.
USAGE
}

repo=""
platform="Pharo64-13"
spec=".smalltalk.ston"
attempts="1"
out=""
image="hpiswa/smalltalkci:24.04"
docker_platform="linux/amd64"
include_git="false"
keep_going="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --platform)
      platform="${2:-}"
      shift 2
      ;;
    --spec)
      spec="${2:-}"
      shift 2
      ;;
    --attempts)
      attempts="${2:-}"
      shift 2
      ;;
    --out)
      out="${2:-}"
      shift 2
      ;;
    --image)
      image="${2:-}"
      shift 2
      ;;
    --docker-platform)
      docker_platform="${2:-}"
      shift 2
      ;;
    --include-git)
      include_git="true"
      shift
      ;;
    --keep-going)
      keep_going="true"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$repo" ]; then
  echo "--repo is required" >&2
  usage >&2
  exit 2
fi

if [ ! -d "$repo" ]; then
  echo "Repo directory does not exist: $repo" >&2
  exit 2
fi

case "$attempts" in
  ''|*[!0-9]*)
    echo "--attempts must be a positive integer" >&2
    exit 2
    ;;
esac

if [ "$attempts" -lt 1 ]; then
  echo "--attempts must be at least 1" >&2
  exit 2
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker CLI not found. Install a container runtime that provides the Docker CLI/API, or use a local smalltalkCI fallback." >&2
  exit 69
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker API is not reachable. Start or repair the local container runtime, then retry this command." >&2
  echo "If container reproduction is not available and the failure is not OS/runtime-sensitive, use a local smalltalkCI fallback with isolated smalltalkCI homes for parallel jobs." >&2
  exit 69
fi

if [ -z "$out" ]; then
  out="/tmp/pharo-ci-repro-$(date +%Y%m%d%H%M%S)"
fi

mkdir -p "$out/logs"

echo "Source: $repo"
echo "Platform: $platform"
echo "Spec: $spec"
echo "Attempts: $attempts"
echo "Output: $out"
echo "Docker platform: $docker_platform"
echo

status=0
i=1
while [ "$i" -le "$attempts" ]; do
  work="$out/work-$i"
  log="$out/logs/attempt-$i.log"
  rm -rf "$work"
  mkdir -p "$work"

  if [ "$include_git" = "true" ]; then
    rsync -a --exclude coverage "$repo"/ "$work"/
  else
    rsync -a --exclude .git --exclude coverage "$repo"/ "$work"/
  fi

  echo "=== Attempt $i/$attempts ==="
  echo "Log: $log"

  docker run --rm --platform "$docker_platform" \
    -v "$work:/work/project" \
    -w /work/project \
    "$image" \
    smalltalkci -s "$platform" "$spec" 2>&1 | tee "$log"

  attempt_status="${PIPESTATUS[0]}"
  if [ "$attempt_status" -ne 0 ]; then
    echo "Attempt $i failed with status $attempt_status"
    echo "Failure log: $log"
    status="$attempt_status"
    if [ "$keep_going" != "true" ]; then
      exit "$status"
    fi
  else
    echo "Attempt $i passed"
  fi

  i=$((i + 1))
done

exit "$status"
