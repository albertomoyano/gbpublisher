#!/bin/bash
# Conversión de una bibliografía original a HTML con LibreOffice — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   convertir_bibliografia.sh <original> <salida.html>
#
#   original     el .rtf (o .docx, .doc, .odt) de originales/ del proyecto
#   salida.html  dónde dejar el HTML tal como lo da LibreOffice, sin tocar
#
# QUÉ HACE
#   Solo la conversión. El HTML crudo lo normaliza Gambas
#   (m_EditorHTML.NormalizarHtml) al subconjunto del TextEdit y escribe el
#   .html de trabajo: esa lógica conoce el control y es la que cuida los
#   semáforos (fondo amarillo, letras rojas), así que queda donde está.
#
#   Reemplaza al lanzamiento de soffice desde Gambas
#   (m_EditorHTML.ConvertirConLibreOffice), que necesitaba el aparato
#   asíncrono completo: Exec For Read, tres manejadores, bucle de espera con
#   vencimiento y drenaje (GV-17, GV-18, GV-19). Ahora lo lanza la
#   lanzadora (SC-53) y Gambas recibe el código de salida (SC-13, criterio 1).
#
# POR QUÉ LIBREOFFICE Y NO PANDOC
#   El modelo de pandoc no representa color de texto ni de fondo: los
#   semáforos se perderían. LibreOffice los conserva, y desde .docx también
#   los enlaces DOI (ver el encabezado de m_EditorHTML).
#
# EL PERFIL APARTE
#   Cada conversión usa un perfil de LibreOffice nuevo, que se borra al
#   salir. Sin él, soffice se conecta a una ventana de LibreOffice abierta
#   y no convierte nada.
#
# CÓDIGOS: los de comun.sh
#   0  la salida está escrita
#   1  no se pudo: falta soffice, falta el original o LibreOffice no
#      generó nada
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
# EL FILTRO DE EXPORTACIÓN DE WRITER: EL QUE CONSERVA LOS COLORES
FILTRO_HTML="html:HTML (StarWriter)"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "IMPORTACIÓN DE LA BIBLIOGRAFÍA"

# --- 2. ARGUMENTOS ---
if (( $# != 2 )); then
    morir "Uso: $(basename "$0") <original> <salida.html>"
fi

ORIGINAL="$1"
SALIDA="$2"

[[ -f "$ORIGINAL" ]] || morir "No existe el original: $ORIGINAL"
[[ -d "$(dirname "$SALIDA")" ]] || morir "No existe la carpeta de la salida: $(dirname "$SALIDA")"

# LIBREOFFICE NO ESTÁ ENTRE LO QUE CONTROLA integridad.sh: EL AVISO DICE
# CÓMO REPONERLO, NO COMO_REPARAR
if ! command -v soffice >/dev/null 2>&1; then
    morir "No se encontró LibreOffice, que es lo que convierte el original. Viene instalado en Linux Mint; si se quitó, se repone con: sudo apt install libreoffice-writer"
fi

tenue "Original: $(basename "$ORIGINAL")"

# UNA SALIDA VIEJA NO PUEDE PASAR POR EL RESULTADO DE ESTA CONVERSIÓN
rm -f "$SALIDA"

# --- 3. CARPETAS DE TRABAJO ---
# EL PERFIL Y LA SALIDA DE soffice, QUE PUEDE DEJAR TAMBIÉN LAS IMÁGENES DEL
# ORIGINAL: TODO SE BORRA AL SALIR
TMP="$(mktemp -d)" || morir "No se pudo crear la carpeta temporal"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/perfil" "$TMP/salida" || morir "No se pudo preparar la carpeta temporal"

# --- 4. CONVERSIÓN ---
paso "Conversión con LibreOffice"
# LA RUTA Y EL PERFIL VAN COMO ARGUMENTOS, SIN sh -c. LA PRIMERA VEZ CON UN
# PERFIL NUEVO LIBREOFFICE TARDA UNOS SEGUNDOS MÁS: LO ESTÁ CREANDO
# LA SALIDA DE ERROR VA A UN ARCHIVO: LIBREOFFICE ESCRIBE AHÍ RUIDO DE
# libxslt («xsltParseStylesheetFile : cannot parse», «failed to load
# external entity ""») AUN CUANDO CONVIERTE BIEN. SE MUESTRA SOLO SI FALLA
soffice --headless --norestore \
    "-env:UserInstallation=file://$TMP/perfil" \
    --convert-to "$FILTRO_HTML" \
    --outdir "$TMP/salida" \
    "$ORIGINAL" 2>"$TMP/soffice.err"
CODIGO=$?

# --- 5. CONTROL DE LA SALIDA ---
# soffice PUEDE TERMINAR CON 0 SIN HABER CONVERTIDO NADA: MANDA EL ARCHIVO
NOMBRE="$(basename "$ORIGINAL")"
CONVERTIDO="$TMP/salida/${NOMBRE%.*}.html"

if [[ ! -s "$CONVERTIDO" ]]; then
    # SIN SALIDA, LO QUE DIJO LIBREOFFICE POR STDERR SÍ SIRVE PARA ENTENDER POR QUÉ
    if [[ -s "$TMP/soffice.err" ]]; then
        while IFS= read -r LINEA; do
            tenue "$LINEA"
        done < <(tail -n 8 "$TMP/soffice.err")
    fi
    morir "LibreOffice no generó el HTML (código $CODIGO). Si el original se abre bien en Writer, probá guardarlo de nuevo como .rtf."
fi

mv -f "$CONVERTIDO" "$SALIDA" || morir "No se pudo escribir la salida: $SALIDA"
ok "Convertido: $(du -h "$SALIDA" | cut -f1)"

terminar
