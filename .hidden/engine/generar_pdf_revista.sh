#!/bin/bash
# PDF de un número de revista y de sus artículos — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa A1.2a de las salidas de revistas (claude/salidas-revistas.md).
# Decisiones de Alberto del 07/11 (A1) y del 12/11/2026 (A1.2a). Desde B5
# (12/11/2026) el modo numero arma además el PDF del número: las
# preliminares que declara y los artículos incluidos con pdfpages.
#
# USO
#   generar_pdf_revista.sh <ruta_proyecto> <nombre_bib> numero [<pagina_inicial>]
#   generar_pdf_revista.sh <ruta_proyecto> <nombre_bib> articulo <archivo>
#
#   ruta_proyecto    raíz del proyecto
#   nombre_bib       el .bib del proyecto en referencias/, con extensión
#                    (m_Bibtex.NombreArchivoBib: único lugar donde se calcula)
#   numero           compone todos los artículos del número, en el orden del
#                    volcado (el manifiesto, decisión 10)
#   pagina_inicial   solo en el modelo por_volumen, y ahí obligatoria: dónde
#                    empieza el número. La calcula Gambas (numero.pagina_inicial
#                    o el número anterior del volumen), porque está en la base
#   articulo         la prueba del artículo en curso: compone solo ese, desde
#                    donde lo dejó la última composición del número (o desde 1)
#
# LOS INSUMOS LOS ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT (SC-13): el
# volcado del número (tmp/numero-datos.xml, versión 3), los reflist y el .bib.
# Este script no toca la base.
# ============================================================================
# QUÉ HACE
#
#   1. Regenera los canónicos de los artículos que compone
#      (generar_canonicos_articulos.sh, anidado). Los rehace todos, aunque el
#      .md no haya cambiado: así llega al canónico lo que cambió en la base.
#   2. numero-a-latex.xsl escribe latex/preambulo-numero.tex y un
#      main-{archivo}.tex por artículo, desde el volcado.
#   3. Por artículo, en el orden del número:
#        - jats-a-latex-articulo.xsl escribe latex/c-{archivo}.tex con su
#          página inicial;
#        - lo compone con lualatex y biber en latex/compilacion/{archivo}/;
#        - lee cuántas páginas tiene y vuelve a correr la hoja con la última
#          página: el rango del «cómo citar» sale del propio LaTeX (decisión
#          de A1); en el modelo continua cita el e-id y no hace falta;
#        - valida el PDF/A-2u con veraPDF;
#        - si el artículo está publicado, verifica que caiga en sus páginas
#          congeladas.
#   4. En el modo numero, el PDF del número (B5): numero-maestro-latex.xsl
#      escribe latex/maestro-numero.tex con las preliminares que el número
#      declara (tapa, página legal, sumario, en el orden de su nombre) y
#      los PDF de los artículos recién compuestos, incluidos con pdfpages;
#      se compone en latex/compilacion/numero/ y se valida igual. pdfpages
#      no conserva los enlaces de los artículos: quedan en sus PDF sueltos
#      (decisión de Alberto, 12/11). El sumario enlaza a cada artículo.
#   5. En el modo numero, si todo salió bien: los PDF van a salidas/pdf/
#      (cada artículo y numero.pdf) y tmp/paginacion.tsv dice dónde quedó
#      cada artículo. Gambas lo lee y guarda las páginas en la base (A1.3).
#
# LOS MODELOS DE PAGINACIÓN (revista.modelo_paginacion)
#   por_numero    el primer artículo empieza en 1 y los demás siguen corridos
#   por_volumen   el primero empieza en <pagina_inicial> y los demás siguen
#   por_articulo  cada artículo empieza en 1
#   continua      cada artículo empieza en 1 y lleva su e-id, que Gambas tiene
#                 que haber asignado antes (elocation en el volcado)
#   El foliado corrido no deja páginas en blanco: el artículo siguiente
#   empieza en la página que sigue (decisión de Alberto, 12/11).
#
# EL FRENO DE LOS PUBLICADOS
#   Que un artículo publicado se corra solo se sabe después de componer los
#   que van antes. Lo que se garantiza es que no se escriba nada: si un
#   publicado no cae en sus páginas congeladas, el script sale con 1 y no
#   deja tmp/paginacion.tsv, así que Gambas no guarda nada (decisión de
#   Alberto, 12/11). Los PDF quedan en latex/compilacion/ para revisarlos.
#
# CUANDO ALGO FALLA
#   Una compilación que no produce PDF corta todo (morir de
#   compilar_latex_comun.sh): sin las páginas de ese artículo no se sabe
#   dónde empieza el siguiente. Un PDF que veraPDF no da por conforme y un
#   publicado corrido se anotan, y la composición sigue: el editor ve todo lo
#   que hay que arreglar, no solo lo primero (criterio de SC-53). Al final,
#   código 1, nada en salidas/ y sin paginacion.tsv.
#
# tmp/paginacion.tsv (LO LEE GAMBAS, A1.3)
#   Una línea por artículo, separada por tabuladores, en el orden del número:
#     archivo  inicio  fin  paginas  elocation
#   La primera línea, que empieza con #, nombra las columnas. Se escribe en un
#   temporal y se pone con mv, al final y solo si todo salió bien: un
#   paginacion.tsv viejo se borra al empezar.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  PDF generados y conformes (en el modo numero, también el del número)
#   3  generados y conformes, con avisos (la columna derecha de la primera
#      página no entra, citas sin resolver, canónicos con avisos…)
#   1  algo no se generó, no es conforme o un publicado se corrió
# ============================================================================

