#!/bin/bash
# Generador de los canónicos JATS de artículo — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
# Es el camino de los números nuevos de revista (SC-71, SC-72; etapa A0 de
# las salidas de revistas, claude/salidas-revistas.md). El camino viejo
# (m_XML, desde Gambas) queda para los números viejos hasta el 2.0.0.
#
# USO
#   generar_canonicos_articulos.sh <ruta_proyecto> <lista_rel>
#
#   ruta_proyecto   raíz del proyecto
#   lista_rel       ruta relativa al proyecto de la lista de artículos. Un
#                   nombre_archivo por línea, sin .md:
#
#                     a-01-ciudad
#
#                   Uno solo para «Canónico archivo en curso»; todos los del
#                   número para «Todos los canónicos». El script no
#                   distingue: procesa lo que la lista declara, en ese orden.
#
# LOS INSUMOS LOS ESCRIBE GAMBAS ANTES DE LANZAR ESTE SCRIPT
# (m_CanonicoRevista.PrepararNumero): la lista, el volcado del número
# (tmp/numero-datos.xml) y tmp/reflist-{base}.xml de cada artículo de la
# lista. Todo lo que sale de la base llega como archivo: este script no toca
# la base. El idioma de cada artículo lo lee del volcado, que es la única
# fuente ({base} es nombre_archivo sin su prefijo a-: a-01-ciudad →
# 01-ciudad, como Mid(nombre, 3) en Gambas).
#
# POR CADA ARTÍCULO
#   0. controles_md.lua sobre el .md (controles_md, comun.sh): los mismos
#      controles que un capítulo de libro (decisión de Alberto, 07/11). Un
#      hallazgo «error» frena el artículo; un «aviso», no. El mismo filtro
#      lista los cuadros que nombra el .md
#   1. las huellas de las fuentes —el .md y sus cuadros— →
#      tmp/huellas-{base}.xml (SC-75). El canónico las anota en su prólogo;
#      la verificación de vigencia la suman las salidas (decisión de
#      Alberto, 07/11)
#   2. pandoc con los filtros de revista (FILTROS_REVISTA, comun.sh) →
#      tmp/body-{base}.xml, con su envoltorio
#   3. Saxon con ensamblar-articulo-canonico.xsl: el front sale del volcado,
#      el body del paso 2, el back del reflist → jats/c-{nombre}.xml,
#      escrito en un temporal y renombrado con mv: nunca queda en disco un
#      canónico a medio escribir
#
# AL EMPEZAR EL LOTE
#   Los .md de articulos/ que la base no tiene (<sin-metadatos> del volcado)
#   y los artículos de la base sin su .md (<huerfano>) son aviso: no frenan
#   a los demás, pero el editor tiene que saberlo.
#
# AL FINAL DEL LOTE
#   validar_canonicos.sh, anidado y UNA vez, con los canónicos que se
#   generaron: bien formado, vigencia, recursos, la DTD de JATS 1.4 y las
#   reglas de JATS4R. Informativo: un canónico bien formado que no valida se
#   conserva, pero el aviso llega a Gambas como código 3.
# ============================================================================
# QUÉ PASA CUANDO UN ARTÍCULO FALLA
#
#   Lo mismo que con un capítulo: se sigue con los demás, al final se listan
#   todos los que fallaron, y el canónico anterior de ESE artículo SE BORRA.
#   Si no se regeneró, no corresponde a su .md, y una salida lo tomaría igual,
#   sin aviso. El canónico se reconstruye siempre desde el .md y la base: no
#   se pierde nada que no se pueda regenerar.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  todos los artículos generados y válidos
#   3  todos generados, alguno con avisos (de los controles, de pandoc, del
#      volcado o de la validación)
#   1  al menos un artículo no se generó, o el lote no pudo empezar
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

XSL="$DIR_GBP_LOCAL/xslt/ensamblar-articulo-canonico.xsl"
DIR_FILTROS="$DIR_GBP_LOCAL/filters"

# EL VOLCADO DEL NÚMERO: LA MISMA RUTA QUE m_CanonicoRevista.ARCHIVO_DATOS, Y
# LA VERSIÓN QUE LEE LA HOJA (m_CanonicoRevista.VERSION_DATOS). SI CAMBIAN
# ALLÁ, CAMBIAN ACÁ. LA 2 (11/11/2026) SUMA LOS NOMBRES DE babel
VOLCADO_REL="tmp/numero-datos.xml"
VERSION_DATOS="2"

