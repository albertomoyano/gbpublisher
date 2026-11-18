#!/usr/bin/env bash
# ============================================================================
# Script    : integridad.sh
# Propósito : Controla que estén, y FUNCIONEN, las herramientas de producción
#             que gbpublisher congela en /opt, e instala o repara las que
#             fallen. Lo lanza el menú «Acerca de... → Controlar integridad
#             del sistema» con m_Lanzadora.EjecutarScript, en la terminal del
#             proyecto abierto.
#
# UNA SOLA LISTA, QUE VIVE ACÁ
#   Antes había dos (IntegridadSistema en Gambas y el viejo integridad.sh) y
#   ninguna miraba lo que usa la cadena: el control daba OK con Saxon sin su
#   enlace saxon-he.jar y la generación moría. Esta es la única lista.
#
# QUÉ SE CONGELA EN /opt Y QUÉ NO
#   En /opt, con versión y huella fijas, lo que define el contenido de una
#   salida o el veredicto de una validación, cuando una versión nueva no
#   garantiza el mismo resultado y congelarlo es barato (un JAR, un binario):
#   Saxon-HE, pandoc, epubcheck, veraPDF y packtools. Lo demás lo da el
#   sistema por las dependencias del .deb (Java, TeX Live, xmllint, Python
#   con venv...) y no se controla acá. MySQL tampoco: si la aplicación está
#   abierta con un proyecto, ya se conectó a la base.
#
# CONTROL POR FUNCIONAMIENTO, NO POR PRESENCIA
#   No alcanza con que exista el archivo. Cada componente se controla por la
#   huella de lo instalado (la versión exacta) y haciéndolo trabajar: Saxon
#   transforma un XML mínimo, pandoc convierte una línea, etc.
#
# CÓMO SE PIDE LA CONTRASEÑA
#   Con pkexec, que abre una ventana gráfica: con sudo, la línea «[sudo]
#   contraseña para...» se pierde entre los mensajes de la terminal. Todo lo
#   que se puede hacer como usuario común se hace antes (control y descargas)
#   y pkexec se llama UNA vez. pkexec limpia el entorno (sin el HOME del
#   usuario): la parte de root no toca ~/.gbpublisher. Verificado en el
#   TerminalView de FMain (Mint 22): la ventana aparece, la salida de root se
#   ve en la terminal, 0 al autenticar y 126 al cerrar la ventana.
#
# USO
#   integridad.sh                        control y reparación (usuario común)
#   integridad.sh --instalar <dir> <c>…  parte de root; la llama pkexec desde
#                                        este mismo script. <dir> tiene las
#                                        descargas; <c> son los componentes
#
# SALIDA (comun.sh, SC-53): 0 todo en orden; 1 algo quedó sin resolver.
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. LO QUE SE CONGELA: ORIGEN Y HUELLAS ---
# CADA HUELLA SE VERIFICÓ EL 18/11/2026 CONTRA LA INSTALACIÓN DE TRABAJO Y,
# DONDE LO HAY, CONTRA UN TERCERO (FLATHUB EN veraPDF). PARA CAMBIAR DE
# VERSIÓN SE CAMBIAN LAS CUATRO COSAS JUNTAS: URL, HUELLA DE LA DESCARGA,
# HUELLA DE LO INSTALADO Y VERSIÓN ESPERADA

# SAXON-HE 12.9 (SC-52). EL ZIP TRAE EL JAR, lib/ (xmlresolver), doc/ Y
# notices/ EN LA RAÍZ. LA CADENA LLAMA A saxon-he.jar (RUTA_SAXON): EL ENLACE
# LO CREA ESTE SCRIPT
SAXON_DIR="/opt/Saxon-HE"
SAXON_JAR="saxon-he-12.9.jar"
SAXON_URL="https://github.com/Saxonica/Saxon-HE/raw/main/12/Java/SaxonHE12-9J.zip"
SAXON_ZIP_SHA="f2895bef3794112c650a158be27c39a86e88c1717ebb8e0e88067d1f07635d12"
SAXON_JAR_SHA="d07312efb12eab7b1d09c50073e28201b5c50054ae162d0e7b41a0d8ec6e6903"

