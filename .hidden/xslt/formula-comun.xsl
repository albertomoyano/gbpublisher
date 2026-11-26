<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  formula-comun.xsl — FÓRMULAS EN LAS SALIDAS DIGITALES DEL LIBRO (SC-110)
  ============================================================
  LA INCLUYEN docbook-to-html.xsl Y docbook-to-epub.xsl. EL PDF NO:
  COMPONE DESDE EL <alt role="tex"> (docbook-to-latex.xsl).

  EL CANÓNICO TRAE CADA FÓRMULA CON SUS DOS FORMAS (filters/formula.lua):
    <inlineequation><alt role="tex">…</alt><mml:math>…</mml:math></inlineequation>
    <informalequation><alt role="tex">…</alt><mml:math>…</mml:math></informalequation>
  ACÁ SE COPIA EL MathML COMO <math> DEL ESPACIO MathML, SIN PREFIJO, Y SE
  DESCARTA EL alt. SIN CDN NI JAVASCRIPT: LOS NAVEGADORES Y LOS LECTORES DE
  EPUB 3 LEEN MathML.

  DOS ARREGLOS SOBRE LO QUE ESCRIBE PANDOC (GV-229):
  - LOS ATRIBUTOS SALEN DEL ESCRITOR DocBook CON EL PREFIJO mml:
    (mml:columnalign, mml:accent, mml:stretchy). EL ESQUEMA LOS ACEPTA,
    PERO UN NAVEGADOR NO LOS RECONOCE: LA BARRA DE x̄ SALDRÍA COMO LÍMITE
    Y NO COMO ACENTO. SE COPIAN SIN EL PREFIJO.
  - LA FÓRMULA EN BLOQUE LLEVA display="block". VA ADENTRO DEL <p> DEL
    PÁRRAFO QUE LA INTRODUCE: <math> ES CONTENIDO EN LÍNEA EN HTML, Y EL
    TEXTO QUE SIGUE QUEDA EN EL MISMO PÁRRAFO, COMO EN EL PDF.

  LA FÓRMULA NUMERADA (<equation xml:id>, DE [$$…$$]{#eq-nombre}) SALE EN
  UN <span class="formula-numerada"> CON SU id: LA FÓRMULA Y, A LA DERECHA,
  EL NÚMERO ENTRE PARÉNTESIS, EL MISMO DEL PDF (nl:numero-ecuacion DE
  numeracion-libro.xsl, QUE LAS DOS HOJAS INCLUYEN; $piezasLibro ES DE
  ELLAS). ES UN span Y NO UN div: VA ADENTRO DEL <p>.
  ============================================================
-->
<!-- EL ESPACIO POR OMISIÓN ES EL DE XHTML: LOS <span> DE LA NUMERADA SON DE
     LA PÁGINA, COMO EN LAS HOJAS QUE LA INCLUYEN. SIN ÉL SALDRÍAN SIN
     ESPACIO DE NOMBRES (xmlns="") Y EL EPUB NO VALIDARÍA -->
<xsl:stylesheet version="2.0"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:nl="urn:gbpublisher:numeracion-libro"
                exclude-result-prefixes="db mml nl">

  <!-- LA COPIA DEL MathML (mode="mathml"): COMÚN CON LAS REVISTAS -->
  <xsl:include href="mathml-comun.xsl"/>


  <!-- ============================================================ -->
  <!-- LA ECUACIÓN: SOLO SU MathML. EL alt ES PARA EL PDF           -->
  <!-- ============================================================ -->
  <xsl:template match="db:inlineequation | inlineequation">
    <xsl:apply-templates select="mml:math" mode="mathml"/>
  </xsl:template>

  <xsl:template match="db:informalequation | informalequation">
    <xsl:apply-templates select="mml:math" mode="mathml">
      <xsl:with-param name="bloque" select="true()" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <!-- NUMERADA: LA REMISIÓN (<a href="#eq-…">) LLEGA AL span -->
  <xsl:template match="db:equation | equation">
    <span class="formula-numerada" id="{@xml:id}">
      <xsl:apply-templates select="mml:math" mode="mathml">
        <xsl:with-param name="bloque" select="true()" tunnel="yes"/>
      </xsl:apply-templates>
      <span class="formula-numero">
        <xsl:text>(</xsl:text>
        <xsl:value-of select="nl:numero-ecuacion(., $piezasLibro)"/>
        <xsl:text>)</xsl:text>
      </span>
    </span>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- LOS MODOS DE LAS HOJAS                                       -->
  <!-- ============================================================ -->

  <!-- LA NOTA EN EL PANEL LATERAL DEL HTML (nota-panel): LA FÓRMULA SE
       COPIA IGUAL QUE EN EL TEXTO. SIN ESTA PLANTILLA EL CATCH-ALL DEL
       MODO LA APLANARÍA: EL TeX DEL alt Y EL TEXTO DEL MathML, PEGADOS -->
  <xsl:template match="db:inlineequation | inlineequation
                       | db:informalequation | informalequation
                       | db:equation | equation" mode="nota-panel">
    <xsl:apply-templates select="."/>
  </xsl:template>

  <!-- TEXTO PLANO (texto-plano EN EL HTML, text-only EN EL EPUB): EL TeX
       DEL alt, QUE ES LO MÁS LEGIBLE QUE HAY EN UNA SOLA LÍNEA -->
  <xsl:template match="db:inlineequation | inlineequation
                       | db:informalequation | informalequation
                       | db:equation | equation" mode="texto-plano text-only">
    <xsl:value-of select="normalize-space((db:alt[@role = 'tex'], alt[@role = 'tex'])[1])"/>
  </xsl:template>

</xsl:stylesheet>
