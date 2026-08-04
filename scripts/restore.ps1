# Applies this repo's config onto a live RPCS3 install. Since the repo is
# public and sanitized (see sync.ps1), this gives you RPCS3's normal
# defaults for the machine-identity fields (auto GPU pick, fresh PSID) —
# it's meant for bootstrapping a fresh/new install, not as a byte-for-byte
# personal disaster-recovery snapshot. RPCS3 must be closed while restoring.
#
# Usage:
#   .\scripts\restore.ps1
#   .\scripts\restore.ps1 -ConfigDir "C:\path\to\rpcs3\config"
param(
    [string]$ConfigDir
)

$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $PSScriptRoot

if (-not $ConfigDir) { $ConfigDir = $env:RPCS3_CONFIG_DIR }

if (-not $ConfigDir) {
    Write-Error "No target given.`nPass it: .\scripts\restore.ps1 -ConfigDir 'C:\path\to\rpcs3\config'`nOr set `$env:RPCS3_CONFIG_DIR."
    exit 1
}

$confirm = Read-Host "This overwrites the live RPCS3 config at $ConfigDir. Continue? [y/N]"
if ($confirm -notin @("y", "Y")) {
    Write-Host "Aborted."
    exit 1
}

$RepoConfig = Join-Path $RepoDir "config"

# Same excludes as sync.ps1, in reverse: with /MIR active, forgetting
# these would wipe your real games.yml/uuid/vfs.yml on restore, since
# this repo never tracks them and they'd look like "extra" files to remove.
robocopy "$RepoConfig" "$ConfigDir" /MIR /XF gamecontrollerdb.txt games.yml uuid vfs.yml players_history.yml /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy failed with exit code $LASTEXITCODE"
    exit 1
}

Write-Host "Restored to $ConfigDir"
Write-Host "Note: games.yml/vfs.yml/uuid were left untouched (they're machine-specific, not tracked here)."