set -uo pipefail

# --- 1. FUNCIONES COMPARTIDAS ---
DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
# LAS PASADAS DE lualatex Y biber, LA LIMPIEZA Y LA CONVERGENCIA SON LAS DE
# LIBROS. LA SECUENCIA (secuencia_compilacion) NO: LLEVA xindy, Y UN ARTÍCULO
# NO TIENE ÍNDICES
if ! source "$DIR_ENGINE/compilar_latex_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/compilar_latex_comun.sh" >&2
    exit 1
fi
if ! source "$DIR_ENGINE/verapdf_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/verapdf_comun.sh" >&2
    exit 1
fi

# --- 2. CONFIGURACIÓN ---
TIEMPO_SAXON=120
XSL_NUMERO="$DIR_GBP_LOCAL/xslt/numero-a-latex.xsl"
XSL_ARTICULO="$DIR_GBP_LOCAL/xslt/jats-a-latex-articulo.xsl"
XSL_MAESTRO="$DIR_GBP_LOCAL/xslt/numero-maestro-latex.xsl"
DIR_ICONOS="$DIR_GBP_LOCAL/fonts/"

# EL VOLCADO: LA MISMA RUTA Y VERSIÓN QUE m_CanonicoRevista. SI CAMBIAN
# ALLÁ, CAMBIAN ACÁ. LA 3 (12/11/2026) SUMA LAS PRELIMINARES Y LA PÁGINA LEGAL
VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="3"

# TODO PDF DE REVISTA ES PDF/A-2u (DECISIÓN DE A1)
NIVEL="2u"

# LO QUE DEJA EN EL .log EL CONTRATO DE REVISTA CUANDO LA COLUMNA DERECHA NO
# ENTRA EN LA PRIMERA PÁGINA (\gbcolocarcolumna, 4.4)
AVISO_COLUMNA="Package gbpublisher Warning: columna-primera-pagina"

# LAS CAPAS QUE EL main CARGA. LAS COPIA GAMBAS DE ~/.gbpublisher/latex AL
# ABRIR EL PROYECTO (CopiarRecursosLatex)
CAPAS=(preambulo-revista-contrato.tex preambulo-revista-estetica.tex
       preambulo-contrato-comun.tex cita-cadenas-es.tex)

# EL RANGO DEL «CÓMO CITAR» SE AJUSTA HASTA QUE LAS PÁGINAS NO CAMBIEN. EL
# CÓMO CITAR VA EN LA COLUMNA DEL MARGEN Y NO EMPUJA EL TEXTO: UNA VUELTA
# ALCANZA; LA SEGUNDA ES POR SI ACASO
VUELTAS_RANGO_MAX=2

# ============================================================================
# Función   : dato_volcado
# Propósito : Un valor del volcado, por XPath (la de generar_canonicos_articulos.sh).
# Parámetros: $1 expresión XPath que devuelve una cadena
# Retorna   : imprime el valor; vacío si no hay
# ============================================================================
dato_volcado() {
    xmllint --xpath "$1" "$VOLCADO" 2>/dev/null
}

# ============================================================================
# Función   : dato_articulo
# Propósito : Un valor de un artículo del volcado.
# Parámetros: $1 archivo; $2 camino relativo al <articulo> (@estado,
#             paginas/@inicio…)
# Retorna   : imprime el valor; vacío si no hay
# Nota      : EL NOMBRE DE ARCHIVO ES ASCII SIN COMILLAS (EL CONTROL DEL
#             APARTADO 4): PUEDE IR ENTRE COMILLAS SIMPLES EN EL XPATH
# ============================================================================
dato_articulo() {
    dato_volcado "string(/numero-datos/articulo[@archivo='$1']/$2)"
}

