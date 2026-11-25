#!/bin/bash
# Depósito Crossref del libro — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Decisiones de Alberto del 25/11/2026 (claude/crossref-libros.md, F2 a F6):
#   - el esquema 5.4.0, el mismo de las revistas (crossref_comun.sh);
#   - el depositante y el registrante son la editorial principal (orden 1 de
#     libro_editorial); el correo, el del libro si tiene uno, si no, el de la
#     editorial; el prefijo, el de la editorial: los da el volcado;
#   - EL CONTENIDO SALE DEL CANÓNICO ENSAMBLADO: este script lo ensambla
#     (ensamblar_libro.sh, anidado). Gambas regenera antes los canónicos de
#     los capítulos, para que lleven las páginas y los DOI de la base;
#   - el libro SIN DOI FRENA: Crossref no acepta capítulos sin el DOI del
#     libro (markup guide, «books and chapters»);
#   - van como content_item las piezas con DOI; si hay alguna, una pieza de
#     tipo «capitulo» sin DOI frena; un DOI de otro prefijo frena;
#   - el ISBN impreso igual al electrónico frena (dos ediciones no comparten
#     ISBN); sin ISBN va noisbn, con aviso;
#   - F4: el resource de cada pieza es url-libro + h-{nombre_archivo}.html; el
#     del libro, url-libro. Sin url-libro, o sin la barra final con la que el
#     HTML arma esas direcciones, frena.
#
# USO
#   generar_crossref_libro.sh <ruta_proyecto> <nombre_base> <lugar_bibliografia> <biblio_rel|->
#
#   Los cuatro argumentos son los de ensamblar_libro.sh, que este script
#   invoca.
#
# LA FRONTERA CON GAMBAS (SC-13): Gambas escribe antes el volcado
# (tmp/crossref-libro-datos.xml, versión 1), el info y el manifiesto del
# libro. Este script no toca la base ni deposita: deja el archivo para
# subirlo a Crossref.
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado: la editorial, el correo y el prefijo DOI.
#   2. Ensambla el canónico del libro (ensamblar_libro.sh, anidado).
#   3. Lee del canónico lo que hace falta para frenar (libro-a-crossref.xsl,
#      plantilla «verificar») y frena o avisa.
#   4. libro-a-crossref.xsl escribe salidas/crossref/crossref-l-{base}.xml,
#      en un temporal que se renombra con mv. El timestamp es la hora de la
#      corrida: Crossref exige que crezca en cada depósito.
#   5. Lo valida contra crossref5.4.0.xsd, sin red. Un archivo que no valida
#      se conserva para revisarlo, y llega a Gambas como código 3.
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
# EL ESQUEMA DE CROSSREF Y SU VALIDACIÓN
if ! source "$DIR_ENGINE/crossref_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/crossref_comun.sh" >&2
    exit 1
fi

# --- 2. CONFIGURACIÓN ---
TIEMPO_SAXON=120
VOLCADO_REL="tmp/crossref-libro-datos.xml"
VERSION_DATOS="1"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "CROSSREF DEL LIBRO"

