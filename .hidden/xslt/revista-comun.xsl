<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  revista-comun.xsl
  ============================================================
  PROPÓSITO : LOS TEXTOS DEL ARTÍCULO DE REVISTA QUE COMPARTEN EL PDF
              (jats-a-latex-articulo.xsl) Y EL EPUB (jats-a-epub-
              articulo.xsl): LOS RÓTULOS POR IDIOMA, LOS MESES, LOS
              TIPOS DE ARTÍCULO Y LOS DATOS EN TEXTO (FECHA, NOMBRE,
              AFILIACIÓN). ESTABAN EN LA HOJA DEL PDF; SE MUDARON ACÁ EN
              E2 (14/11/2026) PARA QUE EL EPUB DIGA LO MISMO QUE EL PDF
              (SC-31: EL PDF ES LA REFERENCIA).
  USO       : SE INCLUYE CON xsl:include. DEVUELVE TEXTO SIN ESCAPAR:
              CADA HOJA LO ESCAPA PARA SU SALIDA (f:latex EN EL PDF; EN
              XHTML LO HACE EL SERIALIZADOR).
  IDIOMA    : EL DE LOS RÓTULOS SON LAS DOS LETRAS DEL CÓDIGO, SI LA
              TABLA LAS TIENE (es, en, pt, fr); SI NO, CASTELLANO
              (gbrc:lang).
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbrc="urn:gbpublisher:revista-comun"
  exclude-result-prefixes="xs gbrc">

  <!-- ============================================================ -->
  <!-- RÓTULOS POR IDIOMA. FUERA DE es, en, pt Y fr, EN CASTELLANO  -->
  <!-- ============================================================ -->
  <xsl:variable name="gbrc:rotulos" as="element()*">
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
    <r k="notas" es="Notas" en="Notes" pt="Notas" fr="Notes"/>
    <r k="referencias" es="Referencias" en="References" pt="Referências" fr="Références"/>
    <r k="declaraciones" es="Declaraciones" en="Declarations" pt="Declarações" fr="Déclarations"/>
    <r k="contribuciones" es="Contribuciones de autoría (CRediT)" en="Author contributions (CRediT)" pt="Contribuições de autoria (CRediT)" fr="Contributions des auteurs (CRediT)"/>
    <r k="financiamiento" es="Financiamiento" en="Funding" pt="Financiamento" fr="Financement"/>
    <r k="coi" es="Conflicto de intereses" en="Conflict of interest" pt="Conflito de interesses" fr="Conflit d’intérêts"/>
    <r k="datos" es="Disponibilidad de datos" en="Data availability" pt="Disponibilidade de dados" fr="Disponibilité des données"/>
    <!-- LAS PRELIMINARES DEL NÚMERO (E3). EN CASTELLANO SON LOS DEL
         CONTRATO DE REVISTA DEL PDF (\gbrotulotapa, \gbrotulolegal,
         \gbrotulosumario, \gbrotulovolumen, \gbrotulonumero,
         \gbrotulosuplemento, \gblegalissn…) -->
    <r k="tapa" es="Tapa" en="Cover" pt="Capa" fr="Couverture"/>
    <r k="legal" es="Página legal" en="Copyright page" pt="Página de créditos" fr="Page de copyright"/>
    <r k="sumario" es="Sumario" en="Contents" pt="Sumário" fr="Sommaire"/>
    <r k="volumen" es="Vol." en="Vol." pt="Vol." fr="Vol."/>
    <r k="numero" es="n.º" en="No." pt="n.º" fr="n°"/>
    <r k="suplemento" es="supl." en="Suppl." pt="supl." fr="suppl."/>
    <r k="issn" es="ISSN" en="ISSN" pt="ISSN" fr="ISSN"/>
    <r k="eissn" es="e-ISSN" en="e-ISSN" pt="e-ISSN" fr="e-ISSN"/>
  </xsl:variable>

  <xsl:variable name="gbrc:meses" as="element()*">
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

  <xsl:variable name="gbrc:tipos" as="element()*">
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

  <!-- ============================================
       Función   : gbrc:lang
       Propósito : El idioma de los rótulos para un código: sus dos
                   letras si la tabla las tiene; si no, es
       Parámetros: codigo As xs:string — código BCP 47 (es, pt-BR)
       Retorna   : xs:string — es, en, pt o fr
       ============================================ -->
  <xsl:function name="gbrc:lang" as="xs:string">
    <xsl:param name="codigo" as="xs:string"/>
    <xsl:sequence select="let $l := lower-case(substring($codigo, 1, 2))
                          return if ($l = ('es', 'en', 'pt', 'fr')) then $l else 'es'"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:rotulo
       Propósito : El rótulo de una clave en un idioma; sin él, castellano
       Parámetros: clave As xs:string — la @k de la tabla
                   lang As xs:string — el de gbrc:lang
       Retorna   : xs:string — el rótulo, sin escapar
       ============================================ -->
  <xsl:function name="gbrc:rotulo" as="xs:string">
    <xsl:param name="clave" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="r" select="$gbrc:rotulos[@k = $clave]"/>
    <xsl:sequence select="string(($r/@*[local-name() = $lang], $r/@es)[1])"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:tipo
       Propósito : El nombre del tipo de artículo en un idioma; un tipo
                   fuera de la tabla, tal cual
       Parámetros: tipo As xs:string — article/@article-type
                   lang As xs:string — el de gbrc:lang
       Retorna   : xs:string — sin escapar
       ============================================ -->
  <xsl:function name="gbrc:tipo" as="xs:string">
    <xsl:param name="tipo" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="t" select="$gbrc:tipos[@t = $tipo]"/>
    <xsl:sequence select="if ($t) then string(($t/@*[local-name() = $lang], $t/@es)[1]) else $tipo"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:fecha
       Propósito : Una fecha de JATS con el mes en letras («1 de marzo
                   de 2026», «1 March 2026»)
       Parámetros: d As element() — date o pub-date (day, month, year)
                   lang As xs:string — el de gbrc:lang
       Retorna   : xs:string — la fecha; solo lo que haya de ella
       ============================================ -->
  <xsl:function name="gbrc:fecha" as="xs:string">
    <xsl:param name="d" as="element()"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="dia" select="if ($d/day castable as xs:integer) then string(xs:integer($d/day)) else ''"/>
    <xsl:variable name="mes" select="if ($d/month castable as xs:integer)
      then string($gbrc:meses[xs:integer($d/month)]/@*[local-name() = $lang]) else ''"/>
    <xsl:variable name="anio" select="normalize-space($d/year)"/>
    <xsl:sequence select="
      if ($lang = ('es', 'pt'))
      then string-join(($dia[. ne ''], $mes[. ne ''], $anio), ' de ')
      else string-join(($dia, $mes, $anio)[. ne ''], ' ')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:nombre
       Propósito : El nombre completo de un contribuyente, persona o
                   colectivo
       Parámetros: c As element() — contrib
       Retorna   : xs:string — sin escapar
       ============================================ -->
  <xsl:function name="gbrc:nombre" as="xs:string">
    <xsl:param name="c" as="element()"/>
    <xsl:sequence select="normalize-space(
      if ($c/name) then string-join(($c/name/given-names, $c/name/surname, $c/name/suffix), ' ')
      else string($c/collab))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:afiliacion
       Propósito : Una afiliación en una línea: institución,
                   dependencia, ciudad, país (Redalyc 4.8, Latindex 13)
       Parámetros: a As element() — aff
       Retorna   : xs:string — sin escapar
       ============================================ -->
  <xsl:function name="gbrc:afiliacion" as="xs:string">
    <xsl:param name="a" as="element()"/>
    <xsl:sequence select="string-join((
      $a//institution[@content-type = 'orgname'],
      $a//institution[starts-with(@content-type, 'orgdiv')],
      $a//institution[not(@content-type)],
      $a/city, $a/country) ! normalize-space(.)[. ne ''], ', ')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- EL NÚMERO, DESDE EL VOLCADO (numero-datos). LOS COMPARTEN EL -->
  <!-- MAESTRO DEL PDF (numero-maestro-latex.xsl) Y LAS PRELIMINARES -->
  <!-- DEL EPUB (numero-a-epub.xsl), DESDE E3 (14/11/2026)          -->
  <!-- ============================================================ -->

  <!-- ============================================
       Función   : gbrc:conjuncion
       Propósito : Lo que va antes del último nombre de una lista, según
                   el idioma principal de la revista. En castellano, «e»
                   ante el sonido i (la regla de m_PrimerasLibro.Conjuncion,
                   DPD «y»): «Pérez e Ibáñez», pero «Ana y Iolanda». Un
                   idioma que esta hoja no conoce separa con coma
       Parámetros: idioma As xs:string — código de la revista (es, en…)
                   siguiente As xs:string — el último nombre
       Retorna   : xs:string — la conjunción con sus espacios
       Nota      : ERA gbm:conjuncion DE numero-maestro-latex.xsl, SIN
                   CAMBIOS
       ============================================ -->
  <xsl:function name="gbrc:conjuncion" as="xs:string">
    <xsl:param name="idioma" as="xs:string"/>
    <xsl:param name="siguiente" as="xs:string"/>
    <xsl:variable name="base" select="substring-before(concat($idioma, '-'), '-')"/>
    <!-- LA h NO SUENA -->
    <xsl:variable name="palabra" select="replace(normalize-space($siguiente), '^[hH]', '')"/>
    <xsl:variable name="primera" select="substring($palabra, 1, 1)"/>
    <xsl:variable name="segunda" select="substring($palabra, 2, 1)"/>
    <xsl:choose>
      <xsl:when test="$base eq 'es'">
        <xsl:choose>
          <xsl:when test="not($primera = ('i', 'I', 'í', 'Í'))"> y </xsl:when>
          <!-- i SIN TILDE ANTE VOCAL: DIPTONGO, «y» -->
          <xsl:when test="$primera = ('i', 'I') and contains('aeiouáéíóúüAEIOUÁÉÍÓÚÜ', $segunda) and $segunda ne ''"> y </xsl:when>
          <xsl:otherwise> e </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$base = ('pt', 'gl', 'it')"> e </xsl:when>
      <xsl:when test="$base eq 'en'"> and </xsl:when>
      <xsl:when test="$base eq 'fr'"> et </xsl:when>
      <xsl:otherwise>, </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:lista
       Propósito : Une nombres: «A», «A y B», «A, B y C»
       Parámetros: nombres As xs:string* — en orden, sin escapar
                   idioma As xs:string — código de la revista
       Retorna   : xs:string — sin escapar
       Nota      : EL PDF NO LA USA: SU gbm:lista ESCAPA CADA NOMBRE POR
                   SEPARADO. LA CONJUNCIÓN ES LA MISMA
       ============================================ -->
  <xsl:function name="gbrc:lista" as="xs:string">
    <xsl:param name="nombres" as="xs:string*"/>
    <xsl:param name="idioma" as="xs:string"/>
    <xsl:variable name="n" select="count($nombres)"/>
    <xsl:sequence select="string-join(
      for $i in 1 to $n return concat(
        if ($i eq 1) then ''
        else if ($i eq $n) then gbrc:conjuncion($idioma, $nombres[$i])
        else ', ',
        $nombres[$i]), '')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:persona
       Propósito : «Nombre Apellidos» de una persona del volcado, o el
                   nombre del colectivo
       Parámetros: e As element() — <persona>, <miembro> o <contribuyente>
       Retorna   : xs:string — sin escapar
       Nota      : ERA gbm:persona DE numero-maestro-latex.xsl, SIN CAMBIOS
       ============================================ -->
  <xsl:function name="gbrc:persona" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="p" select="($e/persona, $e)[1]"/>
    <xsl:sequence select="if ($e/colectivo) then normalize-space($e/colectivo)
      else normalize-space(string-join(($p/nombre, $p/apellidos) ! normalize-space(.), ' '))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:titulo-idioma
       Propósito : El título de una sección o un dossier en el idioma
                   principal; si no lo tiene, el primero
       Parámetros: e As element()? — la sección o el dossier
                   idioma As xs:string — código principal
       Retorna   : xs:string — sin escapar; vacío si no hay
       Nota      : ERA gbm:titulo-idioma DE numero-maestro-latex.xsl
       ============================================ -->
  <xsl:function name="gbrc:titulo-idioma" as="xs:string">
    <xsl:param name="e" as="element()?"/>
    <xsl:param name="idioma" as="xs:string"/>
    <xsl:sequence select="normalize-space(string(($e/titulo[@idioma eq $idioma], $e/titulo)[1]))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:tramo-sumario
       Propósito : La clave del tramo del sumario de un artículo: un
                   tramo es una serie seguida del mismo dossier o, sin
                   dossier, de la misma sección (group-adjacent)
       Parámetros: a As element() — <articulo> del volcado
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbrc:tramo-sumario" as="xs:string">
    <xsl:param name="a" as="element()"/>
    <xsl:sequence select="if ($a/@dossier) then concat('d', $a/@dossier) else concat('s', $a/@seccion)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:encabezado-tramo
       Propósito : El encabezado de un tramo del sumario: «Sección.
                   Dossier» para un dossier; el título de la sección si
                   no; vacío si no hay ninguno
       Parámetros: d As element() — numero-datos
                   primero As element() — el primer artículo del tramo
                   principal As xs:string — idioma principal
       Retorna   : xs:string — sin escapar
       ============================================ -->
  <xsl:function name="gbrc:encabezado-tramo" as="xs:string">
    <xsl:param name="d" as="element()"/>
    <xsl:param name="primero" as="element()"/>
    <xsl:param name="principal" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$primero/@dossier">
        <xsl:variable name="dos" select="$d/dossier[@id eq $primero/@dossier]"/>
        <xsl:variable name="sec" select="gbrc:titulo-idioma($d/seccion[@codigo eq $dos/@seccion], $principal)"/>
        <xsl:sequence select="normalize-space(string-join(($sec, gbrc:titulo-idioma($dos, $principal))[. ne ''], '. '))"/>
      </xsl:when>
      <xsl:when test="$primero/@seccion">
        <xsl:sequence select="normalize-space(gbrc:titulo-idioma($d/seccion[@codigo eq $primero/@seccion], $principal))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="''"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ============================================
       Función   : gbrc:identificacion
       Propósito : «Vol. 3, n.º 2, noviembre de 2026» con lo que haya: la
                   misma composición que \gbidentificacionnumero del
                   contrato de revista del PDF (5.2)
       Parámetros: d As element() — numero-datos
                   lang As xs:string — el de gbrc:lang
       Retorna   : xs:string — sin escapar
       ============================================ -->
  <xsl:function name="gbrc:identificacion" as="xs:string">
    <xsl:param name="d" as="element()"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="n" select="$d/numero"/>
    <xsl:variable name="rotulo" select="(normalize-space($d/revista/@rotulo-volumen)[. ne ''], gbrc:rotulo('volumen', $lang))[1]"/>
    <xsl:variable name="mes" select="if ($n/@mes castable as xs:integer and xs:integer($n/@mes) = 1 to 12)
      then string($gbrc:meses[xs:integer($n/@mes)]/@*[local-name() = $lang]) else ''"/>
    <xsl:variable name="anio" select="normalize-space($n/@anio)"/>
    <xsl:sequence select="string-join((
      (normalize-space($n/@volumen)[. ne ''] ! concat($rotulo, '&#160;', .)),
      (normalize-space($n/@numero)[. ne ''] ! concat(gbrc:rotulo('numero', $lang), '&#160;', .)),
      (normalize-space($n/@suplemento)[. ne ''] ! concat(gbrc:rotulo('suplemento', $lang), '&#160;', .)),
      ($anio[. ne ''] ! (if ($mes eq '') then .
                         else if ($lang = ('es', 'pt')) then concat($mes, ' de ', .)
                         else concat($mes, ' ', .)))
      ), ', ')"/>
  </xsl:function>

</xsl:stylesheet>
