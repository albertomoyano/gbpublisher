<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  jats-to-redalyc.xsl
  =====================================================
  DESCRIPCIÓN   : Transforma el canónico JATS 1.4 Archiving
                  al formato JATS requerido por Redalyc/Marcalyc.
                  Basado en JATS4R + requisitos Marcalyc 4.0.
  FAMILIA       : indexadores
  ENTRADA       : c-NN-slug-vNN-nNN.xml (canónico JATS 1.4)
  SALIDA        : r-NN-slug-vNN-nNN.xml (JATS Archiving 1.4 para Redalyc)
  MOTOR         : Saxon-HE (XSLT 2.0)
  PARÁMETROS    : (ninguno — transformación autónoma)
  VALIDACIÓN    : ValidarArchivoRedalyc() en m_XML.gambas
                  Basado en JATS4R + Marcalyc 4.0
  DOCUMENTACIÓN : https://xmljatsredalyc.org/
                  https://jats4r.org/
  =====================================================
  DIFERENCIAS CON EL CANÓNICO:
    — custom-meta-group eliminado (canal interno de gbpublisher,
      no debe enviarse a indexadores)
    — Solo element-citation en <ref> (sin mixed-citation).
      Diferencia crítica con SciELO, que requiere mixed-citation.
      JATS4R exige element-citation puro.
    — ORCID normalizado a URL https://orcid.org/XXXX
      según JATS4R contributor-identifier best practice.
    — sec-type inferido desde títulos comunes de sección
      (IMRaD + humanidades) para mejorar recuperación.
    — DTD: JATS Archiving 1.4 (igual que el canónico,
      a diferencia de SciELO que usa JATS Publishing 1.0).
  =====================================================
