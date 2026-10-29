# openclaw-openshell

Run OpenClaw inside an NVIDIA OpenShell sandbox with a local Ollama model. The project installs the required services, applies a restricted network and filesystem policy, verifies local inference, and opens an interactive chat.

No paid API key, cloud model, Windows Ollama, or Windows Python installation is required.

## Choose your platform

- [Windows](#windows): starts from a clean Windows machine and manages Ubuntu through WSL 2.
- [Ubuntu](#ubuntu): installs and runs directly on an Ubuntu machine.

## Windows

### Install from a clean machine

Open **Command Prompt (CMD)** and run:

```cmd
curl.exe -fsSL https://raw.githubusercontent.com/AhmedUZaki/openclaw-openshell/main/Install.cmd -o "%TEMP%\openclaw-install.cmd" && call "%TEMP%\openclaw-install.cmd"
```

The installer detects the current state:

- **WSL or Ubuntu is missing:** it requests administrator approval and installs them.
- **Windows requests a restart:** restart, open Ubuntu once to create the Linux account, then run the same command again.
- **Ubuntu is already ready:** it skips WSL installation and continues immediately.
- **The project is already installed:** it updates and launches it.

Everything related to OpenClaw runs inside Ubuntu on WSL: Docker Engine, OpenShell, Ollama, the model, and agent data.

### Required user actions

Windows may require these one-time actions and they cannot be completed silently:

| Prompt | Action |
|---|---|
| UAC approval | Approve the administrator request used to install WSL. |
| Windows restart | Restart only when Windows requests it. |
| Ubuntu account | Choose a Linux username and password when Ubuntu first opens. |
| Ubuntu password | Enter it when `sudo` installs system packages. |
| Docker login refresh | If exit code 20 appears, run `wsl --shutdown` in CMD and run the installer again. |

### Windows commands

Run the download command above for normal chat. Add a mode after the downloaded file when needed:

```cmd
call "%TEMP%\openclaw-install.cmd" test
call "%TEMP%\openclaw-install.cmd" status
call "%TEMP%\openclaw-install.cmd" setup
```

The temporary installer may be removed by Windows. If it is missing, run the full download command again.

## Ubuntu

### Install from a clean machine

Use a normal user with `sudo` on Ubuntu with systemd:

```bash
sudo apt-get update
sudo apt-get install -y git
git clone https://github.com/AhmedUZaki/openclaw-openshell.git ~/openclaw-openshell
cd ~/openclaw-openshell
bash start.sh
```

The first launch installs Docker Engine, OpenShell, Ollama, and OpenClaw, downloads the local model, verifies inference, and opens chat.

If setup exits with code 20, log out and back in so Docker group membership takes effect, then run `bash start.sh` again.

### Ubuntu commands

```bash
cd ~/openclaw-openshell
bash start.sh          # open chat
bash start.sh test     # verify local inference
bash start.sh status   # show services, sandboxes, and models
bash start.sh setup    # rerun dependency setup
bash stop.sh           # stop this sandbox and preserve its data
```

Press Ctrl+C twice in quick succession to leave chat.

## Configuration

Both platform paths ultimately use the Ubuntu project directory. Create a local configuration there:

```bash
cp .env.example .env
nano .env
```

```dotenv
MODEL=qwen3.5:9b
CONTEXT=32768
SANDBOX=claw-ubuntu
```

Run `bash start.sh` again after changing the configuration. Missing models are downloaded automatically. `.env` and runtime files are ignored by Git and preserved during updates.

## What runs

```text
Ubuntu (native or WSL 2)
├── Docker Engine and OpenShell gateway
├── Ollama and the local model
└── OpenShell sandbox: claw-ubuntu
    └── OpenClaw → Ollama on the Ubuntu host
```

OpenClaw receives no Docker socket or Windows filesystem mount. The default policy allows its Node process to reach only the Ubuntu Ollama endpoint. Add explicit policy rules if the agent needs other network destinations.

Persistent data:

- Ollama models: typically `/usr/share/ollama/.ollama/models`
- OpenClaw configuration, workspace, and conversations: `/app/.openclaw` inside the persistent sandbox
- Launcher state: `.runtime/` in the project directory

## Requirements

- Internet access during initial setup
- Approximately 6.6 GB for the default model, plus Docker images and runtime data
- A locally runnable, tool-capable model
- Optional supported GPU; CPU inference can be significantly slower

The tested environment used OpenShell 0.1.6, OpenClaw 2026.10.8, Ollama 0.40.13, `qwen3.5:9b`, and an NVIDIA RTX 3080. Pinned versions and the OpenClaw image digest are recorded in `versions.env`.

## Troubleshooting

```bash
bash start.sh status
systemctl status docker ollama --no-pager
systemctl --user status openshell-gateway --no-pager
journalctl -u ollama -n 40 --no-pager
journalctl --user -u openshell-gateway -n 40 --no-pager
```

- **Exit code 20 or Docker permission denied:** refresh the Linux login, then launch again.
- **Interrupted model download:** launch again; Ollama reuses completed data.
- **Out of memory:** close other GPU workloads or select a smaller tool-capable model.
- **Another launcher is running:** close the existing chat or launcher first.
- **Sandbox provisioning failed:** inspect the OpenShell gateway logs above.

See [VALIDATION.md](VALIDATION.md) for tested behavior and known limits. Model weights, conversations, credentials, and runtime data are not committed to this repository.

References: [NVIDIA OpenShell](https://github.com/NVIDIA/OpenShell), [OpenClaw](https://docs.openclaw.ai/install/docker), [Ollama](https://docs.ollama.com/linux).
