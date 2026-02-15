#!/bin/bash

# ============================================================================
# SCRIPT DE VERIFICACIÓN DE DEPENDENCIAS PARA GBPUBLISHER
# ============================================================================
# DESCRIPCIÓN:
#   Verifica que el sistema operativo sea Linux Mint y que estén instaladas
#   todas las dependencias necesarias para gbpublisher.
#
# USO:
#   chmod +x verificar.sh
#   ./verificar.sh
#
# AUTOR: Alberto Moyano
# FECHA: 2025
# ============================================================================

# COLORES PARA MENSAJES (OPCIONAL)
ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
NC='\033[0m' # Sin Color

# CONTADOR DE ERRORES
ERRORES=0

# ============================================================================
# FUNCIÓN: verificar_linux_mint
# DESCRIPCIÓN: Verifica que el sistema operativo sea Linux Mint
# RETORNA: 0 si es Linux Mint, 1 si no lo es
# ============================================================================
verificar_linux_mint() {
    echo -e "${AZUL}=== VERIFICANDO SISTEMA OPERATIVO ===${NC}"

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$NAME" == *"Linux Mint"* ]]; then
            echo -e "${VERDE}✓ Sistema operativo: $NAME $VERSION${NC}"
            return 0
        else
            echo -e "${ROJO}✗ ERROR: El sistema operativo actual es: $NAME${NC}"
            echo -e "${ROJO}  Este script solo funciona en Linux Mint.${NC}"
            return 1
        fi
    else
        echo -e "${ROJO}✗ ERROR: No se pudo determinar el sistema operativo.${NC}"
        return 1
    fi
}

# ============================================================================
# FUNCIÓN: verificar_paquete
# DESCRIPCIÓN: Verifica si un paquete está instalado en el sistema
# PARÁMETROS:
#   $1 - Nombre del paquete a verificar
#   $2 - Mensaje descriptivo (opcional)
# RETORNA: 0 si está instalado, 1 si no lo está
# ============================================================================
verificar_paquete() {
    local PAQUETE=$1
    local MENSAJE=${2:-$PAQUETE}

    if dpkg -l | grep -q "^ii  $PAQUETE"; then
        echo -e "${VERDE}✓ $MENSAJE está instalado${NC}"
        return 0
    else
        echo -e "${ROJO}✗ $MENSAJE NO está instalado${NC}"
        ((ERRORES++))
        return 1
    fi
}

# ============================================================================
# FUNCIÓN: verificar_comando
# DESCRIPCIÓN: Verifica si un comando está disponible en el sistema
# PARÁMETROS:
#   $1 - Nombre del comando a verificar
#   $2 - Mensaje descriptivo (opcional)
# RETORNA: 0 si está disponible, 1 si no lo está
# NOTA: Útil para verificar programas que no son paquetes .deb
# ============================================================================
verificar_comando() {
    local COMANDO=$1
    local MENSAJE=${2:-$COMANDO}

    if command -v $COMANDO &> /dev/null; then
        echo -e "${VERDE}✓ $MENSAJE está disponible${NC}"
        return 0
    else
        echo -e "${ROJO}✗ $MENSAJE NO está disponible${NC}"
        ((ERRORES++))
        return 1
    fi
}

# ============================================================================
# FUNCIÓN: verificar_jar
# DESCRIPCIÓN: Verifica que exista un archivo JAR de Java en una ruta específica
# PARÁMETROS:
#   $1 - Ruta del directorio donde debe estar el JAR
#   $2 - Patrón del archivo JAR (puede usar wildcards)
#   $3 - Mensaje descriptivo
# RETORNA: 0 si existe, 1 si no existe
# NOTA: Útil para verificar instalaciones manuales de Java como Saxon-HE
# ============================================================================
verificar_jar() {
    local RUTA=$1
    local PATRON=$2
    local MENSAJE=$3

    # VERIFICAR QUE EXISTA EL DIRECTORIO
    if [ ! -d "$RUTA" ]; then
        echo -e "${ROJO}✗ $MENSAJE NO está instalado${NC}"
        echo -e "${ROJO}  No existe el directorio: $RUTA${NC}"
        ((ERRORES++))
        return 1
    fi

    # BUSCAR ARCHIVOS QUE COINCIDAN CON EL PATRÓN
    local ARCHIVOS=$(ls $RUTA/$PATRON 2>/dev/null)

    if [ -n "$ARCHIVOS" ]; then
        # OBTENER SOLO EL NOMBRE DEL ARCHIVO (SIN RUTA)
        local NOMBRE_ARCHIVO=$(basename $(echo $ARCHIVOS | awk '{print $1}'))
        echo -e "${VERDE}✓ $MENSAJE está instalado ($NOMBRE_ARCHIVO)${NC}"
        return 0
    else
        echo -e "${ROJO}✗ $MENSAJE NO está instalado${NC}"
        echo -e "${ROJO}  No se encontró $PATRON en $RUTA${NC}"
        ((ERRORES++))
        return 1
    fi
}

