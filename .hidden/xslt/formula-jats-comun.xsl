<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  formula-jats-comun.xsl — LAS FÓRMULAS DEL ARTÍCULO EN HTML Y
  EPUB (SC-110, LOTE 2b)
  ============================================================
  EL CANÓNICO JATS TRAE CADA FÓRMULA EN <alternatives>, CON SU
  <tex-math> Y SU <mml:math> (PANDOC, GV-229). EL HTML Y EL EPUB
  MUESTRAN EL MathML, SIN MathJax NI CDN: LO DIBUJA EL NAVEGADOR O
  EL LECTOR. EL TeX ES PARA EL PDF (jats-a-latex-articulo.xsl).

    inline-formula               → <math>
    disp-formula                 → <math display="block">
    disp-formula CON <label>     → <span class="formula-numerada">
                                   CON EL MathML Y EL NÚMERO DEL
                                   CANÓNICO (formula-jats.lua). LA
                                   REVISTA NO TIENE REMISIONES (SC-32):
                                   EL NÚMERO SOLO SE MUESTRA

  REEMPLAZA A LAS PLANTILLAS DE LAS HOJAS VIEJAS (jats-to-html,
  jats-to-epub), QUE ESCRIBÍAN EL TeX COMO CÓDIGO.

  CONTRATO CON LA HOJA QUE LO INCLUYE: DECLARA LA VARIABLE
  gbfj:ns-html CON EL ESPACIO DE NOMBRES DE SUS ELEMENTOS HTML: ''
  EN EL HTML (method="html"), EL DE XHTML EN EL EPUB. SIN ELLA LA
  COMPILACIÓN FRENA. LOS span SE CREAN EN ESE ESPACIO: UN span DE
  OTRO ESPACIO SALDRÍA CON xmlns Y EL EPUB NO VALIDARÍA.
  ============================================================
-->
<xsl:stylesheet version="3.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:gbfj="urn:gbpublisher:formula-jats"
                exclude-result-prefixes="xs mml gbfj">

  <!-- LA COPIA DEL MathML (mode="mathml"): COMÚN CON LOS LIBROS -->
  <xsl:include href="mathml-comun.xsl"/>

  <!-- ============================================
       Función   : gbfj:mathml
       Propósito : El MathML de una fórmula. Sin él frena: el HTML y el
                   EPUB no convierten el TeX
       Parámetros: e As element() — inline-formula o disp-formula
       Retorna   : element() — el mml:math del canónico
       ============================================ -->
  <xsl:function name="gbfj:mathml" as="element()">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="m" select="($e/alternatives/mml:math, $e/mml:math)[1]"/>
    <xsl:if test="empty($m)">
      <xsl:message terminate="yes">
        <xsl:text>&#10;[formula-jats-comun] FÓRMULA SIN SU MathML&#10;</xsl:text>
        <xsl:text>  TeX: </xsl:text>
        <xsl:value-of select="normalize-space(($e//tex-math)[1])"/>
        <xsl:text>&#10;&#10;  Regenerá el canónico del artículo (SC-110).&#10;</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:sequence select="$m"/>
  </xsl:function>

  <!-- ============================================
       Función   : inline-formula (plantilla)
       Propósito : La fórmula en línea, como MathML. Vale igual en el
                   texto, en el panel de notas del HTML (nota-panel) y en
                   las notas del EPUB (text-only): las tres salidas van
                   dentro de un párrafo, donde <math> es válido. Sin el
                   modo, los catch-all de las hojas viejas pegarían el TeX
                   y el texto del MathML
       Parámetros: (nodo de contexto) — la fórmula
       Retorna   : <math>
       ============================================ -->
  <xsl:template match="inline-formula" mode="#default nota-panel text-only">
    <xsl:apply-templates select="gbfj:mathml(.)" mode="mathml"/>
  </xsl:template>

  <!-- ============================================
       Función   : disp-formula (plantilla)
       Propósito : La fórmula en bloque, adentro del párrafo que la
                   introduce. Con <label>, envuelta con su número
       Parámetros: (nodo de contexto) — la fórmula
       Retorna   : <math display="block"> o <span class="formula-numerada">
       ============================================ -->
  <xsl:template match="disp-formula" mode="#default nota-panel text-only">
    <xsl:variable name="m" select="gbfj:mathml(.)"/>
    <xsl:choose>
      <!-- LA NUMERADA: EL MISMO ARMADO QUE EL LIBRO (formula-comun.xsl),
           PARA QUE LA MISMA REGLA DE CSS VALGA EN LOS DOS -->
      <xsl:when test="label">
        <xsl:element name="span" namespace="{$gbfj:ns-html}">
          <xsl:attribute name="class">formula-numerada</xsl:attribute>
          <xsl:if test="@id">
            <xsl:attribute name="id" select="@id"/>
          </xsl:if>
          <xsl:apply-templates select="$m" mode="mathml">
            <xsl:with-param name="bloque" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
          <xsl:element name="span" namespace="{$gbfj:ns-html}">
            <xsl:attribute name="class">formula-numero</xsl:attribute>
            <xsl:value-of select="normalize-space(label)"/>
          </xsl:element>
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:apply-templates select="$m" mode="mathml">
          <xsl:with-param name="bloque" select="true()" tunnel="yes"/>
        </xsl:apply-templates>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
