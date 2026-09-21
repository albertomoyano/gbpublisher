#!/bin/bash
# Generador de la salida HTML de libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   generar_html_libro.sh <ruta_proyecto> <nombre_base> <lugar_bibliografia>
#                         <biblio_rel> <estilo_cita> [imagen_tapa]
#
#   Los cuatro primeros son los de ensamblar_libro.sh, que este script invoca.
#   estilo_cita    apa | iso690 | vancouver | ieee — lo resuelve Gambas
#   imagen_tapa    nombre del archivo de tapa según la base. Opcional, y solo
#                  para avisar si falta: la tapa se copia con el resto de media/
# ============================================================================
# POR QUÉ ENSAMBLA PRIMERO
#
#   El HTML es la única salida que lee el canónico del LIBRO: el PDF y el EPUB
#   recorren los canónicos de cada capítulo. Así que un canónico del libro
#   truncado o viejo solo se nota acá, y la costura entre ensamblar y
#   transformar es exactamente donde se rompía. Ensamblar dentro del mismo
#   script la elimina: bash no pasa al paso siguiente hasta que el anterior
#   terminó, y ensamblar_libro.sh no deja en disco un canónico a medio escribir.
#
# LA VALIDACIÓN HTML5 ES INFORMATIVA: sus errores no impiden la salida, pero
# llegan a Gambas como código 3.
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_SAXON=300
TIEMPO_VNU=300
RUTA_VNU="/opt/vnu/vnu.jar"
LINEAS_ERROR_VNU=15

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "GENERACIÓN DE LA SALIDA HTML"

