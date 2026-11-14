<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : numero-a-html.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : docs/index.html, LA ENTRADA DEL SITIO HTML AUTÓNOMO
                   DEL NÚMERO (H2, DECISIONES DE ALBERTO DEL 14/11/2026):
                     - A LA IZQUIERDA: LA TAPA, LA REVISTA, LA
                       IDENTIFICACIÓN DEL NÚMERO, LOS ISSN Y LAS
                       DESCARGAS DEL NÚMERO (PDF Y EPUB);
                     - AL CENTRO: EL SUMARIO, CON EL MISMO AGRUPAMIENTO
                       POR TRAMOS (SECCIÓN O DOSSIER) QUE EL PDF Y EL EPUB
                       (revista-comun.xsl). CADA ARTÍCULO ENLAZA A SU
                       PÁGINA (h-{archivo}.html) Y LLEVA SUS AUTORES Y SU
                       PDF.
                   LAS DESCARGAS ESTÁN SIEMPRE: LA REVISTA ES DE ACCESO
                   ABIERTO, Y LAS SALIDAS SE VALIDAN CRUZADAS (ALBERTO,
                   14/11): generar_html_revista.sh NO LLEGA HASTA ACÁ SI
                   FALTA EL PDF O EL EPUB.
                   EL DISEÑO ES EL DE LA ENTRADA DEL LIBRO AUTÓNOMO: DOS
                   COLUMNAS (layout-2col), gbpublisher.css ENLAZADO, SIN
                   PANEL. SIN ESPACIO DE NOMBRES, COMO LAS PÁGINAS DE LOS
                   ARTÍCULOS (jats-a-html-articulo.xsl).
  ENTRADA        : {proyecto}/tmp/numero-datos.xml (VOLCADO 4)
  SALIDA         : docs/index.html (-o)
  PARÁMETROS     : tapa       LA IMAGEN DE LA TAPA EN assets/media/;
                              VACÍA, SIN TAPA
                   pdf_numero EL PDF DEL NÚMERO, RELATIVO (descargas/…).
                              OBLIGATORIO
                   epub       EL EPUB DEL NÚMERO, RELATIVO. OBLIGATORIO
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbrc="urn:gbpublisher:revista-comun"
  xmlns:gbnh="urn:gbpublisher:numero-html"
  exclude-result-prefixes="xs gbrc gbnh">

  <!-- LA CONJUNCIÓN, LA PERSONA, LOS TRAMOS DEL SUMARIO, LA
       IDENTIFICACIÓN DEL NÚMERO Y LOS RÓTULOS: LOS DEL PDF Y EL EPUB -->
  <xsl:include href="revista-comun.xsl"/>

  <xsl:output method="html" html-version="5" encoding="UTF-8" indent="no"/>

  <xsl:param name="tapa" as="xs:string" select="''"/>
  <xsl:param name="pdf_numero" as="xs:string" select="''"/>
  <xsl:param name="epub" as="xs:string" select="''"/>

  <!-- LA VERSIÓN DEL VOLCADO QUE ESTA HOJA SABE LEER -->
  <xsl:variable name="gbnh:version-datos" select="'4'"/>

  <xsl:variable name="d" select="/numero-datos"/>
  <xsl:variable name="principal" as="xs:string?"
    select="(tokenize(string($d/revista/idiomas), ',') ! normalize-space(.)[. ne ''])[1]"/>
  <xsl:variable name="lang" select="gbrc:lang(string($principal))"/>
  <xsl:variable name="revista" select="normalize-space($d/revista/titulo)"/>
  <xsl:variable name="identificacion" select="gbrc:identificacion($d, $lang)"/>

  <!-- ============================================
       Función   : gbnh:titulo
       Propósito : Un título del volcado en una línea: el corte del
                   editor (SC-28) es un espacio
       Parámetros: t As element()?
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbnh:titulo" as="xs:string">
    <xsl:param name="t" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join(
      for $n in $t/node() return (if ($n/self::break) then ' ' else string($n)), ''))"/>
  </xsl:function>

  <!-- ============================================
       Función   : / (plantilla)
       Propósito : La entrada del sitio del número
       Parámetros: (nodo de contexto) — el volcado
       Retorna   : el documento HTML
       ============================================ -->
  <xsl:template match="/">
    <xsl:variable name="especial" select="gbnh:titulo($d/numero/titulo-especial)"/>
    <xsl:variable name="editorial" select="normalize-space(($d/pagina-legal/editorial/nombre, $d/revista/editorial)[normalize-space(.) ne ''][1])"/>

    <!-- APARTADO 1. VALIDACIÓN: LO QUE FALTA FRENA ACÁ, CON UN MENSAJE -->
    <xsl:if test="string($d/@version) ne $gbnh:version-datos">
      <xsl:message terminate="yes">ERROR: el volcado es versión «<xsl:value-of select="$d/@version"/>» y esta hoja lee la <xsl:value-of select="$gbnh:version-datos"/>: actualizá gbpublisher</xsl:message>
    </xsl:if>
    <xsl:if test="empty($principal)">
      <xsl:message terminate="yes">ERROR: la revista no tiene idiomas de publicación. Cargalos en la ficha de la revista.</xsl:message>
    </xsl:if>
    <xsl:if test="normalize-space($pdf_numero) eq '' or normalize-space($epub) eq ''">
      <xsl:message terminate="yes">ERROR: faltan los parámetros pdf_numero y epub (las descargas del número)</xsl:message>
    </xsl:if>

    <!-- APARTADO 2. EL DOCUMENTO -->
    <html lang="{$principal}">
      <head>
        <meta charset="UTF-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title><xsl:value-of select="string-join(($revista, $identificacion)[. ne ''], ', ')"/></title>
        <!-- METADATOS DEL NÚMERO: LOS DE CADA ARTÍCULO ESTÁN EN SU PÁGINA -->
        <meta name="DC.title" content="{string-join(($revista, $identificacion)[. ne ''], ', ')}"/>
        <xsl:if test="$editorial ne ''">
          <meta name="DC.publisher" content="{$editorial}"/>
        </xsl:if>
        <meta name="DC.language" content="{$principal}"/>
        <meta property="og:type" content="website"/>
        <meta property="og:title" content="{string-join(($revista, $identificacion)[. ne ''], ', ')}"/>
        <meta property="og:site_name" content="{$revista}"/>
        <meta property="og:locale" content="{$principal}"/>
        <link rel="preconnect" href="https://fonts.googleapis.com"/>
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous"/>
        <link rel="stylesheet"
              href="https://fonts.googleapis.com/css2?family=Noto+Serif:ital,wght@0,400;0,600;1,400;1,600&amp;family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,600;1,300;1,400;1,600&amp;family=IBM+Plex+Mono:ital,wght@0,400;0,600;1,400&amp;display=swap"/>
        <link rel="stylesheet" href="assets/css/gbpublisher.css"/>
      </head>
      <body class="pagina-revista-index">
        <div class="layout layout-2col" id="mainLayout">

          <!-- APARTADO 3. LA COLUMNA DEL NÚMERO -->
          <aside class="col-left">
            <xsl:if test="$tapa ne ''">
              <div class="tapa-wrapper">
                <img src="assets/media/{$tapa}" alt="{gbrc:rotulo('tapa', $lang)}: {string-join(($revista, $identificacion)[. ne ''], ', ')}"/>
              </div>
            </xsl:if>
            <div class="meta-revista"><xsl:value-of select="$revista"/></div>
            <div class="meta-issn"><xsl:value-of select="$identificacion"/></div>
            <xsl:for-each select="$d/revista/issn[normalize-space(.) ne '']">
              <div class="meta-issn">
                <span class="meta-key">
                  <xsl:value-of select="gbrc:rotulo(if (@tipo eq 'impreso') then 'issn' else 'eissn', $lang)"/>
                  <xsl:text>: </xsl:text>
                </span>
                <xsl:value-of select="normalize-space(.)"/>
              </div>
            </xsl:for-each>
            <xsl:if test="$editorial ne ''">
              <div class="meta-seccion">
                <div class="meta-valor"><xsl:value-of select="$editorial"/></div>
              </div>
            </xsl:if>
            <!-- LAS DESCARGAS DEL NÚMERO: SIEMPRE (ACCESO ABIERTO) -->
            <div class="meta-seccion descarga-libro-wrapper">
              <a class="btn-descargar-pdf" href="{$pdf_numero}">Descargar PDF</a>
              <a class="btn-descargar-epub" href="{$epub}">Descargar EPUB</a>
            </div>
          </aside>

          <!-- APARTADO 4. EL SUMARIO -->
          <main class="col-center">
            <div class="article-type-bar"><xsl:value-of select="$identificacion"/></div>
            <h1 class="article-title"><xsl:value-of select="$revista"/></h1>
            <xsl:if test="$especial ne ''">
              <div class="article-trans-title"><xsl:value-of select="$especial"/></div>
            </xsl:if>
            <div class="article-body">
              <section class="indice-capitulos sumario-revista">
                <h2 class="sec-title"><xsl:value-of select="gbrc:rotulo('sumario', $lang)"/></h2>
                <!-- UN TRAMO POR SERIE SEGUIDA DEL MISMO DOSSIER O, SIN
                     DOSSIER, DE LA MISMA SECCIÓN: LA REGLA DEL PDF -->
                <xsl:for-each-group select="$d/articulo" group-adjacent="gbrc:tramo-sumario(.)">
                  <xsl:variable name="encabezado" select="gbrc:encabezado-tramo($d, current-group()[1], $principal)"/>
                  <div class="parte-estructural">
                    <xsl:if test="$encabezado ne ''">
                      <h3 class="parte-titulo"><xsl:value-of select="$encabezado"/></h3>
                    </xsl:if>
                    <ul class="lista-capitulos">
                      <xsl:for-each select="current-group()">
                        <xsl:variable name="autores" select="gbrc:lista(contribuyente[@rol eq 'autor'] ! gbrc:persona(.), $principal)"/>
                        <li class="item-capitulo" lang="{@idioma}">
                          <a class="link-capitulo" href="h-{@archivo}.html">
                            <span class="cap-titulo"><xsl:value-of select="gbnh:titulo(titulo)"/></span>
                          </a>
                          <xsl:if test="$autores ne ''">
                            <div class="sumario-autores"><xsl:value-of select="$autores"/></div>
                          </xsl:if>
                          <a class="sumario-pdf" href="descargas/{@archivo}.pdf">PDF</a>
                        </li>
                      </xsl:for-each>
                    </ul>
                  </div>
                </xsl:for-each-group>
              </section>
            </div>
          </main>
        </div>
      </body>
    </html>
  </xsl:template>

</xsl:stylesheet>
