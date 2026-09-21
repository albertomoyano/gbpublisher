#!/bin/bash
# Ensamblador del canónico DocBook del libro — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   ensamblar_libro.sh <ruta_proyecto> <nombre_base> <lugar_bibliografia> <biblio_rel>
#
#   ruta_proyecto        raíz del proyecto
#   nombre_base          nombre del libro sin el prefijo «l-»: el mismo que
#                        usan tmp/manifiesto-libro-{base}.xml y
#                        jats/c-libro-{base}.xml
#   lugar_bibliografia   por_capitulo | consolidada
#   biblio_rel           ruta relativa al proyecto de la bibliografía
#                        consolidada, o «-» en por_capitulo. EL GUION EXISTE
#                        PORQUE UN ARGUMENTO VACÍO ES FRÁGIL DE PASAR DESDE
#                        GAMBAS: SI SE PERDIERA, LOS SIGUIENTES SE CORRERÍAN.
#
# LOS INSUMOS LOS ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT: el manifiesto,
# el info del libro y, si corresponde, la bibliografía consolidada. Todo lo
# que sale de la base llega como archivo. Este script no toca la base.
# ============================================================================
# POR QUÉ ESCRIBE EN UN TEMPORAL
#
#   El canónico del libro apareció truncado en medio de una palabra, y la
#   aplicación lo dio por «generado y validado» porque solo miraba que el
#   archivo existiera. Existir no es haber terminado: el archivo aparece con
#   el primer byte.
#
#   Acá Saxon escribe en un temporal de la misma carpeta, se verifica que esté
#   bien formado, y recién entonces se renombra sobre el definitivo. En bash
#   mv DENTRO DEL MISMO SISTEMA DE ARCHIVOS ES UN RENOMBRE ATÓMICO QUE
#   REEMPLAZA EL DESTINO —a diferencia de la sentencia Move de Gambas, que no
#   pisa (GV-39)—. En disco hay siempre una versión completa, la anterior o la
#   nueva, nunca una a medio escribir. Y si el ensamblado falla, el canónico
#   anterior sigue intacto.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#
#   aborta   insumos ausentes o mal formados, un capítulo declarado en el
#            manifiesto que falta o está mal formado, un fallo de Saxon, un
#            resultado mal formado. En todos esos casos NO se reemplaza nada.
#   avisa    el canónico no valida contra el RNG de DocBook 5.2, o no se pudo
#            validar. Se conserva, porque está bien formado y las salidas lo
#            pueden consumir, pero el aviso llega a Gambas como código 3.
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_SAXON=300
LINEAS_ERROR_RNG=15

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "ENSAMBLADO DEL CANÓNICO DEL LIBRO"

# --- 2. ARGUMENTOS ---
if (( $# < 4 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_base> <lugar_bibliografia> <biblio_rel|->"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_BASE="$2"
LUGAR_BIB="$3"
BIBLIO_REL="$4"
if [[ "$BIBLIO_REL" == "-" ]]; then
    BIBLIO_REL=""
fi

MANIFIESTO="$DIR_PROYECTO/tmp/manifiesto-libro-$NOMBRE_BASE.xml"
CANONICO="$DIR_PROYECTO/jats/c-libro-$NOMBRE_BASE.xml"
# EL TEMPORAL VA EN LA MISMA CARPETA QUE EL DEFINITIVO: SI ESTUVIERA EN OTRO
# SISTEMA DE ARCHIVOS, mv DEJARÍA DE SER UN RENOMBRE Y PASARÍA A SER UNA COPIA
TEMPORAL="$DIR_PROYECTO/jats/.c-libro-$NOMBRE_BASE.xml.tmp"
XSL="$DIR_GBP_LOCAL/xslt/ensamblar-libro-canonico.xsl"
RNG="$DIR_GBP_LOCAL/schemas/docbook/docbook.rng"

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]      || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/jats" ]] || morir "El proyecto no tiene carpeta jats/"

requerir_comandos java xmllint

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de ensamblado: $XSL"

case "$LUGAR_BIB" in
    por_capitulo|consolidada) ;;
    *) morir "Modelo de bibliografía no reconocido: «$LUGAR_BIB»" ;;
