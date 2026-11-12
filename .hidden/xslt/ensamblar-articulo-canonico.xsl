<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  ensamblar-articulo-canonico.xsl — gbpublisher
  =====================================================
  DESCRIPCIÓN : EL CANÓNICO JATS 1.4 DE UN ARTÍCULO DE REVISTA SOBRE EL
                ESQUEMA NUEVO (SC-71; ETAPA A0 DE LAS SALIDAS DE REVISTAS,
                claude/salidas-revistas.md):
                  front  ← EL VOLCADO DEL NÚMERO (tmp/numero-datos.xml) POR
                           datos-a-front-jats.xsl
                  body   ← EL FRAGMENTO DE PANDOC (tmp/body-{base}.xml)
                  back   ← EL reflist (tmp/reflist-{base}.xml), SI TIENE <ref>
                  prólogo← LAS HUELLAS DE LAS FUENTES (tmp/huellas-{base}.xml),
                           UNA <?gb-fuente?> POR ARCHIVO (SC-75)
  REEMPLAZA   : A ensamblar-canonico.xsl PARA LOS NÚMEROS NUEVOS. AQUELLA
                QUEDA PARA EL CAMINO VIEJO HASTA EL 2.0.0, Y ESTA LA IMPORTA:
                EL TRATAMIENTO DEL body (sec-type, ids de sección, tablas de
                ancho completo y rotadas) ES UNO SOLO Y SALE IGUAL.
  USO         : java -jar saxon-he.jar -s:tmp/numero-datos.xml
                  -xsl:ensamblar-articulo-canonico.xsl -o:jats/c-{base}.xml
                  archivo=a-01-tal body=tmp/body-{base}.xml
                  reflist=tmp/reflist-{base}.xml
                  huellas=tmp/huellas-{base}.xml
                LO LANZA engine/generar_canonicos_articulos.sh
  ENTRADA     : numero-datos versión 1 (m_CanonicoRevista.VERSION_DATOS)
  =====================================================
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
    xmlns:gbj="urn:gbpublisher:jats"
    exclude-result-prefixes="xs gbj">

  <!-- EL body Y EL DOCTYPE, LOS DEL ENSAMBLADO DE SIEMPRE (SU PLANTILLA
       RAÍZ QUEDA TAPADA POR LA DE ACÁ, QUE TIENE PRECEDENCIA) -->
  <xsl:import href="ensamblar-canonico.xsl"/>
  <xsl:include href="datos-a-front-jats.xsl"/>

  <!-- EL ARTÍCULO DEL VOLCADO: SU ARCHIVO SIN .md -->
  <xsl:param name="archivo" as="xs:string" select="''"/>

  <!-- RUTA DEL XML DE HUELLAS QUE ESCRIBE generar_canonicos_articulos.sh
       (SC-75): UNA <fuente archivo="…" sha256="…"/> POR CADA ARCHIVO QUE SE
       COPIA DENTRO DEL CANÓNICO, EL .md Y SUS CUADROS. required, COMO EN
       ensamblar-capitulo-canonico.xsl: UN CANÓNICO SIN SUS HUELLAS ES JUSTO
       LO QUE ESA REGLA EVITA -->
  <xsl:param name="huellas" as="xs:string" required="yes"/>

  <!-- EL DOCTYPE: EL IDENTIFICADOR PÚBLICO QUE DECLARA LA DTD DE JATS 1.4
       ARCHIVING (JATS-archivearticle1-4.dtd) Y SU CATÁLOGO OFICIAL. EL QUE
       TRAE ensamblar-canonico.xsl («Article Archiving and Interchange DTD
       v1.4») NO EXISTE: UN VALIDADOR QUE RESUELVE POR CATÁLOGO NO LO
       ENCUENTRA. ESTA DECLARACIÓN TIENE MÁS PRECEDENCIA QUE LA IMPORTADA Y
       REEMPLAZA SUS ATRIBUTOS; EL RESTO (indent="no", SC-30) SE HEREDA -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    doctype-public="-//NLM//DTD JATS (Z39.96) Journal Archiving and Interchange DTD v1.4 20241031//EN"
    doctype-system="https://jats.nlm.nih.gov/archiving/1.4/JATS-archivearticle1-4.dtd"/>

  <!-- LA VERSIÓN DEL VOLCADO QUE ESTA HOJA SABE LEER. LA 2 (11/11/2026) SOLO
       SUMA <idioma codigo babel> Y LA 3 (12/11/2026) <preliminares>,
       <pagina-legal> Y revista/@rotulo-volumen: ESTA HOJA NO USA NINGUNO, SE
       LEE IGUAL -->
  <xsl:variable name="version-datos" select="'3'"/>

  <xsl:template match="/">
    <xsl:variable name="art" select="/numero-datos/articulo[@archivo = $archivo]"/>

    <!-- 1. CONTROLES: VOLCADO, VERSIÓN, ARTÍCULO Y HUELLA DEL .md -->
    <xsl:if test="not(/numero-datos)">
      <xsl:message terminate="yes">ERROR: la entrada no es un volcado del número (numero-datos)</xsl:message>
    </xsl:if>
    <xsl:if test="string(/numero-datos/@version) ne $version-datos">
      <xsl:message terminate="yes">ERROR: el volcado es versión <xsl:value-of select="/numero-datos/@version"/> y esta hoja lee la <xsl:value-of select="$version-datos"/></xsl:message>
    </xsl:if>
    <xsl:if test="count($art) ne 1">
      <xsl:message terminate="yes">ERROR: el volcado no tiene el artículo «<xsl:value-of select="$archivo"/>» (o lo tiene repetido)</xsl:message>
    </xsl:if>
    <!-- UN ARTÍCULO SALE SIEMPRE DE SU .md: SIN SU HUELLA, EL CANÓNICO NO
         PODRÍA DECIR DESPUÉS SI SIGUE CORRESPONDIENDO A ÉL -->
    <xsl:if test="not(doc($huellas)/huellas/fuente[@archivo = concat('articulos/', $archivo, '.md')])">
      <xsl:message terminate="yes">ERROR: las huellas no traen la de articulos/<xsl:value-of select="$archivo"/>.md</xsl:message>
    </xsl:if>

    <!-- 2. LAS HUELLAS, EN EL PRÓLOGO: LA FORMA QUE LEE vigencia_canonico
         (comun.sh), archivo PRIMERO Y sha256 DESPUÉS -->
    <xsl:for-each select="doc($huellas)/huellas/fuente">
      <xsl:processing-instruction name="gb-fuente"
        select="concat('archivo=&quot;', @archivo, '&quot; sha256=&quot;', @sha256, '&quot;')"/>
    </xsl:for-each>

    <!-- 3. EL ARTÍCULO -->
    <article dtd-version="1.4" article-type="{$art/@article-type}" xml:lang="{$art/@idioma}">
      <xsl:call-template name="front">
        <xsl:with-param name="art" select="$art"/>
      </xsl:call-template>

      <!-- EL CUERPO, CON LAS PLANTILLAS DEL ENSAMBLADO DE SIEMPRE -->
      <xsl:variable name="bodyDoc" select="document($body)"/>
      <xsl:apply-templates select="$bodyDoc//body"/>

      <!-- 4. EL back: LA DECLARACIÓN DE DISPONIBILIDAD DE DATOS Y LA
           BIBLIOGRAFÍA. SOLO SI HAY ALGUNA DE LAS DOS: EL DTD NO ADMITE UN
           back VACÍO EN EL SENTIDO DE QUE NO DICE NADA -->
      <xsl:variable name="refs" select="if ($reflist ne '') then document($reflist)//ref-list[ref] else ()"/>
      <xsl:variable name="datos" select="$art/declaracion[@tipo = 'disponibilidad_datos'][normalize-space()]"/>
      <xsl:if test="$refs or $datos">
        <back>
          <!-- DISPONIBILIDAD DE DATOS (SciELO §2.3 Y §5.2.2; 1.25.0): UN
               <sec sec-type="data-availability"> EN EL back, LA FORMA QUE
               PIDE JATS4R (data-availability-errors.sch). UNA POR IDIOMA,
               LA DEL ARTÍCULO PRIMERO. VA ANTES DE ref-list, COMO EN EL
               ORDEN DE LECTURA -->
          <xsl:for-each select="$datos">
            <xsl:sort select="if (@idioma = $art/@idioma) then 0 else 1"/>
            <sec sec-type="data-availability">
              <xsl:if test="@idioma ne $art/@idioma">
                <xsl:attribute name="xml:lang" select="@idioma"/>
              </xsl:if>
              <title><xsl:value-of select="gbj:titulo-datos(@idioma)"/></title>
              <p><xsl:value-of select="normalize-space(.)"/></p>
            </sec>
          </xsl:for-each>
          <xsl:apply-templates select="$refs"/>
        </back>
      </xsl:if>
    </article>
  </xsl:template>

  <!-- EL TÍTULO DE LA DECLARACIÓN DE DISPONIBILIDAD DE DATOS SEGÚN SU
       IDIOMA. UN IDIOMA QUE NO ESTÁ EN LA TABLA LLEVA EL INGLÉS: JATS4R
       SUGIERE «Data Availability» (data-availability-warnings.sch) -->
  <xsl:function name="gbj:titulo-datos" as="xs:string">
    <xsl:param name="idioma" as="xs:string?"/>
    <xsl:variable name="i" select="lower-case(substring(string($idioma), 1, 2))"/>
    <xsl:sequence select="if ($i eq 'es') then 'Disponibilidad de datos'
                          else if ($i eq 'pt') then 'Disponibilidade de dados'
                          else if ($i eq 'fr') then 'Disponibilité des données'
                          else 'Data availability'"/>
  </xsl:function>

</xsl:stylesheet>
