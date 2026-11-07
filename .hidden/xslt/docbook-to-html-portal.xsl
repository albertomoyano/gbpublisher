<?xml version="1.0" encoding="UTF-8"?>
<!--
=========================================================
docbook-to-html-portal.xsl — HTML del libro integrado al portal
=========================================================
UBICACIÓN: ~/.gbpublisher/xslt/docbook-to-html-portal.xsl

PROPÓSITO
  La salida HTML de un libro con destino_html = 'portal' (1.22.0): el
  libro se lee dentro del marco del portal de gbWeb al que pertenece.
  Es la misma salida que la autónoma en contenido; cambia el marco.

POR QUÉ IMPORTA Y NO COPIA
  Esta hoja IMPORTA docbook-to-html.xsl y reemplaza solo la plantilla raíz
  y las que arman cada página. Todo el vocabulario DocBook (secciones,
  figuras, notas, citas, cuadros) es el de la hoja autónoma, sin copia:
  una corrección allá vale acá. Y a la inversa, nada de lo que se escribe
  acá puede cambiar la salida autónoma, que no lee esta hoja.

LA PÁGINA (MODELO 2, DECIDIDO EL 05/11/2026)
  - La cabecera y el pie del portal, copiados del marco que publica gbWeb
    (docs/marco/ del portal), sin banderas. El script los baja, controla
    su sha256 y los deja en docs/assets/marco/ ANTES de esta hoja.
  - La barra del libro, fija al desplazar: «Índice» abre un menú de 600 px
    sobre el texto; a la derecha, dónde se está y Anterior / Siguiente.
  - Dos columnas fijas en el ancho útil del portal (1168 px):
    texto 600 | calle 24 | panel 544. El panel siempre está.
  - En la cabeza del texto: «Cómo citar» y el PDF del capítulo.
  - Debajo de 1232 px, el panel es un cajón (gbpublisher-integrado.css).

LAS PRIMERAS: PORTADA, CRÉDITOS Y DEDICATORIA (DECISIÓN DEL 05/11/2026)
  Una página cada una, como en el EPUB y sin portadilla (SC-25):
    index.html             la portada: adonde lleva «Leer en línea»
    creditos.html          los créditos
    h-<dedicatoria>.html   la dedicatoria, si la hay, como en el PDF (SC-31)
  Son pasos de la lectura (Anterior / Siguiente) pero no entran en el
  menú del índice, como en el nav del EPUB. A la derecha, «Cómo citar» del
  libro. La portada y los créditos los escribe Gambas
  (m_GenerarEpubLibro.EscribirPrimerasHtml) en primeras_dir, con el mismo
  código que las páginas del EPUB.

PARÁMETROS PROPIOS (ADEMÁS DE LOS DE LA HOJA AUTÓNOMA)
  marco_dir     ruta absoluta de docs/assets/marco/
  primeras_dir  ruta absoluta de tmp/html-portal/

DETERMINISMO
  Sin fechas ni azar: la misma entrada y el mismo marco dan los mismos
  bytes.
