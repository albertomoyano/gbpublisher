<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  cita-comun.xsl
  ============================================================
  PROPÓSITO : LAS REGLAS DE LAS CITAS DE LIBRO QUE COMPARTEN EL
              PDF, LA PASADA DE CITAS Y LAS HOJAS DE HTML Y EPUB
              (SC-57): QUÉ COMANDO DE biblatex LE TOCA A CADA MODO,
              QUÉ biblioref FORMAN UN GRUPO Y QUÉ id TIENE CADA
              GRUPO.
  POR QUÉ   : EL TEXTO DE UNA CITA DE HTML Y EPUB SALE DE citas.html,
              DONDE CADA GRUPO ES <span id="gbcita-{id}">. PARA
              ENCONTRARLO, LAS HOJAS TIENEN QUE AGRUPAR EXACTAMENTE
              COMO EL PDF: LA REGLA ES UNA SOLA Y VIVE ACÁ. ANTES
              ESTABA EN docbook-to-latex.xsl, Y LA HOJA DEL HTML
              TENÍA OTRA, DISTINTA: LE SACABA EL SEPARADOR A DOS
              CITAS DE MODO DISTINTO QUE biblatex COMPONE APARTE.
  USO       : SE INCLUYE CON xsl:include, COMO codigo-comun.xsl. LAS
              FUNCIONES NOMBRAN LOS ELEMENTOS CON SU ESPACIO DE
              NOMBRES EXPLÍCITO: NO DEPENDEN DEL xpath-default-namespace
              DE LA HOJA QUE LAS INCLUYE. NO HAY PLANTILLAS: QUÉ SE
              HACE CON UN GRUPO LO DECIDE CADA HOJA.
  ESTILO    : EL ESTILO DE CITA LLEGA COMO PARÁMETRO EXPLÍCITO Y NO
              COMO VARIABLE GLOBAL: CADA HOJA LO TIENE CON OTRO
              NOMBRE ($estilo EN EL PDF, $estilo_cita EN HTML Y EPUB),
              Y UN CONTRATO POR NOMBRE DE VARIABLE NO SE VE.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:gbct="urn:gbpublisher:citas"
  exclude-result-prefixes="xs db gbct">

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:comando-cita                                  -->
  <!-- PROPÓSITO: TRADUCE EL MODO DE CITA DEL CANÓNICO AL COMANDO   -->
  <!--            DE biblatex QUE CORRESPONDE.                      -->
  <!-- PARÁMETROS: modo   As xs:string — normal|author-in-text|     -->
  <!--                                   suppress                  -->
  <!--             estilo As xs:string — familia de estilo activa   -->
  <!-- RETORNA  : xs:string — nombre del comando, con la barra      -->
  <!-- ALCANCE  : SOLO biblatex. LLAMARLA CON UN ESTILO DE bibtex   -->
  <!--            ES UN ERROR DEL LLAMADOR: LA HOJA DEBE HABER      -->
  <!--            CORTADO ANTES CON f:motor-cita (tex-comun.xsl).   -->
  <!-- NOTA SOBRE suppress EN ESTILOS NUMÉRICOS:                    -->
  <!--   \parencite* SUPRIME EL AUTOR EN ESTILOS AUTOR-FECHA. EN UN -->
  <!--   ESTILO NUMÉRICO NO HAY AUTOR QUE SUPRIMIR, ASÍ QUE CAE A   -->
  <!--   LA FORMA NORMAL.                                           -->
  <!-- PENDIENTE: ISO690 TIENE VARIANTE AUTOR-FECHA Y VARIANTE      -->
  <!--   NUMÉRICA. ACÁ SE LO TRATA COMO AUTOR-FECHA. SI EL PROYECTO -->
  <!--   USA LA NUMÉRICA, AGREGARLO A LA CONDICIÓN $numerico.       -->
  <!-- ORIGEN   : ERA f:comando-cita DE tex-comun.xsl. SE MUDÓ ACÁ  -->
  <!--            PORQUE EL AGRUPAMIENTO DEPENDE DE ÉL.             -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:comando-cita" as="xs:string">
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
  <!-- FUNCIÓN : gbct:comando-multicita                             -->
  <!-- PROPÓSITO: LA FORMA MÚLTIPLE DE UN COMANDO DE CITA.          -->
  <!--            biblatex LA NOMBRA AGREGANDO «s»: \parencites,     -->
  <!--            \textcites, \autocites, \cites, \footcites. LOS    -->
  <!--            COMANDOS CON ASTERISCO NO TIENEN FORMA MÚLTIPLE.   -->
  <!-- PARÁMETROS: comando As xs:string — el que da comando-cita    -->
  <!-- RETORNA  : xs:string — el múltiple, o vacío si no existe     -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:comando-multicita" as="xs:string">
    <xsl:param name="comando" as="xs:string"/>
    <xsl:sequence select="if (ends-with($comando, '*')) then '' else concat($comando, 's')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:modo-de                                       -->
  <!-- PROPÓSITO: MODO EFECTIVO DE UN <biblioref>. SIN @role EL     -->
  <!--            MODO ES 'normal'.                                 -->
  <!-- PARÁMETROS: n As node()? — el biblioref, o vacío             -->
  <!-- RETORNA  : xs:string — normal | author-in-text | suppress    -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:modo-de" as="xs:string">
    <xsl:param name="n" as="node()?"/>
    <xsl:variable name="r" select="normalize-space($n/@role)"/>
    <xsl:value-of select="if (empty($n)) then ''
                          else if ($r = '') then 'normal' else $r"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- AGRUPAMIENTO DE CITAS CONSECUTIVAS                           -->
  <!-- [@a; @b; @c] LLEGA AL CANÓNICO COMO TRES <biblioref>         -->
  <!-- SEPARADOS POR NODOS DE TEXTO ', '. CADA UNO PUEDE LLEVAR     -->
  <!-- SU PREFIJO Y SU SUFIJO COMO <phrase> HERMANOS, ASÍ QUE ENTRE -->
  <!-- DOS CITAS DEL MISMO GRUPO PUEDE HABER:                       -->
  <!--   biblioref  [sufijo]  separador  [prefijo]  biblioref       -->
  <!-- Y ADEMÁS ESPACIOS DE INDENTACIÓN DEL CANÓNICO, QUE SE        -->
  <!-- SALTEAN. DOS CITAS SE AGRUPAN SI TIENEN EL MISMO MODO Y EL   -->
  <!-- COMANDO ADMITE FORMA MÚLTIPLE; SI NO LA ADMITE, SOLO CUANDO  -->
  <!-- NINGUNA DE LAS DOS LLEVA AFIJOS.                             -->
  <!-- ============================================================ -->

  <!-- VECINO SIGUIENTE / ANTERIOR, SALTEANDO LOS NODOS DE TEXTO     -->
  <!-- QUE SON SOLO ESPACIO                                         -->
  <xsl:function name="gbct:vecino-sig" as="node()?">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="$n/following-sibling::node()
                          [not(self::text() and not(normalize-space()))][1]"/>
  </xsl:function>

  <xsl:function name="gbct:vecino-ant" as="node()?">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="$n/preceding-sibling::node()
                          [not(self::text() and not(normalize-space()))][1]"/>
  </xsl:function>

  <!-- ¿ES EL NODO UN phrase DE PREFIJO O DE SUFIJO DE CITA?          -->
  <xsl:function name="gbct:es-afijo" as="xs:boolean">
    <xsl:param name="n"   as="node()?"/>
    <xsl:param name="rol" as="xs:string"/>
    <xsl:sequence select="exists($n[self::db:phrase][@role = $rol])"/>
  </xsl:function>

  <!-- EL PREFIJO / SUFIJO DE UNA CITA, O VACÍO                      -->
  <xsl:function name="gbct:prefijo-de" as="node()?">
    <xsl:param name="b" as="node()"/>
    <xsl:variable name="v" select="gbct:vecino-ant($b)"/>
    <xsl:sequence select="$v[gbct:es-afijo(., 'cite-prefix')]"/>
  </xsl:function>

  <xsl:function name="gbct:sufijo-de" as="node()?">
    <xsl:param name="b" as="node()"/>
    <xsl:variable name="v" select="gbct:vecino-sig($b)"/>
    <xsl:sequence select="$v[gbct:es-afijo(., 'cite-suffix')]"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:sin-afijos                                    -->
  <!-- PROPÓSITO: DICE SI UN biblioref NO TIENE PREFIJO NI SUFIJO   -->
  <!-- PARÁMETROS: n As node() — el biblioref                       -->
  <!-- RETORNA  : xs:boolean                                        -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:sin-afijos" as="xs:boolean">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="empty(gbct:prefijo-de($n)) and empty(gbct:sufijo-de($n))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:es-separador                                  -->
  <!-- PROPÓSITO: DICE SI UN NODO ES EL TEXTO QUE SEPARA DOS CITAS  -->
  <!--            AGRUPABLES (COMA, PUNTO Y COMA O GUION SUELTO).   -->
  <!-- PARÁMETROS: n As node()? — nodo a evaluar                    -->
  <!-- RETORNA  : xs:boolean                                        -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:es-separador" as="xs:boolean">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="exists($n[self::text()])
      and matches(string($n), '^\s*[,;\p{Pd}]\s*$')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:clave                                         -->
  <!-- PROPÓSITO: LA CLAVE DEL .bib DE UNA CITA O DE UNA ENTRADA:   -->
  <!--            EL linkend (O EL xml:id) SIN SU PREFIJO.          -->
  <!-- PARÁMETROS: id As xs:string — linkend o xml:id               -->
  <!-- RETORNA  : xs:string — la clave                              -->
  <!-- NOTA     : EL PREFIJO NO ES EL MISMO EN LOS DOS CANÓNICOS:   -->
  <!--              por capítulo   bib-3290-ACOSTA2012              -->
  <!--              ensamblado     cap-7-bib-3290-ACOSTA2012        -->
  <!--            EL 'cap-N-' LO AGREGA EL ENSAMBLADOR PARA QUE LOS -->
  <!--            ids NO COLISIONEN ENTRE CAPÍTULOS.                -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:clave" as="xs:string">
    <xsl:param name="id" as="xs:string?"/>
    <xsl:sequence select="replace(normalize-space($id), '^(cap-\d+-)?bib-', '')"/>
  </xsl:function>

  <!-- ¿SE PUEDEN AGRUPAR ESTAS DOS CITAS CONSECUTIVAS?              -->
  <xsl:function name="gbct:agrupables" as="xs:boolean">
    <xsl:param name="b"      as="node()"/>
    <xsl:param name="c"      as="node()"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:variable name="modo" select="gbct:modo-de($b)"/>
    <xsl:sequence select="$modo = gbct:modo-de($c)
      and (gbct:comando-multicita(gbct:comando-cita($modo, $estilo)) != ''
           or (gbct:sin-afijos($b) and gbct:sin-afijos($c)))"/>
  </xsl:function>

  <!-- LA CITA QUE SIGUE A ESTA EN EL MISMO GRUPO, O VACÍO:          -->
  <!-- biblioref  [sufijo]  separador  [prefijo]  biblioref          -->
  <xsl:function name="gbct:siguiente-en-grupo" as="node()?">
    <xsl:param name="b"      as="node()"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:variable name="v1"  select="gbct:vecino-sig($b)"/>
    <xsl:variable name="sep" select="if (gbct:es-afijo($v1, 'cite-suffix'))
                                     then gbct:vecino-sig($v1) else $v1"/>
    <xsl:variable name="v3"  select="if (gbct:es-separador($sep))
                                     then gbct:vecino-sig($sep) else ()"/>
    <xsl:variable name="c"   select="if (gbct:es-afijo($v3, 'cite-prefix'))
                                     then gbct:vecino-sig($v3) else $v3"/>
    <xsl:sequence select="$c[self::db:biblioref][gbct:agrupables($b, ., $estilo)]"/>
  </xsl:function>

  <!-- LA CITA QUE PRECEDE A ESTA EN EL MISMO GRUPO, O VACÍO         -->
  <xsl:function name="gbct:anterior-en-grupo" as="node()?">
    <xsl:param name="c"      as="node()"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:variable name="v1"  select="gbct:vecino-ant($c)"/>
    <xsl:variable name="sep" select="if (gbct:es-afijo($v1, 'cite-prefix'))
                                     then gbct:vecino-ant($v1) else $v1"/>
    <xsl:variable name="v3"  select="if (gbct:es-separador($sep))
                                     then gbct:vecino-ant($sep) else ()"/>
    <xsl:variable name="b"   select="if (gbct:es-afijo($v3, 'cite-suffix'))
                                     then gbct:vecino-ant($v3) else $v3"/>
    <xsl:sequence select="$b[self::db:biblioref][gbct:agrupables(., $c, $estilo)]"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:es-continuacion                               -->
  <!-- PROPÓSITO: DICE SI ESTE biblioref YA FUE ABSORBIDO POR EL    -->
  <!--            GRUPO DEL biblioref ANTERIOR.                     -->
  <!-- PARÁMETROS: n      As node()     — el biblioref              -->
  <!--             estilo As xs:string  — familia de estilo activa  -->
  <!-- RETORNA  : xs:boolean                                        -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:es-continuacion" as="xs:boolean">
    <xsl:param name="n"      as="node()"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:sequence select="exists(gbct:anterior-en-grupo($n, $estilo))"/>
  </xsl:function>

  <!-- LAS CITAS DEL GRUPO QUE EMPIEZA EN b, EN ORDEN                -->
  <xsl:function name="gbct:grupo-desde" as="node()*">
    <xsl:param name="b"      as="node()"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:variable name="c" select="gbct:siguiente-en-grupo($b, $estilo)"/>
    <xsl:sequence select="$b, if (exists($c)) then gbct:grupo-desde($c, $estilo) else ()"/>
  </xsl:function>

  <!-- EL biblioref QUE SIGUE A UN SEPARADOR, SALTEANDO SU PREFIJO.  -->
  <!-- LO USAN LAS HOJAS PARA SUPRIMIR EL SEPARADOR DE DOS CITAS QUE -->
  <!-- SE AGRUPARON: EL DELIMITADOR LO PONE biblatex.                -->
  <xsl:function name="gbct:biblioref-tras-separador" as="node()?">
    <xsl:param name="t" as="node()"/>
    <xsl:variable name="v" select="gbct:vecino-sig($t)"/>
    <xsl:variable name="c" select="if (gbct:es-afijo($v, 'cite-prefix'))
                                   then gbct:vecino-sig($v) else $v"/>
    <xsl:sequence select="$c[self::db:biblioref]"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:seccion-orden                                 -->
  <!-- PROPÓSITO: LA PARTE FIJA DEL id DE UNA PIEZA: {sección}-     -->
  <!--            {orden}, DE SU <info>. ES TAMBIÉN EL id DE SU     -->
  <!--            BIBLIOGRAFÍA EN citas.html (gbbib-{sección}-      -->
  <!--            {orden}).                                         -->
  <!-- PARÁMETROS: pieza As element() — la pieza                    -->
  <!-- RETORNA  : xs:string — p. ej. a-03; '-' SI LE FALTAN LOS     -->
  <!--            DOS (LA HOJA DE CITAS CORTA ANTES)                -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:seccion-orden" as="xs:string">
    <xsl:param name="pieza" as="element()"/>
    <xsl:sequence select="concat(
      normalize-space($pieza/db:info/db:bibliomisc[@role='seccion-libro']), '-',
      normalize-space($pieza/db:info/db:bibliomisc[@role='orden-seccion']))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:id-cita                                       -->
  <!-- PROPÓSITO: EL id DE UN GRUPO DE CITAS: {sección}-{orden}-{n} -->
  <!-- PARÁMETROS: b     As element() — el primer biblioref del     -->
  <!--                                  grupo                        -->
  <!--             pieza As element() — la pieza que lo contiene    -->
  <!-- RETORNA  : xs:string — p. ej. a-03-17                        -->
  <!-- NOTA     : n ES LA POSICIÓN DEL biblioref DENTRO DE LA PIEZA,-->
  <!--            CONTANDO LOS DE LAS NOTAS, Y NO EN EL DOCUMENTO:  -->
  <!--            ASÍ EL NÚMERO ES EL MISMO EN EL CANÓNICO DE LA     -->
  <!--            PIEZA (PDF, EPUB) Y EN EL DEL LIBRO ENSAMBLADO    -->
  <!--            (HTML). ORIGEN: f:id-cita DE                      -->
  <!--            docbook-to-latex-citas.xsl.                       -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:id-cita" as="xs:string">
    <xsl:param name="b"     as="element()"/>
    <xsl:param name="pieza" as="element()"/>
    <xsl:variable name="n" select="count($b/preceding::db:biblioref intersect $pieza//db:biblioref) + 1"/>
    <xsl:sequence select="concat(gbct:seccion-orden($pieza), '-', $n)"/>
  </xsl:function>

</xsl:stylesheet>
