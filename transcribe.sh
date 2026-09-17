#!/usr/bin/env bash

# Download a whipser model, convert media to 16-bit wav and make a transcription
# This script requires whisper-cli from whisper-cpp to be installed

# Available models:
#  tiny tiny.en tiny-q5_1 tiny.en-q5_1 tiny-q8_0
#  base base.en base-q5_1 base.en-q5_1 base-q8_0
#  small small.en small.en-tdrz small-q5_1 small.en-q5_1 small-q8_0
#  medium medium.en medium-q5_0 medium.en-q5_0 medium-q8_0
#  large-v1 large-v2 large-v2-q5_0 large-v2-q8_0 large-v3 large-v3-q5_0 large-v3-turbo large-v3-turbo-q5_0 large-v3-turbo-q8_0
# ___________________________________________________________
# .en = english-only -q5_[01] = quantized -tdrz = tinydiarize
MODEL=base.en

# Run `whisper-cli --help` to see available output formats and other options 
OPTIONS='--output-txt --output-srt --output-json'

# Working directory where model gets downloaded and media files get converted
# If you want to keep downloaded models and converted audio files, set WORKDIR to a permanent directory and set CLEANUP=false
WORKDIR=$(mktemp -d)
CLEANUP=true

MODEL_DL_SCRIPT_URL=https://raw.githubusercontent.com/ggml-org/whisper.cpp/refs/heads/master/models/download-ggml-model.sh

FILE=$1
FILENAME=$(basename -- "$FILE")
FILEPATH=$(dirname -- "$FILE")
MODELPATH=$WORKDIR/ggml-$MODEL.bin

cleanup() {
  if [ "$CLEANUP" = true ]; then
    echo "--> Cleaning up"
    rm -rf "$WORKDIR"
  fi
}

# Check if $FILE exists
if [ ! -f "$FILE" ]; then
  echo "Error: File "$FILE" not found."
  exit 1
fi

# Create working directory
mkdir -p "$WORKDIR"

echo "--> Downloading model"
# Get model download script
if [ ! -f "$WORKDIR/download-ggml-model.sh" ]; then
  curl -sSL "$MODEL_DL_SCRIPT_URL" -o "$WORKDIR/download-ggml-model.sh"
  chmod +x "$WORKDIR/download-ggml-model.sh"
fi

# Download the model
"$WORKDIR/download-ggml-model.sh" "$MODEL" "$WORKDIR"

echo "--> Converting media"
# Convert audio
if [ -f "$WORKDIR/$FILENAME.wav" ]; then
  echo "Converted audio file already exists: $WORKDIR/$FILENAME.wav"
  else
  echo "Converting audio to wav format..."
  ffmpeg -hide_banner \
    -i "$FILE" \
    -ar 16000 -ac 1 -c:a pcm_s16le \
    "$WORKDIR/$FILENAME.wav"
fi

echo "--> Transcribing audio"
# Make the transcription
whisper-cli --model "$MODELPATH" \
  -f "$WORKDIR/$FILENAME.wav" \
  --output-file "$FILEPATH/$FILENAME" \
  $OPTIONS

trap clean_up EXIT
