#!/bin/bash
# Sabor DOAJ del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa F2 de los sabores XML (claude/salidas-revistas.md), decisiones de
# Alberto del 15/11/2026:
#   - el formato propio de DOAJ (doajArticles.xsd 1.3), no el XML de
#     Crossref: sirve sin DOI y lleva cada idioma;
#   - un archivo por número: salidas/doaj/doaj-{número}.xml, un record por
#     artículo;
#   - LA PINZA DE DOAJ: el texto completo (fullTextUrl, obligatorio) es el
#     self-uri content-type="pagina" del canónico. Sin él no se genera. El
#     HTML local no se exige: la página puede estar en otro sitio (OJS);
#   - como todos los sabores, exige las páginas de cada artículo.
#
# USO
#   generar_doaj_revista.sh <ruta_proyecto> <nombre_bib>
#
#   El .bib lo recibe por ser el contrato común de las salidas del número
#   (m_GenerarSalidasRevista.LanzarSalidaNumero): este script no lo lee.
#
# LA FRONTERA CON GAMBAS (SC-13): Gambas escribe antes el volcado del número
# (tmp/numero-datos.xml, versión 4). Este script no toca la base.
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado y las páginas de cada artículo.
#   2. Regenera los canónicos (generar_canonicos_articulos.sh, anidado): el
#      sabor sale del canónico vigente, que ya pasó la DTD y JATS4R.
#   3. Copia los canónicos sin DOCTYPE (GV-25) y verifica la pinza: cada uno
#      con su self-uri de página.
#   4. numero-a-doaj.xsl escribe el archivo, en un temporal que se renombra
#      con mv: nunca queda un sabor a medio escribir.
#   5. Lo valida contra doajArticles.xsd, sin red (validar_doaj,
#      revista_comun.sh). Un archivo que no valida se conserva para
#      revisarlo, y llega a Gambas como código 3: DOAJ lo rechazaría.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   insumos ausentes, un artículo sin páginas, un canónico que no
#            se generó, un artículo sin self-uri de página, la
#            transformación
#   avisa    canónicos con avisos, el esquema de DOAJ
#
# CÓDIGOS DE SALIDA (comun.sh): 0 generado y válido; 3 con avisos; 1 no
# ============================================================================

set -uo pipefail

# --- 1. FUNCIONES COMPARTIDAS ---
DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
# LA LECTURA DEL VOLCADO, EL NOMBRE DEL NÚMERO, LAS PÁGINAS Y EL ESQUEMA
if ! source "$DIR_ENGINE/revista_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/revista_comun.sh" >&2
    exit 1
fi

# --- 2. CONFIGURACIÓN ---
TIEMPO_SAXON=120
VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="4"
LISTA_REL="tmp/lote-doaj-revista.txt"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "DOAJ DEL NÚMERO"