# PANDOC 3.1.3, EL BINARIO OFICIAL. COMPARADO CON EL DE apt DE MINT 22 SOBRE
# LAS 15 PIEZAS DEL LIBRO DE JENSEN: MISMO XML, BYTE A BYTE
PANDOC_DIR="/opt/pandoc"
PANDOC_URL="https://github.com/jgm/pandoc/releases/download/3.1.3/pandoc-3.1.3-linux-amd64.tar.gz"
PANDOC_TGZ_SHA="74bc434908e4d858b3edbfd6271d2e9e499477837e5df1d630df4e62f113803d"
PANDOC_BIN_SHA="5a953bcbcdc7c36fcb0c263fbb09db8c7b84cfa9ca58e48e321d7edf857a7ee7"

# EPUBCHECK 4.2.6. EL ZIP TRAE TODO DENTRO DE epubcheck-4.2.6/
EPUBCHECK_DIR="/opt/epubcheck"
EPUBCHECK_VERSION="EPUBCheck v4.2.6"
EPUBCHECK_URL="https://github.com/w3c/epubcheck/releases/download/v4.2.6/epubcheck-4.2.6.zip"
EPUBCHECK_ZIP_SHA="3f73c1265cc92e3b53ffda6cd5bbeb58505b2b0c43411c26e74d8df1b193b2c0"
EPUBCHECK_JAR_SHA="e1f650010b0db7b053e74e243688bdf900cbb8df56282012cdbd472e7f821c66"

# VERAPDF 1.30.1. SU INSTALADOR ES GRÁFICO; SIN PREGUNTAS SE CORRE CON
# -options Y UN ARCHIVO DE PROPIEDADES CUYA ÚNICA CLAVE ES INSTALL_PATH (LA
# PLANTILLA QUE GENERA -options-template). /opt/verapdf ES EL PRIMER LUGAR
# DONDE LO BUSCAN LAS SALIDAS (verapdf_comun.sh, m_XML.ValidarPDFA)
VERAPDF_DIR="/opt/verapdf"
VERAPDF_VERSION="veraPDF 1.30.1"
VERAPDF_URL="https://software.verapdf.org/releases/1.30/verapdf-greenfield-1.30.1-installer.zip"
VERAPDF_ZIP_SHA="9f03fc5da454348329f4054256351aa6c6a91683329978e8294f21fe8a5d7abc"

# PACKTOOLS 4.18.2: LO INSTALA instalar_packtools.sh, QUE TIENE LA LISTA DE
# VERSIONES DE SUS DEPENDENCIAS
PACKTOOLS_DIR="/opt/packtools"
PACKTOOLS_VERSION="4.18.2"

COMPONENTES=(saxon pandoc epubcheck verapdf packtools)

# --- 2. CÓMO SE NOMBRA CADA UNO ANTE EL USUARIO ---
# EN LENGUAJE DE OFICIO: QUÉ DEJA DE PODER HACERSE, NO QUÉ ARCHIVO FALTA
declare -A NOMBRE=(
    [saxon]="Saxon-HE 12.9"
    [pandoc]="pandoc 3.1.3"
    [epubcheck]="epubcheck 4.2.6"
    [verapdf]="veraPDF 1.30.1"
    [packtools]="packtools 4.18.2"
)
declare -A SIN_ESTO=(
    [saxon]="sin esto no se genera ninguna salida: XML, HTML, PDF ni EPUB"
    [pandoc]="sin esto los .md no se convierten en el XML canónico"
    [epubcheck]="sin esto los EPUB se generan pero no se validan"
    [verapdf]="sin esto no se puede comprobar que los PDF cumplan PDF/A"
    [packtools]="sin esto no se validan los paquetes para SciELO"
)

# ============================================================================
# Función   : huella
# Propósito : Imprime el sha256 de un archivo, o nada si no se puede leer.
# ============================================================================
huella() {
    sha256sum "$1" 2>/dev/null | cut -d ' ' -f 1
}

