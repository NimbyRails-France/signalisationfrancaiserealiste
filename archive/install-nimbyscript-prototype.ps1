param([string]$ModsDirectory = "$env:USERPROFILE/Saved Games/Weird and Wry/NIMBY Rails/mods")
$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../mod'))
$root = [IO.Path]::GetFullPath($ModsDirectory)
$destination = Join-Path $root 'SignalisationFrancaiseRealiste'
if (-not (Test-Path -LiteralPath (Join-Path $source 'mod.txt'))) { throw 'Missing mod.txt' }
if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw 'Mods directory does not exist; specify -ModsDirectory' }
if (Test-Path -LiteralPath $destination) {
    $backup = Join-Path ([IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../build/mod-backups'))) (Get-Date -Format 'yyyyMMdd-HHmmss-fff')
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -LiteralPath $destination -Destination $backup -Recurse
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Get-ChildItem -LiteralPath $source | Copy-Item -Destination $destination -Recurse -Force
Write-Output "Installed: $destination"
Write-Output 'Load/enable the local mod in NIMBY Rails. Existing signals are not modified.'
