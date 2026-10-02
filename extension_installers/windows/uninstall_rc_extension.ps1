# ==============================================================================
# uninstall_rc_extension.ps1
# Remueve las politicas de la extension RC en Google Chrome
# ==============================================================================

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Este script requiere ejecutarse como Administrador."
    try {
        Start-Process powershell.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
        exit 0
    } catch {
        Write-Error "Por favor ejecute PowerShell como Administrador."
        exit 1
    }
}

$EXT_ID = "mndncghnabjmepgdapcijjohdjonkkle"
$REG_PATH = "HKLM:\SOFTWARE\Policies\Google\Chrome"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Desinstalador de Politicas de Chrome - Extension RC        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Remover de ExtensionSettings
if (Test-Path $REG_PATH) {
    $currentJsonRaw = (Get-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -ErrorAction SilentlyContinue).ExtensionSettings
    if ($currentJsonRaw) {
        try {
            $settingsObj = $currentJsonRaw | ConvertFrom-Json -AsHashtable
            if ($settingsObj.ContainsKey($EXT_ID)) {
                $settingsObj.Remove($EXT_ID)
                if ($settingsObj.Count -gt 0) {
                    $finalJson = ($settingsObj | ConvertTo-Json -Compress -Depth 10)
                    Set-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -Value $finalJson -Type String
                    Write-Host "[+] Extension $EXT_ID removida de ExtensionSettings." -ForegroundColor Green
                } else {
                    Remove-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -ErrorAction SilentlyContinue
                    Write-Host "[+] ExtensionSettings eliminada del Registro." -ForegroundColor Green
                }
            }
        } catch {
            Remove-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -ErrorAction SilentlyContinue
        }
    }
}

# 2. Remover ExtensionInstallSources y ExtensionInstallAllowlist
$sourcesPath = Join-Path $REG_PATH "ExtensionInstallSources"
if (Test-Path $sourcesPath) {
    Remove-Item $sourcesPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Clave ExtensionInstallSources eliminada." -ForegroundColor Green
}

$allowPath = Join-Path $REG_PATH "ExtensionInstallAllowlist"
if (Test-Path $allowPath) {
    Remove-Item $allowPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[+] Clave ExtensionInstallAllowlist eliminada." -ForegroundColor Green
}

# 3. Remover token de prueba si existiera
Remove-ItemProperty -Path $REG_PATH -Name "CloudManagementEnrollmentToken" -ErrorAction SilentlyContinue

Write-Host "`n[OK] Politicas de la extension desinstaladas exitosamente." -ForegroundColor Green
Write-Host "Para completar: Cierre y vuelva a abrir Google Chrome." -ForegroundColor Yellow
Write-Host "Presione Enter para salir..." -ForegroundColor Gray
try { Read-Host } catch {}
