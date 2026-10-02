# Sistema de Distribución Interna - Extensión Chrome RC (Instalación en 1 Clic)

Este directorio contiene los scripts e instaladores de directivas empresariales para desplegar la extensión de Google Chrome **RCivil Scanner** sin requerir Chrome Web Store ni cuentas de administración de Google.

---

## 📌 Datos Clave de la Extensión
* **Extension ID:** `mndncghnabjmepgdapcijjohdjonkkle`
* **URL de Actualización (Update URL):** `https://jkober.github.io/app_scanner_release/updates.xml`
* **URL de Descarga Directa (CRX):** `https://jkober.github.io/app_scanner_release/chrome.crx`
* **Modo de Instalación:** En 1 Clic desde la web autorizada (`ExtensionInstallSources`) + Auto-actualización

---

## 📂 Estructura de Archivos

```
distribution/
│
├── windows/
│   ├── install_rc_extension.cmd     # Lanzador por doble clic (solicita permisos de Administrador)
│   ├── install_rc_extension.ps1     # Script PowerShell que configura las directivas en el Registro (HKLM)
│   ├── install_rc_extension.reg     # Archivo de Registro directo (.reg) para importar con doble clic
│   ├── uninstall_rc_extension.ps1   # Script PowerShell para remover las directivas
│   └── uninstall_rc_extension.reg   # Archivo de Registro para eliminar las directivas
│
└── linux/
    ├── install_rc_extension.sh      # Script Bash para Ubuntu/Debian (sudo ./install_rc_extension.sh)
    ├── rc_extension_policy.json     # Archivo JSON de directiva administrada (/etc/opt/chrome/policies/managed/)
    └── uninstall_rc_extension.sh    # Script Bash para desinstalar la directiva
```

---

## 🪟 Cómo Instalar en Windows (Cualquier PC: Dominio o WORKGROUP)

1. En la computadora del usuario, haz doble clic sobre:
   * **`install_rc_extension.reg`** (y pulsa **Sí** para importar al Registro), o
   * **`install_rc_extension.cmd`** (y acepta el cartel de permisos).
2. Abre Google Chrome y entra a tu web de descargas:
   ```
   https://jkober.github.io/app_scanner_release/
   ```
3. Haz clic en el enlace para descargar **`chrome.crx`**.
4. **Chrome abrirá automáticamente la ventana de confirmación oficial:**  
   *"¿Quieres agregar 'RCivil Scanner Bridge'?"*  
   Pulsa **Agregar extensión**.
5. ¡Listo! La extensión queda instalada y activa.

---

## 🐧 Cómo Instalar en Ubuntu / Debian Linux

1. Abre una terminal en la carpeta `distribution/linux/`.
2. Asigna permisos y ejecuta:
   ```bash
   chmod +x install_rc_extension.sh
   sudo ./install_rc_extension.sh
   ```
3. En Linux, Chrome aplica la directiva obligatoria `force_installed` de inmediato sin requerir confirmación del usuario.

---

## 🚀 Ciclo de Actualizaciones Futuras

* Para publicar una nueva versión, simplemente cambia el número en el archivo `VERSION` y ejecuta el workflow manual en GitHub.
* Todos los navegadores Chrome que tengan la extensión instalada consultarán periódicamente `updates.xml` y se **actualizarán solos en segundo plano de manera transparente**, sin que tengas que volver a tocar las computadoras de los usuarios.
