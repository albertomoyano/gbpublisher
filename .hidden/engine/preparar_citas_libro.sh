#!/bin/bash
# Citas y referencias del libro para HTML y EPUB — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   preparar_citas_libro.sh <ruta_proyecto> <lista_rel> <insumos_rel> <carpeta_rel>
#
#   ruta_proyecto   raíz del proyecto
#   lista_rel       ruta relativa al proyecto de la lista de piezas con
#                   cuerpo, una por línea, en el orden del libro: la MISMA
#                   que usa el PDF (tmp/latex-piezas.txt)
#   insumos_rel     ruta relativa al proyecto de las definiciones de idioma
#                   y de bibliografía (tmp/citas-proyecto.tex): \gbidiomas,
#                   \estandar, \gbarchivobib, \ifgbbibporcapitulo
#   carpeta_rel     ruta relativa al proyecto de la carpeta de salida:
#                   tmp/bib/html-libro-<nombre> o tmp/bib/epub-libro-<nombre>.
#                   SE VACÍA Y SE REESCRIBE ENTERA
#
# LOS INSUMOS LOS ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT
# (m_GenerarPDFLibro.EscribirInsumosCitas): la lista, las definiciones y el
# .bib de referencias/. La lista y las definiciones salen de las MISMAS
# funciones que usa el PDF (LeerPiezasLibro, ListaPiezasConCuerpo,
# DefinicionesCita): HTML y EPUB citan con los mismos datos, sin heredar los
# requisitos de imprenta del PDF. Los cita-<estilo>-config.tex y cita-<estilo>-html.tex los copia al
# proyecto m_InicioCierre.CopiarRecursosLatex. Este script no toca la base.
# ============================================================================
# QUÉ HACE (SC-57)
#
#   1. Por cada pieza de la lista, docbook-to-latex-citas.xsl escribe en la
#      carpeta c-{nombre}.tex: solo sus citas, cada grupo como
#      \gbcita{id}{comando}, con los mismos refsection que el PDF.
#   2. Arma el documento mínimo citas.tex: las definiciones, babel,
#      csquotes, el estilo, su archivo de pantalla y las piezas en orden.
#   3. make4ht lo compila con cita-tex4ht.cfg (lualatex, biber, lualatex
#      dos veces). El producto es citas.html.
#   4. Verifica el producto: XML bien formado, una marca gbcita-* por cada
#      \gbcita de las piezas y una gbbib-* por cada bibliografía.
#
# EL TEXTO LO ESCRIBE biblatex
#
#   Las citas y las referencias de HTML y EPUB salen del mismo estilo, con la
#   misma configuración y el mismo .bib que el PDF. Las hojas de HTML y EPUB
#   no arman el texto de una cita: lo toman de citas.html por su id.
#
# CUANDO UNA PIEZA FALLA
#
#   Se sigue con las demás y al final se listan todas (criterio de
#   preparar_latex_libro.sh). Con una pieza fallida no se compila: un
#   citas.html con piezas de menos haría que HTML y EPUB cortaran por citas
#   que no encuentran, lejos de la causa.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  citas.html listo
#   3  listo, con avisos (una cita sin entrada en el .bib)
#   1  alguna pieza falló, o la compilación no dio el producto
#   EN LA ÚLTIMA LÍNEA DE stdout, CUÁNTAS CITAS TIENE citas.html.
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_SAXON=300
# CUATRO PASADAS DE LuaLaTeX Y UNA DE biber SOBRE UN DOCUMENTO CHICO: EN EL
# LIBRO DE DUEK (132 CITAS, 113 REFERENCIAS) TARDÓ 13 SEGUNDOS
TIEMPO_MAKE4HT=900
XSL="$DIR_GBP_LOCAL/xslt/docbook-to-latex-citas.xsl"
CFG="$DIR_GBP_LOCAL/latex/cita-tex4ht.cfg"

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
# Propósito : Las citas de una pieza, en la carpeta de salida.
# Parámetros: $1 nombre_archivo
# Retorna   : 0 si escribió c-{nombre}.tex; 1 si no
# ============================================================================
preparar_pieza() {
    local nombre="$1"
    local canonico="$DIR_PROYECTO/jats/c-$nombre.xml"
    local tex="$CARPETA/c-$nombre.tex"
    local estilo_pieza
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

    # EL ESTILO DEL CANÓNICO TIENE QUE SER EL DE LAS DEFINICIONES: CON OTRO,
    # LAS CITAS SE AGRUPARÍAN DISTINTO QUE EN EL PDF Y LOS id NO
    # COINCIDIRÍAN (SC-57). FALTA EN LOS CANÓNICOS ANTERIORES A ESTA REGLA
    estilo_pieza="$(estilo_canonico "$canonico")"
    if [[ "$estilo_pieza" != "$ESTILO" ]]; then
        fallo "el canónico declara el estilo «${estilo_pieza:-ninguno}» y el libro usa «$ESTILO»: regenerá el canónico"
        return 1
    fi

    # --- B. TRANSFORMACIÓN ---
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$canonico" \
                -xsl:"$XSL" \
                -o:"$tex" 2>&1)
    codigo=$?

    if (( codigo == 124 )); then
        rm -f "$tex"
        fallo "Saxon no terminó en $TIEMPO_SAXON segundos"
        return 1
    fi
    if (( codigo != 0 )); then
        mostrar_cola "$salida"
        rm -f "$tex"
        fallo "falló la transformación de las citas"
        return 1
    fi
    # UNA PIEZA SIN CITAS DA UN ARCHIVO CORTO PERO NO VACÍO: SU \chapter*
    # (O NADA, SI ES PÁGINA ESPECIAL). POR ESO SE PIDE QUE EXISTA, NO TAMAÑO
    if [[ ! -f "$tex" ]]; then
        fallo "la transformación no produjo salida"
        return 1
    fi

    # LOS xsl:message QUE NO TERMINAN LA TRANSFORMACIÓN LLEGAN CON CÓDIGO 0
    if [[ -n "$salida" ]]; then
        tenue "mensajes de la transformación:"
        mostrar_cola "$salida" 10
    fi

    ok "c-$nombre.tex ($(grep -c '\\gbcita{' "$tex") citas)"
    return 0
}

