#!/bin/bash
# ============================================================================
# SCRIPT: gbpublisher-pipeline-jats.sh
# DESCRIPCIÓN: PIPELINE COMPLETO DE GENERACIÓN Y VALIDACIÓN JATS 1.4
#              PASOS 1.1 A 1.6 DEL FLUJO DE PRODUCCIÓN EDITORIAL
# PROYECTO: gbpublisher
# USO: ./gbpublisher-pipeline-jats.sh <archivo-base> <directorio-proyecto>
# EJEMPLO: ./gbpublisher-pipeline-jats.sh revistaAlgo-v01-n01 /home/usuario/00_Produccion/proyecto
# ============================================================================

set -euo pipefail

# ============================================================================
# CONFIGURACIÓN DE RUTAS DE INFRAESTRUCTURA
# MODIFICAR SEGÚN INSTALACIÓN LOCAL
# ============================================================================
readonly SAXON_JAR="/opt/Saxon-HE/saxon-he.jar"
readonly SCHXSLT_XSL="$HOME/.gbpublisher/schematron/schxslt-xslt/xslt/2.0/pipeline-for-svrl.xsl"
readonly SCH_DIR="$HOME/.gbpublisher/schematron/jats-schematrons/schematrons/1.0"
readonly JATS_DTD="$HOME/.gbpublisher/dtd/JATS-archivearticle1-4.dtd"
readonly FILTROS_DIR="$HOME/.gbpublisher/filters"
readonly XSLT_DIR="$HOME/.gbpublisher/xslt"

# ============================================================================
# COLORES PARA SALIDA EN TERMINAL
# ============================================================================
readonly COLOR_OK="\033[0;32m"    # VERDE
readonly COLOR_ERROR="\033[0;31m" # ROJO
readonly COLOR_INFO="\033[0;34m"  # AZUL
readonly COLOR_WARN="\033[0;33m"  # AMARILLO
readonly COLOR_RESET="\033[0m"

