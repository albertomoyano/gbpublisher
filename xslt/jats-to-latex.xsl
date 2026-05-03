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
    4. Resúmenes con palabras clave (tcolorbox por idioma)
    5. Separador visual (\rule)
    6. Cuerpo del artículo (\section, \p, figuras, tablas...)
    7. Agradecimientos y apéndices (back sin ref-list)
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
    <xsl:variable name="s1"  select="replace($t,   '\\',    '\\textbackslash{}')"/>
    <xsl:variable name="s2"  select="replace($s1,  '\{',    '\\{')"/>
    <xsl:variable name="s3"  select="replace($s2,  '\}',    '\\}')"/>
    <xsl:variable name="s4"  select="replace($s3,  '\$',    '\\\$')"/>
    <xsl:variable name="s5"  select="replace($s4,  '%',     '\\%')"/>
    <xsl:variable name="s6"  select="replace($s5,  '&amp;', '\\&amp;')"/>
    <xsl:variable name="s7"  select="replace($s6,  '#',     '\\#')"/>
    <xsl:variable name="s8"  select="replace($s7,  '_',     '\\_')"/>
    <xsl:variable name="s9"  select="replace($s8,  '\^',    '\\textasciicircum{}')"/>
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
  <!-- IDIOMA PRINCIPAL DEL ARTÍCULO EN CASCADA:                   -->
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
  <!-- PARÁMETRO GLOBAL: $estilo_cita                               -->
  <!-- RECIBIDO DESDE m_XML VÍA SAXON (-p estilo_cita=valor)       -->
  <!-- CONTROLA EL COMANDO DE CITA EN EL CUERPO DEL ARTÍCULO:      -->
  <!--   biblatex (apa, iso690, ieee) → \autocite{}                 -->
  <!--   bibtex (vancouver) → \cite{} DIRECTO SIN PAQUETES EXTRA   -->
  <!-- FALLBACK: 'apa' (biblatex)                                   -->
  <!-- ============================================================ -->
  <xsl:param name="estilo_cita" as="xs:string" select="'apa'"/>

  <!-- PARÁMETRO RECIBIDO DESDE m_XML — URL DEL ARTÍCULO DESDE LA BD -->
  <xsl:param name="url_articulo" as="xs:string" select="''"/>

  <!-- PARÁMETRO RECIBIDO DESDE m_XML — RUTA ABSOLUTA AL DIRECTORIO DE FONTS -->
  <!-- EJEMPLO: /home/alberto/.gbpublisher/fonts/                             -->
  <xsl:param name="ruta_fonts" as="xs:string" select="''"/>

  <!-- ============================================================ -->
  <!--                   PLANTILLAS RAÍZ                           -->
  <!-- ============================================================ -->

  <xsl:template match="/">
    <xsl:apply-templates select="article"/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLA: article                                           -->
  <!-- CONTROLA EL ORDEN DE EMISIÓN DEL FRAGMENTO COMPLETO         -->
  <!-- ============================================================ -->
  <xsl:template match="article">

    <xsl:text>\selectlanguage{</xsl:text>
    <xsl:value-of select="f:babel-lang($xmlLang)"/>
    <xsl:text>}&#10;&#10;</xsl:text>

    <!-- 1. MACROS DE METADATOS (\renewcommand) -->
    <xsl:call-template name="emitir-macros-metadatos"/>

    <!-- NUMERACIÓN DE PÁGINA DESDE fpage + ESTILO PRIMERA PÁGINA -->
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

    <!-- 2. TÍTULO A ANCHO COMPLETO (184mm) + TÍTULO TRADUCIDO -->
    <xsl:call-template name="emitir-titulo-ancho"/>

    <!-- 3. BLOQUE LATERAL DE METADATOS (POSICIÓN ABSOLUTA EN MARGINPAR) -->
    <xsl:call-template name="emitir-bloque-lateral"/>

    <!-- 4. RESÚMENES CON PALABRAS CLAVE — UN tcolorbox POR IDIOMA -->
    <xsl:for-each select="front/article-meta/abstract |
                          front/article-meta/trans-abstract">
      <xsl:variable name="lang"
        select="if (normalize-space(@xml:lang) != '')
                then normalize-space(@xml:lang)
                else $xmlLang"/>
      <xsl:variable name="kwds"
        select="../kwd-group[@xml:lang = $lang]"/>
      <xsl:call-template name="tcolorbox-resumen">
        <xsl:with-param name="lang"  select="$lang"/>
        <xsl:with-param name="parrs" select="p | sec"/>
        <xsl:with-param name="kwds"  select="$kwds"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- SEPARADOR ENTRE METADATOS Y CUERPO -->
    <xsl:if test="body/sec or body/p">
      <xsl:text>&#10;\bigskip&#10;</xsl:text>
      <xsl:text>\noindent\rule{\linewidth}{0.4pt}&#10;</xsl:text>
      <xsl:text>\bigskip&#10;&#10;</xsl:text>
    </xsl:if>

    <!-- 5. CUERPO DEL ARTÍCULO -->
    <xsl:apply-templates select="body"/>

    <!-- 6. AGRADECIMIENTOS -->
    <xsl:apply-templates select="back/ack"/>

    <!-- 7. APÉNDICES -->
    <xsl:apply-templates select="back/app-group"/>

    <!-- NOTA: back/ref-list ES OMITIDO INTENCIONALMENTE.           -->
    <!-- \printbibliography LO INSERTA EnsamblarTeX() EN m_XML.     -->

  </xsl:template>

<!-- ============================================================ -->
<!-- DIÁLOGO: speech CON speaker                                  -->
<!-- USA \paragraph{speaker} PARA EVITAR VIUDAS Y HUÉRFANAS      -->
<!-- EL TEXTO CONTINÚA INLINE DESPUÉS DEL TÍTULO                  -->
<!-- ============================================================ -->
  <xsl:template match="speech">
    <xsl:text>&#10;\paragraph{</xsl:text>
    <xsl:value-of select="f:latex(normalize-space(speaker))"/>
    <xsl:text>} </xsl:text>
    <xsl:apply-templates select="*[not(self::speaker)]"/>
  </xsl:template>

  <xsl:template match="speech/p">
    <xsl:apply-templates/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

