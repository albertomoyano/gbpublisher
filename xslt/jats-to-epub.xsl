<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  jats-to-epub.xsl
  =====================================================
  DESCRIPCIÓN:
    TRANSFORMA UN ARTÍCULO JATS 1.4 CANÓNICO A XHTML
    VÁLIDO PARA EPUB 3. GENERA UN CAPÍTULO POR ARTÍCULO.

  DIFERENCIAS CON jats-to-html.xsl:
    — Sin layout de columnas (flujo lineal)
    — Sin JavaScript
    — Sin Google Fonts (tipografía via epub.css embebida)
    — Metadatos solo Dublin Core en <head>
    — Referencias al final como sección <section>
    — Imágenes referenciadas como ../images/nombre
    — Salida XHTML con namespace y DOCTYPE HTML5

  PARÁMETROS:
    ruta_meta  - RUTA AL XML AUXILIAR m-*.xml GENERADO POR
                 GenerarMetaArticuloXML() EN m_XML.gambas
                 CONTIENE: CRediT POR AUTOR, ROR DE AFILIACIÓN,
                 URL TEXTO COMPLETO, ROR DEL EDITOR
                 VACÍO = HTML SE GENERA SIN METADATOS DC ENRIQUECIDOS
    estilo_cita - 'autor-anio' | 'vancouver' | 'apa' | 'iso690'
                  DETERMINADO AUTOMÁTICAMENTE POR LeerTipoCSL()

  VERSIÓN XSLT: 2.0 (REQUIERE SAXON-HE)
  =====================================================
