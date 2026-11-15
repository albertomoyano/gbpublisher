#!/bin/bash
# Validador de la solapa «Validaciones» para los tipos de revista — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
#
# USO
#   validar_sabor.sh <tipo> <ruta_proyecto> <archivo> [<archivo>...]
#
#   tipo            jats4r, doaj (los demás llegan con sus sabores:
#                   crossref, redalyc, scielo, pmc)
#   ruta_proyecto   raíz del proyecto
#   archivo         ruta absoluta de cada archivo a validar, dentro del
#                   proyecto. Un lote es UNA llamada (SC-53)
#
# LO LLAMA m_Validaciones (Exec con array, SC-05), no la terminal. Por eso la
# salida de lo que corre adentro va a un registro y no a la pantalla: stdout
# es el contrato.
#
# CONTRATO DE SALIDA (stdout, el mismo de validar_pdf.pl)
#   un registro por línea, siete campos separados por NUL:
#     objeto  grupo  comprobacion  estado  encontrado  esperado  detalle
#   objeto  el nombre del archivo, como lo muestra el combo
#   estado  OK | AVISO | ERROR | INFO
#
# TIPO jats4r
#   No valida un sabor: valida el canónico (SC-72). Corre
#   validar_canonicos.sh anidado, en modo completo, sobre la lista, y traduce
#   su informe (tmp/validacion.tsv) y los informes SVRL de JATS4R
#   (tmp/validar-jats-svrl/) al contrato. No repite ninguna validación: una
#   sola regla de qué es válido (SC-75).
#
#   Los niveles del informe pasan así:
#     ok → OK · aviso → AVISO · fallo → ERROR · tenue → INFO
#     no_ejecutado → AVISO (lo que no se comprobó no está bien, GV-23)
#   Y los de JATS4R, por @role (GV-27): error → AVISO; warning e info → INFO.
#   Un hallazgo de JATS4R es informativo, como en el validador.
#
# TIPO doaj
#   El archivo del número (salidas/doaj/doaj-{número}.xml, de
#   generar_doaj_revista.sh). Primero el esquema de DOAJ, sin red
#   (validar_doaj, revista_comun.sh): lo que no valida, DOAJ lo rechaza, y es
#   ERROR. Después, por cada record, lo que el esquema no mira y DOAJ usa:
#   el texto completo y el DOI (identifican el artículo en DOAJ), el idioma
#   (sin código ISO 639-2/B el record sale sin idioma), y cuántos títulos,
#   autores, resúmenes y grupos de palabras clave lleva. El grupo de esas
#   filas es el publisherRecordId: el nombre del artículo.
#
# CÓDIGOS
#   0  hubo registros: los hallazgos van en ellos, no en el código
#   1  no se pudo validar (argumentos, entorno, el validador no dejó informe).
#      El motivo va a stderr y Gambas lo muestra (GV-23)
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi
# LOS ESQUEMAS DE LOS SABORES (esquema_doaj_presente, validar_doaj)
if ! source "$DIR_ENGINE/revista_comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/revista_comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
# CUÁNTAS UBICACIONES DE UN MISMO HALLAZGO VAN AL DETALLE
UBICACIONES_POR_HALLAZGO=5

# ============================================================================
# Función   : registro
# Propósito : Escribe un registro del contrato en stdout.
# Parámetros: $1 objeto  $2 grupo  $3 comprobacion  $4 estado  $5 encontrado
#             $6 esperado  $7 detalle
# Nota      : printf CON %s Y \0: NINGÚN CAMPO SE INTERPRETA. UN SALTO DE
#             LÍNEA DENTRO DE UN CAMPO PARTIRÍA EL REGISTRO: SE CAMBIA POR
#             UN ESPACIO
# ============================================================================
registro() {
    local campo campos=()
    for campo in "$@"; do
        campo="${campo//$'\n'/ }"
        campo="${campo//$'\r'/ }"
        campos+=("$campo")
    done
    printf '%s\0%s\0%s\0%s\0%s\0%s\0%s\n' "${campos[@]}"
}

# ============================================================================
# Función   : estado_de_nivel
# Propósito : El nivel del informe de validar_canonicos.sh, como estado del
#             contrato.
# Parámetros: $1 ok | aviso | tenue | fallo | no_ejecutado
# Retorna   : imprime el estado
# ============================================================================
estado_de_nivel() {
    case "$1" in
        ok)    printf 'OK' ;;
        tenue) printf 'INFO' ;;
        fallo) printf 'ERROR' ;;
        # aviso, no_ejecutado Y CUALQUIER OTRO: UN NIVEL DESCONOCIDO NO PUEDE
        # PASAR POR BUENO
        *)     printf 'AVISO' ;;
    esac
}

