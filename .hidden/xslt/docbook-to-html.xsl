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

  <!-- ESTILO DE CITA: LO RESUELVE GAMBAS CON LeerTipoCSL() Y LO PASA COMO
       PARÁMETRO SAXON, IGUAL QUE EN REVISTAS. VALORES POSIBLES:
       'apa' | 'vancouver' | 'iso690' | 'ieee' | 'autor-anio' (fallback).
       DEFAULT 'apa' SI NO SE PASA (LIBROS ACADÉMICOS SUELEN USAR APA). -->
  <xsl:param name="estilo_cita" as="xs:string" select="'apa'"/>

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

  <!-- URLs DE DESCARGA (LIBRO COMPLETO): LAS EMITE GenerarInfoLibroXML
       COMO bibliomisc DESDE libros_md.url_descarga_pdf/epub. -->
  <xsl:variable name="url_descarga_pdf" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:bibliomisc[@role='url-descarga-pdf']
       | $info/bibliomisc[@role='url-descarga-pdf'])[1])"/>
  </xsl:variable>

  <xsl:variable name="url_descarga_epub" as="xs:string">
    <xsl:value-of select="normalize-space(
      ($info/db:bibliomisc[@role='url-descarga-epub']
       | $info/bibliomisc[@role='url-descarga-epub'])[1])"/>
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

  <!-- Año para CITACIÓN: prioriza el año de la fecha_completa (que refleja
       la última publicación, el objeto que se cita), y cae al pubdate sin
       role solo si no hay fecha completa. Un libro puede tener pubdate=2006
       (papel original) y fecha_completa=2026-07-04 (HTML/EPUB): se cita 2026. -->
  <xsl:variable name="anio_cita" as="xs:string">
    <xsl:choose>
      <xsl:when test="$fecha_completa != ''">
        <!-- EXTRAER LOS 4 DÍGITOS DEL AÑO DE UNA FECHA ISO YYYY-MM-DD -->
        <xsl:value-of select="substring($fecha_completa, 1, 4)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$anio_publicacion"/>
      </xsl:otherwise>
    </xsl:choose>
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
    <!-- 1. PORTADA DEL LIBRO -->
    <xsl:call-template name="emitir-index-html"/>

    <!-- 2. UNA PÁGINA POR CADA CAPÍTULO (Fase 2) -->
    <!-- xsl:result-document DENTRO DE xsl:for-each ES VÁLIDO EN SAXON.
         CADA CAPÍTULO GENERA UN docs/h-{nombre_archivo}.html. -->
    <!-- xsl:result-document DENTRO DE xsl:for-each ES VÁLIDO EN SAXON.
         SE RECORRE EL MANIFIESTO (NO LISTAS DE TIPOS DE ELEMENTO): ASÍ
         CADA CAPÍTULO DECLARADO GENERA SU PÁGINA, SEA CUAL SEA EL
         ELEMENTO DOCBOOK QUE LO REPRESENTE (chapter, preface,
         acknowledgements, appendix, etc.). FUENTE ÚNICA DE VERDAD,
         SINCRONIZADA CON EL ÍNDICE DE LA COLUMNA CENTRAL. -->
    <xsl:for-each select="$manifiesto//capitulo">
      <!-- RESOLVER EL NODO DEL CAPÍTULO EN EL CANÓNICO POR
           xml:id = concat('cap-', @id_capitulo). local-name() != ''
           EXCLUYE LOS ELEMENTOS QUE NO SEAN CAPÍTULOS DE PRIMER NIVEL. -->
      <xsl:variable name="capIdEsperado" select="concat('cap-', @id_capitulo)"/>
      <xsl:variable name="capNodo"
                    select="$book/*[@xml:id = $capIdEsperado]"/>
      <xsl:if test="$capNodo">
        <xsl:call-template name="emitir-capitulo-html">
          <xsl:with-param name="capitulo" select="$capNodo"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:for-each>
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
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
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
               INYECCIÓN DE citaData (Fase 5) + JS EXTERNO
               ========================================== -->
          <xsl:call-template name="emitir-citadata-libro"/>
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

    <xsl:if test="$anio_cita != ''">
      <meta name="citation_publication_date" content="{$anio_cita}"/>
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

    <xsl:if test="$anio_cita != ''">
      <meta name="DC.date" content="{$anio_cita}"/>
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

      <!-- ==========================================================
           BLOQUE DE IDENTIFICADORES: ISBN, eISBN, DOI, LICENCIA
           Van juntos tras la tapa. Rótulos en mayúscula con dos puntos
           (mismo patrón: meta-key negro + valor/enlace).
           ========================================================== -->

      <!-- ISBN (IMPRESO) -->
      <xsl:if test="$isbn_print != ''">
        <div class="meta-issn"><span class="meta-key">ISBN: </span>
          <xsl:value-of select="$isbn_print"/>
        </div>
      </xsl:if>

      <!-- eISBN (ELECTRÓNICO) -->
      <xsl:if test="$isbn_electronic != ''">
        <div class="meta-issn"><span class="meta-key">eISBN: </span>
          <xsl:value-of select="$isbn_electronic"/>
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

      <!-- LICENCIA (mismo patrón que DOI: meta-key inline + link, MAYÚSCULA) -->
      <xsl:if test="$licencia_texto != ''">
        <div class="meta-seccion">
          <div class="meta-valor"><span class="meta-key">LICENCIA: </span>
            <xsl:choose>
              <xsl:when test="$licencia_url != ''">
                <a class="licencia-link" href="{$licencia_url}"
                   target="_blank" rel="noopener noreferrer">
                  <xsl:value-of select="$licencia_texto"/>
                </a>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$licencia_texto"/>
              </xsl:otherwise>
            </xsl:choose>
          </div>
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

      <!-- BOTONES DE DESCARGA (LIBRO COMPLETO): PDF Y EPUB.
           SOLO EN EL INDEX. CADA BOTÓN APARECE SI SU URL EXISTE. -->
      <xsl:if test="$url_descarga_pdf != '' or $url_descarga_epub != ''">
        <div class="meta-seccion descarga-libro-wrapper">
          <xsl:if test="$url_descarga_pdf != ''">
            <a class="btn-descargar-pdf" href="{$url_descarga_pdf}"
               target="_blank" rel="noopener noreferrer">
              <xsl:text>Descargar PDF</xsl:text>
            </a>
          </xsl:if>
          <xsl:if test="$url_descarga_epub != ''">
            <a class="btn-descargar-epub" href="{$url_descarga_epub}"
               target="_blank" rel="noopener noreferrer">
              <xsl:text>Descargar EPUB</xsl:text>
            </a>
          </xsl:if>
        </div>
      </xsl:if>

      <!-- WIDGET "CÓMO CITAR" (FASE 5) -->
      <xsl:call-template name="emitir-widget-citar"/>

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

      <!-- Autoría visible en el centro (nombre enlaza al ORCID si existe) -->
      <xsl:if test="$info/db:author | $info/author | $info/db:editor | $info/editor">
        <div class="autoria-inline">
          <xsl:for-each select="$info/db:author | $info/author">
            <xsl:if test="position() &gt; 1">, </xsl:if>
            <xsl:call-template name="emitir-nombre-autor">
              <xsl:with-param name="persona" select="."/>
            </xsl:call-template>
          </xsl:for-each>
          <xsl:if test="($info/db:author | $info/author)
                    and ($info/db:editor | $info/editor)">
            <xsl:text> · </xsl:text>
          </xsl:if>
          <xsl:for-each select="$info/db:editor | $info/editor">
            <xsl:if test="position() &gt; 1">, </xsl:if>
            <xsl:call-template name="emitir-nombre-autor">
              <xsl:with-param name="persona" select="."/>
            </xsl:call-template>
            <xsl:text> (ed.)</xsl:text>
          </xsl:for-each>
        </div>
      </xsl:if>

      <div class="article-body">

        <!-- ==========================================================
             RESUMEN DEL LIBRO (desplegable, patrón del artículo)
             ==========================================================
             <details>/<summary> igual que el abstract de revistas:
             "Resumen" como etiqueta chica en sans con la flecha nativa
             del <details>; texto y palabras clave dentro. -->
        <xsl:if test="$resumen_libro != ''">
          <div class="abstracts-wrapper">
            <details class="abstract-block" open="open">
              <summary class="abstract-lang-label">Resumen</summary>
              <div class="abstract-texto">
                <p><xsl:value-of select="$resumen_libro"/></p>
              </div>
              <!-- PALABRAS CLAVE -->
              <xsl:variable name="keywords"
                            select="$info/db:keywordset/db:keyword | $info/keywordset/keyword"/>
              <xsl:if test="$keywords">
                <p class="abstract-keywords">
                  <strong>Palabras clave: </strong>
                  <xsl:for-each select="$keywords">
                    <xsl:if test="position() &gt; 1">, </xsl:if>
                    <xsl:value-of select="normalize-space(.)"/>
                  </xsl:for-each>
                </p>
              </xsl:if>
            </details>
          </div>
        </xsl:if>

        <!-- ==========================================================
             ÍNDICE POR PARTES ESTRUCTURALES
             ==========================================================
             Los capítulos se agrupan en 3 partes estructurales según
             el PREFIJO del nombre_archivo del manifiesto:
               fm-  → Preliminares
               a-   → Cuerpo principal (ÚNICO CON NUMERACIÓN)
               bm-  → Material complementario
             El manifiesto ya trae las entradas en orden de lectura.
             Cada parte se muestra solo si tiene capítulos. -->
        <section class="indice-capitulos">

          <!-- PRELIMINARES (fm-) -->
          <xsl:variable name="caps_fm"
                        select="$manifiesto//capitulo[starts-with(@nombre_archivo, 'fm-')]"/>
          <xsl:if test="$caps_fm">
            <div class="parte-estructural">
              <h3 class="parte-titulo">Preliminares</h3>
              <ul class="lista-capitulos">
                <xsl:for-each select="$caps_fm">
                  <xsl:call-template name="emitir-item-parte">
                    <xsl:with-param name="capManif" select="."/>
                    <xsl:with-param name="numero" select="''"/>
                  </xsl:call-template>
                </xsl:for-each>
              </ul>
            </div>
          </xsl:if>

          <!-- CUERPO PRINCIPAL (a-) — CON NUMERACIÓN -->
          <xsl:variable name="caps_a"
                        select="$manifiesto//capitulo[starts-with(@nombre_archivo, 'a-')]"/>
          <xsl:if test="$caps_a">
            <div class="parte-estructural">
              <h3 class="parte-titulo">Cuerpo principal</h3>
              <ol class="lista-capitulos lista-numerada">
                <xsl:for-each select="$caps_a">
                  <xsl:call-template name="emitir-item-parte">
                    <xsl:with-param name="capManif" select="."/>
                    <xsl:with-param name="numero" select="string(position())"/>
                  </xsl:call-template>
                </xsl:for-each>
              </ol>
            </div>
          </xsl:if>

          <!-- MATERIAL COMPLEMENTARIO (bm-) -->
          <xsl:variable name="caps_bm"
                        select="$manifiesto//capitulo[starts-with(@nombre_archivo, 'bm-')]"/>
          <xsl:if test="$caps_bm">
            <div class="parte-estructural">
              <h3 class="parte-titulo">Material complementario</h3>
              <ul class="lista-capitulos">
                <xsl:for-each select="$caps_bm">
                  <xsl:call-template name="emitir-item-parte">
                    <xsl:with-param name="capManif" select="."/>
                    <xsl:with-param name="numero" select="''"/>
                  </xsl:call-template>
                </xsl:for-each>
              </ul>
            </div>
          </xsl:if>

        </section>

      </div>
    </main>
  </xsl:template>

  <!-- ==========================================================
       PARTE ESTRUCTURAL A PARTIR DEL nombre_archivo
       ==========================================================
       Deriva la parte estructural del PREFIJO del nombre_archivo:
         fm-  → Preliminares
         a-   → Cuerpo principal
         bm-  → Material complementario
       Es la misma clasificación que usa el índice de la portada. -->
  <xsl:template name="parte-estructural-de">
    <xsl:param name="nombreArchivo"/>
    <xsl:choose>
      <xsl:when test="starts-with($nombreArchivo, 'fm-')">Preliminares</xsl:when>
      <xsl:when test="starts-with($nombreArchivo, 'a-')">Cuerpo principal</xsl:when>
      <xsl:when test="starts-with($nombreArchivo, 'bm-')">Material complementario</xsl:when>
      <xsl:otherwise>Cuerpo principal</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       NOMBRE DE AUTOR/EDITOR CON ENLACE AL ORCID (SI EXISTE)
       ==========================================================
       Emite "Nombre Apellido". Si el <author>/<editor> tiene
       <uri type="orcid">, el nombre se envuelve en un enlace a esa
       URL (sin escribir la palabra ORCID). Sin ORCID, texto plano. -->
  <xsl:template name="emitir-nombre-autor">
    <xsl:param name="persona"/>
    <xsl:variable name="nombreCompleto"
                  select="concat(
                    normalize-space($persona/db:personname/db:firstname | $persona/personname/firstname),
                    ' ',
                    normalize-space($persona/db:personname/db:surname | $persona/personname/surname))"/>
    <xsl:variable name="orcid"
                  select="normalize-space(
                    ($persona/db:uri[@type='orcid'] | $persona/uri[@type='orcid'])[1])"/>
    <xsl:choose>
      <xsl:when test="$orcid != ''">
        <a class="autor-orcid-link" href="{$orcid}"
           target="_blank" rel="noopener noreferrer">
          <xsl:value-of select="$nombreCompleto"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$nombreCompleto"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       ITEM DE UNA PARTE ESTRUCTURAL DEL ÍNDICE
       ==========================================================
       Recibe la entrada <capitulo> del manifiesto y el número
       (posición dentro del Cuerpo principal, o '' si no numera).
       Resuelve el título yendo al capítulo del canónico por
       xml:id = concat('cap-', @id_capitulo). Solo muestra el
       título (sin etiqueta de tipo). -->
  <xsl:template name="emitir-item-parte">
    <xsl:param name="capManif"/>
    <xsl:param name="numero" as="xs:string" select="''"/>

    <xsl:variable name="nombreArchivo" select="$capManif/@nombre_archivo"/>
    <xsl:variable name="capIdEsperado" select="concat('cap-', $capManif/@id_capitulo)"/>

    <!-- BUSCAR EL CAPÍTULO EN EL CANÓNICO PARA SACAR EL TÍTULO -->
    <xsl:variable name="capNodo"
                  select="($book/db:chapter | $book/chapter
                         | $book/db:preface | $book/preface
                         | $book/db:acknowledgements | $book/acknowledgements
                         | $book/db:appendix | $book/appendix
                         | $book/db:dedication | $book/dedication
                         | $book/db:colophon | $book/colophon
                         | $book/db:glossary | $book/glossary)
                         [@xml:id = $capIdEsperado]"/>

    <xsl:variable name="capTitulo"
                  select="normalize-space(
                    ($capNodo/db:info/db:title | $capNodo/info/title)[1])"/>

    <li class="item-capitulo">
      <a class="link-capitulo" href="h-{$nombreArchivo}.html">
        <xsl:if test="$numero != ''">
          <span class="cap-numero"><xsl:value-of select="$numero"/></span>
        </xsl:if>
        <span class="cap-titulo"><xsl:value-of select="$capTitulo"/></span>
      </a>
    </li>
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

  <!-- ==========================================================
       ============ FASE 2: PÁGINAS DE CAPÍTULO ================
       ========================================================== -->

  <!-- ==========================================================
       TEMPLATE: EMITIR h-{nombre_archivo}.html DE UN CAPÍTULO
       ==========================================================
       Layout de 3 columnas (col-left híbrida + col-center + drawer).
       El drawer (col-right) se arma estructuralmente pero vacío;
       se puebla en Fase 3 con notas/referencias/figuras. -->
  <xsl:template name="emitir-capitulo-html">
    <xsl:param name="capitulo"/>

    <!-- RESOLVER nombre_archivo VÍA MANIFIESTO -->
    <xsl:variable name="capId" select="$capitulo/@xml:id"/>
    <xsl:variable name="capManif" select="key('cap-por-id', $capId, $manifiesto)"/>
    <xsl:variable name="nombreArchivo" select="$capManif/@nombre_archivo"/>

    <!-- SI NO SE RESUELVE EL NOMBRE, NO GENERAR ARCHIVO (SE AVISA EN COMENTARIO) -->
    <xsl:choose>
      <xsl:when test="$nombreArchivo != ''">

        <xsl:variable name="capInfo" select="$capitulo/db:info | $capitulo/info"/>
        <xsl:variable name="capTitulo"
                      select="normalize-space(($capInfo/db:title | $capInfo/title)[1])"/>

        <xsl:result-document href="docs/h-{$nombreArchivo}.html" format="html5">
          <html lang="{$idioma_principal}">
            <head>
              <meta charset="UTF-8"/>
              <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
              <title>
                <xsl:value-of select="$capTitulo"/>
                <xsl:text> — </xsl:text>
                <xsl:value-of select="$titulo_libro"/>
              </title>

              <xsl:call-template name="emitir-metadatos-capitulo">
                <xsl:with-param name="capitulo" select="$capitulo"/>
                <xsl:with-param name="capInfo" select="$capInfo"/>
                <xsl:with-param name="capTitulo" select="$capTitulo"/>
              </xsl:call-template>

              <link rel="preconnect" href="https://fonts.googleapis.com"/>
              <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
              <link rel="stylesheet"
                    href="https://fonts.googleapis.com/css2?family=Noto+Serif:ital,wght@0,400;0,600;1,400;1,600&amp;family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,600;1,300;1,400;1,600&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap"/>
              <link rel="stylesheet" href="assets/css/gbpublisher.css"/>
            </head>

            <body class="pagina-libro-capitulo">

              <!-- BOTÓN MOSTRAR/OCULTAR PANEL DERECHO (IGUAL QUE REVISTAS) -->
              <button class="panel-toggle" id="panelToggle" onclick="togglePanel()">
                <xsl:text>&#x2192; Mostrar panel</xsl:text>
              </button>

              <!-- FABS PARA TABLET/MÓVIL -->
              <button class="fab-meta" onclick="openDrawerMeta()">&#x2261;</button>
              <button class="fab-panel-tablet" onclick="openDrawerPanel()">&#x2192;</button>
              <div class="drawer-backdrop" id="drawerBackdrop" onclick="closeDrawers()"></div>

              <div class="layout layout-3col panel-hidden" id="mainLayout">
                <xsl:call-template name="emitir-col-left-capitulo">
                  <xsl:with-param name="capInfo" select="$capInfo"/>
                  <xsl:with-param name="capTitulo" select="$capTitulo"/>
                </xsl:call-template>

                <xsl:call-template name="emitir-col-center-capitulo">
                  <xsl:with-param name="capitulo" select="$capitulo"/>
                  <xsl:with-param name="capInfo" select="$capInfo"/>
                  <xsl:with-param name="capTitulo" select="$capTitulo"/>
                </xsl:call-template>

                <xsl:call-template name="emitir-col-right-drawer">
                  <xsl:with-param name="capitulo" select="$capitulo"/>
                </xsl:call-template>
              </div>

              <!-- INYECCIÓN DE citaData (Fase 5) ANTES DEL JS EXTERNO -->
              <xsl:call-template name="emitir-citadata-capitulo">
                <xsl:with-param name="capInfo" select="$capInfo"/>
                <xsl:with-param name="capTitulo" select="$capTitulo"/>
              </xsl:call-template>

              <!-- JS EXTERNO COMPARTIDO -->
              <script src="assets/js/gbpublisher.js"></script>
            </body>
          </html>
        </xsl:result-document>

      </xsl:when>
      <xsl:otherwise>
        <xsl:message>
          <xsl:text>ADVERTENCIA: no se pudo resolver nombre_archivo para xml:id='</xsl:text>
          <xsl:value-of select="$capId"/>
          <xsl:text>'. Capítulo omitido del HTML.</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       COL-LEFT DE CAPÍTULO (HÍBRIDA LIBRO + CAPÍTULO)
       ==========================================================
       - Tapa del libro (heredada, constante entre capítulos)
       - Datos del capítulo: autores con afiliación/ORCID, licencia
       - Placeholder "Descargar capítulo (PDF)"
       - Placeholder "Cómo citar" (Fase 5)
       - Enlace de vuelta al índice del libro -->
  <xsl:template name="emitir-col-left-capitulo">
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>

    <aside class="col-left">

      <!-- BOTÓN "IR AL INICIO" (vuelve al index del libro).
           Mismo tratamiento que el botón Descargar EPUB: fondo blanco,
           texto azul, semibold. -->
      <a href="index.html" class="btn-ir-inicio">
        <xsl:text>Ir al inicio</xsl:text>
      </a>

      <!-- TAPA DEL LIBRO -->
      <xsl:if test="$imagen_tapa != ''">
        <div class="tapa-wrapper">
          <img src="{$imagen_tapa}" alt="Cubierta de {$titulo_libro}"/>
        </div>
      </xsl:if>

      <!-- BOTÓN "DESCARGAR PDF" DEL CAPÍTULO.
           Lee la URL de descarga del PDF del capítulo desde el canónico
           (bibliomisc role="url-descarga-pdf-capitulo"), que provendrá de
           un campo del formulario de capítulos (aún no implementado).
           El botón aparece SOLO si la URL existe. Mismo estilo que EPUB. -->
      <xsl:variable name="capUrlPdf"
                    select="normalize-space(
                      ($capInfo/db:bibliomisc[@role='url-descarga-pdf-capitulo']
                       | $capInfo/bibliomisc[@role='url-descarga-pdf-capitulo'])[1])"/>
      <xsl:if test="$capUrlPdf != ''">
        <a class="btn-descargar-pdf" href="{$capUrlPdf}"
           target="_blank" rel="noopener noreferrer">
          <xsl:text>Descargar PDF</xsl:text>
        </a>
      </xsl:if>

      <!-- WIDGET "CÓMO CITAR" (FASE 5) -->
      <xsl:call-template name="emitir-widget-citar"/>

    </aside>
  </xsl:template>

  <!-- ==========================================================
       COL-CENTER DE CAPÍTULO
       ==========================================================
       - Título del capítulo + autores inline
       - Resúmenes (uno por idioma) si existen
       - Keywords si existen
       - Cuerpo del capítulo (apply-templates sobre el contenido) -->
  <xsl:template name="emitir-col-center-capitulo">
    <xsl:param name="capitulo"/>
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>

    <main class="col-center">

      <!-- BARRA SUPERIOR: PARTE ESTRUCTURAL (Preliminares / Cuerpo
           principal / Material complementario), derivada del prefijo
           del nombre_archivo del capítulo (resuelto vía manifiesto). -->
      <xsl:variable name="capIdBarra" select="$capitulo/@xml:id"/>
      <xsl:variable name="capManifBarra"
                    select="key('cap-por-id', $capIdBarra, $manifiesto)"/>
      <div class="article-type-bar">
        <xsl:call-template name="parte-estructural-de">
          <xsl:with-param name="nombreArchivo" select="$capManifBarra/@nombre_archivo"/>
        </xsl:call-template>
      </div>

      <!-- TÍTULO DEL CAPÍTULO -->
      <h1 class="article-title">
        <xsl:value-of select="$capTitulo"/>
      </h1>

      <!-- SUBTÍTULO SI TIENE -->
      <xsl:variable name="capSubtitulo"
                    select="normalize-space(($capInfo/db:subtitle | $capInfo/subtitle)[1])"/>
      <xsl:if test="$capSubtitulo != ''">
        <div class="article-trans-title">
          <xsl:value-of select="$capSubtitulo"/>
        </div>
      </xsl:if>

      <!-- AUTORÍA INLINE (nombre enlaza al ORCID si existe) -->
      <xsl:if test="$capInfo/db:author | $capInfo/author">
        <div class="autoria-inline">
          <xsl:for-each select="$capInfo/db:author | $capInfo/author">
            <xsl:if test="position() &gt; 1">, </xsl:if>
            <xsl:call-template name="emitir-nombre-autor">
              <xsl:with-param name="persona" select="."/>
            </xsl:call-template>
          </xsl:for-each>
        </div>
      </xsl:if>

      <div class="article-body">

        <!-- ==========================================================
             RESUMEN(ES) DEL CAPÍTULO (desplegable, patrón del index)
             ==========================================================
             <details>/<summary> igual que la portada y las revistas.
             Uno por idioma. Las palabras clave del mismo idioma se
             incluyen dentro del <details> correspondiente. -->
        <xsl:if test="$capInfo/db:abstract | $capInfo/abstract">
          <div class="abstracts-wrapper">
            <xsl:for-each select="$capInfo/db:abstract | $capInfo/abstract">
              <details class="abstract-block" open="open">
                <summary class="abstract-lang-label">
                  <xsl:text>Resumen</xsl:text>
                  <xsl:if test="@xml:lang">
                    <xsl:text> (</xsl:text><xsl:value-of select="@xml:lang"/><xsl:text>)</xsl:text>
                  </xsl:if>
                </summary>
                <div class="abstract-texto">
                  <xsl:for-each select="db:para | para">
                    <p><xsl:value-of select="normalize-space(.)"/></p>
                  </xsl:for-each>
                </div>
                <!-- PALABRAS CLAVE DEL MISMO IDIOMA (si hay keywordset con
                     el mismo xml:lang, o el único keywordset si no hay lang) -->
                <xsl:variable name="lang" select="@xml:lang"/>
                <xsl:variable name="kws"
                              select="../db:keywordset[not(@xml:lang) or @xml:lang = $lang]/db:keyword
                                    | ../keywordset[not(@xml:lang) or @xml:lang = $lang]/keyword"/>
                <xsl:if test="$kws">
                  <p class="abstract-keywords">
                    <strong>Palabras clave: </strong>
                    <xsl:for-each select="$kws">
                      <xsl:if test="position() &gt; 1">, </xsl:if>
                      <xsl:value-of select="normalize-space(.)"/>
                    </xsl:for-each>
                  </p>
                </xsl:if>
              </details>
            </xsl:for-each>
          </div>
        </xsl:if>

        <!-- CUERPO DEL CAPÍTULO -->
        <!-- SE APLICAN TEMPLATES SOBRE TODO EL CONTENIDO EXCEPTO <info> Y
             <bibliography> (ESTA ÚLTIMA VA AL DRAWER EN FASE 3, NO AL CUERPO) -->
        <xsl:apply-templates select="$capitulo/*[not(local-name() = 'info')
                                                 and not(local-name() = 'bibliography')]"/>

      </div>
    </main>
  </xsl:template>

  <!-- ==========================================================
       COL-RIGHT: DRAWER CON 3 PESTAÑAS (Fase 3)
       ==========================================================
       Usa las clases reales de revistas (panel-tab, panel-section,
       switchTab, contadores) para reutilizar el CSS de gbpublisher.css.
       - Notas y Figuras: construidas por JS en runtime desde las
         marcas del cuerpo (.nota-ref / .fig-wrapper).
       - Referencias: renderizadas por el XSLT desde <bibliography>. -->
  <xsl:template name="emitir-col-right-drawer">
    <xsl:param name="capitulo"/>

    <aside class="col-right" id="rightPanel">

      <div class="panel-tabs">
        <button class="panel-tab active" id="tab-notas" onclick="switchTab('notas')">
          <xsl:text>Notas </xsl:text>
          <span class="tab-count" id="count-notas">0</span>
        </button>
        <button class="panel-tab" id="tab-refs" onclick="switchTab('refs')">
          <xsl:text>Referencias </xsl:text>
          <span class="tab-count" id="count-refs">0</span>
        </button>
        <button class="panel-tab" id="tab-figs" onclick="switchTab('figs')">
          <xsl:text>Figuras </xsl:text>
          <span class="tab-count" id="count-figs">0</span>
        </button>
      </div>

      <div class="panel-content">

        <!-- SECCIÓN NOTAS: CONSTRUIDA POR JS (buildNotesPanel) -->
        <div class="panel-section active" id="panel-notas"></div>

        <!-- SECCIÓN REFERENCIAS: RENDERIZADA POR EL XSLT -->
        <div class="panel-section" id="panel-refs">
          <!-- FUENTE DE LA BIBLIOGRAFÍA DEL DRAWER:
               - por_capitulo: cada capítulo tiene su <bibliography> propia.
               - consolidada: el capítulo NO tiene bibliografía; se usa la
                 <bibliography> única del final del <book>, idéntica en todas
                 las páginas. La numeración sale corrida por su posición en
                 esa lista única.
               Se detecta sin parámetro de modelo: si el capítulo tiene
               bibliografía propia, se usa; si no, la consolidada del book. -->
          <xsl:variable name="biblioCap"
                        select="$capitulo/db:bibliography | $capitulo/bibliography"/>
          <xsl:variable name="biblio"
                        select="if ($biblioCap/db:biblioentry | $biblioCap/biblioentry)
                                then $biblioCap
                                else ($book/db:bibliography | $book/bibliography)"/>
          <xsl:choose>
            <xsl:when test="$biblio/db:biblioentry | $biblio/biblioentry">
              <xsl:apply-templates select="$biblio/db:biblioentry | $biblio/biblioentry"
                                    mode="panel-ref"/>
            </xsl:when>
            <xsl:otherwise>
              <p class="drawer-vacio">Sin referencias.</p>
            </xsl:otherwise>
          </xsl:choose>
        </div>

        <!-- SECCIÓN FIGURAS: CONSTRUIDA POR JS (buildFigsPanel) -->
        <div class="panel-section" id="panel-figs"></div>

      </div>

    </aside>
  </xsl:template>

  <!-- ==========================================================
       ========== TEMPLATES DEL CUERPO DEL CAPÍTULO ============
       ==========================================================
       Vocabulario DocBook 5.2 → HTML. Namespace db: para los
       nodos cargados del canónico. -->

  <!-- SECTION → nivel de heading según profundidad de anidamiento -->
  <xsl:template match="db:section | section">
    <xsl:variable name="nivel" select="count(ancestor::db:section | ancestor::section) + 2"/>
    <section class="cap-section" id="{@xml:id}">
      <xsl:variable name="tituloSec"
                    select="normalize-space((db:title | title)[1])"/>
      <xsl:if test="$tituloSec != ''">
        <xsl:element name="h{if ($nivel &gt; 6) then 6 else $nivel}">
          <xsl:value-of select="$tituloSec"/>
        </xsl:element>
      </xsl:if>
      <!-- CONTENIDO DE LA SECCIÓN, EXCEPTO SU PROPIO TÍTULO -->
      <xsl:apply-templates select="*[not(local-name() = 'title')]"/>
    </section>
  </xsl:template>

  <!-- PARA → P -->
  <xsl:template match="db:para | para">
    <p>
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- ORDEREDLIST → OL (ANIDABLE) -->
  <xsl:template match="db:orderedlist | orderedlist">
    <ol>
      <xsl:apply-templates select="db:listitem | listitem"/>
    </ol>
  </xsl:template>

  <!-- ITEMIZEDLIST → UL (ANIDABLE) -->
  <xsl:template match="db:itemizedlist | itemizedlist">
    <ul>
      <xsl:apply-templates select="db:listitem | listitem"/>
    </ul>
  </xsl:template>

  <!-- LISTITEM → LI -->
  <xsl:template match="db:listitem | listitem">
    <li>
      <!-- SI EL LISTITEM TIENE UN SOLO PARA, DESENVOLVERLO PARA EVITAR
           <li><p>...</p></li> INNECESARIO. SI TIENE MÁS DE UN HIJO O
           SUBLISTAS, APLICAR TEMPLATES NORMALMENTE. -->
      <xsl:choose>
        <xsl:when test="count(*) = 1 and (db:para | para)">
          <xsl:apply-templates select="(db:para | para)/node()"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </li>
  </xsl:template>

  <!-- FIGURE / INFORMALFIGURE → .fig-wrapper CON data-fig-id.
       EL JS (buildFigsPanel) LEE ESTAS MARCAS PARA CONSTRUIR EL
       PANEL DE FIGURAS Y CABLEAR LA NAVEGACIÓN CRUZADA.
       LA NUMERACIÓN ES CORRELATIVA POR CAPÍTULO. -->
  <xsl:template match="db:figure | figure | db:informalfigure | informalfigure">
    <xsl:variable name="num">
      <xsl:number count="db:figure | figure | db:informalfigure | informalfigure"
                  from="db:chapter | db:preface | db:appendix | db:dedication
                        | db:colophon | db:glossary
                        | chapter | preface | appendix | dedication
                        | colophon | glossary"
                  level="any"/>
    </xsl:variable>
    <xsl:variable name="figId" select="if (@xml:id) then @xml:id else concat('fig-', $num)"/>
    <xsl:variable name="imgdata"
                  select="(db:mediaobject/db:imageobject/db:imagedata
                          | mediaobject/imageobject/imagedata)[1]"/>
    <xsl:variable name="fileref" select="$imgdata/@fileref"/>
    <xsl:variable name="titulo"
                  select="normalize-space((db:title | title)[1])"/>

    <figure class="fig-wrapper"
            id="{$figId}"
            data-fig-id="{$figId}"
            onclick="highlightPanel('figs','{$figId}')"
            style="cursor:pointer">
      <xsl:if test="$fileref != ''">
        <!-- LA IMAGEN VIVE EN media/; EN docs/ VA A assets/media/ -->
        <img src="assets/media/{tokenize($fileref, '/')[last()]}"
             alt="{$titulo}"/>
      </xsl:if>
      <figcaption class="fig-caption">
        <span class="fig-label">Figura <xsl:value-of select="$num"/></span>
        <!-- EL TÍTULO SE RENDERIZA CON apply-templates (NO value-of) PARA
             QUE LOS biblioref DEL CAPTION SE RESUELVAN COMO REFERENCIA
             VISIBLE "(Autor, año)" EN LUGAR DE PERDERSE. -->
        <xsl:if test="normalize-space((db:title | title)[1]) != ''">
          <xsl:text>. </xsl:text>
          <xsl:apply-templates select="(db:title | title)[1]/node()"/>
        </xsl:if>
      </figcaption>
    </figure>
  </xsl:template>

  <!-- CITA DE FUENTE (blockquote role="source") → cita documental
       con la procedencia (attribution) al pie. Se distingue de la
       cita en bloque común por el role y la atribución. -->
  <xsl:template match="db:blockquote[@role='source'] | blockquote[@role='source']">
    <div class="cita-fuente">
      <xsl:for-each select="db:para | para">
        <p class="cita-fuente-texto"><xsl:apply-templates/></p>
      </xsl:for-each>
      <xsl:if test="db:attribution | attribution">
        <p class="cita-fuente-proc">
          <xsl:value-of select="normalize-space((db:attribution | attribution)[1])"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- BLOCKQUOTE → BLOCKQUOTE -->
  <xsl:template match="db:blockquote | blockquote">
    <blockquote>
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <!-- ==========================================================
       TABLA (informaltable / table) → HTML <table>
       ==========================================================
       Modelo CALS de DocBook: tgroup > (thead|tbody) > row > entry.
       - entry en thead → <th>; en tbody → <td>.
       - La alineación de cada columna viene de colspec/@align (por
         posición). Se resuelve por el índice de la celda.
       - Si hay <title> (tabla formal), se emite como <caption>. -->
  <xsl:template match="db:table | table | db:informaltable | informaltable">
    <div class="tabla-wrapper">
      <table class="tabla-datos">
        <xsl:variable name="titulo" select="normalize-space((db:title | title)[1])"/>
        <xsl:if test="$titulo != ''">
          <caption><xsl:value-of select="$titulo"/></caption>
        </xsl:if>
        <!-- ALINEACIONES POR COLUMNA (de los colspec del tgroup) -->
        <xsl:variable name="aligns"
                      select="(db:tgroup | tgroup)[1]/(db:colspec | colspec)/@align"/>
        <xsl:for-each select="(db:tgroup | tgroup)[1]/(db:thead | thead)">
          <thead>
            <xsl:for-each select="db:row | row">
              <tr>
                <xsl:for-each select="db:entry | entry">
                  <xsl:variable name="pos" select="position()"/>
                  <th>
                    <xsl:if test="$aligns[$pos]">
                      <xsl:attribute name="style">
                        <xsl:text>text-align: </xsl:text>
                        <xsl:value-of select="$aligns[$pos]"/>
                      </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates/>
                  </th>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
          </thead>
        </xsl:for-each>
        <xsl:for-each select="(db:tgroup | tgroup)[1]/(db:tbody | tbody)">
          <tbody>
            <xsl:for-each select="db:row | row">
              <tr>
                <xsl:for-each select="db:entry | entry">
                  <xsl:variable name="pos" select="position()"/>
                  <td>
                    <xsl:if test="$aligns[$pos]">
                      <xsl:attribute name="style">
                        <xsl:text>text-align: </xsl:text>
                        <xsl:value-of select="$aligns[$pos]"/>
                      </xsl:attribute>
                    </xsl:if>
                    <xsl:apply-templates/>
                  </td>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
          </tbody>
        </xsl:for-each>
      </table>
    </div>
  </xsl:template>

  <!-- CÓDIGO EN BLOQUE (programlisting) → <pre><code>.
       El atributo language se traslada como clase (para un futuro
       resaltador de sintaxis tipo highlight.js). -->
  <xsl:template match="db:programlisting | programlisting">
    <pre class="code-block">
      <code>
        <xsl:if test="@language">
          <xsl:attribute name="class">
            <xsl:text>language-</xsl:text><xsl:value-of select="@language"/>
          </xsl:attribute>
        </xsl:if>
        <xsl:value-of select="."/>
      </code>
    </pre>
  </xsl:template>

  <!-- CÓDIGO INLINE (literal) → <code> -->
  <xsl:template match="db:literal | literal">
    <code class="code-inline"><xsl:apply-templates/></code>
  </xsl:template>

  <!-- LISTA DE DEFINICIÓN (variablelist) → <dl>.
       varlistentry > term → <dt>; varlistentry > listitem → <dd>. -->
  <xsl:template match="db:variablelist | variablelist">
    <dl class="lista-definicion">
      <xsl:for-each select="db:varlistentry | varlistentry">
        <xsl:for-each select="db:term | term">
          <dt><xsl:apply-templates/></dt>
        </xsl:for-each>
        <xsl:for-each select="db:listitem | listitem">
          <dd>
            <!-- SI EL listitem TIENE UN SOLO para, DESENVOLVERLO -->
            <xsl:choose>
              <xsl:when test="count(*) = 1 and (db:para | para)">
                <xsl:apply-templates select="(db:para | para)/node()"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:apply-templates/>
              </xsl:otherwise>
            </xsl:choose>
          </dd>
        </xsl:for-each>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <!-- ==========================================================
       EPÍGRAFE (epigraph) → cita al inicio con atribución
       ==========================================================
       Estructura DocBook: <epigraph><attribution>...</attribution>
       <para>...</para></epigraph>. La atribución va al pie, alineada
       a la derecha. -->
  <xsl:template match="db:epigraph | epigraph">
    <div class="epigrafe">
      <xsl:for-each select="db:para | para">
        <p class="epigrafe-texto"><xsl:apply-templates/></p>
      </xsl:for-each>
      <xsl:if test="db:attribution | attribution">
        <p class="epigrafe-atrib">
          <xsl:text>— </xsl:text>
          <xsl:value-of select="normalize-space((db:attribution | attribution)[1])"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- ==========================================================
       ALERTAS / RECUADROS (admonitions + sidebar)
       ==========================================================
       El shortcode ::: {.box type="X"} mapea (vía filtro Lua) a:
         - type="info"      → <sidebar role="info">
         - type="warning"   → <warning>
         - type="note"      → <note>
         - type="tip"       → <tip>
         - type="important" → <important>
         - type="caution"   → <caution>
       Cada uno se emite como .alerta con una clase de tipo que
       controla color e icono. Un template auxiliar unifica la
       estructura (icono a la izquierda, contenido a la derecha). -->
  <xsl:template match="db:note | note">
    <xsl:call-template name="emitir-alerta">
      <xsl:with-param name="tipo" select="'note'"/>
      <xsl:with-param name="etiqueta" select="'Nota'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:tip | tip">
    <xsl:call-template name="emitir-alerta">
      <xsl:with-param name="tipo" select="'tip'"/>
      <xsl:with-param name="etiqueta" select="'Sugerencia'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:important | important">
    <xsl:call-template name="emitir-alerta">
      <xsl:with-param name="tipo" select="'important'"/>
      <xsl:with-param name="etiqueta" select="'Importante'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:warning | warning">
    <xsl:call-template name="emitir-alerta">
      <xsl:with-param name="tipo" select="'warning'"/>
      <xsl:with-param name="etiqueta" select="'Advertencia'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:caution | caution">
    <xsl:call-template name="emitir-alerta">
      <xsl:with-param name="tipo" select="'caution'"/>
      <xsl:with-param name="etiqueta" select="'Precaución'"/>
    </xsl:call-template>
  </xsl:template>
  <!-- MATERIAL SUPLEMENTARIO (sidebar role="supplementary") → recuadro
       con etiqueta propia y el xml:id conservado para referencia. -->
  <xsl:template match="db:sidebar[@role='supplementary'] | sidebar[@role='supplementary']">
    <div class="suplementario">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <div class="suplementario-etiqueta">Material suplementario</div>
      <div class="suplementario-cuerpo">
        <xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <!-- SIDEBAR: recuadro genérico. role determina el tipo (ej. info). -->
  <xsl:template match="db:sidebar | sidebar">
    <xsl:call-template name="emitir-alerta">
      <xsl:with-param name="tipo" select="if (@role != '') then @role else 'info'"/>
      <xsl:with-param name="etiqueta"
                      select="if (@role = 'info') then 'Información' else 'Nota'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ESTRUCTURA COMÚN DE ALERTA: icono a la izquierda + contenido -->
  <xsl:template name="emitir-alerta">
    <xsl:param name="tipo"/>
    <xsl:param name="etiqueta"/>
    <div class="alerta alerta-{$tipo}" role="note">
      <div class="alerta-icono" aria-hidden="true"></div>
      <div class="alerta-cuerpo">
        <xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <!-- ==========================================================
       VERSO (literallayout role="verse") → estrofa
       ==========================================================
       Preserva los saltos de línea del original. Cada línea del
       texto se convierte en una línea de verso. -->
  <xsl:template match="db:literallayout[@role='verse'] | literallayout[@role='verse']">
    <div class="verso">
      <xsl:for-each select="tokenize(., '&#10;')">
        <xsl:if test="normalize-space(.) != '' or position() &gt; 1">
          <span class="verso-linea"><xsl:value-of select="normalize-space(.)"/></span>
          <xsl:text>&#10;</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </div>
  </xsl:template>

  <!-- LITERALLAYOUT GENÉRICO (sin role verse) → pre simple -->
  <xsl:template match="db:literallayout | literallayout">
    <pre class="literallayout"><xsl:value-of select="."/></pre>
  </xsl:template>

  <!-- ==========================================================
       DISCURSO / DIÁLOGO (para role="speech")
       ==========================================================
       <para role="speech"> con <emphasis role="speaker"> al inicio.
       Se emite como .speech con el hablante destacado. -->
  <xsl:template match="db:para[@role='speech'] | para[@role='speech']">
    <p class="speech">
      <xsl:apply-templates/>
    </p>
  </xsl:template>

  <!-- HABLANTE del discurso (emphasis role="speaker") -->
  <xsl:template match="db:emphasis[@role='speaker'] | emphasis[@role='speaker']">
    <span class="speech-speaker"><xsl:apply-templates/></span>
  </xsl:template>

  <!-- EMPHASIS → EM / STRONG SEGÚN role -->
  <xsl:template match="db:emphasis | emphasis">
    <xsl:choose>
      <xsl:when test="@role = 'bold' or @role = 'strong'">
        <strong><xsl:apply-templates/></strong>
      </xsl:when>
      <xsl:otherwise>
        <em><xsl:apply-templates/></em>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- FOOTNOTE → MARCA <sup> NUMERADA POR CAPÍTULO.
       LLEVA data-fn-id Y data-fn-text PARA QUE EL JS CONSTRUYA
       EL PANEL DE NOTAS Y CABLEE LA NAVEGACIÓN CRUZADA.
       CLASES fn-ref ALINEADAS CON REVISTAS.
       NUMERACIÓN CORRELATIVA POR CAPÍTULO CON xsl:number. -->
  <xsl:template match="db:footnote | footnote">
    <xsl:variable name="num">
      <xsl:number count="db:footnote | footnote"
                  from="db:chapter | db:preface | db:appendix | db:dedication
                        | db:colophon | db:glossary
                        | chapter | preface | appendix | dedication
                        | colophon | glossary"
                  level="any"/>
    </xsl:variable>
    <!-- EL TEXTO DE LA NOTA SE SERIALIZA A TEXTO PLANO PARA EL data-attribute.
         SE NORMALIZAN ESPACIOS. EL JS LO INYECTA EN EL PANEL. -->
    <xsl:variable name="notaTexto">
      <xsl:apply-templates select="db:para | para" mode="texto-plano"/>
    </xsl:variable>
    <sup class="fn-ref nota-ref"
         data-fn-id="{$num}"
         data-fn-text="{normalize-space($notaTexto)}"
         onclick="highlightPanel('notas','{$num}')"
         style="cursor:pointer">
      <xsl:value-of select="$num"/>
    </sup>
  </xsl:template>

  <!-- MODO texto-plano: SERIALIZA EL CONTENIDO DE UNA NOTA A TEXTO
       SIN MARKUP, PARA EL data-fn-text. -->
  <xsl:template match="*" mode="texto-plano">
    <xsl:apply-templates mode="texto-plano"/>
    <xsl:text> </xsl:text>
  </xsl:template>
  <xsl:template match="text()" mode="texto-plano">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- TEMPLATE ESPECÍFICO PARA biblioref EN MODO texto-plano:
       EL biblioref ES EMPTY (RC-DB-01), ASÍ QUE EL GENÉRICO "*" NO
       PRODUCE NADA Y LA CITA SE PIERDE DEL data-fn-text. SOLUCIÓN
       (PORTADA DE jats-to-html.xsl): RENDERIZAR EL biblioref EN MODO
       DEFAULT (QUE PRODUCE "(Autor, año)" O "[N]") Y EXTRAER EL TEXTO
       PLANO CON string(). ASÍ LA NOTA MUESTRA LA CITA RESUELTA EN LUGAR
       DE PERDERLA. NO HAY RECURSIÓN: texto-plano Y default SON MODOS
       DISTINTOS. -->
  <xsl:template match="db:biblioref | biblioref" mode="texto-plano">
    <xsl:variable name="render">
      <xsl:apply-templates select="."/>
    </xsl:variable>
    <xsl:value-of select="string($render)"/>
  </xsl:template>
  <!-- LOS phrase de prefijo/sufijo SÍ deben aportar su texto en la nota -->
  <xsl:template match="db:phrase[@role='cite-prefix'] | phrase[@role='cite-prefix']
                     | db:phrase[@role='cite-suffix'] | phrase[@role='cite-suffix']"
                mode="texto-plano">
    <xsl:value-of select="."/>
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- ==========================================================
       ========= MARCAS DE CITA EN EL TEXTO (biblioref) =========
       ==========================================================
       Renderiza las marcas de cita del cuerpo según $estilo_cita:
         - APA / ISO690 (author-date): (Autor, año) / Autor (año)
         - Vancouver / IEEE (numérico): [N]
       Portado del jats-to-html.xsl al vocabulario DocBook.

       VOCABULARIO DOCBOOK (RC-DB-01: biblioref es EMPTY):
         <phrase role="cite-prefix">ver</phrase>
         <biblioref linkend="bib-X" role="suppress|author-in-text"/>
         <phrase role="cite-suffix">p. 5</phrase>
       El modo viaja en @role; prefijo/sufijo como phrase HERMANOS.

       AGRUPACIÓN POR ADYACENCIA: citas consecutivas [@a; @b] llegan
       como biblioref separados por texto ', '. Se agrupan detectando
       adyacencia, saltando los phrase de prefijo/sufijo intercalados. -->

  <!-- DESPACHADOR: author-date o numérico según estilo -->
  <xsl:template match="db:biblioref | biblioref">
    <xsl:choose>
      <xsl:when test="$estilo_cita = 'vancouver' or $estilo_cita = 'ieee'">
        <xsl:call-template name="xref-numerico-db"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="xref-autor-anio-db"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       SUPRESORES: phrase de prefijo/sufijo y separadores de grupo
       ==========================================================
       Los phrase cite-prefix/cite-suffix los ABSORBE el template del
       biblioref (para meterlos dentro del paréntesis en author-date).
       Se suprimen aquí para que no se rendericen sueltos. -->
  <xsl:template match="db:phrase[@role='cite-prefix'] | phrase[@role='cite-prefix']"/>
  <xsl:template match="db:phrase[@role='cite-suffix'] | phrase[@role='cite-suffix']"/>

  <!-- SUPRIMIR EL WHITESPACE RESIDUAL QUE SEPARA UN phrase (PREFIJO O
       SUFIJO, YA ABSORBIDO POR EL biblioref) DEL TEXTO CONTIGUO. SIN
       ESTO, EL NAVEGADOR COLAPSA ESE SALTO DE LÍNEA A UN ESPACIO Y
       QUEDA ' .' O '( ' ALREDEDOR DE LA CITA.
       CASO 1: whitespace ENTRE biblioref Y SU phrase-suffix. -->
  <xsl:template match="text()[normalize-space(.) = '']
    [preceding-sibling::node()[1][self::db:biblioref or self::biblioref]]
    [following-sibling::node()[1][self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']]]"/>
  <!-- CASO 2: whitespace ENTRE un phrase-prefix Y SU biblioref. -->
  <xsl:template match="text()[normalize-space(.) = '']
    [preceding-sibling::node()[1][self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']]]
    [following-sibling::node()[1][self::db:biblioref or self::biblioref]]"/>

  <!-- SUPRIMIR EL TEXTO SEPARADOR ', ' / '; ' ENTRE DOS biblioref
       DE UN MISMO GRUPO (LA AGRUPACIÓN LO EMITE EL PRIMERO).
       SE COMPARA CONTRA EL VECINO NO-WHITESPACE. -->
  <xsl:template match="text()[matches(., '^\s*[,;]\s*$')]
    [preceding-sibling::node()[not(self::text() and normalize-space(.)='')][1]
       [self::db:biblioref or self::biblioref
        or self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']]]
    [following-sibling::node()[not(self::text() and normalize-space(.)='')][1]
       [self::db:biblioref or self::biblioref
        or self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']]]"/>

  <!-- ==========================================================
       AUXILIAR: prefijo/sufijo hermanos de un biblioref
       ==========================================================
       Devuelven el phrase adyacente (o vacío). El prefijo es el
       phrase inmediatamente anterior; el sufijo, el posterior. -->
  <xsl:template name="phrase-prefijo-de">
    <!-- EL PHRASE PREFIJO PUEDE ESTAR SEPARADO DEL biblioref POR UN
         text() DE SOLO ESPACIOS (SALTO DE LÍNEA + SANGRÍA DEL CANÓNICO).
         SE BUSCA EL PRIMER preceding-sibling NO-WHITESPACE. -->
    <xsl:variable name="prev"
      select="preceding-sibling::node()[not(self::text() and normalize-space(.) = '')][1]"/>
    <xsl:if test="$prev[self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']]">
      <xsl:apply-templates select="$prev/node()"/>
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template name="phrase-sufijo-de">
    <!-- ÍDEM: EL PHRASE SUFIJO PUEDE ESTAR SEPARADO POR WHITESPACE. -->
    <xsl:variable name="next"
      select="following-sibling::node()[not(self::text() and normalize-space(.) = '')][1]"/>
    <xsl:if test="$next[self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']]">
      <xsl:text>, </xsl:text>
      <xsl:apply-templates select="$next/node()"/>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: resolver autor de una cita desde su biblioentry
       ==========================================================
       Busca el biblioentry por xml:id (= linkend) y devuelve el
       surname formateado: 1 autor → "Apellido"; 2 → "A y B";
       3+ → "A et al.". Usa autores, o editores como fallback. -->
  <xsl:template name="resolver-autor-cita-db">
    <xsl:param name="rid"/>
    <xsl:variable name="entry"
                  select="(//db:biblioentry | //biblioentry)[@xml:id = $rid][1]"/>
    <xsl:variable name="personas"
                  select="$entry/db:author | $entry/author"/>
    <xsl:variable name="editores"
                  select="$entry/db:editor | $entry/editor"/>
    <xsl:choose>
      <xsl:when test="$personas">
        <xsl:call-template name="formatear-surnames-cita">
          <xsl:with-param name="lista" select="$personas"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$editores">
        <xsl:call-template name="formatear-surnames-cita">
          <xsl:with-param name="lista" select="$editores"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <!-- SIN AUTOR: USAR EL citekey VISIBLE (SIN PREFIJO bib-) -->
        <xsl:value-of select="if (starts-with($rid, 'bib-'))
                              then substring-after($rid, 'bib-') else $rid"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- FORMATEA SURNAMES SEGÚN CANTIDAD (1 / 2 / 3+) -->
  <xsl:template name="formatear-surnames-cita">
    <xsl:param name="lista"/>
    <xsl:variable name="n" select="count($lista)"/>
    <xsl:choose>
      <xsl:when test="$n = 1">
        <xsl:value-of select="normalize-space(($lista[1]/db:personname/db:surname
                                              | $lista[1]/personname/surname)[1])"/>
      </xsl:when>
      <xsl:when test="$n = 2">
        <xsl:value-of select="normalize-space(($lista[1]/db:personname/db:surname
                                              | $lista[1]/personname/surname)[1])"/>
        <xsl:text> y </xsl:text>
        <xsl:value-of select="normalize-space(($lista[2]/db:personname/db:surname
                                              | $lista[2]/personname/surname)[1])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space(($lista[1]/db:personname/db:surname
                                              | $lista[1]/personname/surname)[1])"/>
        <xsl:text> et al.</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- AÑO DE UNA CITA DESDE SU biblioentry (pubdate) -->
  <xsl:template name="resolver-anio-cita-db">
    <xsl:param name="rid"/>
    <xsl:variable name="entry"
                  select="(//db:biblioentry | //biblioentry)[@xml:id = $rid][1]"/>
    <xsl:value-of select="normalize-space(($entry/db:pubdate | $entry/pubdate)[1])"/>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: detectar si un biblioref es PRIMERO de su grupo
       ==========================================================
       Es primero si NO hay, inmediatamente antes (saltando su phrase
       prefijo), un separador ',/;' precedido por otro biblioref/sufijo. -->
  <xsl:template name="es-primera-cita-grupo">
    <!-- NODO ANTERIOR NO-WHITESPACE, SALTANDO EL PHRASE DE PREFIJO SI EXISTE -->
    <xsl:variable name="prev1"
      select="preceding-sibling::node()[not(self::text() and normalize-space(.)='')][1]"/>
    <xsl:variable name="ancla"
      select="if ($prev1[self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']])
              then preceding-sibling::node()[not(self::text() and normalize-space(.)='')][2]
              else $prev1"/>
    <!-- ES PRIMERA SI EL ANCLA NO ES UN SEPARADOR DE GRUPO -->
    <xsl:sequence select="not($ancla[self::text() and matches(., '^\s*[,;]\s*$')])"/>
  </xsl:template>

  <!-- ==========================================================
       AUTHOR-DATE (APA / ISO690): (Autor, año) con 3 modos
       ==========================================================
       Modos: normal (Autor, año) · suppress (año) · author-in-text
       Autor (año). Prefijo/sufijo dentro del paréntesis. Agrupa
       citas consecutivas con '; '. -->
  <xsl:template name="xref-autor-anio-db">
    <xsl:variable name="rid" select="@linkend"/>
    <xsl:variable name="modo" select="if (@role != '') then @role else 'normal'"/>
    <xsl:variable name="autor">
      <xsl:call-template name="resolver-autor-cita-db">
        <xsl:with-param name="rid" select="$rid"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="anio">
      <xsl:call-template name="resolver-anio-cita-db">
        <xsl:with-param name="rid" select="$rid"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="esPrimera">
      <xsl:call-template name="es-primera-cita-grupo"/>
    </xsl:variable>
    <!-- ¿ES LA ÚLTIMA DEL GRUPO? EL SIGUIENTE (SALTANDO SUFIJO) NO ES SEP -->
    <xsl:variable name="next1"
      select="following-sibling::node()[not(self::text() and normalize-space(.)='')][1]"/>
    <xsl:variable name="anclaSig"
      select="if ($next1[self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']])
              then following-sibling::node()[not(self::text() and normalize-space(.)='')][2]
              else $next1"/>
    <xsl:variable name="esUltima"
      select="not($anclaSig[self::text() and matches(., '^\s*[,;]\s*$')])"/>

    <xsl:choose>

      <!-- AUTHOR-IN-TEXT: Autor (año) — SIN PARÉNTESIS EXTERIOR -->
      <xsl:when test="$modo = 'author-in-text'">
        <!-- PREFIJO ANTES DEL AUTOR (RARO EN ESTE MODO, PERO SE RESPETA) -->
        <xsl:call-template name="phrase-prefijo-de"/>
        <a class="xref-bibr cita-ref" data-ref-id="{$rid}"
           onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
          <xsl:value-of select="$autor"/>
        </a>
        <xsl:text> (</xsl:text>
        <a class="xref-bibr cita-ref" data-ref-id="{$rid}"
           onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
          <xsl:value-of select="$anio"/>
        </a>
        <xsl:call-template name="phrase-sufijo-de"/>
        <xsl:text>)</xsl:text>
      </xsl:when>

      <!-- SUPPRESS: (año) — SIN AUTOR -->
      <xsl:when test="$modo = 'suppress'">
        <xsl:if test="$esPrimera = true()">
          <xsl:text>(</xsl:text>
          <xsl:call-template name="phrase-prefijo-de"/>
        </xsl:if>
        <xsl:if test="$esPrimera = false()"><xsl:text>; </xsl:text></xsl:if>
        <a class="xref-bibr cita-ref" data-ref-id="{$rid}"
           onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
          <xsl:value-of select="$anio"/>
          <xsl:call-template name="phrase-sufijo-de"/>
        </a>
        <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
      </xsl:when>

      <!-- NORMAL: (Autor, año) -->
      <xsl:otherwise>
        <xsl:if test="$esPrimera = true()">
          <xsl:text>(</xsl:text>
          <xsl:call-template name="phrase-prefijo-de"/>
        </xsl:if>
        <xsl:if test="$esPrimera = false()"><xsl:text>; </xsl:text></xsl:if>
        <a class="xref-bibr cita-ref" data-ref-id="{$rid}"
           onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
          <xsl:value-of select="$autor"/>
          <xsl:if test="$anio != ''">
            <xsl:text>, </xsl:text><xsl:value-of select="$anio"/>
          </xsl:if>
          <xsl:call-template name="phrase-sufijo-de"/>
        </a>
        <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       NUMÉRICO (Vancouver / IEEE): [N]
       ==========================================================
       N = posición del biblioentry en la bibliography del capítulo
       (reinicia por capítulo). Agrupa consecutivas como [1,2,3],
       un <a> por número. Prefijo antes del corchete, sufijo dentro. -->
  <xsl:template name="xref-numerico-db">
    <xsl:variable name="rid" select="@linkend"/>
    <xsl:variable name="modo" select="if (@role != '') then @role else 'normal'"/>
    <xsl:variable name="esPrimera">
      <xsl:call-template name="es-primera-cita-grupo"/>
    </xsl:variable>
    <xsl:variable name="next1"
      select="following-sibling::node()[not(self::text() and normalize-space(.)='')][1]"/>
    <xsl:variable name="anclaSig"
      select="if ($next1[self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']])
              then following-sibling::node()[not(self::text() and normalize-space(.)='')][2]
              else $next1"/>
    <xsl:variable name="esUltima"
      select="not($anclaSig[self::text() and matches(., '^\s*[,;]\s*$')])"/>

    <!-- AUTHOR-IN-TEXT: EN NUMÉRICO SE EMITE 'Autor [N]'. EL AUTOR VA
         ANTES DEL CORCHETE (SOLO PARA LA PRIMERA CITA DEL GRUPO). -->
    <xsl:if test="$modo = 'author-in-text' and $esPrimera = true()">
      <xsl:variable name="autor">
        <xsl:call-template name="resolver-autor-cita-db">
          <xsl:with-param name="rid" select="$rid"/>
        </xsl:call-template>
      </xsl:variable>
      <a class="xref-vancouver cita-ref" data-ref-id="{$rid}"
         onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
        <xsl:value-of select="$autor"/>
      </a>
      <xsl:text> </xsl:text>
    </xsl:if>

    <!-- PREFIJO ANTES DEL CORCHETE (SOLO EN LA PRIMERA DEL GRUPO) -->
    <xsl:if test="$esPrimera = true()">
      <xsl:call-template name="phrase-prefijo-de"/>
      <xsl:text>[</xsl:text>
    </xsl:if>
    <xsl:if test="$esPrimera = false()"><xsl:text>,</xsl:text></xsl:if>

    <!-- EL NÚMERO: POSICIÓN DEL biblioentry EN LA bibliography -->
    <xsl:variable name="num">
      <xsl:call-template name="numero-referencia-db">
        <xsl:with-param name="rid" select="$rid"/>
      </xsl:call-template>
    </xsl:variable>
    <a class="xref-vancouver cita-ref" data-ref-id="{$rid}"
       onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
      <xsl:value-of select="$num"/>
    </a>

    <!-- SUFIJO DENTRO DEL CORCHETE (EN LA ÚLTIMA DEL GRUPO) -->
    <xsl:if test="$esUltima">
      <xsl:call-template name="phrase-sufijo-de"/>
      <xsl:text>]</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- NÚMERO DE UNA REFERENCIA: POSICIÓN EN LA bibliography DEL CAP.
       CUENTA biblioentry PRECEDENTES DENTRO DE LA MISMA bibliography. -->
  <xsl:template name="numero-referencia-db">
    <xsl:param name="rid"/>
    <xsl:variable name="entry"
                  select="(//db:biblioentry | //biblioentry)[@xml:id = $rid][1]"/>
    <xsl:choose>
      <xsl:when test="$entry">
        <xsl:value-of select="count($entry[1]/preceding-sibling::db:biblioentry
                                    | $entry[1]/preceding-sibling::biblioentry) + 1"/>
      </xsl:when>
      <!-- CITA HUÉRFANA: linkend SIN biblioentry -->
      <xsl:otherwise>
        <xsl:text>?</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!-- LINK EXTERNO → A -->
  <xsl:template match="db:link | link">
    <a href="{@xlink:href}" target="_blank" rel="noopener noreferrer">
      <xsl:apply-templates/>
    </a>
  </xsl:template>

  <!-- TÍTULO SUELTO: NO EMITIR (SE MANEJA EN LOS TEMPLATES CONTENEDORES) -->
  <xsl:template match="db:title | title"/>

  <!-- TEXTO: COPIAR NORMALIZANDO ESPACIOS DE FORMA SUAVE -->
  <!-- NO USAR normalize-space GLOBAL PARA NO COLAPSAR ESPACIOS ENTRE
       ELEMENTOS INLINE; SE COPIA EL TEXTO TAL CUAL. -->
  <xsl:template match="text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- CATCH-ALL: ELEMENTOS NO CONTEMPLADOS AÚN → PROCESAR HIJOS.
       EVITA QUE CONTENIDO DESCONOCIDO DESAPAREZCA SILENCIOSAMENTE. -->
  <xsl:template match="*">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ==========================================================
       BIBLIOENTRY EN MODO panel-ref (Fase 3)
       ==========================================================
       Renderiza cada entrada bibliográfica en el panel de referencias.
       Por ahora un formato funcional único (autor-título-editorial-año)
       para habilitar la navegación cruzada. La bifurcación por estilo
       (APA/Vancouver/ISO690/IEEE) se optimiza en fase posterior.

       El data-ref-id (el xml:id bib-XXX) permite que:
       - la marca [cita] del centro ancle a esta entrada (ida)
       - el click en esta entrada lleve a la primera cita (vuelta)
       onclick=irAlTexto para la navegación inversa (bidireccional en libros). -->
  <!-- ==========================================================
       BIBLIOENTRY EN MODO panel-ref — 4 ESTILOS DE CITA
       ==========================================================
       Rendering de cada referencia según $estilo_cita, portado del
       jats-to-html.xsl de revistas al vocabulario DocBook biblioentry.
       Estilos: apa | vancouver | iso690 | ieee + fallback autor-año.

       MAPEO DE VOCABULARIO JATS → DOCBOOK:
         person-group[@type='author']/name → author/personname
         surname/given-names               → surname/firstname
         article-title / chapter-title     → title
         source                            → citetitle
         year                              → pubdate
         volume / issue                    → volumenum / issuenum
         fpage-lpage                       → artpagenums
         publisher-name / publisher-loc    → publishername / address/city
         pub-id[@type='doi']               → biblioid[@class='doi'] -->
  <xsl:template match="db:biblioentry | biblioentry" mode="panel-ref">
    <div class="panel-item ref-item"
         data-ref-id="{@xml:id}"
         onclick="irAlTexto('{@xml:id}')"
         style="cursor:pointer">
      <!-- NÚMERO DE REFERENCIA: SOLO EN ESTILOS NUMÉRICOS (vancouver, ieee).
           ES EL ANCLA VISUAL QUE CONECTA LA MARCA [n] DEL CUERPO CON LA
           ENTRADA DEL DRAWER. SE CALCULA CON numero-referencia-db (EL MISMO
           QUE USAN LAS MARCAS), PASÁNDOLE EL PROPIO xml:id, ASÍ EL NÚMERO
           COINCIDE EXACTAMENTE. EN APA/ISO690 (AUTOR-AÑO) NO SE EMITE. -->
      <xsl:if test="$estilo_cita = 'vancouver' or $estilo_cita = 'ieee'">
        <span class="ref-numero">
          <xsl:text>[</xsl:text>
          <xsl:call-template name="numero-referencia-db">
            <xsl:with-param name="rid" select="string(@xml:id)"/>
          </xsl:call-template>
          <xsl:text>] </xsl:text>
        </span>
      </xsl:if>
      <xsl:choose>

        <!-- ══════════ VANCOUVER ══════════ -->
        <xsl:when test="$estilo_cita = 'vancouver'">
          <xsl:call-template name="ref-personas-db">
            <xsl:with-param name="estilo" select="'vancouver'"/>
          </xsl:call-template>
          <xsl:text>. </xsl:text>

          <!-- TÍTULO (redonda) -->
          <xsl:if test="db:title | title">
            <span class="ref-title-roman">
              <xsl:value-of select="normalize-space((db:title | title)[1])"/>
              <xsl:text>. </xsl:text>
            </span>
          </xsl:if>

          <!-- FUENTE / LIBRO (cursiva) -->
          <xsl:if test="db:citetitle | citetitle">
            <span class="ref-source-italic">
              <xsl:value-of select="normalize-space((db:citetitle | citetitle)[1])"/>
            </span>
          </xsl:if>

          <!-- TESIS: [tipo]. Institución -->
          <xsl:call-template name="ref-tesis-db">
            <xsl:with-param name="estilo" select="'vancouver'"/>
          </xsl:call-template>

          <!-- AÑO;VOLUMEN(NÚMERO):PÁGINAS -->
          <xsl:if test="db:pubdate | pubdate">
            <xsl:text>. </xsl:text>
            <span class="ref-year"><xsl:value-of select="normalize-space((db:pubdate | pubdate)[1])"/></span>
          </xsl:if>
          <xsl:if test="db:volumenum | volumenum">
            <xsl:text>;</xsl:text>
            <xsl:value-of select="normalize-space((db:volumenum | volumenum)[1])"/>
          </xsl:if>
          <xsl:if test="db:issuenum | issuenum">
            <xsl:text>(</xsl:text>
            <xsl:value-of select="normalize-space((db:issuenum | issuenum)[1])"/>
            <xsl:text>)</xsl:text>
          </xsl:if>
          <xsl:if test="db:artpagenums | artpagenums">
            <xsl:text>:</xsl:text>
            <xsl:value-of select="normalize-space((db:artpagenums | artpagenums)[1])"/>
          </xsl:if>

          <!-- EDITORIAL: CIUDAD: EDITORIAL -->
          <xsl:call-template name="ref-editorial-db">
            <xsl:with-param name="sep-inicial" select="'. '"/>
          </xsl:call-template>
          <xsl:text>.</xsl:text>

          <xsl:call-template name="ref-doi-db">
            <xsl:with-param name="etiqueta" select="'DOI: '"/>
          </xsl:call-template>
        </xsl:when>

        <!-- ══════════ APA 7 ══════════ -->
        <xsl:when test="$estilo_cita = 'apa'">
          <xsl:call-template name="ref-personas-db">
            <xsl:with-param name="estilo" select="'apa'"/>
          </xsl:call-template>

          <!-- AÑO ENTRE PARÉNTESIS -->
          <xsl:if test="db:pubdate | pubdate">
            <span class="ref-year">
              <xsl:text> (</xsl:text>
              <xsl:value-of select="normalize-space((db:pubdate | pubdate)[1])"/>
              <xsl:text>). </xsl:text>
            </span>
          </xsl:if>

          <!-- TÍTULO DEL ARTÍCULO/CAPÍTULO (redonda, sin cursiva en APA) -->
          <xsl:if test="db:title | title">
            <span class="ref-title-roman">
              <xsl:value-of select="normalize-space((db:title | title)[1])"/>
              <xsl:text>. </xsl:text>
            </span>
          </xsl:if>

          <!-- FUENTE / LIBRO (cursiva) -->
          <xsl:if test="db:citetitle | citetitle">
            <span class="ref-source-italic">
              <xsl:value-of select="normalize-space((db:citetitle | citetitle)[1])"/>
            </span>
          </xsl:if>

          <!-- TESIS: [Tipo, Institución] tras el título/fuente -->
          <xsl:call-template name="ref-tesis-db">
            <xsl:with-param name="estilo" select="'apa'"/>
          </xsl:call-template>

          <!-- VOLUMEN (cursiva), NÚMERO (paréntesis) -->
          <xsl:if test="db:volumenum | volumenum">
            <xsl:text>, </xsl:text>
            <em><xsl:value-of select="normalize-space((db:volumenum | volumenum)[1])"/></em>
          </xsl:if>
          <xsl:if test="db:issuenum | issuenum">
            <xsl:text>(</xsl:text>
            <xsl:value-of select="normalize-space((db:issuenum | issuenum)[1])"/>
            <xsl:text>)</xsl:text>
          </xsl:if>

          <!-- PÁGINAS -->
          <xsl:if test="db:artpagenums | artpagenums">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="normalize-space((db:artpagenums | artpagenums)[1])"/>
          </xsl:if>

          <!-- EDITORIAL (APA libros: solo editorial, sin ciudad desde 7ª ed.) -->
          <xsl:variable name="pubname-apa"
                        select="normalize-space((db:publisher/db:publishername
                                                | publisher/publishername)[1])"/>
          <xsl:if test="$pubname-apa != ''">
            <xsl:text>. </xsl:text>
            <xsl:value-of select="$pubname-apa"/>
          </xsl:if>

          <!-- DOI como URL sin etiqueta (APA 7) -->
          <xsl:call-template name="ref-doi-db">
            <xsl:with-param name="etiqueta" select="'https://doi.org/'"/>
            <xsl:with-param name="solo-url" select="true()"/>
          </xsl:call-template>
        </xsl:when>

        <!-- ══════════ ISO 690 (autor-fecha, versalitas) ══════════ -->
        <xsl:when test="$estilo_cita = 'iso690'">
          <xsl:call-template name="ref-personas-db">
            <xsl:with-param name="estilo" select="'iso690'"/>
          </xsl:call-template>

          <!-- AÑO ENTRE PARÉNTESIS -->
          <xsl:if test="db:pubdate | pubdate">
            <span class="ref-year">
              <xsl:text> (</xsl:text>
              <xsl:value-of select="normalize-space((db:pubdate | pubdate)[1])"/>
              <xsl:text>). </xsl:text>
            </span>
          </xsl:if>

          <!-- TÍTULO ENTRE COMILLAS -->
          <xsl:if test="db:title | title">
            <span class="ref-title-roman">
              <xsl:text>&#x201C;</xsl:text>
              <xsl:value-of select="normalize-space((db:title | title)[1])"/>
              <xsl:text>&#x201D;. </xsl:text>
            </span>
          </xsl:if>

          <!-- FUENTE / LIBRO (cursiva) -->
          <xsl:if test="db:citetitle | citetitle">
            <span class="ref-source-italic">
              <xsl:value-of select="normalize-space((db:citetitle | citetitle)[1])"/>
            </span>
          </xsl:if>

          <!-- TESIS: . Tipo. Institución -->
          <xsl:call-template name="ref-tesis-db">
            <xsl:with-param name="estilo" select="'iso690'"/>
          </xsl:call-template>

          <!-- VOLUMEN, NÚMERO -->
          <xsl:if test="db:volumenum | volumenum">
            <xsl:text>, vol. </xsl:text>
            <xsl:value-of select="normalize-space((db:volumenum | volumenum)[1])"/>
          </xsl:if>
          <xsl:if test="db:issuenum | issuenum">
            <xsl:text>, n.&#xBA; </xsl:text>
            <xsl:value-of select="normalize-space((db:issuenum | issuenum)[1])"/>
          </xsl:if>

          <!-- PÁGINAS -->
          <xsl:if test="db:artpagenums | artpagenums">
            <xsl:text>, pp. </xsl:text>
            <xsl:value-of select="normalize-space((db:artpagenums | artpagenums)[1])"/>
          </xsl:if>

          <!-- EDITORIAL: CIUDAD: EDITORIAL -->
          <xsl:call-template name="ref-editorial-db">
            <xsl:with-param name="sep-inicial" select="'. '"/>
          </xsl:call-template>
          <xsl:text>.</xsl:text>

          <xsl:call-template name="ref-doi-db">
            <xsl:with-param name="etiqueta" select="'DOI: '"/>
          </xsl:call-template>
        </xsl:when>

        <!-- ══════════ IEEE (inicial primero, año al final) ══════════ -->
        <xsl:when test="$estilo_cita = 'ieee'">
          <xsl:call-template name="ref-personas-db">
            <xsl:with-param name="estilo" select="'ieee'"/>
          </xsl:call-template>
          <xsl:text>. </xsl:text>

          <!-- TÍTULO ENTRE COMILLAS, TERMINADO EN COMA -->
          <xsl:if test="db:title | title">
            <span class="ref-title-roman">
              <xsl:text>&#x201C;</xsl:text>
              <xsl:value-of select="normalize-space((db:title | title)[1])"/>
              <xsl:text>,&#x201D;</xsl:text>
            </span>
          </xsl:if>

          <!-- FUENTE / LIBRO (cursiva) -->
          <xsl:if test="db:citetitle | citetitle">
            <span class="ref-source-italic">
              <xsl:text> </xsl:text>
              <xsl:value-of select="normalize-space((db:citetitle | citetitle)[1])"/>
            </span>
          </xsl:if>

          <!-- TESIS: , tipo, Institución -->
          <xsl:call-template name="ref-tesis-db">
            <xsl:with-param name="estilo" select="'ieee'"/>
          </xsl:call-template>

          <!-- VOLUMEN, NÚMERO -->
          <xsl:if test="db:volumenum | volumenum">
            <xsl:text>, vol. </xsl:text>
            <xsl:value-of select="normalize-space((db:volumenum | volumenum)[1])"/>
          </xsl:if>
          <xsl:if test="db:issuenum | issuenum">
            <xsl:text>, n.&#xBA; </xsl:text>
            <xsl:value-of select="normalize-space((db:issuenum | issuenum)[1])"/>
          </xsl:if>

          <!-- PÁGINAS -->
          <xsl:if test="db:artpagenums | artpagenums">
            <xsl:text>, pp. </xsl:text>
            <xsl:value-of select="normalize-space((db:artpagenums | artpagenums)[1])"/>
          </xsl:if>

          <!-- EDITORIAL: CIUDAD: EDITORIAL -->
          <xsl:call-template name="ref-editorial-db">
            <xsl:with-param name="sep-inicial" select="'. '"/>
          </xsl:call-template>

          <!-- AÑO AL FINAL -->
          <xsl:if test="db:pubdate | pubdate">
            <xsl:text>, </xsl:text>
            <span class="ref-year"><xsl:value-of select="normalize-space((db:pubdate | pubdate)[1])"/></span>
          </xsl:if>
          <xsl:text>.</xsl:text>

          <xsl:call-template name="ref-doi-db">
            <xsl:with-param name="etiqueta" select="'DOI: '"/>
          </xsl:call-template>
        </xsl:when>

        <!-- ══════════ FALLBACK: AUTOR-AÑO GENÉRICO ══════════ -->
        <xsl:otherwise>
          <xsl:call-template name="ref-personas-db">
            <xsl:with-param name="estilo" select="'fallback'"/>
          </xsl:call-template>
          <xsl:if test="db:pubdate | pubdate">
            <xsl:text> (</xsl:text>
            <span class="ref-year"><xsl:value-of select="normalize-space((db:pubdate | pubdate)[1])"/></span>
            <xsl:text>). </xsl:text>
          </xsl:if>
          <xsl:if test="db:title | title">
            <span class="ref-title-roman">
              <xsl:value-of select="normalize-space((db:title | title)[1])"/>
              <xsl:text>. </xsl:text>
            </span>
          </xsl:if>
          <xsl:if test="db:citetitle | citetitle">
            <span class="ref-source-italic">
              <xsl:value-of select="normalize-space((db:citetitle | citetitle)[1])"/>
            </span>
          </xsl:if>
          <xsl:call-template name="ref-editorial-db">
            <xsl:with-param name="sep-inicial" select="'. '"/>
          </xsl:call-template>
          <xsl:text>.</xsl:text>
          <xsl:call-template name="ref-doi-db">
            <xsl:with-param name="etiqueta" select="'DOI: '"/>
          </xsl:call-template>
        </xsl:otherwise>

      </xsl:choose>
    </div>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: ref-personas-db
       ==========================================================
       Emite autores (o editores como fallback) de un biblioentry
       DocBook según el estilo. Encapsula los 4 formatos de nombre.
       Portado del jats-to-html.xsl (person-group → author/editor). -->
  <xsl:template name="ref-personas-db">
    <xsl:param name="estilo" as="xs:string"/>

    <span class="ref-authors">
      <xsl:choose>
        <!-- HAY AUTORES -->
        <xsl:when test="db:author | author">
          <xsl:for-each select="db:author | author">
            <xsl:call-template name="ref-una-persona-db">
              <xsl:with-param name="estilo" select="$estilo"/>
              <xsl:with-param name="total" select="last()"/>
            </xsl:call-template>
          </xsl:for-each>
        </xsl:when>
        <!-- FALLBACK: EDITORES CON MARCA (Ed.)/(Eds.) -->
        <xsl:when test="db:editor | editor">
          <xsl:for-each select="db:editor | editor">
            <xsl:call-template name="ref-una-persona-db">
              <xsl:with-param name="estilo" select="$estilo"/>
              <xsl:with-param name="total" select="last()"/>
            </xsl:call-template>
          </xsl:for-each>
          <!-- MARCA DE EDITOR SEGÚN ESTILO -->
          <xsl:choose>
            <xsl:when test="$estilo = 'apa'">
              <xsl:text> (Ed</xsl:text>
              <xsl:if test="count(db:editor | editor) &gt; 1"><xsl:text>s</xsl:text></xsl:if>
              <xsl:text>.)</xsl:text>
            </xsl:when>
            <xsl:when test="$estilo = 'vancouver'">
              <xsl:text> (ed</xsl:text>
              <xsl:if test="count(db:editor | editor) &gt; 1"><xsl:text>s</xsl:text></xsl:if>
              <xsl:text>.)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <xsl:text> (Ed</xsl:text>
              <xsl:if test="count(db:editor | editor) &gt; 1"><xsl:text>s</xsl:text></xsl:if>
              <xsl:text>.)</xsl:text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
      </xsl:choose>
    </span>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: ref-una-persona-db
       ==========================================================
       Emite UNA persona (surname/firstname) en el formato del estilo,
       con el separador correcto según su posición en la lista. -->
  <xsl:template name="ref-una-persona-db">
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:param name="total" as="xs:integer"/>

    <xsl:variable name="pn" select="db:personname | personname"/>
    <xsl:variable name="surname" select="normalize-space($pn/db:surname | $pn/surname)"/>
    <xsl:variable name="firstname" select="normalize-space($pn/db:firstname | $pn/firstname)"/>

    <xsl:choose>
      <!-- VANCOUVER: Apellido II (iniciales pegadas sin puntos) -->
      <xsl:when test="$estilo = 'vancouver'">
        <xsl:value-of select="$surname"/>
        <xsl:if test="$firstname != ''">
          <xsl:text> </xsl:text>
          <!-- INICIALES SIN PUNTOS NI ESPACIOS: 'Juan Carlos' → 'JC'.
               EN DOCBOOK firstname VIENE COMPLETO, HAY QUE ABREVIAR. -->
          <xsl:for-each select="tokenize(normalize-space($firstname), '\s+')">
            <xsl:value-of select="substring(., 1, 1)"/>
          </xsl:for-each>
        </xsl:if>
        <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
      </xsl:when>

      <!-- APA: Apellido, I. I. -->
      <xsl:when test="$estilo = 'apa'">
        <xsl:value-of select="$surname"/>
        <xsl:if test="$firstname != ''">
          <xsl:text>, </xsl:text>
          <xsl:call-template name="iniciales-apa">
            <xsl:with-param name="nombres" select="$firstname"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="position() = last() - 1"><xsl:text>, &amp; </xsl:text></xsl:when>
          <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
        </xsl:choose>
      </xsl:when>

      <!-- ISO 690: APELLIDO (versalitas), Nombre -->
      <xsl:when test="$estilo = 'iso690'">
        <span style="font-variant:small-caps">
          <xsl:value-of select="upper-case($surname)"/>
        </span>
        <xsl:if test="$firstname != ''">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="$firstname"/>
        </xsl:if>
        <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
      </xsl:when>

      <!-- IEEE: I. Apellido (inicial primero) -->
      <xsl:when test="$estilo = 'ieee'">
        <xsl:if test="$firstname != ''">
          <!-- EXTRAER INICIALES: EN DOCBOOK firstname VIENE COMPLETO
               ('Marcela'), NO ABREVIADO. iniciales-apa PRODUCE 'M.' -->
          <xsl:call-template name="iniciales-apa">
            <xsl:with-param name="nombres" select="$firstname"/>
          </xsl:call-template>
          <xsl:text> </xsl:text>
        </xsl:if>
        <xsl:value-of select="$surname"/>
        <xsl:choose>
          <xsl:when test="position() = last() - 1 and last() &gt; 1"><xsl:text> and </xsl:text></xsl:when>
          <xsl:when test="position() != last()"><xsl:text>, </xsl:text></xsl:when>
        </xsl:choose>
      </xsl:when>

      <!-- FALLBACK: Apellido, Nombre -->
      <xsl:otherwise>
        <xsl:value-of select="$surname"/>
        <xsl:if test="$firstname != ''">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="$firstname"/>
        </xsl:if>
        <xsl:if test="position() != last()"><xsl:text>; </xsl:text></xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: ref-editorial-db
       ==========================================================
       Emite "Ciudad: Editorial" desde publisher/publishername +
       publisher/address/city. Convierte " and " → " y " en el nombre. -->
  <xsl:template name="ref-editorial-db">
    <xsl:param name="sep-inicial" as="xs:string" select="'. '"/>

    <xsl:variable name="pubname"
                  select="normalize-space((db:publisher/db:publishername
                                          | publisher/publishername)[1])"/>
    <xsl:variable name="pubcity"
                  select="normalize-space((db:publisher/db:address/db:city
                                          | publisher/address/city)[1])"/>
    <xsl:if test="$pubname != '' or $pubcity != ''">
      <xsl:value-of select="$sep-inicial"/>
      <xsl:if test="$pubcity != ''">
        <xsl:value-of select="$pubcity"/>
        <xsl:text>: </xsl:text>
      </xsl:if>
      <xsl:if test="$pubname != ''">
        <xsl:value-of select="replace($pubname, '(\s)and(\s)', '$1y$2')"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: ref-doi-db
       ==========================================================
       Emite el DOI como enlace, con etiqueta configurable. -->
  <xsl:template name="ref-doi-db">
    <xsl:param name="etiqueta" as="xs:string" select="'DOI: '"/>
    <xsl:param name="solo-url" as="xs:boolean" select="false()"/>

    <xsl:variable name="doi"
                  select="normalize-space((db:biblioid[@class='doi']
                                          | biblioid[@class='doi'])[1])"/>
    <xsl:if test="$doi != ''">
      <div class="ref-doi">
        <a href="https://doi.org/{$doi}" target="_blank" rel="noopener noreferrer">
          <xsl:choose>
            <xsl:when test="$solo-url">
              <xsl:value-of select="$etiqueta"/><xsl:value-of select="$doi"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$etiqueta"/><xsl:value-of select="$doi"/>
            </xsl:otherwise>
          </xsl:choose>
        </a>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: ref-tesis-db
       ==========================================================
       Emite el tipo de tesis + institución en el formato del estilo.
       Solo aplica si el biblioentry es una tesis (otherpubwork='thesis').
       El tipo (nombre en español) viene de bibliomisc[@role='thesis-type'],
       ya resuelto por Gambas desde cmb_biblatex. Si no hay thesis-type,
       usa "Tesis" genérico. La institución sale de orgname.
       FORMATOS:
         apa:       [Tesis Doctoral, Universidad X]
         vancouver: [tesis doctoral]. Universidad X
         iso690:    Tesis Doctoral. Universidad X
         ieee:      tesis doctoral, Universidad X -->
  <xsl:template name="ref-tesis-db">
    <xsl:param name="estilo" as="xs:string"/>

    <!-- ¿ES TESIS? SOLO ACTÚA SI otherpubwork='thesis' -->
    <xsl:variable name="es-tesis"
                  select="(@otherpubwork = 'thesis')
                          or (db:citetitle/@pubwork = 'thesis')
                          or (citetitle/@pubwork = 'thesis')"/>

    <xsl:if test="$es-tesis">
      <!-- TIPO: bibliomisc[@role='thesis-type'] O "Tesis" GENÉRICO -->
      <xsl:variable name="tipo-tesis">
        <xsl:variable name="tt"
          select="normalize-space((db:bibliomisc[@role='thesis-type']
                                  | bibliomisc[@role='thesis-type'])[1])"/>
        <xsl:choose>
          <xsl:when test="$tt != ''"><xsl:value-of select="$tt"/></xsl:when>
          <xsl:otherwise><xsl:text>Tesis</xsl:text></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- INSTITUCIÓN: orgname -->
      <xsl:variable name="institucion"
        select="normalize-space((db:orgname | orgname)[1])"/>

      <xsl:choose>
        <!-- APA: [Tesis Doctoral, Universidad X] -->
        <xsl:when test="$estilo = 'apa'">
          <xsl:text> [</xsl:text>
          <xsl:value-of select="$tipo-tesis"/>
          <xsl:if test="$institucion != ''">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$institucion"/>
          </xsl:if>
          <xsl:text>]</xsl:text>
        </xsl:when>

        <!-- VANCOUVER: [tesis doctoral]. Universidad X (tipo en minúscula) -->
        <xsl:when test="$estilo = 'vancouver'">
          <xsl:text> [</xsl:text>
          <xsl:value-of select="lower-case($tipo-tesis)"/>
          <xsl:text>]</xsl:text>
          <xsl:if test="$institucion != ''">
            <xsl:text>. </xsl:text>
            <xsl:value-of select="$institucion"/>
          </xsl:if>
        </xsl:when>

        <!-- ISO 690: Tesis Doctoral. Universidad X -->
        <xsl:when test="$estilo = 'iso690'">
          <xsl:text>. </xsl:text>
          <xsl:value-of select="$tipo-tesis"/>
          <xsl:if test="$institucion != ''">
            <xsl:text>. </xsl:text>
            <xsl:value-of select="$institucion"/>
          </xsl:if>
        </xsl:when>

        <!-- IEEE: tesis doctoral, Universidad X (minúscula) -->
        <xsl:when test="$estilo = 'ieee'">
          <xsl:text>, </xsl:text>
          <xsl:value-of select="lower-case($tipo-tesis)"/>
          <xsl:if test="$institucion != ''">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$institucion"/>
          </xsl:if>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: iniciales-apa (idéntico a revistas)
       ==========================================================
       "Juan Carlos" → "J. C." -->
  <xsl:template name="iniciales-apa">
    <xsl:param name="nombres"/>
    <xsl:for-each select="tokenize(normalize-space($nombres), '\s+')">
      <xsl:value-of select="substring(., 1, 1)"/>
      <xsl:text>.</xsl:text>
      <xsl:if test="position() != last()"><xsl:text> </xsl:text></xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- ==========================================================
       ========= FASE 4: METADATOS COMPLETOS POR CAPÍTULO =======
       ==========================================================
       Orquestador: emite Highwire + Dublin Core + Open Graph +
       Twitter Cards + JSON-LD Schema.org para cada capítulo.

       FUENTES DE DATOS:
       - Del capítulo (cambia): $capInfo (título, autores, abstract,
         keywords, DOI, licencia).
       - Del libro (heredado, constante): variables globales de Fase 1
         ($titulo_libro, $isbn_print, $editorial, $anio_publicacion,
         $idioma_principal, $imagen_tapa, $doi_libro).

       BASE DOCUMENTAL (Google Scholar Inclusion Guidelines):
       - citation_title = título del capítulo (NO el del libro).
       - citation_book_title = título del libro contenedor.
       - citation_isbn / citation_publisher / citation_publication_date
         para la obra contenedora.
       - DC como complemento (last resort per Scholar); precisión de
         "capítulo" en JSON-LD @type=Chapter (schema.org). -->
  <xsl:template name="emitir-metadatos-capitulo">
    <xsl:param name="capitulo"/>
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>

    <!-- VARIABLES DERIVADAS DEL CAPÍTULO, REUSADAS POR TODOS LOS BLOQUES -->
    <xsl:variable name="capDoi"
                  select="normalize-space(($capInfo/db:biblioid[@class='doi']
                                          | $capInfo/biblioid[@class='doi'])[1])"/>
    <xsl:variable name="capResumen"
                  select="normalize-space(($capInfo/db:abstract/db:para
                                          | $capInfo/abstract/para)[1])"/>
    <xsl:variable name="capLicUrl"
                  select="normalize-space(($capInfo/db:legalnotice[@role='licencia']/db:para/db:link/@xlink:href
                                          | $capInfo/legalnotice[@role='licencia']/para/link/@xlink:href)[1])"/>
    <xsl:variable name="capLang">
      <xsl:choose>
        <xsl:when test="normalize-space($capitulo/@xml:lang) != ''">
          <xsl:value-of select="$capitulo/@xml:lang"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$idioma_principal"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="meta-highwire-cap">
      <xsl:with-param name="capInfo" select="$capInfo"/>
      <xsl:with-param name="capTitulo" select="$capTitulo"/>
      <xsl:with-param name="capDoi" select="$capDoi"/>
      <xsl:with-param name="capResumen" select="$capResumen"/>
      <xsl:with-param name="capLang" select="$capLang"/>
    </xsl:call-template>

    <xsl:call-template name="meta-dc-cap">
      <xsl:with-param name="capInfo" select="$capInfo"/>
      <xsl:with-param name="capTitulo" select="$capTitulo"/>
      <xsl:with-param name="capDoi" select="$capDoi"/>
      <xsl:with-param name="capResumen" select="$capResumen"/>
      <xsl:with-param name="capLicUrl" select="$capLicUrl"/>
      <xsl:with-param name="capLang" select="$capLang"/>
    </xsl:call-template>

    <xsl:call-template name="meta-og-twitter-cap">
      <xsl:with-param name="capTitulo" select="$capTitulo"/>
      <xsl:with-param name="capResumen" select="$capResumen"/>
      <xsl:with-param name="capLang" select="$capLang"/>
    </xsl:call-template>

    <xsl:call-template name="meta-jsonld-cap">
      <xsl:with-param name="capInfo" select="$capInfo"/>
      <xsl:with-param name="capTitulo" select="$capTitulo"/>
      <xsl:with-param name="capDoi" select="$capDoi"/>
      <xsl:with-param name="capResumen" select="$capResumen"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ==========================================================
       BLOQUE 1: HIGHWIRE PRESS (Google Scholar) — CAPÍTULO
       ========================================================== -->
  <xsl:template name="meta-highwire-cap">
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>
    <xsl:param name="capDoi"/>
    <xsl:param name="capResumen"/>
    <xsl:param name="capLang"/>

    <xsl:comment> METADATOS: Highwire Press — Google Scholar (capítulo) </xsl:comment>

    <!-- TÍTULO DEL CAPÍTULO (NO EL DEL LIBRO) -->
    <meta name="citation_title" content="{$capTitulo}"/>

    <!-- TÍTULO DEL LIBRO CONTENEDOR -->
    <meta name="citation_book_title" content="{$titulo_libro}"/>

    <!-- AUTORES DEL CAPÍTULO CON ORCID Y AFILIACIÓN -->
    <xsl:for-each select="$capInfo/db:author | $capInfo/author">
      <meta name="citation_author"
            content="{normalize-space(db:personname/db:surname | personname/surname)}, {normalize-space(db:personname/db:firstname | personname/firstname)}"/>
      <xsl:variable name="orcid_url" select="(db:uri[@type='orcid'] | uri[@type='orcid'])[1]"/>
      <xsl:if test="$orcid_url != ''">
        <meta name="citation_author_orcid" content="{$orcid_url}"/>
      </xsl:if>
      <xsl:variable name="orgname" select="(db:affiliation/db:orgname | affiliation/orgname)[1]"/>
      <xsl:if test="$orgname != ''">
        <meta name="citation_author_institution" content="{normalize-space($orgname)}"/>
      </xsl:if>
    </xsl:for-each>

    <!-- DATOS HEREDADOS DE LA OBRA CONTENEDORA -->
    <xsl:if test="$capDoi != ''">
      <meta name="citation_doi" content="{$capDoi}"/>
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
    <xsl:if test="$anio_cita != ''">
      <meta name="citation_publication_date" content="{$anio_cita}"/>
    </xsl:if>

    <meta name="citation_language" content="{$capLang}"/>

    <!-- RESUMEN DEL CAPÍTULO SI TIENE -->
    <xsl:if test="$capResumen != ''">
      <meta name="citation_abstract" content="{$capResumen}"/>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       BLOQUE 2: DUBLIN CORE — CAPÍTULO
       ==========================================================
       DC como complemento (Scholar lo trata como last resort).
       DC.type = Text (valor DCMI oficial); la precisión "capítulo"
       va en el JSON-LD (@type=Chapter). -->
  <xsl:template name="meta-dc-cap">
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>
    <xsl:param name="capDoi"/>
    <xsl:param name="capResumen"/>
    <xsl:param name="capLicUrl"/>
    <xsl:param name="capLang"/>

    <xsl:comment> METADATOS: Dublin Core (capítulo) </xsl:comment>

    <meta name="DC.title" content="{$capTitulo}"/>
    <meta name="DC.language" content="{$capLang}"/>
    <meta name="DC.type" content="Text"/>
    <meta name="DC.format" content="text/html"/>

    <!-- OBRA CONTENEDORA -->
    <meta name="DC.relation.ispartof" content="{$titulo_libro}"/>

    <xsl:if test="$editorial != ''">
      <meta name="DC.publisher" content="{$editorial}"/>
    </xsl:if>
    <xsl:if test="$capDoi != ''">
      <meta name="DC.identifier" content="https://doi.org/{$capDoi}"/>
    </xsl:if>
    <xsl:if test="$anio_cita != ''">
      <meta name="DC.date" content="{$anio_cita}"/>
    </xsl:if>
    <xsl:if test="$capResumen != ''">
      <meta name="DC.description" content="{$capResumen}"/>
    </xsl:if>
    <xsl:if test="$capLicUrl != ''">
      <meta name="DC.rights" content="{$capLicUrl}"/>
    </xsl:if>

    <!-- AUTORES COMO DC.creator -->
    <xsl:for-each select="$capInfo/db:author | $capInfo/author">
      <meta name="DC.creator"
            content="{normalize-space(db:personname/db:surname | personname/surname)}, {normalize-space(db:personname/db:firstname | personname/firstname)}"/>
    </xsl:for-each>

    <!-- KEYWORDS COMO DC.subject (UNO POR TÉRMINO, TODOS LOS IDIOMAS) -->
    <xsl:for-each select="$capInfo/db:keywordset/db:keyword | $capInfo/keywordset/keyword">
      <meta name="DC.subject" content="{normalize-space(.)}"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ==========================================================
       BLOQUE 3: OPEN GRAPH + TWITTER CARDS — CAPÍTULO
       ========================================================== -->
  <xsl:template name="meta-og-twitter-cap">
    <xsl:param name="capTitulo"/>
    <xsl:param name="capResumen"/>
    <xsl:param name="capLang"/>

    <xsl:comment> METADATOS: Open Graph + Twitter Cards (capítulo) </xsl:comment>

    <!-- og:type=book: el capítulo es parte de un libro -->
    <meta property="og:type" content="book"/>
    <meta property="og:title" content="{$capTitulo}"/>
    <meta property="og:site_name" content="{$titulo_libro}"/>
    <meta property="og:locale" content="{$capLang}"/>
    <xsl:if test="$capResumen != ''">
      <meta property="og:description" content="{$capResumen}"/>
    </xsl:if>
    <xsl:if test="$imagen_tapa != ''">
      <meta property="og:image" content="{$imagen_tapa}"/>
    </xsl:if>
    <xsl:if test="$isbn_print != ''">
      <meta property="og:book:isbn" content="{$isbn_print}"/>
    </xsl:if>

    <meta name="twitter:card" content="summary"/>
    <meta name="twitter:title" content="{$capTitulo}"/>
    <xsl:if test="$capResumen != ''">
      <meta name="twitter:description" content="{$capResumen}"/>
    </xsl:if>
    <xsl:if test="$imagen_tapa != ''">
      <meta name="twitter:image" content="{$imagen_tapa}"/>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       BLOQUE 4: JSON-LD Schema.org — CAPÍTULO (@type=Chapter)
       ==========================================================
       El capítulo es un Chapter que es isPartOf un Book.
       El Book lleva su publisher (Organization) e isbn.
       Los autores son Person con affiliation Organization.
       Construido con xsl:text para control preciso del JSON. -->
  <xsl:template name="meta-jsonld-cap">
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>
    <xsl:param name="capDoi"/>
    <xsl:param name="capResumen"/>

    <xsl:comment> METADATOS: Schema.org JSON-LD (Chapter) </xsl:comment>

    <script type="application/ld+json">
      <xsl:text>{"@context":"https://schema.org","@type":"Chapter",</xsl:text>
      <xsl:text>"name":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$capTitulo"/></xsl:call-template>
      <xsl:text>"</xsl:text>

      <!-- DOI COMO identifier -->
      <xsl:if test="$capDoi != ''">
        <xsl:text>,"identifier":{"@type":"PropertyValue","propertyID":"DOI","value":"</xsl:text>
        <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$capDoi"/></xsl:call-template>
        <xsl:text>"}</xsl:text>
      </xsl:if>

      <!-- ABSTRACT -->
      <xsl:if test="$capResumen != ''">
        <xsl:text>,"abstract":"</xsl:text>
        <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$capResumen"/></xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:if>

      <!-- AUTORES (Person CON affiliation) -->
      <xsl:if test="$capInfo/db:author | $capInfo/author">
        <xsl:text>,"author":[</xsl:text>
        <xsl:for-each select="$capInfo/db:author | $capInfo/author">
          <xsl:if test="position() &gt; 1"><xsl:text>,</xsl:text></xsl:if>
          <xsl:text>{"@type":"Person","name":"</xsl:text>
          <xsl:call-template name="escapar-json">
            <xsl:with-param name="txt"
              select="concat(normalize-space(db:personname/db:firstname | personname/firstname),
                             ' ',
                             normalize-space(db:personname/db:surname | personname/surname))"/>
          </xsl:call-template>
          <xsl:text>"</xsl:text>
          <xsl:variable name="orgname" select="(db:affiliation/db:orgname | affiliation/orgname)[1]"/>
          <xsl:if test="$orgname != ''">
            <xsl:text>,"affiliation":{"@type":"Organization","name":"</xsl:text>
            <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="normalize-space($orgname)"/></xsl:call-template>
            <xsl:text>"}</xsl:text>
          </xsl:if>
          <xsl:variable name="orcid_url" select="(db:uri[@type='orcid'] | uri[@type='orcid'])[1]"/>
          <xsl:if test="$orcid_url != ''">
            <xsl:text>,"identifier":"</xsl:text>
            <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="normalize-space($orcid_url)"/></xsl:call-template>
            <xsl:text>"</xsl:text>
          </xsl:if>
          <xsl:text>}</xsl:text>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
      </xsl:if>

      <!-- isPartOf: EL LIBRO CONTENEDOR -->
      <xsl:text>,"isPartOf":{"@type":"Book","name":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$titulo_libro"/></xsl:call-template>
      <xsl:text>"</xsl:text>
      <xsl:if test="$isbn_print != ''">
        <xsl:text>,"isbn":"</xsl:text>
        <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$isbn_print"/></xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:if>
      <xsl:if test="$editorial != ''">
        <xsl:text>,"publisher":{"@type":"Organization","name":"</xsl:text>
        <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$editorial"/></xsl:call-template>
        <xsl:text>"}</xsl:text>
      </xsl:if>
      <xsl:if test="$anio_cita != ''">
        <xsl:text>,"datePublished":"</xsl:text>
        <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$anio_cita"/></xsl:call-template>
        <xsl:text>"</xsl:text>
      </xsl:if>
      <xsl:text>}</xsl:text>

      <xsl:text>}</xsl:text>
    </script>
  </xsl:template>

  <!-- ==========================================================
       AUXILIAR: ESCAPAR STRING PARA JSON
       ==========================================================
       Escapa backslash, comilla doble y saltos de línea, que son
       los caracteres que romperían el JSON embebido en el script. -->
  <xsl:template name="escapar-json">
    <xsl:param name="txt" as="xs:string"/>
    <xsl:variable name="t1" select="replace($txt, '\\', '\\\\')"/>
    <xsl:variable name="t2" select="replace($t1, '&quot;', '\\&quot;')"/>
    <xsl:variable name="t3" select="replace($t2, '&#10;', ' ')"/>
    <xsl:variable name="t4" select="replace($t3, '&#13;', ' ')"/>
    <xsl:variable name="t5" select="replace($t4, '&#9;', ' ')"/>
    <xsl:value-of select="$t5"/>
  </xsl:template>

  <!-- ==========================================================
       ============= FASE 5: WIDGET "CÓMO CITAR" ================
       ==========================================================
       - emitir-widget-citar: el bloque visual (botones + área + copiar).
         Reutilizable en index (libro) y en capítulo.
       - emitir-citadata-libro / emitir-citadata-capitulo: el <script>
         inline con var citaData = {...} que el gbpublisher.js consume.
         Se inyecta ANTES del <script src> externo (Opción A, Fase 1). -->

  <!-- WIDGET VISUAL: BOTONES DE FORMATO + ÁREA DE CITA + COPIAR.
       Estructura alineada con revistas para reusar CSS (.citar-wrapper,
       .citar-toggle, .citar-formatos, .citar-btn, .citar-texto,
       .citar-copiar) e IDs que el JS espera (citar-output para el área,
       citar-copiar-btn para el botón). El <details> lo hace colapsable.
       El JS inicializa el contenido en DOMContentLoaded (APA por defecto). -->
  <xsl:template name="emitir-widget-citar">
    <div class="citar-wrapper">
      <details>
        <summary class="citar-toggle">Cómo citar</summary>
        <div class="citar-formatos">
          <button class="citar-btn active" onclick="mostrarFormato(this,'apa')">APA</button>
          <button class="citar-btn" onclick="mostrarFormato(this,'ieee')">IEEE</button>
          <button class="citar-btn" onclick="mostrarFormato(this,'vancouver')">Vancouver</button>
          <button class="citar-btn" onclick="mostrarFormato(this,'bibtex')">BibTeX</button>
          <button class="citar-btn" onclick="mostrarFormato(this,'ris')">RIS</button>
        </div>
        <pre class="citar-texto" id="citar-output"></pre>
        <button class="citar-copiar" id="citar-copiar-btn" onclick="copiarCita()">Copiar</button>
      </details>
    </div>
  </xsl:template>

  <!-- INYECCIÓN DE citaData PARA EL LIBRO (index.html) -->
  <xsl:template name="emitir-citadata-libro">
    <script>
      <xsl:text>var citaData = {</xsl:text>
      <xsl:text>"tipo":"libro",</xsl:text>
      <xsl:text>"titulo":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$titulo_libro"/></xsl:call-template>
      <xsl:text>","editorial":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$editorial"/></xsl:call-template>
      <xsl:text>","ciudad":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$ciudad_pub"/></xsl:call-template>
      <xsl:text>","isbn":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$isbn_print"/></xsl:call-template>
      <xsl:text>","doi":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$doi_libro"/></xsl:call-template>
      <xsl:text>","url":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$url_libro"/></xsl:call-template>
      <xsl:text>","anio":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$anio_cita"/></xsl:call-template>
      <xsl:text>",</xsl:text>

      <!-- AUTORES DEL LIBRO -->
      <xsl:text>"autores":[</xsl:text>
      <xsl:for-each select="$info/db:author | $info/author">
        <xsl:if test="position() &gt; 1"><xsl:text>,</xsl:text></xsl:if>
        <xsl:call-template name="persona-json"><xsl:with-param name="persona" select="."/></xsl:call-template>
      </xsl:for-each>
      <xsl:text>],</xsl:text>

      <!-- EDITORES DEL LIBRO -->
      <xsl:text>"editores":[</xsl:text>
      <xsl:for-each select="$info/db:editor | $info/editor">
        <xsl:if test="position() &gt; 1"><xsl:text>,</xsl:text></xsl:if>
        <xsl:call-template name="persona-json"><xsl:with-param name="persona" select="."/></xsl:call-template>
      </xsl:for-each>
      <xsl:text>]</xsl:text>

      <xsl:text>};</xsl:text>
    </script>
  </xsl:template>

  <!-- INYECCIÓN DE citaData PARA UN CAPÍTULO (h-*.html) -->
  <xsl:template name="emitir-citadata-capitulo">
    <xsl:param name="capInfo"/>
    <xsl:param name="capTitulo"/>

    <xsl:variable name="capDoi"
                  select="normalize-space(($capInfo/db:biblioid[@class='doi']
                                          | $capInfo/biblioid[@class='doi'])[1])"/>
    <script>
      <xsl:text>var citaData = {</xsl:text>
      <xsl:text>"tipo":"capitulo",</xsl:text>
      <xsl:text>"titulo":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$capTitulo"/></xsl:call-template>
      <xsl:text>","tituloLibro":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$titulo_libro"/></xsl:call-template>
      <xsl:text>","editorial":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$editorial"/></xsl:call-template>
      <xsl:text>","ciudad":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$ciudad_pub"/></xsl:call-template>
      <xsl:text>","doi":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$capDoi"/></xsl:call-template>
      <xsl:text>","url":"","anio":"</xsl:text>
      <xsl:call-template name="escapar-json"><xsl:with-param name="txt" select="$anio_cita"/></xsl:call-template>
      <xsl:text>",</xsl:text>

      <!-- AUTORES DEL CAPÍTULO -->
      <xsl:text>"autores":[</xsl:text>
      <xsl:for-each select="$capInfo/db:author | $capInfo/author">
        <xsl:if test="position() &gt; 1"><xsl:text>,</xsl:text></xsl:if>
        <xsl:call-template name="persona-json"><xsl:with-param name="persona" select="."/></xsl:call-template>
      </xsl:for-each>
      <xsl:text>],</xsl:text>

      <!-- EDITORES DEL LIBRO (PARA "En: ...") -->
      <xsl:text>"editores":[</xsl:text>
      <xsl:for-each select="$info/db:editor | $info/editor">
        <xsl:if test="position() &gt; 1"><xsl:text>,</xsl:text></xsl:if>
        <xsl:call-template name="persona-json"><xsl:with-param name="persona" select="."/></xsl:call-template>
      </xsl:for-each>
      <xsl:text>]</xsl:text>

      <xsl:text>};</xsl:text>
    </script>
  </xsl:template>

  <!-- AUXILIAR: UNA PERSONA COMO {"apellido":"X","nombre":"Y"} -->
  <xsl:template name="persona-json">
    <xsl:param name="persona"/>
    <xsl:variable name="pn" select="$persona/db:personname | $persona/personname"/>
    <xsl:text>{"apellido":"</xsl:text>
    <xsl:call-template name="escapar-json">
      <xsl:with-param name="txt" select="normalize-space($pn/db:surname | $pn/surname)"/>
    </xsl:call-template>
    <xsl:text>","nombre":"</xsl:text>
    <xsl:call-template name="escapar-json">
      <xsl:with-param name="txt" select="normalize-space($pn/db:firstname | $pn/firstname)"/>
    </xsl:call-template>
    <xsl:text>"}</xsl:text>
  </xsl:template>

</xsl:stylesheet>
