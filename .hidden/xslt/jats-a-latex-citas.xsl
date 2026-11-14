<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-a-latex-citas.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : LAS CITAS DE UN ARTÍCULO DE REVISTA PARA LA PASADA
                   DE tex4ht DEL EPUB (SC-57; E1, DECISIONES DE ALBERTO
                   DEL 14/11/2026). ES LA GEMELA DE
                   docbook-to-latex-citas.xsl (LIBROS) SOBRE EL CANÓNICO
                   JATS: ESCRIBE SOLO LAS CITAS, CADA GRUPO COMO
                   \gbcita{id}{comando}, CON EL COMANDO QUE ESCRIBE EL
                   PDF. ASÍ EL TEXTO DE LAS CITAS DEL EPUB ES EL DEL PDF
                   POR CONSTRUCCIÓN.
  POR QUÉ IMPORTA: IMPORTA jats-a-latex-articulo.xsl Y USA SU PLANTILLA
                   DE xref Y SUS AFIJOS (QUE ESCAPAN EL TEXTO CON LAS
                   MISMAS FUNCIONES QUE EL PDF). LA REGLA DEL
                   AGRUPAMIENTO Y EL id DE CADA GRUPO ESTÁN EN
                   cita-jats-comun.xsl, QUE TAMBIÉN LEE LA HOJA DEL EPUB.
  ENTRADA        : {proyecto}/jats/c-{archivo}.xml (CANÓNICO)
  SALIDA         : c-{archivo}.tex EN LA CARPETA DE LA PASADA, Y, SI
                   bib_cita NO ESTÁ VACÍO, EL .bib DEL «CÓMO CITAR» AL
                   LADO (LA MISMA PLANTILLA QUE EL PDF, gbr:bib-cita)
  PARÁMETROS     : LOS DE jats-a-latex-articulo.xsl, MÁS
                   archivo   EL ARCHIVO DEL ARTÍCULO (a-01-…): PREFIJO DE
                             LOS id Y NOMBRE DE SU BIBLIOGRAFÍA
  LO QUE ESCRIBE (UN ARTÍCULO; preparar_citas_revista.sh LOS JUNTA):
      \gbselectlanguage{CÓDIGO}       EL IDIOMA DEL ARTÍCULO, COMO EL PDF
      \begin{refsection}              LA NUMERACIÓN Y LA LISTA SON DEL
                                      ARTÍCULO, COMO EN SU PDF
      \gbcita{a-01-ciudad-1}{\autocites[p.~3]{lopez2020}[ver][]{gil_2019}}
      …
      \gbbibliografia{a-01-ciudad}\gbImprimirBibliografia
      \end{refsection}
      \gbcita{a-01-ciudad-comocitar}{\begin{refsection}[cita-a-01-ciudad.bib]\fullcite{gb-articulo}\end{refsection}}
  EL «CÓMO CITAR» VA FUERA DE LA refsection DEL ARTÍCULO: LAS refsection
  NO SE ANIDAN. ES LA MISMA FORMA QUE \gbcomocitar DEL CONTRATO DE
  REVISTA, SIN EL ESTILO DE LA COLUMNA.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:f="urn:gbpublisher:functions"
  xmlns:gbr="urn:gbpublisher:revista-latex"
  xmlns:gbcj="urn:gbpublisher:citas-jats"
  exclude-result-prefixes="xs f gbr gbcj">

  <!-- LA PLANTILLA DE xref, LOS AFIJOS Y EL .bib DEL «CÓMO CITAR» SON LOS
       DEL PDF. LO QUE ESTA HOJA DEFINE GANA POR PRECEDENCIA -->
  <xsl:import href="jats-a-latex-articulo.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="archivo" as="xs:string" select="''"/>

  <!-- ============================================
       Función   : article (plantilla)
       Propósito : Escribe las citas del artículo, su bibliografía y su
                   «cómo citar» para la pasada de tex4ht
       Parámetros: (nodo de contexto) — el article
       Retorna   : texto LaTeX
       ============================================ -->
  <xsl:template match="article">

    <!-- APARTADO 1. EL ARCHIVO ES OBLIGATORIO: DA LOS id -->
    <xsl:if test="normalize-space($archivo) eq ''">
      <xsl:message terminate="yes">ERROR: falta el parámetro archivo (el nombre del artículo)</xsl:message>
    </xsl:if>

    <!-- APARTADO 2. EL IDIOMA Y LA SECCIÓN DE REFERENCIAS DEL ARTÍCULO -->
    <xsl:text>% c-</xsl:text>
    <xsl:value-of select="$archivo"/>
    <xsl:text>.tex — ARCHIVO DERIVADO (jats-a-latex-citas.xsl): NO EDITAR A MANO&#10;</xsl:text>
    <xsl:text>\gbselectlanguage{</xsl:text>
    <xsl:value-of select="$xmlLang"/>
    <xsl:text>}&#10;\begin{refsection}&#10;</xsl:text>

    <!-- APARTADO 3. UN \gbcita POR GRUPO, EN ORDEN DE DOCUMENTO (TAMBIÉN
         LAS DE LAS NOTAS Y LOS PIES). EL COMANDO LO ESCRIBE LA PLANTILLA
         DE xref DEL PDF; LAS CITAS ABSORBIDAS POR UN GRUPO NO ABREN OTRO -->
    <xsl:for-each select="//xref[@ref-type = 'bibr'][gbcj:inicia-grupo(.)]">
      <xsl:text>\gbcita{</xsl:text>
      <xsl:value-of select="gbcj:id-cita(., $archivo)"/>
      <xsl:text>}{</xsl:text>
      <xsl:apply-templates select="."/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>

    <!-- APARTADO 4. LA BIBLIOGRAFÍA DEL ARTÍCULO: LO CITADO, COMO EN SU PDF -->
    <xsl:text>\gbbibliografia{</xsl:text>
    <xsl:value-of select="$archivo"/>
    <xsl:text>}\gbImprimirBibliografia&#10;\end{refsection}&#10;</xsl:text>

    <!-- APARTADO 5. EL «CÓMO CITAR»: EL .bib LO ESCRIBE LA PLANTILLA DEL PDF -->
    <xsl:if test="$bib_cita ne ''">
      <xsl:text>\gbcita{</xsl:text>
      <xsl:value-of select="$archivo"/>
      <xsl:text>-comocitar}{\begin{refsection}[</xsl:text>
      <xsl:value-of select="$bib_cita"/>
      <xsl:text>]\fullcite{</xsl:text>
      <xsl:value-of select="$gbr:clave-cita"/>
      <xsl:text>}\end{refsection}}&#10;</xsl:text>
      <xsl:call-template name="gbr:bib-cita"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
