<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  MÓDULO    : quote.xsl
  PROPÓSITO : NIVELA LAS CITAS EN LÍNEA DEL CANÓNICO DOCBOOK. CADA <quote>
              SE EMITE CON EL PAR DE COMILLAS QUE LE CORRESPONDE SEGÚN SU
              PROFUNDIDAD DE ANIDAMIENTO, CON LA SERIE DEL CASTELLANO:

                nivel 1   « »
                nivel 2   “ ”
                nivel 3   ‘ ’
                nivel 4   vuelve a « », y así sucesivamente

              ES LA ÚNICA REGLA DE NIVELES DEL PROYECTO. LA INCLUYEN LOS TRES
              XSLT DE SALIDA —LATEX, EPUB, HTML— Y NINGUNO DEBE TENER UNA
              COPIA PROPIA: SI DIVERGEN, EL MISMO LIBRO SALE CON COMILLAS
              DISTINTAS SEGÚN EL FORMATO.

              LA SALIDA LATEX EMITE CARACTERES Y NO \enquote{}: UNA SOLA
              REGLA, Y SIN DEPENDER DE CÓMO ESTÉ CONFIGURADO csquotes.

  SE INCLUYE CON xsl:include, NO CON xsl:import. CON import, CUALQUIER
  PLANTILLA GENÉRICA DEL XSLT PRINCIPAL —UNA DE IDENTIDAD SOBRE node(), POR
  EJEMPLO— TIENE MAYOR PRECEDENCIA DE IMPORTACIÓN Y GANA SIEMPRE, SIN
  IMPORTAR LA PRIORIDAD: ESTA PLANTILLA NO SE DISPARARÍA NUNCA.

  LOS CARACTERES VAN COMO REFERENCIAS NUMÉRICAS PARA QUE EL ARCHIVO NO
  DEPENDA DE QUE LA CODIFICACIÓN SOBREVIVA A UN COPIAR Y PEGAR.
  ============================================================================
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:db="http://docbook.org/ns/docbook"
  exclude-result-prefixes="db">

  <!--
    mode="#all" HACE QUE LA PLANTILLA APLIQUE EN CUALQUIER MODO QUE USE EL
    XSLT QUE LA INCLUYE, Y mode="#current" MANTIENE ESE MODO PARA EL
    CONTENIDO. ASÍ EL MÓDULO NO NECESITA CONOCER LOS MODOS DE CADA SALIDA,
    Y EL TEXTO INTERIOR SIGUE PASANDO POR EL ESCAPADO QUE CADA UNA TENGA.
  -->
  <xsl:template match="db:quote" mode="#all">

    <!-- CERO PARA EL NIVEL 1: CUENTA LAS CITAS QUE LA CONTIENEN -->
    <xsl:variable name="nivel" select="count(ancestor::db:quote) mod 3"/>

    <xsl:choose>
      <xsl:when test="$nivel = 0">
        <xsl:text>&#x00AB;</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>&#x00BB;</xsl:text>
      </xsl:when>
      <xsl:when test="$nivel = 1">
        <xsl:text>&#x201C;</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>&#x201D;</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#x2018;</xsl:text>
        <xsl:apply-templates mode="#current"/>
        <xsl:text>&#x2019;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:template>

</xsl:stylesheet>
