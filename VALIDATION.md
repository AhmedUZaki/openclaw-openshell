# Verification

## Tested environment

- Host: Windows with Ubuntu 26.04 under WSL 2.
- Project executed from the Ubuntu filesystem: `~/projects/openclaw-ubuntu`.
- OpenShell: 0.1.6, with a local Docker Engine gateway.
- Ollama: 0.40.13, installed as an Ubuntu systemd service.
- OpenClaw: 2026.10.8, using the official image digest in `versions.env`.
- Local model: `qwen3.5:9b`, approximately 6.6 GB, physically stored in Ubuntu.
- GPU: NVIDIA RTX 3080; `ollama ps` reported 100% GPU and 32768 context.

## Results

- Fresh sandbox creation and native Ubuntu inference returned `OPENCLAW_LOCAL_OK` and exit code 0.
- The old Windows relay service was stopped and disabled. A second test restarted the existing sandbox and returned the same successful result without that relay.
- Bash syntax checks passed for every shipped shell script. The Windows CMD installer rejected invalid modes before entering Ubuntu.
- OpenClaw used file tools to write and read `ubuntu-check.txt`. A separate OpenShell command confirmed its exact contents were `UBUNTU_SANDBOX_OK`.
- The Windows model blobs were copied once into Ubuntu for this machine and verified against their SHA-256 digests. The new-machine setup downloads its own model directly in Ubuntu; it does not use Windows model files.
- The first-launch path automatically ran the smoke test and then opened the local terminal chat UI. The already-verified launch path also opened chat successfully.
- A message sent through the interactive chat UI returned the requested `TUI_LOCAL_OK` response. The UI exited successfully using two consecutive Ctrl+C key presses.
- A concurrent launch was rejected while chat held the launcher lock. An invalid context setting was rejected before startup.
- The Windows `Install.cmd status` bootstrap successfully entered WSL, updated the Ubuntu checkout, and reported OpenShell, sandbox, and Ollama model status.
- Invalid `Install.cmd` modes are rejected before any Ubuntu command is executed.
- The distribution manifest matched all 15 published source files and excludes local runtime directories.

## Limits

- A clean installation on a second machine was not performed. The setup script's package installation path is documented, including Docker group login refresh.
- Performance and GPU support depend on each host. CPU fallback can be slow.
- No embedding model is configured. OpenClaw can emit semantic-memory warnings during otherwise successful tests.
- New OS installation, the automatic administrator-elevation branch, and the one-time Docker group refresh were not exercised on a second clean machine. The unavoidable user interactions remain documented in the English README.
- Published source targets AhmedUZaki/openclaw-openshell. Model weights and local runtime data are excluded.

The published source excludes runtime files, model weights, conversation data, and local Git metadata.
