<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  datos-a-front-jats.xsl — gbpublisher
  =====================================================
  DESCRIPCIÓN : EL <front> JATS 1.4 DE UN ARTÍCULO, A PARTIR DEL VOLCADO DEL
                NÚMERO QUE ESCRIBE GAMBAS (m_CanonicoRevista,
                tmp/numero-datos.xml, versión 1). ETAPA A0 DE LAS SALIDAS DE
                REVISTAS (DECISIONES DE ALBERTO, 07/11/2026; DOCUMENTO DE
                TRABAJO claude/salidas-revistas.md): GAMBAS LLEVA LOS DATOS,
                LA XSLT SABE JATS.
  USO         : NO SE CORRE SOLA. LA INCLUYE ensamblar-articulo-canonico.xsl,
                QUE LLAMA A LA PLANTILLA front CON EL <articulo> DEL VOLCADO.
  FUENTES     : DTD JATS 1.4 ARCHIVING (.hidden/dtd) Y SU TAG LIBRARY; LAS
                REGLAS DE JATS4R (JATS4R/jats-schematrons v0.0.17):
                - financiamiento: UN funding-group; un funding-source por
                  award-group, con UN institution-wrap; el Funder ID como
                  DOI pelado con vocab="open-funder-registry".
                - CRediT: role/@vocab="credit", vocab-identifier, y
                  vocab-term y vocab-term-identifier como en credit-roles.xml.
                - conflicto de intereses: fn[@fn-type="coi-statement"] DENTRO
                  DE author-notes.
                - permisos: SIEMPRE <permissions>; copyright-year Y
                  copyright-holder JUNTOS (EL VOLCADO YA LO RESPETA).
                - palabras clave: SIN xml:lang EN EL GRUPO DEL IDIOMA DEL
                  ARTÍCULO; @kwd-group-type EN CADA GRUPO.
                - fechas: <history> ESTÁ DEPRECADO EN 1.4 (TAG LIBRARY): LAS
                  DEL PROCESO VAN EN pub-history/event.
  PENDIENTE   : EL vocab-identifier (URI) DE MeSH Y DE DeCS NO ESTÁ VERIFICADO:
                SE EMITE SOLO @vocab Y EL CÓDIGO DEL TÉRMINO.
  =====================================================
