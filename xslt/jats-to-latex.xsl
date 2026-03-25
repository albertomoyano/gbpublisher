<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-to-latex.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : TRANSFORMA EL CANÓNICO JATS 1.4 (c-*.xml)
                   EN UN FRAGMENTO LATEX DEL CUERPO DEL
                   ARTÍCULO. LA SALIDA NO ES UN DOCUMENTO
                   COMPLETO: SIN PREÁMBULO NI \begin{document}.
                   EL ENSAMBLADO FINAL LO REALIZA EnsamblarTeX()
                   EN EL MÓDULO m_XML DE GBPUBLISHER.
  MOTOR          : LuaLaTeX (compilación posterior al ensamblado)
  ENTRADA        : {proyecto}/jats/c-{base}.xml
  SALIDA         : {proyecto}/latex/body-{base}.tex
  DEPENDENCIAS   :
    f:latex()      — función de escape de caracteres especiales
    f:babel-lang() — mapeo ISO 639-1 → nombre de idioma babel
  ============================================================
  ESTRUCTURA DEL FRAGMENTO GENERADO:
    1. \renewcommand de macros de metadatos
    2. Título a ancho completo (184mm) + título traducido
    3. Bloque lateral de metadatos (posición absoluta, marginpar)
    4. Resúmenes (\begin{abstract}...) con otherlanguage
    5. Palabras clave (\noindent\textbf{...})
    6. Separador visual (\rule)
    7. Cuerpo del artículo (\section, \p, figuras, tablas...)
    8. Agradecimientos y apéndices (back sin ref-list)
  ============================================================
  CONVENCIÓN DE PREFIJOS rid ↔ id EN EL CANÓNICO:
    CITAS: xref[@ref-type='bibr']/@rid = 'bib-{citekey}'
           → \cite{citekey}  (se quita el prefijo bib-)
    FIGURAS/TABLAS: xref/@rid = @id del elemento objetivo
           → \ref{id}
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:f="urn:gbpublisher:functions"
  exclude-result-prefixes="xs xlink mml f">

  <!-- ============================================================ -->
  <!-- SALIDA: TEXTO PLANO, UTF-8                                   -->
  <!-- method=text: LATEX NO ES XML                                 -->
  <!-- ============================================================ -->
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:strip-space elements="*"/>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:latex                                            -->
  <!-- PROPÓSITO: ESCAPA CARACTERES ESPECIALES LATEX EN TEXTO       -->
  <!--            PLANO PROVENIENTE DEL XML.                        -->
  <!--            ORDEN CRÍTICO: BARRA INVERSA PRIMERO PARA NO      -->
  <!--            DOBLE-ESCAPAR LOS PREFIJOS INSERIDOS DESPUÉS.     -->
  <!-- PARÁMETROS: t — cadena de texto a escapar                    -->
  <!-- RETORNA  : cadena con escapes LaTeX aplicados                -->
  <!-- ============================================================ -->
  <xsl:function name="f:latex" as="xs:string">
    <xsl:param name="t" as="xs:string"/>

    <!-- 1. BARRA INVERSA (OBLIGATORIAMENTE PRIMERA)  -->
    <!-- PATRON '\\' = XPath regex \\ = un literal \         -->
    <!-- REEMPLAZO '\\textbackslash{}' = Java repl → \textbackslash{} -->
    <xsl:variable name="s1"  select="replace($t,   '\\',    '\\textbackslash{}')"/>

    <!-- 2. LLAVES  -->
    <!-- PATRON '\{' = regex \{ = literal {                  -->
    <!-- REEMPLAZO '\\{' = Java repl \\{ → \{               -->
    <xsl:variable name="s2"  select="replace($s1,  '\{',    '\\{')"/>
    <xsl:variable name="s3"  select="replace($s2,  '\}',    '\\}')"/>

    <!-- 3. DÓLAR  -->
    <!-- REEMPLAZO '\\\$' = Java repl \\(bslash) + \$(dolar) → \$ -->
    <xsl:variable name="s4"  select="replace($s3,  '\$',    '\\\$')"/>

    <!-- 4. PORCENTAJE  -->
    <xsl:variable name="s5"  select="replace($s4,  '%',     '\\%')"/>

    <!-- 5. AMPERSAND  -->
    <!-- &amp; EN ATRIBUTO XML = & EN XPATH = patrón literal & -->
    <xsl:variable name="s6"  select="replace($s5,  '&amp;', '\\&amp;')"/>

    <!-- 6. ALMOHADILLA  -->
    <xsl:variable name="s7"  select="replace($s6,  '#',     '\\#')"/>

    <!-- 7. GUIÓN BAJO  -->
    <xsl:variable name="s8"  select="replace($s7,  '_',     '\\_')"/>

    <!-- 8. CARET  -->
    <!-- PATRON '\^' = regex \^ = literal ^ (fuera de clase []) -->
    <xsl:variable name="s9"  select="replace($s8,  '\^',    '\\textasciicircum{}')"/>

    <!-- 9. TILDE  -->
    <xsl:variable name="s10" select="replace($s9,  '~',     '\\textasciitilde{}')"/>

    <xsl:value-of select="$s10"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:babel-lang                                       -->
  <!-- PROPÓSITO: CONVIERTE CÓDIGO ISO 639-1 AL NOMBRE DE IDIOMA   -->
  <!--            RECONOCIDO POR EL PAQUETE babel DE LATEX          -->
  <!-- PARÁMETROS: lang — código ISO 639-1 (es, en, pt, fr…)       -->
  <!-- RETORNA  : string para usar en \begin{otherlanguage}{...}    -->
  <!-- ============================================================ -->
  <xsl:function name="f:babel-lang" as="xs:string">
    <xsl:param name="lang" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$lang = 'es'">spanish</xsl:when>
      <xsl:when test="$lang = 'en'">english</xsl:when>
      <xsl:when test="$lang = 'pt'">portuguese</xsl:when>
      <xsl:when test="$lang = 'fr'">french</xsl:when>
      <xsl:when test="$lang = 'de'">german</xsl:when>
      <xsl:when test="$lang = 'it'">italian</xsl:when>
      <xsl:when test="$lang = 'ca'">catalan</xsl:when>
      <xsl:otherwise>spanish</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- VARIABLE GLOBAL: $xmlLang                                    -->
  <!-- IDIOMA PRINCIPAL DEL ARTÍCULO EN CASCADA (CONSIGNA 6):      -->
  <!--   1. @xml:lang EN EL ELEMENTO RAÍZ <article>                -->
  <!--   2. custom-meta[xml-lang] INYECTADO POR GenerarFrontXML()  -->
  <!--   3. FALLBACK: 'es'                                          -->
  <!-- ============================================================ -->
  <xsl:variable name="xmlLang" as="xs:string">
    <xsl:choose>
      <xsl:when test="normalize-space(/article/@xml:lang) != ''">
        <xsl:value-of select="normalize-space(/article/@xml:lang)"/>
      </xsl:when>
      <xsl:when test="/article/front/article-meta/
                      custom-meta-group/
                      custom-meta[meta-name = 'xml-lang']/
                      meta-value">
        <xsl:value-of select="normalize-space(
          /article/front/article-meta/
          custom-meta-group/
          custom-meta[meta-name = 'xml-lang']/
          meta-value)"/>
      </xsl:when>
      <xsl:otherwise>es</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- ============================================================ -->
  <!--                                                              -->
  <!--                   PLANTILLAS RAÍZ                           -->
  <!--                                                              -->
  <!-- ============================================================ -->

  <xsl:template match="/">
    <xsl:apply-templates select="article"/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLA: article                                           -->
  <!-- CONTROLA EL ORDEN DE EMISIÓN DEL FRAGMENTO COMPLETO         -->
  <!-- ============================================================ -->
  <xsl:template match="article">

    <!-- SELECCIONAR IDIOMA PRINCIPAL AL INICIO DEL FRAGMENTO -->
    <xsl:text>\selectlanguage{</xsl:text>
    <xsl:value-of select="f:babel-lang($xmlLang)"/>
    <xsl:text>}&#10;&#10;</xsl:text>

    <!-- 1. MACROS DE METADATOS (\renewcommand)  -->
    <xsl:call-template name="emitir-macros-metadatos"/>

    <!-- NUMERACIÓN DE PÁGINA DESDE fpage + ESTILO PRIMERA PÁGINA  -->
    <!-- AMBAS INSTRUCCIONES VAN DESPUÉS DE LOS \renewcommand PARA -->
    <!-- QUE \articulotipo YA ESTÉ DISPONIBLE EN EL SHIPOUT        -->
     <!-- \setcounter REQUIERE NÚMERO LITERAL, NO MACRO              -->
    <!-- SE USA fpage DIRECTAMENTE; SI NO EXISTE O NO ES NUMÉRICO   -->
    <!-- SE USA 1 COMO VALOR POR DEFECTO                            -->
    <xsl:variable name="fpageNum"
      select="normalize-space(front/article-meta/fpage)"/>
    <xsl:text>\setcounter{page}{</xsl:text>
    <xsl:choose>
      <xsl:when test="$fpageNum != '' and string(number($fpageNum)) != 'NaN'">
        <xsl:value-of select="$fpageNum"/>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
    <xsl:text>}&#10;</xsl:text>
    <xsl:text>\thispagestyle{firstpage}&#10;&#10;</xsl:text>

    <!-- 2. TÍTULO A ANCHO COMPLETO (184mm) + TÍTULO TRADUCIDO  -->
    <xsl:call-template name="emitir-titulo-ancho"/>

    <!-- 3. BLOQUE LATERAL DE METADATOS (POSICIÓN ABSOLUTA EN MARGINPAR) -->
    <xsl:call-template name="emitir-bloque-lateral"/>

    <!-- 4. RESÚMENES (PRINCIPAL Y TRADUCCIONES) — SOLO SI EXISTEN  -->
    <xsl:apply-templates select="front/article-meta/abstract |
                                 front/article-meta/trans-abstract"/>

    <!-- 5. PALABRAS CLAVE POR IDIOMA — SOLO SI EXISTEN  -->
    <xsl:apply-templates select="front/article-meta/kwd-group"/>

    <!-- SEPARADOR ENTRE METADATOS Y CUERPO  -->
    <xsl:if test="body/sec or body/p">
      <xsl:text>&#10;\bigskip&#10;</xsl:text>
      <xsl:text>\noindent\rule{\linewidth}{0.4pt}&#10;</xsl:text>
      <xsl:text>\bigskip&#10;&#10;</xsl:text>
    </xsl:if>

    <!-- 6. CUERPO DEL ARTÍCULO  -->
    <xsl:apply-templates select="body"/>

    <!-- 7. AGRADECIMIENTOS  -->
    <xsl:apply-templates select="back/ack"/>

    <!-- 8. APÉNDICES  -->
    <xsl:apply-templates select="back/app-group"/>

    <!-- NOTA: back/ref-list ES OMITIDO INTENCIONALMENTE.           -->
    <!-- \printbibliography LO INSERTA EnsamblarTeX() EN m_XML.     -->

  </xsl:template>

  <!-- ============================================================ -->
  <!--                                                              -->
  <!--                   FRONT: METADATOS                          -->
  <!--                                                              -->
  <!-- ============================================================ -->

  <!-- FRONT: SUPRIMIDO COMO ELEMENTO DIRECTO — SE PROCESA          -->
  <!-- EXCLUSIVAMENTE VÍA NAMED TEMPLATES Y apply-templates SELECT  -->
  <xsl:template match="front"/>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-macros-metadatos                      -->
  <!-- PROPÓSITO: \renewcommand PARA CADA MACRO DEL PREÁMBULO.     -->
  <!--            PERMITE A TEMPLATES PERSONALIZADOS ACCEDER A      -->
  <!--            LOS METADATOS DEL ARTÍCULO VÍA MACROS.           -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-macros-metadatos">
    <xsl:variable name="meta" select="front/article-meta"/>

    <!-- IDIOMA PRINCIPAL -->
    <xsl:text>\renewcommand{\articuloidiomaxml}{</xsl:text>
    <xsl:value-of select="$xmlLang"/>
    <xsl:text>}&#10;</xsl:text>

    <!-- TÍTULO PRINCIPAL -->
    <xsl:if test="normalize-space($meta/title-group/article-title) != ''">
      <xsl:text>\renewcommand{\articulotitulo}{</xsl:text>
      <xsl:value-of select="f:latex(
        normalize-space($meta/title-group/article-title))"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- SUBTÍTULO (SOLO SI EXISTE) -->
    <xsl:if test="normalize-space($meta/title-group/subtitle) != ''">
      <xsl:text>\renewcommand{\articulosubtitulo}{</xsl:text>
      <xsl:value-of select="f:latex(
        normalize-space($meta/title-group/subtitle))"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- AUTORES: LISTA SEPARADA POR COMA -->
    <xsl:variable name="listaAutores">
      <xsl:for-each
        select="$meta/contrib-group/contrib[@contrib-type='author']">
        <xsl:if test="position() > 1">, </xsl:if>
        <xsl:value-of select="normalize-space(
          concat(name/given-names, ' ', name/surname))"/>
      </xsl:for-each>
    </xsl:variable>
    <xsl:if test="normalize-space($listaAutores) != ''">
      <xsl:text>\renewcommand{\articuloautores}{</xsl:text>
      <xsl:value-of select="f:latex(normalize-space($listaAutores))"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- DOI (SIN ESCAPE: LOS DOI NO CONTIENEN CARACTERES ESPECIALES LATEX) -->
    <xsl:if test="normalize-space($meta/article-id[@pub-id-type='doi']) != ''">
      <xsl:text>\renewcommand{\articulodoi}{</xsl:text>
      <xsl:value-of select="normalize-space(
        $meta/article-id[@pub-id-type='doi'])"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- TIPO DE ARTÍCULO: upper-case() DE XPATH 3.0 EVITA PROBLEMAS   -->
    <!-- DE \MakeUppercase CON ACENTOS EN EL PARBOX DEL HEADER         -->
    <xsl:variable name="articleType"
      select="normalize-space(/article/@article-type)"/>
    <xsl:if test="$articleType != ''">
      <xsl:variable name="tipoTraducido">
        <xsl:choose>
          <xsl:when test="$xmlLang = 'es'">
            <xsl:choose>
              <xsl:when test="$articleType = 'research-article'">Artículo de investigación</xsl:when>
              <xsl:when test="$articleType = 'review-article'">Artículo de revisión</xsl:when>
              <xsl:when test="$articleType = 'editorial'">Editorial</xsl:when>
              <xsl:when test="$articleType = 'book-review'">Reseña</xsl:when>
              <xsl:when test="$articleType = 'letter'">Carta</xsl:when>
              <xsl:when test="$articleType = 'case-report'">Reporte de caso</xsl:when>
              <xsl:when test="$articleType = 'correction'">Corrección</xsl:when>
              <xsl:when test="$articleType = 'obituary'">Obituario</xsl:when>
              <xsl:when test="$articleType = 'systematic-review'">Revisión sistemática</xsl:when>
              <xsl:otherwise><xsl:value-of select="$articleType"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$xmlLang = 'en'">
            <xsl:choose>
              <xsl:when test="$articleType = 'research-article'">Research article</xsl:when>
              <xsl:when test="$articleType = 'review-article'">Review article</xsl:when>
              <xsl:when test="$articleType = 'editorial'">Editorial</xsl:when>
              <xsl:when test="$articleType = 'book-review'">Book review</xsl:when>
              <xsl:when test="$articleType = 'letter'">Letter</xsl:when>
              <xsl:when test="$articleType = 'case-report'">Case report</xsl:when>
              <xsl:when test="$articleType = 'correction'">Correction</xsl:when>
              <xsl:when test="$articleType = 'obituary'">Obituary</xsl:when>
              <xsl:when test="$articleType = 'systematic-review'">Systematic review</xsl:when>
              <xsl:otherwise><xsl:value-of select="$articleType"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$xmlLang = 'pt'">
            <xsl:choose>
              <xsl:when test="$articleType = 'research-article'">Artigo de pesquisa</xsl:when>
              <xsl:when test="$articleType = 'review-article'">Artigo de revisão</xsl:when>
              <xsl:when test="$articleType = 'editorial'">Editorial</xsl:when>
              <xsl:when test="$articleType = 'book-review'">Resenha</xsl:when>
              <xsl:when test="$articleType = 'letter'">Carta</xsl:when>
              <xsl:when test="$articleType = 'case-report'">Relato de caso</xsl:when>
              <xsl:when test="$articleType = 'correction'">Correção</xsl:when>
              <xsl:when test="$articleType = 'obituary'">Obituário</xsl:when>
              <xsl:when test="$articleType = 'systematic-review'">Revisão sistemática</xsl:when>
              <xsl:otherwise><xsl:value-of select="$articleType"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$xmlLang = 'fr'">
            <xsl:choose>
              <xsl:when test="$articleType = 'research-article'">Article de recherche</xsl:when>
              <xsl:when test="$articleType = 'review-article'">Article de synthèse</xsl:when>
              <xsl:when test="$articleType = 'editorial'">Éditorial</xsl:when>
              <xsl:when test="$articleType = 'book-review'">Compte rendu</xsl:when>
              <xsl:when test="$articleType = 'letter'">Lettre</xsl:when>
              <xsl:when test="$articleType = 'case-report'">Rapport de cas</xsl:when>
              <xsl:when test="$articleType = 'correction'">Correction</xsl:when>
              <xsl:when test="$articleType = 'obituary'">Nécrologie</xsl:when>
              <xsl:when test="$articleType = 'systematic-review'">Revue systématique</xsl:when>
              <xsl:otherwise><xsl:value-of select="$articleType"/></xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="$articleType"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:text>\renewcommand{\articulotipo}{</xsl:text>
      <xsl:value-of select="upper-case($tipoTraducido)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- MACROS PARA EL HEADER DE PÁGINAS 2+ -->
    <!-- NOMBRE DE REVISTA -->
    <xsl:variable name="revNombre"
      select="normalize-space(front/journal-meta/journal-title-group/journal-title)"/>
    <xsl:if test="$revNombre != ''">
      <xsl:text>\renewcommand{\articulorevista}{</xsl:text>
      <xsl:value-of select="f:latex($revNombre)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- e-ISSN -->
    <xsl:if test="normalize-space(front/journal-meta/issn[@pub-type='epub']) != ''">
      <xsl:text>\renewcommand{\articuloissne}{</xsl:text>
      <xsl:value-of select="normalize-space(front/journal-meta/issn[@pub-type='epub'])"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- VOLUMEN -->
    <xsl:if test="normalize-space(front/article-meta/volume) != ''">
      <xsl:text>\renewcommand{\articulovolumen}{</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/volume)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- NÚMERO -->
    <xsl:if test="normalize-space(front/article-meta/issue) != ''">
      <xsl:text>\renewcommand{\articulonumero}{</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/issue)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- FECHA: NOMBRE DEL MES EN MAYÚSCULAS + AÑO -->
    <xsl:variable name="pubMes"
      select="normalize-space(front/article-meta/pub-date/month)"/>
    <xsl:variable name="pubAnio"
      select="normalize-space(front/article-meta/pub-date/year)"/>
    <xsl:if test="$pubAnio != ''">
      <xsl:text>\renewcommand{\articulofecha}{</xsl:text>
      <xsl:if test="$pubMes != ''">
        <xsl:choose>
          <xsl:when test="$xmlLang = 'en'">
            <xsl:choose>
              <xsl:when test="$pubMes = '1'">JANUARY</xsl:when>
              <xsl:when test="$pubMes = '2'">FEBRUARY</xsl:when>
              <xsl:when test="$pubMes = '3'">MARCH</xsl:when>
              <xsl:when test="$pubMes = '4'">APRIL</xsl:when>
              <xsl:when test="$pubMes = '5'">MAY</xsl:when>
              <xsl:when test="$pubMes = '6'">JUNE</xsl:when>
              <xsl:when test="$pubMes = '7'">JULY</xsl:when>
              <xsl:when test="$pubMes = '8'">AUGUST</xsl:when>
              <xsl:when test="$pubMes = '9'">SEPTEMBER</xsl:when>
              <xsl:when test="$pubMes = '10'">OCTOBER</xsl:when>
              <xsl:when test="$pubMes = '11'">NOVEMBER</xsl:when>
              <xsl:when test="$pubMes = '12'">DECEMBER</xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$xmlLang = 'pt'">
            <xsl:choose>
              <xsl:when test="$pubMes = '1'">JANEIRO</xsl:when>
              <xsl:when test="$pubMes = '2'">FEVEREIRO</xsl:when>
              <xsl:when test="$pubMes = '3'">MARÇO</xsl:when>
              <xsl:when test="$pubMes = '4'">ABRIL</xsl:when>
              <xsl:when test="$pubMes = '5'">MAIO</xsl:when>
              <xsl:when test="$pubMes = '6'">JUNHO</xsl:when>
              <xsl:when test="$pubMes = '7'">JULHO</xsl:when>
              <xsl:when test="$pubMes = '8'">AGOSTO</xsl:when>
              <xsl:when test="$pubMes = '9'">SETEMBRO</xsl:when>
              <xsl:when test="$pubMes = '10'">OUTUBRO</xsl:when>
              <xsl:when test="$pubMes = '11'">NOVEMBRO</xsl:when>
              <xsl:when test="$pubMes = '12'">DEZEMBRO</xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="$pubMes = '1'">ENERO</xsl:when>
              <xsl:when test="$pubMes = '2'">FEBRERO</xsl:when>
              <xsl:when test="$pubMes = '3'">MARZO</xsl:when>
              <xsl:when test="$pubMes = '4'">ABRIL</xsl:when>
              <xsl:when test="$pubMes = '5'">MAYO</xsl:when>
              <xsl:when test="$pubMes = '6'">JUNIO</xsl:when>
              <xsl:when test="$pubMes = '7'">JULIO</xsl:when>
              <xsl:when test="$pubMes = '8'">AGOSTO</xsl:when>
              <xsl:when test="$pubMes = '9'">SEPTIEMBRE</xsl:when>
              <xsl:when test="$pubMes = '10'">OCTUBRE</xsl:when>
              <xsl:when test="$pubMes = '11'">NOVIEMBRE</xsl:when>
              <xsl:when test="$pubMes = '12'">DICIEMBRE</xsl:when>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="$pubAnio"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- PÁGINA DE INICIO PARA \setcounter{page}{...} EN EL BODY -->
    <xsl:if test="normalize-space(front/article-meta/fpage) != ''">
      <xsl:text>\renewcommand{\articulopagina}{</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/fpage)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-bloque-titulo                         -->
  <!-- PROPÓSITO: EMITE EL BLOQUE VISUAL DE TÍTULO, AUTORES Y DOI. -->
  <!--            EL XSLT EMITE CONTENIDO DIRECTO (NO DELEGA EN    -->
  <!--            LAS MACROS) PARA EVITAR \ifx\@empty EN LATEX.     -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-bloque-titulo">
    <xsl:variable name="meta"      select="front/article-meta"/>
    <xsl:variable name="titulo"    select="normalize-space($meta/title-group/article-title)"/>
    <xsl:variable name="subtitulo" select="normalize-space($meta/title-group/subtitle)"/>
    <xsl:variable name="doi"       select="normalize-space($meta/article-id[@pub-id-type='doi'])"/>

    <xsl:text>% --- BLOQUE DE TÍTULO ---&#10;</xsl:text>

    <!-- TÍTULO PRINCIPAL (obligatorio) -->
    <xsl:if test="$titulo != ''">
      <xsl:text>{\LARGE\bfseries </xsl:text>
      <xsl:value-of select="f:latex($titulo)"/>
      <xsl:text>\par}&#10;\medskip&#10;</xsl:text>
    </xsl:if>

    <!-- SUBTÍTULO (solo si existe en el canónico) -->
    <xsl:if test="$subtitulo != ''">
      <xsl:text>{\large </xsl:text>
      <xsl:value-of select="f:latex($subtitulo)"/>
      <xsl:text>\par}&#10;\medskip&#10;</xsl:text>
    </xsl:if>

    <!-- AUTORES (solo si existen) -->
    <xsl:if test="$meta/contrib-group/contrib[@contrib-type='author']">
      <xsl:text>{\normalsize </xsl:text>
      <xsl:for-each select="$meta/contrib-group/contrib[@contrib-type='author']">
        <xsl:if test="position() > 1">, </xsl:if>
        <xsl:value-of select="f:latex(normalize-space(
          concat(name/given-names, ' ', name/surname)))"/>
      </xsl:for-each>
      <xsl:text>\par}&#10;</xsl:text>
    </xsl:if>

    <!-- DOI (solo si existe) -->
    <xsl:if test="$doi != ''">
      <xsl:text>\smallskip&#10;{\small\url{https://doi.org/</xsl:text>
      <xsl:value-of select="$doi"/>
      <xsl:text>}\par}&#10;</xsl:text>
    </xsl:if>

    <xsl:text>\bigskip&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: RESÚMENES                                        -->
  <!-- ============================================================ -->

  <!-- RESUMEN PRINCIPAL Y RESÚMENES TRADUCIDOS                      -->
  <!-- AMBOS USAN \begin{abstract}: babel gestiona la etiqueta       -->
  <xsl:template match="abstract | trans-abstract">
    <xsl:variable name="lang"
      select="if (normalize-space(@xml:lang) != '')
              then normalize-space(@xml:lang)
              else $xmlLang"/>
    <xsl:text>\begin{otherlanguage}{</xsl:text>
    <xsl:value-of select="f:babel-lang($lang)"/>
    <xsl:text>}&#10;\begin{abstract}&#10;</xsl:text>
    <xsl:apply-templates select="p | sec"/>
    <xsl:text>\end{abstract}&#10;\end{otherlanguage}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- TÍTULO DEL ABSTRACT: OMITIDO — LATEX LO GENERA CON babel     -->
  <xsl:template match="abstract/title | trans-abstract/title"/>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: PALABRAS CLAVE                                   -->
  <!-- ============================================================ -->
  <xsl:template match="kwd-group">
    <xsl:variable name="lang"
      select="if (normalize-space(@xml:lang) != '')
              then normalize-space(@xml:lang)
              else $xmlLang"/>
    <xsl:text>\begin{otherlanguage}{</xsl:text>
    <xsl:value-of select="f:babel-lang($lang)"/>
    <xsl:text>}&#10;\noindent\textbf{</xsl:text>
    <!-- ETIQUETA SEGÚN IDIOMA DEL GRUPO -->
    <xsl:choose>
      <xsl:when test="$lang = 'es'">Palabras clave</xsl:when>
      <xsl:when test="$lang = 'en'">Keywords</xsl:when>
      <xsl:when test="$lang = 'pt'">Palavras-chave</xsl:when>
      <xsl:when test="$lang = 'fr'">Mots-clés</xsl:when>
      <xsl:otherwise>Palabras clave</xsl:otherwise>
    </xsl:choose>
    <xsl:text>:} </xsl:text>
    <xsl:for-each select="kwd">
      <xsl:if test="position() > 1">, </xsl:if>
      <xsl:value-of select="f:latex(normalize-space(.))"/>
    </xsl:for-each>
    <xsl:text>\par&#10;\end{otherlanguage}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!--                                                              -->
  <!--                   BODY: CUERPO                              -->
  <!--                                                              -->
  <!-- ============================================================ -->

  <xsl:template match="body">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: SECCIONES                                        -->
  <!-- PROFUNDIDAD = NÚMERO DE ANCESTROS sec (0 = sección raíz)    -->
  <!-- ============================================================ -->
  <xsl:template match="sec">
    <xsl:apply-templates/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="sec/title">
    <xsl:variable name="profundidad" select="count(ancestor::sec) - 1"/>
    <xsl:choose>
      <xsl:when test="$profundidad = 0">\section{</xsl:when>
      <xsl:when test="$profundidad = 1">\subsection{</xsl:when>
      <xsl:when test="$profundidad = 2">\subsubsection{</xsl:when>
      <xsl:otherwise>\paragraph{</xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: PÁRRAFOS                                         -->
  <!-- LA REGLA GENERAL Y LAS EXCEPCIONES POR CONTEXTO             -->
  <!-- ============================================================ -->

  <!-- PÁRRAFO GENÉRICO -->
  <xsl:template match="p">
    <xsl:apply-templates/>
    <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- EN ABSTRACT: SIN DOBLE SALTO DESPUÉS DEL ÚLTIMO PÁRRAFO     -->
  <xsl:template match="abstract/p | trans-abstract/p">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::p">
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- EN CAPTION: SIN SALTOS (VA DENTRO DE \caption{})            -->
  <xsl:template match="caption/p">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::p">
      <xsl:text> </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- EN FOOTNOTE: SIN SALTO AL FINAL                              -->
  <xsl:template match="fn/p">
    <xsl:apply-templates/>
    <xsl:if test="following-sibling::p">
      <xsl:text>\par </xsl:text>
    </xsl:if>
  </xsl:template>

  <!-- EN LIST-ITEM: CONTROLA INDENTACIÓN EN ÍTEMS MULTIPARRAFO    -->
  <xsl:template match="list-item/p">
    <xsl:apply-templates/>
    <xsl:choose>
      <xsl:when test="following-sibling::p">
        <xsl:text>&#10;&#10;  </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLA: NODOS DE TEXTO                                    -->
  <!-- TODOS PASAN POR f:latex() EXCEPTO LAS EXCEPCIONES SIGUIENTES -->
  <!-- tex-math//text()  → sin escape (LaTeX matemático nativo)     -->
  <!-- preformat//text() → sin escape (verbatim)                    -->
  <!-- ESTAS PLANTILLAS MÁS ESPECÍFICAS TIENEN MAYOR PRIORIDAD      -->
  <!-- ============================================================ -->
  <xsl:template match="text()">
    <xsl:value-of select="f:latex(.)"/>
  </xsl:template>

  <xsl:template match="tex-math//text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="preformat//text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: MARCAS EN LÍNEA (INLINE)                         -->
  <!-- ============================================================ -->

  <xsl:template match="italic | emphasis">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="bold">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="underline">
    <xsl:text>\underline{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="monospace | code">
    <xsl:text>\texttt{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="sc">
    <!-- VERSALITAS — REQUIERE fontspec EN EL PREÁMBULO (ya incluido) -->
    <xsl:text>\textsc{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="sup">
    <xsl:text>\textsuperscript{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="sub">
    <xsl:text>\textsubscript{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- CONTENEDORES TRANSPARENTES: PASAN SU CONTENIDO SIN MARCADO  -->
  <xsl:template match="named-content | styled-content">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- SALTO DE LÍNEA FORZADO                                        -->
  <xsl:template match="break">
    <xsl:text>\\&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: REFERENCIAS CRUZADAS Y CITAS                     -->
  <!-- ============================================================ -->

  <!-- CITA BIBLIOGRÁFICA                                            -->
  <!-- rid = 'bib-{citekey}' (prefijo insertado por GenerarRefListXML) -->
  <!-- SE QUITA EL PREFIJO bib- PARA OBTENER LA CLAVE REAL DEL .BIB -->
  <xsl:template match="xref[@ref-type='bibr']">
    <xsl:text>\cite{</xsl:text>
    <xsl:value-of select="substring-after(@rid, 'bib-')"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- REFERENCIA A ECUACIÓN → \eqref (INCLUYE PARÉNTESIS AUTOMÁTICAMENTE) -->
  <xsl:template match="xref[@ref-type='disp-formula']">
    <xsl:text>\eqref{</xsl:text>
    <xsl:value-of select="@rid"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- REFERENCIA A FIGURA, TABLA, SECCIÓN, NOTA AL PIE → \ref     -->
  <xsl:template match="xref[@ref-type='fig'   or
                             @ref-type='table' or
                             @ref-type='sec'   or
                             @ref-type='fn']">
    <xsl:text>\ref{</xsl:text>
    <xsl:value-of select="@rid"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- xref GENÉRICO: MOSTRAR SOLO EL TEXTO DEL ENLACE              -->
  <xsl:template match="xref">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: ENLACES EXTERNOS                                  -->
  <!-- ============================================================ -->

  <xsl:template match="ext-link[@xlink:href]">
    <xsl:text>\href{</xsl:text>
    <xsl:value-of select="@xlink:href"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- ENLACE SIN href: SOLO EL TEXTO -->
  <xsl:template match="ext-link">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- URI COMO ELEMENTO AUTÓNOMO (FRECUENTE EN REFERENCIAS) -->
  <xsl:template match="uri">
    <xsl:text>\url{</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: NOTAS AL PIE                                     -->
  <!-- ============================================================ -->

  <!-- fn EN EL CUERPO → \footnote{} INLINE                        -->
  <!-- LA NUMERACIÓN LA GESTIONA LATEX AUTOMÁTICAMENTE              -->
  <xsl:template match="fn[not(ancestor::ref-list)]">
    <xsl:text>\footnote{</xsl:text>
    <xsl:apply-templates select="*[not(self::label)]"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- LABEL DE fn: SUPRIMIR (NUMERACIÓN LA HACE LATEX) -->
  <xsl:template match="fn/label"/>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: LISTAS                                           -->
  <!-- ============================================================ -->

  <!-- LISTAS ORDENADAS -->
  <xsl:template match="list[@list-type='order'       or
                             @list-type='roman-lower' or
                             @list-type='roman-upper' or
                             @list-type='alpha-lower' or
                             @list-type='alpha-upper']">
    <xsl:text>\begin{enumerate}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{enumerate}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- TODOS LOS DEMÁS TIPOS (bullet, simple, sin atributo) → itemize -->
  <xsl:template match="list">
    <xsl:text>\begin{itemize}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{itemize}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="list-item">
    <xsl:text>  \item </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <!-- LISTA DE DEFINICIONES → description -->
  <xsl:template match="def-list">
    <xsl:text>\begin{description}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{description}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="def-item">
    <xsl:text>  \item[</xsl:text>
    <xsl:apply-templates select="term"/>
    <xsl:text>] </xsl:text>
    <xsl:apply-templates select="def"/>
  </xsl:template>

  <xsl:template match="term | def">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: BLOQUES ESPECIALES                               -->
  <!-- ============================================================ -->

  <!-- CITA LARGA EN BLOQUE -->
  <xsl:template match="disp-quote">
    <xsl:text>&#10;\begin{quote}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{quote}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ATRIBUCIÓN EN CITA LARGA -->
  <xsl:template match="attrib">
    <xsl:text>\hfill --- </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- TEXTO PREFORMATEADO / VERBATIM EN BLOQUE                     -->
  <!-- text() DENTRO NO PASA POR f:latex (ver plantilla preformat//text()) -->
  <xsl:template match="preformat">
    <xsl:text>&#10;\begin{verbatim}&#10;</xsl:text>
    <xsl:value-of select="string(.)"/>
    <xsl:text>&#10;\end{verbatim}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: FIGURAS                                          -->
  <!-- ============================================================ -->

  <xsl:template match="fig">
    <xsl:text>&#10;\begin{figure}[htbp]&#10;</xsl:text>
    <xsl:text>  \centering&#10;</xsl:text>

    <!-- IMAGEN: RUTA RELATIVA AL SUBDIRECTORIO figuras/             -->
    <!-- EL EDITOR COLOCA LAS IMÁGENES EN {proyecto}/figuras/        -->
    <!-- EL .TEX SE COMPILA DESDE {proyecto}/latex/ — RUTA RELATIVA  -->
    <xsl:if test="graphic/@xlink:href">
      <xsl:text>  \includegraphics[width=\linewidth]{../figuras/</xsl:text>
      <xsl:value-of select="graphic/@xlink:href"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- LEYENDA (caption title + primer párrafo de caption/p)      -->
    <xsl:if test="caption">
      <xsl:text>  \caption{</xsl:text>
      <xsl:if test="caption/title">
        <xsl:apply-templates select="caption/title/node()"/>
        <xsl:if test="caption/p">. </xsl:if>
      </xsl:if>
      <xsl:for-each select="caption/p">
        <xsl:if test="position() > 1"> </xsl:if>
        <xsl:apply-templates/>
      </xsl:for-each>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- LABEL PARA \ref{} Y \autoref{} -->
    <xsl:if test="@id">
      <xsl:text>  \label{</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <xsl:text>\end{figure}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- SUPRIMIR HIJOS DE fig PROCESADOS EXPLÍCITAMENTE ARRIBA       -->
  <xsl:template match="fig/caption"/>
  <xsl:template match="fig/label"/>
  <xsl:template match="fig/graphic"/>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: TABLAS (JATS CALS → LaTeX booktabs)             -->
  <!-- COBERTURA: TABLAS SIMPLES SIN colspan NI rowspan             -->
  <!-- TODO: TABLAS CON SPANS REQUIEREN makecell O multirow         -->
  <!-- ============================================================ -->

  <xsl:template match="table-wrap">
    <xsl:text>&#10;\begin{table}[htbp]&#10;</xsl:text>
    <xsl:text>  \centering&#10;</xsl:text>

    <!-- LEYENDA ANTES DE LA TABLA (CONVENCIÓN JATS4R / EDITORIAL)  -->
    <xsl:if test="caption">
      <xsl:text>  \caption{</xsl:text>
      <xsl:if test="caption/title">
        <xsl:apply-templates select="caption/title/node()"/>
        <xsl:if test="caption/p">. </xsl:if>
      </xsl:if>
      <xsl:for-each select="caption/p">
        <xsl:if test="position() > 1"> </xsl:if>
        <xsl:apply-templates/>
      </xsl:for-each>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <xsl:if test="@id">
      <xsl:text>  \label{</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- TABLE PUEDE ESTAR DIRECTAMENTE O DENTRO DE alternatives     -->
    <xsl:apply-templates select="table | alternatives/table"/>

    <!-- NOTA AL PIE DE TABLA -->
    <xsl:if test="table-wrap-foot">
      <xsl:text>  \smallskip&#10;</xsl:text>
      <xsl:text>  {\small\raggedright </xsl:text>
      <xsl:apply-templates select="table-wrap-foot//p"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <xsl:text>\end{table}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- SUPRIMIR HIJOS DE table-wrap PROCESADOS EXPLÍCITAMENTE      -->
  <xsl:template match="table-wrap/caption"/>
  <xsl:template match="table-wrap/label"/>

  <xsl:template match="table">
    <!-- NÚMERO DE COLUMNAS DESDE LA PRIMERA FILA DISPONIBLE        -->
    <xsl:variable name="primeraFila"
      select="(thead/tr | tbody/tr | tfoot/tr)[1]"/>
    <xsl:variable name="nCols"
      select="count($primeraFila/(th | td))"/>

    <!-- ESPECIFICACIÓN DE COLUMNAS: l PARA CADA COLUMNA            -->
    <!-- TODO: INFERIR l/c/r DESDE @align EN CADA CELDA            -->
    <xsl:variable name="colSpec"
      select="string-join(for $i in 1 to $nCols return 'l', '')"/>

    <xsl:text>  \begin{tabular}{@{}</xsl:text>
    <xsl:value-of select="$colSpec"/>
    <xsl:text>@{}}&#10;</xsl:text>
    <xsl:text>    \toprule&#10;</xsl:text>

    <!-- ENCABEZADO (thead) -->
    <xsl:for-each select="thead/tr">
      <xsl:call-template name="emitir-fila-tabla">
        <xsl:with-param name="esEncabezado" select="true()"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:if test="thead/tr">
      <xsl:text>    \midrule&#10;</xsl:text>
    </xsl:if>

    <!-- SI NO HAY THEAD, LA PRIMERA FILA DE TBODY FUNCIONA COMO ENCABEZADO -->
    <xsl:if test="not(thead) and tbody/tr">
      <xsl:for-each select="tbody/tr[1]">
        <xsl:call-template name="emitir-fila-tabla">
          <xsl:with-param name="esEncabezado" select="true()"/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:text>    \midrule&#10;</xsl:text>
    </xsl:if>

    <!-- CUERPO (tbody) — SI NO HAY THEAD, OMITIR LA PRIMERA FILA  -->
    <xsl:for-each select="if (not(thead)) then tbody/tr[position() > 1]
                          else tbody/tr">
      <xsl:call-template name="emitir-fila-tabla">
        <xsl:with-param name="esEncabezado" select="false()"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- PIE DE TABLA DENTRO DEL TABULAR (tfoot) -->
    <xsl:for-each select="tfoot/tr">
      <xsl:call-template name="emitir-fila-tabla">
        <xsl:with-param name="esEncabezado" select="false()"/>
      </xsl:call-template>
    </xsl:for-each>

    <xsl:text>    \bottomrule&#10;</xsl:text>
    <xsl:text>  \end{tabular}&#10;</xsl:text>
  </xsl:template>

  <!-- NAMED TEMPLATE: EMITIR UNA FILA DE TABLA                     -->
  <xsl:template name="emitir-fila-tabla">
    <xsl:param name="esEncabezado" as="xs:boolean" select="false()"/>
    <xsl:text>    </xsl:text>
    <xsl:for-each select="th | td">
      <xsl:if test="position() > 1">
        <xsl:text> &amp; </xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="$esEncabezado">
          <xsl:text>\textbf{</xsl:text>
          <xsl:apply-templates/>
          <xsl:text>}</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
    <xsl:text> \\&#10;</xsl:text>
  </xsl:template>

  <!-- CONTENEDOR TRANSPARENTE PARA VERSIONES ALTERNATIVAS          -->
  <xsl:template match="alternatives">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: MATEMÁTICAS                                       -->
  <!-- ============================================================ -->

  <!-- FÓRMULA EN LÍNEA -->
  <xsl:template match="inline-formula">
    <xsl:text>$</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>$</xsl:text>
  </xsl:template>

  <!-- FÓRMULA EN BLOQUE (NUMERADA AUTOMÁTICAMENTE POR LATEX)       -->
  <!-- ETIQUETA \label SOLO SI EL ELEMENTO TIENE @id                 -->
  <xsl:template match="disp-formula">
    <xsl:text>&#10;\begin{equation}</xsl:text>
    <xsl:if test="@id">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="@id"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#10;\end{equation}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- LABEL DENTRO DE disp-formula: SUPRIMIR (YA EMITIDO COMO \label) -->
  <xsl:template match="disp-formula/label"/>

  <!-- tex-math: CONTENIDO LATEX PURO, SE EMITE SIN MODIFICAR       -->
  <!-- text() DENTRO TIENE SU PROPIA PLANTILLA (tex-math//text())   -->
  <xsl:template match="tex-math">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- MathML: PLACEHOLDER HASTA INTEGRACIÓN DE CONVERSOR           -->
  <!-- TODO: INTEGRAR CONVERSIÓN MathML → LaTeX CON MÓDULO EXTERNO  -->
  <xsl:template match="mml:math">
    <xsl:text>\(\text{[FÓRMULA MathML --- conversión pendiente]}\)</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!--                                                              -->
  <!--                   BACK: MATERIAL POSTERIOR                  -->
  <!--                                                              -->
  <!-- ============================================================ -->

  <!-- AGRADECIMIENTOS -->
  <xsl:template match="ack">
    <xsl:text>&#10;\section*{</xsl:text>
    <xsl:choose>
      <xsl:when test="$xmlLang = 'es'">Agradecimientos</xsl:when>
      <xsl:when test="$xmlLang = 'en'">Acknowledgments</xsl:when>
      <xsl:when test="$xmlLang = 'pt'">Agradecimentos</xsl:when>
      <xsl:when test="$xmlLang = 'fr'">Remerciements</xsl:when>
      <xsl:otherwise>Agradecimientos</xsl:otherwise>
    </xsl:choose>
    <xsl:text>}&#10;</xsl:text>
    <!-- SUPRIMIR EL TÍTULO DEL ACK: YA EMITIDO ARRIBA              -->
    <xsl:apply-templates select="*[not(self::title)]"/>
  </xsl:template>

  <!-- GRUPO DE APÉNDICES -->
  <xsl:template match="app-group">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- APÉNDICE INDIVIDUAL -->
  <!-- \appendix CAMBIA EL MODO DE NUMERACIÓN EN LATEX              -->
  <xsl:template match="app">
    <xsl:text>&#10;\appendix&#10;\section{</xsl:text>
    <xsl:apply-templates select="title/node()"/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:apply-templates select="*[not(self::title)]"/>
  </xsl:template>

  <xsl:template match="app/title"/>

  <!-- ============================================================ -->
  <!-- SUPRESIÓN EXPLÍCITA DE BACK/REF-LIST                         -->
  <!-- EL BLOQUE DE REFERENCIAS LO GESTIONA \printbibliography      -->
  <!-- INSERTADO POR EnsamblarTeX() EN m_XML. NO DUPLICAR.          -->
  <!-- ============================================================ -->
  <xsl:template match="back/ref-list"/>


  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-titulo-ancho                          -->
  <!-- PROPÓSITO: TÍTULO PRINCIPAL Y TÍTULO TRADUCIDO AL ANCHO      -->
  <!--            COMPLETO (textwidth + marginparsep + marginpar-    -->
  <!--            width = 184mm). EL TÍTULO TRADUCIDO SE OMITE SI   -->
  <!--            NO EXISTE trans-title EN EL CANÓNICO.             -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-titulo-ancho">

    <!-- 1. Título principal-->
    <xsl:text>% --- TÍTULO A ANCHO COMPLETO ---&#10;</xsl:text>
    <xsl:text>\noindent\begin{minipage}[t]{\dimexpr\textwidth+\marginparsep+\marginparwidth\relax}%&#10;</xsl:text>
    <xsl:text>{\sffamily\bfseries\Large\articulotitulo\par}%&#10;</xsl:text>
    <xsl:text>\end{minipage}\par&#10;</xsl:text>
    <xsl:text>\vspace{3mm}%&#10;</xsl:text>

    <!-- 2. Título en segundo idioma (condicional)-->
    <xsl:if test="normalize-space(front/article-meta/title-group/trans-title-group/trans-title) != ''">
      <xsl:text>\renewcommand{\articulotitulotrans}{</xsl:text>
      <xsl:value-of select="f:latex(normalize-space(
        front/article-meta/title-group/trans-title-group/trans-title))"/>
      <xsl:text>}&#10;</xsl:text>
      <xsl:text>\noindent\begin{minipage}[t]{\dimexpr\textwidth+\marginparsep+\marginparwidth\relax}%&#10;</xsl:text>
      <xsl:text>{\sffamily\itshape\normalsize\articulotitulotrans\par}%&#10;</xsl:text>
      <xsl:text>\end{minipage}\par&#10;</xsl:text>
      <xsl:text>\vspace{4mm}%&#10;</xsl:text>
    </xsl:if>

    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-bloque-lateral                        -->
  <!-- PROPÓSITO: CAJA DE METADATOS EN COLUMNA DERECHA (68mm).     -->
  <!-- POSICIÓN ABSOLUTA VÍA PAQUETE textpos:                       -->
  <!--   HORIZONTAL: left(13) + textwidth(110) + sep(6) = 129mm    -->
  <!--   VERTICAL:   top(13) + headheight(29) + 50mm    =  92mm    -->
  <!-- TODO EL TEXTO EN \sffamily\scriptsize.                       -->
  <!-- URLs, DOIs, ORCID, EMAIL EN \texttt.                         -->
  <!-- ETIQUETAS DE SECCIÓN EN \MakeUppercase.                      -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-bloque-lateral">

    <xsl:text>% --- BLOQUE LATERAL DE METADATOS ---&#10;</xsl:text>
    <!-- POSICIÓN X CALCULADA EN TIEMPO DE COMPILACIÓN LATEX VÍA \gbbloquex -->
    <xsl:text>\begin{textblock*}{68mm}(\gbbloquex,92mm)&#10;</xsl:text>
    <!-- RESETEAR leftskip Y parindent: EL CONTEXTO EXTERIOR PUEDE HEREDAR  -->
    <!-- leftskip != 0 LO QUE DESPLAZA EL CONTENIDO DENTRO DEL BLOQUE       -->
    <xsl:text>{\setlength{\leftskip}{0pt}\setlength{\parindent}{0pt}%&#10;</xsl:text>
    <xsl:text>\noindent\begin{minipage}[t]{68mm}&#10;</xsl:text>
    <xsl:text>\sffamily\small\setlength{\parskip}{1pt}&#10;</xsl:text>

    <!-- 1. Autoría (sin etiqueta, sin revista ni e-ISSN que van en header p.2+) -->
    <xsl:if test="front/article-meta/contrib-group/contrib[@contrib-type='author']">

      <xsl:for-each select="front/article-meta/contrib-group/contrib[@contrib-type='author']">

        <!-- NOMBRE COMPLETO EN BOLD AZUL + \par PARA SEPARAR DEL ORCID -->
        <xsl:text>{\bfseries\color{azulrevista}</xsl:text>
        <xsl:value-of select="f:latex(normalize-space(name/given-names))"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="f:latex(normalize-space(name/surname))"/>
        <xsl:if test="name/suffix">
          <xsl:text> </xsl:text>
          <xsl:value-of select="f:latex(normalize-space(name/suffix))"/>
        </xsl:if>
        <xsl:text>}\par&#10;</xsl:text>

        <!-- ORCID EN \scriptsize -->
        <xsl:if test="normalize-space(contrib-id[@contrib-id-type='orcid']) != ''">
          <xsl:variable name="orcid-url"
            select="normalize-space(contrib-id[@contrib-id-type='orcid'])"/>
          <xsl:text>{\scriptsize\texttt{\href{</xsl:text>
          <xsl:value-of select="$orcid-url"/>
          <xsl:text>}{</xsl:text>
          <xsl:value-of select="$orcid-url"/>
          <xsl:text>}}}\par&#10;</xsl:text>
        </xsl:if>

        <!-- EMAIL (solo autor de correspondencia) EN \scriptsize -->
        <xsl:if test="@corresp='yes' and normalize-space(email) != ''">
          <xsl:text>{\scriptsize\texttt{\href{mailto:</xsl:text>
          <xsl:value-of select="normalize-space(email)"/>
          <xsl:text>}{</xsl:text>
          <xsl:value-of select="normalize-space(email)"/>
          <xsl:text>}}}\par&#10;</xsl:text>
        </xsl:if>

        <!-- AFILIACIÓN -->
        <xsl:if test="aff">
          <xsl:for-each select="aff/institution">
            <xsl:value-of select="f:latex(normalize-space(.))"/>
            <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
          </xsl:for-each>
          <xsl:if test="aff/city">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="f:latex(normalize-space(aff/city))"/>
          </xsl:if>
          <xsl:if test="aff/country">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="f:latex(normalize-space(aff/country))"/>
          </xsl:if>
          <xsl:text>\par&#10;</xsl:text>
        </xsl:if>

        <xsl:if test="position() != last()">
          <xsl:text>\vspace{4pt}&#10;</xsl:text>
        </xsl:if>

      </xsl:for-each>
      <xsl:text>\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 4. Datos de publicación: etiqueta bold azul + datos en línea -->
    <xsl:text>{\bfseries\color{azulrevista!70}</xsl:text>
    <xsl:choose>
      <xsl:when test="$xmlLang = 'es'">Publicación</xsl:when>
      <xsl:when test="$xmlLang = 'en'">Publication</xsl:when>
      <xsl:when test="$xmlLang = 'pt'">Publicação</xsl:when>
      <xsl:when test="$xmlLang = 'fr'">Publication</xsl:when>
      <xsl:otherwise>Publicación</xsl:otherwise>
    </xsl:choose>
    <xsl:text>:} </xsl:text>
    <xsl:if test="normalize-space(front/article-meta/pub-date/year) != ''">
      <xsl:value-of select="normalize-space(front/article-meta/pub-date/year)"/>
    </xsl:if>
    <xsl:if test="normalize-space(front/article-meta/volume) != ''">
      <xsl:text>, vol.~</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/volume)"/>
    </xsl:if>
    <xsl:if test="normalize-space(front/article-meta/issue) != ''">
      <xsl:text>, n\'um.~</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/issue)"/>
    </xsl:if>
    <xsl:if test="normalize-space(front/article-meta/fpage) != ''">
      <xsl:text>, pp.~</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/fpage)"/>
      <xsl:if test="normalize-space(front/article-meta/lpage) != ''">
        <xsl:text>--</xsl:text>
        <xsl:value-of select="normalize-space(front/article-meta/lpage)"/>
      </xsl:if>
    </xsl:if>
    <xsl:text>\par\vspace{6pt}&#10;</xsl:text>

    <!-- 5. DOI: etiqueta bold azul + URL en scriptsize -->
    <xsl:variable name="doi-lat"
      select="normalize-space(front/article-meta/article-id[@pub-id-type='doi'])"/>
    <xsl:if test="$doi-lat != ''">
      <xsl:text>{\bfseries\color{azulrevista!70}DOI:} {\scriptsize\texttt{\href{https://doi.org/</xsl:text>
      <xsl:value-of select="$doi-lat"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="$doi-lat"/>
      <xsl:text>}}}\par\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 6. Licencia: etiqueta bold azul + texto + URL en scriptsize -->
    <xsl:if test="front/article-meta/permissions/license">
      <xsl:text>{\bfseries\color{azulrevista!70}</xsl:text>
      <xsl:choose>
        <xsl:when test="$xmlLang = 'es'">Licencia</xsl:when>
        <xsl:when test="$xmlLang = 'en'">License</xsl:when>
        <xsl:when test="$xmlLang = 'pt'">Licença</xsl:when>
        <xsl:when test="$xmlLang = 'fr'">Licence</xsl:when>
        <xsl:otherwise>Licencia</xsl:otherwise>
      </xsl:choose>
      <xsl:text>:} </xsl:text>
      <xsl:value-of select="f:latex(normalize-space(
        front/article-meta/permissions/license/license-p))"/>
      <xsl:text>\par&#10;</xsl:text>
      <!-- URL DE LA LICENCIA EN \scriptsize\texttt (ATRIBUTO xlink:href) -->
      <xsl:if test="normalize-space(front/article-meta/permissions/license/@xlink:href) != ''">
        <xsl:variable name="lic-url"
          select="normalize-space(front/article-meta/permissions/license/@xlink:href)"/>
        <xsl:text>{\scriptsize\texttt{\href{</xsl:text>
        <xsl:value-of select="$lic-url"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="$lic-url"/>
        <xsl:text>}}}\par&#10;</xsl:text>
      </xsl:if>
      <xsl:text>\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 7. Fechas-->
    <xsl:if test="front/article-meta/history/date[@date-type='received'] or
                  front/article-meta/history/date[@date-type='accepted'] or
                  front/article-meta/history/date[@date-type='pub']">
      <xsl:text>{\bfseries\color{azulrevista!70}</xsl:text>
      <xsl:choose>
        <xsl:when test="$xmlLang = 'es'">Fechas</xsl:when>
        <xsl:when test="$xmlLang = 'en'">Dates</xsl:when>
        <xsl:when test="$xmlLang = 'pt'">Datas</xsl:when>
        <xsl:when test="$xmlLang = 'fr'">Dates</xsl:when>
        <xsl:otherwise>Fechas</xsl:otherwise>
      </xsl:choose>
      <xsl:text>}\par\vspace{2pt}&#10;</xsl:text>

      <xsl:if test="front/article-meta/history/date[@date-type='received']">
        <xsl:variable name="dr"
          select="front/article-meta/history/date[@date-type='received']"/>
        <xsl:choose>
          <xsl:when test="$xmlLang = 'es'">Recibido: </xsl:when>
          <xsl:when test="$xmlLang = 'en'">Received: </xsl:when>
          <xsl:when test="$xmlLang = 'pt'">Recebido: </xsl:when>
          <xsl:when test="$xmlLang = 'fr'">Re\c{c}u\,: </xsl:when>
          <xsl:otherwise>Recibido: </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="normalize-space($dr/day)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="normalize-space($dr/month)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="normalize-space($dr/year)"/>
        <xsl:text>\par&#10;</xsl:text>
      </xsl:if>

      <xsl:if test="front/article-meta/history/date[@date-type='accepted']">
        <xsl:variable name="da"
          select="front/article-meta/history/date[@date-type='accepted']"/>
        <xsl:choose>
          <xsl:when test="$xmlLang = 'es'">Aceptado: </xsl:when>
          <xsl:when test="$xmlLang = 'en'">Accepted: </xsl:when>
          <xsl:when test="$xmlLang = 'pt'">Aceito: </xsl:when>
          <xsl:when test="$xmlLang = 'fr'">Accept\'e\,: </xsl:when>
          <xsl:otherwise>Aceptado: </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="normalize-space($da/day)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="normalize-space($da/month)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="normalize-space($da/year)"/>
        <xsl:text>\par&#10;</xsl:text>
      </xsl:if>

      <xsl:if test="front/article-meta/history/date[@date-type='pub']">
        <xsl:variable name="dp"
          select="front/article-meta/history/date[@date-type='pub']"/>
        <xsl:text>Online: </xsl:text>
        <xsl:value-of select="normalize-space($dp/day)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="normalize-space($dp/month)"/>
        <xsl:text>/</xsl:text>
        <xsl:value-of select="normalize-space($dp/year)"/>
        <xsl:text>\par&#10;</xsl:text>
      </xsl:if>
      <xsl:text>\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 8. Palabras clave (todas las kwd-group) -->
    <xsl:if test="front/article-meta/kwd-group">
      <xsl:text>{\bfseries\color{azulrevista!70}</xsl:text>
      <xsl:choose>
        <xsl:when test="$xmlLang = 'es'">Palabras clave</xsl:when>
        <xsl:when test="$xmlLang = 'en'">Keywords</xsl:when>
        <xsl:when test="$xmlLang = 'pt'">Palavras-chave</xsl:when>
        <xsl:when test="$xmlLang = 'fr'">Mots-cl\'es</xsl:when>
        <xsl:otherwise>Palabras clave</xsl:otherwise>
      </xsl:choose>
      <xsl:text>}\par\vspace{2pt}&#10;</xsl:text>
      <xsl:for-each select="front/article-meta/kwd-group">
        <xsl:if test="@xml:lang != ''">
          <xsl:text>(</xsl:text>
          <xsl:value-of select="@xml:lang"/>
          <xsl:text>)~</xsl:text>
        </xsl:if>
        <xsl:for-each select="kwd">
          <xsl:value-of select="f:latex(normalize-space(.))"/>
          <xsl:if test="position() != last()">
            <xsl:text> $\cdot$ </xsl:text>
          </xsl:if>
        </xsl:for-each>
        <xsl:text>\par&#10;</xsl:text>
      </xsl:for-each>
    </xsl:if>

    <xsl:text>\end{minipage}%&#10;</xsl:text>
    <xsl:text>}% FIN GRUPO leftskip&#10;</xsl:text>
    <xsl:text>\end{textblock*}&#10;&#10;</xsl:text>

  </xsl:template>

</xsl:stylesheet>
