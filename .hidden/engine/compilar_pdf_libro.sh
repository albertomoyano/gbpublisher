#!/bin/bash
# Compilador de la salida PDF de libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Lo invoca Gambas desde el terminal del proyecto, así que la salida está
# pensada para leerse ahí en tiempo real, como ventana de estado.
#
# USO
#   compilar-pdf-libro.sh <ruta_proyecto> <nombre_bib> <nombre_salida>
#
#   ruta_proyecto   raíz del proyecto
#   nombre_bib      nombre del .bib dentro de referencias/, con extensión.
#                   Lo pasa Gambas, que lo sabe por NombreArchivoBib(). NO se
#                   deriva por heurística: el compilador legacy lo derivaba
#                   del nombre del .tex y fallaba en cuanto los dos nombres
#                   no coincidían.
#   nombre_salida   nombre del PDF final, sin extensión
#
# EL MAESTRO SE LLAMA SIEMPRE main.tex: lo escribe GenerarMainTeX con ese
# nombre fijo. Por eso no es un parámetro.
# ============================================================================
# SECUENCIA, Y POR QUÉ CADA PASO ESTÁ DONDE ESTÁ
#
#   limpieza   el .aux viejo falsea la paginación y las referencias cruzadas
#   pasada 1   escribe el .bcf con las claves citadas y los .idx vacíos
#   biber      resuelve las claves contra el .bib y escribe el .bbl con el
#              texto de cada cita y la lista ya compuesta
#   pasada 2   lee el .bbl, compone las citas y LLENA los .idx con páginas
#              ya casi definitivas
#   xindy      convierte cada .idx en .ind, ordenado y agrupado
#   pasada 3   lee los .ind y compone los índices
#   pasada 4   insertar los índices corrió las páginas: el sumario y las
#              referencias cruzadas necesitan otra vuelta para converger
#
# EL CRITERIO DE ÉXITO DE CADA PASADA ES QUE SE ESCRIBA EL PDF, NO EL CÓDIGO
# DE SALIDA. lualatex DEVUELVE 1 POR AVISOS —CITAS SIN RESOLVER ANTES DE QUE
# CORRA biber, QUE ES LO NORMAL EN LA PRIMERA PASADA— Y COMPONE IGUAL. UN
# COMPILADOR QUE CORTE POR EL CÓDIGO DE SALIDA SE MATA JUSTO ANTES DEL PASO
# QUE IBA A ARREGLAR EL PROBLEMA.
# ============================================================================

set -uo pipefail

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

# --- 2. CONFIGURACIÓN ---
BASE="main"
INTERACTION="nonstopmode"
TIEMPO_LUALATEX=600
TIEMPO_BIBER=180
TIEMPO_XINDY=120
XINDY_MODULO_ES="/usr/share/xindy/lang/spanish/modern-utf8.xdy"

# EXTENSIONES QUE SE BORRAN ANTES DE COMPILAR. NUNCA .tex NI .pdf.
EXT_AUXILIARES=(aux toc lof lot out bcf run.xml bbl blg idx ind ilg log
                nav snm xdv fls fdb_latexmk synctex.gz)

# PATRONES QUE INDICAN QUE HACE FALTA OTRA PASADA
PATRONES_RERUN=("Temporary extra page added"
                "Rerun to get"
                "Rerun to correct"
                "Please rerun LaTeX"
                "Package rerunfilecheck Warning")
PASADAS_EXTRA_MAX=2

# --- 3. FUNCIONES DE SALIDA ---
titulo() { printf '%s%s%s\n' "$C_TITULO" "$1" "$C_RESET"; }
paso()   { printf '\n%s→ %s%s\n' "$C_TITULO" "$1" "$C_RESET"; }
ok()     { printf '  %s✓%s %s\n' "$C_OK" "$C_RESET" "$1"; }
aviso()  { printf '  %s⚠%s %s\n' "$C_AVISO" "$C_RESET" "$1"; }
tenue()  { printf '  %s%s%s\n' "$C_TENUE" "$1" "$C_RESET"; }

morir() {
    printf '\n%s✗ %s%s\n' "$C_ERROR" "$1" "$C_RESET" >&2
    exit 1
}

