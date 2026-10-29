#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
[[ $(id -u) != 0 ]] || { echo 'Run as your normal Ubuntu user, not root.' >&2; exit 1; }
[[ $(ps -p 1 -o comm=) == systemd ]] || { echo 'This project requires Ubuntu with systemd enabled.' >&2; exit 1; }
sudo apt-get update
sudo apt-get install -y curl ca-certificates python3 zstd docker.io git
sudo systemctl enable --now docker
sudo usermod -aG docker "$(id -un)"
if ! id -nG | tr ' ' '\n' | grep -qx docker; then
  echo 'Docker is installed. Refresh your login before continuing.'
  echo 'WSL: save work, run wsl --shutdown from PowerShell, reopen Ubuntu, then rerun bash setup.sh.'
  echo 'Native Ubuntu: log out and back in, then rerun bash setup.sh.'
  exit 20
fi
if ! command -v openshell >/dev/null; then
  curl -fLsS https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh -o "$PROJECT_DIR/.runtime/install-openshell.sh"
  OPENSHELL_VERSION="$OPENSHELL_VERSION" sh "$PROJECT_DIR/.runtime/install-openshell.sh"
else
  echo "Using installed $(openshell --version). Expected release: $OPENSHELL_VERSION."
fi
sudo loginctl enable-linger "$(id -un)"
systemctl --user enable --now openshell-gateway
if ! command -v ollama >/dev/null; then
  curl -fLsS https://ollama.com/install.sh -o "$PROJECT_DIR/.runtime/install-ollama.sh"
  OLLAMA_VERSION="$OLLAMA_VERSION" sh "$PROJECT_DIR/.runtime/install-ollama.sh"
else
  echo "Using installed $(ollama --version). Expected release: $OLLAMA_VERSION."
fi
sudo systemctl enable --now ollama
for i in {1..30}; do
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then break; fi
  sleep 1
done
curl -fsS http://127.0.0.1:11434/api/tags >/dev/null
ollama pull "$MODEL"
echo 'Setup complete. Run: bash run.sh test, then bash run.sh chat'
