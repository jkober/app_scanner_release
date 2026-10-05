#!/bin/bash
# ==============================================================================
# install_rc_extension.sh
#
# Instalador Multi-Navegador de la extension RC en Linux:
#   - Google Chrome (DEB / RPM / Portable)
#   - Microsoft Edge (DEB / RPM)
#   - Chromium (DEB y SNAP de Ubuntu)
#   - Brave Browser
#
# Compatible con:
#   - Versiones modernas y antiguas de Ubuntu (16.04, 18.04, 20.04, 22.04, 24.04+)
#   - Debian, Linux Mint, Fedora, CentOS, RHEL
#
# Soluciones de compatibilidad para versiones antiguas y Snap de Ubuntu:
#   1. ExtensionInstallForcelist: Politica clasica/universal requerida por versiones
#      antiguas de Chrome/Chromium donde ExtensionSettings no existe o no se procesa.
#   2. ExtensionSettings (force_installed): Politica moderna recomendada por Google.
#   3. Rutas heredadas: Instala tanto en /etc/opt/chrome como en /etc/chrome y
#      /etc/chromium-browser para compatibilidad con distribuciones antiguas.
#   4. Soporte nativo para Chromium SNAP: Configura /var/snap/chromium/current/policies/managed/
#      para superar el aislamiento del sandbox de AppArmor de Ubuntu.
#   5. Registro externo nativo Linux: Registra <id>.json en /usr/share/.../extensions/
#      como mecanismo de respaldo clasico de Linux.
#   6. Permisos explicitos: Aplica chmod 755 a directorios y 644 a archivos para
#      asegurar lectura por parte del usuario sin privilegios que corre el navegador.
#   7. Auto-elevacion con sudo: Si se ejecuta sin privilegios, solicita sudo automaticamente.
# ==============================================================================

set -u

# ------------------------------------------------------------------------------
# 1. AUTO-ELEVACIÓN CON SUDO
# ------------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo ""
    echo "============================================================"
    echo " Se requieren permisos de administrador"
    echo "============================================================"
    echo ""
    echo "[*] Solicitando permisos mediante sudo..."
    echo ""

    if ! command -v sudo >/dev/null 2>&1; then
        echo "[ERROR] sudo no esta disponible en este sistema."
        echo "Por favor ejecute como root:"
        echo "  su -"
        echo "  bash $0"
        exit 1
    fi

    exec sudo -E bash "$0" "$@"
fi

# ------------------------------------------------------------------------------
# 2. CONFIGURACIÓN Y CONSTANTES
# ------------------------------------------------------------------------------
EXT_ID="mndncghnabjmepgdapcijjohdjonkkle"
UPDATE_URL="https://jkober.github.io/app_scanner_release/updates.xml"
POLICY_FILENAME="rc_extension.json"

# Colores para salida en terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "============================================================"
echo " Instalador Multi-Navegador de Extension RC (Linux / Ubuntu)"
echo "============================================================"
echo ""

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "Sistema : ${PRETTY_NAME:-Linux}"
fi
echo "Kernel  : $(uname -r)"
echo "Usuario : ${SUDO_USER:-$(id -un)}"
echo ""
echo "Extension ID : $EXT_ID"
echo "Update URL   : $UPDATE_URL"
echo ""

# ------------------------------------------------------------------------------
# 3. CONTENIDO DE LAS POLÍTICAS
# ------------------------------------------------------------------------------
# Incluye ExtensionInstallForcelist (para Chrome/Chromium antiguo)
# y ExtensionSettings (para Chrome/Chromium moderno).
POLICY_JSON=$(cat <<EOF
{
  "ExtensionInstallForcelist": [
    "$EXT_ID;$UPDATE_URL"
  ],
  "ExtensionSettings": {
    "$EXT_ID": {
      "installation_mode": "force_installed",
      "update_url": "$UPDATE_URL"
    }
  }
}
EOF
)

# JSON para el registro externo tradicional de Linux (/usr/share/.../extensions/<id>.json)
EXTERNAL_JSON=$(cat <<EOF
{
  "external_update_url": "$UPDATE_URL"
}
EOF
)

# ------------------------------------------------------------------------------
# 4. FUNCIONES AUXILIARES
# ------------------------------------------------------------------------------
validate_json() {
    local file="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -m json.tool "$file" >/dev/null 2>&1
        return $?
    elif command -v python >/dev/null 2>&1; then
        python -m json.tool "$file" >/dev/null 2>&1
        return $?
    fi
    return 0
}

