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
    f:comando-cita()  modo de cita → comando biblatex
    abortar-elemento  plantilla de corte ante vocabulario
                      no previsto
    gb-espacio        ficha de espacio vertical del PDF (SC-39)
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
  exclude-result-prefixes="xs f gbc">

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
  <!-- ============================================================ -->
  <xsl:variable name="f:mapa-tex" as="map(xs:string, xs:string)" select="
    map {
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
  <!--            TEXTO PROVENIENTE DEL XML.                        -->
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
  <!-- FUNCIÓN : f:comando-cita                                     -->
  <!-- PROPÓSITO: TRADUCE EL MODO DE CITA DEL CANÓNICO AL COMANDO   -->
  <!--            DE biblatex QUE CORRESPONDE.                      -->
  <!-- PARÁMETROS: modo   As xs:string — normal|author-in-text|     -->
  <!--                                   suppress                  -->
  <!--             estilo As xs:string — familia de estilo activa   -->
  <!-- RETORNA  : xs:string — nombre del comando, con la barra      -->
  <!-- ALCANCE  : SOLO biblatex. LLAMARLA CON UN ESTILO DE bibtex   -->
  <!--            ES UN ERROR DEL LLAMADOR: LA HOJA DEBE HABER      -->
  <!--            CORTADO ANTES CON f:motor-cita.                   -->
  <!-- NOTA SOBRE suppress EN ESTILOS NUMÉRICOS:                    -->
  <!--   \parencite* SUPRIME EL AUTOR EN ESTILOS AUTOR-FECHA. EN UN -->
  <!--   ESTILO NUMÉRICO NO HAY AUTOR QUE SUPRIMIR, ASÍ QUE CAE A   -->
  <!--   LA FORMA NORMAL. ESTO DEBE COINCIDIR CON LO QUE HAGA LA    -->
  <!--   RAMA HTML: SI ALLÁ SE RESUELVE DE OTRA FORMA, SE CORRIGE   -->
  <!--   ACÁ Y QUEDA CORREGIDO EN LAS DOS RAMAS.                    -->
  <!-- PENDIENTE: ISO690 TIENE VARIANTE AUTOR-FECHA Y VARIANTE      -->
  <!--   NUMÉRICA. ACÁ SE LO TRATA COMO AUTOR-FECHA. SI EL PROYECTO -->
  <!--   USA LA NUMÉRICA, AGREGARLO A LA CONDICIÓN $numerico.       -->
  <!-- ============================================================ -->
  <xsl:function name="f:comando-cita" as="xs:string">
    <xsl:param name="modo"   as="xs:string"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:variable name="numerico" select="$estilo = 'ieee'"/>
    <xsl:choose>
      <xsl:when test="$modo = 'author-in-text'">\textcite</xsl:when>
      <xsl:when test="$modo = 'suppress' and not($numerico)">\parencite*</xsl:when>
      <xsl:otherwise>\parencite</xsl:otherwise>
    </xsl:choose>
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
