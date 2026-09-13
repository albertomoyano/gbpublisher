<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : docbook-to-latex.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : TRANSFORMA UN CANÓNICO DocBook 5.2 DE LIBRO
                   EN UN FRAGMENTO LATEX. LA SALIDA NO ES UN
                   DOCUMENTO COMPLETO: SIN PREÁMBULO, SIN
                   \begin{document}, SIN \input DE NADA.
                   ES LO QUE \include NECESITA.
  MOTOR          : LuaLaTeX
  ENTRADA        : {proyecto}/docbook/c-{sec}-{NN}-{nombre}.xml
                   RAÍZ: chapter | preface | acknowledgements |
                         appendix | colophon | dedication
                   TAMBIÉN ACEPTA <book> ENTERO, ÚTIL PARA
                   PROBAR EL VOCABULARIO DE UNA SOLA CORRIDA.
  SALIDA         : {proyecto}/latex/c-{sec}-{NN}-{nombre}.tex
  ENSAMBLADO     : EL main.tex LO ESCRIBE GAMBAS. ESTA HOJA NO
                   SABE NADA DEL ORDEN NI DE LOS \include.
  DEPENDENCIA    : tex-comun.xsl
  ============================================================
  PRINCIPIO DE DISEÑO — SEMÁNTICA, NO MAQUETACIÓN
    ESTA HOJA NO EMITE \newpage, \vspace, \clearpage, TAMAÑOS
    DE CUERPO NI COLORES. TODO ESO VIVE EN EL PREÁMBULO. ES LO
    QUE PERMITE QUE UNA EDITORIAL REEMPLACE EL PREÁMBULO ENTERO
    Y QUE ESTOS FRAGMENTOS SIGAN SIRVIENDO SIN TOCARLOS.
  ============================================================
  CONTRATO — MACROS Y ENTORNOS QUE ESTE FRAGMENTO PUEDE USAR
    TODO PREÁMBULO, PROPIO O DE EDITORIAL, DEBE DEFINIRLOS.
    ESTA LISTA ES LA VERSIÓN 1 DEL CONTRATO.

    CLASE
      \frontmatter \mainmatter \backmatter   (book, memoir, scrbook)

    ESTRUCTURA
      \chapter \chapter* \section \subsection \subsubsection
      \label \caption \footnote

    PÁGINAS ESPECIALES (fm/bm CON ORDEN 01–09)
      gbpaginaespecial   entorno — recto, sin folio, vuelta en blanco
      gbpaginaimagen     entorno — ídem, rompiendo la caja

    BLOQUES
      gbcita         entorno — cita en bloque
      \gbatribucion  macro   — atribución de la cita
      \gbepigrafe    macro   — {texto}{atribución}
      gbsidebar      entorno — un argumento: info | supplementary
      gbverso        entorno — literallayout role="verse"
      gbparlamento   entorno — para role="speech"
      \gblocutor     macro   — emphasis role="speaker"

    LLAMADAS DE ATENCIÓN
      gbnota gbconsejo gbadvertencia gbimportante gbprecaucion

    OTROS
      \enquote        (csquotes)   comillas según idioma
      \href \url      (hyperref)
      \includegraphics (graphicx)
      lstlisting      (listings)
      \parencite \parencite* \textcite \printbibliography (biblatex)
      refsection      entorno     (biblatex)
      \toprule \midrule \bottomrule (booktabs)
  ============================================================
  DATOS QUE LA HOJA LEE DEL PROPIO XML (RC-XJ-02)
    NO HAY PARÁMETROS DE SAXON PARA DATOS DE LA BASE. EL XML
    CANÓNICO DEBE SER AUTÓNOMO Y REPRODUCIBLE POR SÍ SOLO.
      bibliomisc[@role='csl-style']      estilo de cita
      bibliomisc[@role='seccion-libro']  fm | a | bm
      bibliomisc[@role='orden-seccion']  NN con dos dígitos
    LOS DOS ÚLTIMOS LOS ESCRIBE EL ENSAMBLADOR EN EL <info> DE
    CADA PIEZA. VERIFICADO CONTRA EL RELAX NG DE DocBook 5.2:
    bibliomisc ES VÁLIDO EN chapter/info, preface/info,
    acknowledgements/info, appendix/info, colophon/info Y
    dedication/info.
    SI FALTAN, LA HOJA NO ABORTA: ASUME PIEZA NORMAL DE CUERPO.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:f="urn:gbpublisher:functions"
  xpath-default-namespace="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs xlink f">

  <xsl:import href="tex-comun.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <!-- ============================================================ -->
  <!-- ESPACIO EN BLANCO                                            -->
  <!-- SE APLASTA SOLO EN ELEMENTOS ESTRUCTURALES. EN CONTENIDO     -->
  <!-- MIXTO NO SE TOCA, PORQUE UN ESPACIO ENTRE DOS ELEMENTOS      -->
  <!-- EN LÍNEA ES CONTENIDO Y NO INDENTACIÓN.                      -->
  <!-- ============================================================ -->
  <xsl:strip-space elements="
    book chapter preface appendix acknowledgements colophon dedication
    section info figure mediaobject imageobject textobject
    informaltable table tgroup thead tbody tfoot row
    itemizedlist orderedlist listitem variablelist varlistentry
    bibliography biblioentry biblioset epigraph blockquote sidebar
    note tip warning important caution keywordset subjectset"/>

  <xsl:preserve-space elements="literallayout programlisting"/>

  <!-- ============================================================ -->
  <!-- VARIABLE GLOBAL: $estilo                                     -->
  <!-- FAMILIA DE ESTILO DE CITA, SIN LA EXTENSIÓN .csl             -->
  <!-- SE USA SOLO PARA DECIDIR EL COMANDO DE CITA (VER LA NOTA     -->
  <!-- SOBRE 'suppress' EN tex-comun.xsl). LA MAQUETACIÓN DE LA     -->
  <!-- BIBLIOGRAFÍA LA RESUELVE EL PREÁMBULO.                       -->
  <!-- ============================================================ -->
  <xsl:variable name="estilo" as="xs:string" select="
    let $v := normalize-space((//bibliomisc[@role='csl-style'])[1])
    return if ($v = '') then 'apa' else lower-case(replace($v, '\.csl$', ''))"/>

  <!-- ============================================================ -->
  <!-- VARIABLE GLOBAL: $idioma                                     -->
  <!-- ============================================================ -->
  <xsl:variable name="idioma" as="xs:string" select="
    let $v := normalize-space((/*/@xml:lang, /*/*/@xml:lang)[1])
    return if ($v = '') then 'es' else $v"/>

  <!-- ============================================================ -->
  <!--                   RAÍZ                                       -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:recortar                                         -->
  <!-- PROPÓSITO: SACA EL ESPACIO DE INDENTACIÓN DEL PRINCIPIO Y    -->
  <!--            DEL FINAL DE UN BLOQUE YA SERIALIZADO.            -->
  <!-- PARÁMETROS: s As xs:string — texto emitido por el bloque     -->
  <!-- RETORNA  : xs:string — sin espacio en los bordes             -->
  <!-- RAZÓN    : PANDOC INDENTA EL CONTENIDO DE <para>. SIN ESTO   -->
  <!--            EL .tex SALE CON SANGRÍAS Y LÍNEAS EN BLANCO DE   -->
  <!--            MÁS. NO CAMBIA LA COMPOSICIÓN, PERO EL .tex ESTÁ  -->
  <!--            VERSIONADO Y SU DIFF TIENE QUE SER LEGIBLE.       -->
  <!-- ============================================================ -->
  <xsl:function name="f:recortar" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:value-of select="replace(replace($s, '^[ \t\r\n]+', ''),
                                            '[ \t\r\n]+$', '')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:modo-de                                          -->
  <!-- PROPÓSITO: MODO EFECTIVO DE UN <biblioref>. SIN @role EL     -->
  <!--            MODO ES 'normal'.                                 -->
  <!-- PARÁMETROS: n As node()? — el biblioref, o vacío             -->
  <!-- RETORNA  : xs:string — normal | author-in-text | suppress    -->
  <!-- ============================================================ -->
  <xsl:function name="f:modo-de" as="xs:string">
    <xsl:param name="n" as="node()?"/>
    <xsl:variable name="r" select="normalize-space($n/@role)"/>
    <xsl:value-of select="if (empty($n)) then ''
                          else if ($r = '') then 'normal' else $r"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- GUARDA DE MOTOR BIBLIOGRÁFICO                                -->
  <!-- LA HOJA IMPLEMENTA LA RAMA biblatex: apa, iso690 e ieee.     -->
  <!-- vancouver VA POR bibtex Y NECESITA OTRO JUEGO DE COMANDOS    -->
  <!-- (\cite EN LUGAR DE \parencite, PREFIJO COMO TEXTO LIBRE) Y  -->
  <!-- OTRO MECANISMO DE BIBLIOGRAFÍA POR CAPÍTULO, PORQUE          -->
  <!-- refsection ES DE biblatex. EL CANDIDATO ES chapterbib, QUE   -->
  <!-- SE APOYA EN EL .aux POR ARCHIVO QUE GENERA \include, PERO    -->
  <!-- NO ESTÁ VERIFICADO Y CAMBIA LA ORQUESTACIÓN DEL COMPILADOR:  -->
  <!-- OBLIGA A CORRER bibtex UNA VEZ POR CAPÍTULO.                 -->
  <!-- SE CORTA ACÁ EN VEZ DE EMITIR UN .tex QUE NO COMPILA, O QUE  -->
  <!-- COMPILA CON LAS REFERENCIAS MAL.                             -->
  <!-- ============================================================ -->
  <xsl:template match="/">
    <xsl:if test="f:motor-cita($estilo) != 'biblatex'">
      <xsl:message terminate="yes">
        <xsl:text>&#10;[docbook-to-latex] MOTOR BIBLIOGRÁFICO NO IMPLEMENTADO&#10;</xsl:text>
        <xsl:text>  Estilo del proyecto : </xsl:text>
        <xsl:value-of select="$estilo"/>
        <xsl:text>&#10;  Motor que requiere  : </xsl:text>
        <xsl:value-of select="f:motor-cita($estilo)"/>
        <xsl:text>&#10;&#10;  La salida PDF de libros está implementada para biblatex</xsl:text>
        <xsl:text>&#10;  (apa, iso690, ieee). Cambiar el estilo del proyecto, o</xsl:text>
        <xsl:text>&#10;  implementar y verificar la rama bibtex antes de seguir.&#10;</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:apply-templates select="*"/>
  </xsl:template>

  <!-- LIBRO COMPLETO: SOLO PARA PRUEBA DEL VOCABULARIO.            -->
  <!-- EN PRODUCCIÓN LA ENTRADA ES UNA PIEZA POR ARCHIVO Y EL       -->
  <!-- ORDEN LO PONE EL main.tex QUE ESCRIBE GAMBAS.                -->
  <xsl:template match="book">
    <xsl:apply-templates select="* except info"/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PIEZAS DE NIVEL LIBRO                                        -->
  <!-- ============================================================ -->

  <xsl:template match="chapter | preface | acknowledgements |
                       appendix | colophon | dedication">

    <!-- 1. CLASIFICACIÓN DE LA PIEZA -->
    <xsl:variable name="seccion"
      select="normalize-space(info/bibliomisc[@role='seccion-libro'])"/>
    <!-- tipo_capitulo DE LA BASE. ES LA SEÑAL FUERTE: DICE LA        -->
    <!-- FUNCIÓN EDITORIAL DE LA PIEZA Y DE AHÍ SALE SI SE NUMERA.    -->
    <!-- LA CARPETA NO ALCANZA: UNAS CONCLUSIONES VIVEN EN bm/ PERO   -->
    <!-- VAN EN LA ZONA DE CUERPO, SIN NUMERAR, ANTES DE \appendix,   -->
    <!-- PARA QUE LOS APÉNDICES POSTERIORES NUMEREN CON LETRA.        -->
    <xsl:variable name="tipo"
      select="normalize-space(info/bibliomisc[@role='tipo-capitulo'])"/>
    <xsl:variable name="orden"
      select="normalize-space(info/bibliomisc[@role='orden-seccion'])"/>
    <!-- EN fm Y bm LOS NÚMEROS 01 A 09 ESTÁN RESERVADOS PARA PIEZAS -->
    <!-- SUELTAS: UNA FOTO A PÁGINA ENTERA, UN RECORDATORIO, UNA    -->
    <!-- DEDICATORIA. NO SON CAPÍTULOS Y NO ENTRAN AL ÍNDICE.       -->
    <xsl:variable name="especial" as="xs:boolean" select="
      $seccion = ('fm', 'bm')
      and $orden castable as xs:integer
      and xs:integer($orden) &lt; 10"/>

    <!-- 2. HAY QUE ABRIR refsection -->
    <!-- CADA PIEZA ES AUTOCONTENIDA: ABRE SU PROPIA refsection Y   -->
    <!-- EMITE SU \printbibliography SIN NÚMERO. ASÍ \includeonly   -->
    <!-- NO DESPLAZA LA NUMERACIÓN DE LAS SECCIONES BIBLIOGRÁFICAS. -->
    <xsl:variable name="conCitas" as="xs:boolean"
      select="exists(.//biblioref) or exists(.//bibliography)"/>

    <xsl:choose>

      <!-- PÁGINA ESPECIAL: SIN \chapter, SIN ÍNDICE, SIN FOLIO.    -->
      <!-- EL TÍTULO EXISTE PARA HTML Y PARA EL nav DEL EPUB; ACÁ   -->
      <!-- SE DESCARTA A PROPÓSITO.                                 -->
      <xsl:when test="$especial">
        <xsl:variable name="entorno" select="
          if (exists(.//mediaobject) and not(.//para[normalize-space()]))
          then 'gbpaginaimagen' else 'gbpaginaespecial'"/>
        <xsl:text>&#10;\begin{</xsl:text>
        <xsl:value-of select="$entorno"/>
        <xsl:text>}&#10;</xsl:text>
        <xsl:apply-templates select="* except info"/>
        <xsl:text>\end{</xsl:text>
        <xsl:value-of select="$entorno"/>
        <xsl:text>}&#10;&#10;</xsl:text>
      </xsl:when>

      <!-- PIEZA NORMAL -->
      <xsl:otherwise>
        <xsl:if test="$conCitas">
          <xsl:text>&#10;\begin{refsection}&#10;</xsl:text>
        </xsl:if>

        <!-- LOS PRELIMINARES Y POSLIMINARES NO SE NUMERAN, PERO SÍ -->
        <!-- ENTRAN AL ÍNDICE GENERAL: POR ESO \chapter* MÁS        -->
        <!-- \addcontentsline Y NO \chapter A SECAS.                -->
        <!-- SOLO DOS TIPOS LLEVAN NÚMERO: EL CAPÍTULO CORRIENTE Y  -->
        <!-- EL APÉNDICE, QUE NUMERA CON LETRA POR EFECTO DE          -->
        <!-- \appendix. TODO LO DEMÁS VA CON \chapter* MÁS            -->
        <!-- \addcontentsline, QUE ENTRA AL SUMARIO SIN NÚMERO.       -->
        <!-- SIN tipo-capitulo SE CAE AL CRITERIO DE CARPETA, QUE ES  -->
        <!-- LO ÚNICO DISPONIBLE MIENTRAS EL ENSAMBLADOR NO LO EMITA. -->
        <xsl:variable name="numerado" as="xs:boolean" select="
          if ($tipo != '')
          then $tipo = ('capitulo', 'apendice')
          else (self::chapter and $seccion != 'fm' and $seccion != 'bm')"/>
        <xsl:variable name="titulo"
          select="normalize-space((info/title, title)[1])"/>

        <xsl:text>&#10;\chapter</xsl:text>
        <xsl:if test="not($numerado)">
          <xsl:text>*</xsl:text>
        </xsl:if>
        <xsl:text>{</xsl:text>
        <xsl:value-of select="f:latex($titulo)"/>
        <xsl:text>}&#10;</xsl:text>
        <xsl:if test="not($numerado)">
          <xsl:text>\addcontentsline{toc}{chapter}{</xsl:text>
          <xsl:value-of select="f:latex($titulo)"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="@xml:id">
          <xsl:text>\label{</xsl:text>
          <xsl:value-of select="@xml:id"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:if>
        <xsl:text>&#10;</xsl:text>

        <xsl:apply-templates select="* except info"/>

        <xsl:if test="$conCitas">
          <xsl:text>&#10;\printbibliography[heading=subbibliography]&#10;</xsl:text>
          <xsl:text>\end{refsection}&#10;&#10;</xsl:text>
        </xsl:if>
      </xsl:otherwise>

    </xsl:choose>
  </xsl:template>

  <!-- EL <info> DE UNA PIEZA SOLO APORTA EL TÍTULO, YA CONSUMIDO.  -->
  <xsl:template match="info"/>

  <!-- ============================================================ -->
  <!-- SECCIONES                                                    -->
  <!-- PROFUNDIDAD = CANTIDAD DE ANCESTROS section                  -->
  <!-- ============================================================ -->

  <xsl:template match="section">
    <xsl:variable name="prof" select="count(ancestor::section)"/>
    <xsl:variable name="titulo" select="normalize-space((info/title, title)[1])"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:choose>
      <xsl:when test="$prof = 0">\section{</xsl:when>
      <xsl:when test="$prof = 1">\subsection{</xsl:when>
      <xsl:when test="$prof = 2">\subsubsection{</xsl:when>
      <xsl:otherwise>\paragraph{</xsl:otherwise>
    </xsl:choose>
    <xsl:value-of select="f:latex($titulo)"/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:if test="@xml:id">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="@xml:id"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="* except (info | title)"/>
  </xsl:template>

  <!-- EL TÍTULO LO EMITE EL PADRE. ACÁ SE SUPRIME PARA QUE NO SE   -->
  <!-- CUELE COMO TEXTO SUELTO.                                     -->
  <xsl:template match="chapter/title | preface/title | section/title |
                       appendix/title | acknowledgements/title |
                       colophon/title | dedication/title"/>

  <!-- ============================================================ -->
  <!-- PÁRRAFOS Y TEXTO                                             -->
  <!-- ============================================================ -->

  <xsl:template match="para">
    <xsl:variable name="c"><xsl:apply-templates/></xsl:variable>
    <xsl:value-of select="f:recortar(string($c))"/>
    <xsl:text>&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- PARLAMENTO: para role="speech" -->
  <xsl:template match="para[@role='speech']" priority="5">
    <xsl:text>\begin{gbparlamento}&#10;</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>&#10;\end{gbparlamento}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- PÁRRAFO DENTRO DE UN ÍTEM O DE UNA NOTA: SIN DOBLE SALTO     -->
  <!-- FINAL, QUE ABRIRÍA UN PÁRRAFO VACÍO.                         -->
  <xsl:template match="listitem/para | footnote/para | entry/para |
                       attribution/para | epigraph/para">
    <xsl:variable name="c"><xsl:apply-templates/></xsl:variable>
    <xsl:value-of select="f:recortar(string($c))"/>
    <xsl:if test="following-sibling::para">
      <xsl:text>&#10;&#10;</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="f:latex(.)"/>
  </xsl:template>

  <!-- CONTENIDO LITERAL: PASA CRUDO, SIN ESCAPAR. -->
  <xsl:template match="programlisting//text() | literallayout//text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- MARCAS EN LÍNEA                                              -->
  <!-- ============================================================ -->

  <!-- \emph Y NO \textit: ALTERNA AL ANIDAR. -->
  <xsl:template match="emphasis">
    <xsl:text>\emph{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="emphasis[@role='strong']" priority="5">
    <xsl:text>\textbf{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="emphasis[@role='speaker']" priority="5">
    <xsl:text>\gblocutor{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="literal | code | command | filename">
    <xsl:text>\texttt{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- \enquote RESUELVE LAS COMILLAS SEGÚN EL IDIOMA ACTIVO: EN    -->
  <!-- ESPAÑOL DA « ». NO EMITIR COMILLAS LITERALES ACÁ.            -->
  <xsl:template match="quote">
    <xsl:text>\enquote{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="subscript">
    <xsl:text>\textsubscript{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="superscript">
    <xsl:text>\textsuperscript{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- phrase SIN role: TRANSPARENTE. LOS role DE CITA SE ABSORBEN  -->
  <!-- EN LA PLANTILLA DE biblioref Y SE SUPRIMEN ACÁ.              -->
  <xsl:template match="phrase">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="phrase[@role = ('cite-prefix', 'cite-suffix')]"
                priority="5"/>

  <xsl:template match="link[@xlink:href]">
    <xsl:text>\href{</xsl:text>
    <xsl:value-of select="f:latex-url(@xlink:href)"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="uri">
    <xsl:text>\url{</xsl:text>
    <xsl:value-of select="f:latex-url(string(.))"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="footnote">
    <xsl:variable name="c"><xsl:apply-templates/></xsl:variable>
    <xsl:text>\footnote{</xsl:text>
    <xsl:value-of select="f:recortar(string($c))"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <xsl:template match="xref[@linkend]">
    <xsl:text>\ref{</xsl:text>
    <xsl:value-of select="@linkend"/>
    <xsl:text>}</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- CITAS BIBLIOGRÁFICAS                                         -->
  <!-- ============================================================ -->
  <!-- LA CITA NO ES UN NODO: ES UNA SECUENCIA DE HERMANOS.         -->
  <!--   <phrase role="cite-prefix">ver</phrase>                    -->
  <!--   <biblioref linkend="cap-N-bib-CLAVE" role="..."/>          -->
  <!--   <phrase role="cite-suffix">pp. 55-60</phrase>              -->
  <!-- SE RECONSTRUYE ACÁ Y SE VUELCA EN LOS DOS ARGUMENTOS         -->
  <!-- OPCIONALES DE biblatex.                                      -->
  <!--                                                             -->
  <!-- CLAVE DE CITA: SE QUITA EL PREFIJO DEL linkend.             -->
  <!-- EL PREFIJO NO ES EL MISMO EN LOS DOS CANÓNICOS:              -->
  <!--   por capítulo   bib-3290-ACOSTA2012                         -->
  <!--   ensamblado     cap-7-bib-3290-ACOSTA2012                   -->
  <!-- EL 'cap-N-' LO AGREGA EL ENSAMBLADOR PARA QUE LOS ids NO     -->
  <!-- COLISIONEN ENTRE CAPÍTULOS. LA HOJA TIENE QUE ACEPTAR LAS    -->
  <!-- DOS FORMAS, PORQUE EN PRODUCCIÓN LA ENTRADA ES UNA PIEZA POR -->
  <!-- ARCHIVO Y EL ENSAMBLADO SOLO SE USA PARA PROBAR.             -->
  <!-- LO QUE QUEDA ES LA CLAVE DEL .bib QUE GENERA LA APP.         -->
  <!-- ============================================================ -->
  <xsl:template match="biblioref">
    <xsl:variable name="modo" select="f:modo-de(.)"/>
    <xsl:variable name="clave"
      select="replace(normalize-space(@linkend), '^(cap-\d+-)?bib-', '')"/>
    <xsl:variable name="pre"
      select="preceding-sibling::*[1][self::phrase][@role='cite-prefix']"/>
    <xsl:variable name="post"
      select="following-sibling::*[1][self::phrase][@role='cite-suffix']"/>

    <!-- ESTE biblioref YA FUE ABSORBIDO POR EL GRUPO DEL ANTERIOR: -->
    <!-- NO EMITE NADA. VER LA NOTA SOBRE AGRUPAMIENTO ABAJO.       -->
    <xsl:if test="not(f:es-continuacion(.))">

    <!-- \protect ES OBLIGATORIO: LOS COMANDOS DE CITA DE biblatex
         NO SON ROBUSTOS Y LOS ARGUMENTOS DE \caption, \chapter Y
         \section SON MÓVILES — SE REESCRIBEN AL .toc Y AL .lof Y
         SE REEXPANDEN AHÍ. SIN \protect, UNA CITA EN UN PIE DE
         FIGURA PRODUCE UNA SEGUNDA CITA CON CLAVE VACÍA:
           LaTeX Warning: Citation '' on page 2 undefined
         QUE NO DICE NADA SOBRE LA CAUSA. VERIFICADO.
         FUERA DE UN ARGUMENTO MÓVIL \protect NO HACE NADA, ASÍ
         QUE SE EMITE SIEMPRE EN VEZ DE DETECTAR EL CONTEXTO. -->
    <xsl:text>\protect</xsl:text>
    <xsl:value-of select="f:comando-cita($modo, $estilo)"/>

    <!-- biblatex CON UN SOLO [] LO INTERPRETA COMO POSTNOTA.       -->
    <!-- CON PREFIJO Y SIN SUFIJO HAY QUE EMITIR [pre][] PARA       -->
    <!-- FORZAR QUE EL PRIMERO SE LEA COMO PRENOTA.                 -->
    <xsl:choose>
      <xsl:when test="$pre and $post">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="$pre/node()"/>
        <xsl:text>][</xsl:text>
        <xsl:apply-templates select="$post/node()"/>
        <xsl:text>]</xsl:text>
      </xsl:when>
      <xsl:when test="$pre">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="$pre/node()"/>
        <xsl:text>][]</xsl:text>
      </xsl:when>
      <xsl:when test="$post">
        <xsl:text>[</xsl:text>
        <xsl:apply-templates select="$post/node()"/>
        <xsl:text>]</xsl:text>
      </xsl:when>
    </xsl:choose>

    <xsl:text>{</xsl:text>
    <xsl:value-of select="$clave"/>
    <xsl:call-template name="acumular-claves">
      <xsl:with-param name="desde" select="following-sibling::node()"/>
      <xsl:with-param name="modo"  select="$modo"/>
    </xsl:call-template>
    <xsl:text>}</xsl:text>

    </xsl:if>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- AGRUPAMIENTO DE CITAS CONSECUTIVAS                           -->
  <!-- [@a; @b; @c] LLEGA AL CANÓNICO COMO TRES <biblioref>         -->
  <!-- SEPARADOS POR NODOS DE TEXTO ', '. EN biblatex ESO ES UN     -->
  <!-- SOLO COMANDO CON LAS CLAVES SEPARADAS POR COMA, QUE ES LO    -->
  <!-- QUE PERMITE AL ESTILO ORDENARLAS Y COMPRIMIR RANGOS.         -->
  <!-- SE AGRUPA SOLO CUANDO EL MODO COINCIDE Y NINGUNA DE LAS DOS  -->
  <!-- LLEVA PREFIJO NI SUFIJO: LOS AFIJOS SON POR CLAVE Y NO       -->
  <!-- SOBREVIVEN AL AGRUPAMIENTO.                                  -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:sin-afijos                                       -->
  <!-- PROPÓSITO: DICE SI UN biblioref NO TIENE PREFIJO NI SUFIJO   -->
  <!-- PARÁMETROS: n As node() — el biblioref                       -->
  <!-- RETORNA  : xs:boolean                                        -->
  <!-- ============================================================ -->
  <xsl:function name="f:sin-afijos" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="
      empty($n/preceding-sibling::*[1][self::phrase][@role='cite-prefix'])
      and empty($n/following-sibling::*[1][self::phrase][@role='cite-suffix'])"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:es-separador                                     -->
  <!-- PROPÓSITO: DICE SI UN NODO ES EL TEXTO QUE SEPARA DOS CITAS  -->
  <!--            AGRUPABLES (COMA, PUNTO Y COMA O GUION SUELTO).   -->
  <!-- PARÁMETROS: n As node()? — nodo a evaluar                    -->
  <!-- RETORNA  : xs:boolean                                        -->
  <!-- ============================================================ -->
  <xsl:function name="f:es-separador" as="xs:boolean">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="exists($n[self::text()])
      and matches(string($n), '^\s*[,;\p{Pd}]\s*$')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:es-continuacion                                  -->
  <!-- PROPÓSITO: DICE SI ESTE biblioref YA FUE ABSORBIDO POR EL    -->
  <!--            GRUPO DEL biblioref ANTERIOR.                     -->
  <!-- PARÁMETROS: n As node() — el biblioref                       -->
  <!-- RETORNA  : xs:boolean                                        -->
  <!-- ============================================================ -->
  <xsl:function name="f:es-continuacion" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:variable name="p1" select="$n/preceding-sibling::node()[1]"/>
    <xsl:variable name="p2" select="$n/preceding-sibling::node()[2]"/>
    <xsl:sequence select="
      f:es-separador($p1)
      and exists($p2[self::biblioref])
      and f:modo-de($p2) = f:modo-de($n)
      and f:sin-afijos($n) and f:sin-afijos($p2)"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: acumular-claves                                   -->
  <!-- PROPÓSITO: AGREGA AL COMANDO EN CURSO LAS CLAVES DE LOS      -->
  <!--            biblioref CONSECUTIVOS DEL MISMO MODO.            -->
  <!-- PARÁMETROS: desde As node()* — hermanos siguientes           -->
  <!--             modo  As xs:string — modo del grupo              -->
  <!-- RETORNA  : texto ',clave' repetido, o nada                   -->
  <!-- ============================================================ -->
  <xsl:template name="acumular-claves">
    <xsl:param name="desde" as="node()*"/>
    <xsl:param name="modo"  as="xs:string"/>
    <xsl:if test="count($desde) &gt;= 2">
      <xsl:variable name="sep"  select="$desde[1]"/>
      <xsl:variable name="sig"  select="$desde[2]"/>
      <xsl:if test="f:es-separador($sep)
                    and exists($sig[self::biblioref])
                    and f:modo-de($sig) = $modo
                    and f:sin-afijos($sig)">
        <xsl:text>,</xsl:text>
        <xsl:value-of select="replace(normalize-space($sig/@linkend),
                                      '^(cap-\d+-)?bib-', '')"/>
        <xsl:call-template name="acumular-claves">
          <xsl:with-param name="desde" select="$desde[position() &gt; 2]"/>
          <xsl:with-param name="modo"  select="$modo"/>
        </xsl:call-template>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- SEPARADOR ENTRE DOS CITAS QUE SE AGRUPARON: SE SUPRIME,      -->
  <!-- PORQUE LA COMA YA VA DENTRO DEL ARGUMENTO DEL COMANDO.       -->
  <xsl:template match="text()[f:es-separador(.)]
      [following-sibling::node()[1][self::biblioref]
        [f:es-continuacion(.)]]" priority="6"/>

  <!-- ESPACIO DE INDENTACIÓN ENTRE LAS PARTES DE UNA CITA.         -->
  <!-- SE ABSORBE PARA QUE NO SALGA '(ver  García 2020)'. NO SE     -->
  <!-- USA strip-space GLOBAL PORQUE ESO BORRARÍA TAMBIÉN EL        -->
  <!-- ESPACIO LEGÍTIMO ENTRE DOS ELEMENTOS EN LÍNEA.               -->
  <xsl:template match="text()[not(normalize-space())]
      [preceding-sibling::node()[1][self::phrase[@role='cite-prefix']
                                    or self::biblioref]]
      [following-sibling::node()[1][self::biblioref
                                    or self::phrase[@role='cite-suffix']]]"
      priority="5"/>

  <!-- LA LISTA DE REFERENCIAS LA CONSTRUYE biblatex DESDE EL .bib. -->
  <!-- EL <bibliography> DEL CANÓNICO ES PARA HTML Y EPUB.          -->
  <!-- ATENCIÓN: biblatex IMPRIME LO CITADO, NO LO LISTADO. SI      -->
  <!-- ALGUNA VEZ UNA ENTRADA APARECE EN <bibliography> SIN ESTAR   -->
  <!-- CITADA, LAS DOS RAMAS DIVERGEN Y HACE FALTA UN \nocite.      -->
  <xsl:template match="bibliography"/>

  <!-- ============================================================ -->
  <!-- LISTAS                                                       -->
  <!-- ============================================================ -->

  <xsl:template match="itemizedlist">
    <xsl:text>&#10;\begin{itemize}&#10;</xsl:text>
    <xsl:apply-templates select="listitem"/>
    <xsl:text>\end{itemize}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="orderedlist">
    <xsl:text>&#10;\begin{enumerate}&#10;</xsl:text>
    <xsl:apply-templates select="listitem"/>
    <xsl:text>\end{enumerate}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="listitem">
    <xsl:variable name="c"><xsl:apply-templates/></xsl:variable>
    <xsl:text>  \item </xsl:text>
    <xsl:value-of select="f:recortar(string($c))"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="variablelist">
    <xsl:text>&#10;\begin{description}&#10;</xsl:text>
    <xsl:apply-templates select="varlistentry"/>
    <xsl:text>\end{description}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="varlistentry">
    <xsl:text>  \item[</xsl:text>
    <xsl:apply-templates select="term"/>
    <xsl:text>] </xsl:text>
    <xsl:apply-templates select="listitem/node()"/>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="term">
    <xsl:variable name="c"><xsl:apply-templates/></xsl:variable>
    <xsl:value-of select="f:recortar(string($c))"/>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- BLOQUES                                                      -->
  <!-- ============================================================ -->

  <!-- CITA EN BLOQUE. UNA CITA CON ATRIBUCIÓN NO ES UN EPÍGRAFE:   -->
  <!-- SON DOS COSAS DISTINTAS Y DOCBOOK LAS DISTINGUE.             -->
  <xsl:template match="blockquote">
    <xsl:text>&#10;\begin{gbcita}&#10;</xsl:text>
    <xsl:apply-templates select="* except (attribution | info | title)"/>
    <xsl:if test="attribution">
      <xsl:text>\gbatribucion{</xsl:text>
      <xsl:apply-templates select="attribution/node()"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>
    <xsl:text>\end{gbcita}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="epigraph">
    <xsl:text>&#10;\gbepigrafe{</xsl:text>
    <xsl:apply-templates select="* except attribution"/>
    <xsl:text>}{</xsl:text>
    <xsl:apply-templates select="attribution/node()"/>
    <xsl:text>}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="attribution">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="sidebar">
    <xsl:text>&#10;\begin{gbsidebar}{</xsl:text>
    <xsl:value-of select="if (normalize-space(@role) != '')
                          then normalize-space(@role) else 'info'"/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:apply-templates select="* except (info | title)"/>
    <xsl:text>\end{gbsidebar}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- VERSO: LOS SALTOS DE LÍNEA SON EL CONTENIDO. SE PARTE EL     -->
  <!-- TEXTO POR LÍNEA Y SE EMITE \\ ENTRE ELLAS, MENOS LA ÚLTIMA.  -->
  <xsl:template match="literallayout[@role='verse']" priority="5">
    <xsl:variable name="lineas" select="tokenize(string(.), '\n')"/>
    <xsl:variable name="utiles" select="
      for $l in $lineas return if (normalize-space($l) = '') then () else $l"/>
    <xsl:text>&#10;\begin{gbverso}&#10;</xsl:text>
    <xsl:for-each select="$utiles">
      <xsl:value-of select="f:latex(normalize-space(.))"/>
      <xsl:if test="position() != last()">
        <xsl:text>\\</xsl:text>
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>\end{gbverso}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="literallayout">
    <xsl:text>&#10;\begin{verbatim}&#10;</xsl:text>
    <xsl:value-of select="string(.)"/>
    <xsl:text>&#10;\end{verbatim}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="programlisting">
    <xsl:text>&#10;\begin{lstlisting}</xsl:text>
    <xsl:if test="normalize-space(@language) != ''">
      <xsl:text>[language=</xsl:text>
      <xsl:value-of select="normalize-space(@language)"/>
      <xsl:text>]</xsl:text>
    </xsl:if>
    <xsl:text>&#10;</xsl:text>
    <xsl:value-of select="string(.)"/>
    <xsl:text>&#10;\end{lstlisting}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- LLAMADAS DE ATENCIÓN -->
  <xsl:template match="note | tip | warning | important | caution">
    <xsl:variable name="ent">
      <xsl:choose>
        <xsl:when test="self::note">gbnota</xsl:when>
        <xsl:when test="self::tip">gbconsejo</xsl:when>
        <xsl:when test="self::warning">gbadvertencia</xsl:when>
        <xsl:when test="self::important">gbimportante</xsl:when>
        <xsl:otherwise>gbprecaucion</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:text>&#10;\begin{</xsl:text>
    <xsl:value-of select="$ent"/>
    <xsl:text>}&#10;</xsl:text>
    <xsl:apply-templates select="* except (info | title)"/>
    <xsl:text>\end{</xsl:text>
    <xsl:value-of select="$ent"/>
    <xsl:text>}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- FIGURAS E IMÁGENES                                           -->
  <!-- ============================================================ -->

  <xsl:template match="figure">
    <xsl:text>&#10;\begin{figure}[!ht]&#10;\centering&#10;</xsl:text>
    <xsl:apply-templates select=".//imagedata"/>
    <xsl:if test="(info/title, title)[1]">
      <xsl:text>\caption{</xsl:text>
      <!-- EL ARGUMENTO DE \caption ES MÓVIL: SE REESCRIBE AL .lof.  -->
      <!-- LAS MACROS DE CITA DEL CONTRATO DEBEN SER ROBUSTAS, O    -->
      <!-- ESTO REVIENTA CUANDO EL TÍTULO LLEVA UN <biblioref>.     -->
      <xsl:apply-templates select="(info/title, title)[1]/node()"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>
    <xsl:if test="@xml:id">
      <xsl:text>\label{</xsl:text>
      <xsl:value-of select="@xml:id"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:if>
    <xsl:text>\end{figure}&#10;&#10;</xsl:text>
  </xsl:template>

  <!-- LA TAPA NO VA EN EL PDF DEL INTERIOR: SE PRODUCE APARTE, EN  -->
  <!-- OTRO PROGRAMA, CON SANGRADOS Y LOMO.                         -->
  <xsl:template match="mediaobject[@role='tapa']" priority="5"/>

  <xsl:template match="mediaobject">
    <xsl:apply-templates select=".//imagedata"/>
  </xsl:template>

  <xsl:template match="imagedata">
    <xsl:text>\includegraphics[width=\linewidth]{</xsl:text>
    <xsl:value-of select="f:ruta-imagen(@fileref, '')"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:template>

  <!-- EL TEXTO ALTERNATIVO ES PARA HTML Y EPUB. EN PDF NO TIENE    -->
  <!-- DÓNDE IR. PRIMER CASO EN QUE UNA RAMA DESCARTA UN DATO QUE   -->
  <!-- LA OTRA USA: QUEDA ESCRITO A PROPÓSITO.                      -->
  <xsl:template match="textobject"/>

  <!-- ============================================================ -->
  <!-- TABLAS CALS                                                  -->
  <!-- ============================================================ -->
  <!-- LAS PROPORCIONES DE colwidth ('5*') SE TRADUCEN A COLUMNAS   -->
  <!-- p{} SOBRE \linewidth. SIN ESO, UNA TABLA DE NUEVE COLUMNAS   -->
  <!-- SE SALE DE LA CAJA EN CUALQUIER FORMATO DE LIBRO.            -->
  <!-- ============================================================ -->

  <xsl:template match="informaltable | table">
    <xsl:apply-templates select="tgroup"/>
  </xsl:template>

  <xsl:template match="tgroup">
    <xsl:variable name="props" as="xs:double*" select="
      for $c in colspec return
        let $w := normalize-space($c/@colwidth)
        return if (matches($w, '^[0-9.]+\*$'))
               then xs:double(replace($w, '\*$', ''))
               else 1.0"/>
    <xsl:variable name="total" select="if (sum($props) &gt; 0) then sum($props) else 1"/>
    <!-- SE DESCUENTA \tabcolsep POR COLUMNA PARA QUE LA SUMA DE     -->
    <!-- ANCHOS MÁS LOS FILETES NO EXCEDA \linewidth.               -->
    <xsl:text>&#10;\noindent\begin{tabular}{@{}</xsl:text>
    <xsl:for-each select="$props">
      <xsl:text>p{\dimexpr </xsl:text>
      <xsl:value-of select="format-number(. div $total, '0.0000')"/>
      <xsl:text>\linewidth - 2\tabcolsep\relax}</xsl:text>
    </xsl:for-each>
    <xsl:text>@{}}&#10;\toprule&#10;</xsl:text>
    <xsl:apply-templates select="thead/row"/>
    <xsl:if test="thead/row">
      <xsl:text>\midrule&#10;</xsl:text>
    </xsl:if>
    <xsl:apply-templates select="tbody/row"/>
    <xsl:text>\bottomrule&#10;\end{tabular}&#10;&#10;</xsl:text>
  </xsl:template>

  <xsl:template match="row">
    <xsl:for-each select="entry">
      <xsl:if test="position() &gt; 1">
        <xsl:text> &amp; </xsl:text>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="parent::row/parent::thead">
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

  <!-- LAS CELDAS COMBINADAS NO ESTÁN IMPLEMENTADAS. SE CORTA CON   -->
  <!-- MENSAJE EN VEZ DE EMITIR UNA TABLA CON LA CANTIDAD DE        -->
  <!-- COLUMNAS EQUIVOCADA, QUE DA UN 'Extra alignment tab' A       -->
  <!-- METROS DE LA CAUSA.                                          -->
  <xsl:template match="entry[@namest or @nameend or @morerows]" priority="5">
    <xsl:message terminate="yes">
      <xsl:text>&#10;[docbook-to-latex] CELDA COMBINADA NO IMPLEMENTADA&#10;</xsl:text>
      <xsl:text>  Se requiere \multicolumn / \multirow.&#10;</xsl:text>
    </xsl:message>
  </xsl:template>

  <xsl:template match="colspec"/>

  <!-- ============================================================ -->
  <!-- CAPTURA DE VOCABULARIO NO PREVISTO                           -->
  <!-- ABORTA. VER LA RAZÓN EN tex-comun.xsl.                       -->
  <!-- ============================================================ -->
  <xsl:template match="*" priority="-1">
    <xsl:call-template name="abortar-elemento">
      <xsl:with-param name="contexto" select="'docbook-to-latex'"/>
    </xsl:call-template>
  </xsl:template>

</xsl:stylesheet>
