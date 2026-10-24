# Funciones compartidas por los scripts de engine/ — gbpublisher
# ============================================================================
# SE CARGA CON source DESDE CADA SCRIPT; NO SE EJECUTA SOLO.
#
# Vive en /usr/share/gbpublisher/engine/ junto a los scripts que la usan.
# Es infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# EL BLOQUE DE SALIDA —COLORES, REGLA, titulo, paso, ok, aviso, tenue, morir—
# ES EL DE compilar_pdf_libro.sh, EXTRAÍDO SIN CAMBIOS DE FORMA. EXISTE PARA
# QUE TODOS LOS SCRIPTS HABLEN IGUAL EN LA TERMINAL: SI CADA UNO TUVIERA SU
# COPIA, DIVERGIRÍAN. compilar_pdf_libro.sh YA USA ESTE ARCHIVO: NO QUEDA
# NINGUNA COPIA PROPIA.
#
# CONTRATO DE SALIDA CON GAMBAS
#   0  SALIDA_OK       el producto se generó y todo lo verificado dio bien
#   3  SALIDA_AVISOS   el producto se generó, pero algo merece revisión
#                      (validación de esquema, validación HTML, un recurso
#                      declarado que no está). Gambas lo informa distinto.
#   1  SALIDA_FALLO    no se generó el producto. morir() sale con este código
#   cualquier otro     lo decide bash: 124 es un timeout, 130 un Ctrl+C
# ============================================================================

# --- 1. COLORES (SOLO SI LA SALIDA ES UNA TERMINAL) ---
if [[ -t 1 ]]; then
    C_TITULO=$'\033[1;38;2;125;211;252m'
    C_OK=$'\033[38;2;134;239;172m'
    C_AVISO=$'\033[38;2;250;204;21m'
    C_ERROR=$'\033[1;38;2;248;113;113m'
    C_TENUE=$'\033[38;2;148;163;184m'
    C_RESET=$'\033[0m'
else
    C_TITULO="" ; C_OK="" ; C_AVISO="" ; C_ERROR="" ; C_TENUE="" ; C_RESET=""
fi

REGLA="════════════════════════════════════════════════════════════════════"

# --- 2. CÓDIGOS DE SALIDA ---
SALIDA_OK=0
SALIDA_FALLO=1
SALIDA_AVISOS=3

# CANTIDAD DE AVISOS EMITIDOS. terminar() LA USA PARA ELEGIR EL CÓDIGO
AVISOS=0

# --- 3. RUTAS COMUNES ---
# LA RUTA DE SAXON DEBE COINCIDIR CON m_Constantes.RUTA_SAXON. SE PUEDE
# SOBRESCRIBIR CON LA VARIABLE GBP_SAXON PARA PROBAR A MANO OTRA VERSIÓN
RUTA_SAXON="${GBP_SAXON:-/opt/Saxon-HE/saxon-he.jar}"

# COPIA LOCAL DE TRABAJO: ES LA QUE LA APLICACIÓN LEE (SC-11)
DIR_GBP_LOCAL="$HOME/.gbpublisher"

