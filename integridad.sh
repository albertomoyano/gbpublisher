#!/bin/bash
# ============================================================
# integridad.sh
# ============================================================
# DESCRIPCIÓN : Verifica que todas las dependencias externas y
#               componentes de Gambas necesarios para gbpublisher
#               estén disponibles en el sistema antes de la instalación.
# USO         : bash integridad.sh
# SALIDA      : Lista de dependencias con estado OK / FALLO
#               Exit code 0 si todo OK, 1 si hay al menos un fallo
# NOTA        : Este script no crea ni modifica la base de datos.
#               Para crear la BD ejecutar generar_bbdd.sh
# ============================================================

# --- COLORES ---
VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
NEGRITA='\033[1m'
RESET='\033[0m'

# --- CONTADORES ---
FALLOS=0
TOTAL=0

# --- ANCHO DE COLUMNA PARA ALINEACIÓN ---
ANCHO=52

# ============================================================
# FUNCIONES DE VERIFICACIÓN
# ============================================================

# verificar_paquete <nombre_paquete> <descripcion> <accion>
verificar_paquete() {
  local PAQUETE="$1"
  local DESC="$2"
  local ACCION="$3"
  TOTAL=$((TOTAL + 1))
  printf "  %-${ANCHO}s" "$DESC"
  if dpkg -l "$PAQUETE" 2>/dev/null | grep -q '^ii'; then
    echo -e "${VERDE}OK${RESET}"
  else
    echo -e "${ROJO}FALLO${RESET}   →  $ACCION"
    FALLOS=$((FALLOS + 1))
  fi
}

# verificar_comando <comando> <descripcion> <accion>
verificar_comando() {
  local COMANDO="$1"
  local DESC="$2"
  local ACCION="$3"
  TOTAL=$((TOTAL + 1))
  printf "  %-${ANCHO}s" "$DESC"
  if command -v "$COMANDO" &>/dev/null; then
    echo -e "${VERDE}OK${RESET}"
  else
    echo -e "${ROJO}FALLO${RESET}   →  $ACCION"
    FALLOS=$((FALLOS + 1))
  fi
}

# verificar_jar <directorio> <patron> <descripcion> <accion>
verificar_jar() {
  local DIR="$1"
  local PATRON="$2"
  local DESC="$3"
  local ACCION="$4"
  TOTAL=$((TOTAL + 1))
  printf "  %-${ANCHO}s" "$DESC"
  if ls "$DIR"/$PATRON 2>/dev/null | grep -q .; then
    echo -e "${VERDE}OK${RESET}"
  else
    echo -e "${ROJO}FALLO${RESET}   →  $ACCION"
    FALLOS=$((FALLOS + 1))
  fi
}

# verificar_python_modulo <modulo> <descripcion> <accion>
verificar_python_modulo() {
  local MODULO="$1"
  local DESC="$2"
  local ACCION="$3"
  TOTAL=$((TOTAL + 1))
  printf "  %-${ANCHO}s" "$DESC"
  if python3 -c "import $MODULO" 2>/dev/null; then
    echo -e "${VERDE}OK${RESET}"
  else
    echo -e "${ROJO}FALLO${RESET}   →  $ACCION"
    FALLOS=$((FALLOS + 1))
  fi
}

# verificar_ruta_fija <ruta_ejecutable> <descripcion> <accion>
# USA -x PARA VERIFICAR QUE EL ARCHIVO EXISTE Y ES EJECUTABLE
# NECESARIO PARA HERRAMIENTAS QUE NO SE INSTALAN VÍA APT NI ESTÁN EN EL PATH
# DE LAS APLICACIONES GRÁFICAS (EJ: VERAPDF INSTALADO EN /opt/)
verificar_ruta_fija() {
  local RUTA="$1"
  local DESC="$2"
  local ACCION="$3"
  TOTAL=$((TOTAL + 1))
  printf "  %-${ANCHO}s" "$DESC"
  if [ -x "$RUTA" ]; then
    echo -e "${VERDE}OK${RESET}"
  else
    echo -e "${ROJO}FALLO${RESET}   →  $ACCION"
    FALLOS=$((FALLOS + 1))
  fi
}