# ============================================================================
# PROGRAMA PRINCIPAL
# ============================================================================

echo ""
echo "============================================================================"
echo "  VERIFICACIÓN DE DEPENDENCIAS PARA GBPUBLISHER"
echo "============================================================================"
echo ""

# PASO 1: VERIFICAR QUE SEA LINUX MINT
if ! verificar_linux_mint; then
    echo ""
    echo -e "${ROJO}ABORTANDO: Las tareas de verificación no se pueden cumplir.${NC}"
    exit 1
fi

echo ""
echo -e "${AZUL}=== VERIFICANDO DEPENDENCIAS ===${NC}"

# ============================================================================
# LISTA DE DEPENDENCIAS A VERIFICAR
# ============================================================================
# INSTRUCCIONES PARA AGREGAR NUEVAS DEPENDENCIAS:
#
# Para paquetes .deb (instalados con apt):
#   verificar_paquete "nombre-del-paquete" "Descripción amigable"
#
# Para comandos/programas (que pueden venir de otras fuentes):
#   verificar_comando "nombre-comando" "Descripción amigable"
#
# Para archivos JAR de Java (instalaciones manuales):
#   verificar_jar "/ruta/directorio" "patron-*.jar" "Descripción amigable"
#
# EJEMPLOS:
#   verificar_paquete "gambas3-runtime" "Gambas3 Runtime"
#   verificar_comando "pandoc" "Pandoc (conversor de documentos)"
#   verificar_jar "/opt/Saxon-HE" "saxon-he-*.jar" "Saxon-HE XSLT Processor"
# ============================================================================

# DEPENDENCIAS ACTUALES

# BASES DE DATOS
verificar_paquete "mysql-server" "MySQL Server"

# COMPONENTES DE GAMBAS
verificar_paquete "gambas3-runtime" "Gambas3 Runtime"
verificar_paquete "gambas3-gb-complex" "gambas3-complex Component"
verificar_paquete "gambas3-gb-crypt" "gambas3-gb-crypt Component"
verificar_paquete "gambas3-gb-db2" "gambas3-gb-db2 Component"
verificar_paquete "gambas3-gb-db2-mysql" "gambas3-gb-db2-mysql Component"
verificar_paquete "gambas3-gb-db2-sqlite3" "gambas3-gb-db2-sqlite3 Component"
verificar_paquete "gambas3-gb-dbus" "gambas3-gb-dbus Component"
verificar_paquete "gambas3-gb-desktop" "gambas3-gb-desktop Component"
verificar_paquete "gambas3-gb-eval" "gambas3-gb-eval Component"
verificar_paquete "gambas3-gb-form" "gambas3-gb-form Component"
verificar_paquete "gambas3-gb-form-dialog" "gambas3-gb-form-dialog Component"
verificar_paquete "gambas3-gb-form-editor" "gambas3-gb-form-editor Component"
verificar_paquete "gambas3-gb-form-htmlview" "gambas3-gb-form-htmlview Component"
verificar_paquete "gambas3-gb-form-terminal" "gambas3-gb-form-terminal Component"
verificar_paquete "gambas3-gb-highlight" "gambas3-gb-highlight Component"
verificar_paquete "gambas3-gb-image" "gambas3-gb-image Component"
verificar_paquete "gambas3-gb-markdown" "gambas3-gb-markdown Component"
verificar_paquete "gambas3-gb-net" "gambas3-gb-net Component"
verificar_paquete "gambas3-gb-net-curl" "gambas3-gb-net-curl Component"
verificar_paquete "gambas3-gb-openssl" "gambas3-gb-openssl Component"
verificar_paquete "gambas3-gb-pcre" "gambas3-gb-pcre Component"
verificar_paquete "gambas3-gb-qt5" "gambas3-gb-qt5 Component"
verificar_paquete "gambas3-gb-qt5-ext" "gambas3-gb-qt5-ext Component"
verificar_paquete "gambas3-gb-sdl2-audio" "gambas3-gb-sdl2-audio Component"
verificar_paquete "gambas3-gb-settings" "gambas3-gb-settings Component"
verificar_paquete "gambas3-gb-term" "gambas3-gb-term Component"
verificar_paquete "gambas3-gb-util" "gambas3-gb-util Component"
verificar_paquete "gambas3-gb-util-web" "gambas3-gb-util-web Component"
verificar_paquete "gambas3-gb-xml" "gambas3-gb-xml Component"
verificar_paquete "gambas3-gb-xml-html" "gambas3-gb-xml-html Component"
verificar_paquete "gambas3-gb-xml-rpc" "gambas3-gb-xml-rpc Component"
verificar_paquete "gambas3-gb-xml-xslt" "gambas3-gb-xml-rpc Component"

