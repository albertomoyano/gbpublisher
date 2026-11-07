#!/bin/bash
# ============================================================================
# Script    : generar-schematron-jats4r.sh — gbpublisher
# Propósito : Genera .hidden/schemas/jats4r/: las reglas de JATS4R compiladas
#             a XSLT 2.0 en una sola hoja (jats4r.xsl), con los vocabularios
#             que esas reglas leen con document() al lado. Las usa
#             engine/validar_canonicos.sh para los canónicos de artículo
#             (etapa A0 de las salidas de revistas, claude/salidas-revistas.md).
#
# Es una herramienta de desarrollo: se corre a mano, desde la raíz del
# repositorio, cuando cambia la versión fijada de JATS4R o el esqueleto ISO.
# NO viaja en el .deb. Lo que viaja es su producto, que el validador lee de
# los recursos del sistema y nunca de ~/.gbpublisher (SC-11).
#
# USO
#   ./generar-schematron-jats4r.sh                 clona la versión fijada
#   ./generar-schematron-jats4r.sh <carpeta>       usa un clon local, que
#                                                  tiene que estar en el
#                                                  commit fijado
#
#   GBP_SAXON=/otra/ruta/saxon-he.jar ./generar-schematron-jats4r.sh
#   para probar con otra copia de Saxon (la misma variable que engine/comun.sh)
# ============================================================================
# LA VERSIÓN FIJADA
#
#   jats-schematrons v0.0.17, el commit de abajo. El nombre de la etiqueta no
#   alcanza: una etiqueta se puede mover. Se compara el commit, y si no es
#   el fijado no se compila. Cambiar de versión es cambiar las dos variables
#   y volver a correr el script: las instancias de prueba dicen si las reglas
#   nuevas siguen diciendo lo mismo.
#
# CÓMO
#
#   1. fuente       el clon, en el commit fijado
#   2. compilación  el maestro jats4r.sch con el esqueleto ISO del
#                   repositorio, en tres pasos: iso_dsdl_include (los
#                   <include> de los temáticos), iso_abstract_expand y
#                   iso_svrl_for_xslt2. Es la combinación de GV-26: el .xsl
#                   que publica JATS4R está mal compilado y SchXslt pierde
#                   funciones. Sin fase: corren todos los patrones, errores
#                   y advertencias (la severidad se lee de @role, GV-27)
#   3. vocabularios los .xml que las reglas leen con document() o doc()
#                   (credit-roles.xml, countries.xml, lang.xml…). Se buscan
#                   en los .sch, no se listan a mano, y van al lado de la
#                   hoja: con una cadena, los dos resuelven contra la hoja
#   4. cabecera     un comentario con el origen y las huellas de todo lo que
#                   entra en la hoja
#   5. verificación instancias de prueba con resultado conocido. Si alguna no
#                   da lo esperado, el producto nuevo NO reemplaza al anterior
#
# EL MAESTRO Y NO TEMÁTICO POR TEMÁTICO (GV-26)
#
#   GV-26 pide correr los temáticos por separado porque una regla de
#   coi-errors.sch aborta con XPTY0004 ante un <sec> con más de un <title>,
#   y eso hace perder el análisis del archivo entero. Ese riesgo es del
#   auditor, que lee XML ajenos de estructura imprevisible. Acá las reglas
#   corren solo sobre canónicos que gbpublisher escribe y que la DTD de JATS
#   1.4 controla en la misma pasada: la DTD no admite dos <title> en un
#   <sec>. Con el maestro, una JVM para todo el lote. Si igual abortara, el
#   validador lo informa como «no se comprobó», nunca como válido.
#
# Todo se escribe en temporales y el producto se pone con mv al final (el
# criterio de SC-53).
#
# CÓDIGOS
#   0  reglas compiladas y verificadas
#   1  no se generaron; las anteriores, si había, quedan intactas
# ============================================================================

set -uo pipefail