# verificar_version_gambas <version_minima> <descripcion>
# VERIFICA QUE gambas3-runtime ESTÁ INSTALADO Y QUE SU VERSIÓN
# ES IGUAL O SUPERIOR A LA MÍNIMA REQUERIDA POR GBPUBLISHER.
# USA sort -V PARA COMPARACIÓN SEMÁNTICA CORRECTA (3.9 < 3.21)
verificar_version_gambas() {
  local VERSION_MIN="$1"
  local DESC="$2"
  TOTAL=$((TOTAL + 1))
  printf "  %-${ANCHO}s" "$DESC"
  # VERIFICAR QUE EL PAQUETE ESTÁ INSTALADO
  if ! dpkg -l gambas3-runtime 2>/dev/null | grep -q '^ii'; then
    echo -e "${ROJO}FALLO${RESET}   →  Gambas3 no está instalado"
    FALLOS=$((FALLOS + 1))
    return
  fi
  # EXTRAER VERSIÓN INSTALADA — EJEMPLO DE SALIDA dpkg: "3.21.0-1ubuntu1"
  # cut -d'-' -f1 QUEDA CON "3.21.0" DESCARTANDO EL SUFIJO DE DISTRO
  local VERSION_INST
  VERSION_INST=$(dpkg -l gambas3-runtime 2>/dev/null | grep '^ii' | awk '{print $3}' | cut -d'-' -f1)
  # sort -V ORDENA POR VERSIÓN SEMÁNTICA; tail -n1 DEVUELVE LA MÁS ALTA
  # SI LA MÁS ALTA ES LA INSTALADA (O SON IGUALES), LA VERSIÓN ES SUFICIENTE
  local VERSION_MAYOR
  VERSION_MAYOR=$(printf '%s\n' "$VERSION_MIN" "$VERSION_INST" | sort -V | tail -n1)
  if [ "$VERSION_MAYOR" = "$VERSION_INST" ] || [ "$VERSION_INST" = "$VERSION_MIN" ]; then
    echo -e "${VERDE}OK${RESET}      (versión $VERSION_INST)"
  else
    echo -e "${ROJO}FALLO${RESET}   →  Versión instalada: $VERSION_INST — Se requiere >= $VERSION_MIN"
    echo -e "           ${AMARILLO}Agregar repositorio Gambas $VERSION_MIN para Linux Mint 22.x / Ubuntu 24.04:${RESET}"
    echo    "           echo 'deb http://download.opensuse.org/repositories/home:/gambas:/3.21/xUbuntu_24.04/ /' \\"
    echo    "             | sudo tee /etc/apt/sources.list.d/home:gambas:3.21.list"
    echo    "           curl -fsSL https://download.opensuse.org/repositories/home:gambas:3.21/xUbuntu_24.04/Release.key \\"
    echo    "             | gpg --dearmor \\"
    echo    "             | sudo tee /etc/apt/trusted.gpg.d/home_gambas_3.21.gpg > /dev/null"
    echo    "           sudo apt update && sudo apt install gambas3"
    FALLOS=$((FALLOS + 1))
  fi
}

