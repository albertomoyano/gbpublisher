<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  jats-to-scielo.xsl
  =====================================================
  DESCRIPCIÓN:
    TRANSFORMA EL CANÓNICO JATS 1.4 ARCHIVING AL
    FORMATO SCIELO PUBLISHING SCHEMA (SPS) 1.3
    BASADO EN JATS PUBLISHING 1.0 + ESTILO SCIELO.

  DIFERENCIAS CON EL CANÓNICO:
    — DOCTYPE: JATS Publishing 1.0 (no Archiving 1.4)
    — <journal-id> con journal-id-type="nlm-ta" (acrónimo SciELO)
    — <article-id pub-id-type="publisher-id"> con PID SciELO
    — <aff> estructurada con institution/addr-line/country
    — <ref> incluye <mixed-citation> además de <element-citation>
    — <custom-meta-group> eliminado (no SPS)

  PARÁMETROS REQUERIDOS DESDE GAMBAS:
    acronimo_scielo — acrónimo SciELO de la revista (ej: hind)
    issn_scielo     — ISSN preferido (impreso si existe, sino electrónico)
    url_articulo    — URL canónica del artículo

  VALIDACIÓN:
    Usar packtools StyleChecker:
    python3 -m packtools.stylechecker archivo.xml

  DOCUMENTACIÓN SPS:
    https://scielo.readthedocs.io/projects/scielo-publishing-schema/
  =====================================================