install_policy_file() {
    local target_dir="$1"
    local target_file="$target_dir/$POLICY_FILENAME"

    mkdir -p "$target_dir"
    chmod 755 "$target_dir"

    # Backup si ya existia un archivo diferente
    if [ -f "$target_file" ]; then
        local backup="${target_file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$target_file" "$backup" 2>/dev/null || true
    fi

    echo "$POLICY_JSON" > "$target_file"
    chmod 644 "$target_file"
    chown root:root "$target_file"

    if validate_json "$target_file"; then
        echo -e "  ${GREEN}[OK]${NC} Politica instalada en: $target_file"
        return 0
    else
        echo -e "  ${RED}[ERROR]${NC} Error al validar JSON en: $target_file"
        return 1
    fi
}

install_external_extension() {
    local target_dir="$1"
    local target_file="$target_dir/$EXT_ID.json"

    mkdir -p "$target_dir"
    chmod 755 "$target_dir"

    echo "$EXTERNAL_JSON" > "$target_file"
    chmod 644 "$target_file"
    chown root:root "$target_file"

    echo -e "  ${GREEN}[OK]${NC} Registro externo instalado en: $target_file"
}

# ------------------------------------------------------------------------------
# 5. INSTALACIÓN EN DIRECTORIOS DE POLÍTICAS GESTIONADAS
# ------------------------------------------------------------------------------
echo "------------------------------------------------------------"
echo " Instalando politicas gestionadas..."
echo "------------------------------------------------------------"

POLICY_DIRS=(
    # Google Chrome (rutas modernas y de versiones anteriores)
    "/etc/opt/chrome/policies/managed"
    "/etc/chrome/policies/managed"

    # Chromium (rutas estandar y legacy de Ubuntu/Debian)
    "/etc/chromium/policies/managed"
    "/etc/chromium-browser/policies/managed"

    # Microsoft Edge
    "/etc/opt/edge/policies/managed"

    # Brave Browser
    "/etc/brave/policies/managed"
)

# Soporte para Chromium SNAP en Ubuntu (19.10, 20.04, 22.04, 24.04+)
# Chromium en Snap está confinado y no lee /etc/chromium, pero sí lee /var/snap/chromium/...
if [ -d "/var/snap/chromium" ] || command -v snap >/dev/null 2>&1; then
    POLICY_DIRS+=(
        "/var/snap/chromium/current/policies/managed"
        "/var/snap/chromium/common/policies/managed"
    )
fi

INSTALLED_COUNT=0
for DIR in "${POLICY_DIRS[@]}"; do
    if install_policy_file "$DIR"; then
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi
done

# ------------------------------------------------------------------------------
# 6. INSTALACIÓN DE REGISTRO EXTERNO DE EXTENSIONES (FALLBACK CLÁSICO)
# ------------------------------------------------------------------------------
echo ""
echo "------------------------------------------------------------"
echo " Instalando registro externo tradicional Linux..."
echo "------------------------------------------------------------"

EXTERNAL_DIRS=(
    "/opt/google/chrome/extensions"
    "/usr/share/google-chrome/extensions"
    "/usr/share/chromium-browser/extensions"
    "/usr/share/chromium/extensions"
)

for E_DIR in "${EXTERNAL_DIRS[@]}"; do
    install_external_extension "$E_DIR"
done

# ------------------------------------------------------------------------------
# 7. RESUMEN Y VERIFICACIÓN
# ------------------------------------------------------------------------------
echo ""
echo "============================================================"
echo -e " ${GREEN}[OK] Instalacion completada exitosamente.${NC}"
echo "============================================================"
echo ""
echo "Instrucciones de verificacion:"
echo "  1. Cierre completamente cualquier navegador abierto (Chrome, Chromium, Edge, Brave)."
echo "  2. Vuelva a abrir el navegador."
echo "  3. Visite la pagina:"
echo "       chrome://policy  (o edge://policy / brave://policy)"
echo "     y presione el boton 'Recargar politicas' ('Reload policies')."
echo ""
echo "     Debera observar:"
echo "       - ExtensionSettings (modo: force_installed)"
echo "       - ExtensionInstallForcelist: $EXT_ID"
echo ""
echo "  4. Verifique la extension instalada en: chrome://extensions"
echo "============================================================"
echo ""
