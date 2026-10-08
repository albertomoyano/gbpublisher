<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  codigo-comun.xsl
  ============================================================
  PROPÓSITO : LAS REGLAS DEL CÓDIGO (SC-42) QUE COMPARTEN LAS SEIS
              HOJAS DE SALIDA Y extraer-codigo.xsl: QUÉ NÚMERO TIENE
              CADA BLOQUE, CÓMO SE LEE SU TEXTO, CON QUÉ LENGUAJE SE
              COLOREA, QUÉ RÓTULO LLEVA Y CÓMO SE PARTE EN LÍNEAS.
  USO       : SE INCLUYE CON xsl:include, COMO quote.xsl. LAS
              FUNCIONES NOMBRAN LOS ELEMENTOS CON SU ESPACIO DE
              NOMBRES EXPLÍCITO: NO DEPENDEN DEL xpath-default-namespace
              DE LA HOJA QUE LAS INCLUYE.
  GEMELOS   : LA LISTA DE LENGUAJES ES LA DE codigo.lua (LA QUE
              VALIDA) Y LA REGLA DEL RETORNO ↩ ES LA DE
              colorear_codigo.lua (LA QUE COLOREA). UN CAMBIO VA EN
              LOS TRES.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:gbc="urn:gbpublisher:codigo"
  exclude-result-prefixes="xs db gbc">

  <!-- EL CARÁCTER DE CORTE MANUAL: ↩ (U+21A9) AL FINAL DE LA LÍNEA.
       IBM Plex Mono LO TIENE (MEDIDO); ↵ Y ⏎ NO. -->
  <xsl:variable name="gbc:retorno" as="xs:string" select="'&#x21A9;'"/>

  <!-- ==========================================================
       gbc:numero: LA POSICIÓN DEL BLOQUE EN SU DOCUMENTO. ES LA
       CLAVE DEL ARCHIVO COLOREADO codigo-N: extraer-codigo.xsl Y LA
       HOJA DE SALIDA CORREN SOBRE EL MISMO XML Y CUENTAN IGUAL.
       ========================================================== -->
  <xsl:function name="gbc:numero" as="xs:integer">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="if (namespace-uri($el) = 'http://docbook.org/ns/docbook')
                          then count($el/preceding::db:programlisting) + 1
                          else count($el/preceding::code) + 1"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:texto: EL TEXTO DEL BLOQUE SIN EL SALTO INICIAL NI EL
       FINAL QUE AGREGAN ALGUNOS ESCRITORES DE PANDOC. UN CodeBlock
       DE PANDOC NUNCA EMPIEZA NI TERMINA CON UN SALTO PROPIO.
       ========================================================== -->
  <xsl:function name="gbc:texto" as="xs:string">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="replace(replace(string($el), '^\n', ''), '\n$', '')"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:lenguaje: EL LENGUAJE TAL COMO LO ESCRIBIÓ EL EDITOR, EN
       MINÚSCULAS. VACÍO ES TEXTO SIN COLOR (codigo.lua NO ESCRIBE
       language PARA texto).
       ========================================================== -->
  <xsl:function name="gbc:lenguaje" as="xs:string">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="lower-case(normalize-space($el/@language))"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:lenguaje-color: EL NOMBRE QUE ENTIENDE EL RESALTADOR DE
       PANDOC. DOCBOOK Y JATS NO TIENEN SINTAXIS PROPIA: SON XML.
       ========================================================== -->
  <xsl:function name="gbc:lenguaje-color" as="xs:string">
    <xsl:param name="el" as="element()"/>
    <xsl:variable name="l" select="gbc:lenguaje($el)"/>
    <xsl:sequence select="if ($l = ('docbook', 'jats')) then 'xml'
                          else if ($l = 'texto') then ''
                          else $l"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:rotulo: EL NOMBRE DEL LENGUAJE EN LA CABECERA DEL BLOQUE.
       UN LENGUAJE FUERA DE LA LISTA NO LLEGA HASTA ACÁ (LO FRENA
       codigo.lua); SI LLEGA, SE MUESTRA COMO ESTÁ.
       ========================================================== -->
  <xsl:function name="gbc:rotulo" as="xs:string">
    <xsl:param name="el" as="element()"/>
    <xsl:variable name="l" select="gbc:lenguaje($el)"/>
    <xsl:variable name="m" as="map(xs:string, xs:string)" select="map {
      'python': 'Python', 'r': 'R', 'sql': 'SQL', 'bash': 'Bash',
      'javascript': 'JavaScript', 'json': 'JSON', 'yaml': 'YAML',
      'markdown': 'Markdown', 'latex': 'LaTeX', 'html': 'HTML',
      'xml': 'XML', 'xslt': 'XSLT', 'css': 'CSS', 'lua': 'Lua',
      'docbook': 'DocBook', 'jats': 'JATS', 'texto': 'Texto', '': 'Texto' }"/>
    <xsl:sequence select="if (map:contains($m, $l)) then $m($l) else $l"
                  xmlns:map="http://www.w3.org/2005/xpath-functions/map"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:lineas: LAS LÍNEAS DEL BLOQUE SIN EL ↩ FINAL.
       gbc:con-retorno: SI CADA LÍNEA TERMINA EN ↩ (CORTE MANUAL).
       gbc:numeros: EL NÚMERO VISIBLE DE CADA LÍNEA; 0 EN LA
       CONTINUACIÓN DE UN CORTE, QUE NO SE NUMERA.
       LA REGLA ES LA DE colorear_codigo.lua: ↩ AL FINAL DE LA LÍNEA,
       CON BLANCOS DESPUÉS O SIN ELLOS.
       ========================================================== -->
  <xsl:function name="gbc:lineas-crudas" as="xs:string*">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="tokenize(gbc:texto($el), '\n')"/>
  </xsl:function>

  <xsl:function name="gbc:con-retorno" as="xs:boolean*">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="for $l in gbc:lineas-crudas($el)
                          return matches($l, concat($gbc:retorno, '\s*$'))"/>
  </xsl:function>

  <xsl:function name="gbc:lineas" as="xs:string*">
    <xsl:param name="el" as="element()"/>
    <xsl:sequence select="for $l in gbc:lineas-crudas($el)
                          return replace($l, concat($gbc:retorno, '\s*$'), '')"/>
  </xsl:function>

  <xsl:function name="gbc:numeros" as="xs:integer*">
    <xsl:param name="el" as="element()"/>
    <xsl:variable name="r" select="gbc:con-retorno($el)"/>
    <!-- UNA LÍNEA ES CONTINUACIÓN SI LA ANTERIOR TERMINA EN ↩ -->
    <xsl:variable name="cont" select="for $i in 1 to count($r)
                                      return $i gt 1 and $r[$i - 1]"/>
    <xsl:sequence select="for $i in 1 to count($r)
                          return if ($cont[$i]) then 0
                                 else count($cont[position() le $i][not(.)])"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:uri-carpeta: LA URI file:/// DE UNA CARPETA DADA COMO RUTA
       ABSOLUTA, CON BARRA FINAL. iri-to-uri ESCAPA LOS ESPACIOS Y LOS
       CARACTERES NO ASCII DE UNA RUTA DE PROYECTO.
       ========================================================== -->
  <xsl:function name="gbc:uri-carpeta" as="xs:string">
    <xsl:param name="ruta" as="xs:string"/>
    <xsl:sequence select="iri-to-uri(concat('file://', $ruta,
                          if (ends-with($ruta, '/')) then '' else '/'))"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:archivo: LA URI DEL ARCHIVO COLOREADO DE UN BLOQUE, O ''
       SI LA HOJA NO RECIBIÓ LA CARPETA (LA SALIDA SIN COLOR: EPUB).
       ========================================================== -->
  <xsl:function name="gbc:archivo" as="xs:string">
    <xsl:param name="el" as="element()"/>
    <xsl:param name="dir" as="xs:string"/>
    <xsl:param name="extension" as="xs:string"/>
    <xsl:sequence select="if (normalize-space($dir) = '') then ''
                          else concat(gbc:uri-carpeta($dir), 'codigo-', gbc:numero($el), $extension)"/>
  </xsl:function>

  <!-- ==========================================================
       gbc:bloque-html: EL BLOQUE DE CÓDIGO EN HTML O XHTML, IGUAL EN
       LAS CUATRO HOJAS DIGITALES:
         <div class="gb-codigo" data-lenguaje="python">
           <div class="gb-codigo-cab">Python</div>
           <pre class="gb-codigo-cuerpo"><code>LÍNEAS</code></pre>
         </div>
       CADA LÍNEA ES <span class="gb-l" data-n="N"> O, LA
       CONTINUACIÓN DE UN CORTE, <span class="gb-l gb-cont">; EL ↩ ES
       <span class="gb-ret">.
       PARÁMETROS:
         el      <code> O <programlisting>
         ns      EL ESPACIO DE NOMBRES DE LA SALIDA ('' EN HTML SIN
                 ESPACIO, EL DE XHTML EN LAS DEMÁS)
         dir     LA CARPETA DEL COLOREADO (codigo_dir). CON dir, LAS
                 LÍNEAS SON LAS DE codigo-N.html, CON LOS TOKENS DE
                 skylighting; SI EL ARCHIVO FALTA, LA HOJA SE CORTA. SIN
                 dir (EPUB), LAS LÍNEAS SALEN SIN COLOR.
         texto   true(): EL NÚMERO Y EL ↩ VAN COMO TEXTO EN SPANS
                 (<span class="gb-n">, ↩ DENTRO DE gb-ret): EN EL EPUB
                 NO TODOS LOS LECTORES DIBUJAN EL CONTENIDO GENERADO
                 POR CSS. false(): LOS DIBUJA EL CSS (::before, ::after)
                 Y ASÍ NO SE COPIAN CON EL CÓDIGO.
       LAS LÍNEAS DEL ARCHIVO SE LEEN CON parse-xml-fragment Y SE
       REHACEN EN EL ESPACIO DE NOMBRES DE LA SALIDA (MODO gbc:ns): SIN
       disable-output-escaping, QUE SE PIERDE SI EL RESULTADO PASA POR
       UNA VARIABLE.
       ========================================================== -->
  <xsl:template name="gbc:bloque-html">
    <xsl:param name="el" as="element()"/>
    <xsl:param name="ns" as="xs:string"/>
    <xsl:param name="dir" as="xs:string" select="''"/>
    <xsl:param name="texto" as="xs:boolean" select="false()"/>

    <xsl:variable name="archivo" select="gbc:archivo($el, $dir, '.html')"/>
    <xsl:if test="$archivo != '' and not(unparsed-text-available($archivo))">
      <xsl:message terminate="yes">
        <xsl:text>[código] Falta el bloque coloreado </xsl:text>
        <xsl:value-of select="$archivo"/>
        <xsl:text>: colorear_codigo.sh no corrió sobre este XML.</xsl:text>
      </xsl:message>
    </xsl:if>

    <xsl:element name="div" namespace="{$ns}">
      <xsl:attribute name="class" select="'gb-codigo'"/>
      <xsl:attribute name="data-lenguaje" select="if (gbc:lenguaje($el) = '') then 'texto' else gbc:lenguaje($el)"/>
      <xsl:element name="div" namespace="{$ns}">
        <xsl:attribute name="class" select="'gb-codigo-cab'"/>
        <xsl:value-of select="gbc:rotulo($el)"/>
      </xsl:element>
      <xsl:element name="pre" namespace="{$ns}">
        <xsl:attribute name="class" select="'gb-codigo-cuerpo'"/>
        <xsl:element name="code" namespace="{$ns}">
          <xsl:choose>
            <!-- COLOREADO: LAS LÍNEAS DE colorear_codigo.lua -->
            <xsl:when test="$archivo != ''">
              <xsl:apply-templates select="parse-xml-fragment(unparsed-text($archivo))/*/node()"
                                   mode="gbc:ns">
                <xsl:with-param name="ns" select="$ns" tunnel="yes"/>
              </xsl:apply-templates>
            </xsl:when>
            <!-- SIN COLOR: LAS MISMAS LÍNEAS, CON LA MISMA REGLA DEL ↩ -->
            <xsl:otherwise>
              <xsl:variable name="t" select="gbc:lineas($el)"/>
              <xsl:variable name="r" select="gbc:con-retorno($el)"/>
              <xsl:variable name="n" select="gbc:numeros($el)"/>
              <xsl:for-each select="1 to count($t)">
                <xsl:variable name="i" select="."/>
                <xsl:if test="$i gt 1"><xsl:text>&#10;</xsl:text></xsl:if>
                <xsl:element name="span" namespace="{$ns}">
                  <xsl:attribute name="class" select="if ($n[$i] gt 0) then 'gb-l' else 'gb-l gb-cont'"/>
                  <xsl:if test="$n[$i] gt 0 and not($texto)">
                    <xsl:attribute name="data-n" select="$n[$i]"/>
                  </xsl:if>
                  <xsl:if test="$texto">
                    <xsl:element name="span" namespace="{$ns}">
                      <xsl:attribute name="class" select="'gb-n'"/>
                      <!-- LA CONTINUACIÓN LLEVA UN ESPACIO DURO: UN span VACÍO SE
                           ESCRIBE <span/> EN XHTML, Y UN LECTOR QUE LO TOME COMO
                           HTML LO ABRE Y NO LO CIERRA (MEDIDO EN CHROMIUM) -->
                      <xsl:value-of select="if ($n[$i] gt 0) then string($n[$i]) else '&#xA0;'"/>
                    </xsl:element>
                  </xsl:if>
                  <xsl:value-of select="$t[$i]"/>
                  <xsl:if test="$r[$i]">
                    <xsl:element name="span" namespace="{$ns}">
                      <xsl:attribute name="class" select="'gb-ret'"/>
                      <xsl:if test="$texto"><xsl:value-of select="$gbc:retorno"/></xsl:if>
                    </xsl:element>
                  </xsl:if>
                </xsl:element>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:element>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- MODO gbc:ns: COPIA UN FRAGMENTO SIN ESPACIO DE NOMBRES AL DE LA
       SALIDA. SOLO HAY span CON class Y data-n, Y TEXTO -->
  <xsl:template match="*" mode="gbc:ns">
    <xsl:param name="ns" as="xs:string" tunnel="yes"/>
    <xsl:element name="{local-name()}" namespace="{$ns}">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="gbc:ns"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="text()" mode="gbc:ns">
    <xsl:value-of select="."/>
  </xsl:template>

</xsl:stylesheet>