# --- 3. ARGUMENTOS ---
if (( $# < 4 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_base> <lugar_bibliografia> <biblio_rel|->"
fi
DIR_PROYECTO="${1%/}"
NOMBRE_BASE="$2"
LUGAR_BIB="$3"
BIBLIO_ARG="$4"
# EL NOMBRE VA A RUTAS
[[ "$NOMBRE_BASE" =~ ^[A-Za-z0-9._-]+$ ]] || morir "Nombre de libro no válido: «$NOMBRE_BASE»"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
CANONICO="$DIR_PROYECTO/jats/c-libro-$NOMBRE_BASE.xml"
MANIFIESTO="$DIR_PROYECTO/tmp/manifiesto-libro-$NOMBRE_BASE.xml"
DIR_SALIDA="$DIR_PROYECTO/salidas/crossref"
SALIDA="$DIR_SALIDA/crossref-l-$NOMBRE_BASE.xml"
XSL="$DIR_GBP_LOCAL/xslt/libro-a-crossref.xsl"

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
version="$(xmllint --xpath 'string(/crossref-libro-datos/@version)' "$VOLCADO" 2>/dev/null)"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"

# EL ENCABEZADO DEL DEPÓSITO Y EL PREFIJO: SIN ELLOS NO HAY DEPÓSITO
EDITORIAL="$(xmllint --xpath 'normalize-space(/crossref-libro-datos/depositante)' "$VOLCADO" 2>/dev/null)"
CORREO="$(xmllint --xpath 'normalize-space(/crossref-libro-datos/correo)' "$VOLCADO" 2>/dev/null)"
PREFIJO="$(xmllint --xpath 'normalize-space(/crossref-libro-datos/prefijo)' "$VOLCADO" 2>/dev/null)"
[[ -n "$EDITORIAL" ]] || morir "El libro no tiene editorial: es el depositante de Crossref. Elegila en los metadatos del libro"
[[ "$CORREO" == *@*.* ]] ||
    morir "No hay correo del libro ni de su editorial: Crossref manda ahí el informe del depósito. Cargalo en los metadatos del libro o en la editorial"
[[ "$PREFIJO" =~ ^10\.[0-9]{4,9}$ ]] ||
    morir "El prefijo DOI de la editorial principal no está cargado o no es válido («$PREFIJO»): cargalo en la editorial (gbpublisher admin)"
ok "depositante $EDITORIAL <$CORREO>; prefijo $PREFIJO"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "salidas/crossref/crossref-l-$NOMBRE_BASE.xml"

# --- 6. CANÓNICO DEL LIBRO ---
# CÓDIGO 3 DEL ENSAMBLADOR: EL CANÓNICO EXISTE Y ESTÁ BIEN FORMADO, PERO CON
# AVISOS. SE SIGUE, Y EL AVISO SE HEREDA. CUALQUIER OTRO CÓDIGO DISTINTO DE
# 0: NO HAY CANÓNICO NUEVO Y NO SE GENERA NADA SOBRE EL VIEJO
GBP_ANIDADO=1 bash "$DIR_ENGINE/ensamblar_libro.sh" \
    "$DIR_PROYECTO" "$NOMBRE_BASE" "$LUGAR_BIB" "$BIBLIO_ARG"
codigo=$?
if (( codigo == SALIDA_AVISOS )); then
    aviso "el canónico del libro tiene avisos: el depósito se genera igual"
elif (( codigo != SALIDA_OK )); then
    morir "No se pudo ensamblar el canónico del libro: el depósito no se genera"
fi
[[ -f "$MANIFIESTO" ]] || morir "No está el manifiesto del libro: tmp/manifiesto-libro-$NOMBRE_BASE.xml"

# --- 7. LO QUE FRENA ---
paso "verificando el libro y sus piezas"
# LOS MENSAJES DE java VAN APARTE: EN LOS DATOS SOLO LO QUE ESCRIBE LA HOJA
errores_saxon="$DIR_PROYECTO/tmp/crossref-libro-verificar.err"
datos=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" -s:"$VOLCADO" -xsl:"$XSL" -it:verificar \
          canonico="file://$CANONICO" manifiesto="file://$MANIFIESTO" 2>"$errores_saxon")
if (( $? != 0 )); then
    mostrar_cola "$(cat "$errores_saxon")"
    rm -f "$errores_saxon"
    morir "No se pudo leer el canónico del libro con libro-a-crossref.xsl"
fi
rm -f "$errores_saxon"
# LA SALIDA ES TEXTO, PERO SAXON LE ANTEPONE LA DECLARACIÓN XML DEL DOCUMENTO
# PRINCIPAL
# Y LOS CAMPOS VACÍOS SON PARTE DEL FORMATO: read CON UN TABULADOR EN IFS
# JUNTA DOS SEGUIDOS (ES ESPACIO EN BLANCO PARA bash). SE PASAN A US (0x1F),
# QUE NO LO ES
datos="$(sed 's/^<?xml[^>]*?>//' <<< "$datos" | tr '\t' '\037')"
SEP=$'\037'

problemas=()
declare -A vistos=()
con_doi=0
IFS="$SEP" read -r _ DOI_LIBRO ISBN_IMPRESO ISBN_ELECTRONICO URL_LIBRO TIPO_LIBRO < <(grep "^libro$SEP" <<< "$datos")

# EL LIBRO: DOI, PREFIJO, ISBN Y DIRECCIÓN
if [[ -z "$DOI_LIBRO" ]]; then
    problemas+=("el libro no tiene DOI: Crossref no acepta un libro ni sus capítulos sin el DOI de la obra")
elif [[ "$DOI_LIBRO" != "$PREFIJO/"?* ]]; then
    # EL PREFIJO SE COMPARA CON LA BARRA: 10.1234 NO ES EL PREFIJO DE 10.12345/…
    problemas+=("el DOI del libro, $DOI_LIBRO, no es del prefijo $PREFIJO")
else
    vistos["$DOI_LIBRO"]="el libro"
fi
if [[ -n "$ISBN_IMPRESO" && "$ISBN_IMPRESO" == "$ISBN_ELECTRONICO" ]]; then
    problemas+=("el ISBN impreso y el electrónico son el mismo ($ISBN_IMPRESO): dos ediciones no comparten ISBN")
fi
if [[ ! "$URL_LIBRO" =~ ^https?://[^[:space:]]+/$ ]]; then
    problemas+=("la dirección del libro (url-libro) falta o no termina en «/»: es la del DOI y la base de la de cada capítulo")
fi

# LAS PIEZAS: LAS QUE TIENEN DOI VAN; CON ALGUNA, UN CAPÍTULO SIN DOI FRENA
while IFS="$SEP" read -r _ id archivo tipo doi paginas; do
    [[ -n "$doi" ]] && con_doi=$((con_doi + 1))
done < <(grep "^pieza$SEP" <<< "$datos")
while IFS="$SEP" read -r _ id archivo tipo doi paginas; do
    if [[ -z "$doi" ]]; then
        if (( con_doi > 0 )) && [[ "$tipo" == "capitulo" ]]; then
            problemas+=("$archivo: capítulo sin DOI, y otras piezas del libro lo tienen")
        fi
        continue
    fi
    if [[ "$doi" != "$PREFIJO/"?* ]]; then
        problemas+=("$archivo: el DOI $doi no es del prefijo $PREFIJO")
    elif [[ -n "${vistos[$doi]:-}" ]]; then
        problemas+=("$archivo: el DOI $doi es el mismo de ${vistos[$doi]}")
    else
        vistos["$doi"]="$archivo"
    fi
    [[ -n "$paginas" ]] || aviso "$archivo: sin páginas en la base; componé el PDF del libro y volvé a generar"
done < <(grep "^pieza$SEP" <<< "$datos")

if (( ${#problemas[@]} > 0 )); then
    printf '%s\n' "${problemas[@]}" | sed 's/^/     /'
    morir "${#problemas[@]} problema(s): corregí los metadatos del libro o de esas piezas"
fi
[[ -n "$ISBN_IMPRESO$ISBN_ELECTRONICO" ]] ||
    aviso "el libro no tiene ISBN: se deposita con noisbn"
ok "libro $DOI_LIBRO ($TIPO_LIBRO); $con_doi pieza(s) con DOI"

# --- 8. EL DEPÓSITO ---
paso "escribiendo el depósito de Crossref"
mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
temporal="$DIR_SALIDA/.crossref-l-$NOMBRE_BASE.xml.tmp"
# LA HORA DE LA CORRIDA: CROSSREF EXIGE QUE EL timestamp CREZCA EN CADA
# DEPÓSITO («must be incremented with each metadata record update»)
marca="$(date +%Y%m%d%H%M%S)"
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$VOLCADO" -xsl:"$XSL" -o:"$temporal" \
            canonico="file://$CANONICO" manifiesto="file://$MANIFIESTO" \
            timestamp="$marca" libro="$NOMBRE_BASE" 2>&1)
if (( $? != 0 )) || [[ ! -s "$temporal" ]]; then
    rm -f "$temporal"
    mostrar_cola "$salida"
    morir "La transformación libro-a-crossref.xsl falló: el depósito no se genera"
fi
mv -f "$temporal" "$SALIDA" || morir "No se pudo escribir $SALIDA"
piezas=$(xmllint --xpath "count(//*[local-name()='content_item'])" "$SALIDA" 2>/dev/null)
citas=$(xmllint --xpath "count(//*[local-name()='citation'])" "$SALIDA" 2>/dev/null)
ok "salidas/crossref/crossref-l-$NOMBRE_BASE.xml: ${piezas:-?} pieza(s), ${citas:-?} referencia(s), timestamp $marca"

# --- 9. EL ESQUEMA DE CROSSREF ---
paso "validando contra crossref5.4.0.xsd"
errores="$(validar_crossref "$SALIDA")"
if [[ -z "$errores" ]]; then
    ok "válido contra el esquema de Crossref 5.4.0"
else
    printf '%s\n' "$errores" | head -15 | sed 's/^/     /'
    aviso "el depósito no valida contra el esquema de Crossref: Crossref lo rechazaría"
fi

terminar
