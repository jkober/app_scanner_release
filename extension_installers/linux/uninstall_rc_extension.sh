#!/bin/bash
# ==============================================================================
# uninstall_rc_extension.sh
# Desinstala la politica de la extension RC en Chrome, Edge, Chromium y Brave en Linux
# ==============================================================================

set -e

if [ "$EUID" -ne 0 ]; then
  echo "[!] Este script debe ejecutarse con privilegios de superusuario (root)."
  echo "    Ejecute: sudo $0"
  exit 1
fi

FILES=(
  "/etc/opt/chrome/policies/managed/rc_extension.json"
  "/etc/opt/edge/policies/managed/rc_extension.json"
  "/etc/chromium/policies/managed/rc_extension.json"
  "/etc/brave/policies/managed/rc_extension.json"
)

for FILE in "${FILES[@]}"; do
  if [ -f "$FILE" ]; then
    rm -f "$FILE"
    echo "[+] Removida politica: $FILE"
  fi
done

echo "[OK] Desinstalacion completada. Reinicie sus navegadores."
