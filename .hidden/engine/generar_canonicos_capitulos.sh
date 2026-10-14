#!/bin/bash
# Generador de los canónicos DocBook de capítulo — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   generar_canonicos_capitulos.sh <ruta_proyecto> <lista_rel>
#
#   ruta_proyecto   raíz del proyecto
#   lista_rel       ruta relativa al proyecto de la lista de capítulos. Una
#                   línea por capítulo, cuatro campos separados por TAB:
#
#                     nombre_archivo  xml_id  tipo_capitulo  idioma
#                     a-02-metodologia  cap-37  capitulo  es
#
#                   Uno solo para «Canónico archivo en curso»; todos los que
#                   tienen cuerpo para «Todos los canónicos». El script no
#                   distingue: procesa lo que la lista declara, en ese orden.
#
# LOS INSUMOS LOS ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT: la lista,
# tmp/info-{base}.xml y tmp/biblio-{base}.xml de cada capítulo, y el .bib del
# proyecto ya exportado. Todo lo que sale de la base llega como archivo. Este
# script no toca la base ({base} es nombre_archivo sin su prefijo fm-, a- o
# bm-: a-02-metodologia → 02-metodologia).
#
# POR CADA CAPÍTULO
#   1. pandoc con los filtros de libro → tmp/body-{base}.xml (con su envoltorio)
#   2. Saxon con ensamblar-capitulo-canonico.xsl → jats/c-{nombre}.xml,
#      escrito en un temporal y renombrado con mv: nunca queda en disco un
#      canónico a medio escribir (el mismo motivo que en ensamblar_libro.sh)
#   3. jing contra DocBook 5.2: informativo, como en el libro
# ============================================================================
# QUÉ PASA CUANDO UN CAPÍTULO FALLA
#
#   Se sigue con los demás y al final se listan todos los que fallaron: en un
#   lote de correcciones el editor necesita ver todo lo que hay que arreglar,
#   no solo el primero (mismo criterio que el paso 5 de ensamblar_libro.sh).
#
#   Y el canónico anterior de ESE capítulo SE BORRA. Al revés que el del libro,
#   que se conserva: si un capítulo no se regeneró, su canónico viejo no
#   corresponde al .md, y el ensamblado, el PDF y el EPUB lo tomarían igual,
#   sin aviso. Borrado, el ensamblado se niega («falta jats/c-…») hasta que el
#   capítulo se arregle. El canónico se reconstruye siempre desde el .md: no
#   se pierde nada que no se pueda regenerar.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  todos los capítulos generados y válidos
#   3  todos generados, alguno con avisos (validación de esquema)
#   1  al menos un capítulo no se generó, o el lote no pudo empezar
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_PANDOC=120
TIEMPO_SAXON=120
LINEAS_ERROR_RNG=15

XSL="$DIR_GBP_LOCAL/xslt/ensamblar-capitulo-canonico.xsl"
RNG="$DIR_GBP_LOCAL/schemas/docbook/docbook.rng"
DIR_FILTROS="$DIR_GBP_LOCAL/filters"

# EL ORDEN DE LOS FILTROS ES EL QUE FIJABA m_XML.GenerarBodyCapituloXML, CON
# SUS RAZONES (RC-DB-07, SC-35, SC-39, SC-41, SC-42, SC-43, SC-49):
#   1° guillemets-to-quoted-db  « » A Quoted. PRIMERO: fenced-divs SERIALIZA
#      LOS DIVS CON pandoc.write Y DESPUÉS NO QUEDAN Str QUE PROCESAR
#   2° cite-to-biblioref-db     CITAS BIBLIOGRÁFICAS
#   3° dos-partes               EPÍGRAFES {texto}{atribución}; FRENA SI UNO
#      ESTÁ MAL FORMADO
#   4° espacio-vertical         FICHA <?gb-espacio …?>; ANTES DE fenced-divs,
#      QUE NO CONOCE EL BLOQUE espaciov
#   5° recuadros                DESPUÉS DE dos-partes, QUE PARTE EL recuadrob
#   6° codigo                   <programlisting>; ANTES DE fenced-divs, QUE
#      ARMA EL <example role="listado">
#   7° conversacion             ANTES DE fenced-divs, QUE ARMA EL <qandaset>.
#      SIN -M gb-idioma: LA ETIQUETA LA PONE LA HOJA SEGÚN xml:lang
#   8° verso                    DESPUÉS DE dos-partes, ANTES DE fenced-divs
#   9° fenced-divs-to-elements-db  AL FINAL
FILTROS=(
    guillemets-to-quoted-db.lua
    cite-to-biblioref-db.lua
    dos-partes.lua
    espacio-vertical.lua
    recuadros.lua
    codigo.lua
    conversacion.lua
    verso.lua
    fenced-divs-to-elements-db.lua
)

