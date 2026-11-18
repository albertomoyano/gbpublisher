<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-a-marcalyc.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : EL index.html DEL PAQUETE DE MARCALYC (REDALYC) DE UN
                   ARTÍCULO (F4, DECISIONES DE ALBERTO DEL 18/11/2026):
                     - MARCALYC NO RECIBE XML: RECIBE UN ZIP CON UN SOLO
                       index.html EN UTF-8 Y SUS IMÁGENES, Y EL JATS LO
                       GENERA ÉL AL MARCAR (MANUAL DE USUARIO DE MARCALYC
                       4.0, ABRIL DE 2024);
                     - SOLO EL CUERPO: LOS METADATOS (TÍTULO, AUTORES,
                       RESUMEN, FECHAS) SE CARGAN EN LOS FORMULARIOS DE
                       MARCALYC. VAN EL CUERPO, LOS AGRADECIMIENTOS, LOS
                       APÉNDICES, LAS NOTAS Y LAS REFERENCIAS.
  POR QUÉ IMPORTA: EL CUERPO, LAS NOTAS, LAS CITAS Y LAS REFERENCIAS SON
                   LOS DEL EPUB (jats-a-epub-articulo.xsl): EL MISMO TEXTO
                   QUE EL PDF, CON LAS CITAS DE biblatex (SC-57). ESTA HOJA
                   SOLO CAMBIA EL ENVOLTORIO Y LIMPIA LO QUE ES DEL EPUB.
  LA LIMPIEZA    : UNA SEGUNDA PASADA SOBRE EL RESULTADO DEL EPUB:
                     - HTML SIN ESPACIO DE NOMBRES Y SIN epub:type NI role:
                       MARCALYC MARCA UN HTML COMÚN;
                     - LAS IMÁGENES, POR SU NOMBRE: EN EL ZIP VAN JUNTO A
                       index.html, NO EN ../images/;
                     - SIN ENLACES DE VUELTA (↩) EN LAS NOTAS NI CLASES.
  ENTRADA        : EL CANÓNICO SIN DOCTYPE (GV-25)
  SALIDA         : index.html DEL PAQUETE (LO ARMA generar_redalyc_revista.sh)
  PARÁMETROS     : archivo, bib_dir, estilo_cita: LOS DEL EPUB
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:h="http://www.w3.org/1999/xhtml"
  xmlns:gbct="urn:gbpublisher:citas"
  xmlns:gbe="urn:gbpublisher:revista-epub"
  exclude-result-prefixes="xs h gbct gbe">

  <!-- EL ARTÍCULO DEL EPUB. LO QUE ESTA HOJA DEFINE GANA POR PRECEDENCIA -->
  <xsl:import href="jats-a-epub-articulo.xsl"/>

  <xsl:output method="html" version="5.0" encoding="UTF-8" indent="no"/>

  <!-- ============================================
       Función   : / (plantilla)
       Propósito : El index.html: el cuerpo del artículo del EPUB, limpio
       Parámetros: (nodo de contexto) — el canónico
       Retorna   : el documento HTML
       ============================================ -->
  <xsl:template match="/">
    <xsl:variable name="meta" select="article/front/article-meta"/>

    <!-- APARTADO 1. LOS PARÁMETROS OBLIGATORIOS, COMO EN EL EPUB -->
    <xsl:if test="normalize-space($archivo) eq ''">
      <xsl:message terminate="yes">ERROR: falta el parámetro archivo (el nombre del artículo)</xsl:message>
    </xsl:if>
    <xsl:if test="not($gbct:tex4ht)">
      <xsl:message terminate="yes">ERROR: falta el parámetro bib_dir (la carpeta de preparar_citas_revista.sh)</xsl:message>
    </xsl:if>

    <!-- APARTADO 2. EL CUERPO, CON LAS PLANTILLAS DEL EPUB -->
    <xsl:variable name="cuerpo" as="node()*">
      <xsl:apply-templates select="article/body"/>
      <xsl:apply-templates select="article/back/ack"/>
      <xsl:apply-templates select="article/back/app-group"/>
      <xsl:call-template name="gbe:notas"/>
      <xsl:call-template name="gbe:referencias"/>
    </xsl:variable>

    <!-- APARTADO 3. EL DOCUMENTO, LIMPIO -->
    <html lang="{$gbe:xml-lang}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="gbe:titulo-plano($meta/title-group/article-title)"/></title>
      </head>
      <body>
        <xsl:apply-templates select="$cuerpo" mode="limpio"/>
      </body>
    </html>
  </xsl:template>

  <!-- EL CÓDIGO (SC-42), COMO TEXTO: EL BLOQUE DEL EPUB LLEVA EL RÓTULO
       DEL LENGUAJE Y LOS NÚMEROS DE LÍNEA EN EL MISMO TEXTO, Y MARCALYC
       LOS TOMARÍA COMO PARTE DEL CÓDIGO -->
  <xsl:template match="code">
    <pre><code><xsl:value-of select="."/></code></pre>
  </xsl:template>

  <!-- ==================================================================
       LA LIMPIEZA (mode="limpio")
       ================================================================== -->

  <!-- UN ELEMENTO HTML: EL MISMO NOMBRE, SIN ESPACIO DE NOMBRES -->
  <xsl:template match="*" mode="limpio">
    <xsl:element name="{local-name()}">
      <xsl:apply-templates select="@* | node()" mode="limpio"/>
    </xsl:element>
  </xsl:template>

  <!-- LOS ATRIBUTOS QUE SIRVEN PARA MARCAR: id (DESTINO DE NOTAS Y
       REFERENCIAS), href, src, alt, colspan, rowspan, lang. LO DEMÁS
       (epub:type, role, class, style, aria-*) ES DEL EPUB -->
  <xsl:template match="@*" mode="limpio"/>
  <xsl:template match="@id | @href | @alt | @colspan | @rowspan | @lang" mode="limpio">
    <xsl:attribute name="{local-name()}" select="."/>
  </xsl:template>

  <!-- LA IMAGEN, POR SU NOMBRE: EN EL ZIP ESTÁ JUNTO A index.html -->
  <xsl:template match="@src" mode="limpio">
    <xsl:attribute name="src" select="tokenize(., '/')[last()]"/>
  </xsl:template>

  <!-- EL ENLACE DE VUELTA DE UNA NOTA (↩) Y EL ESPACIO ANTERIOR: NO SON
       TEXTO DEL ARTÍCULO -->
  <xsl:template match="h:a[@role = 'doc-backlink']" mode="limpio"/>
  <xsl:template match="text()[following-sibling::node()[1][self::h:a[@role = 'doc-backlink']]][not(normalize-space())]" mode="limpio"/>

  <xsl:template match="text() | comment()" mode="limpio">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>
