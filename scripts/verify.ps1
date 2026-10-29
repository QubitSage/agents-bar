param([string]$PythonExecutable = '',[string]$NodeExecutable = 'node')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $PythonExecutable) { $PythonExecutable=Join-Path $projectRoot 'tools/python/python.exe' }
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'runtime/test-temp') | Out-Null
$env:TEMP=Join-Path $projectRoot 'runtime/test-temp';$env:TMP=$env:TEMP
Push-Location $projectRoot
try {
    & $PythonExecutable -m unittest discover -s tests -v
    if ($LASTEXITCODE -ne 0) { throw 'Python tests failed.' }
    $godotConsole = Join-Path $projectRoot 'tools\godot\Godot_v4.7.2-stable_win64_console.exe'
    foreach ($testName in @('test_presentation', 'test_gameplay', 'test_first_mission', 'test_hud_game', 'test_azhor', 'test_hud_layout','test_battle_view','test_equipment','test_readiness','test_soak')) {
        $logFile = Join-Path $projectRoot ('runtime\' + $testName + '.log')
        & $godotConsole --headless --path (Join-Path $projectRoot 'game') --script ('res://' + $testName + '.gd') --log-file $logFile
        if ($LASTEXITCODE -ne 0) { throw ('Godot test failed: ' + $testName) }
        if (Select-String -LiteralPath $logFile -Pattern 'SCRIPT ERROR:|ERROR:' -Quiet) { throw ('Godot reported an error: ' + $testName) }
    }
    foreach ($scriptFile in @((Join-Path $projectRoot 'start.ps1'), $PSCommandPath,(Join-Path $projectRoot 'install.ps1'),(Join-Path $projectRoot 'installed-launcher.ps1'))) {
        $parseTokens = $null
        $parseErrors = $null
        [System.Management.Automation.Language.Parser]::ParseFile($scriptFile, [ref]$parseTokens, [ref]$parseErrors) | Out-Null
        if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
    }
    & $NodeExecutable --test server/test.mjs server/recovery.test.mjs server/input.test.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Billing fixture tests failed.' }
    Write-Host 'All code-only checks passed. No application window was instantiated.'
} finally {
    Pop-Location
}
