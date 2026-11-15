<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  numero-a-doaj.xsl — gbpublisher
  ============================================================================
  EL SABOR DOAJ DEL NÚMERO: UN ARCHIVO CON UN record POR ARTÍCULO, EN EL
  FORMATO PROPIO DE DOAJ (doajArticles.xsd 1.3, schemas/ DEL PAQUETE).
  DECISIONES DE ALBERTO (15/11/2026, claude/salidas-revistas.md):
    - EL FORMATO PROPIO, NO EL XML DE CROSSREF: SIRVE SIN DOI Y LLEVA LOS
      TÍTULOS, RESÚMENES Y PALABRAS CLAVE DE CADA IDIOMA;
    - UN ARCHIVO POR NÚMERO;
    - EL fullTextUrl ES EL self-uri content-type="pagina" DEL CANÓNICO.

  ENTRADA: EL VOLCADO DEL NÚMERO (tmp/numero-datos.xml), QUE DA LOS
  ARTÍCULOS Y SU ORDEN. CADA RECORD SALE DEL CANÓNICO DEL ARTÍCULO
  (c-{archivo}.xml EN dir_canonicos, SIN DOCTYPE: GV-25). EL CANÓNICO ES LA
  FUENTE: LO QUE DICE EL SABOR YA PASÓ POR LA DTD Y POR JATS4R.

  QUÉ DICE DOAJ (doaj.org/docs/xml, LEÍDO EL 15/11/2026) Y CÓMO SE APLICA:
    - OBLIGATORIOS: journalTitle, publicationDate, title (UNO O MÁS) Y
      fullTextUrl; issn O eissn, LOS QUE TENGA LA REVISTA EN DOAJ;
    - IDIOMAS EN ISO 639-2/B (EL ESQUEMA LOS ENUMERA): VER $gbd:iso639;
    - EL NOMBRE DEL AUTOR «First Name, Middle Name, Last Name»: NOMBRE Y
      APELLIDO, EN ESE ORDEN;
    - UNA SOLA AFILIACIÓN POR AUTOR («Others will be ignored»): LA PRIMERA;
    - SIN CORREOS DE AUTORES (DATOS PERSONALES, UE);
    - fullTextUrl Y doi IDENTIFICAN EL ARTÍCULO EN DOAJ: CAMBIARLOS DUPLICA
      EL REGISTRO.
  SIN DECIDIR POR FALTA DE FUENTE: EL e-id (elocation-id) DEL MODELO
  CONTINUO NO SE ESCRIBE EN startPage; LA PÁGINA DE DOAJ NO DICE QUÉ HACER
  CON UN ARTÍCULO SIN PÁGINAS.
  ============================================================================
