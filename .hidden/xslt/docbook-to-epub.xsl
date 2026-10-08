<?xml version="1.0" encoding="UTF-8"?>
<!-- ============================================================
     HOJA DE ESTILO : docbook-to-epub.xsl
     PROPÓSITO       : CONVIERTE UN CAPÍTULO CANÓNICO (DocBook 5.2)
                       A XHTML PARA EPUB 3, CON DISEÑO MINIMALISTA
                       PENSADO PARA E-READERS VIEJOS (NO PARA
                       LECTURA EN PANTALLA — ESO LO CUBRE EL HTML WEB).
     UBICACIÓN       : ~/.gbpublisher/xslt/
     ENTRADA         : un capítulo <chapter|preface|...> canónico.
     SALIDA          : un XHTML5 por capítulo (lineal, sin paneles,
                       sin JS, validable con epubcheck).
     PRINCIPIOS      :
       - Notas al pie: ancla inline + texto en <section endnotes>
         al final del capítulo (evita <aside> dentro de <p>, que es
         inválido en XHTML). Popup donde el lector lo soporta,
         enlace bidireccional donde no. Portado de jats-to-epub.xsl.
       - Referencias: enlace a la bibliografía del capítulo (al final).
       - Figuras: inline con caption, sin panel.
       - Todo lineal, sin JS, sin arquitectura de 3 columnas.
     PARÁMETROS      :
       - estilo_cita : apa | iso690 | vancouver | ieee
     ============================================================ -->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:epub="http://www.idpf.org/2007/ops"
    xmlns:nl="urn:gbpublisher:numeracion-libro"
    xmlns:gbc="urn:gbpublisher:codigo"
                exclude-result-prefixes="xsl xs db xlink nl gbc">

  <!-- NIVELADO DE COMILLAS POR PROFUNDIDAD. ES LA ÚNICA REGLA DEL PROYECTO:
       NO DEFINIR ACÁ OTRA PLANTILLA PARA db:quote. SIN ESTE INCLUDE, <quote>
       CAE EN EL CATCH-ALL match="*" Y LAS COMILLAS DESAPARECEN -->
  <xsl:include href="quote.xsl"/>

  <!-- MARCA DE LOS EDITORES QUE OCUPAN EL LUGAR DEL AUTOR: (Ed.), (Comp.)...
       ES LA ÚNICA REGLA DE LAS SALIDAS DIGITALES; NO DUPLICARLA ACÁ -->
  <xsl:include href="marca-editor.xsl"/>

  <!-- NÚMERO DE FIGURA Y REFERENCIAS CRUZADAS: LA MISMA REGLA QUE EL PDF
       Y QUE EL HTML (SC-31). NO DUPLICARLA ACÁ -->
  <xsl:include href="numeracion-libro.xsl"/>

  <!-- LAS REGLAS DEL CÓDIGO COMUNES A LAS SEIS SALIDAS (SC-42) -->
  <xsl:include href="codigo-comun.xsl"/>

  <!-- ================================================
       PARÁMETROS DE ENTRADA
       ================================================ -->
  <xsl:param name="estilo_cita" as="xs:string" select="'apa'"/>

  <!-- ESTA HOJA TRANSFORMA UNA PIEZA POR VEZ, PERO EL NÚMERO DE UNA
       FIGURA DEPENDE DEL LUGAR DE SU PIEZA EN EL LIBRO, Y UNA REFERENCIA
       PUEDE APUNTAR A OTRA PIEZA. EL SCRIPT PASA LA LISTA DEL EPUB
       (tmp/epub-capitulos.txt, EN ORDEN, UN NOMBRE POR LÍNEA) Y EL
       NOMBRE DE LA PIEZA EN CURSO. LOS CANÓNICOS DE LAS DEMÁS SE LEEN
       DE LA MISMA CARPETA QUE EL DE ESTA (jats/c-NOMBRE.xml).
       OBLIGATORIOS: SIN ELLOS LA NUMERACIÓN NO COINCIDIRÍA CON EL PDF. -->
  <xsl:param name="piezas_libro" as="xs:string" required="yes"/>
  <xsl:param name="pieza_actual" as="xs:string" required="yes"/>

  <!-- BIBLIOGRAFÍA CONSOLIDADA (lugar_bibliografia = consolidada)
       RUTA ABSOLUTA DE tmp/epub-bibliografia.xml: LA BIBLIOGRAFÍA DEL LIBRO
       (LA DE GenerarBiblioLibroXML) CON EL TÍTULO DE LA PÁGINA YA PUESTO POR
       GAMBAS. EL TÍTULO VIAJA EN EL ARCHIVO Y NO COMO PARÁMETRO: UN
       PARÁMETRO DE LA LÍNEA DE COMANDOS LLEGA A JAVA SEGÚN EL LOCALE, Y BAJO
       C/POSIX «Bibliografía» SE ROMPE (MEDIDO; LA MISMA FAMILIA QUE GV-03).
       VACÍA = POR CAPÍTULO: CADA CAPÍTULO TRAE SU <bibliography> Y TODO
       QUEDA COMO ANTES. CON ELLA, LAS CITAS SE RESUELVEN CONTRA ESA LISTA
       (AUTOR, AÑO, NÚMERO) Y ENLAZAN A LA PÁGINA DE BIBLIOGRAFÍA. -->
  <xsl:param name="biblio_libro" as="xs:string" select="''"/>

  <!-- NOMBRE FIJO DE LA PÁGINA DE BIBLIOGRAFÍA EN chapters/. DEBE COINCIDIR
       CON m_GenerarEpubLibro (OPF Y NAV) Y CON generar_epub_libro.sh: SI
       DIVERGEN, LA VERIFICACIÓN DEL OPF DEL SCRIPT LO ATRAPA -->
  <xsl:variable name="archivoBibliografia" as="xs:string" select="'bibliografia.xhtml'"/>

  <!-- LA BIBLIOGRAFÍA CONSOLIDADA, SI LA HAY -->
  <xsl:variable name="biblioLibro" as="element()?"
                select="if ($biblio_libro != '') then doc($biblio_libro)/* else ()"/>

  <!-- LAS ENTRADAS CONTRA LAS QUE SE RESUELVEN LAS CITAS: LAS DE LA
       BIBLIOGRAFÍA CONSOLIDADA O LAS DE ESTE DOCUMENTO -->
  <xsl:variable name="entradasBib" as="element()*"
                select="if (exists($biblioLibro))
                        then $biblioLibro//(db:biblioentry | biblioentry)
                        else //(db:biblioentry | biblioentry)"/>

  <!-- DESTINO DE LOS ENLACES DE CITA: LA PÁGINA DE BIBLIOGRAFÍA SI ES
       CONSOLIDADA; EL MISMO ARCHIVO SI ES POR CAPÍTULO -->
  <xsl:variable name="hrefBib" as="xs:string"
                select="if (exists($biblioLibro)) then $archivoBibliografia else ''"/>

  <!-- LAS PIEZAS DEL LIBRO EN ORDEN. LA EN CURSO ES LA RAÍZ DE ESTE
       DOCUMENTO Y NO UNA SEGUNDA CARGA DEL MISMO ARCHIVO: numeracion-libro
       LA BUSCA POR IDENTIDAD DE NODO. -->
  <xsl:variable name="nombresPiezas" as="xs:string*"
                select="tokenize($piezas_libro, '\n')[normalize-space() != '']"/>
  <xsl:variable name="raizPieza" select="/*"/>
  <xsl:variable name="piezasLibro" as="element()*"
                select="for $n in $nombresPiezas
                        return if ($n = $pieza_actual) then $raizPieza
                        else doc(resolve-uri(concat('c-', $n, '.xml'), base-uri($raizPieza)))/*"/>

  <!-- ================================================
       SALIDA: XHTML5 (con doctype legacy-compat para EPUB)
       ================================================ -->
  <!-- indent="no" (SC-30): CON indent="yes" SAXON METE UN SALTO DE
       LÍNEA CON SANGRÍA DONDE UN ELEMENTO QUEDA PEGADO A OTRO SIN TEXTO
       EN MEDIO —</quote></quote>, «<emphasis>, </emphasis><footnote>—, Y
       ESE SALTO SE VE COMO UN ESPACIO EN LA SALIDA (VERIFICADO, GV-71).
       LA SANGRÍA QUE TRAEN LAS FUENTES SE CONSERVA: LA COPIA LLEVA SUS
       NODOS DE ESPACIO. -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    indent="no"
    omit-xml-declaration="no"
    doctype-system="about:legacy-compat"/>

  <!-- ================================================
       VARIABLES GLOBALES
       ================================================ -->
  <!-- EL CAPÍTULO RAÍZ (chapter, preface, acknowledgements, etc.) -->
  <xsl:variable name="cap" select="/*"/>

  <!-- IDIOMA: cascada estándar del proyecto.
       1. @xml:lang del capítulo  2. 'es' -->
  <xsl:variable name="lang">
    <xsl:choose>
      <xsl:when test="normalize-space($cap/@xml:lang) != ''">
        <xsl:value-of select="normalize-space($cap/@xml:lang)"/>
      </xsl:when>
      <xsl:otherwise>es</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- TÍTULO DEL CAPÍTULO -->
  <xsl:variable name="titulo"
    select="normalize-space(($cap/db:info/db:title | $cap/db:title
                            | $cap/info/title | $cap/title)[1])"/>

  <!-- ================================================
       CLAVE PARA RESOLVER biblioref → biblioentry
       ================================================ -->
  <xsl:key name="ref-por-id" match="db:biblioentry | biblioentry"
           use="@xml:id"/>

  <!-- ================================================
       TEMPLATE RAÍZ
       ================================================ -->
  <!-- PÁGINA DE BIBLIOGRAFÍA CONSOLIDADA: LA FUENTE ES LA <bibliography>
       QUE ESCRIBE GenerarBiblioLibroXML, NO UN CAPÍTULO. LAS ENTRADAS SALEN
       CON LA MISMA PLANTILLA QUE LA BIBLIOGRAFÍA DE UN CAPÍTULO (ref-epub),
       ASÍ QUE EL FORMATO ES EL MISMO EN LOS DOS MODELOS -->
  <!-- document-node(element(…)) Y NO "/": LA TRANSFORMACIÓN EMPIEZA EN EL
       NODO DOCUMENTO, Y ESTA REGLA GANA A LA DE "/" SOLO CUANDO LA RAÍZ ES
       UNA BIBLIOGRAFÍA -->
  <xsl:template match="document-node(element(db:bibliography)) | document-node(element(bibliography))" priority="5">
    <xsl:variable name="tituloPagina" select="normalize-space((*/db:title | */title)[1])"/>
    <html xmlns="http://www.w3.org/1999/xhtml"
          xmlns:epub="http://www.idpf.org/2007/ops"
          lang="{$lang}" xml:lang="{$lang}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="$tituloPagina"/></title>
        <link rel="stylesheet" type="text/css" href="../css/gbpublisher-epub-libro.css"/>
      </head>
      <body>
        <section epub:type="bibliography" role="doc-bibliography" class="capitulo bibliografia">
          <xsl:if test="$tituloPagina != ''">
            <h1 class="cap-titulo"><xsl:value-of select="$tituloPagina"/></h1>
          </xsl:if>
          <xsl:for-each select="*/db:biblioentry | */biblioentry">
            <xsl:apply-templates select="." mode="ref-epub"/>
          </xsl:for-each>
        </section>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml"
          xmlns:epub="http://www.idpf.org/2007/ops"
          lang="{$lang}" xml:lang="{$lang}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="$titulo"/></title>
        <link rel="stylesheet" type="text/css" href="../css/gbpublisher-epub-libro.css"/>
      </head>
      <body>
        <section epub:type="chapter" class="capitulo">

          <!-- TÍTULO DEL CAPÍTULO -->
          <xsl:if test="$titulo != ''">
            <h1 class="cap-titulo"><xsl:value-of select="$titulo"/></h1>
          </xsl:if>

          <xsl:variable name="capInfo" select="($cap/db:info | $cap/info)[1]"/>

          <!-- SUBTÍTULO DEL CAPÍTULO (si tiene). normalize-space: EL CORTE
               DEL EDITOR (<?gb-corte?>) NO VALE EN EL EPUB Y SU VALOR DE
               TEXTO ES VACÍO, ASÍ QUE QUEDA UN ESPACIO (SC-28). EL HTML YA
               LO MOSTRABA; EL EPUB NO -->
          <xsl:variable name="subtitulo"
            select="normalize-space(($capInfo/db:subtitle | $capInfo/subtitle)[1])"/>
          <xsl:if test="$subtitulo != ''">
            <p class="cap-subtitulo"><xsl:value-of select="$subtitulo"/></p>
          </xsl:if>

          <!-- AUTORÍA DEL CAPÍTULO (si tiene) -->
          <xsl:if test="$capInfo/db:author | $capInfo/author">
            <p class="cap-autoria">
              <xsl:for-each select="$capInfo/db:author | $capInfo/author">
                <!-- COMAS Y «y» O «e» ANTES DEL ÚLTIMO: «Duek y Moguillansky» -->
                <xsl:call-template name="separador-autoria">
                  <xsl:with-param name="pos" select="position()"/>
                  <xsl:with-param name="total" select="last()"/>
                  <xsl:with-param name="nombre"
                                  select="(db:personname/db:firstname | personname/firstname)[1]"/>
                </xsl:call-template>
                <xsl:value-of select="normalize-space(
                  (db:personname/db:firstname | personname/firstname)[1])"/>
                <xsl:text> </xsl:text>
                <xsl:value-of select="normalize-space(
                  (db:personname/db:surname | personname/surname)[1])"/>
              </xsl:for-each>
            </p>
          </xsl:if>

          <!-- CUERPO DEL CAPÍTULO: TODO MENOS info Y bibliography
               (QUE SE PROCESAN APARTE) -->
          <xsl:apply-templates select="$cap/*[not(self::db:info or self::info
                                              or self::db:bibliography or self::bibliography)]"/>

          <!-- ================================================
               NOTAS AL FINAL DEL CAPÍTULO (endnotes)
               EL ANCLA VA INLINE (template footnote); EL TEXTO
               DE LA NOTA VA AQUÍ. EVITA <aside> DENTRO DE <p>.
               ================================================ -->
          <xsl:if test="$cap//db:footnote | $cap//footnote">
            <section epub:type="endnotes" role="doc-endnotes" class="notas-final">
              <h2 class="seccion-titulo">
                <xsl:choose>
                  <xsl:when test="$lang = 'en'">Notes</xsl:when>
                  <xsl:otherwise>Notas</xsl:otherwise>
                </xsl:choose>
              </h2>
              <xsl:for-each select="$cap//db:footnote | $cap//footnote">
                <xsl:variable name="fn-num">
                  <xsl:number count="db:footnote | footnote" level="any"/>
                </xsl:variable>
                <div role="doc-endnote" id="fn-{$fn-num}" class="nota-item">
                  <p>
                    <sup class="nota-num"><xsl:value-of select="$fn-num"/></sup>
                    <xsl:text> </xsl:text>
                    <xsl:apply-templates select="db:para/node() | para/node()"/>
                    <xsl:text> </xsl:text>
                    <a href="#fnref-{$fn-num}" role="doc-backlink"
                       class="nota-backlink">&#x21A9;</a>
                  </p>
                </div>
              </xsl:for-each>
            </section>
          </xsl:if>

          <!-- ================================================
               BIBLIOGRAFÍA DEL CAPÍTULO (al final)
               ================================================ -->
          <xsl:apply-templates select="$cap/db:bibliography | $cap/bibliography"/>

        </section>
      </body>
    </html>
  </xsl:template>

  <!-- ================================================
       INTERIORES: BLOQUES BÁSICOS
       ================================================ -->

  <!-- PÁRRAFO -->
  <xsl:template match="db:para | para">
    <p><xsl:apply-templates/></p>
  </xsl:template>

  <!-- SECCIÓN Y SUS TÍTULOS -->
  <xsl:template match="db:section | section">
    <section class="cap-section">
      <xsl:apply-templates/>
    </section>
  </xsl:template>

  <!-- TÍTULO DE SECCIÓN: el primer title de una section → h2..h6
       según profundidad de anidamiento. -->
  <xsl:template match="db:section/db:title | section/title">
    <xsl:variable name="nivel" select="count(ancestor::db:section | ancestor::section)"/>
    <xsl:element name="h{min(($nivel + 1, 6))}">
      <xsl:attribute name="class">sec-titulo</xsl:attribute>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

  <!-- OTROS title (info, etc.) NO SE EMITEN SUELTOS -->
  <xsl:template match="db:info/db:title | info/title"/>

  <!-- ÉNFASIS -->
  <xsl:template match="db:emphasis | emphasis">
    <!-- LOS role DE PANDOC (SC-30): strong/bold, smallcaps, strikethrough
         Y underline. SIN LOS TRES ÚLTIMOS SALÍAN EN BASTARDILLA. LOS
         ELEMENTOS SON LOS QUE USA EL ESCRITOR HTML DE PANDOC: <del>, <u>
         Y UNA CLASE PARA LAS VERSALITAS, QUE DEFINE LA HOJA DE ESTILOS. -->
    <xsl:choose>
      <xsl:when test="@role = 'bold' or @role = 'strong'">
        <strong><xsl:apply-templates/></strong>
      </xsl:when>
      <xsl:when test="@role = 'smallcaps'">
        <span class="versalitas"><xsl:apply-templates/></span>
      </xsl:when>
      <xsl:when test="@role = 'strikethrough'">
        <del><xsl:apply-templates/></del>
      </xsl:when>
      <xsl:when test="@role = 'underline'">
        <u><xsl:apply-templates/></u>
      </xsl:when>
      <xsl:otherwise>
        <em><xsl:apply-templates/></em>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- SUPERÍNDICE Y SUBÍNDICE (SC-30). NO HABÍA PLANTILLA: LA REGLA
       INCORPORADA DEJABA EL TEXTO, Y x^2^ SALÍA «x2». -->
  <xsl:template match="db:superscript | superscript">
    <sup><xsl:apply-templates/></sup>
  </xsl:template>
  <xsl:template match="db:subscript | subscript">
    <sub><xsl:apply-templates/></sub>
  </xsl:template>


  <!-- ENLACE -->
  <xsl:template match="db:link | link">
    <xsl:variable name="href" select="(@xlink:href | @href)[1]"/>
    <a href="{$href}"><xsl:apply-templates/></a>
  </xsl:template>

  <!-- LISTAS -->
  <xsl:template match="db:itemizedlist | itemizedlist">
    <ul><xsl:apply-templates select="db:listitem | listitem"/></ul>
  </xsl:template>
  <xsl:template match="db:orderedlist | orderedlist">
    <ol><xsl:apply-templates select="db:listitem | listitem"/></ol>
  </xsl:template>
  <xsl:template match="db:listitem | listitem">
    <li>
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

  <!-- LISTA DE DEFINICIÓN -->
  <xsl:template match="db:variablelist | variablelist">
    <dl class="lista-definicion">
      <xsl:for-each select="db:varlistentry | varlistentry">
        <xsl:for-each select="db:term | term">
          <dt><xsl:apply-templates/></dt>
        </xsl:for-each>
        <xsl:for-each select="db:listitem | listitem">
          <dd>
            <xsl:choose>
              <xsl:when test="count(*) = 1 and (db:para | para)">
                <xsl:apply-templates select="(db:para | para)/node()"/>
              </xsl:when>
              <xsl:otherwise><xsl:apply-templates/></xsl:otherwise>
            </xsl:choose>
          </dd>
        </xsl:for-each>
      </xsl:for-each>
    </dl>
  </xsl:template>

  <!-- CITA EN BLOQUE -->
  <xsl:template match="db:blockquote | blockquote">
    <blockquote class="cita-bloque">
      <xsl:apply-templates/>
    </blockquote>
  </xsl:template>

  <!-- CITA DE FUENTE (blockquote role="source") → cita documental
       con la procedencia (attribution) al pie. -->
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

  <!-- TABLA (informaltable / table) -->
  <xsl:template match="db:table | table | db:informaltable | informaltable">
    <div class="tabla-wrap">
    <table class="tabla-datos">
      <xsl:variable name="titulo" select="normalize-space((db:title | title)[1])"/>
      <xsl:if test="$titulo != ''">
        <caption><xsl:value-of select="$titulo"/></caption>
      </xsl:if>
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
                    <xsl:attribute name="style">text-align: <xsl:value-of select="$aligns[$pos]"/></xsl:attribute>
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
                    <xsl:attribute name="style">text-align: <xsl:value-of select="$aligns[$pos]"/></xsl:attribute>
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

  <!-- CÓDIGO -->
  <!-- CÓDIGO EN BLOQUE (SC-42): EL MISMO DE LAS DEMÁS SALIDAS DIGITALES
       (gbc:bloque-html), SIN COLOR —FONDO NEGRO Y TEXTO BLANCO, POR EL
       CSS— Y CON EL NÚMERO Y EL ↩ COMO TEXTO -->
  <xsl:template match="db:programlisting | programlisting">
    <xsl:call-template name="gbc:bloque-html">
      <xsl:with-param name="el" select="."/>
      <xsl:with-param name="ns" select="'http://www.w3.org/1999/xhtml'"/>
      <xsl:with-param name="texto" select="true()"/>
    </xsl:call-template>
  </xsl:template>

  <!-- LISTADO (SC-42): EL BLOQUE Y EL PIE «Código N.», NUMERADO COMO EN
       EL PDF (nl:numero-listado) -->
  <xsl:template match="db:example[@role = 'listado'] | example[@role = 'listado']" priority="5">
    <div class="gb-listado" id="{@xml:id}">
      <xsl:apply-templates select="db:programlisting | programlisting"/>
      <p class="gb-codigo-pie">
        <xsl:text>Código </xsl:text>
        <xsl:value-of select="nl:numero-listado(., $piezasLibro)"/>
        <xsl:if test="normalize-space((db:title | title)[1]) != ''">
          <xsl:text>. </xsl:text>
          <xsl:apply-templates select="(db:title | title)[1]/node()"/>
        </xsl:if>
      </p>
    </div>
  </xsl:template>
  <xsl:template match="db:literal | literal">
    <code class="code-inline"><xsl:apply-templates/></code>
  </xsl:template>

  <!-- ================================================
       NOTA AL PIE — SOLO EL ANCLA INLINE (SUPERÍNDICE).
       EL TEXTO VA EN LA SECCIÓN endnotes (template raíz).
       ================================================ -->
  <xsl:template match="db:footnote | footnote">
    <xsl:variable name="fn-num">
      <xsl:number count="db:footnote | footnote" level="any"/>
    </xsl:variable>
    <sup class="nota-ref"><a id="fnref-{$fn-num}" href="#fn-{$fn-num}"
      epub:type="noteref" role="doc-noteref"><xsl:value-of select="$fn-num"/></a></sup>
  </xsl:template>

  <!-- ================================================
       REFERENCIA (biblioref) → enlace a la bibliografía
       ================================================
       LÓGICA COMPLETA PORTADA DE docbook-to-html.xsl, ADAPTADA A
       EPUB: el <a> es simple (href="#rid"), SIN onclick/JS/paneles.
       Maneja modos (normal, author-in-text, suppress), agrupación
       de citas múltiples, y prefijos/sufijos. -->
  <xsl:template match="db:biblioref | biblioref">
    <xsl:choose>
      <xsl:when test="$estilo_cita = 'vancouver' or $estilo_cita = 'ieee'">
        <xsl:call-template name="xref-numerico-epub"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="xref-autor-anio-epub"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- LOS phrase de prefijo/sufijo se ABSORBEN en el template del
       biblioref; se suprimen para que no se rendericen sueltos. -->
  <xsl:template match="db:phrase[@role='cite-prefix'] | phrase[@role='cite-prefix']"/>
  <xsl:template match="db:phrase[@role='cite-suffix'] | phrase[@role='cite-suffix']"/>

  <!-- SUPRESORES DE ESPACIOS Y SEPARADORES ALREDEDOR DE LAS CITAS. LA
       HOJA NO TENÍA NINGUNO: [@a; @b] SALÍA CON LA COMA DEL CANÓNICO
       COLGADA ENTRE LAS DOS CITAS, Y LOS SALTOS DE LÍNEA DEL CANÓNICO SE
       VOLVÍAN ESPACIOS DENTRO DEL PARÉNTESIS. SON LOS MISMOS QUE LOS DE
       docbook-to-html.xsl, Y VALEN TAMBIÉN EN MODO text-only, EL DE LAS
       NOTAS. -->
  <!-- ESPACIO ENTRE UN biblioref Y SU SUFIJO -->
  <xsl:template match="text()[normalize-space(.) = '']
    [preceding-sibling::node()[1][self::db:biblioref or self::biblioref]]
    [following-sibling::node()[1][self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']]]"
    mode="#default text-only"/>
  <!-- ESPACIO ENTRE UN PREFIJO Y SU biblioref -->
  <xsl:template match="text()[normalize-space(.) = '']
    [preceding-sibling::node()[1][self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']]]
    [following-sibling::node()[1][self::db:biblioref or self::biblioref]]"
    mode="#default text-only"/>
  <!-- SEPARADOR ', ' / '; ' ENTRE DOS CITAS DEL MISMO GRUPO: LO EMITE LA
       SEGUNDA CITA COMO '; ' -->
  <xsl:template match="text()[matches(., '^\s*[,;]\s*$')]
    [preceding-sibling::node()[not(self::text() and normalize-space(.)='')][1]
       [self::db:biblioref or self::biblioref
        or self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']]]
    [following-sibling::node()[not(self::text() and normalize-space(.)='')][1]
       [self::db:biblioref or self::biblioref
        or self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']]]"
    mode="#default text-only"/>

  <!-- AUXILIAR: prefijo de una cita (phrase cite-prefix hermano) -->
  <xsl:template name="phrase-prefijo-de-epub">
    <xsl:variable name="prev"
      select="preceding-sibling::node()[not(self::text() and normalize-space(.) = '')][1]"/>
    <xsl:if test="$prev[self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']]">
      <xsl:apply-templates select="$prev/node()"/>
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- AUXILIAR: sufijo de una cita (phrase cite-suffix hermano) -->
  <xsl:template name="phrase-sufijo-de-epub">
    <xsl:variable name="next"
      select="following-sibling::node()[not(self::text() and normalize-space(.) = '')][1]"/>
    <xsl:if test="$next[self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']]">
      <xsl:text>, </xsl:text>
      <xsl:apply-templates select="$next/node()"/>
    </xsl:if>
  </xsl:template>

  <!-- AUXILIAR: resolver autor de una cita desde su biblioentry -->
  <xsl:template name="resolver-autor-cita-epub">
    <xsl:param name="rid"/>
    <xsl:variable name="entry"
                  select="$entradasBib[@xml:id = $rid][1]"/>
    <xsl:variable name="personas" select="$entry/db:author | $entry/author"/>
    <xsl:variable name="editores" select="$entry/db:editor | $entry/editor"/>
    <xsl:choose>
      <xsl:when test="$personas">
        <xsl:call-template name="formatear-surnames-cita-epub">
          <xsl:with-param name="lista" select="$personas"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="$editores">
        <xsl:call-template name="formatear-surnames-cita-epub">
          <xsl:with-param name="lista" select="$editores"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="if (starts-with($rid, 'bib-'))
                              then substring-after($rid, 'bib-') else $rid"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- FORMATEA SURNAMES SEGÚN CANTIDAD (1 / 2 / 3+) -->
  <xsl:template name="formatear-surnames-cita-epub">
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
  <xsl:template name="resolver-anio-cita-epub">
    <xsl:param name="rid"/>
    <xsl:variable name="entry"
                  select="$entradasBib[@xml:id = $rid][1]"/>
    <xsl:value-of select="normalize-space(($entry/db:pubdate | $entry/pubdate)[1])"/>
  </xsl:template>

  <!-- ¿ES PRIMERA CITA DEL GRUPO? -->
  <xsl:template name="es-primera-cita-grupo-epub">
    <xsl:variable name="prev1"
      select="preceding-sibling::node()[not(self::text() and normalize-space(.)='')][1]"/>
    <xsl:variable name="ancla"
      select="if ($prev1[self::db:phrase[@role='cite-prefix'] or self::phrase[@role='cite-prefix']])
              then preceding-sibling::node()[not(self::text() and normalize-space(.)='')][2]
              else $prev1"/>
    <xsl:sequence select="not($ancla[self::text() and matches(., '^\s*[,;]\s*$')])"/>
  </xsl:template>

  <!-- AUTHOR-DATE (APA / ISO690): (Autor, año) con 3 modos -->
  <xsl:template name="xref-autor-anio-epub">
    <xsl:variable name="rid" select="@linkend"/>
    <xsl:variable name="modo" select="if (@role != '') then @role else 'normal'"/>
    <xsl:variable name="autor">
      <xsl:call-template name="resolver-autor-cita-epub">
        <xsl:with-param name="rid" select="$rid"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="anio">
      <xsl:call-template name="resolver-anio-cita-epub">
        <xsl:with-param name="rid" select="$rid"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="esPrimera">
      <xsl:call-template name="es-primera-cita-grupo-epub"/>
    </xsl:variable>
    <xsl:variable name="next1"
      select="following-sibling::node()[not(self::text() and normalize-space(.)='')][1]"/>
    <xsl:variable name="anclaSig"
      select="if ($next1[self::db:phrase[@role='cite-suffix'] or self::phrase[@role='cite-suffix']])
              then following-sibling::node()[not(self::text() and normalize-space(.)='')][2]
              else $next1"/>
    <xsl:variable name="esUltima"
      select="not($anclaSig[self::text() and matches(., '^\s*[,;]\s*$')])"/>

    <xsl:choose>
      <!-- AUTHOR-IN-TEXT: Autor (año) -->
      <xsl:when test="$modo = 'author-in-text'">
        <xsl:call-template name="phrase-prefijo-de-epub"/>
        <a class="xref-bibr" href="{$hrefBib}#{$rid}"><xsl:value-of select="$autor"/></a>
        <xsl:text> (</xsl:text>
        <a class="xref-bibr" href="{$hrefBib}#{$rid}"><xsl:value-of select="$anio"/></a>
        <xsl:call-template name="phrase-sufijo-de-epub"/>
        <xsl:text>)</xsl:text>
      </xsl:when>
      <!-- SUPPRESS: (año) -->
      <xsl:when test="$modo = 'suppress'">
        <xsl:if test="$esPrimera = true()">
          <xsl:text>(</xsl:text>
          <xsl:call-template name="phrase-prefijo-de-epub"/>
        </xsl:if>
        <!-- UNA CITA QUE NO ES LA PRIMERA DEL GRUPO TAMBIÉN PUEDE LLEVAR
             PREFIJO: [@a; en @b]. ANTES SE PERDÍA SIN AVISO -->
        <xsl:if test="$esPrimera = false()">
          <xsl:text>; </xsl:text>
          <xsl:call-template name="phrase-prefijo-de-epub"/>
        </xsl:if>
        <a class="xref-bibr" href="{$hrefBib}#{$rid}">
          <xsl:value-of select="$anio"/>
          <xsl:call-template name="phrase-sufijo-de-epub"/>
        </a>
        <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
      </xsl:when>
      <!-- NORMAL: (Autor, año) -->
      <xsl:otherwise>
        <xsl:if test="$esPrimera = true()">
          <xsl:text>(</xsl:text>
          <xsl:call-template name="phrase-prefijo-de-epub"/>
        </xsl:if>
        <!-- UNA CITA QUE NO ES LA PRIMERA DEL GRUPO TAMBIÉN PUEDE LLEVAR
             PREFIJO: [@a; en @b]. ANTES SE PERDÍA SIN AVISO -->
        <xsl:if test="$esPrimera = false()">
          <xsl:text>; </xsl:text>
          <xsl:call-template name="phrase-prefijo-de-epub"/>
        </xsl:if>
        <a class="xref-bibr" href="{$hrefBib}#{$rid}">
          <xsl:value-of select="$autor"/>
          <xsl:if test="$anio != ''">
            <xsl:text>, </xsl:text><xsl:value-of select="$anio"/>
          </xsl:if>
          <xsl:call-template name="phrase-sufijo-de-epub"/>
        </a>
        <xsl:if test="$esUltima"><xsl:text>)</xsl:text></xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- NUMÉRICO (Vancouver / IEEE): [N] -->
  <xsl:template name="xref-numerico-epub">
    <xsl:variable name="rid" select="@linkend"/>
    <!-- CONTRA LA BIBLIOGRAFÍA CONSOLIDADA SI LA HAY: EL NÚMERO ES LA
         POSICIÓN EN ESA LISTA, LA MISMA DE LA PÁGINA DE BIBLIOGRAFÍA -->
    <xsl:variable name="entry" select="$entradasBib[@xml:id = $rid][1]"/>
    <xsl:variable name="num"
      select="count($entry/preceding-sibling::db:biblioentry
                   | $entry/preceding-sibling::biblioentry) + 1"/>
    <xsl:call-template name="phrase-prefijo-de-epub"/>
    <a class="xref-bibr" href="{$hrefBib}#{$rid}">
      <xsl:text>[</xsl:text><xsl:value-of select="$num"/><xsl:text>]</xsl:text>
    </a>
    <xsl:call-template name="phrase-sufijo-de-epub"/>
  </xsl:template>

  <!-- BIBLIOREF EN MODO text-only (PARA LAS NOTAS): RESUELVE
       LA CITA A TEXTO PLANO (mismo patrón que la web). -->
  <xsl:template match="db:biblioref | biblioref" mode="text-only">
    <xsl:variable name="render">
      <xsl:apply-templates select="."/>
    </xsl:variable>
    <xsl:value-of select="string($render)"/>
  </xsl:template>
  <!-- LOS AFIJOS NO SE IMPRIMEN EN LA NOTA: LA CITA, QUE EN ESTE MODO SE
       DIBUJA EN MODO DEFAULT, YA LOS ABSORBE DENTRO DEL PARÉNTESIS. ANTES
       ESTA PLANTILLA LOS IMPRIMÍA OTRA VEZ Y EL SUFIJO SALÍA DOBLE -->
  <xsl:template match="db:phrase[@role='cite-prefix'] | phrase[@role='cite-prefix']
                     | db:phrase[@role='cite-suffix'] | phrase[@role='cite-suffix']"
                mode="text-only"/>

  <!-- ================================================
       FIGURA → inline con caption (sin panel)
       ================================================ -->
  <!-- EL NÚMERO ES EL DEL PDF (numeracion-libro.xsl, SC-31). EL id ES
       EL DEL .md: ES EL DESTINO DE LAS REFERENCIAS CRUZADAS. -->
  <xsl:template match="db:figure | figure | db:informalfigure | informalfigure">
    <xsl:variable name="num" select="nl:numero-figura(., $piezasLibro)"/>
    <xsl:variable name="fileref"
                  select="(db:mediaobject/db:imageobject/db:imagedata/@fileref
                          | mediaobject/imageobject/imagedata/@fileref)[1]"/>
    <!-- TEXTO ALTERNATIVO: EL DECLARADO EN EL .md, QUE EL FILTRO PONE EN
         textobject; SI NO HAY, EL PIE -->
    <xsl:variable name="alt"
                  select="normalize-space(((db:mediaobject/db:textobject/db:phrase
                          | mediaobject/textobject/phrase)[1], (db:title | title)[1])[1])"/>
    <figure class="figura">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id" select="@xml:id"/>
      </xsl:if>
      <xsl:if test="$fileref != ''">
        <img src="../images/{tokenize($fileref, '/')[last()]}" alt="{$alt}"/>
      </xsl:if>
      <figcaption class="figura-caption">
        <span class="figura-label">Figura <xsl:value-of select="$num"/></span>
        <xsl:if test="normalize-space((db:title | title)[1]) != ''">
          <xsl:text>. </xsl:text>
          <xsl:apply-templates select="(db:title | title)[1]/node()"/>
        </xsl:if>
      </figcaption>
    </figure>
  </xsl:template>

  <!-- ================================================
       BIBLIOGRAFÍA DEL CAPÍTULO
       ================================================ -->
  <xsl:template match="db:bibliography | bibliography">
    <section epub:type="bibliography" role="doc-bibliography" class="bibliografia">
      <h2 class="seccion-titulo">
        <xsl:value-of select="normalize-space((db:title | title)[1])"/>
      </h2>
      <xsl:for-each select="db:biblioentry | biblioentry">
        <xsl:apply-templates select="." mode="ref-epub"/>
      </xsl:for-each>
    </section>
  </xsl:template>

  <!-- FORMATO COMPLETO DE CADA ENTRADA (4 estilos CSL: APA, ISO690,
       Vancouver, IEEE). Portado de docbook-to-html.xsl, con el wrapper
       adaptado a EPUB (div.ref-item con id, sin panel/JS). -->
  <xsl:template name="numero-referencia-db">
    <xsl:param name="rid"/>
    <xsl:variable name="entry"
                  select="$entradasBib[@xml:id = $rid][1]"/>
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

  <xsl:template match="db:biblioentry | biblioentry" mode="ref-epub">
    <div class="ref-item" id="{@xml:id}">
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
          <!-- LOS NOMBRES VAN A UNA VARIABLE ANTES DE ESCRIBIRSE: LA MARCA
               NECESITA SABER SI TERMINAN EN PUNTO PARA DECIDIR LA MAYÚSCULA,
               COMO HACE biblatex -->
          <xsl:variable name="nombres">
            <xsl:for-each select="db:editor | editor">
              <xsl:call-template name="ref-una-persona-db">
                <xsl:with-param name="estilo" select="$estilo"/>
                <xsl:with-param name="total" select="last()"/>
              </xsl:call-template>
            </xsl:for-each>
          </xsl:variable>
          <xsl:copy-of select="$nombres"/>
          <!-- MARCA SEGÚN EL ROL DEL EDITOR: (Ed.), (Comp.), (Coord.)...
               LA REGLA VIVE EN marca-editor.xsl -->
          <xsl:call-template name="marca-editor-db">
            <xsl:with-param name="estilo" select="$estilo"/>
            <xsl:with-param name="editores" select="db:editor | editor"/>
            <xsl:with-param name="tras_punto"
                            select="ends-with(normalize-space(string($nombres)), '.')"/>
          </xsl:call-template>
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

  <!-- SUPRIMIR title dentro de figure/table (ya se emiten en su lugar) -->
  <xsl:template match="db:figure/db:title | figure/title
                     | db:table/db:title | table/title
                     | db:informaltable/db:title | informaltable/title"/>

  <!-- ================================================
       REFERENCIA CRUZADA (@fig-… EN EL .md)
       ================================================
       SOLO EL NÚMERO, COMO \ref EN EL PDF. SI LA FIGURA ESTÁ EN OTRA
       PIEZA, EL ENLACE VA A SU ARCHIVO (chapters/h-NOMBRE.xhtml, EL
       MISMO DIRECTORIO). UN DESTINO INEXISTENTE SALE «??» Y SE AVISA. -->
  <xsl:template match="db:xref | xref">
    <xsl:variable name="destino" select="nl:destino(string(@linkend), $piezasLibro)"/>
    <xsl:variable name="texto" select="nl:texto-referencia($destino, $piezasLibro)"/>
    <xsl:choose>
      <xsl:when test="empty($destino)">
        <xsl:message>
          <xsl:text>AVISO: referencia sin destino: </xsl:text>
          <xsl:value-of select="@linkend"/>
        </xsl:message>
        <xsl:value-of select="$texto"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="nl:cantidad-destinos(string(@linkend), $piezasLibro) > 1">
          <xsl:message>
            <xsl:text>AVISO: identificador repetido en el libro: </xsl:text>
            <xsl:value-of select="@linkend"/>
          </xsl:message>
        </xsl:if>
        <xsl:variable name="i" as="xs:integer?"
                      select="(for $k in 1 to count($piezasLibro)
                               return if ($piezasLibro[$k] is nl:pieza-de($destino))
                                      then $k else ())[1]"/>
        <xsl:variable name="archivo"
                      select="if ($nombresPiezas[$i] = $pieza_actual) then ''
                              else concat('h-', $nombresPiezas[$i], '.xhtml')"/>
        <a class="referencia" href="{$archivo}#{@linkend}">
          <xsl:value-of select="$texto"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="db:xref | xref" mode="text-only">
    <xsl:value-of select="nl:texto-referencia(
      nl:destino(string(@linkend), $piezasLibro), $piezasLibro)"/>
  </xsl:template>

  <!-- MODO text-only genérico (para notas): recursa y emite texto -->
  <xsl:template match="*" mode="text-only">
    <xsl:apply-templates mode="text-only"/>
  </xsl:template>
  <xsl:template match="text()" mode="text-only">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- ================================================
       SHORTCODES (versión EPUB minimalista)
       ================================================ -->

  <!-- EPÍGRAFE -->
  <xsl:template match="db:epigraph | epigraph">
    <div class="epigrafe">
      <xsl:for-each select="db:para | para">
        <p class="epigrafe-texto"><xsl:apply-templates/></p>
      </xsl:for-each>
      <!-- LA ATRIBUCIÓN VA ABAJO, SIN RAYA (SC-35), Y CONSERVA SUS MARCAS -->
      <xsl:if test="db:attribution | attribution">
        <p class="epigrafe-atrib">
          <xsl:apply-templates select="(db:attribution | attribution)[1]/node()"/>
        </p>
      </xsl:if>
    </div>
  </xsl:template>

  <!-- ALERTAS / RECUADROS: <div> (NO <aside>, inestable en lectores
       viejos). Cada tipo lleva una clase y una etiqueta textual (el
       icono en EPUB se resuelve por CSS ::before o se omite). -->
  <xsl:template match="db:note | note">
    <xsl:call-template name="emitir-alerta-epub">
      <xsl:with-param name="tipo" select="'note'"/>
      <xsl:with-param name="etiqueta" select="'Nota'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:tip | tip">
    <xsl:call-template name="emitir-alerta-epub">
      <xsl:with-param name="tipo" select="'tip'"/>
      <xsl:with-param name="etiqueta" select="'Sugerencia'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:important | important">
    <xsl:call-template name="emitir-alerta-epub">
      <xsl:with-param name="tipo" select="'important'"/>
      <xsl:with-param name="etiqueta" select="'Importante'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:warning | warning">
    <xsl:call-template name="emitir-alerta-epub">
      <xsl:with-param name="tipo" select="'warning'"/>
      <xsl:with-param name="etiqueta" select="'Advertencia'"/>
    </xsl:call-template>
  </xsl:template>
  <xsl:template match="db:caution | caution">
    <xsl:call-template name="emitir-alerta-epub">
      <xsl:with-param name="tipo" select="'caution'"/>
      <xsl:with-param name="etiqueta" select="'Precaución'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- MATERIAL SUPLEMENTARIO (sidebar role="supplementary") -->
  <xsl:template match="db:sidebar[@role='supplementary'] | sidebar[@role='supplementary']">
    <div class="suplementario">
      <xsl:if test="@xml:id">
        <xsl:attribute name="id"><xsl:value-of select="@xml:id"/></xsl:attribute>
      </xsl:if>
      <p class="suplementario-etiqueta">Material suplementario</p>
      <div class="suplementario-cuerpo">
        <xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <!-- RECUADROS (SC-41): COMO EN docbook-to-html, CON LA BARRA EN
       MAYÚSCULAS ESCRITA ASÍ (VER jats-to-epub). PRIORIDAD 5 -->
  <xsl:template match="db:sidebar[@role = ('recuadro', 'recuadro-barra')] |
                       sidebar[@role = ('recuadro', 'recuadro-barra')]" priority="5">
    <div class="recuadro{if (@role = 'recuadro-barra') then ' recuadro-barra' else ''}">
      <xsl:if test="@role = 'recuadro-barra'">
        <p class="recuadro-titulo"><xsl:value-of select="upper-case(normalize-space((db:title | title)[1]))"/></p>
      </xsl:if>
      <div class="recuadro-cuerpo">
        <xsl:apply-templates select="* except (db:title | title | db:info | info)"/>
      </div>
    </div>
  </xsl:template>

  <!-- SIDEBAR genérico (info, etc.) -->
  <xsl:template match="db:sidebar | sidebar">
    <xsl:call-template name="emitir-alerta-epub">
      <xsl:with-param name="tipo" select="if (@role != '') then @role else 'info'"/>
      <xsl:with-param name="etiqueta"
                      select="if (@role = 'info') then 'Información' else 'Nota'"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ESTRUCTURA COMÚN DE ALERTA (EPUB): <div> con etiqueta textual -->
  <xsl:template name="emitir-alerta-epub">
    <xsl:param name="tipo"/>
    <xsl:param name="etiqueta"/>
    <div class="alerta alerta-{$tipo}" role="note">
      <p class="alerta-etiqueta"><xsl:value-of select="$etiqueta"/></p>
      <div class="alerta-cuerpo">
        <xsl:apply-templates/>
      </div>
    </div>
  </xsl:template>

  <!-- VERSO (literallayout role="verse") -->
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

  <!-- LITERALLAYOUT GENÉRICO -->
  <xsl:template match="db:literallayout | literallayout">
    <pre class="literallayout"><xsl:value-of select="."/></pre>
  </xsl:template>

  <!-- DISCURSO / DIÁLOGO (para role="speech") -->
  <!-- FROUFROU (SC-36): TRES ASTERISCOS A 1 cm, CENTRADOS. CADA UNO EN
       SU span Y SIN ESPACIOS ENTRE ELLOS: LA DISTANCIA LA DA EL MARGEN,
       NO LA FUENTE. role="separator" PARA LOS LECTORES DE PANTALLA. -->
  <xsl:template match="db:para[@role='froufrou'] | para[@role='froufrou']" priority="5">
    <div class="froufrou" role="separator"><span>*</span><span>*</span><span>*</span></div>
  </xsl:template>

  <xsl:template match="db:para[@role='speech'] | para[@role='speech']">
    <p class="speech"><xsl:apply-templates/></p>
  </xsl:template>
  <xsl:template match="db:emphasis[@role='speaker'] | emphasis[@role='speaker']">
    <span class="speech-speaker"><xsl:apply-templates/></span>
  </xsl:template>


  <!-- ==========================================================
       SEPARADOR DE UNA LISTA DE AUTORES
       ==========================================================
       Lo que va antes del nombre en la posición $pos de $total:
       nada, coma, o la conjunción antes del último: «A», «A y B»,
       «A, B y C». $nombre es la palabra que sigue —el nombre de
       pila— y decide entre «y» y «e».
       REGLA DE LA RAE (DPD, «y»): «e» ANTE i- O hi- CON SONIDO DE
       VOCAL («Pérez e Ibáñez», «Ana e Hilda»); «y» SI ESA i SIN
       TILDE FORMA DIPTONGO CON LA VOCAL SIGUIENTE («Ana y
       Iolanda», «agua y hielo»). LA MISMA REGLA QUE
       m_PrimerasLibro.Conjuncion EN LA PORTADA Y EL PDF. -->
  <xsl:template name="separador-autoria">
    <xsl:param name="pos"/>
    <xsl:param name="total"/>
    <xsl:param name="nombre"/>
    <xsl:variable name="sinH" select="replace(normalize-space($nombre), '^[hH]', '')"/>
    <xsl:choose>
      <xsl:when test="$pos = 1"/>
      <xsl:when test="$pos &lt; $total">
        <xsl:text>, </xsl:text>
      </xsl:when>
      <xsl:when test="matches($sinH, '^[iI][aeiouáéíóúüAEIOUÁÉÍÓÚÜ]')">
        <xsl:text> y </xsl:text>
      </xsl:when>
      <xsl:when test="matches($sinH, '^[iIíÍ]')">
        <xsl:text> e </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text> y </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
