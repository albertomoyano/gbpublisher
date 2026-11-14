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
