#!/bin/bash
# Citas y referencias del número de revista para el EPUB — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
# Etapa E1 de las salidas de revistas (claude/salidas-revistas.md), decisión
# de Alberto del 14/11/2026: script propio, gemelo de preparar_citas_libro.sh,
# que parte del canónico JATS y del volcado del número.
#
# USO
#   preparar_citas_revista.sh <ruta_proyecto> <nombre_bib> <carpeta_rel>
#
#   ruta_proyecto   raíz del proyecto
#   nombre_bib      el .bib del proyecto en referencias/, con extensión
#                   (m_Bibtex.NombreArchivoBib, como el PDF)
#   carpeta_rel     ruta relativa al proyecto de la carpeta de salida, dentro
#                   de tmp/ (tmp/bib/epub-revista). SE VACÍA Y SE REESCRIBE
#
# LOS INSUMOS
#   El volcado del número (tmp/numero-datos.xml, versión 4) y los canónicos
#   (jats/c-{archivo}.xml) de sus artículos. Los escribe gbpublisher; el
#   script del EPUB regenera los canónicos antes de llamar a este. Los
#   cita-<estilo>-config.tex, cita-<estilo>-html.tex y cita-cadenas-es.tex
#   los copia al proyecto la aplicación (latex/), como para el PDF. Este
#   script no toca la base.
# ============================================================================
# QUÉ HACE (SC-57)
#
#   1. numero-a-latex.xsl escribe citas-proyecto.tex en la carpeta: las
#      mismas definiciones que el preámbulo del número del PDF (idiomas,
#      nombres de babel, estilo, .bib).
#   2. Por cada artículo del volcado, jats-a-latex-citas.xsl escribe
#      c-{archivo}.tex: sus citas, cada grupo como \gbcita{id}{comando}, en su
#      refsection, con su bibliografía; y su «cómo citar», con el .bib que
#      escribe la misma plantilla que el PDF.
#   3. Arma el documento mínimo citas.tex y make4ht lo compila con
#      cita-tex4ht.cfg (lualatex, biber, lualatex dos veces): citas.html.
#   4. Verifica el producto: XML bien formado, sin errores de biber, una
#      marca gbcita-* por cada \gbcita y una gbbib-* por cada bibliografía.
#
# EL TEXTO LO ESCRIBE biblatex, con el estilo, la configuración y el .bib del
# PDF. La hoja del EPUB no arma el texto de una cita: lo toma de citas.html.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  citas.html listo
#   3  listo, con avisos (una cita sin entrada en el .bib)
#   1  algún artículo falló, o la compilación no dio el producto
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
# CUATRO PASADAS DE LuaLaTeX Y UNA DE biber SOBRE UN DOCUMENTO CHICO
TIEMPO_MAKE4HT=900
XSL_CITAS="$DIR_RECURSOS/xslt/jats-a-latex-citas.xsl"
XSL_NUMERO="$DIR_RECURSOS/xslt/numero-a-latex.xsl"
CFG="$DIR_RECURSOS/latex/cita-tex4ht.cfg"
# EL VOLCADO: LA MISMA RUTA Y VERSIÓN QUE m_CanonicoRevista. SI CAMBIAN
# ALLÁ, CAMBIAN ACÁ (Y EN LOS OTROS LECTORES)
VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="4"

# ============================================================================
# Función   : fallo
# Propósito : Informa el fallo de UN artículo sin terminar el script: morir()
#             saldría de la preparación entera.
# Parámetros: $1 mensaje
# ============================================================================
fallo() {
    printf '  %s✗%s %s\n' "$C_ERROR" "$C_RESET" "$1"
}

# ============================================================================
# Función   : dato_volcado
# Propósito : Un valor del volcado, por XPath (la de generar_pdf_revista.sh).
# Parámetros: $1 expresión XPath que devuelve una cadena
# Retorna   : imprime el valor; vacío si no hay
# ============================================================================
dato_volcado() {
    xmllint --xpath "$1" "$VOLCADO" 2>/dev/null
}

