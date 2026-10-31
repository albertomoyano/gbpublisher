#!/bin/bash
# ============================================================================
# Script    : generar-schematron-canonico.sh — gbpublisher
# Propósito : Genera .hidden/schemas/schematron-canonico.xsl: el Schematron
#             del canónico DocBook compilado a XSLT. Junta en una sola hoja
#             las reglas que el RNG de DocBook 5.2 trae embebidas (GV-XML-03)
#             y las propias de gbpublisher (schemas/gbpublisher/
#             gbpublisher.sch), para que el validador las corra con una sola
#             JVM por lote (SC-75).
#
# Reemplaza a generar-schematron-docbook.sh, que compilaba solo las de
# DocBook en schemas/docbook/docbook-sch.xsl.
#
# Es una herramienta de desarrollo: se corre a mano, desde la raíz del
# repositorio, cada vez que cambian el RNG, gbpublisher.sch o el esqueleto
# ISO. NO viaja en el .deb. Lo que viaja es su producto, que el validador lee
# de los recursos del sistema y nunca de ~/.gbpublisher (SC-11).
#
# USO
#   ./generar-schematron-canonico.sh
#
#   GBP_SAXON=/otra/ruta/saxon-he.jar ./generar-schematron-canonico.sh
#   para probar con otra copia de Saxon (la misma variable que engine/comun.sh)
# ============================================================================
# CÓMO
#
#   1. extracción   una hoja XSLT 2.0 junta en un <s:schema queryBinding=
#                   "xslt2"> los s:ns y los s:pattern del RNG y los de
#                   gbpublisher.sch, sin repetir prefijos. Los patrones de
#                   DocBook no traen @id; los propios llevan el prefijo gbp-,
#                   que es lo que el validador usa para separarlos
#   2. compilación  iso_svrl_for_xslt2.xsl del repositorio
#   3. cabecera     un comentario con el origen y las huellas de todo lo que
#                   entra en la hoja
#   4. verificación instancias de prueba con resultado conocido: cuatro para
#                   DocBook (GV-XML-02) y dos para las reglas propias. Si
#                   alguna no da lo esperado, la hoja nueva NO reemplaza a la
#                   anterior
#
#   Todo se escribe en temporales y el producto se pone con mv al final (el
#   criterio de SC-53).
#
# CÓDIGOS
#   0  hoja generada y verificada
#   1  no se generó; la anterior, si había, queda intacta
# ============================================================================

set -uo pipefail

# --- 1. RUTAS DEL REPOSITORIO ---
# EL SCRIPT VIVE EN LA RAÍZ DEL REPOSITORIO: TODO SE RESUELVE DESDE AHÍ, NO
# DESDE EL DIRECTORIO DESDE EL QUE SE LO LLAMA
DIR_REPO="$(dirname "$(readlink -f "$0")")"
DIR_OCULTO="$DIR_REPO/.hidden"

if ! source "$DIR_OCULTO/engine/comun.sh"; then
    echo "No se pudo cargar $DIR_OCULTO/engine/comun.sh" >&2
    exit 1
fi

DIR_ESQUEMAS="$DIR_OCULTO/schemas"
# readlink -f: docbook.rng ES UN ENLACE A docbook.rng-5.2. LA HUELLA Y EL
# NOMBRE DE LA CABECERA TIENEN QUE SER LOS DEL ARCHIVO REAL
RNG="$(readlink -f "$DIR_ESQUEMAS/docbook/docbook.rng")"
PROPIAS="$DIR_ESQUEMAS/gbpublisher/gbpublisher.sch"
ESQUELETO="$DIR_OCULTO/schematron/iso/iso_svrl_for_xslt2.xsl"
# iso_svrl_for_xslt2.xsl IMPORTA EL ESQUELETO PARA SAXON: ENTRA EN LA HUELLA
# PORQUE TAMBIÉN DECIDE CÓMO SE COMPILA
ESQUELETO_BASE="$DIR_OCULTO/schematron/iso/iso_schematron_skeleton_for_saxon.xsl"

PRODUCTO="$DIR_ESQUEMAS/schematron-canonico.xsl"
# EN LA MISMA CARPETA QUE EL PRODUCTO: mv TIENE QUE SER UN RENOMBRE
TEMPORAL="$DIR_ESQUEMAS/.schematron-canonico.xsl.tmp"

