#!/bin/bash
# ==============================================================================
# uninstall_rc_extension.sh
# Desinstala la extension RC y sus politicas en Chrome, Edge, Chromium y Brave en Linux
# ==============================================================================

set -u

# Auto-lanzar terminal si se ejecuta desde Caja / entorno grafico sin TTY
if [ ! -t 0 ] && { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then
    for term in x-terminal-emulator mate-terminal gnome-terminal xfce4-terminal konsole alacritty kitty xterm; do
        if command -v "$term" >/dev/null 2>&1; then
            exec "$term" -e bash -c "bash \"$0\" --pause \"\$@\"" dummy "$@"
        fi
    done
fi

# Auto-elevacion con sudo o pkexec
if [ "$(id -u)" -ne 0 ]; then
    if [ -t 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "[ERROR] Este script requiere privilegios de superusuario."
            echo "Ejecute como root: su - && bash $0"
            exit 1
        fi
        exec sudo -E bash "$0" "$@"
    elif command -v pkexec >/dev/null 2>&1; then
        exec pkexec bash "$0" "$@"
    elif command -v sudo >/dev/null 2>&1; then
        exec sudo -E bash "$0" "$@"
    else
        echo "[ERROR] Se requieren permisos de superusuario."
        exit 1
    fi
fi

EXT_ID="mndncghnabjmepgdapcijjohdjonkkle"
POLICY_FILENAME="rc_extension.json"

FILES=(
    # Politicas gestionadas
    "/etc/opt/chrome/policies/managed/$POLICY_FILENAME"
    "/etc/chrome/policies/managed/$POLICY_FILENAME"
    "/etc/chromium/policies/managed/$POLICY_FILENAME"
    "/etc/chromium-browser/policies/managed/$POLICY_FILENAME"
    "/etc/opt/edge/policies/managed/$POLICY_FILENAME"
    "/etc/brave/policies/managed/$POLICY_FILENAME"
    "/var/snap/chromium/current/policies/managed/$POLICY_FILENAME"
    "/var/snap/chromium/common/policies/managed/$POLICY_FILENAME"

    # Registro externo de extensiones
    "/opt/google/chrome/extensions/$EXT_ID.json"
    "/usr/share/google-chrome/extensions/$EXT_ID.json"
    "/usr/share/chromium-browser/extensions/$EXT_ID.json"
    "/usr/share/chromium/extensions/$EXT_ID.json"
)

echo "============================================================"
echo " Desinstalando politicas y registros de Extension RC"
echo "============================================================"
echo ""

REMOVED_COUNT=0
for FILE in "${FILES[@]}"; do
    if [ -f "$FILE" ]; then
        rm -f "$FILE"
        echo "[+] Removido: $FILE"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    fi
done

echo ""
echo "============================================================"
echo "[OK] Desinstalacion completada ($REMOVED_COUNT archivos removidos)."
echo "Reinicie sus navegadores para aplicar los cambios."
echo "============================================================"
echo ""

if [ ! -t 1 ] && command -v zenity >/dev/null 2>&1; then
    zenity --info --title="Extension RC" --text="Políticas desinstaladas con éxito.\n\nReinicie sus navegadores para aplicar los cambios." 2>/dev/null || true
fi

if [[ " $* " == *" --pause "* ]] && [ -t 0 ]; then
    echo "Presione Enter para cerrar esta ventana..."
    read -r _ || true
fi
