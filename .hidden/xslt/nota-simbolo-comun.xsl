<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  nota-simbolo-comun.xsl
  ============================================================
  PROPÓSITO : EL DICCIONARIO DE LA NOTA CON SÍMBOLO (SC-86): DEL
              NOMBRE QUE GUARDA EL CANÓNICO EN <footnote label="…">
              AL SIGNO QUE SE VE EN EL HTML Y EL EPUB, Y AL ÍNDICE
              QUE EL PDF PASA A \gbNotaSimbolo.
  USO       : SE INCLUYE CON xsl:include, COMO conversacion-comun.xsl.
              HOY LO INCLUYEN LAS TRES HOJAS DEL LIBRO
              (docbook-to-latex, docbook-to-html, docbook-to-epub).
  POR QUÉ UN NOMBRE: EN DocBook 5.2 label ES NMTOKEN, Y «*» O «†»
              NO VALIDAN CONTRA EL RNG (GV-191).
  GEMELOS   : EL DICCIONARIO DE nota-simbolo.lua (LO QUE SE ESCRIBE
              EN EL .md → EL NOMBRE) Y \gbSimboloNota DEL CONTRATO
              (EL ÍNDICE → EL SIGNO EN EL PDF). LA SECUENCIA ES LA DE
              LA AMS SIN ‖, QUE IBM Plex Sans NO TIENE. UN CAMBIO VA
              EN LOS TRES, EN EL MISMO ORDEN.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbns="urn:gbpublisher:nota-simbolo"
  exclude-result-prefixes="xs gbns">

  <!-- LOS NOMBRES, EN EL ORDEN DEL ÍNDICE (1 A 8) -->
  <xsl:variable name="gbns:nombres" as="xs:string*"
    select="('ast', 'dag', 'ddag', 'S', 'P', 'ast2', 'dag2', 'ddag2')"/>

  <!-- LOS SIGNOS, EN EL MISMO ORDEN: * † ‡ § ¶ ** †† ‡‡ -->
  <xsl:variable name="gbns:signos" as="xs:string*"
    select="('*', '&#x2020;', '&#x2021;', '&#xA7;', '&#xB6;',
             '**', '&#x2020;&#x2020;', '&#x2021;&#x2021;')"/>

  <!-- ==========================================================
       gbns:indice: EL ÍNDICE DEL SÍMBOLO, DE 1 A 8. UN NOMBRE FUERA
       DEL DICCIONARIO CORTA LA TRANSFORMACIÓN: EL CANÓNICO LO ESCRIBE
       nota-simbolo.lua, Y UNO QUE NO CONOCE ES UN CANÓNICO ROTO.
       ========================================================== -->
  <xsl:function name="gbns:indice" as="xs:integer">
    <xsl:param name="label" as="xs:string"/>
    <xsl:variable name="i" select="index-of($gbns:nombres, $label)"/>
    <xsl:if test="empty($i)">
      <xsl:sequence select="error(xs:QName('gbns:label'),
        concat('Nota con símbolo: el label «', $label,
               '» no está en el diccionario (SC-86): ',
               string-join($gbns:nombres, ', ')))"/>
    </xsl:if>
    <xsl:sequence select="$i[1]"/>
  </xsl:function>

  <!-- ==========================================================
       gbns:signo: EL SIGNO QUE SE VE (*, †, ‡…), PARA EL HTML Y EL
       EPUB. EL PDF NO LO USA: LO COMPONE \gbSimboloNota.
       ========================================================== -->
  <xsl:function name="gbns:signo" as="xs:string">
    <xsl:param name="label" as="xs:string"/>
    <xsl:sequence select="$gbns:signos[gbns:indice($label)]"/>
  </xsl:function>

</xsl:stylesheet>
