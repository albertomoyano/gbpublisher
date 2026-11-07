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
# tmp/info-{base}.xml y tmp/biblio-{base}.xml de cada capítulo, el .bib del
# proyecto ya exportado y las siglas del libro ($RUTA_SIGLAS, comun.sh: la
# lee filters/siglas.lua). Todo lo que sale de la base llega como archivo. Este
# script no toca la base ({base} es nombre_archivo sin su prefijo fm-, a- o
# bm-: a-02-metodologia → 02-metodologia).
#
# POR CADA CAPÍTULO
#   0. controles_md.lua sobre el .md: lo que el Markdown deja pasar y llega
#      mal al impreso. Un hallazgo «error» frena el capítulo; un «aviso», no.
#      El mismo filtro lista los cuadros que nombra el .md. Ver «CONTROLES
#      DEL .md»
#   1. las huellas de las fuentes —el .md y sus cuadros— → tmp/huellas-{base}.xml.
#      Ver «HUELLAS»
#   2. pandoc con los filtros de libro → tmp/body-{base}.xml (con su envoltorio)
#   3. Saxon con ensamblar-capitulo-canonico.xsl → jats/c-{nombre}.xml,
#      escrito en un temporal y renombrado con mv: nunca queda en disco un
#      canónico a medio escribir (el mismo motivo que en ensamblar_libro.sh)
#
# LA LISTA DE SIGLAS (lista_abreviaturas, 1.18.0)
#   No tiene .md. Va después de las demás piezas del lote y lleva las siglas
#   que usan sus canónicos, con los datos de $RUTA_SIGLAS y la lista de piezas
#   de $RUTA_SIGLAS_PIEZAS (comun.sh). Ver procesar_lista_siglas.
#
# AL FINAL DEL LOTE
#   validar_canonicos.sh, anidado y UNA vez, con los canónicos que se
#   generaron (SC-75). Informativo: un canónico bien formado que no valida
#   se conserva, pero el aviso llega a Gambas como código 3.
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
# CONTROLES DEL .md
#
#   Corren en una pasada de pandoc propia, antes de la conversión y sin los
#   filtros de producción (criterio de SC-46). Los controles y su nivel están
#   en engine/controles_md.lua, que es donde se suman los nuevos; este script
#   solo lee el informe y no conoce ningún control por su nombre.
#
#   Los [WARNING] que Pandoc emite al LEER el .md (una nota definida y nunca
#   llamada, por ejemplo) son también aviso: salen en esta pasada, y en la de
#   conversión se omiten para no informarlos dos veces.
#   Lo mismo con el aviso de comillas de guillemets-to-quoted-db.lua: lo da
#   el control comillas_desbalanceadas y en la conversión se omite.
#
# HUELLAS (SC-75)
#
#   El canónico anota en su prólogo, en una <?gb-fuente archivo="…"
#   sha256="…"?> por archivo, la huella de cada fuente que se copia dentro de
#   él: el .md y los cuadros/{id}.md que nombra (los lista controles_md.lua en
#   tmp/fuentes-{base}.txt). Con eso vigencia_canonico (comun.sh) sabe si el
#   canónico corresponde todavía a sus fuentes; el ensamblado y el PDF frenan
#   si no.
#
#   Se calculan ANTES de pandoc, sobre los mismos archivos que pandoc va a
#   leer. Una ruta con comillas dobles se rechaza: el contenido de una PI no
#   se escapa y la comilla cortaría el valor.
#
# VALIDACIÓN
#
#   La hace validar_canonicos.sh, con las reglas de la pieza suelta: los
#   IDREF sin ID van en tenue, porque una pieza sola no puede resolver lo que
#   remite afuera de ella —las citas a la bibliografía consolidada y las
#   remisiones a otra pieza (SC-32, SC-53)—. Un IDREF colgado de verdad lo
#   marca la validación del libro en ensamblar_libro.sh, que sí avisa.
#
# CÓDIGOS DE SALIDA (comun.sh)
#   0  todos los capítulos generados y válidos
#   3  todos generados, alguno con avisos (de los controles, de pandoc o de
#      la validación)
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

XSL="$DIR_GBP_LOCAL/xslt/ensamblar-capitulo-canonico.xsl"
DIR_FILTROS="$DIR_GBP_LOCAL/filters"

# LA LISTA QUE ESTE SCRIPT LE PASA AL VALIDADOR, RELATIVA AL PROYECTO
LISTA_VALIDAR="tmp/lote-validar.txt"
# EL TIPO DE LA LISTA DE SIGLAS: NO SALE DE UN .md (procesar_lista_siglas)
TIPO_LISTA_SIGLAS="lista_abreviaturas"

