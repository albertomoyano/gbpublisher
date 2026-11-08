<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-a-latex-articulo.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : EL CUERPO LaTeX DE UN ARTÍCULO PARA EL CAMINO NUEVO
                   (engine/, CONTRATO DE REVISTA 2). IMPORTA
                   jats-to-latex.xsl Y REEMPLAZA SOLO LA PRIMERA PÁGINA,
                   EL BLOQUE DE DECLARACIONES Y LOS DATOS DEL PDF: EL
                   CUERPO (SECCIONES, CITAS, FIGURAS, CUADROS, NOTAS) ES
                   EL DE LA HOJA IMPORTADA.
  POR QUÉ APARTE : m_XML (EL CAMINO VIEJO, HASTA EL 2.0.0) SIGUE USANDO
                   jats-to-latex.xsl CON SU PREÁMBULO EMBEBIDO. LAS
                   MACROS DE ESTA HOJA SON DEL CONTRATO DE REVISTA 2 Y
                   ESE PREÁMBULO NO LAS TIENE: CAMBIAR LA HOJA VIEJA
                   ROMPÍA EL CAMINO VIEJO. EN EL 2.0.0 LAS DOS SE FUNDEN.
  ENTRADA        : {proyecto}/jats/c-{nombre}.xml (CANÓNICO, A0.4)
  SALIDA         : {proyecto}/latex/c-{nombre}.tex
                   Y, SI bib_cita NO ESTÁ VACÍO, EL .bib DEL «CÓMO
                   CITAR» AL LADO (xsl:result-document)
  PARÁMETROS     : LOS DE jats-to-latex.xsl, MÁS
                   pagina_inicial  EL FOLIO DE LA PRIMERA PÁGINA; GANA
                                   SOBRE fpage. VACÍO: fpage, Y SI NO
                                   HAY, 1 (e-id: FOLIOS DESDE 1)
                   bib_cita        NOMBRE DEL .bib DEL «CÓMO CITAR»
                                   (p. ej. cita-a-01-ciudad.bib). biber
                                   LO BUSCA POR BIBINPUTS, QUE DEBE
                                   INCLUIR {proyecto}/latex/. VACÍO: LA
                                   COLUMNA SALE SIN «CÓMO CITAR»
  ============================================================
  ORDEN DEL FRAGMENTO:
    1. IDIOMA, MACROS \articulo*, FOLIO INICIAL, ESTILO firstpage
    2. DATOS DEL PDF (\hypersetup: TÍTULO, AUTORES, DERECHOS,
       LICENCIA, PALABRAS CLAVE; REDALYC 3.3)
    3. TÍTULO, SUBTÍTULO Y TÍTULOS TRADUCIDOS A ANCHO COMPLETO
    4. LA COLUMNA DERECHA (gbcolumna), QUE SE COLOCA A LA ALTURA
       DEL PRIMER RESUMEN Y SE MIDE (\gbcolocarcolumna)
    5. LOS RESÚMENES (gbresumen), UNO POR IDIOMA, CON SUS
       PALABRAS CLAVE
    6. CUERPO, AGRADECIMIENTOS
    7. DECLARACIONES: CRediT, FINANCIAMIENTO, CONFLICTO DE
       INTERESES, DISPONIBILIDAD DE DATOS (SCIELO §5.2.6.4.1, §2.3)
    8. APÉNDICES. \printbibliography LO ESCRIBE main-{nombre}.tex
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
  xmlns:f="urn:gbpublisher:functions"
  xmlns:gbr="urn:gbpublisher:revista-latex"
  exclude-result-prefixes="xs xlink ali f gbr">

  <!-- EL CUERPO ES EL DE LA HOJA VIEJA. xsl:import VA PRIMERO; LO QUE
       ESTA HOJA DEFINE GANA POR PRECEDENCIA DE IMPORTACIÓN -->
  <xsl:import href="jats-to-latex.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="pagina_inicial" as="xs:string" select="''"/>
  <xsl:param name="bib_cita" as="xs:string" select="''"/>

  <!-- LA CLAVE DEL ARTÍCULO EN EL .bib DEL «CÓMO CITAR» -->
  <xsl:variable name="gbr:clave-cita" select="'gb-articulo'"/>

  <!-- ============================================================ -->
  <!-- RÓTULOS POR IDIOMA. EL IDIOMA ES EL DEL ARTÍCULO; FUERA DE    -->
  <!-- es, en, pt Y fr, EN CASTELLANO                                -->
  <!-- ============================================================ -->
  <xsl:variable name="gbr:rotulos" as="element()*">
    <r k="resumen" es="Resumen" en="Abstract" pt="Resumo" fr="Résumé"/>
    <r k="palabras" es="Palabras clave" en="Keywords" pt="Palavras-chave" fr="Mots-clés"/>
    <r k="correspondencia" es="Correspondencia" en="Correspondence" pt="Correspondência" fr="Correspondance"/>
    <r k="editor" es="Editor responsable" en="Handling editor" pt="Editor responsável" fr="Éditeur responsable"/>
    <r k="traductor" es="Traducción" en="Translation" pt="Tradução" fr="Traduction"/>
    <r k="received" es="Recibido" en="Received" pt="Recebido" fr="Reçu"/>
    <r k="rev-recd" es="Revisado" en="Revised" pt="Revisado" fr="Révisé"/>
    <r k="accepted" es="Aceptado" en="Accepted" pt="Aceito" fr="Accepté"/>
    <r k="pub" es="Publicado" en="Published" pt="Publicado" fr="Publié"/>
    <r k="eid" es="Número de artículo" en="Article number" pt="Número do artigo" fr="Numéro d’article"/>
    <r k="comocitar" es="Cómo citar" en="How to cite" pt="Como citar" fr="Comment citer"/>
    <r k="compartir" es="Compartir" en="Share" pt="Compartilhar" fr="Partager"/>
    <r k="licencia" es="Licencia" en="License" pt="Licença" fr="Licence"/>
    <r k="declaraciones" es="Declaraciones" en="Declarations" pt="Declarações" fr="Déclarations"/>
    <r k="contribuciones" es="Contribuciones de autoría (CRediT)" en="Author contributions (CRediT)" pt="Contribuições de autoria (CRediT)" fr="Contributions des auteurs (CRediT)"/>
    <r k="financiamiento" es="Financiamiento" en="Funding" pt="Financiamento" fr="Financement"/>
    <r k="coi" es="Conflicto de intereses" en="Conflict of interest" pt="Conflito de interesses" fr="Conflit d’intérêts"/>
    <r k="datos" es="Disponibilidad de datos" en="Data availability" pt="Disponibilidade de dados" fr="Disponibilité des données"/>
  </xsl:variable>

  <xsl:variable name="gbr:meses" as="element()*">
    <m es="enero" en="January" pt="janeiro" fr="janvier"/>
    <m es="febrero" en="February" pt="fevereiro" fr="février"/>
    <m es="marzo" en="March" pt="março" fr="mars"/>
    <m es="abril" en="April" pt="abril" fr="avril"/>
    <m es="mayo" en="May" pt="maio" fr="mai"/>
    <m es="junio" en="June" pt="junho" fr="juin"/>
    <m es="julio" en="July" pt="julho" fr="juillet"/>
    <m es="agosto" en="August" pt="agosto" fr="août"/>
    <m es="septiembre" en="September" pt="setembro" fr="septembre"/>
    <m es="octubre" en="October" pt="outubro" fr="octobre"/>
    <m es="noviembre" en="November" pt="novembro" fr="novembre"/>
    <m es="diciembre" en="December" pt="dezembro" fr="décembre"/>
  </xsl:variable>

  <!-- EL IDIOMA DE LOS RÓTULOS: LAS DOS LETRAS DEL ARTÍCULO, SI HAY TABLA -->
  <xsl:variable name="gbr:lang" as="xs:string"
    select="let $l := lower-case(substring($xmlLang, 1, 2))
            return if ($l = ('es', 'en', 'pt', 'fr')) then $l else 'es'"/>

  <!-- ============================================
       Función   : gbr:rotulo
       Propósito : El rótulo de una clave en el idioma del artículo
       Parámetros: clave As xs:string — la @k de la tabla
       Retorna   : xs:string — el rótulo, escapado para LaTeX
       ============================================ -->
  <xsl:function name="gbr:rotulo" as="xs:string">
    <xsl:param name="clave" as="xs:string"/>
    <xsl:variable name="r" select="$gbr:rotulos[@k = $clave]"/>
    <xsl:sequence select="f:latex(string(($r/@*[local-name() = $gbr:lang], $r/@es)[1]))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbr:en-idioma
       Propósito : ¿El elemento está en el idioma del artículo? Sin
                   xml:lang, sí: el canónico solo lo pone en los otros
       Parámetros: e As element() — el elemento
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbr:en-idioma" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="normalize-space($e/@xml:lang) = ('', $xmlLang)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbr:fecha
       Propósito : Una fecha de JATS con el mes en letras («1 de marzo
                   de 2026», «1 March 2026»)
       Parámetros: d As element() — date o pub-date (day, month, year)
       Retorna   : xs:string — la fecha; solo lo que haya de ella
       ============================================ -->
  <xsl:function name="gbr:fecha" as="xs:string">
    <xsl:param name="d" as="element()"/>
    <xsl:variable name="dia" select="if ($d/day castable as xs:integer) then string(xs:integer($d/day)) else ''"/>
    <xsl:variable name="mes" select="if ($d/month castable as xs:integer)
      then string($gbr:meses[xs:integer($d/month)]/@*[local-name() = $gbr:lang]) else ''"/>
    <xsl:variable name="anio" select="normalize-space($d/year)"/>
    <xsl:sequence select="
      if ($gbr:lang = ('es', 'pt'))
      then string-join(($dia[. ne ''], $mes[. ne ''], $anio), ' de ')
      else string-join(($dia, $mes, $anio)[. ne ''], ' ')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbr:nombre
       Propósito : El nombre completo de un contribuyente, persona o
                   colectivo, escapado
       Parámetros: c As element(contrib)
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbr:nombre" as="xs:string">
    <xsl:param name="c" as="element()"/>
    <xsl:sequence select="f:latex(normalize-space(
      if ($c/name) then string-join(($c/name/given-names, $c/name/surname, $c/name/suffix), ' ')
      else string($c/collab)))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbr:afiliacion
       Propósito : Una afiliación en una línea: institución,
                   dependencia, ciudad, país (Redalyc 4.8, Latindex 13)
       Parámetros: a As element(aff)
       Retorna   : xs:string — escapado
       ============================================ -->
  <xsl:function name="gbr:afiliacion" as="xs:string">
    <xsl:param name="a" as="element()"/>
    <xsl:sequence select="f:latex(string-join((
      $a//institution[@content-type = 'orgname'],
      $a//institution[starts-with(@content-type, 'orgdiv')],
      $a//institution[not(@content-type)],
      $a/city, $a/country) ! normalize-space(.)[. ne ''], ', '))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: article                                           -->
  <!-- EL ORDEN DEL FRAGMENTO (VER EL ENCABEZADO)                  -->
  <!-- ============================================================ -->
  <xsl:template match="article">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="fpage" select="normalize-space($meta/fpage)"/>

    <!-- 1. IDIOMA, MACROS, FOLIO, ESTILO DE LA PRIMERA PÁGINA -->
    <xsl:text>\selectlanguage{</xsl:text>
    <xsl:value-of select="f:babel-lang($xmlLang)"/>
    <xsl:text>}&#10;&#10;</xsl:text>
    <xsl:call-template name="emitir-macros-metadatos"/>

    <!-- EL FOLIO: EL PARÁMETRO (LA COMPOSICIÓN DEL NÚMERO LO SABE ANTES
         QUE EL CANÓNICO), DESPUÉS fpage, DESPUÉS 1 (e-id, DECISIÓN DE A1) -->
    <xsl:text>\setcounter{page}{</xsl:text>
    <xsl:value-of select="
      if ($pagina_inicial castable as xs:integer) then $pagina_inicial
      else if ($fpage castable as xs:integer) then $fpage
      else '1'"/>
    <xsl:text>}&#10;\thispagestyle{firstpage}&#10;&#10;</xsl:text>

    <!-- 2. DATOS DEL PDF -->
    <xsl:call-template name="gbr:datos-pdf"/>

    <!-- 3. TÍTULOS -->
    <xsl:call-template name="emitir-titulo-ancho"/>

    <!-- 4. LA COLUMNA DERECHA: SE ARMA EN UNA CAJA Y SE COLOCA ACÁ, DONDE
         EMPIEZA EL PRIMER RESUMEN; \gbcolocarcolumna AVISA SI NO ENTRA -->
    <xsl:call-template name="emitir-bloque-lateral"/>
    <xsl:text>\gbcolocarcolumna&#10;&#10;</xsl:text>

    <!-- 5. RESÚMENES: EL DEL ARTÍCULO Y LUEGO LOS TRADUCIDOS -->
    <xsl:for-each select="$meta/abstract | $meta/trans-abstract">
      <xsl:call-template name="tcolorbox-resumen">
        <xsl:with-param name="lang" select="(normalize-space(@xml:lang)[. ne ''], $xmlLang)[1]"/>
        <xsl:with-param name="parrs" select="p | sec"/>
        <xsl:with-param name="kwds" select="()"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- SEPARADOR ENTRE LA PRIMERA PÁGINA Y EL CUERPO -->
    <xsl:if test="body/sec or body/p">
      <xsl:text>&#10;\bigskip&#10;\noindent\rule{\linewidth}{0.4pt}&#10;\bigskip&#10;&#10;</xsl:text>
    </xsl:if>

    <!-- 6. CUERPO Y AGRADECIMIENTOS -->
    <xsl:apply-templates select="body"/>
    <xsl:apply-templates select="back/ack"/>

    <!-- 7. DECLARACIONES, ANTES DE LAS REFERENCIAS (DECISIÓN DE ALBERTO, 7/11) -->
    <xsl:call-template name="gbr:declaraciones"/>

    <!-- 8. APÉNDICES -->
    <xsl:apply-templates select="back/app-group"/>

    <!-- 9. EL .bib DEL «CÓMO CITAR» -->
    <xsl:if test="$bib_cita ne ''">
      <xsl:call-template name="gbr:bib-cita"/>
    </xsl:if>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-macros-metadatos                      -->
  <!-- \renewcommand DE LOS DATOS DEL ARTÍCULO (CONTRATO 2, 4.1).   -->
  <!-- REEMPLAZA AL DE LA HOJA IMPORTADA, QUE CON EL FRONT NUEVO    -->
  <!-- FALLA: LEE pub-date/year COMO UNO SOLO Y EL CANÓNICO TRAE    -->
  <!-- DOS (pub Y collection; MEDIDO: XPTY0004), Y BUSCA issn POR   -->
  <!-- @pub-type, QUE EL CANÓNICO NO USA.                            -->
  <!-- SUMA \articuloautorescorto (MEMBRETE, REDALYC 4.5) Y         -->
  <!-- \articuloeid. LA FECHA ES LA DEL NÚMERO (collection): EL     -->
  <!-- PERÍODO DEL MEMBRETE                                          -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-macros-metadatos">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="autores" select="$meta/contrib-group/contrib[@contrib-type = 'author']"/>
    <xsl:variable name="issn" select="normalize-space((front/journal-meta/issn[@publication-format = 'electronic'],
                                                     front/journal-meta/issn[@pub-type = 'epub'])[1])"/>
    <xsl:variable name="tipo-art" select="string(/article/@article-type)"/>
    <xsl:variable name="tipo" select="$gbr:tipos[@t = $tipo-art]"/>
    <xsl:variable name="periodo" select="($meta/pub-date[@date-type = 'collection'], $meta/pub-date)[1]"/>

    <!-- 1. IDIOMA Y TÍTULOS (EL <break/> PASA A \gbCorteTitulo, SC-28) -->
    <xsl:value-of select="gbr:macro('articuloidiomaxml', $xmlLang)"/>
    <xsl:value-of select="gbr:macro('articulotitulo', f:titulo-compuesto($meta/title-group/article-title))"/>
    <xsl:value-of select="gbr:macro('articulosubtitulo', f:titulo-compuesto($meta/title-group/subtitle))"/>

    <!-- 2. AUTORES: COMPLETOS (PERSONAS Y COLECTIVOS) Y CORTOS -->
    <xsl:value-of select="gbr:macro('articuloautores', string-join($autores ! gbr:nombre(.), ', '))"/>
    <xsl:if test="$autores">
      <!-- APELLIDO; DOS, CON LA CONJUNCIÓN DEL IDIOMA; TRES O MÁS, «et al.» -->
      <xsl:variable name="cortos" select="$autores ! (if (name) then f:latex(normalize-space(name/surname)) else gbr:nombre(.))"/>
      <xsl:variable name="y" select="if ($gbr:lang = 'en') then ' and ' else if ($gbr:lang = 'fr') then ' et '
                                     else if ($gbr:lang = 'pt') then ' e ' else ' y '"/>
      <xsl:value-of select="gbr:macro('articuloautorescorto',
        if (count($cortos) eq 1) then $cortos
        else if (count($cortos) eq 2) then string-join($cortos, $y)
        else concat($cortos[1], ' et al.'))"/>
    </xsl:if>

    <!-- 3. IDENTIFICADORES -->
    <xsl:value-of select="gbr:macro('articulodoi', f:latex(normalize-space($meta/article-id[@pub-id-type = 'doi'])))"/>
    <xsl:value-of select="gbr:macro('articuloeid', f:latex(normalize-space($meta/elocation-id)))"/>

    <!-- 4. TIPO DE ARTÍCULO, EN MAYÚSCULAS, EN EL IDIOMA DEL ARTÍCULO -->
    <xsl:value-of select="gbr:macro('articulotipo', upper-case(f:latex(
      if ($tipo) then string(($tipo/@*[local-name() = $gbr:lang], $tipo/@es)[1])
      else $tipo-art)))"/>

    <!-- 5. LA REVISTA Y EL NÚMERO -->
    <xsl:value-of select="gbr:macro('articulorevista', f:latex(normalize-space(front/journal-meta/journal-title-group/journal-title)))"/>
    <xsl:value-of select="gbr:macro('articuloissne', f:latex($issn))"/>
    <xsl:value-of select="gbr:macro('articulovolumen', f:latex(normalize-space($meta/volume)))"/>
    <xsl:value-of select="gbr:macro('articulonumero', f:latex(normalize-space($meta/issue)))"/>
    <xsl:if test="$periodo">
      <xsl:value-of select="gbr:macro('articulofecha', upper-case(f:latex(gbr:fecha($periodo))))"/>
    </xsl:if>
    <xsl:value-of select="gbr:macro('articulopagina', normalize-space($meta/fpage))"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================
       Función   : gbr:macro
       Propósito : Un \renewcommand de un dato del artículo; nada si el
                   valor está vacío (QUEDA EL DEL CONTRATO)
       Parámetros: nombre As xs:string — la macro sin barra
                   valor As xs:string? — ya escapado
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbr:macro" as="xs:string">
    <xsl:param name="nombre" as="xs:string"/>
    <xsl:param name="valor" as="xs:string?"/>
    <xsl:sequence select="if (normalize-space($valor) eq '') then ''
                          else concat('\renewcommand{\', $nombre, '}{', $valor, '}&#10;')"/>
  </xsl:function>

  <!-- EL TIPO DE ARTÍCULO POR IDIOMA: LA TABLA DE LA HOJA IMPORTADA -->
  <xsl:variable name="gbr:tipos" as="element()*">
    <t t="research-article" es="Artículo de investigación" en="Research article" pt="Artigo de pesquisa" fr="Article de recherche"/>
    <t t="review-article" es="Artículo de revisión" en="Review article" pt="Artigo de revisão" fr="Article de synthèse"/>
    <t t="editorial" es="Editorial" en="Editorial" pt="Editorial" fr="Éditorial"/>
    <t t="book-review" es="Reseña" en="Book review" pt="Resenha" fr="Compte rendu"/>
    <t t="letter" es="Carta" en="Letter" pt="Carta" fr="Lettre"/>
    <t t="case-report" es="Reporte de caso" en="Case report" pt="Relato de caso" fr="Rapport de cas"/>
    <t t="correction" es="Corrección" en="Correction" pt="Correção" fr="Correction"/>
    <t t="obituary" es="Obituario" en="Obituary" pt="Obituário" fr="Nécrologie"/>
    <t t="systematic-review" es="Revisión sistemática" en="Systematic review" pt="Revisão sistemática" fr="Revue systématique"/>
  </xsl:variable>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbr:datos-pdf                                -->
  <!-- TÍTULO, AUTORES, DERECHOS, LICENCIA Y PALABRAS CLAVE EN EL   -->
  <!-- XMP DEL PDF (REDALYC 3.3). CON \DocumentMetadata, hyperref   -->
  <!-- LOS PASA AL XMP: pdftitle → dc:title, pdfauthor → dc:creator -->
  <!-- (UNO POR COMA), pdfcopyright → dc:rights, pdflicenseurl →    -->
  <!-- xmpRights:WebStatement, pdfkeywords → dc:subject. MEDIDO EN  -->
  <!-- EL CUERPO DEL DOCUMENTO, TeX Live 2023, Y PASA PDF/A-2u      -->
  <!-- (7/11/2026)                                                  -->
  <!-- ============================================================ -->
  <xsl:template name="gbr:datos-pdf">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="perm" select="$meta/permissions"/>
    <xsl:variable name="titulo" select="string-join((
      f:titulo-plano($meta/title-group/article-title),
      f:titulo-plano($meta/title-group/subtitle)[. ne '']), ': ')"/>
    <xsl:variable name="derechos" select="string-join((
      normalize-space($perm/copyright-statement),
      normalize-space($perm/license[1]/license-p))[. ne ''], '. ')"/>
    <xsl:variable name="licencia" select="normalize-space(($perm/license[1]/ali:license_ref, $perm/license[1]/@xlink:href)[1])"/>
    <xsl:variable name="claves" select="$meta/kwd-group[gbr:en-idioma(.)][not(@kwd-group-type) or @kwd-group-type = 'author']/kwd"/>

    <xsl:text>\hypersetup{%&#10;  pdftitle={</xsl:text>
    <xsl:value-of select="$titulo"/>
    <xsl:text>},%&#10;  pdfauthor={</xsl:text>
    <xsl:value-of select="string-join($meta/contrib-group/contrib[@contrib-type = 'author'] ! gbr:nombre(.), ', ')"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="$derechos ne ''">
      <xsl:text>,%&#10;  pdfcopyright={</xsl:text>
      <xsl:value-of select="f:latex($derechos)"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="$licencia ne ''">
      <xsl:text>,%&#10;  pdflicenseurl={</xsl:text>
      <xsl:value-of select="f:latex-url($licencia)"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:if test="$claves">
      <xsl:text>,%&#10;  pdfkeywords={</xsl:text>
      <xsl:value-of select="string-join($claves ! f:latex(normalize-space(.)), ', ')"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-titulo-ancho                          -->
  <!-- TÍTULO, SUBTÍTULO Y CADA TÍTULO TRADUCIDO (CON SU SUBTÍTULO) -->
  <!-- A ANCHO COMPLETO. EL ASPECTO ES DEL CONTRATO (\gbtitulo …)   -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-titulo-ancho">
    <xsl:variable name="tg" select="front/article-meta/title-group"/>
    <xsl:text>\gbtitulo{\articulotitulo}&#10;</xsl:text>
    <xsl:if test="normalize-space($tg/subtitle) ne ''">
      <xsl:text>\gbsubtitulo{\articulosubtitulo}&#10;</xsl:text>
    </xsl:if>
    <xsl:for-each select="$tg/trans-title-group[normalize-space(trans-title) ne '']">
      <!-- EL PRIMERO QUEDA EN \articulotitulotrans PARA LA ESTÉTICA -->
      <xsl:if test="position() eq 1">
        <xsl:text>\renewcommand{\articulotitulotrans}{</xsl:text>
        <xsl:value-of select="f:titulo-compuesto(trans-title)"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
      <xsl:text>\gbtitulotrans{</xsl:text>
      <xsl:value-of select="string-join((f:titulo-compuesto(trans-title),
        f:titulo-compuesto(trans-subtitle)[. ne '']), ': ')"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-bloque-lateral                        -->
  <!-- LA COLUMNA DERECHA (A1.1b): AUTORES, EDICIÓN, TRADUCCIÓN,    -->
  <!-- FECHAS, DOI O e-id, CÓMO CITAR, DERECHOS Y LICENCIA. VA EN   -->
  <!-- gbcolumna, QUE LA GUARDA EN UNA CAJA; LA COLOCA Y LA MIDE    -->
  <!-- \gbcolocarcolumna. EL DISEÑO VIEJO (textblock* A 92 mm FIJOS)-->
  <!-- NO SABÍA DÓNDE TERMINABA EL TÍTULO                           -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-bloque-lateral">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="perm" select="$meta/permissions"/>
    <xsl:variable name="doi" select="normalize-space($meta/article-id[@pub-id-type = 'doi'])"/>
    <xsl:variable name="eid" select="normalize-space($meta/elocation-id)"/>
    <xsl:variable name="licencia" select="normalize-space(($perm/license[1]/ali:license_ref, $perm/license[1]/@xlink:href)[1])"/>
    <xsl:variable name="eventos" select="$meta/pub-history/event/date | $meta/history/date"/>
    <xsl:variable name="pub" select="$meta/pub-date[@date-type = 'pub']"/>

    <xsl:text>\begin{gbcolumna}&#10;</xsl:text>

    <!-- 1. AUTORES: NOMBRE COMPLETO, ORCID, AFILIACIÓN Y CORREO (REDALYC 4.8) -->
    <xsl:for-each select="$meta/contrib-group/contrib[@contrib-type = 'author']">
      <xsl:if test="position() gt 1"><xsl:text>\gbentreautores&#10;</xsl:text></xsl:if>
      <xsl:call-template name="gbr:persona"/>
    </xsl:for-each>

    <!-- 2. EDICIÓN Y TRADUCCIÓN (SCIELO §5.2.4: EL EDITOR RESPONSABLE) -->
    <xsl:for-each-group select="$meta/contrib-group/contrib[@contrib-type = ('editor', 'translator')]"
                        group-by="@contrib-type">
      <xsl:sort select="if (current-grouping-key() eq 'editor') then 1 else 2"/>
      <xsl:text>\gbbloque&#10;\gbrotulo{</xsl:text>
      <xsl:value-of select="gbr:rotulo(current-grouping-key() ! (if (. eq 'editor') then 'editor' else 'traductor'))"/>
      <xsl:text>}&#10;</xsl:text>
      <xsl:for-each select="current-group()">
        <xsl:text>\gbnombre{</xsl:text>
        <xsl:value-of select="gbr:nombre(.)"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:for-each>
    </xsl:for-each-group>

    <!-- 3. FECHAS: EL PROCESO Y LA PUBLICACIÓN (REDALYC 1.6, DOAJ) -->
    <xsl:if test="$eventos or $pub">
      <xsl:text>\gbbloque&#10;</xsl:text>
      <xsl:for-each select="$eventos[@date-type = ('received', 'rev-recd', 'accepted')]">
        <xsl:sort select="index-of(('received', 'rev-recd', 'accepted'), string(@date-type))"/>
        <xsl:sort select="@iso-8601-date"/>
        <xsl:call-template name="gbr:dato">
          <xsl:with-param name="rotulo" select="gbr:rotulo(@date-type)"/>
          <xsl:with-param name="valor" select="f:latex(gbr:fecha(.))"/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:for-each select="$pub[1]">
        <xsl:call-template name="gbr:dato">
          <xsl:with-param name="rotulo" select="gbr:rotulo('pub')"/>
          <xsl:with-param name="valor" select="f:latex(gbr:fecha(.))"/>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:if>

    <!-- 4. IDENTIFICADORES (REDALYC 5.9; SCIELO §5.2.7: NÚMERO DE ARTÍCULO) -->
    <xsl:if test="$doi ne '' or $eid ne ''">
      <xsl:text>\gbbloque&#10;</xsl:text>
      <xsl:if test="$doi ne ''">
        <xsl:call-template name="gbr:dato">
          <xsl:with-param name="rotulo" select="'DOI'"/>
          <xsl:with-param name="valor" select="concat('\url{https://doi.org/', f:latex-url($doi), '}')"/>
        </xsl:call-template>
      </xsl:if>
      <xsl:if test="$eid ne ''">
        <xsl:call-template name="gbr:dato">
          <xsl:with-param name="rotulo" select="gbr:rotulo('eid')"/>
          <xsl:with-param name="valor" select="f:latex($eid)"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>

    <!-- 5. CÓMO CITAR: LA REFERENCIA LA ARMA biblatex CON EL ESTILO DE LA
         REVISTA, DESDE EL .bib QUE ESCRIBE gbr:bib-cita -->
    <xsl:if test="$bib_cita ne ''">
      <xsl:text>\gbbloque&#10;\gbrotulo{</xsl:text>
      <xsl:value-of select="gbr:rotulo('comocitar')"/>
      <xsl:text>}&#10;\gbcomocitar{</xsl:text>
      <xsl:value-of select="$bib_cita"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="$gbr:clave-cita"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- 6. DERECHOS Y LICENCIA (LA DE LA BASE, TAL CUAL; DOAJ) -->
    <xsl:if test="$perm/copyright-statement or $perm/license">
      <xsl:text>\gbbloque&#10;\gbrotulo{</xsl:text>
      <xsl:value-of select="gbr:rotulo('licencia')"/>
      <xsl:text>}&#10;\gbtexto{</xsl:text>
      <xsl:value-of select="string-join((
        f:latex(normalize-space($perm/copyright-statement))[. ne ''],
        f:latex(normalize-space($perm/license[1]/license-p))[. ne '']), '. ')"/>
      <xsl:if test="$licencia ne ''">
        <xsl:text> \url{</xsl:text>
        <xsl:value-of select="f:latex-url($licencia)"/>
        <xsl:text>}</xsl:text>
      </xsl:if>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- 7. COMPARTIR: LOS NUEVE ENLACES DEL DISEÑO VIEJO, CON LA DIRECCIÓN
         DEL ARTÍCULO; SIN DIRECCIÓN NO SALEN -->
    <xsl:call-template name="gbr:compartir"/>

    <xsl:text>\end{gbcolumna}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbr:compartir                                -->
  <!-- LOS NUEVE ÍCONOS PARA COMPARTIR EL ARTÍCULO, CON LOS MISMOS  -->
  <!-- ENLACES QUE ARMABA emitir-bloque-lateral DE LA HOJA VIEJA.   -->
  <!-- LA DIRECCIÓN: EL PARÁMETRO url_articulo (EL DEL CAMINO       -->
  <!-- VIEJO); SI ESTÁ VACÍO, LA self-uri «pagina» DEL CANÓNICO.    -->
  <!-- LOS ÍCONOS SON LOS PNG AZULES DE .hidden/fonts (COPIA DE LOS -->
  <!-- SVG DE Font Awesome Free, CC BY 4.0), BUSCADOS EN ruta_fonts:-->
  <!-- \includegraphics, SIN -shell-escape NI Inkscape (\includesvg-->
  <!-- LOS NECESITABA). LAS DIRECCIONES PASAN POR f:latex-url: VAN  -->
  <!-- COMO ARGUMENTO DE \gbicono Y UN % SIN BARRA LAS CORTARÍA     -->
  <!-- ============================================================ -->
  <xsl:template name="gbr:compartir">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="url" select="(normalize-space($url_articulo)[. ne ''],
      normalize-space($meta/self-uri[@content-type = 'pagina'][1]/@xlink:href))[1]"/>
    <xsl:if test="$url ne ''">
      <xsl:variable name="u" select="encode-for-uri($url)"/>
      <xsl:variable name="t" select="encode-for-uri(normalize-space(string-join(
        f:titulo-tramos($meta/title-group/article-title), ' ')))"/>
      <!-- EL ORDEN Y LOS ENLACES, LOS DEL DISEÑO VIEJO -->
      <xsl:variable name="enlaces" as="element()*">
        <e i="bluesky" h="{'https://bsky.app/intent/compose?text=' || $u}"/>
        <e i="envelope" h="{'mailto:?subject=' || $t || '&amp;body=' || $u}"/>
        <e i="facebook" h="{'https://www.facebook.com/sharer/sharer.php?u=' || $u}"/>
        <e i="linkedin" h="{'https://www.linkedin.com/sharing/share-offsite/?url=' || $u}"/>
        <e i="reddit" h="{'https://www.reddit.com/submit?url=' || $u || '&amp;title=' || $t}"/>
        <e i="researchgate" h="{'https://www.researchgate.net/search?q=' || $t}"/>
        <e i="telegram" h="{'https://t.me/share/url?url=' || $u || '&amp;text=' || $t}"/>
        <e i="whatsapp" h="{'https://wa.me/?text=' || $u}"/>
        <e i="x-twitter" h="{'https://twitter.com/intent/tweet?url=' || $u || '&amp;text=' || $t}"/>
      </xsl:variable>
      <xsl:text>\gbbloque&#10;\gbrotulo{</xsl:text>
      <xsl:value-of select="gbr:rotulo('compartir')"/>
      <xsl:text>}&#10;\gbcompartir{%&#10;</xsl:text>
      <xsl:for-each select="$enlaces">
        <xsl:text>  \gbicono{</xsl:text>
        <xsl:value-of select="concat($ruta_fonts, @i, '.png')"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="f:latex-url(@h)"/>
        <xsl:text>}%&#10;</xsl:text>
      </xsl:for-each>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbr:persona
       Propósito : Un autor en la columna: nombre, ORCID, afiliaciones
                   (por xref, LAS COMPARTIDAS SE REPITEN) y correo
       Contexto  : contrib
       ============================================ -->
  <xsl:template name="gbr:persona">
    <xsl:variable name="c" select="."/>
    <xsl:variable name="orcid" select="normalize-space(contrib-id[@contrib-id-type = 'orcid'])"/>

    <!-- 1. NOMBRE -->
    <xsl:text>\gbautor{</xsl:text>
    <xsl:value-of select="gbr:nombre(.)"/>
    <xsl:text>}&#10;</xsl:text>

    <!-- 2. ORCID -->
    <xsl:if test="$orcid ne ''">
      <xsl:text>\gborcid{</xsl:text>
      <xsl:value-of select="f:latex-url($orcid)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- 3. AFILIACIONES: LAS QUE NOMBRA POR xref Y LAS QUE TRAE ADENTRO -->
    <xsl:for-each select="(//aff[@id = $c/xref[@ref-type = 'aff']/@rid], aff)">
      <xsl:text>\gbafiliacion{</xsl:text>
      <xsl:value-of select="gbr:afiliacion(.)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>

    <!-- 4. CORREO; EL DE LA CORRESPONDENCIA, CON SU RÓTULO -->
    <xsl:for-each select="email[normalize-space(.) ne '']">
      <xsl:text>\gbcorreo{</xsl:text>
      <xsl:if test="$c/@corresp = 'yes'"><xsl:value-of select="gbr:rotulo('correspondencia')"/></xsl:if>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="f:latex-url(normalize-space(.))"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbr:dato
       Propósito : Una línea «Rótulo: valor» de la columna
       Parámetros: rotulo, valor As xs:string — ya escapados
       ============================================ -->
  <xsl:template name="gbr:dato">
    <xsl:param name="rotulo" as="xs:string"/>
    <xsl:param name="valor" as="xs:string"/>
    <xsl:text>\gbdato{</xsl:text>
    <xsl:value-of select="$rotulo"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="$valor"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: tcolorbox-resumen                            -->
  <!-- UN gbresumen POR IDIOMA. EL ESTRUCTURADO (abstract/sec) VA   -->
  <!-- CON EL TÍTULO DE CADA SECCIÓN EN LÍNEA, NO COMO \section (LA -->
  <!-- HOJA VIEJA LE APLICABA LA PLANTILLA DE sec DEL CUERPO).      -->
  <!-- LAS PALABRAS CLAVE SON LAS DEL MISMO IDIOMA: LAS DEL AUTOR Y -->
  <!-- LAS DE CADA VOCABULARIO (DeCS…) CON SU NOMBRE. EL PARÁMETRO  -->
  <!-- kwds SE CONSERVA POR LA FIRMA; SE CALCULAN ACÁ: LA HOJA VIEJA-->
  <!-- NO ENCONTRABA LAS DEL IDIOMA DEL ARTÍCULO, QUE VAN SIN        -->
  <!-- xml:lang                                                     -->
  <!-- ============================================================ -->
  <xsl:template name="tcolorbox-resumen">
    <xsl:param name="lang"/>
    <xsl:param name="parrs"/>
    <xsl:param name="kwds"/>
    <xsl:variable name="grupos" select="../kwd-group[normalize-space((@xml:lang, $xmlLang)[1]) = $lang][kwd]"/>
    <xsl:variable name="l2" select="lower-case(substring($lang, 1, 2))"/>
    <xsl:variable name="r" select="$gbr:rotulos[@k = 'resumen']"/>
    <xsl:variable name="p" select="$gbr:rotulos[@k = 'palabras']"/>

    <!-- 1. APERTURA, CON EL RÓTULO EN EL IDIOMA DEL RESUMEN -->
    <xsl:text>\begin{gbresumen}{</xsl:text>
    <xsl:value-of select="f:babel-lang($lang)"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="f:latex(string(($r/@*[local-name() = $l2], $r/@en)[1]))"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="sec">
      <xsl:text>[estructurado]</xsl:text>
    </xsl:if>
    <xsl:text>&#10;</xsl:text>

    <!-- 2. EL TEXTO -->
    <xsl:apply-templates select="$parrs"/>

    <!-- 3. PALABRAS CLAVE: LAS DEL AUTOR PRIMERO -->
    <xsl:for-each select="$grupos">
      <xsl:sort select="if (not(@kwd-group-type) or @kwd-group-type = 'author') then 0 else 1"/>
      <xsl:text>&#10;\gbpalabrasclave{</xsl:text>
      <xsl:value-of select="
        if (not(@kwd-group-type) or @kwd-group-type = 'author')
        then f:latex(string(($p/@*[local-name() = $l2], $p/@en)[1]))
        else f:latex(string((@vocab, @kwd-group-type)[1]))"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="string-join(kwd ! f:latex(normalize-space(.)), '; ')"/>
      <xsl:text>}</xsl:text>
    </xsl:for-each>
    <xsl:text>&#10;\end{gbresumen}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- RESUMEN ESTRUCTURADO: CADA SECCIÓN ES UN PÁRRAFO QUE ABRE CON SU
       TÍTULO EN LÍNEA (\gbresumensec) -->
  <xsl:template match="abstract/sec | trans-abstract/sec">
    <xsl:text>\gbresumensec{</xsl:text>
    <xsl:value-of select="f:latex(normalize-space(title))"/>
    <xsl:text>}</xsl:text>
    <xsl:apply-templates select="* except title"/>
    <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="abstract/sec/p | trans-abstract/sec/p">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::p">
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbr:declaraciones                            -->
  <!-- AL FINAL, ANTES DE LAS REFERENCIAS: CONTRIBUCIONES (CRediT,  -->
  <!-- SCIELO §5.2.6.4.1), FINANCIAMIENTO, CONFLICTO DE INTERESES Y -->
  <!-- DISPONIBILIDAD DE DATOS (SCIELO §2.3). SOLO LO QUE ESTÉ EN   -->
  <!-- EL IDIOMA DEL ARTÍCULO. LOS ROLES CRediT VAN CON EL TÉRMINO  -->
  <!-- DEL VOCABULARIO (EN INGLÉS): NO HAY TRADUCCIÓN VERIFICADA    -->
  <!-- ============================================================ -->
  <xsl:template name="gbr:declaraciones">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="con-roles" select="$meta/contrib-group/contrib[@contrib-type = 'author'][role]"/>
    <xsl:variable name="fg" select="$meta/funding-group"/>
    <xsl:variable name="fin-texto" select="$fg/funding-statement[gbr:en-idioma(.)][1]"/>
    <xsl:variable name="coi" select="$meta/author-notes/fn[@fn-type = 'coi-statement'][gbr:en-idioma(.)][1]"/>
    <xsl:variable name="datos" select="back/sec[@sec-type = 'data-availability'][gbr:en-idioma(.)][1]"/>

    <xsl:if test="$con-roles or $fg/award-group or $fin-texto or $coi or $datos">

      <!-- 1. EL TÍTULO DEL BLOQUE -->
      <xsl:text>&#10;\gbdeclaraciones{</xsl:text>
      <xsl:value-of select="gbr:rotulo('declaraciones')"/>
      <xsl:text>}&#10;</xsl:text>

      <!-- 2. CONTRIBUCIONES: «Nombre: rol, rol.» POR AUTOR -->
      <xsl:if test="$con-roles">
        <xsl:text>\gbdeclaracion{</xsl:text>
        <xsl:value-of select="gbr:rotulo('contribuciones')"/>
        <xsl:text>}</xsl:text>
        <xsl:for-each select="$con-roles">
          <xsl:value-of select="gbr:nombre(.)"/>
          <xsl:text>: </xsl:text>
          <xsl:value-of select="string-join(role ! f:latex(normalize-space((@vocab-term, string(.))[1])), ', ')"/>
          <xsl:text>. </xsl:text>
        </xsl:for-each>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:if>

      <!-- 3. FINANCIAMIENTO: LA DECLARACIÓN; SIN ELLA, LAS FUENTES Y PROYECTOS -->
      <xsl:if test="$fin-texto or $fg/award-group">
        <xsl:text>\gbdeclaracion{</xsl:text>
        <xsl:value-of select="gbr:rotulo('financiamiento')"/>
        <xsl:text>}</xsl:text>
        <xsl:choose>
          <xsl:when test="$fin-texto">
            <xsl:value-of select="f:latex(normalize-space($fin-texto))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="string-join($fg/award-group ! (
              f:latex(normalize-space(string-join(funding-source//institution, ' ')))
              || (if (award-id) then ' (' || string-join(award-id ! f:latex(normalize-space(.)), ', ') || ')' else '')
              ), '; ')"/>
            <xsl:text>.</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:if>

      <!-- 4. CONFLICTO DE INTERESES -->
      <xsl:if test="$coi">
        <xsl:text>\gbdeclaracion{</xsl:text>
        <xsl:value-of select="gbr:rotulo('coi')"/>
        <xsl:text>}</xsl:text>
        <xsl:call-template name="gbr:parrafos-en-linea">
          <xsl:with-param name="p" select="$coi/p"/>
        </xsl:call-template>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:if>

      <!-- 5. DISPONIBILIDAD DE DATOS, CON EL TÍTULO DE SU SECCIÓN -->
      <xsl:if test="$datos">
        <xsl:text>\gbdeclaracion{</xsl:text>
        <xsl:value-of select="if (normalize-space($datos/title) ne '')
                              then f:latex(normalize-space($datos/title))
                              else gbr:rotulo('datos')"/>
        <xsl:text>}</xsl:text>
        <xsl:call-template name="gbr:parrafos-en-linea">
          <xsl:with-param name="p" select="$datos/p"/>
        </xsl:call-template>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbr:parrafos-en-linea
       Propósito : Los párrafos de una declaración seguidos, con sus
                   marcas en línea (cursiva, enlaces) y un espacio
                   entre ellos: van después del rótulo en línea
       Parámetros: p As element(p)* — los párrafos
       ============================================ -->
  <xsl:template name="gbr:parrafos-en-linea">
    <xsl:param name="p" as="element()*"/>
    <xsl:for-each select="$p">
      <xsl:if test="position() gt 1"><xsl:text> </xsl:text></xsl:if>
      <xsl:apply-templates select="node()"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbr:bib-cita                                 -->
  <!-- EL ARTÍCULO COMO ENTRADA @article DE biblatex, PARA QUE EL   -->
  <!-- «CÓMO CITAR» SALGA EN EL ESTILO DE LA REVISTA (\fullcite EN  -->
  <!-- UNA refsection PROPIA: NO ENTRA EN LAS REFERENCIAS). LOS     -->
  <!-- COLECTIVOS VAN ENTRE LLAVES: biber NO LOS PARTE EN NOMBRE Y  -->
  <!-- APELLIDO. PÁGINAS SOLO SI HAY RANGO; SI NO, eid              -->
  <!-- ============================================================ -->
  <xsl:template name="gbr:bib-cita">
    <xsl:variable name="meta" select="front/article-meta"/>
    <xsl:variable name="fp" select="normalize-space($meta/fpage)"/>
    <xsl:variable name="lp" select="normalize-space($meta/lpage)"/>
    <xsl:variable name="pub" select="$meta/pub-date[@date-type = 'pub'][1]"/>
    <xsl:variable name="col" select="$meta/pub-date[@date-type = 'collection'][1]"/>
    <xsl:variable name="fecha" select="
      if ($pub/@iso-8601-date) then string($pub/@iso-8601-date)
      else normalize-space(($pub/year, $col/year)[1])"/>
    <xsl:variable name="campos" as="xs:string*">
      <xsl:sequence select="'author = {' || string-join($meta/contrib-group/contrib[@contrib-type = 'author'] ! (
        if (name) then f:latex(string-join((normalize-space(name/surname), normalize-space(name/suffix)[. ne ''],
                                             normalize-space(name/given-names)[. ne '']), ', '))
        else '{' || f:latex(normalize-space(collab)) || '}'), ' and ') || '}'"/>
      <xsl:sequence select="'title = {' || f:titulo-plano($meta/title-group/article-title) || '}'"/>
      <xsl:if test="normalize-space($meta/title-group/subtitle) ne ''">
        <xsl:sequence select="'subtitle = {' || f:titulo-plano($meta/title-group/subtitle) || '}'"/>
      </xsl:if>
      <xsl:sequence select="'journaltitle = {' || f:latex(normalize-space(front/journal-meta/journal-title-group/journal-title)) || '}'"/>
      <xsl:if test="$fecha ne ''"><xsl:sequence select="'date = {' || $fecha || '}'"/></xsl:if>
      <xsl:if test="normalize-space($meta/volume) ne ''">
        <xsl:sequence select="'volume = {' || f:latex(normalize-space($meta/volume)) || '}'"/>
      </xsl:if>
      <xsl:if test="normalize-space($meta/issue) ne ''">
        <xsl:sequence select="'number = {' || f:latex(normalize-space($meta/issue)) || '}'"/>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="normalize-space($meta/elocation-id) ne ''">
          <xsl:sequence select="'eid = {' || f:latex(normalize-space($meta/elocation-id)) || '}'"/>
        </xsl:when>
        <xsl:when test="$fp ne '' and $lp ne ''">
          <xsl:sequence select="'pages = {' || $fp || '--' || $lp || '}'"/>
        </xsl:when>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="normalize-space($meta/article-id[@pub-id-type = 'doi']) ne ''">
          <xsl:sequence select="'doi = {' || normalize-space($meta/article-id[@pub-id-type = 'doi']) || '}'"/>
        </xsl:when>
        <xsl:when test="$meta/self-uri[@content-type = 'pagina']/@xlink:href">
          <xsl:sequence select="'url = {' || normalize-space($meta/self-uri[@content-type = 'pagina'][1]/@xlink:href) || '}'"/>
        </xsl:when>
      </xsl:choose>
      <xsl:sequence select="'langid = {' || f:babel-lang($xmlLang) || '}'"/>
    </xsl:variable>
    <xsl:result-document href="{$bib_cita}" method="text" encoding="UTF-8">
      <xsl:text>% ESCRITO POR jats-a-latex-articulo.xsl: EL «CÓMO CITAR» DEL ARTÍCULO&#10;</xsl:text>
      <xsl:text>@article{</xsl:text>
      <xsl:value-of select="$gbr:clave-cita"/>
      <xsl:text>,&#10;  </xsl:text>
      <xsl:value-of select="string-join($campos, ',&#10;  ')"/>
      <xsl:text>&#10;}&#10;</xsl:text>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>
