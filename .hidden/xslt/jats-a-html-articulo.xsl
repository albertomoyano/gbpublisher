<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-a-html-articulo.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : LA PÁGINA DE UN ARTÍCULO EN EL SITIO HTML AUTÓNOMO DEL
                   NÚMERO (H1, DECISIONES DE ALBERTO DEL 14/11/2026):
                     - EL DISEÑO DEL LIBRO AUTÓNOMO: TRES COLUMNAS CON
                       gbpublisher.css Y gbpublisher.js ENLAZADOS DESDE
                       assets/ (NO METIDOS EN CADA PÁGINA, COMO HACÍA
                       jats-to-html.xsl);
                     - A LA IZQUIERDA: VOLVER AL SUMARIO, LA TAPA DEL
                       NÚMERO, COMPARTIR, EL PDF DEL ARTÍCULO Y LOS DATOS
                       DE LA COLUMNA DEL PDF, EN SU ORDEN;
                     - AL CENTRO: CABECERA, RESÚMENES, CUERPO,
                       AGRADECIMIENTOS, DECLARACIONES Y APÉNDICES;
                     - A LA DERECHA: EL PANEL DE NOTAS, REFERENCIAS Y
                       FIGURAS;
                     - LAS CITAS, LAS REFERENCIAS Y EL «CÓMO CITAR»: DESDE
                       citas.html (SC-57), EL MISMO TEXTO QUE EL PDF Y EL
                       EPUB. POR ESO NO VA EL WIDGET DE CINCO FORMATOS DEL
                       LIBRO, QUE ARMA LA CITA EN JavaScript: LA CITA ES LA
                       DEL ESTILO DE LA REVISTA, COMO EN SU PDF.
  POR QUÉ IMPORTA: IMPORTA jats-to-html.xsl Y USA SU CUERPO (SECCIONES,
                   FIGURAS, CUADROS, CÓDIGO, VERSO, CONVERSACIÓN, NOTAS,
                   MARCAS EN LÍNEA: LA MATRIZ DE SC-30). LA VIEJA NO SE
                   TOCA MÁS QUE PARA SEPARAR fila-compartir: LA SIGUE
                   USANDO m_GenerarHTML (EL CAMINO VIEJO) HASTA SU RETIRO.
                   SU PLANTILLA RAÍZ, LOS METADATOS Y LA COLUMNA DE DATOS
                   LEÍAN EL CANÓNICO VIEJO Y NO SE USAN.
  REFERENCIA     : SC-31: EL PDF. RÓTULOS, TIPOS, FECHAS, NOMBRES Y LA
                   IDENTIFICACIÓN DEL NÚMERO SALEN DE revista-comun.xsl;
                   EL AGRUPAMIENTO DE LAS CITAS, DE cita-jats-comun.xsl.
  ENTRADA        : EL CANÓNICO SIN DOCTYPE (GV-25)
  SALIDA         : docs/h-{archivo}.html (LO DECIDE EL SCRIPT)
  PARÁMETROS     : archivo     EL ARCHIVO DEL ARTÍCULO. OBLIGATORIO
                   bib_dir     LA CARPETA DE LA PASADA DE CITAS. OBLIGATORIO
                   volcado     RUTA ABSOLUTA DE tmp/numero-datos.xml: LA
                               IDENTIFICACIÓN DEL NÚMERO, COMO EN EL EPUB.
                               OBLIGATORIO
                   estilo_cita EL ESTILO DE LA REVISTA (DECLARADO EN
                               jats-to-html.xsl)
                   tapa        LA IMAGEN DE LA TAPA EN assets/media/; VACÍA,
                               SIN TAPA
                   pdf         EL ENLACE DEL PDF DEL ARTÍCULO, RELATIVO A
                               LA PÁGINA; VACÍO, SIN BOTÓN
                   ruta_media, modo_figura, dir_media, codigo_dir: LOS DE
                               jats-to-html.xsl
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
  xmlns:gbc="urn:gbpublisher:codigo"
  xmlns:gbct="urn:gbpublisher:citas"
  xmlns:gbcj="urn:gbpublisher:citas-jats"
  xmlns:gbrc="urn:gbpublisher:revista-comun"
  xmlns:gbh="urn:gbpublisher:revista-html"
  exclude-result-prefixes="xs xlink ali gbc gbct gbcj gbrc gbh">

  <!-- EL CUERPO ES EL DE LA HOJA VIEJA. LO QUE ESTA HOJA DEFINE GANA POR
       PRECEDENCIA DE IMPORTACIÓN -->
  <xsl:import href="jats-to-html.xsl"/>

  <xsl:include href="cita-jats-comun.xsl"/>
  <xsl:include href="revista-comun.xsl"/>
  <xsl:include href="cita-comun.xsl"/>
  <xsl:include href="cita-fragmentos.xsl"/>

  <xsl:output method="html" html-version="5" encoding="UTF-8" indent="no"/>

  <xsl:param name="archivo" as="xs:string" select="''"/>
  <xsl:param name="volcado" as="xs:string" select="''"/>
  <xsl:param name="tapa" as="xs:string" select="''"/>
  <xsl:param name="pdf" as="xs:string" select="''"/>
  <!-- LOS DE LA HOJA VIEJA, CON LOS VALORES DEL SITIO -->
  <xsl:param name="ruta_media" as="xs:string" select="'assets/media'"/>
  <xsl:param name="modo_figura" as="xs:string" select="'html'"/>

  <xsl:variable name="gbh:meta" select="/article/front/article-meta"/>
  <xsl:variable name="gbh:xml-lang" as="xs:string"
    select="(normalize-space(/article/@xml:lang)[. ne ''], 'es')[1]"/>
  <xsl:variable name="gbh:lang" as="xs:string" select="gbrc:lang($gbh:xml-lang)"/>
  <xsl:variable name="gbh:datos" select="if ($volcado ne '') then doc(iri-to-uri(concat('file://', $volcado)))/numero-datos else ()"/>
  <xsl:variable name="gbh:revista" select="normalize-space(/article/front/journal-meta/journal-title-group/journal-title)"/>
  <xsl:variable name="gbh:titulo" select="gbh:plano($gbh:meta/title-group/article-title)"/>
  <xsl:variable name="gbh:doi" select="normalize-space($gbh:meta/article-id[@pub-id-type = 'doi'])"/>
  <!-- LA DIRECCIÓN DEL ARTÍCULO (articulo_ubicacion, tipo pagina): EL
       canonical, LA QUE SE COMPARTE Y LA DE LOS METADATOS -->
  <xsl:variable name="gbh:url" select="normalize-space($gbh:meta/self-uri[@content-type = 'pagina']/@xlink:href)"/>
  <xsl:variable name="gbh:url-pdf" select="normalize-space($gbh:meta/self-uri[@content-type = 'pdf']/@xlink:href)"/>
  <xsl:variable name="gbh:autores" select="$gbh:meta/contrib-group/contrib[@contrib-type = 'author']"/>
  <xsl:variable name="gbh:resumen" select="normalize-space(string-join(($gbh:meta/abstract[gbh:en-idioma(.)], $gbh:meta/abstract)[1]//p, ' '))"/>
  <xsl:variable name="gbh:pub" select="$gbh:meta/pub-date[@date-type = 'pub'][1]"/>

  <!-- ============================================
       Función   : gbh:plano
       Propósito : Un título como texto: el corte de línea (SC-28) es un
                   espacio
       Parámetros: t As element()?
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbh:plano" as="xs:string">
    <xsl:param name="t" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join(
      for $n in $t/node() return (if ($n/self::break) then ' ' else string($n)), ''))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbh:rotulo
       Propósito : Un rótulo de revista-comun.xsl en el idioma del artículo
       Parámetros: clave As xs:string
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbh:rotulo" as="xs:string">
    <xsl:param name="clave" as="xs:string"/>
    <xsl:sequence select="gbrc:rotulo($clave, $gbh:lang)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbh:en-idioma
       Propósito : ¿El elemento está en el idioma del artículo? Sin
                   xml:lang, sí
       Parámetros: e As element()
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbh:en-idioma" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="normalize-space($e/@xml:lang) = ('', $gbh:xml-lang)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbh:marca
       Propósito : Un elemento de citas.html por su id; si falta, corta
                   (GV-23)
       Parámetros: id As xs:string
       Retorna   : element()
       ============================================ -->
  <xsl:function name="gbh:marca" as="element()">
    <xsl:param name="id" as="xs:string"/>
    <xsl:variable name="e" select="key('gbct:por-id', $id, $gbct:citas)"/>
    <xsl:sequence select="if (count($e) = 1) then $e
      else error(QName('urn:gbpublisher:revista-html', 'sin-marca'),
                 concat('[html] citas.html no tiene ', $id,
                        ': el canónico cambió después de la pasada de citas.'))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbh:numero-nota
       Propósito : El número de una nota del texto: las de author-notes
                   no cuentan (van en la columna de datos)
       Parámetros: f As element()
       Retorna   : xs:integer
       ============================================ -->
  <xsl:function name="gbh:numero-nota" as="xs:integer">
    <xsl:param name="f" as="element()"/>
    <xsl:sequence select="count($f/preceding::fn[not(ancestor::author-notes)]) + 1"/>
  </xsl:function>

  <!-- ============================================
       Función   : / (plantilla)
       Propósito : La página del artículo
       Parámetros: (nodo de contexto) — el documento
       Retorna   : el documento HTML
       ============================================ -->
  <xsl:template match="/">

    <!-- APARTADO 1. LOS PARÁMETROS OBLIGATORIOS -->
    <xsl:if test="normalize-space($archivo) eq ''">
      <xsl:message terminate="yes">ERROR: falta el parámetro archivo (el nombre del artículo)</xsl:message>
    </xsl:if>
    <xsl:if test="not($gbct:tex4ht)">
      <xsl:message terminate="yes">ERROR: falta el parámetro bib_dir (la carpeta de preparar_citas_revista.sh)</xsl:message>
    </xsl:if>
    <xsl:if test="empty($gbh:datos)">
      <xsl:message terminate="yes">ERROR: falta el parámetro volcado (tmp/numero-datos.xml)</xsl:message>
    </xsl:if>

    <!-- APARTADO 2. EL DOCUMENTO -->
    <html lang="{$gbh:xml-lang}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title><xsl:value-of select="concat($gbh:titulo, ' — ', $gbh:revista)"/></title>
        <!-- LA PÁGINA DEL ARTÍCULO EN LA BASE ES LA CANÓNICA: REEMPLAZA LOS
             MODOS control Y final DE LA HOJA VIEJA (DECISIÓN DE ALBERTO) -->
        <xsl:if test="$gbh:url ne ''">
          <link rel="canonical" href="{$gbh:url}"/>
        </xsl:if>
        <xsl:call-template name="gbh:metadatos"/>
        <link rel="preconnect" href="https://fonts.googleapis.com"/>
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
        <link rel="stylesheet"
              href="https://fonts.googleapis.com/css2?family=Noto+Serif:ital,wght@0,400;0,600;1,400;1,600&amp;family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,600;1,300;1,400;1,600&amp;family=IBM+Plex+Mono:ital,wght@0,400;0,600;1,400&amp;display=swap"/>
        <link rel="stylesheet" href="assets/css/gbpublisher.css"/>
      </head>
      <body class="pagina-revista-articulo">

        <!-- LOS BOTONES Y EL FONDO DE LOS CAJONES: LOS DEL LIBRO -->
        <button class="panel-toggle" id="panelToggle" onclick="togglePanel()">&#x2192; Mostrar panel</button>
        <button class="fab-meta" onclick="openDrawerMeta()">&#x2261;</button>
        <button class="fab-panel-tablet" onclick="openDrawerPanel()">&#x2192;</button>
        <div class="drawer-backdrop" id="drawerBackdrop" onclick="closeDrawers()"></div>

        <div class="layout layout-3col panel-hidden" id="mainLayout">
          <xsl:call-template name="gbh:col-izquierda"/>
          <xsl:call-template name="gbh:col-centro"/>
          <xsl:call-template name="gbh:panel"/>
        </div>

        <script src="assets/js/gbpublisher.js"></script>
      </body>
    </html>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbh:metadatos
       Propósito : Los metadatos para indexadores y redes, desde el
                   canónico nuevo: Highwire Press (Google Scholar), Dublin
                   Core, Open Graph y Schema.org. Los de la hoja vieja
                   leían el canónico viejo (issn/@pub-type, aff dentro de
                   contrib, el m-*.xml)
       ============================================ -->
  <xsl:template name="gbh:metadatos">
    <xsl:variable name="issn" select="/article/front/journal-meta/issn[normalize-space(.) ne '']"/>
    <xsl:variable name="editorial" select="normalize-space(/article/front/journal-meta/publisher/publisher-name)"/>
    <xsl:variable name="fecha" select="if ($gbh:pub) then string-join(($gbh:pub/year, $gbh:pub/month, $gbh:pub/day) ! normalize-space(.)[. ne ''], '/') else ''"/>
    <xsl:variable name="licencia" select="normalize-space(($gbh:meta/permissions/license[1]/ali:license_ref, $gbh:meta/permissions/license[1]/@xlink:href)[1])"/>
    <xsl:variable name="palabras" select="$gbh:meta/kwd-group[gbh:en-idioma(.)]/kwd ! normalize-space(.)"/>

    <!-- APARTADO 1. HIGHWIRE PRESS -->
    <meta name="citation_title" content="{$gbh:titulo}"/>
    <xsl:for-each select="$gbh:autores">
      <meta name="citation_author"
            content="{if (name) then string-join((normalize-space(name/surname), normalize-space(name/given-names))[. ne ''], ', ') else normalize-space(collab)}"/>
      <xsl:for-each select="//aff[@id = current()/xref[@ref-type = 'aff']/@rid]">
        <meta name="citation_author_institution" content="{gbrc:afiliacion(.)}"/>
      </xsl:for-each>
      <xsl:if test="normalize-space(contrib-id[@contrib-id-type = 'orcid']) ne ''">
        <meta name="citation_author_orcid" content="{normalize-space(contrib-id[@contrib-id-type = 'orcid'])}"/>
      </xsl:if>
    </xsl:for-each>
    <xsl:if test="$fecha ne ''">
      <meta name="citation_publication_date" content="{$fecha}"/>
    </xsl:if>
    <meta name="citation_journal_title" content="{$gbh:revista}"/>
    <xsl:for-each select="$issn">
      <meta name="citation_issn" content="{normalize-space(.)}"/>
    </xsl:for-each>
    <xsl:for-each select="$gbh:meta/volume[normalize-space(.) ne '']">
      <meta name="citation_volume" content="{normalize-space(.)}"/>
    </xsl:for-each>
    <xsl:for-each select="$gbh:meta/issue[normalize-space(.) ne '']">
      <meta name="citation_issue" content="{normalize-space(.)}"/>
    </xsl:for-each>
    <xsl:for-each select="$gbh:meta/fpage[normalize-space(.) ne '']">
      <meta name="citation_firstpage" content="{normalize-space(.)}"/>
    </xsl:for-each>
    <xsl:for-each select="$gbh:meta/lpage[normalize-space(.) ne '']">
      <meta name="citation_lastpage" content="{normalize-space(.)}"/>
    </xsl:for-each>
    <xsl:if test="$gbh:doi ne ''">
      <meta name="citation_doi" content="{$gbh:doi}"/>
    </xsl:if>
    <meta name="citation_language" content="{$gbh:xml-lang}"/>
    <xsl:if test="$editorial ne ''">
      <meta name="citation_publisher" content="{$editorial}"/>
    </xsl:if>
    <xsl:for-each select="$palabras">
      <meta name="citation_keywords" content="{.}"/>
    </xsl:for-each>
    <xsl:if test="$gbh:url ne ''">
      <meta name="citation_abstract_html_url" content="{$gbh:url}"/>
      <meta name="citation_fulltext_html_url" content="{$gbh:url}"/>
    </xsl:if>
    <!-- SOLO UNA DIRECCIÓN ABSOLUTA: LA DEL PDF EN LA BASE -->
    <xsl:if test="$gbh:url-pdf ne ''">
      <meta name="citation_pdf_url" content="{$gbh:url-pdf}"/>
    </xsl:if>

    <!-- APARTADO 2. DUBLIN CORE -->
    <meta name="DC.title" content="{$gbh:titulo}"/>
    <xsl:for-each select="$gbh:autores">
      <meta name="DC.creator" content="{if (name) then string-join((normalize-space(name/surname), normalize-space(name/given-names))[. ne ''], ', ') else normalize-space(collab)}"/>
    </xsl:for-each>
    <xsl:if test="$gbh:pub">
      <meta name="DC.date" content="{string-join(($gbh:pub/year, $gbh:pub/month, $gbh:pub/day) ! normalize-space(.)[. ne ''], '-')}"/>
    </xsl:if>
    <xsl:if test="$gbh:doi ne ''">
      <meta name="DC.identifier" content="https://doi.org/{$gbh:doi}"/>
    </xsl:if>
    <meta name="DC.language" content="{$gbh:xml-lang}"/>
    <xsl:if test="$editorial ne ''">
      <meta name="DC.publisher" content="{$editorial}"/>
    </xsl:if>
    <xsl:if test="$licencia ne ''">
      <meta name="DC.rights" content="{$licencia}"/>
    </xsl:if>
    <xsl:for-each select="$palabras">
      <meta name="DC.subject" content="{.}"/>
    </xsl:for-each>
    <xsl:if test="$gbh:resumen ne ''">
      <meta name="DC.description" content="{$gbh:resumen}"/>
    </xsl:if>
    <meta name="DC.type" content="Text"/>
    <meta name="DC.format" content="text/html"/>

    <!-- APARTADO 3. OPEN GRAPH -->
    <meta property="og:type" content="article"/>
    <meta property="og:title" content="{$gbh:titulo}"/>
    <meta property="og:site_name" content="{$gbh:revista}"/>
    <meta property="og:locale" content="{$gbh:xml-lang}"/>
    <xsl:if test="$gbh:url ne ''">
      <meta property="og:url" content="{$gbh:url}"/>
    </xsl:if>
    <xsl:if test="$gbh:resumen ne ''">
      <meta property="og:description" content="{$gbh:resumen}"/>
    </xsl:if>

    <!-- APARTADO 4. SCHEMA.ORG. EL SERIALIZADOR JSON ESCAPA EL TEXTO; «</»
         SE ESCRIBE «<\/» PARA QUE NINGÚN DATO CIERRE EL <script> -->
    <xsl:variable name="ld" select="map:merge((
      map{'@context': 'https://schema.org', '@type': 'ScholarlyArticle',
          'headline': $gbh:titulo, 'inLanguage': $gbh:xml-lang,
          'author': array{ $gbh:autores ! map:merge((
              map{'@type': if (name) then 'Person' else 'Organization', 'name': gbrc:nombre(.)},
              if (normalize-space(contrib-id[@contrib-id-type = 'orcid']) ne '')
              then map{'sameAs': normalize-space(contrib-id[@contrib-id-type = 'orcid'])} else ())) },
          'isPartOf': map:merge((
              map{'@type': 'PublicationIssue'},
              if (normalize-space($gbh:meta/issue) ne '') then map{'issueNumber': normalize-space($gbh:meta/issue)} else (),
              map{'isPartOf': map:merge((
                map{'@type': array{'PublicationVolume', 'Periodical'}, 'name': $gbh:revista},
                if (normalize-space($gbh:meta/volume) ne '') then map{'volumeNumber': normalize-space($gbh:meta/volume)} else (),
                if (exists($issn)) then map{'issn': array{ $issn ! normalize-space(.) }} else ()))}))},
      if ($gbh:pub) then map{'datePublished': string-join(($gbh:pub/year, $gbh:pub/month, $gbh:pub/day) ! normalize-space(.)[. ne ''], '-')} else (),
      if ($gbh:doi ne '') then map{'identifier': concat('https://doi.org/', $gbh:doi)} else (),
      if ($gbh:url ne '') then map{'url': $gbh:url} else (),
      if ($licencia ne '') then map{'license': $licencia} else (),
      if ($editorial ne '') then map{'publisher': map{'@type': 'Organization', 'name': $editorial}} else (),
      if (exists($palabras)) then map{'keywords': string-join($palabras, ', ')} else ()
      ))" xmlns:map="http://www.w3.org/2005/xpath-functions/map"/>
    <script type="application/ld+json">
      <xsl:value-of select="replace(serialize($ld, map{'method': 'json'}), '&lt;/', '&lt;\\/')"/>
    </script>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbh:col-izquierda
       Propósito : La columna de datos: volver al sumario, la tapa del
                   número, compartir, el PDF del artículo y lo de la
                   columna del PDF, en su orden
       ============================================ -->
  <xsl:template name="gbh:col-izquierda">
    <xsl:variable name="m" select="$gbh:meta"/>
    <xsl:variable name="perm" select="$m/permissions"/>
    <xsl:variable name="licencia" select="normalize-space(($perm/license[1]/ali:license_ref, $perm/license[1]/@xlink:href)[1])"/>
    <xsl:variable name="eid" select="normalize-space($m/elocation-id)"/>
    <xsl:variable name="notas" select="$m/author-notes/fn[@fn-type = 'other']"/>
    <xsl:variable name="eventos" select="$m/pub-history/event/date | $m/history/date"/>

    <aside class="col-left">

      <!-- APARTADO 1. EL SUMARIO DEL NÚMERO, LA TAPA Y LA REVISTA -->
      <a href="index.html" class="btn-ir-inicio">Ir al sumario</a>
      <xsl:if test="$tapa ne ''">
        <div class="tapa-wrapper">
          <img src="{$ruta_media}/{$tapa}" alt="{gbh:rotulo('tapa')}: {$gbh:revista}"/>
        </div>
      </xsl:if>
      <div class="meta-revista"><xsl:value-of select="$gbh:revista"/></div>
      <div class="meta-issn"><xsl:value-of select="gbrc:identificacion($gbh:datos, $gbh:lang)"/></div>

      <!-- APARTADO 2. COMPARTIR (CON LA DIRECCIÓN DEL ARTÍCULO) Y EL PDF -->
      <xsl:call-template name="fila-compartir">
        <xsl:with-param name="url" select="$gbh:url"/>
        <xsl:with-param name="titulo" select="$gbh:titulo"/>
      </xsl:call-template>
      <xsl:if test="$pdf ne ''">
        <div class="meta-seccion">
          <a class="btn-descargar-pdf" href="{$pdf}">Descargar PDF</a>
        </div>
      </xsl:if>

      <!-- APARTADO 3. AUTORES: NOMBRE, ORCID, CORREO Y AFILIACIONES -->
      <xsl:if test="$gbh:autores">
        <div class="meta-seccion">
          <xsl:for-each select="$gbh:autores">
            <xsl:variable name="c" select="."/>
            <xsl:variable name="orcid" select="normalize-space(contrib-id[@contrib-id-type = 'orcid'])"/>
            <div class="autor-item">
              <div class="autor-nombre-linea">
                <span class="autor-nombre"><xsl:value-of select="gbrc:nombre(.)"/></span>
                <xsl:if test="$orcid ne ''">
                  <xsl:text> </xsl:text>
                  <a class="autor-orcid" href="{$orcid}" target="_blank" rel="noopener noreferrer">ORCID &#x2197;</a>
                </xsl:if>
              </div>
              <xsl:for-each select="email[normalize-space(.) ne '']">
                <div class="autor-email">
                  <xsl:if test="$c/@corresp = 'yes'">
                    <span class="meta-key"><xsl:value-of select="gbh:rotulo('correspondencia')"/>: </span>
                  </xsl:if>
                  <a href="mailto:{normalize-space(.)}"><xsl:value-of select="normalize-space(.)"/></a>
                </div>
              </xsl:for-each>
              <xsl:for-each select="(//aff[@id = $c/xref[@ref-type = 'aff']/@rid], aff)">
                <div class="autor-afil"><xsl:value-of select="gbrc:afiliacion(.)"/></div>
              </xsl:for-each>
            </div>
          </xsl:for-each>
        </div>
      </xsl:if>

      <!-- APARTADO 4. NOTAS DE AUTOR -->
      <xsl:if test="$notas">
        <div class="meta-seccion">
          <div class="meta-label"><xsl:value-of select="gbh:rotulo('notas')"/></div>
          <xsl:for-each select="$notas/p">
            <div class="meta-valor"><xsl:apply-templates select="node()"/></div>
          </xsl:for-each>
        </div>
      </xsl:if>

      <!-- APARTADO 5. EDICIÓN Y TRADUCCIÓN -->
      <xsl:for-each-group select="$m/contrib-group/contrib[@contrib-type = ('editor', 'translator')]" group-by="@contrib-type">
        <xsl:sort select="if (current-grouping-key() eq 'editor') then 1 else 2"/>
        <div class="meta-seccion">
          <div class="meta-label">
            <xsl:value-of select="gbh:rotulo(if (current-grouping-key() eq 'editor') then 'editor' else 'traductor')"/>
          </div>
          <div class="meta-valor"><xsl:value-of select="string-join(current-group() ! gbrc:nombre(.), ', ')"/></div>
        </div>
      </xsl:for-each-group>

      <!-- APARTADO 6. FECHAS -->
      <xsl:if test="$eventos or $gbh:pub">
        <div class="meta-seccion">
          <xsl:for-each select="$eventos[@date-type = ('received', 'rev-recd', 'accepted')]">
            <xsl:sort select="index-of(('received', 'rev-recd', 'accepted'), string(@date-type))"/>
            <xsl:sort select="@iso-8601-date"/>
            <div class="meta-valor">
              <span class="meta-key"><xsl:value-of select="gbh:rotulo(@date-type)"/>: </span>
              <xsl:value-of select="gbrc:fecha(., $gbh:lang)"/>
            </div>
          </xsl:for-each>
          <xsl:for-each select="$gbh:pub">
            <div class="meta-valor">
              <span class="meta-key"><xsl:value-of select="gbh:rotulo('pub')"/>: </span>
              <xsl:value-of select="gbrc:fecha(., $gbh:lang)"/>
            </div>
          </xsl:for-each>
        </div>
      </xsl:if>

      <!-- APARTADO 7. IDENTIFICADORES -->
      <xsl:if test="$gbh:doi ne '' or $eid ne ''">
        <div class="meta-seccion">
          <xsl:if test="$gbh:doi ne ''">
            <div class="meta-valor">
              <span class="meta-key">DOI: </span>
              <a class="doi-link" href="https://doi.org/{$gbh:doi}" target="_blank" rel="noopener noreferrer">
                <xsl:value-of select="concat('https://doi.org/', $gbh:doi)"/>
              </a>
            </div>
          </xsl:if>
          <xsl:if test="$eid ne ''">
            <div class="meta-valor">
              <span class="meta-key"><xsl:value-of select="gbh:rotulo('eid')"/>: </span>
              <xsl:value-of select="$eid"/>
            </div>
          </xsl:if>
        </div>
      </xsl:if>

      <!-- APARTADO 8. CÓMO CITAR: EL TEXTO DE biblatex (E1), EL DEL PDF -->
      <div class="meta-seccion">
        <div class="meta-label"><xsl:value-of select="gbh:rotulo('comocitar')"/></div>
        <div class="meta-valor como-citar">
          <xsl:apply-templates select="gbh:marca(concat('gbcita-', $archivo, '-comocitar'))" mode="gbct:fragmento"/>
        </div>
      </div>

      <!-- APARTADO 9. DERECHOS Y LICENCIA -->
      <xsl:if test="$perm/copyright-statement or $perm/license">
        <div class="meta-seccion">
          <div class="meta-label"><xsl:value-of select="gbh:rotulo('licencia')"/></div>
          <div class="meta-valor">
            <xsl:value-of select="string-join((
              normalize-space($perm/copyright-statement)[. ne ''],
              normalize-space($perm/license[1]/license-p)[. ne '']), '. ')"/>
          </div>
          <xsl:if test="$licencia ne ''">
            <a class="licencia-link" href="{$licencia}" target="_blank" rel="noopener noreferrer">
              <xsl:value-of select="$licencia"/>
            </a>
          </xsl:if>
        </div>
      </xsl:if>
    </aside>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbh:col-centro
       Propósito : Cabecera, resúmenes, cuerpo, agradecimientos,
                   declaraciones y apéndices
       ============================================ -->
  <xsl:template name="gbh:col-centro">
    <xsl:variable name="tg" select="$gbh:meta/title-group"/>
    <main class="col-center">

      <!-- APARTADO 1. CABECERA -->
      <div class="article-type-bar"><xsl:value-of select="gbrc:tipo(string(/article/@article-type), $gbh:lang)"/></div>
      <h1 class="article-title"><xsl:apply-templates select="$tg/article-title/node()"/></h1>
      <xsl:for-each select="$tg/subtitle">
        <div class="article-trans-title"><xsl:apply-templates select="node()"/></div>
      </xsl:for-each>
      <xsl:for-each select="$tg/trans-title-group">
        <div class="article-trans-title" lang="{@xml:lang}">
          <xsl:apply-templates select="trans-title/node()"/>
          <xsl:for-each select="trans-subtitle">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="node()"/>
          </xsl:for-each>
        </div>
      </xsl:for-each>
      <xsl:if test="$gbh:autores">
        <div class="autoria-inline">
          <xsl:value-of select="gbrc:lista($gbh:autores ! gbrc:nombre(.), $gbh:xml-lang)"/>
        </div>
      </xsl:if>

      <!-- APARTADO 2. RESÚMENES -->
      <xsl:call-template name="gbh:resumenes"/>

      <!-- APARTADO 3. EL TEXTO -->
      <div class="article-body">
        <xsl:apply-templates select="/article/body"/>
        <xsl:apply-templates select="/article/back/ack"/>
        <xsl:call-template name="gbh:declaraciones"/>
        <xsl:apply-templates select="/article/back/app-group"/>
      </div>
    </main>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbh:resumenes
       Propósito : Cada resumen con su rótulo en su idioma y sus palabras
                   clave (las del autor primero, después cada
                   vocabulario), desplegables como en el libro
       ============================================ -->
  <xsl:template name="gbh:resumenes">
    <xsl:variable name="m" select="$gbh:meta"/>
    <xsl:if test="$m/abstract | $m/trans-abstract">
      <div class="abstracts-wrapper">
        <xsl:for-each select="$m/abstract | $m/trans-abstract">
          <xsl:variable name="lang" select="(normalize-space(@xml:lang)[. ne ''], $gbh:xml-lang)[1]"/>
          <xsl:variable name="l2" select="gbrc:lang($lang)"/>
          <xsl:variable name="grupos" select="$m/kwd-group[normalize-space((@xml:lang, $gbh:xml-lang)[1]) = $lang][kwd]"/>
          <details class="abstract-block" open="open" lang="{$lang}">
            <summary class="abstract-lang-label"><xsl:value-of select="gbrc:rotulo('resumen', $l2)"/></summary>
            <div class="abstract-texto">
              <xsl:for-each select="p | sec">
                <xsl:choose>
                  <xsl:when test="self::sec">
                    <xsl:for-each select="p">
                      <p>
                        <xsl:if test="position() = 1">
                          <strong><xsl:apply-templates select="../title/node()"/><xsl:text>. </xsl:text></strong>
                        </xsl:if>
                        <xsl:apply-templates select="node()"/>
                      </p>
                    </xsl:for-each>
                  </xsl:when>
                  <xsl:otherwise>
                    <p><xsl:apply-templates select="node()"/></p>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </div>
            <xsl:for-each select="$grupos">
              <xsl:sort select="if (not(@kwd-group-type) or @kwd-group-type = 'author') then 0 else 1"/>
              <p class="abstract-keywords">
                <strong>
                  <xsl:value-of select="if (not(@kwd-group-type) or @kwd-group-type = 'author')
                                        then gbrc:rotulo('palabras', $l2)
                                        else (@vocab, @kwd-group-type)[1]"/>
                  <xsl:text>: </xsl:text>
                </strong>
                <xsl:value-of select="string-join(kwd ! normalize-space(.), '; ')"/>
              </p>
            </xsl:for-each>
          </details>
        </xsl:for-each>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbh:declaraciones
       Propósito : Las declaraciones, como en el PDF y el EPUB
       ============================================ -->
  <xsl:template name="gbh:declaraciones">
    <xsl:variable name="m" select="$gbh:meta"/>
    <xsl:variable name="con-roles" select="$gbh:autores[role]"/>
    <xsl:variable name="fg" select="$m/funding-group"/>
    <xsl:variable name="fin-texto" select="$fg/funding-statement[gbh:en-idioma(.)][1]"/>
    <xsl:variable name="coi" select="$m/author-notes/fn[@fn-type = 'coi-statement'][gbh:en-idioma(.)][1]"/>
    <xsl:variable name="datos" select="/article/back/sec[@sec-type = 'data-availability'][gbh:en-idioma(.)][1]"/>

    <xsl:if test="$con-roles or $fg/award-group or $fin-texto or $coi or $datos">
      <div class="sec declaraciones">
        <h2 class="sec-title"><xsl:value-of select="gbh:rotulo('declaraciones')"/></h2>

        <!-- APARTADO 1. CONTRIBUCIONES: «Nombre: rol, rol.» POR AUTOR -->
        <xsl:if test="$con-roles">
          <p>
            <strong><xsl:value-of select="gbh:rotulo('contribuciones')"/><xsl:text>. </xsl:text></strong>
            <xsl:for-each select="$con-roles">
              <xsl:value-of select="gbrc:nombre(.)"/>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="string-join(role ! normalize-space((string(.)[normalize-space(.) ne ''], @vocab-term)[1]), ', ')"/>
              <xsl:text>. </xsl:text>
            </xsl:for-each>
          </p>
        </xsl:if>

        <!-- APARTADO 2. FINANCIAMIENTO -->
        <xsl:if test="$fin-texto or $fg/award-group">
          <p>
            <strong><xsl:value-of select="gbh:rotulo('financiamiento')"/><xsl:text>. </xsl:text></strong>
            <xsl:choose>
              <xsl:when test="$fin-texto"><xsl:value-of select="normalize-space($fin-texto)"/></xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="string-join($fg/award-group ! (
                  normalize-space(string-join(funding-source//institution, ' '))
                  || (if (award-id) then ' (' || string-join(award-id ! normalize-space(.), ', ') || ')' else '')
                  ), '; ')"/>
                <xsl:text>.</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </p>
        </xsl:if>

        <!-- APARTADO 3. CONFLICTO DE INTERESES -->
        <xsl:if test="$coi">
          <p>
            <strong><xsl:value-of select="gbh:rotulo('coi')"/><xsl:text>. </xsl:text></strong>
            <xsl:for-each select="$coi/p">
              <xsl:if test="position() gt 1"><xsl:text> </xsl:text></xsl:if>
              <xsl:apply-templates select="node()"/>
            </xsl:for-each>
          </p>
        </xsl:if>

        <!-- APARTADO 4. DISPONIBILIDAD DE DATOS -->
        <xsl:if test="$datos">
          <p>
            <strong>
              <xsl:value-of select="if (normalize-space($datos/title) ne '') then normalize-space($datos/title) else gbh:rotulo('datos')"/>
              <xsl:text>. </xsl:text>
            </strong>
            <xsl:for-each select="$datos/p">
              <xsl:if test="position() gt 1"><xsl:text> </xsl:text></xsl:if>
              <xsl:apply-templates select="node()"/>
            </xsl:for-each>
          </p>
        </xsl:if>
      </div>
    </xsl:if>
  </xsl:template>

  <!-- AGRADECIMIENTOS Y APÉNDICES: LA HOJA VIEJA NO LOS DIBUJABA. VAN COMO
       UNA SECCIÓN DE PRIMER NIVEL -->
  <xsl:template match="back/ack | app-group/app">
    <div class="sec" id="{@id}">
      <xsl:if test="normalize-space(title) ne ''">
        <h2 class="sec-title"><xsl:apply-templates select="title/node()"/></h2>
      </xsl:if>
      <xsl:apply-templates select="* except (title, label)"/>
    </div>
  </xsl:template>
  <xsl:template match="app-group">
    <xsl:apply-templates select="app"/>
  </xsl:template>

  <!-- LA DISPONIBILIDAD DE DATOS SALE EN LAS DECLARACIONES -->
  <xsl:template match="back/sec[@sec-type = 'data-availability']"/>

  <!-- ============================================
       Plantilla : gbh:panel
       Propósito : El panel de la derecha: notas y figuras las arma
                   gbpublisher.js desde el texto; las referencias, esta
                   hoja desde citas.html (SC-57), en el orden de biblatex
       ============================================ -->
  <xsl:template name="gbh:panel">
    <aside class="col-right" id="rightPanel">
      <div class="panel-tabs">
        <button class="panel-tab active" id="tab-notas" onclick="switchTab('notas')">
          <xsl:text>Notas </xsl:text><span class="tab-count" id="count-notas">0</span>
        </button>
        <button class="panel-tab" id="tab-refs" onclick="switchTab('refs')">
          <xsl:text>Referencias </xsl:text><span class="tab-count" id="count-refs">0</span>
        </button>
        <button class="panel-tab" id="tab-figs" onclick="switchTab('figs')">
          <xsl:text>Figuras </xsl:text><span class="tab-count" id="count-figs">0</span>
        </button>
      </div>
      <div class="panel-content">
        <div class="panel-section active" id="panel-notas"></div>
        <div class="panel-section" id="panel-refs">
          <xsl:call-template name="gbh:referencias"/>
        </div>
        <div class="panel-section" id="panel-figs"></div>
      </div>
    </aside>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbh:referencias
       Propósito : Las referencias que imprimió biblatex para el
                   artículo, unidas con su ref del canónico por la clave:
                   su id es el data-ref-id de las citas
       ============================================ -->
  <xsl:template name="gbh:referencias">
    <xsl:variable name="entradas" select="gbct:entradas-bib($archivo, true(), gbct:estilo-numerico($estilo_cita))"/>
    <xsl:variable name="refs" select="/article/back/ref-list//ref"/>
    <xsl:choose>
      <xsl:when test="exists($entradas)">
        <xsl:variable name="clase-num" select="gbct:clase-etiquetas($entradas)"/>
        <xsl:for-each select="$entradas">
          <xsl:variable name="clave" select="gbct:clave-entrada(.)"/>
          <xsl:variable name="ref" select="$refs[gbct:clave(@id) = $clave][1]"/>
          <xsl:if test="empty($ref)">
            <xsl:message terminate="yes">
              <xsl:text>[html] biblatex imprimió </xsl:text>
              <xsl:value-of select="$clave"/>
              <xsl:text> y la lista de referencias del canónico no la tiene (</xsl:text>
              <xsl:value-of select="$archivo"/>
              <xsl:text>).</xsl:text>
            </xsl:message>
          </xsl:if>
          <div class="panel-item ref-item ref-biblatex{$clase-num}" data-ref-id="{$ref/@id}"
               onclick="irAlTexto('{$ref/@id}')" style="cursor:pointer">
            <xsl:call-template name="gbh:etiqueta">
              <xsl:with-param name="dd" select="."/>
            </xsl:call-template>
            <xsl:apply-templates select="." mode="gbct:fragmento"/>
          </div>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <p class="drawer-vacio">Sin referencias.</p>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- LA ETIQUETA [n] O n. DE UNA ENTRADA. gbct:etiqueta LA ESCRIBE EN EL
       ESPACIO DE NOMBRES XHTML (LIBROS Y EPUB); ESTA HOJA SALE SIN ESPACIO
       DE NOMBRES, COMO jats-to-html.xsl -->
  <xsl:template name="gbh:etiqueta">
    <xsl:param name="dd" as="element()"/>
    <xsl:variable name="etiqueta" select="gbct:etiqueta-entrada($dd)"/>
    <xsl:if test="$etiqueta != ''">
      <span class="ref-numero"><xsl:value-of select="concat($etiqueta, ' ')"/></span>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Función   : xref[@ref-type='bibr'] (plantilla)
       Propósito : Un grupo de citas con el texto de biblatex; las citas
                   absorbidas por el grupo anterior no emiten nada. En el
                   modo text-only de la hoja vieja (las notas del panel) la
                   cita sale como texto: esa plantilla llama a esta y se
                   queda con su texto
       Parámetros: (nodo de contexto) — el xref
       Retorna   : el texto de la cita, con sus enlaces al panel
       ============================================ -->
  <xsl:template match="xref[@ref-type = 'bibr']">
    <xsl:if test="gbcj:inicia-grupo(.)">
      <xsl:apply-templates select="gbh:marca(concat('gbcita-', gbcj:id-cita(., $archivo)))" mode="gbct:fragmento">
        <xsl:with-param name="grupo" select="gbcj:grupo-desde(.)" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!-- EL ENLACE DE UNA CITA (CONTRATO DE cita-fragmentos.xsl): EL DEL
       LIBRO, QUE ABRE EL PANEL EN SU REFERENCIA -->
  <xsl:template name="gbct:enlace-cita">
    <xsl:param name="rid" as="xs:string"/>
    <xsl:param name="contenido"/>
    <a class="xref-bibr cita-ref" data-ref-id="{$rid}"
       onclick="highlightPanel('refs','{$rid}')" style="cursor:pointer">
      <xsl:copy-of select="$contenido"/>
    </a>
  </xsl:template>

  <!-- EL SEPARADOR ENTRE DOS CITAS: SE SUPRIME SOLO SI LA SEGUNDA QUEDÓ EN
       EL GRUPO DE LA PRIMERA. LA MISMA REGLA QUE EL PDF Y EL EPUB. GANA A
       LOS SUPRESORES DE LA HOJA VIEJA -->
  <xsl:template match="text()[gbcj:es-separador(.)]
                             [preceding-sibling::node()[1][self::xref[@ref-type = 'bibr']]]
                             [following-sibling::node()[1][self::xref[@ref-type = 'bibr']]]"
                mode="#default text-only nota-panel" priority="10">
    <xsl:if test="not(gbcj:agrupables(preceding-sibling::node()[1], following-sibling::node()[1]))">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Función   : fn (plantilla)
       Propósito : La llamada de una nota del texto, con su contenido para
                   el panel (el contrato de gbpublisher.js: data-fn-id y
                   data-fn-text). Como la de la hoja vieja, con el número
                   sin las notas de author-notes
       Parámetros: (nodo de contexto) — la nota
       Retorna   : la llamada
       ============================================ -->
  <xsl:template match="fn">
    <xsl:variable name="n" select="gbh:numero-nota(.)"/>
    <xsl:variable name="fn-html">
      <xsl:apply-templates select="*[not(self::label)]" mode="nota-panel"/>
    </xsl:variable>
    <a class="fn-ref" data-fn-id="fn-{$n}"
       data-fn-text="{normalize-space(serialize($fn-html, map{'method':'html', 'html-version':5.0, 'indent':false()}))}"
       onclick="highlightPanel('notas', 'fn-{$n}')" href="#panel-fn-fn-{$n}">
      <xsl:value-of select="$n"/>
    </a>
  </xsl:template>

  <!-- EL CORTE DE LÍNEA DE UN TÍTULO ES UN ESPACIO EN PANTALLA -->
  <xsl:template match="break">
    <xsl:text> </xsl:text>
  </xsl:template>

</xsl:stylesheet>
