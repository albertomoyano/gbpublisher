<?xml version="1.0" encoding="UTF-8"?>
<!-- Prueba de Saxon - JATS a HTML legible | output:articulo_prueba | format:html -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  exclude-result-prefixes="xs xlink">

  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- ================================================================ -->
  <!-- TEMPLATE PRINCIPAL -->
  <!-- ================================================================ -->
  <xsl:template match="/">
    <html lang="es">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>
          <xsl:value-of select="//article-title"/>
        </title>
        <style>
          body {
            font-family: 'Noto Serif', 'Liberation Serif', 'DejaVu Serif', serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 40px auto;
            padding: 0 20px;
            color: #333;
          }

          header {
            border-bottom: 3px solid #2c3e50;
            padding-bottom: 20px;
            margin-bottom: 30px;
          }

          .journal-name {
            color: #7f8c8d;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 1px;
          }

          h1 {
            color: #2c3e50;
            font-size: 2em;
            margin: 20px 0;
            line-height: 1.3;
          }

          .authors {
            font-size: 1.1em;
            margin: 15px 0;
          }

          .author {
            display: inline;
          }

          .author:not(:last-child):after {
            content: ", ";
          }

          .affiliations {
            font-size: 0.9em;
            color: #555;
            margin: 15px 0;
            padding-left: 20px;
          }

          .affiliation {
            margin: 5px 0;
          }

          .metadata {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            font-size: 0.9em;
            margin: 20px 0;
          }

          .abstract {
            background-color: #f8f9fa;
            padding: 20px;
            border-left: 4px solid #3498db;
            margin: 30px 0;
          }

          .abstract h2 {
            color: #3498db;
            font-size: 1.2em;
            margin-top: 0;
          }

          .keywords {
            margin: 20px 0;
            font-size: 0.95em;
          }

          .keywords strong {
            color: #2c3e50;
          }

          .keyword {
            display: inline-block;
            background-color: #e8f4f8;
            padding: 3px 10px;
            margin: 3px;
            border-radius: 3px;
            font-size: 0.9em;
          }

          section {
            margin: 30px 0;
          }

          h2 {
            color: #2c3e50;
            font-size: 1.5em;
            margin-top: 40px;
            border-bottom: 2px solid #ecf0f1;
            padding-bottom: 10px;
          }

          h3 {
            color: #34495e;
            font-size: 1.2em;
            margin-top: 25px;
          }

          p {
            text-align: justify;
            margin: 15px 0;
          }

          ul, ol {
            margin: 15px 0;
            padding-left: 30px;
          }

          li {
            margin: 8px 0;
          }

          .italic {
            font-style: italic;
          }

          .bold {
            font-weight: bold;
          }

          table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            font-size: 0.9em;
          }

          th {
            background-color: #34495e;
            color: white;
            padding: 12px;
            text-align: left;
          }

          td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
          }

          tr:hover {
            background-color: #f5f5f5;
          }

          .figure {
            margin: 30px 0;
            text-align: center;
          }

          .figure-caption {
            font-size: 0.9em;
            color: #555;
            margin-top: 10px;
            font-style: italic;
          }

          .references {
            margin-top: 40px;
            border-top: 3px solid #2c3e50;
            padding-top: 20px;
          }

          .reference {
            margin: 15px 0;
            padding-left: 30px;
            text-indent: -30px;
            font-size: 0.9em;
          }

          .xref {
            color: #3498db;
            text-decoration: none;
          }

          .xref:hover {
            text-decoration: underline;
          }

          .ext-link {
            color: #e74c3c;
            text-decoration: none;
          }

          .ext-link:hover {
            text-decoration: underline;
          }

          footer {
            margin-top: 60px;
            padding-top: 20px;
            border-top: 2px solid #ecf0f1;
            text-align: center;
            color: #7f8c8d;
            font-size: 0.85em;
          }

          .saxon-info {
            background-color: #d5f4e6;
            border: 1px solid #27ae60;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            font-size: 0.9em;
          }

          .saxon-info strong {
            color: #27ae60;
          }
        </style>
      </head>
      <body>
        <!-- MENSAJE DE ÉXITO DE SAXON CON FECHA EN ESPAÑOL -->
        <div class="saxon-info">
          <strong>✓ Transformación exitosa con Saxon</strong><br/>
          Este HTML fue generado usando XSLT 2.0 - Fecha:
          <xsl:variable name="mes" select="month-from-date(current-date())"/>
          <xsl:variable name="nombreMes">
            <xsl:choose>
              <xsl:when test="$mes = 1">enero</xsl:when>
              <xsl:when test="$mes = 2">febrero</xsl:when>
              <xsl:when test="$mes = 3">marzo</xsl:when>
              <xsl:when test="$mes = 4">abril</xsl:when>
              <xsl:when test="$mes = 5">mayo</xsl:when>
              <xsl:when test="$mes = 6">junio</xsl:when>
              <xsl:when test="$mes = 7">julio</xsl:when>
              <xsl:when test="$mes = 8">agosto</xsl:when>
              <xsl:when test="$mes = 9">septiembre</xsl:when>
              <xsl:when test="$mes = 10">octubre</xsl:when>
              <xsl:when test="$mes = 11">noviembre</xsl:when>
              <xsl:when test="$mes = 12">diciembre</xsl:when>
            </xsl:choose>
          </xsl:variable>
          <xsl:value-of select="concat(
            day-from-date(current-date()),
            ' de ',
            $nombreMes,
            ' de ',
            year-from-date(current-date())
          )"/>
        </div>

        <xsl:apply-templates select="//article"/>
      </body>
    </html>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: ARTÍCULO COMPLETO -->
  <!-- ================================================================ -->
  <xsl:template match="article">
    <header>
      <div class="journal-name">
        <xsl:value-of select="front/journal-meta/journal-title-group/journal-title"/>
      </div>

      <h1>
        <xsl:value-of select="front/article-meta/title-group/article-title"/>
      </h1>

      <!-- AUTORES -->
      <div class="authors">
        <xsl:for-each select="front/article-meta/contrib-group/contrib[@contrib-type='author']">
          <span class="author">
            <xsl:value-of select="name/given-names"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="name/surname"/>
            <xsl:if test="xref[@ref-type='aff']">
              <sup>
                <xsl:value-of select="xref[@ref-type='aff']/@rid"/>
              </sup>
            </xsl:if>
            <xsl:if test="xref[@ref-type='corresp']">
              <sup>*</sup>
            </xsl:if>
          </span>
        </xsl:for-each>
      </div>

      <!-- AFILIACIONES -->
      <div class="affiliations">
        <xsl:for-each select="front/article-meta/aff">
          <div class="affiliation">
            <sup><xsl:value-of select="label"/></sup>
            <xsl:text> </xsl:text>
            <xsl:value-of select="institution"/>
            <xsl:if test="addr-line/named-content[@content-type='city']">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="addr-line/named-content[@content-type='city']"/>
            </xsl:if>
            <xsl:if test="country">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="country"/>
            </xsl:if>
          </div>
        </xsl:for-each>

        <!-- CORRESPONDENCIA -->
        <xsl:if test="front/article-meta/author-notes/corresp">
          <div class="affiliation">
            <xsl:apply-templates select="front/article-meta/author-notes/corresp"/>
          </div>
        </xsl:if>
      </div>

      <!-- METADATOS DE PUBLICACIÓN -->
      <div class="metadata">
        <strong>DOI:</strong> <xsl:value-of select="front/article-meta/article-id[@pub-id-type='doi']"/>
        <br/>
        <strong>Publicado:</strong>
        <xsl:value-of select="front/article-meta/pub-date[@pub-type='epub']/day"/>/<xsl:value-of select="front/article-meta/pub-date[@pub-type='epub']/month"/>/<xsl:value-of select="front/article-meta/pub-date[@pub-type='epub']/year"/>
        <br/>
        <strong>Volumen:</strong> <xsl:value-of select="front/article-meta/volume"/>,
        <strong>Número:</strong> <xsl:value-of select="front/article-meta/issue"/>,
        <strong>Páginas:</strong> <xsl:value-of select="front/article-meta/fpage"/>-<xsl:value-of select="front/article-meta/lpage"/>
      </div>
    </header>

    <!-- RESUMEN -->
    <xsl:apply-templates select="front/article-meta/abstract"/>

    <!-- PALABRAS CLAVE -->
    <xsl:apply-templates select="front/article-meta/kwd-group"/>

    <!-- CUERPO DEL ARTÍCULO -->
    <xsl:apply-templates select="body"/>

    <!-- REFERENCIAS -->
    <xsl:apply-templates select="back/ref-list"/>

    <!-- PIE DE PÁGINA -->
    <footer>
      <p>Documento generado con gbpublisher utilizando Saxon-HE (XSLT 2.0)</p>
      <p>Formato de entrada: JATS XML | Formato de salida: HTML5</p>
    </footer>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: RESUMEN -->
  <!-- ================================================================ -->
  <xsl:template match="abstract">
    <div class="abstract">
      <h2><xsl:value-of select="title"/></h2>
      <xsl:apply-templates select="p"/>
    </div>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: PALABRAS CLAVE -->
  <!-- ================================================================ -->
  <xsl:template match="kwd-group">
    <div class="keywords">
      <strong><xsl:value-of select="title"/>:</strong>
      <xsl:for-each select="kwd">
        <span class="keyword">
          <xsl:value-of select="."/>
        </span>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: SECCIONES -->
  <!-- ================================================================ -->
  <xsl:template match="sec">
    <section id="{@id}">
      <xsl:choose>
        <xsl:when test="parent::sec">
          <h3>
            <xsl:if test="label">
              <xsl:value-of select="label"/>
              <xsl:text>. </xsl:text>
            </xsl:if>
            <xsl:value-of select="title"/>
          </h3>
        </xsl:when>
        <xsl:otherwise>
          <h2>
            <xsl:if test="label">
              <xsl:value-of select="label"/>
              <xsl:text>. </xsl:text>
            </xsl:if>
            <xsl:value-of select="title"/>
          </h2>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:apply-templates select="*[not(self::title) and not(self::label)]"/>
    </section>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: PÁRRAFOS -->
  <!-- ================================================================ -->
  <xsl:template match="p">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: LISTAS -->
  <!-- ================================================================ -->
  <xsl:template match="list[@list-type='order']">
    <ol>
      <xsl:apply-templates/>
    </ol>
  </xsl:template>

  <xsl:template match="list[@list-type='bullet']">
    <ul>
      <xsl:apply-templates/>
    </ul>
  </xsl:template>

  <xsl:template match="list-item">
    <li>
      <xsl:apply-templates/>
    </li>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: FORMATO DE TEXTO -->
  <!-- ================================================================ -->
  <xsl:template match="italic">
    <span class="italic">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <xsl:template match="bold">
    <span class="bold">
      <xsl:apply-templates/>
    </span>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: REFERENCIAS CRUZADAS -->
  <!-- ================================================================ -->
  <xsl:template match="xref">
    <a href="#{@rid}" class="xref">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: ENLACES EXTERNOS -->
  <!-- ================================================================ -->
  <xsl:template match="ext-link">
    <a href="{@xlink:href}" class="ext-link" target="_blank">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: TABLAS -->
  <!-- ================================================================ -->
  <xsl:template match="table-wrap">
    <div class="table-wrap" id="{@id}">
      <xsl:if test="label">
        <p><strong><xsl:value-of select="label"/>. </strong></p>
      </xsl:if>
      <xsl:if test="caption/title">
        <p><em><xsl:value-of select="caption/title"/></em></p>
      </xsl:if>
      <xsl:apply-templates select="table"/>
    </div>
  </xsl:template>

  <xsl:template match="table">
    <table>
      <xsl:apply-templates/>
    </table>
  </xsl:template>

  <xsl:template match="thead">
    <thead>
      <xsl:apply-templates/>
    </thead>
  </xsl:template>

  <xsl:template match="tbody">
    <tbody>
      <xsl:apply-templates/>
    </tbody>
  </xsl:template>

  <xsl:template match="tr">
    <tr>
      <xsl:apply-templates/>
    </tr>
  </xsl:template>

  <xsl:template match="th">
    <th>
      <xsl:apply-templates/>
    </th>
  </xsl:template>

  <xsl:template match="td">
    <td>
      <xsl:apply-templates/>
    </td>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: FIGURAS -->
  <!-- ================================================================ -->
  <xsl:template match="fig">
    <div class="figure" id="{@id}">
      <xsl:if test="label">
        <p><strong><xsl:value-of select="label"/></strong></p>
      </xsl:if>
      <xsl:if test="caption/title">
        <p class="figure-caption"><xsl:value-of select="caption/title"/></p>
      </xsl:if>
      <p><em>[Figura: <xsl:value-of select="graphic/@xlink:href"/>]</em></p>
    </div>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: CORRESPONDENCIA -->
  <!-- ================================================================ -->
  <xsl:template match="corresp">
    <sup><xsl:value-of select="label"/></sup>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select="node()[not(self::label)]"/>
  </xsl:template>

  <xsl:template match="email">
    <a href="mailto:{.}">
      <xsl:value-of select="."/>
    </a>
  </xsl:template>

  <!-- ================================================================ -->
  <!-- TEMPLATE: LISTA DE REFERENCIAS -->
  <!-- ================================================================ -->
  <xsl:template match="ref-list">
    <div class="references">
      <h2><xsl:value-of select="title"/></h2>
      <xsl:apply-templates select="ref"/>
    </div>
  </xsl:template>

  <xsl:template match="ref">
    <div class="reference" id="{@id}">
      <xsl:apply-templates select="element-citation"/>
    </div>
  </xsl:template>

  <xsl:template match="element-citation">
    <!-- AUTORES -->
    <xsl:for-each select="person-group[@person-group-type='author']/name">
      <xsl:value-of select="surname"/>
      <xsl:text>, </xsl:text>
      <xsl:value-of select="given-names"/>
      <xsl:if test="position() != last()">
        <xsl:text>; </xsl:text>
      </xsl:if>
    </xsl:for-each>

    <!-- AÑO -->
    <xsl:if test="year">
      <xsl:text> (</xsl:text>
      <xsl:value-of select="year"/>
      <xsl:text>). </xsl:text>
    </xsl:if>

    <!-- TÍTULO DEL ARTÍCULO O CAPÍTULO -->
    <xsl:if test="article-title">
      <xsl:value-of select="article-title"/>
      <xsl:text>. </xsl:text>
    </xsl:if>

    <xsl:if test="chapter-title">
      <xsl:value-of select="chapter-title"/>
      <xsl:text>. En: </xsl:text>
    </xsl:if>

    <!-- FUENTE (REVISTA O LIBRO) -->
    <xsl:if test="source">
      <em><xsl:value-of select="source"/></em>
      <xsl:text>. </xsl:text>
    </xsl:if>

    <!-- VOLUMEN E ISSUE -->
    <xsl:if test="volume">
      <xsl:value-of select="volume"/>
      <xsl:if test="issue">
        <xsl:text>(</xsl:text>
        <xsl:value-of select="issue"/>
        <xsl:text>)</xsl:text>
      </xsl:if>
      <xsl:text>, </xsl:text>
    </xsl:if>

    <!-- PÁGINAS -->
    <xsl:if test="fpage">
      <xsl:value-of select="fpage"/>
      <xsl:if test="lpage">
        <xsl:text>-</xsl:text>
        <xsl:value-of select="lpage"/>
      </xsl:if>
      <xsl:text>. </xsl:text>
    </xsl:if>

    <!-- EDITORIAL Y LUGAR (PARA LIBROS) -->
    <xsl:if test="publisher-loc">
      <xsl:value-of select="publisher-loc"/>
      <xsl:text>: </xsl:text>
    </xsl:if>

    <xsl:if test="publisher-name">
      <xsl:value-of select="publisher-name"/>
      <xsl:text>. </xsl:text>
    </xsl:if>

    <!-- DOI -->
    <xsl:if test="pub-id[@pub-id-type='doi']">
      <xsl:text>DOI: </xsl:text>
      <xsl:value-of select="pub-id[@pub-id-type='doi']"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
