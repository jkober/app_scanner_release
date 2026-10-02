# ==============================================================================
# install_rc_extension.ps1
# Habilita la instalacion en 1 clic de la extension RCivil Scanner desde GitHub Pages
# Compatible con Google Chrome, Microsoft Edge, Opera, Chromium y Brave
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
        Write-Error "No se pudo elevar automaticamente. Por favor abra PowerShell o el archivo CMD como Administrador."
        exit 1
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Configurador Multi-Navegador - Chrome, Edge, Opera, Brave  " -ForegroundColor Cyan
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

    # 1. ExtensionSettings (fusion segura preservando extensiones previas como Fortinet)
    $currentJsonRaw = (Get-ItemProperty -Path $regBase -Name "ExtensionSettings" -ErrorAction SilentlyContinue).ExtensionSettings
    $settingsObj = @{}
    if ($currentJsonRaw) {
        try {
            $parsed = $currentJsonRaw | ConvertFrom-Json -AsHashtable
            if ($parsed) { $settingsObj = $parsed }
        } catch {}
    }

    # Asegurar que "*" contenga "install_sources"
    if (-not $settingsObj.ContainsKey("*")) {
        $settingsObj["*"] = @{}
    }
    $sources = @()
    if ($settingsObj["*"].ContainsKey("install_sources") -and $settingsObj["*"]["install_sources"]) {
        $sources = @($settingsObj["*"]["install_sources"])
    }
    if ($sources -notcontains $SOURCE_PATTERN) {
        $sources += $SOURCE_PATTERN
    }
    $settingsObj["*"]["install_sources"] = $sources

    # Configurar extension en modo 'allowed' con su update_url
    $settingsObj[$EXT_ID] = @{
        "installation_mode" = "allowed"
        "update_url"        = $UPDATE_URL
    }

    $finalJson = ($settingsObj | ConvertTo-Json -Compress -Depth 10)
    Set-ItemProperty -Path $regBase -Name "ExtensionSettings" -Value $finalJson -Type String

    # 2. ExtensionInstallSources (compatibilidad adicional)
    $sourcesPath = Join-Path $regBase "ExtensionInstallSources"
    if (-not (Test-Path $sourcesPath)) { New-Item -Path $sourcesPath -Force | Out-Null }
    Set-ItemProperty -Path $sourcesPath -Name "1" -Value $SOURCE_PATTERN -Type String

    # 3. ExtensionInstallAllowlist (compatibilidad adicional)
    $allowPath = Join-Path $regBase "ExtensionInstallAllowlist"
    if (-not (Test-Path $allowPath)) { New-Item -Path $allowPath -Force | Out-Null }
    Set-ItemProperty -Path $allowPath -Name "1" -Value $EXT_ID -Type String

    # Limpiar tokens si existieran
    Remove-ItemProperty -Path $regBase -Name "CloudManagementEnrollmentToken" -ErrorAction SilentlyContinue

    Write-Host "[+] Politicas aplicadas para: $bName" -ForegroundColor Green
}

# ==============================================================================
# Ajustes especificos para Microsoft Edge
# ==============================================================================
# Habilitar instalacion desde otras tiendas / origenes web
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ControlDefaultStateOfAllowExtensionFromOtherStoresSettingEnabled" -Value 1 -Type DWord
$edgeRec = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\Recommended"
if (-not (Test-Path $edgeRec)) { New-Item -Path $edgeRec -Force | Out-Null }
Set-ItemProperty -Path $edgeRec -Name "ControlDefaultStateOfAllowExtensionFromOtherStoresSettingEnabled" -Value 1 -Type DWord
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ExtensionDeveloperModeSettings" -Value 0 -Type DWord

# Registro Externo de Extension en Edge (64-bit y WOW6432)
$edgeExtKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Edge\Extensions\$EXT_ID",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Edge\Extensions\$EXT_ID"
)
foreach ($ek in $edgeExtKeys) {
    if (-not (Test-Path $ek)) { New-Item -Path $ek -Force | Out-Null }
    Set-ItemProperty -Path $ek -Name "update_url" -Value $UPDATE_URL -Type String
}
Write-Host "[+] Registros externos nativos configurados para Microsoft Edge" -ForegroundColor Green

# Registro Externo de Extension en Chrome (64-bit y WOW6432)
$chromeExtKeys = @(
    "HKLM:\SOFTWARE\Google\Chrome\Extensions\$EXT_ID",
    "HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\Extensions\$EXT_ID"
)
foreach ($ck in $chromeExtKeys) {
    if (-not (Test-Path $ck)) { New-Item -Path $ck -Force | Out-Null }
    Set-ItemProperty -Path $ck -Name "update_url" -Value $UPDATE_URL -Type String
}
Write-Host "[+] Registros externos nativos configurados para Google Chrome" -ForegroundColor Green

Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "[OK] CONFIGURACION EXITOSA PARA EDGE, CHROME, OPERA Y BRAVE" -ForegroundColor Green
Write-Host "------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "INSTRUCCIONES DE USO:" -ForegroundColor Yellow
Write-Host " 1. Cierre por completo Edge, Chrome u Opera y vuelva a abrirlo."
Write-Host " 2. Ingrese a la web de descargas:"
Write-Host "    https://jkober.github.io/app_scanner_release/" -ForegroundColor White
Write-Host " 3. Haga clic en el boton '+ Instalar Extension'."
Write-Host " 4. En el navegador aparecera el mensaje para 'Agregar extension'."
Write-Host "    (En Edge u Opera: si el archivo .crx se descarga, haga clic en el archivo"
Write-Host "     o arrastrelo a edge://extensions u opera://extensions)."
Write-Host "------------------------------------------------------------`n" -ForegroundColor Cyan

Write-Host "Presione Enter para finalizar..." -ForegroundColor Gray
try { Read-Host } catch {}
