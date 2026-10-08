<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  extraer-codigo.xsl
  ============================================================
  PROPÓSITO : PRIMER PASO DEL COLOREADO DE CÓDIGO (SC-42). ESCRIBE
              CADA BLOQUE DE CÓDIGO DEL CANÓNICO EN UN ARCHIVO DE
              TEXTO PROPIO, PARA QUE colorear_codigo.lua LO COLOREE
              CON EL RESALTADOR DE PANDOC.
  ENTRADA   : EL MISMO XML QUE DESPUÉS TRANSFORMA LA HOJA DE SALIDA:
              JATS (<code>, SIN ESPACIO DE NOMBRES) O DOCBOOK
              (<programlisting>, EN EL DE DOCBOOK).
  PARÁMETRO : dir — CARPETA DE SALIDA, COMO RUTA ABSOLUTA.
  SALIDA    : <dir>/codigo-N.txt — EL TEXTO DEL BLOQUE, TAL CUAL.
              <dir>/indice.txt   — UNA LÍNEA POR BLOQUE: N, TAB Y EL
                                   LENGUAJE (VACÍO = TEXTO SIN COLOR).
  NUMERACIÓN: N ES LA POSICIÓN DEL BLOQUE EN EL DOCUMENTO, CONTADA
              CON preceding:: COMO EN codigo-comun.xsl. LAS DOS HOJAS
              TIENEN QUE CONTAR IGUAL: SI NO, UN BLOQUE RECIBE EL
              COLOREADO DE OTRO.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:gbc="urn:gbpublisher:codigo"
  exclude-result-prefixes="xs db gbc">

  <xsl:include href="codigo-comun.xsl"/>

  <xsl:param name="dir" as="xs:string" required="yes"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <!-- LA CARPETA LLEGA COMO RUTA ABSOLUTA, CON O SIN BARRA FINAL. LA URI
       SE ARMA ACÁ: iri-to-uri ESCAPA LOS ESPACIOS Y LOS ACENTOS DE UNA
       RUTA DE PROYECTO -->
  <xsl:variable name="base" select="gbc:uri-carpeta($dir)"/>

  <xsl:template match="/">
    <!-- CADA BLOQUE EN SU ARCHIVO: EL TEXTO NO PASA POR NINGÚN ESCAPADO -->
    <xsl:for-each select="//code | //db:programlisting">
      <xsl:result-document href="{concat($base, 'codigo-', gbc:numero(.), '.txt')}" method="text" encoding="UTF-8">
        <xsl:value-of select="gbc:texto(.)"/>
      </xsl:result-document>
    </xsl:for-each>
    <!-- EL ÍNDICE VA AL FINAL Y SIEMPRE, AUNQUE NO HAYA BLOQUES: ES LA
         SEÑAL DE QUE LA EXTRACCIÓN TERMINÓ -->
    <xsl:result-document href="{concat($base, 'indice.txt')}" method="text" encoding="UTF-8">
      <xsl:for-each select="//code | //db:programlisting">
        <xsl:value-of select="gbc:numero(.)"/>
        <xsl:text>&#9;</xsl:text>
        <xsl:value-of select="gbc:lenguaje-color(.)"/>
        <xsl:text>&#10;</xsl:text>
      </xsl:for-each>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>