# ============================================================================
# Función   : informar_log
# Propósito : Extrae del .log los bloques de error reales y los imprime con el
#             archivo .tex donde ocurrieron.
# Retorna   : cantidad de bloques por stdout
# Nota      : LA PILA DE ARCHIVOS SE LLEVA HACIA ADELANTE. awk ES ORIENTADO A
#             LÍNEAS Y CON ESTADO, ASÍ QUE CUANDO APARECE UN "!" YA SABE EN QUÉ
#             ARCHIVO ESTÁ.
#             ADVERTENCIA: SI EL ERROR OCURRE EN UN HOOK DIFERIDO —POR EJEMPLO
#             EN \AtEndPreamble— EL ARCHIVO QUE SE REPORTA ES EL ÚLTIMO PAQUETE
#             QUE QUEDÓ EN LA PILA Y NO TIENE NADA QUE VER CON LA CAUSA.
# ============================================================================
informar_log() {
    local etiqueta="$1"
    [[ -f "$ARCHIVO_LOG" ]] || { echo 0; return; }

    local cuenta
    cuenta=$(gawk '/^!/ && !/^!  ==> Fatal error/ {n++} END {print n+0}' "$ARCHIVO_LOG")

    if (( cuenta > 0 )); then
        # LOS BLOQUES VAN A stderr Y SOLO LA CUENTA A stdout: EL LLAMADOR
        # CAPTURA stdout CON $( ) PARA EL (( )), Y SI LOS BLOQUES SALIERAN POR
        # AHÍ LA VARIABLE RECIBIRÍA EL TEXTO ENTERO EN VEZ DEL NÚMERO.
        printf '\n  %s⚠ %d error(es) de TeX en la pasada «%s»%s\n' \
            "$C_AVISO" "$cuenta" "$etiqueta" "$C_RESET" >&2

        gawk -v ce="$C_ERROR" -v ct="$C_TENUE" -v cr="$C_RESET" '
            {
                linea = $0
                while (match(linea, /\((\.\/|\/)[^ ()]*\.tex/)) {
                    archivo = substr(linea, RSTART + 1, RLENGTH - 1)
                    linea = substr(linea, RSTART + RLENGTH)
                }
            }
            /^!/ && !/^!  ==> Fatal error/ {
                bloques++
                if (bloques > 10) { extra++; next }
                printf "  %s── en %s%s\n", ct, (archivo ? archivo : "(desconocido)"), cr
                printf "     %s%s%s\n", ce, $0, cr
                enbloque = 1
                sangria = 0
                next
            }
            enbloque {
                sangria++
                printf "     %s\n", $0
                if ($0 ~ /^l\./ || sangria >= 11) enbloque = 0
            }
            END { if (extra > 0) printf "  %s── (+%d más)%s\n", ct, extra, cr }
        ' "$ARCHIVO_LOG" >&2
    fi

    echo "$cuenta"
}

# ============================================================================
# Función   : volcar_final_log
# Propósito : Imprime las últimas líneas del .log.
# Nota      : HAY FALLOS QUE NO PRODUCEN NINGÚN BLOQUE "!" —UN \input DE
#             ARCHIVO INEXISTENTE, UN PROBLEMA DE PERMISOS EN EL DIRECTORIO DE
#             SALIDA—. SIN ESTE VOLCADO, EL COMPILADOR DIRÍA SOLO «ABORTÓ» Y NO
#             QUEDARÍA NADA QUE MIRAR.
# ============================================================================
volcar_final_log() {
    [[ -f "$ARCHIVO_LOG" ]] || { aviso "No hay .log para revisar"; return; }
    printf '\n  %sÚltimas líneas del registro de compilación%s\n' "$C_TENUE" "$C_RESET"
    tail -25 "$ARCHIVO_LOG" | sed 's/^/     /'
}

# ============================================================================
# Función   : necesita_rerun
# Propósito : Dice si el log pide otra pasada.
# ============================================================================
necesita_rerun() {
    [[ -f "$ARCHIVO_LOG" ]] || return 1
    local p
    for p in "${PATRONES_RERUN[@]}"; do
        grep -qF "$p" "$ARCHIVO_LOG" && return 0
    done
    return 1
}

# ============================================================================
# Función   : correr_lualatex
# Propósito : Una pasada de lualatex.
# Parámetros: $1 etiqueta de la pasada
# Nota      : SIN -halt-on-error: nonstopmode CONVERGE SOLO.
#             TEXINPUTS SE EXTIENDE CONSERVANDO LAS RUTAS DEL SISTEMA. LOS DOS
#             PUNTOS FINALES SON IMPRESCINDIBLES: SIN ELLOS TeX Live PIERDE SUS
#             PROPIAS RUTAS Y NO ENCUENTRA NINGÚN PAQUETE.
# ============================================================================
correr_lualatex() {
    local etiqueta="$1"
    paso "$etiqueta"

    # SE BORRA EL PDF ANTES DE COMPILAR: SU EXISTENCIA ES EL CRITERIO DE ÉXITO,
    # Y EL DE LA CORRIDA ANTERIOR DARÍA UN FALSO POSITIVO.
    rm -f "$ARCHIVO_PDF"

    local salida codigo
    salida=$(TEXINPUTS="$DIR_LATEX/:$DIR_PROYECTO/:${TEXINPUTS:-}" \
             timeout "$TIEMPO_LUALATEX" lualatex \
                -interaction="$INTERACTION" \
                -output-directory=latex \
                "latex/$BASE.tex" 2>&1)
    codigo=$?

    local errores
    errores=$(informar_log "$etiqueta")

    if [[ -f "$ARCHIVO_PDF" ]] && (( errores == 0 )); then
        ok "compuesto"
        return 0
    fi

    if (( errores == 0 )); then
        aviso "la compilación no produjo PDF y no dejó errores en el registro"
        volcar_final_log
        if [[ -n "$salida" ]]; then
            printf '\n  %sSalida del compilador%s\n' "$C_TENUE" "$C_RESET"
            printf '%s\n' "$salida" | tail -10 | sed 's/^/     /'
        fi
    fi

    morir "La compilación falló en la $etiqueta"
}

# ============================================================================
# Función   : correr_biber
# Propósito : Resuelve las citas contra el .bib.
# Nota      : biber DEVUELVE 0 AUNQUE DESCARTE ENTRADAS: HAY QUE MIRAR EL .blg.
#             UN «didn't find a database entry» SIGNIFICA QUE EL LIBRO CITA UNA
#             CLAVE QUE NO ESTÁ EN EL .bib, Y ESO SALE EN EL PDF COMO UNA CITA
#             ROTA QUE NADIE VE HASTA LA CORRECCIÓN DE PRUEBAS. EL CASO TÍPICO
#             ES BORRAR Y RECARGAR UNA REFERENCIA EN EL ABM: CAMBIA SU id Y LOS
#             CANÓNICOS QUEDAN APUNTANDO AL VIEJO.
# ============================================================================
correr_biber() {
    paso "resolviendo las citas bibliográficas"

    local salida codigo
    salida=$(BIBINPUTS="$DIR_PROYECTO/:$DIR_PROYECTO/referencias/:${BIBINPUTS:-}" \
             timeout "$TIEMPO_BIBER" biber --output-directory=latex "$BASE" 2>&1)
    codigo=$?

    if (( codigo != 0 )); then
        printf '%s\n' "$salida" | tail -15 | sed 's/^/     /'
        morir "No se pudieron resolver las citas bibliográficas"
    fi

    local blg="$DIR_LATEX/$BASE.blg"
    if [[ -f "$blg" ]]; then
        local rotas
        rotas=$(grep -c "didn't find a database entry" "$blg")
        if (( rotas > 0 )); then
            aviso "$rotas cita(s) sin entrada en el archivo de referencias:"
            grep -oP "didn't find a database entry for '\K[^']+" "$blg" \
                | sort -u | sed 's/^/       /'
            aviso "el PDF va a salir con esas referencias sin resolver"
        fi
    fi

    ok "citas resueltas"
}

# ============================================================================
# Función   : procesar_indices
# Propósito : Corre xindy sobre todos los .idx presentes.
# Nota      : POR GLOB Y NO POR LISTA FIJA: ASÍ APARECE CUALQUIER ÍNDICE NUEVO
#             SIN TOCAR EL SCRIPT, Y TAMBIÉN SE HACE VISIBLE UN .idx CON EL
#             NOMBRE MAL ESCRITO.
#             SIN ESTE PASO NO HAY .ind Y \printindex NO IMPRIME NADA SIN DAR
#             ERROR: EL ÍNDICE SIMPLEMENTE NO APARECE EN EL PDF.
#             UN .idx VACÍO NO ES UNA ANOMALÍA: SIGNIFICA QUE NADIE CARGÓ
#             ENTRADAS DE ESE ÍNDICE.
# ============================================================================
procesar_indices() {
    paso "componiendo los índices"

    local idx ind hay=0
    for idx in "$DIR_LATEX"/*.idx; do
        [[ -f "$idx" ]] || continue
        hay=1

        if [[ ! -s "$idx" ]]; then
            tenue "$(basename "${idx%.idx}") sin entradas"
            continue
        fi

        ind="${idx%.idx}.ind"
        salida=$( cd "$DIR_LATEX" && timeout "$TIEMPO_XINDY" xindy \
                -M texindy -M page-ranges -M word-order \
                -M "$MODULO_ES" -o "$ind" -I latex "$idx" 2>&1 )

        if [[ -f "$ind" ]]; then
            ok "$(basename "${idx%.idx}")"
            # UNA ENTRADA DESCARTADA NO HACE FALLAR A xindy: SIMPLEMENTE NO
            # APARECE EN EL ÍNDICE. EL CASO QUE LO MOTIVÓ: UN \uppercase SIN
            # EXPANDIR EN EL NÚMERO DE PÁGINA HACÍA QUE xindy IGNORARA TREINTA
            # Y DOS ENTRADAS DE CUARENTA Y UNA, Y EL ÍNDICE SALÍA CORTO SIN
            # QUE NADA LO DIJERA.
            descartadas=$(printf '%s\n' "$salida" |
                          grep -c 'did not match any location-class')
            (( descartadas > 0 )) && aviso \
                "$descartadas entrada(s) descartadas: número de página no reconocido"
        else
            aviso "no se pudo componer el índice $(basename "${idx%.idx}")"
        fi
    done

    (( hay == 1 )) || tenue "el libro no declara índices"
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

echo
titulo "$REGLA"
titulo "  GENERACIÓN DE LA SALIDA PDF"
titulo "$REGLA"

# --- 4. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib> <nombre_salida>"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"
NOMBRE_SALIDA="$3"

DIR_LATEX="$DIR_PROYECTO/latex"
ARCHIVO_TEX="$DIR_LATEX/$BASE.tex"
ARCHIVO_LOG="$DIR_LATEX/$BASE.log"
ARCHIVO_PDF="$DIR_LATEX/$BASE.pdf"
ARCHIVO_BIB="$DIR_PROYECTO/referencias/$NOMBRE_BIB"
DIR_SALIDA="$DIR_PROYECTO/salidas/pdf"
PDF_FINAL="$DIR_SALIDA/$NOMBRE_SALIDA.pdf"

# --- 5. VERIFICACIONES ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_LATEX" ]]    || morir "El proyecto no tiene carpeta latex/"
[[ -f "$ARCHIVO_TEX" ]]  || morir "No existe $ARCHIVO_TEX — generá primero los archivos LaTeX"

# LOS TRES BINARIOS SON OBLIGATORIOS. xindy NO ES OPCIONAL: SIN ÉL LOS ÍNDICES
# NO SE COMPONEN Y EL PDF SALE INCOMPLETO SIN DECIRLO.
# command -v Y NO which: EL PRIMERO ES BUILTIN DE POSIX sh, EL SEGUNDO VIVE EN
# debianutils Y PUEDE NO ESTAR.
faltan=()
for b in lualatex biber xindy; do
    command -v "$b" >/dev/null 2>&1 || faltan+=("$b")
done
if (( ${#faltan[@]} > 0 )); then
    morir "Faltan herramientas del sistema: ${faltan[*]}"
fi

MODULO_ES="$XINDY_MODULO_ES"
if [[ ! -f "$MODULO_ES" ]]; then
    MODULO_ES=$(find /usr/share/xindy/lang/spanish -name '*.xdy' 2>/dev/null | head -1)
    [[ -n "$MODULO_ES" ]] || morir "Falta el módulo español de xindy"
fi

ok "herramientas del sistema"

if [[ -f "$ARCHIVO_BIB" ]]; then
    ok "archivo de referencias: $NOMBRE_BIB"
    HAY_BIB=1
else
    aviso "no existe referencias/$NOMBRE_BIB — las citas van a salir sin resolver"
    HAY_BIB=0
fi

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "$NOMBRE_SALIDA.pdf"

# --- 6. LIMPIEZA ---
# SIN ESTO EL .aux VIEJO FALSEA LA PAGINACIÓN Y LAS REFERENCIAS CRUZADAS.
paso "limpiando la compilación anterior"
borrados=0
for ext in "${EXT_AUXILIARES[@]}"; do
    for f in "$DIR_LATEX"/*."$ext"; do
        [[ -f "$f" ]] || continue
        rm -f "$f" && borrados=$((borrados + 1))
    done
done
for f in "$DIR_LATEX"/*-blx.bib; do
    [[ -f "$f" ]] || continue
    rm -f "$f" && borrados=$((borrados + 1))
done
ok "$borrados archivos temporales eliminados"

# --- 7. COMPILACIÓN ---
cd "$DIR_PROYECTO" || morir "No se pudo entrar a $DIR_PROYECTO"

correr_lualatex "primera composición"

if (( HAY_BIB == 1 )); then
    correr_biber
else
    paso "resolviendo las citas bibliográficas"
    tenue "omitido: no hay archivo de referencias"
fi

correr_lualatex "segunda composición"
correr_lualatex "tercera composición"

# xindy VA DESPUÉS DE LA TERCERA PASADA Y NO DE LA SEGUNDA.
#
# CADA PASADA REESCRIBE EL .idx DESDE CERO. EN LA SEGUNDA LAS CITAS RECIÉN SE
# RESUELVEN Y LA PAGINACIÓN TODAVÍA SE MUEVE, ASÍ QUE EL .idx QUEDA CORTO: SE
# VERIFICÓ UN CASO CON 41 ENTRADAS EN EL .idx Y SOLO 9 EN EL .ind, PORQUE EL
# .ind SE HABÍA CONSTRUIDO UNA PASADA ANTES.
#
# LAS PASADAS POSTERIORES NO REHACEN EL .ind: SOLO LO LEEN. ASÍ QUE SI SE
# COMPONE TEMPRANO, EL ÍNDICE SALE INCOMPLETO Y NADA AVISA.
procesar_indices

correr_lualatex "cuarta composición"
correr_lualatex "composición final"

# PASADAS EXTRA MIENTRAS EL LOG SIGA PIDIENDO RERUN. TÍPICO CUANDO CAMBIA LA
# CANTIDAD DE PÁGINAS: LaTeX EMITE UNA «Temporary extra page» HASTA QUE EL .aux
# CONVERGE.
extra=0
while necesita_rerun && (( extra < PASADAS_EXTRA_MAX )); do
    extra=$((extra + 1))
    tenue "la paginación todavía no converge"
    correr_lualatex "ajuste de paginación $extra"
done

# --- 8. ENTREGA DEL PDF ---
echo
titulo "$REGLA"

[[ -f "$ARCHIVO_PDF" ]] || morir "No se generó el PDF"

mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
mv -f "$ARCHIVO_PDF" "$PDF_FINAL" || morir "No se pudo mover el PDF a salidas/pdf"

TAM_KB=$(( $(stat -c%s "$PDF_FINAL") / 1024 ))
PAGINAS=$(pdfinfo "$PDF_FINAL" 2>/dev/null | grep -oP 'Pages:\s+\K\d+')

printf '%s✓ PDF generado%s\n' "$C_OK" "$C_RESET"
printf '  %-14s %s\n' "Archivo:"  "$PDF_FINAL"
printf '  %-14s %s KB\n' "Tamaño:" "$TAM_KB"
[[ -n "$PAGINAS" ]] && printf '  %-14s %s\n' "Páginas:" "$PAGINAS"

# LAS PRESTACIONES CON LAS QUE SE COMPUSO. CUANDO UN PDF SALE DISTINTO DE LO
# ESPERADO, ESTA LÍNEA DICE POR QUÉ SIN TENER QUE ABRIR EL PREÁMBULO DERIVADO.
PREST=$(grep -oP '\[gbpublisher\] prestaciones: \K.*' "$ARCHIVO_LOG" 2>/dev/null | head -1)
[[ -n "$PREST" ]] && printf '  %-14s %s\n' "Prestaciones:" "$PREST"

for f in "$DIR_LATEX"/*.ind; do
    [[ -f "$f" ]] || continue
    tenue "índice compuesto: $(basename "${f%.ind}")"
done

echo
exit 0
