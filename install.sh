#!/usr/bin/env bash
# Volt — top-level installer dispatcher.
#
# Usage:
#   ./install.sh <pack> [<pack> ...]   install one or more packs
#   ./install.sh all                   install every pack
#   ./install.sh --list                list available packs
#   ./install.sh --uninstall <pack>    uninstall a pack
#   ./install.sh -h | --help           show help

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKS_DIR="$SCRIPT_DIR/packs"
LIB="$SCRIPT_DIR/lib/common.sh"

if [ ! -f "$LIB" ]; then
  echo "[volt] missing lib/common.sh — run install.sh from inside the repo." 1>&2
  exit 1
fi
# shellcheck source=lib/common.sh
source "$LIB"

usage() {
  cat <<EOF
Volt — Cursor hooks, rules, and skills.

Usage:
  $(basename "$0") <pack> [<pack> ...]   install one or more packs
  $(basename "$0") all                   install every available pack
  $(basename "$0") --list                list available packs
  $(basename "$0") --uninstall <pack>    uninstall a pack
  $(basename "$0") -h | --help           show this help

After install or uninstall, restart Cursor (or open a new window).
EOF
}

list_packs() {
  for d in "$PACKS_DIR"/*/; do
    [ -d "$d" ] || continue
    local name
    name="$(basename "$d")"
    case "$name" in
      _template) continue ;;
    esac
    if [ -f "$d/manifest.json" ]; then
      local desc
      desc=$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('description',''))" "$d/manifest.json" 2>/dev/null || echo "")
      printf "  %-20s %s\n" "$name" "$desc"
    else
      printf "  %s\n" "$name"
    fi
  done
}

run_pack() {
  local pack="$1" action="${2:-install}"
  local pack_dir="$PACKS_DIR/$pack"
  if [ ! -d "$pack_dir" ]; then
    volt_err "unknown pack: $pack"
    volt_warn "available packs:"
    list_packs 1>&2
    return 1
  fi
  local installer="$pack_dir/install.sh"
  if [ ! -x "$installer" ] && [ ! -f "$installer" ]; then
    volt_err "$pack has no install.sh"
    return 1
  fi
  case "$action" in
    install)   bash "$installer" ;;
    uninstall) bash "$installer" --uninstall ;;
    *) volt_err "unknown action: $action"; return 1 ;;
  esac
}

main() {
  if [ $# -eq 0 ]; then
    usage
    echo ""
    echo "Available packs:"
    list_packs
    exit 0
  fi

  case "$1" in
    -h|--help)
      usage; exit 0 ;;
    --list)
      list_packs; exit 0 ;;
    --uninstall)
      shift
      [ $# -eq 0 ] && { volt_err "--uninstall requires a pack name"; exit 1; }
      for p in "$@"; do
        volt_info "uninstalling $p..."
        run_pack "$p" uninstall
      done
      exit 0 ;;
    all)
      for d in "$PACKS_DIR"/*/; do
        [ -d "$d" ] || continue
        local name
        name="$(basename "$d")"
        [ "$name" = "_template" ] && continue
        volt_info "installing $name..."
        run_pack "$name" install
      done
      exit 0 ;;
    *)
      for p in "$@"; do
        volt_info "installing $p..."
        run_pack "$p" install
      done
      ;;
  esac
}

main "$@"