# JAVA (REQUERIDO PARA SAXON-HE)
verificar_comando "java" "Java Runtime Environment"

# PROCESADORES DE DOCUMENTOS
verificar_paquete "pandoc" "Pandoc"
verificar_paquete "texlive-full" "TeX Live (completo)"

# SAXON-HE (INSTALACIÓN MANUAL)
# ESTRUCTURA OBLIGATORIA: /opt/Saxon-HE/saxon-he-[version].jar
verificar_jar "/opt/Saxon-HE" "saxon-he-*.jar" "Saxon-HE XSLT Processor"

# VALIDADORES XML
verificar_comando "xmllint" "libxml2-utils (validador XML)"

# ============================================================================
# AQUÍ PUEDES AGREGAR MÁS DEPENDENCIAS SIGUIENDO LOS EJEMPLOS ANTERIORES
# ============================================================================
# EJEMPLOS COMENTADOS (descomentar según necesites):
#
# verificar_paquete "gambas3-gb-db-mysql" "Gambas3 MySQL Component"
# verificar_paquete "gambas3-gb-xml" "Gambas3 XML Component"
# verificar_paquete "python3-lxml" "Python lxml"
# verificar_comando "pdflatex" "PDFLaTeX"
# verificar_jar "/opt/MiPrograma" "programa-*.jar" "Mi Programa Java"
# ============================================================================

echo ""
echo "============================================================================"

# RESUMEN FINAL
if [ $ERRORES -eq 0 ]; then
    echo -e "${VERDE}✓ TODAS LAS DEPENDENCIAS ESTÁN INSTALADAS${NC}"
    echo "============================================================================"
    exit 0
else
    echo -e "${AMARILLO}⚠ SE ENCONTRARON $ERRORES DEPENDENCIA(S) FALTANTE(S)${NC}"
    echo "============================================================================"
    echo ""
    echo "INSTRUCCIONES DE INSTALACIÓN:"
    echo ""
    echo "Para paquetes del sistema:"
    echo -e "${AZUL}  sudo apt update${NC}"
    echo -e "${AZUL}  sudo apt install [nombre-del-paquete]${NC}"
    echo ""
    echo "Para Saxon-HE (instalación manual):"
    echo "  1. Descargar desde: https://www.saxonica.com/download/download_page.xml"
    echo "  2. Crear directorio:"
    echo -e "${AZUL}     sudo mkdir -p /opt/Saxon-HE${NC}"
    echo "  3. Copiar el archivo JAR:"
    echo -e "${AZUL}     sudo cp saxon-he-*.jar /opt/Saxon-HE/${NC}"
    echo "  4. Verificar instalación:"
    echo -e "${AZUL}     java -jar /opt/Saxon-HE/saxon-he-*.jar -?${NC}"
    echo ""
    exit 1
fi