# ============================================================================
# Función   : paginas_pdf
# Propósito : Cuántas páginas tiene ARCHIVO_PDF.
# Retorna   : imprime el número; vacío si no se pudo leer
# ============================================================================
paginas_pdf() {
    pdfinfo "$ARCHIVO_PDF" 2>/dev/null | grep -oP '^Pages:\s+\K\d+'
}

# ============================================================================
# Función   : transformar_articulo
# Propósito : latex/c-{archivo}.tex (y latex/cita-{archivo}.bib) desde el
#             canónico, con jats-a-latex-articulo.xsl.
# Parámetros: $1 archivo; $2 página inicial; $3 página final (vacía: sin
#             rango todavía)
# Retorna   : 0 escrito; 1 no, con el motivo informado por fallo()
# Nota      : EL CANÓNICO VA SIN DOCTYPE: SAXON BAJARÍA LA DTD REMOTA (GV-25).
#             LA SALIDA SE ESCRIBE EN UN TEMPORAL Y SE PONE CON mv (SC-53).
#             prefijo_imagen VACÍO: SE COMPILA DESDE LA RAÍZ DEL PROYECTO Y
#             LAS IMÁGENES SON media/… (EL '../' DE LA HOJA VIEJA ES DEL
#             CAMINO DE m_XML, QUE COMPILA DESDE latex/)
# ============================================================================
transformar_articulo() {
    local archivo="$1" inicio="$2" fin="$3"
    local sin_dtd="$DIR_PROYECTO/tmp/pdf-c-$archivo.xml"
    local destino="$DIR_LATEX/c-$archivo.tex"
    local temporal="$DIR_LATEX/c-$archivo.tex.tmp"
    local salida codigo avisos

    if ! xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$archivo.xml" > "$sin_dtd" 2>/dev/null; then
        fallo "$archivo: el canónico jats/c-$archivo.xml no se pudo leer"
        return 1
    fi

    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
        -s:"$sin_dtd" -xsl:"$XSL_ARTICULO" -o:"$temporal" \
        pagina_inicial="$inicio" pagina_final="$fin" \
        bib_cita="cita-$archivo.bib" ruta_fonts="$DIR_ICONOS" prefijo_imagen= 2>&1)
    codigo=$?
    if (( codigo != 0 )) || [[ ! -s "$temporal" ]]; then
        rm -f "$temporal"
        fallo "$archivo: la hoja jats-a-latex-articulo.xsl no pudo escribir el LaTeX"
        mostrar_cola "$salida"
        return 1
    fi
    mv -f "$temporal" "$destino"

    # LA HOJA VIEJA AVISA LOS ELEMENTOS SIN PLANTILLA Y SIGUE: SE CUENTAN UNA
    # SOLA VEZ, EN LA PRIMERA TRANSFORMACIÓN (LA SEGUNDA DIRÍA LO MISMO)
    if [[ -z "$fin" ]]; then
        avisos=$(printf '%s\n' "$salida" | grep -F 'AVISO:' | sort -u)
        if [[ -n "$avisos" ]]; then
            aviso "$archivo: la hoja encontró elementos sin plantilla:"
            printf '%s\n' "$avisos" | sed 's/^/       /'
        fi
    fi
    return 0
}

