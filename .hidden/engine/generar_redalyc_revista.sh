#!/bin/bash
# Paquetes de Marcalyc (Redalyc) del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa F4 de los sabores (claude/salidas-revistas.md), decisiones de
# Alberto del 18/11/2026:
#   - REDALYC NO RECIBE XML: Marcalyc recibe, por artículo, un ZIP con un
#     solo index.html en UTF-8 y sus imágenes, lo marca y genera él el JATS
#     (manual de usuario de Marcalyc 4.0, abril de 2024). No hay fuente de
#     que acepte un JATS externo;
#   - el index.html lleva solo el cuerpo: los metadatos se cargan en los
#     formularios de Marcalyc;
#   - LOS LÍMITES DE MARCALYC: el ZIP hasta 4 MB; cada imagen JPG, PNG, GIF
#     o SVG, hasta 1 MB, y se recomienda no pasar de 750 px; el PDF de la
#     revista, aparte, hasta 4 MB;
#   - LA PINZA DE REDALYC: el PDF de cada artículo, que va al lado del ZIP;
#   - como todos los sabores, exige las páginas de cada artículo.
#
# USO
#   generar_redalyc_revista.sh <ruta_proyecto> <nombre_bib>
#
# LA FRONTERA CON GAMBAS (SC-13): Gambas escribe antes el volcado del número
# (tmp/numero-datos.xml, versión 4) y el .bib. Este script no toca la base.
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado, la pinza (el PDF de cada artículo) y las páginas.
#   2. Regenera los canónicos y hace la pasada de citas, como el EPUB: las
#      citas y las referencias son las mismas que el PDF (SC-57).
#   3. Rehace salidas/redalyc/: por artículo, {archivo}.zip (index.html y
#      sus imágenes, en la raíz) y {archivo}.pdf (la copia del PDF).
#   4. Cada index.html sale de jats-a-marcalyc.xsl. Cada imagen, de
#      copiar_imagen_pantalla con el tope de Marcalyc (750 px) y en sRGB.
#   5. Verifica los límites: imagen hasta 1 MB, ZIP hasta 4 MB, PDF hasta
#      4 MB. Lo que los pasa se avisa: Marcalyc lo rechazaría.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   insumos ausentes, la pinza, un artículo sin páginas, un
#            canónico que no se generó, la pasada de citas, una
#            transformación o una imagen que falta en media/
#   avisa    canónicos o citas con avisos, un límite de Marcalyc superado
#
# CÓDIGOS DE SALIDA (comun.sh): 0 generado; 3 con avisos; 1 no
# ============================================================================

set -uo pipefail

# --- 1. FUNCIONES COMPARTIDAS ---
DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
if ! source "$DIR_ENGINE/revista_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/revista_comun.sh" >&2
    exit 1
fi

# --- 2. CONFIGURACIÓN ---
TIEMPO_SAXON=120
VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="4"
# LA PASADA DE CITAS: LA MISMA CARPETA QUE EL EPUB Y EL HTML
DIR_CITAS_REL="tmp/bib/epub-revista"
LISTA_REL="tmp/lote-redalyc-revista.txt"

# LOS LÍMITES DE MARCALYC (marcalyc_limites, revista_comun.sh): EL TOPE DE
# LA IMAGEN REEMPLAZA AL DE PANTALLA (comun.sh) SOLO EN ESTE SCRIPT
TOPE_PANTALLA_PX="$MARCALYC_TOPE_PX"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "REDALYC (MARCALYC) DEL NÚMERO"

