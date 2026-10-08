<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  conversacion-comun.xsl
  ============================================================
  PROPÓSITO : LAS REGLAS DE LA CONVERSACIÓN (SC-43) QUE COMPARTEN
              LAS SEIS HOJAS DE SALIDA: QUÉ ETIQUETA LLEVA CADA TURNO
              Y SI EL TURNO ES UNA PREGUNTA.
  USO       : SE INCLUYE CON xsl:include, COMO codigo-comun.xsl.
              LAS FUNCIONES NOMBRAN LOS ELEMENTOS POR local-name():
              NO DEPENDEN DEL xpath-default-namespace DE LA HOJA QUE
              LAS INCLUYE, Y SIRVEN PARA DocBook Y PARA JATS.
  ETIQUETA  : SIEMPRE EN MAYÚSCULAS, EN LAS TRES SALIDAS (SC-43). EL
              CANÓNICO LA GUARDA COMO LA ESCRIBE EL TEXTO.
              - JATS: EL <speaker>, QUE conversacion.lua ESCRIBIÓ
                SIEMPRE (quien O LA ETIQUETA POR OMISIÓN).
              - DocBook: EL <label> DEL TURNO SI LO HAY (quien); SI NO,
                LA DE defaultlabel="qanda" SEGÚN EL xml:lang MÁS
                CERCANO. ESPAÑOL POR OMISIÓN: UN IDIOMA FUERA DE LA
                TABLA, O NINGUNO, DA P. Y R.
  GEMELOS   : LA TABLA DE ETIQUETAS ES LA DE conversacion.lua. UN
              CAMBIO VA EN LOS DOS.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbv="urn:gbpublisher:conversacion"
  exclude-result-prefixes="xs gbv">

  <!-- ==========================================================
       gbv:es-pregunta: SI EL TURNO ES UNA PREGUNTA. DocBook:
       <question>; JATS: <speech content-type="pregunta">.
       ========================================================== -->
  <xsl:function name="gbv:es-pregunta" as="xs:boolean">
    <xsl:param name="turno" as="element()"/>
    <xsl:sequence select="local-name($turno) = 'question'
                          or $turno/@content-type = 'pregunta'"/>
  </xsl:function>

  <!-- ==========================================================
       gbv:idioma: EL CÓDIGO PRINCIPAL DEL IDIOMA MÁS CERCANO, SIN
       REGIÓN Y EN MINÚSCULAS (es-AR → es). SIN NINGUNO, es.
       ========================================================== -->
  <xsl:function name="gbv:idioma" as="xs:string">
    <xsl:param name="nodo" as="element()"/>
    <xsl:variable name="lang"
      select="string(($nodo/ancestor-or-self::*[@xml:lang][1]/@xml:lang, 'es')[1])"/>
    <xsl:sequence select="lower-case(tokenize($lang, '-')[1])"/>
  </xsl:function>

  <!-- ==========================================================
       gbv:etiqueta: LA ETIQUETA DEL TURNO, EN MAYÚSCULAS. SIN
       ESCAPAR: CADA HOJA LA ESCAPA PARA SU SALIDA.
       ========================================================== -->
  <xsl:function name="gbv:etiqueta" as="xs:string">
    <xsl:param name="turno" as="element()"/>
    <xsl:variable name="propia"
      select="normalize-space(string(($turno/*[local-name() = ('speaker', 'label')])[1]))"/>
    <xsl:variable name="pregunta" select="gbv:es-pregunta($turno)"/>
    <xsl:sequence select="upper-case(
      if ($propia != '') then $propia
      else if (gbv:idioma($turno) = 'en') then (if ($pregunta) then 'Q.' else 'A.')
      else (if ($pregunta) then 'P.' else 'R.'))"/>
  </xsl:function>

  <!-- ==========================================================
       gbv:bloques: LOS BLOQUES DEL TURNO, SIN LA ETIQUETA
       (<speaker> O <label>), EN ORDEN.
       ========================================================== -->
  <xsl:function name="gbv:bloques" as="element()*">
    <xsl:param name="turno" as="element()"/>
    <xsl:sequence select="$turno/*[not(local-name() = ('speaker', 'label'))]"/>
  </xsl:function>

</xsl:stylesheet>