# ============================================================================
# FUNCIÓN: log_ok / log_error / log_info
# DESCRIPCIÓN: FUNCIONES DE REGISTRO CON COLORES Y TIMESTAMP
# ============================================================================
log_ok()    { echo -e "${COLOR_OK}[OK]${COLOR_RESET}    $(date '+%H:%M:%S') $*"; }
log_error() { echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $(date '+%H:%M:%S') $*" >&2; }
log_info()  { echo -e "${COLOR_INFO}[INFO]${COLOR_RESET}  $(date '+%H:%M:%S') $*"; }
log_warn()  { echo -e "${COLOR_WARN}[AVISO]${COLOR_RESET} $(date '+%H:%M:%S') $*"; }

# ============================================================================
# FUNCIÓN: verificar_dependencias
# DESCRIPCIÓN: COMPRUEBA QUE TODAS LAS HERRAMIENTAS NECESARIAS ESTÉN
#              INSTALADAS ANTES DE INICIAR EL PIPELINE
# ============================================================================
verificar_dependencias() {
    log_info "Verificando dependencias del sistema..."

    local FALTANTES=0

    # JAVA (REQUERIDO POR SAXON-HE)
    if ! command -v java &>/dev/null; then
        log_error "Java no encontrado. Instalar con: sudo apt install default-jre"
        FALTANTES=$((FALTANTES + 1))
    fi

    # SAXON-HE
    if [ ! -f "$SAXON_JAR" ]; then
        log_error "Saxon-HE no encontrado en: $SAXON_JAR"
        FALTANTES=$((FALTANTES + 1))
    fi

    # PANDOC
    if ! command -v pandoc &>/dev/null; then
        log_error "Pandoc no encontrado. Instalar con: sudo apt install pandoc"
        FALTANTES=$((FALTANTES + 1))
    fi

    # XMLLINT
    if ! command -v xmllint &>/dev/null; then
        log_error "xmllint no encontrado. Instalar con: sudo apt install libxml2-utils"
        FALTANTES=$((FALTANTES + 1))
    fi

    # SCHXSLT XSLT
    if [ ! -f "$SCHXSLT_XSL" ]; then
        log_error "SchXslt no encontrado en: $SCHXSLT_XSL"
        FALTANTES=$((FALTANTES + 1))
    fi

    # DTD JATS 1.4
    if [ ! -f "$JATS_DTD" ]; then
        log_error "DTD JATS 1.4 no encontrado en: $JATS_DTD"
        FALTANTES=$((FALTANTES + 1))
    fi

    # SCHEMATRONS JATS4R
    if [ ! -d "$SCH_DIR" ]; then
        log_error "Directorio de schematrons no encontrado en: $SCH_DIR"
        FALTANTES=$((FALTANTES + 1))
    fi

    if [ "$FALTANTES" -gt 0 ]; then
        log_error "Faltan $FALTANTES dependencias. Abortar."
        exit 1
    fi

    log_ok "Todas las dependencias verificadas."
}

# ============================================================================
# FUNCIÓN: paso_1_1_generar_front
# DESCRIPCIÓN: GENERA EL FRAGMENTO XML DEL FRONT (METADATOS DEL ARTÍCULO)
#              DESDE LA BASE DE DATOS DEL PROYECTO
#              NOTA: EN PRODUCCIÓN ESTE PASO LO EJECUTA GAMBAS DIRECTAMENTE
#                    AQUÍ SE VERIFICA QUE EL ARCHIVO YA EXISTE
# ============================================================================
paso_1_1_generar_front() {
    log_info "PASO 1.1 - Verificando front XML..."

    if [ ! -f "$DIR_TMP/front-${BASE}.xml" ]; then
        log_error "front-${BASE}.xml no encontrado en $DIR_TMP"
        log_error "Este archivo debe generarse desde gbpublisher (función GenerarFrontXML)"
        exit 1
    fi

    log_ok "PASO 1.1 - front-${BASE}.xml presente."
}

# ============================================================================
# FUNCIÓN: paso_1_2_generar_body
# DESCRIPCIÓN: CONVIERTE EL MANUSCRITO MARKDOWN AL FRAGMENTO BODY EN JATS XML
#              USANDO PANDOC CON EL FILTRO LUA cite-to-xref.lua
#              EL FILTRO TRANSFORMA DIVS, CITAS Y NOTAS AL PIE A ELEMENTOS JATS
# ============================================================================
paso_1_2_generar_body() {
    log_info "PASO 1.2 - Generando body XML desde Markdown..."

    local MD_FILE="$DIR_PROYECTO/manuscrito/${BASE}.md"
    local OUTPUT="$DIR_TMP/body-${BASE}.xml"

    if [ ! -f "$MD_FILE" ]; then
        log_error "Manuscrito Markdown no encontrado: $MD_FILE"
        exit 1
    fi

    pandoc "$MD_FILE" \
        --from markdown \
        --to jats \
        --lua-filter "$FILTROS_DIR/cite-to-xref.lua" \
        --wrap=none \
        -o "$OUTPUT" 2>&1

    if [ $? -ne 0 ]; then
        log_error "Pandoc falló al convertir el manuscrito."
        exit 1
    fi

    log_ok "PASO 1.2 - body-${BASE}.xml generado."
}

# ============================================================================
# FUNCIÓN: paso_1_3_generar_reflist
# DESCRIPCIÓN: CONVIERTE LA BIBLIOGRAFÍA BIBTEX AL FRAGMENTO ref-list EN JATS XML
#              USANDO PANDOC CON CITEPROC Y EL FILTRO LUA
# ============================================================================
paso_1_3_generar_reflist() {
    log_info "PASO 1.3 - Generando ref-list XML desde BibTeX..."

    local BIB_FILE="$DIR_PROYECTO/referencias/${BASE}.bib"
    local OUTPUT="$DIR_TMP/reflist-${BASE}.xml"

    if [ ! -f "$BIB_FILE" ]; then
        log_warn "Archivo BibTeX no encontrado: $BIB_FILE (se continuará sin referencias)"
        echo "<ref-list/>" > "$OUTPUT"
        log_ok "PASO 1.3 - ref-list vacío creado."
        return
    fi

    pandoc "$BIB_FILE" \
        --from bibtex \
        --to jats \
        --citeproc \
        --wrap=none \
        -o "$OUTPUT" 2>&1

    if [ $? -ne 0 ]; then
        log_error "Pandoc falló al convertir las referencias."
        exit 1
    fi

    log_ok "PASO 1.3 - reflist-${BASE}.xml generado."
}

# ============================================================================
# FUNCIÓN: paso_1_4_ensamblar_jats
# DESCRIPCIÓN: ENSAMBLA EL ARCHIVO JATS XML CANÓNICO COMPLETO
#              COMBINANDO FRONT + BODY + REF-LIST MEDIANTE XSLT CON SAXON-HE
#              EL ARCHIVO RESULTANTE TIENE EL PREFIJO c- (CANÓNICO)
# ============================================================================
paso_1_4_ensamblar_jats() {
    log_info "PASO 1.4 - Ensamblando JATS canónico con Saxon-HE..."

    local XSLT_ENSAMBLAR="$XSLT_DIR/ensamblar-jats.xsl"
    local OUTPUT="$DIR_JATS/c-${BASE}.xml"

    if [ ! -f "$XSLT_ENSAMBLAR" ]; then
        log_error "XSLT de ensamblado no encontrado: $XSLT_ENSAMBLAR"
        exit 1
    fi

    java -jar "$SAXON_JAR" \
        -s:"$DIR_TMP/front-${BASE}.xml" \
        -xsl:"$XSLT_ENSAMBLAR" \
        body="$DIR_TMP/body-${BASE}.xml" \
        reflist="$DIR_TMP/reflist-${BASE}.xml" \
        -o:"$OUTPUT" 2>&1

    if [ $? -ne 0 ]; then
        log_error "Saxon-HE falló al ensamblar el JATS canónico."
        exit 1
    fi

    log_ok "PASO 1.4 - c-${BASE}.xml ensamblado en $DIR_JATS"
}

# ============================================================================
# FUNCIÓN: paso_1_5_validar_dtd
# DESCRIPCIÓN: VALIDA EL ARCHIVO JATS CANÓNICO CONTRA EL DTD DE JATS 1.4
#              USANDO XMLLINT CON LA COPIA LOCAL DEL DTD
#              UN ERROR AQUÍ INDICA PROBLEMAS ESTRUCTURALES GRAVES
# ============================================================================
paso_1_5_validar_dtd() {
    log_info "PASO 1.5 - Validando contra DTD JATS 1.4..."

    local XML_FILE="$DIR_JATS/c-${BASE}.xml"

    xmllint --noout \
            --dtdvalid "$JATS_DTD" \
            "$XML_FILE" 2>&1

    if [ $? -ne 0 ]; then
        log_error "Validación DTD FALLÓ. El archivo no cumple JATS 1.4."
        log_error "Revise la estructura del XML en: $XML_FILE"
        exit 1
    fi

    log_ok "PASO 1.5 - Validación DTD JATS 1.4 superada."
}

# ============================================================================
# FUNCIÓN: paso_1_6_validar_schematron
# DESCRIPCIÓN: VALIDA EL ARCHIVO JATS CANÓNICO CONTRA LOS 16 SCHEMATRONS
#              JATS4R USANDO SCHXSLT + SAXON-HE
#              GENERA REPORTES SVRL INDIVIDUALES POR CADA SCHEMATRON
#              LOS ERRORES SON RECOMENDACIONES DE CALIDAD (NO ESTRUCTURALES)
# ============================================================================
paso_1_6_validar_schematron() {
    log_info "PASO 1.6 - Validando con Schematrons JATS4R..."

    local XML_FILE="$DIR_JATS/c-${BASE}.xml"
    local DIR_SVRL="$DIR_JATS/svrl-reports"
    local TOTAL_ERRORES=0
    local TOTAL_SCH=0

    # CREAR DIRECTORIO PARA REPORTES SVRL
    mkdir -p "$DIR_SVRL"

    # ITERAR SOBRE TODOS LOS SCHEMATRONS DISPONIBLES
    for SCH_FILE in "$SCH_DIR"/*-errors.sch; do
        local NOMBRE
        NOMBRE=$(basename "$SCH_FILE" .sch)
        local REPORTE="$DIR_SVRL/${NOMBRE}-svrl.xml"
        TOTAL_SCH=$((TOTAL_SCH + 1))

        # EJECUTAR PIPELINE SCHXSLT CON SAXON-HE
        # EL PARÁMETRO document= ES OBLIGATORIO PARA pipeline-for-svrl.xsl
        java -jar "$SAXON_JAR" \
            -s:"$SCH_FILE" \
            -xsl:"$SCHXSLT_XSL" \
            "document=$XML_FILE" \
            -o:"$REPORTE" 2>/dev/null

        # CONTAR ERRORES EN EL REPORTE SVRL
        local ERRORES
        ERRORES=$(grep -c "failed-assert" "$REPORTE" 2>/dev/null || echo 0)
        TOTAL_ERRORES=$((TOTAL_ERRORES + ERRORES))

        if [ "$ERRORES" -gt 0 ]; then
            log_warn "  $NOMBRE: $ERRORES error(es)"
            # MOSTRAR DETALLE DE ERRORES
            grep -o 'location="[^"]*"' "$REPORTE" | while read -r loc; do
                log_warn "    → $loc"
            done
        else
            log_ok "  $NOMBRE: sin errores"
        fi
    done

    echo ""
    log_info "Schematrons ejecutados: $TOTAL_SCH"
    log_info "Reportes SVRL en: $DIR_SVRL"

    if [ "$TOTAL_ERRORES" -gt 0 ]; then
        log_warn "PASO 1.6 - $TOTAL_ERRORES advertencia(s) JATS4R. Revisar reportes SVRL."
    else
        log_ok "PASO 1.6 - Todos los controles JATS4R superados."
    fi
}

# ============================================================================
# FUNCIÓN: mostrar_resumen_final
# DESCRIPCIÓN: IMPRIME UN RESUMEN DEL PIPELINE CON LOS ARCHIVOS GENERADOS
# ============================================================================
mostrar_resumen_final() {
    echo ""
    echo "============================================================================"
    log_info "PIPELINE COMPLETADO: $BASE"
    echo "============================================================================"
    echo ""
    echo "  Archivos generados:"
    echo "    TMP:  $DIR_TMP/front-${BASE}.xml"
    echo "    TMP:  $DIR_TMP/body-${BASE}.xml"
    echo "    TMP:  $DIR_TMP/reflist-${BASE}.xml"
    echo "    JATS: $DIR_JATS/c-${BASE}.xml"
    echo "    SVRL: $DIR_JATS/svrl-reports/"
    echo ""
    echo "  El archivo JATS canónico está listo para generación de salidas."
    echo "============================================================================"
}

# ============================================================================
# PUNTO DE ENTRADA PRINCIPAL
# ============================================================================
main() {
    # VERIFICAR ARGUMENTOS
    if [ $# -lt 2 ]; then
        echo "Uso: $0 <archivo-base> <directorio-proyecto>"
        echo "Ejemplo: $0 revistaAlgo-v01-n01 /home/usuario/00_Produccion/mi-proyecto"
        exit 1
    fi

    readonly BASE="$1"
    readonly DIR_PROYECTO="$2"

    # DIRECTORIOS DERIVADOS DEL PROYECTO
    readonly DIR_TMP="$DIR_PROYECTO/tmp"
    readonly DIR_JATS="$DIR_PROYECTO/jats"

    # CREAR DIRECTORIOS SI NO EXISTEN
    mkdir -p "$DIR_TMP" "$DIR_JATS"

    echo ""
    echo "============================================================================"
    log_info "gbpublisher - Pipeline JATS 1.4"
    log_info "Artículo: $BASE"
    log_info "Proyecto: $DIR_PROYECTO"
    echo "============================================================================"
    echo ""

    verificar_dependencias
    paso_1_1_generar_front
    paso_1_2_generar_body
    paso_1_3_generar_reflist
    paso_1_4_ensamblar_jats
    paso_1_5_validar_dtd
    paso_1_6_validar_schematron
    mostrar_resumen_final
}

main "$@"