# --- 3b. LAS CADENAS DE FILTROS ---
# LIBRO: LA DE generar_canonicos_capitulos.sh Y DE vista_cuadro.sh (SC-67).
# EL ORDEN ES EL QUE FIJABA m_XML.GenerarBodyCapituloXML, CON
# SUS RAZONES (RC-DB-07, SC-35, SC-39, SC-41, SC-42, SC-43, SC-49, SC-61, SC-62, SC-63, SC-65, SC-66):
#   0° cuadro-leer              TRAE EL ARCHIVO DE CADA CUADRO (SC-66) DE
#      cuadros/ (-M gb-proyecto). PRIMERO: SU CONTENIDO PASA ASÍ POR TODOS
#      LOS FILTROS. FRENA EL VIEJO ::: {.table}
#   1° guillemets-to-quoted-db  « » A Quoted. ANTES QUE fenced-divs, QUE
#      SERIALIZA LOS DIVS CON pandoc.write Y DESPUÉS NO QUEDAN Str QUE PROCESAR
#   2° volada                   n\sptext{o} A «n.» Y <superscript
#      role="volada"> (SC-62). ANTES DE cite-to-biblioref-db, QUE SERIALIZA
#      LAS NOTAS CON pandoc.write: UNA \sptext QUE LLEGUE AHÍ SIN TRADUCIR
#      LA DESCARTA EL ESCRITOR DocBook (MEDIDO: «la 2 edición»)
#   3° corte-titulo             EL \\ DE UN TÍTULO A <?gb-corte?> (SC-63). CON
#      volada, ANTES DE LOS FILTROS QUE SERIALIZAN
#   4° cifras                   \num, \SI Y \SIrange A <phrase role="cantidad">
#      (SC-65). ANTES DE LOS FILTROS QUE SERIALIZAN, POR LA MISMA RAZÓN
#      (GV-116). LA PALABRA DEL RANGO SALE DE -M gb-idioma-pieza, QUE ES
#      EL IDIOMA DEL CAPÍTULO (NO gb-idioma: VER conversacion)
#   5° cite-to-biblioref-db     CITAS BIBLIOGRÁFICAS
#   6° dos-partes               EPÍGRAFES {texto}{atribución}; FRENA SI UNO
#      ESTÁ MAL FORMADO
#   7° espacio-vertical         FICHA <?gb-espacio …?>; ANTES DE fenced-divs,
#      QUE NO CONOCE EL BLOQUE espaciov
#   8° alinear                  FICHA <?gb-alinear …?> AL COMIENZO DE CADA
#      PÁRRAFO (SC-61); ANTES DE fenced-divs, QUE NO CONOCE LOS BLOQUES
#      alinear-izq, alinear-centro Y alinear-der
#   9° recuadros                DESPUÉS DE dos-partes, QUE PARTE EL recuadrob
#  10° codigo                   <programlisting>; ANTES DE fenced-divs, QUE
#      ARMA EL <example role="listado">
#  11° conversacion             ANTES DE fenced-divs, QUE ARMA EL <qandaset>.
#      SIN -M gb-idioma: LA ETIQUETA LA PONE LA HOJA SEGÚN xml:lang
#  12° verso                    DESPUÉS DE dos-partes, ANTES DE fenced-divs
#  13° cuadro-armar             ESCRIBE LA TABLA CALS DEL CUADRO (SC-66).
#      DESPUÉS DE LAS CITAS Y LAS CIFRAS; ANTES DE fenced-divs, QUE
#      SERIALIZA LOS BLOQUES QUE CONTIENEN A OTROS
#  14° fenced-divs-to-elements-db  AL FINAL
FILTROS_LIBRO=(
    cuadro-leer.lua
    guillemets-to-quoted-db.lua
    volada.lua
    corte-titulo.lua
    cifras.lua
    cite-to-biblioref-db.lua
    dos-partes.lua
    espacio-vertical.lua
    alinear.lua
    recuadros.lua
    codigo.lua
    conversacion.lua
    verso.lua
    cuadro-armar.lua
    fenced-divs-to-elements-db.lua
)

# REVISTA: LA DE vista_cuadro.sh. ES GEMELA DE LA QUE ARMA
# m_XML.GenerarBodyXML, CON SUS RAZONES EN EL APARTADO 4 DE ESA FUNCIÓN: LA
# CADENA DE LA REVISTA TODAVÍA VIVE EN GAMBAS (SC-13). UN CAMBIO EN UNA VA
# EN LA OTRA HASTA QUE SE MUDE A engine/
FILTROS_REVISTA=(
    cuadro-leer.lua
    guillemets-to-quoted-db.lua
    quoted-a-nivel-jats.lua
    dos-partes.lua
    unwrap-structural-divs.lua
    espacio-vertical.lua
    alinear.lua
    volada.lua
    corte-titulo.lua
    cifras.lua
    recuadros.lua
    codigo.lua
    conversacion.lua
    verso.lua
    cite-to-xref.lua
    cuadro-armar.lua
)

