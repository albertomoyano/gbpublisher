<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  verso-comun.xsl
  ============================================================
  PROPÓSITO : LAS REGLAS DEL VERSO (SC-49) QUE COMPARTEN LAS SEIS
              HOJAS DE SALIDA: CUÁLES SON LAS ESTROFAS DE UN POEMA,
              CUÁLES LOS VERSOS DE UNA ESTROFA Y QUÉ SANGRÍA LLEVA
              CADA VERSO. CADA HOJA ESCRIBE SU SALIDA CON ESO.
  USO       : SE INCLUYE CON xsl:include, COMO conversacion-comun.xsl.
              LAS FUNCIONES NOMBRAN LOS ELEMENTOS POR local-name():
              NO DEPENDEN DEL xpath-default-namespace DE LA HOJA QUE
              LAS INCLUYE, Y SIRVEN PARA DocBook Y PARA JATS.
              DEVUELVEN LOS NODOS DEL CANÓNICO, NO COPIAS: LA HOJA
              APLICA SUS PLANTILLAS SOBRE ELLOS Y LAS NOTAS, LAS CITAS
              Y LAS MARCAS SE NUMERAN Y RESUELVEN EN SU LUGAR.
  CANÓNICO  : LO ESCRIBEN fenced-divs-to-elements-db.lua Y
              cite-to-xref.lua A PARTIR DE LO QUE NORMALIZÓ verso.lua.
              - DocBook: <blockquote role="verso"> CON UN
                <literallayout role="verse"> POR ESTROFA; CADA VERSO,
                UN <phrase role="linea">, CON DOS ESPACIOS POR NIVEL DE
                SANGRÍA DELANTE. EN UN EPÍGRAFE, LOS <literallayout>
                SUELTOS DENTRO DE <epigraph>.
              - JATS: <verse-group> (EL POEMA) CON UN <verse-group> POR
                ESTROFA; CADA VERSO, UN <verse-line>, CON indent-level
                SI LLEVA SANGRÍA.
  UNIDAD    : DOS ESPACIOS POR NIVEL EN DocBook. GEMELO DE
              fenced-divs-to-elements-db.lua (6.5): UN CAMBIO VA EN LOS
              DOS.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbvr="urn:gbpublisher:verso"
  exclude-result-prefixes="xs gbvr">

  <!-- ==========================================================
       gbvr:estrofas: LAS ESTROFAS DE UN POEMA, EN ORDEN.
       - <blockquote role="verso">: SUS <literallayout>.
       - <epigraph>: SUS <literallayout> (EL VERSO DE UN EPÍGRAFE).
       - <verse-group> CON <verse-group> ADENTRO: ESOS.
       - <verse-group> CON <verse-line>: ÉL MISMO, UNA ESTROFA SOLA.
       ========================================================== -->
  <xsl:function name="gbvr:estrofas" as="element()*">
    <xsl:param name="poema" as="element()"/>
    <xsl:sequence select="
      if (local-name($poema) = ('blockquote', 'epigraph'))
        then $poema/*[local-name() = 'literallayout'][@role = 'verse']
      else if ($poema/*[local-name() = 'verse-group'])
        then $poema/*[local-name() = 'verse-group']
      else $poema"/>
  </xsl:function>

  <!-- ==========================================================
       gbvr:versos: LOS VERSOS DE UNA ESTROFA, EN ORDEN:
       <phrase role="linea"> O <verse-line>.
       ========================================================== -->
  <xsl:function name="gbvr:versos" as="element()*">
    <xsl:param name="estrofa" as="element()"/>
    <xsl:sequence select="$estrofa/*[local-name() = 'verse-line'
      or (local-name() = 'phrase' and @role = 'linea')]"/>
  </xsl:function>

  <!-- ==========================================================
       gbvr:nivel: CUÁNTAS SANGRÍAS LLEVA UN VERSO, DE 0 A 9.
       - <verse-line>: SU indent-level; SIN ÉL, O SI NO ES UN
         ENTERO, 0.
       - <phrase role="linea">: LOS ESPACIOS ENTRE EL ÚLTIMO SALTO
         DEL TEXTO QUE LO PRECEDE Y EL <phrase>, DE A DOS.
       ========================================================== -->
  <xsl:function name="gbvr:nivel" as="xs:integer">
    <xsl:param name="verso" as="element()"/>
    <xsl:choose>
      <xsl:when test="local-name($verso) = 'verse-line'">
        <xsl:sequence select="if ($verso/@indent-level castable as xs:integer)
                              then xs:integer($verso/@indent-level) else 0"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- EL NODO DE TEXTO INMEDIATAMENTE ANTERIOR, SI LO HAY: EL
             PRIMER VERSO TIENE SOLO SUS ESPACIOS; LOS DEMÁS, UN SALTO
             Y SUS ESPACIOS -->
        <xsl:variable name="antes"
          select="string(($verso/preceding-sibling::node()[1])[self::text()])"/>
        <xsl:variable name="tras-salto"
          select="replace($antes, '^.*\n', '', 's')"/>
        <xsl:sequence select="string-length($tras-salto) idiv 2"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ==========================================================
       gbvr:sin-versos: UN <literallayout role="verse"> SIN
       <phrase role="linea"> ES UN CANÓNICO ANTERIOR A SC-49. LAS
       HOJAS LO FRENAN CON UN MENSAJE: HAY QUE REGENERAR EL XML.
       ========================================================== -->
  <xsl:function name="gbvr:sin-versos" as="xs:boolean">
    <xsl:param name="estrofa" as="element()"/>
    <xsl:sequence select="local-name($estrofa) = 'literallayout'
                          and empty(gbvr:versos($estrofa))"/>
  </xsl:function>

  <!-- ==========================================================
       gbvr:frenar-si-viejo: DETIENE LA TRANSFORMACIÓN ANTE UN
       CANÓNICO VIEJO. NO ESCRIBE NADA SI ESTÁ BIEN. PLANTILLA CON
       NOMBRE Y NO FUNCIÓN: UNA FUNCIÓN QUE NO DEVUELVE NADA PUEDE
       QUEDAR SIN EVALUAR.
       ========================================================== -->
  <xsl:template name="gbvr:frenar-si-viejo">
    <xsl:param name="estrofas" as="element()*"/>
    <xsl:if test="some $e in $estrofas satisfies gbvr:sin-versos($e)">
      <xsl:message terminate="yes">
        <xsl:text>[verso] El XML canónico es anterior a SC-49: el verso no tiene </xsl:text>
        <xsl:text>sus versos marcados. Regenerar el XML del capítulo antes de </xsl:text>
        <xsl:text>generar las salidas.</xsl:text>
      </xsl:message>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
