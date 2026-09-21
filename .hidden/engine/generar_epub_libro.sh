#!/bin/bash
# Generador de la salida EPUB 3 de libros — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   generar_epub_libro.sh <ruta_proyecto> <nombre_epub> <estilo_cita>
#
#   nombre_epub    nombre del archivo final, con extensión: lo arma Gambas
#                  desde el título abreviado del libro
#   estilo_cita    apa | iso690 | vancouver | ieee
#
# LA FRONTERA CON GAMBAS
#   Gambas escribe ANTES de lanzar este script todo lo que sale de la base,
#   dentro de tmp/epub-work/: las páginas de portada, créditos y colofón, el
#   nav.xhtml y el content.opf. Y deja en tmp/epub-capitulos.txt la lista de
#   piezas que el EPUB toma de su canónico, ya filtrada por la matriz
#   editorial (m_PiezasLibro), una por línea y en orden.
#
#   Este script hace todo lo demás: copia recursos, transforma cada capítulo,
#   escribe mimetype y container.xml, VERIFICA QUE CADA ARCHIVO QUE EL OPF
#   DECLARA EXISTA, empaqueta y valida. No toca la base.
#
# POR QUÉ SE VERIFICA EL OPF
#   El OPF se escribe antes de que existan los capítulos. Si declara uno que
#   no se generó, el EPUB sale roto y epubcheck lo dice recién al final. Así
#   se coló un índice de autores que nunca se generaba. Ahora, un archivo
#   declarado que falta impide empaquetar.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   recursos o insumos ausentes, un capítulo sin canónico o que no se
#            pudo transformar, un archivo declarado en el OPF que no existe,
#            un fallo al empaquetar. Un libro al que le falta un capítulo no
#            se genera.
#   avisa    errores de epubcheck, o epubcheck ausente. El EPUB se conserva y
#            el aviso llega a Gambas como código 3.
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_SAXON=120
TIEMPO_EPUBCHECK=300
LINEAS_EPUBCHECK=15

# NOMBRES FIJOS DEL PAQUETE. DEBEN COINCIDIR CON LOS QUE ESCRIBE GAMBAS EN EL
# OPF (m_GenerarEpubLibro): SI DIVERGEN, LA VERIFICACIÓN DEL OPF LO ATRAPA
FUENTES=(NotoSerif-Regular.ttf NotoSerif-Bold.ttf NotoSerif-Italic.ttf NotoSerif-BoldItalic.ttf)
CSS_EPUB="gbpublisher-epub-libro.css"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "GENERACIÓN DE LA SALIDA EPUB"

# --- 2. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_epub> <estilo_cita>"
fi

DIR_PROYECTO="${1%/}"
NOMBRE_EPUB="$2"
ESTILO_CITA="$3"

DIR_TRABAJO="$DIR_PROYECTO/tmp/epub-work"
DIR_OEBPS="$DIR_TRABAJO/OEBPS"
OPF="$DIR_OEBPS/content.opf"
LISTA="$DIR_PROYECTO/tmp/epub-capitulos.txt"
DIR_SALIDA="$DIR_PROYECTO/salidas/epub"
EPUB="$DIR_SALIDA/$NOMBRE_EPUB"
# EL TEMPORAL LLEVA EXTENSIÓN .tmp: zip AGREGA .zip A UN NOMBRE SIN EXTENSIÓN
TEMPORAL="$DIR_SALIDA/.$NOMBRE_EPUB.tmp"
XSL="$DIR_GBP_LOCAL/xslt/docbook-to-epub.xsl"
DIR_FUENTES="$DIR_GBP_LOCAL/fonts"
CSS="$DIR_GBP_LOCAL/assets/css/$CSS_EPUB"

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"

requerir_comandos java xmllint zip

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de salida EPUB: $XSL"
[[ -f "$CSS" ]]        || morir "No se encontró la hoja de estilos del EPUB: $CSS"

faltan=()
for fuente in "${FUENTES[@]}"; do
    [[ -f "$DIR_FUENTES/$fuente" ]] || faltan+=("$fuente")
