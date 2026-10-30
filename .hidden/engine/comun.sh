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

# LA LISTA DE ABREVIATURAS DEL LECTOR (SC-68): pandoc PONE UN ESPACIO DURO
# DETRÁS DE CADA UNA (pág. 22, cap. 3, n.º 5). REEMPLAZA LA LISTA QUE TRAE
# PANDOC, QUE ES INGLESA (GV-133). VA CON --abbreviations EN TODO LECTOR
# QUE PRODUCE UNA SALIDA; LA MISMA RUTA USA GAMBAS (m_Constantes)
RUTA_ABREVIATURAS="$DIR_GBP_LOCAL/filters/abreviaturas-espacio-fijo.txt"

# --- 3b. LAS CADENAS DE FILTROS ---
# LIBRO: LA DE generar_canonicos_capitulos.sh Y DE vista_cuadro.sh (SC-67).
# EL ORDEN ES EL QUE FIJABA m_XML.GenerarBodyCapituloXML, CON
# SUS RAZONES (RC-DB-07, SC-35, SC-39, SC-41, SC-42, SC-43, SC-49, SC-61, SC-62, SC-63, SC-65, SC-66, SC-77):
#   0° cuadro-leer              TRAE EL ARCHIVO DE CADA CUADRO (SC-66) DE
#      cuadros/ (-M gb-proyecto). PRIMERO: SU CONTENIDO PASA ASÍ POR TODOS
#      LOS FILTROS. FRENA EL VIEJO ::: {.table}
#  0b° espacio-fijo             ¬ A ESPACIO DURO (SC-68). DESPUÉS DE
#      cuadro-leer, PARA ALCANZAR EL TEXTO DEL CUADRO; ANTES DE TODO
#      FILTRO QUE SERIALIZA
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
#  4b° indice                   \index[…]{…} A <indexterm> (SC-77). ANTES DE
#      cite-to-biblioref-db, QUE SERIALIZA LAS NOTAS: UNA MARCA QUE LLEGUE
#      AHÍ SIN TRADUCIR LA DESCARTA EL ESCRITOR DocBook (GV-116). SOLO EN
#      EL LIBRO: LAS REVISTAS NO USAN ÍNDICES
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
    espacio-fijo.lua
    guillemets-to-quoted-db.lua
    volada.lua
    corte-titulo.lua
    cifras.lua
    indice.lua
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
    espacio-fijo.lua
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
# IMÁGENES PARA PANTALLA (EPUB Y HTML)
# ----------------------------------------------------------------------------
# EL PDF USA EL ORIGINAL DE media/. EL EPUB Y EL HTML LLEVAN SOLO LAS IMÁGENES
# QUE USAN, Y UNA COPIA REDUCIDA CUANDO EL ORIGINAL SUPERA EL TOPE O NO ESTÁ
# EN sRGB. EN PANTALLA NO CUENTAN LOS DPI SINO LOS PÍXELES: EL NAVEGADOR Y EL
# LECTOR DE EPUB IGNORAN LA DENSIDAD QUE DECLARA EL ARCHIVO.
#
# EL TOPE: 2000 px DE LADO MAYOR, Y SOLO ACHICA. CON LA GRILLA DEL HTML, LA
# COLUMNA CENTRAL MIDE UNOS 1070 px CSS EN UNA PANTALLA DE 1920; UNA PANTALLA
# DE ALTA DENSIDAD LA DUPLICA. ES UNA DECISIÓN, NO UN ESTÁNDAR (29/10/2026).
#
# LA COPIA SE ESCRIBE CON -strip: SIN ÉL, DOS CORRIDAS IGUALES DAN ARCHIVOS
# DISTINTOS, PORQUE EL PNG GUARDA LA FECHA DE CREACIÓN; CON ÉL, BYTES
# IDÉNTICOS (MEDIDO CON ImageMagick 6.9.12-98). -strip BORRA TAMBIÉN EL
# PERFIL DE COLOR, Y POR ESO ANTES SE CONVIERTE A sRGB LO QUE NO LO ES:
#   - CMYK CON PERFIL: DE SU PERFIL A sRGB
#   - CMYK SIN PERFIL: SE ASUME FOGRA39 (EL DE TEXLIVE) Y DE AHÍ A sRGB.
#     -profile sRGB SOLO, SIN PERFIL DE ORIGEN, DEJA LA IMAGEN EN CMYK (MEDIDO)
#   - RGB CON UN PERFIL QUE NO ES sRGB (ADOBE RGB, POR EJEMPLO): A sRGB
#   - ESCALA DE GRISES: NO SE TOCA
# LOS PERFILES SON LOS QUE TRAE TEXLIVE (texlive-full ES DEPENDENCIA DEL
# .deb): SE UBICAN CON kpsewhich, NO CON UNA RUTA FIJA.
#
# UNA COPIA QUE SOLO REDUCE Y PESA MÁS QUE EL ORIGINAL SE DESCARTA: VA EL
# ORIGINAL. PASA CON UN PNG DE COLORES PLANOS O YA SUAVIZADO: AL REMUESTREAR
# APARECEN TONOS INTERMEDIOS Y COMPRIME PEOR (MEDIDO: LA TAPA DE CALIFA,
# 1747×2593, PASÓ DE 1,1 MB A 1,8 MB A 2000 px; EL GRÁFICO fig-02, DE 50 KB A
# 82 KB; NINGÚN AJUSTE DE COMPRESIÓN DE PNG LO EVITA). EL TOPE EXISTE POR EL
# PESO: SI NO LO BAJA, NO SIRVE. UNA CONVERSIÓN DE COLOR NO SE DESCARTA NUNCA.
#
# LAS COPIAS QUEDAN EN tmp/pantalla/, CON LA HUELLA DEL ORIGINAL EN EL
# NOMBRE: SE REHACEN SOLO SI EL ORIGINAL CAMBIA. VERSION_PANTALLA SUBE SI
# CAMBIA LA RECETA, Y CON ELLA SE INVALIDA TODO EL CACHÉ.
# ============================================================================
TOPE_PANTALLA_PX=2000
VERSION_PANTALLA=1
PERFIL_SRGB="sRGB.icc"
PERFIL_CMYK_SUPUESTO="FOGRA39L_coated.icc"

