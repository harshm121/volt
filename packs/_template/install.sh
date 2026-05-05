#!/usr/bin/env bash
# <pack-name> — <one-line description>
#
# Standalone installer. Works two ways:
#   1) Cloned repo:  bash install.sh
#   2) Curl install: curl -fsSL <url>/packs/<pack-name>/install.sh | bash
# Pass --uninstall to remove what this installed.
set -euo pipefail

# === EDIT THESE ============================================================
PACK_NAME="REPLACE_ME"

# Files to copy into ~/.cursor/rules/.
# Each entry is a path inside this pack directory.
RULES=(
  # "rules/your-rule.mdc"
)

# Hook scripts copied into ~/.cursor/hooks/ and chmod +x'd.
HOOKS=(
  # "hooks/your-hook.sh"
)

# Skill directories. Each entry is a folder under skills/ that becomes
# ~/.cursor/skills-cursor/<basename>/ on install. The folder must contain
# at least a SKILL.md.
SKILLS=(
  # "skills/your-skill"
)

# Path-style data files copied verbatim into ~/.cursor/<rest>. Each entry
# is a path inside this pack directory under data/, where everything after
# data/ is the destination path inside ~/.cursor/.
# Example: data/org/roles/foo.md -> ~/.cursor/org/roles/foo.md
DATA_FILES=(
  # "data/your-namespace/your-file.md"
)

# Path to a hooks.json fragment to merge into ~/.cursor/hooks.json.
# Empty string means no hooks.json changes.
HOOKS_JSON_FRAGMENT=""
# === END EDITABLE BLOCK ====================================================

REPO_URL_DEFAULT="https://raw.githubusercontent.com/harshm121/volt/main/packs/${PACK_NAME}"
REPO_URL="${VOLT_REPO_URL:-$REPO_URL_DEFAULT}"

CURSOR_DIR="${HOME}/.cursor"
RULES_DIR="${CURSOR_DIR}/rules"
HOOKS_DIR="${CURSOR_DIR}/hooks"
SKILLS_DIR="${CURSOR_DIR}/skills-cursor"
HOOKS_JSON="${CURSOR_DIR}/hooks.json"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { printf "${GREEN}[${PACK_NAME}]${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }
err()  { printf "${RED}[${PACK_NAME}]${NC} %s\n" "$1" 1>&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"

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

fetch_or_copy_dir() {
  # fetch_or_copy_dir <relative_pack_dir> <destination_absolute_dir>
  # Local mode copies the directory recursively. Remote mode is unsupported
  # for arbitrary directories — manifest the individual files instead.
  local rel="$1" dest="$2"
  if [ -d "$SCRIPT_DIR/$rel" ]; then
    mkdir -p "$dest"
    cp -R "$SCRIPT_DIR/$rel/." "$dest/"
  else
    err "remote-install of skill directories is not supported; clone the repo or list files in DATA_FILES"
    exit 1
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

dest_for_data() {
  # data/<rest> -> ~/.cursor/<rest>
  local rel="$1"
  printf "%s/%s" "$CURSOR_DIR" "${rel#data/}"
}

do_install() {
  info "installing into ${CURSOR_DIR}..."
  mkdir -p "$RULES_DIR" "$HOOKS_DIR" "$SKILLS_DIR"

  for rule in "${RULES[@]:-}"; do
    [ -z "$rule" ] && continue
    local name; name="$(basename "$rule")"
    fetch_or_copy "$rule" "$RULES_DIR/$name"
    info "rule installed -> $RULES_DIR/$name"
  done

  for hook in "${HOOKS[@]:-}"; do
    [ -z "$hook" ] && continue
    local name; name="$(basename "$hook")"
    fetch_or_copy "$hook" "$HOOKS_DIR/$name"
    chmod +x "$HOOKS_DIR/$name"
    info "hook installed -> $HOOKS_DIR/$name"
  done

  for skill in "${SKILLS[@]:-}"; do
    [ -z "$skill" ] && continue
    local name; name="$(basename "$skill")"
    fetch_or_copy_dir "$skill" "$SKILLS_DIR/$name"
    info "skill installed -> $SKILLS_DIR/$name/"
  done

  for data in "${DATA_FILES[@]:-}"; do
    [ -z "$data" ] && continue
    local dest; dest="$(dest_for_data "$data")"
    fetch_or_copy "$data" "$dest"
  done
  if [ "${#DATA_FILES[@]:-0}" -gt 0 ]; then
    info "${#DATA_FILES[@]} data file(s) installed under ${CURSOR_DIR}/"
  fi

  if [ -n "$HOOKS_JSON_FRAGMENT" ]; then
    require_cmd python3
    local tmp; tmp="$(mktemp)"
    fetch_or_copy "$HOOKS_JSON_FRAGMENT" "$tmp"
    merge_hooks_json "$tmp" "$HOOKS_JSON"
    rm -f "$tmp"
    info "hook config merged into $HOOKS_JSON"
  fi

  echo ""
  info "installed. Restart Cursor (or open a new window) to activate."
}

do_uninstall() {
  info "uninstalling from ${CURSOR_DIR}..."

  for rule in "${RULES[@]:-}"; do
    [ -z "$rule" ] && continue
    local name; name="$(basename "$rule")"
    [ -f "$RULES_DIR/$name" ] && rm -f "$RULES_DIR/$name" && info "removed $RULES_DIR/$name"
  done

  for hook in "${HOOKS[@]:-}"; do
    [ -z "$hook" ] && continue
    local name; name="$(basename "$hook")"
    [ -f "$HOOKS_DIR/$name" ] && rm -f "$HOOKS_DIR/$name" && info "removed $HOOKS_DIR/$name"
  done

  for skill in "${SKILLS[@]:-}"; do
    [ -z "$skill" ] && continue
    local name; name="$(basename "$skill")"
    [ -d "$SKILLS_DIR/$name" ] && rm -rf "$SKILLS_DIR/$name" && info "removed $SKILLS_DIR/$name/"
  done

  for data in "${DATA_FILES[@]:-}"; do
    [ -z "$data" ] && continue
    local dest; dest="$(dest_for_data "$data")"
    [ -f "$dest" ] && rm -f "$dest"
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

case "${1:-install}" in
  install|"")    do_install ;;
  --uninstall|uninstall) do_uninstall ;;
  -h|--help)
    cat <<EOF
${PACK_NAME} installer.

Usage:
  install.sh              install
  install.sh --uninstall  remove
  install.sh --help       show help
EOF
    ;;
  *) err "unknown argument: $1"; exit 1 ;;
esac