# --- 3. ARGUMENTOS ---
if (( $# < 1 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> [<nombre_bib>]"
fi
DIR_PROYECTO="${1%/}"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
DIR_SALIDA="$DIR_PROYECTO/salidas/doaj"
# LOS CANÓNICOS SIN DOCTYPE: SAXON NO BAJA LA DTD REMOTA (GV-25)
DIR_CANONICOS="$DIR_PROYECTO/tmp/doaj-canonicos"
XSL="$DIR_RECURSOS/xslt/numero-a-doaj.xsl"

# --- 4. ENTORNO ---
paso "verificando el entorno"
[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
requerir_comandos java xmllint
[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "Falta la hoja $XSL: reinstalá gbpublisher"
# EL ESQUEMA SE COMPRUEBA ANTES DE TRABAJAR: SIN ÉL NO HAY VALIDACIÓN
esquema_doaj_presente || morir "No está el esquema de DOAJ del sistema: $XSD_DOAJ (o su catálogo, $CATALOGO_DOAJ)"
ok "herramientas, hoja y esquema de DOAJ"

# --- 5. EL VOLCADO ---
[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"
MODELO="$(dato_volcado 'string(/numero-datos/revista/@modelo-paginacion)')"
[[ -n "$MODELO" ]] || morir "La revista no tiene modelo de paginación: elegilo en la ficha de la revista"
ok "volcado versión $version; paginación $MODELO"

base="$(nombre_numero)"
[[ -n "$base" ]] ||
    morir "Para nombrar el archivo hacen falta el acrónimo de la revista (en Revistas) y el año del número (en sus metadatos)"
SALIDA="$DIR_SALIDA/doaj-$base.xml"

mapfile -t ARTICULOS < <(dato_volcado '/numero-datos/articulo/@archivo' | grep -oP 'archivo="\K[^"]+')
(( ${#ARTICULOS[@]} > 0 )) || morir "El número no tiene artículos con metadatos"
for a in "${ARTICULOS[@]}"; do
    # EL NOMBRE VA A UN XPATH Y A RUTAS
    [[ "$a" =~ ^a-[A-Za-z0-9._-]+$ ]] || morir "Nombre de artículo no válido en el volcado: «$a»"
done

# --- 6. LAS PÁGINAS (TODOS LOS SABORES) ---
paso "verificando el número"
mapfile -t sin_paginas < <(articulos_sin_paginas "$MODELO" "${ARTICULOS[@]}")
if (( ${#sin_paginas[@]} > 0 )); then
    printf '%s\n' "${sin_paginas[@]}" | sed 's/^/     /'
    morir "${#sin_paginas[@]} artículo(s) sin páginas (o sin e-id) en la base: componé primero el PDF del número"
fi
ok "${#ARTICULOS[@]} artículo(s)"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "salidas/doaj/doaj-$base.xml"

# --- 7. CANÓNICOS ---
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: el sabor DOAJ no se genera" ;;
esac

# --- 8. CANÓNICOS SIN DTD Y LA PINZA ---
paso "verificando el texto completo de cada artículo"
rm -rf -- "${DIR_CANONICOS:?}"
mkdir -p "$DIR_CANONICOS" || morir "No se pudo crear $DIR_CANONICOS"
sin_pagina=()
for a in "${ARTICULOS[@]}"; do
    xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$a.xml" > "$DIR_CANONICOS/c-$a.xml" 2>/dev/null ||
        morir "$a: el canónico jats/c-$a.xml no se pudo leer"
    # EL fullTextUrl DE DOAJ: OBLIGATORIO, Y CON EL DOI IDENTIFICA EL RECORD
    url="$(xmllint --xpath "normalize-space((//*[local-name()='article-meta']/*[local-name()='self-uri'][@content-type='pagina'])[1]/@*[local-name()='href'])" \
           "$DIR_CANONICOS/c-$a.xml" 2>/dev/null)"
    if [[ ! "$url" =~ ^https?:// ]]; then
        sin_pagina+=("$a")
    fi
done
if (( ${#sin_pagina[@]} > 0 )); then
    printf '%s\n' "${sin_pagina[@]}" | sed 's/^/     /'
    morir "${#sin_pagina[@]} artículo(s) sin la URL de su página (self-uri de página): DOAJ la exige como texto completo. Cargala en los metadatos del artículo"
fi
ok "cada artículo con la URL de su página"

# --- 9. EL SABOR ---
paso "escribiendo el archivo de DOAJ"
mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
temporal="$DIR_SALIDA/.doaj-$base.xml.tmp"
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$VOLCADO" -xsl:"$XSL" -o:"$temporal" \
            dir_canonicos="file://$DIR_CANONICOS/" 2>&1)
if (( $? != 0 )) || [[ ! -s "$temporal" ]]; then
    rm -f "$temporal"
    mostrar_cola "$salida"
    morir "La transformación numero-a-doaj.xsl falló: el sabor DOAJ no se genera"
fi
mv -f "$temporal" "$SALIDA" || morir "No se pudo escribir $SALIDA"
records=$(xmllint --xpath 'count(/records/record)' "$SALIDA" 2>/dev/null)
ok "salidas/doaj/doaj-$base.xml: ${records:-?} record(s)"

# --- 10. EL ESQUEMA DE DOAJ ---
paso "validando contra doajArticles.xsd"
errores="$(validar_doaj "$SALIDA")"
if [[ -z "$errores" ]]; then
    ok "válido contra el esquema de DOAJ"
else
    printf '%s\n' "$errores" | head -15 | sed 's/^/     /'
    aviso "el archivo no valida contra el esquema de DOAJ: DOAJ lo rechazaría. Detalle en la solapa «Validar», tipo DOAJ"
fi

rm -rf -- "${DIR_CANONICOS:?}"
terminar