# ============================================================================
# Función   : imagenes_canonico
# Propósito : Los nombres de las imágenes que un canónico DocBook usa: el
#             @fileref de cada imagedata, sin carpeta, sin repetir.
# Parámetros: $1 ruta del canónico
# Retorna   : imprime un nombre por línea; nada si no usa imágenes
# Nota      : local-name() PORQUE xmllint --xpath NO CONOCE LOS ESPACIOS DE
#             NOMBRES DEL DOCUMENTO (GV-22). xmllint ESCRIBE CADA ATRIBUTO
#             COMO « fileref="valor"» EN SU LÍNEA (MEDIDO, libxml 20914); SIN
#             RESULTADOS SALE CON 10 Y NO IMPRIME NADA EN stdout. EL NOMBRE
#             ES LO QUE SIGUE A LA ÚLTIMA BARRA, COMO tokenize(...)[last()] EN
#             LAS HOJAS DE SALIDA
# ============================================================================
imagenes_canonico() {
    xmllint --nonet --xpath "//*[local-name()='imagedata']/@fileref" "$1" 2>/dev/null |
        grep -oP 'fileref="\K[^"]+' | sed 's|.*/||' | sort -u
}

# ============================================================================
# Función   : copiar_imagen_pantalla
# Propósito : Copia una imagen de media/ a la salida de pantalla: tal cual si
#             no supera el tope y está en sRGB o en grises; si no, la copia
#             reducida o convertida, desde el caché.
# Parámetros: $1 original; $2 destino (archivo); $3 carpeta del caché
# Retorna   : 0 si quedó copiada, 1 si no. Deja en PANTALLA_NOTA qué se le
#             hizo o por qué no («» si se copió tal cual), para el informe,
#             y en PANTALLA_PREPARADA 1 si lo que quedó es una copia y no el
#             original
# Nota      : SOLO png Y jpg: SON LOS FORMATOS DE LAS FIGURAS (SC-75, GV-155)
#             Y DE LOS LOGOS. CUALQUIER OTRA COSA SE COPIA TAL CUAL: identify
#             SOBRE UN svg LO RASTERIZA Y DARÍA MEDIDAS QUE NO SON LAS SUYAS
# ============================================================================
copiar_imagen_pantalla() {
    local origen="$1" destino="$2" dir_cache="$3"
    local extension datos ancho alto espacio perfil lado huella cache temporal
    local srgb cmyk
    local color=0
    local receta=()
    PANTALLA_NOTA=""
    PANTALLA_PREPARADA=0

    # --- 1. LO QUE NO ES png NI jpg VA TAL CUAL ---
    extension="${origen##*.}"
    extension="${extension,,}"
    case "$extension" in
        png|jpg|jpeg) ;;
        *) cp -f "$origen" "$destino"; return ;;
    esac

    # --- 2. MEDIDAS, ESPACIO DE COLOR Y PERFIL ---
    # UNA SOLA LÍNEA: [0] ES EL PRIMER CUADRO, POR SI EL ARCHIVO TRAE VARIOS
    datos=$(identify -format '%w|%h|%[colorspace]|%[profile:icc]' "$origen[0]" 2>/dev/null) || return 1
    [[ -n "$datos" ]] || return 1
    IFS='|' read -r ancho alto espacio perfil <<< "$datos"
    lado=$(( ancho > alto ? ancho : alto ))

    # --- 3. LA RECETA: COLOR PRIMERO, TAMAÑO DESPUÉS ---
    if [[ "$espacio" == "CMYK" ]]; then
        srgb=$(kpsewhich "$PERFIL_SRGB" 2>/dev/null)
        [[ -n "$srgb" ]] || { PANTALLA_NOTA="no se encontró $PERFIL_SRGB con kpsewhich"; return 1; }
        if [[ -z "$perfil" ]]; then
            cmyk=$(kpsewhich "$PERFIL_CMYK_SUPUESTO" 2>/dev/null)
            [[ -n "$cmyk" ]] || { PANTALLA_NOTA="no se encontró $PERFIL_CMYK_SUPUESTO con kpsewhich"; return 1; }
            receta+=(-profile "$cmyk")
            PANTALLA_NOTA="CMYK sin perfil (se asume FOGRA39) → sRGB"
        else
            PANTALLA_NOTA="CMYK ($perfil) → sRGB"
        fi
        receta+=(-profile "$srgb")
        color=1
    elif [[ "$espacio" != "Gray" && -n "$perfil" && "${perfil,,}" != *srgb* ]]; then
        srgb=$(kpsewhich "$PERFIL_SRGB" 2>/dev/null)
        [[ -n "$srgb" ]] || { PANTALLA_NOTA="no se encontró $PERFIL_SRGB con kpsewhich"; return 1; }
        receta+=(-profile "$srgb")
        PANTALLA_NOTA="perfil «$perfil» → sRGB"
        color=1
    fi

    if (( lado > TOPE_PANTALLA_PX )); then
        # «>» SOLO ACHICA: UNA IMAGEN MENOR QUE EL TOPE NO SE AGRANDA
        receta+=(-resize "${TOPE_PANTALLA_PX}x${TOPE_PANTALLA_PX}>")
        PANTALLA_NOTA="${PANTALLA_NOTA:+$PANTALLA_NOTA; }${ancho}×${alto} → lado mayor ${TOPE_PANTALLA_PX}"
    fi

    # --- 4. SIN RECETA: EL ORIGINAL, BYTE POR BYTE ---
    if (( ${#receta[@]} == 0 )); then
        cp -f "$origen" "$destino"
        return
    fi

    # --- 5. LA COPIA, DESDE EL CACHÉ O NUEVA ---
    mkdir -p "$dir_cache" || return 1
    huella=$(sha256sum "$origen" | cut -d' ' -f1)
    cache="$dir_cache/$huella-v$VERSION_PANTALLA-$TOPE_PANTALLA_PX.$extension"
    if [[ ! -f "$cache" ]]; then
        # EL TEMPORAL CONSERVA LA EXTENSIÓN: convert ELIGE EL FORMATO POR ELLA
        temporal="$dir_cache/.tmp-$$.$extension"
        if ! convert "$origen[0]" "${receta[@]}" -strip "$temporal" 2>/dev/null; then
            rm -f "$temporal"
            return 1
        fi
        mv -f "$temporal" "$cache" || return 1
    fi

    # --- 6. SOLO REDUCIDA Y MÁS PESADA: VA EL ORIGINAL ---
    if (( color == 0 )) && (( $(stat -c %s "$cache") >= $(stat -c %s "$origen") )); then
        PANTALLA_NOTA="${ancho}×${alto}: reducida pesaba más que el original; va el original"
        cp -f "$origen" "$destino"
        return
    fi
    cp -f "$cache" "$destino" || return 1
    PANTALLA_PREPARADA=1
}

# ============================================================================
# Función   : estilo_canonico
# Propósito : El estilo de cita que declara el canónico de una pieza: el
#             <bibliomisc role="estilo-cita"> de su <info> (SC-57). Lo escribe
#             m_XML.GenerarInfoCapituloXML. Un canónico anterior al cambio de
#             nombre (csl-style) no lo declara: el cotejo lo hace fallar y se
#             regenera.
# Parámetros: $1 ruta del canónico
# Retorna   : imprime el valor; nada si el canónico no lo declara
# Nota      : SOLO EL <info> DE LA RAÍZ: UNA SECCIÓN TAMBIÉN PUEDE TENER
#             <info>. local-name() PORQUE EL CANÓNICO ESTÁ EN EL ESPACIO DE
#             NOMBRES DE DocBook
# ============================================================================
estilo_canonico() {
    xmllint --xpath 'string(/*/*[local-name()="info"]/*[local-name()="bibliomisc"][@role="estilo-cita"][1])' "$1" 2>/dev/null
}

# ============================================================================
# Función   : carpeta_de_pieza
# Propósito : La carpeta del .md de una pieza, según el prefijo de su
#             nombre_archivo: fm- front-matter, a- articulos, bm- back-matter.
# Parámetros: $1 nombre_archivo (a-02-metodologia)
# Retorna   : imprime la carpeta y devuelve 0; con un prefijo no reconocido
#             no imprime nada y devuelve 1
# Nota      : ÚNICO LUGAR DE ESTA REGLA EN engine/. LA USAN
#             generar_canonicos_capitulos.sh Y vigencia_canonico, QUE A SU
#             VEZ USAN ensamblar_libro.sh, preparar_latex_libro.sh Y
#             validar_canonicos.sh: SI CAMBIA UNA CARPETA, CAMBIA ACÁ
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
# Función   : vigencia_canonico
# Propósito : El estado de un canónico frente a sus archivos fuente (SC-75).
#             Las fuentes son lo que se copia DENTRO del canónico: el .md y
#             los cuadros que nombra. Cada una quedó anotada al generarlo, con
#             su huella, en una <?gb-fuente archivo="…" sha256="…"?> del
#             prólogo; el canónico del libro trae las de todos sus capítulos.
# Parámetros: $1 ruta del canónico
# Retorna   : siempre 0. El resultado queda en dos globales, para que quien
#             llama decida qué hace con él (el ensamblado frena, el validador
#             avisa):
#               VIGENCIA_ESTADO   vigente | desactualizado | huerfano |
#                                 sin_huella | ilegible
#               VIGENCIA_DETALLE  el motivo, para el editor
# Nota      : USA DIR_PROYECTO, QUE DEFINE CADA SCRIPT.
#             GLOBALES Y NO UNA SALIDA IMPRESA: CON $(…) LA FUNCIÓN CORRERÍA
#             EN UNA SUBSHELL Y NO PODRÍA DEVOLVER DOS VALORES.
#             sha256 Y NO FECHA DE MODIFICACIÓN: UNA COPIA DESDE OTRA MÁQUINA
#             CAMBIA LA FECHA SIN CAMBIAR EL TEXTO, O CONSERVA UNA FECHA VIEJA
#             CON TEXTO NUEVO.
#             LO QUE LLEGA DE LA BASE (tmp/info-*, tmp/biblio-*) NO TIENE
#             HUELLA: «vigente» QUIERE DECIR VIGENTE RESPECTO DE SUS ARCHIVOS
#             FUENTE, NO RESPECTO DE LA BASE
# ============================================================================
vigencia_canonico() {
    local canonico="$1"
    local nombre carpeta pis pi archivo huella actual
    local fuentes=0
    local problemas=()

    VIGENCIA_ESTADO=""
    VIGENCIA_DETALLE=""

    # --- A. BIEN FORMADO: SIN ESO NO HAY PI QUE LEER ---
    if ! bien_formado "$canonico"; then
        VIGENCIA_ESTADO="ilegible"
        VIGENCIA_DETALLE="el canónico está mal formado"
        return 0
    fi

    # --- B. HUÉRFANO: UNA PIEZA SIN SU .md ---
    # EL NOMBRE ES jats/c-{nombre_archivo}.xml (m_XML). EL DEL LIBRO,
    # c-libro-{base}.xml, NO TIENE .md PROPIO: SUS FUENTES SON LAS DE SUS
    # CAPÍTULOS. UN NOMBRE CON PREFIJO DESCONOCIDO TAMPOCO TIENE DE DÓNDE
    # REGENERARSE: ES HUÉRFANO
    nombre="$(basename "$canonico" .xml)"
    nombre="${nombre#c-}"
    if [[ "$nombre" != libro-* ]]; then
        if ! carpeta="$(carpeta_de_pieza "$nombre")"; then
            VIGENCIA_ESTADO="huerfano"
            VIGENCIA_DETALLE="«$nombre» no corresponde a ninguna pieza (se espera fm-, a- o bm-)"
            return 0
        fi
        if [[ ! -f "$DIR_PROYECTO/$carpeta/$nombre.md" ]]; then
            VIGENCIA_ESTADO="huerfano"
            VIGENCIA_DETALLE="no existe $carpeta/$nombre.md"
            return 0
        fi
    fi

    # --- C. LAS PI DEL PRÓLOGO ---
    # grep -o Y NO UNA PI POR LÍNEA: NO DEPENDE DE CÓMO SEPARE xmllint LOS
    # NODOS QUE DEVUELVE. EL CONJUNTO VACÍO NO ES UN ERROR: ES «SIN HUELLA»
    pis="$(xmllint --xpath '/processing-instruction("gb-fuente")' "$canonico" 2>/dev/null |
           grep -oP '<\?gb-fuente\s.*?\?>')"

    while IFS= read -r pi; do
        [[ -z "$pi" ]] && continue
        fuentes=$((fuentes + 1))

        # LA FORMA LA ESCRIBE ensamblar-capitulo-canonico.xsl: archivo
        # PRIMERO, sha256 DESPUÉS, 64 CIFRAS HEXADECIMALES
        if [[ ! "$pi" =~ archivo=\"([^\"]*)\"\ sha256=\"([0-9a-f]{64})\" ]]; then
            problemas+=("una huella ilegible: $pi")
            continue
        fi
        archivo="${BASH_REMATCH[1]}"
        huella="${BASH_REMATCH[2]}"

        # LA RUTA ES RELATIVA AL PROYECTO Y NO SALE DE ÉL
        if [[ "$archivo" == /* || "$archivo" == *..* ]]; then
            problemas+=("una huella con una ruta fuera del proyecto: $archivo")
            continue
        fi
        if [[ ! -f "$DIR_PROYECTO/$archivo" ]]; then
            problemas+=("falta $archivo")
            continue
        fi
        actual="$(sha256sum "$DIR_PROYECTO/$archivo" | cut -d' ' -f1)"
        if [[ "$actual" != "$huella" ]]; then
            problemas+=("$archivo cambió")
        fi
    done <<< "$pis"

    # --- D. ESTADO ---
    if (( ${#problemas[@]} > 0 )); then
        VIGENCIA_ESTADO="desactualizado"
        local IFS=";"
        VIGENCIA_DETALLE="${problemas[*]}"
        VIGENCIA_DETALLE="${VIGENCIA_DETALLE//;/; }"
    elif (( fuentes == 0 )); then
        VIGENCIA_ESTADO="sin_huella"
        VIGENCIA_DETALLE="el canónico no registra sus fuentes: es anterior a SC-75"
    else
        VIGENCIA_ESTADO="vigente"
        VIGENCIA_DETALLE="$fuentes archivo(s) fuente sin cambios"
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
