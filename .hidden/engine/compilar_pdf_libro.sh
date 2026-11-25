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
#
# LA PAGINACIÓN (claude/crossref-libros.md, F3, decisión de Alberto del
# 25/11/2026). Las páginas nacen en la composición y vuelven a la base: al
# terminar, este script escribe tmp/paginacion-libro.tsv y Gambas lo guarda.
# Es el ÚNICO escritor de esas páginas: los formularios ya no las graban.
#
#   # comentario (nombra las columnas)
#   (libro)       -   -     -     148      el total: páginas físicas del PDF
#                                          según pdfinfo, cortesía incluida
#                                          (la definición de SC-25)
#   a-01-CAP01    26  1     20    20       por pieza con folio: archivo,
#                                          id_capitulo, inicio, fin, páginas
#                                          (engine/paginacion_libro.pl)
#
#   SE ESCRIBE SOLO SI EL PDF SE ENTREGÓ Y TODAS LAS PIEZAS DEL main.tex SE
#   PUDIERON LEER. CON UN \includeonly SIN COMENTAR EN EL main.tex NO SE
#   ESCRIBE: LOS .aux DE LAS PIEZAS QUE NO SE COMPUSIERON SON VIEJOS. EN LOS
#   DOS CASOS ES AVISO (CÓDIGO 3): EL PDF ESTÁ, LO QUE FALTA SON LAS PÁGINAS.
#   UN paginacion-libro.tsv VIEJO SE BORRA AL EMPEZAR: GAMBAS NO PUEDE LEER
#   EL DE UNA CORRIDA ANTERIOR.
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
# LA PAGINACIÓN QUE LEE GAMBAS (VER EL ENCABEZADO)
TSV_PAGINACION="$DIR_PROYECTO/tmp/paginacion-libro.tsv"

# UNO VIEJO NO PUEDE SOBREVIVIR A ESTA CORRIDA, SALGA BIEN O MAL
rm -f "$TSV_PAGINACION"

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
# LA PAGINACIÓN: perl LA LEE DE LOS .aux Y pdfinfo CUENTA LAS PÁGINAS
requerir_comandos perl pdfinfo
# LA ESTÉTICA DE LA EDITORIAL, SI LA HAY, SE DECLARA (SC-11)
avisar_estetica_editorial "$DIR_AUX/preambulo-estetica.tex"
[[ -f "$DIR_ENGINE/paginacion_libro.pl" ]] || morir "Falta $DIR_ENGINE/paginacion_libro.pl: reinstalá gbpublisher"

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

# --- 8. LA PAGINACIÓN PARA LA BASE ---
# DESPUÉS DE ENTREGAR EL PDF: SI ALGO FALLA ACÁ, EL PDF ESTÁ IGUAL Y ES AVISO
paso "leyendo las páginas de cada pieza"
if grep -qE '^[^%]*\\includeonly' "$ARCHIVO_TEX"; then
    aviso "el main.tex tiene un \\includeonly: la composición es parcial y las páginas no se guardan"
else
    temporal="$TSV_PAGINACION.tmp"
    mkdir -p "$DIR_PROYECTO/tmp" || morir "No se pudo crear $DIR_PROYECTO/tmp"
    total="$(pdfinfo "$PDF_FINAL" 2>/dev/null | grep -oP '^Pages:\s+\K\d+')"
    filas="$(perl "$DIR_ENGINE/paginacion_libro.pl" "$ARCHIVO_TEX" "$DIR_AUX" 2>"$temporal.err")"
    codigo=$?
    # LAS PÁGINAS ESPECIALES NO TIENEN FOLIO: SE NOMBRAN Y NO CUENTAN
    grep -P '^especial\t' "$temporal.err" | cut -f2 | while read -r pieza; do
        tenue "$pieza: página especial, sin folio"
    done
    if (( codigo != 0 )) || [[ -z "$total" ]]; then
        grep -vP '^especial\t' "$temporal.err" | cut -f2,3 | sed 's/\t/: /; s/^/     /'
        [[ -z "$total" ]] && echo "     pdfinfo no devolvió la cantidad de páginas del PDF"
        aviso "no se pudieron leer las páginas: no se guardan en la base"
    else
        # if Y NO &&: UN && FALSO AL FINAL DEL GRUPO LE DARÍA 1 AL GRUPO
        # ENTERO Y EL mv NO SE HARÍA (GV-23)
        {
            printf '# archivo\tid_capitulo\tinicio\tfin\tpaginas\n'
            printf '(libro)\t-\t-\t-\t%s\n' "$total"
            if [[ -n "$filas" ]]; then printf '%s\n' "$filas"; fi
        } > "$temporal" || morir "No se pudo escribir tmp/paginacion-libro.tsv"
        mv -f "$temporal" "$TSV_PAGINACION" || morir "No se pudo escribir tmp/paginacion-libro.tsv"
        ok "tmp/paginacion-libro.tsv: $(grep -c . <<< "$filas") pieza(s) con folio; el libro, $total página(s)"
    fi
    rm -f "$temporal" "$temporal.err"
fi

echo
terminar
