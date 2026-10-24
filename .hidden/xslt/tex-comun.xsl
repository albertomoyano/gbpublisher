<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : tex-comun.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : MÓDULO PUENTE. CONTIENE LO QUE NO DEPENDE
                   DEL VOCABULARIO DE ENTRADA Y ES COMÚN A
                   LAS DOS RAMAS QUE GENERAN LATEX:
                     jats-to-latex.xsl     (artículos)
                     docbook-to-latex.xsl  (libros)
                   NO SE INVOCA DIRECTAMENTE: SE IMPORTA.
  MOTOR DE SALIDA: LuaLaTeX
  ============================================================
  CONTENIDO
    f:latex()         escape de texto para modo normal
    f:latex-url()     escape para el argumento de \href y \url
    f:titulo-tramos()     un título partido en sus cortes (SC-28)
    f:titulo-compuesto()  el título con \gbCorteTitulo (SC-28)
    f:titulo-plano()      el título en una línea (SC-28)
    f:babel-lang()    ISO 639-1 → nombre de idioma babel
    f:ruta-imagen()   normalización de rutas de imagen
    abortar-elemento  plantilla de corte ante vocabulario
                      no previsto
    gb-espacio        ficha de espacio vertical del PDF (SC-39)
    f:alinear-ficha() ficha de alineación de un párrafo (SC-61)
    f:alinear-abre()  apertura del párrafo alineado (SC-61)
    f:alinear-cierra() cierre del párrafo alineado (SC-61)
    gb-alinear        corte ante una ficha fuera de lugar (SC-61)
    f:volada-latex()  la letra volada como \sptext (SC-62)
    f:sin-punto-final() el texto antes de una volada (SC-62)
    f:cifra-latex()   la cantidad como orden de siunitx (SC-65)
    f:pi-valor()      un valor de una instrucción gb- (SC-66)
    f:cuadro-columna() la columna de un cuadro para tabular (SC-66)
    f:cuadro-formato() el table-format de una columna de cifras (SC-66)
    f:cuadro-pie()    el \caption de un cuadro (SC-66)
    f:cuadro-span()   columnas y filas que une una celda (SC-66)
    f:cuadro-grilla() cada celda en su columna (SC-66)
    f:cuadro-abajo()  el texto unido del encabezado, abajo (SC-66)
    f:cuadro-filete() el filete entre dos filas (SC-66)
    f:cuadro-cantidad() la cifra sola de una celda (SC-66)
    gb-cuadro-latex   el cuadro completo, con sus tramos (SC-66)
    gb-cuadro-fila    una fila del cuadro (SC-66)
    f:codigo-latex()  bloque de código coloreado (SC-42)
  ============================================================
  NOTA SOBRE f:latex — CORRECCIÓN DE 2026-09
    LA VERSIÓN ANTERIOR ENCADENABA DIEZ replace() CON LA
    BARRA INVERTIDA PRIMERO. ESO ROMPE: replace() DE LA BARRA
    INYECTA \textbackslash{}, Y LOS PASOS SIGUIENTES ESCAPAN
    LAS LLAVES DE ESE REEMPLAZO.
      ENTRADA a\b  →  SALÍA  a\textbackslash\{\}b
    NO TIENE ARREGLO POR REORDENAMIENTO: SI LAS LLAVES VAN
    PRIMERO, EL \{ QUE PRODUCEN QUEDA EXPUESTO AL PASO DE LA
    BARRA. LA ÚNICA SOLUCIÓN ES UNA PASADA ÚNICA EN LA QUE
    NINGÚN REEMPLAZO PUEDA VOLVER A SER ENTRADA.
    VERIFICADO CON SaxonJ-HE 12.5 SOBRE EL BANCO DE LITERALES
    DEL CAPÍTULO DE PRUEBAS DE CITAS.
  ============================================================
  NOTA SOBRE CARACTERES NO ESCAPADOS
    <  >  |  NO SE ESCAPAN. BAJO LuaLaTeX CON fontspec Y UNA
    FUENTE UNICODE SE COMPONEN COMO SÍ MISMOS. ESTO NO VALE
    PARA pdfLaTeX CON CODIFICACIÓN OT1: SI ALGUNA VEZ SE
    CAMBIA DE MOTOR, HAY QUE REVISAR ESTA DECISIÓN.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:f="urn:gbpublisher:functions"
  xmlns:gbc="urn:gbpublisher:codigo"
  xmlns:array="http://www.w3.org/2005/xpath-functions/array"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="xs f gbc array map">

  <!-- LAS REGLAS DEL CÓDIGO COMUNES A LAS SEIS SALIDAS (SC-42) -->
  <xsl:include href="codigo-comun.xsl"/>

  <!-- ============================================================ -->
  <!-- PARÁMETRO: codigo_dir                                        -->
  <!-- LA CARPETA DONDE colorear_codigo.sh DEJÓ LOS BLOQUES         -->
  <!-- COLOREADOS (SC-42), COMO RUTA ABSOLUTA. VACÍO: LOS BLOQUES   -->
  <!-- SALEN SIN COLOR, CON UN AVISO. LOS GENERADORES LO PASAN      -->
  <!-- SIEMPRE: EL VACÍO ES PARA CORRER LA HOJA A MANO.             -->
  <!-- ============================================================ -->
  <xsl:param name="codigo_dir" as="xs:string" select="''"/>

  <!-- ============================================================ -->
  <!-- TABLA DE ESCAPE PARA MODO TEXTO NORMAL                       -->
  <!-- CADA CARÁCTER SE MIRA UNA SOLA VEZ: EL REEMPLAZO NO VUELVE   -->
  <!-- A ENTRAR AL PROCESO, ASÍ QUE NO HAY ORDEN QUE RESPETAR.      -->
  <!-- AGREGAR UN CARÁCTER ES AGREGAR UNA LÍNEA.                    -->
  <!-- EL ESPACIO DURO U+00A0 (¬ DEL .md, LAS ABREVIATURAS, EL      -->
  <!-- LOCATOR IMPLÍCITO DE LAS CITAS) SALE COMO EL ~ DE LaTeX: ASÍ -->
  <!-- EL PDF NO DEPENDE DE CÓMO TRATEN EL CARÁCTER LA FUENTE O     -->
  <!-- LuaLaTeX (SC-68).                                            -->
  <!-- ============================================================ -->
  <xsl:variable name="f:mapa-tex" as="map(xs:string, xs:string)" select="
    map {
      '&#xA0;' : '~',
      '\'      : '\textbackslash{}',
      '{'      : '\{',
      '}'      : '\}',
      '$'      : '\$',
      '%'      : '\%',
      '&amp;'  : '\&amp;',
      '#'      : '\#',
      '_'      : '\_',
      '^'      : '\textasciicircum{}',
      '~'      : '\textasciitilde{}'
    }"/>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:latex                                            -->
  <!-- PROPÓSITO: ESCAPA LOS DIEZ CARACTERES ACTIVOS DE LATEX EN    -->
  <!--            TEXTO PROVENIENTE DEL XML Y PASA EL ESPACIO DURO  -->
  <!--            A ~ (SC-68).                                      -->
  <!-- PARÁMETROS: t As xs:string — texto crudo                     -->
  <!-- RETORNA  : xs:string — texto seguro para modo texto          -->
  <!-- NOTA     : RECORRE POR CODEPOINT, NO POR BYTE, ASÍ QUE ES    -->
  <!--            CORRECTO EN UTF-8 POR CONSTRUCCIÓN (SC-02).       -->
  <!-- ============================================================ -->
  <xsl:function name="f:latex" as="xs:string">
    <xsl:param name="t" as="xs:string"/>
    <xsl:value-of select="string-join(
      for $cp in string-to-codepoints($t)
      return let $c := codepoints-to-string($cp)
             return ($f:mapa-tex($c), $c)[1], '')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:latex-url                                        -->
  <!-- PROPÓSITO: ESCAPA UNA URL PARA USARLA COMO ARGUMENTO DE      -->
  <!--            \href O \url. SOLO % Y # SON PROBLEMÁTICOS: EL    -->
  <!--            PRIMERO COMENTA EL RESTO DE LA LÍNEA Y EL         -->
  <!--            SEGUNDO ES EL PARÁMETRO DE ALINEACIÓN.            -->
  <!-- PARÁMETROS: u As xs:string — URL cruda                       -->
  <!-- RETORNA  : xs:string — URL segura                            -->
  <!-- PENDIENTE: VERIFICAR CONTRA LA DOCUMENTACIÓN DE hyperref SI  -->
  <!--            \href NECESITA ESTE ESCAPE O SI LO RESUELVE SOLO. -->
  <!--            MIENTRAS TANTO SE ESCAPA, QUE ES LO CONSERVADOR.  -->
  <!-- ============================================================ -->
  <xsl:function name="f:latex-url" as="xs:string">
    <xsl:param name="u" as="xs:string"/>
    <xsl:value-of select="replace(replace($u, '%', '\\%'), '#', '\\#')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- CORTE DE LÍNEA EN TÍTULOS (SC-28)                            -->
  <!--                                                              -->
  <!-- EL CORTE LLEGA AL XML COMO SEPARADOR SIN TEXTO:              -->
  <!--   DocBook   <?gb-corte?>   (DocBook 5.2 NO TIENE ELEMENTO)   -->
  <!--   JATS      <break/>                                         -->
  <!-- EL VALOR DE TEXTO DE LOS DOS ES VACÍO: POR ESO EL TÍTULO SE  -->
  <!-- RECORRE POR NODOS Y NO COMO CADENA. normalize-space() SOBRE  -->
  <!-- EL TÍTULO ENTERO DA LA VERSIÓN PLANA, PERO PIERDE DÓNDE      -->
  <!-- ESTABA EL CORTE.                                             -->
  <!--                                                              -->
  <!-- *:break Y NO break: ESTE MÓDULO NO DECLARA                   -->
  <!-- xpath-default-namespace, Y CADA HOJA QUE LO IMPORTA TIENE EL -->
  <!-- SUYO. EL COMODÍN ALCANZA EL break DE JATS SIN ATARSE A ÉL.   -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:titulo-tramos                                    -->
  <!-- PROPÓSITO: PARTE UN TÍTULO EN SUS CORTES                     -->
  <!-- PARÁMETROS: titulo As node()? — el elemento del título       -->
  <!-- RETORNA  : xs:string* — los tramos, sin espacios sobrantes   -->
  <!--            NI TRAMOS VACÍOS. SIN CORTES, UN SOLO TRAMO.      -->
  <!-- NOTA     : LOS TRAMOS VACÍOS SE DESCARTAN PARA QUE UN CORTE  -->
  <!--            AL PRINCIPIO, AL FINAL O DOBLE NO PRODUZCA UNA    -->
  <!--            LÍNEA VACÍA NI UN \\ SIN LÍNEA QUE TERMINAR.      -->
  <!-- ============================================================ -->
  <xsl:function name="f:titulo-tramos" as="xs:string*">
    <xsl:param name="titulo" as="node()?"/>
    <xsl:for-each-group select="$titulo/node()"
      group-starting-with="processing-instruction('gb-corte') | *:break">
      <!-- SOLO TEXTO Y ELEMENTOS: EL VALOR DE UNA INSTRUCCIÓN O DE UN
           COMENTARIO ES SU CONTENIDO, Y NO DEBE LLEGAR AL TÍTULO -->
      <xsl:variable name="tramo" select="normalize-space(string-join(
        current-group()[self::text() or self::*] ! string(.), ''))"/>
      <xsl:if test="$tramo != ''">
        <xsl:sequence select="$tramo"/>
      </xsl:if>
    </xsl:for-each-group>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:titulo-compuesto                                 -->
  <!-- PROPÓSITO: EL TÍTULO PARA COMPONER: CADA TRAMO ESCAPADO Y    -->
  <!--            UNIDOS CON \gbCorteTitulo (CONTRATO 6)            -->
  <!-- PARÁMETROS: titulo As node()? — el elemento del título       -->
  <!-- RETORNA  : xs:string — LaTeX listo para el argumento de la   -->
  <!--            apertura; vacío si no hay título                  -->
  <!-- NOTA     : SE ESCAPA CADA TRAMO Y DESPUÉS SE UNE: EL ORDEN   -->
  <!--            PARTIR, ESCAPAR, UNIR ES EL DE SC-28. EL ESPACIO  -->
  <!--            DESPUÉS DE LA MACRO LO CONSUME TeX AL LEER EL     -->
  <!--            NOMBRE: «Uno\gbCorteTitulo dos» QUEDA «Uno dos»   -->
  <!--            CUANDO LA MACRO VALE ESPACIO.                     -->
  <!-- ============================================================ -->
  <xsl:function name="f:titulo-compuesto" as="xs:string">
    <xsl:param name="titulo" as="node()?"/>
    <xsl:sequence select="string-join(
      f:titulo-tramos($titulo) ! f:latex(.), '\gbCorteTitulo ')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:titulo-plano                                     -->
  <!-- PROPÓSITO: EL TÍTULO EN UNA LÍNEA, ESCAPADO. ES EL QUE VA AL -->
  <!--            SUMARIO, AL FOLIO Y A LOS MARCADORES (SC-28)      -->
  <!-- PARÁMETROS: titulo As node()? — el elemento del título       -->
  <!-- RETORNA  : xs:string — LaTeX sin \gbCorteTitulo              -->
  <!-- ============================================================ -->
  <xsl:function name="f:titulo-plano" as="xs:string">
    <xsl:param name="titulo" as="node()?"/>
    <xsl:sequence select="f:latex(string-join(f:titulo-tramos($titulo), ' '))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:babel-lang                                       -->
  <!-- PROPÓSITO: CONVIERTE CÓDIGO ISO 639-1 AL NOMBRE DE IDIOMA    -->
  <!--            RECONOCIDO POR babel / polyglossia                -->
  <!-- PARÁMETROS: lang As xs:string — código ISO 639-1             -->
  <!-- RETORNA  : xs:string — nombre para \selectlanguage           -->
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
  <!-- FUNCIÓN : f:ruta-imagen                                      -->
  <!-- PROPÓSITO: NORMALIZA LA RUTA DE UNA IMAGEN Y LE ANTEPONE EL  -->
  <!--            PREFIJO QUE CORRESPONDE AL DIRECTORIO DESDE EL    -->
  <!--            QUE SE COMPILA.                                   -->
  <!-- PARÁMETROS: href    As xs:string — ruta tal como está en XML -->
  <!--             prefijo As xs:string — prefijo de compilación    -->
  <!-- RETORNA  : xs:string — ruta lista para \includegraphics      -->
  <!-- NOTA     : EL CANÓNICO TRAE RUTAS CON DOS ORÍGENES DISTINTOS -->
  <!--            ('media/x.jpg' Y '../media/x.png'). SE NORMALIZA  -->
  <!--            ACÁ HASTA QUE EL ENSAMBLADOR EMITA UNO SOLO.      -->
  <!-- ============================================================ -->
  <xsl:function name="f:ruta-imagen" as="xs:string">
    <xsl:param name="href"    as="xs:string"/>
    <xsl:param name="prefijo" as="xs:string"/>
    <xsl:variable name="limpia"
      select="replace(normalize-space($href), '^(\.\./|\./)+', '')"/>
    <xsl:value-of select="concat($prefijo, $limpia)"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:motor-cita                                       -->
  <!-- PROPÓSITO: DICE CON QUÉ MOTOR BIBLIOGRÁFICO SE PROCESA UN    -->
  <!--            ESTILO. NO ES UNA DISTINCIÓN ESTÉTICA: SON DOS    -->
  <!--            MOTORES CON COMANDOS DISTINTOS.                   -->
  <!-- PARÁMETROS: estilo As xs:string — apa|iso690|ieee|vancouver  -->
  <!-- RETORNA  : xs:string — biblatex | bibtex                     -->
  <!-- NOTA     : gbpublisher TRABAJA CON CUATRO ESTILOS. TRES VAN  -->
  <!--            POR biblatex + biber; vancouver VA POR bibtex.    -->
  <!--            BAJO bibtex NO EXISTEN \parencite, \textcite,     -->
  <!--            \autocite, LA VARIANTE ESTRELLADA NI LOS DOS      -->
  <!--            CORCHETES DE PRENOTA Y POSTNOTA. SOLO EXISTE      -->
  <!--            \cite[postnota]{clave}, Y EL PREFIJO, SI LO HAY,  -->
  <!--            SE EMITE COMO TEXTO LIBRE ANTES DEL COMANDO.      -->
  <!-- ============================================================ -->
  <xsl:function name="f:motor-cita" as="xs:string">
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:value-of select="if ($estilo = 'vancouver') then 'bibtex' else 'biblatex'"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: abortar-elemento                                  -->
  <!-- PROPÓSITO: CORTA LA TRANSFORMACIÓN CUANDO APARECE UN         -->
  <!--            ELEMENTO O UN role QUE LA HOJA NO CONTEMPLA.      -->
  <!-- PARÁMETROS: contexto As xs:string — nombre de la hoja        -->
  <!-- RETORNA  : nada — termina con error                          -->
  <!-- RAZÓN    : LA REGLA POR DEFECTO DE XSLT COPIA EL TEXTO DE    -->
  <!--            LOS HIJOS Y DESCARTA EL ELEMENTO. CON             -->
  <!--            method="text" NO QUEDA NI RASTRO: UN <sidebar>    -->
  <!--            SIN PLANTILLA SE VUELVE UN PÁRRAFO SUELTO Y EL    -->
  <!--            LIBRO COMPILA MAL SIN QUE NADA AVISE (GV-23).     -->
  <!--            PREFERIMOS QUE FRENE ACÁ Y NO EN CORRECCIÓN DE    -->
  <!--            PRUEBAS.                                          -->
  <!-- ============================================================ -->
  <xsl:template name="abortar-elemento">
    <xsl:param name="contexto" as="xs:string" select="'(hoja no declarada)'"/>
    <xsl:variable name="atributos" select="string-join(
      for $a in @* return concat(name($a), '=&quot;', $a, '&quot;'), ' ')"/>
    <xsl:message terminate="yes">
      <xsl:text>&#10;[</xsl:text>
      <xsl:value-of select="$contexto"/>
      <xsl:text>] VOCABULARIO NO PREVISTO&#10;</xsl:text>
      <xsl:text>  Elemento : </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>&#10;  Atributos: </xsl:text>
      <xsl:value-of select="if ($atributos != '') then $atributos else '(ninguno)'"/>
      <xsl:text>&#10;  Ruta     : </xsl:text>
      <xsl:value-of select="string-join(
        for $n in ancestor-or-self::* return name($n), '/')"/>
      <xsl:text>&#10;&#10;  Agregar la plantilla correspondiente, o el entorno</xsl:text>
      <xsl:text>&#10;  equivalente en la capa de contrato del preámbulo.&#10;</xsl:text>
    </xsl:message>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- INSTRUCCIÓN DE COMPOSICIÓN: ESPACIO VERTICAL (SC-38, SC-39)  -->
  <!-- ============================================================ -->
  <!-- EL CANÓNICO NO LLEVA LaTeX: LLEVA UNA FICHA QUE ESCRIBE       -->
  <!-- espacio-vertical.lua, Y ESTA ES LA ÚNICA PLANTILLA QUE LA     -->
  <!-- TRADUCE. SIRVE A LAS DOS RAMAS PORQUE LA FICHA ES IGUAL EN    -->
  <!-- JATS Y EN DOCBOOK. LAS HOJAS DE HTML Y EPUB NO LA TOCAN: LA   -->
  <!-- REGLA INCORPORADA PARA UNA INSTRUCCIÓN DE PROCESAMIENTO NO    -->
  <!-- ESCRIBE NADA.                                                 -->
  <!--   bigskip                    ->  \bigskip                    -->
  <!--   vspace* 2baselineskip      ->  \vspace*{2\baselineskip}    -->
  <!--   enlargethispage 1baselineskip -> \enlargethispage{1\baselineskip} -->
  <!-- UNA FICHA DESCONOCIDA CORTA LA TRANSFORMACIÓN: EL FILTRO YA   -->
  <!-- VALIDA, Y ESTO CUBRE UN CANÓNICO ARMADO POR OTRO CAMINO.      -->
  <!-- ============================================================ -->
  <xsl:template match="processing-instruction('gb-espacio')">
    <xsl:variable name="ficha" select="normalize-space(.)"/>
    <xsl:choose>
      <xsl:when test="$ficha = ('smallskip', 'medskip', 'bigskip',
                                'newpage', 'clearpage', 'cleardoublepage')">
        <xsl:text>&#10;\</xsl:text>
        <xsl:value-of select="$ficha"/>
        <xsl:text>&#10;&#10;</xsl:text>
      </xsl:when>
      <xsl:when test="matches($ficha,
        '^(vspace\*?|enlargethispage) (-?([0-9]+\.?[0-9]*|\.[0-9]+))(pt|mm|cm|em|ex|baselineskip)$')">
        <xsl:analyze-string select="$ficha"
          regex="^(vspace\*?|enlargethispage) (-?([0-9]+\.?[0-9]*|\.[0-9]+))(pt|mm|cm|em|ex|baselineskip)$">
          <xsl:matching-substring>
            <xsl:text>&#10;\</xsl:text>
            <xsl:value-of select="regex-group(1)"/>
            <xsl:text>{</xsl:text>
            <xsl:value-of select="regex-group(2)"/>
            <!-- baselineskip ES UN REGISTRO DE LaTeX: VA CON SU BARRA -->
            <xsl:if test="regex-group(4) = 'baselineskip'">\</xsl:if>
            <xsl:value-of select="regex-group(4)"/>
            <xsl:text>}&#10;&#10;</xsl:text>
          </xsl:matching-substring>
        </xsl:analyze-string>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:text>&#10;[gb-espacio] FICHA DE ESPACIO VERTICAL DESCONOCIDA: «</xsl:text>
          <xsl:value-of select="$ficha"/>
          <xsl:text>»&#10;  La escribe espacio-vertical.lua (SC-39). Si cambió el&#10;</xsl:text>
          <xsl:text>  diccionario del filtro, esta plantilla va en el mismo lote.&#10;</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- INSTRUCCIÓN DE COMPOSICIÓN: ALINEACIÓN (SC-38, SC-61)        -->
  <!-- ============================================================ -->
  <!-- alinear.lua ESCRIBE LA FICHA <?gb-alinear izq|centro|der?>   -->
  <!-- COMO PRIMER NODO DE CADA PÁRRAFO DEL BLOQUE. LA PLANTILLA DE -->
  <!-- PÁRRAFO DE CADA HOJA (para EN docbook-to-latex.xsl, p EN     -->
  <!-- jats-to-latex.xsl) LA TOMA CON f:alinear-ficha, NO LA PASA A -->
  <!-- apply-templates Y ENVUELVE EL PÁRRAFO CON f:alinear-abre Y   -->
  <!-- f:alinear-cierra:                                            -->
  <!--   izq     ->  \begingroup\raggedright\noindent TEXTO\par\endgroup -->
  <!--   centro  ->  \begingroup\centering\noindent TEXTO\par\endgroup   -->
  <!--   der     ->  \begingroup\raggedleft\noindent TEXTO\par\endgroup  -->
  <!-- EL \par VA DENTRO DEL GRUPO: TeX LEE \rightskip Y \leftskip -->
  <!-- AL CERRAR EL PÁRRAFO. SIN CORTE DE PALABRA (DECISIÓN DE      -->
  <!-- ALBERTO) Y SIN PENALIDADES: LAS TRES DECLARACIONES YA NO      -->
  <!-- PARTEN (GV-113), Y \hyphenpenalty=10000 SE HEREDARÍA EN UNA   -->
  <!-- NOTA AL PIE DEL PÁRRAFO, QUE PERDERÍA SU CORTE (GV-114). NO   -->
  <!-- SE AGREGA ESPACIO: EL AIRE LO PONE espaciov (SC-39).          -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:alinear-ficha                                    -->
  <!-- PROPÓSITO: LA FICHA DE ALINEACIÓN DE UN PÁRRAFO, SI LA TIENE -->
  <!-- PARÁMETROS: p As element() — el <para> o el <p>              -->
  <!-- RETORNA  : processing-instruction()? — LA FICHA CUANDO ES EL -->
  <!--            PRIMER NODO CON CONTENIDO; VACÍO SI NO            -->
  <!-- RAZÓN    : EL ESCRITOR DocBook DE PANDOC INDENTA EL CONTENIDO -->
  <!--            DEL <para>: ANTES DE LA FICHA HAY UN NODO DE TEXTO -->
  <!--            EN BLANCO, QUE NO CUENTA (MEDIDO, GV-115)          -->
  <!-- ============================================================ -->
  <xsl:function name="f:alinear-ficha" as="processing-instruction()?">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="$p/node()[not(self::text()[normalize-space() = ''])][1]
                            [self::processing-instruction('gb-alinear')]"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:alinear-abre                                     -->
  <!-- PROPÓSITO: LA APERTURA DEL PÁRRAFO ALINEADO                  -->
  <!-- PARÁMETROS: ficha As processing-instruction()? — LO QUE      -->
  <!--            DEVOLVIÓ f:alinear-ficha                          -->
  <!-- RETORNA  : xs:string — VACÍO SI EL PÁRRAFO NO SE ALINEA      -->
  <!-- ============================================================ -->
  <xsl:function name="f:alinear-abre" as="xs:string">
    <xsl:param name="ficha" as="processing-instruction()?"/>
    <xsl:variable name="valor" select="normalize-space($ficha)"/>
    <xsl:choose>
      <!-- 1. SIN FICHA: EL PÁRRAFO COMÚN NO CAMBIA -->
      <xsl:when test="empty($ficha)">
        <xsl:sequence select="''"/>
      </xsl:when>
      <!-- 2. LAS TRES FICHAS DEL DICCIONARIO -->
      <!-- \noindent EN LAS TRES, TAMBIÉN EN izq (DECISIÓN DE ALBERTO) -->
      <xsl:when test="$valor = ('izq', 'centro', 'der')">
        <xsl:variable name="declaracion" select="
          if ($valor = 'izq') then '\raggedright'
          else if ($valor = 'centro') then '\centering'
          else '\raggedleft'"/>
        <xsl:sequence select="concat('\begingroup', $declaracion, '\noindent ')"/>
      </xsl:when>
      <!-- 3. UNA FICHA DESCONOCIDA CORTA LA TRANSFORMACIÓN -->
      <!-- EL FILTRO YA VALIDA; ESTO CUBRE UN CANÓNICO ARMADO POR OTRO CAMINO -->
      <xsl:otherwise>
        <xsl:message terminate="yes">
          <xsl:text>&#10;[gb-alinear] FICHA DE ALINEACIÓN DESCONOCIDA: «</xsl:text>
          <xsl:value-of select="$valor"/>
          <xsl:text>»&#10;  La escribe alinear.lua (SC-61). Si cambió el&#10;</xsl:text>
          <xsl:text>  diccionario del filtro, esta función va en el mismo lote.&#10;</xsl:text>
        </xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:alinear-cierra                                   -->
  <!-- PROPÓSITO: EL CIERRE DEL PÁRRAFO ALINEADO                    -->
  <!-- PARÁMETROS: ficha As processing-instruction()?               -->
  <!-- RETORNA  : xs:string — VACÍO SI EL PÁRRAFO NO SE ALINEA      -->
  <!-- ============================================================ -->
  <xsl:function name="f:alinear-cierra" as="xs:string">
    <xsl:param name="ficha" as="processing-instruction()?"/>
    <xsl:sequence select="if (empty($ficha)) then '' else '\par\endgroup'"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- LA FICHA FUERA DE LUGAR CORTA LA TRANSFORMACIÓN              -->
  <!-- ============================================================ -->
  <!-- LA PLANTILLA DE PÁRRAFO NUNCA LE PASA LA FICHA A             -->
  <!-- apply-templates: UNA gb-alinear QUE LLEGA ACÁ ESTÁ EN OTRO   -->
  <!-- LUGAR (A MITAD DE UN PÁRRAFO, EN UNA NOTA, UN PIE, UN ÍTEM)  -->
  <!-- Y SE PERDERÍA SIN AVISO.                                     -->
  <!-- ============================================================ -->
  <xsl:template match="processing-instruction('gb-alinear')">
    <xsl:message terminate="yes">
      <xsl:text>&#10;[gb-alinear] FICHA DE ALINEACIÓN FUERA DEL COMIENZO DE UN PÁRRAFO DEL CUERPO: </xsl:text>
      <xsl:value-of select="string-join(
        for $n in ancestor::* return name($n), '/')"/>
      <xsl:text>&#10;  alinear.lua (SC-61) la escribe solo al comienzo de un&#10;</xsl:text>
      <xsl:text>  párrafo del primer nivel.&#10;</xsl:text>
    </xsl:message>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- LETRA VOLADA (SC-62)                                         -->
  <!-- ============================================================ -->
  <!-- volada.lua ESCRIBE n\sptext{o} DEL .md COMO «n.» Y LA VOLADA -->
  <!-- EN SUPERÍNDICE MARCADO: <superscript role="volada"> EN       -->
  <!-- DocBook, <sup specific-use="volada"> EN JATS. EL PUNTO ES EL -->
  <!-- QUE PONE \sptext (babel-spanish, \es@orddot), ASÍ QUE EN EL  -->
  <!-- PDF SE VUELVE A \sptext{o} Y EL PUNTO DEL TEXTO SE QUITA.    -->
  <!-- LAS DOS PLANTILLAS (EL SUPERÍNDICE Y EL TEXTO QUE LO         -->
  <!-- PRECEDE) VAN EN CADA HOJA Y NO ACÁ: UNA PLANTILLA IMPORTADA  -->
  <!-- PIERDE CONTRA text() Y sup/superscript DE LA HOJA QUE        -->
  <!-- IMPORTA, SEA CUAL SEA SU PRIORIDAD (MEDIDO, GV-117: LA       -->
  <!-- PRECEDENCIA DE IMPORTACIÓN SE MIRA ANTES QUE LA PRIORIDAD).  -->
  <!-- ACÁ VAN LAS DOS FUNCIONES QUE LAS DOS USAN.                  -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:volada-latex                                     -->
  <!-- PROPÓSITO: LA VOLADA COMO \sptext{…}, CON LOS DOS CONTROLES  -->
  <!-- PARÁMETROS: v As element() — el superscript o el sup volada  -->
  <!--            marcador As xs:boolean — true EN EL ARGUMENTO     -->
  <!--            OPCIONAL DE UN TÍTULO, QUE VA A LOS MARCADORES    -->
  <!-- RETORNA  : xs:string — \sptext{o}, O EN UN TÍTULO            -->
  <!--            \texorpdfstring{\sptext{o}}{.º}                   -->
  <!-- RAZÓN    : \sptext EXISTE SOLO CON EL ESPAÑOL ACTIVO (GV-105): -->
  <!--            EN OTRO IDIOMA CORTA EL PDF CON «Undefined control -->
  <!--            sequence». FRENA ACÁ, CON UN MENSAJE QUE LO DICE   -->
  <!--            (DECISIÓN DE ALBERTO). EN EL LIBRO ES EL ÚNICO     -->
  <!--            CONTROL DEL IDIOMA DEL CAPÍTULO: volada.lua NO LO  -->
  <!--            CONOCE.                                           -->
  <!-- ============================================================ -->
  <xsl:function name="f:volada-latex" as="xs:string">
    <xsl:param name="v" as="element()"/>
    <xsl:param name="marcador" as="xs:boolean"/>
    <xsl:variable name="anterior" select="$v/preceding-sibling::node()[1]"/>
    <xsl:variable name="orden" select="concat('\sptext{', f:latex(string($v)), '}')"/>
    <xsl:choose>
      <!-- 1. EL TEXTO EN ESPAÑOL: xml:lang ES es O UNA VARIANTE (es-AR) -->
      <!-- fn:lang MIRA EL xml:lang MÁS CERCANO DE LOS ANCESTROS. SIN  -->
      <!-- NINGUNO NO HAY CON QUÉ DECIDIR: SE DEJA PASAR                -->
      <xsl:when test="exists($v/ancestor-or-self::*/@xml:lang) and not(lang('es', $v))">
        <xsl:message terminate="yes">
          <xsl:text>&#10;[sptext] LETRA VOLADA EN UN TEXTO QUE NO ESTÁ EN ESPAÑOL (xml:lang «</xsl:text>
          <xsl:value-of select="$v/ancestor-or-self::*[@xml:lang][1]/@xml:lang"/>
          <xsl:text>»): «</xsl:text>
          <xsl:value-of select="$v"/>
          <xsl:text>»&#10;  \sptext es de babel-spanish (SC-62): en otro idioma el PDF no compila.&#10;</xsl:text>
        </xsl:message>
      </xsl:when>
      <!-- 2. EL PUNTO QUE ESCRIBIÓ volada.lua, PEGADO ANTES -->
      <xsl:when test="not($anterior instance of text() and ends-with($anterior, '.'))">
        <xsl:message terminate="yes">
          <xsl:text>&#10;[sptext] LETRA VOLADA SIN EL PUNTO ANTES: «</xsl:text>
          <xsl:value-of select="$v"/>
          <xsl:text>»&#10;  volada.lua (SC-62) escribe «n.» y la volada; el canónico se armó por otro camino.&#10;</xsl:text>
        </xsl:message>
      </xsl:when>
      <!-- 3. EN UN MARCADOR, LA CADENA PDF APARTE: hyperref NO PUEDE  -->
      <!-- CONVERTIR \sptext Y ESCRIBÍA «n.8-1.5ex o 1» (MEDIDO,       -->
      <!-- GV-118). LA o Y LA a VOLADAS TIENEN SU CARÁCTER: º Y ª       -->
      <xsl:when test="$marcador">
        <xsl:sequence select="concat('\texorpdfstring{', $orden, '}{.',
          if (string($v) = 'o') then 'º'
          else if (string($v) = 'a') then 'ª'
          else f:latex(string($v)), '}')"/>
      </xsl:when>
      <!-- 4. LA ORDEN; EL CONTENIDO SON SOLO MINÚSCULAS (volada.lua) -->
      <xsl:otherwise>
        <xsl:sequence select="$orden"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:sin-punto-final                                  -->
  <!-- PROPÓSITO: EL TEXTO QUE PRECEDE A UNA VOLADA, SIN SU PUNTO   -->
  <!-- PARÁMETROS: s As xs:string — el nodo de texto                -->
  <!-- RETORNA  : xs:string — sin el punto final; \sptext LO PONE   -->
  <!-- ============================================================ -->
  <xsl:function name="f:sin-punto-final" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <xsl:sequence select="replace($s, '\.$', '')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- CIFRAS Y CANTIDADES (SC-64, SC-65)                           -->
  <!-- ============================================================ -->
  <!-- cifras.lua ESCRIBE LA CANTIDAD CON EL TEXTO QUE SE VE Y UNA  -->
  <!-- FICHA SIN LaTeX: <phrase role="cantidad" remap="…"> EN       -->
  <!-- DocBook, <named-content content-type="cantidad"              -->
  <!-- specific-use="…"> EN JATS. LA FICHA ES LA ORDEN Y SUS        -->
  <!-- ARGUMENTOS SEPARADOS POR ESPACIO, CON LAS UNIDADES SIN BARRA: -->
  <!--   num 1500                  ->  \num{1500}                   -->
  <!--   SI 2.5 kilo metre per hour -> \SI{2.5}{\kilo\metre\per\hour} -->
  <!--   SIrange 50 51 degree      ->  \SIrange{50}{51}{\degree}    -->
  <!-- EL PDF LA VUELVE A ESCRIBIR Y COMPONE siunitx, CON EL        -->
  <!-- \sisetup DEL CONTRATO O DEL PREÁMBULO DE LA REVISTA. LAS      -->
  <!-- PLANTILLAS VAN EN CADA HOJA (GV-117); ACÁ, LA FUNCIÓN.        -->
  <!-- ============================================================ -->

  <!-- LAS PALABRAS DEL DICCIONARIO CERRADO (cifras.lua): UNIDADES, -->
  <!-- PREFIJO, POTENCIAS Y \per                                    -->
  <xsl:variable name="f:cifras-unidades" as="xs:string+"
    select="('hour', 'metre', 'gram', 'tonne', 'euro', 'degree', 'percent',
             'kilo', 'square', 'cubic', 'per')"/>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cifra-latex                                      -->
  <!-- PROPÓSITO: LA CANTIDAD COMO ORDEN DE siunitx                  -->
  <!-- PARÁMETROS: c As element() — el phrase o el named-content    -->
  <!--            ficha As xs:string — @remap o @specific-use       -->
  <!--            marcador As xs:boolean — true EN EL ARGUMENTO     -->
  <!--            OPCIONAL DE UN TÍTULO, QUE VA A LOS MARCADORES    -->
  <!-- RETORNA  : xs:string — \num{…}, \SI{…}{…} O \SIrange{…}{…}{…}; -->
  <!--            EN UN MARCADOR, CON \texorpdfstring Y EL TEXTO QUE  -->
  <!--            SE VE (hyperref NO CONVIERTE LAS ÓRDENES, GV-118)   -->
  <!-- ============================================================ -->
  <xsl:function name="f:cifra-latex" as="xs:string">
    <xsl:param name="c" as="element()"/>
    <xsl:param name="ficha" as="xs:string"/>
    <xsl:param name="marcador" as="xs:boolean"/>
    <xsl:variable name="t" select="tokenize(normalize-space($ficha), ' ')"/>
    <xsl:variable name="cifra" select="'^-?[0-9]+(\.[0-9]+)?([eE]-?[0-9]+)?$'"/>
    <xsl:variable name="n-cifras"
      select="if ($t[1] = 'num') then 1 else if ($t[1] = 'SI') then 1
              else if ($t[1] = 'SIrange') then 2 else 0"/>
    <xsl:variable name="cifras" select="subsequence($t, 2, $n-cifras)"/>
    <xsl:variable name="unidades" select="subsequence($t, 2 + $n-cifras)"/>
    <xsl:variable name="orden">
      <xsl:choose>
        <!-- 1. LA FICHA BIEN FORMADA; SI NO, CORTA: LA ESCRIBE      -->
        <!-- cifras.lua, Y ESTO CUBRE UN CANÓNICO ARMADO POR OTRO    -->
        <!-- CAMINO                                                  -->
        <xsl:when test="$n-cifras = 0
                        or count($cifras) != $n-cifras
                        or (some $x in $cifras satisfies not(matches($x, $cifra)))
                        or ($t[1] = 'num' and exists($unidades))
                        or ($t[1] != 'num' and empty($unidades))
                        or (some $u in $unidades satisfies not($u = $f:cifras-unidades))">
          <xsl:message terminate="yes">
            <xsl:text>&#10;[cifras] FICHA DE CANTIDAD DESCONOCIDA: «</xsl:text>
            <xsl:value-of select="$ficha"/>
            <xsl:text>»&#10;  La escribe cifras.lua (SC-65). Si cambió el&#10;</xsl:text>
            <xsl:text>  diccionario del filtro, esta función va en el mismo lote.&#10;</xsl:text>
          </xsl:message>
        </xsl:when>
        <!-- 2. LA ORDEN; LAS CIFRAS SON SOLO DÍGITOS, PUNTO, e Y SIGNO -->
        <xsl:otherwise>
          <xsl:value-of select="concat('\', $t[1],
            string-join($cifras ! concat('{', ., '}'), ''),
            if (exists($unidades))
            then concat('{', string-join($unidades ! concat('\', .), ''), '}')
            else '')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="
      if ($marcador)
      then concat('\texorpdfstring{', $orden, '}{', f:latex(normalize-space($c)), '}')
      else string($orden)"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- CUADROS (SC-66)                                              -->
  <!-- ============================================================ -->
  <!-- cuadro-armar.lua ESCRIBE EL CUADRO CON UNA INSTRUCCIÓN        -->
  <!--   <?gb-cuadro cuerpo="normal" separacion="normal"             -->
  <!--               columnas="texto cifra texto:2.4:centro"?>       -->
  <!-- Y, EN LA COLUMNA DE CIFRAS, CADA CIFRA COMO CANTIDAD          -->
  <!-- (SC-65) CON LA FICHA «num X». EL ESTILO DE LA CASA (LETRA,    -->
  <!-- FILETES, TEXTOS DE CONTINUACIÓN) ESTÁ EN EL PREÁMBULO, COMO   -->
  <!-- MACROS \gbCuadro…. LAS PLANTILLAS VAN EN CADA HOJA (GV-117);  -->
  <!-- ACÁ, LAS FUNCIONES.                                          -->
  <!-- ============================================================ -->

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:pi-valor                                         -->
  <!-- PROPÓSITO: EL VALOR DE UN SEUDOATRIBUTO DE UNA INSTRUCCIÓN   -->
  <!-- PARÁMETROS: pi As processing-instruction(); clave As xs:string -->
  <!-- RETORNA  : xs:string — VACÍO SI NO ESTÁ                      -->
  <!-- ============================================================ -->
  <xsl:function name="f:pi-valor" as="xs:string">
    <xsl:param name="pi" as="processing-instruction()"/>
    <xsl:param name="clave" as="xs:string"/>
    <xsl:variable name="re" select="concat('(^|\s)', $clave, '=&quot;([^&quot;]*)&quot;')"/>
    <xsl:variable name="m" as="xs:string*">
      <xsl:analyze-string select="string($pi)" regex="{$re}">
        <xsl:matching-substring>
          <xsl:sequence select="regex-group(2)"/>
        </xsl:matching-substring>
      </xsl:analyze-string>
    </xsl:variable>
    <xsl:sequence select="string(($m, '')[1])"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-formato                                   -->
  <!-- PROPÓSITO: EL table-format DE UNA COLUMNA S, CALCULADO DE    -->
  <!--            SUS CIFRAS: SIGNO SI HAY UNA NEGATIVA, LOS DÍGITOS -->
  <!--            ENTEROS Y DECIMALES MÁS LARGOS (SC-64: «3.0»)      -->
  <!-- PARÁMETROS: valores As xs:string* — LAS CIFRAS DE ENTRADA    -->
  <!-- RETORNA  : xs:string — p. ej. «3.0», «-2.2»                  -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-formato" as="xs:string">
    <xsl:param name="valores" as="xs:string*"/>
    <xsl:variable name="sin-signo" select="for $v in $valores return replace($v, '^-', '')"/>
    <xsl:variable name="enteros"
      select="max((1, for $v in $sin-signo return string-length(substring-before(concat($v, '.'), '.'))))"/>
    <xsl:variable name="decimales"
      select="max((0, for $v in $sin-signo return string-length(substring-after($v, '.'))))"/>
    <xsl:sequence select="concat(if (some $v in $valores satisfies starts-with($v, '-')) then '-' else '',
                                 $enteros, '.', $decimales)"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-columna                                   -->
  <!-- PROPÓSITO: LA COLUMNA DE tabular SEGÚN SU FICHA              -->
  <!--   cifra              S[table-format=…]                       -->
  <!--   texto              l                                       -->
  <!--   texto::centro      c                                       -->
  <!--   texto:2.4          >{\raggedright\arraybackslash}m{2.4cm}  -->
  <!--   texto:2.4:centro   >{\centering\arraybackslash}m{2.4cm}    -->
  <!-- PARÁMETROS: ficha As xs:string; formato As xs:string — EL     -->
  <!--            table-format, SOLO PARA LA COLUMNA DE CIFRAS      -->
  <!-- RETORNA  : xs:string                                         -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-columna" as="xs:string">
    <xsl:param name="ficha" as="xs:string"/>
    <xsl:param name="formato" as="xs:string"/>
    <xsl:variable name="p" select="tokenize($ficha, ':')"/>
    <xsl:variable name="ancho" select="string($p[2])"/>
    <xsl:variable name="centro" select="$p[3] = 'centro'"/>
    <xsl:sequence select="
      if ($p[1] = 'cifra') then concat('S[table-format=', $formato, ']')
      else if ($p[1] != 'texto') then error(QName('urn:gbpublisher:functions', 'cuadro'),
             concat('[cuadro] COLUMNA DESCONOCIDA EN LA INSTRUCCIÓN: ', $ficha))
      else if ($ancho = '') then (if ($centro) then 'c' else 'l')
      else concat('&gt;{', if ($centro) then '\centering' else '\raggedright',
                  '\arraybackslash}m{', $ancho, 'cm}')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-pie                                       -->
  <!-- PROPÓSITO: EL \caption DEL CUADRO: EL TÍTULO Y, SI HAY, LA   -->
  <!--            NOTA A CONTINUACIÓN (decisión de Alberto: EN EL    -->
  <!--            PDF, TODO EN EL PIE). A LA LISTA DE CUADROS VA     -->
  <!--            SOLO EL TÍTULO                                    -->
  <!-- PARÁMETROS: titulo As xs:string; nota As xs:string — YA EN   -->
  <!--            LaTeX                                             -->
  <!-- RETORNA  : xs:string                                         -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-pie" as="xs:string">
    <xsl:param name="titulo" as="xs:string"/>
    <xsl:param name="nota" as="xs:string"/>
    <xsl:variable name="t" select="normalize-space($titulo)"/>
    <xsl:variable name="n" select="normalize-space($nota)"/>
    <xsl:sequence select="
      if ($n = '') then concat('\caption{', $t, '}')
      else if ($t = '') then concat('\caption{', $n, '}')
      else concat('\caption[{', $t, '}]{', $t,
                  if (matches($t, '[.?!]$')) then ' ' else '. ', $n, '}')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-span                                      -->
  <!-- PROPÓSITO: LAS COLUMNAS Y LAS FILAS QUE UNE UNA CELDA, EN    -->
  <!--            LOS DOS VOCABULARIOS: CALS (namest/nameend        -->
  <!--            «cN», morerows) Y XHTML DE JATS (colspan, rowspan)-->
  <!-- PARÁMETROS: c As element() — entry, th O td                 -->
  <!-- RETORNA  : xs:integer+ — (COLUMNAS, FILAS)                   -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-span" as="xs:integer+">
    <xsl:param name="c" as="element()"/>
    <xsl:sequence select="(
      if ($c/@colspan) then xs:integer($c/@colspan)
      else if ($c/@namest) then xs:integer(substring-after($c/@nameend, 'c'))
                                - xs:integer(substring-after($c/@namest, 'c')) + 1
      else 1,
      if ($c/@rowspan) then xs:integer($c/@rowspan)
      else if ($c/@morerows) then xs:integer($c/@morerows) + 1
      else 1)"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-grilla                                    -->
  <!-- PROPÓSITO: UBICA CADA CELDA EN SU COLUMNA, CON LAS CELDAS    -->
  <!--            UNIDAS QUE VIENEN DE FILAS ANTERIORES (LA MISMA   -->
  <!--            CUENTA QUE mapear EN cuadro-leer.lua)             -->
  <!-- PARÁMETROS: filas As element()* — row O tr; n As xs:integer  -->
  <!-- RETORNA  : map(*)* — UNO POR FILA:                           -->
  <!--   'items'  array: map{'col','cs','celda'} EN ORDEN DE COLUMNA;-->
  <!--            'celda' VACÍA = LA OCUPA UNA CELDA DE ARRIBA, QUE   -->
  <!--            EN LaTeX VA COMO CELDA VACÍA (LA PRÁCTICA DE LA     -->
  <!--            CASA: EL VALOR SOLO EN LA PRIMERA FILA)            -->
  <!--   'cruza'  LAS COLUMNAS QUE SIGUEN UNIDAS AL PASAR A LA FILA   -->
  <!--            SIGUIENTE: AHÍ NO VA FILETE                       -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-grilla" as="map(*)*">
    <xsl:param name="filas" as="element()*"/>
    <xsl:param name="n" as="xs:integer"/>
    <xsl:iterate select="$filas">
      <!-- FILAS QUE QUEDAN OCUPADAS POR COLUMNA, Y EL ANCHO DE LA CELDA
           UNIDA EN LA COLUMNA DONDE EMPIEZA (0 EN LAS DEMÁS) -->
      <xsl:param name="resto" as="xs:integer*" select="for $i in 1 to $n return 0"/>
      <xsl:param name="origen" as="xs:integer*" select="for $i in 1 to $n return 0"/>

      <!-- 1. CADA CELDA EN LA PRIMERA COLUMNA LIBRE -->
      <xsl:variable name="ubicadas" as="map(*)*">
        <xsl:iterate select="*[local-name() = ('entry', 'th', 'td')]">
          <xsl:param name="col" as="xs:integer" select="1"/>
          <xsl:variable name="j" as="xs:integer?"
            select="(for $k in $col to $n return if ($resto[$k] = 0) then $k else ())[1]"/>
          <xsl:if test="empty($j)">
            <xsl:message terminate="yes">[cuadro] UNA FILA TIENE MÁS CELDAS QUE COLUMNAS</xsl:message>
          </xsl:if>
          <xsl:variable name="s" select="f:cuadro-span(.)"/>
          <xsl:sequence select="map{'col': $j, 'cs': $s[1], 'rs': $s[2], 'celda': .}"/>
          <xsl:next-iteration>
            <xsl:with-param name="col" select="$j + $s[1]"/>
          </xsl:next-iteration>
        </xsl:iterate>
      </xsl:variable>

      <!-- 2. LAS COLUMNAS OCUPADAS DESDE ARRIBA: UNA ENTRADA POR CELDA UNIDA -->
      <xsl:variable name="cubiertas" as="map(*)*"
        select="for $i in 1 to $n return
                  if ($resto[$i] &gt; 0 and $origen[$i] &gt; 0)
                  then map{'col': $i, 'cs': $origen[$i], 'rs': 1, 'celda': ()} else ()"/>

      <!-- 3. LO QUE QUEDA OCUPADO DESPUÉS DE ESTA FILA -->
      <xsl:variable name="nuevo-resto" as="xs:integer*"
        select="for $i in 1 to $n return
                  if ($resto[$i] &gt; 0) then $resto[$i] - 1
                  else (for $u in $ubicadas
                        return if ($u?col le $i and $i lt $u?col + $u?cs) then $u?rs - 1 else (),
                        0)[1]"/>
      <xsl:variable name="nuevo-origen" as="xs:integer*"
        select="for $i in 1 to $n return
                  if ($nuevo-resto[$i] = 0) then 0
                  else if ($resto[$i] &gt; 0) then $origen[$i]
                  else (for $u in $ubicadas return if ($u?col = $i) then $u?cs else (), 0)[1]"/>

      <xsl:sequence select="map{
        'items': array{ for $i in 1 to $n return ($ubicadas[?col = $i], $cubiertas[?col = $i]) },
        'cruza': (for $i in 1 to $n return if ($nuevo-resto[$i] &gt; 0) then $i else ())}"/>
      <xsl:next-iteration>
        <xsl:with-param name="resto" select="$nuevo-resto"/>
        <xsl:with-param name="origen" select="$nuevo-origen"/>
      </xsl:next-iteration>
    </xsl:iterate>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-abajo                                     -->
  <!-- PROPÓSITO: PASA EL TEXTO DE CADA CELDA QUE UNE FILAS A LA    -->
  <!--            ÚLTIMA DE ELLAS (PARA EL ENCABEZADO)              -->
  <!-- PARÁMETROS: g As map(*)* — LO QUE DEVUELVE f:cuadro-grilla   -->
  <!-- RETORNA  : map(*)* — LA MISMA GRILLA                          -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-abajo" as="map(*)*">
    <xsl:param name="g" as="map(*)*"/>
    <xsl:sequence select="
      for $r in 1 to count($g) return map{
        'cruza': $g[$r]?cruza,
        'items': array{
          for $m in array:flatten($g[$r]?items) return
            if (exists($m?celda) and $m?rs gt 1) then map:put($m, 'celda', ())
            else if (empty($m?celda)) then
              (for $q in 1 to $r - 1, $o in array:flatten($g[$q]?items)
               return if (exists($o?celda) and $o?col = $m?col and $q + $o?rs - 1 = $r)
                      then map:put($m, 'celda', $o?celda) else (),
               $m)[1]
            else $m }}"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-filete                                    -->
  <!-- PROPÓSITO: EL FILETE ENTRE DOS FILAS: \midrule SI NINGUNA     -->
  <!--            CELDA SIGUE UNIDA; SI NO, UN \cmidrule POR CADA    -->
  <!--            TRAMO DE COLUMNAS LIBRES (EL \cmidrule{2-n} DE LA   -->
  <!--            CASA ENTRE LAS FILAS DE UN GRUPO). DOBLE EN UN     -->
  <!--            BLOQUE (bloques:)                                  -->
  <!-- PARÁMETROS: cruza As xs:integer*; n As xs:integer; doble As  -->
  <!--            xs:boolean                                        -->
  <!-- RETORNA  : xs:string — CON EL SALTO DE LÍNEA                 -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-filete" as="xs:string">
    <xsl:param name="cruza" as="xs:integer*"/>
    <xsl:param name="n" as="xs:integer"/>
    <xsl:param name="doble" as="xs:boolean"/>
    <xsl:variable name="tramos" as="xs:string*">
      <xsl:for-each-group select="(1 to $n)[not(. = $cruza)]" group-adjacent=". - position()">
        <xsl:sequence select="concat('\cmidrule{', current-group()[1], '-', current-group()[last()], '}')"/>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:sequence select="
      if (empty($cruza)) then (if ($doble) then '\midrule&#10;\midrule&#10;' else '\midrule&#10;')
      else concat(string-join($tramos, ''), '&#10;')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:cuadro-cantidad                                  -->
  <!-- PROPÓSITO: LA CIFRA DE ENTRADA SI LA CELDA ES SOLO UNA       -->
  <!--            CANTIDAD «num X» (SC-65), EN LOS DOS VOCABULARIOS -->
  <!-- PARÁMETROS: c As element()                                   -->
  <!-- RETORNA  : xs:string? — VACÍO SI NO LO ES                    -->
  <!-- ============================================================ -->
  <xsl:function name="f:cuadro-cantidad" as="xs:string?">
    <xsl:param name="c" as="element()"/>
    <xsl:variable name="q" select="$c/*[@role = 'cantidad' or @content-type = 'cantidad']"/>
    <xsl:variable name="ficha" select="string(($q/@remap, $q/@specific-use)[1])"/>
    <xsl:sequence select="
      if (count($c/*) = 1 and exists($q) and starts-with($ficha, 'num ')
          and normalize-space($c) = normalize-space($q))
      then substring-after($ficha, 'num ') else ()"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: gb-cuadro-latex                                   -->
  <!-- PROPÓSITO: EL CUADRO COMPLETO, COMÚN A LIBROS Y REVISTAS: UN -->
  <!--   FLOTANTE POR TRAMO (cortes:), CON EL ENCABEZADO REPETIDO Y  -->
  <!--   LOS TEXTOS DE CONTINUACIÓN; EL PIE Y LA ETIQUETA EN EL      -->
  <!--   ÚLTIMO; sidewaystable SI ROTA; gbcuadrototal SI USA EL      -->
  <!--   ANCHO TOTAL DE LA REVISTA. ES UNA PLANTILLA CON NOMBRE: LA  -->
  <!--   LLAMA LA PLANTILLA DE CADA HOJA (GV-117), Y EL CONTENIDO DE  -->
  <!--   LAS CELDAS LO RESUELVEN LAS REGLAS DE ESA HOJA.             -->
  <!-- PARÁMETROS: pi — LA INSTRUCCIÓN gb-cuadro; encabezado, cuerpo -->
  <!--   — LAS FILAS; rotar As xs:boolean; pie As xs:string — EL     -->
  <!--   \caption YA ARMADO; id As xs:string                         -->
  <!-- ============================================================ -->
  <xsl:template name="gb-cuadro-latex">
    <xsl:param name="pi" as="processing-instruction()"/>
    <xsl:param name="encabezado" as="element()*"/>
    <xsl:param name="cuerpo" as="element()*"/>
    <xsl:param name="rotar" as="xs:boolean"/>
    <xsl:param name="pie" as="xs:string"/>
    <xsl:param name="id" as="xs:string"/>
    <xsl:variable name="fichas" select="tokenize(f:pi-valor($pi, 'columnas'), ' ')"/>
    <xsl:variable name="n" select="count($fichas)"/>
    <xsl:variable name="cortes" select="for $t in tokenize(f:pi-valor($pi, 'cortes'), ' ') return xs:integer($t)"/>
    <xsl:variable name="bloques" select="for $t in tokenize(f:pi-valor($pi, 'bloques'), ' ') return xs:integer($t)"/>
    <xsl:variable name="total" select="f:pi-valor($pi, 'ancho') = 'total'"/>
    <!-- EN EL ENCABEZADO, LA CELDA QUE UNE FILAS LLEVA EL TEXTO EN LA
         ÚLTIMA, JUNTO A LOS RÓTULOS DE LAS COLUMNAS («Período» EN EL
         cuadroX2 DE LA CASA); EN EL CUERPO, EN LA PRIMERA (EL GRUPO) -->
    <xsl:variable name="g-enc" select="f:cuadro-abajo(f:cuadro-grilla($encabezado, $n))"/>
    <xsl:variable name="g-cue" select="f:cuadro-grilla($cuerpo, $n)"/>

    <!-- 1. LAS COLUMNAS: LA DE CIFRAS CON SU table-format, DE SUS CIFRAS SOLAS -->
    <xsl:variable name="columnas" as="xs:string*">
      <xsl:for-each select="1 to $n">
        <xsl:variable name="i" select="."/>
        <xsl:sequence select="f:cuadro-columna($fichas[$i], f:cuadro-formato(
          for $fila in $g-cue, $m in array:flatten($fila?items)
          return if ($m?col = $i and $m?cs = 1 and exists($m?celda))
                 then f:cuadro-cantidad($m?celda) else ()))"/>
      </xsl:for-each>
    </xsl:variable>

    <!-- 2. LOS TRAMOS: LOS NÚMEROS DE FILA DONDE EMPIEZA CADA UNO -->
    <xsl:variable name="inicios" select="(1, for $k in $cortes return $k + 1)"/>
    <xsl:for-each select="$inicios">
      <xsl:variable name="t" select="position()"/>
      <xsl:variable name="desde" select="."/>
      <xsl:variable name="hasta" select="if ($t = count($inicios)) then count($cuerpo) else $inicios[$t + 1] - 1"/>
      <xsl:variable name="ultimo" select="$t = count($inicios)"/>

      <!-- 2a. EL FLOTANTE Y LA LETRA: ALCANZAN TAMBIÉN AL PIE -->
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="if ($rotar) then '\begin{sidewaystable}' else '\begin{table}[!ht]'"/>
      <xsl:text>&#10;\gbCuadroLetra</xsl:text>
      <xsl:value-of select="if (f:pi-valor($pi, 'cuerpo') = 'chico')
                            then '\gbCuadroCuerpoChico' else '\gbCuadroCuerpoNormal'"/>
      <xsl:text>\setlength\tabcolsep{</xsl:text>
      <xsl:value-of select="if (f:pi-valor($pi, 'separacion') = 'estrecha')
                            then '\gbCuadroSepEstrecha' else '\gbCuadroSepNormal'"/>
      <xsl:text>}%&#10;</xsl:text>
      <xsl:if test="$total"><xsl:text>\begin{gbcuadrototal}&#10;</xsl:text></xsl:if>
      <xsl:text>\centering&#10;\begin{tabular}{</xsl:text>
      <xsl:value-of select="string-join($columnas, ' | ')"/>
      <xsl:text>}&#10;\toprule&#10;</xsl:text>

      <!-- 2b. «VIENE DE LA PÁGINA ANTERIOR» EN LOS TRAMOS QUE SIGUEN -->
      <xsl:if test="$t &gt; 1">
        <xsl:value-of select="concat('\multicolumn{', $n, '}{l}{\emph{\gbCuadroViene}} \\&#10;\midrule&#10;')"/>
      </xsl:if>

      <!-- 2c. EL ENCABEZADO, EN CADA TRAMO -->
      <xsl:for-each select="$g-enc">
        <xsl:call-template name="gb-cuadro-fila">
          <xsl:with-param name="items" select="?items"/>
          <xsl:with-param name="fichas" select="$fichas"/>
          <xsl:with-param name="encabezado" select="true()"/>
        </xsl:call-template>
        <xsl:value-of select="if (position() = last()) then '\midrule&#10;'
                              else f:cuadro-filete(?cruza, $n, false())"/>
      </xsl:for-each>

      <!-- 2d. LAS FILAS DEL TRAMO, CON SU FILETE -->
      <xsl:for-each select="$g-cue[position() ge $desde and position() le $hasta]">
        <xsl:variable name="r" select="$desde + position() - 1"/>
        <xsl:call-template name="gb-cuadro-fila">
          <xsl:with-param name="items" select="?items"/>
          <xsl:with-param name="fichas" select="$fichas"/>
          <xsl:with-param name="encabezado" select="false()"/>
        </xsl:call-template>
        <xsl:if test="$r lt $hasta">
          <xsl:value-of select="f:cuadro-filete(?cruza, $n, $r = $bloques)"/>
        </xsl:if>
      </xsl:for-each>

      <!-- 2e. «CONTINÚA EN LA PÁGINA SIGUIENTE» EN LOS TRAMOS QUE NO SON EL ÚLTIMO -->
      <xsl:if test="not($ultimo)">
        <xsl:value-of select="concat('\midrule&#10;\multicolumn{', $n, '}{r}{\emph{\gbCuadroContinua}} \\&#10;')"/>
      </xsl:if>
      <xsl:text>\bottomrule&#10;\end{tabular}&#10;</xsl:text>

      <!-- 2f. EL PIE Y LA ETIQUETA, SOLO EN EL ÚLTIMO: EL NÚMERO ES UNO -->
      <xsl:if test="$ultimo">
        <xsl:value-of select="$pie"/>
        <xsl:value-of select="concat('\label{', $id, '}&#10;')"/>
      </xsl:if>
      <xsl:if test="$total"><xsl:text>\end{gbcuadrototal}&#10;</xsl:text></xsl:if>
      <xsl:value-of select="if ($rotar) then '\end{sidewaystable}&#10;' else '\end{table}&#10;'"/>
    </xsl:for-each>
    <xsl:text>&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- PLANTILLA: gb-cuadro-fila                                    -->
  <!-- PROPÓSITO: UNA FILA DEL CUADRO. LA CELDA QUE UNE COLUMNAS:    -->
  <!--   \multicolumn{n}{c|}{…} (SIN EL FILETE SI LLEGA A LA ÚLTIMA). -->
  <!--   LA OCUPADA DESDE ARRIBA: VACÍA. EN LA COLUMNA DE CIFRAS, LA  -->
  <!--   CIFRA VA SOLA, COMO LA LEE LA COLUMNA S; LO QUE NO ES UNA    -->
  <!--   CIFRA, ENTRE LLAVES. EL ENCABEZADO, EN NEGRITA.             -->
  <!-- PARÁMETROS: items As array(*); fichas As xs:string*;         -->
  <!--   encabezado As xs:boolean                                   -->
  <!-- ============================================================ -->
  <xsl:template name="gb-cuadro-fila">
    <xsl:param name="items" as="array(*)"/>
    <xsl:param name="fichas" as="xs:string*"/>
    <xsl:param name="encabezado" as="xs:boolean"/>
    <xsl:variable name="n" select="count($fichas)"/>
    <xsl:for-each select="array:flatten($items)">
      <xsl:variable name="m" select="."/>
      <xsl:variable name="cifra" select="$fichas[$m?col] = 'cifra' and $m?cs = 1"/>
      <xsl:variable name="valor" select="if (exists($m?celda) and $cifra and not($encabezado))
                                         then f:cuadro-cantidad($m?celda) else ()"/>
      <xsl:variable name="texto" as="xs:string">
        <xsl:choose>
          <xsl:when test="empty($m?celda)"><xsl:sequence select="''"/></xsl:when>
          <xsl:when test="exists($valor)"><xsl:sequence select="$valor"/></xsl:when>
          <xsl:otherwise>
            <xsl:variable name="c"><xsl:apply-templates select="$m?celda/node()"/></xsl:variable>
            <xsl:variable name="c2" select="normalize-space($c)"/>
            <xsl:sequence select="
              if ($c2 = '') then ''
              else concat(if ($cifra) then '{' else '',
                          if ($encabezado) then concat('\textbf{', $c2, '}') else $c2,
                          if ($cifra) then '}' else '')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="position() &gt; 1"><xsl:text> &amp; </xsl:text></xsl:if>
      <xsl:value-of select="
        if ($m?cs &gt; 1)
        then concat('\multicolumn{', $m?cs, '}{c', if ($m?col + $m?cs - 1 lt $n) then '|' else '', '}{', $texto, '}')
        else $texto"/>
    </xsl:for-each>
    <xsl:text> \\&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : f:codigo-latex                                     -->
  <!-- PROPÓSITO: EL BLOQUE DE CÓDIGO COMPLETO (SC-42): EL ENTORNO  -->
  <!--            gbCodigo CON EL RÓTULO DEL LENGUAJE Y LAS LÍNEAS  -->
  <!--            QUE ESCRIBIÓ colorear_codigo.lua. LAS MACROS LAS  -->
  <!--            DEFINE EL PREÁMBULO (CONTRATO 11).                -->
  <!-- PARÁMETROS: el As element() — <code> O <programlisting>      -->
  <!-- RETORNA  : xs:string — EL BLOQUE, CON LÍNEAS EN BLANCO       -->
  <!--            ALREDEDOR                                         -->
  <!-- NOTA     : CON codigo_dir, FALTAR EL ARCHIVO DE UN BLOQUE ES -->
  <!--            UN ERROR DE LA CADENA Y CORTA LA TRANSFORMACIÓN:  -->
  <!--            NO SE DEGRADA EN SILENCIO. SIN codigo_dir, LAS    -->
  <!--            LÍNEAS SALEN SIN COLOR, CON LA MISMA NUMERACIÓN.  -->
  <!-- ============================================================ -->
  <xsl:function name="f:codigo-latex" as="xs:string">
    <xsl:param name="el" as="element()"/>
    <xsl:variable name="archivo" select="gbc:archivo($el, $codigo_dir, '.tex')"/>
    <xsl:variable name="lineas" as="xs:string">
      <xsl:choose>
        <xsl:when test="$archivo != '' and unparsed-text-available($archivo)">
          <xsl:sequence select="unparsed-text($archivo)"/>
        </xsl:when>
        <xsl:when test="$archivo != ''">
          <xsl:message terminate="yes">
            <xsl:text>[código] Falta el bloque coloreado </xsl:text>
            <xsl:value-of select="$archivo"/>
            <xsl:text>: colorear_codigo.sh no corrió sobre este XML.</xsl:text>
          </xsl:message>
        </xsl:when>
        <xsl:otherwise>
          <!-- SIN COLOR: LA MISMA FORMA QUE ESCRIBE colorear_codigo.lua,
               CON \NormalTok Y SOLO LA BARRA Y LAS LLAVES ESCAPADAS
               (EN UN Verbatim CON commandchars SON LAS ÚNICAS ACTIVAS).
               U+E000 GUARDA EL LUGAR DE LAS LLAVES DE \textbackslash{}
               PARA QUE EL PASO DE LAS LLAVES NO LAS ESCAPE -->
          <xsl:message>[código] codigo_dir vacío: el bloque sale sin color</xsl:message>
          <xsl:variable name="t" select="gbc:lineas($el)"/>
          <xsl:variable name="r" select="gbc:con-retorno($el)"/>
          <xsl:variable name="n" select="gbc:numeros($el)"/>
          <xsl:sequence select="string-join(
            for $i in 1 to count($t) return concat(
              if ($n[$i] gt 0) then concat('\gbnl{', $n[$i], '}') else '\gbnc',
              if ($t[$i] = '') then ''
              else concat('\NormalTok{',
                replace(replace(replace($t[$i], '\\', '\\textbackslash&#xE000;'),
                  '([{}])', '\\$1'), '&#xE000;', '{}'), '}'),
              if ($r[$i]) then '\gbret' else ''), '&#10;')"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="concat('&#10;\begin{gbCodigo}{', gbc:rotulo($el), '}&#10;',
                                 replace($lineas, '\n$', ''),
                                 '&#10;\end{gbCodigo}&#10;&#10;')"/>
  </xsl:function>

</xsl:stylesheet>