# ============================================================
# VERIFICACIÓN DE ENTORNO — DEBE EJECUTARSE ANTES DE TODO
# gbpublisher ESTÁ CERTIFICADO EXCLUSIVAMENTE PARA
# LINUX MINT CON ESCRITORIO CINNAMON Y SERVIDOR X11.
# EN OTROS ENTORNOS SE ADVIERTE PERO NO SE ABORTA,
# PARA PERMITIR LA VERIFICACIÓN DE DEPENDENCIAS IGUALMENTE.
# ============================================================
verificar_entorno() {
  local DISTRO=""
  local DESKTOP=""
  local SESSION=""
  local OK=true

  # LEER NOMBRE DE LA DISTRIBUCIÓN DESDE /etc/os-release
  if [ -f /etc/os-release ]; then
    DISTRO=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]')
  fi
  DESKTOP=$(echo "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')
  SESSION=$(echo "${XDG_SESSION_TYPE:-}" | tr '[:upper:]' '[:lower:]')

  # EVALUAR CADA CONDICIÓN POR SEPARADO PARA DAR MENSAJES PRECISOS
  if ! echo "$DISTRO" | grep -q "linux mint"; then
    OK=false
  fi
  if ! echo "$DESKTOP" | grep -q "cinnamon"; then
    OK=false
  fi
  if [ "$SESSION" != "x11" ]; then
    OK=false
  fi

  if [ "$OK" = false ]; then
    echo ""
    echo -e "  ${AMARILLO}${NEGRITA}ADVERTENCIA — Entorno no certificado${RESET}"
    echo -e "  ${AMARILLO}gbpublisher está diseñado y probado exclusivamente para:${RESET}"
    echo -e "  ${AMARILLO}  • Distribución : Linux Mint${RESET}"
    echo -e "  ${AMARILLO}  • Escritorio   : Cinnamon${RESET}"
    echo -e "  ${AMARILLO}  • Sesión       : X11${RESET}"
    echo ""
    echo -e "  ${AMARILLO}Entorno detectado:${RESET}"
    echo -e "  ${AMARILLO}  • Distribución : ${DISTRO:-no detectada}${RESET}"
    echo -e "  ${AMARILLO}  • Escritorio   : ${DESKTOP:-no detectado}${RESET}"
    echo -e "  ${AMARILLO}  • Sesión       : ${SESSION:-no detectada}${RESET}"
    echo ""
    echo -e "  ${AMARILLO}En este entorno no hay garantías de estabilidad ni soporte oficial.${RESET}"
    echo -e "  ${AMARILLO}Se continúa la verificación de dependencias a modo informativo.${RESET}"
    echo "  ────────────────────────────────────────────────────────────────────"
  fi
}

# ============================================================
# INICIO
# ============================================================
echo ""
echo -e "${NEGRITA}gbpublisher — Verificación de integridad del sistema${RESET}"
echo "  $(uname -n)  |  $(lsb_release -ds 2>/dev/null || echo Linux)  |  $(date '+%d/%m/%Y %H:%M')"
echo "  ────────────────────────────────────────────────────────────────────"

# VERIFICACIÓN DE ENTORNO: PRIMERA EN EJECUTARSE, ANTES DE CUALQUIER DEPENDENCIA
verificar_entorno

# ============================================================
# BASE DE DATOS
# ============================================================
echo ""
echo -e "${NEGRITA}  Base de datos${RESET}"
verificar_paquete "mysql-server" \
  "MySQL Server" \
  "sudo apt install mysql-server"

# ============================================================
# JAVA Y PROCESADORES XSLT
# ============================================================
echo ""
echo -e "${NEGRITA}  Java y procesadores XSLT${RESET}"
verificar_comando "java" \
  "Java Runtime Environment" \
  "sudo apt install default-jre"
verificar_jar "/opt/Saxon-HE" "saxon-he-*.jar" \
  "Saxon-HE — JAR principal" \
  "Descargar ZIP desde saxonica.com → sudo mkdir -p /opt/Saxon-HE → sudo cp saxon-he-*.jar /opt/Saxon-HE/"
verificar_jar "/opt/Saxon-HE/lib" "xmlresolver-*.jar" \
  "Saxon-HE — dependencias lib/xmlresolver" \
  "Copiar carpeta lib/ del ZIP de Saxon → sudo mkdir -p /opt/Saxon-HE/lib → sudo cp lib/xmlresolver-*.jar /opt/Saxon-HE/lib/"

# ============================================================
# PROCESADORES DE DOCUMENTOS
# ============================================================
echo ""
echo -e "${NEGRITA}  Procesadores de documentos${RESET}"
verificar_paquete "chromium" \
  "Chromium" \
  "sudo apt install chromium"