# ============================================================================
# Funciones : controlar_<componente>
# Propósito : Responden si el componente está en su versión y funciona.
#             Dejan en MOTIVO, para la terminal, por qué no.
# Retorna   : 0 en orden; 1 no
# Nota      : CORREN COMO USUARIO COMÚN, QUE ES COMO LOS USA LA CADENA: UN
#             ARCHIVO QUE SOLO root PUEDE LEER FALLA ACÁ Y NO EN UNA SALIDA
# ============================================================================
controlar_saxon() {
    local jar salida
    if [[ ! -e "$SAXON_DIR/saxon-he.jar" ]]; then
        MOTIVO="no está $SAXON_DIR/saxon-he.jar"
        return 1
    fi
    # EL ENLACE TIENE QUE LLEVAR A LA VERSIÓN DEL PROYECTO
    jar="$(readlink -f "$SAXON_DIR/saxon-he.jar")"
    if [[ "$(huella "$jar")" != "$SAXON_JAR_SHA" ]]; then
        MOTIVO="saxon-he.jar no es la versión 12.9 (lleva a ${jar##*/})"
        return 1
    fi
    # Y TIENE QUE TRANSFORMAR: ESTO PRUEBA TAMBIÉN JAVA Y lib/
    printf '<a/>' > "$PRUEBAS/t.xml"
    printf '<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:template match="/">ok</xsl:template></xsl:stylesheet>' > "$PRUEBAS/t.xsl"
    salida="$(timeout 60 java -jar "$SAXON_DIR/saxon-he.jar" -s:"$PRUEBAS/t.xml" -xsl:"$PRUEBAS/t.xsl" 2>&1)"
    if [[ "$salida" != *">ok"* ]]; then
        MOTIVO="Saxon no transformó el XML de prueba"
        return 1
    fi
    return 0
}

controlar_pandoc() {
    local bin="$PANDOC_DIR/bin/pandoc" salida
    if [[ ! -x "$bin" ]]; then
        MOTIVO="no está $bin"
        return 1
    fi
    if [[ "$(huella "$bin")" != "$PANDOC_BIN_SHA" ]]; then
        MOTIVO="$bin no es el binario oficial de la 3.1.3"
        return 1
    fi
    salida="$(printf '*a*\n' | timeout 60 "$bin" -f markdown -t docbook5 2>&1)"
    if [[ "$salida" != *"<emphasis>a</emphasis>"* ]]; then
        MOTIVO="pandoc no convirtió el texto de prueba"
        return 1
    fi
    # colorear_codigo.sh LO USA COMO INTÉRPRETE DE Lua
    if [[ "$(timeout 60 "$bin" lua -e 'print("ok")' 2>&1)" != "ok" ]]; then
        MOTIVO="«pandoc lua» no responde"
        return 1
    fi
    return 0
}

controlar_epubcheck() {
    local jar="$EPUBCHECK_DIR/epubcheck.jar" salida
    if [[ ! -f "$jar" ]]; then
        MOTIVO="no está $jar"
        return 1
    fi
    if [[ "$(huella "$jar")" != "$EPUBCHECK_JAR_SHA" ]]; then
        MOTIVO="$jar no es la versión 4.2.6"
        return 1
    fi
    # SIN ARCHIVO, epubcheck IGUAL CARGA SUS lib/ E IMPRIME LA VERSIÓN
    salida="$(timeout 60 java -jar "$jar" --version 2>&1)"
    if [[ "$salida" != *"$EPUBCHECK_VERSION"* ]]; then
        MOTIVO="epubcheck no arrancó"
        return 1
    fi
    return 0
}

controlar_verapdf() {
    local bin="$VERAPDF_DIR/verapdf" salida
    if [[ ! -x "$bin" ]]; then
        MOTIVO="no está $bin"
        return 1
    fi
    salida="$(timeout 120 "$bin" --version 2>&1)"
    if [[ "$salida" != *"$VERAPDF_VERSION"* ]]; then
        MOTIVO="no responde como $VERAPDF_VERSION"
        return 1
    fi
    return 0
}

