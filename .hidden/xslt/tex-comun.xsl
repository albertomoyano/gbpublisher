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
    f:babel-lang()    ISO 639-1 → nombre de idioma babel
    f:ruta-imagen()   normalización de rutas de imagen
    f:comando-cita()  modo de cita → comando biblatex
    abortar-elemento  plantilla de corte ante vocabulario
                      no previsto
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
  exclude-result-prefixes="xs f">

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

</xsl:stylesheet>