verificar_paquete "pandoc" \
  "Pandoc" \
  "sudo apt install pandoc"
verificar_paquete "imagemagick" \
  "ImageMagick (convertidor)" \
  "sudo apt install imagemagick"
verificar_paquete "texlive-full" \
  "TeX Live (completo)" \
  "sudo apt install texlive-full"
verificar_paquete "epubcheck" \
  "epubcheck (validador EPUB)" \
  "sudo apt install epubcheck"
verificar_paquete "libimage-exiftool-perl" \
  "libimage-exiftool-perl (exiftool)" \
  "sudo apt install libimage-exiftool-perl"

# ============================================================
# VALIDADORES XML
# ============================================================
echo ""
echo -e "${NEGRITA}  Validadores XML${RESET}"
verificar_comando "xmllint" \
  "xmllint (validador XML)" \
  "sudo apt install libxml2-utils"
verificar_comando "xsltproc" \
  "xsltproc (XSLT processor)" \
  "sudo apt install xsltproc"
verificar_python_modulo "packtools" \
  "packtools (validador SciELO PS)" \
  "pip install packtools --break-system-packages"
# VERAPDF SE INSTALA EN RUTA FIJA /opt/verapdf/ — NO ESTÁ EN EL PATH
# DE LAS APLICACIONES GRÁFICAS, POR LO QUE command -v DARÍA FALSO POSITIVO
verificar_ruta_fija "/opt/verapdf/verapdf" \
  "veraPDF (validador PDF/A)" \
  "Descargar desde verapdf.org → sudo ./verapdf-installer --installpath /opt/verapdf"

# ============================================================
# CONTROL DE VERSIONES
# ============================================================
echo ""
echo -e "${NEGRITA}  Control de versiones${RESET}"
verificar_comando "git" \
  "Git (control de versiones)" \
  "sudo apt install git"

# ============================================================
# COMPONENTES GAMBAS 3
# ============================================================
echo ""
echo -e "${NEGRITA}  Componentes Gambas 3${RESET}"
# LA VERSIÓN SE VERIFICA PRIMERO: SI ES INSUFICIENTE, LOS PAQUETES
# INDIVIDUALES PUEDEN ESTAR INSTALADOS Y AUN ASÍ CAUSAR FALLOS EN RUNTIME
verificar_version_gambas "3.21.0" \
  "Gambas3 versión mínima requerida (>= 3.21)"