# EL ENVOLTORIO ES OBLIGATORIO: EL XSLT CARGA EL FRAGMENTO CON document() Y
# SIN LOS NAMESPACES DECLARADOS FALLA (RC-DB-06)
ENVOLTORIO_ABRE='<section xmlns="http://docbook.org/ns/docbook" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:xlink="http://www.w3.org/1999/xlink">'
ENVOLTORIO_CIERRA='</section>'

# ============================================================================
# Función   : fallo
# Propósito : Informa el fallo de UN capítulo sin terminar el script: morir()
#             saldría del lote entero.
# Parámetros: $1 mensaje
# ============================================================================
fallo() {
    printf '  %s✗%s %s\n' "$C_ERROR" "$C_RESET" "$1"
}

# ============================================================================
# Función   : procesar_capitulo
# Propósito : pandoc, Saxon y jing para un capítulo.
# Parámetros: $1 nombre_archivo  $2 xml_id  $3 tipo_capitulo  $4 idioma
# Retorna   : 0 generado (con o sin avisos, que cuenta aviso()); 1 no generado
# ============================================================================
procesar_capitulo() {
    local nombre="$1" xml_id="$2" tipo="$3" idioma="$4"
    local base carpeta md info body biblio parcial canonico temporal
    local salida codigo filtro errores
    local args_pandoc=()

    # --- A. RUTAS ---
    # EL NOMBRE SIN PREFIJO, COMO Mid(…, InStr(…, "-") + 1) EN GAMBAS
    base="${nombre#*-}"
    case "$nombre" in
        fm-*) carpeta="front-matter" ;;
        a-*)  carpeta="articulos" ;;
        bm-*) carpeta="back-matter" ;;
        *)    fallo "prefijo no reconocido (se espera fm-, a- o bm-)"; return 1 ;;
    esac

    md="$DIR_PROYECTO/$carpeta/$nombre.md"
    info="$DIR_PROYECTO/tmp/info-$base.xml"
    biblio="$DIR_PROYECTO/tmp/biblio-$base.xml"
    body="$DIR_PROYECTO/tmp/body-$base.xml"
    parcial="$body.parcial"
    canonico="$DIR_PROYECTO/jats/c-$nombre.xml"
    # EN LA MISMA CARPETA QUE EL DEFINITIVO: mv TIENE QUE SER UN RENOMBRE
    temporal="$DIR_PROYECTO/jats/.c-$nombre.xml.tmp"

    # --- B. INSUMOS ---
    [[ -f "$md" ]] || { fallo "no existe $carpeta/$nombre.md"; return 1; }
    [[ -f "$info" ]] || { fallo "no existe tmp/info-$base.xml"; return 1; }
    bien_formado "$info" || { fallo "tmp/info-$base.xml está mal formado"; return 1; }
    [[ -f "$biblio" ]] || { fallo "no existe tmp/biblio-$base.xml"; return 1; }
    bien_formado "$biblio" || { fallo "tmp/biblio-$base.xml está mal formado"; return 1; }

    # --- C. PANDOC ---
    # SE BORRA EL body ANTERIOR: SI ESTA CORRIDA FALLA, NO PUEDE QUEDAR EL
    # VIEJO PARA QUE ALGO LO TOME POR BUENO
    rm -f "$body" "$parcial" "$body.fallo"

    for filtro in "${FILTROS[@]}"; do
        args_pandoc+=(--lua-filter "$DIR_FILTROS/$filtro")
    done

    salida=$(timeout "$TIEMPO_PANDOC" pandoc "$md" \
                --from markdown --to docbook5 --mathml --no-highlight --wrap=none \
                "${args_pandoc[@]}" \
                --output "$parcial" 2>&1)
    codigo=$?

    if (( codigo == 124 )); then
        rm -f "$parcial"
        fallo "pandoc no terminó en $TIEMPO_PANDOC segundos"
        return 1
    fi
    if (( codigo != 0 )); then
        # EL MOTIVO LO DA EL FILTRO QUE FRENÓ: ES LO QUE EL EDITOR TIENE QUE LEER
        mostrar_cola "$salida"
        rm -f "$parcial"
        fallo "pandoc rechazó $carpeta/$nombre.md"
        return 1
    fi
    if [[ ! -s "$parcial" ]]; then
        rm -f "$parcial"
        fallo "pandoc no produjo contenido: ¿el .md está vacío?"
        return 1
    fi

    { printf '%s\n' "$ENVOLTORIO_ABRE"; cat "$parcial"; printf '%s\n' "$ENVOLTORIO_CIERRA"; } > "$body"
    rm -f "$parcial"

    if ! bien_formado "$body"; then
        fallo "el cuerpo convertido está mal formado: tmp/body-$base.xml"
        return 1
    fi

    # LOS AVISOS DE PANDOC QUE NO FRENAN SE MUESTRAN PARA QUE NO SE PIERDAN
    if [[ -n "$salida" ]]; then
        tenue "mensajes de pandoc:"
        mostrar_cola "$salida" 10
    fi
    ok "cuerpo"

    # --- D. SAXON ---
    rm -f "$temporal"

    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$info" \
                -xsl:"$XSL" \
                -o:"$temporal" \
                body="$body" \
                biblio="$biblio" \
                tipo_capitulo="$tipo" \
                xml_id_capitulo="$xml_id" \
                idioma="$idioma" 2>&1)
    codigo=$?

    if (( codigo == 124 )); then
        rm -f "$temporal"
        fallo "Saxon no terminó en $TIEMPO_SAXON segundos"
        return 1
    fi
    if (( codigo != 0 )); then
        mostrar_cola "$salida"
        rm -f "$temporal"
        fallo "Saxon no pudo ensamblar el capítulo"
        return 1
    fi
    if [[ ! -s "$temporal" ]]; then
        rm -f "$temporal"
        fallo "Saxon terminó sin escribir el canónico"
        return 1
    fi
    if ! bien_formado "$temporal"; then
        rm -f "$temporal"
        fallo "el ensamblado produjo un XML mal formado"
        return 1
    fi

    if [[ -n "$salida" ]]; then
        tenue "mensajes de la transformación:"
        mostrar_cola "$salida" 10
    fi

    mv -f "$temporal" "$canonico" || { fallo "no se pudo reemplazar jats/c-$nombre.xml"; return 1; }
    ok "canónico bien formado"

    # --- E. VALIDACIÓN CONTRA DocBook 5.2 ---
    # INFORMATIVA, COMO EN EL LIBRO: UN CANÓNICO BIEN FORMADO QUE NO VALIDA SE
    # CONSERVA, PERO EL AVISO LLEGA A GAMBAS COMO CÓDIGO 3. LA AUSENCIA DE jing
    # O DEL ESQUEMA SE AVISA UNA SOLA VEZ, ANTES DEL LOTE
    if [[ "$VALIDAR" == "si" ]]; then
        salida=$(jing "$RNG" "$canonico" 2>&1)
        codigo=$?
        if (( codigo == 0 )); then
            ok "válido contra DocBook 5.2"
        else
            errores=$(printf '%s\n' "$salida" | grep -c .)
            aviso "$errores error(es) de validación contra el esquema:"
            # SE QUITA LA RUTA, QUE SE REPITE EN CADA LÍNEA
            printf '%s\n' "$salida" | sed "s|^$canonico:||" |
                head -"$LINEAS_ERROR_RNG" | sed 's/^/     /'
            if (( errores > LINEAS_ERROR_RNG )); then
                tenue "(+$((errores - LINEAS_ERROR_RNG)) más)"
            fi
        fi
    fi

    return 0
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "CANÓNICOS DE CAPÍTULO"

