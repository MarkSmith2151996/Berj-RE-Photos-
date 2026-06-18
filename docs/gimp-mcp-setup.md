# GIMP MCP Setup

This guide documents the intended setup path for the Berj RE Photos worker environment.

## Overview

Primary target:

- `maorcc/gimp-mcp`

Reference alternative for future containerized workers:

- `abelduarte/gimp-mcp`

The current repo is scaffolded around the `maorcc/gimp-mcp` tool surface because it exposes the `get_state_snapshot` workflow that the editor worker prompt depends on.

## Install GIMP 3.2+

### macOS

```bash
brew install --cask gimp
```

Launch GIMP once after installation so its user config directories are created.

### Ubuntu / WSL

```bash
sudo apt update
sudo apt install -y gimp
```

If the package repository lags behind the desired GIMP 3.2 build, treat the distro package as the baseline and verify the exact version before production rollout.

## Install `maorcc/gimp-mcp`

```bash
git clone https://github.com/maorcc/gimp-mcp.git
cd gimp-mcp
uv sync
```

If `uv` is not installed:

```bash
python3 -m pip install uv
uv sync
```

## Copy the GIMP Plugin

The upstream project expects `gimp-mcp-plugin.py` to be copied into the active per-user GIMP plugin directory.

### macOS / Linux

```bash
# macOS
BASE="$HOME/Library/Application Support/GIMP"

# Linux standard install
# BASE="$HOME/.config/GIMP"

# Linux Snap install
# BASE="$HOME/snap/gimp/current/.config/GIMP"

GIMP_DIR="$(ls -d "$BASE"/3.* 2>/dev/null | sort -V | tail -1)"
mkdir -p "$GIMP_DIR/plug-ins/gimp-mcp-plugin"
cp gimp-mcp-plugin.py "$GIMP_DIR/plug-ins/gimp-mcp-plugin/"
chmod +x "$GIMP_DIR/plug-ins/gimp-mcp-plugin/gimp-mcp-plugin.py"
```

### Verification path in GIMP

Open GIMP and inspect:

- `Edit -> Preferences -> Folders -> Plug-ins`

Use the listed path if the auto-detected directory is wrong.

## Headless Mode

`maorcc/gimp-mcp` documents a plugin-driven startup flow from inside GIMP, not a fully automated private headless bridge.

Practical headless-style launch for batch workers:

```bash
gimp -i -d -f --new-instance >/tmp/berj-gimp.log 2>&1 &
```

Meaning:

- `-i`: no user interface
- `-d`: no data
- `-f`: no fonts
- `--new-instance`: avoid attaching to another session

Important limitation:

- The upstream README still expects the MCP server to be started from within GIMP via `Tools -> MCP -> Start MCP Server` after an image is opened.
- Because of that, true unattended worker startup is still a future integration task.

For a more container-native private bridge model, review `abelduarte/gimp-mcp` during implementation.

## MCP Server Startup

From the upstream `maorcc/gimp-mcp` repo:

```bash
uv run --directory /absolute/path/to/gimp-mcp gimp_mcp_server.py
```

The GIMP-side plugin must already be installed, and the MCP server inside GIMP must be running.

## Smoke Test

Do not treat this as completed until implementation-phase testing is allowed.

Suggested smoke test sequence:

1. Start GIMP.
2. Open any image.
3. In GIMP, run `Tools -> MCP -> Start MCP Server`.
4. In another shell, start the MCP server with `uv run --directory /absolute/path/to/gimp-mcp gimp_mcp_server.py`.
5. Confirm the bridge is reachable by invoking a low-risk tool such as image listing or GIMP info.

## Claude Desktop / Claude Code Config

### Claude Desktop

```json
{
  "mcpServers": {
    "gimp": {
      "command": "uv",
      "args": [
        "run",
        "--directory",
        "/absolute/path/to/gimp-mcp",
        "gimp_mcp_server.py"
      ]
    }
  }
}
```

### Claude Code

```bash
claude mcp add gimp-mcp -- uv run --directory /absolute/path/to/gimp-mcp gimp_mcp_server.py
```

## Known Issues

- Placeholder: confirm the exact unattended startup sequence required for `maorcc/gimp-mcp` in production worker environments.
- Placeholder: verify whether the target Linux environment ships GIMP 3.2+ directly or needs a custom install path.