-->
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:gbd="urn:gbpublisher:doaj"
    exclude-result-prefixes="xs xlink gbd">

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <!-- LA CARPETA DE LOS CANÓNICOS SIN DOCTYPE, COMO URI CON / FINAL -->
  <xsl:param name="dir_canonicos" as="xs:string" required="yes"/>

  <!-- ISO 639-1 → ISO 639-2/B. GENERADA DE LA LISTA OFICIAL DE LA AGENCIA
       DE MANTENIMIENTO (Library of Congress,
       https://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt, BAJADA EL
       15/11/2026): TODAS LAS FILAS CON CÓDIGO DE DOS LETRAS, CON EL CÓDIGO
       BIBLIOGRÁFICO. COINCIDE CON LA ENUMERACIÓN DE iso_639-2b.xsd DE DOAJ
       (ESTA TIENE ADEMÁS hbs, SIN CÓDIGO DE DOS LETRAS VIGENTE) -->
  <xsl:variable name="gbd:iso639" as="map(xs:string, xs:string)" select="map {
    'aa': 'aar',
    'ab': 'abk',
    'ae': 'ave',
    'af': 'afr',
    'ak': 'aka',
    'am': 'amh',
    'an': 'arg',
    'ar': 'ara',
    'as': 'asm',
    'av': 'ava',
    'ay': 'aym',
    'az': 'aze',
    'ba': 'bak',
    'be': 'bel',
    'bg': 'bul',
    'bi': 'bis',
    'bm': 'bam',
    'bn': 'ben',
    'bo': 'tib',
    'br': 'bre',
    'bs': 'bos',
    'ca': 'cat',
    'ce': 'che',
    'ch': 'cha',
    'co': 'cos',
    'cr': 'cre',
    'cs': 'cze',
    'cu': 'chu',
    'cv': 'chv',
    'cy': 'wel',
    'da': 'dan',
    'de': 'ger',
    'dv': 'div',
    'dz': 'dzo',
    'ee': 'ewe',
    'el': 'gre',
    'en': 'eng',
    'eo': 'epo',
    'es': 'spa',
    'et': 'est',
    'eu': 'baq',
    'fa': 'per',
    'ff': 'ful',
    'fi': 'fin',
    'fj': 'fij',
    'fo': 'fao',
    'fr': 'fre',
    'fy': 'fry',
    'ga': 'gle',
    'gd': 'gla',
    'gl': 'glg',
    'gn': 'grn',
    'gu': 'guj',
    'gv': 'glv',
    'ha': 'hau',
    'he': 'heb',
    'hi': 'hin',
    'ho': 'hmo',
    'hr': 'hrv',
    'ht': 'hat',
    'hu': 'hun',
    'hy': 'arm',
    'hz': 'her',
    'ia': 'ina',
    'id': 'ind',
    'ie': 'ile',
    'ig': 'ibo',
    'ii': 'iii',
    'ik': 'ipk',
    'io': 'ido',
    'is': 'ice',
    'it': 'ita',
    'iu': 'iku',
    'ja': 'jpn',
    'jv': 'jav',
    'ka': 'geo',
    'kg': 'kon',
    'ki': 'kik',
    'kj': 'kua',
    'kk': 'kaz',
    'kl': 'kal',
    'km': 'khm',
    'kn': 'kan',
    'ko': 'kor',
    'kr': 'kau',
    'ks': 'kas',
    'ku': 'kur',
    'kv': 'kom',
    'kw': 'cor',
    'ky': 'kir',
    'la': 'lat',
    'lb': 'ltz',
    'lg': 'lug',
    'li': 'lim',
    'ln': 'lin',
    'lo': 'lao',
    'lt': 'lit',
    'lu': 'lub',
    'lv': 'lav',
    'mg': 'mlg',
    'mh': 'mah',
    'mi': 'mao',
    'mk': 'mac',
    'ml': 'mal',
    'mn': 'mon',
    'mr': 'mar',
    'ms': 'may',
    'mt': 'mlt',
    'my': 'bur',
    'na': 'nau',
    'nb': 'nob',
    'nd': 'nde',
    'ne': 'nep',
    'ng': 'ndo',
    'nl': 'dut',
    'nn': 'nno',
    'no': 'nor',
    'nr': 'nbl',
    'nv': 'nav',
    'ny': 'nya',
    'oc': 'oci',
    'oj': 'oji',
    'om': 'orm',
    'or': 'ori',
    'os': 'oss',
    'pa': 'pan',
    'pi': 'pli',
    'pl': 'pol',
    'ps': 'pus',
    'pt': 'por',
    'qu': 'que',
    'rm': 'roh',
    'rn': 'run',
    'ro': 'rum',
    'ru': 'rus',
    'rw': 'kin',
    'sa': 'san',
    'sc': 'srd',
    'sd': 'snd',
    'se': 'sme',
    'sg': 'sag',
    'si': 'sin',
    'sk': 'slo',
    'sl': 'slv',
    'sm': 'smo',
    'sn': 'sna',
    'so': 'som',
    'sq': 'alb',
    'sr': 'srp',
    'ss': 'ssw',
    'st': 'sot',
    'su': 'sun',
    'sv': 'swe',
    'sw': 'swa',
    'ta': 'tam',
    'te': 'tel',
    'tg': 'tgk',
    'th': 'tha',
    'ti': 'tir',
    'tk': 'tuk',
    'tl': 'tgl',
    'tn': 'tsn',
    'to': 'ton',
    'tr': 'tur',
    'ts': 'tso',
    'tt': 'tat',
    'tw': 'twi',
    'ty': 'tah',
    'ug': 'uig',
    'uk': 'ukr',
    'ur': 'urd',
    'uz': 'uzb',
    've': 'ven',
    'vi': 'vie',
    'vo': 'vol',
    'wa': 'wln',
    'wo': 'wol',
    'xh': 'xho',
    'yi': 'yid',
    'yo': 'yor',
    'za': 'zha',
    'zh': 'chi',
    'zu': 'zul'
  }"/>

  <!-- ==================================================================
       FUNCIONES
       ================================================================== -->

  <!-- EL CÓDIGO DOAJ DE UN IDIOMA BCP 47 (es, pt-BR): LA SUBETIQUETA
       PRINCIPAL. VACÍO SI NO TIENE CÓDIGO DE DOS LETRAS EN LA LISTA: EL
       ELEMENTO O EL ATRIBUTO NO SE ESCRIBE (ES OPCIONAL) Y LA VALIDACIÓN
       DEL SABOR LO INFORMA -->
  <xsl:function name="gbd:idioma" as="xs:string">
    <xsl:param name="bcp47" as="xs:string?"/>
    <xsl:variable name="principal" select="lower-case(tokenize(normalize-space($bcp47), '-')[1])"/>
    <xsl:sequence select="if ($principal = '') then '' else (($gbd:iso639($principal), '')[1])"/>
  </xsl:function>

  <!-- TEXTO PLANO DE UN ELEMENTO DE CONTENIDO MIXTO: <break/> ES UN
       ESPACIO (SC-28), LO DEMÁS SU TEXTO -->
  <xsl:function name="gbd:texto" as="xs:string">
    <xsl:param name="nodos" as="node()*"/>
    <xsl:sequence select="normalize-space(string-join(
        for $t in $nodos//(text() | *:break) return
          if ($t instance of element()) then ' ' else string($t), ''))"/>
  </xsl:function>

  <!-- UN TÍTULO CON SU SUBTÍTULO: «Título: subtítulo» -->
  <xsl:function name="gbd:titulo" as="xs:string">
    <xsl:param name="titulo" as="element()?"/>
    <xsl:param name="subtitulo" as="element()?"/>
    <xsl:variable name="t" select="gbd:texto($titulo)"/>
    <xsl:variable name="s" select="gbd:texto($subtitulo)"/>
    <xsl:sequence select="if ($s = '') then $t else concat($t, ': ', $s)"/>
  </xsl:function>

  <!-- UN RESUMEN EN UNA LÍNEA: LOS TÍTULOS DE SUS SECCIONES SEGUIDOS DE
       PUNTO (SI NO TERMINAN EN SIGNO) Y LOS PÁRRAFOS, EN ORDEN -->
  <xsl:function name="gbd:resumen" as="xs:string">
    <xsl:param name="resumen" as="element()"/>
    <xsl:sequence select="normalize-space(string-join(
        for $b in $resumen//(*:title | *:p)[not(ancestor::*:title)]
                          [not(self::*:title and parent::*[self::*:abstract or self::*:trans-abstract])]
        return
          if ($b/self::*:title)
          then (let $t := gbd:texto($b) return
                  if (matches($t, '[.:;?!]$')) then $t else concat($t, '.'))
          else gbd:texto($b),
        ' '))"/>
  </xsl:function>

  <!-- LA FECHA DE PUBLICACIÓN: LA DEL ARTÍCULO (pub); SI NO, LA DEL
       NÚMERO (collection). AAAA[-MM[-DD]], EL PATRÓN DEL ESQUEMA -->
  <xsl:function name="gbd:fecha" as="xs:string">
    <xsl:param name="meta" as="element()"/>
    <xsl:variable name="f" select="($meta/*:pub-date[@date-type = 'pub'],
                                    $meta/*:pub-date[@date-type = 'collection'])[1]"/>
    <xsl:sequence select="
      if ($f/@iso-8601-date) then string($f/@iso-8601-date)
      else string-join((
        normalize-space($f/*:year),
        $f/*:month[normalize-space()]/format-number(xs:integer(normalize-space(.)), '00'),
        $f/*:day[normalize-space()][../*:month[normalize-space()]]/format-number(xs:integer(normalize-space(.)), '00')
      ), '-')"/>
  </xsl:function>

  <!-- LA AFILIACIÓN EN UNA LÍNEA: LAS INSTITUCIONES (DE LA MÁS GENERAL A LA
       MÁS PARTICULAR, COMO LAS ESCRIBE EL CANÓNICO), LA CIUDAD Y EL PAÍS -->
  <xsl:function name="gbd:afiliacion" as="xs:string">
    <xsl:param name="aff" as="element()"/>
    <xsl:sequence select="string-join((
        for $i in $aff//*:institution return gbd:texto($i),
        $aff/*:city/gbd:texto(.),
        $aff/*:country/gbd:texto(.)
      )[. != ''], ', ')"/>
  </xsl:function>

  <!-- ==================================================================
       RAÍZ
       ================================================================== -->
  <xsl:template match="/">
    <records>
      <xsl:for-each select="/numero-datos/articulo">
        <xsl:variable name="ruta" select="concat($dir_canonicos, 'c-', @archivo, '.xml')"/>
        <xsl:if test="not(doc-available($ruta))">
          <xsl:message terminate="yes">No se pudo leer el canónico <xsl:value-of select="$ruta"/></xsl:message>
        </xsl:if>
        <xsl:apply-templates select="doc($ruta)/*:article" mode="record">
          <xsl:with-param name="archivo" select="string(@archivo)"/>
        </xsl:apply-templates>
      </xsl:for-each>
    </records>
  </xsl:template>

  <!-- ==================================================================
       UN RECORD. EL ORDEN DE LOS HIJOS ES EL DE recordType EN EL ESQUEMA
       ================================================================== -->
  <xsl:template match="*:article" mode="record">
    <xsl:param name="archivo" as="xs:string"/>
    <xsl:variable name="jm" select="*:front/*:journal-meta"/>
    <xsl:variable name="am" select="*:front/*:article-meta"/>
    <xsl:variable name="lang" select="string(@xml:lang)"/>
    <xsl:variable name="idioma" select="gbd:idioma($lang)"/>

    <record>
      <xsl:if test="$idioma != ''">
        <language><xsl:value-of select="$idioma"/></language>
      </xsl:if>
      <xsl:for-each select="($jm/*:publisher/*:publisher-name)[1]">
        <publisher><xsl:value-of select="gbd:texto(.)"/></publisher>
      </xsl:for-each>
      <journalTitle><xsl:value-of select="gbd:texto(($jm/*:journal-title-group/*:journal-title)[1])"/></journalTitle>
      <xsl:for-each select="($jm/*:issn[@publication-format = 'print'])[1]">
        <issn><xsl:value-of select="normalize-space(.)"/></issn>
      </xsl:for-each>
      <xsl:for-each select="($jm/*:issn[@publication-format = 'electronic'])[1]">
        <eissn><xsl:value-of select="normalize-space(.)"/></eissn>
      </xsl:for-each>
      <publicationDate><xsl:value-of select="gbd:fecha($am)"/></publicationDate>
      <xsl:for-each select="$am/*:volume[normalize-space()]">
        <volume><xsl:value-of select="normalize-space(.)"/></volume>
      </xsl:for-each>
      <xsl:for-each select="$am/*:issue[normalize-space()]">
        <issue><xsl:value-of select="normalize-space(.)"/></issue>
      </xsl:for-each>
      <xsl:for-each select="$am/*:fpage[normalize-space()]">
        <startPage><xsl:value-of select="normalize-space(.)"/></startPage>
      </xsl:for-each>
      <xsl:for-each select="$am/*:lpage[normalize-space()]">
        <endPage><xsl:value-of select="normalize-space(.)"/></endPage>
      </xsl:for-each>
      <xsl:for-each select="$am/*:article-id[@pub-id-type = 'doi'][normalize-space()]">
        <doi><xsl:value-of select="normalize-space(.)"/></doi>
      </xsl:for-each>
      <!-- EL NOMBRE DEL ARCHIVO: ES ESTABLE EN EL PROYECTO Y PERMITE
           ENCONTRAR EL RECORD EN LA VALIDACIÓN -->
      <publisherRecordId><xsl:value-of select="$archivo"/></publisherRecordId>
      <!-- EL ÚNICO VALOR QUE MUESTRA DOAJ (EL EJEMPLO DE doaj.org/docs/xml) -->
      <documentType>article</documentType>

      <!-- TÍTULOS: EL DEL ARTÍCULO Y LOS TRADUCIDOS -->
      <title>
        <xsl:if test="$idioma != ''"><xsl:attribute name="language" select="$idioma"/></xsl:if>
        <xsl:value-of select="gbd:titulo($am/*:title-group/*:article-title, $am/*:title-group/*:subtitle)"/>
      </title>
      <xsl:for-each select="$am/*:title-group/*:trans-title-group[*:trans-title]">
        <xsl:variable name="i" select="gbd:idioma(@xml:lang)"/>
        <title>
          <xsl:if test="$i != ''"><xsl:attribute name="language" select="$i"/></xsl:if>
          <xsl:value-of select="gbd:titulo(*:trans-title, *:trans-subtitle)"/>
        </title>
      </xsl:for-each>

      <!-- AUTORES: PERSONAS Y COLECTIVOS DEL contrib-group DEL ARTÍCULO -->
      <xsl:variable name="autores" select="$am/*:contrib-group/*:contrib[@contrib-type = 'author']"/>
      <xsl:if test="$autores">
        <authors>
          <xsl:for-each select="$autores">
            <xsl:variable name="orcid" select="normalize-space((*:contrib-id[@contrib-id-type = 'orcid'])[1])"/>
            <xsl:variable name="orcid-url" select="if ($orcid = '' or starts-with($orcid, 'https://')) then $orcid
                                                   else concat('https://orcid.org/', replace($orcid, '^.*orcid\.org/', ''))"/>
            <author>
              <name>
                <xsl:value-of select="if (*:collab) then gbd:texto(*:collab[1])
                                      else string-join((gbd:texto(*:name/*:given-names),
                                                        gbd:texto(*:name/*:surname),
                                                        gbd:texto(*:name/*:suffix))[. != ''], ' ')"/>
              </name>
              <!-- UNA AFILIACIÓN: DOAJ IGNORA LAS DEMÁS -->
              <xsl:for-each select="(*:xref[@ref-type = 'aff'])[1]">
                <affiliationId><xsl:value-of select="@rid"/></affiliationId>
              </xsl:for-each>
              <xsl:if test="matches($orcid-url, '^https://orcid\.org/[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$')">
                <orcid_id><xsl:value-of select="$orcid-url"/></orcid_id>
              </xsl:if>
            </author>
          </xsl:for-each>
        </authors>
        <!-- LAS AFILIACIONES QUE ALGÚN AUTOR NOMBRA, UNA VEZ CADA UNA -->
        <xsl:variable name="ids" select="distinct-values($autores/(*:xref[@ref-type = 'aff'])[1]/@rid)"/>
        <xsl:if test="exists($ids)">
          <affiliationsList>
            <xsl:for-each select="$ids">
              <xsl:variable name="id" select="."/>
              <xsl:for-each select="($am//*:aff[@id = $id])[1]">
                <affiliationName affiliationId="{$id}"><xsl:value-of select="gbd:afiliacion(.)"/></affiliationName>
              </xsl:for-each>
            </xsl:for-each>
          </affiliationsList>
        </xsl:if>
      </xsl:if>

      <!-- RESÚMENES: EL DEL ARTÍCULO Y LOS TRADUCIDOS. LOS DE OTRO TIPO
           (abstract-type: graphical, key-points…) NO SON EL RESUMEN -->
      <xsl:for-each select="$am/*:abstract[not(@abstract-type)] | $am/*:trans-abstract[not(@abstract-type)]">
        <xsl:variable name="i" select="gbd:idioma(if (@xml:lang) then @xml:lang else $lang)"/>
        <abstract>
          <xsl:if test="$i != ''"><xsl:attribute name="language" select="$i"/></xsl:if>
          <xsl:value-of select="gbd:resumen(.)"/>
        </abstract>
      </xsl:for-each>

      <!-- EL TEXTO COMPLETO: LA PÁGINA DEL ARTÍCULO. EL SCRIPT FRENA ANTES
           SI FALTA (LA PINZA DE DOAJ) -->
      <fullTextUrl format="html">
        <xsl:value-of select="normalize-space(($am/*:self-uri[@content-type = 'pagina'])[1]/@xlink:href)"/>
      </fullTextUrl>

      <!-- PALABRAS CLAVE: UN keywords POR IDIOMA, CON LAS DE TODOS LOS
           GRUPOS DE ESE IDIOMA (DEL AUTOR Y DE VOCABULARIO), SIN REPETIR. UN
           GRUPO SIN xml:lang ES DEL IDIOMA DEL ARTÍCULO -->
      <xsl:for-each-group select="$am/*:kwd-group/*:kwd[normalize-space()]"
                          group-by="gbd:idioma(if (../@xml:lang) then ../@xml:lang else $lang)">
        <keywords>
          <xsl:if test="current-grouping-key() != ''">
            <xsl:attribute name="language" select="current-grouping-key()"/>
          </xsl:if>
          <xsl:for-each select="distinct-values(current-group()/gbd:texto(.))">
            <keyword><xsl:value-of select="."/></keyword>
          </xsl:for-each>
        </keywords>
      </xsl:for-each-group>
    </record>
  </xsl:template>

</xsl:stylesheet>
