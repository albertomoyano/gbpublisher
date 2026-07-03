<?xml version="1.0" encoding="UTF-8"?>
<!--
=========================================================
docbook-to-html.xsl — Generación HTML del libro completo
=========================================================
UBICACIÓN: ~/.gbpublisher/xslt/docbook-to-html.xsl

VERSIÓN: Fase 1 (solo index.html — portada del libro).

PROPÓSITO GENERAL:
  Transforma el canónico DocBook 5.2 del libro completo
  (jats/c-libro-{nombre}.xml) en una salida HTML multi-página
  para GitHub Pages. Todas las páginas comparten CSS/JS externo
  en docs/assets/ para minimizar tamaño y facilitar mantenimiento.

FUENTES DE ENTRADA:
  - Fuente principal: canónico ensamblado del libro.
  - Parámetro manifiesto_libro: ruta al manifiesto para mapear
    xml:id → nombre_archivo de cada capítulo.
  - Parámetro proyecto_dir: para construir paths absolutos si
    hicieran falta (por ahora no se usa; queda declarado para
    fases futuras).

SALIDAS DE FASE 1:
  - docs/index.html: portada del libro con
    * layout de 2 columnas (col-left + col-center, sin col-right)
    * metadatos HTML: Highwire Press, DC, OG, Twitter Cards
    * col-left: tapa, ISBN(s), autores, editorial, DOI, colección/serie,
      licencia, fecha de publicación en cascada
    * col-center: título, subtítulo, autoría, resumen (si hay),
      keywords, lista de capítulos con enlaces a h-{nombre}.html

FASES POSTERIORES (no implementadas todavía):
  - Fase 2: páginas h-{nombre_archivo}.html de cada capítulo
  - Fase 3: drawer con refs/notas/figs
  - Fase 4: metadatos HTML por capítulo
  - Fase 5: widget "Citar este libro/capítulo"

RC APLICADAS:
  - RC-XJ-01: idioma en cascada (idioma_principal → 'es' default)
  - RC-DB-08: copy-namespaces="no" cuando aplique
  - Fecha en cascada: fecha_publicacion_completa → mes+año → año → nada
