#!/bin/bash
# Compilador de la salida PDF de libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Lo lanza Gambas con m_GenerarSalidasLibro.EjecutarScriptSalida (SC-53), en
# el terminal del proyecto, así que la salida está pensada para leerse ahí en
# tiempo real, como ventana de estado.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  PDF generado sin avisos
#   3  PDF generado con avisos: citas sin entrada en el .bib, entradas de
#      índice descartadas, referencias cruzadas sin destino o repetidas, falta
#      el .bib
#   1  no se generó el PDF
#
# USO
#   compilar_pdf_libro.sh <ruta_proyecto> <nombre_bib> <nombre_salida>
#                         <lista_rel> <main_rel>
#
#   ruta_proyecto   raíz del proyecto
#   nombre_bib      nombre del .bib dentro de referencias/, con extensión.
#                   Lo pasa Gambas, que lo sabe por NombreArchivoBib(). NO se
#                   deriva por heurística: el compilador legacy lo derivaba
#                   del nombre del .tex y fallaba en cuanto los dos nombres
#                   no coincidían.
#   nombre_salida   nombre del PDF final, sin extensión
#   lista_rel       los dos de preparar_latex_libro.sh, que este script
#   main_rel        llama primero: la lista de piezas con cuerpo y el main.tex
#                   propuesto. Si la preparación falla, no se compila.
#
# EL MAESTRO SE LLAMA SIEMPRE main.tex: lo pone en su lugar
# preparar_latex_libro.sh con ese nombre fijo. Por eso no es un parámetro.
#
# LA SECUENCIA —limpieza, pasadas, biber, xindy, convergencia— VIVE EN
# compilar_latex_comun.sh, COMPARTIDA CON compilar_pdfa_libro.sh. ESTE SCRIPT
# SOLO DICE QUÉ SE COMPILA (latex/main.tex), DÓNDE QUEDAN LOS AUXILIARES
# (latex/) Y CÓMO SE ENTREGA EL PDF.
# ============================================================================

set -uo pipefail

# --- 1. FUNCIONES COMPARTIDAS ---
# LOS COLORES, LA REGLA, titulo, paso, ok, aviso, tenue, morir, encabezado Y
# terminar SALEN DE comun.sh, COMO EN LOS DEMÁS SCRIPTS. ESTE SCRIPT TENÍA SU
# COPIA PROPIA, Y SU aviso NO CONTABA: LOS AVISOS QUEDABAN EN LA TERMINAL Y
# GAMBAS NO SE ENTERABA. AHORA LLEGAN COMO CÓDIGO 3 (SC-53).
DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
if ! source "$DIR_ENGINE/compilar_latex_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/compilar_latex_comun.sh" >&2
    exit 1
fi

# --- 2. ORQUESTACIÓN ---
encabezado "GENERACIÓN DE LA SALIDA PDF"

# --- 3. ARGUMENTOS ---
if (( $# < 5 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib> <nombre_salida> <lista_rel> <main_rel>"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"
NOMBRE_SALIDA="$3"
LISTA_REL="$4"
MAIN_REL="$5"

# EL MAESTRO SE LLAMA SIEMPRE main.tex Y LOS AUXILIARES QUEDAN EN latex/,
# JUNTO A ÉL: ES LO QUE ESPERA QUIEN COMPILA EL PROYECTO A MANO
BASE="main"
DIR_LATEX="$DIR_PROYECTO/latex"
DIR_AUX="$DIR_LATEX"
MAESTRO="latex/$BASE.tex"
ARCHIVO_TEX="$DIR_LATEX/$BASE.tex"
ARCHIVO_LOG="$DIR_AUX/$BASE.log"
ARCHIVO_PDF="$DIR_AUX/$BASE.pdf"
ARCHIVO_BIB="$DIR_PROYECTO/referencias/$NOMBRE_BIB"
DIR_SALIDA="$DIR_PROYECTO/salidas/pdf"
PDF_FINAL="$DIR_SALIDA/$NOMBRE_SALIDA.pdf"
HAY_BIB=0

# --- 4. PREPARACIÓN DE LOS ARCHIVOS LaTeX ---
# PRIMERO, Y EN EL MISMO LANZAMIENTO: EL COLOREO Y LA TRANSFORMACIÓN DE CADA
# PIEZA SON LO QUE MÁS TARDA ANTES DE COMPILAR, Y ASÍ CORREN A LA VISTA.
# CÓDIGO 3: LOS ARCHIVOS ESTÁN, CON AVISOS; SE COMPILA Y EL AVISO SE HEREDA.
# CUALQUIER OTRO DISTINTO DE 0: EL main.tex NO SE REEMPLAZÓ Y NO SE COMPILA
# SOBRE EL VIEJO.
GBP_ANIDADO=1 bash "$DIR_ENGINE/preparar_latex_libro.sh" \
    "$DIR_PROYECTO" "$LISTA_REL" "$MAIN_REL"
codigo=$?

if (( codigo == SALIDA_AVISOS )); then
    aviso "la preparación de los archivos LaTeX tiene avisos: se compila igual"
elif (( codigo != SALIDA_OK )); then
    morir "No se prepararon los archivos LaTeX: el PDF no se compila"
fi

# --- 5. VERIFICACIONES ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_LATEX" ]]    || morir "El proyecto no tiene carpeta latex/"
[[ -f "$ARCHIVO_TEX" ]]  || morir "No existe $ARCHIVO_TEX — generá primero los archivos LaTeX"

verificar_herramientas_latex
verificar_bib

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "$NOMBRE_SALIDA.pdf"

# --- 6. LIMPIEZA Y COMPILACIÓN ---
limpiar_auxiliares
secuencia_compilacion
verificar_referencias_cruzadas

# --- 7. ENTREGA DEL PDF ---
echo
titulo "$REGLA"

[[ -f "$ARCHIVO_PDF" ]] || morir "No se generó el PDF"

mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
mv -f "$ARCHIVO_PDF" "$PDF_FINAL" || morir "No se pudo mover el PDF a salidas/pdf"

resumen_pdf "$PDF_FINAL"

echo
terminar