<!-- ============================================================ -->
<!-- CASO DE ESTUDIO: boxed-text CON id                          -->
<!-- DISEÑO: borde izquierdo azul, fondo neutro                  -->
<!-- ============================================================ -->
  <xsl:template match="boxed-text[@id]" priority="5">
    <xsl:text>&#10;\begin{tcolorbox}[colback=white,colframe=azulrevista,</xsl:text>
    <xsl:text>leftrule=3pt,rightrule=0pt,toprule=0pt,bottomrule=0pt,</xsl:text>
    <xsl:text>arc=0pt,left=8pt,right=4pt,top=3pt,bottom=3pt,</xsl:text>
    <xsl:text>before skip=4pt,after skip=4pt]&#10;</xsl:text>
    <xsl:text>{\sffamily\small&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:text>\end{tcolorbox}&#10;&#10;</xsl:text>
  </xsl:template>

<!-- ============================================================ -->
<!-- ENTREVISTA CUALITATIVA: disp-quote content-type="interview" -->
<!-- EL CÓDIGO DE INFORMANTE VA COMO TÍTULO DE \paragraph        -->
<!-- ============================================================ -->
  <xsl:template match="disp-quote[@content-type='interview']">
    <xsl:variable name="codigo"
    select="normalize-space(@specific-use)"/>
    <xsl:text>&#10;\paragraph{</xsl:text>
    <xsl:choose>
      <xsl:when test="$codigo != ''">
        <xsl:value-of select="f:latex($codigo)"/>
      </xsl:when>
      <xsl:otherwise>INF</xsl:otherwise>
    </xsl:choose>
    <xsl:text>} </xsl:text>
    <xsl:apply-templates select="*[not(self::attrib)]"/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: tcolorbox-resumen                           -->
  <!-- UN BOX POR IDIOMA: ETIQUETA + TEXTO + PALABRAS CLAVE        -->
  <!-- COLOR: té con leche — marrón muy claro (brown!8!white)      -->
  <!-- TIPOGRAFÍA: sans small, etiqueta bold inline                 -->
  <!-- ============================================================ -->
  <xsl:template name="tcolorbox-resumen">
    <xsl:param name="lang"/>
    <xsl:param name="parrs"/>
    <xsl:param name="kwds"/>

    <!-- ETIQUETA SEGÚN IDIOMA -->
    <xsl:variable name="etiqueta">
      <xsl:choose>
        <xsl:when test="$lang = 'es'">Resumen</xsl:when>
        <xsl:when test="$lang = 'en'">Abstract</xsl:when>
        <xsl:when test="$lang = 'pt'">Resumo</xsl:when>
        <xsl:when test="$lang = 'fr'">Résumé</xsl:when>
        <xsl:otherwise>Resumen</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- ETIQUETA DE PALABRAS CLAVE SEGÚN IDIOMA -->
    <xsl:variable name="etiqueta-kwd">
      <xsl:choose>
        <xsl:when test="$lang = 'es'">Palabras clave</xsl:when>
        <xsl:when test="$lang = 'en'">Keywords</xsl:when>
        <xsl:when test="$lang = 'pt'">Palavras-chave</xsl:when>
        <xsl:when test="$lang = 'fr'">Mots-clés</xsl:when>
        <xsl:otherwise>Palabras clave</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:text>&#10;\begin{tcolorbox}[</xsl:text>
    <xsl:text>colback=brown!8!white,</xsl:text>
    <xsl:text>colframe=brown!8!white,</xsl:text>
    <xsl:text>boxrule=0pt,arc=2pt,</xsl:text>
    <xsl:text>left=4pt,right=4pt,top=3pt,bottom=3pt,</xsl:text>
    <xsl:text>before skip=4pt,after skip=4pt]</xsl:text>
    <xsl:text>&#10;\begin{otherlanguage}{</xsl:text>
    <xsl:value-of select="f:babel-lang($lang)"/>
    <xsl:text>}&#10;\sffamily\small </xsl:text>
    <xsl:text>\textbf{</xsl:text>
    <xsl:value-of select="$etiqueta"/>
    <xsl:text>:} </xsl:text>
    <xsl:apply-templates select="$parrs"/>
    <xsl:if test="$kwds/kwd">
      <xsl:text>&#10;\par\smallskip\noindent\textbf{</xsl:text>
      <xsl:value-of select="$etiqueta-kwd"/>
      <xsl:text>:} </xsl:text>
      <xsl:for-each select="$kwds/kwd">
        <xsl:if test="position() > 1">, </xsl:if>
        <xsl:value-of select="f:latex(normalize-space(.))"/>
      </xsl:for-each>
    </xsl:if>
    <xsl:text>&#10;\end{otherlanguage}</xsl:text>
    <xsl:text>&#10;\end{tcolorbox}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- RESÚMENES Y PALABRAS CLAVE                                   -->
  <!-- PROCESADOS POR tcolorbox-resumen DESDE EL FOR-EACH          -->
  <!-- DEL TEMPLATE article — NO PROCESAR DIRECTAMENTE             -->
  <!-- ============================================================ -->
  <xsl:template match="abstract | trans-abstract"/>
  <xsl:template match="abstract/title | trans-abstract/title"/>
  <xsl:template match="kwd-group"/>

  <!-- ============================================================ -->
  <!--                   FRONT: METADATOS                          -->
  <!-- ============================================================ -->

  <!-- FRONT: SUPRIMIDO COMO ELEMENTO DIRECTO — SE PROCESA          -->
  <!-- EXCLUSIVAMENTE VÍA NAMED TEMPLATES Y apply-templates SELECT  -->
  <xsl:template match="front"/>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: emitir-macros-metadatos                      -->
  <!-- PROPÓSITO: \renewcommand PARA CADA MACRO DEL PREÁMBULO.     -->
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

    <!-- DOI -->
    <xsl:if test="normalize-space($meta/article-id[@pub-id-type='doi']) != ''">
      <xsl:text>\renewcommand{\articulodoi}{</xsl:text>
      <xsl:value-of select="normalize-space(
        $meta/article-id[@pub-id-type='doi'])"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <!-- TIPO DE ARTÍCULO -->
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

    <!-- PÁGINA DE INICIO -->
    <xsl:if test="normalize-space(front/article-meta/fpage) != ''">
      <xsl:text>\renewcommand{\articulopagina}{</xsl:text>
      <xsl:value-of select="normalize-space(front/article-meta/fpage)"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>

    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!--                   BODY: CUERPO                              -->
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

  <!-- SUPRIMIR TÍTULO DE LA PRIMERA SECCIÓN DEL BODY              -->
  <!-- EN JATS EL ARTÍCULO COMIENZA CON UNA <sec> CUYO <title>    -->
  <!-- REPITE EL TÍTULO DEL ARTÍCULO YA PRESENTE EN EL PREÁMBULO  -->
  <xsl:template match="body/sec[1]/title" priority="5"/>

  <!-- SEC/TITLE: normalize-space() EVITA WHITESPACE DE indent=yes  -->
  <!-- QUE ROMPE \section{} CON titlesec                           -->
  <xsl:template match="sec/title">
    <xsl:variable name="profundidad" select="count(ancestor::sec) - 1"/>
    <xsl:variable name="tituloSec"   select="normalize-space(.)"/>
    <xsl:choose>
      <xsl:when test="$profundidad = 0">\section{</xsl:when>
      <xsl:when test="$profundidad = 1">\subsection{</xsl:when>
      <xsl:when test="$profundidad = 2">\subsubsection{</xsl:when>
      <xsl:otherwise>\paragraph{</xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="$tituloSec"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: PÁRRAFOS                                         -->
  <!-- ============================================================ -->

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

  <!-- EN FOOTNOTE: SIN SALTO AL FINAL -->
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

<!-- ============================================================ -->
<!-- VERSO: verse-group CON verse-line                           -->
<!-- DISEÑO: bastardilla, sangría 14pt, líneas con \\            -->
<!-- LA ÚLTIMA LÍNEA NO LLEVA \\ — se detecta con position()     -->
<!-- ============================================================ -->
  <xsl:template match="verse-group">
    <xsl:text>&#10;\begin{verse}&#10;</xsl:text>
    <xsl:apply-templates select="verse-line"/>
    <xsl:text>\end{verse}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="verse-line">
    <xsl:text>\textit{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
    <xsl:if test="position() != last()">
      <xsl:text>\\&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="position() = last()">
      <xsl:text>&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

<!-- ============================================================ -->
  <!-- BLOQUE DE CÓDIGO CON LENGUAJE — USA listings                -->
  <!-- priority="5" TIENE PRECEDENCIA SOBRE EL TEMPLATE GENÉRICO   -->
  <!-- code SIN @language SIGUE USANDO \texttt{} (INLINE)          -->
  <!-- ============================================================ -->
  <xsl:template match="code[@language]" priority="5">
    <xsl:variable name="lang">
      <xsl:choose>
        <xsl:when test="lower-case(@language) = 'python'">Python</xsl:when>
        <xsl:when test="lower-case(@language) = 'r'">R</xsl:when>
        <xsl:when test="lower-case(@language) = 'javascript'">JavaScript</xsl:when>
        <xsl:when test="lower-case(@language) = 'sql'">SQL</xsl:when>
        <xsl:when test="lower-case(@language) = 'bash'">bash</xsl:when>
        <xsl:when test="lower-case(@language) = 'java'">Java</xsl:when>
        <xsl:when test="lower-case(@language) = 'c'">C</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@language"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>&#10;\begin{lstlisting}[language=</xsl:text>
    <xsl:value-of select="$lang"/>
    <xsl:text>]&#10;</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>&#10;\end{lstlisting}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="sc">
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

  <xsl:template match="named-content | styled-content">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="break">
    <xsl:text>\\&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: REFERENCIAS CRUZADAS Y CITAS                     -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- CITA BIBLIOGRÁFICA                                           -->
  <!-- EL COMANDO VARÍA SEGÚN $estilo_cita:                        -->
  <!--   biblatex (apa, iso690, ieee) → \autocite{k1,k2,...}       -->
  <!--   bibtex (vancouver) → \cite{k1,k2,...}                     -->
  <!-- EL AGRUPAMIENTO ES UNIVERSAL — EL PRIMERO DEL GRUPO         -->
  <!-- RECOPILA TODAS LAS CLAVES, LOS SIGUIENTES SE SUPRIMEN       -->
  <!-- PARA VANCOUVER EL PAQUETE cite RESUELVE \cite{k1,k2,k3}    -->
  <!-- ============================================================ -->
  <!-- ============================================================ -->
  <!-- CITA BIBLIOGRÁFICA                                           -->
  <!-- LEE @specific-use PARA MODO, PREFIJO Y SUFIJO               -->
  <!-- FORMATO DE specific-use: "modo|prefijo|sufijo"              -->
  <!--   normal         → \autocite[pre][suf]{key}                 -->
  <!--   suppress       → \autocite*[pre][suf]{key}  (solo año)    -->
  <!--   author-in-text → \textcite[pre][suf]{key}   (autor inline)-->
  <!-- VANCOUVER USA \cite EN TODOS LOS CASOS SIN VARIANTES        -->
  <!-- ============================================================ -->
  <xsl:template match="xref[@ref-type='bibr']">
    <xsl:variable name="prev1" select="preceding-sibling::node()[1]"/>
    <xsl:variable name="prev2" select="preceding-sibling::node()[2]"/>

    <!-- SI ES PARTE DE UN GRUPO — EL PRIMERO YA INCLUYÓ ESTA CLAVE -->
    <xsl:if test="not(
      $prev1/self::text()[matches(normalize-space(.), '^[\p{Pd},;]\s*$')] and
      $prev2/self::xref[@ref-type='bibr'])">

      <!-- PARSEAR specific-use: modo|prefijo|sufijo -->
      <xsl:variable name="su" select="normalize-space(@specific-use)"/>
      <xsl:variable name="modo">
        <xsl:choose>
          <xsl:when test="$su != ''">
            <xsl:value-of select="tokenize($su, '\|')[1]"/>
          </xsl:when>
          <xsl:otherwise>normal</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="prefijo">
        <xsl:if test="$su != ''">
          <xsl:value-of select="normalize-space(tokenize($su, '\|')[2])"/>
        </xsl:if>
      </xsl:variable>
      <xsl:variable name="sufijo">
        <xsl:if test="$su != ''">
          <xsl:value-of select="normalize-space(tokenize($su, '\|')[3])"/>
        </xsl:if>
      </xsl:variable>

      <xsl:choose>

<!-- VANCOUVER: prefijo como texto libre + \cite[sufijo]{key} -->
<xsl:when test="$estilo_cita = 'vancouver'">
  <xsl:if test="$prefijo != ''">
    <xsl:value-of select="$prefijo"/>
    <xsl:text> </xsl:text>
  </xsl:if>
  <xsl:text>\cite</xsl:text>
  <xsl:if test="$sufijo != ''">
    <xsl:text>[</xsl:text>
    <xsl:value-of select="$sufijo"/>
    <xsl:text>]</xsl:text>
  </xsl:if>
  <xsl:text>{</xsl:text>
  <xsl:value-of select="substring-after(@rid, 'bib-')"/>
  <xsl:call-template name="recopilar-grupo-citas">
    <xsl:with-param name="nodos" select="following-sibling::node()"/>
  </xsl:call-template>
  <xsl:text>}</xsl:text>
</xsl:when>

        <!-- SUPPRESS AUTHOR: [-@key] → \autocite* — SOLO AÑO -->
        <xsl:when test="$modo = 'suppress'">
          <xsl:text>\autocite*</xsl:text>
          <xsl:if test="$prefijo != ''">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$prefijo"/>
            <xsl:text>]</xsl:text>
          </xsl:if>
          <xsl:if test="$sufijo != ''">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$sufijo"/>
            <xsl:text>]</xsl:text>
          </xsl:if>
          <xsl:text>{</xsl:text>
          <xsl:value-of select="substring-after(@rid, 'bib-')"/>
          <xsl:call-template name="recopilar-grupo-citas">
            <xsl:with-param name="nodos" select="following-sibling::node()"/>
          </xsl:call-template>
          <xsl:text>}</xsl:text>
        </xsl:when>

        <!-- AUTHOR IN TEXT: @key → \textcite — AUTOR INLINE -->
        <xsl:when test="$modo = 'author-in-text'">
          <xsl:text>\textcite</xsl:text>
          <xsl:if test="$prefijo != ''">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$prefijo"/>
            <xsl:text>]</xsl:text>
          </xsl:if>
          <xsl:if test="$sufijo != ''">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$sufijo"/>
            <xsl:text>]</xsl:text>
          </xsl:if>
          <xsl:text>{</xsl:text>
          <xsl:value-of select="substring-after(@rid, 'bib-')"/>
          <xsl:call-template name="recopilar-grupo-citas">
            <xsl:with-param name="nodos" select="following-sibling::node()"/>
          </xsl:call-template>
          <xsl:text>}</xsl:text>
        </xsl:when>

        <!-- NORMAL: [@key] → \autocite CON PREFIJO Y SUFIJO OPCIONALES -->
        <xsl:otherwise>
          <xsl:text>\autocite</xsl:text>
          <xsl:if test="$prefijo != ''">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$prefijo"/>
            <xsl:text>]</xsl:text>
          </xsl:if>
          <xsl:if test="$sufijo != ''">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="$sufijo"/>
            <xsl:text>]</xsl:text>
          </xsl:if>
          <xsl:text>{</xsl:text>
          <xsl:value-of select="substring-after(@rid, 'bib-')"/>
          <xsl:call-template name="recopilar-grupo-citas">
            <xsl:with-param name="nodos" select="following-sibling::node()"/>
          </xsl:call-template>
          <xsl:text>}</xsl:text>
        </xsl:otherwise>

      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- SUPRIMIR SEPARADORES ENTRE CITAS AGRUPADAS                  -->
  <!-- APLICA A TODOS LOS ESTILOS — LOS SEPARADORES , ; - ENTRE    -->
  <!-- DOS XREF DE CITA QUEDAN ABSORBIDOS POR EL AGRUPAMIENTO      -->
  <!-- ============================================================ -->
  <xsl:template match="text()[
      matches(normalize-space(.), '^[\p{Pd},;]\s*$') and
      preceding-sibling::node()[1]/self::xref[@ref-type='bibr'] and
      following-sibling::node()[1]/self::xref[@ref-type='bibr']
    ]"/>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: recopilar-grupo-citas                       -->
  <!-- AGREGA CLAVES DE XREFS CONSECUTIVOS EN cmd{k1,k2,...}       -->
  <!-- RECURSIVO: AVANZA DE A DOS NODOS (separador + xref)         -->
  <!-- ============================================================ -->
  <xsl:template name="recopilar-grupo-citas">
    <xsl:param name="nodos" as="node()*"/>
    <xsl:if test="count($nodos) >= 2">
      <xsl:variable name="sep"  select="$nodos[1]"/>
      <xsl:variable name="next" select="$nodos[2]"/>
      <xsl:if test="$sep/self::text()[matches(normalize-space(.), '^[\p{Pd},;]\s*$')] and
                    $next/self::xref[@ref-type='bibr']">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="substring-after($next/@rid, 'bib-')"/>
        <xsl:call-template name="recopilar-grupo-citas">
          <xsl:with-param name="nodos" select="$nodos[position() > 2]"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template match="xref[@ref-type='disp-formula']">
    <xsl:text>\eqref{</xsl:text>
    <xsl:value-of select="@rid"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="xref[@ref-type='fig'   or
                             @ref-type='table' or
                             @ref-type='sec'   or
                             @ref-type='fn']">
    <xsl:text>\ref{</xsl:text>
    <xsl:value-of select="@rid"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

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

  <xsl:template match="ext-link">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="uri">
    <xsl:text>\url{</xsl:text>
    <xsl:value-of select="."/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: NOTAS AL PIE                                     -->
  <!-- ============================================================ -->

  <xsl:template match="fn[not(ancestor::ref-list)]">
    <xsl:text>\footnote{</xsl:text>
    <xsl:apply-templates select="*[not(self::label)]"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="fn/label"/>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: LISTAS                                           -->
  <!-- ============================================================ -->

  <xsl:template match="list[@list-type='order'       or
                             @list-type='roman-lower' or
                             @list-type='roman-upper' or
                             @list-type='alpha-lower' or
                             @list-type='alpha-upper']">
    <xsl:text>\begin{enumerate}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{enumerate}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="list">
    <xsl:text>\begin{itemize}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\end{itemize}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="list-item">
    <xsl:text>  \item </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

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

<!-- EPÍGRAFE: USA \epigraph{texto}{atribución} DEFINIDO EN EL PREÁMBULO -->
  <!-- EN JATS: disp-quote CONTIENE EL TEXTO Y attrib LA ATRIBUCIÓN        -->
  <xsl:template match="disp-quote">
    <xsl:choose>
      <!-- CON attrib → EPÍGRAFE -->
      <xsl:when test="attrib">
        <xsl:text>&#10;\epigraph{</xsl:text>
        <xsl:apply-templates select="*[not(self::attrib)]"/>
        <xsl:text>}{</xsl:text>
        <xsl:apply-templates select="attrib"/>
        <xsl:text>}&#10;&#10;</xsl:text>
      </xsl:when>
      <!-- SIN attrib → CITA TEXTUAL CON ENTORNO quote -->
      <xsl:otherwise>
        <xsl:text>&#10;\begin{quote}&#10;</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>\end{quote}&#10;&#10;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- ============================================================ -->
<!-- BOXED-TEXT — RECUADROS CON TIPO (warning, note, tip, etc.)  -->
<!-- USA EL MISMO tcolorbox DE LOS RESÚMENES: brown!8!white      -->
<!-- ============================================================ -->
  <xsl:template match="boxed-text">
  <xsl:text>&#10;\begin{tcolorbox}[colback=brown!8!white,colframe=brown!8!white,</xsl:text>
    <xsl:text>boxrule=0pt,arc=2pt,left=4pt,right=4pt,top=3pt,bottom=3pt,</xsl:text>
    <xsl:text>before skip=4pt,after skip=4pt]&#10;</xsl:text>
    <xsl:text>{\sffamily\small&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:text>\end{tcolorbox}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ATTRIB: CONTENIDO PURO SIN PREFIJO — \epigraph LO POSICIONA -->
  <xsl:template match="attrib">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="preformat">
    <xsl:text>&#10;\begin{verbatim}&#10;</xsl:text>
    <xsl:value-of select="string(.)"/>
    <xsl:text>&#10;\end{verbatim}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: FIGURAS                                          -->
  <!-- ============================================================ -->

  <xsl:template match="fig">
  <xsl:choose>
    <!-- FIGURA A ANCHO COMPLETO (texto + marginparsep + marginparwidth) -->
    <xsl:when test="@specific-use='fullwidth'">
      <xsl:text>&#10;\begin{adjustwidth}{0pt}{-\dimexpr\marginparsep+\marginparwidth\relax}%&#10;</xsl:text>
      <xsl:text>\centering&#10;</xsl:text>
      <xsl:call-template name="emitir-contenido-fig"/>
      <xsl:text>\end{adjustwidth}&#10;&#10;</xsl:text>
    </xsl:when>
    <!-- FIGURA NORMAL — ANCHO DE LA CAJA DE TEXTO -->
    <xsl:otherwise>
      <xsl:text>&#10;\begin{figure}[!ht]&#10;</xsl:text>
      <xsl:text>\centering&#10;</xsl:text>
      <xsl:call-template name="emitir-contenido-fig"/>
      <xsl:text>\end{figure}&#10;&#10;</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- NAMED TEMPLATE: contenido común de la figura -->
<xsl:template name="emitir-contenido-fig">
  <xsl:if test="graphic/@xlink:href != ''">
    <xsl:text>\includegraphics[width=\linewidth]{../</xsl:text>
    <xsl:value-of select="graphic/@xlink:href"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:if>
  <xsl:if test="caption">
    <xsl:text>\captionof{figure}{</xsl:text>
    <xsl:apply-templates select="caption/p/node()"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:if>
  <xsl:if test="@id">
    <xsl:text>\label{</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:if>
  <xsl:if test="@id">
    <xsl:text>\label{</xsl:text>
    <xsl:value-of select="@id"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:if>
  <xsl:text>\vspace{\intextsep}&#10;</xsl:text>
</xsl:template>

  <xsl:template match="fig/caption"/>
  <xsl:template match="fig/label"/>
  <xsl:template match="fig/graphic"/>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: TABLAS (JATS CALS → LaTeX booktabs)             -->
  <!-- ============================================================ -->
  <!-- ============================================================ -->
  <!-- TABLA — TRES VARIANTES SEGÚN @specific-use                  -->
  <!--   landscape → sidewaystable (flotante, página propia)        -->
  <!--   fullwidth → adjustwidth al margen derecho, centrada        -->
  <!--   (ninguno) → table normal ancho de columna                  -->
  <!-- ============================================================ -->
  <xsl:template match="table-wrap">
    <xsl:choose>

      <!-- TABLA APAISADA — sidewaystable, ancho total, página propia -->
      <xsl:when test="@specific-use='landscape'">
        <xsl:text>&#10;\begin{sidewaystable}&#10;</xsl:text>
        <xsl:text>\centering&#10;</xsl:text>
        <xsl:text>{\sf\footnotesize\setlength\tabcolsep{4pt}%&#10;</xsl:text>
        <xsl:apply-templates select="table | alternatives/table"/>
        <xsl:if test="table-wrap-foot">
          <xsl:text>  \smallskip&#10;</xsl:text>
          <xsl:text>  {\small\raggedright </xsl:text>
          <xsl:apply-templates select="table-wrap-foot//p"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>}%&#10;</xsl:text>
        <xsl:if test="caption">
          <xsl:text>\caption{</xsl:text>
          <xsl:if test="caption/title">
            <xsl:apply-templates select="caption/title/node()"/>
            <xsl:if test="caption/p">. </xsl:if>
          </xsl:if>
          <xsl:for-each select="caption/p">
            <xsl:if test="position() > 1"> </xsl:if>
            <xsl:apply-templates/>
          </xsl:for-each>
          <xsl:text>}</xsl:text>
        </xsl:if>
        <xsl:if test="@id">
          <xsl:text>\label{</xsl:text>
          <xsl:value-of select="@id"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>\end{sidewaystable}&#10;&#10;</xsl:text>
      </xsl:when>

      <!-- TABLA ANCHO TOTAL — adjustwidth al margen derecho, centrada -->
      <xsl:when test="@specific-use='fullwidth'">
        <xsl:text>&#10;\begin{adjustwidth}{0pt}{-\dimexpr\marginparsep+\marginparwidth\relax}%&#10;</xsl:text>
        <xsl:text>\centering&#10;</xsl:text>
        <xsl:text>{\sf\footnotesize\setlength\tabcolsep{4pt}%&#10;</xsl:text>
        <xsl:apply-templates select="table | alternatives/table"/>
        <xsl:if test="table-wrap-foot">
          <xsl:text>  \smallskip&#10;</xsl:text>
          <xsl:text>  {\small\raggedright </xsl:text>
          <xsl:apply-templates select="table-wrap-foot//p"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>}%&#10;</xsl:text>
        <xsl:if test="caption">
          <xsl:text>\captionof{table}{</xsl:text>
          <xsl:if test="caption/title">
            <xsl:apply-templates select="caption/title/node()"/>
            <xsl:if test="caption/p">. </xsl:if>
          </xsl:if>
          <xsl:for-each select="caption/p">
            <xsl:if test="position() > 1"> </xsl:if>
            <xsl:apply-templates/>
          </xsl:for-each>
          <xsl:text>}</xsl:text>
        </xsl:if>
        <xsl:if test="@id">
          <xsl:text>\label{</xsl:text>
          <xsl:value-of select="@id"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>\vspace{\intextsep}&#10;</xsl:text>
        <xsl:text>\end{adjustwidth}&#10;&#10;</xsl:text>
      </xsl:when>

      <!-- TABLA NORMAL — ancho de columna de texto -->
      <xsl:otherwise>
        <xsl:text>&#10;\begin{table}[!ht]&#10;</xsl:text>
        <xsl:text>\centering&#10;</xsl:text>
        <xsl:text>{\sf\footnotesize\setlength\tabcolsep{4pt}%&#10;</xsl:text>
        <xsl:apply-templates select="table | alternatives/table"/>
        <xsl:if test="table-wrap-foot">
          <xsl:text>  \smallskip&#10;</xsl:text>
          <xsl:text>  {\small\raggedright </xsl:text>
          <xsl:apply-templates select="table-wrap-foot//p"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>}%&#10;</xsl:text>
        <xsl:if test="caption">
          <xsl:text>\caption{</xsl:text>
          <xsl:if test="caption/title">
            <xsl:apply-templates select="caption/title/node()"/>
            <xsl:if test="caption/p">. </xsl:if>
          </xsl:if>
          <xsl:for-each select="caption/p">
            <xsl:if test="position() > 1"> </xsl:if>
            <xsl:apply-templates/>
          </xsl:for-each>
          <xsl:text>}</xsl:text>
        </xsl:if>
        <xsl:if test="@id">
          <xsl:text>\label{</xsl:text>
          <xsl:value-of select="@id"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>\end{table}&#10;&#10;</xsl:text>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <xsl:template match="table-wrap/caption"/>
  <xsl:template match="table-wrap/label"/>

  <xsl:template match="table">
    <xsl:variable name="primeraFila"
      select="(thead/tr | tbody/tr | tfoot/tr)[1]"/>
    <xsl:variable name="nCols"
      select="count($primeraFila/(th | td))"/>
    <xsl:variable name="colSpec"
      select="string-join(for $i in 1 to $nCols return 'l', '')"/>
    <xsl:text>  \begin{tabular}{@{}</xsl:text>
    <xsl:value-of select="$colSpec"/>
    <xsl:text>@{}}&#10;</xsl:text>
    <xsl:text>    \toprule&#10;</xsl:text>
    <xsl:for-each select="thead/tr">
      <xsl:call-template name="emitir-fila-tabla">
        <xsl:with-param name="esEncabezado" select="true()"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:if test="thead/tr">
      <xsl:text>    \midrule&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="not(thead) and tbody/tr">
      <xsl:for-each select="tbody/tr[1]">
        <xsl:call-template name="emitir-fila-tabla">
          <xsl:with-param name="esEncabezado" select="true()"/>
        </xsl:call-template>
      </xsl:for-each>
      <xsl:text>    \midrule&#10;</xsl:text>
    </xsl:if>
    <xsl:for-each select="if (not(thead)) then tbody/tr[position() > 1]
                          else tbody/tr">
      <xsl:call-template name="emitir-fila-tabla">
        <xsl:with-param name="esEncabezado" select="false()"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:for-each select="tfoot/tr">
      <xsl:call-template name="emitir-fila-tabla">
        <xsl:with-param name="esEncabezado" select="false()"/>
      </xsl:call-template>
    </xsl:for-each>
    <xsl:text>    \bottomrule&#10;</xsl:text>
    <xsl:text>  \end{tabular}&#10;</xsl:text>
  </xsl:template>

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
    <!-- MIDRULE DESPUÉS DE CADA FILA EXCEPTO LA ÚLTIMA -->
    <xsl:if test="position() != last()">
      <xsl:text>    \midrule&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="alternatives">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLAS: MATEMÁTICAS                                       -->
  <!-- ============================================================ -->

  <xsl:template match="inline-formula">
    <xsl:text>$</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>$</xsl:text>
  </xsl:template>

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

  <xsl:template match="disp-formula/label"/>

  <xsl:template match="tex-math">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="mml:math">
    <xsl:text>\(\text{[FÓRMULA MathML --- conversión pendiente]}\)</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!--                   BACK: MATERIAL POSTERIOR                  -->
  <!-- ============================================================ -->

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
    <xsl:apply-templates select="*[not(self::title)]"/>
  </xsl:template>

  <xsl:template match="app-group">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="app">
    <xsl:text>&#10;\appendix&#10;\section{</xsl:text>
    <xsl:value-of select="normalize-space(title)"/>
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
  <!-- TÍTULO PRINCIPAL Y TÍTULO TRADUCIDO AL ANCHO COMPLETO        -->
  <!-- (textwidth + marginparsep + marginparwidth = 184mm)          -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-titulo-ancho">

    <xsl:text>% --- TÍTULO A ANCHO COMPLETO ---&#10;</xsl:text>
    <xsl:text>\noindent\begin{minipage}[t]{\dimexpr\textwidth+\marginparsep+\marginparwidth\relax}%&#10;</xsl:text>
    <xsl:text>{\sffamily\bfseries\Large\articulotitulo\par}%&#10;</xsl:text>
    <xsl:text>\end{minipage}\par&#10;</xsl:text>
    <xsl:text>\vspace{3mm}%&#10;</xsl:text>

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
  <!-- CAJA DE METADATOS EN COLUMNA DERECHA (68mm).                 -->
  <!-- POSICIÓN ABSOLUTA VÍA PAQUETE textpos:                       -->
  <!--   HORIZONTAL: left(13) + textwidth(110) + sep(6) = 129mm    -->
  <!--   VERTICAL:   top(13) + headheight(29) + 50mm    =  92mm    -->
  <!-- ============================================================ -->
  <xsl:template name="emitir-bloque-lateral">

    <xsl:text>% --- BLOQUE LATERAL DE METADATOS ---&#10;</xsl:text>
    <xsl:text>\begin{textblock*}{68mm}(\gbbloquex,92mm)&#10;</xsl:text>
    <xsl:text>{\setlength{\leftskip}{0pt}\setlength{\parindent}{0pt}%&#10;</xsl:text>
    <xsl:text>\noindent\begin{minipage}[t]{68mm}&#10;</xsl:text>
    <xsl:text>\sffamily\small\setlength{\parskip}{1pt}&#10;</xsl:text>

    <!-- 1. AUTORÍA -->
    <xsl:if test="front/article-meta/contrib-group/contrib[@contrib-type='author']">
      <xsl:for-each select="front/article-meta/contrib-group/contrib[@contrib-type='author']">

        <xsl:text>{\bfseries\color{azulrevista}</xsl:text>
        <xsl:value-of select="f:latex(normalize-space(name/given-names))"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="f:latex(normalize-space(name/surname))"/>
        <xsl:if test="name/suffix">
          <xsl:text> </xsl:text>
          <xsl:value-of select="f:latex(normalize-space(name/suffix))"/>
        </xsl:if>
        <xsl:text>}\par&#10;</xsl:text>

        <xsl:if test="normalize-space(contrib-id[@contrib-id-type='orcid']) != ''">
          <xsl:variable name="orcid-url"
            select="normalize-space(contrib-id[@contrib-id-type='orcid'])"/>
          <xsl:text>{\scriptsize\texttt{\href{</xsl:text>
          <xsl:value-of select="$orcid-url"/>
          <xsl:text>}{</xsl:text>
          <xsl:value-of select="$orcid-url"/>
          <xsl:text>}}}\par&#10;</xsl:text>
        </xsl:if>

        <xsl:if test="@corresp='yes' and normalize-space(email) != ''">
          <xsl:text>{\scriptsize\texttt{\href{mailto:</xsl:text>
          <xsl:value-of select="normalize-space(email)"/>
          <xsl:text>}{</xsl:text>
          <xsl:value-of select="normalize-space(email)"/>
          <xsl:text>}}}\par&#10;</xsl:text>
        </xsl:if>

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

    <!-- 1.5. DERECHOS DE AUTORÍA — DESPUÉS DE AUTORES, ANTES DE PUBLICACIÓN -->
    <!-- ETIQUETA EN AZUL IGUAL A Publicación — © AUTOR EN LÍNEA NUEVA       -->
    <!-- TEXTO DESCRIPTIVO MISMO TAMAÑO QUE EL RESTO, CONTINÚA EN EL PÁRRAFO -->
    <xsl:variable name="anio-pub"
      select="normalize-space(front/article-meta/pub-date/year)"/>
    <xsl:variable name="lic-url-der"
      select="normalize-space(front/article-meta/permissions/license/@xlink:href)"/>
    <xsl:variable name="contribs-der"
      select="front/article-meta/contrib-group/contrib[@contrib-type='author']"/>
    <xsl:variable name="autores-copyright">
      <xsl:choose>
        <xsl:when test="count($contribs-der) = 1">
          <xsl:value-of select="normalize-space($contribs-der[1]/name/surname)"/>
          <xsl:text>, </xsl:text>
          <xsl:value-of select="substring(
            normalize-space($contribs-der[1]/name/given-names), 1, 1)"/>
          <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:when test="count($contribs-der) = 2">
          <xsl:value-of select="normalize-space($contribs-der[1]/name/surname)"/>
          <xsl:text>, </xsl:text>
          <xsl:value-of select="substring(
            normalize-space($contribs-der[1]/name/given-names), 1, 1)"/>
          <xsl:text>. y </xsl:text>
          <xsl:value-of select="normalize-space($contribs-der[2]/name/surname)"/>
          <xsl:text>, </xsl:text>
          <xsl:value-of select="substring(
            normalize-space($contribs-der[2]/name/given-names), 1, 1)"/>
          <xsl:text>.</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space($contribs-der[1]/name/surname)"/>
          <xsl:text>, </xsl:text>
          <xsl:value-of select="substring(
            normalize-space($contribs-der[1]/name/given-names), 1, 1)"/>
          <xsl:text>. et al.</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="lic-texto-der">
      <xsl:choose>
        <xsl:when test="contains($lic-url-der, 'by/4.0')">
          <xsl:text>Se permite el uso, distribución y reproducción sin restricciones, incluso con fines comerciales, siempre que se cite la obra original.</xsl:text>
        </xsl:when>
        <xsl:when test="contains($lic-url-der, 'by-nc-sa/4.0')">
          <xsl:text>Se permite el uso, distribución y reproducción sin fines comerciales, siempre que se cite la obra original y las obras derivadas se distribuyan bajo la misma licencia.</xsl:text>
        </xsl:when>
        <xsl:when test="contains($lic-url-der, 'by-nc-nd/4.0')">
          <xsl:text>Se permite el uso y distribución sin fines comerciales, siempre que se cite la obra original y no se realicen obras derivadas.</xsl:text>
        </xsl:when>
        <xsl:when test="contains($lic-url-der, 'by-nc/4.0')">
          <xsl:text>Se permite el uso, distribución y reproducción sin fines comerciales, siempre que se cite la obra original.</xsl:text>
        </xsl:when>
        <xsl:when test="contains($lic-url-der, 'by-sa/4.0')">
          <xsl:text>Se permite el uso, distribución y reproducción, incluso con fines comerciales, siempre que se cite la obra original y las obras derivadas se distribuyan bajo la misma licencia.</xsl:text>
        </xsl:when>
        <xsl:when test="contains($lic-url-der, 'by-nd/4.0')">
          <xsl:text>Se permite el uso y distribución, incluso con fines comerciales, siempre que se cite la obra original y no se realicen obras derivadas.</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space(
            front/article-meta/permissions/license/license-p)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="$lic-url-der != '' or $autores-copyright != ''">
      <!-- ETIQUETA — MISMO ESTILO QUE Publicación, DOI, etc. -->
      <xsl:text>{\bfseries\color{azulrevista!70}Derechos de autor\'ia:}\par&#10;</xsl:text>
      <!-- © AUTOR — LÍNEA NUEVA, MISMO TAMAÑO QUE EL RESTO DE LA COLUMNA -->
      <xsl:text>\textcopyright\ </xsl:text>
      <xsl:value-of select="$anio-pub"/>
      <xsl:text> </xsl:text>
      <xsl:value-of select="f:latex($autores-copyright)"/>
      <xsl:text> Publicado por </xsl:text>
      <xsl:value-of select="f:latex(normalize-space(
        front/journal-meta/journal-title-group/journal-title))"/>
      <xsl:text>. </xsl:text>
      <!-- TEXTO DESCRIPTIVO — CONTINÚA EN EL MISMO PÁRRAFO, MISMO TAMAÑO -->
      <xsl:value-of select="f:latex($lic-texto-der)"/>
      <xsl:if test="$lic-url-der != ''">
        <xsl:text> (\href{</xsl:text>
        <xsl:value-of select="$lic-url-der"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="$lic-url-der"/>
        <xsl:text>})</xsl:text>
      </xsl:if>
      <xsl:text>\par\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 2. DATOS DE PUBLICACIÓN -->
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

    <!-- 3. URL -->
    <xsl:if test="$url_articulo != ''">
      <xsl:text>{\bfseries\color{azulrevista!70}</xsl:text>
      <xsl:choose>
        <xsl:when test="$xmlLang = 'es'">URL</xsl:when>
        <xsl:when test="$xmlLang = 'en'">URL</xsl:when>
        <xsl:when test="$xmlLang = 'pt'">URL</xsl:when>
        <xsl:otherwise>URL</xsl:otherwise>
      </xsl:choose>
      <xsl:text>:} {\scriptsize\texttt{\href{</xsl:text>
      <xsl:value-of select="$url_articulo"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="$url_articulo"/>
      <xsl:text>}}}\par\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 4. DOI -->
    <xsl:variable name="doi-lat"
      select="normalize-space(front/article-meta/article-id[@pub-id-type='doi'])"/>
    <xsl:if test="$doi-lat != ''">
      <xsl:text>{\bfseries\color{azulrevista!70}DOI:} {\scriptsize\texttt{\href{https://doi.org/</xsl:text>
      <xsl:value-of select="$doi-lat"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="$doi-lat"/>
      <xsl:text>}}}\par\vspace{6pt}&#10;</xsl:text>
    </xsl:if>

    <!-- 5. LICENCIA -->
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

    <!-- 6. FECHAS -->
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


<!-- N. COMPARTIR EN REDES SOCIALES -->
    <xsl:if test="$url_articulo != ''">
      <xsl:variable name="url-enc" select="encode-for-uri($url_articulo)"/>
      <xsl:variable name="tit-enc" select="encode-for-uri(
        normalize-space(front/article-meta/title-group/article-title))"/>
      <xsl:text>\vspace{6pt}&#10;</xsl:text>
      <xsl:text>{\bfseries\color{azulrevista!70}</xsl:text>
      <xsl:choose>
        <xsl:when test="$xmlLang = 'es'">Compartir</xsl:when>
        <xsl:when test="$xmlLang = 'en'">Share</xsl:when>
        <xsl:when test="$xmlLang = 'pt'">Compartilhar</xsl:when>
        <xsl:otherwise>Compartir</xsl:otherwise>
      </xsl:choose>
      <xsl:text>:}\par\vspace{3pt}&#10;</xsl:text>
      <xsl:text>{\large&#10;</xsl:text>
      <!-- BLUESKY -->
      <xsl:text>\href{https://bsky.app/intent/compose?text=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>bluesky}}~&#10;</xsl:text>
      <!-- EMAIL -->
      <xsl:text>\href{mailto:?subject=</xsl:text>
      <xsl:value-of select="$tit-enc"/>
      <xsl:text>&amp;body=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>envelope}}~&#10;</xsl:text>
      <!-- FACEBOOK -->
      <xsl:text>\href{https://www.facebook.com/sharer/sharer.php?u=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>facebook}}~&#10;</xsl:text>
      <!-- LINKEDIN -->
      <xsl:text>\href{https://www.linkedin.com/sharing/share-offsite/?url=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>linkedin}}~&#10;</xsl:text>
      <!-- REDDIT -->
      <xsl:text>\href{https://www.reddit.com/submit?url=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>&amp;title=</xsl:text>
      <xsl:value-of select="$tit-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>reddit}}~&#10;</xsl:text>
      <!-- RESEARCHGATE -->
      <xsl:text>\href{https://www.researchgate.net/search?q=</xsl:text>
      <xsl:value-of select="$tit-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>researchgate}}~&#10;</xsl:text>
      <!-- TELEGRAM -->
      <xsl:text>\href{https://t.me/share/url?url=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>&amp;text=</xsl:text>
      <xsl:value-of select="$tit-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>telegram}}~&#10;</xsl:text>
      <!-- WHATSAPP -->
      <xsl:text>\href{https://wa.me/?text=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>whatsapp}}~&#10;</xsl:text>
      <!-- X / TWITTER -->
      <xsl:text>\href{https://twitter.com/intent/tweet?url=</xsl:text>
      <xsl:value-of select="$url-enc"/>
      <xsl:text>&amp;text=</xsl:text>
      <xsl:value-of select="$tit-enc"/>
      <xsl:text>}{\includesvg[height=0.9em]{</xsl:text>
      <xsl:value-of select="$ruta_fonts"/>
      <xsl:text>x-twitter}}&#10;</xsl:text>
      <xsl:text>}\par&#10;</xsl:text>
    </xsl:if>

    <xsl:text>\end{minipage}%&#10;</xsl:text>
    <xsl:text>}% FIN GRUPO leftskip&#10;</xsl:text>
    <xsl:text>\end{textblock*}&#10;&#10;</xsl:text>

  </xsl:template>

</xsl:stylesheet>
