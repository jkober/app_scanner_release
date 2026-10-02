# ==============================================================================
# uninstall_rc_extension.ps1
# Remueve la politica de la extension RC en Google Chrome
# ==============================================================================

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
                    Write-Host "[OK] Extension $EXT_ID removida de ExtensionSettings. Otras extensiones se conservaron." -ForegroundColor Green
                } else {
                    Remove-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -ErrorAction SilentlyContinue
                    Write-Host "[OK] Clave ExtensionSettings eliminada del Registro." -ForegroundColor Green
                }
            } else {
                Write-Host "[*] La extension no estaba configurada en ExtensionSettings." -ForegroundColor Yellow
            }
        } catch {
            Remove-ItemProperty -Path $REG_PATH -Name "ExtensionSettings" -ErrorAction SilentlyContinue
            Write-Host "[OK] Clave ExtensionSettings reiniciada." -ForegroundColor Green
        }
    }
}

Write-Host "Reinicio de Chrome necesario para completar la desinstalacion." -ForegroundColor Cyan
Write-Host "Presione Enter para salir..."
try { Read-Host } catch {}