# LA LISTA QUE ESTE SCRIPT LE PASA AL VALIDADOR, RELATIVA AL PROYECTO
LISTA_VALIDAR="tmp/lote-validar.txt"

# LA LISTA DE FILTROS, CON EL ORDEN Y SUS RAZONES, ESTÁ EN comun.sh
# (FILTROS_REVISTA): LA USA TAMBIÉN vista_cuadro.sh, QUE TIENE QUE PASAR EL
# CUADRO POR LOS MISMOS FILTROS QUE EL ARTÍCULO (SC-67)
FILTROS=("${FILTROS_REVISTA[@]}")

# EL ENVOLTORIO ES OBLIGATORIO: LA HOJA CARGA EL FRAGMENTO CON document() Y
# SIN EL NAMESPACE DECLARADO FALLA. ES EL MISMO DE m_XML.GenerarBodyXML
ENVOLTORIO_ABRE='<body xmlns:xlink="http://www.w3.org/1999/xlink">'
ENVOLTORIO_CIERRA='</body>'

# ============================================================================
# Función   : dato_volcado
# Propósito : Un valor del volcado, por XPath.
# Parámetros: $1 expresión XPath que devuelve una cadena o un número
# Retorna   : imprime el valor; vacío si no hay
# ============================================================================
dato_volcado() {
    xmllint --xpath "$1" "$VOLCADO" 2>/dev/null
}

# ============================================================================
# Función   : idioma_pandoc
# Propósito : El idioma que va a pandoc como -M gb-idioma: el del artículo en
#             el volcado, si son letras ASCII y guiones; si no, «es». La misma
#             regla que m_XML.ArgumentoIdiomaPandoc, que es también lo que
#             hacen los filtros con un idioma fuera de su tabla
# Parámetros: $1 el idioma del volcado
# Retorna   : imprime el idioma
# ============================================================================
idioma_pandoc() {
    if [[ "$1" =~ ^[A-Za-z-]+$ ]]; then
        printf '%s' "$1"
    else
        printf 'es'
    fi
}