# LOS INTERMEDIOS VAN A UNA CARPETA PROPIA, QUE SE BORRA AL SALIR
DIR_TRABAJO="$(mktemp -d)" || { echo "No se pudo crear una carpeta temporal" >&2; exit 1; }
trap 'rm -rf "$DIR_TRABAJO"; rm -f "$TEMPORAL"' EXIT

TIEMPO_SAXON=300

NS_SVRL_ID='//*[local-name()="failed-assert" or local-name()="successful-report"]'

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
# Función   : correr_instancia
# Propósito : Corre la hoja temporal sobre una instancia de prueba y deja el
#             informe en $DIR_TRABAJO/{nombre}.svrl.
# Parámetros: $1 nombre de la instancia (sin .xml)
# Retorna   : 0 si hay informe SVRL; 1 si no, con el motivo impreso
# ============================================================================
correr_instancia() {
    local nombre="$1"
    if ! saxon -s:"$DIR_TRABAJO/$nombre.xml" -xsl:"$TEMPORAL" -o:"$DIR_TRABAJO/$nombre.svrl"; then
        mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
        printf '  %s✗%s %s: la hoja no pudo ejecutarse\n' "$C_ERROR" "$C_RESET" "$nombre"
        return 1
    fi
    if ! es_svrl "$DIR_TRABAJO/$nombre.svrl"; then
        printf '  %s✗%s %s: la salida no es un informe SVRL\n' "$C_ERROR" "$C_RESET" "$nombre"
        return 1
    fi
    return 0
}

