#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: bash transcribe.sh MEDIA_FILE [MODEL]" >&2
  echo 'Example: bash transcribe.sh "recording.mp4" small.en' >&2
  exit 1
fi
if [[ ! -f "$1" ]]; then
  echo "Error: File not found: $1" >&2
  exit 1
fi
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: Install Docker Desktop (or Docker Engine) first." >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Error: Docker is unavailable. Start Docker first." >&2
  exit 1
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
INPUT_DIR=$(cd -- "$(dirname -- "$1")" && pwd -P)
INPUT_NAME=$(basename -- "$1")

docker build --tag transcribe:local "$SCRIPT_DIR/docker"
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=$INPUT_DIR,target=/data" \
  --mount type=volume,source=transcribe-models,target=/models \
  --env "MODEL=${2:-small.en}" \
  transcribe:local "/data/$INPUT_NAME"