controlar_packtools() {
    local py="$PACKTOOLS_DIR/bin/python" salida
    if [[ ! -x "$py" ]]; then
        MOTIVO="no está el entorno $PACKTOOLS_DIR"
        return 1
    fi
    # TRAS UN CAMBIO DEL PYTHON DEL SISTEMA EL ENTORNO QUEDA ROTO: FALLA ACÁ
    # Y SE RECONSTRUYE, QUE ES LO QUE CORRESPONDE
    # stderr AFUERA: UN AVISO DE PYTHON NO TIENE QUE PARECER OTRA VERSIÓN
    salida="$(timeout 120 "$py" -I -c 'import packtools.version as v; from packtools import catalogs, stylechecker; print(v.__version__)' 2>/dev/null)"
    if [[ "$salida" != "$PACKTOOLS_VERSION" ]]; then
        MOTIVO="el entorno no carga packtools $PACKTOOLS_VERSION"
        return 1
    fi
    return 0
}

# ============================================================================
# Función   : controlar_todo
# Propósito : Controla cada componente e informa una línea por cada uno.
#             Deja en FALTAN los que fallaron.
# ============================================================================
controlar_todo() {
    local c
    FALTAN=()
    for c in "${COMPONENTES[@]}"; do
        MOTIVO=""
        if "controlar_$c"; then
            ok "${NOMBRE[$c]}"
        else
            fallo "${NOMBRE[$c]}: ${SIN_ESTO[$c]}"
            tenue "  ($MOTIVO)"
            FALTAN+=("$c")
        fi
    done
}

# ============================================================================
# Función   : descargar
# Propósito : Baja un archivo y controla su huella antes de aceptarlo.
# Parámetros: $1 URL  $2 destino  $3 sha256 esperado  $4 nombre legible
# ============================================================================
descargar() {
    local url="$1" destino="$2" esperada="$3" nombre="$4"
    local codigo
    tenue "bajando $nombre"
    curl -fL --retry 2 --connect-timeout 20 --max-time 900 --progress-bar -o "$destino" "$url"
    codigo=$?
    # SIN RED, curl DICE «Could not resolve host» Y SALE CON 6, 7 O 28: PARA
    # ESTOS USUARIOS ESO TIENE QUE LEERSE COMO «NO HAY INTERNET»
    case "$codigo" in
        0)         ;;
        6|7|28|35) morir "No hay conexión a internet. Conectate y volvé a usar «Controlar integridad del sistema»." ;;
        *)         morir "No se pudo bajar $nombre (curl, código $codigo). Volvé a intentar más tarde." ;;
    esac
    if [[ "$(huella "$destino")" != "$esperada" ]]; then
        morir "Lo que se bajó de $nombre no es el archivo esperado (la huella no coincide). No se instaló nada."
    fi
    ok "$nombre bajado y verificado"
}

# ============================================================================
# Función   : dejar_de_root
# Propósito : Lo que se instala en /opt queda de root y legible por todos: la
#             cadena corre como usuario común y nadie lo cambia sin permiso.
#             Se aplica al terminar CADA componente: si uno posterior falla,
#             los anteriores ya quedaron utilizables.
# Parámetros: $1 carpeta instalada
# ============================================================================
dejar_de_root() {
    chown -R root:root "$1"
    chmod -R a+rX "$1"
}

# ============================================================================
# Funciones : instalar_<componente>
# Propósito : Parte de root. Reemplazan la carpeta del componente por una
#             instalación limpia desde la descarga, que se vuelve a verificar.
# Nota      : SE REEMPLAZA ENTERA Y NO SE PARCHEA: UNA INSTALACIÓN A MANO A
#             MEDIAS (EL JAR SIN SU ENLACE) ES JUSTO LO QUE SE QUIERE QUITAR.
#             SOLO LLEGA ACÁ UN COMPONENTE QUE FALLÓ SU CONTROL.
# ============================================================================
instalar_saxon() {
    rm -rf -- "${SAXON_DIR:?}"
    mkdir -p "$SAXON_DIR"
    unzip -q -o "$DESCARGAS/saxon.zip" -d "$SAXON_DIR" || morir "No se pudo descomprimir Saxon-HE"
    # RELATIVO: SIGUE VALIENDO SI ALGUIEN MUEVE LA CARPETA
    ln -sfn "$SAXON_JAR" "$SAXON_DIR/saxon-he.jar"
    dejar_de_root "$SAXON_DIR"
    ok "Saxon-HE 12.9 en $SAXON_DIR, con el enlace saxon-he.jar"
}

