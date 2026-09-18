param([switch]$PrepareOnly)
$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sdk=[IO.Path]::GetFullPath((Join-Path $root '../sdk'))
$hub=[IO.Path]::GetFullPath((Join-Path $root '../hub'))
$cmake=Join-Path $env:LOCALAPPDATA 'Programs/CLion/bin/cmake/win/x64/bin/cmake.exe'
$settingsPath=Join-Path $env:LOCALAPPDATA 'NimbyRailsFrance/NRFHub/settings.json'
$settings=Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
$game=[IO.Path]::GetFullPath($settings.gameDirectory)
$work=Join-Path $root ('build/local-install-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null
$sdkStage=Join-Path $work 'NimbyRailsFranceSDK-local'
& $cmake --install "$sdk/build/clion-Release" --prefix $sdkStage *> "$work/sdk-stage.log"
if($LASTEXITCODE){throw "SDK staging failed: $work/sdk-stage.log"}
New-Item -ItemType Directory -Path "$sdkStage/loader" | Out-Null
foreach($name in @('SDL3.dll','NimbyRailsFranceSDK.dll','libwinpthread-1.dll','NimbyRailsFranceTextureBridge-experimental-v3.dll')){
 Copy-Item -LiteralPath "$sdk/build/clion-Release/drop-in/$name" -Destination "$sdkStage/loader/$name"
}
Copy-Item -LiteralPath "$sdk/tools/install-proxy.ps1" -Destination "$sdkStage/loader/install-proxy.ps1"
$sdkZip=Join-Path $work 'sdk-local.zip'
Compress-Archive -LiteralPath $sdkStage -DestinationPath $sdkZip
$sdkProject=[pscustomobject]@{
 id='sdk';name='NimbyRailsFranceSDK + NRF Loader';kind='sdk';version='0.7.2';loaderApi=1
 rootFolder='NimbyRailsFranceSDK-local';size=(Get-Item -LiteralPath $sdkZip).Length
 sha256=(Get-FileHash -LiteralPath $sdkZip).Hash.ToLowerInvariant()
 gameSha256=@('fff49ac21720abfc824c2b4f68b862727630eb0db71cfe1f9ea8f685d0db10ae')
}
$modProject=Get-Content -LiteralPath "$root/dist/project.json" -Raw | ConvertFrom-Json
$modZip=Join-Path "$root/dist" ([IO.Path]::GetFileName(([uri]$modProject.url).AbsolutePath))
if((Get-FileHash -LiteralPath $modZip).Hash -ine $modProject.sha256){throw 'Mod package hash mismatch'}
if($PrepareOnly){Write-Output "Prepared SDK package: $sdkZip";exit 0}
foreach($name in @('NIMBYRails','NRFHub','NimbyTco','NimbyRailsFranceLoader')){
 if(Get-Process -Name $name -ErrorAction SilentlyContinue){throw "Close $name before local installation. For the Hub, use Quitter from its tray icon."}
}
$gameHash=(Get-FileHash -LiteralPath (Join-Path $game 'NIMBYRails.exe')).Hash.ToLowerInvariant()
if($gameHash -notin $sdkProject.gameSha256){throw 'Unsupported game binary'}
Copy-Item -LiteralPath $settingsPath -Destination "$work/settings-before.json"
function SaveSettings {
 $json=$settings | ConvertTo-Json -Depth 20
 $temporary=$settingsPath+'.local-install.tmp'
 [IO.File]::WriteAllText($temporary,$json,(New-Object Text.UTF8Encoding($false)))
 [IO.File]::Replace($temporary,$settingsPath,$null)
}
function InstallProject($project,[string]$archive,[string]$destination){
 $request=[ordered]@{action='install';project=$project;archive=$archive;destination=$destination;gameDirectory=$game;expectedGameHash=$gameHash;resultFile="$work/result.json"}
 $request | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath "$work/request.json" -Encoding UTF8
 & powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$hub/scripts/manage.ps1" -RequestFile "$work/request.json"
 if($LASTEXITCODE){throw "Installation failed for $($project.id); see $work"}
 $record=Get-Content -LiteralPath "$work/result.json" -Raw | ConvertFrom-Json
 $settings.installed | Add-Member -MemberType NoteProperty -Name $project.id -Value $record -Force
 SaveSettings
}
$sdkDestination=$settings.installed.sdk.directory
if(!$sdkDestination){$sdkDestination=Join-Path $settings.root 'sdk'}
$modDestination=$settings.installed.signalisationfrancaiserealiste.directory
if(!$modDestination){$modDestination=Join-Path $settings.root $modProject.id}
# The texture-only prototype may already exist. Preserve it before registering the Hub junction.
$nativeLink=Join-Path $env:USERPROFILE "Saved Games/Weird and Wry/NIMBY Rails/mods/$($modProject.modId)"
$existing=Get-Item -LiteralPath $nativeLink -Force -ErrorAction SilentlyContinue
$backup=$null
if($existing -and !$settings.installed.signalisationfrancaiserealiste){
 if($existing.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Existing mod junction belongs to another installation'}
 $expectedParent=[IO.Path]::GetFullPath((Join-Path $env:USERPROFILE 'Saved Games/Weird and Wry/NIMBY Rails/mods'))
 if([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($nativeLink)) -ne $expectedParent){throw 'Unexpected mod path'}
 if(!(Test-Path -LiteralPath "$nativeLink/mod.txt")){throw 'Existing mod directory is not the texture prototype'}
 $backup=Join-Path $work 'previous-texture-mod'
 if(![IO.Path]::GetFullPath($backup).StartsWith([IO.Path]::GetFullPath($work)+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Backup path outside local installation workspace'}
 Move-Item -LiteralPath $nativeLink -Destination $backup
}
try {
 InstallProject $sdkProject $sdkZip $sdkDestination
 InstallProject $modProject $modZip $modDestination
}catch{
 if($backup -and !(Get-Item -LiteralPath $nativeLink -Force -ErrorAction SilentlyContinue)){Move-Item -LiteralPath $backup -Destination $nativeLink}
 throw
}
$hubInstalled=Join-Path $env:LOCALAPPDATA 'Programs/NimbyRailsFranceHub'
if(Test-Path -LiteralPath "$hubInstalled/NRFHub.exe"){
 Copy-Item -LiteralPath "$hubInstalled/NRFHub.exe" -Destination "$work/NRFHub-before.exe"
 Copy-Item -LiteralPath "$hubInstalled/scripts/manage.ps1" -Destination "$work/manage-before.ps1"
 Copy-Item -LiteralPath "$hub/build/NRFHub.exe" -Destination "$hubInstalled/NRFHub.exe" -Force
 Copy-Item -LiteralPath "$hub/scripts/manage.ps1" -Destination "$hubInstalled/scripts/manage.ps1" -Force
}
Write-Output "Installed SFR in $modDestination. Start the game normally: NRF Loader starts the module automatically."
Write-Output "Backups: $work"
