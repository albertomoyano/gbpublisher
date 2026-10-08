#!/usr/bin/env bash
# ============================================================
# SCRIPT      : colorear_codigo.sh
# PROPÓSITO   : PASO PREVIO DE LAS SALIDAS HTML Y PDF (SC-42): COLOREA
#               LOS BLOQUES DE CÓDIGO DE UN XML CANÓNICO Y DEJA UN
#               ARCHIVO POR BLOQUE PARA QUE LA HOJA DE SALIDA LO META.
#               1. extraer-codigo.xsl ESCRIBE codigo-N.txt E indice.txt
#               2. colorear_codigo.lua ESCRIBE codigo-N.html O .tex
# USO         : colorear_codigo.sh <xml> <carpeta> <html|latex>
#               <xml>     EL MISMO ARCHIVO QUE DESPUÉS TRANSFORMA LA HOJA
#               <carpeta> SE VACÍA Y SE REESCRIBE ENTERA
# SALIDA      : 0 SI TERMINÓ (AUNQUE EL XML NO TENGA CÓDIGO); 1 SI NO.
#               EN LA ÚLTIMA LÍNEA DE stdout, CUÁNTOS BLOQUES COLOREÓ.
# NOTA        : LA HOJA DE SALIDA RECIBE LA CARPETA EN EL PARÁMETRO
#               codigo_dir Y FRENA SI FALTA EL ARCHIVO DE UN BLOQUE:
#               SI ESTE PASO NO CORRIÓ, LA SALIDA NO SE GENERA.
# ============================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

TIEMPO_SAXON=120
TIEMPO_PANDOC=120

# --- 1. ARGUMENTOS ---
if (( $# != 3 )); then
    morir "Uso: $(basename "$0") <xml> <carpeta> <html|latex>"
fi
XML="$1"
CARPETA="${2%/}"
FORMATO="$3"
XSL="$DIR_GBP_LOCAL/xslt/extraer-codigo.xsl"
LUA="$DIR_ENGINE/colorear_codigo.lua"

[[ "$FORMATO" == "html" || "$FORMATO" == "latex" ]] || morir "Formato desconocido: $FORMATO"
[[ -f "$XML" ]]        || morir "No existe el XML: $XML"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de extracción: $XSL"
[[ -f "$LUA" ]]        || morir "No se encontró el coloreador: $LUA"
[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
requerir_comandos java pandoc

# --- 2. CARPETA LIMPIA: UN ARCHIVO DE UNA CORRIDA ANTERIOR NO SE MEZCLA ---
rm -rf "$CARPETA"
mkdir -p "$CARPETA" || morir "No se pudo crear $CARPETA"

# --- 3. EXTRACCIÓN ---
# LA CARPETA VA COMO RUTA ABSOLUTA: LA HOJA ARMA LA URI
CARPETA_ABS="$(readlink -f "$CARPETA")"
# EL CANÓNICO DE REVISTA DECLARA EL DTD DE JATS POR URL: CON EL CATÁLOGO
# LOCAL SE RESUELVE SIN RED, COMO EN LA SALIDA PDF. AL DOCBOOK NO LE AFECTA
CATALOGO="$DIR_GBP_LOCAL/dtd/catalog-jats-v1-4-no-base.xml"
OPC_CATALOGO=()
[[ -f "$CATALOGO" ]] && OPC_CATALOGO=(-catalog:"$CATALOGO")
salida=$(timeout "$TIEMPO_SAXON" java -Djavax.xml.accessExternalDTD=all -jar "$RUTA_SAXON" \
            "${OPC_CATALOGO[@]}" -s:"$XML" -xsl:"$XSL" dir="$CARPETA_ABS" 2>&1)
if (( $? != 0 )); then
    mostrar_cola "$salida"
    morir "No se pudieron extraer los bloques de código de $XML"
fi
[[ -f "$CARPETA/indice.txt" ]] || morir "La extracción terminó sin escribir el índice"

# --- 4. COLOREADO ---
salida=$(timeout "$TIEMPO_PANDOC" pandoc lua "$LUA" "$CARPETA_ABS" "$FORMATO" 2>&1)
if (( $? != 0 )); then
    mostrar_cola "$salida"
    morir "No se pudieron colorear los bloques de código"
fi

echo "$salida" | tail -n 1
exit 0
