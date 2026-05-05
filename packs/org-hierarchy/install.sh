#!/usr/bin/env bash
# org-hierarchy — Director / Manager / 10 SDE org chart, activated by `use org`.
#
# Standalone installer. Works two ways:
#   1) Cloned repo:  bash install.sh
#   2) Curl install: curl -fsSL <url>/packs/org-hierarchy/install.sh | bash
# Pass --uninstall to remove what this installed.
set -euo pipefail

PACK_NAME="org-hierarchy"
REPO_URL_DEFAULT="https://raw.githubusercontent.com/harshm121/volt/main/packs/${PACK_NAME}"
REPO_URL="${VOLT_REPO_URL:-$REPO_URL_DEFAULT}"

CURSOR_DIR="${HOME}/.cursor"
RULES_DIR="${CURSOR_DIR}/rules"
ORG_DIR="${CURSOR_DIR}/org"
ROLES_DIR="${ORG_DIR}/roles"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { printf "${GREEN}[${PACK_NAME}]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }
err()  { printf "${RED}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

RULES=("rules/org-hierarchy.mdc")
ROLE_FILES=(
  "data/org/roles/data-engineer.md"
  "data/org/roles/env-steward.md"
  "data/org/roles/general-mle.md"
  "data/org/roles/job-launcher.md"
  "data/org/roles/job-monitor.md"
  "data/org/roles/lit-scout.md"
  "data/org/roles/run-triage-debugger.md"
  "data/org/roles/sweep-designer.md"
)

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

# Rewrite any packaging-machine absolute home prefix (/Users/<x>/.cursor/ or
# /home/<x>/.cursor/) to point at the runtime $HOME so the rule's role paths
# resolve on whichever machine installs the pack.
rewrite_home_paths() {
  local file="$1"
  python3 - "$file" "$HOME" <<'PY'
import re, sys
path, home = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
new = re.sub(r"(/Users/[^/\s]+|/home/[^/\s]+)/\.cursor/", home + "/.cursor/", content)
if new != content:
    with open(path, "w") as f:
        f.write(new)
PY
}

do_install() {
  require_cmd python3
  info "installing into ${CURSOR_DIR}..."
  mkdir -p "$RULES_DIR" "$ROLES_DIR"

  for rule in "${RULES[@]}"; do
    local name; name="$(basename "$rule")"
    fetch_or_copy "$rule" "$RULES_DIR/$name"
    rewrite_home_paths "$RULES_DIR/$name"
    info "rule installed -> $RULES_DIR/$name"
  done

  for role in "${ROLE_FILES[@]}"; do
    local name; name="$(basename "$role")"
    fetch_or_copy "$role" "$ROLES_DIR/$name"
  done
  info "${#ROLE_FILES[@]} role contracts installed -> $ROLES_DIR/"

  echo ""
  info "installed. Restart Cursor (or open a new window) to activate."
  info "trigger this protocol with the phrase: use org"
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

  for role in "${ROLE_FILES[@]}"; do
    local name; name="$(basename "$role")"
    if [ -f "$ROLES_DIR/$name" ]; then
      rm -f "$ROLES_DIR/$name"
    fi
  done
  info "removed role contracts from $ROLES_DIR/"

  # Clean up org/roles and org/ if they end up empty.
  if [ -d "$ROLES_DIR" ] && [ -z "$(ls -A "$ROLES_DIR" 2>/dev/null)" ]; then
    rmdir "$ROLES_DIR"
  fi
  if [ -d "$ORG_DIR" ] && [ -z "$(ls -A "$ORG_DIR" 2>/dev/null)" ]; then
    rmdir "$ORG_DIR"
  fi

  info "uninstalled. Restart Cursor for changes to take effect."
}

case "${1:-install}" in
  install|"")    do_install ;;
  --uninstall|uninstall) do_uninstall ;;
  -h|--help)
    cat <<EOF
org-hierarchy installer.

Usage:
  install.sh              install
  install.sh --uninstall  remove
  install.sh --help       show help
EOF
    ;;
  *) err "unknown argument: $1"; exit 1 ;;
esac
