<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  Hoja     : jats-to-redalyc.xsl
  Propósito: Transforma el canónico JATS 1.4 al formato
             JATS4R requerido por Redalyc / Marcalyc.
             Redalyc no tiene schema propio: usa NISO JATS 1.4
             con JATS4R más un conjunto de elementos obligatorios
             y convenciones de uso propias.
  Entrada  : c-NN-revistaSlug-vNN-nNN.xml  (canónico JATS)
  Salida   : r-NN-revistaSlug-vNN-nNN.xml  (Redalyc JATS4R)
  Motor    : Saxon-HE (XSLT 2.0)
  Notas    : - La transformación es esencialmente una copia
               identidad con los siguientes ajustes específicos
               para Redalyc:
               1. Se elimina el namespace xlink del elemento
                  raíz y se re-declara correctamente.
               2. Se normaliza el atributo license-type a
                  "open-access" en <license> (obligatorio).
               3. Se garantiza que <abstract> tenga xml:lang.
               4. Se normaliza <trans-abstract> con xml:lang.
               5. Se agrega <journal-id journal-id-type="redalyc">
                  si no existe, derivado del e_issn o issn.
             - Redalyc acepta XMLs generados con otras
               herramientas siempre que pasen el validador
               PMC: https://www.ncbi.nlm.nih.gov/pmc/tools/xmlchecker/
             - La validación de reglas de negocio propias de
               Redalyc se realiza en Gambas (ValidarArchivoRedalyc).
  Versión  : 1.0
  ============================================================
