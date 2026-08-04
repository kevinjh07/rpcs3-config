#!/usr/bin/env bash
# Applies this repo's config onto a live RPCS3 install. Since the repo is
# public and sanitized (see sync.sh), this gives you RPCS3's normal
# defaults for the machine-identity fields (auto GPU pick, fresh PSID) —
# it's meant for bootstrapping a fresh/new install, not as a byte-for-byte
# personal disaster-recovery snapshot. RPCS3 must be closed while restoring.
#
# Usage:
#   ./scripts/restore.sh                      # auto-detect or use RPCS3_CONFIG_DIR/.env
#   ./scripts/restore.sh /path/to/rpcs3/config
#
# For Linux/macOS/WSL/Git-Bash-with-rsync. Native Windows: use restore.ps1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
[[ -f "$SCRIPT_DIR/.env" ]] && source "$SCRIPT_DIR/.env"

RPCS3_CONFIG_DIR="${1:-${RPCS3_CONFIG_DIR:-}}"

if [[ -z "$RPCS3_CONFIG_DIR" ]]; then
  echo "No target given." >&2
  echo "Pass it as an argument: ./scripts/restore.sh /path/to/rpcs3/config" >&2
  echo "Or set RPCS3_CONFIG_DIR (env var, or scripts/.env — see scripts/.env.example)." >&2
  exit 1
fi

read -rp "This overwrites the live RPCS3 config at $RPCS3_CONFIG_DIR. Continue? [y/N] " confirm
[[ "$confirm" == "y" || "$confirm" == "Y" ]] || { echo "Aborted."; exit 1; }

# Same excludes as sync.sh, in reverse: with --delete active, forgetting
# these would wipe your real games.yml/uuid/vfs.yml on restore, since
# this repo never tracks them and they'd look like "extra" files to remove.
rsync -av --delete \
  --exclude 'input_configs/gamecontrollerdb.txt' \
  --exclude 'games.yml' \
  --exclude 'uuid' \
  --exclude 'vfs.yml' \
  --exclude 'players_history.yml' \
  "$REPO_DIR/config/" "$RPCS3_CONFIG_DIR/"

echo "Restored to $RPCS3_CONFIG_DIR"
echo "Note: games.yml/vfs.yml/uuid were left untouched (they're machine-specific, not tracked here)."
