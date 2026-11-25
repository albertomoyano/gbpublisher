<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  libro-a-crossref.xsl — gbpublisher
  ============================================================================
  EL DEPÓSITO CROSSREF DEL LIBRO: UN doi_batch CON UN book, SUS METADATOS Y
  UN content_item POR PIEZA CON DOI, EN EL ESQUEMA 5.4.0 (EL MISMO DE LAS
  REVISTAS: schemas/crossref/crossref5.4.0.xsd DEL PAQUETE).

  DECISIONES DE ALBERTO (25/11/2026, claude/crossref-libros.md):
    - EL CONTENIDO SALE DEL CANÓNICO ENSAMBLADO DEL LIBRO; DE GAMBAS, SOLO EL
      ENCABEZADO (DEPOSITANTE, CORREO, PREFIJO) EN EL VOLCADO;
    - book_type: monografia, manual, traduccion → monograph; obra_colectiva,
      compilacion, actas → edited_book; referencia → reference;
    - ROLES: author → author; editor (CON CUALQUIER role: compilador,
      coordinador) → editor; othercredit class="translator" → translator. LOS
      DEMÁS (PROLOGUISTA, ILUSTRADOR, DIRECTOR DE COLECCIÓN) NO VAN: CROSSREF
      NO TIENE UN ROL PARA ELLOS;
    - SERIE: LA MÁS ESPECÍFICA CON ISSN (subseries > series); SIN ISSN, EL
      LIBRO VA COMO book_metadata COMÚN. book_series_metadata ADMITE UNA SOLA
      EDITORIAL: EN UNA COEDICIÓN VA LA PRINCIPAL;
    - ISBN: UNO POR SOPORTE; SIN ISBN, noisbn reason="monograph" (CROSSREF LO
      EXIGE, markup guide «books and chapters»);
    - F4: EL resource DE UNA PIEZA ES url-libro + h-{nombre_archivo}.html (LA
      PÁGINA QUE YA GENERA EL HTML); EL DEL LIBRO, url-libro;
    - F5: SOLO LAS PIEZAS CON DOI VAN COMO content_item;
    - F6: LAS REFERENCIAS POR PIEZA: LAS DE SU BIBLIOGRAFÍA, O CON BIBLIOGRAFÍA
      CONSOLIDADA LAS QUE LA PIEZA CITA (biblioref). SIN PIEZAS CON DOI, LAS
      REFERENCIAS VAN EN EL LIBRO.

  LOS FRENOS (DOI DEL LIBRO, PREFIJO, ISBN REPETIDO, url-libro) LOS PONE
  generar_crossref_libro.sh ANTES DE TRANSFORMAR, CON LA PLANTILLA
  «verificar» DE ESTA MISMA HOJA: LAS DOS LEEN EL CANÓNICO IGUAL.

  ENTRADA: EL VOLCADO (tmp/crossref-libro-datos.xml, VERSIÓN 1). EL CANÓNICO
  Y EL MANIFIESTO LLEGAN COMO PARÁMETROS (URI).
  ============================================================================
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:db="http://docbook.org/ns/docbook"
    xmlns:gbx="urn:gbpublisher:crossref"
    xmlns="http://www.crossref.org/schema/5.4.0"
    xmlns:jats="http://www.ncbi.nlm.nih.gov/JATS1"
    xmlns:ai="http://www.crossref.org/AccessIndicators.xsd"
    exclude-result-prefixes="xs xlink db gbx">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:output name="texto" method="text" encoding="UTF-8"/>

  <!-- EL CANÓNICO ENSAMBLADO Y EL MANIFIESTO, COMO URI file:// -->
  <xsl:param name="canonico" as="xs:string" required="yes"/>
  <xsl:param name="manifiesto" as="xs:string" required="yes"/>
  <!-- AAAAMMDDhhmmss DE LA CORRIDA: CRECE EN CADA DEPÓSITO -->
  <xsl:param name="timestamp" as="xs:string" select="''"/>
  <!-- EL NOMBRE DEL LIBRO SIN «l-»: ARMA EL doi_batch_id -->
  <xsl:param name="libro" as="xs:string" select="''"/>

  <xsl:variable name="volcado" select="/crossref-libro-datos"/>
  <xsl:variable name="book" select="doc($canonico)/db:book"/>
  <xsl:variable name="info" select="$book/db:info"/>
  <xsl:variable name="manif" select="doc($manifiesto)/manifiesto-libro"/>

  <!-- LAS PIEZAS: LOS ELEMENTOS CON xml:id cap-<id> (LAS ENTRADAS DE
       BIBLIOGRAFÍA TIENEN cap-<id>-bib-…: POR ESO EL PATRÓN ENTERO) -->
  <xsl:variable name="piezas" select="$book//*[matches(@xml:id, '^cap-[0-9]+$')]"/>
  <xsl:variable name="con-doi" select="$piezas[normalize-space(db:info/db:biblioid[@class = 'doi'][1]) != '']"/>
  <xsl:variable name="url-libro" select="normalize-space($info/db:bibliomisc[@role = 'url-libro'][1])"/>

  <!-- ==================================================================
       FUNCIONES
       ================================================================== -->

  <!-- TEXTO PLANO DE CONTENIDO MIXTO -->
  <xsl:function name="gbx:texto" as="xs:string">
    <xsl:param name="nodos" as="node()*"/>
    <xsl:sequence select="normalize-space(string-join($nodos//text(), ''))"/>
  </xsl:function>

  <!-- EL IDIOMA PARA @language: LA SUBETIQUETA PRINCIPAL DE BCP 47 -->
  <xsl:function name="gbx:idioma" as="xs:string">
    <xsl:param name="bcp47" as="xs:string?"/>
    <xsl:sequence select="lower-case(tokenize(normalize-space($bcp47), '-')[1])"/>
  </xsl:function>

  <!-- UN ORCID COMO URL https://orcid.org/…, EL PATRÓN DE orcid_t -->
  <xsl:function name="gbx:orcid" as="xs:string">
    <xsl:param name="valor" as="xs:string?"/>
    <xsl:variable name="v" select="normalize-space($valor)"/>
    <xsl:sequence select="if ($v = '') then ''
                          else concat('https://orcid.org/', replace($v, '^.*orcid\.org/', ''))"/>
  </xsl:function>

  <!-- EL nombre_archivo DE UNA PIEZA, POR SU id EN EL MANIFIESTO -->
  <xsl:function name="gbx:archivo" as="xs:string">
    <xsl:param name="pieza" as="element()"/>
    <xsl:sequence select="string(($manif//capitulo[@id_capitulo = substring-after($pieza/@xml:id, 'cap-')]/@nombre_archivo)[1])"/>
  </xsl:function>

  <!-- tipo_libro → book_type (DECISIÓN DE ALBERTO, 25/11) -->
  <xsl:function name="gbx:tipo-libro" as="xs:string">
    <xsl:param name="tipo" as="xs:string"/>
    <xsl:sequence select="
        if ($tipo = ('obra_colectiva', 'compilacion', 'actas')) then 'edited_book'
        else if ($tipo = 'referencia') then 'reference'
        else 'monograph'"/>
  </xsl:function>

  <!-- UN DOI SIN EL RESOLVEDOR DELANTE -->
  <xsl:function name="gbx:doi" as="xs:string">
    <xsl:param name="valor" as="xs:string?"/>
    <xsl:sequence select="replace(normalize-space($valor), '^https?://(dx\.)?doi\.org/', '')"/>
  </xsl:function>

  <!-- ==================================================================
       VERIFICAR (generar_crossref_libro.sh, -it:verificar): LO QUE EL
       SCRIPT NECESITA PARA FRENAR, EN TEXTO SEPARADO POR TABULADORES
         libro  doi  isbn-impreso  isbn-electronico  url-libro  tipo-libro
         pieza  id  nombre_archivo  tipo_capitulo  doi  paginas
       ================================================================== -->
  <xsl:template name="verificar">
    <xsl:result-document format="texto">
      <xsl:value-of select="string-join(('libro',
          normalize-space($info/db:biblioid[@class = 'doi'][1]),
          normalize-space($info/db:biblioid[@class = 'isbn'][@role = 'print'][1]),
          normalize-space($info/db:biblioid[@class = 'isbn'][@role = 'electronic'][1]),
          $url-libro,
          normalize-space($info/db:bibliomisc[@role = 'tipo-libro'][1])), '&#9;')"/>
      <xsl:text>&#10;</xsl:text>
      <xsl:for-each select="$piezas">
        <xsl:variable name="id" select="substring-after(@xml:id, 'cap-')"/>
        <xsl:value-of select="string-join(('pieza', $id, gbx:archivo(.),
            string(($manif//capitulo[@id_capitulo = $id]/@tipo_capitulo)[1]),
            normalize-space(db:info/db:biblioid[@class = 'doi'][1]),
            normalize-space(db:info/db:bibliomisc[@role = 'paginas'][1])), '&#9;')"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
    </xsl:result-document>
  </xsl:template>

  <!-- ==================================================================
       RAÍZ: EL DEPÓSITO
       ================================================================== -->
  <xsl:template match="/">
    <doi_batch version="5.4.0"
        xsi:schemaLocation="http://www.crossref.org/schema/5.4.0 https://www.crossref.org/schemas/crossref5.4.0.xsd"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <head>
        <!-- EL LIBRO Y LA CORRIDA: ÚNICO POR DEPÓSITO -->
        <doi_batch_id><xsl:value-of select="concat('l-', $libro, '-', $timestamp)"/></doi_batch_id>
        <timestamp><xsl:value-of select="$timestamp"/></timestamp>
        <depositor>
          <depositor_name><xsl:value-of select="normalize-space($volcado/depositante)"/></depositor_name>
          <!-- CROSSREF MANDA AHÍ EL INFORME DEL DEPÓSITO -->
          <email_address><xsl:value-of select="normalize-space($volcado/correo)"/></email_address>
        </depositor>
        <registrant><xsl:value-of select="normalize-space($volcado/depositante)"/></registrant>
      </head>
      <body>
        <book book_type="{gbx:tipo-libro(normalize-space($info/db:bibliomisc[@role = 'tipo-libro'][1]))}">
          <xsl:variable name="serie" select="(
              $info/db:biblioset[@relation = 'subseries'][normalize-space(db:issn) != ''],
              $info/db:biblioset[@relation = 'series'][normalize-space(db:issn) != ''])[1]"/>
          <xsl:choose>
            <xsl:when test="$serie">
              <book_series_metadata>
                <xsl:call-template name="idioma-libro"/>
                <series_metadata>
                  <titles><title><xsl:value-of select="gbx:texto($serie/db:title)"/></title></titles>
                  <issn><xsl:value-of select="normalize-space($serie/db:issn)"/></issn>
                </series_metadata>
                <xsl:call-template name="metadatos-libro">
                  <xsl:with-param name="volumen" select="normalize-space($serie/db:volumenum)"/>
                  <xsl:with-param name="editoriales" select="$info/db:publisher[1]"/>
                </xsl:call-template>
              </book_series_metadata>
            </xsl:when>
            <xsl:otherwise>
              <book_metadata>
                <xsl:call-template name="idioma-libro"/>
                <xsl:call-template name="metadatos-libro">
                  <xsl:with-param name="volumen" select="''"/>
                  <xsl:with-param name="editoriales" select="$info/db:publisher"/>
                </xsl:call-template>
              </book_metadata>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:apply-templates select="$con-doi" mode="pieza"/>
        </book>
      </body>
    </doi_batch>
  </xsl:template>

  <xsl:template name="idioma-libro">
    <xsl:if test="gbx:idioma($book/@xml:lang) != ''">
      <xsl:attribute name="language" select="gbx:idioma($book/@xml:lang)"/>
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================
       LOS METADATOS DEL LIBRO, EN EL ORDEN DE book_metadata. EN
       book_series_metadata EL ORDEN ES EL MISMO, CON volume DESPUÉS DEL
       RESUMEN
       ================================================================== -->
  <xsl:template name="metadatos-libro">
    <xsl:param name="volumen" as="xs:string"/>
    <xsl:param name="editoriales" as="element()*"/>

    <xsl:call-template name="contribuyentes">
      <xsl:with-param name="personas" select="$info/(db:author | db:editor | db:othercredit[@class = 'translator'])"/>
    </xsl:call-template>

    <titles>
      <title><xsl:value-of select="gbx:texto($info/db:title)"/></title>
      <xsl:for-each select="$info/db:subtitle[normalize-space()]">
        <subtitle><xsl:value-of select="gbx:texto(.)"/></subtitle>
      </xsl:for-each>
    </titles>

    <xsl:apply-templates select="$info/db:abstract" mode="resumen"/>

    <xsl:if test="$volumen != ''">
      <volume><xsl:value-of select="$volumen"/></volume>
    </xsl:if>

    <xsl:for-each select="$info/db:edition[@role = 'numeric'][normalize-space()][1]">
      <edition_number><xsl:value-of select="normalize-space(.)"/></edition_number>
    </xsl:for-each>

    <!-- LA FECHA: LA COMPLETA SI LA HAY; SI NO, EL AÑO. IMPRESA SI EL LIBRO
         TIENE ISBN IMPRESO -->
    <xsl:variable name="isbn-impreso" select="normalize-space($info/db:biblioid[@class = 'isbn'][@role = 'print'][1])"/>
    <xsl:variable name="completa" select="tokenize(normalize-space($info/db:pubdate[@role = 'completa'][1]), '-')"/>
    <publication_date media_type="{if ($isbn-impreso != '') then 'print' else 'online'}">
      <xsl:choose>
        <xsl:when test="count($completa) = 3">
          <month><xsl:value-of select="$completa[2]"/></month>
          <day><xsl:value-of select="$completa[3]"/></day>
          <year><xsl:value-of select="$completa[1]"/></year>
        </xsl:when>
        <xsl:otherwise>
          <year><xsl:value-of select="normalize-space($info/db:pubdate[not(@role)][1])"/></year>
        </xsl:otherwise>
      </xsl:choose>
    </publication_date>

    <!-- ISBN: UNO POR SOPORTE; SIN NINGUNO, noisbn -->
    <xsl:variable name="isbns" select="$info/db:biblioid[@class = 'isbn'][normalize-space()]"/>
    <xsl:choose>
      <xsl:when test="$isbns">
        <xsl:for-each select="$isbns">
          <isbn media_type="{if (@role = 'electronic') then 'electronic' else 'print'}">
            <xsl:value-of select="normalize-space(.)"/>
          </isbn>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <noisbn reason="monograph"/>
      </xsl:otherwise>
    </xsl:choose>

    <xsl:for-each select="$editoriales">
      <publisher>
        <publisher_name><xsl:value-of select="gbx:texto(db:publishername)"/></publisher_name>
        <xsl:variable name="lugar" select="string-join((gbx:texto(db:address/db:city), gbx:texto(db:address/db:country))[. != ''], ', ')"/>
        <xsl:if test="$lugar != ''">
          <publisher_place><xsl:value-of select="$lugar"/></publisher_place>
        </xsl:if>
      </publisher>
    </xsl:for-each>

    <!-- LA LICENCIA DEL LIBRO -->
    <xsl:variable name="licencia" select="normalize-space(($info/db:legalnotice[@role = 'licencia']//db:link/@xlink:href)[1])"/>
    <xsl:if test="$licencia != ''">
      <ai:program name="AccessIndicators">
        <ai:license_ref applies_to="vor"><xsl:value-of select="$licencia"/></ai:license_ref>
      </ai:program>
    </xsl:if>

    <doi_data>
      <doi><xsl:value-of select="gbx:doi($info/db:biblioid[@class = 'doi'][1])"/></doi>
      <resource><xsl:value-of select="$url-libro"/></resource>
    </doi_data>

    <!-- SIN PIEZAS CON DOI, LAS REFERENCIAS SON DEL LIBRO (F6) -->
    <xsl:if test="empty($con-doi)">
      <xsl:call-template name="citas">
        <xsl:with-param name="entradas" select="$book//db:biblioentry"/>
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================
       LAS PERSONAS. EL PRIMERO ES first; LOS DEMÁS, additional
       ================================================================== -->
  <xsl:template name="contribuyentes">
    <xsl:param name="personas" as="element()*"/>
    <xsl:if test="$personas">
      <contributors>
        <xsl:for-each select="$personas">
          <xsl:variable name="secuencia" select="if (position() = 1) then 'first' else 'additional'"/>
          <xsl:variable name="rol" select="
              if (self::db:editor) then 'editor'
              else if (self::db:othercredit) then 'translator'
              else 'author'"/>
          <xsl:choose>
            <xsl:when test="db:orgname">
              <organization sequence="{$secuencia}" contributor_role="{$rol}">
                <xsl:value-of select="gbx:texto(db:orgname)"/>
              </organization>
            </xsl:when>
            <xsl:otherwise>
              <person_name sequence="{$secuencia}" contributor_role="{$rol}">
                <xsl:if test="normalize-space(db:personname/db:firstname) != ''">
                  <given_name><xsl:value-of select="gbx:texto(db:personname/db:firstname)"/></given_name>
                </xsl:if>
                <surname><xsl:value-of select="gbx:texto(db:personname/db:surname)"/></surname>
                <xsl:variable name="orcid" select="gbx:orcid((db:uri[@type = 'orcid'])[1])"/>
                <xsl:if test="matches($orcid, '^https://orcid\.org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[X0-9]$')">
                  <ORCID><xsl:value-of select="$orcid"/></ORCID>
                </xsl:if>
              </person_name>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </contributors>
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================
       UNA PIEZA CON DOI, EN EL ORDEN DE content_item
       ================================================================== -->
  <xsl:template match="*" mode="pieza">
    <xsl:variable name="pi" select="db:info"/>
    <xsl:variable name="paginas" select="tokenize(normalize-space($pi/db:bibliomisc[@role = 'paginas'][1]), '-')"/>
    <content_item component_type="chapter" publication_type="full_text">
      <xsl:if test="gbx:idioma(@xml:lang) != ''">
        <xsl:attribute name="language" select="gbx:idioma(@xml:lang)"/>
      </xsl:if>
      <xsl:call-template name="contribuyentes">
        <xsl:with-param name="personas" select="$pi/(db:author | db:othercredit[@class = 'translator'])"/>
      </xsl:call-template>
      <titles>
        <title><xsl:value-of select="gbx:texto(($pi/db:title, db:title)[1])"/></title>
        <xsl:for-each select="($pi/db:subtitle, db:subtitle)[normalize-space()][1]">
          <subtitle><xsl:value-of select="gbx:texto(.)"/></subtitle>
        </xsl:for-each>
      </titles>
      <xsl:apply-templates select="$pi/db:abstract" mode="resumen"/>
      <xsl:if test="$paginas[1] != ''">
        <pages>
          <first_page><xsl:value-of select="$paginas[1]"/></first_page>
          <xsl:if test="$paginas[2] != ''">
            <last_page><xsl:value-of select="$paginas[2]"/></last_page>
          </xsl:if>
        </pages>
      </xsl:if>
      <doi_data>
        <doi><xsl:value-of select="gbx:doi($pi/db:biblioid[@class = 'doi'][1])"/></doi>
        <resource><xsl:value-of select="concat($url-libro, 'h-', gbx:archivo(.), '.html')"/></resource>
      </doi_data>
      <!-- F6: SU BIBLIOGRAFÍA; SI NO TIENE, LO QUE CITA -->
      <xsl:variable name="propias" select=".//db:bibliography//db:biblioentry"/>
      <xsl:call-template name="citas">
        <xsl:with-param name="entradas" select="
            if ($propias) then $propias
            else $book//db:biblioentry[@xml:id = current()//db:biblioref/@linkend]"/>
      </xsl:call-template>
    </content_item>
  </xsl:template>

  <!-- ==================================================================
       UN RESUMEN: JATS CON PREFIJO, PÁRRAFOS EN TEXTO PLANO
       ================================================================== -->
  <xsl:template match="db:abstract" mode="resumen">
    <jats:abstract>
      <xsl:if test="gbx:idioma(@xml:lang) != ''">
        <xsl:attribute name="xml:lang" select="gbx:idioma(@xml:lang)"/>
      </xsl:if>
      <!-- UN para PUEDE TRAER VARIOS PÁRRAFOS SEPARADOS POR LÍNEA EN BLANCO -->
      <xsl:for-each select="db:para">
        <xsl:for-each select="tokenize(string(.), '\n\s*\n')[normalize-space()]">
          <jats:p><xsl:value-of select="normalize-space(.)"/></jats:p>
        </xsl:for-each>
      </xsl:for-each>
    </jats:abstract>
  </xsl:template>

  <!-- ==================================================================
       LAS REFERENCIAS. citation_t ES UN xsd:all: EL ORDEN NO IMPORTA, PERO
       CADA ELEMENTO VA UNA VEZ COMO MÁXIMO
       ================================================================== -->
  <xsl:template name="citas">
    <xsl:param name="entradas" as="element()*"/>
    <xsl:if test="$entradas">
      <citation_list>
        <xsl:for-each select="$entradas">
          <xsl:call-template name="cita"/>
        </xsl:for-each>
      </citation_list>
    </xsl:if>
  </xsl:template>

  <xsl:template name="cita">
    <xsl:variable name="tipo" select="string(@pubwork)"/>
    <xsl:variable name="doi" select="gbx:doi(db:biblioid[@class = 'doi'][1])"/>
    <xsl:variable name="autor" select="gbx:texto((db:author/db:personname/db:surname, db:author/db:orgname, db:editor/db:personname/db:surname)[1])"/>
    <xsl:variable name="anio" select="replace(normalize-space(db:pubdate[1]), '^.*?([0-9]{4}).*$', '$1')"/>
    <xsl:variable name="paginas" select="normalize-space(db:artpagenums[1])"/>
    <citation key="{@xml:id}">
      <xsl:if test="$doi != ''">
        <doi><xsl:value-of select="$doi"/></doi>
      </xsl:if>
      <xsl:if test="$autor != ''">
        <author><xsl:value-of select="$autor"/></author>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$tipo = 'article'">
          <xsl:for-each select="db:citetitle[normalize-space()][1]">
            <journal_title><xsl:value-of select="gbx:texto(.)"/></journal_title>
          </xsl:for-each>
          <xsl:for-each select="db:title[normalize-space()][1]">
            <article_title><xsl:value-of select="gbx:texto(.)"/></article_title>
          </xsl:for-each>
          <xsl:for-each select="db:volumenum[normalize-space()][1]">
            <volume><xsl:value-of select="normalize-space(.)"/></volume>
          </xsl:for-each>
          <xsl:for-each select="db:issuenum[normalize-space()][1]">
            <issue><xsl:value-of select="normalize-space(.)"/></issue>
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <!-- LIBRO, CAPÍTULO Y LO DEMÁS: EL TÍTULO DEL VOLUMEN ES citetitle
               (O EL TÍTULO, EN UN LIBRO SIN citetitle); EL DEL CAPÍTULO,
               article_title -->
          <xsl:for-each select="(db:citetitle, db:title[not(../db:citetitle)])[normalize-space()][1]">
            <volume_title><xsl:value-of select="gbx:texto(.)"/></volume_title>
          </xsl:for-each>
          <xsl:if test="db:citetitle">
            <xsl:for-each select="db:title[normalize-space()][1]">
              <article_title><xsl:value-of select="gbx:texto(.)"/></article_title>
            </xsl:for-each>
          </xsl:if>
          <xsl:for-each select="db:edition[normalize-space()][string-length(normalize-space()) le 15][1]">
            <edition_number><xsl:value-of select="normalize-space(.)"/></edition_number>
          </xsl:for-each>
          <xsl:for-each select="db:biblioid[@class = 'isbn'][normalize-space()][1]">
            <isbn><xsl:value-of select="normalize-space(.)"/></isbn>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="$paginas != ''">
        <first_page><xsl:value-of select="tokenize($paginas, '[-–]')[1]"/></first_page>
      </xsl:if>
      <xsl:if test="matches($anio, '^[0-9]{4}$')">
        <cYear><xsl:value-of select="$anio"/></cYear>
      </xsl:if>
    </citation>
  </xsl:template>

</xsl:stylesheet>
