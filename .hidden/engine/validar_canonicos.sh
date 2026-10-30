#!/bin/bash
# Validador de los canónicos DocBook del libro — gbpublisher
# ============================================================================
# Vive en /usr/share/gbpublisher/engine/ y viaja en el .deb. Es
# infraestructura: no se personaliza y no se copia a ~/.gbpublisher (SC-11).
# La norma es SC-75.
#
# USO
#   validar_canonicos.sh <ruta_proyecto> <modo> <lista_rel|->
#
#   ruta_proyecto   raíz del proyecto
#   modo            completo   todas las capas
#                   vigencia   solo la vigencia, sin JVM: la usa la apertura
#                              del proyecto
#   lista_rel       ruta relativa al proyecto de un archivo con una ruta de
#                   canónico por línea, también relativa al proyecto
#                   (jats/c-a-01-CAP01.xml). «-» es todos los jats/c-*.xml.
#
# LO LLAMAN el botón «Validar» del visor XML y la apertura del proyecto (por
# m_GenerarSalidasLibro.EjecutarScriptSalida, SC-53), y anidados
# generar_canonicos_capitulos.sh y ensamblar_libro.sh, que ya no validan por
# su cuenta. Un lote es UNA llamada: jing y el Schematron corren una vez para
# todos los archivos (GV-XML-03).
# ============================================================================
# LAS CAPAS
#
#   bien_formado  xmllint. Si falla, las demás quedan «no ejecutado»: nunca ✓
#   vigencia      las <?gb-fuente?> del prólogo contra el disco
#                 (vigencia_canonico, comun.sh). Desactualizado y huérfano
#                 son aviso; sin huella, tenue
#   docbook       jing contra el RNG y el Schematron del RNG compilado
#                 aparte, porque jing no lo ejecuta (GV-XML-02). En una pieza
#                 los IDREF sin ID van en tenue: son remisiones a otra pieza
#                 o a la bibliografía consolidada (SC-53); en el libro, aviso
#   proyecto      las reglas propias de gbpublisher (schemas/gbpublisher/
#                 gbpublisher.sch): ubicación de la pieza, estilo de cita,
#                 instrucciones gb-*, citas, entradas sin citar, figuras sin
#                 remitir, texto alternativo e idioma. Van compiladas en la
#                 misma hoja que las de DocBook y corren en la misma pasada;
#                 se distinguen por el prefijo gbp- de su @id, y cada una
#                 declara su nivel en @role: aviso o tenue
#   recursos      cada imagedata/@fileref tiene que ser media/{nombre} —con
#                 o sin ../ adelante— y existir. Las hojas de salida toman el
#                 nombre y lo buscan en media/: HTML y EPUB se quedan con el
#                 último tramo de la ruta (docbook-to-html.xsl,
#                 docbook-to-epub.xsl) y LaTeX le quita los ../ (f:ruta-imagen,
#                 tex-comun.xsl). Una subcarpeta de media/ funcionaría en el
#                 PDF y no en las salidas digitales: es aviso.
#                 Y tiene que ser png o jpg, lo único que sale en las tres:
#                 LuaLaTeX no admite svg, gif ni webp (luatex.def, medido), y
#                 el EPUB y el HTML no muestran un pdf. Otro formato es aviso
#
#   El modo vigencia corre solo las dos primeras.
#
# EL ALCANCE lo da la raíz de cada archivo: book es libro; las raíces que
# escribe ensamblar-capitulo-canonico.xsl son pieza; article (JATS) y
# cualquier otra son fallo.
#
# LOS RECURSOS DEL SISTEMA
#   El RNG y el Schematron compilado salen de la carpeta de recursos de ESTE
#   script ($DIR_ENGINE/..): .hidden/ desde el IDE, /usr/share/gbpublisher/
#   instalado. No de ~/.gbpublisher: un informe que dice «válido» solo se
#   sostiene con el esquema del paquete (SC-11, SC-75).
#
# EL INFORME
#   tmp/validacion.tsv, reescrito en cada corrida, también vacío. Una línea
#   por hallazgo o por capa: archivo TAB capa TAB nivel TAB mensaje, con nivel
#   ok | aviso | tenue | fallo | no_ejecutado. Lo que falta del entorno (jing,
#   Saxon, los esquemas) va con archivo «-» y capa «entorno». Lo leen los scripts que llaman
#   a este, para saber qué canónico tuvo avisos. Gambas no lo lee (SC-53).
#
# CÓDIGOS (comun.sh, leídos para un script que no genera nada)
#   0  corrieron todas las capas y no hubo hallazgos
#   3  hubo hallazgos, o una capa no pudo correr (jing ausente, por ejemplo)
#   1  algún archivo no se pudo validar: ausente, mal formado, raíz
#      desconocida; o el lote no pudo empezar
# ============================================================================

