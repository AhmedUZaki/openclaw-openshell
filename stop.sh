#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
openshell sandbox stop "$SANDBOX"
echo 'Sandbox stopped; workspace and model files were preserved.'
echo 'Ollama and the shared OpenShell gateway are still running.'
