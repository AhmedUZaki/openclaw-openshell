@echo off
setlocal

set "mode=%~1"
if "%mode%"=="" set "mode=chat"
if /i "%mode%"=="chat" goto :mode_ok
if /i "%mode%"=="test" goto :mode_ok
if /i "%mode%"=="status" goto :mode_ok
if /i "%mode%"=="setup" goto :mode_ok
echo Usage: Install.cmd [chat^|test^|status^|setup]
exit /b 2

:mode_ok

where wsl.exe >nul 2>&1
if errorlevel 1 goto :wsl_missing

wsl.exe -d Ubuntu --exec true >nul 2>&1
if errorlevel 1 goto :ubuntu_missing

echo Preparing openclaw-openshell inside Ubuntu...
wsl.exe -d Ubuntu --exec bash -lc "set -e; if ! command -v git >/dev/null 2>&1; then sudo apt-get update; sudo apt-get install -y git; fi; mkdir -p \"$HOME/projects\"; if [ -d \"$HOME/projects/openclaw-ubuntu/.git\" ]; then git -C \"$HOME/projects/openclaw-ubuntu\" pull --ff-only; else git clone https://github.com/AhmedUZaki/openclaw-openshell.git \"$HOME/projects/openclaw-ubuntu\"; fi; cd \"$HOME/projects/openclaw-ubuntu\"; exec bash start.sh %mode%"
set "install_result=%errorlevel%"

if "%install_result%"=="20" (
  echo.
  echo One-time login refresh required.
  echo Save all WSL work, run: wsl --shutdown
  echo Then run the installation command again.
)
if not "%install_result%"=="0" (
  echo.
  echo Setup or launch needs attention. Read the message above.
  pause
)
exit /b %install_result%

:wsl_missing
echo WSL is not installed. Requesting Windows administrator approval...
goto :install_ubuntu

:ubuntu_missing
echo Ubuntu is not installed. Requesting Windows administrator approval...
goto :install_ubuntu

:install_ubuntu
net.exe session >nul 2>&1
if errorlevel 1 (
  powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%mode%' -Verb RunAs"
  if errorlevel 1 (
    echo Administrator approval was cancelled or could not be requested.
    exit /b 1
  )
  exit /b 0
)

wsl.exe --install -d Ubuntu
set "wsl_result=%errorlevel%"
echo.
if not "%wsl_result%"=="0" (
  echo Windows could not complete WSL installation. Review the message above.
  pause
  exit /b %wsl_result%
)
echo Windows completed the automated WSL installation step.
echo Restart Windows if requested. Then open Ubuntu once and create your Linux
echo username and password. Finally, run the same installation command again.
pause
exit /b 0
