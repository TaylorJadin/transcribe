#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 MEDIA_FILE [WHISPER_OPTIONS...]" >&2
  exit 1
fi

FILE=$1
shift
if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

MODEL=${MODEL:-small.en}
MODEL_DIR=${MODEL_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/transcribe}
case "$MODEL" in
  *[!a-zA-Z0-9._-]*)
    echo "Error: Invalid model name: $MODEL" >&2
    exit 1
    ;;
esac

mkdir -p "$MODEL_DIR"
MODEL_PATH="$MODEL_DIR/ggml-$MODEL.bin"
WORKDIR=$(mktemp -d)
DOWNLOAD=
cleanup() {
  rm -rf -- "$WORKDIR"
  if [[ -n "$DOWNLOAD" ]]; then
    rm -f -- "$DOWNLOAD"
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ ! -s "$MODEL_PATH" ]]; then
  echo "--> Downloading model: $MODEL"
  MODEL_URL=https://huggingface.co/ggerganov/whisper.cpp/resolve/main
  if [[ "$MODEL" == *tdrz* ]]; then
    MODEL_URL=https://huggingface.co/akashmjn/tinydiarize-whisper.cpp/resolve/main
  fi
  # Download beside the cache entry so only a completed download is published.
  DOWNLOAD=$(mktemp "$MODEL_DIR/.download-XXXXXX")
  curl --fail --location --retry 3 \
    "$MODEL_URL/ggml-$MODEL.bin" --output "$DOWNLOAD"
  chmod 644 "$DOWNLOAD"
  mv -- "$DOWNLOAD" "$MODEL_PATH"
  DOWNLOAD=
else
  echo "--> Using cached model: $MODEL"
fi

echo "--> Converting media"
ffmpeg -hide_banner -nostdin -y -i "$FILE" \
  -vn -ar 16000 -ac 1 -c:a pcm_s16le "$WORKDIR/audio.wav"

echo "--> Transcribing audio"
whisper-cli --model "$MODEL_PATH" \
  --file "$WORKDIR/audio.wav" \
  --language auto \
  --output-file "$FILE" \
  --output-txt --output-srt --output-json "$@"

echo "--> Saved: $FILE.txt, $FILE.srt, $FILE.json"
