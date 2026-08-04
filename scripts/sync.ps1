# Pulls a live RPCS3 config into this repo, then strips the fields that
# are personal-machine identifiers rather than actual settings (PSID,
# system name, GPU adapter pin). Run this after changing settings in
# RPCS3, review with `git diff`, then commit.
#
# Usage:
#   .\scripts\sync.ps1
#   .\scripts\sync.ps1 -ConfigDir "C:\path\to\rpcs3\config"
#
# Native Windows, no extra installs (uses built-in robocopy). If Windows
# blocks the script (execution policy), run it as:
#   powershell -ExecutionPolicy Bypass -File .\scripts\sync.ps1
param(
    [string]$ConfigDir
)

$ErrorActionPreference = "Stop"
$RepoDir = Split-Path -Parent $PSScriptRoot

if (-not $ConfigDir) { $ConfigDir = $env:RPCS3_CONFIG_DIR }

if (-not $ConfigDir) {
    $candidates = @(
        (Join-Path $env:APPDATA "EmuDeck\Emulators\RPCS3\config"),
        (Join-Path $env:APPDATA "rpcs3\config")
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $ConfigDir = $c; break }
    }
}

if (-not $ConfigDir -or -not (Test-Path $ConfigDir)) {
    Write-Error "Couldn't find your RPCS3 config folder.`nPass it: .\scripts\sync.ps1 -ConfigDir 'C:\path\to\rpcs3\config'`nOr set `$env:RPCS3_CONFIG_DIR."
    exit 1
}

$RepoConfig = Join-Path $RepoDir "config"
New-Item -ItemType Directory -Force -Path $RepoConfig | Out-Null

robocopy "$ConfigDir" "$RepoConfig" /MIR /XF gamecontrollerdb.txt games.yml uuid vfs.yml players_history.yml *.Zone.Identifier /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) {
    Write-Error "robocopy failed with exit code $LASTEXITCODE"
    exit 1
}

# Neutralize per-machine identifiers so the repo stays safe to publish.
# Matched by key name, not by value, so this never has to hardcode
# anything about the machine it ran on.
Get-ChildItem -Path $RepoConfig -Filter *.yml -Recurse | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName)
    $text = $text -replace '(?m)^(\s*Console PSID:).*', '$1 "0x00000000000000000000000000000000"'
    $text = $text -replace '(?m)^(\s*PSID (high|low):).*', '$1 0'
    $text = $text -replace '(?m)^(\s*System Name:).*', '$1 RPCS3'
    $text = $text -replace '(?m)^(\s*HDD (Model Name|Serial Number):).*', '$1 ""'
    $text = $text -replace '(?m)^(\s*Adapter:).*', '$1 ""'
    [System.IO.File]::WriteAllText($_.FullName, $text, [System.Text.UTF8Encoding]::new($false))
}

Write-Host ""
Write-Host "Synced from $ConfigDir"
Write-Host "Review with: git status / git diff"