# ============================================================================
# Función   : componer_articulo
# Propósito : Un artículo, de la hoja al PDF validado. Deja PAGINAS con la
#             cantidad de páginas del PDF.
# Parámetros: $1 archivo; $2 página inicial
# Retorna   : 0 PDF conforme; 1 sin LaTeX o no conforme (fallo informado).
#             Una pasada que no produce PDF corta el script (morir)
# ============================================================================
componer_articulo() {
    local archivo="$1" inicio="$2"
    local vuelta=0 anteriores informe codigo perfil fallidas

    PAGINAS=""
    paso "$archivo: desde la página $inicio"

    # --- 1. EL LaTeX DEL ARTÍCULO, TODAVÍA SIN RANGO ---
    transformar_articulo "$archivo" "$inicio" "" || return 1

    # --- 2. EL ÁREA DE COMPILACIÓN DE ESTE ARTÍCULO ---
    # UNA CARPETA POR ARTÍCULO: limpiar_auxiliares BORRA TODOS LOS AUXILIARES
    # DE DIR_AUX, Y LOS DE OTRO ARTÍCULO SON DE OTRO
    BASE="main-$archivo"
    MAESTRO="latex/$BASE.tex"
    DIR_AUX="$DIR_COMPILACION/$archivo"
    ARCHIVO_LOG="$DIR_AUX/$BASE.log"
    ARCHIVO_PDF="$DIR_AUX/$BASE.pdf"
    if [[ ! -f "$DIR_PROYECTO/$MAESTRO" ]]; then
        fallo "$archivo: numero-a-latex.xsl no escribió $MAESTRO"
        return 1
    fi
    mkdir -p "$DIR_AUX" || morir "No se pudo crear $DIR_AUX"
    limpiar_auxiliares

    # --- 3. LAS PASADAS: LA DE biber Y LA QUE COMPONE LAS CITAS ---
    correr_lualatex "primera composición"
    correr_biber
    correr_lualatex "segunda composición"
    PAGINAS=$(paginas_pdf)
    [[ -n "$PAGINAS" ]] || morir "No se pudo leer cuántas páginas tiene $ARCHIVO_PDF"

    # --- 4. EL RANGO DEL «CÓMO CITAR», DEL PROPIO LaTeX ---
    # continua CITA EL e-id: NO HAY RANGO
    if [[ "$MODELO" != "continua" ]]; then
        while (( vuelta < VUELTAS_RANGO_MAX )); do
            vuelta=$((vuelta + 1))
            anteriores="$PAGINAS"
            transformar_articulo "$archivo" "$inicio" "$((inicio + PAGINAS - 1))" || return 1
            correr_biber
            correr_lualatex "composición con el rango $inicio–$((inicio + PAGINAS - 1))"
            PAGINAS=$(paginas_pdf)
            [[ "$PAGINAS" == "$anteriores" ]] && break
            tenue "cambió la cantidad de páginas ($anteriores → $PAGINAS): otra vuelta"
        done
        if [[ "$PAGINAS" != "$anteriores" ]]; then
            aviso "$archivo: la cantidad de páginas no se asentó; el rango del «cómo citar» puede no coincidir"
        fi
    fi

    # --- 5. CONVERGENCIA ---
    correr_lualatex "composición final"
    local extra=0
    while necesita_rerun && (( extra < PASADAS_EXTRA_MAX )); do
        extra=$((extra + 1))
        tenue "la paginación todavía no converge"
        correr_lualatex "ajuste de paginación $extra"
    done
    PAGINAS=$(paginas_pdf)
    ok "$PAGINAS página(s): $inicio–$((inicio + PAGINAS - 1))"

    # --- 6. LA COLUMNA DERECHA DE LA PRIMERA PÁGINA (DECISIÓN DE A1.1b) ---
    if grep -qF "$AVISO_COLUMNA" "$ARCHIVO_LOG"; then
        aviso "$archivo: la columna derecha de la primera página no entra; el PDF sale igual"
    fi

    # --- 7. PDF/A-2u (LA MISMA VALIDACIÓN QUE EL PDF/A DE LIBROS) ---
    informe=$(validar_pdfa)
    codigo=$?
    perfil=$(printf '%s\n' "$informe" | grep -oP '^PERFIL\t\K.*')
    if (( codigo == 0 )); then
        ok "PDF/A-2u conforme${perfil:+ ($perfil)}"
        return 0
    fi
    if (( codigo == 1 )); then
        fallo "$archivo: veraPDF no devolvió un informe legible"
        return 1
    fi
    fallidas=$(printf '%s\n' "$informe" | grep -oP '^FALLIDAS\t\K.*')
    fallo "$archivo: no es PDF/A-2u: $fallidas regla(s) fallida(s)"
    printf '%s\n' "$informe" | grep -oP '^REGLA\t\K.*' | sed 's/^/     /'
    return 1
}

# ============================================================================
# Función   : verificar_publicado
# Propósito : Un artículo publicado tiene que caer en sus páginas congeladas.
# Parámetros: $1 archivo; $2 inicio compuesto; $3 fin compuesto
# Retorna   : 0 no está publicado o cae donde debe; 1 se corrió (informado)
# ============================================================================
verificar_publicado() {
    local archivo="$1" inicio="$2" fin="$3" ini_base fin_base

    [[ "$(dato_articulo "$archivo" '@estado')" == "publicado" ]] || return 0
    ini_base=$(dato_articulo "$archivo" 'paginas/@inicio')
    fin_base=$(dato_articulo "$archivo" 'paginas/@fin')

    # UN PUBLICADO SIN PÁGINAS EN LA BASE NO SE PUEDE COMPARAR: SE AVISA
    if [[ -z "$ini_base" || -z "$fin_base" ]]; then
        aviso "$archivo: está publicado y no tiene páginas en la base; no se pudo verificar que no se corra"
        return 0
    fi
    if [[ "$ini_base" == "$inicio" && "$fin_base" == "$fin" ]]; then
        ok "publicado: cae en sus páginas ($ini_base–$fin_base)"
        return 0
    fi
    fallo "$archivo: está publicado en las páginas $ini_base–$fin_base y ahora cae en $inicio–$fin"
    return 1
}