# --- 1. RUTAS DEL REPOSITORIO ---
# EL SCRIPT VIVE EN LA RAÍZ DEL REPOSITORIO: TODO SE RESUELVE DESDE AHÍ
DIR_REPO="$(dirname "$(readlink -f "$0")")"
DIR_OCULTO="$DIR_REPO/.hidden"

if ! source "$DIR_OCULTO/engine/comun.sh"; then
    echo "No se pudo cargar $DIR_OCULTO/engine/comun.sh" >&2
    exit 1
fi

# --- 2. LA VERSIÓN FIJADA ---
JATS4R_URL="https://github.com/JATS4R/jats-schematrons.git"
JATS4R_ETIQUETA="v0.0.17"
JATS4R_COMMIT="6589a03abc87eedd1156b7dc8acc39d5cda4dd3a"
# LA CARPETA DE LAS REGLAS DENTRO DEL CLON, Y EL MAESTRO
SUBCARPETA="schematrons/1.0"
MAESTRO="jats4r.sch"

DIR_ISO="$DIR_OCULTO/schematron/iso"
INCLUIR="$DIR_ISO/iso_dsdl_include.xsl"
EXPANDIR="$DIR_ISO/iso_abstract_expand.xsl"
ESQUELETO="$DIR_ISO/iso_svrl_for_xslt2.xsl"
# iso_svrl_for_xslt2.xsl IMPORTA EL ESQUELETO PARA SAXON: ENTRA EN LA HUELLA
# PORQUE TAMBIÉN DECIDE CÓMO SE COMPILA
ESQUELETO_BASE="$DIR_ISO/iso_schematron_skeleton_for_saxon.xsl"

DIR_ESQUEMAS="$DIR_OCULTO/schemas"
PRODUCTO="$DIR_ESQUEMAS/jats4r"
HOJA="jats4r.xsl"
# EN LA MISMA CARPETA QUE EL PRODUCTO: mv TIENE QUE SER UN RENOMBRE
TEMPORAL="$DIR_ESQUEMAS/.jats4r.tmp"
ANTERIOR="$DIR_ESQUEMAS/.jats4r.anterior"

# LOS INTERMEDIOS VAN A UNA CARPETA PROPIA, QUE SE BORRA AL SALIR
DIR_TRABAJO="$(mktemp -d)" || { echo "No se pudo crear una carpeta temporal" >&2; exit 1; }
trap 'rm -rf "$DIR_TRABAJO" "$TEMPORAL"' EXIT

TIEMPO_SAXON=300
TIEMPO_GIT=120

NS_SVRL_HALLAZGO='//*[local-name()="failed-assert" or local-name()="successful-report"]'

# ============================================================================
# Función   : saxon
# Propósito : Corre Saxon con un plazo y devuelve su código. La salida de
#             Saxon queda en $DIR_TRABAJO/saxon.log para mostrarla si falla.
# Parámetros: los de la línea de órdenes de Saxon
# Retorna   : el código de Saxon (124 si venció el plazo)
# ============================================================================
saxon() {
    timeout "$TIEMPO_SAXON" java -jar "$RUTA_SAXON" "$@" > "$DIR_TRABAJO/saxon.log" 2>&1
}

# ============================================================================
# Función   : es_svrl
# Propósito : Responde si un archivo es un informe SVRL y no otra cosa.
# Parámetros: $1 ruta
# Retorna   : 0 si la raíz es schematron-output
# Nota      : GV-28: UNA VEZ SE CONTARON LOS failed-assert DE LA HOJA
#             COMPILADA CREYENDO QUE ERAN EL INFORME
# ============================================================================
es_svrl() {
    [[ "$(xmllint --xpath 'local-name(/*)' "$1" 2>/dev/null)" == "schematron-output" ]]
}

