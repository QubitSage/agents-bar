param([ValidateSet('Install','Rollback','Verify','Uninstall')][string]$Mode='Install',[string]$PackageRoot=$PSScriptRoot,[string]$InstallRoot=(Join-Path $env:LOCALAPPDATA 'Programs\Agents Bar'),[switch]$NoShortcut)
$ErrorActionPreference='Stop'
function File-Hash([string]$Path) {
 $stream=[IO.File]::OpenRead($Path);$sha=[Security.Cryptography.SHA256]::Create()
 try {return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant()} finally {$stream.Dispose();$sha.Dispose()}
}
$script:verifiedPaths=@{}
function Assert-NoLinks([string]$Path) {
 $current=[IO.Path]::GetFullPath($Path)
 while ($current) {
  if($script:verifiedPaths.ContainsKey($current)){break}
  $item=Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
  if($item){
   if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw 'Linked installation paths are not supported.'}
   $script:verifiedPaths[$current]=$true
  }
  $parent=[IO.Path]::GetDirectoryName($current);if($parent -eq $current){break};$current=$parent
 }
}
function Resolve-Child([string]$Root,[string]$Relative) {
 if ($Relative.Contains('\') -or [IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.?([\\/]|$)|:|[<>"|?*]' -or $Relative -match '[ .]($|[\\/])') {throw 'Unsafe package path.'}
 $base=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\';$path=[IO.Path]::GetFullPath((Join-Path $Root $Relative))
 if (-not $path.StartsWith($base,[StringComparison]::OrdinalIgnoreCase)) {throw 'Package path escapes destination.'}
 Assert-NoLinks $path;return $path
}
function Read-VerifiedPackage([string]$Root,[bool]$Strict=$true) {
 $script:verifiedPaths=@{} # Reset for each complete integrity pass.
 Assert-NoLinks $Root
 $manifest=Get-Content -LiteralPath (Resolve-Child $Root 'manifest.json') -Raw | ConvertFrom-Json
 if ($manifest.version -notmatch '^\d+\.\d+\.\d+$' -or -not $manifest.files -or $manifest.files.Count -gt 10000) {throw 'Invalid release manifest.'}
 $seen=@{}
 foreach ($entry in $manifest.files) {
  $relative=[string]$entry.path
  if ($seen.ContainsKey($relative) -or $relative -eq 'manifest.json' -or $entry.sha256 -notmatch '^[a-f0-9]{64}$') {throw 'Invalid or duplicate manifest entry.'}
  $seen[$relative]=$true;$file=Resolve-Child $Root $relative
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {throw ('Missing package file: '+$relative)}
  if ((Get-Item -LiteralPath $file).Length -ne $entry.bytes -or (File-Hash $file) -ne $entry.sha256) {throw ('Damaged package file: '+$relative)}
 }
 foreach ($required in @('start.ps1','Iniciar Agents Bar.cmd','install.ps1','installed-launcher.ps1','game/project.godot','tools/python/python.exe','tools/godot/Godot_v4.7.2-stable_win64.exe')) {
  if (-not $seen.ContainsKey($required)) {throw ('Incomplete release: '+$required)}
 }
 if ($Strict) {
  $prefix=[IO.Path]::GetFullPath($Root).TrimEnd('\')+'\'
  foreach ($file in Get-ChildItem -LiteralPath $Root -Recurse -File -Force) {
   Assert-NoLinks $file.FullName;$relative=$file.FullName.Substring($prefix.Length).Replace('\','/')
   if ($relative -ne 'manifest.json' -and -not $seen.ContainsKey($relative)) {throw ('Unexpected package file: '+$relative)}
  }
 }
 return $manifest
}
$PackageRoot=[IO.Path]::GetFullPath($PackageRoot);$InstallRoot=[IO.Path]::GetFullPath($InstallRoot).TrimEnd('\')
if ($InstallRoot -eq [IO.Path]::GetPathRoot($InstallRoot).TrimEnd('\')) {throw 'Choose a dedicated installation folder.'}
Assert-NoLinks $InstallRoot
if ($Mode -eq 'Verify') {$verified=Read-VerifiedPackage $PackageRoot;Write-Output ('Verified '+$verified.version+' / '+$verified.files.Count+' files');return}
$mutex=[Threading.Mutex]::new($false,('Local\AgentsBar-'+[Environment]::UserName));$owns=$false
try {
 try {$owns=$mutex.WaitOne(0)} catch [Threading.AbandonedMutexException] {$owns=$true}
 if (-not $owns) {throw 'Close Agents Bar before installing or changing versions.'}
 $pointer=Resolve-Child $InstallRoot 'current.json';$old=$null
 if (Test-Path -LiteralPath $pointer) {$old=Get-Content -LiteralPath $pointer -Raw | ConvertFrom-Json}
 if ($Mode -eq 'Uninstall') {
  if (-not $old -or $old.current -notmatch '^\d+\.\d+\.\d+$') {throw 'No managed installation found.'}
  $versions=Resolve-Child $InstallRoot 'versions';$packages=@()
  foreach ($folder in Get-ChildItem -LiteralPath $versions -Directory) {
   if ($folder.Name -notmatch '^\d+\.\d+\.\d+$') {continue}
   $verified=Read-VerifiedPackage $folder.FullName $false
   $packages+=@{root=$folder.FullName;manifest=$verified}
  }
  # Verify every package before removing any owned file. Personal data is outside versions.
  foreach ($package in $packages) {
   foreach ($entry in $package.manifest.files) {Remove-Item -LiteralPath (Resolve-Child $package.root $entry.path)}
   Remove-Item -LiteralPath (Resolve-Child $package.root 'manifest.json')
   $folders=@(Get-ChildItem -LiteralPath $package.root -Directory -Recurse | Sort-Object {$_.FullName.Length} -Descending)
   foreach ($folder in $folders) {
    $safe=Resolve-Child $InstallRoot ($folder.FullName.Substring($InstallRoot.Length+1).Replace('\','/'))
    if (-not (Get-ChildItem -LiteralPath $safe -Force | Select-Object -First 1)) {Remove-Item -LiteralPath $safe}
   }
   if (-not (Get-ChildItem -LiteralPath $package.root -Force | Select-Object -First 1)) {Remove-Item -LiteralPath $package.root}
  }
  if (-not $NoShortcut) {
   $shortcutPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Agents Bar.lnk'
   if (Test-Path -LiteralPath $shortcutPath) {
    $link=(New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
    if ($link.TargetPath -eq (Join-Path $InstallRoot 'Agents Bar.cmd')) {Remove-Item -LiteralPath $shortcutPath}
   }
  }
  foreach ($name in @('Agents Bar.ps1','Agents Bar.cmd','current.json','current.json.bak')) {
   $file=Resolve-Child $InstallRoot $name;if (Test-Path -LiteralPath $file) {Remove-Item -LiteralPath $file}
  }
  Write-Output 'Program removed. Saves, tracking data and any unrecognized files were preserved.';return
 }
 if ($Mode -eq 'Rollback') {
  if (-not $old -or $old.previous -notmatch '^\d+\.\d+\.\d+$') {throw 'No previous installed version.'}
  $version=$old.previous;$destination=Resolve-Child $InstallRoot ('versions/'+$version);$null=Read-VerifiedPackage $destination $false
 } else {
  $manifest=Read-VerifiedPackage $PackageRoot;$version=$manifest.version;$destination=Resolve-Child $InstallRoot ('versions/'+$version)
  if (Test-Path -LiteralPath $destination) {
   $null=Read-VerifiedPackage $destination $false
   if ((File-Hash (Join-Path $destination 'manifest.json')) -ne (File-Hash (Join-Path $PackageRoot 'manifest.json'))) {throw 'This version already exists with different content.'}
  } else {
   $staging=Resolve-Child $InstallRoot ('staging/'+[guid]::NewGuid().ToString());New-Item -ItemType Directory -Path $staging -Force | Out-Null
   foreach ($entry in $manifest.files) {
    $target=Resolve-Child $staging $entry.path;New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath (Resolve-Child $PackageRoot $entry.path) -Destination $target
   }
   Copy-Item -LiteralPath (Join-Path $PackageRoot 'manifest.json') -Destination (Join-Path $staging 'manifest.json')
   $null=Read-VerifiedPackage $staging;New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
   # Absolute source and destination have both been resolved inside InstallRoot.
   Move-Item -LiteralPath $staging -Destination $destination
  }
 }
 New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
 Copy-Item -LiteralPath (Join-Path $destination 'installed-launcher.ps1') -Destination (Resolve-Child $InstallRoot 'Agents Bar.ps1') -Force
 '@echo off'+"`r`npowershell.exe -NoProfile -ExecutionPolicy Bypass -File `"%~dp0Agents Bar.ps1`"`r`n" | Set-Content -LiteralPath (Join-Path $InstallRoot 'Agents Bar.cmd') -Encoding ASCII
 $previous=if ($old -and $old.current -ne $version) {$old.current} elseif ($old) {$old.previous} else {$null}
 @{current=$version;previous=$previous} | ConvertTo-Json | Set-Content -LiteralPath ($pointer+'.tmp') -Encoding UTF8
 if (Test-Path -LiteralPath $pointer) {[IO.File]::Replace($pointer+'.tmp',$pointer,$pointer+'.bak')} else {[IO.File]::Move($pointer+'.tmp',$pointer)}
 if (-not $NoShortcut) {
  $shortcut=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Agents Bar.lnk'))
  $shortcut.TargetPath=Join-Path $InstallRoot 'Agents Bar.cmd';$shortcut.WorkingDirectory=$InstallRoot;$shortcut.Description='Agents Bar';$shortcut.Save()
 }
 Write-Output ('Agents Bar '+$version+' ready. Installation: '+$InstallRoot)
} finally {if ($owns) {$mutex.ReleaseMutex()};$mutex.Dispose()}
