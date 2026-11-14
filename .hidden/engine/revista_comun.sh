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
# ============================================================================

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
