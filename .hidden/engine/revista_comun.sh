#!/bin/bash
# Funciones comunes de las salidas del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Lo cargan con source generar_pdf_revista.sh y generar_epub_revista.sh,
# después de comun.sh. Estaba en generar_pdf_revista.sh; se mudó en E3
# (14/11/2026) para que el EPUB lea el volcado y se nombre igual que el PDF
# sin copiar el código (decisión de Alberto: el mismo esquema de nombre).
#
# REQUIERE la variable VOLCADO: la ruta absoluta de tmp/numero-datos.xml.
# Las funciones de los esquemas de los sabores (esquema_*_presente,
# validar_doaj, validar_crossref) no la usan: las carga también
# validar_sabor.sh.
# ============================================================================

# LOS ESQUEMAS DE LOS SABORES SON DEL PAQUETE, NO DE ~/.gbpublisher: UN
# «VÁLIDO» SOLO SE SOSTIENE CON EL ESQUEMA DEL SISTEMA (SC-11, COMO
# validar_canonicos.sh). LA CARPETA DE RECURSOS ES LA DE ESTE ARCHIVO, UN
# NIVEL ARRIBA: .hidden/ DESDE EL IDE, /usr/share/gbpublisher/ INSTALADO
DIR_RECURSOS_REVISTA="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
XSD_DOAJ="$DIR_RECURSOS_REVISTA/schemas/doajArticles.xsd"
# doajArticles.xsd IMPORTA LOS CÓDIGOS DE IDIOMA DESDE doaj.org. EL CATÁLOGO
# LOS RESUELVE A LA COPIA LOCAL (iso_639-2b.xsd): SIN RED Y SIEMPRE LA MISMA
# VERSIÓN. SIN ÉL, xmllint --nonet NO COMPILA EL ESQUEMA (MEDIDO, libxml
# 2.9.14)
CATALOGO_DOAJ="$DIR_RECURSOS_REVISTA/schemas/catalogo-doaj.xml"
# CROSSREF 5.4.0 (DECISIÓN DE ALBERTO, 18/11: LA 5.5.0 ES XSD 1.1 Y xmllint
# NO LA COMPILA, MEDIDO). SUS MÓDULOS IMPORTAN ESQUEMAS DE LA W3C POR URL
# (EL CATÁLOGO LOS RESUELVE) Y EL JATS 1.3 QUE TRAE PIDE standard-modules/
DIR_ESQUEMA_CROSSREF="$DIR_RECURSOS_REVISTA/schemas/crossref"
XSD_CROSSREF="$DIR_ESQUEMA_CROSSREF/crossref5.4.0.xsd"
CATALOGO_CROSSREF="$DIR_ESQUEMA_CROSSREF/catalogo-crossref.xml"

# LOS LÍMITES DE MARCALYC (REDALYC), DEL MANUAL DE USUARIO DE MARCALYC 4.0
# (ABRIL DE 2024): EL ZIP HASTA 4 MB, CADA IMAGEN HASTA 1 MB Y SE
# RECOMIENDA NO PASAR DE 750 px, EL PDF DE LA REVISTA HASTA 4 MB. LOS USAN
# generar_redalyc_revista.sh Y validar_sabor.sh: SI MARCALYC LOS CAMBIA,
# CAMBIAN ACÁ
MARCALYC_MAX_ZIP=$(( 4 * 1024 * 1024 ))
MARCALYC_MAX_IMAGEN=$(( 1024 * 1024 ))
MARCALYC_MAX_PDF=$(( 4 * 1024 * 1024 ))
MARCALYC_TOPE_PX=750

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
# Nota      : EL NOMBRE DE ARCHIVO ES ASCII SIN COMILLAS (EL CONTROL DE CADA
#             SCRIPT AL LEER LA LISTA): PUEDE IR ENTRE COMILLAS SIMPLES EN EL
#             XPATH
# ============================================================================
dato_articulo() {
    dato_volcado "string(/numero-datos/articulo[@archivo='$1']/$2)"
}

# ============================================================================
# Función   : limpiar_parte_nombre
# Propósito : Una parte del nombre de un archivo del número, apta para una
#             ruta: las letras con tilde pasan a su base (iconv //TRANSLIT de
#             glibc, con C.UTF-8: «Ñandú» → «Nandu», medido); lo que no es
#             letra ASCII, cifra o punto pasa a guion, sin guiones repetidos
#             ni en los bordes. «Vol. 3/4» → «Vol.-3-4»
# Parámetros: $1 el texto
# Retorna   : imprime la parte limpia (puede quedar vacía)
# ============================================================================
limpiar_parte_nombre() {
    printf '%s' "$1" | LC_ALL=C.UTF-8 iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null |
        LC_ALL=C sed -e 's/[^A-Za-z0-9.]/-/g' -e 's/--*/-/g' -e 's/^-//' -e 's/-$//'
}

