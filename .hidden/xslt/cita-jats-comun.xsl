<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  cita-jats-comun.xsl
  ============================================================
  PROPÓSITO : LAS REGLAS DE LAS CITAS DE REVISTA QUE COMPARTEN EL
              PDF (jats-a-latex-articulo.xsl), LA PASADA DE CITAS
              (jats-a-latex-citas.xsl) Y EL EPUB: QUÉ COMANDO DE
              biblatex LE TOCA A CADA MODO, QUÉ xref FORMAN UN GRUPO
              Y QUÉ id TIENE CADA GRUPO. ES LA REGLA DE cita-comun.xsl
              (LIBROS, SC-57) LEÍDA SOBRE LA FORMA JATS DE LA CITA: LOS
              AFIJOS SON named-content HIJOS DEL xref, NO HERMANOS.
  POR QUÉ   : EL TEXTO DE UNA CITA DEL EPUB SALE DE citas.html, DONDE
              CADA GRUPO ES <span id="gbcita-{id}">. PARA ENCONTRARLO,
              LA HOJA DEL EPUB TIENE QUE AGRUPAR EXACTAMENTE COMO EL
              PDF: LA REGLA ES UNA SOLA Y VIVE ACÁ. HASTA E1 (14/11)
              ESTABA EN jats-a-latex-articulo.xsl (C1).
  USO       : SE INCLUYE CON xsl:include. NO HAY PLANTILLAS: QUÉ SE
              HACE CON UN GRUPO LO DECIDE CADA HOJA. LOS ELEMENTOS DE
              JATS NO TIENEN ESPACIO DE NOMBRES.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbcj="urn:gbpublisher:citas-jats"
  exclude-result-prefixes="xs gbcj">

  <!-- ============================================
       Función   : gbcj:modo-cita
       Propósito : El modo de una cita: lo que va antes de «|» en
                   @specific-use; sin atributo, 'normal'
       Parámetros: x As element()? — el xref, o vacío
       Retorna   : xs:string — normal | author-in-text | suppress,
                   o vacío si no hay xref
       ============================================ -->
  <xsl:function name="gbcj:modo-cita" as="xs:string">
    <xsl:param name="x" as="element()?"/>
    <xsl:variable name="su" select="normalize-space($x/@specific-use)"/>
    <xsl:sequence select="if (empty($x)) then ''
                          else if ($su = '') then 'normal'
                          else if (contains($su, '|')) then substring-before($su, '|')
                          else $su"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:comando-cita
       Propósito : El comando de biblatex de un modo, el mismo que
                   emite jats-to-latex.xsl
       Parámetros: modo As xs:string — normal | author-in-text | suppress
       Retorna   : xs:string — el comando, con la barra
       ============================================ -->
  <xsl:function name="gbcj:comando-cita" as="xs:string">
    <xsl:param name="modo" as="xs:string"/>
    <xsl:sequence select="if ($modo = 'author-in-text') then '\textcite'
                          else if ($modo = 'suppress') then '\autocite*'
                          else '\autocite'"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:comando-multicita
       Propósito : La forma múltiple de un comando (biblatex agrega
                   «s»). Los comandos con asterisco no la tienen
       Parámetros: comando As xs:string — el de gbcj:comando-cita
       Retorna   : xs:string — el múltiple, o vacío
       ============================================ -->
  <xsl:function name="gbcj:comando-multicita" as="xs:string">
    <xsl:param name="comando" as="xs:string"/>
    <xsl:sequence select="if (ends-with($comando, '*')) then '' else concat($comando, 's')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:sin-afijos
       Propósito : ¿La cita no tiene prefijo ni sufijo?
       Parámetros: x As element() — el xref
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbcj:sin-afijos" as="xs:boolean">
    <xsl:param name="x" as="element()"/>
    <xsl:sequence select="empty($x/named-content[@content-type = ('cite-prefix', 'cite-suffix')])"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:es-separador
       Propósito : ¿El nodo es el texto que separa dos citas
                   agrupables (coma, punto y coma o guion suelto)?
       Parámetros: n As node()? — el nodo
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbcj:es-separador" as="xs:boolean">
    <xsl:param name="n" as="node()?"/>
    <xsl:sequence select="exists($n[self::text()])
                          and matches(string($n), '^\s*[,;\p{Pd}]\s*$')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:agrupables
       Propósito : ¿Dos citas consecutivas van en el mismo comando?
       Parámetros: a As element() — la primera
                   b As element() — la segunda
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbcj:agrupables" as="xs:boolean">
    <xsl:param name="a" as="element()"/>
    <xsl:param name="b" as="element()"/>
    <xsl:variable name="modo" select="gbcj:modo-cita($a)"/>
    <xsl:sequence select="$modo = gbcj:modo-cita($b)
      and (gbcj:comando-multicita(gbcj:comando-cita($modo)) != ''
           or (gbcj:sin-afijos($a) and gbcj:sin-afijos($b)))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:siguiente-en-grupo
       Propósito : La cita que sigue a esta en el mismo grupo:
                   xref, separador, xref; o vacío
       Parámetros: x As element() — el xref
       Retorna   : element()? — el xref siguiente del grupo
       ============================================ -->
  <xsl:function name="gbcj:siguiente-en-grupo" as="element()?">
    <xsl:param name="x" as="element()"/>
    <xsl:variable name="sep" select="$x/following-sibling::node()[1]"/>
    <xsl:variable name="c" select="if (gbcj:es-separador($sep))
                                   then $sep/following-sibling::node()[1] else ()"/>
    <xsl:sequence select="$c[self::xref[@ref-type = 'bibr']][gbcj:agrupables($x, .)]"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:anterior-en-grupo
       Propósito : La cita que precede a esta en el mismo grupo, o vacío
       Parámetros: x As element() — el xref
       Retorna   : element()? — el xref anterior del grupo
       ============================================ -->
  <xsl:function name="gbcj:anterior-en-grupo" as="element()?">
    <xsl:param name="x" as="element()"/>
    <xsl:variable name="sep" select="$x/preceding-sibling::node()[1]"/>
    <xsl:variable name="a" select="if (gbcj:es-separador($sep))
                                   then $sep/preceding-sibling::node()[1] else ()"/>
    <xsl:sequence select="$a[self::xref[@ref-type = 'bibr']][gbcj:agrupables(., $x)]"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:grupo-desde
       Propósito : Las citas del grupo que empieza en x, en orden
       Parámetros: x As element() — el primer xref del grupo
       Retorna   : element()* — los xref del grupo
       ============================================ -->
  <xsl:function name="gbcj:grupo-desde" as="element()*">
    <xsl:param name="x" as="element()"/>
    <xsl:variable name="c" select="gbcj:siguiente-en-grupo($x)"/>
    <xsl:sequence select="$x, if (exists($c)) then gbcj:grupo-desde($c) else ()"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:inicia-grupo
       Propósito : ¿Este xref abre un grupo? (no fue absorbido por el
                   grupo del anterior)
       Parámetros: x As element() — el xref de cita
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbcj:inicia-grupo" as="xs:boolean">
    <xsl:param name="x" as="element()"/>
    <xsl:sequence select="empty(gbcj:anterior-en-grupo($x))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbcj:id-cita
       Propósito : El id del grupo que empieza en este xref:
                   {archivo}-{n}, con n la posición del xref entre
                   todas las citas del artículo, en orden de
                   documento y contando las de las notas. Es el mismo
                   en la pasada de citas y en el EPUB porque las dos
                   leen el mismo canónico. El archivo hace único el id
                   en un EPUB con varios artículos
       Parámetros: x As element() — el xref que abre el grupo
                   archivo As xs:string — el archivo del artículo (a-01-…)
       Retorna   : xs:string — sin el prefijo gbcita-
       ============================================ -->
  <xsl:function name="gbcj:id-cita" as="xs:string">
    <xsl:param name="x" as="element()"/>
    <xsl:param name="archivo" as="xs:string"/>
    <xsl:sequence select="concat($archivo, '-', count($x/preceding::xref[@ref-type = 'bibr']) + 1)"/>
  </xsl:function>

</xsl:stylesheet>
