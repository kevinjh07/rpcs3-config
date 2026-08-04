#!/usr/bin/env bash
# Pulls a live RPCS3 config into this repo, then strips the fields that
# are personal-machine identifiers rather than actual settings (PSID,
# system name, GPU adapter pin). Run this after changing settings in
# RPCS3, review with `git diff`, then commit.
#
# Usage:
#   ./scripts/sync.sh                      # auto-detect or use RPCS3_CONFIG_DIR/.env
#   ./scripts/sync.sh /path/to/rpcs3/config
#
# For Linux/macOS/WSL/Git-Bash-with-rsync. Native Windows: use sync.ps1.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=/dev/null
[[ -f "$SCRIPT_DIR/.env" ]] && source "$SCRIPT_DIR/.env"

RPCS3_CONFIG_DIR="${1:-${RPCS3_CONFIG_DIR:-}}"

if [[ -z "$RPCS3_CONFIG_DIR" ]]; then
  for candidate in \
    "$HOME/.config/rpcs3" \
    "/mnt/c/Users/$USER/AppData/Roaming/EmuDeck/Emulators/RPCS3/config" \
    "/mnt/c/Users/$USER/AppData/Roaming/rpcs3/config"
  do
    if [[ -d "$candidate" ]]; then
      RPCS3_CONFIG_DIR="$candidate"
      break
    fi
  done
fi

if [[ -z "$RPCS3_CONFIG_DIR" || ! -d "$RPCS3_CONFIG_DIR" ]]; then
  echo "Couldn't find your RPCS3 config folder." >&2
  echo "Pass it as an argument: ./scripts/sync.sh /path/to/rpcs3/config" >&2
  echo "Or set RPCS3_CONFIG_DIR (env var, or scripts/.env — see scripts/.env.example)." >&2
  exit 1
fi

EXCLUDES=(
  --exclude 'input_configs/gamecontrollerdb.txt'
  --exclude 'games.yml'
  --exclude 'uuid'
  --exclude 'vfs.yml'
  --exclude 'players_history.yml'
  --exclude '*.Zone.Identifier'
)

rsync -av --delete "${EXCLUDES[@]}" "$RPCS3_CONFIG_DIR/" "$REPO_DIR/config/"

# Neutralize per-machine identifiers so the repo stays safe to publish.
# Matched by key name, not by value, so this never has to hardcode
# anything about the machine it ran on.
find "$REPO_DIR/config" -name '*.yml' -print0 | xargs -0 sed -i -E \
  -e 's/^(\s*Console PSID:).*/\1 "0x00000000000000000000000000000000"/' \
  -e 's/^(\s*PSID (high|low):).*/\1 0/' \
  -e 's/^(\s*System Name:).*/\1 RPCS3/' \
  -e 's/^(\s*HDD (Model Name|Serial Number):).*/\1 ""/' \
  -e 's/^(\s*Adapter:).*/\1 ""/'

echo
echo "Synced from $RPCS3_CONFIG_DIR"
echo "Review with: git -C \"$REPO_DIR\" status / git diff"