# LA LISTA DE FILTROS, CON EL ORDEN Y SUS RAZONES, ESTÁ EN comun.sh
# (FILTROS_LIBRO): LA USA TAMBIÉN vista_cuadro.sh, QUE TIENE QUE PASAR EL
# CUADRO POR LOS MISMOS FILTROS QUE EL CAPÍTULO (SC-67)
FILTROS=("${FILTROS_LIBRO[@]}")

# EL ENVOLTORIO ES OBLIGATORIO: EL XSLT CARGA EL FRAGMENTO CON document() Y
# SIN LOS NAMESPACES DECLARADOS FALLA (RC-DB-06)
ENVOLTORIO_ABRE='<section xmlns="http://docbook.org/ns/docbook" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:xlink="http://www.w3.org/1999/xlink">'
ENVOLTORIO_CIERRA='</section>'

# fallo, escribir_huellas, controles_md Y filtrar_mensajes_pandoc VIVEN EN
# comun.sh: LAS COMPARTE generar_canonicos_articulos.sh, Y LOS CONTROLES Y LAS
# HUELLAS DE UN CAPÍTULO Y DE UN ARTÍCULO TIENEN QUE SER LOS MISMOS

# ============================================================================
# Función   : procesar_capitulo
# Propósito : Controles, huellas, pandoc y Saxon para un capítulo. La
#             validación la hace el lote al final.
# Parámetros: $1 nombre_archivo  $2 xml_id  $3 tipo_capitulo  $4 idioma
# Retorna   : 0 generado (con o sin avisos, que cuenta aviso()); 1 no generado
# ============================================================================
procesar_capitulo() {
    local nombre="$1" xml_id="$2" tipo="$3" idioma="$4"
    local base carpeta md info body biblio parcial
    local salida codigo filtro huellas
    local args_pandoc=()
    local lista_fuentes=()

    # --- A. RUTAS ---
    # EL NOMBRE SIN PREFIJO, COMO Mid(…, InStr(…, "-") + 1) EN GAMBAS
    base="${nombre#*-}"
    # LA REGLA PREFIJO → CARPETA VIVE EN comun.sh (carpeta_de_pieza)
    if ! carpeta="$(carpeta_de_pieza "$nombre")"; then
        fallo "prefijo no reconocido (se espera fm-, a- o bm-)"
        return 1
    fi

    md="$DIR_PROYECTO/$carpeta/$nombre.md"
    info="$DIR_PROYECTO/tmp/info-$base.xml"
    biblio="$DIR_PROYECTO/tmp/biblio-$base.xml"
    body="$DIR_PROYECTO/tmp/body-$base.xml"
    parcial="$body.parcial"

    # --- B. INSUMOS ---
    [[ -f "$md" ]] || { fallo "no existe $carpeta/$nombre.md"; return 1; }
    [[ -f "$info" ]] || { fallo "no existe tmp/info-$base.xml"; return 1; }
    bien_formado "$info" || { fallo "tmp/info-$base.xml está mal formado"; return 1; }
    [[ -f "$biblio" ]] || { fallo "no existe tmp/biblio-$base.xml"; return 1; }
    bien_formado "$biblio" || { fallo "tmp/biblio-$base.xml está mal formado"; return 1; }

    # --- C. CONTROLES DEL .md (comun.sh) ---
    controles_md "$md" "$carpeta/$nombre.md" "$base" || return 1

    # --- C2. HUELLAS (SC-75) ---
    # ANTES DE PANDOC: LA HUELLA ES DE LO QUE PANDOC VA A LEER
    huellas="$DIR_PROYECTO/tmp/huellas-$base.xml"
    lista_fuentes=("$carpeta/$nombre.md" "${CONTROLES_CUADROS[@]}")
    escribir_huellas "$huellas" "${lista_fuentes[@]}" || return 1
    ok "huellas de ${#lista_fuentes[@]} fuente(s)"

    # --- D. PANDOC ---
    # SE BORRA EL body ANTERIOR: SI ESTA CORRIDA FALLA, NO PUEDE QUEDAR EL
    # VIEJO PARA QUE ALGO LO TOME POR BUENO
    rm -f "$body" "$parcial" "$body.fallo"

    for filtro in "${FILTROS[@]}"; do
        args_pandoc+=(--lua-filter "$DIR_FILTROS/$filtro")
    done

    # --abbreviations: EL ESPACIO DURO DETRÁS DE pág., cap., n.º (SC-68)
    salida=$(timeout "$TIEMPO_PANDOC" pandoc "$md" \
                --from markdown --to docbook5 --mathml --no-highlight --wrap=none \
                --abbreviations "$RUTA_ABREVIATURAS" \
                "${args_pandoc[@]}" \
                --metadata gb-idioma-pieza="$idioma" \
                --metadata gb-proyecto="$DIR_PROYECTO" \
                --metadata gb-tipo-pieza="$tipo" \
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

    # LOS AVISOS DE PANDOC QUE NO FRENAN SE MUESTRAN PARA QUE NO SE PIERDAN,
    # SALVO LOS QUE YA SE INFORMARON EN LOS CONTROLES (comun.sh)
    salida="$(filtrar_mensajes_pandoc "$salida" "$CONTROLES_LECTURA")"
    if [[ -n "$salida" ]]; then
        tenue "mensajes de pandoc:"
        mostrar_cola "$salida" 10
    fi
    ok "cuerpo"

    # --- E. SAXON ---
    ensamblar_pieza "$nombre" "$xml_id" "$tipo" "$idioma" "$info" "$body" "$biblio" "$huellas" || return 1

    return 0
}

# ============================================================================
# Función   : ensamblar_pieza
# Propósito : Saxon con ensamblar-capitulo-canonico.xsl: info, cuerpo,
#             bibliografía y huellas → jats/c-{nombre}.xml, escrito en un
#             temporal y renombrado con mv. Es el paso común de las piezas que
#             salen de su .md (procesar_capitulo) y de la lista de siglas
#             (procesar_lista_siglas)
# Parámetros: $1 nombre_archivo  $2 xml_id  $3 tipo_capitulo  $4 idioma
#             $5 info  $6 body  $7 biblio  $8 huellas (rutas absolutas)
# Retorna   : 0 escrito; 1 no, con fallo() ya informado
# ============================================================================
ensamblar_pieza() {
    local nombre="$1" xml_id="$2" tipo="$3" idioma="$4"
    local info="$5" body="$6" biblio="$7" huellas="$8"
    local canonico temporal salida codigo

    canonico="$DIR_PROYECTO/jats/c-$nombre.xml"
    # EN LA MISMA CARPETA QUE EL DEFINITIVO: mv TIENE QUE SER UN RENOMBRE
    temporal="$DIR_PROYECTO/jats/.c-$nombre.xml.tmp"
    rm -f "$temporal"

    salida=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$info" \
                -xsl:"$XSL" \
                -o:"$temporal" \
                body="$body" \
                biblio="$biblio" \
                tipo_capitulo="$tipo" \
                xml_id_capitulo="$xml_id" \
                idioma="$idioma" \
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
    return 0
}

# ============================================================================
# Función   : xml_desarrollo
# Propósito : Un desarrollo del .tsv de siglas como contenido DocBook: escapa
#             & < > y pasa la cursiva *…* a <emphasis>. Lo mismo que hace
#             filters/siglas.lua en el texto
# Parámetros: $1 el desarrollo (los asteriscos van de a pares: lo controla
#             m_Siglas.AvisoEntrada al grabar)
# Retorna   : imprime el XML
# ============================================================================
xml_desarrollo() {
    local t="$1"
    t="${t//&/&amp;}"
    t="${t//</&lt;}"
    t="${t//>/&gt;}"
    printf '%s' "$t" | sed 's/\*\([^*]*\)\*/<emphasis>\1<\/emphasis>/g'
}

# ============================================================================
# Función   : procesar_lista_siglas
# Propósito : La lista de siglas del libro (lista_abreviaturas, 1.18.0). NO
#             SALE DE UN .md: lleva las siglas que usan los canónicos de las
#             piezas del libro (sus <?gb-sigla?>, claves_siglas_usadas en
#             comun.sh), con los datos de $RUTA_SIGLAS, que Gambas escribe
#             en el orden de la lista. Una sigla con dos significados en el
#             libro (PO) va en una sola entrada, con los desarrollos unidos
#             por « / ». El cuerpo pasa por la misma hoja que los capítulos
# Parámetros: $1 nombre_archivo  $2 xml_id  $3 tipo_capitulo  $4 idioma
# Retorna   : 0 generado; 1 no generado
# Nota      : CORRE DESPUÉS DE LAS DEMÁS PIEZAS DEL LOTE: SUS SIGLAS SALEN
#             DE LOS CANÓNICOS QUE EL LOTE ACABA DE ESCRIBIR. GAMBAS LA AGREGA
#             A TODO LOTE (m_GenerarSalidasLibro.LanzarCanonicos).
#             LA ANOTA EN <?gb-lista-siglas claves="…"?> PARA vigencia_canonico.
#             LA LISTA NO REPITE EL plural: SOLO EL DESARROLLO SINGULAR
#             (DECISIÓN DE ALBERTO, 31/10)
# ============================================================================
procesar_lista_siglas() {
    local nombre="$1" xml_id="$2" tipo="$3" idioma="$4"
    local base carpeta info biblio body parcial huellas
    local linea clave sigla desarrollo idioma_sigla resto contenido falta
    local sigla_actual="" definicion=""
    local entradas=() huellas_siglas=()
    local -A usadas=()
    local -A encontradas=()

    # --- A. RUTAS ---
    base="${nombre#*-}"
    if ! carpeta="$(carpeta_de_pieza "$nombre")"; then
        fallo "prefijo no reconocido (se espera fm-, a- o bm-)"
        return 1
    fi
    info="$DIR_PROYECTO/tmp/info-$base.xml"
    biblio="$DIR_PROYECTO/tmp/biblio-$base.xml"
    body="$DIR_PROYECTO/tmp/body-$base.xml"
    parcial="$body.parcial"
    huellas="$DIR_PROYECTO/tmp/huellas-$base.xml"

    # UN .md DE UNA LISTA ESCRITA A MANO NO SE USA: QUE NO PAREZCA QUE SÍ
    if [[ -f "$DIR_PROYECTO/$carpeta/$nombre.md" ]]; then
        aviso "$carpeta/$nombre.md no se usa: la lista sale de las siglas marcadas en los capítulos"
    fi

    # --- B. INSUMOS ---
    [[ -f "$info" ]] || { fallo "no existe tmp/info-$base.xml"; return 1; }
    bien_formado "$info" || { fallo "tmp/info-$base.xml está mal formado"; return 1; }
    [[ -f "$biblio" ]] || { fallo "no existe tmp/biblio-$base.xml"; return 1; }
    bien_formado "$biblio" || { fallo "tmp/biblio-$base.xml está mal formado"; return 1; }

    # --- C. LAS SIGLAS QUE USAN LOS CANÓNICOS ---
    if ! claves_siglas_usadas; then
        fallo "no está $RUTA_SIGLAS_PIEZAS: lo escribe gbpublisher al generar"
        return 1
    fi
    for falta in "${SIGLAS_FALTAN[@]}"; do
        aviso "falta $falta: sus siglas no entran a la lista"
    done
    if [[ -z "$SIGLAS_USADAS" ]]; then
        fallo "ningún capítulo usa siglas marcadas: la lista quedaría vacía. Marcá las siglas o quitá la pieza del libro"
        return 1
    fi
    for clave in $SIGLAS_USADAS; do usadas["$clave"]=1; done

    # --- D. LAS ENTRADAS, EN EL ORDEN DEL .tsv ---
    # LOS CAMPOS SE SEPARAN A MANO: CON IFS=$'\t', read JUNTA DOS TABULADORES
    # SEGUIDOS (EL TABULADOR ES ESPACIO PARA IFS) Y UN plural VACÍO CORRERÍA
    # EL idioma A SU LUGAR
    while IFS= read -r linea || [[ -n "$linea" ]]; do
        [[ -z "$linea" ]] && continue
        clave="${linea%%$'\t'*}"
        [[ -n "${usadas[$clave]+x}" ]] || continue
        resto="${linea#*$'\t'}"
        sigla="${resto%%$'\t'*}" ; resto="${resto#*$'\t'}"
        desarrollo="${resto%%$'\t'*}" ; resto="${resto#*$'\t'}"
        # EL plural NO VA EN LA LISTA
        resto="${resto#*$'\t'}"
        idioma_sigla="$resto"
        encontradas["$clave"]=1

        # CON IDIOMA YA SALE EN CURSIVA: ENTRE ASTERISCOS SALDRÍA EN REDONDA
        # (LO CONTROLA m_Siglas.AvisoIdioma AL GRABAR; ACÁ, LO GRABADO ANTES)
        if [[ -n "$idioma_sigla" && "$desarrollo" =~ ^\*[^*]+\*$ ]]; then
            fallo "la sigla $clave tiene idioma y el desarrollo entre asteriscos: con idioma ya va en cursiva. Sacá los asteriscos en Siglas, en el catálogo"
            return 1
        fi
        contenido="$(xml_desarrollo "$desarrollo")"
        if [[ -n "$idioma_sigla" ]]; then
            if [[ ! "$idioma_sigla" =~ ^[A-Za-z]{2,3}(-[A-Za-z0-9]+)*$ ]]; then
                fallo "la sigla $clave tiene un idioma ilegible: «$idioma_sigla»"
                return 1
            fi
            contenido="<foreignphrase xml:lang=\"$idioma_sigla\">$contenido</foreignphrase>"
        fi

        # LA MISMA SIGLA SEGUIDA (EL .tsv VIENE ORDENADO POR SIGLA): UNA
        # SOLA ENTRADA CON LOS DESARROLLOS UNIDOS
        if [[ "$sigla" == "$sigla_actual" ]]; then
            definicion+=" / $contenido"
        else
            [[ -n "$sigla_actual" ]] && entradas+=("$(entrada_lista_siglas "$sigla_actual" "$definicion")")
            sigla_actual="$sigla"
            definicion="$contenido"
        fi
        huellas_siglas+=("<?gb-sigla clave=\"$clave\" sha1=\"$(printf '%s' "$linea" | sha1sum | cut -d' ' -f1)\"?>")
    done < "$DIR_PROYECTO/$RUTA_SIGLAS"
    [[ -n "$sigla_actual" ]] && entradas+=("$(entrada_lista_siglas "$sigla_actual" "$definicion")")

    # UNA SIGLA QUE UN CANÓNICO USA Y EL LIBRO YA NO TIENE: ESE CANÓNICO ESTÁ
    # VIEJO (LO DICE SU VIGENCIA). LA LISTA SALE SIN ELLA
    for clave in $SIGLAS_USADAS; do
        [[ -n "${encontradas[$clave]+x}" ]] ||
            aviso "la sigla $clave la usa un canónico viejo y ya no está en el libro: regenerá ese capítulo"
    done
    if (( ${#entradas[@]} == 0 )); then
        fallo "ninguna de las siglas usadas está en el libro: regenerá los capítulos"
        return 1
    fi

    # --- E. EL CUERPO ---
    rm -f "$body" "$parcial"
    {
        printf '%s\n' "$ENVOLTORIO_ABRE"
        printf '<glosslist role="siglas">\n'
        printf '%s\n' "${entradas[@]}"
        printf '</glosslist>\n'
        printf '%s\n' "${huellas_siglas[@]}"
        printf '<?gb-lista-siglas claves="%s"?>\n' "$SIGLAS_USADAS"
        printf '%s\n' "$ENVOLTORIO_CIERRA"
    } > "$parcial" || { fallo "no se pudo escribir tmp/body-$base.xml"; return 1; }
    if ! bien_formado "$parcial"; then
        mv -f "$parcial" "$body.fallo"
        fallo "la lista de siglas quedó mal formada: tmp/body-$base.xml.fallo"
        return 1
    fi
    mv -f "$parcial" "$body"
    ok "lista de ${#entradas[@]} sigla(s)"

    # --- F. HUELLAS: NINGUNA FUENTE ---
    # SIN .md NO HAY gb-fuente. SU VIGENCIA ES LA DE SUS SIGLAS (comun.sh, C2 Y C3)
    escribir_huellas "$huellas" || return 1

    # --- G. SAXON ---
    ensamblar_pieza "$nombre" "$xml_id" "$tipo" "$idioma" "$info" "$body" "$biblio" "$huellas" || return 1
    return 0
}

# ============================================================================
# Función   : entrada_lista_siglas
# Propósito : Un <glossentry> de la lista de siglas
# Parámetros: $1 la sigla, sin escapar  $2 la definición, ya en XML
# Retorna   : imprime el XML
# ============================================================================
entrada_lista_siglas() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    printf '<glossentry><glossterm><acronym>%s</acronym></glossterm><glossdef><para>%s</para></glossdef></glossentry>' "$s" "$2"
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
[[ -f "$RUTA_ABREVIATURAS" ]] || morir "No se encontró la lista de abreviaturas: $RUTA_ABREVIATURAS"
# GAMBAS LO ESCRIBE SIEMPRE, VACÍO EN UN LIBRO SIN SIGLAS: SI FALTA, EL
# SCRIPT NO SE LANZÓ DESDE LA APLICACIÓN Y LAS SIGLAS PUEDEN SER VIEJAS
[[ -f "$DIR_PROYECTO/$RUTA_SIGLAS" ]] || morir "No está $RUTA_SIGLAS: lo escribe gbpublisher al generar. Generá desde la aplicación."
[[ -f "$DIR_PROYECTO/$RUTA_SIGLAS_PIEZAS" ]] || morir "No está $RUTA_SIGLAS_PIEZAS: lo escribe gbpublisher al generar. Generá desde la aplicación."

[[ -f "$DIR_ENGINE/controles_md.lua" ]] || morir "No se encontró el filtro de controles: $DIR_ENGINE/controles_md.lua"

ok "herramientas, hoja, filtros, controles y validador"

# EL VALIDADOR ES DEL LOTE: SI NO ESTÁ, NO SE EMPIEZA. VERIFICA ÉL MISMO SUS
# HERRAMIENTAS (jing, Saxon, LOS ESQUEMAS) Y AVISA SI FALTA ALGUNA
[[ -f "$DIR_ENGINE/validar_canonicos.sh" ]] || morir "No se encontró el validador: $DIR_ENGINE/validar_canonicos.sh"

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
# LOS QUE SE GENERARON, PARA EL VALIDADOR
GENERADOS_LISTA=()

# LA LISTA DE SIGLAS (lista_abreviaturas) VA AL FINAL, CUALQUIERA SEA SU
# LUGAR EN EL LIBRO: SUS SIGLAS SALEN DE LOS CANÓNICOS QUE EL LOTE ESCRIBE
# ANTES (procesar_lista_siglas)
ORDEN=()
for (( i = 0; i < TOTAL; i++ )); do
    [[ "${TIPOS[$i]}" == "$TIPO_LISTA_SIGLAS" ]] || ORDEN+=("$i")
done
for (( i = 0; i < TOTAL; i++ )); do
    [[ "${TIPOS[$i]}" == "$TIPO_LISTA_SIGLAS" ]] && ORDEN+=("$i")
done

for (( n = 0; n < TOTAL; n++ )); do
    i="${ORDEN[$n]}"
    nombre="${NOMBRES[$i]}"
    paso "$((n + 1))/$TOTAL  $nombre"

    avisos_antes=$AVISOS
    if [[ "${TIPOS[$i]}" == "$TIPO_LISTA_SIGLAS" ]]; then
        procesar_lista_siglas "$nombre" "${IDS[$i]}" "${TIPOS[$i]}" "${IDIOMAS[$i]}"
    else
        procesar_capitulo "$nombre" "${IDS[$i]}" "${TIPOS[$i]}" "${IDIOMAS[$i]}"
    fi
    if (( $? == 0 )); then
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

# --- 6. VALIDACIÓN DEL LOTE (SC-75) ---
# UNA SOLA LLAMADA CON TODOS LOS QUE SE GENERARON: jing Y EL SCHEMATRON CORREN
# UNA VEZ. INFORMATIVA: EL CANÓNICO SE CONSERVA, PERO LOS HALLAZGOS LLEGAN A
# GAMBAS COMO CÓDIGO 3. EL VALIDADOR CORRE EN OTRO PROCESO Y SUS AVISOS NO
# SUMAN ACÁ: EL CÓDIGO SE HEREDA CON UN aviso PROPIO, Y EL INFORME DICE QUÉ
# CAPÍTULO LOS TUVO
if (( GENERADOS > 0 )); then
    : > "$DIR_PROYECTO/$LISTA_VALIDAR" || morir "No se pudo escribir la lista del validador: $LISTA_VALIDAR"
    for nombre in "${GENERADOS_LISTA[@]}"; do
        printf 'jats/c-%s.xml\n' "$nombre" >> "$DIR_PROYECTO/$LISTA_VALIDAR"
    done

    GBP_ANIDADO=1 bash "$DIR_ENGINE/validar_canonicos.sh" "$DIR_PROYECTO" completo "$LISTA_VALIDAR"
    codigo=$?

    if (( codigo != SALIDA_OK )); then
        # LOS CAPÍTULOS CON UN aviso O UN fallo EN EL INFORME. awk CON
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

# --- 7. RESUMEN ---
# SOLO SE AFIRMA LO VERIFICADO: CADA ✓ DE ARRIBA LO DIJO xmllint, jing O EL
# SCHEMATRON
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
echo

if (( ${#FALLIDOS[@]} > 0 )); then
    exit "$SALIDA_FALLO"
fi

terminar
