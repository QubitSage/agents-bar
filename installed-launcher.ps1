param([switch]$Prepare,[switch]$Demo,[switch]$Rollback,[switch]$Uninstall)
$ErrorActionPreference='Stop'
$state=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'current.json') -Raw | ConvertFrom-Json
if ($state.current -notmatch '^\d+\.\d+\.\d+$') {throw 'Invalid installed version.'}
$root=Join-Path $PSScriptRoot ('versions\'+$state.current)
$env:AGENTS_BAR_DATA=Join-Path $PSScriptRoot 'data'
if ($Prepare) {& (Join-Path $root 'tools\python\python.exe') (Join-Path $root 'scripts\configure_tracking.py');exit $LASTEXITCODE}
if ($Uninstall) {& (Join-Path $root 'install.ps1') -Mode Uninstall -InstallRoot $PSScriptRoot;return}
if ($Rollback) {& (Join-Path $root 'install.ps1') -Mode Rollback -InstallRoot $PSScriptRoot;return}
& (Join-Path $root 'start.ps1') -Demo:$Demo