# ============================================================================
# Función   : probar
# Propósito : Corre la hoja temporal sobre una instancia de prueba y compara
#             lo que informa con lo esperado: la cantidad de hallazgos y, si
#             se espera uno, su severidad y su texto exactos.
# Parámetros: $1 nombre de la instancia (sin .xml)  $2 cantidad esperada
#             $3 severidad esperada (error | warning), o «-»
#             $4 texto esperado, o «-»
# Retorna   : 0 si dio lo esperado; 1 si no, con el motivo impreso
# Nota      : EL TEXTO Y NO SOLO LA CANTIDAD: UNA REGLA EQUIVOCADA QUE FALLA
#             POR CASUALIDAD DARÍA LA MISMA CUENTA. LA INSTANCIA VA SIN
#             DOCTYPE: CON EL DE JATS, SAXON SALE A BUSCAR LA DTD A LA RED
#             (GV-25)
# ============================================================================
probar() {
    local nombre="$1" esperado="$2" severidad="$3" mensaje="$4"
    local informe="$DIR_TRABAJO/$nombre.svrl" cantidad rol texto

    if ! saxon -s:"$DIR_TRABAJO/$nombre.xml" -xsl:"$TEMPORAL/$HOJA" -o:"$informe"; then
        mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
        printf '  %s✗%s %s: la hoja no pudo ejecutarse\n' "$C_ERROR" "$C_RESET" "$nombre"
        return 1
    fi
    if ! es_svrl "$informe"; then
        printf '  %s✗%s %s: la salida no es un informe SVRL\n' "$C_ERROR" "$C_RESET" "$nombre"
        return 1
    fi

    cantidad="$(xmllint --xpath "count($NS_SVRL_HALLAZGO)" "$informe" 2>/dev/null)"
    if [[ "$cantidad" != "$esperado" ]]; then
        printf '  %s✗%s %s: %s hallazgo(s), se esperaba(n) %s\n' \
            "$C_ERROR" "$C_RESET" "$nombre" "${cantidad:-?}" "$esperado"
        return 1
    fi
    if [[ "$severidad" != "-" ]]; then
        rol="$(xmllint --xpath "string(($NS_SVRL_HALLAZGO)[1]/@role)" "$informe" 2>/dev/null)"
        texto="$(xmllint --xpath "normalize-space(($NS_SVRL_HALLAZGO)[1]/*[local-name()='text'])" "$informe" 2>/dev/null)"
        if [[ "$rol" != "$severidad" ]]; then
            printf '  %s✗%s %s: la severidad fue «%s», se esperaba «%s»\n' \
                "$C_ERROR" "$C_RESET" "$nombre" "$rol" "$severidad"
            return 1
        fi
        if [[ "$texto" != "$mensaje" ]]; then
            printf '  %s✗%s %s: el mensaje fue «%s», se esperaba «%s»\n' \
                "$C_ERROR" "$C_RESET" "$nombre" "$texto" "$mensaje"
            return 1
        fi
    fi
    if [[ "$severidad" == "-" ]]; then
        ok "$nombre: $esperado hallazgo(s), como se esperaba"
    else
        ok "$nombre: $esperado hallazgo(s) ($severidad), como se esperaba"
    fi
    return 0
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "REGLAS DE JATS4R COMPILADAS"

# --- 3. ENTORNO ---
paso "verificando el entorno"

requerir_comandos java xmllint sha256sum timeout git

[[ -f "$RUTA_SAXON" ]]     || morir "Saxon-HE no está en $RUTA_SAXON"
for hoja in "$INCLUIR" "$EXPANDIR" "$ESQUELETO" "$ESQUELETO_BASE"; do
    [[ -f "$hoja" ]] || morir "No se encontró el esqueleto ISO: $hoja"
done

VERSION_SAXON="$(java -jar "$RUTA_SAXON" -? 2>&1 | grep -m1 -o 'SaxonJ-HE [0-9.]*')"
[[ -n "$VERSION_SAXON" ]] || morir "No se pudo leer la versión de Saxon en $RUTA_SAXON"

ok "herramientas y esqueleto ISO"
tenue "$VERSION_SAXON"

# --- 4. LA FUENTE, EN EL COMMIT FIJADO ---
paso "fuente: jats-schematrons $JATS4R_ETIQUETA"

if (( $# >= 1 )); then
    DIR_CLON="$(readlink -f "$1")"
    [[ -d "$DIR_CLON/.git" ]] || morir "$1 no es un clon de git de jats-schematrons"
    tenue "clon local: $DIR_CLON"
else
    DIR_CLON="$DIR_TRABAJO/jats-schematrons"
    timeout "$TIEMPO_GIT" git clone --quiet --depth 1 --branch "$JATS4R_ETIQUETA" \
        "$JATS4R_URL" "$DIR_CLON" > "$DIR_TRABAJO/git.log" 2>&1 || {
        mostrar_cola "$(cat "$DIR_TRABAJO/git.log")"
        morir "No se pudo clonar $JATS4R_URL en $JATS4R_ETIQUETA"
    }
fi

COMMIT="$(git -C "$DIR_CLON" rev-parse HEAD 2>/dev/null)"
[[ "$COMMIT" == "$JATS4R_COMMIT" ]] ||
    morir "El clon está en ${COMMIT:-?} y la versión fijada es $JATS4R_COMMIT ($JATS4R_ETIQUETA)"

DIR_FUENTE="$DIR_CLON/$SUBCARPETA"
[[ -f "$DIR_FUENTE/$MAESTRO" ]] || morir "No está $SUBCARPETA/$MAESTRO en el clon"
bien_formado "$DIR_FUENTE/$MAESTRO" || morir "$MAESTRO está mal formado"

ok "commit $JATS4R_COMMIT"

# --- 5. COMPILACIÓN ---
paso "compilando el maestro con el esqueleto ISO"

saxon -s:"$DIR_FUENTE/$MAESTRO" -xsl:"$INCLUIR" -o:"$DIR_TRABAJO/paso1.sch" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "iso_dsdl_include no pudo resolver los <include>"
}
saxon -s:"$DIR_TRABAJO/paso1.sch" -xsl:"$EXPANDIR" -o:"$DIR_TRABAJO/paso2.sch" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "iso_abstract_expand no pudo expandir los patrones abstractos"
}

# TODOS LOS TEMÁTICOS TIENEN QUE HABER ENTRADO: LOS <include> DEL MAESTRO Y
# LOS PATRONES DEL RESULTADO. SIN NÚMEROS FIJOS: OTRA VERSIÓN PUEDE TRAER
# OTRA CANTIDAD
INCLUIDOS="$(xmllint --xpath 'count(/*/*[local-name()="include"])' "$DIR_FUENTE/$MAESTRO")"
PATRONES="$(xmllint --xpath 'count(/*/*[local-name()="pattern"])' "$DIR_TRABAJO/paso2.sch")"
RESTOS="$(xmllint --xpath 'count(//*[local-name()="include"])' "$DIR_TRABAJO/paso2.sch")"
(( INCLUIDOS > 0 )) || morir "$MAESTRO no incluye ningún temático"
[[ "$RESTOS" == "0" ]] || morir "Quedaron $RESTOS <include> sin resolver"
(( PATRONES >= INCLUIDOS )) || morir "Entraron $PATRONES patrones de $INCLUIDOS temáticos"

mkdir -p "$TEMPORAL" || morir "No se pudo crear $TEMPORAL"
saxon -s:"$DIR_TRABAJO/paso2.sch" -xsl:"$ESQUELETO" -o:"$DIR_TRABAJO/compilada.xsl" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "El esqueleto ISO no pudo compilar el Schematron"
}
bien_formado "$DIR_TRABAJO/compilada.xsl" || morir "La compilación produjo un XSLT mal formado"