# ============================================================================
# Función   : componer_numero
# Propósito : El PDF del número (B5): el maestro con las preliminares y los
#             PDF de los artículos ya compuestos, de la hoja al PDF validado.
# Parámetros: ninguno (usa LINEAS_TSV, la paginación de esta corrida)
# Retorna   : 0 PDF conforme; 1 no (fallo informado). Una pasada que no
#             produce PDF corta el script (morir)
# Nota      : LOS ARTÍCULOS SE INCLUYEN DESDE latex/compilacion/{archivo}/:
#             SE LLAMA ANTES DE MOVERLOS A salidas/. EL FOLIO DEL SUMARIO
#             SALE DE ESTA CORRIDA, NO DE LA BASE (TODAVÍA NO SE GUARDÓ)
# ============================================================================
componer_numero() {
    local tsv_corrida="$DIR_PROYECTO/tmp/paginacion-corrida.tsv"
    local salida informe codigo perfil fallidas

    paso "PDF del número"

    # --- 1. LA PAGINACIÓN DE ESTA CORRIDA, PARA EL SUMARIO ---
    {
        printf '# archivo\tinicio\tfin\tpaginas\telocation\n'
        printf '%s\n' "${LINEAS_TSV[@]}"
    } > "$tsv_corrida" || { fallo "No se pudo escribir tmp/paginacion-corrida.tsv"; return 1; }

    # --- 2. EL MAESTRO ---
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
        -s:"$VOLCADO" -xsl:"$XSL_MAESTRO" -o:"$DIR_LATEX/maestro-numero.tex" \
        paginacion="$tsv_corrida" dir_pdf="latex/compilacion/" 2>&1)
    if (( $? != 0 )); then
        mostrar_cola "$salida"
        fallo "numero-maestro-latex.xsl no pudo escribir latex/maestro-numero.tex"
        return 1
    fi
    ok "latex/maestro-numero.tex"

    # --- 3. LA COMPOSICIÓN: SIN biber (EL MAESTRO NO CITA); LA SEGUNDA
    # PASADA RESUELVE LOS ENLACES DEL SUMARIO Y LOS MARCADORES ---
    BASE="maestro-numero"
    MAESTRO="latex/$BASE.tex"
    DIR_AUX="$DIR_COMPILACION/numero"
    ARCHIVO_LOG="$DIR_AUX/$BASE.log"
    ARCHIVO_PDF="$DIR_AUX/$BASE.pdf"
    mkdir -p "$DIR_AUX" || morir "No se pudo crear $DIR_AUX"
    limpiar_auxiliares
    correr_lualatex "primera composición del número"
    correr_lualatex "segunda composición del número"
    local extra=0
    while necesita_rerun && (( extra < PASADAS_EXTRA_MAX )); do
        extra=$((extra + 1))
        tenue "los enlaces todavía no convergen"
        correr_lualatex "ajuste del número $extra"
    done
    ok "$(paginas_pdf) página(s)"

    # --- 4. PDF/A-2u ---
    informe=$(validar_pdfa)
    codigo=$?
    perfil=$(printf '%s\n' "$informe" | grep -oP '^PERFIL\t\K.*')
    if (( codigo == 0 )); then
        ok "PDF/A-2u conforme${perfil:+ ($perfil)}"
        return 0
    fi
    if (( codigo == 1 )); then
        fallo "el número: veraPDF no devolvió un informe legible"
        return 1
    fi
    fallidas=$(printf '%s\n' "$informe" | grep -oP '^FALLIDAS\t\K.*')
    fallo "el número: no es PDF/A-2u: $fallidas regla(s) fallida(s)"
    printf '%s\n' "$informe" | grep -oP '^REGLA\t\K.*' | sed 's/^/     /'
    return 1
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

# --- 3. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib> numero [<pagina_inicial>] | articulo <archivo>"
fi
DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"
MODO="$3"
VALOR="${4:-}"