esac

if [[ "$LUGAR_BIB" == "consolidada" && -z "$BIBLIO_REL" ]]; then
    morir "La bibliografía es consolidada pero no se indicó su archivo"
fi

ok "herramientas del sistema"

# --- 4. INSUMOS ---
paso "verificando los insumos"

[[ -f "$MANIFIESTO" ]] || morir "No existe el manifiesto: $MANIFIESTO"
bien_formado "$MANIFIESTO" || morir "El manifiesto está mal formado: $MANIFIESTO"
ok "manifiesto"

# LA RUTA DEL INFO SE LEE DEL MANIFIESTO Y NO SE RECONSTRUYE: ES LA QUE VA A
# CARGAR EL ENSAMBLADOR, Y SI LAS DOS DIVERGIERAN SE VERIFICARÍA OTRO ARCHIVO
INFO_REL=$(xmllint --xpath 'string(/manifiesto-libro/libro/@info_libro)' "$MANIFIESTO" 2>/dev/null)
[[ -n "$INFO_REL" ]] || morir "El manifiesto no declara el archivo de información del libro"

INFO="$DIR_PROYECTO/$INFO_REL"
[[ -f "$INFO" ]]    || morir "No existe la información del libro: $INFO"
bien_formado "$INFO" || morir "La información del libro está mal formada: $INFO"
ok "información del libro"

if [[ "$LUGAR_BIB" == "consolidada" ]]; then
    BIBLIO="$DIR_PROYECTO/$BIBLIO_REL"
    [[ -f "$BIBLIO" ]]    || morir "No existe la bibliografía consolidada: $BIBLIO"
    bien_formado "$BIBLIO" || morir "La bibliografía consolidada está mal formada: $BIBLIO"
    ok "bibliografía consolidada"
else
    tenue "bibliografía por capítulo"
fi

# --- 5. CANÓNICOS DE LOS CAPÍTULOS ---
# SE VERIFICA EXACTAMENTE LO QUE EL MANIFIESTO DECLARA, QUE ES LO QUE EL
# ENSAMBLADOR VA A CARGAR. ANTES SE VERIFICABA LA LISTA DE LA BASE, Y LA
# DEL MANIFIESTO PODÍA NO COINCIDIR CON ELLA.
# BIEN FORMADO Y NO SOLO PRESENTE: UN CANÓNICO DE CAPÍTULO TRUNCADO EXISTE.
# SE JUNTAN TODOS LOS PROBLEMAS ANTES DE ABORTAR: EL EDITOR NECESITA VER TODO
# LO QUE HAY QUE REGENERAR, NO SOLO EL PRIMERO.
paso "verificando los canónicos de los capítulos"

mapfile -t RUTAS < <(
    xmllint --xpath '/manifiesto-libro/capitulos/capitulo/@path' "$MANIFIESTO" 2>/dev/null |
    grep -oP 'path="\K[^"]+'
)

