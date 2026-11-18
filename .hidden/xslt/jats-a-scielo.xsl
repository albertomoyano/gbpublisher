<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-a-scielo.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : EL XML SciELO PS DE UN ARTÍCULO (F6, DECISIONES DE
                   ALBERTO DEL 18/11/2026): EL CANÓNICO (JATS 1.4
                   Archiving) PASADO A SciELO PS 1.9, QUE ES JATS 1.1
                   Publishing CON LAS REGLAS DE scielo-style-1.9.sch
                   (packtools 4.18.2).
                     - sps-1.9 Y NO sps-1.10: packtools 4.18.2 RECHAZA
                       sps-1.10 POR DEFECTO («not currently supported»,
                       MEDIDO), Y EL ARTÍCULO REAL DE 2025 QUE TRAE COMO
                       EJEMPLO ES sps-1.9;
                     - mixed-citation: EL TEXTO QUE ESCRIBIÓ biblatex (SC-72,
                       SC-57); element-citation: EL DEL CANÓNICO. SciELO
                       EXIGE LOS DOS EN CADA ref;
                     - LAS CITAS EN EL TEXTO, CON EL TEXTO DE biblatex (EL
                       MISMO QUE EL PDF), Y EL xref SOBRE LA PARTE QUE ENLAZA.
  POR QUÉ IMPORTA: LAS CITAS Y LAS REFERENCIAS SE ARMAN CON LA MAQUINARIA
                   DEL EPUB (jats-a-epub-articulo.xsl, cita-fragmentos.xsl),
                   QUE DEVUELVE HTML; EL MODO html-jats LO PASA A JATS. EL
                   RESTO DEL ARTÍCULO VA EN EL MODO sps, UNA COPIA CON LOS
                   CAMBIOS QUE PIDE SciELO.
  LO QUE CAMBIA RESPECTO DEL CANÓNICO (CADA PLANTILLA LO DICE):
                   article (dtd-version, specific-use), journal-meta (issn
                   pub-type, abbrev-journal-title), article-id other,
                   contrib-id ORCID sin URL, role sin vocabulario, aff
                   (orgname, addr-line, original), pub-history → history,
                   license (license-type, xlink:href, xml:lang), kwd-group
                   con xml:lang, counts, figuras y cuadros (label, caption
                   con title, archivos con el nombre SPS), notas al final
                   (fn-group), el suplemento en el texto de issue, la nota
                   financial-disclosure con los award-id que los
                   agradecimientos no nombran, y lo que JATS 1.1 o SciELO no
                   admiten, fuera
                   (self-uri, related-article, custom-meta, los atributos
                   de vocabulario de 1.2+).
  ENTRADA        : EL CANÓNICO SIN DOCTYPE (GV-25)
  SALIDA         : {nombre}.xml Y, APARTE, EL MANIFIESTO DE IMÁGENES
                   (original TAB nombre SPS, una por línea), QUE USA
                   generar_scielo_revista.sh PARA COPIARLAS
  PARÁMETROS     : archivo, bib_dir, estilo_cita: LOS DEL EPUB
                   volcado     URI DEL VOLCADO DEL NÚMERO (EL TÍTULO
                               ABREVIADO DE LA REVISTA)
                   nombre      EL NOMBRE SPS DEL ARTÍCULO, SIN EXTENSIÓN
                   orden       LA POSICIÓN DEL ARTÍCULO EN EL NÚMERO
                   manifiesto  URI DEL MANIFIESTO DE IMÁGENES
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
  xmlns:h="http://www.w3.org/1999/xhtml"
  xmlns:gbct="urn:gbpublisher:citas"
  xmlns:gbcj="urn:gbpublisher:citas-jats"
  xmlns:gbe="urn:gbpublisher:revista-epub"
  xmlns:gbs="urn:gbpublisher:scielo"
  exclude-result-prefixes="xs ali h gbct gbcj gbe gbs">

  <!-- LAS CITAS Y LAS REFERENCIAS DEL EPUB -->
  <xsl:import href="jats-a-epub-articulo.xsl"/>

  <!-- JATS 1.1 Publishing: EL DOCTYPE QUE PIDE SciELO PS 1.9 (EL DE SU
       DOCUMENTACIÓN; packtools LO EXIGE: «cannot get the DOCTYPE»). SIN
       SANGRÍA: CON indent, SAXON METE ESPACIOS EN EL CONTENIDO MIXTO (GV-71) -->
  <xsl:output method="xml" encoding="UTF-8" indent="no"
    doctype-public="-//NLM//DTD JATS (Z39.96) Journal Publishing DTD v1.1 20151215//EN"
    doctype-system="https://jats.nlm.nih.gov/publishing/1.1/JATS-journalpublishing1.dtd"/>

  <xsl:param name="volcado" as="xs:string" select="''"/>
  <xsl:param name="nombre" as="xs:string" select="''"/>
  <xsl:param name="orden" as="xs:string" select="'1'"/>
  <xsl:param name="manifiesto" as="xs:string" select="''"/>

  <xsl:variable name="gbs:lang" select="string(/article/@xml:lang)"/>
  <xsl:variable name="gbs:revista" select="if ($volcado != '') then doc($volcado)/numero-datos/revista else ()"/>

  <!-- LAS FIGURAS DEL ARTÍCULO, EN ORDEN: SU NÚMERO DA EL NOMBRE SPS
       ({nombre}-gf01.png) Y EL ROTULO -->
  <xsl:variable name="gbs:figuras" select="/article/body//fig[graphic]"/>

  <!-- LAS NOTAS DEL TEXTO (NO LAS DE author-notes): VAN AL FINAL, EN
       back/fn-group, CON SU LLAMADA; ES LO QUE ESPERA SciELO -->
  <xsl:variable name="gbs:notas" select="/article//fn[not(ancestor::author-notes)][not(ancestor::table-wrap-foot)]"/>

  <!-- ============================================
       Función   : / (plantilla)
       Propósito : El artículo SPS y el manifiesto de imágenes
       ============================================ -->
  <xsl:template match="/">
    <!-- APARTADO 1. LOS PARÁMETROS OBLIGATORIOS -->
    <xsl:if test="normalize-space($archivo) eq '' or normalize-space($nombre) eq ''">
      <xsl:message terminate="yes">ERROR: faltan los parámetros archivo o nombre</xsl:message>
    </xsl:if>
    <xsl:if test="not($gbct:tex4ht)">
      <xsl:message terminate="yes">ERROR: falta el parámetro bib_dir (la carpeta de preparar_citas_revista.sh)</xsl:message>
    </xsl:if>

    <!-- APARTADO 2. EL ARTÍCULO -->
    <xsl:apply-templates select="article" mode="sps"/>

    <!-- APARTADO 3. EL MANIFIESTO DE IMÁGENES -->
    <xsl:if test="$manifiesto != ''">
      <xsl:result-document href="{$manifiesto}" method="text">
        <xsl:for-each select="$gbs:figuras">
          <xsl:value-of select="tokenize(graphic/@xlink:href, '/')[last()]"/>
          <xsl:text>&#9;</xsl:text>
          <xsl:value-of select="gbs:nombre-imagen(.)"/>
          <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <!-- EL NOMBRE SPS DE LA IMAGEN DE UNA FIGURA: {nombre}-gfNN.{ext} («Prefixo
       com uma numeração sequencial», regra-nomeacao de SciELO PS) -->
  <xsl:function name="gbs:nombre-imagen" as="xs:string">
    <xsl:param name="fig" as="element()"/>
    <xsl:variable name="original" select="tokenize($fig/graphic/@xlink:href, '/')[last()]"/>
    <xsl:variable name="n" select="count($fig/preceding::fig[graphic][ancestor::body]) + 1"/>
    <xsl:sequence select="concat($nombre, '-gf', format-number($n, '00'), '.', lower-case(tokenize($original, '\.')[last()]))"/>
  </xsl:function>

  <!-- ==================================================================
       LA COPIA (mode="sps")
       ================================================================== -->

  <xsl:template match="*" mode="sps">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="sps"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="@*" mode="sps">
    <xsl:copy/>
  </xsl:template>

  <!-- EL TEXTO, CON LAS REGLAS DEL EPUB: EL SEPARADOR ENTRE DOS CITAS DE UN
       MISMO GRUPO LO PUSO biblatex, Y SE SUPRIME (cita-jats-comun.xsl) -->
  <xsl:template match="text()" mode="sps">
    <xsl:apply-templates select="." mode="#default"/>
  </xsl:template>

  <!-- LAS INSTRUCCIONES gb-* SON DEL PDF; LOS COMENTARIOS, DEL PROCESO -->
  <xsl:template match="processing-instruction() | comment()" mode="sps"/>

  <!-- UN ELEMENTO VACÍO DE element-citation (<lpage/>) NO DICE NADA -->
  <xsl:template match="element-citation//*[not(node())][not(@*)]" mode="sps"/>

  <!-- ··· article ··· -->
  <xsl:template match="article" mode="sps">
    <article article-type="{@article-type}" dtd-version="1.1" specific-use="sps-1.9" xml:lang="{@xml:lang}">
      <xsl:namespace name="mml" select="'http://www.w3.org/1998/Math/MathML'"/>
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:apply-templates select="front" mode="sps"/>
      <xsl:apply-templates select="body" mode="sps"/>
      <back>
        <xsl:apply-templates select="back/ack" mode="sps"/>
        <xsl:call-template name="gbs:referencias"/>
        <xsl:call-template name="gbs:notas"/>
        <xsl:apply-templates select="back/app-group | back/sec" mode="sps"/>
      </back>
    </article>
  </xsl:template>

  <!-- ··· journal-meta ··· -->
  <!-- SciELO PIDE EL TÍTULO ABREVIADO (abbrev-type="publisher"): SALE DEL
       VOLCADO; SIN ÉL, EL TÍTULO ENTERO (EL SCRIPT LO AVISA) -->
  <xsl:template match="journal-title-group" mode="sps">
    <journal-title-group>
      <xsl:apply-templates select="journal-title" mode="sps"/>
      <abbrev-journal-title abbrev-type="publisher">
        <xsl:value-of select="(normalize-space($gbs:revista/titulo-abreviado)[. != ''], normalize-space(journal-title))[1]"/>
      </abbrev-journal-title>
    </journal-title-group>
  </xsl:template>

  <xsl:template match="journal-meta/issn" mode="sps">
    <issn pub-type="{if (@publication-format = 'print') then 'ppub' else 'epub'}">
      <xsl:value-of select="normalize-space(.)"/>
    </issn>
  </xsl:template>

  <!-- ··· article-meta ··· -->
  <xsl:template match="article-meta" mode="sps">
    <article-meta>
      <xsl:apply-templates select="article-id" mode="sps"/>
      <!-- LA POSICIÓN EN EL NÚMERO, CON CINCO CIFRAS (pub-id-type="other",
           COMO EL ARTÍCULO DE EJEMPLO DE packtools: «00304») -->
      <article-id pub-id-type="other">
        <xsl:value-of select="format-number(xs:integer($orden), '00000')"/>
      </article-id>
      <xsl:apply-templates select="article-categories | title-group | contrib-group | aff | author-notes | pub-date
                                   | volume" mode="sps"/>
      <xsl:call-template name="gbs:issue"/>
      <xsl:apply-templates select="issue-title | fpage | lpage | elocation-id" mode="sps"/>
      <xsl:apply-templates select="pub-history" mode="sps"/>
      <xsl:apply-templates select="permissions | abstract | trans-abstract | kwd-group | funding-group" mode="sps"/>
      <xsl:call-template name="gbs:counts"/>
    </article-meta>
  </xsl:template>

  <!-- EL NÚMERO Y EL SUPLEMENTO: SciELO NO USA supplement; EL SUPLEMENTO VA
       EN EL TEXTO DE issue («5 suppl 1», «suppl 1»), QUE ES DE DONDE
       packtools LO SACA PARA EL NOMBRE DEL PAQUETE (lib/normalizer.py,
       extract_number_and_supplment_from_issue_element) -->
  <xsl:template name="gbs:issue">
    <xsl:variable name="n" select="normalize-space(issue[1])"/>
    <xsl:variable name="s" select="normalize-space(supplement[1])"/>
    <xsl:if test="$n != '' or $s != ''">
      <issue>
        <xsl:value-of select="string-join(($n[. != ''], if ($s != '') then concat('suppl ', $s) else ()), ' ')"/>
      </issue>
    </xsl:if>
  </xsl:template>

  <!-- SOLO LA SECCIÓN (heading): LOS GRUPOS PROPIOS (dossier) NO SON DE SciELO -->
  <xsl:template match="article-categories" mode="sps">
    <article-categories>
      <xsl:apply-templates select="subj-group[@subj-group-type = 'heading']" mode="sps"/>
    </article-categories>
  </xsl:template>

  <!-- EL ORCID SIN LA URL, COMO EL ARTÍCULO DE EJEMPLO DE packtools -->
  <xsl:template match="contrib-id[@contrib-id-type = 'orcid']" mode="sps">
    <contrib-id contrib-id-type="orcid">
      <xsl:value-of select="replace(normalize-space(.), '^https?://orcid\.org/', '')"/>
    </contrib-id>
  </xsl:template>

  <!-- EL ROL, SIN LOS ATRIBUTOS DE VOCABULARIO (JATS 1.2+): EL TEXTO -->
  <xsl:template match="contrib/role" mode="sps">
    <role><xsl:value-of select="normalize-space(.)"/></role>
  </xsl:template>

  <!-- LA AFILIACIÓN COMO LA PIDE SciELO: orgname, orgdiv, addr-line/city,
       country CON @country Y LA CADENA ORIGINAL ENTERA. EL ROR NO TIENE
       LUGAR EN SciELO PS 1.9 -->
  <xsl:template match="aff" mode="sps">
    <aff id="{@id}">
      <xsl:for-each select=".//institution[@content-type = 'orgname']">
        <institution content-type="orgname"><xsl:value-of select="normalize-space(.)"/></institution>
      </xsl:for-each>
      <xsl:for-each select=".//institution[starts-with(@content-type, 'orgdiv')]">
        <institution content-type="{@content-type}"><xsl:value-of select="normalize-space(.)"/></institution>
      </xsl:for-each>
      <xsl:if test="city">
        <addr-line>
          <named-content content-type="city"><xsl:value-of select="normalize-space(city)"/></named-content>
        </addr-line>
      </xsl:if>
      <xsl:for-each select="country">
        <country>
          <xsl:copy-of select="@country"/>
          <xsl:value-of select="normalize-space(.)"/>
        </country>
      </xsl:for-each>
      <institution content-type="original">
        <xsl:value-of select="normalize-space(string-join((.//institution, city, country) ! normalize-space(.), ', '))"/>
      </institution>
    </aff>
  </xsl:template>

  <!-- LAS NOTAS DE AUTOR CON LOS TIPOS DE SciELO -->
  <xsl:template match="author-notes/fn" mode="sps">
    <xsl:variable name="tipo" select="string(@fn-type)"/>
    <fn fn-type="{if ($tipo = 'coi-statement') then 'conflict'
                  else if ($tipo = ('author', 'con', 'conflict', 'corresp', 'current-aff', 'deceased', 'edited-by',
                                    'equal', 'on-leave', 'present-address', 'previously-at', 'presented-at')) then $tipo
                  else 'other'}">
      <xsl:apply-templates select="@id | node()" mode="sps"/>
    </fn>
  </xsl:template>

  <!-- LAS FECHAS DEL PROCESO: pub-history ES DE JATS 1.2; EN 1.1, history -->
  <xsl:template match="pub-history" mode="sps">
    <history>
      <xsl:for-each select="event/date">
        <date date-type="{@date-type}">
          <xsl:apply-templates select="day | month | year" mode="sps"/>
        </date>
      </xsl:for-each>
    </history>
  </xsl:template>

  <!-- LA LICENCIA COMO LA PIDE SciELO: license-type, xlink:href Y xml:lang;
       EL TEXTO EN license-p. LOS ELEMENTOS ali: QUEDAN FUERA -->
  <xsl:template match="permissions" mode="sps">
    <permissions>
      <xsl:apply-templates select="copyright-statement | copyright-year | copyright-holder" mode="sps"/>
      <xsl:for-each select="license">
        <license license-type="open-access" xml:lang="{$gbs:lang}"
                 xlink:href="{normalize-space((ali:license_ref, @xlink:href)[1])}">
          <xsl:apply-templates select="license-p" mode="sps"/>
        </license>
      </xsl:for-each>
    </permissions>
  </xsl:template>

  <!-- EL GRUPO DE PALABRAS CLAVE CON SU IDIOMA (SciELO LO EXIGE) Y SIN LOS
       ATRIBUTOS DE VOCABULARIO (JATS 1.2+) -->
  <xsl:template match="kwd-group" mode="sps">
    <kwd-group xml:lang="{(@xml:lang, $gbs:lang)[1]}">
      <xsl:copy-of select="@kwd-group-type"/>
      <xsl:for-each select="kwd">
        <kwd><xsl:apply-templates select="node()" mode="sps"/></kwd>
      </xsl:for-each>
    </kwd-group>
  </xsl:template>

  <!-- EL IDENTIFICADOR DEL FINANCIADOR, SIN LOS ATRIBUTOS DE VOCABULARIO -->
  <xsl:template match="institution-id" mode="sps">
    <institution-id>
      <xsl:copy-of select="@institution-id-type"/>
      <xsl:value-of select="normalize-space(.)"/>
    </institution-id>
  </xsl:template>

  <!-- LO QUE NO VA: LA PÁGINA Y EL PDF LOS PUBLICA SciELO; LAS RELACIONES
       LOCALES Y LOS DATOS PROPIOS SON DE gbpublisher -->
  <xsl:template match="self-uri | related-article | custom-meta-group" mode="sps"/>

  <!-- LOS CONTEOS: LA PÁGINA, SOLO CON PÁGINAS NUMÉRICAS (counts_pages) -->
  <xsl:template name="gbs:counts">
    <xsl:variable name="am" select="/article/front/article-meta"/>
    <counts>
      <fig-count count="{count(/article/body//fig)}"/>
      <table-count count="{count(/article/body//table-wrap)}"/>
      <equation-count count="{count(/article/body//disp-formula)}"/>
      <ref-count count="{count(/article/back/ref-list//ref)}"/>
      <xsl:if test="matches(normalize-space($am/fpage), '^\d+$') and matches(normalize-space($am/lpage), '^\d+$') and not(normalize-space($am/elocation-id))">
        <page-count count="{xs:integer($am/lpage) - xs:integer($am/fpage) + 1}"/>
      </xsl:if>
    </counts>
  </xsl:template>

  <!-- ··· body ··· -->

  <!-- UNA CITA: EL TEXTO DE biblatex DEL GRUPO QUE EMPIEZA ACÁ, EN JATS -->
  <xsl:template match="xref[@ref-type = 'bibr']" mode="sps">
    <xsl:variable name="html" as="node()*">
      <xsl:apply-templates select="." mode="#default"/>
    </xsl:variable>
    <xsl:apply-templates select="$html" mode="html-jats"/>
  </xsl:template>

  <!-- UNA NOTA DEL TEXTO: LA LLAMADA; LA NOTA VA EN back/fn-group -->
  <xsl:template match="fn[not(ancestor::author-notes)][not(ancestor::table-wrap-foot)]" mode="sps">
    <xsl:variable name="n" select="gbe:numero-nota(.)"/>
    <xref ref-type="fn" rid="fn{$n}"><sup><xsl:value-of select="$n"/></sup></xref>
  </xsl:template>

  <!-- LA FIGURA: ROTULO, PIE CON TÍTULO (caption_title) Y EL ARCHIVO CON SU
       NOMBRE SPS -->
  <xsl:template match="fig" mode="sps">
    <fig>
      <xsl:copy-of select="@id"/>
      <label>
        <xsl:text>Figura </xsl:text>
        <xsl:value-of select="count(preceding::fig[ancestor::body]) + 1"/>
      </label>
      <xsl:call-template name="gbs:caption"/>
      <xsl:for-each select="graphic">
        <graphic xlink:href="{gbs:nombre-imagen(..)}">
          <xsl:apply-templates select="alt-text" mode="sps"/>
        </graphic>
      </xsl:for-each>
      <xsl:apply-templates select="attrib" mode="sps"/>
    </fig>
  </xsl:template>

  <!-- EL CUADRO: ROTULO Y PIE CON TÍTULO, COMO LA FIGURA -->
  <xsl:template match="table-wrap" mode="sps">
    <table-wrap>
      <xsl:copy-of select="@id"/>
      <label>
        <xsl:text>Cuadro </xsl:text>
        <xsl:value-of select="count(preceding::table-wrap[ancestor::body]) + 1"/>
      </label>
      <xsl:call-template name="gbs:caption"/>
      <xsl:apply-templates select="* except (label, caption)" mode="sps"/>
    </table-wrap>
  </xsl:template>

  <!-- EL PIE: SciELO EXIGE caption/title. SI EL PIE NO TIENE TÍTULO, EL
       PRIMER PÁRRAFO LO ES; LOS DEMÁS SIGUEN COMO PÁRRAFOS -->
  <xsl:template name="gbs:caption">
    <xsl:if test="caption">
      <caption>
        <xsl:choose>
          <xsl:when test="caption/title">
            <xsl:apply-templates select="caption/node()" mode="sps"/>
          </xsl:when>
          <xsl:otherwise>
            <title><xsl:apply-templates select="caption/p[1]/node()" mode="sps"/></title>
            <xsl:apply-templates select="caption/p[position() gt 1]" mode="sps"/>
          </xsl:otherwise>
        </xsl:choose>
      </caption>
    </xsl:if>
  </xsl:template>

  <!-- EL CÓDIGO (SC-42): EL TEXTO, CON SU LENGUAJE -->
  <xsl:template match="code" mode="sps">
    <code>
      <xsl:copy-of select="@language"/>
      <xsl:value-of select="."/>
    </code>
  </xsl:template>

  <!-- ··· back ··· -->

  <!-- LAS REFERENCIAS EN EL ORDEN DE biblatex (EL DEL PDF): CADA UNA CON SU
       TEXTO FORMATEADO (mixed-citation) Y SU ESTRUCTURA (element-citation) -->
  <xsl:template name="gbs:referencias">
    <xsl:variable name="entradas" select="gbct:entradas-bib($archivo, true(), gbct:estilo-numerico($estilo_cita))"/>
    <xsl:variable name="refs" select="/article/back/ref-list//ref"/>
    <xsl:if test="exists($entradas)">
      <ref-list>
        <title><xsl:value-of select="gbe:rotulo('referencias')"/></title>
        <xsl:for-each select="$entradas">
          <xsl:variable name="clave" select="gbct:clave-entrada(.)"/>
          <xsl:variable name="ref" select="$refs[gbct:clave(@id) = $clave][1]"/>
          <xsl:if test="empty($ref)">
            <xsl:message terminate="yes">[scielo] biblatex imprimió <xsl:value-of select="$clave"/> y el canónico no la tiene (<xsl:value-of select="$archivo"/>).</xsl:message>
          </xsl:if>
          <xsl:variable name="html" as="node()*">
            <xsl:apply-templates select="." mode="gbct:fragmento"/>
          </xsl:variable>
          <ref id="{$ref/@id}">
            <mixed-citation>
              <xsl:apply-templates select="$html" mode="html-jats"/>
            </mixed-citation>
            <xsl:apply-templates select="$ref/element-citation" mode="sps"/>
          </ref>
        </xsl:for-each>
      </ref-list>
    </xsl:if>
  </xsl:template>

  <!-- LAS NOTAS DEL TEXTO, AL FINAL, CON SU NÚMERO -->
  <xsl:template name="gbs:notas">
    <!-- SciELO EXIGE QUE CADA award-id APAREZCA EN back//fn[@fn-type =
         'financial-disclosure']/p O EN back//ack/p (packtools,
         catalogs/checks.py, funding_group). SI LOS AGRADECIMIENTOS NO LOS
         NOMBRAN, LA NOTA SE ARMA CON LAS FUENTES Y LOS CÓDIGOS DEL
         funding-group: NO SE INVENTA TEXTO -->
    <xsl:variable name="ack" select="string-join(/article/back/ack//p, ' ')"/>
    <xsl:variable name="grupos" select="/article/front/article-meta/funding-group/award-group"/>
    <xsl:variable name="faltan" select="$grupos/award-id[not(contains($ack, normalize-space(.)))]"/>
    <xsl:if test="exists($gbs:notas) or exists($faltan)">
      <fn-group>
        <xsl:if test="exists($faltan)">
          <fn fn-type="financial-disclosure" id="fn-fin">
            <p>
              <xsl:value-of select="if (starts-with($gbs:lang, 'en')) then 'Funding: '
                                    else if (starts-with($gbs:lang, 'pt')) then 'Financiamento: '
                                    else 'Financiamiento: '"/>
              <xsl:value-of select="string-join(
                  for $g in $grupos
                  return concat(normalize-space(string-join($g/funding-source//institution, ' ')),
                                if ($g/award-id) then concat(' (', string-join($g/award-id/normalize-space(), ', '), ')') else ''),
                  '; ')"/>
              <xsl:text>.</xsl:text>
            </p>
          </fn>
        </xsl:if>
        <xsl:for-each select="$gbs:notas">
          <xsl:variable name="n" select="gbe:numero-nota(.)"/>
          <fn fn-type="other" id="fn{$n}">
            <label><xsl:value-of select="$n"/></label>
            <xsl:apply-templates select="node()" mode="sps"/>
          </fn>
        </xsl:for-each>
      </fn-group>
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================
       DEL HTML DE LAS CITAS A JATS (mode="html-jats")
       ================================================================== -->

  <!-- EL ENLACE DE UNA CITA A SU REFERENCIA -->
  <xsl:template match="h:a[starts-with(@href, '#')]" mode="html-jats">
    <xref ref-type="bibr" rid="{substring(@href, 2)}">
      <xsl:apply-templates mode="html-jats"/>
    </xref>
  </xsl:template>

  <!-- UN ENLACE A LA RED (UN DOI, UNA URL DE LA REFERENCIA) -->
  <xsl:template match="h:a[matches(@href, '^https?://')]" mode="html-jats">
    <ext-link ext-link-type="uri" xlink:href="{@href}">
      <xsl:apply-templates mode="html-jats"/>
    </ext-link>
  </xsl:template>

  <xsl:template match="h:em | h:i" mode="html-jats">
    <italic><xsl:apply-templates mode="html-jats"/></italic>
  </xsl:template>

  <xsl:template match="h:strong | h:b" mode="html-jats">
    <bold><xsl:apply-templates mode="html-jats"/></bold>
  </xsl:template>

  <xsl:template match="h:sup | h:sub" mode="html-jats">
    <xsl:element name="{local-name()}"><xsl:apply-templates mode="html-jats"/></xsl:element>
  </xsl:template>

  <!-- LO DEMÁS (span, div, a sin destino): SU CONTENIDO -->
  <xsl:template match="*" mode="html-jats">
    <xsl:apply-templates mode="html-jats"/>
  </xsl:template>

  <xsl:template match="text()" mode="html-jats">
    <xsl:copy/>
  </xsl:template>

</xsl:stylesheet>