instalar_pandoc() {
    rm -rf -- "${PANDOC_DIR:?}"
    mkdir -p "$PANDOC_DIR"
    # EL TARBALL TRAE TODO DENTRO DE pandoc-3.1.3/: QUEDA /opt/pandoc/bin/pandoc
    tar -xzf "$DESCARGAS/pandoc.tar.gz" -C "$PANDOC_DIR" --strip-components=1 ||
        morir "No se pudo descomprimir pandoc"
    dejar_de_root "$PANDOC_DIR"
    ok "pandoc 3.1.3 en $PANDOC_DIR"
}

instalar_epubcheck() {
    local tmp
    tmp="$(mktemp -d)"
    unzip -q -o "$DESCARGAS/epubcheck.zip" -d "$tmp" || morir "No se pudo descomprimir epubcheck"
    rm -rf -- "${EPUBCHECK_DIR:?}"
    mv "$tmp/epubcheck-4.2.6" "$EPUBCHECK_DIR"
    rm -rf -- "$tmp"
    dejar_de_root "$EPUBCHECK_DIR"
    ok "epubcheck 4.2.6 en $EPUBCHECK_DIR"
}

instalar_verapdf() {
    local tmp salida
    tmp="$(mktemp -d)"
    unzip -q -o "$DESCARGAS/verapdf.zip" -d "$tmp" || morir "No se pudo descomprimir veraPDF"
    printf 'INSTALL_PATH=%s\n' "$VERAPDF_DIR" > "$tmp/vera.properties"
    rm -rf -- "${VERAPDF_DIR:?}"
    tenue "corriendo el instalador de veraPDF"
    # EL INSTALADOR HABLA MUCHO: SOLO SE MUESTRA SI FALLA
    if ! salida="$(cd "$tmp/verapdf-greenfield-1.30.1" && ./verapdf-install -options "$tmp/vera.properties" 2>&1)"; then
        mostrar_cola "$salida"
        rm -rf -- "$tmp"
        morir "El instalador de veraPDF falló"
    fi
    rm -rf -- "$tmp"
    dejar_de_root "$VERAPDF_DIR"
    ok "veraPDF 1.30.1 en $VERAPDF_DIR"
}

instalar_packtools() {
    GBP_ANIDADO=1 bash "$DIR_ENGINE/instalar_packtools.sh" ||
        morir "No se pudo instalar packtools"
}

# ============================================================================
# Función   : modo_root
# Propósito : La parte que corre como root, por pkexec. Verifica de nuevo las
#             descargas (entre la bajada y este momento pasó una ventana de
#             contraseña) e instala cada componente pedido.
# Parámetros: $1 carpeta de descargas; $2… componentes
# ============================================================================
modo_root() {
    local c
    (( EUID == 0 )) || morir "La instalación tiene que correr como administrador."
    DESCARGAS="$1"
    shift

    for c in "$@"; do
        case "$c" in
            saxon)     [[ "$(huella "$DESCARGAS/saxon.zip")" == "$SAXON_ZIP_SHA" ]] ;;
            pandoc)    [[ "$(huella "$DESCARGAS/pandoc.tar.gz")" == "$PANDOC_TGZ_SHA" ]] ;;
            epubcheck) [[ "$(huella "$DESCARGAS/epubcheck.zip")" == "$EPUBCHECK_ZIP_SHA" ]] ;;
            verapdf)   [[ "$(huella "$DESCARGAS/verapdf.zip")" == "$VERAPDF_ZIP_SHA" ]] ;;
            packtools) true ;;
            *)         morir "Componente desconocido: $c" ;;
        esac || morir "La descarga de ${NOMBRE[$c]} cambió antes de instalarse. No se instaló nada."
    done

    for c in "$@"; do
        "instalar_$c"
    done

    exit "$SALIDA_OK"
}

# ============================================================================
# EJECUCIÓN
# ============================================================================