ok "$INCLUIDOS temáticos, $PATRONES patrones"

# --- 6. VOCABULARIOS ---
# LOS QUE LAS REGLAS LEEN CON document('…') O doc('…'): LAS DOS FORMAS ESTÁN
# EN v0.0.17 (credit-roles.xml CON LA PRIMERA, lang.xml CON LA SEGUNDA). SE
# BUSCAN EN LOS .sch PARA QUE UNA VERSIÓN NUEVA QUE SUME UNO NO QUEDE SIN SU
# ARCHIVO
paso "vocabularios que leen las reglas"

VOCABULARIOS=()
while IFS= read -r nombre; do
    [[ -n "$nombre" ]] && VOCABULARIOS+=("$nombre")
done < <(grep -ohP "\b(?:document|doc)\(\s*'\K[^']+(?='\s*\))" "$DIR_FUENTE"/*.sch | sort -u)

for nombre in "${VOCABULARIOS[@]}"; do
    # UN NOMBRE CON / SALDRÍA DE LA CARPETA DE LA FUENTE
    [[ "$nombre" == */* ]] && morir "Un document() de las reglas apunta fuera de su carpeta: $nombre"
    [[ -f "$DIR_FUENTE/$nombre" ]] || morir "Las reglas leen $nombre y no está en la fuente"
    bien_formado "$DIR_FUENTE/$nombre" || morir "$nombre está mal formado"
    cp "$DIR_FUENTE/$nombre" "$TEMPORAL/$nombre" || morir "No se pudo copiar $nombre"