# ============================================================================
# Función   : probar_docbook
# Propósito : Una instancia que incumple, como mucho, UNA regla de DocBook:
#             compara la cantidad de incumplimientos de DocBook (los que no
#             traen @id gbp-) y, si se espera uno, su mensaje exacto.
# Parámetros: $1 nombre  $2 cantidad esperada  $3 mensaje, o «-»
# Retorna   : 0 si dio lo esperado; 1 si no, con el motivo impreso
# Nota      : EL MENSAJE Y NO SOLO LA CANTIDAD: UNA REGLA EQUIVOCADA QUE FALLA
#             POR CASUALIDAD DARÍA LA MISMA CUENTA
# ============================================================================
probar_docbook() {
    local nombre="$1" esperado="$2" mensaje="$3"
    local informe="$DIR_TRABAJO/$nombre.svrl" cantidad texto

    correr_instancia "$nombre" || return 1

    cantidad="$(xmllint --xpath "count($NS_SVRL_ID[not(starts-with(@id, 'gbp-'))])" "$informe" 2>/dev/null)"
    if [[ "$cantidad" != "$esperado" ]]; then
        printf '  %s✗%s %s: %s incumplimiento(s) de DocBook, se esperaba(n) %s\n' \
            "$C_ERROR" "$C_RESET" "$nombre" "${cantidad:-?}" "$esperado"
        return 1
    fi
    if [[ "$mensaje" != "-" ]]; then
        texto="$(xmllint --xpath "normalize-space(($NS_SVRL_ID[not(starts-with(@id, 'gbp-'))])[1]/*[local-name()='text'])" "$informe" 2>/dev/null)"
        if [[ "$texto" != "$mensaje" ]]; then
            printf '  %s✗%s %s: el mensaje fue «%s», se esperaba «%s»\n' \
                "$C_ERROR" "$C_RESET" "$nombre" "$texto" "$mensaje"
            return 1
        fi
    fi
    ok "$nombre: $esperado incumplimiento(s) de DocBook, como se esperaba"
    return 0
}

# ============================================================================
# Función   : probar_propias
# Propósito : Una instancia para las reglas propias: el CONJUNTO de @id gbp-
#             que incumple tiene que ser exactamente el esperado, y ninguna
#             regla de DocBook puede fallar.
# Parámetros: $1 nombre  $2 los @id esperados, separados por espacios, o «-»
#             para ninguno
# Retorna   : 0 si dio lo esperado; 1 si no, con el motivo impreso
# Nota      : EL CONJUNTO Y NO LA CANTIDAD: UNA REGLA QUE DEJA DE DISPARAR Y
#             OTRA QUE DISPARA DE MÁS DARÍAN LA MISMA CUENTA
# ============================================================================
probar_propias() {
    local nombre="$1" esperado="$2"
    local informe="$DIR_TRABAJO/$nombre.svrl" obtenido docbook

    correr_instancia "$nombre" || return 1

    docbook="$(xmllint --xpath "count($NS_SVRL_ID[not(starts-with(@id, 'gbp-'))])" "$informe" 2>/dev/null)"
    if [[ "$docbook" != "0" ]]; then
        printf '  %s✗%s %s: falla(n) %s regla(s) de DocBook y la instancia tiene que ser válida\n' \
            "$C_ERROR" "$C_RESET" "$nombre" "${docbook:-?}"
        return 1
    fi

    # LOS @id, ORDENADOS Y SIN REPETIR, EN UNA LÍNEA
    obtenido="$(xmllint --xpath "$NS_SVRL_ID/@id" "$informe" 2>/dev/null |
                grep -oP 'id="\Kgbp-[^"]+' | sort -u | tr '\n' ' ' | sed 's/ $//')"
    [[ "$esperado" == "-" ]] && esperado=""
    esperado="$(printf '%s\n' $esperado | grep . | sort -u | tr '\n' ' ' | sed 's/ $//')"

    if [[ "$obtenido" != "$esperado" ]]; then
        printf '  %s✗%s %s: incumple «%s», se esperaba «%s»\n' \
            "$C_ERROR" "$C_RESET" "$nombre" "$obtenido" "$esperado"
        return 1
    fi
    ok "$nombre: ${esperado:-ninguna regla propia}, como se esperaba"
    return 0
}

# ============================================================================
# ORQUESTACIÓN
# ============================================================================

encabezado "SCHEMATRON DEL CANÓNICO COMPILADO"

# --- 2. ENTORNO ---
paso "verificando el entorno"

requerir_comandos java xmllint sha256sum timeout

[[ -f "$RUTA_SAXON" ]]     || morir "Saxon-HE no está en $RUTA_SAXON"
[[ -f "$RNG" ]]            || morir "No se encontró el RNG de DocBook: $DIR_ESQUEMAS/docbook/docbook.rng"
[[ -f "$PROPIAS" ]]        || morir "No se encontraron las reglas propias: $PROPIAS"
[[ -f "$ESQUELETO" ]]      || morir "No se encontró el esqueleto ISO: $ESQUELETO"
[[ -f "$ESQUELETO_BASE" ]] || morir "No se encontró el esqueleto ISO para Saxon: $ESQUELETO_BASE"
bien_formado "$RNG"        || morir "El RNG está mal formado: $RNG"
bien_formado "$PROPIAS"    || morir "Las reglas propias están mal formadas: $PROPIAS"

VERSION_SAXON="$(java -jar "$RUTA_SAXON" -? 2>&1 | grep -m1 -o 'SaxonJ-HE [0-9.]*')"
[[ -n "$VERSION_SAXON" ]] || morir "No se pudo leer la versión de Saxon en $RUTA_SAXON"

ok "herramientas, RNG, reglas propias y esqueleto"
tenue "$VERSION_SAXON"

# --- 3. EXTRACCIÓN Y UNIÓN ---
# LA HOJA VA ACÁ Y NO EN UN ARCHIVO DEL REPOSITORIO: ES PARTE DE ESTE
# PROCEDIMIENTO Y NO TIENE OTRO USO
paso "juntando las reglas de DocBook y las propias"

cat > "$DIR_TRABAJO/juntar.xsl" <<'XSL'
<?xml version="1.0" encoding="UTF-8"?>
<!-- JUNTA EN UN DOCUMENTO SCHEMATRON LAS DECLARACIONES Y LOS PATRONES QUE EL
     RNG DE DocBook TRAE EMBEBIDOS (LA ENTRADA) Y LOS DE gbpublisher.sch (EL
     PARÁMETRO propias) -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:s="http://purl.oclc.org/dsdl/schematron">
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:param name="propias" required="yes"/>
  <xsl:template match="/">
    <xsl:variable name="gbp" select="doc($propias)/s:schema"/>
    <s:schema queryBinding="xslt2">
      <!-- UN s:ns POR PREFIJO: LOS DOS DECLARAN db, Y UN PREFIJO REPETIDO
           HARÍA FALLAR LA COMPILACIÓN. SI DOS DECLARACIONES DEL MISMO PREFIJO
           APUNTARAN A ESPACIOS DISTINTOS, SE FRENA: ELEGIR UNO SERÍA
           CAMBIAR EN SILENCIO EL SENTIDO DE LAS REGLAS -->
      <xsl:for-each-group select="//s:ns | $gbp/s:ns" group-by="@prefix">
        <xsl:if test="count(distinct-values(current-group()/@uri)) gt 1">
          <xsl:message terminate="yes">El prefijo <xsl:value-of select="current-grouping-key()"/> está declarado con espacios de nombres distintos</xsl:message>
        </xsl:if>
        <xsl:copy-of select="current-group()[1]"/>
      </xsl:for-each-group>
      <xsl:copy-of select="//s:pattern"/>
      <xsl:copy-of select="$gbp/s:pattern"/>
    </s:schema>
  </xsl:template>
</xsl:stylesheet>
XSL

saxon -s:"$RNG" -xsl:"$DIR_TRABAJO/juntar.xsl" -o:"$DIR_TRABAJO/canonico.sch" propias="$PROPIAS" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "Saxon no pudo juntar las reglas"
}

# TODOS LOS PATRONES TIENEN QUE LLEGAR AL DOCUMENTO: SE CUENTAN EN LAS
# FUENTES Y EN EL RESULTADO. SIN NÚMEROS FIJOS: UN RNG O UN .sch NUEVO PUEDE
# TRAER OTRA CANTIDAD
PATRONES_RNG="$(xmllint --xpath 'count(//*[local-name()="pattern"][namespace-uri()="http://purl.oclc.org/dsdl/schematron"])' "$RNG")"
PATRONES_GBP="$(xmllint --xpath 'count(/*/*[local-name()="pattern"])' "$PROPIAS")"
PATRONES_SCH="$(xmllint --xpath 'count(/*/*[local-name()="pattern"])' "$DIR_TRABAJO/canonico.sch")"
NS_SCH="$(xmllint --xpath 'count(/*/*[local-name()="ns"])' "$DIR_TRABAJO/canonico.sch")"

(( PATRONES_RNG > 0 )) || morir "El RNG no trae reglas Schematron: ¿es el de DocBook 5.2?"
(( PATRONES_GBP > 0 )) || morir "gbpublisher.sch no trae patrones"
[[ "$PATRONES_SCH" == "$(( PATRONES_RNG + PATRONES_GBP ))" ]] ||
    morir "El documento tiene $PATRONES_SCH patrones y se esperaban $PATRONES_RNG + $PATRONES_GBP"

ok "$PATRONES_RNG patrones de DocBook, $PATRONES_GBP propios y $NS_SCH espacios de nombres"

# --- 4. COMPILACIÓN ---
paso "compilando con el esqueleto ISO"

saxon -s:"$DIR_TRABAJO/canonico.sch" -xsl:"$ESQUELETO" -o:"$DIR_TRABAJO/compilada.xsl" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "El esqueleto ISO no pudo compilar el Schematron"
}
bien_formado "$DIR_TRABAJO/compilada.xsl" || morir "La compilación produjo un XSLT mal formado"

