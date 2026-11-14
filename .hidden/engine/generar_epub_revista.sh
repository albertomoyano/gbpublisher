#!/bin/bash
# EPUB 3 del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa E3 de las salidas de revistas (claude/salidas-revistas.md),
# decisiones de Alberto del 14/11/2026: un EPUB con el número entero (no hay
# EPUB por artículo), con las preliminares que el número declara, el sumario
# como página propia sin folios, Noto Serif y el nombre del PDF
# (ACRÓNIMO-AÑO-vVOL-nNÚM.epub).
#
# USO
#   generar_epub_revista.sh <ruta_proyecto> <nombre_bib>
#
#   ruta_proyecto    raíz del proyecto
#   nombre_bib       el .bib del proyecto en referencias/, con extensión
#                    (m_Bibtex.NombreArchivoBib, como el PDF)
#
# LA FRONTERA CON GAMBAS (SC-13)
#   Gambas escribe antes el volcado del número (tmp/numero-datos.xml, versión
#   4) y el .bib. Este script no toca la base. A diferencia de libros, el
#   armazón del paquete —content.opf, nav, tapa, página legal y sumario— no
#   lo escribe Gambas: sale del volcado por numero-a-epub.xsl, con las mismas
#   funciones que las preliminares del PDF (decisión de Alberto: escrito una
#   sola vez, el EPUB y el PDF no divergen).
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado y lo que el número necesita: las preliminares que
#      declara y las páginas de cada artículo. Las páginas salen de la última
#      composición del PDF (las guarda Gambas en la base): sin ellas el
#      «cómo citar» saldría sin rango, y el EPUB no se genera (decisión de
#      Alberto). En el modelo continua, lo que hace falta es el e-id.
#   2. Regenera los canónicos (generar_canonicos_articulos.sh, anidado), como
#      el PDF: el volcado puede traer datos nuevos de la base.
#   3. La pasada de citas (preparar_citas_revista.sh, anidado, SC-57): el
#      texto de las citas, las referencias y el «cómo citar» lo escribe
#      biblatex, el mismo que el PDF.
#   4. numero-a-epub.xsl escribe content.opf, nav.xhtml y las preliminares;
#      jats-a-epub-articulo.xsl, un XHTML por artículo.
#   5. Copia la hoja de estilos, las fuentes y las imágenes que el OPF
#      declara (copiar_imagen_pantalla, SC-76); escribe mimetype y
#      container.xml; verifica que todo lo declarado exista; empaqueta y
#      valida con epubcheck.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   recursos o insumos ausentes, un artículo sin páginas, un
#            canónico que no se generó, la pasada de citas fallida, un
#            artículo que no se pudo transformar, un archivo declarado en el
#            OPF que no existe, un fallo al empaquetar. Un número al que le
#            falta un artículo no se genera.
#   avisa    canónicos o citas con avisos; errores de epubcheck, o epubcheck
#            ausente. El EPUB se conserva y el aviso llega a Gambas como
#            código 3.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  EPUB generado y válido
#   3  generado, con avisos
#   1  no se generó
# ============================================================================

set -uo pipefail

# --- 1. FUNCIONES COMPARTIDAS ---
DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
# LA LECTURA DEL VOLCADO Y EL NOMBRE DEL NÚMERO, LOS MISMOS QUE EL PDF
if ! source "$DIR_ENGINE/revista_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/revista_comun.sh" >&2
    exit 1
fi

# --- 2. CONFIGURACIÓN ---
TIEMPO_SAXON=120
TIEMPO_EPUBCHECK=300
LINEAS_EPUBCHECK=15

# NOMBRES FIJOS DEL PAQUETE. DEBEN COINCIDIR CON LOS QUE DECLARA
# numero-a-epub.xsl ($gbn:css, $gbn:fuentes): SI DIVERGEN, LA VERIFICACIÓN
# DEL OPF LO ATRAPA
FUENTES=(NotoSerif-Regular.ttf NotoSerif-Bold.ttf NotoSerif-Italic.ttf NotoSerif-BoldItalic.ttf)
CSS_EPUB="gbpublisher-epub-revista.css"

# EL VOLCADO: LA MISMA RUTA Y VERSIÓN QUE m_CanonicoRevista. SI CAMBIAN
# ALLÁ, CAMBIAN ACÁ (Y EN LOS OTROS LECTORES)
VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="4"