done
ok "${#VOCABULARIOS[@]} vocabulario(s): ${VOCABULARIOS[*]}"

# --- 7. CABECERA ---
# UN COMENTARIO ANTES DE LA RAÍZ CON EL ORIGEN. SE PONE CON UNA COPIA
# IDENTIDAD Y NO CON sed: LA SALIDA DEL ESQUELETO PUEDE NO TENER SALTO DE
# LÍNEA DESPUÉS DE LA DECLARACIÓN XML (EL MISMO CRITERIO QUE
# generar-schematron-canonico.sh). EL TEXTO VA EN UN ARCHIVO Y NO EN LA LÍNEA
# DE ÓRDENES: JAVA DECODIFICA LOS ARGUMENTOS CON LA CODIFICACIÓN DEL SISTEMA,
# Y CON UNA QUE NO ES UTF-8 LAS TILDES LLEGAN ROTAS (MEDIDO CON LC_CTYPE=POSIX)
paso "escribiendo la cabecera"

cat > "$DIR_TRABAJO/cabecera.xsl" <<'XSL'
<?xml version="1.0" encoding="UTF-8"?>
<!-- COPIA LA HOJA COMPILADA TAL CUAL Y LE ANTEPONE UN COMENTARIO -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:param name="texto" required="yes"/>
  <xsl:template match="/">
    <xsl:comment select="unparsed-text($texto, 'UTF-8')"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:copy-of select="node()"/>
  </xsl:template>
</xsl:stylesheet>
XSL

HUELLAS_VOCABULARIOS=""
for nombre in "${VOCABULARIOS[@]}"; do
    HUELLAS_VOCABULARIOS+="
             $nombre
             sha256 $(sha256sum "$DIR_FUENTE/$nombre" | cut -d' ' -f1)"
done

CABECERA="
  GENERADO POR generar-schematron-jats4r.sh. NO EDITAR A MANO: SE REGENERA
  DESDE LA VERSIÓN FIJADA DE jats-schematrons (SC-11, GV-26).

  Reglas de JATS4R para los canónicos de artículo: el maestro $MAESTRO con
  todos sus temáticos, sin fase (errores y advertencias; la severidad va en
  @role, GV-27), compilado a XSLT 2.0 con el esqueleto ISO.

  fuente     $JATS4R_URL
             $JATS4R_ETIQUETA, commit $JATS4R_COMMIT
  maestro    $SUBCARPETA/$MAESTRO
             sha256 $(sha256sum "$DIR_FUENTE/$MAESTRO" | cut -d' ' -f1)
  vocabularios (al lado de esta hoja: document() resuelve contra ella)$HUELLAS_VOCABULARIOS
  esqueleto  $(basename "$INCLUIR")
             sha256 $(sha256sum "$INCLUIR" | cut -d' ' -f1)
             $(basename "$EXPANDIR")
             sha256 $(sha256sum "$EXPANDIR" | cut -d' ' -f1)
             $(basename "$ESQUELETO")
             sha256 $(sha256sum "$ESQUELETO" | cut -d' ' -f1)
             $(basename "$ESQUELETO_BASE")
             sha256 $(sha256sum "$ESQUELETO_BASE" | cut -d' ' -f1)
  patrones   $PATRONES de $INCLUIDOS temáticos
  compilado  $VERSION_SAXON, $(date '+%Y-%m-%d')