# ============================================================================
# Función   : decodificar
# Propósito : Las cinco entidades predefinidas de XML a su carácter (los
#             textos del SVRL llegan serializados por xmllint).
# Parámetros: $1 texto
# Retorna   : imprime el texto
# Nota      : &amp; AL FINAL, COMO EN validar_canonicos.sh
# ============================================================================
decodificar() {
    local t="$1"
    t="${t//&lt;/<}"
    t="${t//&gt;/>}"
    t="${t//&quot;/\"}"
    t="${t//&apos;/\'}"
    t="${t//&amp;/&}"
    printf '%s' "$t"
}

# ============================================================================
# Función   : hallazgos_jats4r
# Propósito : Un registro por mensaje distinto de un informe SVRL de JATS4R,
#             con la cantidad y las primeras ubicaciones.
# Parámetros: $1 objeto  $2 ruta del informe SVRL
# Nota      : xmllint CON XPath 1.0, UN HALLAZGO POR VUELTA: EL SVRL DE UN
#             ARTÍCULO TIENE POCOS, Y ASÍ NO HACE FALTA OTRA JVM. LOS ELEMENTOS
#             SE NOMBRAN POR local-name(): EL SVRL TRAE SU ESPACIO DE NOMBRES
# ============================================================================
hallazgos_jats4r() {
    local objeto="$1" svrl="$2"
    local sel="(//*[local-name()='failed-assert' or local-name()='successful-report'])"
    local total i rol patron ubicacion texto estado
    local -A CANTIDAD=() ESTADO=() PATRON=() UBICACIONES=()
    local -a ORDEN=()

    total=$(xmllint --xpath "count($sel)" "$svrl" 2>/dev/null)
    [[ "$total" =~ ^[0-9]+$ ]] || return 0

    for (( i = 1; i <= total; i++ )); do
        rol=$(xmllint --xpath "string($sel[$i]/@role)" "$svrl" 2>/dev/null)
        ubicacion=$(xmllint --xpath "string($sel[$i]/@location)" "$svrl" 2>/dev/null)
        # EL PATRÓN ES EL active-pattern ANTERIOR MÁS CERCANO: EN EL SVRL, LOS
        # HALLAZGOS VAN DESPUÉS DEL PATRÓN QUE LOS PRODUJO
        patron=$(xmllint --xpath "string($sel[$i]/preceding-sibling::*[local-name()='active-pattern'][1]/@id)" "$svrl" 2>/dev/null)
        texto=$(xmllint --xpath "string($sel[$i]/*[local-name()='text'])" "$svrl" 2>/dev/null |
                tr '\n' ' ' | tr -s ' ' | sed 's/^ //;s/ $//')
        texto="$(decodificar "$texto")"
        [[ -n "$texto" ]] || texto="(sin texto en el informe)"

        # GV-27: error ES AVISO; warning E info, INFO. UN role QUE NO ES
        # NINGUNO DE LOS DOS SEGUNDOS CUENTA COMO error, COMO EN EL VALIDADOR
        if [[ "$rol" == "warning" || "$rol" == "info" ]]; then
            estado="INFO"
        else
            estado="AVISO"
        fi

        if [[ -z "${CANTIDAD[$texto]:-}" ]]; then
            ORDEN+=("$texto")
            CANTIDAD[$texto]=0
            ESTADO[$texto]="$estado"
            PATRON[$texto]="$patron"
            UBICACIONES[$texto]=""
        fi
        CANTIDAD[$texto]=$(( ${CANTIDAD[$texto]} + 1 ))
        # UN MENSAJE CON AVISO Y CON INFO (NO DEBERÍA PASAR) QUEDA EN AVISO
        [[ "$estado" == "AVISO" ]] && ESTADO[$texto]="AVISO"
        if (( ${CANTIDAD[$texto]} <= UBICACIONES_POR_HALLAZGO )); then
            UBICACIONES[$texto]+="${UBICACIONES[$texto]:+ · }$ubicacion"
        fi
    done

    for texto in "${ORDEN[@]}"; do
        local detalle="Patrón de JATS4R: ${PATRON[$texto]:-?}."
        [[ -n "${UBICACIONES[$texto]}" ]] && detalle+=" En: ${UBICACIONES[$texto]}"
        (( ${CANTIDAD[$texto]} > UBICACIONES_POR_HALLAZGO )) &&
            detalle+=" (y $(( ${CANTIDAD[$texto]} - UBICACIONES_POR_HALLAZGO )) más)"
        registro "$objeto" jats4r "$texto" "${ESTADO[$texto]}" \
            "${CANTIDAD[$texto]} ×" "" "$detalle"
    done
}