=========================================================
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="db xs xlink">

  <!-- Output principal: no se usa en Fase 1 (todo va por xsl:result-document) -->
  <xsl:output method="xml"
              encoding="UTF-8"
              indent="yes"
              omit-xml-declaration="yes"/>

  <!-- Formato específico para archivos HTML de salida -->
  <xsl:output name="html5"
              method="html"
              encoding="UTF-8"
              indent="yes"
              doctype-system="about:legacy-compat"
              omit-xml-declaration="yes"/>

  <!-- ==========================================================
       PARÁMETROS DE ENTRADA
       ========================================================== -->
  <xsl:param name="proyecto_dir" as="xs:string" required="yes"/>
  <xsl:param name="manifiesto_libro" as="xs:string" required="yes"/>

  <!-- ==========================================================
       CARGA DEL MANIFIESTO Y KEY PARA MAPEAR xml:id → nombre_archivo
       ========================================================== -->
  <xsl:variable name="manifiesto"
                select="doc(concat($proyecto_dir, '/', $manifiesto_libro))"/>

  <!-- Genera un mapeo directo: al buscar la key con el xml_id de un capítulo
       ('cap-7'), retorna el nodo <capitulo> del manifiesto que tiene
       @id_capitulo='7'. De ahí se lee el @nombre_archivo. -->
  <xsl:key name="cap-por-id"
           match="capitulo"
           use="concat('cap-', @id_capitulo)"/>

  <!-- ==========================================================
       VARIABLES GLOBALES DERIVADAS DEL <book>
       ========================================================== -->
  <xsl:variable name="book" select="/db:book | /book"/>
  <xsl:variable name="info" select="$book/db:info | $book/info"/>

  <xsl:variable name="idioma_principal" as="xs:string">
    <xsl:choose>
      <xsl:when test="normalize-space($book/@xml:lang) != ''">
        <xsl:value-of select="$book/@xml:lang"/>
      </xsl:when>
      <xsl:otherwise>es</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="titulo_libro" as="xs:string">
    <xsl:value-of select="normalize-space($info/db:title[not(@role)] | $info/title[not(@role)])"/>
  </xsl:variable>

  <xsl:variable name="subtitulo" as="xs:string">
    <xsl:value-of select="normalize-space($info/db:subtitle | $info/subtitle)"/>
  </xsl:variable>

  <xsl:variable name="doi_libro" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:biblioid[@class='doi'] | $info/biblioid[@class='doi'])[1])"/>
  </xsl:variable>

  <xsl:variable name="isbn_print" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:biblioid[@class='isbn'][@role='print']
       | $info/biblioid[@class='isbn'][@role='print'])[1])"/>
  </xsl:variable>

  <xsl:variable name="isbn_electronic" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:biblioid[@class='isbn'][@role='electronic']
       | $info/biblioid[@class='isbn'][@role='electronic'])[1])"/>
  </xsl:variable>

  <xsl:variable name="editorial" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:publisher/db:publishername
       | $info/publisher/publishername)[1])"/>
  </xsl:variable>

  <xsl:variable name="ciudad_pub" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:publisher/db:address/db:city
       | $info/publisher/address/city)[1])"/>
  </xsl:variable>

  <xsl:variable name="pais_pub" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:publisher/db:address/db:country
       | $info/publisher/address/country)[1])"/>
  </xsl:variable>

  <!-- Fecha de publicación en cascada:
       1. pubdate[@role='completa'] (ISO YYYY-MM-DD)
       2. pubdate sin role (año)
       3. bibliomisc[@role='mes-publicacion'] + pubdate (año)
       4. vacío -->
  <xsl:variable name="fecha_completa" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:pubdate[@role='completa'] | $info/pubdate[@role='completa'])[1])"/>
  </xsl:variable>

  <xsl:variable name="anio_publicacion" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:pubdate[not(@role)] | $info/pubdate[not(@role)])[1])"/>
  </xsl:variable>

  <xsl:variable name="mes_publicacion" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:bibliomisc[@role='mes-publicacion']
       | $info/bibliomisc[@role='mes-publicacion'])[1])"/>
  </xsl:variable>

  <!-- Fecha "amigable" para mostrar en col-left, según cascada -->
  <xsl:variable name="fecha_display" as="xs:string">
    <xsl:choose>
      <xsl:when test="$fecha_completa != ''">
        <xsl:value-of select="$fecha_completa"/>
      </xsl:when>
      <xsl:when test="$mes_publicacion != '' and $anio_publicacion != ''">
        <xsl:value-of select="concat($mes_publicacion, ' ', $anio_publicacion)"/>
      </xsl:when>
      <xsl:when test="$anio_publicacion != ''">
        <xsl:value-of select="$anio_publicacion"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Tapa del libro: en el canónico está como ../media/{archivo}
       (relativa desde jats/). En HTML va como assets/media/{archivo}. -->
  <xsl:variable name="imagen_tapa" as="xs:string">
    <xsl:variable name="fileref"
                  select="($info/db:mediaobject[@role='tapa']/db:imageobject/db:imagedata/@fileref
                          | $info/mediaobject[@role='tapa']/imageobject/imagedata/@fileref)[1]"/>
    <xsl:choose>
      <xsl:when test="$fileref != ''">
        <!-- Extraer solo el nombre del archivo -->
        <xsl:value-of select="concat('assets/media/',
                                    tokenize($fileref, '/')[last()])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text></xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="url_libro" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:bibliomisc[@role='url-libro']
       | $info/bibliomisc[@role='url-libro'])[1])"/>
  </xsl:variable>

  <xsl:variable name="licencia_texto" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:legalnotice[@role='licencia']/db:para[1]
       | $info/legalnotice[@role='licencia']/para[1])[1])"/>
  </xsl:variable>

  <xsl:variable name="licencia_url" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:legalnotice[@role='licencia']/db:para/db:link/@xlink:href
       | $info/legalnotice[@role='licencia']/para/link/@xlink:href)[1])"/>
  </xsl:variable>

  <xsl:variable name="resumen_libro" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:abstract[not(@role='traducido')]/db:para
       | $info/abstract[not(@role='traducido')]/para)[1])"/>
  </xsl:variable>

  <!-- ==========================================================
       TEMPLATE PRINCIPAL: MATCH /
       ==========================================================
       En Fase 1 solo emite index.html.
       En fases futuras acá también se disparan xsl:result-document
       para cada capítulo. -->
  <xsl:template match="/">
    <xsl:call-template name="emitir-index-html"/>
  </xsl:template>

  <!-- ==========================================================
       TEMPLATE: EMITIR index.html
       ========================================================== -->
  <xsl:template name="emitir-index-html">
    <xsl:result-document href="docs/index.html" format="html5">
      <html lang="{$idioma_principal}">
        <head>
          <meta charset="UTF-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

          <title>
            <xsl:value-of select="$titulo_libro"/>
          </title>

          <xsl:call-template name="emitir-meta-highwire-libro"/>
          <xsl:call-template name="emitir-meta-dc-libro"/>
          <xsl:call-template name="emitir-meta-og-twitter-libro"/>

          <!-- Fuentes tipográficas (compartidas con revistas) -->
          <link rel="preconnect" href="https://fonts.googleapis.com"/>
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="crossorigin"/>
          <link rel="stylesheet"
                href="https://fonts.googleapis.com/css2?family=Noto+Serif:ital,wght@0,400;0,600;1,400;1,600&amp;family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,600;1,300;1,400;1,600&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap"/>

          <!-- CSS y JS externos, compartidos entre index y capítulos -->
          <link rel="stylesheet" href="assets/css/gbpublisher.css"/>
        </head>

        <body class="pagina-libro-index">

          <!-- ==========================================
               LAYOUT DE 2 COLUMNAS (SIN COL-RIGHT)
               ========================================== -->
          <div class="layout layout-2col" id="mainLayout">

            <xsl:call-template name="emitir-col-left-libro"/>
            <xsl:call-template name="emitir-col-center-index"/>

          </div>

          <!-- ==========================================
               JAVASCRIPT: EN FASE 1 NO HAY DRAWER NI CITAR
               El JS externo se carga por si en el futuro
               se agregan interacciones. citaData se
               inyectará en Fase 5.
               ========================================== -->
          <script src="assets/js/gbpublisher.js"></script>

        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- ==========================================================
       META TAGS: HIGHWIRE PRESS (Google Scholar) — LIBROS
       ========================================================== -->
  <xsl:template name="emitir-meta-highwire-libro">
    <xsl:comment> ============================================
    METADATOS: Highwire Press — Google Scholar
    Adaptados para libros (citation_book_title, citation_isbn)
    ============================================ </xsl:comment>

    <meta name="citation_book_title" content="{$titulo_libro}"/>

    <xsl:if test="$doi_libro != ''">
      <meta name="citation_doi" content="{$doi_libro}"/>
    </xsl:if>

    <xsl:if test="$isbn_print != ''">
      <meta name="citation_isbn" content="{$isbn_print}"/>
    </xsl:if>

    <xsl:if test="$isbn_electronic != ''">
      <meta name="citation_isbn" content="{$isbn_electronic}"/>
    </xsl:if>

    <xsl:if test="$editorial != ''">
      <meta name="citation_publisher" content="{$editorial}"/>
    </xsl:if>

    <xsl:if test="$anio_publicacion != ''">
      <meta name="citation_publication_date" content="{$anio_publicacion}"/>
    </xsl:if>

    <meta name="citation_language" content="{$idioma_principal}"/>

    <xsl:if test="$url_libro != ''">
      <meta name="citation_fulltext_html_url" content="{$url_libro}"/>
    </xsl:if>

    <!-- Autores (loop) -->
    <xsl:for-each select="$info/db:author | $info/author">
      <meta name="citation_author"
            content="{normalize-space(db:personname/db:surname | personname/surname)}, {normalize-space(db:personname/db:firstname | personname/firstname)}"/>

      <xsl:variable name="orcid_url"
                    select="(db:uri[@type='orcid'] | uri[@type='orcid'])[1]"/>
      <xsl:if test="$orcid_url != ''">
        <meta name="citation_author_orcid" content="{$orcid_url}"/>
      </xsl:if>

      <xsl:variable name="orgname"
                    select="(db:affiliation/db:orgname | affiliation/orgname)[1]"/>
      <xsl:if test="$orgname != ''">
        <meta name="citation_author_institution" content="{normalize-space($orgname)}"/>
      </xsl:if>
    </xsl:for-each>

    <!-- Editores del libro -->
    <xsl:for-each select="$info/db:editor | $info/editor">
      <meta name="citation_editor"
            content="{normalize-space(db:personname/db:surname | personname/surname)}, {normalize-space(db:personname/db:firstname | personname/firstname)}"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ==========================================================
       META TAGS: DUBLIN CORE
       ========================================================== -->
  <xsl:template name="emitir-meta-dc-libro">
    <xsl:comment> ============================================
    METADATOS: Dublin Core (DC)
    ============================================ </xsl:comment>

    <meta name="DC.title" content="{$titulo_libro}"/>
    <meta name="DC.language" content="{$idioma_principal}"/>
    <meta name="DC.type" content="Book"/>
    <meta name="DC.format" content="text/html"/>

    <xsl:if test="$editorial != ''">
      <meta name="DC.publisher" content="{$editorial}"/>
    </xsl:if>

    <xsl:if test="$doi_libro != ''">
      <meta name="DC.identifier" content="https://doi.org/{$doi_libro}"/>
    </xsl:if>

    <xsl:if test="$anio_publicacion != ''">
      <meta name="DC.date" content="{$anio_publicacion}"/>
    </xsl:if>

    <xsl:if test="$licencia_url != ''">
      <meta name="DC.rights" content="{$licencia_url}"/>
    </xsl:if>

    <xsl:for-each select="$info/db:author | $info/author">
      <meta name="DC.creator"
            content="{normalize-space(db:personname/db:surname | personname/surname)}, {normalize-space(db:personname/db:firstname | personname/firstname)}"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ==========================================================
       META TAGS: OPEN GRAPH + TWITTER CARDS
       ========================================================== -->
  <xsl:template name="emitir-meta-og-twitter-libro">
    <xsl:comment> ============================================
    METADATOS: Open Graph + Twitter Cards
    ============================================ </xsl:comment>

    <meta property="og:type" content="book"/>
    <meta property="og:title" content="{$titulo_libro}"/>
    <xsl:if test="$resumen_libro != ''">
      <meta property="og:description" content="{$resumen_libro}"/>
    </xsl:if>
    <xsl:if test="$imagen_tapa != ''">
      <meta property="og:image" content="{$imagen_tapa}"/>
    </xsl:if>
    <xsl:if test="$url_libro != ''">
      <meta property="og:url" content="{$url_libro}"/>
    </xsl:if>
    <xsl:if test="$isbn_print != ''">
      <meta property="og:book:isbn" content="{$isbn_print}"/>
    </xsl:if>

    <meta name="twitter:card" content="summary_large_image"/>
    <meta name="twitter:title" content="{$titulo_libro}"/>
    <xsl:if test="$resumen_libro != ''">
      <meta name="twitter:description" content="{$resumen_libro}"/>
    </xsl:if>
    <xsl:if test="$imagen_tapa != ''">
      <meta name="twitter:image" content="{$imagen_tapa}"/>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       COL-LEFT: METADATOS DEL LIBRO
       ==========================================================
       Estructura:
         - Tapa
         - ISBN(s)
         - Autores del libro
         - Publicación (año + lugar)
         - DOI
         - Licencia badge
         - Colección/serie
       En Fase 5 se agregará "Citar este libro". -->
  <xsl:template name="emitir-col-left-libro">
    <aside class="col-left">

      <!-- TAPA DEL LIBRO -->
      <xsl:if test="$imagen_tapa != ''">
        <div class="tapa-wrapper">
          <img src="{$imagen_tapa}" alt="Cubierta de {$titulo_libro}"/>
        </div>
      </xsl:if>

      <!-- ISBN(s) -->
      <xsl:if test="$isbn_print != ''">
        <div class="meta-issn"><span class="meta-key">ISBN impreso: </span>
          <xsl:value-of select="$isbn_print"/>
        </div>
      </xsl:if>

      <xsl:if test="$isbn_electronic != ''">
        <div class="meta-issn"><span class="meta-key">ISBN electrónico: </span>
          <xsl:value-of select="$isbn_electronic"/>
        </div>
      </xsl:if>

      <!-- AUTORÍA -->
      <xsl:if test="$info/db:author | $info/author | $info/db:editor | $info/editor">
        <div class="meta-seccion">
          <div class="meta-label">Autoría</div>
          <xsl:for-each select="$info/db:author | $info/author">
            <div class="autor-item">
              <div class="autor-nombre-linea">
                <span class="autor-nombre">
                  <xsl:value-of select="normalize-space(db:personname/db:firstname | personname/firstname)"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="normalize-space(db:personname/db:surname | personname/surname)"/>
                </span>
                <xsl:variable name="orcid_url"
                              select="(db:uri[@type='orcid'] | uri[@type='orcid'])[1]"/>
                <xsl:if test="$orcid_url != ''">
                  <a class="autor-orcid" href="{$orcid_url}" target="_blank" rel="noopener noreferrer">ORCID ↗</a>
                </xsl:if>
              </div>
              <xsl:variable name="orgname"
                            select="(db:affiliation/db:orgname | affiliation/orgname)[1]"/>
              <xsl:if test="$orgname != ''">
                <div class="autor-afil">
                  <xsl:value-of select="normalize-space($orgname)"/>
                </div>
              </xsl:if>
            </div>
          </xsl:for-each>

          <xsl:for-each select="$info/db:editor | $info/editor">
            <div class="autor-item">
              <div class="autor-nombre-linea">
                <span class="autor-nombre">
                  <xsl:value-of select="normalize-space(db:personname/db:firstname | personname/firstname)"/>
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="normalize-space(db:personname/db:surname | personname/surname)"/>
                </span>
                <span class="autor-rol"> (ed.)</span>
              </div>
            </div>
          </xsl:for-each>
        </div>
      </xsl:if>

      <!-- PUBLICACIÓN -->
      <xsl:if test="$editorial != '' or $fecha_display != ''">
        <div class="meta-seccion">
          <div class="meta-label">Publicación</div>
          <div class="meta-valor">
            <xsl:if test="$fecha_display != ''">
              <xsl:value-of select="$fecha_display"/>
            </xsl:if>
            <xsl:if test="$fecha_display != '' and $editorial != ''">
              <xsl:text>. </xsl:text>
            </xsl:if>
            <xsl:if test="$editorial != ''">
              <xsl:value-of select="$editorial"/>
            </xsl:if>
            <xsl:if test="$ciudad_pub != ''">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="$ciudad_pub"/>
            </xsl:if>
            <xsl:if test="$pais_pub != ''">
              <xsl:text>, </xsl:text>
              <xsl:value-of select="$pais_pub"/>
            </xsl:if>
          </div>
        </div>
      </xsl:if>

      <!-- DOI -->
      <xsl:if test="$doi_libro != ''">
        <div class="meta-seccion">
          <div class="meta-valor"><span class="meta-key">DOI: </span>
            <a class="doi-link" href="https://doi.org/{$doi_libro}"
               target="_blank" rel="noopener noreferrer">
              <xsl:value-of select="$doi_libro"/>
            </a>
          </div>
        </div>
      </xsl:if>

      <!-- LICENCIA -->
      <xsl:if test="$licencia_texto != ''">
        <div class="meta-seccion">
          <div class="meta-label">Licencia</div>
          <xsl:choose>
            <xsl:when test="$licencia_url != ''">
              <a class="licencia-badge" href="{$licencia_url}"
                 target="_blank" rel="noopener noreferrer">
                <xsl:value-of select="$licencia_texto"/>
              </a>
            </xsl:when>
            <xsl:otherwise>
              <div class="meta-valor">
                <xsl:value-of select="$licencia_texto"/>
              </div>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </xsl:if>

      <!-- COLECCIÓN / SERIE -->
      <xsl:for-each select="$info/db:biblioset | $info/biblioset">
        <div class="meta-seccion">
          <div class="meta-label">
            <xsl:choose>
              <xsl:when test="@relation='series'">Colección</xsl:when>
              <xsl:when test="@relation='subseries'">Serie</xsl:when>
              <xsl:otherwise>Colección</xsl:otherwise>
            </xsl:choose>
          </div>
          <div class="meta-valor">
            <xsl:value-of select="normalize-space(db:title | title)"/>
            <xsl:if test="db:volumenum | volumenum">
              <xsl:text>, número </xsl:text>
              <xsl:value-of select="normalize-space(db:volumenum | volumenum)"/>
            </xsl:if>
          </div>
        </div>
      </xsl:for-each>

    </aside>
  </xsl:template>

  <!-- ==========================================================
       COL-CENTER PARA index.html
       ==========================================================
       Estructura:
         - Título + subtítulo
         - Autores (nombres visibles)
         - Resumen (si hay) + keywords (si hay)
         - Índice de contenidos (lista de capítulos con links)  -->
  <xsl:template name="emitir-col-center-index">
    <main class="col-center">

      <!-- Tipo (para el chip superior estilo revista) -->
      <div class="article-type-bar">Libro</div>

      <!-- Título del libro -->
      <h1 class="article-title">
        <xsl:value-of select="$titulo_libro"/>
      </h1>

      <!-- Subtítulo si tiene -->
      <xsl:if test="$subtitulo != ''">
        <div class="article-trans-title">
          <xsl:value-of select="$subtitulo"/>
        </div>
      </xsl:if>

      <!-- Autoría visible en el centro -->
      <xsl:if test="$info/db:author | $info/author | $info/db:editor | $info/editor">
        <div class="autoria-inline">
          <xsl:for-each select="$info/db:author | $info/author">
            <xsl:if test="position() &gt; 1">, </xsl:if>
            <xsl:value-of select="normalize-space(db:personname/db:firstname | personname/firstname)"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="normalize-space(db:personname/db:surname | personname/surname)"/>
          </xsl:for-each>
          <xsl:if test="($info/db:author | $info/author)
                    and ($info/db:editor | $info/editor)">
            <xsl:text> · </xsl:text>
          </xsl:if>
          <xsl:for-each select="$info/db:editor | $info/editor">
            <xsl:if test="position() &gt; 1">, </xsl:if>
            <xsl:value-of select="normalize-space(db:personname/db:firstname | personname/firstname)"/>
            <xsl:text> </xsl:text>
            <xsl:value-of select="normalize-space(db:personname/db:surname | personname/surname)"/>
            <xsl:text> (ed.)</xsl:text>
          </xsl:for-each>
        </div>
      </xsl:if>

      <div class="article-body">

        <!-- Resumen del libro (si tiene) -->
        <xsl:if test="$resumen_libro != ''">
          <section class="abstract-block">
            <h2>Resumen</h2>
            <p><xsl:value-of select="$resumen_libro"/></p>

            <!-- Keywords si tiene -->
            <xsl:variable name="keywords"
                          select="$info/db:keywordset/db:keyword | $info/keywordset/keyword"/>
            <xsl:if test="$keywords">
              <p class="keywords-line">
                <strong>Palabras clave: </strong>
                <xsl:for-each select="$keywords">
                  <xsl:if test="position() &gt; 1">, </xsl:if>
                  <xsl:value-of select="normalize-space(.)"/>
                </xsl:for-each>
              </p>
            </xsl:if>
          </section>
        </xsl:if>

        <!-- Índice de capítulos -->
        <section class="indice-capitulos">
          <h2>Contenido</h2>
          <ol class="lista-capitulos">
            <xsl:for-each select="$book/db:chapter
                                  | $book/db:preface
                                  | $book/db:appendix
                                  | $book/db:dedication
                                  | $book/db:colophon
                                  | $book/db:bibliography
                                  | $book/db:glossary
                                  | $book/chapter
                                  | $book/preface
                                  | $book/appendix
                                  | $book/dedication
                                  | $book/colophon
                                  | $book/bibliography
                                  | $book/glossary">

              <xsl:call-template name="emitir-item-capitulo">
                <xsl:with-param name="capitulo" select="."/>
              </xsl:call-template>
            </xsl:for-each>
          </ol>
        </section>

      </div>
    </main>
  </xsl:template>

  <!-- ==========================================================
       ITEM DE LA LISTA DE CAPÍTULOS
       ==========================================================
       Recibe el nodo <chapter>/<preface>/etc. del <book>.
       Mapea xml:id → nombre_archivo consultando el manifiesto
       con xsl:key ('cap-por-id').  -->
  <xsl:template name="emitir-item-capitulo">
    <xsl:param name="capitulo"/>

    <!-- xml:id del capítulo raíz (típicamente 'cap-N') -->
    <xsl:variable name="capId" select="$capitulo/@xml:id"/>

    <!-- Buscar en el manifiesto el <capitulo> con id que coincide -->
    <xsl:variable name="capManif"
                  select="key('cap-por-id', $capId, $manifiesto)"/>

    <xsl:variable name="nombreArchivo"
                  select="$capManif/@nombre_archivo"/>

    <!-- Título del capítulo (del <info>) -->
    <xsl:variable name="capTitulo"
                  select="normalize-space(
                    ($capitulo/db:info/db:title
                     | $capitulo/info/title)[1])"/>

    <!-- Etiqueta del tipo de capítulo (chapter, preface, appendix, etc.) -->
    <xsl:variable name="capTipo">
      <xsl:call-template name="etiqueta-tipo-capitulo">
        <xsl:with-param name="elemento" select="local-name($capitulo)"/>
      </xsl:call-template>
    </xsl:variable>

    <li class="item-capitulo">
      <xsl:choose>
        <xsl:when test="$nombreArchivo != ''">
          <a class="link-capitulo" href="h-{$nombreArchivo}.html">
            <span class="cap-tipo"><xsl:value-of select="$capTipo"/></span>
            <span class="cap-titulo"><xsl:value-of select="$capTitulo"/></span>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <!-- Fallback: nombre_archivo no encontrado en manifiesto,
               emitir texto sin enlace y comentario para debug -->
          <xsl:comment>
            <xsl:text>ADVERTENCIA: no se pudo resolver nombre_archivo para xml:id='</xsl:text>
            <xsl:value-of select="$capId"/>
            <xsl:text>'. Verificar manifiesto.</xsl:text>
          </xsl:comment>
          <span class="cap-tipo"><xsl:value-of select="$capTipo"/></span>
          <span class="cap-titulo"><xsl:value-of select="$capTitulo"/></span>
        </xsl:otherwise>
      </xsl:choose>
    </li>
  </xsl:template>

  <!-- ==========================================================
       MAPEO DE local-name() A ETIQUETA LEGIBLE PARA EL ÍNDICE
       ========================================================== -->
  <xsl:template name="etiqueta-tipo-capitulo">
    <xsl:param name="elemento" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$elemento = 'chapter'">Capítulo</xsl:when>
      <xsl:when test="$elemento = 'preface'">Prefacio</xsl:when>
      <xsl:when test="$elemento = 'appendix'">Apéndice</xsl:when>
      <xsl:when test="$elemento = 'dedication'">Dedicatoria</xsl:when>
      <xsl:when test="$elemento = 'colophon'">Colofón</xsl:when>
      <xsl:when test="$elemento = 'bibliography'">Bibliografía</xsl:when>
      <xsl:when test="$elemento = 'glossary'">Glosario</xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$elemento"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