# ============================================================================
# Función   : preparar_articulo
# Propósito : Las citas de un artículo, en la carpeta de salida.
# Parámetros: $1 archivo (a-01-…)
# Retorna   : 0 si escribió c-{archivo}.tex; 1 si no
# ============================================================================
preparar_articulo() {
    local archivo="$1"
    local canonico="$DIR_PROYECTO/jats/c-$archivo.xml"
    local tex="$CARPETA/c-$archivo.tex"
    local salida codigo

    # --- A. CANÓNICO: BIEN FORMADO Y NO SOLO PRESENTE ---
    if [[ ! -f "$canonico" ]]; then
        fallo "no existe jats/c-$archivo.xml: generá primero su canónico"
        return 1
    fi
    if ! bien_formado "$canonico"; then
        fallo "jats/c-$archivo.xml está mal formado: regenerá su canónico"
        return 1
    fi

    # --- B. TRANSFORMACIÓN: LAS CITAS Y EL .bib DEL «CÓMO CITAR» ---
    # EL .bib QUEDA AL LADO DE c-{archivo}.tex (xsl:result-document RELATIVO
    # A LA SALIDA)
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$canonico" \
                -xsl:"$XSL_CITAS" \
                -o:"$tex" \
                archivo="$archivo" \
                bib_cita="cita-$archivo.bib" 2>&1)
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
    if [[ ! -f "$tex" ]]; then
        fallo "la transformación no produjo salida"
        return 1
    fi
    # LOS xsl:message QUE NO TERMINAN LA TRANSFORMACIÓN LLEGAN CON CÓDIGO 0
    if [[ -n "$salida" ]]; then
        tenue "mensajes de la transformación:"
        mostrar_cola "$salida" 10
    fi

    ok "c-$archivo.tex ($(grep -c '\\gbcita{' "$tex") grupo(s) de citas y su cómo citar)"
    return 0
}

