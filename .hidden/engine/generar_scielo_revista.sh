#!/bin/bash
# Paquete SciELO PS del número de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# Etapa F6 de los sabores (claude/salidas-revistas.md), decisiones de
# Alberto del 18/11/2026:
#   - SciELO PS sps-1.9 (JATS 1.1 Publishing), validado con packtools
#     4.18.2 (/opt/packtools, instalar-packtools.sh). sps-1.10 quedó
#     descartado: packtools 4.18.2 lo rechaza por defecto (medido);
#   - UN ZIP POR NÚMERO: salidas/scielo/{ISSN-acrónimo-volumen-número}.zip,
#     con una carpeta del mismo nombre y, por artículo, su XML, sus imágenes
#     y su PDF, todos con el nombre SPS (la regla de packtools, nombre_sps);
#   - LA PINZA DE SciELO: el PDF de cada artículo;
#   - como todos los sabores, exige las páginas de cada artículo.
#
# USO
#   generar_scielo_revista.sh <ruta_proyecto> <nombre_bib>
#
# LA FRONTERA CON GAMBAS (SC-13): Gambas escribe antes el volcado del número
# (tmp/numero-datos.xml, versión 4) y el .bib. Este script no toca la base.
# ============================================================================
# QUÉ HACE
#
#   1. Verifica el volcado, la pinza (el PDF de cada artículo) y las páginas.
#   2. Regenera los canónicos y hace la pasada de citas, como el EPUB: las
#      citas y las referencias son las mismas que el PDF (SC-57).
#   3. Por artículo: el nombre SPS (nombre_sps), el XML (jats-a-scielo.xsl),
#      las imágenes con su nombre SPS (el manifiesto que escribe la hoja) y
#      el PDF.
#   4. Valida la carpeta con packtools (validar_sps.py): DTD, reglas sps-1.9,
#      el nombre y los archivos que nombra cada XML.
#   5. Arma salidas/scielo/{número SPS}.zip.
#
# QUÉ ABORTA Y QUÉ SOLO AVISA
#   aborta   insumos ausentes, la pinza, un artículo sin páginas, la revista
#            sin ISSN o sin acrónimo, dos artículos con el mismo nombre SPS,
#            un canónico que no se generó, la pasada de citas, una
#            transformación o una imagen que falta en media/
#   avisa    canónicos o citas con avisos, sin título abreviado, packtools
#            ausente (el paquete sale sin validar: lo que no se comprobó no
#            está bien, GV-23) y los hallazgos de packtools (el detalle, en
#            la solapa «Validaciones», tipo SciELO)
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
LISTA_REL="tmp/lote-scielo-revista.txt"
# CUÁNTOS HALLAZGOS DE packtools SE MUESTRAN ACÁ (EL RESTO, EN LA SOLAPA)
HALLAZGOS_EN_PANTALLA=10

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "SciELO PS DEL NÚMERO"