case "$MODO" in
    numero)   encabezado "PDF DEL NÚMERO Y DE SUS ARTÍCULOS" ;;
    articulo) encabezado "PDF DE PRUEBA DEL ARTÍCULO EN CURSO" ;;
    *)        morir "Modo desconocido «$MODO»: numero o articulo" ;;
esac

DIR_LATEX="$DIR_PROYECTO/latex"
DIR_COMPILACION="$DIR_LATEX/compilacion"
DIR_SALIDA="$DIR_PROYECTO/salidas/pdf"
VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
ARCHIVO_BIB="$DIR_PROYECTO/referencias/$NOMBRE_BIB"
LISTA_REL="tmp/lote-pdf-revista.txt"
TSV="$DIR_PROYECTO/tmp/paginacion.tsv"

# --- 4. VERIFICACIONES ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
cd "$DIR_PROYECTO" || morir "No se pudo entrar a $DIR_PROYECTO"

# UN paginacion.tsv VIEJO NO PUEDE SOBREVIVIR A UNA CORRIDA QUE FALLA: GAMBAS
# LO TOMARÍA POR EL DE ESTA
[[ "$MODO" == "numero" ]] && rm -f "$TSV"

# LAS HERRAMIENTAS. NO SE USA verificar_herramientas_latex: EXIGE xindy, Y LA
# REVISTA NO TIENE ÍNDICES
requerir_comandos lualatex biber java xmllint pdfinfo perl
[[ -f "$RUTA_SAXON" ]]   || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL_NUMERO" ]]   || morir "Falta la hoja $XSL_NUMERO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -f "$XSL_ARTICULO" ]] || morir "Falta la hoja $XSL_ARTICULO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -f "$XSL_MAESTRO" ]]  || morir "Falta la hoja $XSL_MAESTRO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -d "$DIR_ICONOS" ]]   || morir "Falta la carpeta de los íconos: $DIR_ICONOS"
# SIN veraPDF NO SE PUEDE AFIRMAR LA NORMA: NO SE COMPILA EN VANO
VERAPDF="$(buscar_verapdf)"
[[ -n "$VERAPDF" ]] || morir "No se encontró veraPDF (PATH, /opt/verapdf, ~/verapdf): sin él no se puede verificar el PDF/A-2u"
ok "herramientas; veraPDF: $VERAPDF"

# EL VOLCADO
[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"
MODELO="$(dato_volcado 'string(/numero-datos/revista/@modelo-paginacion)')"
ESTILO="$(dato_volcado 'string(/numero-datos/revista/estilo-cita)')"
case "$MODELO" in
    por_numero|por_volumen|por_articulo|continua) ;;
    "") morir "La revista no tiene modelo de paginación: elegilo en la ficha de la revista" ;;
    *)  morir "Modelo de paginación desconocido: «$MODELO»" ;;
esac
ok "volcado versión $version; paginación $MODELO"

# LAS CAPAS DE LaTeX Y EL .bib
for capa in "${CAPAS[@]}" "cita-$ESTILO-config.tex"; do
    [[ -f "$DIR_LATEX/$capa" ]] || morir "Falta latex/$capa: lo copia gbpublisher al abrir el proyecto (CopiarRecursosLatex)"
done
[[ -f "$ARCHIVO_BIB" ]] || morir "No existe referencias/$NOMBRE_BIB: lo exporta gbpublisher antes de generar"
ok "capas de LaTeX, estilo $ESTILO y referencias/$NOMBRE_BIB"

# biber BUSCA EL .bib DEL «CÓMO CITAR» (latex/cita-{archivo}.bib) POR
# BIBINPUTS: correr_biber ANTEPONE EL PROYECTO Y referencias/ A LO QUE YA HAY
export BIBINPUTS="$DIR_LATEX/:${BIBINPUTS:-}"

