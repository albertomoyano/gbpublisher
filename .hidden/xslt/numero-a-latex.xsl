<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : numero-a-latex.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : LO QUE LaTeX NECESITA DEL NÚMERO, DERIVADO DEL
                   VOLCADO (tmp/numero-datos.xml, VERSIÓN 2):
                     - latex/preambulo-numero.tex (SALIDA PRINCIPAL):
                       LAS BANDERAS, LOS IDIOMAS DE babel CON EL NOMBRE
                       DE CADA CÓDIGO, EL ESTILO DE CITA Y EL .bib;
                     - latex/main-{archivo}.tex DE CADA ARTÍCULO
                       (xsl:result-document): \DocumentMetadata CON SU
                       IDIOMA, LAS CAPAS, LAS PRESTACIONES DE SU ESTADO Y
                       SU CUERPO.
                   DECISIONES DE ALBERTO, 11/11/2026 (A1.1b-3).
  POR QUÉ DEL VOLCADO: ES EL MISMO PATRÓN QUE
                   m_GenerarPDFLibro.GenerarPreambuloProyecto EN LIBROS,
                   PERO SIN DUPLICAR EN GAMBAS LO QUE YA ESTÁ EN EL
                   VOLCADO. LOS NOMBRES DE babel LOS RESOLVIÓ GAMBAS CON EL
                   CATÁLOGO (m_Idiomas.Babel): ESTA HOJA NO TIENE TABLA
                   PROPIA DE IDIOMAS (LA DE f:babel-lang DIVERGÍA: de →
                   german, Y LO DESCONOCIDO CAÍA EN spanish SIN AVISO).
  ENTRADA        : {proyecto}/tmp/numero-datos.xml
  SALIDA         : -o:{proyecto}/latex/preambulo-numero.tex; LOS main
                   VAN AL LADO
  PARÁMETRO      : bib  EL NOMBRE DEL .bib DEL PROYECTO
                        (m_Bibtex.NombreArchivoBib, ÚNICO LUGAR DONDE SE
                        CALCULA): GAMBAS → SCRIPT → ESTA HOJA, COMO EN
                        LIBROS. REQUERIDO
  ARCHIVOS DERIVADOS: SE REESCRIBEN EN CADA GENERACIÓN Y NO LLEVAN MARCA
                   DE TIEMPO: DOS GENERACIONES CON LOS MISMOS DATOS DAN
                   LOS MISMOS ARCHIVOS (EL CRITERIO DE preambulo-proyecto)
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:gbn="urn:gbpublisher:numero-latex"
  exclude-result-prefixes="xs gbn">

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="bib" as="xs:string" required="yes"/>

  <!-- LA VERSIÓN DEL VOLCADO QUE ESTA HOJA SABE LEER. LA 2 TRAJO
       <idioma codigo babel>; LA 3 (12/11/2026) SUMA <preliminares> Y
       <pagina-legal>, QUE ESTA HOJA TODAVÍA NO USA (LLEGAN CON B5) -->
  <xsl:variable name="gbn:version-datos" select="'3'"/>

  <!-- LA VERSIÓN DEL CONTRATO DE REVISTA QUE PIDEN LOS main -->
  <xsl:variable name="gbn:contrato" select="'3'"/>

  <!-- ============================================
       Función   : gbn:babel
       Propósito : El nombre de babel de un código, del volcado
       Parámetros: raiz As document-node() — el volcado
                   codigo As xs:string — código BCP 47
       Retorna   : xs:string — el nombre; vacío si el volcado no lo trae
       ============================================ -->
  <xsl:function name="gbn:babel" as="xs:string">
    <xsl:param name="raiz" as="document-node()"/>
    <xsl:param name="codigo" as="xs:string"/>
    <xsl:sequence select="string(($raiz/numero-datos/idioma[@codigo = $codigo])[1]/@babel)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbn:prestaciones
       Propósito : Las banderas de un artículo según su estado. borrador:
                   la caja a la vista y las marcas de impnattypo; en
                   producción y publicado, limpio. El código va siempre en
                   color: el PDF de revista es PDF/A de pantalla (el PDF/X
                   de imprenta quedó para después)
       Parámetros: estado As xs:string — articulo/@estado
       Retorna   : xs:string — las asignaciones, una por línea
       ============================================ -->
  <xsl:function name="gbn:prestaciones" as="xs:string">
    <xsl:param name="estado" as="xs:string"/>
    <xsl:variable name="marcas" select="if ($estado eq 'borrador') then 'true' else 'false'"/>
    <xsl:sequence select="concat('\gbshowframe', $marcas, '&#10;\gbhomeoarchy', $marcas, '&#10;')"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: /                                                 -->
  <!-- VALIDA EL VOLCADO, ESCRIBE EL PREÁMBULO Y LOS main           -->
  <!-- ============================================================ -->
  <xsl:template match="/">
    <xsl:variable name="raiz" select="."/>
    <xsl:variable name="rev" select="numero-datos/revista"/>
    <xsl:variable name="codigos-revista" select="tokenize(string($rev/idiomas), ',') ! normalize-space(.)[. ne '']"/>
    <xsl:variable name="principal" select="if (exists($codigos-revista)) then gbn:babel($raiz, $codigos-revista[1]) else ''"/>
    <xsl:variable name="estilo" select="normalize-space($rev/estilo-cita)"/>

    <!-- 1. VALIDACIÓN: LO QUE FALTA FRENA ACÁ, CON UN MENSAJE, Y NO EN LaTeX -->
    <xsl:if test="string(numero-datos/@version) ne $gbn:version-datos">
      <xsl:message terminate="yes">ERROR: el volcado es versión «<xsl:value-of select="numero-datos/@version"/>» y esta hoja lee la <xsl:value-of select="$gbn:version-datos"/>: actualizá gbpublisher</xsl:message>
    </xsl:if>
    <xsl:if test="$bib eq ''">
      <xsl:message terminate="yes">ERROR: falta el nombre del .bib del proyecto (parámetro bib)</xsl:message>
    </xsl:if>
    <xsl:if test="$estilo eq ''">
      <xsl:message terminate="yes">ERROR: la revista no tiene estilo de cita. Elegilo en la ficha de la revista.</xsl:message>
    </xsl:if>
    <xsl:if test="empty($codigos-revista)">
      <xsl:message terminate="yes">ERROR: la revista no tiene idiomas de publicación. Cargalos en la ficha de la revista.</xsl:message>
    </xsl:if>
    <xsl:if test="$principal eq ''">
      <xsl:message terminate="yes">ERROR: el idioma principal de la revista («<xsl:value-of select="$codigos-revista[1]"/>») no tiene nombre de babel en el volcado</xsl:message>
    </xsl:if>
    <xsl:for-each select="numero-datos/articulo[gbn:babel($raiz, string(@idioma)) eq '']">
      <xsl:message terminate="yes">ERROR: el artículo <xsl:value-of select="@archivo"/> no tiene idioma, o su idioma («<xsl:value-of select="@idioma"/>») no tiene nombre de babel en el volcado</xsl:message>
    </xsl:for-each>

    <!-- 2. EL PREÁMBULO DEL NÚMERO -->
    <xsl:call-template name="gbn:preambulo">
      <xsl:with-param name="principal" select="$principal"/>
      <xsl:with-param name="estilo" select="$estilo"/>
    </xsl:call-template>

    <!-- 3. UN main POR ARTÍCULO DEL NÚMERO -->
    <xsl:for-each select="numero-datos/articulo[normalize-space(@archivo) ne '']">
      <xsl:call-template name="gbn:main"/>
    </xsl:for-each>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbn:preambulo                                -->
  <!-- SOLO DEFINE VALORES: NO CARGA NINGÚN PAQUETE. VA PRIMERO     -->
  <!-- PORQUE babel NECESITA \gbidiomas EN EL \usepackage DEL       -->
  <!-- CONTRATO COMÚN                                               -->
  <!-- ============================================================ -->
  <xsl:template name="gbn:preambulo">
    <xsl:param name="principal" as="xs:string"/>
    <xsl:param name="estilo" as="xs:string"/>
    <xsl:variable name="otros" select="sort(distinct-values(numero-datos/idioma/@babel[. ne $principal]))"/>

    <xsl:text>% ============================================================
