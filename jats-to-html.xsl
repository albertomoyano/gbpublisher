<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  jats-to-html.xsl
  =====================================================
  DESCRIPCIÓN:
    TRANSFORMA UN ARTÍCULO JATS 1.4 CANÓNICO A HTML5
    CON DISEÑO DE 7 COLUMNAS TIPO LENS/DOCSY:

    - COLUMNA IZQUIERDA (2/7): METADATOS FIJOS (sticky)
    - COLUMNA CENTRAL  (3/7): TÍTULO + RESÚMENES + CUERPO
    - COLUMNA DERECHA  (2/7): PANEL NOTAS/REFS/FIGURAS (sticky, ocultable)

  PARÁMETROS:
    imagen_tapa  - NOMBRE DEL ARCHIVO DE TAPA EN /media
    ruta_media   - RUTA RELATIVA AL DIRECTORIO /media
                   VACÍO = solo nombre de archivo (para OJS)
                   ../media = revisión interna desde docs/

  VERSIÓN XSLT: 2.0 (REQUIERE SAXON-HE)
  =====================================================
-->
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  version="2.0">

  <!-- ================================================
       PARÁMETROS EXTERNOS
       ================================================ -->
  <xsl:param name="imagen_tapa" as="xs:string" select="''"
             xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
  <xsl:param name="ruta_media"  as="xs:string" select="''"
             xmlns:xs="http://www.w3.org/2001/XMLSchema"/>

  <!-- ================================================
       SALIDA: HTML5
       ================================================ -->
  <xsl:output
    method="html"
    version="5"
    encoding="UTF-8"
    indent="yes"/>

  <!-- ================================================
       VARIABLES GLOBALES DERIVADAS DEL JATS
       ================================================ -->
  <xsl:variable name="doi"
    select="normalize-space(//article-meta/article-id[@pub-id-type='doi'])"/>
  <xsl:variable name="lang"
    select="normalize-space(/article/@xml:lang)"/>
  <xsl:variable name="titulo"
    select="normalize-space(//article-meta/title-group/article-title)"/>
  <xsl:variable name="revista"
    select="normalize-space(//journal-meta/journal-title-group/journal-title)"/>

  <!-- ================================================
       TEMPLATE RAÍZ
       ================================================ -->
  <xsl:template match="/">
    <xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
    <html lang="{$lang}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>
          <xsl:value-of select="$titulo"/>
          <xsl:text> — </xsl:text>
          <xsl:value-of select="$revista"/>
        </title>

        <!-- META PARA INDEXACIÓN ACADÉMICA -->
        <xsl:if test="$doi != ''">
          <meta name="citation_doi" content="{$doi}"/>
        </xsl:if>
        <meta name="citation_title" content="{$titulo}"/>
        <xsl:for-each select="//contrib[@contrib-type='author']/name">
          <meta name="citation_author"
            content="{normalize-space(surname)}, {normalize-space(given-names)}"/>
        </xsl:for-each>

        <!-- MATHJAX PARA ECUACIONES -->
        <script>
          MathJax = {
            tex: {
              inlineMath: [['$', '$'], ['\\(', '\\)']],
              displayMath: [['$$', '$$'], ['\\[', '\\]']]
            },
            options: {
              skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre']
            }
          };
        </script>
        <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"
                async="async"/>

        <!-- FUENTES TIPOGRÁFICAS -->
        <link rel="preconnect" href="https://fonts.googleapis.com"/>
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
        <link href="https://fonts.googleapis.com/css2?family=Noto+Serif:ital,wght@0,400;0,600;1,400;1,600&amp;family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,600;1,300;1,400;1,600&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap"
              rel="stylesheet"/>

        <style>
          /* ============================================
             VARIABLES Y RESET
             ============================================ */
          :root {
            --col-left:   320px;   /* FIJA EN PX */
            --col-center: 2fr;     /* TOMA EL ESPACIO RESTANTE */
            --col-right:  1fr;     /* 50% DEL ANCHO DE CENTRO */

            --color-bg:               #fafaf8;
            --color-surface:          #ffffff;
            --color-border:           #e2e0db;
            --color-text:             #1a1a18;
            --color-text-muted:       #6b6860;
            --color-accent:           #2d5a8e;
            --color-accent-soft:      #eef3f9;
            --color-highlight:        #fef3cd;
            --color-highlight-border: #f0c040;
            --color-tab-active:       #2d5a8e;
            --color-code-bg:          #f4f3f0;
            --color-quote-bar:        #2d5a8e;

            --font-serif:  'Noto Serif', Georgia, serif;
            --font-sans:   'IBM Plex Sans', system-ui, sans-serif;
            --font-mono:   'JetBrains Mono', 'Courier New', monospace;

            --text-xs:   0.75rem;    /* 13.5px — metadatos, labels */
            --text-sm:   0.875rem;   /* 15.75px — abstracts, panel */
            --text-base: 1.125rem;   /* 18px — cuerpo del artículo */
            --text-lg:   1.25rem;    /* 22.5px */
            --text-xl:   1.5rem;     /* 27px */
            --text-2xl:  1.875rem;   /* 33.75px */
            --text-3xl:  2.375rem;   /* 42.75px */

            --radius:    4px;
            --radius-lg: 8px;
            --shadow-sm: 0 1px 3px rgba(0,0,0,0.08);
            --shadow:    0 2px 8px rgba(0,0,0,0.10);
          }

          *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

          html { scroll-behavior: smooth; }

          body {
            background: var(--color-bg);
            color: var(--color-text);
            font-family: var(--font-sans);
            font-size: var(--text-base);
            line-height: 1.7;
            -webkit-font-smoothing: antialiased;
          }

          /* ============================================
             LAYOUT PRINCIPAL — 7 COLUMNAS (2+3+2)
             ============================================ */
           .layout {
            display: grid;
            grid-template-columns: var(--col-left) var(--col-center) var(--col-right);
            grid-template-areas: "left center right";
            min-height: 100vh;
            width: 100%;
            gap: 0;
          }

          .layout.panel-hidden {
            grid-template-columns: 320px 1fr;
            grid-template-areas: "left center";
          }

          .layout.panel-hidden .col-right {
            display: none;
          }

          /* ============================================
             COLUMNA IZQUIERDA
             ============================================ */
          .col-left {
            grid-area: left;
            position: sticky;
            top: 0;
            height: 100vh;
            overflow-y: auto;
            border-right: 1px solid var(--color-border);
            background: var(--color-surface);
            padding: 1.5rem 1.25rem;
            scrollbar-width: thin;
          }

          .col-left::-webkit-scrollbar { width: 4px; }
          .col-left::-webkit-scrollbar-thumb {
            background: var(--color-border);
            border-radius: 2px;
          }

          .tapa-wrapper {
            margin-bottom: 1.5rem;
            border-radius: var(--radius);
            overflow: hidden;
            box-shadow: var(--shadow);
          }

          .tapa-wrapper img {
            width: 100%;
            height: auto;
            display: block;
          }

          .tapa-placeholder {
            background: var(--color-accent-soft);
            border: 2px dashed var(--color-border);
            border-radius: var(--radius);
            height: 160px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: var(--color-text-muted);
            font-size: var(--text-sm);
            margin-bottom: 1.5rem;
          }

          .meta-revista {
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--color-accent);
            margin-bottom: 0.25rem;
          }

          .meta-issn {
            font-size: var(--text-sm);
            color: var(--color-text-muted);
            margin-bottom: 1rem;
            padding-bottom: 1rem;
            border-bottom: 1px solid var(--color-border);
          }

          /* ETIQUETA INLINE EN NEGRITA (DOI:, e-ISSN:, EMAIL:) */
          .meta-key {
            font-size: var(--text-sm);
            font-weight: 600;
            color: var(--color-text);
          }

          .meta-seccion { margin-bottom: 1rem; }

          .meta-label {
            font-size: var(--text-xs);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--color-text-muted);
            margin-bottom: 0.35rem;
          }

          .meta-valor {
            font-size: var(--text-sm);
            color: var(--color-text);
            line-height: 1.5;
          }

          /* ============================================
             AUTORÍA — BLOQUE POR AUTOR
             ============================================ */
          .autor-item {
            margin-bottom: 0.75rem;
            padding-bottom: 0.75rem;
            border-bottom: 1px solid var(--color-border);
          }

          .autor-item:last-child {
            border-bottom: none;
            margin-bottom: 0;
            padding-bottom: 0;
          }

          /* NOMBRE + ORCID EN LA MISMA LÍNEA */
          .autor-nombre-linea {
            display: flex;
            align-items: baseline;
            flex-wrap: wrap;
            gap: 0.35rem;
          }

          .autor-nombre {
            font-size: var(--text-sm);
            font-weight: 600;
            color: var(--color-text);
          }

          .autor-orcid {
            font-size: var(--text-xs);
            color: var(--color-accent);
            text-decoration: none;
          }

          .autor-orcid:hover { text-decoration: underline; }

          .autor-email {
            font-size: var(--text-sm);
            color: var(--color-text-muted);
            margin-top: 0.2rem;
          }

          .autor-email a {
            color: var(--color-accent);
            text-decoration: none;
          }

          .autor-email a:hover { text-decoration: underline; }

          .autor-afil {
            font-size: var(--text-xs);
            color: var(--color-text-muted);
            margin-top: 0.2rem;
            line-height: 1.4;
          }

          /* ============================================
             DOI LINK
             ============================================ */
          .doi-link {
            font-size: var(--text-sm);
            color: var(--color-accent);
            text-decoration: none;
            word-break: break-all;
          }

          .doi-link:hover { text-decoration: underline; }

          .licencia-badge {
            display: inline-block;
            font-size: var(--text-xs);
            background: var(--color-accent-soft);
            color: var(--color-accent);
            padding: 0.2rem 0.5rem;
            border-radius: var(--radius);
            text-decoration: none;
            border: 1px solid rgba(45,90,142,0.2);
          }

          .kwd-list {
            display: flex;
            flex-wrap: wrap;
            gap: 0.3rem;
            margin-top: 0.35rem;
          }

          .kwd-tag {
            font-size: var(--text-xs);
            background: var(--color-code-bg);
            color: var(--color-text-muted);
            padding: 0.15rem 0.4rem;
            border-radius: var(--radius);
            border: 1px solid var(--color-border);
          }

          .kwd-lang-label {
            font-size: var(--text-xs);
            color: var(--color-text-muted);
            font-style: italic;
            margin-top: 0.5rem;
            margin-bottom: 0.2rem;
          }

          /* ============================================
             WIDGET CITAR ESTE ARTÍCULO
             ============================================ */
          .citar-wrapper {
            margin-top: 1.5rem;
            padding-top: 1rem;
            border-top: 1px solid var(--color-border);
          }

          .citar-toggle {
            font-size: var(--text-xs);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--color-text-muted);
            cursor: pointer;
            user-select: none;
            list-style: none;
            display: flex;
            align-items: center;
            gap: 0.4rem;
            padding: 0.4rem 0;
          }

          .citar-toggle::before {
            content: "▶";
            font-size: 0.6rem;
            transition: transform 0.2s;
          }

          details[open] .citar-toggle::before {
            transform: rotate(90deg);
          }

          .citar-formatos {
            display: flex;
            flex-wrap: wrap;
            gap: 0.3rem;
            margin: 0.75rem 0 0.5rem;
          }

          .citar-btn {
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 600;
            padding: 0.25rem 0.6rem;
            border-radius: var(--radius);
            border: 1px solid var(--color-border);
            background: var(--color-code-bg);
            color: var(--color-text-muted);
            cursor: pointer;
            transition: all 0.15s;
          }

          .citar-btn:hover,
          .citar-btn.active {
            background: var(--color-accent);
            color: #fff;
            border-color: var(--color-accent);
          }

          .citar-texto {
            font-family: var(--font-mono);
            font-size: 0.7rem;
            line-height: 1.6;
            background: var(--color-code-bg);
            border: 1px solid var(--color-border);
            border-radius: var(--radius);
            padding: 0.75rem;
            white-space: pre-wrap;
            word-break: break-all;
            color: var(--color-text);
            min-height: 60px;
          }

          .citar-copiar {
            margin-top: 0.5rem;
            width: 100%;
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 600;
            padding: 0.35rem;
            border-radius: var(--radius);
            border: 1px solid var(--color-accent);
            background: var(--color-accent-soft);
            color: var(--color-accent);
            cursor: pointer;
            transition: all 0.15s;
          }

          .citar-copiar:hover {
            background: var(--color-accent);
            color: #fff;
          }

          .citar-copiar.copiado {
            background: #2e7d52;
            border-color: #2e7d52;
            color: #fff;
          }

          /* ============================================
             COLUMNA CENTRAL
             ============================================ */
          .col-center {
            grid-area: center;
            padding: 2.5rem 24px 4rem 24px;
            max-width: 100%;
            min-width: 0;
          }

          .article-title {
            font-family: var(--font-serif);
            font-size: var(--text-3xl);
            font-weight: 700;
            line-height: 1.25;
            color: var(--color-text);
            margin-bottom: 0.75rem;
          }

          .article-trans-title {
            font-family: var(--font-serif);
            font-size: var(--text-xl);
            font-weight: 400;
            font-style: italic;
            color: var(--color-text-muted);
            margin-bottom: 2rem;
            padding-bottom: 2rem;
            border-bottom: 2px solid var(--color-border);
          }

          .abstracts-wrapper {
            margin-bottom: 2.5rem;
            padding-bottom: 2rem;
            border-bottom: 1px solid var(--color-border);
          }

          .abstract-block { margin-bottom: 0.5rem; }

          .abstract-lang-label {
            font-size: var(--text-xs);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--color-accent);
            cursor: pointer;
            user-select: none;
            list-style: none;
            display: flex;
            align-items: center;
            gap: 0.4rem;
            margin-bottom: 0;
            padding: 0.4rem 0;
          }

          .abstract-lang-label::before {
            content: "▶";
            font-size: 0.6rem;
            transition: transform 0.2s;
          }

          details[open] .abstract-lang-label::before {
            transform: rotate(90deg);
          }

          details[open] .abstract-texto {
            margin-top: 0.5rem;
          }

          .abstract-texto {
            font-size: var(--text-sm);
            line-height: 1.75;
            color: var(--color-text);
            background: var(--color-accent-soft);
            border-left: 3px solid var(--color-accent);
            padding: 1rem 1.25rem;
            border-radius: 0 var(--radius) var(--radius) 0;
          }

          /* CUERPO DEL ARTÍCULO */
          .article-body {
            font-family: var(--font-serif);
            font-size: var(--text-base);
            line-height: 1.85;
          }

          .article-body p {
            margin-bottom: 1.25em;
            text-align: justify;
            hyphens: auto;
          }

          .article-body .sec { margin-bottom: 2.5rem; }

          .article-body .sec-title {
            font-family: var(--font-sans);
            font-size: var(--text-xl);
            font-weight: 600;
            color: var(--color-text);
            margin-bottom: 1rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid var(--color-border);
          }

          /* EPÍGRAFE */
          .disp-quote-epigraph {
            margin: 1.5rem 0 1.5rem 2rem;
            padding: 0;
            border: none;
          }

          .disp-quote-epigraph p {
            font-style: italic;
            color: var(--color-text-muted);
            margin-bottom: 0.25rem;
          }

          .disp-quote-epigraph .attrib {
            font-size: var(--text-sm);
            color: var(--color-text-muted);
            font-style: normal;
          }

          .disp-quote-epigraph .attrib::before { content: "— "; }

          /* CITA EN BLOQUE */
          .disp-quote {
            margin: 1.5rem 0;
            padding: 1rem 1.5rem;
            border-left: 3px solid var(--color-quote-bar);
            background: var(--color-accent-soft);
            border-radius: 0 var(--radius) var(--radius) 0;
          }

          .disp-quote p {
            font-style: italic;
            margin-bottom: 0;
          }

          /* FIGURAS */
          .fig-wrapper {
            margin: 2rem 0;
            text-align: center;
            cursor: pointer;
          }

          .fig-wrapper img {
            max-width: 100%;
            height: auto;
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            transition: opacity 0.2s;
          }

          .fig-wrapper:hover img { opacity: 0.9; }

          .fig-label {
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--color-accent);
            margin-top: 0.75rem;
          }

          .fig-caption {
            font-size: var(--text-sm);
            color: var(--color-text-muted);
            margin-top: 0.25rem;
            font-style: italic;
          }

          /* VERSOS */
          .verse-group {
            margin: 1.5rem 0 1.5rem 2rem;
            font-style: italic;
          }

          .verse-line {
            display: block;
            line-height: 1.6;
          }

          /* CÓDIGO FUENTE */
          .code-block {
            margin: 1.5rem 0;
            background: var(--color-code-bg);
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            overflow: hidden;
          }

          .code-lang-label {
            font-family: var(--font-mono);
            font-size: var(--text-xs);
            color: var(--color-text-muted);
            background: var(--color-border);
            padding: 0.3rem 0.75rem;
            display: block;
          }

          .code-block pre {
            font-family: var(--font-mono);
            font-size: var(--text-sm);
            line-height: 1.6;
            padding: 1rem 1.25rem;
            overflow-x: auto;
            margin: 0;
          }

          /* RECUADRO */
          .boxed-text {
            margin: 1.5rem 0;
            padding: 1.25rem 1.5rem;
            border: 1px solid var(--color-border);
            border-radius: var(--radius-lg);
            background: var(--color-surface);
            box-shadow: var(--shadow-sm);
          }

          .boxed-text-warning {
            border-left: 4px solid #e67e22;
            background: #fffbf5;
          }

          .boxed-text-info {
            border-left: 4px solid var(--color-accent);
            background: var(--color-accent-soft);
          }

          /* NOTAS AL PIE INLINE */
          .fn-ref {
            font-size: var(--text-xs);
            vertical-align: super;
            color: var(--color-accent);
            cursor: pointer;
            font-family: var(--font-sans);
            font-weight: 600;
            text-decoration: none;
            margin-left: 1px;
          }

          .fn-ref:hover { text-decoration: underline; }

          .fn-ref.selected {
            background: var(--color-highlight);
            color: var(--color-accent);
            border-radius: 2px;
            padding: 0 2px;
          }

          /* FÓRMULAS */
          .disp-formula {
            margin: 1.5rem 0;
            text-align: center;
            overflow-x: auto;
            padding: 0.5rem;
          }

          /* SPEECH / DIÁLOGO */
          .speech-block {
            margin: 1rem 0 1rem 1rem;
            padding: 0.5rem 0;
          }

          .speech-speaker {
            font-family: var(--font-sans);
            font-size: var(--text-sm);
            font-weight: 700;
            color: var(--color-accent);
            margin-bottom: 0.15rem;
          }

          .speech-text { font-size: var(--text-base); }

          /* TABLAS */
          .table-wrap {
            margin: 2rem 0;
            overflow-x: auto;
          }

          .table-wrap table {
            width: 100%;
            border-collapse: collapse;
            font-family: var(--font-sans);
            font-size: var(--text-sm);
          }

          .table-wrap th {
            background: var(--color-accent);
            color: #fff;
            padding: 0.6rem 0.75rem;
            text-align: left;
            font-weight: 600;
            font-size: var(--text-xs);
            text-transform: uppercase;
            letter-spacing: 0.05em;
          }

          .table-wrap td {
            padding: 0.5rem 0.75rem;
            border-bottom: 1px solid var(--color-border);
            color: var(--color-text);
          }

          .table-wrap tr:nth-child(even) td { background: var(--color-accent-soft); }
          .table-wrap tr:hover td          { background: #f0f0ec; }

          /* CITAS BIBLIOGRÁFICAS EN TEXTO */
          .xref-bibr {
            color: var(--color-accent);
            cursor: pointer;
            font-size: inherit;
            text-decoration: none;
            font-style: normal;
            border-radius: 2px;
            padding: 0 2px;
            transition: background 0.15s, color 0.15s;
          }

          .xref-bibr:hover {
            background: var(--color-accent);
            color: #ffffff !important;
            text-decoration: none;
          }

          .xref-bibr:hover * { color: #ffffff !important; }

          .xref-bibr:visited { color: var(--color-accent); }

          .xref-bibr.selected {
            background: var(--color-highlight);
            color: var(--color-text);
            border-radius: 2px;
            padding: 0 2px;
          }

          /* ============================================
             COLUMNA DERECHA — PANEL LATERAL
             ============================================ */
          .col-right {
            grid-area: right;
            position: sticky;
            top: 0;
            height: 100vh;
            display: flex;
            flex-direction: column;
            border-left: 1px solid var(--color-border);
            background: var(--color-surface);
          }

          /* BOTÓN TOGGLE PANEL */
          .panel-toggle {
            position: fixed;
            top: 1rem;
            right: 1rem;
            z-index: 100;
            background: var(--color-surface);
            border: 1px solid var(--color-border);
            border-radius: var(--radius);
            padding: 0.4rem 0.75rem;
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 600;
            color: var(--color-text-muted);
            cursor: pointer;
            box-shadow: var(--shadow-sm);
            transition: all 0.15s;
          }

          .panel-toggle:hover {
            background: var(--color-accent-soft);
            color: var(--color-accent);
            border-color: var(--color-accent);
          }

          /* SOLAPAS */
          .panel-tabs {
            display: flex;
            border-bottom: 1px solid var(--color-border);
            background: var(--color-bg);
            flex-shrink: 0;
          }

          .panel-tab {
            flex: 1;
            padding: 0.75rem 0.5rem;
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.06em;
            color: var(--color-text-muted);
            background: none;
            border: none;
            border-bottom: 2px solid transparent;
            cursor: pointer;
            transition: all 0.15s;
          }

          .panel-tab:hover { color: var(--color-accent); }

          .panel-tab.active {
            color: var(--color-tab-active);
            border-bottom-color: var(--color-tab-active);
            background: var(--color-surface);
          }

          .panel-tab .tab-count {
            font-size: var(--text-xs);
            background: var(--color-code-bg);
            border-radius: 10px;
            padding: 0 0.4rem;
            margin-left: 0.25rem;
          }

          /* CONTENIDO DEL PANEL */
          .panel-content {
            flex: 1;
            overflow-y: auto;
            scrollbar-width: thin;
          }

          .panel-content::-webkit-scrollbar { width: 4px; }
          .panel-content::-webkit-scrollbar-thumb { background: var(--color-border); }

          .panel-section {
            display: none;
            padding: 1rem;
          }

          .panel-section.active { display: block; }

          /* ITEMS DEL PANEL */
          .panel-item {
            padding: 0.75rem;
            border-radius: var(--radius);
            margin-bottom: 0.5rem;
            border: 1px solid transparent;
            transition: all 0.2s;
          }

          .panel-item.highlighted {
            background: var(--color-highlight);
            border-color: var(--color-highlight-border);
          }

          .panel-item-label {
            font-family: var(--font-sans);
            font-size: var(--text-xs);
            font-weight: 700;
            color: var(--color-accent);
            margin-bottom: 0.35rem;
          }

          .panel-item-text {
            font-size: var(--text-sm);
            color: var(--color-text);
            line-height: 1.55;
            font-family: var(--font-sans);
          }

          /* REFERENCIAS EN PANEL */
          .ref-item {
            font-size: var(--text-sm);
            font-family: var(--font-sans);
            line-height: 1.55;
            color: var(--color-text);
          }

          .ref-authors        { font-weight: 600; }
          .ref-year           { color: var(--color-text-muted); }
          .ref-title-roman    { font-style: normal; }
          .ref-source-italic  { font-style: italic; color: var(--color-text-muted); }

          .ref-doi a {
            color: var(--color-accent);
            font-size: var(--text-xs);
            text-decoration: none;
          }

          .ref-doi a:hover { text-decoration: underline; }

          /* FIGURAS EN PANEL */
          .panel-fig img {
            width: 100%;
            height: auto;
            border-radius: var(--radius);
            margin-bottom: 0.5rem;
          }

          /* ============================================
             RESPONSIVE
             ============================================ */
          @media (max-width: 600px) {
            .layout {
              grid-template-columns: 1fr;
              grid-template-areas: "center";
            }
            .col-left, .col-right { display: none; }
            .col-center           { padding: 1.5rem; }
            .panel-toggle         { display: none; }
          }
        </style>
      </head>

      <body>

        <!-- BOTÓN PARA OCULTAR/MOSTRAR PANEL DERECHO
             ESTADO INICIAL: PANEL OCULTO             -->
        <button class="panel-toggle" id="panelToggle" onclick="togglePanel()">
          &#x2192; Mostrar panel
        </button>

        <!-- LAYOUT CON PANEL OCULTO POR DEFECTO -->
        <div class="layout panel-hidden" id="mainLayout">

          <!-- ==========================================
               COLUMNA IZQUIERDA — METADATOS
               ========================================== -->
          <aside class="col-left">

            <!-- TAPA DE LA REVISTA -->
            <xsl:choose>
              <xsl:when test="$imagen_tapa != ''">
                <div class="tapa-wrapper">
                  <xsl:variable name="nombre-tapa"
                    select="tokenize($imagen_tapa, '/')[last()]"/>
                  <xsl:variable name="src-tapa">
                    <xsl:choose>
                      <xsl:when test="$ruta_media != ''">
                        <xsl:value-of select="$ruta_media"/>
                        <xsl:text>/</xsl:text>
                        <xsl:value-of select="$nombre-tapa"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$nombre-tapa"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:variable>
                  <img src="{$src-tapa}" alt="Tapa de {$revista}"/>
                </div>
              </xsl:when>
              <xsl:otherwise>
                <div class="tapa-placeholder">Sin tapa</div>
              </xsl:otherwise>
            </xsl:choose>

            <!-- NOMBRE DE LA REVISTA -->
            <div class="meta-revista">
              <xsl:value-of select="$revista"/>
            </div>

            <!-- e-ISSN CON ETIQUETA INLINE -->
            <xsl:if test="//journal-meta/issn[@pub-type='epub']">
              <div class="meta-issn">
                <span class="meta-key">e-ISSN: </span>
                <xsl:value-of select="//journal-meta/issn[@pub-type='epub']"/>
              </div>
            </xsl:if>

            <!-- ==========================================
                 AUTORÍA — SIEMPRE "AUTORÍA" (1 o N autores)
                 NOMBRE | ORCID | EMAIL | AFILIACIÓN
                 ========================================== -->
            <xsl:if test="//contrib[@contrib-type='author']">
              <div class="meta-seccion">
                <div class="meta-label">Autor&#xED;a</div>
                <xsl:for-each select="//contrib[@contrib-type='author']">
                  <div class="autor-item">

                    <!-- NOMBRE + SUFIJO + ORCID INLINE -->
                    <div class="autor-nombre-linea">
                      <span class="autor-nombre">
                        <xsl:value-of select="name/given-names"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="name/surname"/>
                        <xsl:if test="name/suffix">
                          <xsl:text> </xsl:text>
                          <xsl:value-of select="name/suffix"/>
                        </xsl:if>
                      </span>
                      <xsl:if test="contrib-id[@contrib-id-type='orcid']">
                        <a class="autor-orcid"
                           href="{contrib-id[@contrib-id-type='orcid']}"
                           target="_blank"
                           rel="noopener noreferrer">
                          <xsl:text>ORCID &#x2197;</xsl:text>
                        </a>
                      </xsl:if>
                    </div>

                    <!-- EMAIL INSTITUCIONAL -->
                    <xsl:if test="email">
                      <div class="autor-email">
                        <span class="meta-key">EMAIL: </span>
                        <a href="mailto:{email}">
                          <xsl:value-of select="email"/>
                        </a>
                      </div>
                    </xsl:if>

                    <!-- AFILIACIÓN -->
                    <xsl:if test="aff">
                      <div class="autor-afil">
                        <xsl:for-each select="aff/institution">
                          <xsl:value-of select="."/>
                          <xsl:if test="position() != last()">
                            <xsl:text>, </xsl:text>
                          </xsl:if>
                        </xsl:for-each>
                        <xsl:if test="aff/city">
                          <xsl:text>, </xsl:text>
                          <xsl:value-of select="aff/city"/>
                        </xsl:if>
                        <xsl:if test="aff/country">
                          <xsl:text>, </xsl:text>
                          <xsl:value-of select="aff/country"/>
                        </xsl:if>
                      </div>
                    </xsl:if>

                  </div>
                </xsl:for-each>
              </div>
            </xsl:if>

            <!-- PUBLICACIÓN -->
            <div class="meta-seccion">
              <div class="meta-label">Publicaci&#xF3;n</div>
              <div class="meta-valor">
                <xsl:if test="//article-meta/pub-date/year">
                  <xsl:value-of select="//article-meta/pub-date/year"/>
                </xsl:if>
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
              </div>
            </div>

            <!-- DOI CON ETIQUETA EN NEGRITA INLINE -->
            <xsl:if test="$doi != ''">
              <div class="meta-seccion">
                <div class="meta-valor">
                  <span class="meta-key">DOI: </span>
                  <a class="doi-link"
                     href="https://doi.org/{$doi}"
                     target="_blank"
                     rel="noopener noreferrer">
                    <xsl:value-of select="$doi"/>
                  </a>
                </div>
              </div>
            </xsl:if>

            <!-- FECHAS -->
            <xsl:if test="//article-meta/history/date[@date-type='received'] or
                          //article-meta/history/date[@date-type='accepted'] or
                          //article-meta/history/date[@date-type='pub']">
              <div class="meta-seccion">
                <div class="meta-label">Fechas</div>
                <div class="meta-valor">

                  <xsl:if test="//article-meta/history/date[@date-type='received']">
                    <xsl:variable name="dr"
                      select="//article-meta/history/date[@date-type='received']"/>
                    <div>
                      <span style="color:var(--color-text-muted)">Recibido: </span>
                      <xsl:value-of select="$dr/day"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$dr/month"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$dr/year"/>
                    </div>
                  </xsl:if>

                  <xsl:if test="//article-meta/history/date[@date-type='accepted']">
                    <xsl:variable name="da"
                      select="//article-meta/history/date[@date-type='accepted']"/>
                    <div>
                      <span style="color:var(--color-text-muted)">Aceptado: </span>
                      <xsl:value-of select="$da/day"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$da/month"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$da/year"/>
                    </div>
                  </xsl:if>

                  <xsl:if test="//article-meta/history/date[@date-type='pub']">
                    <xsl:variable name="dp"
                      select="//article-meta/history/date[@date-type='pub']"/>
                    <div>
                      <span style="color:var(--color-text-muted)">Online: </span>
                      <xsl:value-of select="$dp/day"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$dp/month"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="$dp/year"/>
                    </div>
                  </xsl:if>

                </div>
              </div>
            </xsl:if>

            <!-- LICENCIA -->
            <xsl:if test="//permissions/license">
              <div class="meta-seccion">
                <div class="meta-label">Licencia</div>
                <a class="licencia-badge"
                   href="{//permissions/license/@xlink:href}"
                   target="_blank"
                   rel="noopener noreferrer">
                  <xsl:value-of select="//permissions/license/license-p"/>
                </a>
              </div>
            </xsl:if>

            <!-- PALABRAS CLAVE -->
            <xsl:for-each select="//kwd-group">
              <div class="meta-seccion">
                <div class="meta-label">
                  <xsl:text>Palabras clave</xsl:text>
                  <xsl:if test="@xml:lang != ''">
                    <span class="kwd-lang-label">
                      <xsl:text> (</xsl:text>
                      <xsl:value-of select="@xml:lang"/>
                      <xsl:text>)</xsl:text>
                    </span>
                  </xsl:if>
                </div>
                <div class="kwd-list">
                  <xsl:for-each select="kwd">
                    <span class="kwd-tag">
                      <xsl:value-of select="."/>
                    </span>
                  </xsl:for-each>
                </div>
              </div>
            </xsl:for-each>

            <!-- CITAR ESTE ARTÍCULO -->
            <div class="citar-wrapper">
              <details>
                <summary class="citar-toggle">Citar este art&#xED;culo</summary>
                <div class="citar-formatos">
                  <button class="citar-btn active" onclick="mostrarFormato(this, 'apa')">APA 7</button>
                  <button class="citar-btn" onclick="mostrarFormato(this, 'ieee')">IEEE</button>
                  <button class="citar-btn" onclick="mostrarFormato(this, 'vancouver')">Vancouver</button>
                  <button class="citar-btn" onclick="mostrarFormato(this, 'bibtex')">BibTeX</button>
                  <button class="citar-btn" onclick="mostrarFormato(this, 'ris')">RIS</button>
                </div>
                <div class="citar-texto" id="citar-output"></div>
                <button class="citar-copiar" id="citar-copiar-btn" onclick="copiarCita()">
                  Copiar
                </button>
              </details>
            </div>

          </aside>

          <!-- ==========================================
               COLUMNA CENTRAL — CONTENIDO
               ========================================== -->
          <main class="col-center">

            <!-- TÍTULO -->
            <h1 class="article-title">
              <xsl:value-of select="//article-meta/title-group/article-title"/>
            </h1>

            <!-- TÍTULO TRADUCIDO -->
            <xsl:if test="//article-meta/title-group/trans-title-group/trans-title">
              <div class="article-trans-title">
                <xsl:value-of
                  select="//article-meta/title-group/trans-title-group/trans-title"/>
              </div>
            </xsl:if>

            <!-- RESÚMENES -->
            <xsl:if test="//abstract or //trans-abstract">
              <div class="abstracts-wrapper">
                <xsl:apply-templates select="//abstract"/>
                <xsl:apply-templates select="//trans-abstract"/>
              </div>
            </xsl:if>

            <!-- CUERPO DEL ARTÍCULO -->
            <div class="article-body">
              <xsl:apply-templates select="//body"/>
            </div>

          </main>

          <!-- ==========================================
               COLUMNA DERECHA — PANEL LATERAL
               ========================================== -->
          <aside class="col-right" id="rightPanel">

            <div class="panel-tabs">
              <button class="panel-tab active" id="tab-notas"
                      onclick="switchTab('notas')">
                Notas
                <span class="tab-count" id="count-notas">0</span>
              </button>
              <button class="panel-tab" id="tab-refs"
                      onclick="switchTab('refs')">
                Referencias
                <span class="tab-count" id="count-refs">0</span>
              </button>
              <button class="panel-tab" id="tab-figs"
                      onclick="switchTab('figs')">
                Figuras
                <span class="tab-count" id="count-figs">0</span>
              </button>
            </div>

            <div class="panel-content">

              <!-- SECCIÓN NOTAS (construida por JS) -->
              <div class="panel-section active" id="panel-notas"></div>

              <!-- SECCIÓN REFERENCIAS (generada por XSLT) -->
              <div class="panel-section" id="panel-refs">
                <xsl:apply-templates select="//ref-list/ref"/>
              </div>

              <!-- SECCIÓN FIGURAS (construida por JS) -->
              <div class="panel-section" id="panel-figs"></div>

            </div>
          </aside>

        </div>

        <!-- FOOTER -->
        <footer style="
          background: #2a2a28;
          color: #c8c6c0;
          text-align: center;
          padding: 1.25rem;
          font-family: var(--font-sans);
          font-size: 0.9rem;
          font-weight: 300;
          letter-spacing: 0.03em;
          margin-top: 1.5rem;
        ">
          <xsl:variable name="mes-num" select="month-from-date(current-date())"/>
          <xsl:variable name="mes-texto">
            <xsl:choose>
              <xsl:when test="$mes-num=1">enero</xsl:when>
              <xsl:when test="$mes-num=2">febrero</xsl:when>
              <xsl:when test="$mes-num=3">marzo</xsl:when>
              <xsl:when test="$mes-num=4">abril</xsl:when>
              <xsl:when test="$mes-num=5">mayo</xsl:when>
              <xsl:when test="$mes-num=6">junio</xsl:when>
              <xsl:when test="$mes-num=7">julio</xsl:when>
              <xsl:when test="$mes-num=8">agosto</xsl:when>
              <xsl:when test="$mes-num=9">septiembre</xsl:when>
              <xsl:when test="$mes-num=10">octubre</xsl:when>
              <xsl:when test="$mes-num=11">noviembre</xsl:when>
              <xsl:otherwise>diciembre</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:text>P&#xE1;gina generada el </xsl:text>
          <xsl:value-of select="format-date(current-date(), '[D]')"/>
          <xsl:text> de </xsl:text>
          <xsl:value-of select="$mes-texto"/>
          <xsl:text> de </xsl:text>
          <xsl:value-of select="format-date(current-date(), '[Y0001]')"/>
          <xsl:text> con </xsl:text>
          <a href="https://estudio2a.netlify.app/"
             target="_blank"
             rel="noopener noreferrer"
             style="color: #8ab4d8; text-decoration: none;">gbpublisher</a>
        </footer>

        <!-- ============================================
             JAVASCRIPT — INTERACTIVIDAD DEL PANEL
             ============================================ -->
        <script>

          // ============================================
          // DATOS DE LA CITA — INYECTADOS POR XSLT
          // ============================================
          var citaData = {
            titulo:  "<xsl:value-of select="replace(replace($titulo, '\\', '\\\\'), '&quot;', '\\&quot;')"/>",
            revista: "<xsl:value-of select="replace(replace($revista, '\\', '\\\\'), '&quot;', '\\&quot;')"/>",
            doi:     "<xsl:value-of select="$doi"/>",
            anio:    "<xsl:value-of select="//article-meta/pub-date/year"/>",
            volumen: "<xsl:value-of select="//article-meta/volume"/>",
            numero:  "<xsl:value-of select="//article-meta/issue"/>",
            paginaI: "<xsl:value-of select="//article-meta/fpage"/>",
            paginaF: "<xsl:value-of select="//article-meta/lpage"/>",
            autores: [<xsl:for-each select="//contrib[@contrib-type='author']"><xsl:text>{apellido:"</xsl:text><xsl:value-of select="replace(name/surname, '&quot;', '\\&quot;')"/><xsl:text>",nombre:"</xsl:text><xsl:value-of select="replace(name/given-names, '&quot;', '\\&quot;')"/><xsl:text>"}</xsl:text><xsl:if test="position() != last()">,</xsl:if></xsl:for-each>]
          };

          // ============================================
          // INICIALIZACIÓN: CONSTRUIR PANEL DESDE EL DOM
          // ============================================
          document.addEventListener('DOMContentLoaded', function() {
            buildNotesPanel();
            buildFigsPanel();
            updateCounts();
            // MOSTRAR APA POR DEFECTO SIN EVENTO
            document.getElementById('citar-output').textContent = generarCita('apa');
          });

          // ============================================
          // CONSTRUIR INICIAL DE NOMBRE (ej: "J. A.")
          // ============================================
          function iniciales(nombre) {
            if (!nombre) return '';
            return nombre.split(' ').map(function(p) {
              return p.charAt(0).toUpperCase() + '.';
            }).join(' ');
          }

          // ============================================
          // GENERAR CITA SEGÚN FORMATO
          // ============================================
          function generarCita(formato) {
            var d      = citaData;
            var doiUrl = d.doi ? 'https://doi.org/' + d.doi : '';
            var pages  = d.paginaI ? d.paginaI + (d.paginaF ? '\u2013' + d.paginaF : '') : '';

            // APA 7
            if (formato === 'apa') {
              var lista = d.autores.map(function(a) {
                return a.apellido + ', ' + iniciales(a.nombre);
              });
              var autStr = lista.length === 1
                ? lista[0]
                : lista.slice(0, -1).join(', ') + ', &amp; ' + lista[lista.length - 1];
              var cita = autStr + ' (' + d.anio + '). ' + d.titulo + '. ';
              cita += d.revista;
              if (d.volumen) cita += ', ' + d.volumen;
              if (d.numero)  cita += '(' + d.numero + ')';
              if (pages)     cita += ', ' + pages;
              cita += '.';
              if (doiUrl) cita += ' ' + doiUrl;
              return cita;
            }

            // IEEE
            if (formato === 'ieee') {
              var lista = d.autores.map(function(a) {
                return iniciales(a.nombre) + ' ' + a.apellido;
              });
              var autStr = lista.length &lt;= 3
                ? lista.join(', ')
                : lista[0] + ' et al.';
              var cita = autStr + ', "' + d.titulo + '," ';
              cita += d.revista;
              if (d.volumen) cita += ', vol. ' + d.volumen;
              if (d.numero)  cita += ', no. ' + d.numero;
              if (pages)     cita += ', pp. ' + pages;
              if (d.anio)    cita += ', ' + d.anio;
              if (d.doi)     cita += ', doi: ' + d.doi;
              cita += '.';
              return cita;
            }

            // VANCOUVER
            if (formato === 'vancouver') {
              var lista = d.autores.map(function(a) {
                return a.apellido + ' ' + iniciales(a.nombre).replace(/\./g, '').replace(/ /g, '');
              });
              var autStr = lista.length > 6
                ? lista.slice(0, 6).join(', ') + ', et al'
                : lista.join(', ');
              var cita = autStr + '. ' + d.titulo + '. ';
              cita += d.revista + '. ';
              cita += d.anio;
              if (d.volumen) cita += ';' + d.volumen;
              if (d.numero)  cita += '(' + d.numero + ')';
              if (pages)     cita += ':' + pages.replace('\u2013', '-');
              cita += '.';
              if (d.doi) cita += ' doi:' + d.doi;
              return cita;
            }

            // BIBTEX
            if (formato === 'bibtex') {
              var citekey = (d.autores[0] ? d.autores[0].apellido.toLowerCase() : 'autor')
                            + d.anio;
              var autStr = d.autores.map(function(a) {
                return a.apellido + ', ' + a.nombre;
              }).join(' and ');
              var cita = '@article{' + citekey + ',\n';
              cita += '  author  = {' + autStr + '},\n';
              cita += '  title   = {' + d.titulo + '},\n';
              cita += '  journal = {' + d.revista + '},\n';
              cita += '  year    = {' + d.anio + '}';
              if (d.volumen) cita += ',\n  volume  = {' + d.volumen + '}';
              if (d.numero)  cita += ',\n  number  = {' + d.numero + '}';
              if (d.paginaI) cita += ',\n  pages   = {' + d.paginaI + (d.paginaF ? '--' + d.paginaF : '') + '}';
              if (d.doi)     cita += ',\n  doi     = {' + d.doi + '}';
              cita += '\n}';
              return cita;
            }

            // RIS
            if (formato === 'ris') {
              var cita = 'TY  - JOUR\n';
              d.autores.forEach(function(a) {
                cita += 'AU  - ' + a.apellido + ', ' + a.nombre + '\n';
              });
              cita += 'TI  - ' + d.titulo + '\n';
              cita += 'JO  - ' + d.revista + '\n';
              cita += 'PY  - ' + d.anio + '\n';
              if (d.volumen) cita += 'VL  - ' + d.volumen + '\n';
              if (d.numero)  cita += 'IS  - ' + d.numero + '\n';
              if (d.paginaI) cita += 'SP  - ' + d.paginaI + '\n';
              if (d.paginaF) cita += 'EP  - ' + d.paginaF + '\n';
              if (d.doi)     cita += 'DO  - ' + d.doi + '\n';
              cita += 'ER  - ';
              return cita;
            }

            return '';
          }

          // ============================================
          // MOSTRAR FORMATO SELECCIONADO
          // ============================================
          function mostrarFormato(btn, formato) {
            document.getElementById('citar-output').textContent = generarCita(formato);

            // ACTUALIZAR BOTONES ACTIVOS
            document.querySelectorAll('.citar-btn').forEach(function(b) {
              b.classList.remove('active');
            });
            btn.classList.add('active');

            // RESET BOTÓN COPIAR
            var btnCopiar = document.getElementById('citar-copiar-btn');
            btnCopiar.textContent = 'Copiar';
            btnCopiar.classList.remove('copiado');
          }

          // ============================================
          // COPIAR CITA AL PORTAPAPELES
          // ============================================
          function copiarCita() {
            var texto = document.getElementById('citar-output').textContent;
            var btn   = document.getElementById('citar-copiar-btn');
            navigator.clipboard.writeText(texto).then(function() {
              btn.textContent = '\u2713 Copiado';
              btn.classList.add('copiado');
              setTimeout(function() {
                btn.textContent = 'Copiar';
                btn.classList.remove('copiado');
              }, 2000);
            });
          }

          // ============================================
          // CONSTRUIR PANEL DE NOTAS DESDE LOS fn-ref DEL TEXTO
          // ============================================
          function buildNotesPanel() {
            var panelNotas = document.getElementById('panel-notas');
            var fnRefs     = document.querySelectorAll('.fn-ref');
            panelNotas.innerHTML = '';

            if (fnRefs.length === 0) {
              panelNotas.innerHTML =
                '<p style="padding:1rem;color:var(--color-text-muted);' +
                'font-size:0.875rem;">Sin notas al pie.</p>';
              return;
            }

            fnRefs.forEach(function(ref) {
              var id    = ref.getAttribute('data-fn-id');
              var texto = ref.getAttribute('data-fn-text');
              var num   = ref.textContent;
              var item  = document.createElement('div');
              item.className = 'panel-item';
              item.id = 'panel-fn-' + id;
              item.innerHTML =
                '<div class="panel-item-label">Nota ' + num + '</div>' +
                '<div class="panel-item-text">' + texto + '</div>';
              panelNotas.appendChild(item);
            });
          }

          // ============================================
          // CONSTRUIR PANEL DE FIGURAS DESDE LAS fig-wrapper DEL TEXTO
          // ============================================
          function buildFigsPanel() {
            var panelFigs = document.getElementById('panel-figs');
            var figs      = document.querySelectorAll('.fig-wrapper');
            panelFigs.innerHTML = '';

            if (figs.length === 0) {
              panelFigs.innerHTML =
                '<p style="padding:1rem;color:var(--color-text-muted);' +
                'font-size:0.875rem;">Sin figuras.</p>';
              return;
            }

            figs.forEach(function(fig) {
              var id      = fig.getAttribute('data-fig-id');
              var img     = fig.querySelector('img');
              var caption = fig.querySelector('.fig-caption');
              var label   = fig.querySelector('.fig-label');
              var item    = document.createElement('div');
              item.className = 'panel-item panel-fig';
              item.id = 'panel-fig-' + id;

              var html = '';
              if (img)     html += '<img src="' + img.src + '" alt="' + (img.alt || '') + '"/>';
              if (label)   html += '<div class="panel-item-label">' + label.textContent + '</div>';
              if (caption) html += '<div class="panel-item-text">' + caption.textContent + '</div>';

              item.innerHTML = html;
              panelFigs.appendChild(item);
            });
          }

          // ============================================
          // ACTUALIZAR CONTADORES DE SOLAPAS
          // ============================================
          function updateCounts() {
            document.getElementById('count-notas').textContent =
              document.querySelectorAll('.fn-ref').length;
            document.getElementById('count-refs').textContent =
              document.querySelectorAll('#panel-refs .panel-item').length;
            document.getElementById('count-figs').textContent =
              document.querySelectorAll('.fig-wrapper').length;
          }

          // ============================================
          // CAMBIAR SOLAPA ACTIVA
          // ============================================
          function switchTab(tab) {
            ['notas', 'refs', 'figs'].forEach(function(t) {
              document.getElementById('tab-'   + t).classList.remove('active');
              document.getElementById('panel-' + t).classList.remove('active');
            });
            document.getElementById('tab-'   + tab).classList.add('active');
            document.getElementById('panel-' + tab).classList.add('active');
          }

          // ============================================
          // HIGHLIGHT CON TOGGLE
          // ============================================
          var selectedRef  = null;
          var panelVisible = false;

          function highlightPanel(tipo, id) {

            // TOGGLE: DESPINTAR Y OCULTAR PANEL
            if (selectedRef === tipo + '-' + id) {
              selectedRef = null;
              document.querySelectorAll('.panel-item.highlighted').forEach(function(el) {
                el.classList.remove('highlighted');
              });
              document.querySelectorAll('.xref-bibr.selected, .fn-ref.selected').forEach(
                function(el) { el.classList.remove('selected'); }
              );
              if (panelVisible) togglePanel();
              return;
            }

            // LIMPIAR SELECCIÓN ANTERIOR
            selectedRef = tipo + '-' + id;
            document.querySelectorAll('.panel-item.highlighted').forEach(function(el) {
              el.classList.remove('highlighted');
            });
            document.querySelectorAll('.xref-bibr.selected, .fn-ref.selected').forEach(
              function(el) { el.classList.remove('selected'); }
            );

            // ABRIR PANEL SI ESTÁ OCULTO
            if (!panelVisible) togglePanel();

            // RESALTAR EN EL TEXTO
            var textoEl = document.querySelector(
              '.xref-bibr[data-ref-id="' + id + '"], .fn-ref[data-fn-id="' + id + '"]'
            );
            if (textoEl) textoEl.classList.add('selected');

            // RESALTAR EN EL PANEL CON DELAY PARA ESPERAR DISPLAY
            switchTab(tipo);
            setTimeout(function() {
              var target = null;
              if (tipo === 'notas') {
                target = document.getElementById('panel-fn-' + id);
              } else if (tipo === 'refs') {
                target = document.querySelector('#panel-refs [data-ref-id="' + id + '"]');
              } else if (tipo === 'figs') {
                target = document.getElementById('panel-fig-' + id);
              }
              if (target) {
                target.classList.add('highlighted');
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
              }
            }, 100);
          }

          // ============================================
          // TOGGLE PANEL DERECHO
          // ============================================
          function togglePanel() {
            var layout = document.getElementById('mainLayout');
            var btn    = document.getElementById('panelToggle');
            panelVisible = !panelVisible;
            layout.classList.toggle('panel-hidden', !panelVisible);
            btn.textContent = panelVisible ? '\u2190 Ocultar panel' : '\u2192 Mostrar panel';
          }

        </script>

      </body>
    </html>
  </xsl:template>

  <!-- ================================================
       RESÚMENES — COLAPSABLES CON details/summary
       ================================================ -->
  <xsl:template match="abstract | trans-abstract">
    <details class="abstract-block">
      <summary class="abstract-lang-label">
        <xsl:choose>
          <xsl:when test="@xml:lang = 'es'">Resumen</xsl:when>
          <xsl:when test="@xml:lang = 'en'">Abstract</xsl:when>
          <xsl:when test="@xml:lang = 'pt'">Resumo</xsl:when>
          <xsl:when test="@xml:lang = 'fr'">R&#xE9;sum&#xE9;</xsl:when>
          <xsl:otherwise><xsl:value-of select="@xml:lang"/></xsl:otherwise>
        </xsl:choose>
      </summary>
      <div class="abstract-texto">
        <xsl:apply-templates/>
      </div>
    </details>
  </xsl:template>

  <!-- ================================================
       BODY
       ================================================ -->
  <xsl:template match="body">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ================================================
       SECCIÓN
       ================================================ -->
  <xsl:template match="sec">
    <div class="sec" id="{@id}">
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="sec/title">
    <h2 class="sec-title"><xsl:apply-templates/></h2>
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
    <blockquote class="disp-quote-epigraph">
      <xsl:apply-templates select="p"/>
      <xsl:if test="attrib">
        <cite class="attrib">
          <xsl:value-of select="attrib"/>
        </cite>
      </xsl:if>
    </blockquote>
  </xsl:template>

  <!-- ================================================
       CITA EN BLOQUE (NO EPÍGRAFE)
       ================================================ -->
  <xsl:template match="disp-quote[not(@specific-use='epigraph')]">
    <blockquote class="disp-quote">
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <!-- ================================================
       FIGURA
       ================================================ -->
  <xsl:template match="fig">
    <xsl:variable name="href"   select="graphic/@xlink:href"/>
    <xsl:variable name="nombre" select="tokenize($href, '/')[last()]"/>
    <xsl:variable name="src">
      <xsl:choose>
        <xsl:when test="$ruta_media != ''">
          <xsl:value-of select="$ruta_media"/>
          <xsl:text>/</xsl:text>
          <xsl:value-of select="$nombre"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$nombre"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <div class="fig-wrapper"
         data-fig-id="{@id}"
         onclick="highlightPanel('figs', '{@id}')">
      <img src="{$src}" alt="{normalize-space(caption/p)}"/>
      <div class="fig-label">
        <xsl:text>Figura </xsl:text>
        <xsl:number count="fig" level="any"/>
      </div>
      <xsl:if test="caption/p">
        <div class="fig-caption">
          <xsl:value-of select="caption/p"/>
        </div>
      </xsl:if>
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
       CÓDIGO FUENTE
       ================================================ -->
  <xsl:template match="code">
    <div class="code-block">
      <xsl:if test="@language">
        <span class="code-lang-label">
          <xsl:value-of select="@language"/>
        </span>
      </xsl:if>
      <pre><xsl:value-of select="."/></pre>
    </div>
  </xsl:template>

  <!-- ================================================
       RECUADRO
       ================================================ -->
  <xsl:template match="boxed-text">
    <div>
      <xsl:attribute name="class">
        <xsl:text>boxed-text</xsl:text>
        <xsl:if test="@content-type">
          <xsl:text> boxed-text-</xsl:text>
          <xsl:value-of select="@content-type"/>
        </xsl:if>
      </xsl:attribute>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- ================================================
       NOTA AL PIE INLINE — fn
       ================================================ -->
  <xsl:template match="fn">
    <xsl:variable name="fn-num">
      <xsl:number count="fn" level="any"/>
    </xsl:variable>
    <xsl:variable name="fn-id"   select="generate-id(.)"/>
    <xsl:variable name="fn-text">
      <xsl:apply-templates mode="text-only"/>
    </xsl:variable>
    <a class="fn-ref"
       data-fn-id="{$fn-id}"
       data-fn-text="{$fn-text}"
       onclick="highlightPanel('notas', '{$fn-id}')"
       href="#panel-fn-{$fn-id}">
      <xsl:value-of select="$fn-num"/>
    </a>
  </xsl:template>

  <!-- MODO TEXT-ONLY PARA EXTRAER TEXTO DE fn SIN ETIQUETAS -->
  <xsl:template match="*" mode="text-only">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- ================================================
       FÓRMULA MATEMÁTICA
       ================================================ -->
  <xsl:template match="disp-formula">
    <div class="disp-formula" id="{@id}">
      <xsl:text>\[</xsl:text>
      <xsl:value-of select="tex-math"/>
      <xsl:text>\]</xsl:text>
    </div>
  </xsl:template>

  <!-- ================================================
       SPEECH / DIÁLOGO
       ================================================ -->
  <xsl:template match="speech">
    <div class="speech-block">
      <div class="speech-speaker">
        <xsl:value-of select="speaker"/>
      </div>
      <div class="speech-text">
        <xsl:apply-templates select="p"/>
      </div>
    </div>
  </xsl:template>

  <!-- ================================================
       TABLA
       ================================================ -->
  <xsl:template match="table-wrap">
    <div class="table-wrap" id="{@id}">
      <xsl:apply-templates select="table"/>
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
       XREF — CITA BIBLIOGRÁFICA EN TEXTO
       MANEJA CITAS MÚLTIPLES CONSECUTIVAS:
         PRIMERA:     ( Apellido, año
         INTERMEDIAS: ; Apellido, año
         ÚLTIMA:      )
       ================================================ -->
  <xsl:template match="xref[@ref-type='bibr']">
    <xsl:variable name="rid" select="@rid"/>
    <xsl:variable name="cit" select="//ref[@id=$rid]/element-citation"/>
    <xsl:variable name="autor">
      <xsl:choose>
        <xsl:when test="$cit/person-group[@person-group-type='author']/name[1]/surname">
          <xsl:value-of
            select="$cit/person-group[@person-group-type='author']/name[1]/surname"/>
        </xsl:when>
        <xsl:when test="$cit/person-group[@person-group-type='editor']/name[1]/surname">
          <xsl:value-of
            select="$cit/person-group[@person-group-type='editor']/name[1]/surname"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$rid"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="anio" select="$cit/year"/>

    <xsl:variable name="esPrimera" select="not(
      preceding-sibling::node()[1][self::text() and matches(., '^\s*,\s*$')] and
      preceding-sibling::node()[2][self::xref[@ref-type='bibr']]
    )"/>

    <xsl:variable name="esUltima" select="not(
      following-sibling::node()[1][self::text() and matches(., '^\s*,\s*$')] and
      following-sibling::node()[2][self::xref[@ref-type='bibr']]
    )"/>

    <xsl:if test="$esPrimera"><xsl:text>(</xsl:text></xsl:if>
    <xsl:if test="not($esPrimera)"><xsl:text>; </xsl:text></xsl:if>

    <a class="xref-bibr"
       data-ref-id="{$rid}"
       onclick="highlightPanel('refs', '{$rid}')"
       href="#panel-ref-{$rid}">
      <xsl:value-of select="$autor"/>
      <xsl:if test="$anio != ''">
        <xsl:text>, </xsl:text>
        <xsl:value-of select="$anio"/>
      </xsl:if>
    </a>

    <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
  </xsl:template>

  <!-- SUPRIMIR NODOS ", " ENTRE DOS XREFS CONSECUTIVOS -->
  <xsl:template match="text()[matches(., '^\s*,\s*$')]
    [preceding-sibling::node()[1][self::xref[@ref-type='bibr']]]
    [following-sibling::node()[1][self::xref[@ref-type='bibr']]]"/>

  <!-- ================================================
       REFERENCIAS EN PANEL DERECHO
       ================================================ -->
  <xsl:template match="ref">
    <div class="panel-item ref-item" data-ref-id="{@id}">
      <xsl:apply-templates select="element-citation"/>
    </div>
  </xsl:template>

  <xsl:template match="element-citation">
    <div class="ref-authors">
      <xsl:for-each select="person-group[@person-group-type='author']/name">
        <xsl:value-of select="surname"/>
        <xsl:if test="given-names">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="given-names"/>
        </xsl:if>
        <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
      </xsl:for-each>
      <xsl:for-each select="person-group[@person-group-type='editor']/name">
        <xsl:value-of select="surname"/>
        <xsl:if test="given-names">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="given-names"/>
        </xsl:if>
        <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
        <xsl:if test="position() = last()"><xsl:text> (ed.)</xsl:text></xsl:if>
      </xsl:for-each>
    </div>
    <xsl:if test="year">
      <span class="ref-year">
        <xsl:text> (</xsl:text>
        <xsl:value-of select="year"/>
        <xsl:text>). </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="chapter-title">
      <span class="ref-title-roman">
        <xsl:value-of select="chapter-title"/>
        <xsl:text>. </xsl:text>
      </span>
      <xsl:text>En </xsl:text>
    </xsl:if>
    <xsl:if test="article-title">
      <span class="ref-title-roman">
        <xsl:value-of select="article-title"/>
        <xsl:text>. </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="source">
      <span class="ref-source-italic">
        <xsl:value-of select="source"/>
        <xsl:text>. </xsl:text>
      </span>
    </xsl:if>
    <xsl:if test="publisher-loc">
      <xsl:value-of select="publisher-loc"/>
      <xsl:text>: </xsl:text>
    </xsl:if>
    <xsl:if test="publisher-name">
      <xsl:value-of select="publisher-name"/>
      <xsl:text>. </xsl:text>
    </xsl:if>
    <xsl:if test="fpage">
      <xsl:text>pp. </xsl:text>
      <xsl:value-of select="fpage"/>
      <xsl:if test="lpage">
        <xsl:text>&#x2013;</xsl:text>
        <xsl:value-of select="lpage"/>
      </xsl:if>
      <xsl:text>. </xsl:text>
    </xsl:if>
    <xsl:if test="pub-id[@pub-id-type='doi']">
      <div class="ref-doi">
        <a href="https://doi.org/{pub-id[@pub-id-type='doi']}"
           target="_blank"
           rel="noopener noreferrer">
          <xsl:text>DOI: </xsl:text>
          <xsl:value-of select="pub-id[@pub-id-type='doi']"/>
        </a>
      </div>
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
       SUPRIMIR ELEMENTOS QUE NO VAN AL HTML
       ================================================ -->
  <xsl:template match="front | back | journal-meta | article-meta |
                        article-categories | title-group | contrib-group |
                        pub-date | volume | issue | fpage | lpage |
                        permissions |
                        kwd-group | funding-group | article-id"/>

  <xsl:template match="sec[@sec-type='intro']/title"     priority="3"/>
  <xsl:template match="sec[@sec-type='editorial']/title" priority="3"/>
  <xsl:template match="sec/title[normalize-space(.) = normalize-space(//article-meta/title-group/article-title)]" priority="2"/>

</xsl:stylesheet>