(( ${#RUTAS[@]} > 0 )) || morir "El manifiesto no declara ningún capítulo"

problemas=0
for ruta in "${RUTAS[@]}"; do
    archivo="$DIR_PROYECTO/$ruta"
    if [[ ! -f "$archivo" ]]; then
        printf '  %s✗%s falta %s\n' "$C_ERROR" "$C_RESET" "$ruta"
        problemas=$((problemas + 1))
    elif ! bien_formado "$archivo"; then
        printf '  %s✗%s mal formado %s\n' "$C_ERROR" "$C_RESET" "$ruta"
        problemas=$((problemas + 1))
    fi
done

if (( problemas > 0 )); then
    morir "$problemas canónico(s) de capítulo con problemas: regenerá cada uno antes de ensamblar"
fi

ok "${#RUTAS[@]} capítulos presentes y bien formados"

# --- 6. ENSAMBLADO ---
paso "ensamblando"

rm -f "$TEMPORAL"

salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$MANIFIESTO" \
            -xsl:"$XSL" \
            -o:"$TEMPORAL" \
            proyecto_dir="$DIR_PROYECTO" \
            lugar_bibliografia="$LUGAR_BIB" \
            biblio_libro="$BIBLIO_REL" 2>&1)
codigo=$?

if (( codigo == 124 )); then
    rm -f "$TEMPORAL"
    morir "Saxon no terminó en $TIEMPO_SAXON segundos. El canónico anterior se conserva."
fi

if (( codigo != 0 )); then
    mostrar_cola "$salida"
    rm -f "$TEMPORAL"
    morir "Saxon no pudo ensamblar el libro. El canónico anterior se conserva."
fi

if [[ ! -s "$TEMPORAL" ]]; then
    rm -f "$TEMPORAL"
    morir "Saxon terminó sin escribir el canónico. El anterior se conserva."
fi

if ! bien_formado "$TEMPORAL"; then
    rm -f "$TEMPORAL"
    morir "El ensamblado produjo un XML mal formado. El canónico anterior se conserva."
fi

# LOS MENSAJES DE xsl:message QUE NO TERMINAN LA TRANSFORMACIÓN LLEGAN ACÁ CON
# CÓDIGO 0. SE MUESTRAN PARA QUE NO SE PIERDAN
if [[ -n "$salida" ]]; then
    tenue "mensajes de la transformación:"
    mostrar_cola "$salida" 10
fi

mv -f "$TEMPORAL" "$CANONICO" || morir "No se pudo reemplazar el canónico: $CANONICO"
ok "canónico ensamblado y bien formado"

# --- 7. VALIDACIÓN CONTRA DocBook 5.2 ---
# INFORMATIVA POR DECISIÓN: UN CANÓNICO BIEN FORMADO QUE NO VALIDA SE CONSERVA
# Y LAS SALIDAS LO PUEDEN CONSUMIR, PERO EL AVISO LLEGA A GAMBAS COMO CÓDIGO 3.
# NO VALIDAR —jing AUSENTE O ESQUEMA AUSENTE— TAMBIÉN ES AVISO: EL INFORME NO
# PUEDE DAR POR VÁLIDO LO QUE NO VALIDÓ.
paso "validando contra DocBook 5.2"

if ! command -v jing >/dev/null 2>&1; then
    aviso "jing no está instalado: el canónico no se validó contra el esquema"
elif [[ ! -f "$RNG" ]]; then
    aviso "no se encontró el esquema $RNG: el canónico no se validó"
else
    salida=$(jing "$RNG" "$CANONICO" 2>&1)
    codigo=$?
    if (( codigo == 0 )); then
        ok "válido"
    else
        errores=$(printf '%s\n' "$salida" | grep -c .)
        aviso "$errores error(es) de validación contra el esquema:"
        # SE QUITA LA RUTA DEL ARCHIVO, QUE SE REPITE EN CADA LÍNEA: QUEDA
        # LÍNEA:COLUMNA Y EL MENSAJE
        printf '%s\n' "$salida" | sed "s|^$CANONICO:||" |
            head -"$LINEAS_ERROR_RNG" | sed 's/^/     /'
        if (( errores > LINEAS_ERROR_RNG )); then
            tenue "(+$((errores - LINEAS_ERROR_RNG)) más)"
        fi
    fi
fi

# --- 8. RESUMEN ---
# SOLO SE AFIRMA LO VERIFICADO: BIEN FORMADO SIEMPRE; VÁLIDO SOLO SI jing LO
# DIJO, Y ESO YA QUEDÓ ESCRITO ARRIBA.
if [[ -z "${GBP_ANIDADO:-}" ]]; then
    echo
    titulo "$REGLA"
    printf '%s✓ Canónico del libro ensamblado%s\n' "$C_OK" "$C_RESET"
    printf '  %-14s %s\n' "Archivo:"   "$CANONICO"
    printf '  %-14s %s KB\n' "Tamaño:" "$(( $(stat -c%s "$CANONICO") / 1024 ))"
    printf '  %-14s %s\n' "Capítulos:" "${#RUTAS[@]}"
    if (( AVISOS > 0 )); then
        printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
    fi
    echo
fi

terminar
