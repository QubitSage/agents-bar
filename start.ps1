param([switch]$Connect, [string]$SessionFile, [ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ThreadId, [string]$ConnectionsFile, [switch]$Demo, [switch]$AzhorDemo)
$ErrorActionPreference = 'Stop'
if ($AzhorDemo) { $Demo=$true }
$projectRoot = $PSScriptRoot
$runtimeRoot = Join-Path $projectRoot 'runtime'
New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
$godotExe = Join-Path $projectRoot 'tools\godot\Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godotExe)) { throw 'Godot portátil não encontrado em tools/godot.' }
if ($Connect -and -not $ConnectionsFile -and (-not $SessionFile -or -not $ThreadId)) {
    throw 'A conexão exige SessionFile e ThreadId, ou ConnectionsFile, escolhidos explicitamente.'
}
if (($SessionFile -or $ThreadId -or $ConnectionsFile) -and -not $Connect) { throw 'Use Connect explicitamente para acompanhar sessões.' }
if ($ConnectionsFile -and ($SessionFile -or $ThreadId)) { throw 'Escolha um arquivo de conexões ou uma sessão individual.' }
if ($Connect -and $Demo) { throw 'Escolha conexão real ou demonstração.' }
$connectionRoot = Join-Path $runtimeRoot ([guid]::NewGuid().ToString())
$bridgeProcess = $null
$gameProcess = $null
$instanceMutex = [System.Threading.Mutex]::new($false, ('Local\AgentsBar-' + [Environment]::UserName))
$ownsMutex = $false
try {
    try { $ownsMutex = $instanceMutex.WaitOne(0) } catch [System.Threading.AbandonedMutexException] { $ownsMutex = $true }
    if (-not $ownsMutex) { Write-Host 'Agents Bar ja esta aberto. Use a barra no canto.'; return }
    if ($Connect) {
        $pythonExe = Join-Path $projectRoot 'tools\python\python.exe'
        if (-not (Test-Path -LiteralPath $pythonExe)) { $pythonExe = (Get-Command python -ErrorAction Stop).Source }
        New-Item -ItemType Directory -Path $connectionRoot -Force | Out-Null
        if ($ConnectionsFile) {
            if (-not (Test-Path -LiteralPath $ConnectionsFile -PathType Leaf)) { throw 'Arquivo de conexões não encontrado.' }
            $bridgeArgs = @(('"' + (Join-Path $projectRoot 'bridge\multi_watch.py') + '"'), '--config', ('"' + $ConnectionsFile + '"'), '--output-dir', ('"' + $connectionRoot + '"'))
        } else {
            if (-not (Test-Path -LiteralPath $SessionFile -PathType Leaf)) { throw 'Arquivo de sessão não encontrado.' }
            $bridgeArgs = @(('"' + (Join-Path $projectRoot 'bridge\watch.py') + '"'), '--session-file', ('"' + $SessionFile + '"'), '--thread-id', $ThreadId, '--output-dir', ('"' + $connectionRoot + '"'))
        }
        $bridgeProcess = Start-Process -FilePath $pythonExe -ArgumentList $bridgeArgs -WindowStyle Hidden -PassThru -RedirectStandardError (Join-Path $runtimeRoot 'bridge.log')
    }
    # Parentheses keep each quoted path a single array item in Windows PowerShell 5.1.
    $gameArgs = @('--path', ('"' + (Join-Path $projectRoot 'game') + '"'), '--log-file', ('"' + (Join-Path $runtimeRoot 'game.log') + '"'))
    if ($Connect) { $gameArgs += @('--', ('"--state-file=' + (Join-Path $connectionRoot 'session-state.json') + '"')) }
    if ($Demo) { $gameArgs += @('--',$(if ($AzhorDemo) {'--demo-azhor'} else {'--demo'})) }
    $gameProcess = Start-Process -FilePath $godotExe -ArgumentList $gameArgs -WindowStyle Normal -PassThru
    @{ gamePid=$gameProcess.Id; bridgePid=if($bridgeProcess){$bridgeProcess.Id}else{$null}; launcherPid=$PID } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $runtimeRoot 'processes.json') -Encoding utf8
    $gameProcess.WaitForExit()
    if ($gameProcess.ExitCode -ne 0) { throw ('Agents Bar encerrou com erro ' + $gameProcess.ExitCode + '. Consulte runtime\game.log.') }
} finally {
    if ($bridgeProcess -and -not $bridgeProcess.HasExited) { $bridgeProcess.Kill() }
    if ($ownsMutex) { $instanceMutex.ReleaseMutex() }
    $instanceMutex.Dispose()
}
