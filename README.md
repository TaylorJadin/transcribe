# Transcribe

Transcribe an audio or video file locally with [whisper.cpp](https://github.com/ggml-org/whisper.cpp).
Docker supplies FFmpeg and whisper.cpp through Nix packages; no Nix, Python, or other transcription tools need to be installed on your computer.

Install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/) on Windows or macOS, or Docker Engine on Linux.

Download or clone this repository, open a terminal in its directory, and run:

**macOS / Linux**

```sh
bash transcribe.sh "/path/to/recording.mp4"
```

**Windows (PowerShell or Command Prompt)**

```powershell
.\transcribe.bat "C:\Recordings\recording.mp4"
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
bash transcribe.sh "recording.mp4" small.en
```

```powershell
.\transcribe.bat "C:\Recordings\recording.mp4" small.en
```

Use `tiny.en` for a faster English model, `small.en` for a larger English model, or `base` / `small` for other languages. Language detection is automatic. Larger models need more memory and processing time. See the [whisper.cpp model list](https://github.com/ggml-org/whisper.cpp/blob/master/models/download-ggml-model.sh) for available names.

## Updates and caching

To force a fresh image build with the latest packages, run this from the repository directory:

```sh
docker build --pull --no-cache --tag transcribe:local ./docker
```

To delete downloaded models, run this when no transcription is running. The next transcription recreates the volume and downloads its selected model:

```sh
docker volume rm transcribe-models
```

You can also prune your various docker caches at the system level or in Docker Desktop.