"

printf '%s' "$CABECERA" > "$DIR_TRABAJO/cabecera.txt" || morir "No se pudo escribir el texto de la cabecera"
saxon -s:"$DIR_TRABAJO/compilada.xsl" -xsl:"$DIR_TRABAJO/cabecera.xsl" -o:"$TEMPORAL/$HOJA" \
    texto="$DIR_TRABAJO/cabecera.txt" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "No se pudo escribir la cabecera"
}
bien_formado "$TEMPORAL/$HOJA" || morir "La hoja con cabecera está mal formada"

ok "cabecera con el origen y las huellas"

# --- 8. VERIFICACIÓN ---
# INSTANCIAS CON RESULTADO CONOCIDO, CON LA FORMA DEL CANÓNICO QUE ESCRIBE
# datos-a-front-jats.xsl. SE PRUEBA LA HOJA TEMPORAL, LA QUE SE VA A PONER:
# SI FALLA, NO REEMPLAZA A LA ANTERIOR. CADA UNA QUE INCUMPLE ES LA LIMPIA
# CON UN SOLO CAMBIO. credit-mal, pais-mal E idioma-mal PRUEBAN ADEMÁS QUE
# LOS VOCABULARIOS ESTÁN AL LADO DE LA HOJA: SIN credit-roles.xml,
# countries.xml O lang.xml, EL HALLAZGO NO SALE O LA HOJA ABORTA.
# clinical-trial-registries.xml NO TIENE INSTANCIA: SE COMPRUEBA SOLO QUE
# ESTÉ Y ESTÉ BIEN FORMADO (APARTADO 6)
paso "verificando con instancias de prueba"

ABRE='<article xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ali="http://www.niso.org/schemas/ali/1.0/" dtd-version="1.4" article-type="research-article" xml:lang="es"><front><journal-meta><journal-id journal-id-type="publisher-id">rp</journal-id><journal-title-group><journal-title>Revista</journal-title></journal-title-group><issn pub-type="epub">1234-5678</issn><publisher><publisher-name>Editorial</publisher-name></publisher></journal-meta><article-meta><title-group><article-title>Título</article-title></title-group><contrib-group><contrib contrib-type="author"><name><surname>Pérez</surname><given-names>Ana</given-names></name>'
ROL=''
AFILIACION=''
MEDIO='</contrib></contrib-group><pub-date publication-format="electronic" date-type="pub"><year>2026</year></pub-date><volume>1</volume><issue>1</issue><elocation-id>e1</elocation-id><permissions><copyright-statement>© 2026 Ana Pérez</copyright-statement><copyright-year>2026</copyright-year><copyright-holder>Ana Pérez</copyright-holder><license><ali:license_ref>https://creativecommons.org/licenses/by/4.0/</ali:license_ref><license-p>CC BY 4.0</license-p></license></permissions><abstract><p>Resumen.</p></abstract>'
FINANCIAMIENTO=''
CIERRA='</article-meta></front><body><sec><title>Uno</title><p>Texto.</p>'
FIN='</sec></body></article>'

