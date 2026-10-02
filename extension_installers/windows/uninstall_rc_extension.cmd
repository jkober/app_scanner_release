@echo off
@chcp 65001 >nul
setlocal EnableDelayedExpansion

:: 1. Comprobar si ya se ejecuta como Administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    goto :run_script
)

:: 2. Si no es Administrador, solicitar elevacion mediante UAC
echo Solicitando permisos de Administrador...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
exit /b

:run_script
cd /d "%~dp0"
echo ============================================================
echo  Desinstalador de Politicas de Google Chrome - Extension RC
echo ============================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall_rc_extension.ps1"
echo.
pause
