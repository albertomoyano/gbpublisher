#!/bin/bash
# HTML autónomo del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa H2 de las salidas de revistas (claude/salidas-revistas.md),
# decisiones de Alberto del 14/11/2026:
#   - un sitio por número en docs/ del proyecto: index.html es el sumario,
#     con la tapa y las descargas, y hay una página por artículo
#     (h-{archivo}.html), la que se enlaza desde OJS;
#   - el diseño del libro autónomo: gbpublisher.css y gbpublisher.js en
#     docs/assets/;
#   - las descargas, copiadas al sitio (docs/descargas/);
#   - LA PINZA: la revista es de acceso abierto y las salidas se validan
#     cruzadas. El HTML ofrece el PDF de cada artículo y el PDF y el EPUB
#     del número: si falta alguno en salidas/, no se genera.
#   - el integrado al portal espera el portal R- de gbWeb.
#
# USO
#   generar_html_revista.sh <ruta_proyecto> <nombre_bib>
#
# LA FRONTERA CON GAMBAS (SC-13): Gambas escribe antes el volcado del número
# (tmp/numero-datos.xml, versión 4) y el .bib. Este script no toca la base.
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado, la pinza (los PDF y el EPUB en salidas/) y las
#      páginas de cada artículo.
#   2. Regenera los canónicos y hace la pasada de citas, como el EPUB.
#   3. Colorea el código de cada artículo (SC-42).
#   4. Rehace docs/: borra las páginas, las imágenes y las descargas de la
#      corrida anterior (un artículo que salió del número no queda
#      publicado), copia la hoja de estilos y el script, las imágenes que
#      usan los artículos y la tapa (copiar_imagen_pantalla, SC-76, con el
#      .html de cada gráfico, SC-69) y las descargas.
#   5. jats-a-html-articulo.xsl escribe cada artículo; numero-a-html.xsl,
#      index.html.
#   6. Valida con vnu (HTML5). Sus errores no impiden la salida: llegan a
#      Gambas como código 3, como en libros. Sin vnu no se genera: se
#      controla al verificar el entorno.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   insumos ausentes (vnu incluido), la pinza, un artículo sin páginas, un
#            canónico que no se generó, la pasada de citas o el coloreo
#            fallidos, una página que no se pudo transformar, una imagen
#            que falta en media/
#   avisa    canónicos o citas con avisos, errores de vnu
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
# LA LECTURA DEL VOLCADO, EL NOMBRE DEL NÚMERO, LAS PÁGINAS Y LA PINZA
if ! source "$DIR_ENGINE/revista_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/revista_comun.sh" >&2
    exit 1
fi

# --- 2. CONFIGURACIÓN ---
TIEMPO_SAXON=120
# RUTA_VNU VIVE EN comun.sh, COMO LAS DEMÁS HERRAMIENTAS CONGELADAS
TIEMPO_VNU=300
LINEAS_ERROR_VNU=15

VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="4"
# LA PASADA DE CITAS: LA MISMA CARPETA QUE EL EPUB (LOS MISMOS INSUMOS)
DIR_CITAS_REL="tmp/bib/epub-revista"
LISTA_REL="tmp/lote-html-revista.txt"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "HTML DEL NÚMERO"

