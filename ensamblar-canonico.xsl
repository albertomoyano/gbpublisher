<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  ensamblar-canonico.xsl
  =====================================================
  DESCRIPCIÓN:
    ENSAMBLA EL ARTÍCULO JATS 1.4 CANÓNICO COMPLETO
    A PARTIR DE TRES FRAGMENTOS GENERADOS POR GBPUBLISHER:

    - FUENTE PRINCIPAL (-s):  front-*.xml
    - PARÁMETRO body:         body-*.xml
    - PARÁMETRO reflist:      reflist-*.xml

  USO:
    java -jar /opt/Saxon-HE/saxon-he.jar \
      -s:tmp/front-01-....xml \
      -xsl:~/.gbpublisher/xslt/ensamblar-canonico.xsl \
      -o:jats/can-01-....xml \
      body=tmp/body-01-....xml \
      reflist=tmp/reflist-01-....xml

  ESTRUCTURA DE SALIDA:
    <article xmlns:xlink="..." article-type="..." xml:lang="...">
      <front>...</front>
      <body>...</body>
      <back>
        <ref-list>...</ref-list>
      </back>
    </article>

  NOTAS:
    - article-type SE DERIVA DE <subject> EN <article-categories>
    - xml:lang SE DERIVA DE <abstract xml:lang="..."> EN <article-meta>
    - EL NAMESPACE xlink SE DECLARA UNA SOLA VEZ EN <article>
      Y SE ELIMINA DE LOS FRAGMENTOS PARA EVITAR DUPLICACIÓN
    - EL DOCTYPE SE EMITE VÍA <xsl:output> CON doctype-public/system

  VERSIÓN XSLT: 2.0 (REQUIERE SAXON-HE)
  =====================================================