# ============================================================================
# Función   : instancia
# Propósito : Escribe una instancia de prueba con las piezas de arriba.
# Parámetros: $1 nombre  $2 rol  $3 afiliación (va después del cierre del
#             contrib, dentro de contrib-group)  $4 financiamiento
#             $5 un bloque más en la sección del cuerpo
# ============================================================================
instancia() {
    local medio="$MEDIO"
    [[ -n "$3" ]] && medio="${medio/<\/contrib><\/contrib-group>/<\/contrib>$3<\/contrib-group>}"
    printf '<?xml version="1.0" encoding="UTF-8"?>\n%s%s%s%s%s%s%s\n' \
        "$ABRE" "$2" "$medio" "$4" "$CIERRA" "$5" "$FIN" > "$DIR_TRABAJO/$1.xml"
}

instancia limpia "" "" "" ""
instancia credit-mal \
    '<role vocab="credit" vocab-identifier="http://credit.niso.org/" vocab-term="Methodology" vocab-term-identifier="https://credit.niso.org/contributor-roles/methodology/">Metodología</role>' "" "" ""
instancia financiador-mal "" "" \
    '<funding-group><award-group><funding-source><institution-wrap><institution-id institution-id-type="doi" vocab="open-funder-registry" vocab-identifier="10.13039/open_funder_registry">https://doi.org/10.13039/501100002923</institution-id><institution>CONICET</institution></institution-wrap></funding-source></award-group></funding-group>' ""
instancia pais-mal '<xref ref-type="aff" rid="af1"/>' \
    '<aff id="af1"><institution>UNC</institution><country country="XX">Argentina</country></aff>' "" ""
instancia idioma-mal "" "" "" '<boxed-text id="r1" xml:lang="zz"><p>Recuadro.</p></boxed-text>'

fallidas=0
probar limpia 0 - - || fallidas=$((fallidas + 1))
probar credit-mal 1 error \
    "A CRediT taxonomy role must have a @vocab-identifier whose value is https://credit.niso.org/." ||
    fallidas=$((fallidas + 1))
probar financiador-mal 1 error \
    "The value of <institution vocab=\"open-funder-registry\"> in JATS 1.4 must start with '10.13039/'." ||
    fallidas=$((fallidas + 1))
probar pais-mal 1 warning \
    "<country> should have a @country that includes the ISO 3166-1 2-letter country code." ||
    fallidas=$((fallidas + 1))
probar idioma-mal 1 error \
    "<boxed-text> has an xml:lang attribute, whose value (zz) is not one of the IETF RFC 5646 values." ||
    fallidas=$((fallidas + 1))

if (( fallidas > 0 )); then
    morir "$fallidas instancia(s) de prueba no dieron lo esperado: las reglas anteriores se conservan"
fi

# --- 9. REEMPLAZO ---
# LA CARPETA ENTERA: LA HOJA Y SUS VOCABULARIOS VAN JUNTOS. LA ANTERIOR SE
# APARTA PRIMERO Y SE BORRA SOLO CUANDO LA NUEVA YA ESTÁ EN SU LUGAR
rm -rf "$ANTERIOR"
if [[ -d "$PRODUCTO" ]]; then
    mv "$PRODUCTO" "$ANTERIOR" || morir "No se pudo apartar $PRODUCTO"
fi
if ! mv "$TEMPORAL" "$PRODUCTO"; then
    [[ -d "$ANTERIOR" ]] && mv "$ANTERIOR" "$PRODUCTO"
    morir "No se pudo poner $PRODUCTO: las reglas anteriores se conservan"
fi
rm -rf "$ANTERIOR"

echo
titulo "$REGLA"
printf '%s✓ Reglas de JATS4R compiladas y verificadas%s\n' "$C_OK" "$C_RESET"
# ETIQUETAS CON SU RELLENO ESCRITO: printf CUENTA BYTES Y NO CARACTERES
printf '  Carpeta:    %s\n' "$PRODUCTO"
printf '  Versión:    %s (%s)\n' "$JATS4R_ETIQUETA" "${JATS4R_COMMIT:0:12}"
printf '  Patrones:   %s de %s temáticos\n' "$PATRONES" "$INCLUIDOS"
echo

terminar