# --- 3. ARGUMENTOS ---
if (( $# < 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib>"
fi
DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
DIR_DOCS="$DIR_PROYECTO/docs"
DIR_ASSETS="$DIR_DOCS/assets"
DIR_DESCARGAS="$DIR_DOCS/descargas"
INDEX="$DIR_DOCS/index.html"
# LOS CANÓNICOS SIN DOCTYPE: SAXON NO BAJA LA DTD REMOTA (GV-25)
DIR_CANONICOS="$DIR_PROYECTO/tmp/html-canonicos"
DIR_CODIGO="$DIR_PROYECTO/tmp/codigo/html-revista"
XSL_NUMERO="$DIR_GBP_LOCAL/xslt/numero-a-html.xsl"
XSL_ARTICULO="$DIR_GBP_LOCAL/xslt/jats-a-html-articulo.xsl"
CSS="$DIR_GBP_LOCAL/assets/css/gbpublisher.css"
JS="$DIR_GBP_LOCAL/assets/js/gbpublisher.js"

# --- 4. ENTORNO ---
paso "verificando el entorno"
[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
[[ "$NOMBRE_BIB" == */* ]] && morir "Nombre de .bib no válido: $NOMBRE_BIB"
requerir_comandos java xmllint identify convert sha256sum iconv
# SIN vnu EL HTML NO SE GENERA: SE SABE ACÁ Y NO AL FINAL (SC-95)
requerir_vnu
[[ -f "$RUTA_SAXON" ]]   || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL_NUMERO" ]]   || morir "Falta la hoja $XSL_NUMERO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -f "$XSL_ARTICULO" ]] || morir "Falta la hoja $XSL_ARTICULO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -f "$CSS" ]]          || morir "No se encontró la hoja de estilos: $CSS"
[[ -f "$JS" ]]           || morir "No se encontró el script: $JS"
ok "herramientas (con vnu), hojas, hoja de estilos y script"

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
    morir "Para nombrar las descargas del número hacen falta el acrónimo de la revista (en Revistas) y el año del número (en sus metadatos)"

mapfile -t ARTICULOS < <(dato_volcado '/numero-datos/articulo/@archivo' | grep -oP 'archivo="\K[^"]+')
(( ${#ARTICULOS[@]} > 0 )) || morir "El número no tiene artículos con metadatos"
for a in "${ARTICULOS[@]}"; do
    # EL NOMBRE VA A UN XPATH Y A RUTAS
    [[ "$a" =~ ^a-[A-Za-z0-9._-]+$ ]] || morir "Nombre de artículo no válido en el volcado: «$a»"
done

# LA TAPA: LA IMAGEN DEL NÚMERO, SI TIENE. EN EL HTML NO DEPENDE DE QUE EL
# NÚMERO DECLARE LA TAPA COMO PRELIMINAR: ES LA IMAGEN DE LA COLUMNA, COMO
# EN EL LIBRO
TAPA="$(dato_volcado 'normalize-space(/numero-datos/numero/imagen-tapa)')"
if [[ -n "$TAPA" ]]; then
    [[ "$TAPA" != */* ]] || morir "Nombre de tapa no válido: $TAPA"
    [[ -f "$DIR_PROYECTO/media/$TAPA" ]] || morir "La tapa del número (media/$TAPA) no está en el proyecto"
fi

# --- 6. LA PINZA Y LAS PÁGINAS ---
paso "verificando el número"
mapfile -t faltan_salidas < <(salidas_que_faltan pdf+epub "$DIR_PROYECTO" "$base" "${ARTICULOS[@]}")
if (( ${#faltan_salidas[@]} > 0 )); then
    printf '%s\n' "${faltan_salidas[@]}" | sed 's/^/     /'
    morir "Faltan ${#faltan_salidas[@]} salida(s) del número: componé el PDF del número y generá el EPUB antes del HTML"
fi
ok "los PDF y el EPUB del número"

mapfile -t sin_paginas < <(articulos_sin_paginas "$MODELO" "${ARTICULOS[@]}")
if (( ${#sin_paginas[@]} > 0 )); then
    printf '%s\n' "${sin_paginas[@]}" | sed 's/^/     /'
    morir "${#sin_paginas[@]} artículo(s) sin páginas (o sin e-id) en la base: componé primero el PDF del número"
fi
ok "${#ARTICULOS[@]} artículo(s)"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "docs/"

# --- 7. CANÓNICOS Y CITAS ---
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: el HTML no se genera" ;;
esac

paso "preparando las citas con biblatex"
salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/preparar_citas_revista.sh" \
            "$DIR_PROYECTO" "$NOMBRE_BIB" "$DIR_CITAS_REL" 2>&1)
codigo=$?
if (( codigo == SALIDA_AVISOS )); then
    mostrar_cola "$(grep '⚠' <<< "$salida")"
    aviso "la pasada de citas tiene avisos: el HTML se genera igual"
elif (( codigo != SALIDA_OK )); then
    mostrar_cola "$salida"
    morir "No se pudieron preparar las citas: el HTML no se genera"
fi
ok "$(printf '%s\n' "$salida" | tail -n 1) cita(s) de biblatex"

# --- 8. CANÓNICOS SIN DTD Y CÓDIGO (SC-42) ---
# EL COLOREO CORRE SOBRE EL MISMO ARCHIVO QUE DESPUÉS TRANSFORMA LA HOJA, UNA
# CARPETA POR ARTÍCULO: LOS BLOQUES SE NUMERAN POR CANÓNICO
paso "coloreando el código"
rm -rf -- "${DIR_CANONICOS:?}" "${DIR_CODIGO:?}"
mkdir -p "$DIR_CANONICOS" "$DIR_CODIGO" || morir "No se pudieron crear las carpetas de trabajo en tmp/"
bloques=0
for a in "${ARTICULOS[@]}"; do
    xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$a.xml" > "$DIR_CANONICOS/c-$a.xml" 2>/dev/null ||
        morir "$a: el canónico jats/c-$a.xml no se pudo leer"
    salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/colorear_codigo.sh" "$DIR_CANONICOS/c-$a.xml" "$DIR_CODIGO/$a" html 2>&1)
    if (( $? != 0 )); then
        mostrar_cola "$salida"
        morir "$a: no se pudo colorear el código: el HTML no se genera"
    fi
    bloques=$((bloques + $(printf '%s\n' "$salida" | tail -n 1 | grep -oE '^[0-9]+$' || echo 0)))
done
ok "$bloques bloque(s) de código"

# --- 9. docs/ ---
# LO QUE ESCRIBE ESTE SCRIPT SE REHACE ENTERO: LAS PÁGINAS, LAS IMÁGENES Y
# LAS DESCARGAS. LO DEMÁS DE docs/ (UN CNAME, UN .nojekyll) NO SE TOCA
paso "preparando docs/"
mkdir -p "$DIR_DOCS" || morir "No se pudo crear $DIR_DOCS"
rm -f "$INDEX" "$DIR_DOCS"/h-a-*.html
rm -rf -- "${DIR_ASSETS:?}/media" "${DIR_DESCARGAS:?}"
mkdir -p "$DIR_ASSETS/css" "$DIR_ASSETS/js" "$DIR_ASSETS/media" "$DIR_DESCARGAS" ||
    morir "No se pudo crear la estructura de docs/"
cp -f "$CSS" "$DIR_ASSETS/css/" || morir "No se pudo copiar la hoja de estilos"
cp -f "$JS"  "$DIR_ASSETS/js/"  || morir "No se pudo copiar el script"
ok "hoja de estilos y script"

# LAS IMÁGENES: LAS QUE NOMBRAN LOS CANÓNICOS Y LA TAPA, SIN REPETIR (SC-76)
mapfile -t USADAS < <(
    {
        for a in "${ARTICULOS[@]}"; do imagenes_canonico_jats "$DIR_CANONICOS/c-$a.xml"; done
        if [[ -n "$TAPA" ]]; then printf '%s\n' "$TAPA"; fi
    } | sort -u
)
imagenes=0
reducidas=0
for nombre in "${USADAS[@]}"; do
    [[ -n "$nombre" ]] || continue
    origen="$DIR_PROYECTO/media/$nombre"
    [[ -f "$origen" ]] || morir "El número usa una imagen que no está en media/: $nombre"
    copiar_imagen_pantalla "$origen" "$DIR_ASSETS/media/$nombre" "$DIR_PROYECTO/tmp/pantalla" ||
        morir "No se pudo preparar la imagen $nombre${PANTALLA_NOTA:+: $PANTALLA_NOTA}"
    imagenes=$((imagenes + 1))
    [[ -z "$PANTALLA_NOTA" ]] || tenue "$nombre: $PANTALLA_NOTA"
    reducidas=$((reducidas + PANTALLA_PREPARADA))
    # EL GRÁFICO INTERACTIVO (SC-69): EL PATRÓN DE gbg:patron-png, COMO EN
    # generar_html_libro.sh
    if [[ "$nombre" =~ ^fig-[A-Za-z0-9-]+\.png$ && -f "$DIR_PROYECTO/media/${nombre%.png}.html" ]]; then
        cp -f "$DIR_PROYECTO/media/${nombre%.png}.html" "$DIR_ASSETS/media/" ||
            morir "No se pudo copiar ${nombre%.png}.html"
        tenue "$nombre: gráfico interactivo, con su HTML"
    fi
done
if (( imagenes > 0 && reducidas > 0 )); then
    ok "$imagenes imagen(es), $reducidas preparada(s) para pantalla"
elif (( imagenes > 0 )); then
    ok "$imagenes imagen(es)"
else
    tenue "el número no usa imágenes"
fi

# LAS DESCARGAS: LAS QUE LA PINZA VERIFICÓ
for a in "${ARTICULOS[@]}"; do
    cp -f "$DIR_PROYECTO/salidas/pdf/$a.pdf" "$DIR_DESCARGAS/" || morir "No se pudo copiar el PDF de $a"
done
cp -f "$DIR_PROYECTO/salidas/pdf/$base.pdf" "$DIR_DESCARGAS/" || morir "No se pudo copiar el PDF del número"
cp -f "$DIR_PROYECTO/salidas/epub/$base.epub" "$DIR_DESCARGAS/" || morir "No se pudo copiar el EPUB del número"
ok "descargas: ${#ARTICULOS[@]} PDF de artículo, el PDF y el EPUB del número"

# --- 10. LAS PÁGINAS ---
# SE JUNTAN TODOS LOS PROBLEMAS ANTES DE ABORTAR
paso "transformando a HTML"
problemas=0
PARAM_TAPA=()
[[ -n "$TAPA" ]] && PARAM_TAPA=(tapa="$TAPA")
for a in "${ARTICULOS[@]}"; do
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$DIR_CANONICOS/c-$a.xml" -xsl:"$XSL_ARTICULO" -o:"$DIR_DOCS/h-$a.html" \
                archivo="$a" \
                bib_dir="$DIR_PROYECTO/$DIR_CITAS_REL" \
                volcado="$VOLCADO" \
                estilo_cita="$ESTILO" \
                pdf="descargas/$a.pdf" \
                dir_media="$DIR_PROYECTO/media" \
                codigo_dir="$DIR_CODIGO/$a" \
                "${PARAM_TAPA[@]}" 2>&1)
    codigo=$?
    if (( codigo != 0 )) || [[ ! -s "$DIR_DOCS/h-$a.html" ]]; then
        fallo "$a: Saxon falló (código $codigo)"
        mostrar_cola "$salida" 8
        problemas=$((problemas + 1))
    else
        ok "h-$a.html"
    fi
done

salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$VOLCADO" -xsl:"$XSL_NUMERO" -o:"$INDEX" \
            pdf_numero="descargas/$base.pdf" \
            epub="descargas/$base.epub" \
            "${PARAM_TAPA[@]}" 2>&1)
codigo=$?
if (( codigo != 0 )) || [[ ! -s "$INDEX" ]]; then
    fallo "index.html: Saxon falló (código $codigo)"
    mostrar_cola "$salida" 8
    problemas=$((problemas + 1))
else
    ok "index.html"
fi
if (( problemas > 0 )); then
    morir "$problemas página(s) con problemas: el HTML no está completo"
fi

# --- 11. VALIDACIÓN HTML5 (Nu Html Checker) ---
# vnu Y NO xmllint, COMO EN LIBROS: xmllint ES UN PARSER HTML 4.01. SIN
# --exit-zero-always, vnu DEVUELVE DISTINTO DE CERO SI ENCUENTRA ERRORES
# SU PRESENCIA YA SE CONTROLÓ EN EL APARTADO 4 (requerir_vnu)
paso "validando el HTML"
mapfile -t PAGINAS_VNU < <(find "$DIR_DOCS" -type f -name '*.html' | LC_ALL=C sort)
salida=$(timeout "$TIEMPO_VNU" java -jar "$RUTA_VNU" \
            --format gnu --errors-only --skip-non-html "${PAGINAS_VNU[@]}" 2>&1)
codigo=$?
if (( codigo == 0 )); then
    ok "HTML5 sin errores"
elif (( codigo == 124 )); then
    aviso "la validación HTML5 no terminó en $TIEMPO_VNU segundos"
else
    errores=$(printf '%s\n' "$salida" | grep -c .)
    aviso "$errores error(es) de HTML5:"
    printf '%s\n' "$salida" | sed "s|$DIR_DOCS/||" |
        head -"$LINEAS_ERROR_VNU" | sed 's/^/     /'
    if (( errores > LINEAS_ERROR_VNU )); then
        tenue "(+$((errores - LINEAS_ERROR_VNU)) más)"
    fi
fi

# --- 12. RESUMEN ---
rm -rf -- "${DIR_CANONICOS:?}"
echo
titulo "$REGLA"
printf '%s✓ HTML generado%s\n' "$C_OK" "$C_RESET"
printf '  %-14s %s\n' "Archivo:"   "$INDEX"
printf '  %-14s %s\n' "Artículos:" "${#ARTICULOS[@]}"
if (( AVISOS > 0 )); then
    printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
fi
echo

terminar
