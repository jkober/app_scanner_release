# ==============================================================================
# uninstall_rc_extension.ps1
# Remueve las politicas de la extension RC en Chrome, Edge y Chromium
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

$browsers = @(
    @{ Name = "Google Chrome";  Path = "HKLM:\SOFTWARE\Policies\Google\Chrome" },
    @{ Name = "Microsoft Edge"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge" },
    @{ Name = "Chromium";       Path = "HKLM:\SOFTWARE\Policies\Chromium" },
    @{ Name = "Brave Browser";  Path = "HKLM:\SOFTWARE\Policies\BraveSoftware\Brave" }
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Desinstalador de Politicas Multi-Navegador                  " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

foreach ($b in $browsers) {
    $regBase = $b.Path
    $bName   = $b.Name

    if (Test-Path $regBase) {
        # 1. Remover de ExtensionSettings
        $currentJsonRaw = (Get-ItemProperty -Path $regBase -Name "ExtensionSettings" -ErrorAction SilentlyContinue).ExtensionSettings
        if ($currentJsonRaw) {
            try {
                $settingsObj = $currentJsonRaw | ConvertFrom-Json -AsHashtable
                if ($settingsObj.ContainsKey($EXT_ID)) {
                    $settingsObj.Remove($EXT_ID)
                    if ($settingsObj.Count -gt 0) {
                        $finalJson = ($settingsObj | ConvertTo-Json -Compress -Depth 10)
                        Set-ItemProperty -Path $regBase -Name "ExtensionSettings" -Value $finalJson -Type String
                    } else {
                        Remove-ItemProperty -Path $regBase -Name "ExtensionSettings" -ErrorAction SilentlyContinue
                    }
                }
            } catch {
                Remove-ItemProperty -Path $regBase -Name "ExtensionSettings" -ErrorAction SilentlyContinue
            }
        }

        # 2. Remover ExtensionInstallSources y ExtensionInstallAllowlist
        $sourcesPath = Join-Path $regBase "ExtensionInstallSources"
        if (Test-Path $sourcesPath) { Remove-Item $sourcesPath -Recurse -Force -ErrorAction SilentlyContinue }

        $allowPath = Join-Path $regBase "ExtensionInstallAllowlist"
        if (Test-Path $allowPath) { Remove-Item $allowPath -Recurse -Force -ErrorAction SilentlyContinue }

        # 3. Remover token si existiera
        Remove-ItemProperty -Path $regBase -Name "CloudManagementEnrollmentToken" -ErrorAction SilentlyContinue

        Write-Host "[+] Politicas removidas para: $bName" -ForegroundColor Green
    }
}

Write-Host "`n[OK] Politicas de la extension desinstaladas exitosamente." -ForegroundColor Green
Write-Host "Para completar: Cierre y vuelva a abrir sus navegadores." -ForegroundColor Yellow
Write-Host "Presione Enter para salir..." -ForegroundColor Gray
try { Read-Host } catch {}
