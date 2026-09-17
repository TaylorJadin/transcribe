# Transcribe

Transcribe an audio or video file locally with [whisper.cpp](https://github.com/ggml-org/whisper.cpp).
Docker supplies FFmpeg and whisper.cpp through Nix packages; no Nix, Python, or other transcription tools need to be installed on your computer.

Install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/) on Windows or macOS, or Docker Engine on Linux. On Windows, use Linux containers.
Download or clone this repository, open a terminal in its directory, and run:

**macOS / Linux**

```sh
bash run.sh "/path/to/recording.mp4"
```

**Windows (PowerShell or Command Prompt)**

```powershell
.\run.bat "C:\Recordings\recording.mp4"
```

The first run builds the image and downloads the default English model (`small.en`); this takes a few minutes and needs internet access. Later runs reuse Docker's build cache and the downloaded model. Transcription runs on your CPU, and your media stays on your computer.

Outputs appear beside the input, retaining its original extension:

- `recording.mp4.txt` — plain text
- `recording.mp4.srt` — subtitles
- `recording.mp4.json` — structured transcription

Quote paths containing spaces. The input can be outside this repository; its parent folder must be writable and accessible to Docker. Re-running a file overwrites its transcript outputs. Temporary converted audio is removed when the container exits.

## Choosing a model

Pass a model name as the second argument:

```sh
bash run.sh "recording.mp4" small.en
```

```powershell
.\run.bat "C:\Recordings\recording.mp4" small.en
```

Use `tiny.en` for a faster English model, `small.en` for a larger English model, or `base` / `small` for other languages. Language detection is automatic. Larger models need more memory and processing time. See the [whisper.cpp model list](https://github.com/ggml-org/whisper.cpp/blob/master/models/download-ggml-model.sh) for available names.

Models persist in the Docker volume `transcribe-models`. To clear the cache when no transcription is running:

```sh
docker volume rm transcribe-models
```

## Docker directly

The launchers build the local image and mount the media's parent folder and model cache. Equivalent commands on macOS / Linux are:

```sh
docker build -t transcribe:local ./lib
docker run --rm --user "$(id -u):$(id -g)" \
  --mount "type=bind,source=/absolute/path/to/recordings,target=/data" \
  --mount type=volume,source=transcribe-models,target=/models \
  --env MODEL=small.en \
  transcribe:local /data/recording.mp4
```

You can append whisper-cli options after the media path when using Docker directly, for example `--language fr`.

The image follows the [Nix with Dockerfiles approach](https://mitchellh.com/writing/nix-with-dockerfiles): `lib/flake.nix` assembles the runtime dependencies, and a `nixos/nix` build stage copies them into a final `scratch` image. Docker copies `lib/transcribe.sh` directly into that image and runs it with Bash. Nix itself is only present in the build stage. The runtime includes CA certificates so curl can verify HTTPS model downloads, plus writable temporary and model-cache directories.

The flake follows the `nixos-26.05` stable Nixpkgs channel. Nix creates a `flake.lock` inside the Docker build stage when it resolves package versions; this does not create a lock file in your checkout. Nix downloads prebuilt packages from its binary cache when available. Transcription uses the CPU in Linux containers, including Docker Desktop.

Normal runs reuse Docker's build cache. To refresh the base image and packages to the latest updates in the stable channel, run:

```sh
docker build --pull --no-cache -t transcribe:local ./lib
```

When a new stable NixOS release is available, update `inputs.nixpkgs.url` in `lib/flake.nix` to follow that release.