# ============================================================================
# Función   : validar_jats4r
# Propósito : El tipo jats4r: validar_canonicos.sh anidado y su informe
#             traducido al contrato.
# Parámetros: los archivos (rutas absolutas)
# ============================================================================
validar_jats4r() {
    local abs rel nombre lista registro_log codigo
    local archivo capa nivel mensaje comprobacion grupo estado
    local -a RELATIVOS=()
    local -A OBJETO=()

    # --- A. LA LISTA, RELATIVA AL PROYECTO (EL CONTRATO DEL VALIDADOR) ---
    for abs in "$@"; do
        # LA MISMA FORMA QUE DIR_PROYECTO: UN ENLACE EN LA RUTA NO PUEDE
        # DEJAR UN ARCHIVO «FUERA» DEL PROYECTO
        abs="$(readlink -f "$abs")"
        [[ "$abs" == "$DIR_PROYECTO/"* ]] || morir "El archivo no está dentro del proyecto: $abs"
        rel="${abs#"$DIR_PROYECTO/"}"
        RELATIVOS+=("$rel")
        OBJETO[$rel]="$(basename "$abs")"
    done

    lista="tmp/validar-sabor-lista.txt"
    printf '%s\n' "${RELATIVOS[@]}" > "$DIR_PROYECTO/$lista" ||
        morir "No se pudo escribir la lista: $lista"

    # --- B. EL VALIDADOR, ANIDADO (SC-53) ---
    # SU SALIDA VA A UN REGISTRO: stdout ES EL CONTRATO. 0 Y 3 SON CORRIDAS
    # COMPLETAS; 1 PUEDE SER UN ARCHIVO QUE NO SE PUDO VALIDAR (QUEDA EN EL
    # INFORME) O UN LOTE QUE NO EMPEZÓ (NO HAY INFORME)
    registro_log="$DIR_PROYECTO/tmp/validar-sabor.log"
    : > "$DIR_PROYECTO/tmp/validacion.tsv" 2>/dev/null
    GBP_ANIDADO=1 bash "$DIR_ENGINE/validar_canonicos.sh" "$DIR_PROYECTO" completo "$lista" \
        > "$registro_log" 2>&1
    codigo=$?

    if [[ ! -s "$DIR_PROYECTO/tmp/validacion.tsv" ]]; then
        {
            echo "El validador de canónicos no dejó informe (código $codigo)."
            tail -8 "$registro_log" 2>/dev/null
        } >&2
        exit 1
    fi

    # --- C. EL INFORME, LÍNEA POR LÍNEA ---
    while IFS=$'\t' read -r archivo capa nivel mensaje; do
        estado="$(estado_de_nivel "$nivel")"

        # LO QUE FALTA DEL ENTORNO NO ES DE UN ARCHIVO: VA EN TODOS, PORQUE EN
        # TODOS DEJA ALGO SIN COMPROBAR
        if [[ "$archivo" == "-" ]]; then
            for rel in "${RELATIVOS[@]}"; do
                registro "${OBJETO[$rel]}" entorno "Entorno" "$estado" "$mensaje" "" ""
            done
            continue
        fi

        nombre="${OBJETO[$archivo]:-}"
        [[ -n "$nombre" ]] || continue

        # LA CAPA jats JUNTA LA DTD Y JATS4R: SE SEPARAN POR EL TEXTO, QUE
        # NOMBRA SIEMPRE A UNA DE LAS DOS (validar_canonicos.sh, capa_jats)
        case "$capa" in
            bien_formado) grupo="canonico"; comprobacion="Bien formado" ;;
            vigencia)     grupo="canonico"; comprobacion="Vigencia" ;;
            recursos)     grupo="canonico"; comprobacion="Imágenes" ;;
            docbook)      grupo="canonico"; comprobacion="Raíz" ;;
            jats)
                grupo="jats"
                if [[ "$mensaje" == *JATS4R* ]]; then
                    if [[ "$nivel" == "tenue" ]]; then
                        comprobacion="JATS4R: recomendaciones"
                    else
                        comprobacion="JATS4R"
                    fi
                elif [[ "$mensaje" == *DTD* ]]; then
                    comprobacion="DTD de JATS 1.4"
                else
                    comprobacion="DTD y JATS4R"
                fi
                ;;
            *)            grupo="$capa"; comprobacion="$capa" ;;
        esac
        # EL MENSAJE QUE ANUNCIA UNA LISTA TERMINA EN «:»; LA LISTA ESTÁ EN
        # LOS REGISTROS DE JATS4R
        registro "$nombre" "$grupo" "$comprobacion" "$estado" "${mensaje%:}" "" ""
    done < "$DIR_PROYECTO/tmp/validacion.tsv"

    # --- D. LOS HALLAZGOS DE JATS4R, UNO POR MENSAJE ---
    # LOS INFORMES SE LLAMAN NNN-<nombre>: EL NÚMERO EVITA CHOQUES EN EL LOTE
    # (validar_canonicos.sh, capa_jats). EN jats/ LOS NOMBRES SON ÚNICOS
    shopt -s nullglob
    for svrl in "$DIR_PROYECTO"/tmp/validar-jats-svrl/[0-9][0-9][0-9]-*; do
        nombre="$(basename "$svrl")"
        nombre="${nombre#[0-9][0-9][0-9]-}"
        hallazgos_jats4r "$nombre" "$svrl"
    done
    shopt -u nullglob
}