verificar_paquete "gambas3-runtime"           "Gambas3 Runtime"               "sudo apt install gambas3-runtime"
verificar_paquete "gambas3-gb-complex"        "Gambas3 gb.complex"            "sudo apt install gambas3-gb-complex"
verificar_paquete "gambas3-gb-crypt"          "Gambas3 gb.crypt"              "sudo apt install gambas3-gb-crypt"
verificar_paquete "gambas3-gb-db2"            "Gambas3 gb.db2"                "sudo apt install gambas3-gb-db2"
verificar_paquete "gambas3-gb-db2-mysql"      "Gambas3 gb.db2.mysql"          "sudo apt install gambas3-gb-db2-mysql"
verificar_paquete "gambas3-gb-db2-sqlite3"    "Gambas3 gb.db2.sqlite3"        "sudo apt install gambas3-gb-db2-sqlite3"
verificar_paquete "gambas3-gb-dbus"           "Gambas3 gb.dbus"               "sudo apt install gambas3-gb-dbus"
verificar_paquete "gambas3-gb-desktop"        "Gambas3 gb.desktop"            "sudo apt install gambas3-gb-desktop"
verificar_paquete "gambas3-gb-eval-highlight" "Gambas3 gb.eval / gb.eval.highlight" "sudo apt install gambas3-gb-eval-highlight"
verificar_paquete "gambas3-gb-form"           "Gambas3 gb.form"               "sudo apt install gambas3-gb-form"
verificar_paquete "gambas3-gb-form-dialog"    "Gambas3 gb.form.dialog"        "sudo apt install gambas3-gb-form-dialog"
verificar_paquete "gambas3-gb-form-editor"    "Gambas3 gb.form.editor"        "sudo apt install gambas3-gb-form-editor"
verificar_paquete "gambas3-gb-form-htmlview"  "Gambas3 gb.form.htmlview"      "sudo apt install gambas3-gb-form-htmlview"
verificar_paquete "gambas3-gb-form-terminal"  "Gambas3 gb.form.terminal"      "sudo apt install gambas3-gb-form-terminal"
verificar_paquete "gambas3-gb-highlight"      "Gambas3 gb.highlight"          "sudo apt install gambas3-gb-highlight"
verificar_paquete "gambas3-gb-image"          "Gambas3 gb.image"              "sudo apt install gambas3-gb-image"
verificar_paquete "gambas3-gb-markdown"       "Gambas3 gb.markdown"           "sudo apt install gambas3-gb-markdown"
verificar_paquete "gambas3-gb-net"            "Gambas3 gb.net"                "sudo apt install gambas3-gb-net"
verificar_paquete "gambas3-gb-net-curl"       "Gambas3 gb.net.curl"           "sudo apt install gambas3-gb-net-curl"
verificar_paquete "gambas3-gb-openssl"        "Gambas3 gb.openssl"            "sudo apt install gambas3-gb-openssl"
verificar_paquete "gambas3-gb-pcre"           "Gambas3 gb.pcre"               "sudo apt install gambas3-gb-pcre"
verificar_paquete "gambas3-gb-qt5"            "Gambas3 gb.qt5"                "sudo apt install gambas3-gb-qt5"
verificar_paquete "gambas3-gb-qt5-ext"        "Gambas3 gb.qt5.ext"            "sudo apt install gambas3-gb-qt5-ext"
verificar_paquete "gambas3-gb-sdl2-audio"     "Gambas3 gb.sdl2.audio"         "sudo apt install gambas3-gb-sdl2-audio"
verificar_paquete "gambas3-gb-settings"       "Gambas3 gb.settings"           "sudo apt install gambas3-gb-settings"
verificar_paquete "gambas3-gb-term"           "Gambas3 gb.term"               "sudo apt install gambas3-gb-term"
verificar_paquete "gambas3-gb-util"           "Gambas3 gb.util"               "sudo apt install gambas3-gb-util"
verificar_paquete "gambas3-gb-util-web"       "Gambas3 gb.util.web"           "sudo apt install gambas3-gb-util-web"
verificar_paquete "gambas3-gb-xml"            "Gambas3 gb.xml"                "sudo apt install gambas3-gb-xml"
verificar_paquete "gambas3-gb-xml-html"       "Gambas3 gb.xml.html"           "sudo apt install gambas3-gb-xml-html"
verificar_paquete "gambas3-gb-xml-rpc"        "Gambas3 gb.xml.rpc"            "sudo apt install gambas3-gb-xml-rpc"
verificar_paquete "gambas3-gb-xml-xslt"       "Gambas3 gb.xml.xslt"           "sudo apt install gambas3-gb-xml-xslt"

# ============================================================
# RESUMEN
# ============================================================
echo ""
echo "  ────────────────────────────────────────────────────────────────────"
if [ "$FALLOS" -eq 0 ]; then
  echo -e "  ${VERDE}${NEGRITA}Sistema listo: todas las dependencias ($TOTAL) están disponibles.${RESET}"
  echo -e "  Podés instalar gbpublisher y ejecutar ${NEGRITA}generar_bbdd.sh${RESET} para crear la base de datos."
else
  echo -e "  ${ROJO}${NEGRITA}$FALLOS de $TOTAL dependencia(s) con FALLO.${RESET}"
  echo -e "  Instalá las dependencias faltantes antes de continuar."
fi
echo ""

exit $FALLOS
