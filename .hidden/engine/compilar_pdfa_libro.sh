#!/bin/bash
# Compilador de la salida PDF/A de libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Lo lanza Gambas con m_GenerarSalidasLibro.EjecutarScriptSalida (SC-53), en
# el terminal del proyecto.
#
# QUÉ HACE Y QUÉ NO
#   Compila el maestro envolvente que escribe Gambas en latex/pdfa/:
#     \DocumentMetadata{pdfstandard=A-2u, lang=…}
#     \def\gbPerfilPreservacion{}
#     \input{main}
#   NO regenera nada: ni el main.tex ni las piezas. El PDF/A se hace cuando el
#   libro ya está publicado, y tiene que ser ESE libro. Por eso tampoco llama
#   a preparar_latex_libro.sh, a diferencia de compilar_pdf_libro.sh.
#   \gbPerfilPreservacion hace que el preámbulo derivado use el perfil de
#   preservación (sin marcas de trabajo ni cruces de corte), cualquiera sea el
#   estado editorial con que se generó.
#
#   Los auxiliares van a latex/pdfa/ y no a latex/: los .idx tienen nombre
#   fijo y pisarían los del PDF estándar.
#
#   Después de compilar valida con veraPDF el nivel pedido. Solo un PDF
#   conforme pasa a salidas/pdf/; entonces latex/pdfa/ se borra. Si no es
#   conforme, todo queda en latex/pdfa/ para revisarlo: en salidas/ nunca hay
#   un archivo que declare PDF/A sin cumplirlo.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  PDF/A conforme, sin avisos
#   3  PDF/A conforme, con avisos de compilación (citas, índices, referencias)
#   1  no se generó, o veraPDF dice que no es conforme
#
# USO
#   compilar_pdfa_libro.sh <ruta_proyecto> <nombre_bib> <nombre_salida>
#                          <maestro_rel> <nivel>
#
#   ruta_proyecto   raíz del proyecto
#   nombre_bib      nombre del .bib dentro de referencias/, con extensión
#   nombre_salida   nombre del PDF final, sin extensión (l-CALIFA_pdfa2u). Es
#                   también el nombre del maestro: así dc:source, que con
#                   \DocumentMetadata es el nombre del trabajo, dice de qué
#                   libro es
#   maestro_rel     el maestro envolvente, relativo al proyecto
#   nivel           el nivel de veraPDF: 2u
# ============================================================================

set -uo pipefail

# --- 1. FUNCIONES COMPARTIDAS ---
DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
if ! source "$DIR_ENGINE/compilar_latex_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/compilar_latex_comun.sh" >&2
    exit 1
fi
# LA BÚSQUEDA DE veraPDF Y validar_pdfa: COMPARTIDAS CON
# generar_pdf_revista.sh (A1.2a)
if ! source "$DIR_ENGINE/verapdf_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/verapdf_comun.sh" >&2
    exit 1
fi

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

# --- 2. ARGUMENTOS ---
if (( $# < 5 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib> <nombre_salida> <maestro_rel> <nivel>"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"
NOMBRE_SALIDA="$3"
MAESTRO="$4"
NIVEL="$5"
NIVEL_VISIBLE="PDF/A-$NIVEL"

encabezado "GENERACIÓN DE LA SALIDA $NIVEL_VISIBLE"

BASE="$(basename "$MAESTRO" .tex)"
DIR_LATEX="$DIR_PROYECTO/latex"
DIR_AUX="$DIR_PROYECTO/$(dirname "$MAESTRO")"
ARCHIVO_LOG="$DIR_AUX/$BASE.log"
ARCHIVO_PDF="$DIR_AUX/$BASE.pdf"
ARCHIVO_BIB="$DIR_PROYECTO/referencias/$NOMBRE_BIB"
DIR_SALIDA="$DIR_PROYECTO/salidas/pdf"
PDF_FINAL="$DIR_SALIDA/$NOMBRE_SALIDA.pdf"
HAY_BIB=0

# --- 3. VERIFICACIONES ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]          || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -f "$DIR_LATEX/main.tex" ]]    || morir "No existe latex/main.tex — generá primero el PDF estándar"
[[ -f "$DIR_PROYECTO/$MAESTRO" ]] || morir "No existe el maestro $MAESTRO"

# EL AUXILIAR SE BORRA ENTERO AL TERMINAR: TIENE QUE SER UNA SUBCARPETA DE
# latex/, NUNCA latex/ MISMO NI OTRA COSA
[[ "$DIR_AUX" == "$DIR_LATEX"/?* ]] || morir "El maestro tiene que estar en una subcarpeta de latex/: $MAESTRO"

verificar_herramientas_latex

# SIN veraPDF NO SE PUEDE AFIRMAR LA NORMA: NO SE COMPILA EN VANO
VERAPDF="$(buscar_verapdf)"
[[ -n "$VERAPDF" ]] || morir "No se encontró veraPDF (PATH, /opt/verapdf, ~/verapdf): sin él no se puede verificar el $NIVEL_VISIBLE"
ok "veraPDF: $VERAPDF"

verificar_bib

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Maestro:"  "$MAESTRO"
printf '  %-14s %s\n'   "Salida:"   "$NOMBRE_SALIDA.pdf"

# --- 4. LIMPIEZA Y COMPILACIÓN ---
limpiar_auxiliares
secuencia_compilacion
verificar_referencias_cruzadas

[[ -f "$ARCHIVO_PDF" ]] || morir "No se generó el PDF"

# --- 5. VALIDACIÓN ---
paso "validando $NIVEL_VISIBLE con veraPDF"

informe=$(validar_pdfa)
codigo=$?

perfil=$(printf '%s\n' "$informe" | grep -oP '^PERFIL\t\K.*')
[[ -n "$perfil" ]] && tenue "$perfil"

if (( codigo == 1 )); then
    morir "veraPDF no devolvió un informe legible: el PDF queda en $(dirname "$MAESTRO")/"
fi

if (( codigo != 0 )); then
    fallidas=$(printf '%s\n' "$informe" | grep -oP '^FALLIDAS\t\K.*')
    printf '  %s✗%s no es conforme: %s regla(s) fallida(s)\n' "$C_ERROR" "$C_RESET" "$fallidas"
    printf '%s\n' "$informe" | grep -oP '^REGLA\t\K.*' | sed 's/^/     /'
    morir "El PDF no es $NIVEL_VISIBLE: queda en $(dirname "$MAESTRO")/ para revisarlo"
fi

ok "conforme"

# --- 6. ENTREGA ---
# SOLO UN PDF CONFORME LLEGA A salidas/. EL NOMBRE YA LO DISTINGUE DEL PDF
# ESTÁNDAR (l-CALIFA_pdfa2u.pdf JUNTO A l-CALIFA.pdf)
echo
titulo "$REGLA"

mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
mv -f "$ARCHIVO_PDF" "$PDF_FINAL" || morir "No se pudo mover el PDF a salidas/pdf"

resumen_pdf "$PDF_FINAL"

# --- 7. LIMPIEZA DEL ÁREA DE TRABAJO ---
# CONFORME Y ENTREGADO, latex/pdfa/ YA NO TIENE NADA QUE REVISAR: GAMBAS
# VUELVE A ESCRIBIR EL MAESTRO EN CADA GENERACIÓN. LA GUARDA DEL APARTADO 3
# ASEGURA QUE ES UNA SUBCARPETA DE latex/
rm -rf -- "$DIR_AUX"
tenue "área de trabajo $(dirname "$MAESTRO")/ eliminada"

echo
terminar