# --- 2. ARGUMENTOS ---
if (( $# < 5 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_base> <lugar_bibliografia> <biblio_rel|-> <estilo_cita> [imagen_tapa]"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BASE="$2"
LUGAR_BIB="$3"
BIBLIO_ARG="$4"
ESTILO_CITA="$5"
IMAGEN_TAPA="${6:-}"

CANONICO="$DIR_PROYECTO/jats/c-libro-$NOMBRE_BASE.xml"
MANIFIESTO_REL="tmp/manifiesto-libro-$NOMBRE_BASE.xml"
DIR_DOCS="$DIR_PROYECTO/docs"
DIR_ASSETS="$DIR_DOCS/assets"
INDEX="$DIR_DOCS/index.html"
XSL="$DIR_GBP_LOCAL/xslt/docbook-to-html.xsl"
COLOFON="$DIR_PROYECTO/tmp/colofon-digital.xml"
CSS="$DIR_GBP_LOCAL/assets/css/gbpublisher.css"
JS="$DIR_GBP_LOCAL/assets/js/gbpublisher.js"

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"

requerir_comandos java xmllint

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de salida HTML: $XSL"
[[ -f "$CSS" ]]        || morir "No se encontró la hoja de estilos compartida: $CSS"
[[ -f "$JS" ]]         || morir "No se encontró el script compartido: $JS"

ok "herramientas del sistema"

# EL COLOFÓN DEL PIE LO ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT. LA HOJA LO
# LEE CON doc-available(): SI FALTARA, OMITIRÍA EL PIE SIN DECIR NADA
[[ -f "$COLOFON" ]]    || morir "No existe el colofón del pie: $COLOFON"
bien_formado "$COLOFON" || morir "El colofón del pie está mal formado: $COLOFON"
ok "colofón del pie"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Citas:"    "$ESTILO_CITA"

# --- 4. CANÓNICO DEL LIBRO ---
# CÓDIGO 3 DEL ENSAMBLADOR: EL CANÓNICO EXISTE Y ESTÁ BIEN FORMADO, PERO
# CON AVISOS. SE SIGUE, Y EL AVISO SE HEREDA. CUALQUIER OTRO CÓDIGO DISTINTO
# DE 0: NO HAY CANÓNICO NUEVO Y NO SE GENERA NADA SOBRE EL VIEJO.
GBP_ANIDADO=1 bash "$DIR_ENGINE/ensamblar_libro.sh" \
    "$DIR_PROYECTO" "$NOMBRE_BASE" "$LUGAR_BIB" "$BIBLIO_ARG"
codigo=$?

if (( codigo == SALIDA_AVISOS )); then
    aviso "el canónico del libro tiene avisos: la salida HTML se genera igual"
elif (( codigo != SALIDA_OK )); then
    morir "No se pudo ensamblar el canónico del libro: la salida HTML no se genera"
fi

# --- 5. ESTRUCTURA docs/ Y RECURSOS ---
# CSS Y JS SE SOBRESCRIBEN SIEMPRE PARA PROPAGAR ACTUALIZACIONES (DECISIÓN
# PREVIA DEL PROYECTO). LAS IMÁGENES SE COPIAN TODAS DESDE media/, TAPA
# INCLUIDA: LA TAPA NO NECESITA UN CAMINO APARTE.
paso "preparando docs/"

mkdir -p "$DIR_ASSETS/css" "$DIR_ASSETS/js" "$DIR_ASSETS/media" ||
    morir "No se pudo crear $DIR_ASSETS"

cp -f "$CSS" "$DIR_ASSETS/css/" || morir "No se pudo copiar la hoja de estilos"
cp -f "$JS"  "$DIR_ASSETS/js/"  || morir "No se pudo copiar el script"
ok "hoja de estilos y script"

imagenes=0
if [[ -d "$DIR_PROYECTO/media" ]]; then
    for archivo in "$DIR_PROYECTO/media"/*; do
        # LOS SUBDIRECTORIOS SE SALTEAN, COMO HACÍA LA VERSIÓN EN GAMBAS
        [[ -f "$archivo" ]] || continue
        cp -f "$archivo" "$DIR_ASSETS/media/" ||
            morir "No se pudo copiar $(basename "$archivo")"
        imagenes=$((imagenes + 1))
    done
fi

if (( imagenes > 0 )); then
    ok "$imagenes imagen(es)"
else
    tenue "el proyecto no tiene imágenes en media/"
fi

# LA TAPA QUE DECLARA LA BASE Y NO ESTÁ EN DISCO NO IMPIDE LA SALIDA, PERO EL
# HTML VA A REFERENCIAR UN ARCHIVO INEXISTENTE
if [[ -n "$IMAGEN_TAPA" ]]; then
    if [[ -f "$DIR_PROYECTO/media/$IMAGEN_TAPA" ]]; then
        tenue "tapa: $IMAGEN_TAPA"
    else
        aviso "la tapa declarada en la base no está en media/: $IMAGEN_TAPA"
    fi
fi

# --- 6. TRANSFORMACIÓN ---
# SE BORRA EL index.html ANTERIOR: SU EXISTENCIA ES PARTE DEL CRITERIO DE
# ÉXITO, Y EL DE LA CORRIDA ANTERIOR DARÍA UN FALSO POSITIVO.
# LA HOJA ESCRIBE docs/index.html CON xsl:result-document Y RUTA RELATIVA,
# QUE SE RESUELVE CONTRA EL DIRECTORIO DE TRABAJO: POR ESO SAXON CORRE DESDE
# LA RAÍZ DEL PROYECTO, DENTRO DE UN SUBSHELL PARA NO CAMBIAR EL DEL SCRIPT.
paso "transformando a HTML"

rm -f "$INDEX"

salida=$(cd "$DIR_PROYECTO" &&
         timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$CANONICO" \
            -xsl:"$XSL" \
            proyecto_dir="$DIR_PROYECTO" \
            manifiesto_libro="$MANIFIESTO_REL" \
            estilo_cita="$ESTILO_CITA" 2>&1)
codigo=$?

if (( codigo == 124 )); then
    morir "Saxon no terminó en $TIEMPO_SAXON segundos"
fi

if (( codigo != 0 )); then
    mostrar_cola "$salida"
    morir "Saxon no pudo generar el HTML"
fi

[[ -s "$INDEX" ]] || morir "Saxon terminó sin escribir docs/index.html"

if [[ -n "$salida" ]]; then
    tenue "mensajes de la transformación:"
    mostrar_cola "$salida" 10
fi

ok "docs/index.html"

# --- 7. VALIDACIÓN HTML5 (Nu Html Checker) ---
# vnu Y NO xmllint: xmllint ES UN PARSER HTML 4.01 Y DA FALSOS POSITIVOS CON
# aside, details Y EL RESTO DE HTML5. SIN --exit-zero-always, vnu DEVUELVE
# DISTINTO DE CERO CUANDO ENCUENTRA ERRORES, Y ESO ES LO QUE SE USA ACÁ.
paso "validando el HTML"

if [[ ! -f "$RUTA_VNU" ]]; then
    tenue "vnu no está instalado en $RUTA_VNU: el HTML no se validó"
else
    salida=$(timeout "$TIEMPO_VNU" java -jar "$RUTA_VNU" \
                --format gnu --errors-only --skip-non-html "$DIR_DOCS/" 2>&1)
    codigo=$?
    if (( codigo == 0 )); then
        ok "HTML5 sin errores"
    elif (( codigo == 124 )); then
        aviso "la validación HTML5 no terminó en $TIEMPO_VNU segundos"
    else
        errores=$(printf '%s\n' "$salida" | grep -c .)
        aviso "$errores error(es) de HTML5:"
        printf '%s\n' "$salida" | sed "s|$DIR_DOCS/||" |
            head -"$LINEAS_ERROR_VNU" | sed 's/^/     /'
        if (( errores > LINEAS_ERROR_VNU )); then
            tenue "(+$((errores - LINEAS_ERROR_VNU)) más)"
        fi
    fi
fi

# --- 8. RESUMEN ---
echo
titulo "$REGLA"
printf '%s✓ HTML generado%s\n' "$C_OK" "$C_RESET"
printf '  %-14s %s\n' "Archivo:" "$INDEX"
if (( AVISOS > 0 )); then
    printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
fi
echo

terminar