# --- 5. LOS ARTÍCULOS Y DÓNDE EMPIEZAN ---
# EN EL VOLCADO SOLO HAY ARTÍCULOS CON .md Y CON METADATOS; LOS DEMÁS LOS
# INFORMA EL SCRIPT DE CANÓNICOS
mapfile -t TODOS < <(dato_volcado '/numero-datos/articulo/@archivo' | grep -oP 'archivo="\K[^"]+')
(( ${#TODOS[@]} > 0 )) || morir "El número no tiene artículos con metadatos"
for a in "${TODOS[@]}"; do
    # EL MISMO CONTROL QUE generar_canonicos_articulos.sh: EL NOMBRE VA A UN
    # XPATH Y A RUTAS
    [[ "$a" =~ ^a-[A-Za-z0-9._-]+$ ]] || morir "Nombre de artículo no válido en el volcado: «$a»"
done

if [[ "$MODO" == "numero" ]]; then
    ARTICULOS=("${TODOS[@]}")
    case "$MODELO" in
        por_numero) INICIO=1 ;;
        por_volumen)
            [[ "$VALOR" =~ ^[1-9][0-9]*$ ]] ||
                morir "En el modelo por_volumen hace falta la página inicial del número (la calcula gbpublisher)"
            INICIO="$VALOR" ;;
        *) INICIO=1 ;;
    esac
    # LAS PRELIMINARES DEL NÚMERO (B5): LO QUE FALTA FRENA ANTES DE COMPONER
    # LOS ARTÍCULOS, NO DESPUÉS DE MINUTOS DE COMPILACIÓN
    if [[ -n "$(dato_volcado "string(/numero-datos/preliminares/pieza[@tipo='tapa']/@tipo)")" ]]; then
        tapa="$(dato_volcado 'normalize-space(/numero-datos/numero/imagen-tapa)')"
        # SIN IMAGEN FRENA (DECISIÓN DE ALBERTO, 12/11)
        [[ -n "$tapa" ]] || morir "El número declara la tapa y no tiene imagen: elegila en los metadatos del número"
        [[ -f "$DIR_PROYECTO/media/$tapa" ]] || morir "La tapa del número (media/$tapa) no está en el proyecto"
        [[ "${tapa,,}" =~ \.(jpe?g|png)$ ]] || morir "La tapa del número tiene que ser JPG o PNG: media/$tapa"
    fi
    if [[ -n "$(dato_volcado "string(/numero-datos/preliminares/pieza[@tipo='legales']/@tipo)")" ]]; then
        [[ -n "$(dato_volcado 'string(/numero-datos/pagina-legal/@fecha-referencia)')" ]] ||
            morir "El número declara la página legal y el volcado no la trae (¿falta el año del número?)"
    fi
    PRELIMINARES="$(dato_volcado '/numero-datos/preliminares/pieza/@tipo' | grep -oP 'tipo="\K[^"]+' | paste -sd' ')"
    ok "preliminares: ${PRELIMINARES:-ninguna}"

    # continua: CADA ARTÍCULO NECESITA SU e-id ANTES DE COMPONER. LO ASIGNA
    # GAMBAS (A1.3); SIN ÉL, EL «CÓMO CITAR» Y EL CANÓNICO SALEN SIN NÚMERO
    if [[ "$MODELO" == "continua" ]]; then
        for a in "${ARTICULOS[@]}"; do
            [[ -n "$(dato_articulo "$a" 'paginas/@elocation')" ]] ||
                morir "$a no tiene e-id: gbpublisher lo asigna antes de componer el número"
        done
    fi
else
    [[ -n "$VALOR" ]] || morir "Falta el artículo: articulo <archivo>"
    printf '%s\n' "${TODOS[@]}" | grep -qxF "$VALOR" ||
        morir "$VALOR no está en el volcado del número (¿tiene metadatos?)"
    ARTICULOS=("$VALOR")
    # LA PRUEBA EMPIEZA DONDE LO DEJÓ LA ÚLTIMA COMPOSICIÓN DEL NÚMERO
    INICIO=1
    if [[ "$MODELO" == "por_numero" || "$MODELO" == "por_volumen" ]]; then
        inicio_base=$(dato_articulo "$VALOR" 'paginas/@inicio')
        [[ "$inicio_base" =~ ^[1-9][0-9]*$ ]] && INICIO="$inicio_base"
    fi
fi

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Paginación:" "$MODELO, desde la página $INICIO"
printf '  %-14s %s\n'   "Artículos:" "${#ARTICULOS[@]}"

# --- 6. LOS CANÓNICOS ---
# ANIDADO, Y LOS REHACE TODOS: EL VOLCADO PUEDE TRAER DATOS NUEVOS DE LA BASE
# AUNQUE EL .md NO HAYA CAMBIADO. UN ARTÍCULO QUE NO SE GENERA
# CORTA: SIN SU CANÓNICO NO HAY PÁGINAS, Y SIN PÁGINAS NO SE SABE DÓNDE
# EMPIEZA EL SIGUIENTE
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    0) ;;
    3) aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: no se compone" ;;
esac

# --- 7. EL PREÁMBULO DEL NÚMERO Y LOS main ---
paso "preámbulo del número y main de cada artículo"
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
    -s:"$VOLCADO" -xsl:"$XSL_NUMERO" -o:"$DIR_LATEX/preambulo-numero.tex" \
    bib="$NOMBRE_BIB" 2>&1)