done
if (( ${#faltan[@]} > 0 )); then
    morir "Faltan fuentes en $DIR_FUENTES: ${faltan[*]}"
fi

ok "herramientas, hoja de estilos y fuentes"
printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Citas:"    "$ESTILO_CITA"
printf '  %-14s %s\n'   "Salida:"   "$NOMBRE_EPUB"

# --- 4. INSUMOS QUE ESCRIBIÓ GAMBAS ---
paso "verificando lo que escribió la aplicación"

[[ -d "$DIR_OEBPS/chapters" ]] || morir "No existe el árbol de trabajo: $DIR_OEBPS"

for archivo in "$OPF" "$DIR_OEBPS/nav.xhtml" \
               "$DIR_OEBPS/chapters/front-portada.xhtml" \
               "$DIR_OEBPS/chapters/front-creditos.xhtml" \
               "$DIR_OEBPS/chapters/bm-99-colofon.xhtml"; do
    [[ -f "$archivo" ]]    || morir "No existe ${archivo#"$DIR_TRABAJO"/}"
    bien_formado "$archivo" || morir "Está mal formado: ${archivo#"$DIR_TRABAJO"/}"
done
ok "content.opf, nav y páginas de la base"

[[ -f "$LISTA" ]] || morir "No existe la lista de capítulos: $LISTA"
mapfile -t PIEZAS < <(grep -v '^[[:space:]]*$' "$LISTA")
(( ${#PIEZAS[@]} > 0 )) || morir "La lista de capítulos está vacía"
ok "${#PIEZAS[@]} capítulos a transformar"

# --- 5. RECURSOS ---
paso "copiando recursos"

cp -f "$CSS" "$DIR_OEBPS/css/" || morir "No se pudo copiar la hoja de estilos"
for fuente in "${FUENTES[@]}"; do
    cp -f "$DIR_FUENTES/$fuente" "$DIR_OEBPS/fonts/" || morir "No se pudo copiar $fuente"
done
ok "hoja de estilos y ${#FUENTES[@]} fuentes"

# LAS IMÁGENES SE COPIAN TODAS DESDE media/, SALTEANDO SUBDIRECTORIOS. EL GLOB
# NO INCLUYE ARCHIVOS OCULTOS, Y GAMBAS TAMPOCO LOS DECLARA EN EL OPF
imagenes=0
if [[ -d "$DIR_PROYECTO/media" ]]; then
    for archivo in "$DIR_PROYECTO/media"/*; do
        [[ -f "$archivo" ]] || continue
        cp -f "$archivo" "$DIR_OEBPS/images/" || morir "No se pudo copiar $(basename "$archivo")"
        imagenes=$((imagenes + 1))
    done
fi
if (( imagenes > 0 )); then
    ok "$imagenes imagen(es)"
else
    tenue "el proyecto no tiene imágenes en media/"
fi

# --- 6. CAPÍTULOS ---
# SE JUNTAN TODOS LOS PROBLEMAS ANTES DE ABORTAR, COMO EN EL ENSAMBLADO: EL
# EDITOR NECESITA VER TODO LO QUE HAY QUE REGENERAR
paso "transformando los capítulos"

problemas=0
for pieza in "${PIEZAS[@]}"; do
    canonico="$DIR_PROYECTO/jats/c-$pieza.xml"
    xhtml="$DIR_OEBPS/chapters/h-$pieza.xhtml"

    if [[ ! -f "$canonico" ]]; then
        printf '  %s✗%s falta el canónico de %s\n' "$C_ERROR" "$C_RESET" "$pieza"
        problemas=$((problemas + 1))
        continue
    fi
    if ! bien_formado "$canonico"; then
        printf '  %s✗%s canónico mal formado: %s\n' "$C_ERROR" "$C_RESET" "$pieza"
        problemas=$((problemas + 1))
        continue
    fi

    salida=$(timeout "$TIEMPO_SAXON" java -Djavax.xml.accessExternalDTD=all -jar "$RUTA_SAXON" \
                -s:"$canonico" \
                -xsl:"$XSL" \
                -o:"$xhtml" \
                estilo_cita="$ESTILO_CITA" 2>&1)
    codigo=$?

    if (( codigo != 0 )); then
        printf '  %s✗%s %s: Saxon falló (código %d)\n' "$C_ERROR" "$C_RESET" "$pieza" "$codigo"
        mostrar_cola "$salida" 8
        problemas=$((problemas + 1))
    elif ! bien_formado "$xhtml"; then
        printf '  %s✗%s %s: el XHTML salió mal formado\n' "$C_ERROR" "$C_RESET" "$pieza"
        problemas=$((problemas + 1))
    else
        ok "$pieza"
    fi
done

if (( problemas > 0 )); then
    morir "$problemas capítulo(s) con problemas: el EPUB no se genera"
fi

# --- 7. mimetype Y container.xml ---
# NO SALEN DE LA BASE: SON FIJOS DEL FORMATO. mimetype SIN SALTO FINAL
printf 'application/epub+zip' > "$DIR_TRABAJO/mimetype" ||
    morir "No se pudo escribir mimetype"

cat > "$DIR_TRABAJO/META-INF/container.xml" <<'CONTENEDOR' ||
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
<rootfiles>
<rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
</rootfiles>
</container>
CONTENEDOR
    morir "No se pudo escribir META-INF/container.xml"

# --- 8. VERIFICACIÓN DEL OPF ---
# CADA href DEL MANIFIESTO TIENE QUE EXISTIR. local-name() Y NO EL PREFIJO:
# xmllint --xpath NO CONOCE LOS NAMESPACES DEL DOCUMENTO (GV-22), Y EL OPF
# TIENE UN NAMESPACE POR OMISIÓN
paso "verificando el paquete contra content.opf"

mapfile -t DECLARADOS < <(
    xmllint --xpath "//*[local-name()='manifest']/*[local-name()='item']/@href" "$OPF" 2>/dev/null |
    grep -oP 'href="\K[^"]+'
)

(( ${#DECLARADOS[@]} > 0 )) || morir "content.opf no declara ningún archivo"

ausentes=0
for href in "${DECLARADOS[@]}"; do
    if [[ ! -f "$DIR_OEBPS/$href" ]]; then
        printf '  %s✗%s declarado y ausente: %s\n' "$C_ERROR" "$C_RESET" "$href"
        ausentes=$((ausentes + 1))
    fi
done

if (( ausentes > 0 )); then
    morir "content.opf declara $ausentes archivo(s) que no existen: el EPUB no se empaqueta"
fi

ok "${#DECLARADOS[@]} archivos declarados, todos presentes"

# --- 9. EMPAQUETADO ---
# mimetype PRIMERO Y SIN COMPRIMIR: LO EXIGE EL FORMATO. SE EMPAQUETA EN UN
# TEMPORAL Y SE RENOMBRA AL FINAL, COMO EL CANÓNICO: SI ALGO FALLA, EL EPUB
# ANTERIOR SIGUE INTACTO
paso "empaquetando"

mkdir -p "$DIR_SALIDA" || morir "No se pudo crear $DIR_SALIDA"
rm -f "$TEMPORAL"

if ! (cd "$DIR_TRABAJO" && zip -q -0 -X "$TEMPORAL" mimetype); then
    rm -f "$TEMPORAL"
    morir "No se pudo empaquetar mimetype"
fi

if ! (cd "$DIR_TRABAJO" && zip -q -9 -r -X "$TEMPORAL" META-INF OEBPS); then
    rm -f "$TEMPORAL"
    morir "No se pudo empaquetar el contenido"
fi

if ! zip -q -T "$TEMPORAL" >/dev/null 2>&1; then
    rm -f "$TEMPORAL"
    morir "El paquete no pasó la prueba de integridad de zip"
fi

mv -f "$TEMPORAL" "$EPUB" || morir "No se pudo escribir $EPUB"
ok "$NOMBRE_EPUB"

# --- 10. VALIDACIÓN CON epubcheck ---
paso "validando con epubcheck"

EPUBCHECK=()
if command -v epubcheck >/dev/null 2>&1; then
    EPUBCHECK=(epubcheck)
elif [[ -f /opt/epubcheck/epubcheck.jar ]]; then
    EPUBCHECK=(java -jar /opt/epubcheck/epubcheck.jar)
elif [[ -x "$HOME/.local/bin/epubcheck" ]]; then
    EPUBCHECK=("$HOME/.local/bin/epubcheck")
fi

if (( ${#EPUBCHECK[@]} == 0 )); then
    aviso "epubcheck no está instalado: el EPUB no se validó"
else
    salida=$(timeout "$TIEMPO_EPUBCHECK" "${EPUBCHECK[@]}" "$EPUB" 2>&1)
    codigo=$?
    errores=$(printf '%s\n' "$salida" | grep -cE '^(FATAL|ERROR)')
    advertencias=$(printf '%s\n' "$salida" | grep -cE '^WARNING')

    if (( codigo == 124 )); then
        aviso "epubcheck no terminó en $TIEMPO_EPUBCHECK segundos"
    elif (( codigo == 0 && errores == 0 )); then
        ok "sin errores"
    else
        aviso "epubcheck informó $errores error(es):"
    fi

    # LAS ADVERTENCIAS SE MUESTRAN PERO NO CAMBIAN EL CÓDIGO: SON LO QUE EL
    # EDITOR DECIDE SI ATENDER, NO UN EPUB INVÁLIDO
    if (( errores + advertencias > 0 )); then
        printf '%s\n' "$salida" | grep -E '^(FATAL|ERROR|WARNING)' |
            sed "s|$EPUB|$NOMBRE_EPUB|" |
            head -"$LINEAS_EPUBCHECK" | sed 's/^/     /'
        total=$((errores + advertencias))
        if (( total > LINEAS_EPUBCHECK )); then
            tenue "(+$((total - LINEAS_EPUBCHECK)) más)"
        fi
    fi
fi

# --- 11. RESUMEN ---
echo
titulo "$REGLA"
printf '%s✓ EPUB generado%s\n' "$C_OK" "$C_RESET"
printf '  %-14s %s\n'    "Archivo:"   "$EPUB"
printf '  %-14s %s KB\n' "Tamaño:"    "$(( $(stat -c%s "$EPUB") / 1024 ))"
printf '  %-14s %s\n'    "Capítulos:" "${#PIEZAS[@]}"
if (( AVISOS > 0 )); then
    printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
fi
echo

terminar