# ============================================================================
# Función   : escribir_documento
# Propósito : Escribe citas.tex, el documento mínimo de la pasada (SC-57).
# Nota      : NO CARGA EL CONTRATO NI LA ESTÉTICA: SOLO LO QUE DECIDE EL
#             TEXTO DE UNA CITA. LAS DEFINICIONES SON LAS DEL PREÁMBULO DEL
#             NÚMERO DEL PDF (numero-a-latex.xsl).
# ============================================================================
escribir_documento() {
    local archivo
    {
        echo "% ============================================================"
        echo "% citas.tex — DOCUMENTO MÍNIMO DE LA PASADA DE tex4ht (SC-57)"
        echo "% LO ESCRIBE preparar_citas_revista.sh: NO SE EDITA A MANO"
        echo "% ============================================================"
        echo "\\documentclass{article}"
        echo "\\input{citas-proyecto}"
        echo "\\usepackage{fontspec}"
        echo "% EL MISMO IDIOMA Y LAS MISMAS COMILLAS QUE EL PDF"
        echo "% (preambulo-contrato-comun.tex, SECCIÓN IDIOMA)"
        echo "\\usepackage[\\gbidiomas]{babel}"
        echo "\\usepackage[autostyle=true]{csquotes}"
        echo "\\input{cita-\\estandar-config.tex}"
        echo "\\input{cita-cadenas-es.tex}"
        echo "\\input{cita-\\estandar-html.tex}"
        echo "% EL .bib SE COPIA A LA CARPETA: \\gbarchivobib ES RELATIVO A LA"
        echo "% RAÍZ DEL PROYECTO, Y ESTE DOCUMENTO SE COMPILA EN OTRO LUGAR"
        echo "\\addbibresource{$BIB_NOMBRE}"
        echo "\\usepackage{hyperref}"
        echo "% EL IDIOMA DE CADA ARTÍCULO POR SU CÓDIGO, COMO EL PDF (CONTRATO"
        echo "% DE REVISTA 3, 4.0): EL NOMBRE DE babel LO DA citas-proyecto"
        echo "\\makeatletter"
        echo "\\newcommand*{\\gbselectlanguage}[1]{%"
        echo "  \\edef\\gb@idioma{\\noexpand\\selectlanguage{\\csname gbbabel@#1\\endcsname}}%"
        echo "  \\gb@idioma}"
        echo "\\makeatother"
        echo "% EN UNA COMPILACIÓN COMÚN SOLO ENVUELVE; cita-tex4ht.cfg LA"
        echo "% REDEFINE COMO <span id=\"gbcita-...\">"
        echo "\\newcommand*{\\gbcita}[2]{#2}"
        echo "% LA MARCA DE CADA BIBLIOGRAFÍA: EN UNA COMPILACIÓN COMÚN NO"
        echo "% ESCRIBE NADA; cita-tex4ht.cfg LA REDEFINE COMO <span id=\"gbbib-...\">"
        echo "\\newcommand*{\\gbbibliografia}[1]{}"
        echo "\\begin{document}"
        for archivo in "${ARTICULOS[@]}"; do
            echo "\\input{c-$archivo}"
        done
        echo "\\end{document}"
    } > "$CARPETA/citas.tex"
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "CITAS Y REFERENCIAS DEL NÚMERO PARA EL EPUB"

# --- 2. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib> <carpeta_rel>"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"
CARPETA_REL="${3%/}"
CARPETA="$DIR_PROYECTO/$CARPETA_REL"
DIR_LATEX="$DIR_PROYECTO/latex"
VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"

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
# EL NOMBRE DEL .bib VA A UNA RUTA
[[ "$NOMBRE_BIB" == */* ]] && morir "Nombre de .bib no válido: $NOMBRE_BIB"

requerir_comandos java xmllint timeout make4ht lualatex biber

[[ -f "$RUTA_SAXON" ]]  || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL_CITAS" ]]   || morir "Falta la hoja $XSL_CITAS: reinstalá gbpublisher"
[[ -f "$XSL_NUMERO" ]]  || morir "Falta la hoja $XSL_NUMERO: reinstalá gbpublisher"
[[ -f "$CFG" ]]         || morir "No se encontró la configuración de tex4ht: $CFG"

# EL VOLCADO
[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"
ESTILO="$(dato_volcado 'normalize-space(/numero-datos/revista/estilo-cita)')"
[[ -n "$ESTILO" ]] || morir "La revista no tiene estilo de cita: elegilo en la ficha de la revista"

BIB="$DIR_PROYECTO/referencias/$NOMBRE_BIB"
[[ -f "$BIB" ]] || morir "No existe referencias/$NOMBRE_BIB: lo exporta gbpublisher antes de generar"
BIB_NOMBRE="$NOMBRE_BIB"

CONFIG_ESTILO="$DIR_LATEX/cita-$ESTILO-config.tex"
PANTALLA_ESTILO="$DIR_LATEX/cita-$ESTILO-html.tex"
CADENAS="$DIR_LATEX/cita-cadenas-es.tex"
[[ -f "$CONFIG_ESTILO" ]] || morir "No existe latex/cita-$ESTILO-config.tex: reabrí el proyecto para que la aplicación copie los recursos de LaTeX"
[[ -f "$CADENAS" ]]       || morir "No existe latex/cita-cadenas-es.tex: reabrí el proyecto para que la aplicación copie los recursos de LaTeX"
# CADA ESTILO TIENE SU VERSIÓN DE PANTALLA (MEDIDOS LOS CINCO EN E0, 14/11)
[[ -f "$PANTALLA_ESTILO" ]] ||
    morir "El estilo $ESTILO no tiene versión para pantalla (latex/cita-$ESTILO-html.tex): reabrí el proyecto para que la aplicación copie los recursos de LaTeX"

ok "herramientas, hojas, configuración e insumos"
tenue "volcado versión $version · estilo: $ESTILO · bibliografía: referencias/$NOMBRE_BIB"

# --- 4. LOS ARTÍCULOS, EN EL ORDEN DEL VOLCADO (EL MANIFIESTO) ---
mapfile -t ARTICULOS < <(dato_volcado '/numero-datos/articulo/@archivo' | grep -oP 'archivo="\K[^"]+')
(( ${#ARTICULOS[@]} > 0 )) || morir "El número no tiene artículos con metadatos"
for a in "${ARTICULOS[@]}"; do
    # EL MISMO CONTROL QUE generar_pdf_revista.sh: EL NOMBRE VA A RUTAS
    [[ "$a" =~ ^a-[A-Za-z0-9._-]+$ ]] || morir "Nombre de artículo no válido en el volcado: «$a»"
done
tenue "${#ARTICULOS[@]} artículo(s)"

# --- 5. CARPETA LIMPIA: UN ARCHIVO DE UNA CORRIDA ANTERIOR NO SE MEZCLA ---
rm -rf "$CARPETA"
mkdir -p "$CARPETA" || morir "No se pudo crear $CARPETA_REL"

# --- 6. LAS DEFINICIONES: LAS DEL PREÁMBULO DEL NÚMERO DEL PDF ---
paso "definiciones del número"
# numero-a-latex.xsl ESCRIBE TAMBIÉN UN main POR ARTÍCULO AL LADO DE SU
# SALIDA: ACÁ NO SIRVEN Y SE BORRAN
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$VOLCADO" -xsl:"$XSL_NUMERO" \
            -o:"$CARPETA/citas-proyecto.tex" bib="$NOMBRE_BIB" 2>&1) || {
    mostrar_cola "$salida"
    morir "numero-a-latex.xsl no pudo escribir las definiciones"
}
rm -f "$CARPETA"/main-*.tex
[[ -s "$CARPETA/citas-proyecto.tex" ]] || morir "numero-a-latex.xsl no escribió las definiciones"
ok "citas-proyecto.tex"

# --- 7. ARTÍCULOS ---
FALLIDOS=()
for (( i = 0; i < ${#ARTICULOS[@]}; i++ )); do
    paso "$((i + 1))/${#ARTICULOS[@]}  ${ARTICULOS[$i]}"
    preparar_articulo "${ARTICULOS[$i]}" || FALLIDOS+=("${ARTICULOS[$i]}")
done
if (( ${#FALLIDOS[@]} > 0 )); then
    echo
    printf '  No se prepararon (motivo arriba, en cada uno):\n'
    printf '    %s\n' "${FALLIDOS[@]}"
    morir "${#FALLIDOS[@]} artículo(s) con problemas: no se compiló la pasada"
fi

# --- 8. DOCUMENTO MÍNIMO E INSUMOS EN LA CARPETA ---
paso "documento mínimo"
cp -f "$CONFIG_ESTILO" "$CADENAS" "$PANTALLA_ESTILO" "$CFG" "$CARPETA/" ||
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
# UNA BIBLIOGRAFÍA POR ARTÍCULO, TENGA O NO CITAS: LA MARCA SALE IGUAL
BIBS_ESPERADAS=$(cat "$CARPETA"/c-*.tex 2>/dev/null | grep -o '\\gbbibliografia{' | wc -l)
ok "citas.tex: ${#ARTICULOS[@]} artículo(s), $ESPERADAS marca(s) de cita, $BIBS_ESPERADAS bibliografía(s)"

# --- 9. COMPILACIÓN ---
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

# --- 10. VERIFICACIÓN DEL PRODUCTO ---
paso "verificando citas.html"
HTML="$CARPETA/citas.html"
[[ -s "$HTML" ]]     || morir "make4ht terminó sin escribir citas.html"
bien_formado "$HTML" || morir "citas.html está mal formado: el EPUB no lo podría leer"

# biber: UN ERROR DEJA LA BIBLIOGRAFÍA VACÍA SIN QUE make4ht LO DIGA
if [[ -f "$CARPETA/citas.blg" ]] && grep -q '^ERROR' "$CARPETA/citas.blg"; then
    mostrar_cola "$(grep '^ERROR' "$CARPETA/citas.blg")"
    morir "biber terminó con errores (registro: $CARPETA_REL/citas.blg)"
fi

# CADA \gbcita TIENE QUE LLEGAR COMO UNA MARCA: SI FALTA UNA, LA HOJA DEL
# EPUB CORTARÍA LEJOS DE LA CAUSA
OBTENIDAS=$(grep -o 'id=.gbcita-' "$HTML" | wc -l)
if (( OBTENIDAS != ESPERADAS )); then
    morir "citas.html trae $OBTENIDAS marca(s) de cita y los artículos tienen $ESPERADAS"
fi
BIBS_OBTENIDAS=$(grep -o 'id=.gbbib-' "$HTML" | wc -l)
if (( BIBS_OBTENIDAS != BIBS_ESPERADAS )); then
    morir "citas.html trae $BIBS_OBTENIDAS marca(s) de bibliografía y se esperaban $BIBS_ESPERADAS"
fi
ok "$OBTENIDAS marca(s) de cita, $BIBS_OBTENIDAS bibliografía(s), XML bien formado"

# UNA CLAVE QUE NO ESTÁ EN EL .bib: EL PDF LA COMPONE COMO CLAVE EN NEGRITA
# Y AVISA; ACÁ SE AVISA IGUAL Y LA SALIDA SIGUE
if grep -q "Citation '.*' .*undefined" "$CARPETA/citas.log" 2>/dev/null; then
    aviso "hay citas sin entrada en el .bib: $(grep -o "Citation '[^']*'" "$CARPETA/citas.log" | sort -u | sed "s/Citation //" | tr '\n' ' ')"
fi

# --- 11. RESUMEN ---
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