# LA PASADA DE CITAS: UNA CARPETA FIJA, COMO EN LIBROS
DIR_CITAS_REL="tmp/bib/epub-revista"
# LA LISTA DE CANÓNICOS QUE SE REGENERAN
LISTA_REL="tmp/lote-epub-revista.txt"

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "EPUB DEL NÚMERO"

# --- 3. ARGUMENTOS ---
if (( $# < 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib>"
fi
DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
DIR_TRABAJO="$DIR_PROYECTO/tmp/epub-work"
DIR_OEBPS="$DIR_TRABAJO/OEBPS"
OPF="$DIR_OEBPS/content.opf"
# LOS CANÓNICOS SIN DOCTYPE: SAXON NO BAJA LA DTD REMOTA (GV-25)
DIR_CANONICOS="$DIR_PROYECTO/tmp/epub-canonicos"
DIR_SALIDA="$DIR_PROYECTO/salidas/epub"
XSL_NUMERO="$DIR_GBP_LOCAL/xslt/numero-a-epub.xsl"
XSL_ARTICULO="$DIR_GBP_LOCAL/xslt/jats-a-epub-articulo.xsl"
DIR_FUENTES="$DIR_GBP_LOCAL/fonts"
CSS="$DIR_GBP_LOCAL/assets/css/$CSS_EPUB"

# --- 4. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
[[ "$NOMBRE_BIB" == */* ]] && morir "Nombre de .bib no válido: $NOMBRE_BIB"

requerir_comandos java xmllint zip identify convert sha256sum iconv
[[ -f "$RUTA_SAXON" ]]   || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL_NUMERO" ]]   || morir "Falta la hoja $XSL_NUMERO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -f "$XSL_ARTICULO" ]] || morir "Falta la hoja $XSL_ARTICULO: actualizá la copia local (~/.gbpublisher/xslt)"
[[ -f "$CSS" ]]          || morir "No se encontró la hoja de estilos del EPUB: $CSS"

faltan=()
for fuente in "${FUENTES[@]}"; do
    [[ -f "$DIR_FUENTES/$fuente" ]] || faltan+=("$fuente")
done
if (( ${#faltan[@]} > 0 )); then
    morir "Faltan fuentes en $DIR_FUENTES: ${faltan[*]}"
fi
ok "herramientas, hojas, hoja de estilos y fuentes"

# --- 5. EL VOLCADO ---
[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"
MODELO="$(dato_volcado 'string(/numero-datos/revista/@modelo-paginacion)')"
ESTILO="$(dato_volcado 'string(/numero-datos/revista/estilo-cita)')"
case "$MODELO" in
    por_numero|por_volumen|por_articulo|continua) ;;
    "") morir "La revista no tiene modelo de paginación: elegilo en la ficha de la revista" ;;
    *)  morir "Modelo de paginación desconocido: «$MODELO»" ;;
esac
[[ -n "$ESTILO" ]] || morir "La revista no tiene estilo de cita: elegilo en la ficha de la revista"
ok "volcado versión $version; paginación $MODELO; citas $ESTILO"

# EL NOMBRE: EL DEL PDF CON .epub (revista_comun.sh). SIN ACRÓNIMO O SIN AÑO
# NO HAY NOMBRE: FRENA ANTES DE TRABAJAR
base="$(nombre_numero)"
[[ -n "$base" ]] ||
    morir "Para nombrar el EPUB del número hacen falta el acrónimo de la revista (en Revistas) y el año del número (en sus metadatos)"
NOMBRE_EPUB="$base.epub"
EPUB="$DIR_SALIDA/$NOMBRE_EPUB"
# EL TEMPORAL LLEVA EXTENSIÓN .tmp: zip AGREGA .zip A UN NOMBRE SIN EXTENSIÓN
TEMPORAL="$DIR_SALIDA/.$NOMBRE_EPUB.tmp"

# --- 6. LOS ARTÍCULOS, EN EL ORDEN DEL VOLCADO (EL MANIFIESTO) ---
mapfile -t ARTICULOS < <(dato_volcado '/numero-datos/articulo/@archivo' | grep -oP 'archivo="\K[^"]+')
(( ${#ARTICULOS[@]} > 0 )) || morir "El número no tiene artículos con metadatos"
for a in "${ARTICULOS[@]}"; do
    # EL MISMO CONTROL QUE generar_canonicos_articulos.sh: EL NOMBRE VA A UN
    # XPATH Y A RUTAS
    [[ "$a" =~ ^a-[A-Za-z0-9._-]+$ ]] || morir "Nombre de artículo no válido en el volcado: «$a»"
done

# --- 7. LO QUE EL NÚMERO NECESITA: PRELIMINARES Y PÁGINAS ---
paso "verificando el número"

# LAS PRELIMINARES: LAS MISMAS CONDICIONES QUE EL PDF (B5). EL EPUB LLEVA
# LAS QUE EL NÚMERO DECLARA (DECISIÓN DE ALBERTO)
if [[ -n "$(dato_volcado "string(/numero-datos/preliminares/pieza[@tipo='tapa']/@tipo)")" ]]; then
    tapa="$(dato_volcado 'normalize-space(/numero-datos/numero/imagen-tapa)')"
    [[ -n "$tapa" ]] || morir "El número declara la tapa y no tiene imagen: elegila en los metadatos del número"
    [[ -f "$DIR_PROYECTO/media/$tapa" ]] || morir "La tapa del número (media/$tapa) no está en el proyecto"
    [[ "${tapa,,}" =~ \.(jpe?g|png)$ ]] || morir "La tapa del número tiene que ser JPG o PNG: media/$tapa"
fi
if [[ -n "$(dato_volcado "string(/numero-datos/preliminares/pieza[@tipo='legales']/@tipo)")" ]]; then
    [[ -n "$(dato_volcado 'string(/numero-datos/pagina-legal/@fecha-referencia)')" ]] ||
        morir "El número declara la página legal y el volcado no la trae (¿falta el año del número?)"
fi
PRELIMINARES="$(dato_volcado '/numero-datos/preliminares/pieza/@tipo' | grep -oP 'tipo="\K[^"]+' | paste -sd' ')"
ok "preliminares: ${PRELIMINARES:-ninguna}"

# LAS PÁGINAS DEL «CÓMO CITAR» SALEN DE LA BASE, QUE LAS TOMA DE LA ÚLTIMA
# COMPOSICIÓN DEL PDF. SIN ELLAS NO HAY EPUB (DECISIÓN DE ALBERTO, 14/11): SE
# JUNTAN TODOS LOS QUE FALTAN ANTES DE FRENAR. QUE EL PDF HAYA QUEDADO VIEJO
# NO SE DETECTA ACÁ
sin_paginas=()
for a in "${ARTICULOS[@]}"; do
    if [[ "$MODELO" == "continua" ]]; then
        [[ -n "$(dato_articulo "$a" 'paginas/@elocation')" ]] || sin_paginas+=("$a")
    else
        if [[ -z "$(dato_articulo "$a" 'paginas/@inicio')" || -z "$(dato_articulo "$a" 'paginas/@fin')" ]]; then
            sin_paginas+=("$a")
        fi
    fi
done
if (( ${#sin_paginas[@]} > 0 )); then
    printf '%s\n' "${sin_paginas[@]}" | sed 's/^/     /'
    if [[ "$MODELO" == "continua" ]]; then
        morir "${#sin_paginas[@]} artículo(s) sin e-id: componé primero el PDF del número, que los asigna"
    fi
    morir "${#sin_paginas[@]} artículo(s) sin páginas en la base: componé primero el PDF del número"
fi
ok "${#ARTICULOS[@]} artículo(s), todos con $( [[ "$MODELO" == "continua" ]] && echo e-id || echo páginas )"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "$NOMBRE_EPUB"

# --- 8. LOS CANÓNICOS ---
# ANIDADO, Y LOS REHACE TODOS, COMO EL PDF: EL VOLCADO PUEDE TRAER DATOS
# NUEVOS DE LA BASE AUNQUE EL .md NO HAYA CAMBIADO
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: el EPUB no se genera" ;;
esac

# --- 9. LAS CITAS (SC-57) ---
# CÓDIGO 3: CITAS SIN ENTRADA EN EL .bib; SE SIGUE Y EL AVISO SE HEREDA
paso "preparando las citas con biblatex"
salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/preparar_citas_revista.sh" \
            "$DIR_PROYECTO" "$NOMBRE_BIB" "$DIR_CITAS_REL" 2>&1)
codigo=$?
if (( codigo == SALIDA_AVISOS )); then
    mostrar_cola "$(grep '⚠' <<< "$salida")"
    aviso "la pasada de citas tiene avisos: el EPUB se genera igual"
elif (( codigo != SALIDA_OK )); then
    mostrar_cola "$salida"
    morir "No se pudieron preparar las citas: el EPUB no se genera"
fi
ok "$(printf '%s\n' "$salida" | tail -n 1) cita(s) de biblatex"

# --- 10. EL ÁRBOL DE TRABAJO, LIMPIO ---
# UN ARCHIVO DE UNA CORRIDA ANTERIOR (UN ARTÍCULO QUE YA NO ESTÁ, UNA
# PRELIMINAR QUE SE DEJÓ DE DECLARAR) NO PUEDE COLARSE EN EL PAQUETE
paso "preparando el paquete"
rm -rf -- "${DIR_TRABAJO:?}" "${DIR_CANONICOS:?}"
mkdir -p "$DIR_OEBPS/chapters" "$DIR_OEBPS/css" "$DIR_OEBPS/fonts" "$DIR_OEBPS/images" \
         "$DIR_TRABAJO/META-INF" "$DIR_CANONICOS" ||
    morir "No se pudo crear el árbol de trabajo en tmp/epub-work"

for a in "${ARTICULOS[@]}"; do
    xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$a.xml" > "$DIR_CANONICOS/c-$a.xml" 2>/dev/null ||
        morir "$a: el canónico jats/c-$a.xml no se pudo leer"
done

# EL ARMAZÓN: OPF, nav Y PRELIMINARES, DESDE EL VOLCADO. dcterms:modified
# EN UTC, COMO PIDE EPUB 3
salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
            -s:"$VOLCADO" -xsl:"$XSL_NUMERO" -o:"$OPF" \
            dir_canonicos="$DIR_CANONICOS" \
            modificado="$(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>&1)
if (( $? != 0 )); then
    mostrar_cola "$salida"
    morir "numero-a-epub.xsl no pudo escribir content.opf, el nav y las preliminares"
fi
bien_formado "$OPF" || morir "content.opf salió mal formado"
bien_formado "$DIR_OEBPS/nav.xhtml" || morir "nav.xhtml salió mal formado"
ok "content.opf, nav.xhtml y preliminares"

# --- 11. LOS ARTÍCULOS ---
# SE JUNTAN TODOS LOS PROBLEMAS ANTES DE ABORTAR: EL EDITOR NECESITA VER
# TODO LO QUE HAY QUE ARREGLAR
paso "transformando los artículos"
problemas=0
for a in "${ARTICULOS[@]}"; do
    xhtml="$DIR_OEBPS/chapters/$a.xhtml"
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$DIR_CANONICOS/c-$a.xml" -xsl:"$XSL_ARTICULO" -o:"$xhtml" \
                archivo="$a" \
                bib_dir="$DIR_PROYECTO/$DIR_CITAS_REL" \
                estilo_cita="$ESTILO" 2>&1)
    codigo=$?
    if (( codigo != 0 )); then
        fallo "$a: Saxon falló (código $codigo)"
        mostrar_cola "$salida" 8
        problemas=$((problemas + 1))
    elif ! bien_formado "$xhtml"; then
        fallo "$a: el XHTML salió mal formado"
        problemas=$((problemas + 1))
    else
        ok "$a"
    fi
done
if (( problemas > 0 )); then
    morir "$problemas artículo(s) con problemas: el EPUB no se genera"
fi

# --- 12. RECURSOS ---
paso "copiando recursos"
cp -f "$CSS" "$DIR_OEBPS/css/" || morir "No se pudo copiar la hoja de estilos"
for fuente in "${FUENTES[@]}"; do
    cp -f "$DIR_FUENTES/$fuente" "$DIR_OEBPS/fonts/" || morir "No se pudo copiar $fuente"
done
ok "hoja de estilos y ${#FUENTES[@]} fuentes"

# LAS IMÁGENES: LAS QUE EL OPF DECLARA EN images/, Y NINGUNA MÁS (SC-76). LA
# LISTA LA ARMA numero-a-epub.xsl CON LO QUE USAN LOS ARTÍCULOS Y LA TAPA.
# local-name() Y NO EL PREFIJO: xmllint --xpath NO CONOCE LOS NAMESPACES DEL
# DOCUMENTO (GV-22)
mapfile -t IMAGENES_OPF < <(
    xmllint --xpath "//*[local-name()='manifest']/*[local-name()='item']/@href" "$OPF" 2>/dev/null |
    grep -oP 'href="images/\K[^"]+'
)
imagenes=0
reducidas=0
for nombre in "${IMAGENES_OPF[@]}"; do
    [[ -n "$nombre" ]] || continue
    origen="$DIR_PROYECTO/media/$nombre"
    [[ -f "$origen" ]] || morir "El número usa una imagen que no está en media/: $nombre"
    copiar_imagen_pantalla "$origen" "$DIR_OEBPS/images/$nombre" "$DIR_PROYECTO/tmp/pantalla" ||
        morir "No se pudo preparar la imagen $nombre${PANTALLA_NOTA:+: $PANTALLA_NOTA}"
    imagenes=$((imagenes + 1))
    [[ -z "$PANTALLA_NOTA" ]] || tenue "$nombre: $PANTALLA_NOTA"
    reducidas=$((reducidas + PANTALLA_PREPARADA))
done
if (( imagenes > 0 && reducidas > 0 )); then
    ok "$imagenes imagen(es), $reducidas preparada(s) para pantalla"
elif (( imagenes > 0 )); then
    ok "$imagenes imagen(es)"
else
    tenue "el número no usa imágenes"
fi

# --- 13. mimetype Y container.xml ---
# FIJOS DEL FORMATO. mimetype SIN SALTO FINAL
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

# --- 14. VERIFICACIÓN DEL OPF ---
# CADA href DEL MANIFIESTO TIENE QUE EXISTIR: UN ARCHIVO DECLARADO Y AUSENTE
# DEJARÍA EL EPUB ROTO, Y epubcheck LO DIRÍA RECIÉN AL FINAL
paso "verificando el paquete contra content.opf"
mapfile -t DECLARADOS < <(
    xmllint --xpath "//*[local-name()='manifest']/*[local-name()='item']/@href" "$OPF" 2>/dev/null |
    grep -oP 'href="\K[^"]+'
)
(( ${#DECLARADOS[@]} > 0 )) || morir "content.opf no declara ningún archivo"
ausentes=0
for href in "${DECLARADOS[@]}"; do
    if [[ ! -f "$DIR_OEBPS/$href" ]]; then
        fallo "declarado y ausente: $href"
        ausentes=$((ausentes + 1))
    fi
done
if (( ausentes > 0 )); then
    morir "content.opf declara $ausentes archivo(s) que no existen: el EPUB no se empaqueta"
fi
ok "${#DECLARADOS[@]} archivos declarados, todos presentes"

# --- 15. EMPAQUETADO ---
# mimetype PRIMERO Y SIN COMPRIMIR: LO EXIGE EL FORMATO. SE EMPAQUETA EN UN
# TEMPORAL Y SE RENOMBRA AL FINAL: SI ALGO FALLA, EL EPUB ANTERIOR SIGUE
# INTACTO
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
ok "salidas/epub/$NOMBRE_EPUB"

# --- 16. VALIDACIÓN CON epubcheck ---
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

# --- 17. RESUMEN ---
rm -rf -- "${DIR_CANONICOS:?}"
echo
titulo "$REGLA"
printf '%s✓ EPUB generado%s\n' "$C_OK" "$C_RESET"
printf '  %-14s %s\n'    "Archivo:"    "$EPUB"
printf '  %-14s %s KB\n' "Tamaño:"     "$(( $(stat -c%s "$EPUB") / 1024 ))"
printf '  %-14s %s\n'    "Artículos:"  "${#ARTICULOS[@]}"
if (( AVISOS > 0 )); then
    printf '  %s⚠ con %d aviso(s): revisar arriba%s\n' "$C_AVISO" "$AVISOS" "$C_RESET"
fi
echo

terminar
