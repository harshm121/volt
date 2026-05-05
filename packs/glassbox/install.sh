#!/usr/bin/env bash
# Glassbox — auto-generated .vis.md mermaid companions for every code file.
#
# Standalone installer. Works two ways:
#   1) Cloned repo:  bash install.sh
#   2) Curl install: curl -fsSL <url>/packs/glassbox/install.sh | bash
# Pass --uninstall to remove what this installed.
set -euo pipefail

PACK_NAME="glassbox"
REPO_URL_DEFAULT="https://raw.githubusercontent.com/harshm121/volt/main/packs/${PACK_NAME}"
REPO_URL="${VOLT_REPO_URL:-$REPO_URL_DEFAULT}"

CURSOR_DIR="${HOME}/.cursor"
RULES_DIR="${CURSOR_DIR}/rules"
HOOKS_DIR="${CURSOR_DIR}/hooks"
HOOKS_JSON="${CURSOR_DIR}/hooks.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { printf "${GREEN}[${PACK_NAME}]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }
err()  { printf "${RED}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

# Asset manifest (relative paths inside the pack directory).
RULES=("rules/glassbox.mdc")
HOOKS=("hooks/check-vis-md.sh")
HOOKS_JSON_FRAGMENT="hooks.json"

# ---- helpers ----------------------------------------------------------------

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { err "missing dependency: $1"; exit 1; }
}

fetch_or_copy() {
  # fetch_or_copy <relative_pack_path> <destination_absolute_path>
  local rel="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$SCRIPT_DIR/$rel" ]; then
    cp "$SCRIPT_DIR/$rel" "$dest"
  else
    require_cmd curl
    curl -fsSL "$REPO_URL/$rel" -o "$dest"
  fi
}

merge_hooks_json() {
  local fragment_path="$1" target="$2"
  python3 - "$fragment_path" "$target" <<'PY'
import json, os, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    new = json.load(f)
if os.path.exists(dst):
    with open(dst) as f:
        cur = json.load(f)
else:
    cur = {"version": new.get("version", 1), "hooks": {}}
cur.setdefault("version", new.get("version", 1))
cur.setdefault("hooks", {})
for event, entries in new.get("hooks", {}).items():
    bucket = cur["hooks"].setdefault(event, [])
    for e in entries:
        if e not in bucket:
            bucket.append(e)
with open(dst, "w") as f:
    json.dump(cur, f, indent=2); f.write("\n")
PY
}

remove_hooks_json() {
  local fragment_path="$1" target="$2"
  [ -f "$target" ] || return 0
  python3 - "$fragment_path" "$target" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as f:
    new = json.load(f)
with open(dst) as f:
    cur = json.load(f)
hooks = cur.get("hooks", {})
for event, entries in new.get("hooks", {}).items():
    bucket = hooks.get(event, [])
    hooks[event] = [e for e in bucket if e not in entries]
    if not hooks[event]:
        del hooks[event]
with open(dst, "w") as f:
    json.dump(cur, f, indent=2); f.write("\n")
PY
}

# ---- actions ----------------------------------------------------------------

do_install() {
  require_cmd python3
  info "installing into ${CURSOR_DIR}..."
  mkdir -p "$RULES_DIR" "$HOOKS_DIR"

  for rule in "${RULES[@]}"; do
    local name; name="$(basename "$rule")"
    fetch_or_copy "$rule" "$RULES_DIR/$name"
    info "rule installed -> $RULES_DIR/$name"
  done

  for hook in "${HOOKS[@]}"; do
    local name; name="$(basename "$hook")"
    fetch_or_copy "$hook" "$HOOKS_DIR/$name"
    chmod +x "$HOOKS_DIR/$name"
    info "hook installed -> $HOOKS_DIR/$name"
  done

  if [ -n "$HOOKS_JSON_FRAGMENT" ]; then
    local tmp; tmp="$(mktemp)"
    fetch_or_copy "$HOOKS_JSON_FRAGMENT" "$tmp"
    merge_hooks_json "$tmp" "$HOOKS_JSON"
    rm -f "$tmp"
    info "hook config merged into $HOOKS_JSON"
  fi

  echo ""
  info "installed. Restart Cursor (or open a new window) to activate."
  info "what's next:"
  info "  1) ask Cursor to edit code — it will auto-generate .vis.md files"
  info "  2) open any .vis.md and press Cmd+Shift+V to view the diagrams"
  info "  3) commit the .vis/ directory alongside your code"
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

  for hook in "${HOOKS[@]}"; do
    local name; name="$(basename "$hook")"
    if [ -f "$HOOKS_DIR/$name" ]; then
      rm -f "$HOOKS_DIR/$name"
      info "removed $HOOKS_DIR/$name"
    fi
  done

  if [ -n "$HOOKS_JSON_FRAGMENT" ] && [ -f "$HOOKS_JSON" ]; then
    require_cmd python3
    local tmp; tmp="$(mktemp)"
    fetch_or_copy "$HOOKS_JSON_FRAGMENT" "$tmp"
    remove_hooks_json "$tmp" "$HOOKS_JSON"
    rm -f "$tmp"
    info "hook entries removed from $HOOKS_JSON"
  fi

  info "uninstalled. Restart Cursor for changes to take effect."
}

# ---- entrypoint -------------------------------------------------------------

case "${1:-install}" in
  install|"")    do_install ;;
  --uninstall|uninstall) do_uninstall ;;
  -h|--help)
    cat <<EOF
Glassbox installer.

Usage:
  install.sh              install
  install.sh --uninstall  remove
  install.sh --help       show help
EOF
    ;;
  *) err "unknown argument: $1"; exit 1 ;;
esac
