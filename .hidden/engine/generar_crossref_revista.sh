#!/bin/bash
# Sabor Crossref del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa F3 de los sabores XML (claude/salidas-revistas.md), decisiones de
# Alberto del 18/11/2026:
#   - el esquema 5.4.0: la 5.5.0 (la de los roles CRediT) está en XSD 1.1 y
#     xmllint no la compila (medido);
#   - el depositante y el registrante son la editorial; el correo, el del
#     volcado (el de la revista si tiene; si no, el de la editorial);
#   - las referencias, estructuradas desde el canónico;
#   - EL NÚMERO SE DEPOSITA COMPLETO O NO SE DEPOSITA: un artículo sin DOI,
#     o con un DOI que no es del prefijo de la editorial, frena;
#   - LA PINZA DE CROSSREF, la misma que la de DOAJ: el resource es el
#     self-uri content-type="pagina" del canónico, y sin él no se genera;
#   - como todos los sabores, exige las páginas de cada artículo.
#
# USO
#   generar_crossref_revista.sh <ruta_proyecto> <nombre_bib>
#
#   El .bib lo recibe por ser el contrato común de las salidas del número
#   (m_GenerarSalidasRevista.LanzarSalidaNumero): este script no lo lee.
#
# LA FRONTERA CON GAMBAS (SC-13): Gambas escribe antes el volcado del número
# (tmp/numero-datos.xml, versión 4). Este script no toca la base ni deposita:
# deja el archivo para subirlo a Crossref.
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado: la editorial, el correo y el prefijo DOI; y las
#      páginas de cada artículo.
#   2. Regenera los canónicos (generar_canonicos_articulos.sh, anidado): el
#      sabor sale del canónico vigente, que ya pasó la DTD y JATS4R.
#   3. Copia los canónicos sin DOCTYPE (GV-25) y verifica cada uno: el DOI
#      con el prefijo de la editorial y el self-uri de página.
#   4. numero-a-crossref.xsl escribe salidas/crossref/crossref-{número}.xml,
#      en un temporal que se renombra con mv. El timestamp es la hora de la
#      corrida: Crossref exige que crezca en cada depósito.
#   5. Lo valida contra crossref5.4.0.xsd, sin red (validar_crossref,
#      revista_comun.sh). Un archivo que no valida se conserva para
#      revisarlo, y llega a Gambas como código 3: Crossref lo rechazaría.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   insumos ausentes, la editorial, el correo o el prefijo DOI sin
#            cargar, un artículo sin páginas, un canónico que no se generó,
#            un artículo sin DOI, con otro prefijo o sin self-uri de página,
#            la transformación
#   avisa    canónicos con avisos, el esquema de Crossref
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
LISTA_REL="tmp/lote-crossref-revista.txt"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "CROSSREF DEL NÚMERO"

