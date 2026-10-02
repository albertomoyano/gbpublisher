<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  MÓDULO    : numeracion-libro.xsl
  PROPÓSITO : NÚMERO DE CADA FIGURA DEL LIBRO, EL MISMO QUE LE DA EL PDF
              (SC-31). LO INCLUYEN docbook-to-html.xsl Y docbook-to-epub.xsl;
              NINGUNA DE LAS DOS DEBE TENER UNA COPIA PROPIA DE ESTA REGLA.

              REGLA (LA DEL CONTRATO 9 DE preambulo-contrato.tex):
                capítulo numerado     número del capítulo y de la figura: 2.3
                apéndice              letra y número: A.1
                pieza sin número      número dentro de la pieza: 1, 2, 3
                                      (preliminares, Introducción,
                                      Conclusiones, posliminares)

              QUÉ PIEZA SE NUMERA ES LA MISMA DECISIÓN QUE TOMA
              docbook-to-latex.xsl ($numerado): SI LA PIEZA TRAE
              bibliomisc[@role='tipo-capitulo'] —EL CANÓNICO ENSAMBLADO DEL
              LIBRO—, SE NUMERAN capitulo Y apendice; SI NO LO TRAE —EL
              CANÓNICO DE UNA PIEZA—, SE NUMERAN <chapter> Y <appendix> SIN
              role. SI SE CAMBIA UNA, SE CAMBIA LA OTRA.

              EL NÚMERO DE CAPÍTULO ES EL QUE DA LaTeX: \chapter SOLO CUENTA
              LAS PIEZAS NUMERADAS, Y \appendix REINICIA LA CUENTA CON LETRAS.

  ENTRADA   : $piezas, LAS PIEZAS DEL LIBRO EN ORDEN. EL HTML LAS TOMA DEL
              CANÓNICO DEL LIBRO; EL EPUB, QUE TRANSFORMA PIEZA POR PIEZA,
              CARGA LOS CANÓNICOS DE LA LISTA QUE LE PASA EL SCRIPT.

  LOS ELEMENTOS SE NOMBRAN CON *: PORQUE LAS DOS HOJAS ACEPTAN EL CANÓNICO
  CON EL ESPACIO DE NOMBRES DE DocBook Y SIN ÉL.

  SE INCLUYE CON xsl:include, COMO quote.xsl.
  ============================================================================
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:nl="urn:gbpublisher:numeracion-libro"
                exclude-result-prefixes="xs nl">

  <!-- LOS ELEMENTOS QUE PUEDEN SER UNA PIEZA DEL LIBRO
       (LOS QUE EMITE ensamblar-capitulo-canonico.xsl) -->
  <xsl:variable name="nl:elementos-pieza" as="xs:string*"
                select="('chapter', 'preface', 'appendix', 'dedication',
                         'acknowledgements', 'colophon', 'glossary',
                         'bibliography', 'toc', 'index')"/>

  <!-- ==========================================================
       nl:es-pieza: UN ELEMENTO DE PIEZA QUE ES RAÍZ DEL DOCUMENTO
       (CANÓNICO DE PIEZA) O HIJO DE book O DE part (CANÓNICO DEL
       LIBRO). UN <bibliography> DENTRO DE UN CAPÍTULO NO ES PIEZA.
       ========================================================== -->
  <xsl:function name="nl:es-pieza" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="local-name($e) = $nl:elementos-pieza
                          and (not($e/parent::*)
                               or local-name($e/parent::*) = ('book', 'part'))"/>
  </xsl:function>

  <!-- LA PIEZA QUE CONTIENE UN NODO -->
  <xsl:function name="nl:pieza-de" as="element()?">
    <xsl:param name="n" as="node()"/>
    <xsl:sequence select="($n/ancestor-or-self::*[nl:es-pieza(.)])[1]"/>
  </xsl:function>

  <xsl:function name="nl:tipo" as="xs:string">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="normalize-space(
      ($p/*:info/*:bibliomisc[@role = 'tipo-capitulo'])[1])"/>
  </xsl:function>

  <!-- ==========================================================
       nl:es-apendice / nl:es-numerada: LA REGLA DE $numerado DE
       docbook-to-latex.xsl, PARTIDA EN DOS
       ========================================================== -->
  <xsl:function name="nl:es-apendice" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="if (nl:tipo($p) != '')
                          then nl:tipo($p) = 'apendice'
                          else local-name($p) = 'appendix'
                               and normalize-space($p/@role) = ''"/>
  </xsl:function>

  <xsl:function name="nl:es-numerada" as="xs:boolean">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="if (nl:tipo($p) != '')
                          then nl:tipo($p) = ('capitulo', 'apendice')
                          else local-name($p) = ('chapter', 'appendix')
                               and normalize-space($p/@role) = ''"/>
  </xsl:function>

  <!-- ==========================================================
       nl:etiqueta-pieza: «2» PARA EL SEGUNDO CAPÍTULO NUMERADO, «A»
       PARA EL PRIMER APÉNDICE, VACÍO PARA UNA PIEZA SIN NÚMERO.
       LA POSICIÓN SE BUSCA EN $piezas POR IDENTIDAD DE NODO (is) Y NO
       CON <<: EN EL EPUB CADA PIEZA ES OTRO DOCUMENTO, Y EL ORDEN ENTRE
       DOCUMENTOS DISTINTOS NO ES EL DEL LIBRO. EL ORDEN ES EL DE LA
       SECUENCIA.
       ========================================================== -->
  <xsl:function name="nl:etiqueta-pieza" as="xs:string">
    <xsl:param name="p" as="element()"/>
    <xsl:param name="piezas" as="element()*"/>
    <xsl:variable name="i" as="xs:integer?"
                  select="(for $k in 1 to count($piezas)
                           return if ($piezas[$k] is $p) then $k else ())[1]"/>
    <xsl:variable name="anteriores"
                  select="if (exists($i)) then subsequence($piezas, 1, $i - 1) else ()"/>
    <xsl:choose>
      <xsl:when test="not(nl:es-numerada($p))">
        <xsl:sequence select="''"/>
      </xsl:when>
      <!-- UNA PIEZA NUMERADA QUE NO ESTÁ EN LA LISTA NO TIENE NÚMERO
           CIERTO: «??», COMO UNA REFERENCIA SIN RESOLVER, Y NO UN 1 FALSO -->
      <xsl:when test="empty($i)">
        <xsl:sequence select="'??'"/>
      </xsl:when>
      <xsl:when test="nl:es-apendice($p)">
        <!-- \Alph DE LaTeX: A..Z -->
        <xsl:sequence select="codepoints-to-string(64 +
          count($anteriores[nl:es-apendice(.)]) + 1)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="string(count($anteriores[nl:es-numerada(.)
                                                       and not(nl:es-apendice(.))]) + 1)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ==========================================================
       nl:numero-figura: EL NÚMERO VISIBLE DE UN <figure>.
       $p ES LA PIEZA DE LA FIGURA TAL COMO APARECE EN $piezas: EN EL
       EPUB, LA FIGURA DE OTRA PIEZA ESTÁ EN OTRO DOCUMENTO.
       ========================================================== -->
  <xsl:function name="nl:numero-figura" as="xs:string">
    <xsl:param name="fig" as="element()"/>
    <xsl:param name="piezas" as="element()*"/>
    <xsl:variable name="p" select="nl:pieza-de($fig)"/>
    <xsl:variable name="n" select="count($p//*:figure[. &lt;&lt; $fig]) + 1"/>
    <xsl:variable name="etiqueta" select="nl:etiqueta-pieza($p, $piezas)"/>
    <xsl:sequence select="if ($etiqueta = '') then string($n)
                          else concat($etiqueta, '.', $n)"/>
  </xsl:function>

  <!-- ==========================================================
       nl:destino: EL ELEMENTO AL QUE APUNTA UN xref, BUSCADO EN TODAS
       LAS PIEZAS. VACÍO SI NO EXISTE: LA HOJA ESCRIBE «??», COMO LaTeX.
       ========================================================== -->
  <xsl:function name="nl:destino" as="element()?">
    <xsl:param name="linkend" as="xs:string"/>
    <xsl:param name="piezas" as="element()*"/>
    <xsl:sequence select="($piezas/descendant-or-self::*[@xml:id = $linkend])[1]"/>
  </xsl:function>

  <!-- CUÁNTOS ELEMENTOS TIENEN ESE id EN EL LIBRO: MÁS DE UNO ES UN
       id REPETIDO ENTRE CAPÍTULOS, Y LA REFERENCIA VA AL PRIMERO -->
  <xsl:function name="nl:cantidad-destinos" as="xs:integer">
    <xsl:param name="linkend" as="xs:string"/>
    <xsl:param name="piezas" as="element()*"/>
    <xsl:sequence select="count($piezas/descendant-or-self::*[@xml:id = $linkend])"/>
  </xsl:function>

  <!-- ==========================================================
       nl:texto-referencia: LO QUE MUESTRA LA REFERENCIA. SOLO EL
       NÚMERO, COMO \ref: LA PALABRA LA ESCRIBE EL EDITOR.
       ========================================================== -->
  <xsl:function name="nl:texto-referencia" as="xs:string">
    <xsl:param name="destino" as="element()?"/>
    <xsl:param name="piezas" as="element()*"/>
    <xsl:sequence select="if (empty($destino)) then '??'
                          else if (local-name($destino) = 'figure')
                          then nl:numero-figura($destino, $piezas)
                          else '??'"/>
  </xsl:function>

</xsl:stylesheet>