-->
<xsl:stylesheet
  version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs">

  <!-- ================================================
       PARÁMETROS RECIBIDOS DESDE GAMBAS
       ================================================ -->
  <xsl:param name="acronimo_scielo" as="xs:string" select="''"/>
  <xsl:param name="issn_scielo"     as="xs:string" select="''"/>
  <xsl:param name="url_articulo"    as="xs:string" select="''"/>

  <!-- ================================================
       SALIDA: XML CON DOCTYPE JATS PUBLISHING 1.0
       SPS REQUIERE ESTA DTD ESPECÍFICA
       ================================================ -->
  <xsl:output
    method="xml"
    version="1.0"
    encoding="UTF-8"
    indent="yes"
    doctype-public="-//NLM//DTD JATS (Z39.96) Journal Publishing DTD v1.0 20120330//EN"
    doctype-system="JATS-journalpublishing1.dtd"/>

  <!-- ================================================
       VARIABLES GLOBALES
       ================================================ -->
  <xsl:variable name="issn-epub"  select="normalize-space(//journal-meta/issn[@pub-type='epub'])"/>
  <xsl:variable name="issn-ppub"  select="normalize-space(//journal-meta/issn[@pub-type='ppub'])"/>
  <xsl:variable name="doi"        select="normalize-space(//article-meta/article-id[@pub-id-type='doi'])"/>
  <xsl:variable name="fpage"      select="normalize-space(//article-meta/fpage)"/>
  <xsl:variable name="lpage"      select="normalize-space(//article-meta/lpage)"/>
  <xsl:variable name="volume"     select="normalize-space(//article-meta/volume)"/>
  <xsl:variable name="issue"      select="normalize-space(//article-meta/issue)"/>
  <xsl:variable name="year"       select="normalize-space(//article-meta/pub-date/year)"/>

  <!-- PID SCIELO: ISSN-acrónimo-vol-nro-paginainicio
       EJEMPLO: 1851-703X-hind-01-01-00023 -->
  <xsl:variable name="pid-scielo">
    <xsl:choose>
      <xsl:when test="$issn_scielo != '' and $acronimo_scielo != ''">
        <xsl:value-of select="$issn_scielo"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="$acronimo_scielo"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="format-number(xs:integer($volume), '00')"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="format-number(xs:integer($issue), '00')"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="format-number(xs:integer($fpage), '00000')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$doi"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- ================================================
       PLANTILLA IDENTIDAD — COPIA TODO POR DEFECTO
       copy-namespaces="no" EVITA QUE xmlns:ali Y xmlns:xsi
       SE PROPAGUEN DESDE EL CANÓNICO A TODOS LOS ELEMENTOS
       ================================================ -->
  <xsl:template match="@* | node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================
       ELEMENTO RAÍZ: <article>
       SPS REQUIERE dtd-version="1.0" Y specific-use="sps-1.9"
       PACKTOOLS 2.6.4 SOPORTA sps-1.8 Y sps-1.9 POR DEFECTO
       ================================================ -->
  <xsl:template match="article">
    <article
      xmlns:xlink="http://www.w3.org/1999/xlink"
      xmlns:mml="http://www.w3.org/1998/Math/MathML"
      dtd-version="1.0"
      specific-use="sps-1.9">
      <xsl:copy-of select="@article-type"/>
      <xsl:copy-of select="@xml:lang"/>
      <xsl:apply-templates select="front | body | back"/>
    </article>
  </xsl:template>

  <!-- ================================================
       JOURNAL-META: AGREGAR journal-id nlm-ta CON ACRÓNIMO
       SPS REQUIERE AL MENOS UN journal-id-type="nlm-ta"
       ================================================ -->
  <xsl:template match="journal-meta">
    <journal-meta>
      <!-- journal-id CON PUBLISHER-ID (YA EXISTE EN EL CANÓNICO) -->
      <xsl:apply-templates select="journal-id"/>
      <!-- journal-id nlm-ta CON ACRÓNIMO SCIELO — OBLIGATORIO EN SPS -->
      <xsl:if test="$acronimo_scielo != ''">
        <journal-id journal-id-type="nlm-ta">
          <xsl:value-of select="$acronimo_scielo"/>
        </journal-id>
      </xsl:if>
      <xsl:apply-templates select="journal-title-group | issn | publisher"/>
    </journal-meta>
  </xsl:template>

  <!-- ================================================
       JOURNAL-TITLE-GROUP: AGREGAR abbrev-journal-title
       SPS 1.9 REQUIERE abbrev-type="publisher" OBLIGATORIO
       ================================================ -->
  <xsl:template match="journal-title-group">
    <journal-title-group>
      <xsl:apply-templates select="journal-title | trans-title-group"/>
      <!-- abbrev-journal-title CON ACRÓNIMO SCIELO — OBLIGATORIO EN SPS -->
      <xsl:choose>
        <xsl:when test="abbrev-journal-title[@abbrev-type='publisher']">
          <xsl:apply-templates select="abbrev-journal-title"/>
        </xsl:when>
        <xsl:when test="$acronimo_scielo != ''">
          <abbrev-journal-title abbrev-type="publisher">
            <xsl:value-of select="$acronimo_scielo"/>
          </abbrev-journal-title>
        </xsl:when>
      </xsl:choose>
    </journal-title-group>
  </xsl:template>

  <!-- ================================================
       ARTICLE-META: AGREGAR publisher-id (PID SCIELO)
       Y LIMPIAR custom-meta-group (NO SPS)
       ================================================ -->
  <xsl:template match="article-meta">
    <article-meta>
      <!-- article-id publisher-id CON PID SCIELO -->
      <xsl:if test="$pid-scielo != ''">
        <article-id pub-id-type="publisher-id">
          <xsl:value-of select="$pid-scielo"/>
        </article-id>
      </xsl:if>
      <!-- COPIAR article-id EXISTENTES (doi, pmid, etc) -->
      <xsl:apply-templates select="article-id"/>
      <xsl:apply-templates select="article-categories | title-group | contrib-group | aff | author-notes"/>
      <!-- pub-date EN POSICIÓN CORRECTA SEGÚN DTD: ANTES DE volume -->
      <xsl:apply-templates select="pub-date" mode="sps"/>
      <xsl:if test="history/date[@date-type='pub']">
        <pub-date date-type="pub" publication-format="electronic">
          <xsl:if test="history/date[@date-type='pub']/day">
            <day><xsl:value-of select="history/date[@date-type='pub']/day"/></day>
          </xsl:if>
          <xsl:if test="history/date[@date-type='pub']/month">
            <month><xsl:value-of select="history/date[@date-type='pub']/month"/></month>
          </xsl:if>
          <year><xsl:value-of select="history/date[@date-type='pub']/year"/></year>
        </pub-date>
      </xsl:if>
      <xsl:apply-templates select="volume | issue | fpage | lpage | elocation-id | history | permissions"/>
      <!-- SELF-URI VA ANTES DE abstract SEGÚN DTD JATS PUBLISHING 1.0 -->
      <xsl:if test="$url_articulo != ''">
        <self-uri xlink:href="{$url_articulo}"/>
      </xsl:if>
      <xsl:apply-templates select="abstract | trans-abstract | kwd-group | funding-group | counts"/>
    </article-meta>
  </xsl:template>

  <!-- ================================================
       PUB-DATE EN MODO SPS:
       AGREGA date-type Y publication-format OBLIGATORIOS
       ORDEN JATS PUBLISHING 1.0: year, month, day
       USA value-of EN VEZ DE copy-of PARA EVITAR NAMESPACES ali/xsi
       ================================================ -->
  <xsl:template match="pub-date" mode="sps">
    <pub-date date-type="collection" publication-format="electronic">
      <xsl:if test="month"><month><xsl:value-of select="month"/></month></xsl:if>
      <year><xsl:value-of select="year"/></year>
    </pub-date>
  </xsl:template>

  <!-- ================================================
       CONTRIB: REORDENAR SEGÚN JATS PUBLISHING 1.0
       DTD ESPERA: contrib-id* ANTES QUE name
       ================================================ -->
  <xsl:template match="contrib">
    <contrib>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="contrib-id"/>
      <xsl:apply-templates select="name | collab | anonymous"/>
      <xsl:apply-templates select="degrees | address | aff | aff-alternatives |
        author-comment | bio | email | ext-link | on-behalf-of |
        role | uri | xref"/>
    </contrib>
  </xsl:template>

  <!-- ELIMINAR @authenticated — NO EXISTE EN JATS PUBLISHING 1.0 -->
  <xsl:template match="contrib-id">
    <contrib-id>
      <xsl:for-each select="@*">
        <xsl:if test="name() != 'authenticated'">
          <xsl:copy/>
        </xsl:if>
      </xsl:for-each>
      <xsl:value-of select="."/>
    </contrib-id>
  </xsl:template>

  <!-- ================================================
       CODE: NO EXISTE EN JATS PUBLISHING 1.0
       SE CONVIERTE A <preformat> QUE ES EL EQUIVALENTE
       ================================================ -->
  <xsl:template match="code">
    <preformat preformat-type="code">
      <xsl:if test="@language">
        <xsl:attribute name="specific-use">
          <xsl:value-of select="@language"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:value-of select="."/>
    </preformat>
  </xsl:template>

  <!-- ================================================
       AFF: ESTRUCTURAR SEGÚN SPS
       SPS REQUIERE institution CON content-type
       EL CANÓNICO TIENE TEXTO LIBRE EN <institution>
       ================================================ -->
  <xsl:template match="aff">
    <aff>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <!-- SI YA TIENE institution CON content-type, COPIAR TAL CUAL -->
        <xsl:when test="institution[@content-type]">
          <xsl:apply-templates select="@* | node()"/>
        </xsl:when>
        <!-- SI TIENE institution SIN content-type, ESTRUCTURAR PARA SPS -->
        <xsl:when test="institution">
          <institution content-type="orgname">
            <xsl:value-of select="normalize-space(institution)"/>
          </institution>
          <!-- COPIAR addr-line Y country SI EXISTEN -->
          <xsl:if test="addr-line">
            <xsl:apply-templates select="addr-line"/>
          </xsl:if>
          <xsl:if test="country">
            <xsl:apply-templates select="country"/>
          </xsl:if>
          <!-- SI NO HAY country, INTENTAR INFERIR DEL CONTEXTO -->
          <xsl:if test="not(country)">
            <country>Argentina</country>
          </xsl:if>
        </xsl:when>
        <!-- FALLBACK: COPIAR TAL CUAL -->
        <xsl:otherwise>
          <xsl:apply-templates select="@* | node()"/>
        </xsl:otherwise>
      </xsl:choose>
    </aff>
  </xsl:template>

  <!-- ================================================
       REF: AGREGAR <mixed-citation> ADEMÁS DE
       <element-citation> — OBLIGATORIO EN SPS
       mixed-citation ES EL TEXTO FORMATEADO DE LA CITA
       ================================================ -->
  <xsl:template match="ref">
    <ref>
      <xsl:copy-of select="@*"/>
      <!-- GENERAR mixed-citation DESDE element-citation -->
      <xsl:apply-templates select="element-citation" mode="mixed"/>
      <!-- COPIAR element-citation ORIGINAL -->
      <xsl:apply-templates select="element-citation"/>
    </ref>
  </xsl:template>

  <!-- ================================================
       MIXED-CITATION: TEXTO FORMATEADO SEGÚN TIPO
       GENERA UN TEXTO CONTINUO LEGIBLE A PARTIR DE
       LOS CAMPOS ESTRUCTURADOS DE element-citation
       ================================================ -->
  <xsl:template match="element-citation" mode="mixed">
    <mixed-citation publication-type="{@publication-type}">
      <xsl:call-template name="formato-mixto">
        <xsl:with-param name="cit" select="."/>
      </xsl:call-template>
    </mixed-citation>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: formato-mixto
       CONSTRUYE EL TEXTO DE LA CITA SEGÚN TIPO
       ================================================ -->
  <xsl:template name="formato-mixto">
    <xsl:param name="cit"/>
    <xsl:choose>

      <!-- ARTÍCULO DE REVISTA -->
      <xsl:when test="$cit/@publication-type = 'journal'">
        <!-- AUTORES -->
        <xsl:call-template name="autores-mixto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <!-- AÑO -->
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$cit/year"/>
          <xsl:text>). </xsl:text>
        </xsl:if>
        <!-- TÍTULO ARTÍCULO -->
        <xsl:if test="$cit/article-title">
          <xsl:value-of select="normalize-space($cit/article-title)"/>
          <xsl:text>. </xsl:text>
        </xsl:if>
        <!-- FUENTE -->
        <xsl:if test="$cit/source">
          <italic><xsl:value-of select="normalize-space($cit/source)"/></italic>
          <xsl:text>, </xsl:text>
        </xsl:if>
        <!-- VOLUMEN E ISSUE -->
        <xsl:if test="$cit/volume">
          <italic><xsl:value-of select="$cit/volume"/></italic>
        </xsl:if>
        <xsl:if test="$cit/issue">
          <xsl:text>(</xsl:text>
          <xsl:value-of select="$cit/issue"/>
          <xsl:text>)</xsl:text>
        </xsl:if>
        <!-- PÁGINAS -->
        <xsl:if test="$cit/fpage">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="$cit/fpage"/>
          <xsl:if test="$cit/lpage">
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$cit/lpage"/>
          </xsl:if>
        </xsl:if>
        <!-- DOI -->
        <xsl:if test="$cit/pub-id[@pub-id-type='doi']">
          <xsl:text>. https://doi.org/</xsl:text>
          <xsl:value-of select="$cit/pub-id[@pub-id-type='doi']"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:when>

      <!-- LIBRO -->
      <xsl:when test="$cit/@publication-type = 'book'">
        <xsl:call-template name="autores-mixto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$cit/year"/>
          <xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <italic><xsl:value-of select="normalize-space($cit/source)"/></italic>
          <xsl:text>. </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/edition">
          <xsl:value-of select="$cit/edition"/>
          <xsl:text>. </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/publisher-loc">
          <xsl:value-of select="normalize-space($cit/publisher-loc)"/>
          <xsl:text>: </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/publisher-name">
          <xsl:value-of select="normalize-space($cit/publisher-name)"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:when>

      <!-- CAPÍTULO DE LIBRO -->
      <xsl:when test="$cit/@publication-type = 'book-chapter'">
        <xsl:call-template name="autores-mixto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text>
          <xsl:value-of select="$cit/year"/>
          <xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/chapter-title">
          <xsl:value-of select="normalize-space($cit/chapter-title)"/>
          <xsl:text>. En </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/person-group[@person-group-type='editor']">
          <xsl:for-each select="$cit/person-group[@person-group-type='editor']/name">
            <xsl:value-of select="surname"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="given-names"/>
            <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
          </xsl:for-each>
          <xsl:text> (Ed</xsl:text>
          <xsl:if test="count($cit/person-group[@person-group-type='editor']/name) > 1">s</xsl:if>
          <xsl:text>.), </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <italic><xsl:value-of select="normalize-space($cit/source)"/></italic>
        </xsl:if>
        <xsl:if test="$cit/fpage">
          <xsl:text> (pp. </xsl:text>
          <xsl:value-of select="$cit/fpage"/>
          <xsl:if test="$cit/lpage">
            <xsl:text>-</xsl:text>
            <xsl:value-of select="$cit/lpage"/>
          </xsl:if>
          <xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:text>. </xsl:text>
        <xsl:if test="$cit/publisher-loc">
          <xsl:value-of select="normalize-space($cit/publisher-loc)"/>
          <xsl:text>: </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/publisher-name">
          <xsl:value-of select="normalize-space($cit/publisher-name)"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:when>

      <!-- FALLBACK: CONCATENAR LO QUE HAYA -->
      <xsl:otherwise>
        <xsl:call-template name="autores-mixto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text><xsl:value-of select="$cit/year"/><xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <italic><xsl:value-of select="normalize-space($cit/source)"/></italic>
          <xsl:text>. </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/publisher-name">
          <xsl:value-of select="normalize-space($cit/publisher-name)"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: autores-mixto
       GENERA LA LISTA DE AUTORES EN TEXTO CONTINUO
       ================================================ -->
  <xsl:template name="autores-mixto">
    <xsl:param name="cit"/>
    <xsl:variable name="autores" select="$cit/person-group[@person-group-type='author']/name"/>
    <xsl:variable name="colabs"  select="$cit/person-group[@person-group-type='author']/collab"/>
    <xsl:choose>
      <xsl:when test="$autores">
        <xsl:for-each select="$autores">
          <xsl:value-of select="normalize-space(surname)"/>
          <xsl:if test="given-names">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="normalize-space(given-names)"/>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="position() = last() - 1 and last() > 1">
              <xsl:text> y </xsl:text>
            </xsl:when>
            <xsl:when test="position() != last()">
              <xsl:text>; </xsl:text>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <xsl:when test="$colabs">
        <xsl:value-of select="normalize-space($colabs[1])"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       ELIMINAR custom-meta-group — NO ES SPS
       ================================================ -->
  <xsl:template match="custom-meta-group"/>

  <!-- ================================================
       ABSTRACT: SPS 1.9 NO ACEPTA @xml:lang EN abstract
       EL IDIOMA SE INFIERE DEL article/@xml:lang
       SOLO trans-abstract LLEVA @xml:lang
       ================================================ -->
  <xsl:template match="abstract">
    <abstract>
      <xsl:apply-templates/>
    </abstract>
  </xsl:template>

  <!-- ================================================
       LICENSE: SPS 1.9 REQUIERE @xml:lang OBLIGATORIO
       SE USA EL IDIOMA DEL ARTÍCULO COMO DEFAULT
       ================================================ -->
  <xsl:template match="license">
    <license>
      <xsl:copy-of select="@*"/>
      <xsl:if test="not(@xml:lang)">
        <xsl:attribute name="xml:lang">
          <xsl:value-of select="ancestor::article/@xml:lang"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates/>
    </license>
  </xsl:template>

  <!-- ================================================
       CAPTION: SPS REQUIERE <title> DENTRO DE <caption>
       SI NO EXISTE SE AGREGA USANDO EL TEXTO DEL PRIMER <p>
       EL <title> SIEMPRE VA PRIMERO — LUEGO EL RESTO
       ================================================ -->
  <xsl:template match="caption">
    <caption>
      <xsl:copy-of select="@*"/>
      <xsl:choose>
        <!-- SI YA TIENE title, COPIAR EN ORDEN NORMAL -->
        <xsl:when test="title">
          <xsl:apply-templates/>
        </xsl:when>
        <!-- SI NO TIENE title, GENERARLO DESDE EL PRIMER <p> -->
        <xsl:otherwise>
          <title>
            <xsl:value-of select="normalize-space(p[1])"/>
          </title>
          <!-- COPIAR EL RESTO DEL CONTENIDO (sin el primer p que ya está en title) -->
          <xsl:apply-templates select="p[position() > 1] | *[not(self::p)]"/>
        </xsl:otherwise>
      </xsl:choose>
    </caption>
  </xsl:template>

  <!-- ================================================
       ELIMINAR article-id pmid FICTICIO SI TIENE
       VALOR PLACEHOLDER
       ================================================ -->
  <xsl:template match="article-id[@pub-id-type='pmid'][normalize-space(.) = 'pm-id']"/>

</xsl:stylesheet>
