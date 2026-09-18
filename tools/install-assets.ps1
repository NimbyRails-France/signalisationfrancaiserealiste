param([string]$ModsDirectory = "$env:USERPROFILE/Saved Games/Weird and Wry/NIMBY Rails/mods")
$ErrorActionPreference = 'Stop'
$project = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$destination = Join-Path ([IO.Path]::GetFullPath($ModsDirectory)) 'SignalisationFrancaiseRealiste'
if (-not (Test-Path -LiteralPath $ModsDirectory -PathType Container)) { throw 'Mods directory missing' }
$manifest = Join-Path $destination 'mod.txt'
if (Test-Path -LiteralPath $manifest) {
    $backup = Join-Path $project ('build/mod-backups/' + (Get-Date -Format 'yyyyMMdd-HHmmss-fff'))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    Copy-Item -LiteralPath $manifest -Destination $backup
}
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $project 'imgs') -Destination $destination -Recurse -Force
Copy-Item -LiteralPath (Join-Path $project 'assets/mod.txt') -Destination $manifest -Force
Write-Output "C++ test assets installed: $destination"