# --- 3. ARGUMENTOS ---
if (( $# < 1 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> [<nombre_bib>]"
fi
DIR_PROYECTO="${1%/}"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
DIR_SALIDA="$DIR_PROYECTO/salidas/crossref"
# LOS CANÓNICOS SIN DOCTYPE: SAXON NO BAJA LA DTD REMOTA (GV-25)
DIR_CANONICOS="$DIR_PROYECTO/tmp/crossref-canonicos"
XSL="$DIR_GBP_LOCAL/xslt/numero-a-crossref.xsl"

# --- 4. ENTORNO ---
paso "verificando el entorno"
[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
requerir_comandos java xmllint
[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "Falta la hoja $XSL: actualizá la copia local (~/.gbpublisher/xslt)"
# EL ESQUEMA SE COMPRUEBA ANTES DE TRABAJAR: SIN ÉL NO HAY VALIDACIÓN
esquema_crossref_presente || morir "No está el esquema de Crossref del sistema: $XSD_CROSSREF (o su catálogo, $CATALOGO_CROSSREF, o standard-modules/)"
ok "herramientas, hoja y esquema de Crossref 5.4.0"

# --- 5. EL VOLCADO ---
[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"
MODELO="$(dato_volcado 'string(/numero-datos/revista/@modelo-paginacion)')"
[[ -n "$MODELO" ]] || morir "La revista no tiene modelo de paginación: elegilo en la ficha de la revista"
ok "volcado versión $version; paginación $MODELO"

# EL ENCABEZADO DEL DEPÓSITO Y EL PREFIJO: SIN ELLOS NO HAY DEPÓSITO
EDITORIAL="$(dato_volcado 'normalize-space(/numero-datos/revista/editorial)')"
CORREO="$(dato_volcado 'normalize-space(/numero-datos/revista/email)')"
PREFIJO="$(dato_volcado 'normalize-space(/numero-datos/revista/doi-prefijo)')"
[[ -n "$EDITORIAL" ]] || morir "La revista no tiene editorial: es el depositante de Crossref. Elegila en la ficha de la revista"
[[ "$CORREO" == *@*.* ]] ||
    morir "No hay correo de la revista ni de su editorial: Crossref manda ahí el informe del depósito. Cargalo en la ficha"
[[ "$PREFIJO" =~ ^10\.[0-9]{4,9}$ ]] ||
    morir "El prefijo DOI de la editorial no está cargado o no es válido («$PREFIJO»): cargalo en la ficha de la editorial"
ok "depositante $EDITORIAL <$CORREO>; prefijo $PREFIJO"

base="$(nombre_numero)"
[[ -n "$base" ]] ||
    morir "Para nombrar el archivo hacen falta el acrónimo de la revista (en Revistas) y el año del número (en sus metadatos)"
SALIDA="$DIR_SALIDA/crossref-$base.xml"

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
printf '  %-14s %s\n'   "Salida:"   "salidas/crossref/crossref-$base.xml"

# --- 7. CANÓNICOS ---
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: el sabor Crossref no se genera" ;;
esac

# --- 8. CANÓNICOS SIN DTD, LOS DOI Y LA PINZA ---
paso "verificando el DOI y la página de cada artículo"
rm -rf -- "${DIR_CANONICOS:?}"
mkdir -p "$DIR_CANONICOS" || morir "No se pudo crear $DIR_CANONICOS"
problemas=()
for a in "${ARTICULOS[@]}"; do
    xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$a.xml" > "$DIR_CANONICOS/c-$a.xml" 2>/dev/null ||
        morir "$a: el canónico jats/c-$a.xml no se pudo leer"
    doi="$(xmllint --xpath "normalize-space((//*[local-name()='article-meta']/*[local-name()='article-id'][@pub-id-type='doi'])[1])" \
           "$DIR_CANONICOS/c-$a.xml" 2>/dev/null)"
    url="$(xmllint --xpath "normalize-space((//*[local-name()='article-meta']/*[local-name()='self-uri'][@content-type='pagina'])[1]/@*[local-name()='href'])" \
           "$DIR_CANONICOS/c-$a.xml" 2>/dev/null)"
    # EL NÚMERO SE DEPOSITA COMPLETO: UN DOI QUE FALTA O DE OTRO PREFIJO
    # FRENA (DECISIÓN DE ALBERTO). EL PREFIJO SE COMPARA CON LA BARRA: 10.1234
    # NO ES EL PREFIJO DE 10.12345/…
    if [[ -z "$doi" ]]; then
        problemas+=("$a: sin DOI")
    elif [[ "$doi" != "$PREFIJO/"?* ]]; then
        problemas+=("$a: el DOI $doi no es del prefijo $PREFIJO")
    fi
    if [[ ! "$url" =~ ^https?:// ]]; then
        problemas+=("$a: sin la URL de su página (self-uri de página)")
    fi
done
if (( ${#problemas[@]} > 0 )); then
    printf '%s\n' "${problemas[@]}" | sed 's/^/     /'
    morir "${#problemas[@]} problema(s) en los artículos: el número se deposita completo. Corregí los metadatos de esos artículos"
fi
ok "cada artículo con su DOI ($PREFIJO) y la URL de su página"

# --- 9. EL SABOR ---
paso "escribiendo el depósito de Crossref"
mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
temporal="$DIR_SALIDA/.crossref-$base.xml.tmp"
# LA HORA DE LA CORRIDA: CROSSREF EXIGE QUE EL timestamp CREZCA EN CADA
# DEPÓSITO («must be incremented with each metadata record update»)
marca="$(date +%Y%m%d%H%M%S)"
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$VOLCADO" -xsl:"$XSL" -o:"$temporal" \
            dir_canonicos="file://$DIR_CANONICOS/" timestamp="$marca" numero="$base" 2>&1)
if (( $? != 0 )) || [[ ! -s "$temporal" ]]; then
    rm -f "$temporal"
    mostrar_cola "$salida"
    morir "La transformación numero-a-crossref.xsl falló: el sabor Crossref no se genera"
fi
mv -f "$temporal" "$SALIDA" || morir "No se pudo escribir $SALIDA"
articulos=$(xmllint --xpath "count(//*[local-name()='journal_article'])" "$SALIDA" 2>/dev/null)
ok "salidas/crossref/crossref-$base.xml: ${articulos:-?} artículo(s), timestamp $marca"

# --- 10. EL ESQUEMA DE CROSSREF ---
paso "validando contra crossref5.4.0.xsd"
errores="$(validar_crossref "$SALIDA")"
if [[ -z "$errores" ]]; then
    ok "válido contra el esquema de Crossref 5.4.0"
else
    printf '%s\n' "$errores" | head -15 | sed 's/^/     /'
    aviso "el depósito no valida contra el esquema de Crossref: Crossref lo rechazaría. Detalle en la solapa «Validar», tipo Crossref"
fi

rm -rf -- "${DIR_CANONICOS:?}"
terminar