# ============================================================================
# Función   : nombre_numero
# Propósito : La base del nombre con que se distribuyen el PDF y el EPUB del
#             número (C3, decisión de Alberto del 14/11/2026):
#             ACRÓNIMO-AÑO-vVOLUMEN-nNÚMERO, p. ej. rp-2026-v3-n3. Un número
#             sin volumen o sin número omite esa parte; un suplemento suma
#             -sSUPLEMENTO. Cada parte pasa por limpiar_parte_nombre
# Parámetros: (ninguno; lee el volcado)
# Retorna   : imprime la base, sin extensión; vacío si faltan el acrónimo o
#             el año (el llamador frena)
# ============================================================================
nombre_numero() {
    local acronimo anio volumen numero suplemento nombre
    acronimo="$(limpiar_parte_nombre "$(dato_volcado 'normalize-space(/numero-datos/revista/acronimo)')")"
    anio="$(limpiar_parte_nombre "$(dato_volcado 'string(/numero-datos/numero/@anio)')")"
    volumen="$(limpiar_parte_nombre "$(dato_volcado 'normalize-space(/numero-datos/numero/@volumen)')")"
    numero="$(limpiar_parte_nombre "$(dato_volcado 'normalize-space(/numero-datos/numero/@numero)')")"
    suplemento="$(limpiar_parte_nombre "$(dato_volcado 'normalize-space(/numero-datos/numero/@suplemento)')")"
    [[ -n "$acronimo" && -n "$anio" ]] || return 0
    nombre="$acronimo-$anio"
    [[ -n "$volumen" ]]    && nombre+="-v$volumen"
    [[ -n "$numero" ]]     && nombre+="-n$numero"
    [[ -n "$suplemento" ]] && nombre+="-s$suplemento"
    printf '%s' "$nombre"
}

# ============================================================================
# Función   : articulos_sin_paginas
# Propósito : Los artículos a los que les falta lo que el «cómo citar» toma
#             de la última composición del PDF del número: las páginas
#             (inicio y fin) o, en el modelo continua, el e-id. Lo usan el
#             EPUB y el HTML para frenar (decisión de Alberto, 14/11): las
#             salidas se validan cruzadas, y sin el PDF no hay las demás
# Parámetros: $1 modelo de paginación; $2… archivos de los artículos
# Retorna   : imprime uno por línea; nada si todos las tienen
# Nota      : SE MUDÓ DE generar_epub_revista.sh EN H2 (14/11/2026)
# ============================================================================
articulos_sin_paginas() {
    local modelo="$1" a
    shift
    for a in "$@"; do
        if [[ "$modelo" == "continua" ]]; then
            [[ -n "$(dato_articulo "$a" 'paginas/@elocation')" ]] || printf '%s\n' "$a"
        elif [[ -z "$(dato_articulo "$a" 'paginas/@inicio')" || -z "$(dato_articulo "$a" 'paginas/@fin')" ]]; then
            printf '%s\n' "$a"
        fi
    done
}

# ============================================================================
# Función   : salidas_que_faltan
# Propósito : La pinza de las salidas del número (Alberto, 14/11/2026): la
#             revista es de acceso abierto y cada salida enlaza o se apoya
#             en las otras, así que una salida no se genera si falta una
#             anterior. El PDF (de cada artículo y del número) es la base;
#             el EPUB lo exige; el HTML exige el PDF y el EPUB, que ofrece
#             como descargas
# Parámetros: $1 qué se pide: pdf o pdf+epub; $2 raíz del proyecto;
#             $3 base del nombre del número (nombre_numero); $4… archivos
#             de los artículos
# Retorna   : imprime, una por línea y relativa al proyecto, cada salida
#             que falta; nada si están todas
# ============================================================================
salidas_que_faltan() {
    local que="$1" proyecto="$2" base="$3" a
    shift 3
    for a in "$@"; do
        [[ -f "$proyecto/salidas/pdf/$a.pdf" ]] || printf 'salidas/pdf/%s.pdf\n' "$a"
    done
    [[ -f "$proyecto/salidas/pdf/$base.pdf" ]] || printf 'salidas/pdf/%s.pdf\n' "$base"
    if [[ "$que" == "pdf+epub" ]]; then
        [[ -f "$proyecto/salidas/epub/$base.epub" ]] || printf 'salidas/epub/%s.epub\n' "$base"
    fi
}

