@echo off
setlocal
cd /d "%~dp0"
echo Solicitando permisos de administrador y ejecutando instalador...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_rc_extension.ps1"
pause
