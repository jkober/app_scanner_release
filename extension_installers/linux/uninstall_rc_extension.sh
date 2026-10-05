#!/bin/bash
# ==============================================================================
# uninstall_rc_extension.sh
# Desinstala la extension RC y sus politicas en Chrome, Edge, Chromium y Brave en Linux
# ==============================================================================

set -u

# Auto-elevacion con sudo
if [ "$(id -u)" -ne 0 ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[ERROR] Este script requiere privilegios de superusuario."
        echo "Ejecute como root: su - && bash $0"
        exit 1
    fi
    exec sudo -E bash "$0" "$@"
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