ok "hoja compilada"

# --- 5. CABECERA ---
# UN COMENTARIO ANTES DE LA RAÍZ CON EL ORIGEN: SI ALGUNA FUENTE CAMBIA Y
# NADIE REGENERA LA HOJA, LAS HUELLAS NO COINCIDEN. SE PONE CON UNA COPIA
# IDENTIDAD Y NO CON sed: LA SALIDA DEL ESQUELETO PUEDE NO TENER SALTO DE
# LÍNEA DESPUÉS DE LA DECLARACIÓN XML
paso "escribiendo la cabecera"

cat > "$DIR_TRABAJO/cabecera.xsl" <<'XSL'
<?xml version="1.0" encoding="UTF-8"?>
<!-- COPIA LA HOJA COMPILADA TAL CUAL Y LE ANTEPONE UN COMENTARIO -->
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" encoding="UTF-8"/>
  <xsl:param name="texto" required="yes"/>
  <xsl:template match="/">
    <xsl:comment select="$texto"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:copy-of select="node()"/>
  </xsl:template>
</xsl:stylesheet>
XSL

CABECERA="
  GENERADO POR generar-schematron-canonico.sh. NO EDITAR A MANO: SE REGENERA
  DESDE EL RNG Y DESDE gbpublisher.sch (SC-75, GV-XML-03).

  Schematron del canónico DocBook: las reglas embebidas en el RNG de
  DocBook 5.2, que jing ignora (GV-XML-02), y las propias de gbpublisher
  (los @id con prefijo gbp-), compiladas a XSLT 2.0 en una sola hoja.

  RNG        $(basename "$RNG")
             sha256 $(sha256sum "$RNG" | cut -d' ' -f1)
  propias    $(basename "$PROPIAS")
             sha256 $(sha256sum "$PROPIAS" | cut -d' ' -f1)
  esqueleto  $(basename "$ESQUELETO")
             sha256 $(sha256sum "$ESQUELETO" | cut -d' ' -f1)
             $(basename "$ESQUELETO_BASE")
             sha256 $(sha256sum "$ESQUELETO_BASE" | cut -d' ' -f1)
  patrones   $PATRONES_RNG de DocBook y $PATRONES_GBP propios
  compilado  $VERSION_SAXON, $(date '+%Y-%m-%d')