-->
<xsl:stylesheet
  version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="xlink">

  <xsl:output
    method="xml"
    version="1.0"
    encoding="UTF-8"
    indent="yes"
    doctype-public="-//NLM//DTD JATS (Z39.96) Article Authoring DTD v1.4//EN"
    doctype-system="https://jats.nlm.nih.gov/authoring/1.4/JATS-articleauthoring1-4.dtd"/>

  <!-- ============================================================
       PLANTILLA DE IDENTIDAD — COPIA TODO POR DEFECTO
       Las plantillas específicas a continuación sobreescriben
       solo los casos que requieren ajuste para Redalyc.
       ============================================================ -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA RAÍZ
       ============================================================ -->
  <xsl:template match="/">
    <xsl:comment> ARCHIVO GENERADO AUTOMÁTICAMENTE POR GBPUBLISHER </xsl:comment>
    <xsl:comment> Validar en: https://www.ncbi.nlm.nih.gov/pmc/tools/xmlchecker/ </xsl:comment>
    <xsl:apply-templates select="article"/>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <article>
       Garantiza que el namespace xlink esté declarado
       correctamente en el elemento raíz.
       ============================================================ -->
  <xsl:template match="article">
    <article>
      <!-- COPIAR ATRIBUTOS DEL ELEMENTO RAÍZ -->
      <xsl:copy-of select="@article-type"/>
      <xsl:copy-of select="@xml:lang"/>
      <!-- NAMESPACE XLINK OBLIGATORIO PARA JATS4R -->
      <xsl:namespace name="xlink">http://www.w3.org/1999/xlink</xsl:namespace>
      <xsl:apply-templates select="front | body | back"/>
    </article>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <journal-meta>
       Agrega <journal-id journal-id-type="redalyc"> si no existe.
       Redalyc utiliza este identificador para vincular la revista
       en su sistema interno. Se deriva del ISSN electrónico o
       impreso disponible.
       ============================================================ -->
  <xsl:template match="journal-meta">
    <journal-meta>
      <!-- COPIAR journal-id EXISTENTES -->
      <xsl:apply-templates select="journal-id"/>

      <!-- AGREGAR journal-id TIPO redalyc SI NO EXISTE -->
      <xsl:if test="not(journal-id[@journal-id-type='redalyc'])">
        <xsl:variable name="idRedalyc">
          <xsl:choose>
            <xsl:when test="issn[@pub-type='epub']">
              <xsl:value-of select="normalize-space(issn[@pub-type='epub'])"/>
            </xsl:when>
            <xsl:when test="issn[@pub-type='ppub']">
              <xsl:value-of select="normalize-space(issn[@pub-type='ppub'])"/>
            </xsl:when>
            <xsl:otherwise></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="$idRedalyc != ''">
          <journal-id journal-id-type="redalyc">
            <xsl:value-of select="$idRedalyc"/>
          </journal-id>
        </xsl:if>
      </xsl:if>

      <!-- COPIAR EL RESTO DE ELEMENTOS DE journal-meta -->
      <xsl:apply-templates select="journal-title-group | issn | publisher"/>
    </journal-meta>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <license>
       Normaliza license-type a "open-access" (requerido por
       Redalyc que indexa exclusivamente revistas AA).
       Preserva xlink:href y el contenido del elemento.
       ============================================================ -->
  <xsl:template match="license">
    <license license-type="open-access">
      <!-- PRESERVAR xlink:href SI EXISTE -->
      <xsl:if test="@xlink:href">
        <xsl:attribute name="xlink:href">
          <xsl:value-of select="@xlink:href"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="node()"/>
    </license>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <abstract>
       Garantiza que abstract tenga xml:lang.
       Usa la cascada estándar del proyecto:
         abstract/@xml:lang → custom-meta xml-lang → article/@xml:lang → 'es'
       ============================================================ -->
  <xsl:template match="abstract">
    <xsl:variable name="xmlLang">
      <xsl:choose>
        <xsl:when test="@xml:lang">
          <xsl:value-of select="@xml:lang"/>
        </xsl:when>
        <xsl:when test="ancestor::article-meta/custom-meta-group/custom-meta[meta-name='xml-lang']/meta-value">
          <xsl:value-of select="normalize-space(ancestor::article-meta/custom-meta-group/custom-meta[meta-name='xml-lang']/meta-value)"/>
        </xsl:when>
        <xsl:when test="ancestor::article/@xml:lang">
          <xsl:value-of select="ancestor::article/@xml:lang"/>
        </xsl:when>
        <xsl:otherwise>es</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <abstract>
      <xsl:attribute name="xml:lang">
        <xsl:value-of select="$xmlLang"/>
      </xsl:attribute>
      <xsl:apply-templates select="node()"/>
    </abstract>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <trans-abstract>
       Garantiza xml:lang en todos los resúmenes traducidos.
       ============================================================ -->
  <xsl:template match="trans-abstract">
    <xsl:if test="@xml:lang and normalize-space(.) != ''">
      <trans-abstract>
        <xsl:attribute name="xml:lang">
          <xsl:value-of select="@xml:lang"/>
        </xsl:attribute>
        <xsl:apply-templates select="node()"/>
      </trans-abstract>
    </xsl:if>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <kwd-group>
       Garantiza xml:lang en todos los grupos de palabras clave.
       ============================================================ -->
  <xsl:template match="kwd-group">
    <xsl:if test="kwd">
      <kwd-group>
        <xsl:if test="@xml:lang">
          <xsl:attribute name="xml:lang">
            <xsl:value-of select="@xml:lang"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:if test="@kwd-group-type">
          <xsl:attribute name="kwd-group-type">
            <xsl:value-of select="@kwd-group-type"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:apply-templates select="kwd"/>
      </kwd-group>
    </xsl:if>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <contrib>
       Redalyc requiere que contrib-id ORCID tenga la URL completa
       (https://orcid.org/XXXX-XXXX-XXXX-XXXX).
       Si solo tiene el número, se completa la URL.
       ============================================================ -->
  <xsl:template match="contrib-id[@contrib-id-type='orcid']">
    <xsl:variable name="valorOrcid" select="normalize-space(.)"/>
    <contrib-id contrib-id-type="orcid">
      <xsl:if test="@authenticated">
        <xsl:attribute name="authenticated">
          <xsl:value-of select="@authenticated"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <!-- YA TIENE URL COMPLETA -->
        <xsl:when test="starts-with($valorOrcid, 'https://orcid.org/')">
          <xsl:value-of select="$valorOrcid"/>
        </xsl:when>
        <!-- TIENE SOLO EL NÚMERO: COMPLETAR URL -->
        <xsl:when test="$valorOrcid != ''">
          <xsl:text>https://orcid.org/</xsl:text>
          <xsl:value-of select="$valorOrcid"/>
        </xsl:when>
      </xsl:choose>
    </contrib-id>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA: <ref>
       Redalyc / JATS4R recomienda element-citation sobre
       mixed-citation. El canónico de gbpublisher ya genera
       element-citation, así que la copia es directa.
       Se preserva el id del <ref> para que las <xref> funcionen.
       ============================================================ -->
  <xsl:template match="ref">
    <ref>
      <xsl:copy-of select="@id"/>
      <xsl:apply-templates select="element-citation | mixed-citation | note"/>
    </ref>
  </xsl:template>


</xsl:stylesheet>
