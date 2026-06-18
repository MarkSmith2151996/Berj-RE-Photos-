#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEPS_DIR="${ROOT_DIR}/.deps"
GIMP_MCP_DIR="${DEPS_DIR}/gimp-mcp"

OS="$(uname -s)"
SMOKE_TEST_READY=false
PLUGIN_DIR=""
MCP_SERVER_CMD=()

log() {
  printf '[setup] %s\n' "$1"
}

warn() {
  printf '[warn] %s\n' "$1" >&2
}

fail() {
  printf '[error] %s\n' "$1" >&2
  exit 1
}

ensure_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Required command not found: $1"
  fi
}

install_gimp() {
  if command -v gimp >/dev/null 2>&1; then
    log "GIMP already installed: $(command -v gimp)"
    return
  fi

  case "$OS" in
    Darwin)
      ensure_cmd brew
      log "Installing GIMP via Homebrew cask"
      brew install --cask gimp
      ;;
    Linux)
      ensure_cmd sudo
      ensure_cmd apt
      log "Installing GIMP via apt"
      sudo apt update
      sudo apt install -y gimp
      ;;
    *)
      fail "Unsupported OS: $OS"
      ;;
  esac
}

install_uv_if_needed() {
  if command -v uv >/dev/null 2>&1; then
    log "uv already installed"
    return
  fi

  ensure_cmd python3
  log "Installing uv via pip"
  python3 -m pip install --user uv
  export PATH="$HOME/.local/bin:$PATH"
  command -v uv >/dev/null 2>&1 || fail "uv installation completed but uv is not on PATH"
}

clone_gimp_mcp() {
  mkdir -p "$DEPS_DIR"

  if [ -d "$GIMP_MCP_DIR/.git" ]; then
    log "gimp-mcp already cloned at $GIMP_MCP_DIR"
    return
  fi

  ensure_cmd git
  log "Cloning maorcc/gimp-mcp"
  git clone https://github.com/maorcc/gimp-mcp.git "$GIMP_MCP_DIR"
}

install_python_deps() {
  install_uv_if_needed
  log "Installing gimp-mcp Python dependencies"
  uv sync --directory "$GIMP_MCP_DIR"
}

resolve_plugin_dir() {
  local base=""

  case "$OS" in
    Darwin)
      base="$HOME/Library/Application Support/GIMP"
      ;;
    Linux)
      if [ -d "$HOME/.config/GIMP" ]; then
        base="$HOME/.config/GIMP"
      elif [ -d "$HOME/snap/gimp/current/.config/GIMP" ]; then
        base="$HOME/snap/gimp/current/.config/GIMP"
      else
        base="$HOME/.config/GIMP"
      fi
      ;;
    *)
      fail "Unsupported OS while resolving plugin directory: $OS"
      ;;
  esac

  if compgen -G "$base/3.*" >/dev/null 2>&1; then
    local version_dir
    version_dir="$(ls -d "$base"/3.* | sort -V | tail -1)"
    PLUGIN_DIR="$version_dir/plug-ins/gimp-mcp-plugin"
    return
  fi

  fail "No GIMP 3.x config directory found under $base. Launch GIMP once, then re-run this script."
}

install_plugin() {
  resolve_plugin_dir
  mkdir -p "$PLUGIN_DIR"
  cp "$GIMP_MCP_DIR/gimp-mcp-plugin.py" "$PLUGIN_DIR/"
  chmod +x "$PLUGIN_DIR/gimp-mcp-plugin.py"
  log "Installed plugin to $PLUGIN_DIR"
}

smoke_test() {
  local timeout_cmd=""

  if ! command -v gimp >/dev/null 2>&1; then
    fail "Cannot run smoke test because gimp is unavailable"
  fi

  if command -v timeout >/dev/null 2>&1; then
    timeout_cmd="timeout"
  elif command -v gtimeout >/dev/null 2>&1; then
    timeout_cmd="gtimeout"
  else
    fail "Smoke test requires timeout or gtimeout"
  fi

  MCP_SERVER_CMD=(uv run --directory "$GIMP_MCP_DIR" gimp_mcp_server.py)

  log "Launching headless GIMP smoke process"
  "$timeout_cmd" 10s gimp -i -d -f --new-instance >/tmp/berj-gimp-headless.log 2>&1 || true

  if [ -f /tmp/berj-gimp-headless.log ]; then
    log "Headless GIMP launch attempted; see /tmp/berj-gimp-headless.log"
  fi

  log "Checking whether the MCP server command can start"
  "$timeout_cmd" 5s "${MCP_SERVER_CMD[@]}" >/tmp/berj-gimp-mcp-server.log 2>&1 || true

  if [ -f /tmp/berj-gimp-mcp-server.log ]; then
    log "MCP server startup attempted; see /tmp/berj-gimp-mcp-server.log"
  fi

  cat <<'EOF'
[smoke] Next manual verification steps:
  1. Open GIMP with an image loaded.
  2. Run Tools -> MCP -> Start MCP Server.
  3. Start the MCP server with:
     uv run --directory /path/to/gimp-mcp gimp_mcp_server.py
  4. Verify the bridge responds to a low-risk command such as image listing or GIMP info.
EOF

  SMOKE_TEST_READY=true
}

print_summary() {
  log "Summary"
  printf '  OS: %s\n' "$OS"
  printf '  Repo root: %s\n' "$ROOT_DIR"
  printf '  gimp-mcp dir: %s\n' "$GIMP_MCP_DIR"
  printf '  plugin dir: %s\n' "$PLUGIN_DIR"
  printf '  smoke test prepared: %s\n' "$SMOKE_TEST_READY"
}

main() {
  install_gimp
  clone_gimp_mcp
  install_python_deps
  install_plugin
  smoke_test
  print_summary
  warn "This script prepares the environment, but unattended MCP startup still needs implementation validation."
}

main "$@"