-->
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  version="2.0">

  <!-- ================================================
       PARÁMETROS DE ENTRADA
       RECIBEN LAS RUTAS A LOS FRAGMENTOS body Y reflist
       PASADOS DESDE LA LÍNEA DE COMANDOS DE SAXON
       ================================================ -->
  <xsl:param name="body"    as="xs:string" xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
  <!-- PARÁMETRO OPCIONAL: CADENA VACÍA SI NO HAY REFERENCIAS -->
  <xsl:param name="reflist" as="xs:string" select="''"
             xmlns:xs="http://www.w3.org/2001/XMLSchema"/>

  <!-- ================================================
       SALIDA: XML CON DOCTYPE JATS 1.4
       ================================================ -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    indent="yes"
    doctype-public="-//NLM//DTD JATS (Z39.96) Article Archiving and Interchange DTD v1.4//EN"
    doctype-system="https://jats.nlm.nih.gov/archiving/1.4/JATS-archivearticle1-4.dtd"/>

  <!-- ================================================
       TEMPLATE RAÍZ
       PUNTO DE ENTRADA: PROCESA front-*.xml
       ================================================ -->
  <xsl:template match="/">

    <!-- DERIVAR article-type DESDE <subject> EN <article-categories> -->
    <xsl:variable name="articleType"
      select="normalize-space(//article-categories/subj-group[@subj-group-type='heading']/subject)"/>

    <!-- DERIVAR xml:lang DESDE EL PRIMER <abstract xml:lang="..."> -->
    <xsl:variable name="xmlLang"
      select="normalize-space((//abstract/@xml:lang)[1])"/>

    <!-- CARGAR FRAGMENTOS EXTERNOS -->
    <xsl:variable name="bodyDoc"    select="document($body)"/>
    <xsl:variable name="reflistDoc" select="document($reflist)"/>

    <!-- ELEMENTO RAÍZ <article> -->
    <article
      xmlns:xlink="http://www.w3.org/1999/xlink"
      article-type="{$articleType}"
      xml:lang="{$xmlLang}">

      <!-- PASO 1: INSERTAR <front> SIN EL NAMESPACE xlink
                  (YA ESTÁ DECLARADO EN <article>) -->
      <xsl:apply-templates select="//front"/>

      <!-- PASO 2: INSERTAR <body> DESDE EL FRAGMENTO EXTERNO -->
      <xsl:if test="$bodyDoc//body">
        <xsl:apply-templates select="$bodyDoc//body"/>
      </xsl:if>

      <!-- PASO 3: INSERTAR <back> CON <ref-list> SOLO SI HAY REFERENCIAS -->
      <xsl:if test="$reflist != ''">
        <xsl:variable name="reflistDoc" select="document($reflist)"/>
        <xsl:if test="$reflistDoc//ref-list/ref">
          <back>
            <xsl:apply-templates select="$reflistDoc//ref-list"/>
          </back>
        </xsl:if>
      </xsl:if>

    </article>
  </xsl:template>

  <!-- ================================================
       TEMPLATE DE IDENTIDAD
       COPIA TODOS LOS NODOS TAL CUAL, EXCEPTO LOS
       QUE TIENEN TEMPLATES ESPECÍFICOS MÁS ABAJO
       ================================================ -->
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================
       MAPEO DE sec-type DESDE ATRIBUTOS DE PANDOC
       NORMALIZA VALORES AL VOCABULARIO JATS 1.4
       ================================================ -->
  <xsl:template match="sec[@sec-type]">
    <xsl:variable name="tipo" select="normalize-space(@sec-type)"/>
    <xsl:variable name="tipoNorm">
		<xsl:choose>
        <xsl:when test="$tipo = 'intro'">intro</xsl:when>
        <xsl:when test="$tipo = 'methods'">methods</xsl:when>
        <xsl:when test="$tipo = 'results'">results</xsl:when>
        <xsl:when test="$tipo = 'discussion'">discussion</xsl:when>
        <xsl:when test="$tipo = 'conclusions'">conclusions</xsl:when>
        <xsl:when test="$tipo = 'acknowledgments'">acknowledgments</xsl:when>
        <xsl:when test="$tipo = 'supplementary-material'">supplementary-material</xsl:when>
        <xsl:when test="$tipo = 'cases'">cases</xsl:when>
        <xsl:when test="$tipo = 'findings'">findings</xsl:when>
        <xsl:when test="$tipo = 'materials'">materials</xsl:when>
        <!-- TIPOS DE 01_ESTRUCTURA -->
        <xsl:when test="$tipo = 'case-report'">case-report</xsl:when>
        <xsl:when test="$tipo = 'review-article'">review-article</xsl:when>
        <xsl:when test="$tipo = 'abstract'">abstract</xsl:when>
        <xsl:when test="$tipo = 'appendix'">appendix</xsl:when>
        <xsl:when test="$tipo = 'conflict-of-interest'">conflict-of-interest</xsl:when>
        <xsl:when test="$tipo = 'editorial'">editorial</xsl:when>
        <xsl:when test="$tipo = 'correspondence'">correspondence</xsl:when>
        <xsl:when test="$tipo = 'book-review'">book-review</xsl:when>
        <xsl:when test="$tipo = 'obituary'">obituary</xsl:when>
        <xsl:when test="$tipo = 'oration'">oration</xsl:when>
        <xsl:when test="$tipo = 'retraction'">retraction</xsl:when>
        <xsl:when test="$tipo = 'correction'">correction</xsl:when>
        <!-- VALOR NO RECONOCIDO: PASAR TAL CUAL -->
        <xsl:otherwise><xsl:value-of select="$tipo"/></xsl:otherwise>
        </xsl:choose>
    </xsl:variable>
    <sec sec-type="{$tipoNorm}">
      <xsl:apply-templates select="@* except @sec-type"/>
      <xsl:apply-templates select="node()"/>
    </sec>
  </xsl:template>

  <!-- ================================================
       LIMPIAR id GENERADOS POR PANDOC EN <sec>
       PANDOC GENERA IDs DESDE EL TEXTO DEL TÍTULO,
       QUE SON LARGOS Y NO SIGUEN CONVENCIÓN JATS.
       SE REEMPLAZAN POR UN id CORTO BASADO EN sec-type
       Y POSICIÓN DENTRO DEL DOCUMENTO.
       ================================================ -->
  <xsl:template match="sec/@id">
    <xsl:variable name="secType" select="normalize-space(../@sec-type)"/>
    <xsl:choose>
      <xsl:when test="$secType != ''">
        <xsl:attribute name="id">
          <xsl:value-of select="$secType"/>
          <xsl:text>-</xsl:text>
          <xsl:number count="sec" level="any" from="body"/>
        </xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <!-- SIN sec-type: USAR id GENÉRICO -->
        <xsl:attribute name="id">
          <xsl:text>sec-</xsl:text>
          <xsl:number count="sec" level="any" from="body"/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
