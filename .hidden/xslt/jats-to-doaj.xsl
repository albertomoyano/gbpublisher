<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  Hoja     : jats-to-doaj.xsl
  Propósito: Transforma el canónico JATS 1.4 al formato DOAJ
             XML nativo (doajArticles.xsd v1.3).
  Entrada  : c-NN-revistaSlug-vNN-nNN.xml  (canónico JATS)
  Salida   : d-NN-revistaSlug-vNN-nNN.xml  (DOAJ XML)
  Motor    : Saxon-HE (XSLT 2.0)
  Notas    : - El campo fullTextUrl NO está en el canónico.
               Debe pasarse como parámetro Saxon ($fullTextUrl)
               o incorporarse como custom-meta en el canónico
               antes de la transformación.
             - DOAJ acepta solo un idioma para título y abstract.
               Se usa el idioma principal del artículo (xml:lang
               en <article> o custom-meta 'xml-lang').
             - Idiomas: ISO 639-1 → ISO 639-2b (es→spa, en→eng,
               pt→por, fr→fre, de→ger, it→ita, pt→por)
             - Orden de elementos según doajArticles.xsd v1.3:
               abstract → fullTextUrl → keywords
  Versión  : 1.4
  Cambios  : 1.1 — normalize-space() en eissn, issn, orcid_id,
                    doi, publisherRecordId, title, afiliaciones,
                    abstract/p, keywords y campos de fecha para
             1.2 — string-join(aff/institution) para soportar autores
                    con múltiples afiliaciones institucionales.
             1.3 — Renombrado elemento <n> a <name> segun doajArticles.xsd.
                    eliminar whitespace de indentación del canónico.
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
    indent="yes"/>

  <!-- ============================================================
       PARÁMETROS EXTERNOS
       Pueden pasarse desde Saxon con -param:nombre valor
       o desde Gambas vía Shell al invocar el proceso Saxon.
       ============================================================ -->

  <!-- URL DEL TEXTO COMPLETO: obligatoria en la práctica para DOAJ.
       Si no se pasa y tampoco está en custom-meta, el campo se omite
       y se inserta un comentario XML como advertencia. -->
  <xsl:param name="fullTextUrl" select="''"/>

  <!-- FORMATO DEL TEXTO COMPLETO: text/html | application/pdf -->
  <xsl:param name="fullTextFormat" select="'text/html'"/>

  <!-- TIPO DE DOCUMENTO: sobrescribe la detección automática si se
       proporciona. Valores válidos: article | review | other -->
  <xsl:param name="documentType" select="''"/>


  <!-- ============================================================
       PLANTILLA RAÍZ
       ============================================================ -->
  <xsl:template match="/">
    <xsl:comment> ARCHIVO GENERADO AUTOMÁTICAMENTE POR GBPUBLISHER </xsl:comment>
    <xsl:comment> Validar contra: ~/.gbpublisher/schemas/doajArticles.xsd </xsl:comment>
    <records>
      <xsl:apply-templates select="article"/>
    </records>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA PRINCIPAL: <article> → <record>
       ============================================================ -->
  <xsl:template match="article">

    <!-- 1. RESOLUCIÓN DEL IDIOMA PRINCIPAL -->
    <!--
      Cascada de detección:
      1. abstract/@xml:lang (idioma declarado en el resumen principal)
      2. custom-meta[meta-name='xml-lang']/meta-value
      3. article/@xml:lang
      4. 'es' como último recurso
    -->
    <xsl:variable name="langISO1">
      <xsl:choose>
        <xsl:when test="front/article-meta/abstract/@xml:lang">
          <xsl:value-of select="front/article-meta/abstract/@xml:lang"/>
        </xsl:when>
        <xsl:when test="front/article-meta/custom-meta-group/custom-meta[meta-name='xml-lang']/meta-value">
          <xsl:value-of select="normalize-space(front/article-meta/custom-meta-group/custom-meta[meta-name='xml-lang']/meta-value)"/>
        </xsl:when>
        <xsl:when test="@xml:lang">
          <xsl:value-of select="@xml:lang"/>
        </xsl:when>
        <xsl:otherwise>es</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- CONVERSIÓN ISO 639-1 → ISO 639-2b (requerido por DOAJ) -->
    <xsl:variable name="langISO2b">
      <xsl:call-template name="iso1-to-iso2b">
        <xsl:with-param name="lang" select="$langISO1"/>
      </xsl:call-template>
    </xsl:variable>

    <!-- 2. RESOLUCIÓN DE LA URL DEL TEXTO COMPLETO -->
    <!--
      Cascada de resolución:
      1. Parámetro externo Saxon $fullTextUrl
      2. custom-meta[meta-name='fullTextUrl'] en el canónico
      3. self-uri en article-meta
      4. Cadena vacía (se emite advertencia)
    -->
    <xsl:variable name="resolvedUrl">
      <xsl:choose>
        <xsl:when test="$fullTextUrl != ''">
          <xsl:value-of select="$fullTextUrl"/>
        </xsl:when>
        <xsl:when test="front/article-meta/custom-meta-group/custom-meta[normalize-space(meta-name)='fullTextUrl']/meta-value">
          <xsl:value-of select="normalize-space(front/article-meta/custom-meta-group/custom-meta[normalize-space(meta-name)='fullTextUrl']/meta-value)"/>
        </xsl:when>
        <xsl:when test="front/article-meta/self-uri/@xlink:href">
          <xsl:value-of select="front/article-meta/self-uri/@xlink:href"/>
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- 3. RESOLUCIÓN DEL TIPO DE DOCUMENTO -->
    <xsl:variable name="resolvedDocType">
      <xsl:choose>
        <xsl:when test="$documentType != ''">
          <xsl:value-of select="$documentType"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="map-article-type">
            <xsl:with-param name="type" select="@article-type"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- 4. CONSTRUCCIÓN DEL REGISTRO DOAJ -->
    <record>

      <!-- IDIOMA DEL ARTÍCULO (ISO 639-2b) -->
      <language>
        <xsl:value-of select="$langISO2b"/>
      </language>

      <!-- EDITORIAL -->
      <publisher>
        <xsl:value-of select="normalize-space(front/journal-meta/publisher/publisher-name)"/>
      </publisher>

      <!-- TÍTULO DE LA REVISTA -->
      <journalTitle>
        <xsl:value-of select="normalize-space(front/journal-meta/journal-title-group/journal-title)"/>
      </journalTitle>

      <!-- ISSN IMPRESO (opcional en XSD, pero DOAJ requiere al menos uno) -->
      <xsl:if test="front/journal-meta/issn[@pub-type='ppub']">
        <issn>
          <xsl:value-of select="normalize-space(front/journal-meta/issn[@pub-type='ppub'])"/>
        </issn>
      </xsl:if>

      <!-- ISSN ELECTRÓNICO -->
      <xsl:if test="front/journal-meta/issn[@pub-type='epub']">
        <eissn>
          <xsl:value-of select="normalize-space(front/journal-meta/issn[@pub-type='epub'])"/>
        </eissn>
      </xsl:if>

      <!-- ADVERTENCIA SI NO HAY NINGÚN ISSN -->
      <xsl:if test="not(front/journal-meta/issn)">
        <xsl:comment> ADVERTENCIA: No se encontró ningún ISSN. DOAJ requiere al menos uno. </xsl:comment>
      </xsl:if>

      <!-- FECHA DE PUBLICACIÓN: prioridad epub-ppub, luego pub, luego epub -->
      <publicationDate>
        <xsl:call-template name="build-date">
          <xsl:with-param name="dateNode" select="front/article-meta/pub-date[@pub-type='epub-ppub']"/>
          <xsl:with-param name="fallbackNode" select="front/article-meta/history/date[@date-type='pub']"/>
        </xsl:call-template>
      </publicationDate>

      <!-- VOLUMEN -->
      <xsl:if test="front/article-meta/volume != ''">
        <volume>
          <xsl:value-of select="normalize-space(front/article-meta/volume)"/>
        </volume>
      </xsl:if>

      <!-- NÚMERO / FASCÍCULO -->
      <xsl:if test="front/article-meta/issue != ''">
        <issue>
          <xsl:value-of select="normalize-space(front/article-meta/issue)"/>
        </issue>
      </xsl:if>

      <!-- PÁGINAS -->
      <xsl:if test="front/article-meta/fpage != ''">
        <startPage>
          <xsl:value-of select="normalize-space(front/article-meta/fpage)"/>
        </startPage>
      </xsl:if>
      <xsl:if test="front/article-meta/lpage != ''">
        <endPage>
          <xsl:value-of select="normalize-space(front/article-meta/lpage)"/>
        </endPage>
      </xsl:if>

      <!-- DOI -->
      <xsl:if test="front/article-meta/article-id[@pub-id-type='doi']">
        <doi>
          <xsl:value-of select="normalize-space(front/article-meta/article-id[@pub-id-type='doi'])"/>
        </doi>
      </xsl:if>

      <!-- ID INTERNO DEL EDITOR -->
      <xsl:if test="front/article-meta/article-id[@pub-id-type='publisher-id']">
        <publisherRecordId>
          <xsl:value-of select="normalize-space(front/article-meta/article-id[@pub-id-type='publisher-id'])"/>
        </publisherRecordId>
      </xsl:if>

      <!-- TIPO DE DOCUMENTO -->
      <documentType>
        <xsl:value-of select="$resolvedDocType"/>
      </documentType>

      <!-- TÍTULO DEL ARTÍCULO EN EL IDIOMA PRINCIPAL -->
      <title>
        <xsl:attribute name="language">
          <xsl:value-of select="$langISO2b"/>
        </xsl:attribute>
        <xsl:value-of select="normalize-space(front/article-meta/title-group/article-title)"/>
      </title>

      <!-- ======================================================
           AUTORES Y AFILIACIONES
           Las afiliaciones están inline en <aff> dentro de
           cada <contrib>. Se generan IDs correlativos.
           ====================================================== -->
      <xsl:if test="front/article-meta/contrib-group/contrib[@contrib-type='author']">
        <authors>
          <xsl:for-each select="front/article-meta/contrib-group/contrib[@contrib-type='author']">
            <author>
              <!-- NOMBRE: apellido, nombre (formato DOAJ) -->
              <name>
                <xsl:value-of select="normalize-space(name/surname)"/>
                <xsl:if test="name/given-names">
                  <xsl:text>, </xsl:text>
                  <xsl:value-of select="normalize-space(name/given-names)"/>
                </xsl:if>
              </name>
              <!-- ID DE AFILIACIÓN: correlativo por posición del autor -->
              <xsl:if test="aff/institution">
                <affiliationId>
                  <xsl:value-of select="position()"/>
                </affiliationId>
              </xsl:if>
              <!-- ORCID -->
              <xsl:if test="contrib-id[@contrib-id-type='orcid']">
                <orcid_id>
                  <xsl:value-of select="normalize-space(contrib-id[@contrib-id-type='orcid'])"/>
                </orcid_id>
              </xsl:if>
            </author>
          </xsl:for-each>
        </authors>

        <!-- LISTA DE AFILIACIONES: se itera sobre TODOS los autores
             (mismo conjunto que <authors>) para que position() coincida.
             Solo se emite <affiliationName> si el autor tiene <aff>. -->
        <xsl:if test="front/article-meta/contrib-group/contrib[@contrib-type='author'][aff/institution]">
          <affiliationsList>
            <xsl:for-each select="front/article-meta/contrib-group/contrib[@contrib-type='author']">
              <xsl:if test="aff/institution">
                <affiliationName>
                  <xsl:attribute name="affiliationId">
                    <xsl:value-of select="position()"/>
                  </xsl:attribute>
                  <xsl:value-of select="normalize-space(string-join(aff/institution, ', '))"/>
                </affiliationName>
              </xsl:if>
            </xsl:for-each>
          </affiliationsList>
        </xsl:if>
      </xsl:if>

      <!-- ABSTRACT EN EL IDIOMA PRINCIPAL -->
      <!-- ORDEN XSD v1.3: abstract → fullTextUrl → keywords -->
      <xsl:variable name="mainAbstract"
        select="front/article-meta/abstract[@xml:lang = $langISO1]
              | front/article-meta/abstract[not(@xml:lang)]"/>
      <xsl:if test="$mainAbstract">
        <abstract>
          <xsl:attribute name="language">
            <xsl:value-of select="$langISO2b"/>
          </xsl:attribute>
          <!-- CONCATENAR TODOS LOS PÁRRAFOS DEL ABSTRACT -->
          <xsl:for-each select="$mainAbstract/p">
            <xsl:if test="position() > 1">
              <xsl:text> </xsl:text>
            </xsl:if>
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:for-each>
        </abstract>
      </xsl:if>

      <!-- URL DEL TEXTO COMPLETO -->
      <xsl:choose>
        <xsl:when test="$resolvedUrl != ''">
          <fullTextUrl>
            <xsl:attribute name="format">
              <xsl:value-of select="$fullTextFormat"/>
            </xsl:attribute>
            <xsl:value-of select="$resolvedUrl"/>
          </fullTextUrl>
        </xsl:when>
        <xsl:otherwise>
          <xsl:comment> ADVERTENCIA: fullTextUrl ausente. Pasar como parámetro Saxon
            -param:fullTextUrl https://url-del-articulo
            o agregar custom-meta 'fullTextUrl' en el canónico. </xsl:comment>
        </xsl:otherwise>
      </xsl:choose>

      <!-- PALABRAS CLAVE EN EL IDIOMA PRINCIPAL -->
      <xsl:variable name="mainKwdGroup"
        select="front/article-meta/kwd-group[@xml:lang = $langISO1]"/>
      <xsl:if test="$mainKwdGroup/kwd">
        <keywords>
          <xsl:attribute name="language">
            <xsl:value-of select="$langISO2b"/>
          </xsl:attribute>
          <xsl:for-each select="$mainKwdGroup/kwd">
            <keyword>
              <xsl:value-of select="normalize-space(.)"/>
            </keyword>
          </xsl:for-each>
        </keywords>
      </xsl:if>

    </record>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA NOMBRADA: build-date
       Construye fecha en formato DOAJ (YYYY | YYYY-MM | YYYY-MM-DD)
       desde un nodo JATS <pub-date> o <date>.
       normalize-space() elimina whitespace de indentación del canónico.
       ============================================================ -->
  <xsl:template name="build-date">
    <xsl:param name="dateNode"/>
    <xsl:param name="fallbackNode"/>

    <xsl:variable name="year"  select="normalize-space(($dateNode | $fallbackNode)[1]/year)"/>
    <xsl:variable name="month" select="normalize-space(($dateNode | $fallbackNode)[1]/month)"/>
    <xsl:variable name="day"   select="normalize-space(($dateNode | $fallbackNode)[1]/day)"/>

    <xsl:choose>
      <xsl:when test="$year and $month and $day">
        <xsl:value-of select="$year"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="format-number(number($month), '00')"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="format-number(number($day), '00')"/>
      </xsl:when>
      <xsl:when test="$year and $month">
        <xsl:value-of select="$year"/>
        <xsl:text>-</xsl:text>
        <xsl:value-of select="format-number(number($month), '00')"/>
      </xsl:when>
      <xsl:when test="$year">
        <xsl:value-of select="$year"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:comment> ADVERTENCIA: publicationDate no pudo resolverse </xsl:comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA NOMBRADA: iso1-to-iso2b
       Convierte código ISO 639-1 (2 letras) a ISO 639-2b (3 letras)
       para los idiomas más frecuentes en publicaciones académicas
       latinoamericanas. Extender según necesidad.
       ============================================================ -->
  <xsl:template name="iso1-to-iso2b">
    <xsl:param name="lang"/>
    <xsl:choose>
      <xsl:when test="$lang = 'es'">spa</xsl:when>
      <xsl:when test="$lang = 'en'">eng</xsl:when>
      <xsl:when test="$lang = 'pt'">por</xsl:when>
      <xsl:when test="$lang = 'fr'">fre</xsl:when>
      <xsl:when test="$lang = 'de'">ger</xsl:when>
      <xsl:when test="$lang = 'it'">ita</xsl:when>
      <xsl:when test="$lang = 'ca'">cat</xsl:when>
      <xsl:when test="$lang = 'gl'">glg</xsl:when>
      <!-- SI YA LLEGA EN ISO 639-2b SE DEVUELVE SIN CAMBIOS -->
      <xsl:when test="string-length($lang) = 3">
        <xsl:value-of select="$lang"/>
      </xsl:when>
      <!-- FALLBACK: idioma desconocido, se registra tal cual -->
      <xsl:otherwise>
        <xsl:value-of select="$lang"/>
        <xsl:comment> ADVERTENCIA: código de idioma '<xsl:value-of select="$lang"/>' no reconocido. Verificar contra iso_639-2b.xsd </xsl:comment>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- ============================================================
       PLANTILLA NOMBRADA: map-article-type
       Mapea article-type JATS a documentType DOAJ
       ============================================================ -->
  <xsl:template name="map-article-type">
    <xsl:param name="type"/>
    <xsl:choose>
      <xsl:when test="$type = 'research-article'">article</xsl:when>
      <xsl:when test="$type = 'review-article'">review</xsl:when>
      <xsl:when test="$type = 'editorial'">editorial</xsl:when>
      <xsl:when test="$type = 'letter'">letter</xsl:when>
      <xsl:when test="$type = 'book-review'">book review</xsl:when>
      <xsl:when test="$type = 'case-report'">case report</xsl:when>
      <xsl:when test="$type = 'correction'">correction</xsl:when>
      <xsl:when test="$type = 'retraction'">retraction</xsl:when>
      <!-- TIPOS SIN EQUIVALENTE DIRECTO EN DOAJ -->
      <xsl:otherwise>article</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
