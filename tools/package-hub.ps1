param([ValidateSet('Debug','Release')][string]$Configuration='Release')
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$cmake=Join-Path $env:LOCALAPPDATA 'Programs/CLion/bin/cmake/win/x64/bin/cmake.exe'
$version='0.1.0'
$folder="SignalisationFrancaiseRealiste-$version"
$stage=Join-Path $root ('build/package-'+[guid]::NewGuid().ToString('N'))
& $cmake --install "$root/build/$Configuration" --prefix "$stage/$folder"
if($LASTEXITCODE){throw 'Mod staging failed; build the project first'}
$dist=Join-Path $root 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$zip=Join-Path $dist "$folder-windows-x64.zip"
Compress-Archive -LiteralPath "$stage/$folder" -DestinationPath $zip -Force
$project=[ordered]@{
 id='signalisationfrancaiserealiste';name='Signalisation francaise realiste';kind='native-mod';version=$version
 modId='SignalisationFrancaiseRealiste';loaderApi=1;sdkMin='0.7.1';sdkMaxExclusive='0.8.0'
 module='SignalisationFrancaiseRealisteMod.dll'
 rootFolder=$folder;size=(Get-Item -LiteralPath $zip).Length
 sha256=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
 url="https://github.com/NimbyRails-France/signalisationfrancaiserealiste/releases/download/v$version/$([IO.Path]::GetFileName($zip))"
 gameSha256=@('fff49ac21720abfc824c2b4f68b862727630eb0db71cfe1f9ea8f685d0db10ae')
}
$project | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$dist/project.json" -Encoding UTF8
Write-Output "Local package prepared (not published): $zip"