# ============================================================================
# Función   : procesar_articulo
# Propósito : Controles, huellas, pandoc y Saxon para un artículo. La
#             validación la hace el lote al final.
# Parámetros: $1 nombre_archivo
# Retorna   : 0 generado (con o sin avisos, que cuenta aviso()); 1 no generado
# ============================================================================
procesar_articulo() {
    local nombre="$1"
    local base md reflist body parcial huellas canonico temporal
    local idioma salida codigo filtro
    local args_pandoc=()
    local lista_fuentes=()

    # --- A. RUTAS ---
    base="${nombre#a-}"
    md="$DIR_PROYECTO/articulos/$nombre.md"
    reflist="$DIR_PROYECTO/tmp/reflist-$base.xml"
    body="$DIR_PROYECTO/tmp/body-$base.xml"
    parcial="$body.parcial"
    huellas="$DIR_PROYECTO/tmp/huellas-$base.xml"

    # --- B. INSUMOS ---
    [[ -f "$md" ]] || { fallo "no existe articulos/$nombre.md"; return 1; }
    # EL NOMBRE VA A UNA EXPRESIÓN XPath ENTRE COMILLAS DOBLES: LA LECTURA DE
    # LA LISTA YA RECHAZÓ LAS COMILLAS
    if [[ "$(dato_volcado "count(/numero-datos/sin-metadatos[@archivo=\"$nombre\"])")" != "0" ]]; then
        fallo "el artículo no tiene metadatos en la base: cargalo en el formulario del artículo"
        return 1
    fi
    if [[ "$(dato_volcado "count(/numero-datos/articulo[@archivo=\"$nombre\"])")" != "1" ]]; then
        fallo "el volcado del número no tiene este artículo: generá desde la aplicación"
        return 1
    fi
    [[ -f "$reflist" ]] || { fallo "no existe tmp/reflist-$base.xml"; return 1; }
    bien_formado "$reflist" || { fallo "tmp/reflist-$base.xml está mal formado"; return 1; }

    idioma="$(idioma_pandoc "$(dato_volcado "string(/numero-datos/articulo[@archivo=\"$nombre\"]/@idioma)")")"

    # --- C. CONTROLES DEL .md (comun.sh) ---
    controles_md "$md" "articulos/$nombre.md" "$base" || return 1

    # --- C2. HUELLAS (SC-75) ---
    # ANTES DE PANDOC: LA HUELLA ES DE LO QUE PANDOC VA A LEER
    lista_fuentes=("articulos/$nombre.md" "${CONTROLES_CUADROS[@]}")
    escribir_huellas "$huellas" "${lista_fuentes[@]}" || return 1
    ok "huellas de ${#lista_fuentes[@]} fuente(s)"

    # --- D. PANDOC ---
    # SE BORRA EL body ANTERIOR: SI ESTA CORRIDA FALLA, NO PUEDE QUEDAR EL
    # VIEJO PARA QUE ALGO LO TOME POR BUENO
    rm -f "$body" "$parcial" "$body.fallo"

    for filtro in "${FILTROS[@]}"; do
        args_pandoc+=(--lua-filter "$DIR_FILTROS/$filtro")
    done

    # LOS ARGUMENTOS SON LOS DE m_XML.GenerarBodyXML: --abbreviations PONE EL
    # ESPACIO DURO DETRÁS DE pág., cap., n.º (SC-68); gb-idioma LO LEEN
    # volada, cifras Y conversacion; gb-proyecto, cuadro-leer
    salida=$(timeout "$TIEMPO_PANDOC" pandoc "$md" \
                --from markdown --to jats --no-highlight --wrap=none \
                --abbreviations "$RUTA_ABREVIATURAS" \
                "${args_pandoc[@]}" \
                --metadata gb-idioma="$idioma" \
                --metadata gb-proyecto="$DIR_PROYECTO" \
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
        fallo "pandoc rechazó articulos/$nombre.md"
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

    # LOS AVISOS DE PANDOC QUE NO FRENAN SE MUESTRAN PARA QUE NO SE PIERDAN,
    # SALVO LOS QUE YA SE INFORMARON EN LOS CONTROLES (comun.sh)
    salida="$(filtrar_mensajes_pandoc "$salida" "$CONTROLES_LECTURA")"
    if [[ -n "$salida" ]]; then
        tenue "mensajes de pandoc:"
        mostrar_cola "$salida" 10
    fi
    ok "cuerpo"

    # --- E. SAXON ---
    canonico="$DIR_PROYECTO/jats/c-$nombre.xml"
    # EN LA MISMA CARPETA QUE EL DEFINITIVO: mv TIENE QUE SER UN RENOMBRE
    temporal="$DIR_PROYECTO/jats/.c-$nombre.xml.tmp"
    rm -f "$temporal"

    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$VOLCADO" \
                -xsl:"$XSL" \
                -o:"$temporal" \
                archivo="$nombre" \
                body="$body" \
                reflist="$reflist" \
                huellas="$huellas" 2>&1)
    codigo=$?

    if (( codigo == 124 )); then
        rm -f "$temporal"
        fallo "Saxon no terminó en $TIEMPO_SAXON segundos"
        return 1
    fi
    if (( codigo != 0 )); then
        mostrar_cola "$salida"
        rm -f "$temporal"
        fallo "Saxon no pudo ensamblar el artículo"
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
    return 0
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "CANÓNICOS DE ARTÍCULO"

# --- 2. ARGUMENTOS ---
if (( $# < 2 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <lista_rel>"
fi

DIR_PROYECTO="${1%/}"
LISTA="$DIR_PROYECTO/$2"
VOLCADO="$DIR_PROYECTO/$VOLCADO_REL"

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]           || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/articulos" ]] || morir "El proyecto no tiene carpeta articulos/"
[[ -d "$DIR_PROYECTO/jats" ]]      || morir "El proyecto no tiene carpeta jats/"
[[ -d "$DIR_PROYECTO/tmp" ]]       || morir "El proyecto no tiene carpeta tmp/"

requerir_comandos pandoc java xmllint timeout sha256sum

[[ -f "$RUTA_SAXON" ]] || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$XSL" ]]        || morir "No se encontró la hoja de ensamblado: $XSL"

faltan=()
for filtro in "${FILTROS[@]}"; do
    [[ -f "$DIR_FILTROS/$filtro" ]] || faltan+=("$filtro")
done
if (( ${#faltan[@]} > 0 )); then
    morir "Faltan filtros en $DIR_FILTROS: ${faltan[*]}"
fi
[[ -f "$RUTA_ABREVIATURAS" ]] || morir "No se encontró la lista de abreviaturas: $RUTA_ABREVIATURAS"
[[ -f "$DIR_ENGINE/controles_md.lua" ]] || morir "No se encontró el filtro de controles: $DIR_ENGINE/controles_md.lua"

# EL VALIDADOR ES DEL LOTE: SI NO ESTÁ, NO SE EMPIEZA. VERIFICA ÉL MISMO SUS
# HERRAMIENTAS (LA DTD, Saxon, LAS REGLAS DE JATS4R) Y AVISA SI FALTA ALGUNA
[[ -f "$DIR_ENGINE/validar_canonicos.sh" ]] || morir "No se encontró el validador: $DIR_ENGINE/validar_canonicos.sh"

ok "herramientas, hoja, filtros, controles y validador"

# --- 4. EL VOLCADO DEL NÚMERO ---
# LO ESCRIBE GAMBAS JUSTO ANTES DE LANZAR ESTE SCRIPT: SI FALTA, EL SCRIPT NO
# SE LANZÓ DESDE LA APLICACIÓN Y LOS DATOS PUEDEN SER VIEJOS
paso "leyendo el volcado del número"

[[ -f "$VOLCADO" ]] || morir "No está $VOLCADO_REL: lo escribe gbpublisher al generar. Generá desde la aplicación."
bien_formado "$VOLCADO" || morir "$VOLCADO_REL está mal formado"
[[ "$(dato_volcado 'local-name(/*)')" == "numero-datos" ]] || morir "$VOLCADO_REL no es un volcado del número"
version="$(dato_volcado 'string(/numero-datos/@version)')"
[[ "$version" == "$VERSION_DATOS" ]] ||
    morir "$VOLCADO_REL es versión «$version» y este script lee la $VERSION_DATOS: actualizá gbpublisher"

ok "$(dato_volcado 'count(/numero-datos/articulo)') artículo(s) en el número"

# LO QUE NO CIERRA ENTRE EL DISCO Y LA BASE: AVISO, UNA VEZ POR LOTE. LOS
# NOMBRES VIENEN COMO ATRIBUTOS SERIALIZADOS: SE RECORTAN CON grep -oP
DEL_NUMERO=()
while IFS= read -r archivo; do
    [[ -z "$archivo" ]] && continue
    aviso "articulos/$archivo.md no tiene metadatos en la base: no entra al número"
    DEL_NUMERO+=("articulos/$archivo.md: sin metadatos en la base")
done < <(dato_volcado '/numero-datos/sin-metadatos/@archivo' | grep -oP 'archivo="\K[^"]*')
while IFS= read -r archivo; do
    [[ -z "$archivo" ]] && continue
    aviso "el artículo «$archivo» está en la base y no tiene su .md en articulos/"
    DEL_NUMERO+=("$archivo: en la base, sin su .md")
done < <(dato_volcado '/numero-datos/huerfano/@archivo' | grep -oP 'archivo="\K[^"]*')

# --- 5. LISTA ---
paso "leyendo la lista de artículos"

[[ -f "$LISTA" ]] || morir "No existe la lista de artículos: $LISTA"

NOMBRES=()
numero_linea=0
while IFS= read -r nombre || [[ -n "$nombre" ]]; do
    numero_linea=$((numero_linea + 1))
    nombre="${nombre%$'\r'}"
    [[ -z "$nombre" ]] && continue
    # UN NOMBRE CON / SALDRÍA DE LA CARPETA DEL PROYECTO; UNO CON OTROS
    # CARACTERES ROMPERÍA LA EXPRESIÓN XPath DEL VOLCADO. EL PREFIJO a- ES EL
    # DE LOS ARTÍCULOS: SIN ÉL, {base} NO SALE IGUAL QUE EN GAMBAS
    if [[ ! "$nombre" =~ ^a-[A-Za-z0-9._-]+$ || "$nombre" == *.md ]]; then
        morir "Línea $numero_linea de la lista mal formada: «$nombre» (se espera a-…, sin .md)"
    fi
    NOMBRES+=("$nombre")
done < "$LISTA"

TOTAL=${#NOMBRES[@]}
(( TOTAL > 0 )) || morir "La lista no declara ningún artículo"
ok "$TOTAL artículo(s)"

# --- 6. LOTE ---
GENERADOS=0
CON_AVISOS=()
FALLIDOS=()
# LOS QUE SE GENERARON, PARA EL VALIDADOR
GENERADOS_LISTA=()

for (( n = 0; n < TOTAL; n++ )); do
    nombre="${NOMBRES[$n]}"
    paso "$((n + 1))/$TOTAL  $nombre"

    avisos_antes=$AVISOS
    if procesar_articulo "$nombre"; then
        GENERADOS=$((GENERADOS + 1))
        GENERADOS_LISTA+=("$nombre")
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

# --- 7. VALIDACIÓN DEL LOTE ---
# UNA SOLA LLAMADA CON TODOS LOS QUE SE GENERARON: Saxon CORRE UNA VEZ PARA
# JATS4R. INFORMATIVA: EL CANÓNICO SE CONSERVA, PERO LOS HALLAZGOS LLEGAN A
# GAMBAS COMO CÓDIGO 3. EL VALIDADOR CORRE EN OTRO PROCESO Y SUS AVISOS NO
# SUMAN ACÁ: EL CÓDIGO SE HEREDA CON UN aviso PROPIO, Y EL INFORME DICE QUÉ
# ARTÍCULO LOS TUVO
if (( GENERADOS > 0 )); then
    : > "$DIR_PROYECTO/$LISTA_VALIDAR" || morir "No se pudo escribir la lista del validador: $LISTA_VALIDAR"
    for nombre in "${GENERADOS_LISTA[@]}"; do
        printf 'jats/c-%s.xml\n' "$nombre" >> "$DIR_PROYECTO/$LISTA_VALIDAR"
    done

    GBP_ANIDADO=1 bash "$DIR_ENGINE/validar_canonicos.sh" "$DIR_PROYECTO" completo "$LISTA_VALIDAR"
    codigo=$?

    if (( codigo != SALIDA_OK )); then
        # LOS ARTÍCULOS CON UN aviso O UN fallo EN EL INFORME. awk CON
        # IGUALDAD EXACTA: EL NOMBRE NO ES UNA EXPRESIÓN REGULAR
        for nombre in "${GENERADOS_LISTA[@]}"; do
            if awk -F '\t' -v a="jats/c-$nombre.xml" '$1 == a && ($3 == "aviso" || $3 == "fallo") { e = 1 } END { exit !e }' \
                   "$DIR_PROYECTO/tmp/validacion.tsv" 2>/dev/null; then
                [[ " ${CON_AVISOS[*]} " == *" $nombre "* ]] || CON_AVISOS+=("$nombre")
            fi
        done
        if (( codigo == SALIDA_AVISOS )); then
            aviso "la validación encontró hallazgos: los canónicos se conservan"
        else
            aviso "la validación no pudo completarse (código $codigo): los canónicos se conservan, pero no se dan por válidos"
        fi
    fi
fi

# --- 8. RESUMEN ---
# SOLO SE AFIRMA LO VERIFICADO: CADA ✓ DE ARRIBA LO DIJO xmllint, LA DTD O
# JATS4R
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
    printf '  %s⚠ Con avisos (de los controles, de pandoc o de la validación):%s\n' "$C_AVISO" "$C_RESET"
    printf '    %s\n' "${CON_AVISOS[@]}"
fi
# LOS AVISOS DEL VOLCADO NO SON DE NINGÚN ARTÍCULO DE LA LISTA: SIN ESTA
# LÍNEA, EL CÓDIGO 3 LLEGARÍA SIN NADA EN EL RESUMEN QUE LO EXPLIQUE
if (( ${#DEL_NUMERO[@]} > 0 )); then
    printf '  %s⚠ Del número (no cierran el disco y la base):%s\n' "$C_AVISO" "$C_RESET"
    printf '    %s\n' "${DEL_NUMERO[@]}"
fi
echo

if (( ${#FALLIDOS[@]} > 0 )); then
    exit "$SALIDA_FALLO"
fi

terminar
