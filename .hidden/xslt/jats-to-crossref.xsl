<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  jats-to-crossref.xsl
  =====================================================
  DESCRIPCIÓN:
    TRANSFORMA EL CANÓNICO JATS 1.4 AL FORMATO DE
    DEPÓSITO CROSSREF SCHEMA 5.3.1.
    GENERA UN doi_batch CON METADATOS COMPLETOS DEL
    ARTÍCULO PARA REGISTRO DE DOI EN CROSSREF.

  PARÁMETROS REQUERIDOS DESDE GAMBAS:
    depositor_name  — nombre de la editorial depositante
    email_address   — email del depositante
    registrant      — institución registrante
    doi_prefix      — prefijo DOI de la revista (ej: 10.56503)
    url_articulo    — URL canónica del artículo
    timestamp       — timestamp único del batch (yyyymmddHHnnss)
    batch_id        — ID único del batch

  DOCUMENTACIÓN CROSSREF SCHEMA 5.3.1:
    https://www.crossref.org/documentation/schema-library/
    /metadata-deposit-schema-5-3-1/
  =====================================================
-->
<xsl:stylesheet
  version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="xs xlink">

  <!-- ================================================
       PARÁMETROS RECIBIDOS DESDE GAMBAS
       ================================================ -->
  <xsl:param name="depositor_name" as="xs:string" select="''"/>
  <xsl:param name="email_address"  as="xs:string" select="''"/>
  <xsl:param name="registrant"     as="xs:string" select="''"/>
  <xsl:param name="doi_prefix"     as="xs:string" select="''"/>
  <xsl:param name="url_articulo"   as="xs:string" select="''"/>
  <xsl:param name="timestamp"      as="xs:string" select="''"/>
  <xsl:param name="batch_id"       as="xs:string" select="''"/>

  <!-- ================================================
       SALIDA: XML CROSSREF 5.3.1
       ================================================ -->
  <xsl:output
    method="xml"
    version="1.0"
    encoding="UTF-8"
    indent="yes"/>

  <!-- ================================================
       VARIABLES GLOBALES DEL ARTÍCULO
       ================================================ -->
  <xsl:variable name="doi"      select="normalize-space(//article-meta/article-id[@pub-id-type='doi'])"/>
  <xsl:variable name="lang"     select="normalize-space(/article/@xml:lang)"/>
  <xsl:variable name="fpage"    select="normalize-space(//article-meta/fpage)"/>
  <xsl:variable name="lpage"    select="normalize-space(//article-meta/lpage)"/>
  <xsl:variable name="volume"   select="normalize-space(//article-meta/volume)"/>
  <xsl:variable name="issue"    select="normalize-space(//article-meta/issue)"/>

  <!-- ================================================
       TEMPLATE PRINCIPAL
       ================================================ -->
  <xsl:template match="/">
    <doi_batch
      xmlns="http://www.crossref.org/schema/5.3.1"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xmlns:jats="http://www.ncbi.nlm.nih.gov/JATS1"
      xmlns:fr="http://www.crossref.org/fundref.xsd"
      xmlns:mml="http://www.w3.org/1998/Math/MathML"
      xsi:schemaLocation="http://www.crossref.org/schema/5.3.1 https://www.crossref.org/schemas/crossref5.3.1.xsd"
      version="5.3.1">

      <!-- HEAD: IDENTIFICACIÓN DEL BATCH -->
      <head>
        <doi_batch_id><xsl:value-of select="$batch_id"/></doi_batch_id>
        <timestamp><xsl:value-of select="$timestamp"/></timestamp>
        <depositor>
          <depositor_name><xsl:value-of select="$depositor_name"/></depositor_name>
          <email_address><xsl:value-of select="$email_address"/></email_address>
        </depositor>
        <registrant><xsl:value-of select="$registrant"/></registrant>
      </head>

      <!-- BODY: DATOS DEL JOURNAL Y ARTÍCULO -->
      <body>
        <journal>

          <!-- METADATA DE LA REVISTA -->
          <journal_metadata language="{$lang}" reference_distribution_opts="any">
            <full_title>
              <xsl:value-of select="normalize-space(//journal-meta/journal-title-group/journal-title)"/>
            </full_title>
            <xsl:if test="normalize-space(//journal-meta/journal-title-group/abbrev-journal-title) != ''">
              <abbrev_title>
                <xsl:value-of select="normalize-space(//journal-meta/journal-title-group/abbrev-journal-title)"/>
              </abbrev_title>
            </xsl:if>
            <!-- ISSN ELECTRÓNICO -->
            <xsl:if test="normalize-space(//journal-meta/issn[@pub-type='epub']) != ''">
              <issn media_type="electronic">
                <xsl:value-of select="normalize-space(//journal-meta/issn[@pub-type='epub'])"/>
              </issn>
            </xsl:if>
            <!-- ISSN IMPRESO -->
            <xsl:if test="normalize-space(//journal-meta/issn[@pub-type='ppub']) != ''">
              <issn media_type="print">
                <xsl:value-of select="normalize-space(//journal-meta/issn[@pub-type='ppub'])"/>
              </issn>
            </xsl:if>
          </journal_metadata>

          <!-- ISSUE: VOLUMEN Y NÚMERO -->
          <xsl:if test="$volume != '' or $issue != ''">
            <journal_issue>
              <publication_date media_type="online">
                <xsl:call-template name="publication-date"/>
              </publication_date>
              <xsl:if test="$volume != ''">
                <journal_volume>
                  <volume><xsl:value-of select="$volume"/></volume>
                </journal_volume>
              </xsl:if>
              <xsl:if test="$issue != ''">
                <issue><xsl:value-of select="$issue"/></issue>
              </xsl:if>
            </journal_issue>
          </xsl:if>

          <!-- ARTÍCULO -->
          <journal_article language="{$lang}" publication_type="full_text" reference_distribution_opts="any">

            <!-- TÍTULO -->
            <titles>
              <title>
                <xsl:value-of select="normalize-space(//article-meta/title-group/article-title)"/>
              </title>
              <!-- TÍTULO TRADUCIDO SI EXISTE -->
              <xsl:for-each select="//article-meta/title-group/trans-title-group">
                <original_language_title language="{@xml:lang}">
                  <xsl:value-of select="normalize-space(trans-title)"/>
                </original_language_title>
              </xsl:for-each>
            </titles>

            <!-- AUTORES -->
            <xsl:if test="//article-meta/contrib-group/contrib[@contrib-type='author']">
              <contributors>
                <xsl:for-each select="//article-meta/contrib-group/contrib[@contrib-type='author']">
                  <xsl:variable name="secuencia">
                    <xsl:choose>
                      <xsl:when test="position() = 1">first</xsl:when>
                      <xsl:otherwise>additional</xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <person_name sequence="{$secuencia}" contributor_role="author">
                    <given_name>
                      <xsl:value-of select="normalize-space(name/given-names)"/>
                    </given_name>
                    <surname>
                      <xsl:value-of select="normalize-space(name/surname)"/>
                    </surname>
                    <!-- AFILIACIÓN -->
                    <xsl:variable name="aff-id" select="xref[@ref-type='aff']/@rid"/>
                    <xsl:variable name="aff-text" select="normalize-space(//aff[@id=$aff-id]/institution)"/>
                    <xsl:if test="$aff-text != ''">
                      <affiliations>
                        <institution>
                          <institution_name><xsl:value-of select="$aff-text"/></institution_name>
                        </institution>
                      </affiliations>
                    </xsl:if>
                    <!-- ORCID -->
                    <xsl:variable name="orcid" select="normalize-space(contrib-id[@contrib-id-type='orcid'])"/>
                    <xsl:if test="$orcid != ''">
                      <ORCID authenticated="true">
                        <xsl:choose>
                          <xsl:when test="starts-with($orcid, 'https://')">
                            <xsl:value-of select="$orcid"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:text>https://orcid.org/</xsl:text>
                            <xsl:value-of select="$orcid"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </ORCID>
                    </xsl:if>
                  </person_name>
                </xsl:for-each>
              </contributors>
            </xsl:if>

            <!-- RESÚMENES CON NAMESPACE JATS -->
            <xsl:for-each select="//article-meta/abstract">
              <jats:abstract>
                <xsl:for-each select="p">
                  <jats:p>
                    <xsl:if test="../@xml:lang != ''">
                      <xsl:attribute name="xml:lang">
                        <xsl:value-of select="../@xml:lang"/>
                      </xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                  </jats:p>
                </xsl:for-each>
              </jats:abstract>
            </xsl:for-each>
            <xsl:for-each select="//article-meta/trans-abstract">
              <jats:abstract>
                <xsl:for-each select="p">
                  <jats:p>
                    <xsl:if test="../@xml:lang != ''">
                      <xsl:attribute name="xml:lang">
                        <xsl:value-of select="../@xml:lang"/>
                      </xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                  </jats:p>
                </xsl:for-each>
              </jats:abstract>
            </xsl:for-each>

            <!-- FECHA DE PUBLICACIÓN -->
            <publication_date media_type="online">
              <xsl:call-template name="publication-date"/>
            </publication_date>

            <!-- PÁGINAS -->
            <xsl:if test="$fpage != ''">
              <pages>
                <first_page><xsl:value-of select="$fpage"/></first_page>
                <xsl:if test="$lpage != ''">
                  <last_page><xsl:value-of select="$lpage"/></last_page>
                </xsl:if>
              </pages>
            </xsl:if>

            <!-- LICENCIA CC -->
            <xsl:variable name="url-lic" select="normalize-space(//article-meta/permissions/license/@xlink:href)"/>
            <xsl:if test="$url-lic != ''">
              <program xmlns="http://www.crossref.org/AccessIndicators.xsd">
                <free_to_read/>
                <license_ref applies_to="vor">
                  <xsl:value-of select="$url-lic"/>
                </license_ref>
              </program>
            </xsl:if>

            <!-- DOI Y URL DEL ARTÍCULO -->
            <doi_data>
              <doi><xsl:value-of select="$doi"/></doi>
              <resource content_version="vor" mime_type="text/html">
                <xsl:choose>
                  <!-- URL VÁLIDA: DEBE COMENZAR CON http O https -->
                  <xsl:when test="starts-with($url_articulo, 'http://') or starts-with($url_articulo, 'https://')">
                    <xsl:value-of select="$url_articulo"/>
                  </xsl:when>
                  <!-- FALLBACK: CONSTRUIR URL DESDE DOI -->
                  <xsl:otherwise>
                    <xsl:text>https://doi.org/</xsl:text>
                    <xsl:value-of select="$doi"/>
                  </xsl:otherwise>
                </xsl:choose>
              </resource>
            </doi_data>

            <!-- LISTA DE CITAS -->
            <xsl:if test="//ref-list/ref">
              <citation_list>
                <xsl:for-each select="//ref-list/ref">
                  <citation key="{@id}">
                    <!-- SI TIENE DOI ESTRUCTURADO LO USAMOS -->
                    <xsl:variable name="ref-doi" select="normalize-space(.//pub-id[@pub-id-type='doi'])"/>
                    <xsl:if test="$ref-doi != ''">
                      <doi><xsl:value-of select="$ref-doi"/></doi>
                    </xsl:if>
                    <!-- CITA NO ESTRUCTURADA GENERADA DESDE element-citation -->
                    <unstructured_citation>
                      <xsl:call-template name="formato-cita">
                        <xsl:with-param name="cit" select="element-citation"/>
                      </xsl:call-template>
                    </unstructured_citation>
                  </citation>
                </xsl:for-each>
              </citation_list>
            </xsl:if>

          </journal_article>
        </journal>
      </body>
    </doi_batch>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: publication-date
       EXTRAE DÍA, MES Y AÑO DEL pub-date DEL CANÓNICO
       ================================================ -->
  <xsl:template name="publication-date">
    <xsl:variable name="pd" select="//article-meta/pub-date[1]"/>
    <!-- xsl:element CON namespace EXPLÍCITO EVITA QUE SAXON EMITA xmlns="" -->
    <xsl:if test="normalize-space($pd/month) != ''">
      <xsl:element name="month" namespace="http://www.crossref.org/schema/5.3.1">
        <xsl:value-of select="normalize-space($pd/month)"/>
      </xsl:element>
    </xsl:if>
    <xsl:if test="normalize-space($pd/day) != ''">
      <xsl:element name="day" namespace="http://www.crossref.org/schema/5.3.1">
        <xsl:value-of select="normalize-space($pd/day)"/>
      </xsl:element>
    </xsl:if>
    <xsl:element name="year" namespace="http://www.crossref.org/schema/5.3.1">
      <xsl:value-of select="normalize-space($pd/year)"/>
    </xsl:element>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: formato-cita
       GENERA TEXTO FORMATEADO DESDE element-citation
       MISMO PATRÓN QUE jats-to-scielo.xsl
       ================================================ -->
  <xsl:template name="formato-cita">
    <xsl:param name="cit"/>
    <xsl:choose>

      <!-- ARTÍCULO DE REVISTA -->
      <xsl:when test="$cit/@publication-type = 'journal'">
        <xsl:call-template name="autores-texto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text><xsl:value-of select="$cit/year"/><xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/article-title">
          <xsl:value-of select="normalize-space($cit/article-title)"/>
          <xsl:text>. </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <xsl:value-of select="normalize-space($cit/source)"/>
          <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/volume">
          <xsl:value-of select="$cit/volume"/>
        </xsl:if>
        <xsl:if test="$cit/issue">
          <xsl:text>(</xsl:text><xsl:value-of select="$cit/issue"/><xsl:text>)</xsl:text>
        </xsl:if>
        <xsl:if test="$cit/fpage">
          <xsl:text>, </xsl:text><xsl:value-of select="$cit/fpage"/>
          <xsl:if test="$cit/lpage">
            <xsl:text>-</xsl:text><xsl:value-of select="$cit/lpage"/>
          </xsl:if>
        </xsl:if>
        <xsl:if test="$cit/pub-id[@pub-id-type='doi']">
          <xsl:text>. https://doi.org/</xsl:text>
          <xsl:value-of select="$cit/pub-id[@pub-id-type='doi']"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:when>

      <!-- LIBRO -->
      <xsl:when test="$cit/@publication-type = 'book'">
        <xsl:call-template name="autores-texto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text><xsl:value-of select="$cit/year"/><xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <xsl:value-of select="normalize-space($cit/source)"/>
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
        <xsl:call-template name="autores-texto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text><xsl:value-of select="$cit/year"/><xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/chapter-title">
          <xsl:value-of select="normalize-space($cit/chapter-title)"/>
          <xsl:text>. En </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <xsl:value-of select="normalize-space($cit/source)"/>
        </xsl:if>
        <xsl:if test="$cit/fpage">
          <xsl:text> (pp. </xsl:text><xsl:value-of select="$cit/fpage"/>
          <xsl:if test="$cit/lpage">
            <xsl:text>-</xsl:text><xsl:value-of select="$cit/lpage"/>
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

      <!-- FALLBACK -->
      <xsl:otherwise>
        <xsl:call-template name="autores-texto">
          <xsl:with-param name="cit" select="$cit"/>
        </xsl:call-template>
        <xsl:if test="$cit/year">
          <xsl:text> (</xsl:text><xsl:value-of select="$cit/year"/><xsl:text>). </xsl:text>
        </xsl:if>
        <xsl:if test="$cit/source">
          <xsl:value-of select="normalize-space($cit/source)"/>
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
       NAMED TEMPLATE: autores-texto
       GENERA LISTA DE AUTORES EN TEXTO CONTINUO
       ================================================ -->
  <xsl:template name="autores-texto">
    <xsl:param name="cit"/>
    <xsl:variable name="autores" select="$cit/person-group[@person-group-type='author']/name"/>
    <xsl:variable name="editores" select="$cit/person-group[@person-group-type='editor']/name"/>
    <xsl:variable name="colabs"   select="$cit/person-group[@person-group-type='author']/collab"/>
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
      <xsl:when test="$editores">
        <xsl:for-each select="$editores">
          <xsl:value-of select="normalize-space(surname)"/>
          <xsl:if test="given-names">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="normalize-space(given-names)"/>
          </xsl:if>
          <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:text> (Ed</xsl:text>
        <xsl:if test="count($editores) > 1">s</xsl:if>
        <xsl:text>.)</xsl:text>
      </xsl:when>
      <xsl:when test="$colabs">
        <xsl:value-of select="normalize-space($colabs[1])"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