# --- 4. FUNCIONES DE SALIDA ---
titulo() { printf '%s%s%s\n' "$C_TITULO" "$1" "$C_RESET"; }
paso()   { printf '\n%s→ %s%s\n' "$C_TITULO" "$1" "$C_RESET"; }
ok()     { printf '  %s✓%s %s\n' "$C_OK" "$C_RESET" "$1"; }
tenue()  { printf '  %s%s%s\n' "$C_TENUE" "$1" "$C_RESET"; }

# A DIFERENCIA DE LA COPIA DEL PDF, ESTE aviso CUENTA: UN AVISO EMITIDO TIENE
# QUE LLEGAR A GAMBAS COMO CÓDIGO 3, NO QUEDAR SOLO EN LA TERMINAL
aviso() {
    AVISOS=$((AVISOS + 1))
    printf '  %s⚠%s %s\n' "$C_AVISO" "$C_RESET" "$1"
}

morir() {
    printf '\n%s✗ %s%s\n' "$C_ERROR" "$1" "$C_RESET" >&2
    exit "$SALIDA_FALLO"
}

# ============================================================================
# Función   : encabezado
# Propósito : Imprime el recuadro de título del script.
# Nota      : UN SCRIPT QUE LLAMA A OTRO EXPORTA GBP_ANIDADO=1. EL LLAMADO SE
#             PRESENTA ENTONCES COMO UN PASO MÁS DEL LLAMADOR, Y NO COMO UN
#             SEGUNDO RECUADRO EN MEDIO DE LA SALIDA.
# ============================================================================
encabezado() {
    if [[ -n "${GBP_ANIDADO:-}" ]]; then
        paso "$1"
        return
    fi
    echo
    titulo "$REGLA"
    titulo "  $1"
    titulo "$REGLA"
}

# ============================================================================
# Función   : requerir_comandos
# Propósito : Aborta si falta alguno de los ejecutables, nombrándolos todos.
# Nota      : command -v Y NO which: EL PRIMERO ES BUILTIN DE POSIX sh, EL
#             SEGUNDO VIVE EN debianutils Y PUEDE NO ESTAR (GV-07).
# ============================================================================
requerir_comandos() {
    local faltan=() c
    for c in "$@"; do
        command -v "$c" >/dev/null 2>&1 || faltan+=("$c")
    done
    if (( ${#faltan[@]} > 0 )); then
        morir "Faltan herramientas del sistema: ${faltan[*]}"
    fi
}

# ============================================================================
# Función   : bien_formado
# Propósito : Responde si un archivo XML está bien formado. Silenciosa.
# ============================================================================
bien_formado() {
    xmllint --noout "$1" >/dev/null 2>&1
}

# ============================================================================
# Función   : estilo_canonico
# Propósito : El estilo de cita que declara el canónico de una pieza: el
#             <bibliomisc role="csl-style"> de su <info> (SC-57). Lo escribe
#             m_XML.GenerarInfoCapituloXML.
# Parámetros: $1 ruta del canónico
# Retorna   : imprime el valor; nada si el canónico no lo declara
# Nota      : SOLO EL <info> DE LA RAÍZ: UNA SECCIÓN TAMBIÉN PUEDE TENER
#             <info>. local-name() PORQUE EL CANÓNICO ESTÁ EN EL ESPACIO DE
#             NOMBRES DE DocBook
# ============================================================================
estilo_canonico() {
    xmllint --xpath 'string(/*/*[local-name()="info"]/*[local-name()="bibliomisc"][@role="csl-style"][1])' "$1" 2>/dev/null
}

# ============================================================================
# Función   : carpeta_de_pieza
# Propósito : La carpeta del .md de una pieza, según el prefijo de su
#             nombre_archivo: fm- front-matter, a- articulos, bm- back-matter.
# Parámetros: $1 nombre_archivo (a-02-metodologia)
# Retorna   : imprime la carpeta y devuelve 0; con un prefijo no reconocido
#             no imprime nada y devuelve 1
# Nota      : ÚNICO LUGAR DE ESTA REGLA EN engine/. LA USAN
#             generar_canonicos_capitulos.sh Y, POR avisar_md_posterior,
#             preparar_latex_libro.sh Y ensamblar_libro.sh: SI CAMBIA UNA
#             CARPETA, CAMBIA ACÁ
# ============================================================================
carpeta_de_pieza() {
    case "$1" in
        fm-*) printf '%s\n' "front-matter" ;;
        a-*)  printf '%s\n' "articulos" ;;
        bm-*) printf '%s\n' "back-matter" ;;
        *)    return 1 ;;
    esac
}