"

saxon -s:"$DIR_TRABAJO/compilada.xsl" -xsl:"$DIR_TRABAJO/cabecera.xsl" -o:"$TEMPORAL" texto="$CABECERA" || {
    mostrar_cola "$(cat "$DIR_TRABAJO/saxon.log")"
    morir "No se pudo escribir la cabecera"
}
bien_formado "$TEMPORAL" || morir "La hoja con cabecera está mal formada"

ok "cabecera con el origen y las huellas"

# --- 6. VERIFICACIÓN ---
# INSTANCIAS CON RESULTADO CONOCIDO. SE PRUEBA LA HOJA TEMPORAL, LA QUE SE VA
# A PONER: SI FALLA, NO REEMPLAZA A LA ANTERIOR
paso "verificando con instancias de prueba"

NS='xmlns="http://docbook.org/ns/docbook"'
# EL <info> DE UNA PIEZA COMO LO ESCRIBE m_XML.GenerarInfoCapituloXML: CON
# ÉL, UNA PIEZA NO INCUMPLE NINGUNA REGLA PROPIA
INFO='<info><title>T</title><bibliomisc role="seccion-libro">a</bibliomisc><bibliomisc role="orden-seccion">01</bibliomisc><bibliomisc role="tipo-capitulo">capitulo</bibliomisc><bibliomisc role="estilo-cita">apa</bibliomisc></info>'

# DocBook (GV-XML-02): UNA LIMPIA Y TRES QUE INCUMPLEN UNA REGLA CADA UNA
cat > "$DIR_TRABAJO/limpia.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<?gb-fuente archivo="articulos/a-01-X.md" sha256="0000000000000000000000000000000000000000000000000000000000000000"?>
<chapter $NS version="5.2" xml:lang="es" xml:id="c1">$INFO<para>x<footnote xml:id="n1"><para>nota</para></footnote><footnoteref linkend="n1"/></para><mediaobject><imageobject><imagedata fileref="media/a.png" width="60%"/></imageobject><textobject><phrase>alt</phrase></textobject></mediaobject></chapter>
XML

cat > "$DIR_TRABAJO/sin-version.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<chapter $NS xml:lang="es" xml:id="c1">$INFO<para>x</para></chapter>
XML

cat > "$DIR_TRABAJO/nota-en-nota.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<chapter $NS version="5.2" xml:lang="es" xml:id="c1">$INFO<note><para>a</para><note><para>b</para></note></note></chapter>
XML

cat > "$DIR_TRABAJO/footnoteref-a-para.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<chapter $NS version="5.2" xml:lang="es" xml:id="c1">$INFO<para xml:id="p1">x<footnoteref linkend="p1"/></para></chapter>
XML

