@echo off
set "PLATFORM_ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PLATFORM_ROOT%scripts\stop_all.ps1"
pause
