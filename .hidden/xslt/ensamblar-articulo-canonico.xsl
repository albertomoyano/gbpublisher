<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  ensamblar-articulo-canonico.xsl — gbpublisher
  =====================================================
  DESCRIPCIÓN : EL CANÓNICO JATS 1.4 DE UN ARTÍCULO DE REVISTA SOBRE EL
                ESQUEMA NUEVO (SC-71; ETAPA A0 DE LAS SALIDAS DE REVISTAS,
                claude/salidas-revistas.md):
                  front  ← EL VOLCADO DEL NÚMERO (tmp/numero-datos.xml) POR
                           datos-a-front-jats.xsl
                  body   ← EL FRAGMENTO DE PANDOC (tmp/body-{base}.xml)
                  back   ← EL reflist (tmp/reflist-{base}.xml), SI TIENE <ref>
  REEMPLAZA   : A ensamblar-canonico.xsl PARA LOS NÚMEROS NUEVOS. AQUELLA
                QUEDA PARA EL CAMINO VIEJO HASTA EL 2.0.0, Y ESTA LA IMPORTA:
                EL TRATAMIENTO DEL body (sec-type, ids de sección, tablas de
                ancho completo y rotadas) ES UNO SOLO Y SALE IGUAL.
  USO         : java -jar saxon-he.jar -s:tmp/numero-datos.xml
                  -xsl:ensamblar-articulo-canonico.xsl -o:jats/c-{base}.xml
                  archivo=a-01-tal body=tmp/body-{base}.xml
                  reflist=tmp/reflist-{base}.xml
  ENTRADA     : numero-datos versión 1 (m_CanonicoRevista.VERSION_DATOS)
  =====================================================
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
    exclude-result-prefixes="xs">

  <!-- EL body Y EL DOCTYPE, LOS DEL ENSAMBLADO DE SIEMPRE (SU PLANTILLA
       RAÍZ QUEDA TAPADA POR LA DE ACÁ, QUE TIENE PRECEDENCIA) -->
  <xsl:import href="ensamblar-canonico.xsl"/>
  <xsl:include href="datos-a-front-jats.xsl"/>

  <!-- EL ARTÍCULO DEL VOLCADO: SU ARCHIVO SIN .md -->
  <xsl:param name="archivo" as="xs:string" select="''"/>

  <!-- LA VERSIÓN DEL VOLCADO QUE ESTA HOJA SABE LEER -->
  <xsl:variable name="version-datos" select="'1'"/>

  <xsl:template match="/">
    <xsl:variable name="art" select="/numero-datos/articulo[@archivo = $archivo]"/>

    <!-- 1. CONTROLES: VOLCADO, VERSIÓN Y ARTÍCULO -->
    <xsl:if test="not(/numero-datos)">
      <xsl:message terminate="yes">ERROR: la entrada no es un volcado del número (numero-datos)</xsl:message>
    </xsl:if>
    <xsl:if test="string(/numero-datos/@version) ne $version-datos">
      <xsl:message terminate="yes">ERROR: el volcado es versión <xsl:value-of select="/numero-datos/@version"/> y esta hoja lee la <xsl:value-of select="$version-datos"/></xsl:message>
    </xsl:if>
    <xsl:if test="count($art) ne 1">
      <xsl:message terminate="yes">ERROR: el volcado no tiene el artículo «<xsl:value-of select="$archivo"/>» (o lo tiene repetido)</xsl:message>
    </xsl:if>

    <!-- 2. EL ARTÍCULO -->
    <article dtd-version="1.4" article-type="{$art/@article-type}" xml:lang="{$art/@idioma}">
      <xsl:call-template name="front">
        <xsl:with-param name="art" select="$art"/>
      </xsl:call-template>

      <!-- EL CUERPO, CON LAS PLANTILLAS DEL ENSAMBLADO DE SIEMPRE -->
      <xsl:variable name="bodyDoc" select="document($body)"/>
      <xsl:apply-templates select="$bodyDoc//body"/>

      <!-- LA BIBLIOGRAFÍA, SOLO SI HAY REFERENCIAS -->
      <xsl:if test="$reflist ne ''">
        <xsl:variable name="reflistDoc" select="document($reflist)"/>
        <xsl:if test="$reflistDoc//ref-list/ref">
          <back>
            <xsl:apply-templates select="$reflistDoc//ref-list"/>
          </back>
        </xsl:if>
      </xsl:if>
    </article>
  </xsl:template>

</xsl:stylesheet>
