#!/bin/bash
# ==============================================================================
# install_rc_extension.sh
# Instala la extension RC en Chrome, Edge, Chromium y Brave en Linux
# mediante politicas gestionadas (ExtensionSettings con force_installed).
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[!] Este script debe ejecutarse con privilegios de superusuario (root)."
  echo "    Ejecute: sudo $0"
  exit 1
fi

echo "============================================================"
echo " Instalador Multi-Navegador de Extension RC (Linux)"
echo "============================================================"

EXT_ID="mndncghnabjmepgdapcijjohdjonkkle"
UPDATE_URL="https://jkober.github.io/app_scanner_release/updates.xml"

POLICY_CONTENT=$(cat <<EOF
{
  "ExtensionSettings": {
    "$EXT_ID": {
      "installation_mode": "force_installed",
      "update_url": "$UPDATE_URL"
    }
  }
}
EOF
)

DIRECTORIES=(
  "/etc/opt/chrome/policies/managed"
  "/etc/opt/edge/policies/managed"
  "/etc/chromium/policies/managed"
  "/etc/brave/policies/managed"
)

for DIR in "${DIRECTORIES[@]}"; do
  mkdir -p "$DIR"
  echo "$POLICY_CONTENT" > "$DIR/rc_extension.json"
  chmod 644 "$DIR/rc_extension.json"
  chown root:root "$DIR/rc_extension.json"
  echo "[+] Politica instalada en: $DIR/rc_extension.json"
done

echo ""
echo "============================================================"
echo "[OK] Instalacion completada exitosamente."
echo "Para verificar: Abra o reinicie Chrome, Edge o Chromium y visite: chrome://extensions"
echo "============================================================"