% preambulo-numero.tex
% ------------------------------------------------------------
% ARCHIVO DERIVADO — LO ESCRIBE numero-a-latex.xsl DESDE EL VOLCADO
% DEL NÚMERO (tmp/numero-datos.xml). NO EDITAR A MANO: SE REESCRIBE
% EN CADA GENERACIÓN. LOS CAMBIOS SE HACEN EN LA BASE.
% SIN MARCA DE TIEMPO: LOS MISMOS DATOS DAN EL MISMO ARCHIVO.
% ------------------------------------------------------------
% SOLO DEFINE VALORES. LAS BANDERAS SE DECLARAN ACÁ Y CADA
% main-{archivo}.tex LES DA EL VALOR DEL ESTADO DE SU ARTÍCULO.
% ============================================================

% --- PRESTACIONES (LAS FIJA CADA main) ---
\newif\ifgbshowframe
\newif\ifgbhomeoarchy
% EL CÓDIGO EN COLOR SIEMPRE: EL PDF DE REVISTA ES PDF/A DE PANTALLA
\newif\ifgbcodigocolor \gbcodigocolortrue

% --- IDIOMAS ---
% LOS DE TODO EL VOLCADO (REVISTA, ARTÍCULOS, TRADUCCIONES, RESÚMENES,
% PALABRAS CLAVE, SECCIONES). EL PRINCIPAL ES EL PRIMERO DE LA
% REVISTA; CADA ARTÍCULO ELIGE EL SUYO CON \gbselectlanguage
</xsl:text>
    <xsl:text>\def\gbidiomas{</xsl:text>
    <xsl:value-of select="string-join(($otros, concat('main=', $principal)), ',')"/>
    <xsl:text>}&#10;\def\gbidiomaprincipal{</xsl:text>
    <xsl:value-of select="$principal"/>
    <xsl:text>}&#10;</xsl:text>
    <!-- EL NOMBRE DE CADA CÓDIGO, PARA \gbselectlanguage Y gbresumen (CONTRATO
         DE REVISTA 3, 4.0): LAS HOJAS EMITEN CÓDIGOS, NO NOMBRES -->
    <xsl:for-each select="numero-datos/idioma">
      <xsl:sort select="@codigo"/>
      <xsl:text>\expandafter\def\csname gbbabel@</xsl:text>
      <xsl:value-of select="@codigo"/>
      <xsl:text>\endcsname{</xsl:text>
      <xsl:value-of select="@babel"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>

    <xsl:text>&#10;% --- BIBLIOGRAFÍA ---&#10;\def\estandar{</xsl:text>
    <xsl:value-of select="$estilo"/>
    <xsl:text>}&#10;\def\gbarchivobib{./referencias/</xsl:text>
    <xsl:value-of select="$bib"/>
    <xsl:text>}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbn:main                                     -->
  <!-- EL main DE UN ARTÍCULO: SU IDIOMA EN \DocumentMetadata (EL   -->
  <!-- /Lang Y EL XMP DEL PDF/A), LAS CAPAS EN SU ORDEN, LAS        -->
  <!-- PRESTACIONES DE SU ESTADO ENTRE EL PREÁMBULO DEL NÚMERO      -->
  <!-- (QUE DECLARA LAS BANDERAS) Y LA ESTÉTICA (QUE LAS LEE), Y EL -->
  <!-- CUERPO c-{archivo}.tex QUE ESCRIBE jats-a-latex-articulo.xsl -->
  <!-- Contexto  : articulo                                         -->
  <!-- ============================================================ -->
  <xsl:template name="gbn:main">
    <xsl:variable name="archivo" select="normalize-space(@archivo)"/>
    <xsl:result-document href="{concat('main-', $archivo, '.tex')}" method="text" encoding="UTF-8">
      <xsl:text>% main-</xsl:text>
      <xsl:value-of select="$archivo"/>
      <xsl:text>.tex — ARCHIVO DERIVADO (numero-a-latex.xsl): NO EDITAR A MANO&#10;</xsl:text>
      <xsl:text>\DocumentMetadata{pdfstandard=A-2u, lang=</xsl:text>
      <xsl:value-of select="@idioma"/>
      <xsl:text>}&#10;\documentclass{article}&#10;\input{preambulo-numero}&#10;</xsl:text>
      <xsl:text>% PRESTACIONES DEL ESTADO «</xsl:text>
      <xsl:value-of select="@estado"/>
      <xsl:text>»&#10;</xsl:text>
      <xsl:value-of select="gbn:prestaciones(string(@estado))"/>
      <xsl:text>\input{preambulo-revista-contrato}&#10;\input{preambulo-revista-estetica}&#10;</xsl:text>
      <xsl:text>\gbRequiereContratoRevista{</xsl:text>
      <xsl:value-of select="$gbn:contrato"/>
      <xsl:text>}&#10;\begin{document}&#10;\input{c-</xsl:text>
      <xsl:value-of select="$archivo"/>
      <xsl:text>}&#10;\printbibliography&#10;\end{document}&#10;</xsl:text>
    </xsl:result-document>
  </xsl:template>

</xsl:stylesheet>