# ============================================================================
# Función   : avisar_md_posterior
# Propósito : Avisa si el .md de una pieza es posterior a su canónico: el
#             canónico no tiene los últimos cambios y la salida los pierde
#             sin ningún error.
# Parámetros: $1 nombre_archivo  $2 ruta del canónico
# Retorna   : siempre 0; el aviso lo cuenta aviso()
# Nota      : USA DIR_PROYECTO, QUE DEFINE CADA SCRIPT.
#             POR FECHA DE MODIFICACIÓN: UN GUARDADO SIN CAMBIOS REALES
#             TAMBIÉN AVISA. SOLO MIRA EL .md: UN CAMBIO EN LA BASE QUE
#             LLEGA AL CANÓNICO POR tmp/info-*.xml O tmp/biblio-*.xml NO SE
#             DETECTA. SIN .md O CON PREFIJO NO RECONOCIDO NO AVISA: ESO LO
#             INFORMA LA GENERACIÓN DEL CANÓNICO
# ============================================================================
avisar_md_posterior() {
    local carpeta md
    carpeta="$(carpeta_de_pieza "$1")" || return 0
    md="$DIR_PROYECTO/$carpeta/$1.md"
    # EL -f PRIMERO: SIN .md NO HAY NADA QUE COMPARAR
    if [[ -f "$md" && "$md" -nt "$2" ]]; then
        aviso "$carpeta/$1.md es posterior a su canónico: regenerá el canónico"
    fi
    return 0
}

# ============================================================================
# Función   : mostrar_cola
# Propósito : Imprime las últimas líneas de una salida capturada, sangradas.
#             SIN LA PILA DE LUA: CUANDO UN FILTRO FRENA, PANDOC AGREGA
#             DESPUÉS DEL MENSAJE UNA O DOS «stack traceback:» QUE AL EDITOR
#             NO LE DICEN NADA Y QUE, CON LA COLA, DEJABAN EL MOTIVO FUERA
#             DE LA PANTALLA (MEDIDO CON pandoc 3.1.3, cifras.lua: 20 LÍNEAS,
#             EL MOTIVO EN LA 3.ª). SE CORTA DESDE LA PRIMERA.
# Parámetros: $1 texto; $2 cantidad de líneas (15 si se omite)
# ============================================================================
mostrar_cola() {
    [[ -n "$1" ]] || return 0
    printf '%s\n' "$1" | sed '/^[[:space:]]*stack traceback:/,$d' \
        | tail -"${2:-15}" | sed 's/^/     /'
}

# ============================================================================
# Función   : terminar
# Propósito : Sale con SALIDA_OK o SALIDA_AVISOS según se haya avisado algo.
#             ES LA ÚNICA SALIDA NORMAL DE UN SCRIPT: ASÍ NINGUNO PUEDE
#             OLVIDARSE DE INFORMAR QUE HUBO AVISOS.
# ============================================================================
terminar() {
    if (( AVISOS > 0 )); then
        exit "$SALIDA_AVISOS"
    fi
    exit "$SALIDA_OK"
}