# PROPIAS, PIEZA: INCUMPLE CADA REGLA DE PIEZA UNA VEZ, Y SIGUE SIENDO
# DocBook VÁLIDO. LA CITA A UN ID AUSENTE NO CUENTA: EN UNA PIEZA ES UNA
# REMISIÓN A LA BIBLIOGRAFÍA CONSOLIDADA
cat > "$DIR_TRABAJO/pieza-incumple.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<chapter $NS version="5.2" xml:lang="español" xml:id="c1"><info><title>T</title><bibliomisc role="seccion-libro">a</bibliomisc><bibliomisc role="seccion-libro">x</bibliomisc><bibliomisc role="orden-seccion">1</bibliomisc><bibliomisc role="tipo-capitulo"> </bibliomisc></info><para xml:id="p1">x<?gb-raro y?><?gb-fuente archivo="a" sha256="b"?><biblioref linkend="p1"/><biblioref linkend="bib-afuera"/></para><mediaobject><imageobject><imagedata fileref="media/a.png" width="60"/></imageobject><textobject><phrase> </phrase></textobject></mediaobject></chapter>
XML

# PROPIAS, LIBRO: LAS REGLAS DE LIBRO, CON UNA PIEZA BIEN ARMADA ADENTRO
cat > "$DIR_TRABAJO/libro-incumple.xml" <<XML
<?xml version="1.0" encoding="UTF-8"?>
<book $NS version="5.2" xml:lang="es"><info><title>L</title><bibliomisc role="lugar-bibliografia">mixta</bibliomisc></info><chapter xml:lang="es" xml:id="c1"><info><title>T</title><bibliomisc role="seccion-libro">a</bibliomisc><bibliomisc role="orden-seccion">01</bibliomisc><bibliomisc role="estilo-cita">apa</bibliomisc></info><para>x<biblioref linkend="bib-1"/></para><figure xml:id="fig-1"><title>F</title><mediaobject><imageobject><imagedata fileref="../media/a.png"/></imageobject><textobject><phrase>alt</phrase></textobject></mediaobject></figure></chapter><bibliography><biblioentry xml:id="bib-1"><title>A</title></biblioentry><biblioentry xml:id="bib-2"><title>B</title></biblioentry></bibliography></book>
XML

fallidas=0
probar_docbook limpia 0 - || fallidas=$((fallidas + 1))
probar_docbook sin-version 1 "If this element is the root element, it must have a version attribute." || fallidas=$((fallidas + 1))
probar_docbook nota-en-nota 1 "note must not occur among the children or descendants of note" || fallidas=$((fallidas + 1))
probar_docbook footnoteref-a-para 1 "@linkend on footnoteref must point to a footnote." || fallidas=$((fallidas + 1))
probar_propias limpia - || fallidas=$((fallidas + 1))
probar_propias pieza-incumple "gbp-seccion-una gbp-seccion-valor gbp-orden-valor gbp-tipo-vacio gbp-estilo-pieza-uno gbp-pi-conocida gbp-pi-fuente-prologo gbp-cita-a-entrada gbp-alt-presente gbp-idioma-presente gbp-ancho-forma" || fallidas=$((fallidas + 1))
probar_propias libro-incumple "gbp-estilo-libro-uno gbp-lugar-bib-valor gbp-estilo-capitulo-ninguno gbp-bib-citada gbp-remision-remitido" || fallidas=$((fallidas + 1))

if (( fallidas > 0 )); then
    morir "$fallidas instancia(s) de prueba no dieron lo esperado: la hoja anterior se conserva"
fi

# --- 7. REEMPLAZO ---
mv -f "$TEMPORAL" "$PRODUCTO" || morir "No se pudo reemplazar $PRODUCTO"

echo
titulo "$REGLA"
printf '%s✓ Schematron del canónico compilado y verificado%s\n' "$C_OK" "$C_RESET"
# ETIQUETAS CON SU RELLENO ESCRITO: printf CUENTA BYTES Y NO CARACTERES,
# Y LA ñ DE «Tamaño» CORRÍA LA COLUMNA
printf '  Archivo:    %s\n' "$PRODUCTO"
printf '  Tamaño:     %s KB\n' "$(( $(stat -c%s "$PRODUCTO") / 1024 ))"
printf '  Patrones:   %s de DocBook y %s propios\n' "$PATRONES_RNG" "$PATRONES_GBP"
echo

terminar
