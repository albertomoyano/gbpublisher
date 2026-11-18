<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  numero-a-crossref.xsl — gbpublisher
  ============================================================================
  EL SABOR CROSSREF DEL NÚMERO: UN DEPÓSITO (doi_batch) CON LA REVISTA, EL
  NÚMERO Y UN journal_article POR ARTÍCULO, EN EL ESQUEMA 5.4.0
  (schemas/crossref/crossref5.4.0.xsd DEL PAQUETE).
  DECISIONES DE ALBERTO (18/11/2026, claude/salidas-revistas.md):
    - 5.4.0 Y NO 5.5.0: LA 5.5.0 ESTÁ EN XSD 1.1 (xsd:assert) Y xmllint NO
      LA COMPILA (MEDIDO). PASAR A 5.5.0 ES CAMBIAR LA VERSIÓN Y SUMAR LOS
      ROLES CRediT, QUE LA 5.4.0 NO TIENE;
    - EL DEPOSITANTE Y EL REGISTRANTE SON LA EDITORIAL; EL CORREO, EL DEL
      VOLCADO (EL DE LA REVISTA SI TIENE UNO; SI NO, EL DE LA EDITORIAL:
      m_CanonicoRevista.EscribirRevista);
    - LAS REFERENCIAS VAN ESTRUCTURADAS, DESDE element-citation DEL CANÓNICO;
    - UN ARTÍCULO SIN DOI FRENA EL NÚMERO: LO VERIFICA EL SCRIPT ANTES.

  ENTRADA: EL VOLCADO DEL NÚMERO (LA REVISTA, EL NÚMERO Y LOS ARTÍCULOS EN
  SU ORDEN). CADA ARTÍCULO SALE DE SU CANÓNICO (c-{archivo}.xml EN
  dir_canonicos, SIN DOCTYPE: GV-25).

  FUENTES DE CADA DECISIÓN (crossref.org/documentation, LEÍDO EL 18/11):
    - e-id: publisher_item/item_number CON item_number_type="article_number"
      («do not use the <first_page> tag to capture the ID»);
    - RESÚMENES: CON EL PREFIJO jats: Y SU ESPACIO DE NOMBRES;
    - AFILIACIONES: institution_name Y institution_id type="ror";
    - FINANCIAMIENTO: fr:program name="fundref", UN fundgroup POR
      award-group, CON EL ror O EL funder_identifier DENTRO DE funder_name
      (EL EJEMPLO DE LA GUÍA);
    - LICENCIA: ai:program CON license_ref applies_to="vor";
    - timestamp: «must be incremented with each metadata record update»:
      LO DA EL SCRIPT, CON LA HORA DE LA CORRIDA.
  ============================================================================
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
    xmlns:gbx="urn:gbpublisher:crossref"
    xmlns="http://www.crossref.org/schema/5.4.0"
    xmlns:jats="http://www.ncbi.nlm.nih.gov/JATS1"
    xmlns:fr="http://www.crossref.org/fundref.xsd"
    xmlns:ai="http://www.crossref.org/AccessIndicators.xsd"
    exclude-result-prefixes="xs xlink ali gbx">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- LA CARPETA DE LOS CANÓNICOS SIN DOCTYPE, COMO URI CON / FINAL -->
  <xsl:param name="dir_canonicos" as="xs:string" required="yes"/>
  <!-- AAAAMMDDhhmmss DE LA CORRIDA: CRECE EN CADA DEPÓSITO -->
  <xsl:param name="timestamp" as="xs:string" required="yes"/>
  <!-- EL NOMBRE DEL NÚMERO (EL DEL PDF): ARMA EL doi_batch_id -->
  <xsl:param name="numero" as="xs:string" required="yes"/>

  <xsl:variable name="volcado" select="/numero-datos"/>

  <!-- ==================================================================
       FUNCIONES
       ================================================================== -->

  <!-- TEXTO PLANO DE CONTENIDO MIXTO: <break/> ES UN ESPACIO (SC-28) -->
  <xsl:function name="gbx:texto" as="xs:string">
    <xsl:param name="nodos" as="node()*"/>
    <xsl:sequence select="normalize-space(string-join(
        for $t in $nodos//(text() | *:break) return
          if ($t instance of element()) then ' ' else string($t), ''))"/>
  </xsl:function>

  <!-- EL IDIOMA PARA @language: LA SUBETIQUETA PRINCIPAL DE BCP 47. LA
       ENUMERACIÓN DE languages5.4.0.xsd TRAE LOS CÓDIGOS DE DOS LETRAS -->
  <xsl:function name="gbx:idioma" as="xs:string">
    <xsl:param name="bcp47" as="xs:string?"/>
    <xsl:sequence select="lower-case(tokenize(normalize-space($bcp47), '-')[1])"/>
  </xsl:function>

  <!-- UNA FECHA date_t: month, day, year, EN ESE ORDEN Y CON DOS CIFRAS.
       DE @iso-8601-date SI LO HAY; SI NO, DE LOS HIJOS -->
  <xsl:function name="gbx:fecha" as="element()*">
    <xsl:param name="f" as="element()?"/>
    <xsl:variable name="partes" select="
        if ($f/@iso-8601-date) then tokenize(string($f/@iso-8601-date), '-')
        else (normalize-space($f/*:year), normalize-space($f/*:month), normalize-space($f/*:day))"/>
    <xsl:if test="$partes[2] != ''">
      <month><xsl:value-of select="format-number(xs:integer($partes[2]), '00')"/></month>
      <xsl:if test="$partes[3] != ''">
        <day><xsl:value-of select="format-number(xs:integer($partes[3]), '00')"/></day>
      </xsl:if>
    </xsl:if>
    <year><xsl:value-of select="$partes[1]"/></year>
  </xsl:function>

  <!-- UN ORCID COMO URL https://orcid.org/…, EL PATRÓN DE orcid_t -->
  <xsl:function name="gbx:orcid" as="xs:string">
    <xsl:param name="valor" as="xs:string?"/>
    <xsl:variable name="v" select="normalize-space($valor)"/>
    <xsl:sequence select="if ($v = '') then ''
                          else concat('https://orcid.org/', replace($v, '^.*orcid\.org/', ''))"/>
  </xsl:function>

  <!-- ==================================================================
       RAÍZ: EL DEPÓSITO
       ================================================================== -->
  <xsl:template match="/">
    <xsl:variable name="rev" select="$volcado/revista"/>
    <xsl:variable name="num" select="$volcado/numero"/>
    <doi_batch version="5.4.0"
        xsi:schemaLocation="http://www.crossref.org/schema/5.4.0 https://www.crossref.org/schemas/crossref5.4.0.xsd"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <head>
        <!-- EL NÚMERO Y LA CORRIDA: ÚNICO POR DEPÓSITO -->
        <doi_batch_id><xsl:value-of select="concat($numero, '-', $timestamp)"/></doi_batch_id>
        <timestamp><xsl:value-of select="$timestamp"/></timestamp>
        <depositor>
          <depositor_name><xsl:value-of select="gbx:texto($rev/editorial)"/></depositor_name>
          <!-- CROSSREF MANDA AHÍ EL INFORME DEL DEPÓSITO -->
          <email_address><xsl:value-of select="normalize-space($rev/email)"/></email_address>
        </depositor>
        <registrant><xsl:value-of select="gbx:texto($rev/editorial)"/></registrant>
      </head>
      <body>
        <journal>
          <journal_metadata>
            <xsl:variable name="idioma-revista" select="gbx:idioma(tokenize(string($rev/idiomas), ',')[1])"/>
            <xsl:if test="$idioma-revista != ''">
              <xsl:attribute name="language" select="$idioma-revista"/>
            </xsl:if>
            <full_title><xsl:value-of select="gbx:texto($rev/titulo)"/></full_title>
            <xsl:for-each select="$rev/titulo-abreviado[normalize-space()]">
              <abbrev_title><xsl:value-of select="gbx:texto(.)"/></abbrev_title>
            </xsl:for-each>
            <xsl:for-each select="$rev/issn[@tipo = 'impreso'][normalize-space()]">
              <issn media_type="print"><xsl:value-of select="normalize-space(.)"/></issn>
            </xsl:for-each>
            <xsl:for-each select="$rev/issn[@tipo = 'electronico'][normalize-space()]">
              <issn media_type="electronic"><xsl:value-of select="normalize-space(.)"/></issn>
            </xsl:for-each>
          </journal_metadata>

          <!-- EL NÚMERO: LA FECHA ES LA DEL NÚMERO (AÑO Y MES DEL VOLCADO) -->
          <journal_issue>
            <publication_date media_type="online">
              <xsl:if test="normalize-space($num/@mes) != ''">
                <month><xsl:value-of select="format-number(xs:integer($num/@mes), '00')"/></month>
              </xsl:if>
              <year><xsl:value-of select="normalize-space($num/@anio)"/></year>
            </publication_date>
            <xsl:if test="normalize-space($num/@volumen) != ''">
              <journal_volume><volume><xsl:value-of select="normalize-space($num/@volumen)"/></volume></journal_volume>
            </xsl:if>
            <xsl:if test="normalize-space($num/@numero) != ''">
              <issue><xsl:value-of select="normalize-space($num/@numero)"/></issue>
            </xsl:if>
          </journal_issue>

          <xsl:for-each select="$volcado/articulo">
            <xsl:variable name="ruta" select="concat($dir_canonicos, 'c-', @archivo, '.xml')"/>
            <xsl:if test="not(doc-available($ruta))">
              <xsl:message terminate="yes">No se pudo leer el canónico <xsl:value-of select="$ruta"/></xsl:message>
            </xsl:if>
            <xsl:apply-templates select="doc($ruta)/*:article" mode="articulo"/>
          </xsl:for-each>
        </journal>
      </body>
    </doi_batch>
  </xsl:template>

  <!-- ==================================================================
       UN ARTÍCULO. EL ORDEN DE LOS HIJOS ES EL DE journal_article
       ================================================================== -->
  <xsl:template match="*:article" mode="articulo">
    <xsl:variable name="am" select="*:front/*:article-meta"/>
    <xsl:variable name="lang" select="string(@xml:lang)"/>

    <journal_article publication_type="full_text">
      <xsl:if test="gbx:idioma($lang) != ''">
        <xsl:attribute name="language" select="gbx:idioma($lang)"/>
      </xsl:if>

      <!-- TÍTULO: EL DEL ARTÍCULO, EN SU IDIOMA -->
      <titles>
        <title><xsl:value-of select="gbx:texto($am/*:title-group/*:article-title)"/></title>
        <xsl:for-each select="$am/*:title-group/*:subtitle[normalize-space()]">
          <subtitle><xsl:value-of select="gbx:texto(.)"/></subtitle>
        </xsl:for-each>
      </titles>

      <!-- AUTORES: PERSONAS Y COLECTIVOS DEL contrib-group DEL ARTÍCULO.
           EL PRIMERO ES first; LOS DEMÁS, additional -->
      <xsl:variable name="autores" select="$am/*:contrib-group/*:contrib[@contrib-type = 'author']"/>
      <xsl:if test="$autores">
        <contributors>
          <xsl:for-each select="$autores">
            <xsl:variable name="secuencia" select="if (position() = 1) then 'first' else 'additional'"/>
            <xsl:choose>
              <xsl:when test="*:collab">
                <organization sequence="{$secuencia}" contributor_role="author">
                  <xsl:value-of select="gbx:texto(*:collab[1])"/>
                </organization>
              </xsl:when>
              <xsl:otherwise>
                <person_name sequence="{$secuencia}" contributor_role="author">
                  <xsl:if test="normalize-space(*:name/*:given-names) != ''">
                    <given_name><xsl:value-of select="gbx:texto(*:name/*:given-names)"/></given_name>
                  </xsl:if>
                  <surname><xsl:value-of select="gbx:texto(*:name/*:surname)"/></surname>
                  <xsl:for-each select="*:name/*:suffix[normalize-space()]">
                    <suffix><xsl:value-of select="gbx:texto(.)"/></suffix>
                  </xsl:for-each>
                  <!-- TODAS LAS AFILIACIONES: CROSSREF ADMITE VARIAS -->
                  <xsl:variable name="affs" select="for $r in *:xref[@ref-type = 'aff']/@rid return ($am//*:aff[@id = $r])[1]"/>
                  <xsl:if test="exists($affs)">
                    <affiliations>
                      <xsl:apply-templates select="$affs" mode="institucion"/>
                    </affiliations>
                  </xsl:if>
                  <xsl:variable name="orcid" select="gbx:orcid((*:contrib-id[@contrib-id-type = 'orcid'])[1])"/>
                  <xsl:if test="matches($orcid, '^https://orcid\.org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[X0-9]$')">
                    <ORCID><xsl:value-of select="$orcid"/></ORCID>
                  </xsl:if>
                </person_name>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </contributors>
      </xsl:if>

      <!-- RESÚMENES: EL DEL ARTÍCULO Y LOS TRADUCIDOS, EN JATS CON PREFIJO.
           LOS DE OTRO TIPO (abstract-type) NO SON EL RESUMEN -->
      <xsl:for-each select="$am/*:abstract[not(@abstract-type)] | $am/*:trans-abstract[not(@abstract-type)]">
        <jats:abstract xml:lang="{gbx:idioma(if (@xml:lang) then @xml:lang else $lang)}">
          <xsl:apply-templates select="*:sec | *:p" mode="resumen"/>
        </jats:abstract>
      </xsl:for-each>

      <!-- LA FECHA DEL ARTÍCULO; SI NO TIENE, LA DEL NÚMERO -->
      <publication_date media_type="online">
        <xsl:sequence select="gbx:fecha(($am/*:pub-date[@date-type = 'pub'], $am/*:pub-date[@date-type = 'collection'])[1])"/>
      </publication_date>
      <xsl:for-each select="($am/*:pub-history/*:event/*:date[@date-type = 'accepted'])[1]">
        <acceptance_date media_type="online">
          <xsl:sequence select="gbx:fecha(.)"/>
        </acceptance_date>
      </xsl:for-each>

      <!-- PÁGINAS; SIN PÁGINAS, EL e-id COMO NÚMERO DE ARTÍCULO -->
      <xsl:choose>
        <xsl:when test="normalize-space($am/*:fpage) != ''">
          <pages>
            <first_page><xsl:value-of select="normalize-space($am/*:fpage)"/></first_page>
            <xsl:if test="normalize-space($am/*:lpage) != ''">
              <last_page><xsl:value-of select="normalize-space($am/*:lpage)"/></last_page>
            </xsl:if>
          </pages>
        </xsl:when>
        <xsl:when test="normalize-space($am/*:elocation-id) != ''">
          <publisher_item>
            <item_number item_number_type="article_number"><xsl:value-of select="normalize-space($am/*:elocation-id)"/></item_number>
          </publisher_item>
        </xsl:when>
      </xsl:choose>

      <!-- FINANCIAMIENTO: UN fundgroup POR award-group -->
      <xsl:variable name="ayudas" select="$am/*:funding-group/*:award-group[*:funding-source]"/>
      <xsl:if test="$ayudas">
        <fr:program name="fundref">
          <xsl:for-each select="$ayudas">
            <fr:assertion name="fundgroup">
              <xsl:for-each select="*:funding-source">
                <xsl:variable name="ror" select="normalize-space((.//*:institution-id[@institution-id-type = 'ror'])[1])"/>
                <xsl:variable name="doi" select="normalize-space((.//*:institution-id[@institution-id-type = 'doi'])[1])"/>
                <fr:assertion name="funder_name">
                  <xsl:value-of select="gbx:texto((.//*:institution, .)[1])"/>
                  <xsl:if test="$ror != ''">
                    <fr:assertion name="ror"><xsl:value-of select="$ror"/></fr:assertion>
                  </xsl:if>
                  <xsl:if test="$doi != ''">
                    <fr:assertion name="funder_identifier">
                      <xsl:value-of select="if (starts-with($doi, 'http')) then $doi else concat('https://doi.org/', $doi)"/>
                    </fr:assertion>
                  </xsl:if>
                </fr:assertion>
              </xsl:for-each>
              <xsl:for-each select="*:award-id[normalize-space()]">
                <fr:assertion name="award_number"><xsl:value-of select="normalize-space(.)"/></fr:assertion>
              </xsl:for-each>
            </fr:assertion>
          </xsl:for-each>
        </fr:program>
      </xsl:if>

      <!-- LICENCIA Y ACCESO -->
      <xsl:variable name="licencia" select="normalize-space(($am/*:permissions/*:license/ali:license_ref, $am/*:permissions/*:license/@xlink:href)[1])"/>
      <xsl:if test="$licencia != '' or $am/*:permissions/ali:free_to_read">
        <ai:program name="AccessIndicators">
          <xsl:if test="$am/*:permissions/ali:free_to_read">
            <ai:free_to_read/>
          </xsl:if>
          <xsl:if test="$licencia != ''">
            <ai:license_ref applies_to="vor"><xsl:value-of select="$licencia"/></ai:license_ref>
          </xsl:if>
        </ai:program>
      </xsl:if>

      <!-- EL DOI Y LA PÁGINA DEL ARTÍCULO (LA PINZA: LA VERIFICA EL SCRIPT) -->
      <doi_data>
        <doi><xsl:value-of select="normalize-space(($am/*:article-id[@pub-id-type = 'doi'])[1])"/></doi>
        <resource><xsl:value-of select="normalize-space(($am/*:self-uri[@content-type = 'pagina'])[1]/@xlink:href)"/></resource>
      </doi_data>

      <!-- LAS REFERENCIAS, ESTRUCTURADAS -->
      <xsl:variable name="refs" select="*:back/*:ref-list/*:ref"/>
      <xsl:if test="$refs">
        <citation_list>
          <xsl:apply-templates select="$refs" mode="cita"/>
        </citation_list>
      </xsl:if>
    </journal_article>
  </xsl:template>

  <!-- ==================================================================
       UNA AFILIACIÓN: EL NOMBRE (LA INSTITUCIÓN PRINCIPAL), EL ROR, EL
       LUGAR Y LAS DEPENDENCIAS. EL ORDEN ES EL DE institution
       ================================================================== -->
  <xsl:template match="*:aff" mode="institucion">
    <xsl:variable name="principal" select="(.//*:institution[@content-type = 'orgname'], .//*:institution[not(@content-type)])[1]"/>
    <xsl:variable name="ror" select="normalize-space((.//*:institution-id[@institution-id-type = 'ror'])[1])"/>
    <xsl:variable name="lugar" select="string-join((gbx:texto(*:city), gbx:texto(*:country))[. != ''], ', ')"/>
    <institution>
      <xsl:if test="$principal">
        <institution_name><xsl:value-of select="gbx:texto($principal)"/></institution_name>
      </xsl:if>
      <!-- EL PATRÓN DE CROSSREF: https://ror.org/0 + SEIS + DOS CIFRAS -->
      <xsl:if test="matches($ror, '^https://ror\.org/0[^ilo]{6}[0-9]{2}$')">
        <institution_id type="ror"><xsl:value-of select="$ror"/></institution_id>
      </xsl:if>
      <xsl:if test="$lugar != ''">
        <institution_place><xsl:value-of select="$lugar"/></institution_place>
      </xsl:if>
      <xsl:for-each select="(.//*:institution[starts-with(@content-type, 'orgdiv')])[position() le 6]">
        <institution_department><xsl:value-of select="gbx:texto(.)"/></institution_department>
      </xsl:for-each>
    </institution>
  </xsl:template>

  <!-- ==================================================================
       UN RESUMEN EN JATS (EL DE CROSSREF ES JATS 1.3 Journal Publishing):
       SECCIONES CON TÍTULO Y PÁRRAFOS, EN TEXTO PLANO
       ================================================================== -->
  <xsl:template match="*:sec" mode="resumen">
    <jats:sec>
      <xsl:for-each select="*:title">
        <jats:title><xsl:value-of select="gbx:texto(.)"/></jats:title>
      </xsl:for-each>
      <xsl:apply-templates select="*:sec | *:p" mode="resumen"/>
    </jats:sec>
  </xsl:template>

  <xsl:template match="*:p" mode="resumen">
    <jats:p><xsl:value-of select="gbx:texto(.)"/></jats:p>
  </xsl:template>

  <!-- ==================================================================
       UNA REFERENCIA. citation_t ES UN xsd:all: EL ORDEN NO IMPORTA, PERO
       CADA ELEMENTO VA UNA VEZ COMO MÁXIMO
       ================================================================== -->
  <xsl:template match="*:ref" mode="cita">
    <xsl:variable name="c" select="(*:element-citation, *:mixed-citation)[1]"/>
    <xsl:variable name="tipo" select="string($c/@publication-type)"/>
    <xsl:variable name="doi" select="normalize-space(($c/*:pub-id[@pub-id-type = 'doi'])[1])"/>
    <xsl:variable name="autor" select="normalize-space((($c/*:person-group[@person-group-type = 'author'], $c)[1]//*:name/*:surname)[1])"/>
    <citation key="{@id}">
      <xsl:choose>
        <!-- CON DOI, EL DOI ES LO QUE CROSSREF USA («If you know the DOIs
             of individual citations, include them»). LO DEMÁS AYUDA SI EL
             DOI NO COINCIDE -->
        <xsl:when test="$c/self::*:element-citation">
          <xsl:if test="$doi != ''">
            <doi><xsl:value-of select="replace($doi, '^https?://(dx\.)?doi\.org/', '')"/></doi>
          </xsl:if>
          <xsl:if test="$autor != ''">
            <author><xsl:value-of select="$autor"/></author>
          </xsl:if>
          <xsl:choose>
            <xsl:when test="$tipo = 'journal'">
              <xsl:for-each select="$c/*:source[normalize-space()][1]">
                <journal_title><xsl:value-of select="gbx:texto(.)"/></journal_title>
              </xsl:for-each>
              <xsl:for-each select="$c/*:article-title[normalize-space()][1]">
                <article_title><xsl:value-of select="gbx:texto(.)"/></article_title>
              </xsl:for-each>
              <xsl:for-each select="$c/*:volume[normalize-space()][1]">
                <volume><xsl:value-of select="normalize-space(.)"/></volume>
              </xsl:for-each>
              <xsl:for-each select="$c/*:issue[normalize-space()][1]">
                <issue><xsl:value-of select="normalize-space(.)"/></issue>
              </xsl:for-each>
              <xsl:for-each select="$c/*:fpage[normalize-space()][1]">
                <first_page><xsl:value-of select="normalize-space(.)"/></first_page>
              </xsl:for-each>
              <xsl:for-each select="$c/*:elocation-id[normalize-space()][1]">
                <elocation_id><xsl:value-of select="normalize-space(.)"/></elocation_id>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <!-- LIBRO, CAPÍTULO Y LO DEMÁS: EL TÍTULO DEL VOLUMEN ES source;
                   EL DEL CAPÍTULO O LA PARTE, article_title -->
              <xsl:for-each select="$c/*:source[normalize-space()][1]">
                <volume_title><xsl:value-of select="gbx:texto(.)"/></volume_title>
              </xsl:for-each>
              <xsl:for-each select="($c/*:chapter-title, $c/*:article-title)[normalize-space()][1]">
                <article_title><xsl:value-of select="gbx:texto(.)"/></article_title>
              </xsl:for-each>
              <xsl:for-each select="$c/*:edition[normalize-space()][1]">
                <edition_number><xsl:value-of select="normalize-space(.)"/></edition_number>
              </xsl:for-each>
              <xsl:for-each select="$c/*:isbn[normalize-space()][1]">
                <isbn><xsl:value-of select="normalize-space(.)"/></isbn>
              </xsl:for-each>
              <xsl:for-each select="$c/*:fpage[normalize-space()][1]">
                <first_page><xsl:value-of select="normalize-space(.)"/></first_page>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:for-each select="$c/*:year[normalize-space()][1]">
            <cYear><xsl:value-of select="normalize-space(.)"/></cYear>
          </xsl:for-each>
        </xsl:when>
        <!-- UNA REFERENCIA SIN ESTRUCTURA (mixed-citation): SU TEXTO -->
        <xsl:otherwise>
          <xsl:if test="$doi != ''">
            <doi><xsl:value-of select="replace($doi, '^https?://(dx\.)?doi\.org/', '')"/></doi>
          </xsl:if>
          <unstructured_citation><xsl:value-of select="gbx:texto($c)"/></unstructured_citation>
        </xsl:otherwise>
      </xsl:choose>
    </citation>
  </xsl:template>

</xsl:stylesheet>
