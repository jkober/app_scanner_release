#!/bin/bash
# ==============================================================================
# install_rc_extension.sh
# Instala la extensión RC en Google Chrome y Chromium para Ubuntu / Debian Linux
# mediante políticas gestionadas (ExtensionSettings con force_installed).
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[!] Este script debe ejecutarse con privilegios de superusuario (root)."
  echo "    Ejecute: sudo $0"
  exit 1
fi

echo "============================================================"
echo " Instalador de Política de Extensión RC (Ubuntu/Linux)"
echo "============================================================"

EXT_ID="mndncghnabjmepgdapcijjohdjonkkle"
UPDATE_URL="https://jkober.github.io/app_scanner_release/updates.xml"

# Rutas estándar de políticas gestionadas en Linux
CHROME_POLICY_DIR="/etc/opt/chrome/policies/managed"
CHROMIUM_POLICY_DIR="/etc/chromium/policies/managed"

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

# 1. Instalar para Google Chrome
mkdir -p "$CHROME_POLICY_DIR"
echo "$POLICY_CONTENT" > "$CHROME_POLICY_DIR/rc_extension.json"
chmod 644 "$CHROME_POLICY_DIR/rc_extension.json"
chown root:root "$CHROME_POLICY_DIR/rc_extension.json"
echo "[+] Política instalada en Google Chrome: $CHROME_POLICY_DIR/rc_extension.json"

# 2. Instalar para Chromium (si existe o se desea compatibilidad)
mkdir -p "$CHROMIUM_POLICY_DIR"
echo "$POLICY_CONTENT" > "$CHROMIUM_POLICY_DIR/rc_extension.json"
chmod 644 "$CHROMIUM_POLICY_DIR/rc_extension.json"
chown root:root "$CHROMIUM_POLICY_DIR/rc_extension.json"
echo "[+] Política instalada en Chromium:      $CHROMIUM_POLICY_DIR/rc_extension.json"

# 3. Comprobar conectividad
echo "[*] Comprobando acceso a la URL de actualización..."
if command -v curl >/dev/null 2>&1; then
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$UPDATE_URL" || true)
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "[+] Conexión exitosa a $UPDATE_URL (HTTP 200)."
  else
    echo "[!] Advertencia: La URL respondió HTTP $HTTP_STATUS. (Verifique si ya fue desplegado en GitHub)."
  fi
fi

echo ""
echo "============================================================"
echo "[OK] Instalación completada exitosamente."
echo "Para verificar:"
echo " 1. Abra o reinicie Google Chrome."
echo " 2. Visite: chrome://policy y presione 'Volver a cargar políticas'."
echo "    Verá 'ExtensionSettings' cargada."
echo " 3. Visite: chrome://extensions"
echo "    Verá la extensión RCivil instalada por el administrador."
echo "============================================================"
