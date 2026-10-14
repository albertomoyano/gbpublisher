#!/bin/bash
# Preparación de los archivos LaTeX del libro — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   preparar_latex_libro.sh <ruta_proyecto> <lista_rel> <main_rel>
#
#   ruta_proyecto   raíz del proyecto
#   lista_rel       ruta relativa al proyecto de la lista de piezas con
#                   cuerpo, una por línea, en el orden del libro: el
#                   nombre_archivo de cada una (a-02-metodologia)
#   main_rel        ruta relativa al proyecto del main.tex ya armado por
#                   Gambas, en un temporal dentro de latex/
#
# Lo lanza Gambas para «Solo generar», y compilar_pdf_libro.sh lo llama
# anidado (GBP_ANIDADO=1) antes de compilar.
#
# LOS INSUMOS LOS ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT: la lista, el
# main.tex propuesto, el preámbulo derivado y el .bib. Todo lo que sale de la
# base llega como archivo. Este script no toca la base.
# ============================================================================
# QUÉ HACE
#
#   Por cada pieza de la lista: verifica su canónico, colorea su código
#   (colorear_codigo.sh, SC-42) y lo transforma con docbook-to-latex.xsl en
#   latex/c-{nombre}.tex, escrito en un temporal y renombrado con mv. Después
#   borra los c-*.tex que ya no están en la lista y, AL FINAL, pone el main.tex
#   en su lugar.
#
#   Antes lo hacía m_GenerarPDFLibro.GenerarMainTeX desde Gambas, con Exec
#   síncronos: mientras corrían, la interfaz no se repintaba (GV-17) y no
#   había ninguna señal de vida. Así queda dentro de la lanzadora (SC-53).
#
# EL main.tex VA ÚLTIMO
#
#   Es lo que DECLARA la existencia de todo lo demás: si una pieza falla, no
#   se pone, y el main.tex anterior queda intacto en vez de prometer
#   \include de archivos que no existen (criterio de SC-07). Gambas lo arma
#   antes, porque sale de la base, pero lo deja en un temporal; el mv lo pone
#   en su lugar de una vez. El mv conserva la fecha del temporal, anterior a
#   la de las piezas: un touch después lo deja como el archivo más nuevo, que
#   es lo que siempre fue.
#
# CUANDO UNA PIEZA FALLA
#
#   Se sigue con las demás y al final se listan todas: el editor necesita ver
#   todo lo que hay que arreglar, no solo lo primero (mismo criterio que los
#   canónicos de capítulo, SC-53). Y no se pone el main.tex.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  archivos LaTeX listos
#   3  listos, con avisos (un huérfano que no se pudo borrar)
#   1  alguna pieza falló, o la preparación no pudo empezar: main.tex intacto
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_SAXON=300
XSL="$DIR_GBP_LOCAL/xslt/docbook-to-latex.xsl"
COLOREAR="$DIR_ENGINE/colorear_codigo.sh"

# ============================================================================
# Función   : fallo
# Propósito : Informa el fallo de UNA pieza sin terminar el script: morir()
#             saldría de la preparación entera.
# Parámetros: $1 mensaje
# ============================================================================
fallo() {
    printf '  %s✗%s %s\n' "$C_ERROR" "$C_RESET" "$1"
}