-->
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns="http://www.w3.org/1999/xhtml"
  version="2.0">

  <!-- ================================================
       PARÁMETROS EXTERNOS
       ================================================ -->
  <xsl:param name="ruta_meta" as="xs:string" select="''"
             xmlns:xs="http://www.w3.org/2001/XMLSchema"/>

  <xsl:param name="estilo_cita" as="xs:string" select="'autor-anio'"
             xmlns:xs="http://www.w3.org/2001/XMLSchema"/>

  <!-- ================================================
       SALIDA: XHTML5
       ================================================ -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    indent="yes"
    omit-xml-declaration="no"/>

  <!-- ================================================
       VARIABLES GLOBALES
       ================================================ -->
  <xsl:variable name="doi"
    select="normalize-space(//article-meta/article-id[@pub-id-type='doi'])"/>

  <xsl:variable name="lang">
    <xsl:choose>
      <xsl:when test="normalize-space(//article-meta/custom-meta-group/custom-meta[meta-name='xml-lang']/meta-value) != ''">
        <xsl:value-of select="normalize-space(//article-meta/custom-meta-group/custom-meta[meta-name='xml-lang']/meta-value)"/>
      </xsl:when>
      <xsl:when test="normalize-space(/article/@xml:lang) != ''">
        <xsl:value-of select="normalize-space(/article/@xml:lang)"/>
      </xsl:when>
      <xsl:when test="//article-meta/abstract/@xml:lang">
        <xsl:value-of select="//article-meta/abstract/@xml:lang"/>
      </xsl:when>
      <xsl:otherwise>es</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="titulo"
    select="normalize-space(//article-meta/title-group/article-title)"/>

  <xsl:variable name="revista"
    select="normalize-space(//journal-meta/journal-title-group/journal-title)"/>

  <!-- DOCUMENTO XML AUXILIAR DE METADATOS -->
  <xsl:variable name="meta"
    select="if ($ruta_meta != '') then doc($ruta_meta) else ()"/>

  <xsl:variable name="url-texto-completo"
    select="if ($meta) then
      normalize-space($meta/meta-articulo/identidad/url-texto-completo)
    else ''"/>

  <!-- ================================================
       TEMPLATE RAÍZ
       ================================================ -->
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml"
          xmlns:epub="http://www.idpf.org/2007/ops"
          lang="{$lang}" xml:lang="{$lang}">
      <head>
        <meta charset="UTF-8"/>
        <title>
          <xsl:value-of select="$titulo"/>
          <xsl:text> — </xsl:text>
          <xsl:value-of select="$revista"/>
        </title>

        <!-- ================================================
             DUBLIN CORE — METADATOS DE INDEXACIÓN
             ================================================ -->
        <meta name="DC.title"    content="{$titulo}"/>
        <meta name="DC.language" content="{$lang}"/>
        <meta name="DC.type"     content="Text"/>
        <xsl:if test="$doi != ''">
          <meta name="DC.identifier"
            content="https://doi.org/{$doi}"/>
        </xsl:if>
        <xsl:if test="//article-meta/pub-date/year">
          <meta name="DC.date"
            content="{//article-meta/pub-date/year}"/>
        </xsl:if>
        <xsl:if test="//journal-meta/publisher/publisher-name">
          <meta name="DC.publisher"
            content="{normalize-space(//journal-meta/publisher/publisher-name)}"/>
        </xsl:if>
        <xsl:if test="//permissions/license/@xlink:href">
          <meta name="DC.rights"
            content="{//permissions/license/@xlink:href}"/>
        </xsl:if>
        <xsl:for-each select="//contrib[@contrib-type='author']/name">
          <meta name="DC.creator"
            content="{normalize-space(surname)}, {normalize-space(given-names)}"/>
        </xsl:for-each>
        <xsl:if test="//abstract">
          <meta name="DC.description"
            content="{normalize-space(//abstract/p[1])}"/>
        </xsl:if>
        <xsl:for-each select="//kwd-group[@xml:lang=$lang]/kwd">
          <meta name="DC.subject" content="{normalize-space(.)}"/>
        </xsl:for-each>

        <!-- HOJA DE ESTILOS EMBEBIDA EN EL EPUB -->
        <link rel="stylesheet" type="text/css" href="../css/epub.css"/>

      </head>

      <body>

        <!-- ================================================
             PREAMBLE — INFORMACIÓN DEL ARTÍCULO
             SECCIÓN NO NARRATIVA AL INICIO DE CADA CAPÍTULO.
             CONTIENE: DATOS DE PUBLICACIÓN + CÓMO CITAR
             epub:type="preamble" INDICA A LOS LECTORES QUE
             ESTA SECCIÓN ES INTRODUCTORIA, NO NARRATIVA.
             ================================================ -->
        <section epub:type="preamble" class="article-preamble">

          <!-- TIPO DE ARTÍCULO -->
          <xsl:if test="//article-categories/subj-group[@subj-group-type='heading']/subject">
            <xsl:variable name="tipoJATS"
              select="normalize-space(
                //article-categories/subj-group[@subj-group-type='heading']/subject
              )"/>
            <p class="article-type">
              <xsl:choose>
                <xsl:when test="$lang = 'es'">
                  <xsl:choose>
                    <xsl:when test="$tipoJATS = 'research-article'">Artículo de investigación</xsl:when>
                    <xsl:when test="$tipoJATS = 'review-article'">Artículo de revisión</xsl:when>
                    <xsl:when test="$tipoJATS = 'systematic-review'">Revisión sistemática</xsl:when>
                    <xsl:when test="$tipoJATS = 'meta-analysis'">Metaanálisis</xsl:when>
                    <xsl:when test="$tipoJATS = 'case-report'">Caso clínico</xsl:when>
                    <xsl:when test="$tipoJATS = 'brief-report'">Comunicación breve</xsl:when>
                    <xsl:when test="$tipoJATS = 'letter'">Carta al editor</xsl:when>
                    <xsl:when test="$tipoJATS = 'editorial'">Editorial</xsl:when>
                    <xsl:when test="$tipoJATS = 'commentary'">Comentario</xsl:when>
                    <xsl:when test="$tipoJATS = 'book-review'">Reseña bibliográfica</xsl:when>
                    <xsl:when test="$tipoJATS = 'obituary'">Obituario</xsl:when>
                    <xsl:when test="$tipoJATS = 'correction'">Corrección</xsl:when>
                    <xsl:when test="$tipoJATS = 'retraction'">Retractación</xsl:when>
                    <xsl:when test="$tipoJATS = 'conference-paper'">Ponencia</xsl:when>
                    <xsl:otherwise><xsl:value-of select="$tipoJATS"/></xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:when test="$lang = 'en'">
                  <xsl:choose>
                    <xsl:when test="$tipoJATS = 'research-article'">Research Article</xsl:when>
                    <xsl:when test="$tipoJATS = 'review-article'">Review Article</xsl:when>
                    <xsl:when test="$tipoJATS = 'editorial'">Editorial</xsl:when>
                    <xsl:when test="$tipoJATS = 'letter'">Letter to the Editor</xsl:when>
                    <xsl:otherwise><xsl:value-of select="$tipoJATS"/></xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:when test="$lang = 'pt'">
                  <xsl:choose>
                    <xsl:when test="$tipoJATS = 'research-article'">Artigo de pesquisa</xsl:when>
                    <xsl:when test="$tipoJATS = 'editorial'">Editorial</xsl:when>
                    <xsl:otherwise><xsl:value-of select="$tipoJATS"/></xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$tipoJATS"/>
                </xsl:otherwise>
              </xsl:choose>
            </p>
          </xsl:if>

          <!-- TÍTULO -->
          <h1 class="article-title" id="titulo-articulo">
            <xsl:value-of select="//article-meta/title-group/article-title"/>
          </h1>

          <xsl:if test="//article-meta/title-group/trans-title-group/trans-title">
            <p class="article-trans-title">
              <xsl:value-of
                select="//article-meta/title-group/trans-title-group/trans-title"/>
            </p>
          </xsl:if>

          <!-- AUTORÍA -->
          <xsl:if test="//contrib[@contrib-type='author']">
            <div class="autoria">
              <xsl:for-each select="//contrib[@contrib-type='author']">
                <div class="autor-item">
                  <p class="autor-nombre">
                    <xsl:value-of select="name/given-names"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="name/surname"/>
                    <xsl:if test="contrib-id[@contrib-id-type='orcid']">
                      <xsl:text> </xsl:text>
                      <span class="orcid">
                        <xsl:value-of select="contrib-id[@contrib-id-type='orcid']"/>
                      </span>
                    </xsl:if>
                  </p>
                  <xsl:if test="aff">
                    <p class="autor-afil">
                      <xsl:for-each select="aff/institution">
                        <xsl:value-of select="."/>
                        <xsl:if test="position() != last()">, </xsl:if>
                      </xsl:for-each>
                      <xsl:if test="aff/city">, <xsl:value-of select="aff/city"/></xsl:if>
                      <xsl:if test="aff/country">, <xsl:value-of select="aff/country"/></xsl:if>
                    </p>
                  </xsl:if>
                  <xsl:if test="@corresp='yes' and email">
                    <p class="autor-email">
                      <xsl:value-of select="email"/>
                    </p>
                  </xsl:if>
                </div>
              </xsl:for-each>
            </div>
          </xsl:if>

          <!-- DATOS DE PUBLICACIÓN -->
          <div class="pub-data">
            <xsl:if test="//article-meta/pub-date/year">
              <p class="pub-fecha">
                <xsl:value-of select="//article-meta/pub-date/year"/>
                <xsl:if test="//article-meta/volume">
                  <xsl:text>, vol. </xsl:text>
                  <xsl:value-of select="//article-meta/volume"/>
                </xsl:if>
                <xsl:if test="//article-meta/issue">
                  <xsl:text>, n&#xFA;m. </xsl:text>
                  <xsl:value-of select="//article-meta/issue"/>
                </xsl:if>
                <xsl:if test="//article-meta/fpage">
                  <xsl:text>, pp. </xsl:text>
                  <xsl:value-of select="//article-meta/fpage"/>
                  <xsl:if test="//article-meta/lpage">
                    <xsl:text>&#x2013;</xsl:text>
                    <xsl:value-of select="//article-meta/lpage"/>
                  </xsl:if>
                </xsl:if>
              </p>
            </xsl:if>
            <xsl:if test="$doi != ''">
              <p class="pub-doi">
                <xsl:text>DOI: https://doi.org/</xsl:text>
                <xsl:value-of select="$doi"/>
              </p>
            </xsl:if>
            <xsl:if test="//permissions/license/license-p">
              <p class="pub-licencia">
                <xsl:value-of select="//permissions/license/license-p"/>
              </p>
            </xsl:if>
          </div>

          <!-- CÓMO CITAR — GENERADO SEGÚN ESTILO ACTIVO
               TEXTO PLANO, PREDECIBLE, SIN JS
               ================================================ -->
          <div class="como-citar">
            <p class="como-citar-label">
              <xsl:choose>
                <xsl:when test="$lang = 'es'">Cómo citar</xsl:when>
                <xsl:when test="$lang = 'en'">How to cite</xsl:when>
                <xsl:when test="$lang = 'pt'">Como citar</xsl:when>
                <xsl:otherwise>Cómo citar</xsl:otherwise>
              </xsl:choose>
            </p>
            <p class="como-citar-texto">
              <xsl:call-template name="generarCitaPreamble"/>
            </p>
          </div>

        </section>

        <!-- RESÚMENES -->
        <xsl:if test="//abstract or //trans-abstract">
          <section class="abstracts" id="abstracts">
            <xsl:apply-templates select="//abstract"/>
            <xsl:apply-templates select="//trans-abstract"/>
          </section>
        </xsl:if>


        <!-- ================================================
             CUERPO DEL ARTÍCULO
             ================================================ -->
        <xsl:apply-templates select="//body"/>

        <!-- ================================================
             NOTAS AL FINAL DEL CAPÍTULO
             PATRÓN ENDNOTES: EL ANCLA VA INLINE EN EL TEXTO
             (template fn), EL TEXTO DE LA NOTA VA AQUÍ.
             <aside> DENTRO DE <p> ES INVÁLIDO EN XHTML —
             POR ESO SE SEPARAN EN DOS LUGARES.
             ================================================ -->
        <xsl:if test="//fn">
          <section epub:type="endnotes" role="doc-endnotes" id="notas">
            <h2>
              <xsl:choose>
                <xsl:when test="$lang = 'es'">Notas</xsl:when>
                <xsl:when test="$lang = 'en'">Notes</xsl:when>
                <xsl:when test="$lang = 'pt'">Notas</xsl:when>
                <xsl:otherwise>Notas</xsl:otherwise>
              </xsl:choose>
            </h2>
            <xsl:for-each select="//fn">
              <xsl:variable name="fn-num">
                <xsl:number count="fn" level="any"/>
              </xsl:variable>
              <div role="doc-endnote" id="fn-{$fn-num}" class="fn-item">
                <p>
                  <sup><xsl:value-of select="$fn-num"/></sup>
                  <xsl:text> </xsl:text>
                  <xsl:apply-templates mode="text-only"/>
                  <xsl:text> </xsl:text>
                  <a href="#fnref-{$fn-num}"
                     role="doc-backlink"
                     class="fn-backlink">&#x21A9;</a>
                </p>
              </div>
            </xsl:for-each>
          </section>
        </xsl:if>

        <!-- ================================================
             REFERENCIAS AL FINAL DEL CAPÍTULO
             EN EPUB NO HAY PANEL LATERAL — VAN INLINE
             ================================================ -->
        <xsl:if test="//ref-list/ref">
          <section class="ref-list">
            <h2>Referencias</h2>
            <xsl:apply-templates select="//ref-list/ref"/>
          </section>
        </xsl:if>

      </body>
    </html>
  </xsl:template>

  <!-- ================================================
       RESÚMENES
       ================================================ -->
  <xsl:template match="abstract | trans-abstract">
    <xsl:variable name="lang-abs" select="@xml:lang"/>
    <div class="abstract">
      <p class="abstract-label">
        <xsl:choose>
          <xsl:when test="@xml:lang = 'es'">Resumen</xsl:when>
          <xsl:when test="@xml:lang = 'en'">Abstract</xsl:when>
          <xsl:when test="@xml:lang = 'pt'">Resumo</xsl:when>
          <xsl:when test="@xml:lang = 'fr'">Résumé</xsl:when>
          <xsl:otherwise><xsl:value-of select="@xml:lang"/></xsl:otherwise>
        </xsl:choose>
      </p>
      <xsl:apply-templates/>
      <!-- PALABRAS CLAVE DEL MISMO IDIOMA QUE EL RESUMEN -->
      <xsl:if test="//kwd-group[@xml:lang=$lang-abs]/kwd">
        <p class="abstract-keywords">
          <strong>
            <xsl:choose>
              <xsl:when test="$lang-abs = 'es'">Palabras clave: </xsl:when>
              <xsl:when test="$lang-abs = 'en'">Keywords: </xsl:when>
              <xsl:when test="$lang-abs = 'pt'">Palavras-chave: </xsl:when>
              <xsl:when test="$lang-abs = 'fr'">Mots-cl&#xE9;s: </xsl:when>
              <xsl:otherwise>Palabras clave: </xsl:otherwise>
            </xsl:choose>
          </strong>
          <xsl:for-each select="//kwd-group[@xml:lang=$lang-abs]/kwd">
            <xsl:if test="position() > 1"><xsl:text>, </xsl:text></xsl:if>
            <xsl:value-of select="."/>
          </xsl:for-each>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- ================================================
       BODY
       ================================================ -->
  <xsl:template match="body">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ================================================
       SECCIÓN
       ID PREDECIBLE BASADO EN POSICIÓN — NUNCA
       generate-id() QUE PUEDE CAMBIAR EN CONVERSIÓN
       ================================================ -->
  <xsl:template match="sec">
    <xsl:variable name="sec-num">
      <xsl:number count="sec" level="any"/>
    </xsl:variable>
    <xsl:variable name="sec-id">
      <xsl:choose>
        <xsl:when test="@id != ''"><xsl:value-of select="@id"/></xsl:when>
        <xsl:otherwise>sec-<xsl:value-of select="$sec-num"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <section id="{$sec-id}">
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <xsl:template match="sec/title">
    <h2><xsl:apply-templates/></h2>
  </xsl:template>

  <!-- ================================================
       PÁRRAFO
       ================================================ -->
  <xsl:template match="p">
    <p><xsl:apply-templates/></p>
  </xsl:template>

  <!-- ================================================
       EPÍGRAFE
       ================================================ -->
  <xsl:template match="disp-quote[@specific-use='epigraph']">
    <blockquote class="epigraph">
      <xsl:apply-templates select="p"/>
      <xsl:if test="attrib">
        <cite class="attrib">
          <xsl:value-of select="attrib"/>
        </cite>
      </xsl:if>
    </blockquote>
  </xsl:template>

  <!-- ================================================
       CITA EN BLOQUE
       ================================================ -->
  <xsl:template match="disp-quote[not(@specific-use='epigraph')]">
    <blockquote class="disp-quote">
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <!-- ================================================
       FIGURA
       EPUB: <figure> Y <figcaption> SON INESTABLES EN
       LECTORES VIEJOS — SE USA <div> Y <p> EN SU LUGAR.
       RUTAS RELATIVAS A ../images/
       ID PREDECIBLE BASADO EN POSICIÓN NUMÉRICA.
       ================================================ -->
  <xsl:template match="fig">
    <xsl:variable name="href"   select="graphic/@xlink:href"/>
    <xsl:variable name="nombre" select="tokenize($href, '/')[last()]"/>
    <xsl:variable name="fignum">
      <xsl:number count="fig" level="any"/>
    </xsl:variable>
    <div class="fig-wrapper" id="fig-{$fignum}">
      <img src="../images/{$nombre}"
           alt="{normalize-space(caption/p)}"
           class="fig-img"/>
      <p class="fig-caption">
        <xsl:text>Figura </xsl:text>
        <xsl:value-of select="$fignum"/>
        <xsl:if test="caption/p">
          <xsl:text>. </xsl:text>
          <xsl:value-of select="caption/p"/>
        </xsl:if>
      </p>
    </div>
  </xsl:template>

  <!-- ================================================
       VERSOS
       ================================================ -->
