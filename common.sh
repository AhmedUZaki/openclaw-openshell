#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$PROJECT_DIR/versions.env"
if [[ -f "$PROJECT_DIR/.env" ]]; then source <(tr -d '\r' < "$PROJECT_DIR/.env"); fi
MODEL="${MODEL:-qwen3.5:9b}"
CONTEXT="${CONTEXT:-32768}"
SANDBOX="${SANDBOX:-claw-ubuntu}"
[[ "$CONTEXT" =~ ^[0-9]+$ ]] && (( CONTEXT >= 16384 && CONTEXT <= 131072 )) || { echo 'CONTEXT must be between 16384 and 131072.' >&2; exit 1; }
[[ "$SANDBOX" =~ ^[a-z][a-z0-9-]{0,18}$ ]] || { echo 'SANDBOX must use 1-19 lowercase letters, numbers or hyphens, starting with a letter.' >&2; exit 1; }
[[ -n "$MODEL" && "$MODEL" != *:cloud ]] || { echo 'Select a local model, not an Ollama cloud model.' >&2; exit 1; }
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
# Use the local gateway registered by the official installer.
export OPENSHELL_GATEWAY=openshell
mkdir -p "$PROJECT_DIR/.runtime"
