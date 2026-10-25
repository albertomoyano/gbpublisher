<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  grafico-comun.xsl
  ============================================================
  PROPÓSITO : LA FIGURA INTERACTIVA DE UN GRÁFICO (SC-69), QUE
              COMPARTEN LAS HOJAS DE HTML DE REVISTAS
              (jats-to-html.xsl) Y DE LIBROS (docbook-to-html.xsl).
              UNA FIGURA ES INTERACTIVA SI SU IMAGEN ES media/fig-….png
              Y JUNTO A ELLA ESTÁ media/fig-….html, QUE ESCRIBE
              engine/grafico.sh AL GENERAR EL GRÁFICO. SI NO, ES UNA
              FIGURA COMÚN CON SU <img>.
  USO       : SE INCLUYE CON xsl:include, COMO codigo-comun.xsl.
  LA RUTA   : unparsed-text-available NECESITA LA RUTA ABSOLUTA DE
              media/ COMO URL file://, CON CADA TRAMO PASADO POR
              encode-for-uri: iri-to-uri NO ESCAPA # NI ?, Y UNA
              CARPETA DE PROYECTO CON # DARÍA false (GV-136). EL
              PARÁMETRO LLEGA POR LA LÍNEA DE ÓRDENES: CON LOCALE UTF-8
              (EL DE MINT) LA ñ LLEGA BIEN (GV-136).
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbg="urn:gbpublisher:grafico"
  exclude-result-prefixes="xs gbg">

  <!-- EL NOMBRE DE LA IMAGEN DE UN GRÁFICO: fig- Y LETRAS SIN TILDE,
       CIFRAS O GUIONES (m_Graficos.NombreValido, SC-69) -->
  <xsl:variable name="gbg:patron-png" as="xs:string" select="'^fig-[A-Za-z0-9-]+\.png$'"/>

  <!-- LA PROPORCIÓN SI EL HTML NO LA DICE: LA DE LA PLANTILLA DE UN
       GRÁFICO NUEVO (CGrafico.Proporcion) -->
  <xsl:variable name="gbg:proporcion-omision" as="xs:string" select="'1.6'"/>

  <!-- ==========================================================
       gbg:url-archivo: LA URL file:// DE UNA RUTA ABSOLUTA, CON
       CADA TRAMO ESCAPADO (GV-136)
       ========================================================== -->
  <xsl:function name="gbg:url-archivo" as="xs:string">
    <xsl:param name="ruta" as="xs:string"/>
    <xsl:sequence select="concat('file://',
                          string-join(for $t in tokenize($ruta, '/')
                                      return encode-for-uri($t), '/'))"/>
  </xsl:function>

  <!-- ==========================================================
       gbg:html-del-png: EL NOMBRE DEL HTML DE UN GRÁFICO A PARTIR
       DEL DE SU PNG: fig-x.png DA fig-x.html
       ========================================================== -->
  <xsl:function name="gbg:html-del-png" as="xs:string">
    <xsl:param name="nombre" as="xs:string"/>
    <xsl:sequence select="replace($nombre, '\.png$', '.html')"/>
  </xsl:function>

  <!-- ==========================================================
       gbg:interactivo: RESPONDE SI LA FIGURA TIENE VERSIÓN
       INTERACTIVA. ANTES, starts-with($nombre, 'fi') TOMABA TAMBIÉN
       fig-*, EL PREFIJO DE TODA FIGURA: CADA FIGURA COMÚN SE VOLVÍA
       UN IFRAME A UN ARCHIVO INEXISTENTE (SC-69)
       PARÁMETROS: dir_media — RUTA ABSOLUTA DE media/; VACÍA, NUNCA
                   nombre    — EL NOMBRE DE LA IMAGEN, SIN CARPETA
       ========================================================== -->
  <xsl:function name="gbg:interactivo" as="xs:boolean">
    <xsl:param name="dir_media" as="xs:string"/>
    <xsl:param name="nombre" as="xs:string"/>
    <xsl:sequence select="$dir_media != ''
                          and matches($nombre, $gbg:patron-png)
                          and unparsed-text-available(
                                gbg:url-archivo(concat($dir_media, '/', gbg:html-del-png($nombre))))"/>
  </xsl:function>

  <!-- ==========================================================
       gbg:proporcion: ANCHO / ALTO DEL GRÁFICO, LEÍDO DE LA
       DESCRIPCIÓN QUE LLEVA SU HTML («"proporcion":1.6», COMO LA
       ESCRIBE JSON.Encode). ES LA DEL aspect-ratio DEL IFRAME: ASÍ
       EL IFRAME MIDE LO QUE EL GRÁFICO Y NO SE CORTA
       ========================================================== -->
  <xsl:function name="gbg:proporcion" as="xs:string">
    <xsl:param name="dir_media" as="xs:string"/>
    <xsl:param name="nombre" as="xs:string"/>
    <xsl:variable name="texto" as="xs:string"
      select="unparsed-text(gbg:url-archivo(concat($dir_media, '/', gbg:html-del-png($nombre))))"/>
    <xsl:variable name="hallado" as="xs:string*">
      <xsl:analyze-string select="$texto" regex="&quot;proporcion&quot;\s*:\s*([0-9]+(\.[0-9]+)?)">
        <xsl:matching-substring>
          <xsl:sequence select="regex-group(1)"/>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="($hallado, $gbg:proporcion-omision)[1]"/>
  </xsl:function>

  <!-- ==========================================================
       gbg:iframe: EL IFRAME DEL GRÁFICO. OCUPA EL ANCHO DEL
       CONTENEDOR Y TOMA EL ALTO DE LA PROPORCIÓN: SE ADAPTA A LAS
       TRES MEDIDAS DE PANTALLA SIN BARRAS NI CORTES. EL title ES EL
       TEXTO ALTERNATIVO DE LA FIGURA; ADENTRO, EL GRÁFICO LLEVA SU
       TABLA DE DATOS PARA EL LECTOR DE PANTALLA (SC-69).
       espacio: EL ESPACIO DE NOMBRES DEL HTML DE LA HOJA QUE LLAMA.
       jats-to-html.xsl ESCRIBE HTML SIN ESPACIO DE NOMBRES (VACÍO);
       docbook-to-html.xsl, XHTML: UN ELEMENTO LITERAL DE ESTA HOJA
       SALDRÍA SIN ESPACIO DE NOMBRES Y CON xmlns="" EN EL XHTML
       ========================================================== -->
  <xsl:template name="gbg:iframe">
    <xsl:param name="src" as="xs:string"/>
    <xsl:param name="proporcion" as="xs:string"/>
    <xsl:param name="alt" as="xs:string"/>
    <xsl:param name="espacio" as="xs:string" select="''"/>
    <xsl:element name="iframe" namespace="{$espacio}">
      <xsl:attribute name="class" select="'fig-grafico'"/>
      <xsl:attribute name="src" select="$src"/>
      <xsl:attribute name="title" select="$alt"/>
      <xsl:attribute name="loading" select="'lazy'"/>
      <xsl:attribute name="scrolling" select="'no'"/>
      <xsl:attribute name="style" select="concat('width:100%;aspect-ratio:', $proporcion, ';border:0;display:block')"/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