# --- 3. LA PARTE DE root ---
if [[ "${1:-}" == "--instalar" ]]; then
    shift
    (( $# >= 2 )) || morir "Uso: $(basename "$0") --instalar <carpeta> <componente>…"
    modo_root "$@"
fi

encabezado "Integridad del sistema"

# --- 4. LO QUE ESTE SCRIPT NECESITA PARA TRABAJAR ---
# TODO ES DEPENDENCIA DEL .deb: SI FALTA, LA INSTALACIÓN DE gbpublisher ESTÁ
# INCOMPLETA Y ESTO NO LO PUEDE ARREGLAR
paso "Herramientas del sistema"
faltan_base=()
for comando in java curl unzip tar sha256sum timeout pkexec python3; do
    command -v "$comando" >/dev/null 2>&1 || faltan_base+=("$comando")
done
if (( ${#faltan_base[@]} > 0 )); then
    morir "Faltan herramientas que instala gbpublisher: ${faltan_base[*]}. Reinstalá el paquete .deb de gbpublisher."
fi
ok "Java, curl, unzip y Python presentes"

# CARPETA DE TRABAJO: PRUEBAS Y DESCARGAS. LA BORRA LA SALIDA DEL SCRIPT,
# TAMBIÉN SI FALLA. LA PARTE DE root SOLO LA LEE
TRABAJO="$(mktemp -d /tmp/gbp-integridad.XXXXXX)" || morir "No se pudo crear una carpeta temporal"
trap 'rm -rf -- "$TRABAJO"' EXIT
PRUEBAS="$TRABAJO/pruebas"
mkdir -p "$PRUEBAS"

# --- 5. CONTROL ---
paso "Herramientas de producción"
controlar_todo

if (( ${#FALTAN[@]} == 0 )); then
    echo
    ok "Todo en orden: no hay nada que instalar."
    terminar
fi

# --- 6. DESCARGAS, COMO USUARIO COMÚN ---
paso "Descargas"
for c in "${FALTAN[@]}"; do
    case "$c" in
        saxon)     descargar "$SAXON_URL" "$TRABAJO/saxon.zip" "$SAXON_ZIP_SHA" "Saxon-HE 12.9" ;;
        pandoc)    descargar "$PANDOC_URL" "$TRABAJO/pandoc.tar.gz" "$PANDOC_TGZ_SHA" "pandoc 3.1.3" ;;
        epubcheck) descargar "$EPUBCHECK_URL" "$TRABAJO/epubcheck.zip" "$EPUBCHECK_ZIP_SHA" "epubcheck 4.2.6" ;;
        verapdf)   descargar "$VERAPDF_URL" "$TRABAJO/verapdf.zip" "$VERAPDF_ZIP_SHA" "veraPDF 1.30.1" ;;
        packtools) tenue "packtools se baja durante la instalación (GitHub y PyPI)" ;;
    esac
done
# --- 7. INSTALACIÓN: UNA SOLA VENTANA DE CONTRASEÑA ---
paso "Instalación"
echo
printf '  %s➜ Se abre una ventana que pide tu contraseña. Escribila y aceptá.%s\n' "$C_AVISO" "$C_RESET"
echo
pkexec /bin/bash "$DIR_ENGINE/integridad.sh" --instalar "$TRABAJO" "${FALTAN[@]}"
codigo=$?
case "$codigo" in
    0)   ;;
    126) morir "Se cerró la ventana de la contraseña: no se instaló nada. Cuando quieras, volvé a usar «Controlar integridad del sistema»." ;;
    127) morir "No se obtuvo permiso de administrador: no se instaló nada. La contraseña tiene que ser la de un usuario administrador de esta computadora." ;;
    *)   morir "La instalación no terminó (código $codigo). El motivo está más arriba." ;;
esac

# --- 8. CONTROL FINAL: LO MISMO QUE AL PRINCIPIO ---
paso "Control final"
controlar_todo
if (( ${#FALTAN[@]} > 0 )); then
    morir "Quedaron herramientas sin resolver. Copiá lo que muestra la terminal y enviáselo a quien te da soporte."
fi
echo
ok "Todo en orden: las herramientas de producción quedaron instaladas."
terminar