# ============================================================================
# Función   : escribir_documento
# Propósito : Escribe citas.tex, el documento mínimo de la pasada (SC-57).
# Nota      : NO CARGA EL CONTRATO NI LA ESTÉTICA: SOLO LO QUE DECIDE EL
#             TEXTO DE UNA CITA. EL IDIOMA, EL ESTILO Y EL .bib SALEN DE
#             citas-proyecto.tex, CON LAS DEFINICIONES DEL PREÁMBULO DEL PDF.
# ============================================================================
escribir_documento() {
    local nombre
    {
        echo "% ============================================================"
        echo "% citas.tex — DOCUMENTO MÍNIMO DE LA PASADA DE tex4ht (SC-57)"
        echo "% LO ESCRIBE preparar_citas_libro.sh: NO SE EDITA A MANO"
        echo "% ============================================================"
        echo "\\documentclass{book}"
        echo "\\input{citas-proyecto}"
        echo "\\usepackage{fontspec}"
        echo "% EL MISMO IDIOMA Y LAS MISMAS COMILLAS QUE EL PDF"
        echo "% (preambulo-contrato.tex, SECCIÓN IDIOMA)"
        echo "\\usepackage[\\gbidiomas]{babel}"
        echo "\\usepackage[autostyle=true]{csquotes}"
        echo "\\input{cita-\\estandar-config.tex}"
        echo "\\input{cita-\\estandar-html.tex}"
        echo "% EL .bib SE COPIA A LA CARPETA: \\gbarchivobib ES RELATIVO A LA"
        echo "% RAÍZ DEL PROYECTO, Y ESTE DOCUMENTO SE COMPILA EN OTRO LUGAR"
        echo "\\addbibresource{$BIB_NOMBRE}"
        echo "\\usepackage{hyperref}"
        echo "% EN UNA COMPILACIÓN COMÚN SOLO ENVUELVE; cita-tex4ht.cfg LA"
        echo "% REDEFINE COMO <span id=\"gbcita-...\">"
        echo "\\newcommand*{\\gbcita}[2]{#2}"
        echo "% LA MARCA DE CADA BIBLIOGRAFÍA: EN UNA COMPILACIÓN COMÚN NO"
        echo "% ESCRIBE NADA; cita-tex4ht.cfg LA REDEFINE COMO <span id=\"gbbib-...\">"
        echo "\\newcommand*{\\gbbibliografia}[1]{}"
        echo "\\begin{document}"
        for nombre in "${PIEZAS[@]}"; do
            echo "\\input{c-$nombre}"
        done
        echo "% BIBLIOGRAFÍA CONSOLIDADA: UNA SOLA, AL FINAL, COMO EN EL PDF."
        echo "% POR CAPÍTULO LA CIERRA CADA PIEZA EN SU refsection (GV-102)"
        echo "\\ifgbbibporcapitulo\\else\\gbbibliografia{libro}\\gbImprimirBibliografia\\fi"
        echo "\\end{document}"
    } > "$CARPETA/citas.tex"
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "CITAS Y REFERENCIAS PARA HTML Y EPUB"

# --- 2. ARGUMENTOS ---
if (( $# < 4 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <lista_rel> <insumos_rel> <carpeta_rel>"
fi

DIR_PROYECTO="${1%/}"
LISTA="$DIR_PROYECTO/$2"
INSUMOS_REL="$3"
INSUMOS="$DIR_PROYECTO/$INSUMOS_REL"
CARPETA_REL="${4%/}"
CARPETA="$DIR_PROYECTO/$CARPETA_REL"
DIR_LATEX="$DIR_PROYECTO/latex"

# --- 3. ENTORNO E INSUMOS ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]      || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/jats" ]] || morir "El proyecto no tiene carpeta jats/"
# LA CARPETA DE SALIDA SE BORRA ENTERA: TIENE QUE QUEDAR DENTRO DE tmp/
case "$CARPETA_REL" in
    tmp/?*) ;;
    *) morir "La carpeta de salida tiene que estar dentro de tmp/: $CARPETA_REL" ;;
esac
[[ "$CARPETA_REL" == *..* ]] && morir "La carpeta de salida no puede tener «..»: $CARPETA_REL"

requerir_comandos java xmllint timeout make4ht lualatex biber

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de citas: $XSL"
[[ -f "$CFG" ]]        || morir "No se encontró la configuración de tex4ht: $CFG"
[[ -f "$LISTA" ]]      || morir "No existe la lista de piezas: $LISTA"
[[ -f "$INSUMOS" ]]    || morir "No existe $INSUMOS_REL: lo escribe Gambas antes de esta pasada"

# EL ESTILO Y EL .bib, TAL COMO LOS DECLARAN LAS DEFINICIONES DEL PROYECTO
ESTILO=$(sed -n 's/^\\def\\estandar{\([^}]*\)}.*$/\1/p' "$INSUMOS" | head -n 1)
[[ -n "$ESTILO" ]] || morir "$INSUMOS_REL no declara \\estandar"
BIB_REL=$(sed -n 's/^\\def\\gbarchivobib{\.\/\([^}]*\)}.*$/\1/p' "$INSUMOS" | head -n 1)
[[ -n "$BIB_REL" ]] || morir "$INSUMOS_REL no declara \\gbarchivobib"
BIB="$DIR_PROYECTO/$BIB_REL"
BIB_NOMBRE="$(basename "$BIB")"
[[ -f "$BIB" ]] || morir "No existe el .bib del proyecto: $BIB_REL"

CONFIG_ESTILO="$DIR_LATEX/cita-$ESTILO-config.tex"
PANTALLA_ESTILO="$DIR_LATEX/cita-$ESTILO-html.tex"
[[ -f "$CONFIG_ESTILO" ]] || morir "No existe latex/cita-$ESTILO-config.tex"
# UN ESTILO SIN ARCHIVO DE PANTALLA NO ENTRA POR ESTE CAMINO (SC-57: CADA
# ESTILO SE RELEVA ANTES; HOY, SOLO VERONA)
[[ -f "$PANTALLA_ESTILO" ]] ||
    morir "El estilo $ESTILO no tiene versión para pantalla (latex/cita-$ESTILO-html.tex): sus citas de HTML y EPUB no salen por esta pasada"

ok "herramientas, hoja, configuración e insumos"
tenue "estilo: $ESTILO · bibliografía: $BIB_REL"

# --- 4. LISTA ---
PIEZAS=()
while IFS= read -r nombre || [[ -n "$nombre" ]]; do
    [[ -z "$nombre" ]] && continue
    # UN NOMBRE CON / SALDRÍA DE LA CARPETA DEL PROYECTO
    [[ "$nombre" == */* ]] && morir "Nombre de pieza no válido en la lista: $nombre"
    PIEZAS+=("$nombre")
done < "$LISTA"
tenue "${#PIEZAS[@]} pieza(s) con cuerpo"

# --- 5. CARPETA LIMPIA: UN ARCHIVO DE UNA CORRIDA ANTERIOR NO SE MEZCLA ---
rm -rf "$CARPETA"
mkdir -p "$CARPETA" || morir "No se pudo crear $CARPETA_REL"

# --- 6. PIEZAS ---
FALLIDAS=()
for (( i = 0; i < ${#PIEZAS[@]}; i++ )); do
    paso "$((i + 1))/${#PIEZAS[@]}  ${PIEZAS[$i]}"
    preparar_pieza "${PIEZAS[$i]}" || FALLIDAS+=("${PIEZAS[$i]}")
done

if (( ${#FALLIDAS[@]} > 0 )); then
    echo
    printf '  No se prepararon (motivo arriba, en cada una):\n'
    printf '    %s\n' "${FALLIDAS[@]}"
    morir "${#FALLIDAS[@]} pieza(s) con problemas: no se compiló la pasada"
fi

# --- 7. DOCUMENTO MÍNIMO E INSUMOS EN LA CARPETA ---
paso "documento mínimo"
# LAS DEFINICIONES VAN CON NOMBRE FIJO: citas.tex LAS CARGA COMO citas-proyecto
cp -f "$INSUMOS" "$CARPETA/citas-proyecto.tex" ||
    morir "No se pudieron copiar las definiciones a $CARPETA_REL"
cp -f "$CONFIG_ESTILO" "$PANTALLA_ESTILO" "$CFG" "$CARPETA/" ||
    morir "No se pudieron copiar los insumos a $CARPETA_REL"
cp -f "$BIB" "$CARPETA/$BIB_NOMBRE" || morir "No se pudo copiar el .bib a $CARPETA_REL"
escribir_documento
# EL ARCHIVO DE COMPILACIÓN DE make4ht: biber ENTRE LA PRIMERA PASADA Y LAS
# OTRAS DOS, COMO EN EL PDF
printf '%s\n' \
    'Make:add("biber", "biber ${input}")' \
    'Make:htlatex {}' \
    'Make:biber {}' \
    'Make:htlatex {}' \
    'Make:htlatex {}' > "$CARPETA/citas.mk4"
ESPERADAS=$(cat "$CARPETA"/c-*.tex 2>/dev/null | grep -o '\\gbcita{' | wc -l)
# LAS BIBLIOGRAFÍAS: UNA POR PIEZA CON <bibliography>, O LA CONSOLIDADA.
# LA SEÑAL ES LA MISMA QUE LEE citas.tex: \gbbibporcapitulotrue|false
BIBS_ESPERADAS=$(cat "$CARPETA"/c-*.tex 2>/dev/null | grep -o '\\gbbibliografia{' | wc -l)
if grep -q '\\gbbibporcapitulofalse' "$INSUMOS"; then
    BIBS_ESPERADAS=$((BIBS_ESPERADAS + 1))
fi
ok "citas.tex: ${#PIEZAS[@]} pieza(s), $ESPERADAS cita(s), $BIBS_ESPERADAS bibliografía(s)"

# --- 8. COMPILACIÓN ---
paso "compilando con make4ht"
# EN LA CARPETA: make4ht ESCRIBE TODO DONDE CORRE
salida=$(cd "$CARPETA" && timeout "$TIEMPO_MAKE4HT" make4ht -l -u \
            -c cita-tex4ht.cfg -e citas.mk4 -f html5+common_domfilters citas.tex 2>&1)
codigo=$?
if (( codigo == 124 )); then
    morir "make4ht no terminó en $TIEMPO_MAKE4HT segundos"
fi
# make4ht SALE CON 0 AUNQUE biber FALLE: EL PRODUCTO SE VERIFICA ABAJO
if (( codigo != 0 )) || grep -q '\[ERROR\]' <<< "$salida"; then
    mostrar_cola "$(grep -A4 '\[ERROR\]' <<< "$salida")" 20
    morir "make4ht no pudo compilar citas.tex (registro: $CARPETA_REL/citas.log)"
fi

# --- 9. VERIFICACIÓN DEL PRODUCTO ---
paso "verificando citas.html"
HTML="$CARPETA/citas.html"
[[ -s "$HTML" ]]    || morir "make4ht terminó sin escribir citas.html"
bien_formado "$HTML" || morir "citas.html está mal formado: HTML y EPUB no lo podrían leer"

# biber: UN ERROR DEJA LA BIBLIOGRAFÍA VACÍA SIN QUE make4ht LO DIGA
if [[ -f "$CARPETA/citas.blg" ]] && grep -q '^ERROR' "$CARPETA/citas.blg"; then
    mostrar_cola "$(grep '^ERROR' "$CARPETA/citas.blg")"
    morir "biber terminó con errores (registro: $CARPETA_REL/citas.blg)"
fi

# CADA \gbcita DE LAS PIEZAS TIENE QUE LLEGAR COMO UNA MARCA: SI FALTA UNA,
# LA HOJA DE HTML O EPUB CORTARÍA LEJOS DE LA CAUSA
OBTENIDAS=$(grep -o 'id=.gbcita-' "$HTML" | wc -l)
if (( OBTENIDAS != ESPERADAS )); then
    morir "citas.html trae $OBTENIDAS marca(s) de cita y las piezas tienen $ESPERADAS"
fi
# LO MISMO CON LAS MARCAS DE BIBLIOGRAFÍA: SIN LA MARCA, LA HOJA NO SABE DE
# QUÉ PIEZA ES UNA LISTA
BIBS_OBTENIDAS=$(grep -o 'id=.gbbib-' "$HTML" | wc -l)
if (( BIBS_OBTENIDAS != BIBS_ESPERADAS )); then
    morir "citas.html trae $BIBS_OBTENIDAS marca(s) de bibliografía y se esperaban $BIBS_ESPERADAS"
fi
ok "$OBTENIDAS cita(s), $BIBS_OBTENIDAS bibliografía(s), XML bien formado"

# UNA CLAVE QUE NO ESTÁ EN EL .bib: EL PDF LA COMPONE COMO CLAVE EN NEGRITA
# Y AVISA; ACÁ SE AVISA IGUAL Y LA SALIDA SIGUE
if grep -q "Citation '.*' .*undefined" "$CARPETA/citas.log" 2>/dev/null; then
    aviso "hay citas sin entrada en el .bib: $(grep -o "Citation '[^']*'" "$CARPETA/citas.log" | sort -u | sed "s/Citation //" | tr '\n' ' ')"
fi

# --- 10. RESUMEN ---
if [[ -z "${GBP_ANIDADO:-}" ]]; then
    echo
    titulo "$REGLA"
    printf '%s✓ Citas y referencias listas%s\n' "$C_OK" "$C_RESET"
    printf '  %-14s %s\n' "Carpeta:" "$CARPETA"
    printf '  %-14s %s\n' "Estilo:"  "$ESTILO"
    printf '  %-14s %s\n' "Citas:"   "$OBTENIDAS"
    if (( AVISOS > 0 )); then
        printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
    fi
    echo
fi

echo "$OBTENIDAS"
terminar