<xsl:template match="verse-group">
    <div class="verse-group">
      <xsl:for-each select="verse-line">
        <span class="verse-line"><xsl:value-of select="."/></span>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- ================================================
       LISTAS ORDENADAS Y NO ORDENADAS
       ================================================ -->
  <xsl:template match="list[@list-type='order']">
    <ol class="list-order"><xsl:apply-templates select="list-item"/></ol>
  </xsl:template>

  <xsl:template match="list[@list-type='bullet']">
    <ul class="list-bullet"><xsl:apply-templates select="list-item"/></ul>
  </xsl:template>

  <xsl:template match="list[@list-type='simple' or not(@list-type)]">
    <ul class="list-simple"><xsl:apply-templates select="list-item"/></ul>
  </xsl:template>

  <xsl:template match="list-item">
    <li><xsl:apply-templates/></li>
  </xsl:template>

  <!-- P DENTRO DE LIST-ITEM: SIN WRAPPER <p> PARA EVITAR MARGEN EXTRA -->
  <xsl:template match="list-item/p" priority="5">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ================================================
       CÓDIGO FUENTE
       ================================================ -->
  <xsl:template match="code">
    <div class="code-block">
      <xsl:if test="@language">
        <span class="code-lang"><xsl:value-of select="@language"/></span>
      </xsl:if>
      <pre><code>
        <xsl:if test="@language">
          <xsl:attribute name="class">language-<xsl:value-of select="@language"/></xsl:attribute>
        </xsl:if>
        <xsl:value-of select="."/>
      </code></pre>
    </div>
  </xsl:template>

  <!-- ================================================
       RECUADRO
       <aside> ES INESTABLE EN LECTORES VIEJOS — SE USA
       <div> CON CLASE SEMÁNTICA EN SU LUGAR
       ================================================ -->
  <xsl:template match="boxed-text">
    <xsl:variable name="clase">
      <xsl:choose>
        <xsl:when test="@content-type">
          <xsl:text>boxed-text boxed-text-</xsl:text>
          <xsl:value-of select="@content-type"/>
        </xsl:when>
        <xsl:otherwise>boxed-text</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <div class="{$clase}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- ================================================
       NOTA AL PIE — fn
       PATRÓN EPUB 3 + ARIA ROLES (DAISY KNOWLEDGE BASE)
       IDS PREDECIBLES BASADOS EN POSICIÓN NUMÉRICA.
       EL LECTOR EPUB 3 MUESTRA EL <aside> COMO POPUP.
       EN LECTORES QUE NO SOPORTAN POPUP FUNCIONA
       COMO ENLACE BIDIRECCIONAL (DEGRADACIÓN ELEGANTE).
       KINDLE PAPERWHITE SOPORTA POPUP EN MISMO XHTML.
       ================================================ -->
  <!-- ================================================
       NOTA AL PIE — fn
       SOLO EMITE EL ANCLA INLINE (SUPERÍNDICE).
       EL TEXTO DE LA NOTA VA EN LA SECCIÓN endnotes
       AL FINAL DEL ARTÍCULO, GENERADA DESDE EL TEMPLATE
       RAÍZ. ESTO EVITA QUE <aside> QUEDE DENTRO DE <p>,
       LO QUE ES INVÁLIDO EN XHTML Y RECHAZADO POR
       EPUBCHECK.
       ================================================ -->
  <xsl:template match="fn">
    <xsl:variable name="fn-num">
      <xsl:number count="fn" level="any"/>
    </xsl:variable>
    <sup><a
      id="fnref-{$fn-num}"
      href="#fn-{$fn-num}"
      epub:type="noteref"
      role="doc-noteref"><xsl:value-of select="$fn-num"/></a></sup>
  </xsl:template>

  <!-- MODO TEXT-ONLY -->
  <xsl:template match="*" mode="text-only">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- ================================================
       FÓRMULA MATEMÁTICA
       ================================================ -->