# --- 3. ARGUMENTOS ---
if (( $# < 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib>"
fi
DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
DIR_SALIDA="$DIR_PROYECTO/salidas/redalyc"
DIR_TRABAJO="$DIR_PROYECTO/tmp/redalyc-work"
# LOS CANÓNICOS SIN DOCTYPE: SAXON NO BAJA LA DTD REMOTA (GV-25)
DIR_CANONICOS="$DIR_PROYECTO/tmp/redalyc-canonicos"
XSL="$DIR_RECURSOS/xslt/jats-a-marcalyc.xsl"

# --- 4. ENTORNO ---
paso "verificando el entorno"
[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
[[ "$NOMBRE_BIB" == */* ]] && morir "Nombre de .bib no válido: $NOMBRE_BIB"
requerir_comandos java xmllint zip identify convert sha256sum iconv stat
[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "Falta la hoja $XSL: reinstalá gbpublisher"
ok "herramientas y hoja"

# --- 5. EL VOLCADO ---
[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"
MODELO="$(dato_volcado 'string(/numero-datos/revista/@modelo-paginacion)')"
ESTILO="$(dato_volcado 'string(/numero-datos/revista/estilo-cita)')"
[[ -n "$MODELO" ]] || morir "La revista no tiene modelo de paginación: elegilo en la ficha de la revista"
[[ -n "$ESTILO" ]] || morir "La revista no tiene estilo de cita: elegilo en la ficha de la revista"
ok "volcado versión $version; paginación $MODELO; citas $ESTILO"

base="$(nombre_numero)"
[[ -n "$base" ]] ||
    morir "Para ubicar el PDF del número hacen falta el acrónimo de la revista (en Revistas) y el año del número (en sus metadatos)"

mapfile -t ARTICULOS < <(dato_volcado '/numero-datos/articulo/@archivo' | grep -oP 'archivo="\K[^"]+')
(( ${#ARTICULOS[@]} > 0 )) || morir "El número no tiene artículos con metadatos"
for a in "${ARTICULOS[@]}"; do
    # EL NOMBRE VA A UN XPATH Y A RUTAS
    [[ "$a" =~ ^a-[A-Za-z0-9._-]+$ ]] || morir "Nombre de artículo no válido en el volcado: «$a»"
done

# --- 6. LA PINZA Y LAS PÁGINAS ---
paso "verificando el número"
# EL PDF DE CADA ARTÍCULO VA AL LADO DEL ZIP: SIN ÉL NO HAY PAQUETE. EL
# DEL NÚMERO TAMBIÉN SE EXIGE: ES LA BASE DE LA PINZA (SC-93)
mapfile -t faltan_salidas < <(salidas_que_faltan pdf "$DIR_PROYECTO" "$base" "${ARTICULOS[@]}")
if (( ${#faltan_salidas[@]} > 0 )); then
    printf '%s\n' "${faltan_salidas[@]}" | sed 's/^/     /'
    morir "Faltan ${#faltan_salidas[@]} PDF del número: componé primero el PDF del número"
fi
ok "los PDF del número y de sus ${#ARTICULOS[@]} artículo(s)"

mapfile -t sin_paginas < <(articulos_sin_paginas "$MODELO" "${ARTICULOS[@]}")
if (( ${#sin_paginas[@]} > 0 )); then
    printf '%s\n' "${sin_paginas[@]}" | sed 's/^/     /'
    morir "${#sin_paginas[@]} artículo(s) sin páginas (o sin e-id) en la base: componé primero el PDF del número"
fi
ok "${#ARTICULOS[@]} artículo(s)"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "salidas/redalyc/"

# --- 7. CANÓNICOS Y CITAS ---
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: los paquetes de Marcalyc no se generan" ;;
esac

paso "preparando las citas con biblatex"
salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/preparar_citas_revista.sh" \
            "$DIR_PROYECTO" "$NOMBRE_BIB" "$DIR_CITAS_REL" 2>&1)
codigo=$?
if (( codigo == SALIDA_AVISOS )); then
    mostrar_cola "$(grep '⚠' <<< "$salida")"
    aviso "la pasada de citas tiene avisos: los paquetes se generan igual"
elif (( codigo != SALIDA_OK )); then
    mostrar_cola "$salida"
    morir "No se pudieron preparar las citas: los paquetes de Marcalyc no se generan"
fi
ok "$(printf '%s\n' "$salida" | tail -n 1) cita(s) de biblatex"

# --- 8. salidas/redalyc/, DE NUEVO ---
# UN ARTÍCULO QUE SALIÓ DEL NÚMERO NO PUEDE QUEDAR CON SU PAQUETE
paso "preparando salidas/redalyc/"
rm -rf -- "${DIR_TRABAJO:?}" "${DIR_CANONICOS:?}"
mkdir -p "$DIR_SALIDA" "$DIR_TRABAJO" "$DIR_CANONICOS" || morir "No se pudieron crear las carpetas de trabajo"
rm -f "$DIR_SALIDA"/a-*.zip "$DIR_SALIDA"/a-*.pdf

# --- 9. UN PAQUETE POR ARTÍCULO ---
# SE JUNTAN TODOS LOS PROBLEMAS ANTES DE ABORTAR
problemas=0
for a in "${ARTICULOS[@]}"; do
    paso "$a"
    dir="$DIR_TRABAJO/$a"
    mkdir -p "$dir" || morir "No se pudo crear $dir"
    canonico="$DIR_CANONICOS/c-$a.xml"
    xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$a.xml" > "$canonico" 2>/dev/null ||
        morir "$a: el canónico jats/c-$a.xml no se pudo leer"

    # A. EL index.html
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$canonico" -xsl:"$XSL" -o:"$dir/index.html" \
                archivo="$a" \
                bib_dir="$DIR_PROYECTO/$DIR_CITAS_REL" \
                estilo_cita="$ESTILO" 2>&1)
    if (( $? != 0 )) || [[ ! -s "$dir/index.html" ]]; then
        fallo "Saxon no pudo escribir el index.html"
        mostrar_cola "$salida" 8
        problemas=$((problemas + 1))
        continue
    fi
    # MARCALYC PIDE UTF-8: SE COMPRUEBA, NO SE SUPONE
    if ! iconv -f UTF-8 -t UTF-8 "$dir/index.html" > /dev/null 2>&1; then
        fallo "el index.html no es UTF-8 válido"
        problemas=$((problemas + 1))
        continue
    fi

    # B. LAS IMÁGENES QUE USA, AL TOPE DE MARCALYC Y EN sRGB
    imagenes=0
    while IFS= read -r nombre; do
        [[ -n "$nombre" ]] || continue
        origen="$DIR_PROYECTO/media/$nombre"
        if [[ ! -f "$origen" ]]; then
            fallo "usa una imagen que no está en media/: $nombre"
            problemas=$((problemas + 1))
            continue
        fi
        if ! copiar_imagen_pantalla "$origen" "$dir/$nombre" "$DIR_PROYECTO/tmp/pantalla"; then
            fallo "no se pudo preparar la imagen $nombre${PANTALLA_NOTA:+: $PANTALLA_NOTA}"
            problemas=$((problemas + 1))
            continue
        fi
        [[ -n "$PANTALLA_NOTA" ]] && tenue "$nombre: $PANTALLA_NOTA"
        if ! marcalyc_formato_imagen "$nombre"; then
            aviso "$nombre: Marcalyc solo acepta JPG, PNG, GIF o SVG"
        fi
        peso=$(stat -c %s "$dir/$nombre")
        if (( peso > MARCALYC_MAX_IMAGEN )); then
            aviso "$nombre pesa $(( peso / 1024 )) KB: Marcalyc acepta hasta $(( MARCALYC_MAX_IMAGEN / 1024 )) KB por imagen"
        fi
        imagenes=$((imagenes + 1))
    done < <(imagenes_canonico_jats "$canonico")

    # C. EL ZIP: index.html Y LAS IMÁGENES EN LA RAÍZ. SIN EXTRAS (-X)
    zip_final="$DIR_SALIDA/$a.zip"
    temporal="$DIR_SALIDA/.$a.zip.tmp"
    rm -f "$temporal"
    if ! (cd "$dir" && zip -q -9 -X -r "$temporal" .); then
        rm -f "$temporal"
        fallo "no se pudo armar el ZIP"
        problemas=$((problemas + 1))
        continue
    fi
    mv -f "$temporal" "$zip_final" || morir "No se pudo escribir $zip_final"
    peso=$(stat -c %s "$zip_final")
    ok "$a.zip: index.html y $imagenes imagen(es), $(( peso / 1024 )) KB"
    if (( peso > MARCALYC_MAX_ZIP )); then
        aviso "$a.zip pesa $(( peso / 1024 )) KB: Marcalyc acepta hasta $(( MARCALYC_MAX_ZIP / 1024 )) KB"
    fi

    # D. EL PDF DEL ARTÍCULO, AL LADO
    cp -f "$DIR_PROYECTO/salidas/pdf/$a.pdf" "$DIR_SALIDA/$a.pdf" || morir "No se pudo copiar salidas/pdf/$a.pdf"
    peso=$(stat -c %s "$DIR_SALIDA/$a.pdf")
    if (( peso > MARCALYC_MAX_PDF )); then
        aviso "$a.pdf pesa $(( peso / 1024 )) KB: Marcalyc acepta hasta $(( MARCALYC_MAX_PDF / 1024 )) KB"
    else
        ok "$a.pdf, $(( peso / 1024 )) KB"
    fi
done

if (( problemas > 0 )); then
    morir "$problemas problema(s) en los artículos: revisar arriba"
fi

rm -rf -- "${DIR_TRABAJO:?}" "${DIR_CANONICOS:?}"
terminar
