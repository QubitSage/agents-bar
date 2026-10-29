param([ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version='0.9.12')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$archive=Join-Path $root ('release\AgentsBar-'+$Version+'-win64.zip')
$destination=Join-Path $root ('release\AgentsBar-Setup-'+$Version+'.exe')
if(Test-Path -LiteralPath $destination){throw 'Existing installers are immutable; choose another release.'}
$compiler='C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$framework=Split-Path -Parent $compiler
if(-not (Test-Path -LiteralPath $compiler)){throw 'The Windows .NET Framework compiler is required to build this installer.'}
$hash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$source=[IO.File]::ReadAllText((Join-Path $root 'installer\Setup.cs')).Replace('PAYLOAD_SHA256',$hash).Replace('0.9.9',$Version)
$generated=Join-Path $root 'runtime\Setup.Generated.cs'
[IO.File]::WriteAllText($generated,$source,[Text.UTF8Encoding]::new($true))
& $compiler /nologo /target:winexe /platform:anycpu /optimize+ (('/out:')+$destination) ('/resource:'+$archive+',AgentsBar.Payload.zip') /r:System.Windows.Forms.dll /r:System.Drawing.dll ('/r:'+(Join-Path $framework 'System.IO.Compression.dll')) ('/r:'+(Join-Path $framework 'System.IO.Compression.FileSystem.dll')) $generated
if($LASTEXITCODE -ne 0){throw 'Installer compilation failed.'}
Write-Output ('Built '+$destination)
