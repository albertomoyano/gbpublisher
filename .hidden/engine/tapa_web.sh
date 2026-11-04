#!/bin/bash
# Tapa del libro para el portal (gbWeb) — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   tapa_web.sh <ruta_proyecto> <imagen_tapa>
#
#   ruta_proyecto  la carpeta del proyecto abierto (la conoce Gambas: la
#                  identidad del proyecto es el nombre de su .md, SC-82)
#   imagen_tapa    nombre del archivo de tapa según la base (libros_md.
#                  imagen_tapa); está en media/
#
# QUÉ HACE (SC-81)
#   Escribe la tapa para el portal en tmp/tapa-web.jpg y sus medidas
#   («ancho alto») en tmp/tapa-web.txt. NO TOCA LA BASE (SC-13, SC-53): la
#   guarda Gambas en libro_tapa_web (m_TapaWeb), y gbWeb copia esos bytes.
#
# LA RECETA, EN ESTE ORDEN
#   1. COLOR: receta_color_srgb de comun.sh, la misma de las imágenes de
#      pantalla (SC-76). Una tapa de imprenta suele venir en CMYK, y -strip
#      borra el perfil: el color se convierte antes.
#   2. APLANADO SOBRE BLANCO: JPEG no tiene transparencia. Sin esto, la zona
#      transparente de un PNG sale negra.
#   3. TAMAÑO: 600 px de ancho como máximo; «>» solo achica.
#   4. -strip: sin fechas ni perfiles en el archivo. Es lo que hace la salida
#      idéntica byte a byte entre corridas (GV-156).
#   5. JPEG, calidad 80: unos 117 KB por tapa (medido sobre la tapa de Duek,
#      02/11/2026; Alberto no distingue 600 de 800 px en pantalla).
#
# CÓDIGOS: los de comun.sh (0 bien; 1 no se generó).
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
# SI CAMBIA LA RECETA, CAMBIAN LOS BYTES DE TODAS LAS TAPAS: gbWeb LAS VERÁ
# COMO NUEVAS (SU NOMBRE PUBLICADO LLEVA EL sha256, SC-81)
TAPA_WEB_ANCHO=600
TAPA_WEB_CALIDAD=80
TAPA_WEB_FONDO="white"
SALIDA_REL="tmp/tapa-web.jpg"
MEDIDAS_REL="tmp/tapa-web.txt"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "TAPA PARA EL PORTAL"

# --- 2. ARGUMENTOS ---
if (( $# != 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <imagen_tapa>"
fi

DIR_PROYECTO="${1%/}"
IMAGEN_TAPA="$2"
ORIGEN="$DIR_PROYECTO/media/$IMAGEN_TAPA"
SALIDA="$DIR_PROYECTO/$SALIDA_REL"
MEDIDAS="$DIR_PROYECTO/$MEDIDAS_REL"

requerir_comandos convert identify

[[ -d "$DIR_PROYECTO" ]] || morir "No existe la carpeta del proyecto: $DIR_PROYECTO"
[[ -f "$ORIGEN" ]] || morir "La tapa declarada en la base no está en media/: $IMAGEN_TAPA"

# SOLO png Y jpg: LOS FORMATOS QUE ACEPTA EL FORMULARIO (btnBuscarTapa_Click)
EXTENSION="${IMAGEN_TAPA##*.}"
case "${EXTENSION,,}" in
    png|jpg|jpeg) ;;
    *) morir "Formato de tapa no admitido (solo png y jpg): $IMAGEN_TAPA" ;;
esac

# --- 3. LECTURA ---
paso "Lectura de la tapa"
# [0]: EL PRIMER CUADRO, POR SI EL ARCHIVO TRAE VARIOS
DATOS=$(identify -format '%w|%h|%[colorspace]|%[profile:icc]' "$ORIGEN[0]" 2>/dev/null) ||
    morir "No se pudo leer la tapa: $IMAGEN_TAPA"
[[ -n "$DATOS" ]] || morir "No se pudo leer la tapa: $IMAGEN_TAPA"
IFS='|' read -r ANCHO ALTO ESPACIO PERFIL <<< "$DATOS"
ok "$IMAGEN_TAPA: ${ANCHO}×${ALTO}, $ESPACIO${PERFIL:+, perfil «$PERFIL»}"

# --- 4. COLOR ---
receta_color_srgb "$ESPACIO" "$PERFIL" || morir "$NOTA_COLOR"
if [[ -n "$NOTA_COLOR" ]]; then
    ok "Color: $NOTA_COLOR"
else
    tenue "Color: sin conversión"
fi

# --- 5. CONVERSIÓN ---
paso "Conversión"
mkdir -p "$DIR_PROYECTO/tmp" || morir "No se pudo crear tmp/ en el proyecto"

# EL TEMPORAL EN LA MISMA CARPETA: EL mv QUE LO PONE EN SU LUGAR ES ATÓMICO
# (SC-53). CONSERVA LA EXTENSIÓN: convert ELIGE EL FORMATO POR ELLA
TEMPORAL="$DIR_PROYECTO/tmp/.tapa-web-$$.jpg"
TEMPORAL_MEDIDAS="$DIR_PROYECTO/tmp/.tapa-web-$$.txt"

if ! convert "$ORIGEN[0]" "${RECETA_COLOR[@]}" \
        -background "$TAPA_WEB_FONDO" -flatten \
        -resize "${TAPA_WEB_ANCHO}x>" \
        -strip -quality "$TAPA_WEB_CALIDAD" "$TEMPORAL" 2>/dev/null; then
    rm -f "$TEMPORAL"
    morir "No se pudo convertir la tapa"
fi

# LAS MEDIDAS SE LEEN DEL RESULTADO, NO SE CALCULAN: SON LAS QUE VA A USAR
# gbWeb PARA width Y height DEL <img>
MEDIDAS_TAPA=$(identify -format '%w %h' "$TEMPORAL" 2>/dev/null) || {
    rm -f "$TEMPORAL"
    morir "No se pudo leer la tapa convertida"
}
printf '%s\n' "$MEDIDAS_TAPA" > "$TEMPORAL_MEDIDAS" || {
    rm -f "$TEMPORAL" "$TEMPORAL_MEDIDAS"
    morir "No se pudieron escribir las medidas"
}

mv -f "$TEMPORAL" "$SALIDA" || morir "No se pudo escribir $SALIDA_REL"
mv -f "$TEMPORAL_MEDIDAS" "$MEDIDAS" || morir "No se pudo escribir $MEDIDAS_REL"

read -r ANCHO_WEB ALTO_WEB <<< "$MEDIDAS_TAPA"
ok "$SALIDA_REL: ${ANCHO_WEB}×${ALTO_WEB}, $(stat -c %s "$SALIDA") bytes"

terminar