# --- 3. ARGUMENTOS ---
if (( $# < 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <nombre_bib>"
fi
DIR_PROYECTO="${1%/}"
NOMBRE_BIB="$2"

VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"
DIR_SALIDA="$DIR_PROYECTO/salidas/scielo"
DIR_TRABAJO="$DIR_PROYECTO/tmp/scielo-work"
# LOS CANÓNICOS SIN DOCTYPE: SAXON NO BAJA LA DTD REMOTA (GV-25)
DIR_CANONICOS="$DIR_PROYECTO/tmp/scielo-canonicos"
XSL="$DIR_RECURSOS/xslt/jats-a-scielo.xsl"

# --- 4. ENTORNO ---
paso "verificando el entorno"
[[ -d "$DIR_PROYECTO" ]] || morir "No existe el proyecto: $DIR_PROYECTO"
[[ "$NOMBRE_BIB" == */* ]] && morir "Nombre de .bib no válido: $NOMBRE_BIB"
requerir_comandos java xmllint zip sha256sum stat
[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "Falta la hoja $XSL: reinstalá gbpublisher"
# SIN packtools EL PAQUETE SE ARMA IGUAL, PERO NO SE PUEDE DAR POR VÁLIDO
CON_PACKTOOLS=1
if motivo="$(packtools_presente)"; then
    ok "herramientas, hoja y packtools $SCIELO_VERSION_PACKTOOLS"
else
    CON_PACKTOOLS=0
    ok "herramientas y hoja"
    aviso "sin packtools: $motivo. El paquete se arma sin validar"
fi

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

# EL NOMBRE SPS SE ARMA CON EL ISSN Y EL ACRÓNIMO: SIN ELLOS NO HAY PAQUETE
[[ -n "$(dato_volcado 'normalize-space(/numero-datos/revista/issn[1])')" ]] ||
    morir "La revista no tiene ISSN: SciELO nombra cada archivo con él. Cargalo en Revistas"
[[ -n "$(dato_volcado 'normalize-space(/numero-datos/revista/acronimo)')" ]] ||
    morir "La revista no tiene acrónimo: SciELO nombra cada archivo con él. Cargalo en Revistas"
# SciELO PIDE EL TÍTULO ABREVIADO; LA HOJA PONE EL TÍTULO ENTERO SI FALTA
[[ -n "$(dato_volcado 'normalize-space(/numero-datos/revista/titulo-abreviado)')" ]] ||
    aviso "la revista no tiene título abreviado: va el título entero en abbrev-journal-title"

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
# EL PDF DE CADA ARTÍCULO VA EN EL PAQUETE: SIN ÉL NO HAY PAQUETE. EL DEL
# NÚMERO TAMBIÉN SE EXIGE: ES LA BASE DE LA PINZA (SC-93)
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

# --- 7. CANÓNICOS Y CITAS ---
printf '%s\n' "${ARTICULOS[@]}" > "$DIR_PROYECTO/$LISTA_REL" || morir "No se pudo escribir $LISTA_REL"
GBP_ANIDADO=1 bash "$DIR_ENGINE/generar_canonicos_articulos.sh" "$DIR_PROYECTO" "$LISTA_REL"
codigo=$?
case "$codigo" in
    "$SALIDA_OK") ;;
    "$SALIDA_AVISOS") aviso "los canónicos tienen avisos: revisar arriba" ;;
    *) morir "No se generaron todos los canónicos: el paquete de SciELO no se genera" ;;
esac

paso "preparando las citas con biblatex"
salida=$(GBP_ANIDADO=1 bash "$DIR_ENGINE/preparar_citas_revista.sh" \
            "$DIR_PROYECTO" "$NOMBRE_BIB" "$DIR_CITAS_REL" 2>&1)
codigo=$?
if (( codigo == SALIDA_AVISOS )); then
    mostrar_cola "$(grep '⚠' <<< "$salida")"
    aviso "la pasada de citas tiene avisos: el paquete se genera igual"
elif (( codigo != SALIDA_OK )); then
    mostrar_cola "$salida"
    morir "No se pudieron preparar las citas: el paquete de SciELO no se genera"
fi
ok "$(printf '%s\n' "$salida" | tail -n 1) cita(s) de biblatex"

# --- 8. LOS NOMBRES SPS ---
# SE CALCULAN TODOS ANTES DE GENERAR: DOS ARTÍCULOS CON EL MISMO NOMBRE SE
# PISARÍAN EN EL PAQUETE
paso "nombres SciELO PS"
rm -rf -- "${DIR_TRABAJO:?}" "${DIR_CANONICOS:?}"
mkdir -p "$DIR_SALIDA" "$DIR_TRABAJO" "$DIR_CANONICOS" || morir "No se pudieron crear las carpetas de trabajo"
declare -A NOMBRES=()
declare -A USADOS=()
orden=0
for a in "${ARTICULOS[@]}"; do
    orden=$((orden + 1))
    canonico="$DIR_CANONICOS/c-$a.xml"
    xmllint --nonet --dropdtd "$DIR_PROYECTO/jats/c-$a.xml" > "$canonico" 2>/dev/null ||
        morir "$a: el canónico jats/c-$a.xml no se pudo leer"
    n="$(nombre_sps "$canonico" "$orden")"
    [[ -n "$n" ]] || morir "$a: no se pudo armar el nombre SPS (¿falta el ISSN o el acrónimo en el canónico?)"
    # EL NOMBRE VA A RUTAS: SOLO LOS CARACTERES DE UN NOMBRE DE ARCHIVO
    [[ "$n" =~ ^[A-Za-z0-9._-]+$ ]] || morir "$a: el nombre SPS «$n» tiene caracteres que no van en un archivo (revisá volumen, número y páginas)"
    if [[ -n "${USADOS[$n]:-}" ]]; then
        morir "$a y ${USADOS[$n]} tienen el mismo nombre SPS ($n): revisá sus páginas o e-location"
    fi
    NOMBRES[$a]="$n"
    USADOS[$n]="$a"
    tenue "$a → $n"
done

# EL NOMBRE DEL NÚMERO: EL DEL PRIMER ARTÍCULO SIN SU ÚLTIMA PARTE (LA
# PÁGINA): ISSN-acrónimo-volumen-número
numero_sps="${NOMBRES[${ARTICULOS[0]}]%-*}"
DIR_PAQUETE="$DIR_TRABAJO/$numero_sps"
mkdir -p "$DIR_PAQUETE" || morir "No se pudo crear $DIR_PAQUETE"

printf '\n  %-14s %s\n' "Proyecto:" "$DIR_PROYECTO"
printf '  %-14s %s\n'   "Salida:"   "salidas/scielo/$numero_sps.zip"

# --- 9. UN ARTÍCULO POR VEZ ---
# SE JUNTAN TODOS LOS PROBLEMAS ANTES DE ABORTAR
problemas=0
orden=0
for a in "${ARTICULOS[@]}"; do
    orden=$((orden + 1))
    n="${NOMBRES[$a]}"
    paso "$a"
    canonico="$DIR_CANONICOS/c-$a.xml"
    manifiesto="$DIR_TRABAJO/$a.manifiesto"

    # A. EL XML SPS Y EL MANIFIESTO DE IMÁGENES
    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$canonico" -xsl:"$XSL" -o:"$DIR_PAQUETE/$n.xml" \
                archivo="$a" \
                bib_dir="$DIR_PROYECTO/$DIR_CITAS_REL" \
                estilo_cita="$ESTILO" \
                volcado="file://$VOLCADO" \
                nombre="$n" \
                orden="$orden" \
                manifiesto="file://$manifiesto" 2>&1)
    if (( $? != 0 )) || [[ ! -s "$DIR_PAQUETE/$n.xml" ]]; then
        fallo "Saxon no pudo escribir $n.xml"
        mostrar_cola "$salida" 8
        problemas=$((problemas + 1))
        continue
    fi

    # B. LAS IMÁGENES, CON EL NOMBRE SPS QUE LES DIO LA HOJA. SE COPIAN SIN
    # TOCAR: SciELO HACE SUS VERSIONES PARA PANTALLA
    imagenes=0
    if [[ -f "$manifiesto" ]]; then
        while IFS=$'\t' read -r original nuevo; do
            [[ -n "$original" ]] || continue
            if [[ ! -f "$DIR_PROYECTO/media/$original" ]]; then
                fallo "usa una imagen que no está en media/: $original"
                problemas=$((problemas + 1))
                continue
            fi
            cp -f "$DIR_PROYECTO/media/$original" "$DIR_PAQUETE/$nuevo" ||
                morir "No se pudo copiar media/$original"
            imagenes=$((imagenes + 1))
        done < "$manifiesto"
    fi

    # C. EL PDF DEL ARTÍCULO, CON EL NOMBRE DEL XML
    cp -f "$DIR_PROYECTO/salidas/pdf/$a.pdf" "$DIR_PAQUETE/$n.pdf" ||
        morir "No se pudo copiar salidas/pdf/$a.pdf"
    ok "$n: XML, PDF y $imagenes imagen(es)"
done

if (( problemas > 0 )); then
    morir "$problemas problema(s) en los artículos: revisar arriba"
fi

# --- 10. LA VALIDACIÓN CON packtools ---
# NO FRENA: EL PAQUETE SE ARMA Y LOS HALLAZGOS SE AVISAN. EL DETALLE ES DE LA
# SOLAPA «Validaciones» (TIPO SciELO), QUE VALIDA EL ZIP CON LA MISMA REGLA
if (( CON_PACKTOOLS )); then
    paso "validando con packtools"
    informe="$(validar_sps "$DIR_PAQUETE"/*.xml)"
    codigo=$?
    hallazgos="$(printf '%s\n' "$informe" | awk -F'\t' '$2 == "dtd" || $2 == "sps" || $2 == "nombre" || $2 == "activo" || $2 == "error"')"
    if (( codigo == 0 )); then
        ok "${#ARTICULOS[@]} XML válido(s) para sps-1.9"
    elif (( codigo == 2 )); then
        aviso "packtools no se pudo cargar: el paquete sale sin validar"
    else
        printf '%s\n' "$hallazgos" | head -n "$HALLAZGOS_EN_PANTALLA" |
            awk -F'\t' '{ printf "     %s, línea %s: %s\n", $1, $3, $4 }'
        aviso "$(printf '%s\n' "$hallazgos" | grep -c .) hallazgo(s) de packtools: el detalle, en la solapa Validaciones (SciELO)"
    fi
fi

# --- 11. EL ZIP ---
# UN NÚMERO ANTERIOR CON OTRO NOMBRE NO PUEDE QUEDAR AL LADO
paso "armando el paquete"
rm -f "$DIR_SALIDA"/*.zip
zip_final="$DIR_SALIDA/$numero_sps.zip"
temporal="$DIR_SALIDA/.$numero_sps.zip.tmp"
rm -f "$temporal"
if ! (cd "$DIR_TRABAJO" && zip -q -9 -X -r "$temporal" "$numero_sps"); then
    rm -f "$temporal"
    morir "No se pudo armar el ZIP"
fi
mv -f "$temporal" "$zip_final" || morir "No se pudo escribir $zip_final"
peso=$(stat -c %s "$zip_final")
ok "$numero_sps.zip: ${#ARTICULOS[@]} artículo(s), $(( peso / 1024 )) KB"

rm -rf -- "${DIR_TRABAJO:?}" "${DIR_CANONICOS:?}"
terminar
