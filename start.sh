#!/usr/bin/env bash
# The only command needed for first setup and subsequent launches.
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
MODE="${1:-chat}"
case "$MODE" in chat|test|status|setup) ;; *) echo 'Usage: bash start.sh [chat|test|status|setup]' >&2; exit 2 ;; esac
[[ $(id -u) != 0 ]] || { echo 'Launch as your normal Ubuntu user, not root.' >&2; exit 1; }
[[ $(ps -p 1 -o comm=) == systemd ]] || { echo 'Ubuntu must run systemd. Enable systemd in WSL and restart the distribution.' >&2; exit 1; }
exec 9>"$PROJECT_DIR/.runtime/launcher.lock"
flock -n 9 || { echo 'Another launcher from this checkout is already running. Close it first.' >&2; exit 1; }
trap 'code=$?; echo "Launch failed (exit $code). Run bash start.sh status or see README.md → Troubleshooting." >&2' ERR
need_setup=false
for dependency in docker openshell ollama python3 curl; do
  command -v "$dependency" >/dev/null || need_setup=true
done
if ! id -nG | tr ' ' '\n' | grep -qx docker; then need_setup=true; fi
if [[ "$MODE" == setup || "$need_setup" == true ]]; then
  echo '[1/4] Installing missing dependencies (sudo may ask for your Ubuntu password)...'
  bash "$PROJECT_DIR/setup.sh"
  if [[ "$MODE" == setup ]]; then exit 0; fi
fi
echo '[1/4] Checking Ubuntu services...'
for service in docker ollama; do
  if ! systemctl is-active --quiet "$service"; then sudo systemctl start "$service"; fi
done
if [[ "$MODE" == status ]]; then exec bash "$PROJECT_DIR/run.sh" status; fi
echo "[2/4] Checking local model: $MODEL"
for i in {1..30}; do
  if curl -fsS --max-time 3 http://127.0.0.1:11434/api/tags > "$PROJECT_DIR/.runtime/models.json" 2>/dev/null; then break; fi
  sleep 1
done
if [[ ! -s "$PROJECT_DIR/.runtime/models.json" ]]; then echo 'Ubuntu Ollama did not become ready.' >&2; exit 1; fi
if ! python3 - "$PROJECT_DIR/.runtime/models.json" "$MODEL" <<'PY'
import json, sys
models = [m['name'] for m in json.load(open(sys.argv[1]))['models']]
raise SystemExit(0 if sys.argv[2] in models else 1)
PY
then
  echo 'Downloading the model once into Ubuntu. This may take several minutes.'
  ollama pull "$MODEL"
fi
echo '[3/4] Preparing the OpenShell sandbox...'
# A changed model, policy, image or configuration needs a new smoke test.
fingerprint="$(cat "$PROJECT_DIR/versions.env" "$PROJECT_DIR/policy.yaml" "$PROJECT_DIR/configure.cjs"; printf '%s\n' "$MODEL" "$CONTEXT" "$SANDBOX")"
fingerprint="$(printf '%s' "$fingerprint" | sha256sum | cut -d ' ' -f 1)"
if [[ "$MODE" == test ]]; then
  bash "$PROJECT_DIR/run.sh" test
  printf '%s\n' "$fingerprint" > "$PROJECT_DIR/.runtime/verified"
elif [[ ! -f "$PROJECT_DIR/.runtime/verified" ]] || [[ $(cat "$PROJECT_DIR/.runtime/verified") != "$fingerprint" ]]; then
  echo '[4/4] First launch: verifying local inference before opening chat...'
  # One sandbox preparation serves both the test and chat.
  OPENCLAW_VERIFIED_FILE="$PROJECT_DIR/.runtime/verified" OPENCLAW_FINGERPRINT="$fingerprint" bash "$PROJECT_DIR/run.sh" try
else
  echo '[4/4] Opening chat (configuration already verified)...'
  bash "$PROJECT_DIR/run.sh" chat
fi