-->
<xsl:stylesheet
  version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"
  exclude-result-prefixes="xs">

  <!-- ================================================
       SALIDA: XML JATS ARCHIVING 1.4
       REDALYC ACEPTA JATS ARCHIVING (A DIFERENCIA DE
       SCIELO QUE REQUIERE JATS PUBLISHING 1.0)
       ================================================ -->
  <xsl:output
    method="xml"
    version="1.0"
    encoding="UTF-8"
    indent="yes"
    doctype-public="-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.4 20151215//EN"
    doctype-system="JATS-archivearticle1.dtd"/>

  <!-- ================================================
       PLANTILLA IDENTIDAD — COPIA TODO POR DEFECTO
       copy-namespaces="no" EVITA QUE XMLNS AUXILIARES
       DEL CANÓNICO SE PROPAGUEN A TODOS LOS ELEMENTOS
       ================================================ -->
  <xsl:template match="@* | node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================
       ELEMENTO RAÍZ: <article>
       SE DECLARAN SOLO LOS NAMESPACES NECESARIOS.
       dtd-version="1.4" REQUERIDO EXPLÍCITAMENTE.
       ================================================ -->
  <xsl:template match="article">
    <article
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xmlns:mml="http://www.w3.org/1998/Math/MathML"
      dtd-version="1.4">
      <xsl:copy-of select="@article-type"/>
      <xsl:copy-of select="@xml:lang"/>
      <xsl:apply-templates select="front | body | back"/>
    </article>
  </xsl:template>

  <!-- ================================================
       ELIMINAR custom-meta-group
       ES EL CANAL DE METADATOS INTERNOS DE GBPUBLISHER
       (idioma principal, URL texto completo, etc.).
       NO FORMA PARTE DEL ESQUEMA REDALYC/MARCALYC.
       ================================================ -->
  <xsl:template match="custom-meta-group"/>

  <!-- ================================================
       CONTRIB-ID ORCID: NORMALIZAR A URL COMPLETA
       JATS4R BEST PRACTICE: https://orcid.org/XXXX-XXXX-XXXX-XXXX
       EL CANÓNICO PUEDE TRAER SOLO EL ID (0000-0000-...)
       O LA URL CON HTTP (NO HTTPS)
       ================================================ -->
  <xsl:template match="contrib-id[@contrib-id-type='orcid']">
    <contrib-id contrib-id-type="orcid" authenticated="true">
      <xsl:variable name="orcid" select="normalize-space(.)"/>
      <xsl:choose>
        <!-- YA TIENE URL HTTPS CORRECTA -->
        <xsl:when test="starts-with($orcid, 'https://orcid.org/')">
          <xsl:value-of select="$orcid"/>
        </xsl:when>
        <!-- TIENE URL HTTP — CONVERTIR A HTTPS -->
        <xsl:when test="starts-with($orcid, 'http://orcid.org/')">
          <xsl:value-of select="concat('https://orcid.org/', substring-after($orcid, 'http://orcid.org/'))"/>
        </xsl:when>
        <!-- TIENE URL HTTPS GENÉRICA — NORMALIZAR DOMINIO -->
        <xsl:when test="starts-with($orcid, 'https://')">
          <xsl:value-of select="$orcid"/>
        </xsl:when>
        <!-- SOLO EL ID: AGREGAR PREFIJO DE URL -->
        <xsl:otherwise>
          <xsl:value-of select="concat('https://orcid.org/', $orcid)"/>
        </xsl:otherwise>
      </xsl:choose>
    </contrib-id>
  </xsl:template>

  <!-- ================================================
       SECCIONES SIN sec-type: INFERIR DESDE TÍTULO
       JATS4R RECOMIENDA sec-type EN SECCIONES PRINCIPALES
       PARA MEJORAR RECUPERACIÓN E INTEROPERABILIDAD.
       CUBRE IMRaD + TIPOS FRECUENTES EN HUMANIDADES Y
       CIENCIAS SOCIALES LATINOAMERICANAS.
       SECCIONES NO RECONOCIDAS PASAN SIN ATRIBUTO.
       ================================================ -->
  <xsl:template match="sec[not(@sec-type)]">
    <xsl:variable name="titulo-norm"
      select="lower-case(normalize-space(title))"/>
    <xsl:variable name="tipo-inferido">
      <xsl:choose>
        <!-- INTRODUCCIÓN -->
        <xsl:when test="$titulo-norm = 'introducción'
                     or $titulo-norm = 'introduccion'
                     or $titulo-norm = 'introduction'">intro</xsl:when>
        <!-- MÉTODOS -->
        <xsl:when test="$titulo-norm = 'metodología'
                     or $titulo-norm = 'metodologia'
                     or $titulo-norm = 'métodos'
                     or $titulo-norm = 'metodos'
                     or $titulo-norm = 'methods'
                     or $titulo-norm = 'material y métodos'
                     or $titulo-norm = 'material y metodos'
                     or $titulo-norm = 'materials and methods'">methods</xsl:when>
        <!-- RESULTADOS -->
        <xsl:when test="$titulo-norm = 'resultados'
                     or $titulo-norm = 'results'">results</xsl:when>
        <!-- DISCUSIÓN -->
        <xsl:when test="$titulo-norm = 'discusión'
                     or $titulo-norm = 'discusion'
                     or $titulo-norm = 'discussion'">discussion</xsl:when>
        <!-- RESULTADOS Y DISCUSIÓN (sección combinada) -->
        <xsl:when test="$titulo-norm = 'resultados y discusión'
                     or $titulo-norm = 'resultados y discusion'
                     or $titulo-norm = 'results and discussion'">results-discussion</xsl:when>
        <!-- CONCLUSIONES -->
        <xsl:when test="$titulo-norm = 'conclusiones'
                     or $titulo-norm = 'conclusión'
                     or $titulo-norm = 'conclusion'
                     or $titulo-norm = 'conclusions'">conclusions</xsl:when>
        <!-- AGRADECIMIENTOS -->
        <xsl:when test="$titulo-norm = 'agradecimientos'
                     or $titulo-norm = 'agradecimiento'
                     or $titulo-norm = 'acknowledgments'
                     or $titulo-norm = 'acknowledgements'">acknowledgments</xsl:when>
        <!-- MARCO TEÓRICO / REVISIÓN DE LITERATURA -->
        <xsl:when test="$titulo-norm = 'marco teórico'
                     or $titulo-norm = 'marco teorico'
                     or $titulo-norm = 'antecedentes'
                     or $titulo-norm = 'revisión de literatura'
                     or $titulo-norm = 'revision de literatura'
                     or $titulo-norm = 'revisión bibliográfica'
                     or $titulo-norm = 'literature review'">literature-review</xsl:when>
        <!-- NO RECONOCIDO: SIN SEC-TYPE -->
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <sec>
      <xsl:copy-of select="@*"/>
      <xsl:if test="$tipo-inferido != ''">
        <xsl:attribute name="sec-type">
          <xsl:value-of select="$tipo-inferido"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </sec>
  </xsl:template>

  <!-- ================================================
       SECCIONES CON sec-type YA DECLARADO
       PASAN INTACTAS POR LA IDENTIDAD ESTÁNDAR
       PERO SE DECLARA EXPLÍCITAMENTE PARA CLARIDAD
       ================================================ -->
  <xsl:template match="sec[@sec-type]">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================
       MIXED-CITATION: SUPRIMIR EXPLÍCITAMENTE
       EL CANÓNICO NO GENERA mixed-citation, PERO SE
       EXCLUYE POR TRAZABILIDAD Y COMO RED DE SEGURIDAD.
       DIFERENCIA CRÍTICA CON SCIELO:
         SciELO  → REQUIERE mixed-citation en <ref>
         Redalyc → PROHÍBE mixed-citation (JATS4R)
       ================================================ -->
  <xsl:template match="mixed-citation"/>

</xsl:stylesheet>