-->
<xsl:stylesheet version="2.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
    xmlns:gbj="urn:gbpublisher:jats"
    exclude-result-prefixes="xs gbj">

  <!-- ==========================================================
       CATÁLOGOS FIJOS
       ========================================================== -->

  <!-- CRediT: LOS 14 TÉRMINOS Y SUS URI, COMO credit-roles.xml DE JATS4R
       (v0.0.17). LA BASE GUARDA EL TÉRMINO (SC-23; 1.17.0 LOS DEJÓ EN ESTA
       FORMA) -->
  <xsl:variable name="gbj:credit" as="element()*">
    <r t="Conceptualization" u="https://credit.niso.org/contributor-roles/conceptualization/"/>
    <r t="Data curation" u="https://credit.niso.org/contributor-roles/data-curation/"/>
    <r t="Formal Analysis" u="https://credit.niso.org/contributor-roles/formal-analysis/"/>
    <r t="Funding acquisition" u="https://credit.niso.org/contributor-roles/funding-acquisition/"/>
    <r t="Investigation" u="https://credit.niso.org/contributor-roles/investigation/"/>
    <r t="Methodology" u="https://credit.niso.org/contributor-roles/methodology/"/>
    <r t="Project administration" u="https://credit.niso.org/contributor-roles/project-administration/"/>
    <r t="Resources" u="https://credit.niso.org/contributor-roles/resources/"/>
    <r t="Software" u="https://credit.niso.org/contributor-roles/software/"/>
    <r t="Supervision" u="https://credit.niso.org/contributor-roles/supervision/"/>
    <r t="Validation" u="https://credit.niso.org/contributor-roles/validation/"/>
    <r t="Visualization" u="https://credit.niso.org/contributor-roles/visualization/"/>
    <r t="Writing – original draft" u="https://credit.niso.org/contributor-roles/writing-original-draft/"/>
    <r t="Writing – review &amp; editing" u="https://credit.niso.org/contributor-roles/writing-review-editing/"/>
  </xsl:variable>

  <!-- EL TEXTO DE CADA ENLACE DE self-uri (articulo_ubicacion.tipo) -->
  <xsl:variable name="gbj:ubicaciones" as="element()*">
    <u tipo="pagina" es="Página del artículo" en="Article page" pt="Página do artigo"/>
    <u tipo="html" es="Texto completo en HTML" en="Full text (HTML)" pt="Texto completo em HTML"/>
    <u tipo="pdf" es="PDF del artículo" en="Article PDF" pt="PDF do artigo"/>
    <u tipo="epub" es="EPUB del número" en="Issue EPUB" pt="EPUB do número"/>
    <u tipo="xml" es="XML JATS del artículo" en="Article JATS XML" pt="XML JATS do artigo"/>
  </xsl:variable>

  <!-- ROL DEL CONTRIBUYENTE EN LA BASE → @contrib-type DE JATS -->
  <xsl:function name="gbj:tipo-contrib" as="xs:string">
    <xsl:param name="rol" as="xs:string"/>
    <xsl:sequence select="if ($rol eq 'editor') then 'editor' else if ($rol eq 'traductor') then 'translator' else 'author'"/>
  </xsl:function>

  <!-- ORCID COMO URL (FORMA DE JATS4R Y DE CROSSREF); LA BASE PUEDE TENER EL
       IDENTIFICADOR SOLO -->
  <xsl:function name="gbj:orcid" as="xs:string">
    <xsl:param name="v" as="xs:string"/>
    <xsl:sequence select="if (starts-with($v, 'http')) then $v else concat('https://orcid.org/', $v)"/>
  </xsl:function>

  <!-- PÁRRAFOS DE UN TEXTO DE LA BASE: UNA LÍNEA EN BLANCO LOS SEPARA -->
  <xsl:template name="gbj:parrafos">
    <xsl:param name="texto" as="xs:string"/>
    <xsl:for-each select="tokenize(normalize-unicode($texto), '\n[ \t]*\n')[normalize-space(.) ne '']">
      <p><xsl:value-of select="normalize-space(.)"/></p>
    </xsl:for-each>
  </xsl:template>

  <!-- UNA FECHA ISO (aaaa-mm-dd) COMO day, month, year -->
  <xsl:template name="gbj:fecha-partes">
    <xsl:param name="iso" as="xs:string"/>
    <day><xsl:value-of select="substring($iso, 9, 2)"/></day>
    <month><xsl:value-of select="substring($iso, 6, 2)"/></month>
    <year><xsl:value-of select="substring($iso, 1, 4)"/></year>
  </xsl:template>

  <!-- ==========================================================
       EL FRONT
       ========================================================== -->
  <xsl:template name="front">
    <xsl:param name="art" as="element(articulo)"/>
    <xsl:variable name="datos" select="$art/ancestor::numero-datos"/>
    <front>
      <xsl:call-template name="journal-meta">
        <xsl:with-param name="rev" select="$datos/revista"/>
      </xsl:call-template>
      <xsl:call-template name="article-meta">
        <xsl:with-param name="art" select="$art"/>
      </xsl:call-template>
    </front>
  </xsl:template>

  <!-- ==========================================================
       journal-meta
       ========================================================== -->
  <xsl:template name="journal-meta">
    <xsl:param name="rev" as="element(revista)"/>
    <journal-meta>
      <xsl:if test="$rev/acronimo">
        <journal-id journal-id-type="publisher-id"><xsl:value-of select="$rev/acronimo"/></journal-id>
      </xsl:if>
      <journal-title-group>
        <journal-title><xsl:value-of select="$rev/titulo"/></journal-title>
        <xsl:if test="$rev/titulo-abreviado">
          <abbrev-journal-title abbrev-type="publisher"><xsl:value-of select="$rev/titulo-abreviado"/></abbrev-journal-title>
        </xsl:if>
      </journal-title-group>
      <xsl:for-each select="$rev/issn[@tipo = 'impreso']">
        <issn publication-format="print"><xsl:value-of select="."/></issn>
      </xsl:for-each>
      <xsl:for-each select="$rev/issn[@tipo = 'electronico']">
        <issn publication-format="electronic"><xsl:value-of select="."/></issn>
      </xsl:for-each>
      <!-- publisher-name SOLO ADMITE TEXTO EN 1.4: EL ROR DE LA EDITORIAL NO
           ENTRA ACÁ (LO TOMAN DEL VOLCADO LOS SABORES QUE LO PIDEN) -->
      <xsl:variable name="editorial" select="($rev/editorial, $rev/institucion)[1]"/>
      <xsl:if test="$editorial">
        <publisher>
          <publisher-name><xsl:value-of select="$editorial"/></publisher-name>
          <xsl:variable name="lugar" select="string-join(($rev/ciudad, $rev/pais), ', ')"/>
          <xsl:if test="$lugar ne ''">
            <publisher-loc><xsl:value-of select="$lugar"/></publisher-loc>
          </xsl:if>
        </publisher>
      </xsl:if>
    </journal-meta>
  </xsl:template>

  <!-- ==========================================================
       article-meta, EN EL ORDEN DEL MODELO DEL DTD
       ========================================================== -->
  <xsl:template name="article-meta">
    <xsl:param name="art" as="element(articulo)"/>
    <xsl:variable name="datos" select="$art/ancestor::numero-datos"/>
    <xsl:variable name="num" select="$datos/numero"/>
    <xsl:variable name="lang" select="string($art/@idioma)"/>
    <article-meta>

      <!-- 1. IDENTIFICADORES -->
      <xsl:for-each select="$art/doi">
        <article-id pub-id-type="doi"><xsl:value-of select="."/></article-id>
      </xsl:for-each>
      <xsl:for-each select="$art/pmid">
        <article-id pub-id-type="pmid"><xsl:value-of select="."/></article-id>
      </xsl:for-each>

      <!-- 2. SECCIÓN (heading, DECISIÓN 15) Y DOSSIER -->
      <xsl:variable name="sec" select="$datos/seccion[@codigo = $art/@seccion]"/>
      <xsl:variable name="dos" select="$datos/dossier[@id = $art/@dossier]"/>
      <xsl:if test="$sec or $dos">
        <article-categories>
          <xsl:if test="$sec">
            <subj-group subj-group-type="heading">
              <subject><xsl:value-of select="($sec/titulo[@idioma = $lang], $sec/titulo, $sec/@codigo)[1]"/></subject>
            </subj-group>
          </xsl:if>
          <xsl:if test="$dos">
            <subj-group subj-group-type="dossier">
              <subject><xsl:value-of select="normalize-space(string(($dos/titulo[@idioma = $lang], $dos/titulo)[1]))"/></subject>
            </subj-group>
          </xsl:if>
        </article-categories>
      </xsl:if>

      <!-- 3. TÍTULOS -->
      <title-group>
        <article-title><xsl:apply-templates select="$art/titulo/node()" mode="titulo"/></article-title>
        <xsl:if test="$art/subtitulo">
          <subtitle><xsl:apply-templates select="$art/subtitulo/node()" mode="titulo"/></subtitle>
        </xsl:if>
        <xsl:for-each-group select="$art/titulo-traducido | $art/subtitulo-traducido" group-by="@idioma">
          <xsl:sort select="current-grouping-key()"/>
          <xsl:if test="current-group()[self::titulo-traducido]">
            <trans-title-group xml:lang="{current-grouping-key()}">
              <trans-title><xsl:apply-templates select="current-group()[self::titulo-traducido][1]/node()" mode="titulo"/></trans-title>
              <xsl:for-each select="current-group()[self::subtitulo-traducido][1]">
                <trans-subtitle><xsl:apply-templates select="node()" mode="titulo"/></trans-subtitle>
              </xsl:for-each>
            </trans-title-group>
          </xsl:if>
        </xsl:for-each-group>
        <xsl:if test="$art/titulo-corto">
          <alt-title alt-title-type="running-head"><xsl:apply-templates select="$art/titulo-corto/node()" mode="titulo"/></alt-title>
        </xsl:if>
      </title-group>

      <!-- 4. CONTRIBUYENTES Y AFILIACIONES -->
      <xsl:call-template name="contribuyentes">
        <xsl:with-param name="art" select="$art"/>
      </xsl:call-template>

      <!-- 5. NOTAS DE AUTOR: CORRESPONDENCIA, NOTAS Y CONFLICTO DE INTERESES -->
      <xsl:variable name="coi" select="$art/declaracion[@tipo = 'conflicto_interes']"/>
      <xsl:if test="$art/notas-autor or $coi">
        <author-notes>
          <xsl:for-each select="$coi">
            <fn fn-type="coi-statement">
              <xsl:if test="@idioma ne $lang"><xsl:attribute name="xml:lang" select="@idioma"/></xsl:if>
              <xsl:call-template name="gbj:parrafos"><xsl:with-param name="texto" select="string(.)"/></xsl:call-template>
            </fn>
          </xsl:for-each>
          <xsl:for-each select="$art/notas-autor">
            <fn fn-type="other">
              <xsl:call-template name="gbj:parrafos"><xsl:with-param name="texto" select="string(.)"/></xsl:call-template>
            </fn>
          </xsl:for-each>
        </author-notes>
      </xsl:if>

      <!-- 6. FECHAS DE PUBLICACIÓN: LA DEL ARTÍCULO Y LA DEL NÚMERO -->
      <xsl:for-each select="$art/fecha[@tipo = 'publicacion']">
        <pub-date publication-format="electronic" date-type="pub" iso-8601-date="{.}">
          <xsl:call-template name="gbj:fecha-partes"><xsl:with-param name="iso" select="string(.)"/></xsl:call-template>
        </pub-date>
      </xsl:for-each>
      <xsl:if test="$num/@anio">
        <pub-date publication-format="electronic" date-type="collection">
          <xsl:if test="$num/@mes">
            <month><xsl:value-of select="format-number(xs:integer($num/@mes), '00')"/></month>
          </xsl:if>
          <year><xsl:value-of select="$num/@anio"/></year>
        </pub-date>
      </xsl:if>

      <!-- 7. VOLUMEN, NÚMERO, PÁGINAS -->
      <xsl:if test="$num/@volumen"><volume><xsl:value-of select="$num/@volumen"/></volume></xsl:if>
      <xsl:if test="$num/@numero"><issue><xsl:value-of select="$num/@numero"/></issue></xsl:if>
      <xsl:if test="$num/titulo-especial">
        <!-- issue-title NO ADMITE <break/> (DTD 1.4): EL CORTE ES UN ESPACIO -->
        <issue-title><xsl:value-of select="normalize-space(string($num/titulo-especial))"/></issue-title>
      </xsl:if>
      <xsl:if test="$num/@suplemento"><supplement><xsl:value-of select="$num/@suplemento"/></supplement></xsl:if>
      <!-- SIN RANGO HASTA QUE LA COMPOSICIÓN LO ESCRIBA EN LA BASE (DECISIÓN 11) -->
      <xsl:choose>
        <xsl:when test="$art/paginas/@elocation">
          <elocation-id><xsl:value-of select="$art/paginas/@elocation"/></elocation-id>
        </xsl:when>
        <xsl:when test="$art/paginas/@inicio">
          <fpage><xsl:value-of select="$art/paginas/@inicio"/></fpage>
          <xsl:if test="$art/paginas/@fin"><lpage><xsl:value-of select="$art/paginas/@fin"/></lpage></xsl:if>
        </xsl:when>
      </xsl:choose>

      <!-- 8. EL PROCESO EDITORIAL: pub-history/event (<history> DEPRECADO) -->
      <xsl:variable name="proceso" select="$art/fecha[@tipo = ('recepcion', 'revision', 'aceptacion')]"/>
      <xsl:if test="$proceso">
        <pub-history>
          <xsl:for-each select="$proceso">
            <xsl:variable name="tipo" select="if (@tipo eq 'recepcion') then 'received' else if (@tipo eq 'revision') then 'rev-recd' else 'accepted'"/>
            <event event-type="{$tipo}">
              <date date-type="{$tipo}" iso-8601-date="{.}">
                <xsl:call-template name="gbj:fecha-partes"><xsl:with-param name="iso" select="string(.)"/></xsl:call-template>
              </date>
            </event>
          </xsl:for-each>
        </pub-history>
      </xsl:if>

      <!-- 9. PERMISOS: SIEMPRE (JATS4R), CON LO EFECTIVO QUE TRAE EL VOLCADO -->
      <xsl:call-template name="permisos">
        <xsl:with-param name="perm" select="$art/permisos"/>
      </xsl:call-template>

      <!-- 10. DÓNDE ESTÁ PUBLICADO -->
      <!-- CADA ENLACE CON SU TEXTO (JATS4R, accessibility-errors.sch): EN EL
           IDIOMA DEL ARTÍCULO SI ES es, en O pt; SI NO, EN INGLÉS -->
      <xsl:for-each select="$art/ubicacion">
        <xsl:variable name="t" select="$gbj:ubicaciones[@tipo = current()/@tipo]"/>
        <self-uri content-type="{@tipo}" xlink:href="{.}"><xsl:value-of select="($t/@*[local-name() = substring($lang, 1, 2)], $t/@en, @tipo)[1]"/></self-uri>
      </xsl:for-each>

      <!-- 11. RELACIONES -->
      <xsl:for-each select="$art/relacion">
        <xsl:call-template name="relacion"/>
      </xsl:for-each>

      <!-- 12. RESÚMENES: EL DEL IDIOMA DEL ARTÍCULO ES abstract; LOS DEMÁS, trans-abstract -->
      <xsl:for-each select="$art/resumen[@idioma = $lang]">
        <abstract><xsl:call-template name="resumen"><xsl:with-param name="datos" select="$datos"/><xsl:with-param name="art" select="$art"/></xsl:call-template></abstract>
      </xsl:for-each>
      <xsl:for-each select="$art/resumen[@idioma ne $lang]">
        <trans-abstract xml:lang="{@idioma}"><xsl:call-template name="resumen"><xsl:with-param name="datos" select="$datos"/><xsl:with-param name="art" select="$art"/></xsl:call-template></trans-abstract>
      </xsl:for-each>

      <!-- 13. PALABRAS CLAVE: PRIMERO LAS DEL IDIOMA DEL ARTÍCULO -->
      <xsl:for-each select="$art/palabras-clave">
        <xsl:sort select="@idioma ne $lang"/>
        <kwd-group kwd-group-type="{if (@vocabulario) then @vocabulario else 'author'}">
          <xsl:if test="@idioma ne $lang"><xsl:attribute name="xml:lang" select="@idioma"/></xsl:if>
          <xsl:if test="@vocabulario"><xsl:attribute name="vocab" select="@vocabulario"/></xsl:if>
          <xsl:for-each select="palabra">
            <kwd>
              <xsl:if test="@identificador"><xsl:attribute name="vocab-term-identifier" select="@identificador"/></xsl:if>
              <xsl:value-of select="."/>
            </kwd>
          </xsl:for-each>
        </kwd-group>
      </xsl:for-each>

      <!-- 14. FINANCIAMIENTO: UN SOLO funding-group (JATS4R) -->
      <xsl:variable name="dfin" select="$art/declaracion[@tipo = 'financiamiento']"/>
      <xsl:if test="$art/financiador or $dfin">
        <funding-group>
          <xsl:for-each select="$art/financiador">
            <award-group id="{concat('award-', @orden)}">
              <funding-source>
                <institution-wrap>
                  <xsl:choose>
                    <xsl:when test="@tipo-id = 'ror'">
                      <institution-id institution-id-type="ror"><xsl:value-of select="@id"/></institution-id>
                    </xsl:when>
                    <xsl:when test="@tipo-id = 'funder_id'">
                      <institution-id institution-id-type="doi" vocab="open-funder-registry" vocab-identifier="10.13039/open_funder_registry"><xsl:value-of select="@id"/></institution-id>
                    </xsl:when>
                  </xsl:choose>
                  <institution><xsl:value-of select="nombre"/></institution>
                </institution-wrap>
              </funding-source>
              <xsl:for-each select="proyecto"><award-id><xsl:value-of select="."/></award-id></xsl:for-each>
            </award-group>
          </xsl:for-each>
          <xsl:for-each select="$dfin">
            <funding-statement>
              <xsl:if test="@idioma ne $lang"><xsl:attribute name="xml:lang" select="@idioma"/></xsl:if>
              <xsl:value-of select="normalize-space(.)"/>
            </funding-statement>
          </xsl:for-each>
        </funding-group>
      </xsl:if>

      <!-- 15. LO PROPIO DE gbpublisher QUE NO TIENE ELEMENTO EN JATS -->
      <xsl:if test="$art/@anonimos = 'si'">
        <custom-meta-group>
          <custom-meta>
            <meta-name>gbpublisher-autoria-anonima</meta-name>
            <meta-value>si</meta-value>
          </custom-meta>
        </custom-meta-group>
      </xsl:if>

    </article-meta>
  </xsl:template>

  <!-- ==========================================================
       CONTRIBUYENTES: UN contrib-group; LAS AFILIACIONES IGUALES SE
       COMPARTEN (UNA <aff> POR INSTITUCIÓN, DEPARTAMENTO Y ROR)
       ========================================================== -->
  <xsl:template name="contribuyentes">
    <xsl:param name="art" as="element(articulo)"/>
    <xsl:variable name="claves-aff" select="distinct-values(for $a in $art/contribuyente/afiliacion return gbj:clave-aff($a))"/>
    <xsl:if test="$art/contribuyente">
      <contrib-group>
        <xsl:for-each select="$art/contribuyente">
          <contrib contrib-type="{gbj:tipo-contrib(@rol)}">
            <xsl:if test="@correspondencia = 'si'"><xsl:attribute name="corresp" select="'yes'"/></xsl:if>
            <xsl:for-each select="persona/@orcid">
              <contrib-id contrib-id-type="orcid"><xsl:value-of select="gbj:orcid(.)"/></contrib-id>
            </xsl:for-each>
            <xsl:choose>
              <xsl:when test="persona">
                <name name-style="western">
                  <surname><xsl:value-of select="persona/apellidos"/></surname>
                  <xsl:if test="persona/nombre"><given-names><xsl:value-of select="persona/nombre"/></given-names></xsl:if>
                  <xsl:if test="persona/sufijo"><suffix><xsl:value-of select="persona/sufijo"/></suffix></xsl:if>
                </name>
              </xsl:when>
              <xsl:otherwise>
                <collab><xsl:value-of select="colectivo"/></collab>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:for-each select="credit">
              <xsl:variable name="t" select="string(.)"/>
              <xsl:variable name="r" select="$gbj:credit[@t = $t]"/>
              <xsl:choose>
                <xsl:when test="$r">
                  <role vocab="credit" vocab-identifier="https://credit.niso.org/" vocab-term="{$t}" vocab-term-identifier="{$r/@u}"><xsl:value-of select="$t"/></role>
                </xsl:when>
                <!-- UN TÉRMINO FUERA DE LA TABLA NO SE DECLARA CRediT -->
                <xsl:otherwise><role><xsl:value-of select="$t"/></role></xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <xsl:for-each select="afiliacion">
              <xref ref-type="aff" rid="{concat('aff-', index-of($claves-aff, gbj:clave-aff(.))[1])}"/>
            </xsl:for-each>
            <xsl:for-each select="@email"><email><xsl:value-of select="."/></email></xsl:for-each>
          </contrib>
        </xsl:for-each>
      </contrib-group>
      <xsl:for-each select="$claves-aff">
        <xsl:variable name="pos" select="position()"/>
        <xsl:variable name="a" select="($art/contribuyente/afiliacion[gbj:clave-aff(.) = current()])[1]"/>
        <aff id="aff-{$pos}">
          <institution-wrap>
            <xsl:for-each select="$a/@ror">
              <institution-id institution-id-type="ror"><xsl:value-of select="."/></institution-id>
            </xsl:for-each>
            <xsl:for-each select="$a/institucion">
              <institution content-type="orgname"><xsl:value-of select="."/></institution>
            </xsl:for-each>
            <xsl:for-each select="$a/departamento">
              <institution content-type="orgdiv1"><xsl:value-of select="."/></institution>
            </xsl:for-each>
          </institution-wrap>
          <xsl:for-each select="$a/ciudad"><xsl:text>, </xsl:text><city><xsl:value-of select="."/></city></xsl:for-each>
          <xsl:for-each select="$a/pais"><xsl:text>, </xsl:text><country><xsl:value-of select="."/></country></xsl:for-each>
        </aff>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <xsl:function name="gbj:clave-aff" as="xs:string">
    <xsl:param name="a" as="element()"/>
    <xsl:sequence select="string-join(($a/institucion, $a/departamento, $a/@ror, $a/ciudad, $a/pais), '|')"/>
  </xsl:function>

  <!-- ==========================================================
       PERMISOS
       ========================================================== -->
  <xsl:template name="permisos">
    <xsl:param name="perm" as="element(permisos)?"/>
    <permissions>
      <xsl:if test="$perm/anio and $perm/titular">
        <copyright-statement>© <xsl:value-of select="$perm/anio"/><xsl:text> </xsl:text><xsl:value-of select="$perm/titular"/></copyright-statement>
        <copyright-year><xsl:value-of select="$perm/anio"/></copyright-year>
        <copyright-holder><xsl:value-of select="$perm/titular"/></copyright-holder>
      </xsl:if>
      <xsl:if test="$perm/@acceso = 'abierto'">
        <ali:free_to_read/>
      </xsl:if>
      <xsl:for-each select="$perm/licencia">
        <license>
          <xsl:if test="@url">
            <ali:license_ref><xsl:value-of select="@url"/></ali:license_ref>
          </xsl:if>
          <license-p><xsl:value-of select="."/></license-p>
        </license>
      </xsl:for-each>
    </permissions>
  </xsl:template>

  <!-- ==========================================================
       RELACIONES: EL DESTINO LOCAL VA POR SU DOI SI LO TIENE; SI NO, POR
       SU ARCHIVO EN @specific-use (LO RESUELVEN LAS SALIDAS)
       ========================================================== -->
  <xsl:template name="relacion">
    <related-article related-article-type="{@tipo}">
      <xsl:choose>
        <xsl:when test="@local-doi">
          <xsl:attribute name="ext-link-type" select="'doi'"/>
          <xsl:attribute name="xlink:href" select="@local-doi"/>
        </xsl:when>
        <xsl:when test="@local">
          <xsl:attribute name="specific-use" select="concat('gbpublisher-local:', @local-archivo)"/>
        </xsl:when>
        <xsl:when test="@doi">
          <xsl:attribute name="ext-link-type" select="'doi'"/>
          <xsl:attribute name="xlink:href" select="@doi"/>
        </xsl:when>
      </xsl:choose>
      <xsl:if test="not(@local)">
        <xsl:for-each select="revista"><source><xsl:value-of select="."/></source></xsl:for-each>
        <xsl:for-each select="@anio"><year><xsl:value-of select="."/></year></xsl:for-each>
        <xsl:for-each select="@volumen"><volume><xsl:value-of select="."/></volume></xsl:for-each>
        <xsl:for-each select="@numero"><issue><xsl:value-of select="."/></issue></xsl:for-each>
        <xsl:for-each select="@fpage"><fpage><xsl:value-of select="."/></fpage></xsl:for-each>
        <xsl:for-each select="@lpage"><lpage><xsl:value-of select="."/></lpage></xsl:for-each>
      </xsl:if>
    </related-article>
  </xsl:template>

  <!-- ==========================================================
       RESUMEN: SIMPLE (PÁRRAFOS) O ESTRUCTURADO (UN sec POR APARTADO,
       CON EL TÍTULO DE LA PLANTILLA EN EL IDIOMA DEL RESUMEN)
       ========================================================== -->
  <xsl:template name="resumen">
    <xsl:param name="datos" as="element(numero-datos)"/>
    <xsl:param name="art" as="element(articulo)"/>
    <xsl:variable name="idioma" select="string(@idioma)"/>
    <xsl:choose>
      <xsl:when test="@estructurado = 'si'">
        <xsl:variable name="pl" select="$datos/plantilla[@id = $datos/seccion[@codigo = $art/@seccion]/@plantilla]"/>
        <xsl:for-each select="apartado">
          <xsl:variable name="c" select="string(@codigo)"/>
          <sec>
            <title><xsl:value-of select="($pl/apartado[@codigo = $c]/titulo[@idioma = $idioma], $pl/apartado[@codigo = $c]/titulo, $c)[1]"/></title>
            <xsl:call-template name="gbj:parrafos"><xsl:with-param name="texto" select="string(.)"/></xsl:call-template>
          </sec>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="gbj:parrafos"><xsl:with-param name="texto" select="string(.)"/></xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- UN TÍTULO DEL VOLCADO: TEXTO Y EL <break/> DEL CORTE (SC-28) -->
  <xsl:template match="break" mode="titulo"><break/></xsl:template>
  <xsl:template match="text()" mode="titulo"><xsl:value-of select="."/></xsl:template>

</xsl:stylesheet>
