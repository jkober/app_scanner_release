# ==============================================================================
# install_rc_extension.ps1
# Instala la extensión RCivil Scanner en Google Chrome mediante directiva de grupo (ExtensionSettings)
# Configuración: force_installed con auto-actualización desde GitHub Pages
# ==============================================================================

# 1. Asegurar privilegios de Administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Elevando permisos de Administrador..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
    exit
}

Clear-Host
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Instalador de Política de Extensión RC para Google Chrome " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$EXT_ID = "mndncghnabjmepgdapcijjohdjonkkle"
$UPDATE_URL = "https://jkober.github.io/app_scanner_release/updates.xml"
$REG_PATH = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# 2. Asegurar que existe la clave en el Registro
if (-not (Test-Path $REG_PATH)) {
    Write-Host "[*] Creando clave de directivas de Chrome en Registro..." -ForegroundColor Gray
    New-Item -Path $REG_PATH -Force | Out-Null
}

# 3. Leer configuración existente de ExtensionSettings si existe
$currentJsonRaw = (Get-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -ErrorAction SilentlyContinue).ExtensionSettings
$settingsObj = @{}

if ($currentJsonRaw) {
    try {
        $parsed = $currentJsonRaw | ConvertFrom-Json -AsHashtable
        if ($parsed) {
            $settingsObj = $parsed
            Write-Host "[*] Se preservaron directivas existentes en ExtensionSettings." -ForegroundColor Gray
        }
    } catch {
        Write-Warning "El valor existente en ExtensionSettings no era un JSON válido. Se creará uno nuevo."
    }
}

# 4. Agregar o actualizar la configuración de nuestra extensión
$settingsObj[$EXT_ID] = @{
    "installation_mode" = "force_installed"
    "update_url"        = $UPDATE_URL
}

# Convertir a JSON compacto para registro
$finalJson = ($settingsObj | ConvertTo-Json -Compress -Depth 10)

# 5. Guardar en el Registro (HKLM)
Set-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -Value $finalJson -Type String

Write-Host "`n[OK] Directiva ExtensionSettings configurada exitosamente en HKLM:" -ForegroundColor Green
Write-Host "  Ruta:       $REG_PATH" -ForegroundColor White
Write-Host "  Extension:  $EXT_ID" -ForegroundColor White
Write-Host "  Modo:       force_installed" -ForegroundColor White
Write-Host "  Update URL: $UPDATE_URL" -ForegroundColor White

# 6. Verificar conectividad a la URL de actualización
Write-Host "`n[*] Verificando conectividad con GitHub Pages..." -ForegroundColor Gray
try {
    $res = Invoke-WebRequest -Uri $UPDATE_URL -UseBasicParsing -TimeoutSec 5
    if ($res.StatusCode -eq 200) {
        Write-Host "[+] Conexión con updates.xml exitosa (HTTP 200)." -ForegroundColor Green
    } else {
        Write-Warning "El servidor respondió con código HTTP: $($res.StatusCode)"
    }
} catch {
    Write-Warning "No se pudo conectar a $UPDATE_URL (¿aún no fue desplegado el workflow en GitHub?): $($_.Exception.Message)"
}

Write-Host "`n------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "CÓMO PROBAR:" -ForegroundColor Yellow
Write-Host " 1. Si Chrome está abierto, ciérrelo y vuelva a abrirlo."
Write-Host " 2. Ingrese a: chrome://policy"
Write-Host "    - Debe ver 'ExtensionSettings' con estado 'Correcto' / 'OK'."
Write-Host " 3. Ingrese a: chrome://extensions"
Write-Host "    - Verá 'RCivil Scanner Bridge' con el icono de gestión empresarial."
Write-Host "------------------------------------------------------------`n" -ForegroundColor Cyan

Write-Host "Presione cualquier tecla para salir..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
