# ==============================================================================
# install_rc_extension.ps1
# Habilita la instalacion en 1 clic de la extension RCivil Scanner desde GitHub Pages
# Compatible con cualquier PC (en Dominio o en Grupo de Trabajo / WORKGROUP)
# Sin restricciones ni necesidad de registrarse en Google
# ==============================================================================

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

# 1. Asegurar privilegios de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Este script requiere ejecutarse como Administrador."
    Write-Host "Intentando solicitar elevacion UAC..." -ForegroundColor Yellow
    try {
        Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
        exit 0
    } catch {
        Write-Error "No se pudo elevar automaticamente. Por favor abra PowerShell como Administrador y ejecute el script."
        exit 1
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Configurador de Politicas de Chrome - Instalacion en 1 Clic " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$EXT_ID = "mndncghnabjmepgdapcijjohdjonkkle"
$UPDATE_URL = "https://jkober.github.io/app_scanner_release/updates.xml"
$SOURCE_PATTERN = "https://jkober.github.io/*"
$REG_BASE = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# 2. Asegurar que existe la clave base en el Registro
if (-not (Test-Path $REG_BASE)) {
    Write-Host "[*] Creando clave de directivas de Chrome en Registro..." -ForegroundColor Gray
    New-Item -Path $REG_BASE -Force | Out-Null
}

# 3. Configurar ExtensionSettings con installation_mode = allowed (Sin advertencia [BLOCKED])
$currentJsonRaw = (Get-ItemProperty -Path $REG_BASE -Name "ExtensionSettings" -ErrorAction SilentlyContinue).ExtensionSettings
$settingsObj = @{}

if ($currentJsonRaw) {
    try {
        $parsed = $currentJsonRaw | ConvertFrom-Json -AsHashtable
        if ($parsed) { $settingsObj = $parsed }
    } catch {}
}

$settingsObj[$EXT_ID] = @{
    "installation_mode" = "allowed"
    "update_url"        = $UPDATE_URL
}

$finalJson = ($settingsObj | ConvertTo-Json -Compress -Depth 10)
Set-ItemProperty -Path $REG_BASE -Name "ExtensionSettings" -Value $finalJson -Type String
Write-Host "[+] ExtensionSettings configurado con modo 'allowed' y URL de actualizacion." -ForegroundColor Green

# 4. Configurar ExtensionInstallSources para autorizar la descarga directa desde GitHub Pages
$sourcesPath = Join-Path $REG_BASE "ExtensionInstallSources"
if (-not (Test-Path $sourcesPath)) { New-Item -Path $sourcesPath -Force | Out-Null }
Set-ItemProperty -Path $sourcesPath -Name "1" -Value $SOURCE_PATTERN -Type String
Write-Host "[+] ExtensionInstallSources autorizo: $SOURCE_PATTERN" -ForegroundColor Green

# 5. Configurar ExtensionInstallAllowlist para habilitar la extension
$allowPath = Join-Path $REG_BASE "ExtensionInstallAllowlist"
if (-not (Test-Path $allowPath)) { New-Item -Path $allowPath -Force | Out-Null }
Set-ItemProperty -Path $allowPath -Name "1" -Value $EXT_ID -Type String
Write-Host "[+] ExtensionInstallAllowlist autorizo el ID: $EXT_ID" -ForegroundColor Green

# 6. Limpiar token vacio si existiera
Remove-ItemProperty -Path $REG_BASE -Name "CloudManagementEnrollmentToken" -ErrorAction SilentlyContinue

Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "[OK] POLITICAS APLICADAS CON EXITO" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PASOS PARA INSTALAR LA EXTENSION:" -ForegroundColor Yellow
Write-Host " 1. Si Chrome esta abierto, cierrelo y vuelva a abrirlo."
Write-Host " 2. Ingrese a su pagina de descargas:"
Write-Host "    https://jkober.github.io/app_scanner_release/" -ForegroundColor White
Write-Host " 3. Haga clic en el enlace para descargar 'chrome.crx'."
Write-Host "    Chrome abrira directamente la ventana de instalacion:"
Write-Host "    'Quieres agregar RCivil Scanner Bridge?'" -ForegroundColor White
Write-Host " 4. Pulse 'Agregar extension' y quedara instalada."
Write-Host "    Las actualizaciones futuras se descargaran solas desde updates.xml."
Write-Host "------------------------------------------------------------`n" -ForegroundColor Cyan

Write-Host "Presione Enter para finalizar..." -ForegroundColor Gray
try { Read-Host } catch {}