set -uo pipefail

DIR_ENGINE="$(dirname "$(readlink -f "$0")")"
if ! source "$DIR_ENGINE/comun.sh"; then
    echo "No se pudo cargar $DIR_ENGINE/comun.sh" >&2
    exit 1
fi

# --- 1. CONFIGURACIÓN ---
TIEMPO_JING=300
TIEMPO_SAXON=300
LINEAS_POR_ARCHIVO=15
# EL ANCHO MÁXIMO DE UNA LÍNEA DE ERROR EN LA TERMINAL
ANCHO_LINEA=240

# EL MENSAJE DE jing PARA UN IDREF SIN SU ID. TOMADO DE LA SALIDA REAL DE jing
# EN LINUX MINT: «69:1130: error: IDREF "bib-4308-TOCHO2020" without matching ID»
PATRON_IDREF='IDREF "[^"]*" without matching ID'

DIR_RECURSOS="$(dirname "$DIR_ENGINE")"
RNG="$DIR_RECURSOS/schemas/docbook/docbook.rng"
# LAS REGLAS DE DocBook Y LAS PROPIAS, EN UNA SOLA HOJA: LA GENERA
# generar-schematron-canonico.sh, EN LA RAÍZ DEL REPOSITORIO
SCH="$DIR_RECURSOS/schemas/schematron-canonico.xsl"

NS_DOCBOOK="http://docbook.org/ns/docbook"

# LAS RAÍCES DE PIEZA: LAS QUE ESCRIBE ensamblar-capitulo-canonico.xsl SEGÚN
# tipo_capitulo. SI ESA HOJA SUMA UNA, SE SUMA ACÁ
RAICES_PIEZA=" chapter preface dedication acknowledgements appendix glossary bibliography colophon toc index "

# EL RESULTADO DE CADA ARCHIVO: ok, aviso O fallo, EL PEOR DE SUS CAPAS
declare -A RESULTADO=()
# EL ALCANCE DE CADA ARCHIVO QUE LLEGA A LA CAPA docbook: pieza O libro
declare -A ALCANCE=()
# LOS ARCHIVOS, EN EL ORDEN DE LA LISTA
ARCHIVOS=()
# LOS QUE ESTÁN BIEN FORMADOS Y SON DocBook: LOS QUE VAN A jing Y AL SCHEMATRON

# LAS IMÁGENES QUE SALEN EN LAS TRES SALIDAS (VER LA CABECERA, «recursos»)
FORMATOS_COMUNES=" png jpg jpeg "
PARA_DOCBOOK=()

# ============================================================================
# Función   : limpiar
# Propósito : Un texto en una sola línea y sin TAB, para el informe.
# Parámetros: $1 texto
# Retorna   : imprime el texto limpio
# ============================================================================
limpiar() {
    local texto="$1"
    texto="${texto//$'\t'/ }"
    texto="${texto//$'\r'/ }"
    texto="${texto//$'\n'/ }"
    printf '%s' "$texto"
}

# ============================================================================
# Función   : empeorar
# Propósito : Sube el resultado de un archivo si el nuevo nivel es peor.
# Parámetros: $1 archivo  $2 ok | aviso | fallo
# ============================================================================
empeorar() {
    local actual="${RESULTADO[$1]:-ok}"
    case "$2" in
        fallo) RESULTADO[$1]="fallo" ;;
        aviso) [[ "$actual" != "fallo" ]] && RESULTADO[$1]="aviso" ;;
    esac
    return 0
}

