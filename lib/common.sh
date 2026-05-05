#!/usr/bin/env bash
# Shared install helpers for Volt packs.
#
# This file is sourced by the top-level installer and (when available) by per-pack
# install.sh scripts. Per-pack scripts also support running without this file —
# they fall back to inlined minimal versions of these helpers when invoked via
# `curl ... | bash` from a fresh machine.

set -euo pipefail

VOLT_GREEN='\033[0;32m'
VOLT_YELLOW='\033[1;33m'
VOLT_RED='\033[0;31m'
VOLT_NC='\033[0m'

volt_info() { printf "${VOLT_GREEN}[volt]${VOLT_NC} %s\n" "$1"; }
volt_warn() { printf "${VOLT_YELLOW}[volt]${VOLT_NC} %s\n" "$1" 1>&2; }
volt_err()  { printf "${VOLT_RED}[volt]${VOLT_NC} %s\n" "$1" 1>&2; }

volt_require() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || {
    volt_err "missing dependency: $cmd"
    return 1
  }
}

# volt_cursor_dir — echo the user's ~/.cursor directory, creating it if needed.
volt_cursor_dir() {
  local dir="${HOME}/.cursor"
  mkdir -p "$dir"
  printf "%s" "$dir"
}

# volt_install_file <src> <dest> [mode]
# Copy a file, creating parent directories. If `mode` is given, chmod after copy.
volt_install_file() {
  local src="$1" dest="$2" mode="${3:-}"
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  if [ -n "$mode" ]; then
    chmod "$mode" "$dest"
  fi
}

# volt_install_dir <src_dir> <dest_dir>
# Recursively copy a directory's contents into dest_dir. Creates dest_dir.
volt_install_dir() {
  local src="$1" dest="$2"
  mkdir -p "$dest"
  # Trailing slash on src ensures contents (not the dir itself) are copied.
  cp -R "$src/." "$dest/"
}

# volt_merge_hooks_json <pack_hooks_json> <target_hooks_json>
# Merge entries from pack_hooks_json into target_hooks_json. Appends entries
# (deduped by exact equality) under each event key. Creates target if missing.
volt_merge_hooks_json() {
  local pack_json="$1" target_json="$2"
  python3 - "$pack_json" "$target_json" <<'PY'
import json, os, sys

pack_path, target_path = sys.argv[1], sys.argv[2]

with open(pack_path) as f:
    pack = json.load(f)

if os.path.exists(target_path):
    with open(target_path) as f:
        try:
            target = json.load(f)
        except json.JSONDecodeError:
            print(f"[volt] target hooks.json is malformed: {target_path}", file=sys.stderr)
            sys.exit(1)
else:
    target = {"version": 1, "hooks": {}}

target.setdefault("version", pack.get("version", 1))
target.setdefault("hooks", {})

for event, entries in pack.get("hooks", {}).items():
    bucket = target["hooks"].setdefault(event, [])
    for entry in entries:
        if entry not in bucket:
            bucket.append(entry)

os.makedirs(os.path.dirname(target_path) or ".", exist_ok=True)
with open(target_path, "w") as f:
    json.dump(target, f, indent=2)
    f.write("\n")
PY
}

# volt_remove_hooks_json <pack_hooks_json> <target_hooks_json>
# Remove entries that match the pack's hooks.json from the target. Used during
# uninstall. Empty event arrays are removed.
volt_remove_hooks_json() {
  local pack_json="$1" target_json="$2"
  if [ ! -f "$target_json" ]; then
    return 0
  fi
  python3 - "$pack_json" "$target_json" <<'PY'
import json, sys

pack_path, target_path = sys.argv[1], sys.argv[2]

with open(pack_path) as f:
    pack = json.load(f)
with open(target_path) as f:
    target = json.load(f)

hooks = target.get("hooks", {})
for event, entries in pack.get("hooks", {}).items():
    bucket = hooks.get(event, [])
    hooks[event] = [e for e in bucket if e not in entries]
    if not hooks[event]:
        del hooks[event]

with open(target_path, "w") as f:
    json.dump(target, f, indent=2)
    f.write("\n")
PY
}

# volt_rewrite_home <file>
# In-place replace the literal absolute path of a packaging machine's home with
# the runtime $HOME so role-contract paths and similar references stay valid on
# whichever machine installs the pack.
volt_rewrite_home() {
  local file="$1"
  python3 - "$file" "$HOME" <<'PY'
import re, sys
path, home = sys.argv[1], sys.argv[2]
with open(path) as f:
    content = f.read()
# Match any absolute /Users/<name>/.cursor/ or /home/<name>/.cursor/ prefix
# that came from the packaging machine and rewrite it to the runtime $HOME.
new = re.sub(r"(/Users/[^/\s]+|/home/[^/\s]+)/\.cursor/", home + "/.cursor/", content)
if new != content:
    with open(path, "w") as f:
        f.write(new)
PY
}
