#!/usr/bin/env bash
# llm-thinkers — breadth-first ideation panel on three fixed models that hands
# off to the llm-council pack for ranking. Activated by the phrase `use thinkers`.
#
# Standalone installer. Works two ways:
#   1) Cloned repo:  bash install.sh
#   2) Curl install: curl -fsSL <url>/packs/llm-thinkers/install.sh | bash
# Pass --uninstall to remove what this installed.
set -euo pipefail

PACK_NAME="llm-thinkers"
REPO_URL_DEFAULT="https://raw.githubusercontent.com/harshm121/volt/main/packs/${PACK_NAME}"
REPO_URL="${VOLT_REPO_URL:-$REPO_URL_DEFAULT}"

CURSOR_DIR="${HOME}/.cursor"
RULES_DIR="${CURSOR_DIR}/rules"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { printf "${GREEN}[${PACK_NAME}]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }
err()  { printf "${RED}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

RULES=("rules/llm-thinkers.mdc")

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "missing dependency: $1"; exit 1; }
}

fetch_or_copy() {
  local rel="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$SCRIPT_DIR/$rel" ]; then
    cp "$SCRIPT_DIR/$rel" "$dest"
  else
    require_cmd curl
    curl -fsSL "$REPO_URL/$rel" -o "$dest"
  fi
}

do_install() {
  info "installing into ${CURSOR_DIR}..."
  mkdir -p "$RULES_DIR"
  for rule in "${RULES[@]}"; do
    local name; name="$(basename "$rule")"
    fetch_or_copy "$rule" "$RULES_DIR/$name"
    info "rule installed -> $RULES_DIR/$name"
  done

  echo ""
  info "installed. Restart Cursor (or open a new window) to activate."
  info "trigger this protocol with the phrase: use thinkers"

  # Soft advisory: this pack hands off to the llm-council pack in Step 3.
  if [ ! -f "$RULES_DIR/llm-council.mdc" ]; then
    echo ""
    warn "this pack hands off to llm-council in Step 3, but ${RULES_DIR}/llm-council.mdc was not found."
    warn "install it too:"
    warn "  curl -fsSL https://raw.githubusercontent.com/harshm121/volt/main/packs/llm-council/install.sh | bash"
  else
    info "llm-council rule detected at $RULES_DIR/llm-council.mdc — ranking handoff will resolve."
  fi
}

do_uninstall() {
  info "uninstalling from ${CURSOR_DIR}..."
  for rule in "${RULES[@]}"; do
    local name; name="$(basename "$rule")"
    if [ -f "$RULES_DIR/$name" ]; then
      rm -f "$RULES_DIR/$name"
      info "removed $RULES_DIR/$name"
    fi
  done
  info "uninstalled. Restart Cursor for changes to take effect."
}

case "${1:-install}" in
  install|"")    do_install ;;
  --uninstall|uninstall) do_uninstall ;;
  -h|--help)
    cat <<EOF
llm-thinkers installer.

Usage:
  install.sh              install
  install.sh --uninstall  remove
  install.sh --help       show help
EOF
    ;;
  *) err "unknown argument: $1"; exit 1 ;;
esac