if (( $? != 0 )); then
    mostrar_cola "$salida"
    morir "numero-a-latex.xsl no pudo escribir latex/preambulo-numero.tex"
fi
ok "latex/preambulo-numero.tex y los main-*.tex"

# --- 8. LA COMPOSICIÓN, EN EL ORDEN DEL NÚMERO ---
FALLIDOS=()
LINEAS_TSV=()
inicio="$INICIO"
for a in "${ARTICULOS[@]}"; do
    if ! componer_articulo "$a" "$inicio"; then
        FALLIDOS+=("$a")
        # SIN PÁGINAS NO SE SABE DÓNDE EMPIEZA EL SIGUIENTE (UNA FALLA DE LA
        # HOJA); UN PDF NO CONFORME SÍ LAS TIENE, Y SE SIGUE
        [[ -n "$PAGINAS" ]] || morir "Sin las páginas de $a no se puede seguir componiendo el número"
    fi
    fin=$((inicio + PAGINAS - 1))
    if [[ "$MODO" == "numero" ]]; then
        verificar_publicado "$a" "$inicio" "$fin" || FALLIDOS+=("$a")
        LINEAS_TSV+=("$a"$'\t'"$inicio"$'\t'"$fin"$'\t'"$PAGINAS"$'\t'"$(dato_articulo "$a" 'paginas/@elocation')")
    fi
    # EL SIGUIENTE: CORRIDO EN por_numero Y por_volumen, SIN BLANCAS
    # (DECISIÓN DE ALBERTO, 12/11); EN LOS OTROS DOS, DESDE 1
    case "$MODELO" in
        por_numero|por_volumen) inicio=$((fin + 1)) ;;
        *) inicio=1 ;;
    esac
done

# --- 9. EL PDF DEL NÚMERO (B5) ---
# SOLO SI TODOS LOS ARTÍCULOS SALIERON BIEN: SE ARMA CON SUS PDF
if [[ "$MODO" == "numero" ]] && (( ${#FALLIDOS[@]} == 0 )); then
    componer_numero || FALLIDOS+=("PDF del número")
fi

# --- 10. CIERRE ---
rm -f "$DIR_PROYECTO"/tmp/pdf-c-*.xml "$DIR_PROYECTO/tmp/paginacion-corrida.tsv"
echo
titulo "$REGLA"

if (( ${#FALLIDOS[@]} > 0 )); then
    printf '%s✗ No se entregó ningún PDF%s\n' "$C_ERROR" "$C_RESET"
    printf '%s\n' "${FALLIDOS[@]}" | sort -u | sed 's/^/    /'
    tenue "los PDF quedan en latex/compilacion/ para revisarlos; sin tmp/paginacion.tsv"
    exit "$SALIDA_FALLO"
fi

# SOLO PDF CONFORMES LLEGAN A salidas/. LA PRUEBA LLEVA -prueba: NO PISA EL
# PDF DEL NÚMERO
mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
for a in "${ARTICULOS[@]}"; do
    if [[ "$MODO" == "numero" ]]; then
        destino="$DIR_SALIDA/$a.pdf"
    else
        destino="$DIR_SALIDA/$a-prueba.pdf"
    fi
    mv -f "$DIR_COMPILACION/$a/main-$a.pdf" "$destino" || morir "No se pudo mover el PDF de $a a salidas/pdf"
    ok "salidas/pdf/$(basename "$destino")"
    rm -rf -- "${DIR_COMPILACION:?}/$a"
done
if [[ "$MODO" == "numero" ]]; then
    mv -f "$DIR_COMPILACION/numero/maestro-numero.pdf" "$DIR_SALIDA/numero.pdf" || morir "No se pudo mover el PDF del número a salidas/pdf"
    ok "salidas/pdf/numero.pdf"
    rm -rf -- "${DIR_COMPILACION:?}/numero"
fi
rmdir "$DIR_COMPILACION" 2>/dev/null

if [[ "$MODO" == "numero" ]]; then
    {
        printf '# archivo\tinicio\tfin\tpaginas\telocation\n'
        printf '%s\n' "${LINEAS_TSV[@]}"
    } > "$TSV.tmp" && mv -f "$TSV.tmp" "$TSV" || morir "No se pudo escribir tmp/paginacion.tsv"
    ok "tmp/paginacion.tsv: ${#LINEAS_TSV[@]} artículo(s)"
fi

if (( AVISOS > 0 )); then
    printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
fi
echo
terminar
