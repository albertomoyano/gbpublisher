<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  MÓDULO    : marca-editor.xsl
  PROPÓSITO : LA MARCA QUE ACOMPAÑA A LOS EDITORES CUANDO OCUPAN EL LUGAR DEL
              AUTOR EN UNA REFERENCIA: (Ed.), (Eds.), (comp.), (coords.)...

              LA INCLUYEN docbook-to-html.xsl Y docbook-to-epub.xsl. ES LA ÚNICA
              COPIA DE ESTA REGLA EN LAS SALIDAS DIGITALES: SI CADA HOJA TUVIERA
              LA SUYA, EL MISMO LIBRO SALDRÍA CON MARCAS DISTINTAS EN HTML Y EN
              EPUB.

  DE DÓNDE SALE EL rol
              m_XML.MapearTipoEditorDocBook TRADUCE editortype DE biblatex A UN
              <editor role="…">, IGUAL QUE biblatex, PARA EL QUE UN COMPILADOR
              ES UN EDITOR CON UN TIPO. ANTES ESOS TIPOS SE EMITÍAN COMO
              <othercredit>, LAS HOJAS NO LOS TOMABAN COMO SUSTITUTO DEL AUTOR,
              Y LA REFERENCIA SALÍA SIN NOMBRE.

  CORRESPONDENCIA CON EL PDF
              LAS ABREVIATURAS SON LAS DE cita-apa-config.tex
              (\DefineBibliographyStrings{spanish}), TODAS EN MINÚSCULA. SI SE
              CAMBIAN ALLÁ, CAMBIARLAS ACÁ.

  MAYÚSCULA   LA DECIDE EL CONTEXTO, COMO EN biblatex: UNA CADENA QUE VA
              DESPUÉS DE UN PUNTO EMPIEZA ORACIÓN Y SE CAPITALIZA. CON UN NOMBRE
              QUE TERMINA EN INICIAL —«Clemenceau, L.»— SALE «(Comp.)»; CON UN
              EDITOR INSTITUCIONAL SIN NOMBRE DE PILA, O EN vancouver, QUE NO
              PONE PUNTOS EN LAS INICIALES, SALE EN MINÚSCULA. LO DECIDE QUIEN
              LLAMA, MIRANDO LO QUE ACABA DE ESCRIBIR (PARÁMETRO tras_punto): ASÍ
              LA REGLA NO DEPENDE DE ENUMERAR ESTILOS.

  LIMITACIÓN  UNA REFERENCIA CON EDITORES DE ROLES DISTINTOS TOMA LA MARCA DEL
              PRIMERO. biblatex TIENE UN SOLO editortype POR CAMPO, ASÍ QUE LOS
              EDITORES DEL CAMPO editor COMPARTEN SIEMPRE EL ROL.
  ============================================================================
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:db="http://docbook.org/ns/docbook"
  exclude-result-prefixes="xs db">

  <!-- ==========================================================
       LA ABREVIATURA SOLA, EN MINÚSCULA Y SIN PARÉNTESIS NI PUNTO:
       «ed», «eds», «comp», «comps»... LA USA marca-editor-db, Y LA HOJA
       HTML LA PASA AL «CÓMO CITAR» (citaData.abrevEditores) PARA QUE
       gbpublisher.js NO TENGA SU PROPIA TABLA.
       ========================================================== -->
  <xsl:template name="abreviatura-editor-db">
    <xsl:param name="editores"/>

    <!-- EL ROL DEL PRIMER EDITOR; SIN ROL ES UN EDITOR A SECAS -->
    <xsl:variable name="rol" select="lower-case(normalize-space(string(($editores/@role)[1])))"/>

    <xsl:variable name="base" as="xs:string">
      <xsl:choose>
        <xsl:when test="$rol = 'compiler'">comp</xsl:when>
        <xsl:when test="$rol = 'coordinator'">coord</xsl:when>
        <xsl:when test="$rol = 'director'">dir</xsl:when>
        <xsl:when test="$rol = 'collaborator'">col</xsl:when>
        <xsl:when test="$rol = 'organizer'">org</xsl:when>
        <!-- editor, SIN ROL O CON UN ROL NO PREVISTO -->
        <xsl:otherwise>ed</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- TODAS LAS ABREVIATURAS FORMAN EL PLURAL CON «s» -->
    <xsl:value-of select="concat($base, if (count($editores) gt 1) then 's' else '')"/>
  </xsl:template>

  <!-- ==========================================================
       LA MARCA COMPLETA: « (Comps.)», « (ed.)»...
       ========================================================== -->
  <xsl:template name="marca-editor-db">
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:param name="editores"/>
    <!-- TRUE SI LOS NOMBRES QUE PRECEDEN A LA MARCA TERMINAN EN PUNTO -->
    <xsl:param name="tras_punto" as="xs:boolean" select="false()"/>

    <xsl:variable name="abreviatura" as="xs:string">
      <xsl:call-template name="abreviatura-editor-db">
        <xsl:with-param name="editores" select="$editores"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:value-of select="concat(' (',
                          if ($tras_punto)
                          then concat(upper-case(substring($abreviatura, 1, 1)), substring($abreviatura, 2))
                          else $abreviatura,
                          '.)')"/>
  </xsl:template>

</xsl:stylesheet>