<xsl:template match="disp-formula">
  <div class="disp-formula" id="{@id}">
    <code class="tex-math">
      <xsl:value-of select="tex-math"/>
    </code>
  </div>
</xsl:template>

  <!-- ================================================
       SPEECH / DIÁLOGO — INLINE
       speaker EN BOLD + — + TEXTO EN MISMA LÍNEA
       ================================================ -->
  <xsl:template match="speech">
    <p class="speech-item">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <xsl:template match="speech/speaker">
    <span class="speech-speaker"><xsl:apply-templates/></span>
    <xsl:text> — </xsl:text>
  </xsl:template>

  <!-- P DENTRO DE SPEECH: SIN WRAPPER PARA QUEDAR INLINE -->
  <xsl:template match="speech/p" priority="5">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ================================================
       TABLA
       ================================================ -->
  <xsl:template match="table-wrap">
    <div class="table-wrap" id="{@id}">
      <xsl:apply-templates select="table"/>
      <xsl:if test="caption/p">
        <p class="table-caption">
          <xsl:value-of select="caption/p"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <xsl:template match="table">
    <table><xsl:apply-templates/></table>
  </xsl:template>

  <xsl:template match="thead | tbody | tfoot | tr">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="th | td">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- ================================================
       XREF — CITA EN TEXTO
       DESPACHA SEGÚN ESTILO (SIN INTERACTIVIDAD JS)
       ================================================ -->
  <xsl:template match="xref[@ref-type='bibr']">
    <xsl:choose>
      <xsl:when test="$estilo_cita = 'vancouver' or $estilo_cita = 'ieee'">
        <xsl:call-template name="xref-vancouver-epub"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="xref-autor-anio-epub"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       XREF AUTOR-AÑO PARA EPUB
       LEE @specific-use PARA MODO, PREFIJO Y SUFIJO
       SOPORTE DE MÚLTIPLES AUTORES (&, et al.)
       ================================================ -->
  <xsl:template name="xref-autor-anio-epub">
    <xsl:variable name="rid" select="@rid"/>
    <xsl:variable name="cit" select="//ref[@id=$rid]/element-citation"/>
    <xsl:variable name="autor">
      <xsl:choose>
        <xsl:when test="$cit/person-group[@person-group-type='author']/name">
          <xsl:choose>
            <xsl:when test="count($cit/person-group[@person-group-type='author']/name) = 1">
              <xsl:value-of select="$cit/person-group[@person-group-type='author']/name[1]/surname"/>
            </xsl:when>
            <xsl:when test="count($cit/person-group[@person-group-type='author']/name) = 2">
              <xsl:value-of select="$cit/person-group[@person-group-type='author']/name[1]/surname"/>
              <xsl:text> &amp; </xsl:text>
              <xsl:value-of select="$cit/person-group[@person-group-type='author']/name[2]/surname"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$cit/person-group[@person-group-type='author']/name[1]/surname"/>
              <xsl:text> et al.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$cit/person-group[@person-group-type='editor']/name">
          <xsl:choose>
            <xsl:when test="count($cit/person-group[@person-group-type='editor']/name) = 1">
              <xsl:value-of select="$cit/person-group[@person-group-type='editor']/name[1]/surname"/>
            </xsl:when>
            <xsl:when test="count($cit/person-group[@person-group-type='editor']/name) = 2">
              <xsl:value-of select="$cit/person-group[@person-group-type='editor']/name[1]/surname"/>
              <xsl:text> &amp; </xsl:text>
              <xsl:value-of select="$cit/person-group[@person-group-type='editor']/name[2]/surname"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$cit/person-group[@person-group-type='editor']/name[1]/surname"/>
              <xsl:text> et al.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$cit/person-group[@person-group-type='compiler']/name">
          <xsl:choose>
            <xsl:when test="count($cit/person-group[@person-group-type='compiler']/name) = 1">
              <xsl:value-of select="$cit/person-group[@person-group-type='compiler']/name[1]/surname"/>
            </xsl:when>
            <xsl:when test="count($cit/person-group[@person-group-type='compiler']/name) = 2">
              <xsl:value-of select="$cit/person-group[@person-group-type='compiler']/name[1]/surname"/>
              <xsl:text> &amp; </xsl:text>
              <xsl:value-of select="$cit/person-group[@person-group-type='compiler']/name[2]/surname"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$cit/person-group[@person-group-type='compiler']/name[1]/surname"/>
              <xsl:text> et al.</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$cit/person-group/name[1]/surname">
          <xsl:value-of select="$cit/person-group/name[1]/surname"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$rid"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="anio" select="$cit/year"/>

    <!-- PARSEAR specific-use: modo|prefijo|sufijo -->
    <xsl:variable name="su" select="normalize-space(@specific-use)"/>
    <xsl:variable name="modo">
      <xsl:choose>
        <xsl:when test="$su != ''"><xsl:value-of select="tokenize($su, '\|')[1]"/></xsl:when>
        <xsl:otherwise>normal</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="prefijo">
      <xsl:if test="$su != ''"><xsl:value-of select="normalize-space(tokenize($su, '\|')[2])"/></xsl:if>
    </xsl:variable>
    <xsl:variable name="sufijo">
      <xsl:if test="$su != ''"><xsl:value-of select="normalize-space(tokenize($su, '\|')[3])"/></xsl:if>
    </xsl:variable>

    <xsl:variable name="esPrimera" select="not(
      preceding-sibling::node()[1][self::text() and matches(., '^\s*,\s*$')] and
      preceding-sibling::node()[2][self::xref[@ref-type='bibr']]
    )"/>
    <xsl:variable name="esUltima" select="not(
      following-sibling::node()[1][self::text() and matches(., '^\s*,\s*$')] and
      following-sibling::node()[2][self::xref[@ref-type='bibr']]
    )"/>

    <xsl:choose>
      <!-- AUTHOR-IN-TEXT: Autor (2025) -->
      <xsl:when test="$modo = 'author-in-text'">
        <a class="xref-bibr" href="#ref-epub-{$rid}"><xsl:value-of select="$autor"/></a>
        <xsl:text> (</xsl:text>
        <a class="xref-bibr" href="#ref-epub-{$rid}"><xsl:value-of select="$anio"/></a>
        <xsl:if test="$sufijo != ''">, <xsl:value-of select="$sufijo"/></xsl:if>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <!-- SUPPRESS: solo año -->
      <xsl:when test="$modo = 'suppress'">
        <xsl:if test="$esPrimera">
          <xsl:text>(</xsl:text>
          <xsl:if test="$prefijo != ''"><xsl:value-of select="$prefijo"/><xsl:text> </xsl:text></xsl:if>
        </xsl:if>
        <xsl:if test="not($esPrimera)"><xsl:text>; </xsl:text></xsl:if>
        <a class="xref-bibr" href="#ref-epub-{$rid}">
          <xsl:value-of select="$anio"/>
          <xsl:if test="$sufijo != ''">, <xsl:value-of select="$sufijo"/></xsl:if>
        </a>
        <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
      </xsl:when>
      <!-- NORMAL -->
      <xsl:otherwise>
        <xsl:if test="$esPrimera">
          <xsl:text>(</xsl:text>
          <xsl:if test="$prefijo != ''"><xsl:value-of select="$prefijo"/><xsl:text> </xsl:text></xsl:if>
        </xsl:if>
        <xsl:if test="not($esPrimera)"><xsl:text>; </xsl:text></xsl:if>
        <a class="xref-bibr" href="#ref-epub-{$rid}">
          <xsl:value-of select="$autor"/>
          <xsl:if test="$anio != ''">, <xsl:value-of select="$anio"/></xsl:if>
          <xsl:if test="$sufijo != ''">, <xsl:value-of select="$sufijo"/></xsl:if>
        </a>
        <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       XREF VANCOUVER/IEEE PARA EPUB — [1] [2,3]
       SOPORTA PREFIJO ANTES DEL CORCHETE Y SUFIJO DENTRO
       ================================================ -->
  <xsl:template name="xref-vancouver-epub">
    <xsl:variable name="esPrimera" select="not(
      preceding-sibling::node()[1][self::text() and matches(., '^\s*[,;]\s*$')] and
      preceding-sibling::node()[2][self::xref[@ref-type='bibr']]
    )"/>
    <xsl:variable name="su" select="normalize-space(@specific-use)"/>
    <xsl:variable name="prefijo">
      <xsl:if test="$su != ''"><xsl:value-of select="normalize-space(tokenize($su, '\|')[2])"/></xsl:if>
    </xsl:variable>
    <xsl:variable name="sufijo">
      <xsl:if test="$su != ''"><xsl:value-of select="normalize-space(tokenize($su, '\|')[3])"/></xsl:if>
    </xsl:variable>

    <xsl:if test="$esPrimera">
      <xsl:if test="$prefijo != ''"><xsl:value-of select="$prefijo"/><xsl:text> </xsl:text></xsl:if>
      <xsl:variable name="rids" as="xs:string*"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xsl:call-template name="recolectarRidsGrupo">
          <xsl:with-param name="xrefActual" select="."/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="docRoot" select="/"/>
      <xsl:variable name="pares">
        <xsl:for-each select="$rids">
          <xsl:variable name="r" select="."/>
          <par rid="{$r}"
               num="{count($docRoot//ref-list/ref[@id=$r]/preceding-sibling::ref) + 1}"/>
        </xsl:for-each>
      </xsl:variable>
      <xsl:variable name="paresOrdenados" as="element()*">
        <xsl:perform-sort select="$pares/par">
          <xsl:sort select="xs:integer(@num)" order="ascending"
                    xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
        </xsl:perform-sort>
      </xsl:variable>
      <xsl:text>[</xsl:text>
      <xsl:for-each select="$paresOrdenados">
        <xsl:if test="position() > 1"><xsl:text>,</xsl:text></xsl:if>
        <a class="xref-vancouver" href="#ref-epub-{@rid}">
          <xsl:value-of select="@num"/>
        </a>
      </xsl:for-each>
      <xsl:if test="$sufijo != ''">, <xsl:value-of select="$sufijo"/></xsl:if>
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- SUPRIMIR NODOS SEPARADORES ENTRE XREFS CONSECUTIVOS -->
  <xsl:template match="text()[matches(., '^\s*[,;]\s*$')]
    [preceding-sibling::node()[1][self::xref[@ref-type='bibr']]]
    [following-sibling::node()[1][self::xref[@ref-type='bibr']]]"/>

  <!-- ================================================
       REFERENCIAS EN SECCIÓN FINAL
       ================================================ -->
  <xsl:template match="ref">
    <div class="ref-item" id="ref-epub-{@id}">
      <xsl:if test="$estilo_cita = 'vancouver' or $estilo_cita = 'ieee'">
        <span class="ref-numero">
          <xsl:text>[</xsl:text>
          <xsl:number count="ref" level="any"/>
          <xsl:text>] </xsl:text>
        </span>
      </xsl:if>
      <xsl:apply-templates select="element-citation"/>
    </div>
  </xsl:template>

  <!-- ================================================
       ELEMENT-CITATION — 4 FORMATOS
       MISMA LÓGICA QUE jats-to-html.xsl PERO SIN
       CLASES DE PANEL NI ONCLICK
       ================================================ -->
  <xsl:template match="element-citation">
    <xsl:choose>

      <!-- VANCOUVER -->
      <xsl:when test="$estilo_cita = 'vancouver'">
        <span class="ref-authors">
          <xsl:choose>
            <xsl:when test="person-group[@person-group-type='author']/name">
              <xsl:for-each select="person-group[@person-group-type='author']/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="translate(given-names, '. ', '')"/>
                </xsl:if>
                <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:if test="person-group[@person-group-type='author']/etal">
                <xsl:text>, et al</xsl:text>
              </xsl:if>
            </xsl:when>
            <xsl:when test="person-group[@person-group-type='editor']/name">
              <xsl:for-each select="person-group[@person-group-type='editor']/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="translate(given-names, '. ', '')"/>
                </xsl:if>
                <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="abrev-tipo-persona">
                <xsl:with-param name="tipo" select="'editor'"/>
                <xsl:with-param name="cantidad" select="count(person-group[@person-group-type='editor']/name)"/>
                <xsl:with-param name="minuscula" select="true()"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
            </xsl:when>
            <!-- FALLBACK: compiler y otros tipos -->
            <xsl:when test="person-group[not(@person-group-type='author')]/name">
              <xsl:for-each select="person-group[not(@person-group-type='author')][1]/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="translate(given-names, '. ', '')"/>
                </xsl:if>
                <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="abrev-tipo-persona">
                <xsl:with-param name="tipo" select="string(person-group[not(@person-group-type='author')][1]/@person-group-type)"/>
                <xsl:with-param name="cantidad" select="count(person-group[not(@person-group-type='author')][1]/name)"/>
                <xsl:with-param name="minuscula" select="true()"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
            </xsl:when>
          </xsl:choose>
          <xsl:text>. </xsl:text>
        </span>
        <xsl:if test="article-title">
          <span class="ref-title"><xsl:value-of select="article-title"/>. </span>
        </xsl:if>
        <xsl:if test="chapter-title">
          <span class="ref-title"><xsl:value-of select="chapter-title"/>. </span>
        </xsl:if>
        <xsl:if test="source">
          <em class="ref-source"><xsl:value-of select="source"/></em>
        </xsl:if>
        <xsl:if test="year">. <xsl:value-of select="year"/></xsl:if>
        <xsl:if test="volume">;<xsl:value-of select="volume"/></xsl:if>
        <xsl:if test="issue">(<xsl:value-of select="issue"/>)</xsl:if>
        <xsl:if test="fpage">:<xsl:value-of select="fpage"/>
          <xsl:if test="lpage">-<xsl:value-of select="lpage"/></xsl:if>
        </xsl:if>
        <xsl:if test="publisher-loc or publisher-name">
          <xsl:text>. </xsl:text>
          <xsl:if test="publisher-loc"><xsl:value-of select="publisher-loc"/>: </xsl:if>
          <xsl:if test="publisher-name"><xsl:value-of select="replace(publisher-name, '(\s)and(\s)', '$1y$2')"/></xsl:if>
        </xsl:if>
        <xsl:text>.</xsl:text>
        <xsl:if test="pub-id[@pub-id-type='doi']">
          <span class="ref-doi">
            <xsl:text> DOI: https://doi.org/</xsl:text>
            <xsl:value-of select="pub-id[@pub-id-type='doi']"/>
          </span>
        </xsl:if>
      </xsl:when>

      <!-- APA 7 -->
      <xsl:when test="$estilo_cita = 'apa'">
        <span class="ref-authors">
          <xsl:choose>
            <xsl:when test="person-group[@person-group-type='author']/name">
              <xsl:for-each select="person-group[@person-group-type='author']/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">
                  <xsl:text>, </xsl:text>
                  <xsl:call-template name="iniciales-apa">
                    <xsl:with-param name="nombres" select="given-names"/>
                  </xsl:call-template>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test="position() = last() - 1"><xsl:text>, &amp; </xsl:text></xsl:when>
                  <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
                </xsl:choose>
              </xsl:for-each>
              <xsl:if test="person-group[@person-group-type='author']/etal">
                <xsl:text>, . . .</xsl:text>
              </xsl:if>
            </xsl:when>
            <xsl:when test="person-group[@person-group-type='editor']/name">
              <xsl:for-each select="person-group[@person-group-type='editor']/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">
                  <xsl:text>, </xsl:text>
                  <xsl:call-template name="iniciales-apa">
                    <xsl:with-param name="nombres" select="given-names"/>
                  </xsl:call-template>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test="position() = last() - 1"><xsl:text>, &amp; </xsl:text></xsl:when>
                  <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
                </xsl:choose>
              </xsl:for-each>
              <xsl:text> (Ed</xsl:text>
              <xsl:if test="count(person-group[@person-group-type='editor']/name) > 1">s</xsl:if>
              <xsl:text>.)</xsl:text>
            </xsl:when>
            <!-- FALLBACK: compiler y otros tipos -->
            <xsl:when test="person-group[not(@person-group-type='author')]/name">
              <xsl:for-each select="person-group[not(@person-group-type='author')][1]/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">
                  <xsl:text>, </xsl:text>
                  <xsl:call-template name="iniciales-apa">
                    <xsl:with-param name="nombres" select="given-names"/>
                  </xsl:call-template>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test="position() = last() - 1 and last() > 1"><xsl:text>, &amp; </xsl:text></xsl:when>
                  <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
                </xsl:choose>
              </xsl:for-each>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="abrev-tipo-persona">
                <xsl:with-param name="tipo" select="string(person-group[not(@person-group-type='author')][1]/@person-group-type)"/>
                <xsl:with-param name="cantidad" select="count(person-group[not(@person-group-type='author')][1]/name)"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
            </xsl:when>
          </xsl:choose>
        </span>
        <xsl:if test="year"> (<xsl:value-of select="year"/>). </xsl:if>
        <xsl:if test="chapter-title">
          <span class="ref-title"><xsl:value-of select="chapter-title"/>. </span>
          <xsl:text>En </xsl:text>
        </xsl:if>
        <xsl:if test="article-title">
          <span class="ref-title"><xsl:value-of select="article-title"/>. </span>
        </xsl:if>
        <xsl:if test="source">
          <em class="ref-source"><xsl:value-of select="source"/></em>
        </xsl:if>
        <xsl:if test="volume">, <em><xsl:value-of select="volume"/></em></xsl:if>
        <xsl:if test="issue">(<xsl:value-of select="issue"/>)</xsl:if>
        <xsl:if test="fpage">, <xsl:value-of select="fpage"/>
          <xsl:if test="lpage">&#x2013;<xsl:value-of select="lpage"/></xsl:if>
        </xsl:if>
        <xsl:if test="elocation-id">, <xsl:value-of select="elocation-id"/></xsl:if>
        <xsl:if test="publisher-name">. <xsl:value-of select="replace(publisher-name, '(\s)and(\s)', '$1y$2')"/></xsl:if>
        <xsl:if test="pub-id[@pub-id-type='doi']">
          <span class="ref-doi">
            <xsl:text> https://doi.org/</xsl:text>
            <xsl:value-of select="pub-id[@pub-id-type='doi']"/>
          </span>
        </xsl:if>
      </xsl:when>

      <!-- ISO 690 -->
      <xsl:when test="$estilo_cita = 'iso690'">
        <span class="ref-authors">
          <xsl:choose>
            <xsl:when test="person-group[@person-group-type='author']/name">
              <xsl:for-each select="person-group[@person-group-type='author']/name">
                <span style="font-variant:small-caps">
                  <xsl:value-of select="upper-case(surname)"/>
                </span>
                <xsl:if test="given-names">, <xsl:value-of select="given-names"/></xsl:if>
                <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:if test="person-group[@person-group-type='author']/etal"> et al.</xsl:if>
            </xsl:when>
            <xsl:when test="person-group[@person-group-type='editor']/name">
              <xsl:for-each select="person-group[@person-group-type='editor']/name">
                <span style="font-variant:small-caps">
                  <xsl:value-of select="upper-case(surname)"/>
                </span>
                <xsl:if test="given-names">, <xsl:value-of select="given-names"/></xsl:if>
                <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="abrev-tipo-persona">
                <xsl:with-param name="tipo" select="'editor'"/>
                <xsl:with-param name="cantidad" select="count(person-group[@person-group-type='editor']/name)"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
            </xsl:when>
            <!-- FALLBACK: compiler y otros tipos -->
            <xsl:when test="person-group[not(@person-group-type='author')]/name">
              <xsl:for-each select="person-group[not(@person-group-type='author')][1]/name">
                <span style="font-variant:small-caps">
                  <xsl:value-of select="upper-case(surname)"/>
                </span>
                <xsl:if test="given-names">, <xsl:value-of select="given-names"/></xsl:if>
                <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="abrev-tipo-persona">
                <xsl:with-param name="tipo" select="string(person-group[not(@person-group-type='author')][1]/@person-group-type)"/>
                <xsl:with-param name="cantidad" select="count(person-group[not(@person-group-type='author')][1]/name)"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
            </xsl:when>
          </xsl:choose>
        </span>
        <xsl:if test="year"> (<xsl:value-of select="year"/>). </xsl:if>
        <xsl:if test="article-title">
          &#x201C;<xsl:value-of select="article-title"/>&#x201D;.
        </xsl:if>
        <xsl:if test="chapter-title">
          &#x201C;<xsl:value-of select="chapter-title"/>&#x201D;. En:
        </xsl:if>
        <xsl:if test="source">
          <em class="ref-source"><xsl:value-of select="source"/></em>
        </xsl:if>
        <xsl:if test="volume">, vol. <xsl:value-of select="volume"/></xsl:if>
        <xsl:if test="issue">, n.º <xsl:value-of select="issue"/></xsl:if>
        <xsl:if test="fpage">, pp. <xsl:value-of select="fpage"/>
          <xsl:if test="lpage">&#x2013;<xsl:value-of select="lpage"/></xsl:if>
        </xsl:if>
        <xsl:if test="publisher-loc or publisher-name">
          <xsl:text>. </xsl:text>
          <xsl:if test="publisher-loc"><xsl:value-of select="publisher-loc"/>: </xsl:if>
          <xsl:if test="publisher-name"><xsl:value-of select="replace(publisher-name, '(\s)and(\s)', '$1y$2')"/></xsl:if>
        </xsl:if>
        <xsl:text>.</xsl:text>
        <xsl:if test="pub-id[@pub-id-type='doi']">
          <span class="ref-doi"> DOI: https://doi.org/<xsl:value-of select="pub-id[@pub-id-type='doi']"/></span>
        </xsl:if>
      </xsl:when>

      <!-- IEEE — TODO INLINE -->
      <xsl:when test="$estilo_cita = 'ieee'">
        <span class="ref-authors">
          <xsl:choose>
            <xsl:when test="person-group[@person-group-type='author']/name">
              <xsl:for-each select="person-group[@person-group-type='author']/name">
                <xsl:if test="given-names">
                  <xsl:value-of select="translate(given-names, '. ', '')"/>
                  <xsl:text>. </xsl:text>
                </xsl:if>
                <xsl:value-of select="surname"/>
                <xsl:choose>
                  <xsl:when test="position() = last() - 1 and last() > 1"><xsl:text> and </xsl:text></xsl:when>
                  <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
                </xsl:choose>
              </xsl:for-each>
            </xsl:when>
            <xsl:when test="person-group[not(@person-group-type='author')]/name">
              <xsl:for-each select="person-group[not(@person-group-type='author')][1]/name">
                <xsl:if test="given-names">
                  <xsl:value-of select="translate(given-names, '. ', '')"/>
                  <xsl:text>. </xsl:text>
                </xsl:if>
                <xsl:value-of select="surname"/>
                <xsl:choose>
                  <xsl:when test="position() = last() - 1 and last() > 1"><xsl:text> and </xsl:text></xsl:when>
                  <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
                </xsl:choose>
              </xsl:for-each>
              <xsl:text> (</xsl:text>
              <xsl:call-template name="abrev-tipo-persona">
                <xsl:with-param name="tipo" select="string(person-group[not(@person-group-type='author')][1]/@person-group-type)"/>
                <xsl:with-param name="cantidad" select="count(person-group[not(@person-group-type='author')][1]/name)"/>
              </xsl:call-template>
              <xsl:text>)</xsl:text>
            </xsl:when>
          </xsl:choose>
        </span>
        <xsl:text>. </xsl:text>
        <xsl:if test="article-title">&#x201C;<xsl:value-of select="article-title"/>,&#x201D; </xsl:if>
        <xsl:if test="chapter-title">&#x201C;<xsl:value-of select="chapter-title"/>,&#x201D; </xsl:if>
        <xsl:if test="source"><em class="ref-source"><xsl:value-of select="source"/></em></xsl:if>
        <xsl:if test="volume">, vol. <xsl:value-of select="volume"/></xsl:if>
        <xsl:if test="issue">, n.º <xsl:value-of select="issue"/></xsl:if>
        <xsl:if test="fpage">, pp. <xsl:value-of select="fpage"/>
          <xsl:if test="lpage">&#x2013;<xsl:value-of select="lpage"/></xsl:if>
        </xsl:if>
        <xsl:if test="publisher-loc or publisher-name">
          <xsl:text>. </xsl:text>
          <xsl:if test="publisher-loc"><xsl:value-of select="publisher-loc"/>: </xsl:if>
          <xsl:if test="publisher-name"><xsl:value-of select="replace(publisher-name, '(\s)and(\s)', '$1y$2')"/></xsl:if>
        </xsl:if>
        <xsl:if test="year">, <xsl:value-of select="year"/></xsl:if>
        <xsl:text>.</xsl:text>
        <xsl:if test="pub-id[@pub-id-type='doi']">
          <span class="ref-doi"> DOI: https://doi.org/<xsl:value-of select="pub-id[@pub-id-type='doi']"/></span>
        </xsl:if>
      </xsl:when>

      <!-- FALLBACK AUTOR-AÑO -->
      <xsl:otherwise>
        <span class="ref-authors">
          <xsl:choose>
            <xsl:when test="person-group[@person-group-type='author']/name">
              <xsl:for-each select="person-group[@person-group-type='author']/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">, <xsl:value-of select="given-names"/></xsl:if>
                <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:if test="person-group[@person-group-type='author']/etal">; et al.</xsl:if>
            </xsl:when>
            <xsl:when test="person-group[@person-group-type='editor']/name">
              <xsl:for-each select="person-group[@person-group-type='editor']/name">
                <xsl:value-of select="surname"/>
                <xsl:if test="given-names">, <xsl:value-of select="given-names"/></xsl:if>
                <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
              </xsl:for-each>
              <xsl:text> (ed.)</xsl:text>
            </xsl:when>
          </xsl:choose>
        </span>
        <xsl:if test="year"> (<xsl:value-of select="year"/>). </xsl:if>
        <xsl:if test="article-title">
          <span class="ref-title"><xsl:value-of select="article-title"/>. </span>
        </xsl:if>
        <xsl:if test="source">
          <em class="ref-source"><xsl:value-of select="source"/></em>
        </xsl:if>
        <xsl:if test="volume">, <xsl:value-of select="volume"/></xsl:if>
        <xsl:if test="issue">(<xsl:value-of select="issue"/>)</xsl:if>
        <xsl:if test="fpage">, pp. <xsl:value-of select="fpage"/>
          <xsl:if test="lpage">&#x2013;<xsl:value-of select="lpage"/></xsl:if>
        </xsl:if>
        <xsl:if test="publisher-loc">. <xsl:value-of select="publisher-loc"/>: </xsl:if>
        <xsl:if test="publisher-name"><xsl:value-of select="publisher-name"/></xsl:if>
        <xsl:text>. </xsl:text>
        <xsl:if test="pub-id[@pub-id-type='doi']">
          <span class="ref-doi"> DOI: https://doi.org/<xsl:value-of select="pub-id[@pub-id-type='doi']"/></span>
        </xsl:if>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: generarCitaPreamble
       GENERA LA REFERENCIA BIBLIOGRÁFICA DEL ARTÍCULO
       EN TEXTO PLANO SEGÚN EL ESTILO ACTIVO.
       SE LLAMA DESDE LA SECCIÓN preamble.
       ================================================ -->
  <xsl:template name="generarCitaPreamble">
    <xsl:variable name="anio"    select="//article-meta/pub-date/year"/>
    <xsl:variable name="revista" select="normalize-space(//journal-meta/journal-title-group/journal-title)"/>
    <xsl:variable name="vol"     select="//article-meta/volume"/>
    <xsl:variable name="num"     select="//article-meta/issue"/>
    <xsl:variable name="fp"      select="//article-meta/fpage"/>
    <xsl:variable name="lp"      select="//article-meta/lpage"/>

    <xsl:choose>

      <!-- APA 7 -->
      <xsl:when test="$estilo_cita = 'apa'">
        <xsl:for-each select="//contrib[@contrib-type='author']">
          <xsl:value-of select="name/surname"/>
          <xsl:if test="name/given-names">
            <xsl:text>, </xsl:text>
            <xsl:call-template name="iniciales-apa">
              <xsl:with-param name="nombres" select="name/given-names"/>
            </xsl:call-template>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="position() = last() - 1"><xsl:text>, &amp; </xsl:text></xsl:when>
            <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
          </xsl:choose>
        </xsl:for-each>
        <xsl:if test="$anio != ''"> (<xsl:value-of select="$anio"/>). </xsl:if>
        <xsl:value-of select="$titulo"/>
        <xsl:text>. </xsl:text>
        <em><xsl:value-of select="$revista"/></em>
        <xsl:if test="$vol != ''">, <em><xsl:value-of select="$vol"/></em></xsl:if>
        <xsl:if test="$num != ''">(<xsl:value-of select="$num"/>)</xsl:if>
        <xsl:if test="$fp != ''">, <xsl:value-of select="$fp"/>
          <xsl:if test="$lp != ''">&#x2013;<xsl:value-of select="$lp"/></xsl:if>
        </xsl:if>
        <xsl:if test="$doi != ''">. https://doi.org/<xsl:value-of select="$doi"/></xsl:if>
      </xsl:when>

      <!-- VANCOUVER -->
      <xsl:when test="$estilo_cita = 'vancouver'">
        <xsl:for-each select="//contrib[@contrib-type='author']">
          <xsl:value-of select="name/surname"/>
          <xsl:if test="name/given-names">
            <xsl:text> </xsl:text>
            <xsl:value-of select="translate(name/given-names, '. ', '')"/>
          </xsl:if>
          <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:text>. </xsl:text>
        <xsl:value-of select="$titulo"/>
        <xsl:text>. </xsl:text>
        <em><xsl:value-of select="$revista"/></em>
        <xsl:if test="$anio != ''">.  <xsl:value-of select="$anio"/></xsl:if>
        <xsl:if test="$vol != ''">;
          <xsl:value-of select="$vol"/>
        </xsl:if>
        <xsl:if test="$num != ''">(<xsl:value-of select="$num"/>)</xsl:if>
        <xsl:if test="$fp != ''">, <xsl:value-of select="$fp"/>
          <xsl:if test="$lp != ''">-<xsl:value-of select="$lp"/></xsl:if>
        </xsl:if>
        <xsl:if test="$doi != ''">. DOI: https://doi.org/<xsl:value-of select="$doi"/></xsl:if>
      </xsl:when>

      <!-- ISO 690 -->
      <xsl:when test="$estilo_cita = 'iso690'">
        <xsl:for-each select="//contrib[@contrib-type='author']">
          <xsl:value-of select="upper-case(name/surname)"/>
          <xsl:if test="name/given-names">, <xsl:value-of select="name/given-names"/></xsl:if>
          <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:if test="$anio != ''"> (<xsl:value-of select="$anio"/>). </xsl:if>
        <xsl:text>&#x201C;</xsl:text><xsl:value-of select="$titulo"/><xsl:text>&#x201D;. </xsl:text>
        <em><xsl:value-of select="$revista"/></em>
        <xsl:if test="$vol != ''">, vol. <xsl:value-of select="$vol"/></xsl:if>
        <xsl:if test="$num != ''">, n.&#xBA; <xsl:value-of select="$num"/></xsl:if>
        <xsl:if test="$fp != ''">, pp. <xsl:value-of select="$fp"/>
          <xsl:if test="$lp != ''">&#x2013;<xsl:value-of select="$lp"/></xsl:if>
        </xsl:if>
        <xsl:if test="$doi != ''">, DOI: https://doi.org/<xsl:value-of select="$doi"/></xsl:if>
      </xsl:when>

      <!-- FALLBACK AUTOR-AÑO -->
      <xsl:otherwise>
        <xsl:for-each select="//contrib[@contrib-type='author']">
          <xsl:value-of select="name/surname"/>
          <xsl:if test="name/given-names">, <xsl:value-of select="name/given-names"/></xsl:if>
          <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
        </xsl:for-each>
        <xsl:if test="$anio != ''"> (<xsl:value-of select="$anio"/>). </xsl:if>
        <xsl:value-of select="$titulo"/>
        <xsl:text>. </xsl:text>
        <em><xsl:value-of select="$revista"/></em>
        <xsl:if test="$vol != ''">, <xsl:value-of select="$vol"/></xsl:if>
        <xsl:if test="$num != ''">(<xsl:value-of select="$num"/>)</xsl:if>
        <xsl:if test="$fp != ''">, pp. <xsl:value-of select="$fp"/>
          <xsl:if test="$lp != ''">&#x2013;<xsl:value-of select="$lp"/></xsl:if>
        </xsl:if>
        <xsl:if test="$doi != ''">, DOI: https://doi.org/<xsl:value-of select="$doi"/></xsl:if>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: abrev-tipo-persona
       MAPEA @person-group-type A SU ABREVIATURA EN ESPAÑOL
       ================================================ -->
  <xsl:template name="abrev-tipo-persona">
    <xsl:param name="tipo" as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
    <xsl:param name="cantidad" as="xs:integer" xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
    <xsl:param name="minuscula" as="xs:boolean" select="false()" xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
    <xsl:variable name="texto">
      <xsl:choose>
        <xsl:when test="$tipo = 'compiler'"><xsl:choose><xsl:when test="$cantidad > 1">Comps.</xsl:when><xsl:otherwise>Comp.</xsl:otherwise></xsl:choose></xsl:when>
        <xsl:when test="$tipo = 'coordinator'"><xsl:choose><xsl:when test="$cantidad > 1">Coords.</xsl:when><xsl:otherwise>Coord.</xsl:otherwise></xsl:choose></xsl:when>
        <xsl:when test="$tipo = 'direction'"><xsl:choose><xsl:when test="$cantidad > 1">Dirs.</xsl:when><xsl:otherwise>Dir.</xsl:otherwise></xsl:choose></xsl:when>
        <xsl:when test="$tipo = 'organizer'"><xsl:choose><xsl:when test="$cantidad > 1">Orgs.</xsl:when><xsl:otherwise>Org.</xsl:otherwise></xsl:choose></xsl:when>
        <xsl:when test="$tipo = 'collaborator'"><xsl:choose><xsl:when test="$cantidad > 1">Cols.</xsl:when><xsl:otherwise>Col.</xsl:otherwise></xsl:choose></xsl:when>
        <xsl:when test="$tipo = 'editor'"><xsl:choose><xsl:when test="$cantidad > 1">Eds.</xsl:when><xsl:otherwise>Ed.</xsl:otherwise></xsl:choose></xsl:when>
        <xsl:otherwise><xsl:value-of select="$tipo"/><xsl:text>.</xsl:text></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="$minuscula"><xsl:value-of select="lower-case($texto)"/></xsl:when>
      <xsl:otherwise><xsl:value-of select="$texto"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: iniciales-apa
       CONVIERTE "John Allen" → "J. A."
       ================================================ -->
  <xsl:template name="iniciales-apa">
    <xsl:param name="nombres"/>
    <xsl:for-each select="tokenize(normalize-space($nombres), '\s+')">
      <xsl:value-of select="substring(., 1, 1)"/>
      <xsl:text>.</xsl:text>
      <xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- ================================================
       NAMED TEMPLATE: recolectarRidsGrupo
       ================================================ -->
  <xsl:template name="recolectarRidsGrupo" as="xs:string*"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">
    <xsl:param name="xrefActual" as="element()"/>
    <xsl:sequence select="string($xrefActual/@rid)"/>
    <xsl:variable name="sig1" select="$xrefActual/following-sibling::node()[1]"/>
    <xsl:variable name="sig2" select="$xrefActual/following-sibling::node()[2]"/>
    <xsl:if test="$sig1[self::text() and matches(., '^\s*[,;]\s*$')] and
                  $sig2[self::xref[@ref-type='bibr']]">
      <xsl:call-template name="recolectarRidsGrupo">
        <xsl:with-param name="xrefActual" select="$sig2"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ================================================
       ELEMENTOS DE FORMATO INLINE
       ================================================ -->
  <xsl:template match="bold">
    <strong><xsl:apply-templates/></strong>
  </xsl:template>

  <xsl:template match="italic">
    <em><xsl:apply-templates/></em>
  </xsl:template>

  <xsl:template match="sup">
    <sup><xsl:apply-templates/></sup>
  </xsl:template>

  <xsl:template match="sub">
    <sub><xsl:apply-templates/></sub>
  </xsl:template>

  <xsl:template match="monospace">
    <code><xsl:apply-templates/></code>
  </xsl:template>

  <!-- ================================================
       SUPRIMIR ELEMENTOS QUE NO VAN AL XHTML
       ================================================ -->
  <xsl:template match="front | back | journal-meta | article-meta |
                        article-categories | title-group | contrib-group |
                        pub-date | volume | issue | fpage | lpage |
                        permissions | kwd-group | funding-group | article-id"/>

  <xsl:template match="sec[@sec-type='intro']/title"     priority="3"/>
  <xsl:template match="sec[@sec-type='editorial']/title" priority="3"/>
  <xsl:template match="sec/title[normalize-space(.) = normalize-space(//article-meta/title-group/article-title)]" priority="2"/>

</xsl:stylesheet>
