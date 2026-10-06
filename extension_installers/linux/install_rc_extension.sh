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
#   - Ubuntu 16.04, 18.04, 20.04, 22.04, 24.04+ (GNOME, MATE/Caja, XFCE, etc.)
#   - Debian, Linux Mint, Fedora, CentOS, RHEL
#
# Comportamiento al ejecutar desde Caja / Nautilus / Gestores de archivos:
#   - Si se selecciona "Ejecutar en un terminal": Corre normalmente y solicita sudo.
#   - Si se selecciona "Ejecutar" (sin terminal): Abre automaticamente la terminal
#     del entorno de escritorio (mate-terminal, x-terminal-emulator, etc.) o usa
#     el dialogo grafico de elevacion (pkexec / zenity) para solicitar credenciales.
# ==============================================================================

set -u

# ------------------------------------------------------------------------------
# 1. AUTO-LANZAR TERMINAL SI SE EJECUTA DESDE CAJA / ENTORNO GRÁFICO SIN TTY
# ------------------------------------------------------------------------------
if [ ! -t 0 ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then
    for term in x-terminal-emulator mate-terminal gnome-terminal xfce4-terminal konsole alacritty kitty xterm; do
        if command -v "$term" >/dev/null 2>&1; then
            exec "$term" -e bash -c "bash \"$0\" --pause \"\$@\"" dummy "$@"
        fi
    done
fi

# ------------------------------------------------------------------------------
# 2. AUTO-ELEVACIÓN DE PRIVILEGIOS (SUDO / PKEXEC)
# ------------------------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    if [ -t 0 ]; then
        echo ""
        echo "============================================================"
        echo " Se requieren permisos de administrador"
        echo "============================================================"
        echo ""
        echo "[*] Solicitando permisos mediante sudo..."
        echo ""

        if ! command -v sudo >/dev/null 2>&1; then
            echo "[ERROR] sudo no esta disponible en este sistema."
            echo "Por favor ejecute como root: su - && bash $0"
            exit 1
        fi

        exec sudo -E bash "$0" "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        # Sin terminal interactiva pero con interfaz grafica PolicyKit disponible
        exec pkexec bash "$0" "$@"
    elif command -v sudo >/dev/null 2>&1; then
        exec sudo -E bash "$0" "$@"
    else
        echo "[ERROR] Se requieren permisos de superusuario (root)."
        exit 1
    fi
fi

# ------------------------------------------------------------------------------
# 3. CONFIGURACIÓN Y CONSTANTES
# ------------------------------------------------------------------------------
EXT_ID="mndncghnabjmepgdapcijjohdjonkkle"
UPDATE_URL="https://jkober.github.io/app_scanner_release/updates.xml"
POLICY_FILENAME="rc_extension.json"

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
# 4. CONTENIDO DE LAS POLÍTICAS (HÍBRIDO ANTIGUO + MODERNO)
# ------------------------------------------------------------------------------
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

EXTERNAL_JSON=$(cat <<EOF
{
  "external_update_url": "$UPDATE_URL"
}
EOF
)

# ------------------------------------------------------------------------------
# 5. FUNCIONES AUXILIARES
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
# 6. INSTALACIÓN EN DIRECTORIOS DE POLÍTICAS GESTIONADAS
# ------------------------------------------------------------------------------
echo "------------------------------------------------------------"
echo " Instalando politicas gestionadas..."
echo "------------------------------------------------------------"

POLICY_DIRS=(
    "/etc/opt/chrome/policies/managed"
    "/etc/chrome/policies/managed"
    "/etc/chromium/policies/managed"
    "/etc/chromium-browser/policies/managed"
    "/etc/opt/edge/policies/managed"
    "/etc/brave/policies/managed"
)

# Soporte para Chromium SNAP en Ubuntu
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
# 7. REGISTRO EXTERNO TRADICIONAL LINUX (/usr/share/.../extensions)
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
# 8. RESUMEN Y FINALIZACIÓN
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

# Notificación gráfica si se ejecutó en segundo plano con zenity
if [ ! -t 1 ] && command -v zenity >/dev/null 2>&1; then
    zenity --info --title="Extension RC" --text="Instalación de políticas completada con éxito.\n\nReinicie sus navegadores para aplicar los cambios." 2>/dev/null || true
fi

# Pausa al final si fue invocado en una terminal creada por el script
if [[ " $* " == *" --pause "* ]] && [ -t 0 ]; then
    echo "Presione Enter para cerrar esta ventana..."
    read -r _ || true
fi
