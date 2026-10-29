@echo off
if exist "%~dp0manifest.json" (
 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
) else (
 powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -PackageRoot "%~dp0release\AgentsBar-0.9.9-win64"
)
if errorlevel 1 pause
