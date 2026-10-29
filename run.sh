#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
MODE="${1:-chat}"
case "$MODE" in test|chat|status|try) ;; *) echo 'Usage: bash run.sh [test|chat|status|try]' >&2; exit 1 ;; esac
for dependency in docker openshell ollama python3 curl; do
  command -v "$dependency" >/dev/null || { echo "Missing $dependency. Run bash setup.sh first." >&2; exit 1; }
done
docker info >/dev/null 2>&1 || { echo 'Docker unavailable. Check sudo systemctl start docker and refresh docker group membership.' >&2; exit 1; }
systemctl --user start openshell-gateway
for i in {1..30}; do
  if openshell status >/dev/null 2>&1; then break; fi
  sleep 1
done
if [[ "$MODE" == status ]]; then
  openshell status
  openshell sandbox list
  ollama list
  exit
fi
openshell status >/dev/null
curl -fsS --max-time 5 http://127.0.0.1:11434/api/tags > "$PROJECT_DIR/.runtime/models.json" || { echo 'Ubuntu Ollama is unavailable. Run sudo systemctl start ollama.' >&2; exit 1; }
python3 - "$PROJECT_DIR/.runtime/models.json" "$MODEL" <<'PY'
import json, sys
models = [m['name'] for m in json.load(open(sys.argv[1]))['models']]
if sys.argv[2] not in models:
    raise SystemExit('Model missing in Ubuntu Ollama. Run: ollama pull ' + sys.argv[2])
PY
if ! openshell sandbox get "$SANDBOX" > "$PROJECT_DIR/.runtime/sandbox.txt" 2>&1; then
  if ! grep -Eiq 'not found|not_found|does not exist' "$PROJECT_DIR/.runtime/sandbox.txt"; then
    cat "$PROJECT_DIR/.runtime/sandbox.txt" >&2; exit 1
  fi
  openshell sandbox create --name "$SANDBOX" --from "$OPENCLAW_IMAGE" --policy "$PROJECT_DIR/policy.yaml" --detach -- /bin/sh -c 'sleep infinity'
else
  openshell policy set "$SANDBOX" --policy "$PROJECT_DIR/policy.yaml" --wait
  # A restart activates filesystem policy and recovers stale runtime sessions.
  openshell sandbox stop "$SANDBOX"
  openshell sandbox start "$SANDBOX"
fi
for i in {1..60}; do
  if openshell sandbox exec "$SANDBOX" -- true >/dev/null 2>&1; then break; fi
  sleep 1
done
openshell sandbox exec "$SANDBOX" -- true
if ! openshell sandbox exec "$SANDBOX" -- test -f /app/.openclaw/openclaw.json; then
  openshell sandbox exec "$SANDBOX" -- openclaw setup --baseline
fi
SCRIPT64="$(base64 -w0 "$PROJECT_DIR/configure.cjs")"
openshell sandbox exec "$SANDBOX" -- node -e "eval(Buffer.from('$SCRIPT64','base64').toString())" "$MODEL" "$CONTEXT"
if [[ "$MODE" == test || "$MODE" == try ]]; then
  openshell sandbox exec "$SANDBOX" -- openclaw agent --local --agent main --session-id "smoke-$(date +%s)" --thinking off --message 'Reply with exactly: OPENCLAW_LOCAL_OK' --timeout 180 | tee "$PROJECT_DIR/.runtime/smoke-result.txt"
  grep -qx 'OPENCLAW_LOCAL_OK' "$PROJECT_DIR/.runtime/smoke-result.txt"
  echo 'PASS: OpenClaw inside OpenShell used the local Ubuntu Ollama model.'
  if [[ -n "${OPENCLAW_VERIFIED_FILE:-}" ]]; then printf '%s\n' "$OPENCLAW_FINGERPRINT" > "$OPENCLAW_VERIFIED_FILE"; fi
fi
if [[ "$MODE" == chat || "$MODE" == try ]]; then
  openshell sandbox exec "$SANDBOX" --tty -- openclaw chat --local --thinking off
fi
