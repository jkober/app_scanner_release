#!/bin/bash
# ==============================================================================
# uninstall_rc_extension.sh
# Desinstala la política de la extensión RC en Ubuntu/Debian Linux
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[!] Este script debe ejecutarse con privilegios de superusuario (root)."
  echo "    Ejecute: sudo $0"
  exit 1
fi

CHROME_POLICY="/etc/opt/chrome/policies/managed/rc_extension.json"
CHROMIUM_POLICY="/etc/chromium/policies/managed/rc_extension.json"

if [ -f "$CHROME_POLICY" ]; then
  rm -f "$CHROME_POLICY"
  echo "[+] Removida política de Google Chrome: $CHROME_POLICY"
fi

if [ -f "$CHROMIUM_POLICY" ]; then
  rm -f "$CHROMIUM_POLICY"
  echo "[+] Removida política de Chromium: $CHROMIUM_POLICY"
fi

echo "[OK] Desinstalación completada. Reinicie Chrome para aplicar los cambios."
