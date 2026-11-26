<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  mathml-comun.xsl — LA COPIA DEL MathML DE UNA FÓRMULA (SC-110)
  ============================================================
  PANDOC ESCRIBE EL MathML CON EL PREFIJO mml: EN LOS ELEMENTOS Y
  EN LOS ATRIBUTOS (GV-229). EL HTML Y EL EPUB LO QUIEREN EN EL
  ESPACIO DE NOMBRES DE MathML, SIN PREFIJOS. ESTE MÓDULO LO COPIA
  ASÍ, EN EL MODO mathml, CON display="block" CUANDO LA FÓRMULA
  VA EN BLOQUE (PARÁMETRO EN TÚNEL bloque).

  LO INCLUYEN:
    formula-comun.xsl       — LIBROS (DocBook)
    formula-jats-comun.xsl  — REVISTAS (JATS)
  SIN DEPENDENCIAS DE LA HOJA QUE LO INCLUYE.
  ============================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                exclude-result-prefixes="mml">

  <!-- ============================================================ -->
  <!-- LA COPIA DEL MathML                                          -->
  <!-- ============================================================ -->

  <!-- LA RAÍZ: display="block" EN LA FÓRMULA EN BLOQUE. EL display QUE
       TRAIGA SE DESCARTA: MANDA EL ELEMENTO QUE LA CONTIENE
       (equation O disp-formula), QUE PASA bloque -->
  <xsl:template match="mml:math" mode="mathml">
    <xsl:param name="bloque" select="false()" tunnel="yes"/>
    <xsl:element name="math" namespace="http://www.w3.org/1998/Math/MathML">
      <xsl:if test="$bloque">
        <xsl:attribute name="display">block</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="@*[local-name() != 'display']" mode="mathml"/>
      <xsl:apply-templates mode="mathml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="mml:*" mode="mathml">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1998/Math/MathML">
      <xsl:apply-templates select="@* | node()" mode="mathml"/>
    </xsl:element>
  </xsl:template>

  <!-- EL ATRIBUTO SIN EL PREFIJO mml: QUE LE PONE PANDOC (GV-229) -->
  <xsl:template match="@*" mode="mathml">
    <xsl:attribute name="{local-name()}" select="."/>
  </xsl:template>

  <xsl:template match="text()" mode="mathml">
    <xsl:value-of select="."/>
  </xsl:template>

</xsl:stylesheet>