# ============================================================================
# Función   : anotar
# Propósito : Registra un resultado en el informe y lo muestra en la terminal.
#             Es el único lugar que escribe el informe: así la terminal y el
#             archivo dicen siempre lo mismo.
# Parámetros: $1 archivo  $2 capa  $3 nivel  $4 mensaje
# Nota      : aviso() CUENTA PARA EL CÓDIGO 3; fallo NO SALE DEL SCRIPT: EL
#             LOTE SIGUE CON LOS DEMÁS ARCHIVOS (SC-53)
# ============================================================================
anotar() {
    local archivo="$1" capa="$2" nivel="$3" mensaje
    mensaje="$(limpiar "$4")"
    printf '%s\t%s\t%s\t%s\n' "$archivo" "$capa" "$nivel" "$mensaje" >> "$INFORME"
    case "$nivel" in
        ok)           ok "$mensaje" ;;
        aviso)        aviso "$mensaje" ; empeorar "$archivo" aviso ;;
        tenue)        tenue "$mensaje" ;;
        no_ejecutado) tenue "no ejecutado ($capa): $mensaje" ;;
        fallo)        printf '  %s✗%s %s\n' "$C_ERROR" "$C_RESET" "$mensaje"
                      empeorar "$archivo" fallo ;;
    esac
    return 0
}

# ============================================================================
# Función   : decodificar
# Propósito : Las cinco entidades predefinidas de XML a su carácter, para
#             mostrar valores de atributo y textos que xmllint devuelve
#             serializados.
# Parámetros: $1 texto
# Retorna   : imprime el texto
# Nota      : &amp; AL FINAL: SI FUERA PRIMERO, «&amp;lt;» TERMINARÍA EN «<»
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
# Función   : capa_vigencia
# Propósito : El estado del canónico frente a sus fuentes, en el informe.
# Parámetros: $1 ruta relativa  $2 ruta absoluta
# ============================================================================
capa_vigencia() {
    local rel="$1" abs="$2"

    vigencia_canonico "$abs"
    case "$VIGENCIA_ESTADO" in
        vigente)        anotar "$rel" vigencia ok "vigente respecto de sus archivos fuente ($VIGENCIA_DETALLE)" ;;
        desactualizado) anotar "$rel" vigencia aviso "desactualizado: $VIGENCIA_DETALLE. Regenerá el canónico" ;;
        huerfano)       anotar "$rel" vigencia aviso "huérfano: $VIGENCIA_DETALLE. No se puede regenerar: si sobra, borralo" ;;
        sin_huella)     anotar "$rel" vigencia tenue "vigencia desconocida: $VIGENCIA_DETALLE. Regenerá el canónico para registrarlas" ;;
        ilegible)       anotar "$rel" vigencia fallo "no se pudo leer la vigencia: $VIGENCIA_DETALLE" ;;
        *)              anotar "$rel" vigencia fallo "estado de vigencia desconocido: «$VIGENCIA_ESTADO»" ;;
    esac
}