# ============================================================================
# Función   : preparar_pieza
# Propósito : Coloreo y transformación de una pieza.
# Parámetros: $1 nombre_archivo
# Retorna   : 0 si escribió latex/c-{nombre}.tex; 1 si no
# ============================================================================
preparar_pieza() {
    local nombre="$1"
    local canonico="$DIR_PROYECTO/jats/c-$nombre.xml"
    local tex="$DIR_LATEX/c-$nombre.tex"
    # EN LA MISMA CARPETA: mv TIENE QUE SER UN RENOMBRE. EL PUNTO INICIAL LO
    # DEJA FUERA DEL PATRÓN c-*.tex DE LOS HUÉRFANOS
    local temporal="$DIR_LATEX/.c-$nombre.tex.tmp"
    local dir_codigo="$DIR_PROYECTO/tmp/codigo/latex-$nombre"
    local salida codigo

    # --- A. CANÓNICO ---
    # BIEN FORMADO Y NO SOLO PRESENTE: UN CANÓNICO TRUNCADO EXISTE
    if [[ ! -f "$canonico" ]]; then
        fallo "no existe jats/c-$nombre.xml: generá primero su canónico"
        return 1
    fi
    if ! bien_formado "$canonico"; then
        fallo "jats/c-$nombre.xml está mal formado: regenerá su canónico"
        return 1
    fi

    # --- B. COLOREO DEL CÓDIGO (SC-42) ---
    # LA HOJA LEE LOS BLOQUES DE dir_codigo Y FRENA SI FALTA UNO: SIN ESTE
    # PASO LA PIEZA NO SE TRANSFORMA
    salida=$(GBP_ANIDADO=1 bash "$COLOREAR" "$canonico" "$dir_codigo" latex 2>&1)
    codigo=$?
    if (( codigo != 0 )); then
        mostrar_cola "$salida"
        fallo "no se pudo colorear el código"
        return 1
    fi

    # --- C. TRANSFORMACIÓN ---
    rm -f "$temporal"
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$canonico" \
                -xsl:"$XSL" \
                -o:"$temporal" \
                codigo_dir="$dir_codigo" 2>&1)
    codigo=$?

    if (( codigo == 124 )); then
        rm -f "$temporal"
        fallo "Saxon no terminó en $TIEMPO_SAXON segundos"
        return 1
    fi
    if (( codigo != 0 )); then
        mostrar_cola "$salida"
        rm -f "$temporal"
        fallo "falló la transformación; si el mensaje habla de vocabulario no previsto, el canónico tiene un elemento que la hoja todavía no contempla"
        return 1
    fi
    if [[ ! -s "$temporal" ]]; then
        rm -f "$temporal"
        fallo "la transformación no produjo salida"
        return 1
    fi

    # LOS MENSAJES DE xsl:message QUE NO TERMINAN LA TRANSFORMACIÓN LLEGAN
    # CON CÓDIGO 0: SE MUESTRAN PARA QUE NO SE PIERDAN
    if [[ -n "$salida" ]]; then
        tenue "mensajes de la transformación:"
        mostrar_cola "$salida" 10
    fi

    mv -f "$temporal" "$tex" || { fallo "no se pudo escribir latex/c-$nombre.tex"; return 1; }
    ok "c-$nombre.tex"
    return 0
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "PREPARACIÓN DE LOS ARCHIVOS LaTeX"

# --- 2. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <lista_rel> <main_rel>"
fi

DIR_PROYECTO="${1%/}"
LISTA="$DIR_PROYECTO/$2"
MAIN_PROPUESTO="$DIR_PROYECTO/$3"
DIR_LATEX="$DIR_PROYECTO/latex"
MAIN="$DIR_LATEX/main.tex"

# --- 3. ENTORNO E INSUMOS ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]      || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/jats" ]] || morir "El proyecto no tiene carpeta jats/"
[[ -d "$DIR_LATEX" ]]         || morir "El proyecto no tiene carpeta latex/"

requerir_comandos java xmllint timeout

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de transformación: $XSL"
[[ -f "$COLOREAR" ]]   || morir "No se encontró el coloreador de código: $COLOREAR"

# EL main.tex PROPUESTO TIENE QUE ESTAR EN latex/: SI ESTUVIERA EN OTRO
# SISTEMA DE ARCHIVOS, mv DEJARÍA DE SER UN RENOMBRE
[[ -f "$MAIN_PROPUESTO" ]] || morir "No existe el main.tex propuesto: $MAIN_PROPUESTO"
[[ "$(dirname "$(readlink -f "$MAIN_PROPUESTO")")" == "$(readlink -f "$DIR_LATEX")" ]] ||
    morir "El main.tex propuesto tiene que estar en latex/: $MAIN_PROPUESTO"
[[ -f "$LISTA" ]] || morir "No existe la lista de piezas: $LISTA"

ok "herramientas, hoja, coloreador e insumos"

# --- 4. LISTA ---
PIEZAS=()
while IFS= read -r nombre || [[ -n "$nombre" ]]; do
    [[ -z "$nombre" ]] && continue
    # UN NOMBRE CON / SALDRÍA DE LA CARPETA DEL PROYECTO
    [[ "$nombre" == */* ]] && morir "Nombre de pieza no válido en la lista: $nombre"
    PIEZAS+=("$nombre")
done < "$LISTA"

# UNA LISTA VACÍA ES POSIBLE: UN LIBRO CUYAS PIEZAS NO TIENEN CUERPO PROPIO.
# EL main.tex IGUAL SE PONE
tenue "${#PIEZAS[@]} pieza(s) con cuerpo"

# --- 5. PIEZAS ---
FALLIDAS=()
for (( i = 0; i < ${#PIEZAS[@]}; i++ )); do
    paso "$((i + 1))/${#PIEZAS[@]}  ${PIEZAS[$i]}"
    preparar_pieza "${PIEZAS[$i]}" || FALLIDAS+=("${PIEZAS[$i]}")
done

if (( ${#FALLIDAS[@]} > 0 )); then
    # EL PROPUESTO SE BORRA: QUEDA EL main.tex ANTERIOR, QUE CORRESPONDE A LOS
    # .tex ANTERIORES DE LAS PIEZAS QUE FALLARON
    rm -f "$MAIN_PROPUESTO"
    echo
    printf '  No se prepararon (motivo arriba, en cada una):\n'
    printf '    %s\n' "${FALLIDAS[@]}"
    morir "${#FALLIDAS[@]} pieza(s) con problemas: el main.tex no se reemplazó"
fi

# --- 6. HUÉRFANOS ---
# UN c-*.tex QUE YA NO ESTÁ EN LA LISTA ES DE UNA PIEZA BORRADA O RENOMBRADA:
# SI QUEDARA, UN \includeonly O UN SCRIPT DE PERSONALIZACIÓN PODRÍA TOMARLO
paso "archivos de piezas que ya no están"
declare -A DECLARADOS=()
for nombre in "${PIEZAS[@]}"; do
    DECLARADOS["c-$nombre.tex"]=1
done

borrados=0
for f in "$DIR_LATEX"/c-*.tex; do
    [[ -f "$f" ]] || continue
    base_f="$(basename "$f")"
    [[ -n "${DECLARADOS[$base_f]:-}" ]] && continue
    if rm -f "$f"; then
        tenue "borrado $base_f"
        borrados=$((borrados + 1))
    else
        # NO SE ABORTA: UN HUÉRFANO NO IMPIDE COMPILAR, PERO SE INFORMA
        aviso "no se pudo borrar el huérfano $base_f"
    fi
done
(( borrados == 0 )) && tenue "ninguno"

# --- 7. EL main.tex, ÚLTIMO ---
paso "main.tex"
mv -f "$MAIN_PROPUESTO" "$MAIN" || morir "No se pudo poner el main.tex en su lugar"
# EL mv CONSERVA LA FECHA DEL TEMPORAL, ANTERIOR A LAS PIEZAS (VER CABECERA)
touch "$MAIN"
ok "main.tex en su lugar"

# --- 8. RESUMEN ---
if [[ -z "${GBP_ANIDADO:-}" ]]; then
    echo
    titulo "$REGLA"
    printf '%s✓ Archivos LaTeX listos%s\n' "$C_OK" "$C_RESET"
    printf '  %-14s %s\n' "Carpeta:" "$DIR_LATEX"
    printf '  %-14s %s\n' "Piezas:"  "${#PIEZAS[@]}"
    if (( AVISOS > 0 )); then
        printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
    fi
    echo
fi

terminar