=========================================================
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:h="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:gbct="urn:gbpublisher:citas"
                xmlns:gbi="urn:gbpublisher:integrado"
                exclude-result-prefixes="db h xs gbct gbi">

  <!-- LA HOJA AUTÓNOMA: SUS PLANTILLAS Y VARIABLES. LAS DE ACÁ LAS REEMPLAZAN
       POR PRECEDENCIA DE IMPORTACIÓN -->
  <xsl:import href="docbook-to-html.xsl"/>

  <!-- ==========================================================
       PARÁMETROS
       ========================================================== -->
  <xsl:param name="marco_dir" as="xs:string" required="yes"/>
  <xsl:param name="primeras_dir" as="xs:string" required="yes"/>

  <!-- ==========================================================
       EL MARCO DEL PORTAL
       ==========================================================
       EL IDIOMA DEL MARCO ES EL DEL LIBRO SI EL PORTAL LO TIENE: SE COMPARA
       LA PRIMERA PARTE DEL CÓDIGO (pt-BR → pt). SI NO, EL CASTELLANO, QUE
       gbWeb SIEMPRE PUBLICA. LOS FRAGMENTOS SON .xml DESDE EL 07/11/2026:
       UN SERVIDOR PUEDE REESCRIBIR LOS .html (NETLIFY, «PRETTY URLS») -->
  <xsl:variable name="marco_base" as="xs:string"
                select="lower-case(tokenize($idioma_principal, '[-_]')[1])"/>
  <xsl:variable name="marco_idioma" as="xs:string"
                select="if (doc-available(concat($marco_dir, '/', $marco_base, '/cabecera.xml')))
                        then $marco_base else 'es'"/>
  <xsl:variable name="marco_cabecera"
                select="doc(concat($marco_dir, '/', $marco_idioma, '/cabecera.xml'))/*"/>
  <xsl:variable name="marco_pie"
                select="doc(concat($marco_dir, '/', $marco_idioma, '/pie.xml'))/*"/>

  <!-- LAS PRIMERAS QUE ESCRIBIÓ GAMBAS. LA PORTADA SOLO EXISTE SI EL LIBRO LA
       DECLARA (SC-25); LOS CRÉDITOS, SIEMPRE -->
  <xsl:variable name="ruta_portada" select="concat($primeras_dir, '/portada.xhtml')"/>
  <xsl:variable name="ruta_creditos" select="concat($primeras_dir, '/creditos.xhtml')"/>
  <xsl:variable name="primera_portada"
                select="if (doc-available($ruta_portada))
                        then doc($ruta_portada)//h:section[1] else ()"/>
  <xsl:variable name="primera_creditos"
                select="if (doc-available($ruta_creditos))
                        then doc($ruta_creditos)//h:section[1] else ()"/>

  <!-- ==========================================================
       LAS PIEZAS QUE TIENEN PÁGINA, EN ORDEN DE LECTURA
       ==========================================================
       LAS DEL MANIFIESTO CUYO NODO ESTÁ EN EL CANÓNICO, MENOS LA
       DEDICATORIA, QUE VA EN LA ENTRADA (SC-31). ES LA MISMA REGLA QUE
       DECIDE QUÉ PÁGINAS SE ESCRIBEN: EL MENÚ Y ANTERIOR / SIGUIENTE NO
       PUEDEN NOMBRAR UNA PÁGINA QUE NO EXISTE. SE ARMA CON for-each Y NO
       CON UN PASO DE RUTA PARA CONSERVAR EL ORDEN DEL MANIFIESTO (GV-183) -->
  <xsl:variable name="piezas" as="element()*">
    <xsl:for-each select="$manifiesto//capitulo">
      <xsl:variable name="idEsperado" select="concat('cap-', @id_capitulo)"/>
      <xsl:if test="$book/*[@xml:id = $idEsperado]
                    [not(self::db:dedication or self::dedication)]">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <!-- LAS DEDICATORIAS DEL MANIFIESTO QUE ESTÁN EN EL CANÓNICO -->
  <xsl:variable name="dedicatorias" as="element()*">
    <xsl:for-each select="$manifiesto//capitulo">
      <xsl:variable name="idEsperado" select="concat('cap-', @id_capitulo)"/>
      <xsl:if test="$book/*[@xml:id = $idEsperado][self::db:dedication or self::dedication]">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>

  <!-- ==========================================================
       EL RECORRIDO: TODAS LAS PÁGINAS EN ORDEN DE LECTURA
       ==========================================================
       PORTADA, CRÉDITOS, DEDICATORIA Y LAS PIEZAS. ES LO QUE SIGUEN
       ANTERIOR / SIGUIENTE. LAS DOS PRIMERAS NO TIENEN ENTRADA EN EL
       MANIFIESTO: SON ELEMENTOS gbi:paso CON SU PÁGINA Y SU ETIQUETA, Y LAS
       FUNCIONES DE ABAJO LOS RECONOCEN -->
  <xsl:variable name="paso_portada" as="element()">
    <gbi:paso pagina="index.html" etiqueta="{$titulo_libro}"/>
  </xsl:variable>
  <xsl:variable name="paso_creditos" as="element()">
    <gbi:paso pagina="creditos.html" etiqueta="Créditos"/>
  </xsl:variable>
  <xsl:variable name="recorrido" as="element()*"
                select="($paso_portada,
                         if ($primera_creditos) then $paso_creditos else (),
                         $dedicatorias,
                         $piezas)"/>

  <!-- ==========================================================
       FUNCIONES
       ========================================================== -->

  <!-- EL NÚMERO DE UNA PIEZA: SOLO LAS DEL CUERPO PRINCIPAL (a-) NUMERAN, Y
       POR SU POSICIÓN ENTRE ELLAS, COMO EN EL ÍNDICE DE LA SALIDA AUTÓNOMA -->
  <xsl:function name="gbi:numero" as="xs:string">
    <xsl:param name="capManif" as="element()"/>
    <xsl:variable name="cuerpo"
                  select="$manifiesto//capitulo[starts-with(@nombre_archivo, 'a-')]"/>
    <xsl:sequence select="if (starts-with($capManif/@nombre_archivo, 'a-'))
                          then string(count($cuerpo[. &lt;&lt; $capManif]) + 1)
                          else ''"/>
  </xsl:function>

  <!-- EL TÍTULO DE UNA PIEZA, LEÍDO DE SU NODO EN EL CANÓNICO -->
  <xsl:function name="gbi:titulo" as="xs:string">
    <xsl:param name="capManif" as="element()"/>
    <xsl:variable name="idEsperado" select="concat('cap-', $capManif/@id_capitulo)"/>
    <xsl:variable name="nodo" select="$book/*[@xml:id = $idEsperado]"/>
    <!-- UN gbi:paso (PORTADA, CRÉDITOS) TRAE SU ETIQUETA -->
    <xsl:sequence select="if ($capManif/self::gbi:paso) then string($capManif/@etiqueta)
                          else normalize-space(($nodo/db:info/db:title | $nodo/info/title)[1])"/>
  </xsl:function>

  <!-- «2. Título» PARA EL CUERPO PRINCIPAL; EL TÍTULO SOLO PARA EL RESTO -->
  <xsl:function name="gbi:etiqueta" as="xs:string">
    <xsl:param name="capManif" as="element()"/>
    <xsl:variable name="numero" select="gbi:numero($capManif)"/>
    <xsl:sequence select="if ($numero != '')
                          then concat($numero, '. ', gbi:titulo($capManif))
                          else gbi:titulo($capManif)"/>
  </xsl:function>

  <!-- LA PÁGINA DE UNA PIEZA -->
  <xsl:function name="gbi:pagina" as="xs:string">
    <xsl:param name="capManif" as="element()"/>
    <xsl:sequence select="if ($capManif/self::gbi:paso) then string($capManif/@pagina)
                          else concat('h-', $capManif/@nombre_archivo, '.html')"/>
  </xsl:function>

  <!-- ==========================================================
       PLANTILLA RAÍZ
       ========================================================== -->
  <xsl:template match="/">
    <!-- 0. ESTILO SIN CAMINO: LA MISMA GUARDA QUE LA HOJA AUTÓNOMA -->
    <xsl:if test="not($gbct:tex4ht) and not($estilo_cita = ('apa', 'iso690', 'vancouver', 'ieee'))">
      <xsl:message terminate="yes">
        <xsl:text>&#10;[docbook-to-html-portal] ESTILO DE CITA SIN SALIDA HTML: </xsl:text>
        <xsl:value-of select="$estilo_cita"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:message>
    </xsl:if>

    <!-- 1. SIN EL MARCO NO HAY PÁGINA: EL SCRIPT LO BAJA ANTES -->
    <xsl:if test="not($marco_cabecera) or not($marco_pie)">
      <xsl:message terminate="yes">
        <xsl:text>&#10;[docbook-to-html-portal] FALTA EL MARCO DEL PORTAL EN </xsl:text>
        <xsl:value-of select="$marco_dir"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:message>
    </xsl:if>

    <!-- 2. UNA PÁGINA POR PASO DEL RECORRIDO, CON SUS VECINAS PARA
         ANTERIOR / SIGUIENTE -->
    <xsl:for-each select="$recorrido">
      <xsl:variable name="pos" select="position()"/>
      <xsl:choose>
        <xsl:when test=". is $paso_portada or . is $paso_creditos
                        or exists(. intersect $dedicatorias)">
          <xsl:call-template name="emitir-primera-portal">
            <xsl:with-param name="paso" select="."/>
            <xsl:with-param name="anterior" select="$recorrido[$pos - 1]"/>
            <xsl:with-param name="siguiente" select="$recorrido[$pos + 1]"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="emitir-pieza-portal">
            <xsl:with-param name="capManif" select="."/>
            <xsl:with-param name="anterior" select="$recorrido[$pos - 1]"/>
            <xsl:with-param name="siguiente" select="$recorrido[$pos + 1]"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:template>

  <!-- ==========================================================
       UNA PRIMERA: PORTADA (index.html), CRÉDITOS O DEDICATORIA
       ==========================================================
       EL MISMO ESQUELETO DE LAS PIEZAS, CON EL CONTENIDO DE LA PRIMERA EN
       LA COLUMNA DEL TEXTO Y «CÓMO CITAR» DEL LIBRO A LA DERECHA. LOS
       METADATOS DEL LIBRO (HIGHWIRE, DC, OG) VAN SOLO EN LA PORTADA: TRES
       PÁGINAS DECLARANDO EL MISMO LIBRO CONFUNDEN A LOS INDEXADORES -->
  <xsl:template name="emitir-primera-portal">
    <xsl:param name="paso" as="element()"/>
    <xsl:param name="anterior" as="element()?"/>
    <xsl:param name="siguiente" as="element()?"/>

    <xsl:variable name="esPortada" select="$paso is $paso_portada"/>

    <xsl:result-document href="docs/{gbi:pagina($paso)}" format="html5">
      <html lang="{$idioma_principal}">
        <head>
          <meta charset="UTF-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
          <title>
            <xsl:if test="not($esPortada)">
              <xsl:value-of select="gbi:titulo($paso)"/>
              <xsl:text> — </xsl:text>
            </xsl:if>
            <xsl:value-of select="$titulo_libro"/>
          </title>
          <xsl:if test="$esPortada">
            <xsl:call-template name="emitir-meta-highwire-libro"/>
            <xsl:call-template name="emitir-meta-dc-libro"/>
            <xsl:call-template name="emitir-meta-og-twitter-libro"/>
          </xsl:if>
          <xsl:call-template name="emitir-hojas-portal"/>
        </head>
        <body class="libro-integrado">

          <!-- 1. LA CABECERA DEL PORTAL: COMPARTE EL LIBRO DESDE LA PORTADA Y
               CADA PÁGINA DESDE LAS DEMÁS -->
          <xsl:call-template name="emitir-marco">
            <xsl:with-param name="fragmento" select="$marco_cabecera"/>
            <xsl:with-param name="url"
              select="if ($url_libro = '') then ''
                      else if ($esPortada) then $url_libro
                      else concat($url_libro, gbi:pagina($paso))"/>
            <xsl:with-param name="titulo" select="$titulo_libro"/>
          </xsl:call-template>

          <!-- 2. LA BARRA DEL LIBRO -->
          <xsl:call-template name="emitir-barra-libro">
            <xsl:with-param name="actual" select="$paso"/>
            <xsl:with-param name="anterior" select="$anterior"/>
            <xsl:with-param name="siguiente" select="$siguiente"/>
          </xsl:call-template>

          <div class="contenedor marco-libro">
            <div class="layout layout-dos" id="mainLayout">

              <!-- 3. LA PRIMERA -->
              <main class="col-center inicio-libro">
                <xsl:choose>
                  <xsl:when test="$esPortada">
                    <xsl:call-template name="emitir-portada-portal"/>
                  </xsl:when>
                  <xsl:when test="$paso is $paso_creditos">
                    <section class="creditos-libro">
                      <xsl:apply-templates select="$primera_creditos/node()" mode="primeras"/>
                    </section>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="emitir-dedicatoria"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="emitir-pasos-pie">
                  <xsl:with-param name="anterior" select="$anterior"/>
                  <xsl:with-param name="siguiente" select="$siguiente"/>
                </xsl:call-template>
                <xsl:call-template name="emitir-pie-colofon"/>
              </main>

              <!-- 4. A LA DERECHA, «CÓMO CITAR» DEL LIBRO -->
              <aside class="col-right col-right-inicio">
                <xsl:call-template name="emitir-widget-citar"/>
              </aside>

            </div>
          </div>

          <!-- 5. EL PIE DEL PORTAL -->
          <xsl:call-template name="emitir-marco">
            <xsl:with-param name="fragmento" select="$marco_pie"/>
            <xsl:with-param name="url" select="''"/>
            <xsl:with-param name="titulo" select="''"/>
          </xsl:call-template>

          <xsl:call-template name="emitir-citadata-libro"/>
          <xsl:call-template name="emitir-scripts-portal"/>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- ==========================================================
       LA PORTADA DE LA PÁGINA DE ENTRADA
       ==========================================================
       LA DE GAMBAS SI EL LIBRO DECLARA LA PIEZA. SI NO, UNA PORTADA
       MÍNIMA CON TÍTULO, SUBTÍTULO Y AUTORÍA: EN EL EPUB LA TAPA HACE ESE
       PAPEL, PERO UNA PÁGINA WEB SIN TÍTULO NO SE PUEDE LEER -->
  <xsl:template name="emitir-portada-portal">
    <section class="portada-libro">
      <xsl:choose>
        <xsl:when test="$primera_portada">
          <xsl:apply-templates select="$primera_portada/node()" mode="primeras"/>
        </xsl:when>
        <xsl:otherwise>
          <p class="portada-autores"><xsl:call-template name="emitir-autoria-libro"/></p>
          <h1 class="portada-titulo"><xsl:value-of select="$titulo_libro"/></h1>
          <xsl:if test="$subtitulo != ''">
            <p class="portada-subtitulo"><xsl:value-of select="$subtitulo"/></p>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </section>
  </xsl:template>

  <!-- ==========================================================
       PÁGINA DE UNA PIEZA: h-{nombre_archivo}.html
       ========================================================== -->
  <xsl:template name="emitir-pieza-portal">
    <xsl:param name="capManif" as="element()"/>
    <xsl:param name="anterior" as="element()?"/>
    <xsl:param name="siguiente" as="element()?"/>

    <xsl:variable name="idEsperado" select="concat('cap-', $capManif/@id_capitulo)"/>
    <xsl:variable name="capitulo" select="$book/*[@xml:id = $idEsperado]"/>
    <xsl:variable name="capInfo" select="$capitulo/db:info | $capitulo/info"/>
    <xsl:variable name="capTitulo" select="gbi:titulo($capManif)"/>

    <xsl:result-document href="docs/{gbi:pagina($capManif)}" format="html5">
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
          <xsl:call-template name="emitir-hojas-portal"/>
        </head>
        <body class="libro-integrado">

          <!-- 1. LA CABECERA DEL PORTAL: COMPARTE ESTA PIEZA. LA DIRECCIÓN SE
               ARMA COMO EN LA SALIDA AUTÓNOMA: LA DEL LIBRO, QUE TERMINA EN
               «/», MÁS LA PÁGINA -->
          <xsl:call-template name="emitir-marco">
            <xsl:with-param name="fragmento" select="$marco_cabecera"/>
            <xsl:with-param name="url"
              select="if ($url_libro != '') then concat($url_libro, gbi:pagina($capManif)) else ''"/>
            <xsl:with-param name="titulo" select="$capTitulo"/>
          </xsl:call-template>

          <!-- 2. LA BARRA DEL LIBRO -->
          <xsl:call-template name="emitir-barra-libro">
            <xsl:with-param name="actual" select="$capManif"/>
            <xsl:with-param name="anterior" select="$anterior"/>
            <xsl:with-param name="siguiente" select="$siguiente"/>
          </xsl:call-template>

          <div class="contenedor marco-libro">
            <!-- DEBAJO DE 1232 px EL PANEL ES UN CAJÓN: SU BOTÓN Y SU FONDO.
                 ARRIBA DE ESE ANCHO, LA HOJA LOS OCULTA -->
            <button class="fab-panel-tablet" onclick="openDrawerPanel()">&#x2192;</button>
            <div class="drawer-backdrop" id="drawerBackdrop" onclick="closeDrawers()"></div>

            <div class="layout layout-dos" id="mainLayout">

              <!-- 3. EL TEXTO -->
              <main class="col-center">
                <xsl:call-template name="emitir-cabeza-capitulo">
                  <xsl:with-param name="capitulo" select="$capitulo"/>
                  <xsl:with-param name="capInfo" select="$capInfo"/>
                  <xsl:with-param name="capTitulo" select="$capTitulo"/>
                </xsl:call-template>

                <!-- LO QUE EN LA SALIDA AUTÓNOMA VA EN LA COLUMNA IZQUIERDA -->
                <div class="cabeza-acciones">
                  <xsl:call-template name="emitir-widget-citar"/>
                  <xsl:call-template name="emitir-boton-pdf-capitulo">
                    <xsl:with-param name="capInfo" select="$capInfo"/>
                  </xsl:call-template>
                </div>

                <div class="article-body">
                  <xsl:call-template name="emitir-cuerpo-capitulo">
                    <xsl:with-param name="capitulo" select="$capitulo"/>
                    <xsl:with-param name="capInfo" select="$capInfo"/>
                  </xsl:call-template>
                </div>

                <xsl:call-template name="emitir-pasos-pie">
                  <xsl:with-param name="anterior" select="$anterior"/>
                  <xsl:with-param name="siguiente" select="$siguiente"/>
                </xsl:call-template>
                <xsl:call-template name="emitir-pie-colofon"/>
              </main>

              <!-- 4. EL PANEL: EL MISMO DE LA SALIDA AUTÓNOMA -->
              <xsl:call-template name="emitir-col-right-drawer">
                <xsl:with-param name="capitulo" select="$capitulo"/>
              </xsl:call-template>

            </div>
          </div>

          <!-- 5. EL PIE DEL PORTAL -->
          <xsl:call-template name="emitir-marco">
            <xsl:with-param name="fragmento" select="$marco_pie"/>
            <xsl:with-param name="url" select="''"/>
            <xsl:with-param name="titulo" select="''"/>
          </xsl:call-template>

          <xsl:call-template name="emitir-citadata-capitulo">
            <xsl:with-param name="capInfo" select="$capInfo"/>
            <xsl:with-param name="capTitulo" select="$capTitulo"/>
          </xsl:call-template>
          <xsl:call-template name="emitir-scripts-portal"/>
        </body>
      </html>
    </xsl:result-document>
  </xsl:template>

  <!-- ==========================================================
       HOJAS DE ESTILO
       ==========================================================
       EN ESTE ORDEN: LA DEL PORTAL (CON SUS FUENTES, SERVIDAS DESDE EL
       PROPIO SITIO), LA DEL LIBRO Y LA QUE LAS ACOMODA. SIN GOOGLE FONTS
       Y SIN IBM PLEX: UNA SOLA FAMILIA, NOTO -->
  <xsl:template name="emitir-hojas-portal">
    <link rel="stylesheet" href="assets/marco/marco.css"/>
    <link rel="stylesheet" href="assets/css/gbpublisher.css"/>
    <link rel="stylesheet" href="assets/css/gbpublisher-integrado.css"/>
  </xsl:template>

  <!-- ==========================================================
       SCRIPTS AL PIE
       ========================================================== -->
  <xsl:template name="emitir-scripts-portal">
    <script src="assets/js/gbpublisher.js"></script>
    <!-- EL MENÚ DEL ÍNDICE ES UNA CASILLA (SIN JS); ESTO SOLO LO CIERRA CON Esc -->
    <script>document.addEventListener('keydown', function (e) { if (e.key === 'Escape') { document.getElementById('indice-abierto').checked = false; } });</script>
  </xsl:template>

  <!-- ==========================================================
       LA BARRA DEL LIBRO Y EL MENÚ DEL ÍNDICE
       ==========================================================
       SIN JS: LA CASILLA ABRE Y CIERRA EL MENÚ. TIENE QUE SER HERMANA
       ANTERIOR DEL FONDO Y DEL MENÚ PARA QUE EL SELECTOR ~ LOS ALCANCE.
       actual: EL PASO DEL RECORRIDO DE ESTA PÁGINA -->
  <xsl:template name="emitir-barra-libro">
    <xsl:param name="actual" as="element()?"/>
    <xsl:param name="anterior" as="element()?"/>
    <xsl:param name="siguiente" as="element()?"/>

    <div class="barra-libro">
      <div class="contenedor">
        <input type="checkbox" id="indice-abierto" class="barra-casilla"/>
        <div class="barra-fila">
          <label for="indice-abierto" class="barra-indice">&#9776; Índice</label>
          <div class="barra-donde">
            <a href="index.html"><xsl:value-of select="$titulo_libro"/></a>
            <xsl:if test="not($actual is $paso_portada)">
              <xsl:text> · </xsl:text>
              <xsl:value-of select="gbi:etiqueta($actual)"/>
            </xsl:if>
          </div>
          <nav class="barra-pasos" aria-label="Pasos">
            <xsl:call-template name="emitir-paso">
              <xsl:with-param name="destino" select="$anterior"/>
              <xsl:with-param name="texto" select="'← Anterior'"/>
            </xsl:call-template>
            <xsl:call-template name="emitir-paso">
              <xsl:with-param name="destino" select="$siguiente"/>
              <xsl:with-param name="texto" select="'Siguiente →'"/>
            </xsl:call-template>
          </nav>
        </div>
        <!-- EL FONDO ES OTRA ETIQUETA DE LA MISMA CASILLA: UN CLIC AFUERA CIERRA.
             SIN aria-hidden: EN UNA ETIQUETA ASOCIADA NO VALE (vnu) -->
        <label for="indice-abierto" class="indice-fondo"></label>
        <nav class="indice-menu" aria-label="Índice del libro">
          <div class="indice-cabeza">
            <xsl:if test="$imagen_tapa != ''">
              <img src="{$imagen_tapa}" alt="Cubierta de {$titulo_libro}"/>
            </xsl:if>
            <div>
              <p class="indice-titulo">
                <a href="index.html">
                  <xsl:if test="$actual is $paso_portada">
                    <xsl:attribute name="class" select="'actual'"/>
                  </xsl:if>
                  <xsl:value-of select="$titulo_libro"/>
                </a>
              </p>
              <xsl:if test="$subtitulo != ''">
                <p class="indice-sub"><xsl:value-of select="$subtitulo"/></p>
              </xsl:if>
              <p class="indice-autoria"><xsl:call-template name="emitir-autoria-libro"/></p>
            </div>
          </div>
          <ol>
            <xsl:for-each select="$piezas">
              <li>
                <!-- LA PIEZA ABIERTA, EN NEGRITA (DECISIÓN DE ALBERTO) -->
                <xsl:if test=". is $actual">
                  <xsl:attribute name="class" select="'actual'"/>
                </xsl:if>
                <a href="{gbi:pagina(.)}">
                  <span class="indice-num"><xsl:value-of select="gbi:numero(.)"/></span>
                  <span><xsl:value-of select="gbi:titulo(.)"/></span>
                </a>
              </li>
            </xsl:for-each>
          </ol>
        </nav>
      </div>
    </div>
  </xsl:template>

  <!-- UN PASO DE LA BARRA. SIN DESTINO (ANTERIOR EN LA PORTADA, SIGUIENTE
       EN LA ÚLTIMA PIEZA) QUEDA INACTIVO, SIN ENLACE -->
  <xsl:template name="emitir-paso">
    <xsl:param name="destino" as="element()?"/>
    <xsl:param name="texto" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$destino">
        <a href="{gbi:pagina($destino)}"><xsl:value-of select="$texto"/></a>
      </xsl:when>
      <xsl:otherwise>
        <span class="paso-inactivo"><xsl:value-of select="$texto"/></span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==========================================================
       ANTERIOR / SIGUIENTE AL FINAL DEL TEXTO
       ==========================================================
       CON LA ETIQUETA DE CADA VECINA DEL RECORRIDO -->
  <xsl:template name="emitir-pasos-pie">
    <xsl:param name="anterior" as="element()?"/>
    <xsl:param name="siguiente" as="element()?"/>
    <nav class="pasos-pie" aria-label="Pasos">
      <xsl:choose>
        <xsl:when test="$anterior">
          <a class="paso-anterior" href="{gbi:pagina($anterior)}">
            <small>← Anterior</small>
            <xsl:value-of select="gbi:etiqueta($anterior)"/>
          </a>
        </xsl:when>
        <!-- UN LUGAR VACÍO: «SIGUIENTE» QUEDA A LA DERECHA -->
        <xsl:otherwise><span></span></xsl:otherwise>
      </xsl:choose>
      <xsl:if test="$siguiente">
        <a class="paso-siguiente" href="{gbi:pagina($siguiente)}">
          <small>Siguiente →</small>
          <xsl:value-of select="gbi:etiqueta($siguiente)"/>
        </a>
      </xsl:if>
    </nav>
  </xsl:template>

  <!-- ==========================================================
       NOMBRE DE AUTOR CON SU ORCID
       ==========================================================
       REEMPLAZA LA PLANTILLA DE LA HOJA AUTÓNOMA, QUE ENLAZA EL NOMBRE.
       ACÁ VA COMO EN LA FICHA DEL PORTAL (gbWeb, plantilla personas): EL
       NOMBRE SIN ENLACE Y, DESPUÉS, EL ÍCONO DE ORCID, QUE ES EL ENLACE. EL
       ÍCONO ES EL MISMO PNG DEL PORTAL, EMBEBIDO EN gbpublisher-integrado.css
       (.orcid): EL ENLACE NO TIENE TEXTO, Y SU NOMBRE ACCESIBLE ES aria-label -->
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
    <xsl:value-of select="$nombreCompleto"/>
    <xsl:if test="$orcid != ''">
      <xsl:text>&#160;</xsl:text>
      <!-- EL title MUESTRA EL IDENTIFICADOR SOLO, SIN LA DIRECCIÓN -->
      <a class="orcid" href="{$orcid}"
         title="ORCID {replace($orcid, '^https?://(www\.)?orcid\.org/', '')}"
         aria-label="ORCID de {$nombreCompleto}"></a>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       AUTORÍA DEL LIBRO, EN TEXTO PLANO
       ==========================================================
       LA DE LA PORTADA DE LA SALIDA AUTÓNOMA, SIN LOS ENLACES AL ORCID:
       VA EN EL MENÚ Y EN LA PORTADA MÍNIMA -->
  <xsl:template name="emitir-autoria-libro">
    <xsl:for-each select="$info/db:author | $info/author">
      <xsl:call-template name="separador-autoria">
        <xsl:with-param name="pos" select="position()"/>
        <xsl:with-param name="total" select="last()"/>
        <xsl:with-param name="nombre" select="(db:personname/db:firstname | personname/firstname)[1]"/>
      </xsl:call-template>
      <xsl:value-of select="normalize-space(concat(db:personname/db:firstname | personname/firstname, ' ',
                                                   db:personname/db:surname | personname/surname))"/>
    </xsl:for-each>
    <xsl:if test="($info/db:author | $info/author) and ($info/db:editor | $info/editor)">
      <xsl:text> · </xsl:text>
    </xsl:if>
    <xsl:for-each select="$info/db:editor | $info/editor">
      <xsl:call-template name="separador-autoria">
        <xsl:with-param name="pos" select="position()"/>
        <xsl:with-param name="total" select="last()"/>
        <xsl:with-param name="nombre" select="(db:personname/db:firstname | personname/firstname)[1]"/>
      </xsl:call-template>
      <xsl:value-of select="normalize-space(concat(db:personname/db:firstname | personname/firstname, ' ',
                                                   db:personname/db:surname | personname/surname))"/>
    </xsl:for-each>
    <xsl:if test="$info/db:editor | $info/editor">
      <xsl:call-template name="marca-editor-db">
        <xsl:with-param name="estilo" select="$estilo_cita"/>
        <xsl:with-param name="editores" select="$info/db:editor | $info/editor"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ==========================================================
       COPIA DEL MARCO (CABECERA O PIE DEL PORTAL)
       ==========================================================
       LOS FRAGMENTOS DE gbWeb SON XML SIN ESPACIO DE NOMBRES: CADA
       ELEMENTO PASA AL DE XHTML, COMO EL RESTO DE LA PÁGINA. EL SVG DE LOS
       ÍCONOS CONSERVA EL SUYO. DOS AJUSTES:
         - el logo es relativo al fragmento (../media/…): en el libro, el
           marco está en assets/marco/;
         - compartir trae {u} y {t}: se completan con la dirección y el
           título de esta página. Sin dirección del libro (url-libro
           vacía), compartir no va: los enlaces quedarían sin destino. -->
  <xsl:template name="emitir-marco">
    <xsl:param name="fragmento" as="element()"/>
    <xsl:param name="url" as="xs:string"/>
    <xsl:param name="titulo" as="xs:string"/>
    <xsl:apply-templates select="$fragmento" mode="marco">
      <xsl:with-param name="u" select="encode-for-uri($url)" tunnel="yes"/>
      <xsl:with-param name="t" select="encode-for-uri($titulo)" tunnel="yes"/>
      <xsl:with-param name="hayUrl" select="$url != ''" tunnel="yes"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*[namespace-uri() = '']" mode="marco" priority="1">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*" mode="marco"/>
      <xsl:apply-templates mode="marco"/>
    </xsl:element>
  </xsl:template>

  <!-- COMPARTIR SIN DIRECCIÓN: NO VA -->
  <xsl:template match="nav[tokenize(@class, '\s+') = 'compartir']" mode="marco" priority="2">
    <xsl:param name="hayUrl" as="xs:boolean" tunnel="yes"/>
    <xsl:if test="$hayUrl">
      <xsl:next-match/>
    </xsl:if>
  </xsl:template>

  <!-- EL SVG Y CUALQUIER OTRO ESPACIO DE NOMBRES, TAL CUAL -->
  <xsl:template match="*" mode="marco">
    <xsl:copy-of select="." copy-namespaces="no"/>
  </xsl:template>

  <xsl:template match="@*" mode="marco">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="img/@src[starts-with(., '../')]" mode="marco">
    <xsl:attribute name="src" select="concat('assets/marco/', substring(., 4))"/>
  </xsl:template>

  <!-- encode-for-uri NO DEJA $ NI \ SIN ESCAPAR: EL REEMPLAZO ES SEGURO -->
  <xsl:template match="a/@href[contains(., '{u}') or contains(., '{t}')]" mode="marco">
    <xsl:param name="u" as="xs:string" tunnel="yes"/>
    <xsl:param name="t" as="xs:string" tunnel="yes"/>
    <xsl:attribute name="href" select="replace(replace(., '\{u\}', $u), '\{t\}', $t)"/>
  </xsl:template>

  <xsl:template match="text() | comment()" mode="marco">
    <xsl:copy/>
  </xsl:template>

  <!-- LOS BLANCOS DE LA SANGRÍA DEL FRAGMENTO NO SE COPIAN: LA SALIDA SE
       SANGRA SOLA (indent="yes") Y SE DUPLICABAN LAS LÍNEAS EN BLANCO -->
  <xsl:template match="text()[normalize-space(.) = '']" mode="marco"/>

  <!-- ==========================================================
       COPIA DE LAS PRIMERAS (PORTADA Y CRÉDITOS DE GAMBAS)
       ==========================================================
       SON LAS PÁGINAS DEL EPUB, YA EN XHTML. TRES AJUSTES:
         - las imágenes apuntan a ../images/X: en el HTML, assets/media/X
           (el script copia ahí los logos);
         - el título de los créditos genéricos es un h1: en la página ya
           hay uno, el de la portada, así que pasa a párrafo;
         - sin los atributos epub:*. -->
  <xsl:template match="h:*" mode="primeras">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="@*" mode="primeras"/>
      <xsl:apply-templates mode="primeras"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="h:h1[ancestor::h:section[tokenize(@class, '\s+') = 'creditos']]" mode="primeras">
    <p>
      <xsl:apply-templates select="@*" mode="primeras"/>
      <xsl:apply-templates mode="primeras"/>
    </p>
  </xsl:template>

  <xsl:template match="@*" mode="primeras">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="@*[namespace-uri() != '']" mode="primeras"/>

  <xsl:template match="h:img/@src[starts-with(., '../images/')]" mode="primeras">
    <xsl:attribute name="src" select="concat('assets/media/', substring(., 11))"/>
  </xsl:template>

  <xsl:template match="text()" mode="primeras">
    <xsl:copy/>
  </xsl:template>

  <xsl:template match="comment() | processing-instruction()" mode="primeras"/>

</xsl:stylesheet>