# ============================================================================
# Función   : capa_recursos
# Propósito : Cada imagedata/@fileref del canónico, contra media/.
# Parámetros: $1 ruta relativa  $2 ruta absoluta
# ============================================================================
capa_recursos() {
    local rel="$1" abs="$2"
    local refs ref limpia nombre extension motivo
    local total=0 problemas=0

    # grep -oP SOBRE LA SERIALIZACIÓN DE xmllint: UN SOLO PROCESO POR ARCHIVO,
    # NO UNO POR IMAGEN. EL CONJUNTO VACÍO NO ES UN ERROR
    refs="$(xmllint --xpath '//*[local-name()="imagedata"]/@fileref' "$abs" 2>/dev/null |
            grep -oP 'fileref="\K[^"]*')"

    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        total=$((total + 1))
        ref="$(decodificar "$ref")"

        # CON ESQUEMA (http:, https:, data:): NO ES UN ARCHIVO DEL PROYECTO Y
        # NO SE SALE A LA RED A COMPROBARLO
        if [[ "$ref" =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]]; then
            anotar "$rel" recursos tenue "«$ref» es una dirección externa: no se comprueba"
            continue
        fi

        # LOS ../ Y ./ DEL PRINCIPIO, COMO f:ruta-imagen DE tex-comun.xsl
        limpia="$ref"
        while [[ "$limpia" == ../* || "$limpia" == ./* ]]; do
            limpia="${limpia#../}"
            limpia="${limpia#./}"
        done

        if [[ ! "$limpia" =~ ^media/[^/]+$ ]]; then
            anotar "$rel" recursos aviso "«$ref» no está directamente en media/: las salidas digitales solo toman media/{nombre}"
            problemas=$((problemas + 1))
            continue
        fi
        nombre="${limpia#media/}"
        if [[ ! -f "$DIR_PROYECTO/media/$nombre" ]]; then
            anotar "$rel" recursos aviso "«$ref» no existe en media/: ¿se borró o se renombró?"
            problemas=$((problemas + 1))
            continue
        fi

        # EL FORMATO, POR LA EXTENSIÓN EN MINÚSCULAS: ES LO QUE MIRAN LAS
        # SALIDAS (graphicx, EsImagenEpub)
        extension="${nombre##*.}"
        extension="${extension,,}"
        if [[ "$FORMATOS_COMUNES" != *" $extension "* ]]; then
            case "$extension" in
                svg|gif|webp) motivo="no sale en el PDF: LuaLaTeX no lo admite" ;;
                pdf)          motivo="no sale en el EPUB ni en el HTML" ;;
                *)            motivo="no es png ni jpg y puede no salir en ninguna salida" ;;
            esac
            anotar "$rel" recursos aviso "«$ref» $motivo; las figuras van en png o jpg"
            problemas=$((problemas + 1))
        fi
    done <<< "$refs"

    if (( total == 0 )); then
        anotar "$rel" recursos tenue "sin imágenes"
    elif (( problemas == 0 )); then
        anotar "$rel" recursos ok "$total imagen(es) en media/"
    fi
}

# ============================================================================
# Función   : listar_svrl
# Propósito : Muestra, agrupados por mensaje, los incumplimientos de un
#             informe SVRL que cumplen un filtro. Una regla que falla en cien
#             lugares es una línea con su cantidad.
# Parámetros: $1 ruta del informe  $2 predicado XPath sobre failed-assert y
#             successful-report ([starts-with(@id, 'gbp-')], por ejemplo)
# Retorna   : imprime las líneas; nada si no hay incumplimientos
# ============================================================================
listar_svrl() {
    local svrl="$1" filtro="$2" textos linea cantidad

    textos="$(xmllint --xpath "//*[local-name()='failed-assert' or local-name()='successful-report']$filtro/*[local-name()='text']" "$svrl" 2>/dev/null |
              grep -oP '<svrl:text>\K.*?(?=</svrl:text>)')"
    [[ -n "$textos" ]] || return 0

    cantidad=$(printf '%s\n' "$textos" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sort -u | grep -c .)
    while IFS= read -r linea; do
        printf '     %s\n' "$(decodificar "$linea")" | cut -c1-"$ANCHO_LINEA"
    done < <(printf '%s\n' "$textos" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
             sort | uniq -c | sort -rn | head -"$LINEAS_POR_ARCHIVO" |
             sed -E 's/^ *([0-9]+) (.*)$/\1 × \2/')
    if (( cantidad > LINEAS_POR_ARCHIVO )); then
        tenue "(+$(( cantidad - LINEAS_POR_ARCHIVO )) mensaje(s) más: el informe SVRL completo está en tmp/validar-svrl/)"
    fi
}

# ============================================================================
# Función   : contar_svrl
# Propósito : Cuántos incumplimientos de un informe SVRL cumplen un filtro.
# Parámetros: $1 ruta del informe  $2 predicado XPath, como en listar_svrl
# Retorna   : imprime la cantidad
# ============================================================================
contar_svrl() {
    xmllint --xpath "count(//*[local-name()='failed-assert' or local-name()='successful-report']$2)" "$1" 2>/dev/null
}

# ============================================================================
# Función   : capa_docbook
# Propósito : jing y el Schematron del RNG, UNA vez para todos los archivos de
#             PARA_DOCBOOK, y el resultado repartido por archivo.
# Nota      : jing ANTEPONE A CADA ERROR LA RUTA DEL ARCHIVO, QUE ES LA QUE
#             RECIBIÓ: CON RUTAS ABSOLUTAS SE ATRIBUYE SIN AMBIGÜEDAD.
#             EL SCHEMATRON CORRE SOBRE UNA CARPETA DE ENLACES A LA LISTA: EL
#             MODO CARPETA DE SAXON TOMA LA CARPETA ENTERA Y NO UNA LISTA
#             (GV-XML-03). LOS ENLACES LLEVAN UN NÚMERO ADELANTE PARA QUE DOS
#             ARCHIVOS CON EL MISMO NOMBRE NO CHOQUEN
# ============================================================================
capa_docbook() {
    local rel abs i n
    local salida_jing="" codigo_jing=0 jing_corrio="no" sch_corrio="no"
    local propios remisiones errores cantidad lineas_atribuidas=0
    local dir_enlaces="$DIR_PROYECTO/tmp/validar"
    local dir_svrl="$DIR_PROYECTO/tmp/validar-svrl"
    local enlace svrl fallidas avisos_gbp tenues_gbp salida_saxon codigo_saxon
    local abs_lista=()
    declare -A ENLACE=()

    n=${#PARA_DOCBOOK[@]}
    (( n > 0 )) || return 0

    paso "esquema DocBook 5.2 y reglas de gbpublisher ($n archivo(s))"

    for rel in "${PARA_DOCBOOK[@]}"; do
        abs_lista+=("$DIR_PROYECTO/$rel")
    done

    # --- A. jing ---
    if [[ "$HAY_JING" == "si" ]]; then
        salida_jing=$(timeout "$TIEMPO_JING" jing "$RNG" "${abs_lista[@]}" 2>&1)
        codigo_jing=$?
        if (( codigo_jing == 124 )); then
            tenue "jing no terminó en $TIEMPO_JING segundos"
        else
            jing_corrio="si"
        fi
    fi

    # --- B. SCHEMATRON ---
    if [[ "$HAY_SCH" == "si" ]]; then
        rm -rf "$dir_enlaces" "$dir_svrl"
        if mkdir -p "$dir_enlaces" "$dir_svrl"; then
            i=0
            for rel in "${PARA_DOCBOOK[@]}"; do
                i=$((i + 1))
                enlace="$(printf '%03d' "$i")-$(basename "$rel")"
                ENLACE[$rel]="$enlace"
                ln -s "$DIR_PROYECTO/$rel" "$dir_enlaces/$enlace"
            done
            salida_saxon=$(timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" \
                -s:"$dir_enlaces" -xsl:"$SCH" -o:"$dir_svrl/" 2>&1)
            codigo_saxon=$?
            if (( codigo_saxon == 0 )); then
                sch_corrio="si"
            else
                mostrar_cola "$salida_saxon" 10
                tenue "el Schematron no pudo correr (código $codigo_saxon)"
            fi
        fi
        rm -rf "$dir_enlaces"
    fi

    # --- C. EL RESULTADO DE CADA ARCHIVO ---
    for rel in "${PARA_DOCBOOK[@]}"; do
        abs="$DIR_PROYECTO/$rel"
        tenue "$rel"

        # jing
        if [[ "$jing_corrio" != "si" ]]; then
            anotar "$rel" docbook no_ejecutado "jing no corrió: el RNG no se comprobó"
        else
            # LAS LÍNEAS DE ESTE ARCHIVO, SIN SU RUTA: QUEDA LÍNEA:COLUMNA Y EL
            # MENSAJE. grep -F: LA RUTA NO ES UNA EXPRESIÓN REGULAR
            errores="$(printf '%s\n' "$salida_jing" | grep -F -- "$abs:" | sed "s|^$abs:||")"
            [[ -n "$errores" ]] && lineas_atribuidas=$((lineas_atribuidas + 1))

            if [[ "${ALCANCE[$rel]}" == "pieza" ]]; then
                remisiones=$(printf '%s\n' "$errores" | grep -c -- "$PATRON_IDREF")
                propios="$(printf '%s\n' "$errores" | grep -v -- "$PATRON_IDREF" | grep .)"
            else
                remisiones=0
                propios="$(printf '%s\n' "$errores" | grep .)"
            fi

            if [[ -n "$propios" ]]; then
                cantidad=$(printf '%s\n' "$propios" | grep -c .)
                anotar "$rel" docbook aviso "$cantidad error(es) contra el RNG:"
                # CADA LÍNEA RECORTADA: CON UN ELEMENTO NO ADMITIDO, jing LISTA
                # TODOS LOS QUE ESPERABA, Y SON CIENTOS
                printf '%s\n' "$propios" | head -"$LINEAS_POR_ARCHIVO" |
                    cut -c1-"$ANCHO_LINEA" | sed 's/^/     /'
                (( cantidad > LINEAS_POR_ARCHIVO )) &&
                    tenue "(+$(( cantidad - LINEAS_POR_ARCHIVO )) más)"
            elif (( remisiones > 0 )); then
                # NO SE DICE «VÁLIDO»: LAS REMISIONES SE VERIFICAN EN EL LIBRO
                anotar "$rel" docbook ok "sin errores de esquema propios de la pieza"
            else
                anotar "$rel" docbook ok "válido contra el RNG"
            fi
            # LAS REMISIONES: INFORMACIÓN, NO AVISO, HAYA O NO ERRORES PROPIOS
            if (( remisiones > 0 )); then
                anotar "$rel" docbook tenue "$remisiones remisión(es) a IDs fuera de la pieza (bibliografía consolidada u otra pieza): se verifican en el libro"
            fi
        fi

        # SCHEMATRON: LAS REGLAS DE DocBook Y LAS PROPIAS, EN EL MISMO INFORME
        if [[ "$sch_corrio" != "si" ]]; then
            anotar "$rel" docbook no_ejecutado "el Schematron de DocBook no corrió"
            anotar "$rel" proyecto no_ejecutado "las reglas de gbpublisher no corrieron"
        else
            svrl="$dir_svrl/${ENLACE[$rel]}"
            # GV-28: QUE SEA EL INFORME Y NO OTRA COSA ANTES DE CONTAR
            if [[ ! -f "$svrl" || "$(xmllint --xpath 'local-name(/*)' "$svrl" 2>/dev/null)" != "schematron-output" ]]; then
                anotar "$rel" docbook aviso "el Schematron no dejó un informe SVRL: no se comprobó"
                anotar "$rel" proyecto aviso "el Schematron no dejó un informe SVRL: las reglas de gbpublisher no se comprobaron"
            else
                # DocBook: LAS QUE NO TRAEN @id gbp-
                fallidas=$(contar_svrl "$svrl" "[not(starts-with(@id, 'gbp-'))]")
                if [[ "${fallidas:-0}" == "0" ]]; then
                    anotar "$rel" docbook ok "cumple las reglas Schematron de DocBook"
                else
                    anotar "$rel" docbook aviso "$fallidas incumplimiento(s) de las reglas Schematron de DocBook:"
                    listar_svrl "$svrl" "[not(starts-with(@id, 'gbp-'))]"
                fi

                # PROPIAS: EL NIVEL LO DECLARA LA REGLA EN @role. tenue
                # INFORMA; CUALQUIER OTRO VALOR CUENTA COMO aviso: UN role
                # MAL ESCRITO NO PUEDE DEJAR UN HALLAZGO SIN CONTAR
                avisos_gbp=$(contar_svrl "$svrl" "[starts-with(@id, 'gbp-')][not(@role = 'tenue')]")
                tenues_gbp=$(contar_svrl "$svrl" "[starts-with(@id, 'gbp-')][@role = 'tenue']")
                if [[ "${avisos_gbp:-0}" == "0" ]]; then
                    anotar "$rel" proyecto ok "cumple las reglas de gbpublisher"
                else
                    anotar "$rel" proyecto aviso "$avisos_gbp incumplimiento(s) de las reglas de gbpublisher:"
                    listar_svrl "$svrl" "[starts-with(@id, 'gbp-')][not(@role = 'tenue')]"
                fi
                if [[ "${tenues_gbp:-0}" != "0" ]]; then
                    anotar "$rel" proyecto tenue "$tenues_gbp observación(es) de las reglas de gbpublisher:"
                    listar_svrl "$svrl" "[starts-with(@id, 'gbp-')][@role = 'tenue']"
                fi
            fi
        fi
    done

    # jing FALLÓ SIN ERRORES QUE SE PUEDAN ATRIBUIR: EL ESQUEMA O LA
    # INVOCACIÓN, NO LOS ARCHIVOS. NO SE PUEDE DAR NADA POR VÁLIDO
    if [[ "$jing_corrio" == "si" ]] && (( codigo_jing != 0 && lineas_atribuidas == 0 )); then
        mostrar_cola "$salida_jing" 10
        for rel in "${PARA_DOCBOOK[@]}"; do
            anotar "$rel" docbook aviso "jing terminó con código $codigo_jing sin informar errores de este archivo: el RNG no se comprobó"
        done
    fi
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "VALIDACIÓN DE CANÓNICOS"

# --- 2. ARGUMENTOS ---
if (( $# < 3 )); then
    morir "Uso: $(basename "$0") <ruta_proyecto> <completo|vigencia> <lista_rel|->"
fi

DIR_PROYECTO="${1%/}"
MODO="$2"
LISTA_REL="$3"
INFORME="$DIR_PROYECTO/tmp/validacion.tsv"

case "$MODO" in
    completo|vigencia) ;;
    *) morir "Modo no reconocido: «$MODO» (se espera completo o vigencia)" ;;
esac

# --- 3. ENTORNO ---
paso "verificando el entorno"

[[ -d "$DIR_PROYECTO" ]]      || morir "No existe el proyecto: $DIR_PROYECTO"
[[ -d "$DIR_PROYECTO/jats" ]] || morir "El proyecto no tiene carpeta jats/"
[[ -d "$DIR_PROYECTO/tmp" ]]  || morir "El proyecto no tiene carpeta tmp/"

requerir_comandos xmllint sha256sum grep sed timeout

# EL INFORME SE EMPIEZA ANTES DE CUALQUIER ANOTACIÓN: UNO VIEJO NO PUEDE
# PASAR POR ESTE
: > "$INFORME" || morir "No se pudo escribir el informe: $INFORME"

HAY_JING="no"
HAY_SCH="no"
if [[ "$MODO" == "completo" ]]; then
    # LA FALTA DE UN VALIDADOR SE AVISA UNA VEZ, NO UNA POR ARCHIVO. ES AVISO
    # Y NO FALLO: LAS OTRAS CAPAS CORREN IGUAL, Y EL INFORME NO DA POR VÁLIDO
    # LO QUE NO VALIDÓ
    if ! command -v jing >/dev/null 2>&1; then
        anotar - entorno aviso "jing no está instalado: el RNG de DocBook no se comprueba"
    elif [[ ! -f "$RNG" ]]; then
        anotar - entorno aviso "no se encontró el RNG del sistema: $RNG"
    else
        HAY_JING="si"
    fi
    if ! command -v java >/dev/null 2>&1; then
        anotar - entorno aviso "java no está instalado: el Schematron (DocBook y reglas de gbpublisher) no se comprueba"
    elif [[ ! -f "$RUTA_SAXON" ]]; then
        anotar - entorno aviso "Saxon-HE no está en $RUTA_SAXON: el Schematron (DocBook y reglas de gbpublisher) no se comprueba"
    elif [[ ! -f "$SCH" ]]; then
        anotar - entorno aviso "no se encontró el Schematron compilado del sistema: $SCH"
    else
        HAY_SCH="si"
    fi
fi
ok "herramientas ($MODO)"

# --- 4. LISTA ---
paso "leyendo la lista"

if [[ "$LISTA_REL" == "-" ]]; then
    # TODOS LOS CANÓNICOS, SIN LOS TEMPORALES (.c-*.xml.tmp NO TERMINA EN
    # .xml NI EMPIEZA CON c-)
    shopt -s nullglob
    for abs in "$DIR_PROYECTO"/jats/c-*.xml; do
        ARCHIVOS+=("jats/$(basename "$abs")")
    done
    shopt -u nullglob
else
    [[ -f "$DIR_PROYECTO/$LISTA_REL" ]] || morir "No existe la lista: $LISTA_REL"
    while IFS= read -r linea || [[ -n "$linea" ]]; do
        linea="${linea%$'\r'}"
        [[ -z "$linea" ]] && continue
        ARCHIVOS+=("$linea")
    done < "$DIR_PROYECTO/$LISTA_REL"
fi

if (( ${#ARCHIVOS[@]} == 0 )); then
    tenue "no hay canónicos que validar"
    terminar
fi
ok "${#ARCHIVOS[@]} archivo(s)"

# --- 5. ARCHIVO POR ARCHIVO ---
for rel in "${ARCHIVOS[@]}"; do
    paso "$rel"
    RESULTADO[$rel]="ok"
    abs="$DIR_PROYECTO/$rel"

    # UNA RUTA QUE SALE DEL PROYECTO ES UNA LISTA QUE GAMBAS NO ESCRIBIÓ ASÍ
    if [[ "$rel" == /* || "$rel" == *..* ]]; then
        anotar "$rel" bien_formado fallo "ruta inválida: tiene que ser relativa al proyecto y no salir de él"
        continue
    fi
    if [[ ! -f "$abs" ]]; then
        anotar "$rel" bien_formado fallo "no existe"
        continue
    fi

    # --- A. BIEN FORMADO ---
    if ! bien_formado "$abs"; then
        anotar "$rel" bien_formado fallo "mal formado"
        # SIN LA RUTA, QUE YA ESTÁ EN EL PASO: QUEDA LA LÍNEA Y EL MOTIVO
        mostrar_cola "$(xmllint --noout "$abs" 2>&1 | sed "s|^$abs:|línea |")" 5
        anotar "$rel" vigencia no_ejecutado "el archivo está mal formado"
        if [[ "$MODO" == "completo" ]]; then
            anotar "$rel" docbook no_ejecutado "el archivo está mal formado"
            anotar "$rel" recursos no_ejecutado "el archivo está mal formado"
        fi
        continue
    fi
    anotar "$rel" bien_formado ok "bien formado"

    # --- B. ALCANCE (SOLO EN completo: LA VIGENCIA NO DEPENDE DE LA RAÍZ) ---
    if [[ "$MODO" == "completo" ]]; then
        raiz="$(xmllint --xpath 'local-name(/*)' "$abs" 2>/dev/null)"
        ns="$(xmllint --xpath 'namespace-uri(/*)' "$abs" 2>/dev/null)"
        if [[ "$raiz" == "article" ]]; then
            anotar "$rel" docbook fallo "es un artículo JATS: la validación de revistas todavía no está en engine/"
            continue
        fi
        if [[ "$ns" != "$NS_DOCBOOK" ]]; then
            anotar "$rel" docbook fallo "la raíz <$raiz> no es DocBook"
            continue
        fi
        if [[ "$raiz" == "book" ]]; then
            ALCANCE[$rel]="libro"
        elif [[ "$RAICES_PIEZA" == *" $raiz "* ]]; then
            ALCANCE[$rel]="pieza"
        else
            anotar "$rel" docbook fallo "la raíz <$raiz> no es la de un libro ni la de una pieza"
            continue
        fi
        tenue "alcance: ${ALCANCE[$rel]} (<$raiz>)"
    fi

    # --- C. VIGENCIA ---
    capa_vigencia "$rel" "$abs"

    # --- D. RECURSOS; LA CAPA docbook VA DESPUÉS, PARA TODOS JUNTOS ---
    if [[ "$MODO" == "completo" ]]; then
        capa_recursos "$rel" "$abs"
        PARA_DOCBOOK+=("$rel")
    fi
done

# --- 6. DocBook, EN UN SOLO LOTE ---
if [[ "$MODO" == "completo" ]]; then
    capa_docbook
fi

# --- 7. RESUMEN ---
# SOLO SE AFIRMA LO VERIFICADO: «sin hallazgos» QUIERE DECIR QUE TODAS LAS
# CAPAS CORRIERON Y NINGUNA ENCONTRÓ NADA
sin_hallazgos=() ; con_hallazgos=() ; no_validados=()
for rel in "${ARCHIVOS[@]}"; do
    case "${RESULTADO[$rel]}" in
        ok)    sin_hallazgos+=("$rel") ;;
        aviso) con_hallazgos+=("$rel") ;;
        *)     no_validados+=("$rel") ;;
    esac
done

if [[ -z "${GBP_ANIDADO:-}" ]]; then
    echo
    titulo "$REGLA"
    if (( ${#no_validados[@]} > 0 )); then
        printf '%s✗ No se pudieron validar %d de %d%s\n' "$C_ERROR" "${#no_validados[@]}" "${#ARCHIVOS[@]}" "$C_RESET"
        printf '    %s\n' "${no_validados[@]}"
    elif (( AVISOS > 0 )); then
        printf '%s⚠ Validación con hallazgos%s\n' "$C_AVISO" "$C_RESET"
    else
        printf '%s✓ Sin hallazgos: %d archivo(s)%s\n' "$C_OK" "${#ARCHIVOS[@]}" "$C_RESET"
    fi
    if (( ${#con_hallazgos[@]} > 0 )); then
        printf '  %sCon hallazgos (marcados con ⚠ arriba):%s\n' "$C_AVISO" "$C_RESET"
        printf '    %s\n' "${con_hallazgos[@]}"
    fi
    printf '  %-9s %s\n' "Modo:" "$MODO"
    printf '  Informe:  %s\n' "$INFORME"
    echo
fi

if (( ${#no_validados[@]} > 0 )); then
    exit "$SALIDA_FALLO"
fi

terminar