# ============================================================================
# Función   : valor_xpath
# Propósito : Un valor de un archivo por XPath 1.0.
# Parámetros: $1 archivo  $2 expresión que devuelve una cadena o un número
# Retorna   : imprime el valor; vacío si no hay
# ============================================================================
valor_xpath() {
    xmllint --nonet --xpath "$2" "$1" 2>/dev/null
}

# ============================================================================
# Función   : validar_doaj_archivo
# Propósito : Los registros de un archivo de DOAJ.
# Parámetros: $1 ruta absoluta del archivo
# ============================================================================
validar_doaj_archivo() {
    local abs="$1" objeto errores cantidad total i r id valor n
    objeto="$(basename "$abs")"

    # --- A. BIEN FORMADO: SIN ESO, NADA MÁS SE PUEDE LEER ---
    if ! xmllint --nonet --noout "$abs" 2>/dev/null; then
        registro "$objeto" esquema "Bien formado" ERROR "mal formado" "" \
            "$(xmllint --nonet --noout "$abs" 2>&1 | head -3 | sed "s|^$abs:|línea |" | tr '\n' ' ')"
        return
    fi

    # --- B. EL ESQUEMA DE DOAJ ---
    errores="$(validar_doaj "$abs")"
    if [[ -z "$errores" ]]; then
        registro "$objeto" esquema "doajArticles.xsd" OK "válido" "" ""
    else
        cantidad=$(printf '%s\n' "$errores" | grep -c .)
        registro "$objeto" esquema "doajArticles.xsd" ERROR "$cantidad error(es)" "válido" \
            "$(printf '%s\n' "$errores" | head -5 | tr '\n' ' ')"
    fi

    # --- C. EL ARCHIVO ---
    total=$(valor_xpath "$abs" 'count(/records/record)')
    [[ "$total" =~ ^[0-9]+$ ]] || total=0
    if (( total == 0 )); then
        registro "$objeto" archivo "Records" ERROR "ninguno" "uno por artículo" ""
        return
    fi
    registro "$objeto" archivo "Records" OK "$total" "" ""
    valor="$(valor_xpath "$abs" 'string((/records/record[1]/eissn | /records/record[1]/issn)[1])')"
    if [[ -n "$valor" ]]; then
        registro "$objeto" archivo "ISSN" OK "$valor" "" \
            "DOAJ compara los ISSN con los de la ficha de la revista en DOAJ: tienen que ser los mismos"
    else
        registro "$objeto" archivo "ISSN" ERROR "ninguno" "issn o eissn" \
            "DOAJ exige el ISSN o el eISSN de la revista"
    fi

    # --- D. CADA RECORD ---
    for (( i = 1; i <= total; i++ )); do
        r="/records/record[$i]"
        id="$(valor_xpath "$abs" "normalize-space($r/publisherRecordId)")"
        [[ -n "$id" ]] || id="record $i"

        # EL TEXTO COMPLETO Y EL DOI IDENTIFICAN EL ARTÍCULO EN DOAJ: SI
        # CAMBIAN DESPUÉS DE SUBIRLO, DOAJ LO DUPLICA
        valor="$(valor_xpath "$abs" "normalize-space($r/fullTextUrl)")"
        if [[ "$valor" =~ ^https?:// ]]; then
            registro "$objeto" "$id" "Texto completo" OK "$valor" "" \
                "Con el DOI, identifica el artículo en DOAJ: cambiarlo después de subirlo duplica el registro"
        else
            registro "$objeto" "$id" "Texto completo" ERROR "${valor:-ninguno}" "una URL http(s)" ""
        fi

        valor="$(valor_xpath "$abs" "normalize-space($r/doi)")"
        if [[ -n "$valor" ]]; then
            registro "$objeto" "$id" "DOI" OK "$valor" "" ""
        else
            registro "$objeto" "$id" "DOI" INFO "sin DOI" "" "DOAJ no lo exige"
        fi

        valor="$(valor_xpath "$abs" "normalize-space($r/language)")"
        if [[ -n "$valor" ]]; then
            registro "$objeto" "$id" "Idioma" OK "$valor" "" ""
        else
            registro "$objeto" "$id" "Idioma" AVISO "sin idioma" "un código ISO 639-2/B" \
                "El idioma del artículo no tiene código de dos letras en la lista ISO 639-2 (numero-a-doaj.xsl): el record sale sin idioma"
        fi

        n=$(valor_xpath "$abs" "count($r/title)")
        registro "$objeto" "$id" "Títulos" OK "$n" "" "DOAJ muestra uno solo, el que elige"

        n=$(valor_xpath "$abs" "count($r/authors/author)")
        if [[ "$n" == "0" ]]; then
            registro "$objeto" "$id" "Autores" INFO "ninguno" "" ""
        else
            registro "$objeto" "$id" "Autores" OK "$n" "" \
                "Con ORCID: $(valor_xpath "$abs" "count($r/authors/author[orcid_id])"). Una afiliación por autor: DOAJ ignora las demás"
        fi

        n=$(valor_xpath "$abs" "count($r/abstract)")
        if [[ "$n" == "0" ]]; then
            registro "$objeto" "$id" "Resúmenes" INFO "ninguno" "" ""
        else
            registro "$objeto" "$id" "Resúmenes" OK "$n" "" ""
        fi

        n=$(valor_xpath "$abs" "count($r/keywords)")
        if [[ "$n" == "0" ]]; then
            registro "$objeto" "$id" "Palabras clave" INFO "ninguna" "" ""
        else
            registro "$objeto" "$id" "Palabras clave" OK "$n idioma(s)" "" ""
        fi
    done
}

# ============================================================================
# Función   : validar_doaj_tipo
# Propósito : El tipo doaj: cada archivo de la lista.
# Parámetros: los archivos (rutas absolutas)
# ============================================================================
validar_doaj_tipo() {
    local abs

    # SIN EL ESQUEMA NO HAY VALIDACIÓN: ES UN PROBLEMA DE INSTALACIÓN, Y
    # LLEGA A GAMBAS COMO TAL (GV-23)
    esquema_doaj_presente ||
        morir "No está el esquema de DOAJ del sistema: $XSD_DOAJ (o su catálogo, $CATALOGO_DOAJ)"

    for abs in "$@"; do
        abs="$(readlink -f "$abs")"
        [[ "$abs" == "$DIR_PROYECTO/"* ]] || morir "El archivo no está dentro del proyecto: $abs"
        [[ -f "$abs" ]] || morir "No existe: $abs"
        validar_doaj_archivo "$abs"
    done
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

# --- 2. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <tipo> <ruta_proyecto> <archivo> [<archivo>...]"
fi

TIPO="$1"
DIR_PROYECTO="$(readlink -f "${2%/}")"
shift 2

[[ -d "$DIR_PROYECTO" ]]     || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/tmp" ]] || morir "El proyecto no tiene carpeta tmp/"
command -v xmllint >/dev/null 2>&1 || morir "Falta xmllint (paquete libxml2-utils)"

# --- 3. EL TIPO ---
case "$TIPO" in
    jats4r) validar_jats4r "$@" ;;
    doaj)   validar_doaj_tipo "$@" ;;
    *)      morir "Tipo de validación no reconocido: «$TIPO»" ;;
esac

exit 0
