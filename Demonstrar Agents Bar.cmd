@echo off
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0start.ps1" -Demo
if errorlevel 1 (
  echo Nao foi possivel abrir Agents Bar. Consulte a mensagem acima e runtime\game.log.
  pause
)