# ============================================================================
# Función   : imagenes_canonico_jats
# Propósito : Las imágenes que usa un canónico de artículo: el xlink:href de
#             cada fig/graphic, sin carpeta, sin repetir. Es la regla de
#             numero-a-epub.xsl y de la plantilla fig de las hojas de
#             revista (tokenize(...)[last()]). imagenes_canonico (comun.sh)
#             es la de DocBook
# Parámetros: $1 ruta del canónico (sin DOCTYPE)
# Retorna   : imprime un nombre por línea; nada si no usa imágenes
# Nota      : local-name() PORQUE xmllint --xpath NO CONOCE LOS ESPACIOS DE
#             NOMBRES DEL DOCUMENTO (GV-22)
# ============================================================================
imagenes_canonico_jats() {
    xmllint --nonet --xpath "//*[local-name()='fig']/*[local-name()='graphic']/@*[local-name()='href']" "$1" 2>/dev/null |
        grep -oP 'href="\K[^"]+' | sed 's|.*/||' | sort -u
}

# ============================================================================
# Función   : esquema_doaj_presente
# Propósito : Si están el esquema de DOAJ, su catálogo y los códigos de
#             idioma que importa.
# Retorna   : 0 si están; 1 si falta algo
# ============================================================================
esquema_doaj_presente() {
    [[ -f "$XSD_DOAJ" && -f "$CATALOGO_DOAJ" && -f "$(dirname "$XSD_DOAJ")/iso_639-2b.xsd" ]]
}

# ============================================================================
# Función   : validar_doaj
# Propósito : Valida un archivo contra doajArticles.xsd, sin red.
# Parámetros: $1 ruta del archivo
# Retorna   : imprime los errores, una línea cada uno, sin la ruta del
#             archivo; nada si es válido
# Nota      : XML_CATALOG_FILES SOLO PARA ESTA LLAMADA: NO CAMBIA LO QUE
#             RESUELVEN LAS DEMÁS
# ============================================================================
validar_doaj() {
    local archivo="$1"
    XML_CATALOG_FILES="$CATALOGO_DOAJ" xmllint --nonet --noout --schema "$XSD_DOAJ" "$archivo" 2>&1 |
        grep -v ' validates$' | grep -v ' fails to validate$' |
        sed -E "s|^$archivo:||" | grep .
}

# ============================================================================
# Función   : esquema_crossref_presente
# Propósito : Si están el esquema 5.4.0 de Crossref, su catálogo y los
#             módulos que importa por ruta relativa.
# Retorna   : 0 si están; 1 si falta algo
# ============================================================================
esquema_crossref_presente() {
    local f
    for f in "$XSD_CROSSREF" "$CATALOGO_CROSSREF" \
             "$DIR_ESQUEMA_CROSSREF/common5.4.0.xsd" \
             "$DIR_ESQUEMA_CROSSREF/standard-modules/xlink.xsd"; do
        [[ -f "$f" ]] || return 1
    done
    return 0
}

# ============================================================================
# Función   : validar_crossref
# Propósito : Valida un depósito contra crossref5.4.0.xsd, sin red.
# Parámetros: $1 ruta del archivo
# Retorna   : imprime los errores, una línea cada uno, sin la ruta del
#             archivo; nada si es válido
# Nota      : xmllint AVISA AL COMPILAR EL ESQUEMA QUE SALTEA IMPORTACIONES
#             REPETIDAS (EL MISMO ESPACIO DE NOMBRES POR DOS CAMINOS) Y QUE
#             LOS ESQUEMAS DECLARAN XML 1.1: SON DEL ESQUEMA DE CROSSREF, NO
#             DEL DEPÓSITO. SOLO SE CONSERVAN LOS ERRORES
# ============================================================================
validar_crossref() {
    local archivo="$1"
    XML_CATALOG_FILES="$CATALOGO_CROSSREF" xmllint --nonet --noout --schema "$XSD_CROSSREF" "$archivo" 2>&1 |
        grep -E 'error|failed to compile' |
        sed -E "s|^$archivo:||" | grep .
}

# ============================================================================
# Función   : marcalyc_formato_imagen
# Propósito : Si Marcalyc acepta el formato de una imagen, por su extensión:
#             JPG, JPEG, PNG, GIF o SVG (manual de Marcalyc 4.0).
# Parámetros: $1 nombre del archivo
# Retorna   : 0 si lo acepta; 1 si no
# ============================================================================
marcalyc_formato_imagen() {
    local extension="${1##*.}"
    case "${extension,,}" in
        jpg|jpeg|png|gif|svg) return 0 ;;
        *) return 1 ;;
    esac
}
