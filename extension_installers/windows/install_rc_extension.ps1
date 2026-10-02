# ==============================================================================
# install_rc_extension.ps1
# Habilita la instalacion en 1 clic de la extension RCivil Scanner desde GitHub Pages
# Compatible con Google Chrome, Microsoft Edge, Opera y Chromium
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
Write-Host " Configurador Multi-Navegador - Chrome, Edge, Opera         " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$EXT_ID = "mndncghnabjmepgdapcijjohdjonkkle"
$UPDATE_URL = "https://jkober.github.io/app_scanner_release/updates.xml"
$SOURCE_PATTERN = "https://jkober.github.io/*"

# Lista de navegadores Chromium en el Registro
$browsers = @(
    @{ Name = "Google Chrome";   Path = "HKLM:\SOFTWARE\Policies\Google\Chrome" },
    @{ Name = "Microsoft Edge";  Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge" },
    @{ Name = "Chromium";        Path = "HKLM:\SOFTWARE\Policies\Chromium" },
    @{ Name = "Brave Browser";   Path = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" }
)

foreach ($b in $browsers) {
    $regBase = $b.Path
    $bName   = $b.Name

    if (-not (Test-Path $regBase)) {
        New-Item -Path $regBase -Force | Out-Null
    }

    # 1. ExtensionSettings
    $currentJsonRaw = (Get-ItemProperty -Path $regBase -Name "ExtensionSettings" -ErrorAction SilentlyContinue).ExtensionSettings
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
    Set-ItemProperty -Path $regBase -Name "ExtensionSettings" -Value $finalJson -Type String

    # 2. ExtensionInstallSources
    $sourcesPath = Join-Path $regBase "ExtensionInstallSources"
    if (-not (Test-Path $sourcesPath)) { New-Item -Path $sourcesPath -Force | Out-Null }
    Set-ItemProperty -Path $sourcesPath -Name "1" -Value $SOURCE_PATTERN -Type String

    # 3. ExtensionInstallAllowlist
    $allowPath = Join-Path $regBase "ExtensionInstallAllowlist"
    if (-not (Test-Path $allowPath)) { New-Item -Path $allowPath -Force | Out-Null }
    Set-ItemProperty -Path $allowPath -Name "1" -Value $EXT_ID -Type String

    # Limpiar tokens si existieran
    Remove-ItemProperty -Path $regBase -Name "CloudManagementEnrollmentToken" -ErrorAction SilentlyContinue

    Write-Host "[+] Politicas aplicadas para: $bName" -ForegroundColor Green
}

Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "[OK] POLITICAS APLICADAS PARA CHROME, EDGE Y OPERA" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "PASOS PARA INSTALAR LA EXTENSION:" -ForegroundColor Yellow
Write-Host " 1. Si el navegador esta abierto (Chrome, Edge u Opera), cierrelo y vuelva a abrirlo."
Write-Host " 2. Ingrese a la pagina de descargas:"
Write-Host "    https://jkober.github.io/app_scanner_release/" -ForegroundColor White
Write-Host " 3. Haga clic en el boton para instalar la extension (chrome.crx)."
Write-Host " 4. Pulse 'Agregar extension' / 'Instalar' en la ventana de confirmacion."
Write-Host "------------------------------------------------------------`n" -ForegroundColor Cyan

Write-Host "Presione Enter para finalizar..." -ForegroundColor Gray
try { Read-Host } catch {}
