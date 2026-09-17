@echo off
setlocal DisableDelayedExpansion

if "%~1"=="" goto usage
if not "%~3"=="" goto usage
if not exist "%~f1" (
  echo Error: File not found: "%~f1" 1>&2
  exit /b 1
)
if exist "%~f1\" (
  echo Error: Expected a media file, got a directory. 1>&2
  exit /b 1
)
where docker >nul 2>&1
if errorlevel 1 (
  echo Error: Install Docker Desktop first. 1>&2
  exit /b 1
)
docker info >nul 2>&1
if errorlevel 1 (
  echo Error: Docker is unavailable. Start Docker Desktop with Linux containers. 1>&2
  exit /b 1
)

set "MODEL=small.en"
if not "%~2"=="" set "MODEL=%~2"

docker build --tag transcribe:local "%~dp0lib"
if errorlevel 1 exit /b %errorlevel%

docker run --rm ^
  --mount "type=bind,source=%~dp1.,target=/data" ^
  --mount "type=volume,source=transcribe-models,target=/models" ^
  --env "MODEL=%MODEL%" ^
  transcribe:local "/data/%~nx1"
exit /b %errorlevel%

:usage
echo Usage: run.bat MEDIA_FILE [MODEL] 1>&2
echo Example: run.bat "C:\Recordings\meeting.mp4" small.en 1>&2
exit /b 1
