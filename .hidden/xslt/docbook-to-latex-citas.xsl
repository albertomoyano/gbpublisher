<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : docbook-to-latex-citas.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : DEL CANÓNICO DE UNA PIEZA, SOLO SUS CITAS, PARA
                   LA PASADA DE tex4ht QUE ARMA EL TEXTO DE LAS
                   CITAS Y DE LAS REFERENCIAS DE HTML Y EPUB
                   (SC-57).
  ENTRADA        : {proyecto}/jats/c-{sec}-{NN}-{nombre}.xml
  SALIDA         : UN FRAGMENTO LATEX QUE EL DOCUMENTO MÍNIMO DE
                   LA PASADA INCLUYE CON \input, EN EL ORDEN DE
                   tmp/latex-piezas.txt.
  DEPENDENCIA    : docbook-to-latex.xsl (IMPORTADA)
  ============================================================
  POR QUÉ IMPORTA LA HOJA DEL PDF
    LAS CITAS TIENEN QUE SER LAS DEL PDF POR CONSTRUCCIÓN: EL
    COMANDO, LOS AFIJOS Y EL AGRUPAMIENTO SALEN DE LA MISMA
    PLANTILLA DE biblioref Y DE LAS MISMAS FUNCIONES. ESTA HOJA
    SOLO SOBRESCRIBE LA PLANTILLA DE PIEZA. LA HOJA DEL PDF NO
    SE TOCA.

  QUÉ EMITE POR PIEZA
    - \begin{refsection} ... \end{refsection} SI LA PIEZA TRAE
      <bibliography>, CON LA MISMA REGLA QUE EL PDF (GV-102).
    - \chapter* SI LA PIEZA NO ES PÁGINA ESPECIAL: citereset=chapter
      REINICIA LOS RASTREADORES EN CADA CAPÍTULO, IGUAL QUE EN EL PDF.
    - CADA GRUPO DE CITAS, EN EL ORDEN DEL DOCUMENTO, COMO
      \gbcita{id}{comando}. EL DE UNA NOTA, DENTRO DE \footnote.
    - \gbImprimirBibliografia AL CERRAR LA refsection. LA DEFINE
      EL ARCHIVO DE PANTALLA DEL ESTILO (cita-<estilo>-html.tex).

  EL id DE CADA CITA
    {sección}-{orden}-{n}: sección y orden salen del <info> de la
    pieza; n es la posición, dentro de la pieza, del PRIMER
    biblioref DEL GRUPO, CONTANDO LOS DE LAS NOTAS. LAS HOJAS DE
    HTML Y EPUB CUENTAN IGUAL. GEMELO: f:id-cita.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:f="urn:gbpublisher:functions"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs f">

  <xsl:import href="docbook-to-latex.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:id-cita                                          -->
  <!-- PROPÓSITO: EL id DE UN GRUPO DE CITAS: {sección}-{orden}-{n} -->
  <!-- PARÁMETROS: b     As element() — el primer biblioref del     -->
  <!--                                  grupo                        -->
  <!--             pieza As element() — la pieza que lo contiene    -->
  <!-- RETORNA  : xs:string — p. ej. a-03-17                        -->
  <!-- NOTA     : SE CUENTA DENTRO DE LA PIEZA Y NO EN EL DOCUMENTO: -->
  <!--            ASÍ EL NÚMERO ES EL MISMO EN EL CANÓNICO DE LA     -->
  <!--            PIEZA Y EN EL DEL LIBRO ENSAMBLADO.                -->
  <!-- ============================================================ -->
  <xsl:function name="f:id-cita" as="xs:string">
    <xsl:param name="b"     as="element()"/>
    <xsl:param name="pieza" as="element()"/>
    <xsl:variable name="n" select="count($b/preceding::biblioref intersect $pieza//biblioref) + 1"/>
    <xsl:sequence select="concat(
      normalize-space($pieza/info/bibliomisc[@role='seccion-libro']), '-',
      normalize-space($pieza/info/bibliomisc[@role='orden-seccion']), '-',
      $n)"/>
  </xsl:function>

  <!-- LIBRO COMPLETO: CADA PIEZA, COMO EN LA HOJA DEL PDF (SOLO PRUEBA) -->
  <xsl:template match="book">
    <xsl:apply-templates select="* except info"/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PIEZA: SOLO SUS CITAS                                        -->
  <!-- ============================================================ -->
  <xsl:template match="chapter | preface | acknowledgements |
                       appendix | colophon | dedication | glossary">

    <!-- 1. CLASIFICACIÓN DE LA PIEZA -->
    <!-- LA MISMA REGLA DE PÁGINA ESPECIAL QUE LA HOJA DEL PDF (GEMELO) -->
    <xsl:variable name="pieza" select="."/>
    <xsl:variable name="seccion"
      select="normalize-space(info/bibliomisc[@role='seccion-libro'])"/>
    <xsl:variable name="orden"
      select="normalize-space(info/bibliomisc[@role='orden-seccion'])"/>
    <xsl:variable name="especial" as="xs:boolean" select="
      $seccion = ('fm', 'bm')
      and $orden castable as xs:integer
      and xs:integer($orden) &lt; 10"/>
    <!-- BIBLIOGRAFÍA POR CAPÍTULO: LA SEÑAL ES <bibliography> (GV-102) -->
    <xsl:variable name="conCitas" as="xs:boolean" select="exists(.//bibliography)"/>
    <!-- LOS GRUPOS: UN biblioref QUE NO FUE ABSORBIDO POR EL ANTERIOR -->
    <xsl:variable name="grupos" select=".//biblioref[not(f:es-continuacion(.))]"/>

    <!-- 2. VALIDACIÓN: SIN SECCIÓN U ORDEN NO HAY id ESTABLE -->
    <xsl:if test="exists($grupos) and ($seccion = '' or $orden = '')">
      <xsl:message terminate="yes">
        <xsl:text>&#10;[docbook-to-latex-citas] PIEZA SIN SECCIÓN U ORDEN&#10;</xsl:text>
        <xsl:text>  La pieza tiene citas pero su &lt;info&gt; no trae&#10;</xsl:text>
        <xsl:text>  bibliomisc seccion-libro y orden-seccion: sin ellos las&#10;</xsl:text>
        <xsl:text>  citas no tienen un id que HTML y EPUB puedan encontrar.&#10;</xsl:text>
        <xsl:text>  Regenerar el canónico de la pieza.&#10;</xsl:text>
      </xsl:message>
    </xsl:if>

    <!-- 3. APERTURA -->
    <xsl:if test="$conCitas">
      <xsl:text>&#10;\begin{refsection}&#10;</xsl:text>
    </xsl:if>
    <!-- EL TÍTULO NO HACE FALTA: SOLO EL \chapter, POR citereset -->
    <xsl:if test="not($especial)">
      <xsl:text>\chapter*{</xsl:text>
      <xsl:value-of select="concat($seccion, '-', $orden)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- 4. LAS CITAS, EN EL ORDEN DEL DOCUMENTO -->
    <!-- EL COMANDO LO ESCRIBE LA PLANTILLA DE biblioref DEL PDF -->
    <xsl:for-each select="$grupos">
      <xsl:variable name="cita">
        <xsl:text>\gbcita{</xsl:text>
        <xsl:value-of select="f:id-cita(., $pieza)"/>
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates select="."/>
        <xsl:text>}</xsl:text>
      </xsl:variable>
      <!-- LA CITA DE UNA NOTA VA EN UNA NOTA: biblatex DISTINGUE EL CONTEXTO -->
      <xsl:choose>
        <xsl:when test="ancestor::footnote">
          <xsl:text>\footnote{</xsl:text>
          <xsl:value-of select="$cita"/>
          <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$cita"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>

    <!-- 5. CIERRE: LA BIBLIOGRAFÍA DE LA PIEZA -->
    <xsl:if test="$conCitas">
      <xsl:text>\gbImprimirBibliografia&#10;</xsl:text>
      <xsl:text>\end{refsection}&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