# --- 2. ARGUMENTOS ---
if (( $# < 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <lista_rel>"
fi

DIR_PROYECTO="${1%/}"
LISTA="$DIR_PROYECTO/$2"

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]      || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/jats" ]] || morir "El proyecto no tiene carpeta jats/"
[[ -d "$DIR_PROYECTO/tmp" ]]  || morir "El proyecto no tiene carpeta tmp/"

requerir_comandos pandoc java xmllint timeout

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de ensamblado: $XSL"

faltan=()
for filtro in "${FILTROS[@]}"; do
    [[ -f "$DIR_FILTROS/$filtro" ]] || faltan+=("$filtro")
done
if (( ${#faltan[@]} > 0 )); then
    morir "Faltan filtros en $DIR_FILTROS: ${faltan[*]}"
fi

ok "herramientas, hoja y filtros"

# LA FALTA DE VALIDADOR SE AVISA UNA VEZ, NO UNA POR CAPÍTULO. SIGUE SIENDO
# AVISO: EL INFORME NO PUEDE DAR POR VÁLIDO LO QUE NO VALIDÓ
VALIDAR="si"
if ! command -v jing >/dev/null 2>&1; then
    aviso "jing no está instalado: los canónicos no se validan contra el esquema"
    VALIDAR="no"
elif [[ ! -f "$RNG" ]]; then
    aviso "no se encontró el esquema $RNG: los canónicos no se validan"
    VALIDAR="no"
fi

# --- 4. LISTA ---
paso "leyendo la lista de capítulos"

[[ -f "$LISTA" ]] || morir "No existe la lista de capítulos: $LISTA"

NOMBRES=() ; IDS=() ; TIPOS=() ; IDIOMAS=()
numero_linea=0
while IFS=$'\t' read -r nombre xml_id tipo idioma resto || [[ -n "$nombre" ]]; do
    numero_linea=$((numero_linea + 1))
    [[ -z "$nombre" ]] && continue
    # UN NOMBRE CON / SALDRÍA DE LA CARPETA DEL PROYECTO; UN CAMPO DE MÁS
    # O DE MENOS ES UNA LISTA QUE GAMBAS NO ESCRIBIÓ COMO ESTE SCRIPT ESPERA
    if [[ "$nombre" == */* || -z "$xml_id" || -z "$tipo" || -z "$idioma" || -n "${resto:-}" ]]; then
        morir "Línea $numero_linea de la lista mal formada: $nombre"
    fi
    NOMBRES+=("$nombre") ; IDS+=("$xml_id") ; TIPOS+=("$tipo") ; IDIOMAS+=("$idioma")
done < "$LISTA"

TOTAL=${#NOMBRES[@]}
(( TOTAL > 0 )) || morir "La lista no declara ningún capítulo"
ok "$TOTAL capítulo(s)"

# --- 5. LOTE ---
GENERADOS=0
CON_AVISOS=()
FALLIDOS=()

for (( i = 0; i < TOTAL; i++ )); do
    nombre="${NOMBRES[$i]}"
    paso "$((i + 1))/$TOTAL  $nombre"

    avisos_antes=$AVISOS
    if procesar_capitulo "$nombre" "${IDS[$i]}" "${TIPOS[$i]}" "${IDIOMAS[$i]}"; then
        GENERADOS=$((GENERADOS + 1))
        (( AVISOS > avisos_antes )) && CON_AVISOS+=("$nombre")
    else
        FALLIDOS+=("$nombre")
        # VER LA CABECERA: UN CANÓNICO QUE NO SE REGENERÓ NO SE CONSERVA
        if [[ -f "$DIR_PROYECTO/jats/c-$nombre.xml" ]]; then
            rm -f "$DIR_PROYECTO/jats/c-$nombre.xml"
            tenue "se borró el canónico anterior: ya no corresponde a su .md"
        fi
    fi
done

# --- 6. RESUMEN ---
# SOLO SE AFIRMA LO VERIFICADO: CADA ✓ DE ARRIBA LO DIJO xmllint O jing
echo
titulo "$REGLA"
if (( ${#FALLIDOS[@]} == 0 )); then
    printf '%s✓ Canónicos generados: %d de %d%s\n' "$C_OK" "$GENERADOS" "$TOTAL" "$C_RESET"
else
    printf '%s✗ Canónicos generados: %d de %d%s\n' "$C_ERROR" "$GENERADOS" "$TOTAL" "$C_RESET"
    printf '  No se generaron (motivo arriba, en cada uno):\n'
    printf '    %s\n' "${FALLIDOS[@]}"
fi
if (( ${#CON_AVISOS[@]} > 0 )); then
    printf '  %s⚠ Con avisos de validación:%s\n' "$C_AVISO" "$C_RESET"
    printf '    %s\n' "${CON_AVISOS[@]}"
fi
if [[ "$VALIDAR" == "no" ]]; then
    printf '  %s⚠ Sin validar contra el esquema: ver el aviso del principio%s\n' "$C_AVISO" "$C_RESET"
fi
echo

if (( ${#FALLIDOS[@]} > 0 )); then
    exit "$SALIDA_FALLO"
fi

terminar
