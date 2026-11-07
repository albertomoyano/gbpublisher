<?xml version="1.0" encoding="UTF-8"?><!--
  GENERADO POR generar-schematron-jats4r.sh. NO EDITAR A MANO: SE REGENERA
  DESDE LA VERSIÓN FIJADA DE jats-schematrons (SC-11, GV-26).

  Reglas de JATS4R para los canónicos de artículo: el maestro jats4r.sch con
  todos sus temáticos, sin fase (errores y advertencias; la severidad va en
  @role, GV-27), compilado a XSLT 2.0 con el esqueleto ISO.

  fuente     https://github.com/JATS4R/jats-schematrons.git
             v0.0.17, commit 6589a03abc87eedd1156b7dc8acc39d5cda4dd3a
  maestro    schematrons/1.0/jats4r.sch
             sha256 2794d489060851f404e3cf69ed78f6f8edc2cf53d908ff1b4d8be3a6468d3cfd
  vocabularios (al lado de esta hoja: document() resuelve contra ella)
             clinical-trial-registries.xml
             sha256 8ae76e79a46e45bdeaea6c601f4c066af50c8e4d631a5a2868d5cf8ec10d578e
             countries.xml
             sha256 4e83fb5e667d6730c1a09eb6c9f5ef77b8859c4d2b34f552599fec3ca506a761
             credit-roles.xml
             sha256 6a1ea9d970aae4185f21d19686efa69f3a7e8a036335399532019f1815f8bbdc
             lang.xml
             sha256 c42fc1e859996157949f7ec3eaf52efc8988d558558675ba6a805905e8b53cf4
  esqueleto  iso_dsdl_include.xsl
             sha256 43ff20a1afd89d8a744d1c0b8df94ac5559ffa6a820d1ffbf508d6431ee4fdd9
             iso_abstract_expand.xsl
             sha256 c5267f124abf23eeb6669884e40a98607c055bfaa1f39e73b7d578feceeb6e46
             iso_svrl_for_xslt2.xsl
             sha256 0588d617924a0686255f6d182633d434c7986d561be8fcc3b363907d3f671b26
             iso_schematron_skeleton_for_saxon.xsl
             sha256 95f3195d9f437ea8ff5f75d1a27f4e68ae20b236fe0d4a217bb4209f498a10a3
  patrones   36 de 36 temáticos
  compilado  SaxonJ-HE 12.9, 2026-11-07
-->
<xsl:stylesheet xmlns:ali="http://www.niso.org/schemas/ali/1.0" xmlns:iso="http://purl.oclc.org/dsdl/schematron" xmlns:j4r="http://jats4r.org/ns" xmlns:mml="http://www.w3.org/1998/Math/MathML" xmlns:oasis="http://www.niso.org/standards/z39-96/ns/oasis-exchange/table" xmlns:saxon="http://saxon.sf.net/" xmlns:schold="http://www.ascc.net/xml/schematron" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"><!--Implementers: please note that overriding process-prolog or process-root is 
    the preferred method for meta-stylesheets to use where possible. -->
   <xsl:param name="archiveDirParameter"/>
   <xsl:param name="archiveNameParameter"/>
   <xsl:param name="fileNameParameter"/>
   <xsl:param name="fileDirParameter"/>
   <xsl:variable name="document-uri">
      <xsl:value-of select="document-uri(/)"/>
   </xsl:variable>
   <!--PHASES-->

   <!--PROLOG-->
   <xsl:output xmlns:svrl="http://purl.oclc.org/dsdl/svrl" method="xml" omit-xml-declaration="no" standalone="yes" indent="yes"/>
   <!--XSD TYPES FOR XSLT2-->

   <!--KEYS AND FUNCTIONS-->
   <xsl:function xmlns="http://purl.oclc.org/dsdl/schematron" name="j4r:jats-version-later-1d2" as="xsd:boolean">
      <xsl:param name="v"/>
      <xsl:variable name="maj" select="substring-before($v, '.')"/>
      <xsl:variable name="min" select="substring-after($v, '.')"/>
      <xsl:variable name="min-is-num" select="number($min) = number($min)"/>
      <xsl:value-of select="       $maj = '1' and       ( $min-is-num and number($min) &gt;= 1 or         not($min-is-num) and $min &gt; '1d2' )     "/>
   </xsl:function>
   <xsl:function xmlns="http://purl.oclc.org/dsdl/schematron" name="j4r:coi-type" as="xsd:boolean">
      <xsl:param name="type"/>
      <xsl:value-of select="       $type='COI_statement' or       $type='COI-statement' or       $type='coi_statement' or       $type='conflict-statement' or       $type='conflict_statement' or       $type='conflict-of-interests' or       $type='conflict_of_interests' or       $type='conflict-of-interest' or       $type='conflict_of_interest' or       $type='competing-interests' or       $type='competing_interests' or       $type='competing-interest' or       $type='competing_interess' or       $type='conflict'"/>
   </xsl:function>
   <xsl:function xmlns="http://purl.oclc.org/dsdl/schematron" name="j4r:coi-title" as="xsd:boolean">
      <xsl:param name="title"/>
      <xsl:variable name="testtitle" select="upper-case($title)"/>
      <xsl:value-of select="       $testtitle='CONFLICT OF INTEREST' or       $testtitle='CONFLICTS OF INTEREST' or       $testtitle='CONFLICT OF INTEREST STATEMENT' or       $testtitle='CONFLICT OF INTEREST STATEMENTS' or       $testtitle='AUTHOR CONFLICTS' or       $testtitle='COMPETING INTERESS' or       $testtitle='COMPETING INTERESTS' or       $testtitle='CONFLICTS'"/>
   </xsl:function>
   <xsl:function xmlns="http://purl.oclc.org/dsdl/schematron" name="j4r:data-avail-type" as="xsd:boolean">
      <xsl:param name="type"/>
      <xsl:value-of select="       $type='data availability' or       $type='Data availability' or       $type='Data Availability' or        $type='Data-Availability' or        $type='data availability statement' or        $type='Data availability statement' or        $type='Data Availability Statement' or        $type='data-availability-statement' or       $type='Data-availability-statement' or       $type='Data-Availability-Statement' or        $type='Data_Availability' or        $type='data_availability-statement' or        $type='Data_availability-statement' or       $type='Data_Availability-Statement' or        $type='data_availability' or       $type='Data Accessibility' or       $type='Data accessibility'"/>
   </xsl:function>
   <!--DEFAULT RULES-->

   <!--MODE: SCHEMATRON-SELECT-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-select-full-path">
      <xsl:apply-templates select="." mode="schematron-get-full-path"/>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-->
   <!--This mode can be used to generate an ugly though full XPath for locators-->
   <xsl:template match="*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">
            <xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>*:</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>[namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:variable name="preceding" select="count(preceding-sibling::*[local-name()=local-name(current())                                   and namespace-uri() = namespace-uri(current())])"/>
      <xsl:text>[</xsl:text>
      <xsl:value-of select="1+ $preceding"/>
      <xsl:text>]</xsl:text>
   </xsl:template>
   <xsl:template match="@*" mode="schematron-get-full-path">
      <xsl:apply-templates select="parent::*" mode="schematron-get-full-path"/>
      <xsl:text>/</xsl:text>
      <xsl:choose>
         <xsl:when test="namespace-uri()=''">@<xsl:value-of select="name()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text>@*[local-name()='</xsl:text>
            <xsl:value-of select="local-name()"/>
            <xsl:text>' and namespace-uri()='</xsl:text>
            <xsl:value-of select="namespace-uri()"/>
            <xsl:text>']</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-2-->
   <!--This mode can be used to generate prefixed XPath for humans-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-2">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="preceding-sibling::*[name(.)=name(current())]">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: SCHEMATRON-FULL-PATH-3-->
   <!--This mode can be used to generate prefixed XPath for humans 
	(Top-level element has index)-->
   <xsl:template match="node() | @*" mode="schematron-get-full-path-3">
      <xsl:for-each select="ancestor-or-self::*">
         <xsl:text>/</xsl:text>
         <xsl:value-of select="name(.)"/>
         <xsl:if test="parent::*">
            <xsl:text>[</xsl:text>
            <xsl:value-of select="count(preceding-sibling::*[name(.)=name(current())])+1"/>
            <xsl:text>]</xsl:text>
         </xsl:if>
      </xsl:for-each>
      <xsl:if test="not(self::*)">
         <xsl:text/>/@<xsl:value-of select="name(.)"/>
      </xsl:if>
   </xsl:template>
   <!--MODE: GENERATE-ID-FROM-PATH -->
   <xsl:template match="/" mode="generate-id-from-path"/>
   <xsl:template match="text()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.text-', 1+count(preceding-sibling::text()), '-')"/>
   </xsl:template>
   <xsl:template match="comment()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.comment-', 1+count(preceding-sibling::comment()), '-')"/>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.processing-instruction-', 1+count(preceding-sibling::processing-instruction()), '-')"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-from-path">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:value-of select="concat('.@', name())"/>
   </xsl:template>
   <xsl:template match="*" mode="generate-id-from-path" priority="-0.5">
      <xsl:apply-templates select="parent::*" mode="generate-id-from-path"/>
      <xsl:text>.</xsl:text>
      <xsl:value-of select="concat('.',name(),'-',1+count(preceding-sibling::*[name()=name(current())]),'-')"/>
   </xsl:template>
   <!--MODE: GENERATE-ID-2 -->
   <xsl:template match="/" mode="generate-id-2">U</xsl:template>
   <xsl:template match="*" mode="generate-id-2" priority="2">
      <xsl:text>U</xsl:text>
      <xsl:number level="multiple" count="*"/>
   </xsl:template>
   <xsl:template match="node()" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>n</xsl:text>
      <xsl:number count="node()"/>
   </xsl:template>
   <xsl:template match="@*" mode="generate-id-2">
      <xsl:text>U.</xsl:text>
      <xsl:number level="multiple" count="*"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="string-length(local-name(.))"/>
      <xsl:text>_</xsl:text>
      <xsl:value-of select="translate(name(),':','.')"/>
   </xsl:template>
   <!--Strip characters-->
   <xsl:template match="text()" priority="-1"/>
   <!--SCHEMA SETUP-->
   <xsl:template match="/">
      <svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl" title="" schemaVersion="">
         <xsl:comment>
            <xsl:value-of select="$archiveDirParameter"/>   
		 <xsl:value-of select="$archiveNameParameter"/>  
		 <xsl:value-of select="$fileNameParameter"/>  
		 <xsl:value-of select="$fileDirParameter"/>
         </xsl:comment>
         <svrl:ns-prefix-in-attribute-values uri="http://www.niso.org/schemas/ali/1.0" prefix="ali"/>
         <svrl:ns-prefix-in-attribute-values uri="http://jats4r.org/ns" prefix="j4r"/>
         <svrl:ns-prefix-in-attribute-values uri="http://www.w3.org/1998/Math/MathML" prefix="mml"/>
         <svrl:ns-prefix-in-attribute-values uri="http://www.w3.org/2001/XMLSchema" prefix="xs"/>
         <svrl:ns-prefix-in-attribute-values uri="http://www.w3.org/2001/XMLSchema-instance" prefix="xsi"/>
         <svrl:ns-prefix-in-attribute-values uri="http://www.w3.org/1999/xlink" prefix="xlink"/>
         <svrl:ns-prefix-in-attribute-values uri="http://www.niso.org/standards/z39-96/ns/oasis-exchange/table" prefix="oasis"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">abstract-errors</xsl:attribute>
            <xsl:attribute name="name">abstract-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M9"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">abstract-warnings-1</xsl:attribute>
            <xsl:attribute name="name">abstract-warnings-1</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M10"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">abstract-warnings-2</xsl:attribute>
            <xsl:attribute name="name">abstract-warnings-2</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M11"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">accessibility-errors</xsl:attribute>
            <xsl:attribute name="name">accessibility-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M12"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">accessibility-warnings</xsl:attribute>
            <xsl:attribute name="name">accessibility-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M13"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">auths-aff-errors</xsl:attribute>
            <xsl:attribute name="name">auths-aff-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M14"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">auths-aff-warnings</xsl:attribute>
            <xsl:attribute name="name">auths-aff-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M15"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">coi-errors</xsl:attribute>
            <xsl:attribute name="name">coi-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M16"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">clinical-trial-errors-1</xsl:attribute>
            <xsl:attribute name="name">clinical-trial-errors-1</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M17"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">clinical-trial-errors-2</xsl:attribute>
            <xsl:attribute name="name">clinical-trial-errors-2</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M18"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">clinical-trial-warnings</xsl:attribute>
            <xsl:attribute name="name">clinical-trial-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M19"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">credit-errors</xsl:attribute>
            <xsl:attribute name="name">credit-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M20"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">credit-warnings</xsl:attribute>
            <xsl:attribute name="name">credit-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M21"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">data-availability-errors</xsl:attribute>
            <xsl:attribute name="name">data-availability-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M22"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">data-availability-warnings</xsl:attribute>
            <xsl:attribute name="name">data-availability-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M23"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">data-citations-errors</xsl:attribute>
            <xsl:attribute name="name">data-citations-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M24"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">display-object-errors</xsl:attribute>
            <xsl:attribute name="name">display-object-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M25"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">display-object-warnings-1</xsl:attribute>
            <xsl:attribute name="name">display-object-warnings-1</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M26"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">display-object-warnings-2</xsl:attribute>
            <xsl:attribute name="name">display-object-warnings-2</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M27"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">ethics-errors</xsl:attribute>
            <xsl:attribute name="name">ethics-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M28"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">ethics-warnings</xsl:attribute>
            <xsl:attribute name="name">ethics-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M29"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">funding-errors</xsl:attribute>
            <xsl:attribute name="name">funding-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M30"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">general-citations-errors</xsl:attribute>
            <xsl:attribute name="name">general-citations-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M31"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">general-citations-warnings</xsl:attribute>
            <xsl:attribute name="name">general-citations-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M32"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">kwd-warnings</xsl:attribute>
            <xsl:attribute name="name">kwd-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M33"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">math-errors</xsl:attribute>
            <xsl:attribute name="name">math-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M34"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">math-warnings</xsl:attribute>
            <xsl:attribute name="name">math-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M35"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">peer-review-errors</xsl:attribute>
            <xsl:attribute name="name">peer-review-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M36"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">peer-review-errors-2</xsl:attribute>
            <xsl:attribute name="name">peer-review-errors-2</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M37"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">peer-review-warnings</xsl:attribute>
            <xsl:attribute name="name">peer-review-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M38"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">permissions-errors</xsl:attribute>
            <xsl:attribute name="name">permissions-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M39"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">permissions-warnings</xsl:attribute>
            <xsl:attribute name="name">permissions-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M40"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">preprint-citations-errors</xsl:attribute>
            <xsl:attribute name="name">preprint-citations-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M41"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">preprint-citations-warnings</xsl:attribute>
            <xsl:attribute name="name">preprint-citations-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M42"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">subj-warnings</xsl:attribute>
            <xsl:attribute name="name">subj-warnings</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M43"/>
         <svrl:active-pattern>
            <xsl:attribute name="document">
               <xsl:value-of select="document-uri(/)"/>
            </xsl:attribute>
            <xsl:attribute name="id">xml-lang-errors</xsl:attribute>
            <xsl:attribute name="name">xml-lang-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M44"/>
      </svrl:schematron-output>
   </xsl:template>
   <!--SCHEMATRON PATTERNS-->

   <!--PATTERN abstract-errors-->

   <!--RULE -->
   <xsl:template match="article-meta" priority="1004" mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article-meta"/>
      <!--REPORT error-->
      <xsl:if test="count(abstract[not(@abstract-type or @xml:lang or @specific-use)]) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(abstract[not(@abstract-type or @xml:lang or @specific-use)]) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            If there are multiple abstracts then each abstract, other than the main abstract, must have at least one of the following attributes: abstract-type, xml:lang, or specific-use.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="abstract|trans-abstract" priority="1003" mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="abstract|trans-abstract"/>
      <!--REPORT error-->
      <xsl:if test="not(p) and count(sec)=1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(p) and count(sec)=1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/>&gt; has no child &lt;p&gt; elements, but it has only 1 &lt;sec&gt; element.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="@abstract-type='graphical' and not(descendant::fig[descendant::graphic])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@abstract-type='graphical' and not(descendant::fig[descendant::graphic])">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/> abstract-type="graphical"&gt; has no descendant &lt;fig&gt; elements.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="(not(@abstract-type) or not(@abstract-type=('video','audio'))) and descendant::media">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(not(@abstract-type) or not(@abstract-type=('video','audio'))) and descendant::media">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/>&gt; has descendant &lt;media&gt; element(s), but it does not have an abstract-type attribute with a value of either "video" or "audio".
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="@abstract-type='video' and not(descendant::fig[descendant::media[@mimetype='video']])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@abstract-type='video' and not(descendant::fig[descendant::media[@mimetype='video']])">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/> abstract-type="video"&gt; has no descendant &lt;fig&gt; elements containing &lt;media mimetype="video"&gt;.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="@abstract-type='audio' and not(descendant::fig[descendant::media[@mimetype='audio']])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@abstract-type='audio' and not(descendant::fig[descendant::media[@mimetype='audio']])">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/> abstract-type="audio"&gt; has no descendant &lt;fig&gt; elements containing &lt;media mimetype="audio"&gt;.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="name()='trans-abstract' and not(@xml:lang)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="name()='trans-abstract' and not(@xml:lang)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Missing xml:lang attribute. &lt;trans-abstract&gt; must have an xml:lang attribute, whose value indicates the language. This one does not.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="abstract//sec" priority="1002" mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="abstract//sec"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="title"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="title">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Missing &lt;title&gt;. Every &lt;sec&gt; within &lt;abstract&gt; must have a &lt;title&gt;, this one does not.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="graphic[ancestor::abstract or ancestor::trans-abstract]" priority="1001" mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="graphic[ancestor::abstract or ancestor::trans-abstract]"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="parent::fig or parent::alternatives/parent::fig"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::fig or parent::alternatives/parent::fig">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;graphic&gt; within &lt;abstract&gt; must be a child of &lt;fig&gt; or a child of &lt;alternatives&gt;, which in turn is a child of &lt;fig&gt;. This one is not.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="media[ancestor::abstract or ancestor::trans-abstract]" priority="1000" mode="M9">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="media[ancestor::abstract or ancestor::trans-abstract]"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="parent::fig or parent::alternatives/parent::fig"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::fig or parent::alternatives/parent::fig">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;media&gt; within &lt;abstract&gt; must be a child of &lt;fig&gt; or a child of &lt;alternatives&gt;, which in turn is a child of &lt;fig&gt;. This one is not.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M9"/>
   <xsl:template match="@*|node()" priority="-2" mode="M9">
      <xsl:apply-templates select="*" mode="M9"/>
   </xsl:template>
   <!--PATTERN abstract-warnings-1-->

   <!--RULE -->
   <xsl:template match="abstract|trans-abstract" priority="1000" mode="M10">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="abstract|trans-abstract"/>
      <xsl:variable name="recommended-values" select="('teaser','extract','editor-summary','executive-summary','interpretive-summary','summary','plain-language-summary','graphical','simple','structured','video','audio')"/>
      <!--REPORT warning-->
      <xsl:if test="(not(@abstract-type) or @abstract-type!='graphical') and descendant::fig[descendant::graphic]">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(not(@abstract-type) or @abstract-type!='graphical') and descendant::fig[descendant::graphic]">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/>&gt; does not have the attribute abstract-type="graphical" but it has a descendant &lt;fig&gt; with a graphic. 
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="@abstract-type and not(normalize-space(@abstract-type)=$recommended-values)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@abstract-type and not(normalize-space(@abstract-type)=$recommended-values)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            abstract-type attribute value (<xsl:text/>
               <xsl:value-of select="@abstract-type"/>
               <xsl:text/>) on &lt;<xsl:text/>
               <xsl:value-of select="name()"/>
               <xsl:text/>&gt; is not one of the recommended values (<xsl:text/>
               <xsl:value-of select="string-join($recommended-values,'; ')"/>
               <xsl:text/>). 
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M10"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M10"/>
   <xsl:template match="@*|node()" priority="-2" mode="M10">
      <xsl:apply-templates select="*" mode="M10"/>
   </xsl:template>
   <!--PATTERN abstract-warnings-2-->

   <!--RULE -->
   <xsl:template match="abstract[@xml:lang]" priority="1000" mode="M11">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="abstract[@xml:lang]"/>
      <xsl:variable name="iso-639-3-sl" select="('ads','aed','aen','afg','ajs','ase','asp','asq','asw','bfi','bfk','bog','bqn','bqy','bvl','bzs','cds','csc','csd','cse','csf','csg','csl','csn','csq','csr','csx','doq','dse','dsl','dsz','ecs','ehs','esl','esn','eso','eth','fcs','fse','fsl','fss','gds','gse','gsg','gsm','gss','gus','hab','haf','hds','hks','hos','hps','hsh','hsl','icl','iks','inl','ins','ise','isg','isr','jcs','jhs','jks','jls','jos','jsl','jus','kgi','kvk','lbs','lls','lsb','lsc','lsl','lsn','lso','lsp','lst','lsv','lsw','lsy','lws','mdl','mfs','mre','msd','msr','mzc','mzg','mzy','nbs','ncs','nsi','nsl','nsp','nsr','nzs','okl','pgz','pks','prl','prz','psc','psd','psg','psl','pso','psp','psr','pys','rib','rms','rnb','rsl','rsm','rsn','sdl','sfs','sgg','sgx','slf','sls','sqk','sqs','sqx','ssp','ssr','svk','swl','syy','szs','tse','tsm','tsq','tss','tsy','tza','ugn','ugy','ukl','uks','vsi','vsl','vsv','wbs','xki','xml','xms','ygs','yhs','ysl','ysm','zib','zsl')"/>
      <!--REPORT warning-->
      <xsl:if test="@xml:lang=$iso-639-3-sl">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xml:lang=$iso-639-3-sl">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;abstract&gt; has an xml:lang attribute with a value for one of the ISO-639 sign languages ("<xsl:text/>
               <xsl:value-of select="@xml:lang"/>
               <xsl:text/>"). Where a video depicts sign language which is a direct translation of the main abstract, &lt;trans-abstract abstract-type="video"&gt; should be used with the correct (same) xml:lang attribute.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M11"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M11"/>
   <xsl:template match="@*|node()" priority="-2" mode="M11">
      <xsl:apply-templates select="*" mode="M11"/>
   </xsl:template>
   <!--PATTERN accessibility-errors-->

   <!--RULE -->
   <xsl:template match="graphic" priority="1010" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="graphic"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="alt-text"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="alt-text">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
            All &lt;graphic&gt; must have &lt;alt-text&gt;. This one does not.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="long-desc and (parent::*/long-desc or parent::alternatives/parent::*/long-desc)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="long-desc and (parent::*/long-desc or parent::alternatives/parent::*/long-desc)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            &lt;graphic&gt; has a child &lt;long-desc&gt;, but its ancestor <xsl:text/>
               <xsl:value-of select="if (parent::alternatives) then parent::alternatives/parent::*/name() else parent::*/name()"/>
               <xsl:text/> also has a child &lt;long-desc&gt;. &lt;long-desc&gt; should be for the entire object or for each included image, not both places.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="oasis:table" priority="1009" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="oasis:table"/>
      <!--REPORT error-->
      <xsl:if test=".">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test=".">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            OASIS (CALS) tables are not recommended for accessibility and should not be used. Tag all tables using the XHTML-based JATS model instead.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="table-wrap" priority="1008" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="table-wrap"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="table or alternatives/table"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="table or alternatives/table">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
            &lt;table&gt; element not found inside &lt;table-wrap&gt;. The &lt;table&gt; element is required inside &lt;table-wrap&gt; for data table accessibility.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="table" priority="1007" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="table"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="descendant::th"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="descendant::th">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
            &lt;th&gt; element not found within &lt;table&gt;. Headers must be included in &lt;th&gt; tags for data table accessibility.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="ext-link | uri | self-uri" priority="1006" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="ext-link | uri | self-uri"/>
      <!--REPORT error-->
      <xsl:if test="((not(*) and normalize-space(.)='') or (.=@xlink:href) or matches(.,'^https?://|^s?ftp://')) and not(@xlink:title)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="((not(*) and normalize-space(.)='') or (.=@xlink:href) or matches(.,'^https?://|^s?ftp://')) and not(@xlink:title)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Text that describes the linked object must be provided for each link either in the element content or in @xlink:title.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec" priority="1005" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="title"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="title">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
            Each sec element must have a title.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="@disp-level">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@disp-level">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Document structure should be defined by the position of the sections, not by the @disp-level attribute.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="private-char" priority="1004" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="private-char"/>
      <!--REPORT error-->
      <xsl:if test=".">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test=".">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Do not use &lt;private-char&gt; or use graphics for special characters.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="disp-formula | inline-formula" priority="1003" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="disp-formula | inline-formula"/>
      <!--REPORT error-->
      <xsl:if test="graphic or alternatives[count(*)=1 and graphic]">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="graphic or alternatives[count(*)=1 and graphic]">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Do not use &lt;graphic&gt; to represent mathematical notation
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="custom-meta-group[@content-type='accessibility-metadata']" priority="1002" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="custom-meta-group[@content-type='accessibility-metadata']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="parent::processing-meta"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::processing-meta">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
            Accessibility Metadata should be in a &lt;custom-meta-group&gt; in &lt;processing-meta&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="processing-meta/custom-meta-group[@content-type='accessibility-metadata']/custom-meta" priority="1001" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="processing-meta/custom-meta-group[@content-type='accessibility-metadata']/custom-meta"/>
      <xsl:variable name="meta-name-values" select="('accessibilityFeature','accessibilityHazard','accessibilitySummary')"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="meta-name[.=$meta-name-values]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="meta-name[.=$meta-name-values]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
           Accessibility Metadata entries must have a &lt;meta-name&gt; value of ‘accessibilityFeature’, ‘accessibilityHazard’, or ‘accessibilitySummary’.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@vocab='schema.org'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@vocab='schema.org'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
           Accessibility Metadata entries should use the schema.org vocabulary.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="alternatives/textual-form" priority="1000" mode="M12">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="alternatives/textual-form"/>
      <!--REPORT error-->
      <xsl:if test="ancestor::disp-formula or ancestor::inline-formula">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ancestor::disp-formula or ancestor::inline-formula">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Do not use &lt;textual-form&gt; for math. Use MathML tagging.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="ancestor::fig or ancestor::fig-group">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ancestor::fig or ancestor::fig-group">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Do not use &lt;textual-form&gt; for figures. Use &lt;alt-text&gt;, &lt;long-desc&gt;, or supply a transcript for audio or  video material.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M12"/>
   <xsl:template match="@*|node()" priority="-2" mode="M12">
      <xsl:apply-templates select="*" mode="M12"/>
   </xsl:template>
   <!--PATTERN accessibility-warnings-->

   <!--RULE -->
   <xsl:template match="graphic/alt-text" priority="1002" mode="M13">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="graphic/alt-text"/>
      <!--REPORT warning-->
      <xsl:if test="normalize-space(.)=normalize-space(ancestor::fig/caption/title)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="normalize-space(.)=normalize-space(ancestor::fig/caption/title)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;alt-text&gt; should not be a duplication of the figure title.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="normalize-space(.)=normalize-space(ancestor::fig/caption/p[1])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="normalize-space(.)=normalize-space(ancestor::fig/caption/p[1])">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;alt-text&gt; should not be a duplication of the figure caption.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="normalize-space(.)=''">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="normalize-space(.)=''">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Use value ‘null’ to indicate a decorative (non-substantive) image
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M13"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="ext-link | uri | self-uri" priority="1001" mode="M13">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="ext-link | uri | self-uri"/>
      <!--REPORT warning-->
      <xsl:if test=".=@xlink:href or matches(.,'^https?://|^s?ftp://')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test=".=@xlink:href or matches(.,'^https?://|^s?ftp://')">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            A URI is not descriptive link text. The text of ext-link should describe the linked object.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M13"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="list-item" priority="1000" mode="M13">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="list-item"/>
      <!--REPORT warning-->
      <xsl:if test="label">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="label">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
            Accessible @list-type overridden by list-item/label.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M13"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M13"/>
   <xsl:template match="@*|node()" priority="-2" mode="M13">
      <xsl:apply-templates select="*" mode="M13"/>
   </xsl:template>
   <!--PATTERN auths-aff-errors-->

   <!--RULE -->
   <xsl:template match="aff" priority="1005" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="aff"/>
      <!--REPORT error-->
      <xsl:if test="parent::article-meta and following-sibling::aff and count(preceding::contrib) &gt; 1 and ((@id and not(idref(@id)) or not(@id)))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::article-meta and following-sibling::aff and count(preceding::contrib) &gt; 1 and ((@id and not(idref(@id)) or not(@id)))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
    When there is more than one author and more than one affiliation, there must be a relationship between them either by position of the &lt;aff&gt; in the &lt;contrib-group&gt; or with &lt;xref ref-type="aff"  in the &lt;contrib&gt; pointing to the @id on the &lt;aff&gt;.
  </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="parent::contrib-group and following-sibling::aff and count(preceding-sibling::contrib) &gt; 1 and ((@id and not(idref(@id)) or not(@id)))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::contrib-group and following-sibling::aff and count(preceding-sibling::contrib) &gt; 1 and ((@id and not(idref(@id)) or not(@id)))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
    When there is more than one author and more than one affiliation in a &lt;contrib-group&gt;, there mut be a relationship between them  defined by an &lt;xref ref-type="aff" in the &lt;contrib&gt; pointing to the @id on the &lt;aff&gt;.
  </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="name(child::node()[1])='sup' and string-length(sup[1])=1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="name(child::node()[1])='sup' and string-length(sup[1])=1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
    Do not put label content in &lt;sup&gt; at the begnning of &lt;aff&gt;. Use  &lt;label&gt; instead.
  </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="xref[name(id(@rid))='aff']" priority="1004" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="xref[name(id(@rid))='aff']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@ref-type and @ref-type='aff'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@ref-type and @ref-type='aff'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      &lt;xref&gt; that point to &lt;aff&gt; must have @ref-type="aff"/
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="institution-id" priority="1003" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="institution-id"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@institution-id-type"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@institution-id-type">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      &lt;institution-id&gt; must have an @institution-id-type.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="contrib-id" priority="1002" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="contrib-id"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="normalize-space(@contrib-id-type)!=''"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="normalize-space(@contrib-id-type)!=''">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      &lt;contrib-id&gt; must have a @contrib-id-type with a non-empty value.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article/front/article-meta" priority="1001" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article/front/article-meta"/>
      <!--REPORT error-->
      <xsl:if test="count(descendant::contrib[@contrib-type='author' and @equal-contrib='yes'])=1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::contrib[@contrib-type='author' and @equal-contrib='yes'])=1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      There is only one author with the attribute @equal-contrib="yes", which cannot be correct.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="contrib[@contrib-type='author']" priority="1000" mode="M14">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="contrib[@contrib-type='author']"/>
      <!--REPORT error-->
      <xsl:if test="ancestor::collab">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ancestor::collab">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
       &lt;contrib contrib-id-type="author"&gt; should not be a descendant of collab.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M14"/>
   <xsl:template match="@*|node()" priority="-2" mode="M14">
      <xsl:apply-templates select="*" mode="M14"/>
   </xsl:template>
   <!--PATTERN auths-aff-warnings-->

   <!--RULE -->
   <xsl:template match="/article/front/article-meta[descendant::contrib]" priority="1005" mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="/article/front/article-meta[descendant::contrib]"/>
      <!--REPORT warning-->
      <xsl:if test="not(descendant::contrib[@contrib-type='author'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(descendant::contrib[@contrib-type='author'])">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Articles should have authors included as &lt;contrib contrib-type="author"&gt;.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="contrib[@contrib-type='author']/xref[@ref-type='aff' and (* or normalize-space(.)!='')]" priority="1004" mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="contrib[@contrib-type='author']/xref[@ref-type='aff' and (* or normalize-space(.)!='')]" role="warning"/>
      <xsl:variable name="aff" select="id(./@rid)"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="$aff/label"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$aff/label">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;xref&gt; which contains content, but the &lt;aff&gt; that it points to does not have a label.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="contrib[@initials]" priority="1003" mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="contrib[@initials]"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="matches(@initials,'^[\p{L}]\.?[\p{L}]?\.?[\p{L}]?\.?[\p{L}]?\.?[\p{L}]?\.?$')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(@initials,'^[\p{L}]\.?[\p{L}]?\.?[\p{L}]?\.?[\p{L}]?\.?[\p{L}]?\.?$')">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;xref&gt; which contains content, but the &lt;aff&gt; that it points to does not have a label.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="aff//country" priority="1002" mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="aff//country"/>
      <xsl:variable name="countries" select="document('countries.xml')"/>
      <xsl:variable name="country" select="@country"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="@country and (some $code in $countries//*:country satisfies $code/@country = $country)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@country and (some $code in $countries//*:country satisfies $code/@country = $country)">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      &lt;country&gt; should have a @country that includes the ISO 3166-1 2-letter country code.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="aff" priority="1001" mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="aff"/>
      <!--ASSERT info-->
      <xsl:choose>
         <xsl:when test="institution or institution-wrap/institution"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="institution or institution-wrap/institution">
               <xsl:attribute name="role">info</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;aff&gt; does not contain &lt;institution&gt;
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="collab" priority="1000" mode="M15">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="collab"/>
      <!--REPORT warning-->
      <xsl:if test="ancestor::article-meta and not(parent::contrib[@contrib-type='author'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ancestor::article-meta and not(parent::contrib[@contrib-type='author'])">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;collab&gt; should be a child of &lt;contrib contrib-type="author"&gt; when it is a group author
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M15"/>
   <xsl:template match="@*|node()" priority="-2" mode="M15">
      <xsl:apply-templates select="*" mode="M15"/>
   </xsl:template>
   <!--PATTERN coi-errors-->

   <!--RULE -->
   <xsl:template match="fn[@fn-type='coi-statement']" priority="1004" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fn[@fn-type='coi-statement']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="parent::author-notes"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::author-notes">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Conflict of Interest Statements shoud be tagged as &lt;fn fn-type="coi-statement" in the &lt;author-notes&gt;.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="fn" priority="1003" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fn"/>
      <!--REPORT error-->
      <xsl:if test="@content-type='coi-statement' or j4r:coi-type(@content-type) or j4r:coi-type(@fn-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@content-type='coi-statement' or j4r:coi-type(@content-type) or j4r:coi-type(@fn-type)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Conflict of Interest Statements shoud be tagged as &lt;fn fn-type="coi-statement" in the &lt;author-notes&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="notes" priority="1002" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="notes"/>
      <!--REPORT error-->
      <xsl:if test="@notes-type='coi-statement' or j4r:coi-type(@notes-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@notes-type='coi-statement' or j4r:coi-type(@notes-type)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Conflict of Interest Statements shoud be tagged as &lt;fn fn-type="coi-statement" in the &lt;author-notes&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="p" priority="1001" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="p"/>
      <!--REPORT error-->
      <xsl:if test="@content-type='coi-statement' or j4r:coi-type(@content-type) or j4r:coi-title(normalize-space(b[1]))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@content-type='coi-statement' or j4r:coi-type(@content-type) or j4r:coi-title(normalize-space(b[1]))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Conflict of Interest Statements shoud be tagged as &lt;fn fn-type="coi-statement" in the &lt;author-notes&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec" priority="1000" mode="M16">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec"/>
      <!--REPORT error-->
      <xsl:if test="@sec-type='coi-statement' or j4r:coi-type(@sec-type) or j4r:coi-title(normalize-space(title))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@sec-type='coi-statement' or j4r:coi-type(@sec-type) or j4r:coi-title(normalize-space(title))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Conflict of Interest Statements shoud be tagged as &lt;fn fn-type="coi-statement" in the &lt;author-notes&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M16"/>
   <xsl:template match="@*|node()" priority="-2" mode="M16">
      <xsl:apply-templates select="*" mode="M16"/>
   </xsl:template>
   <!--PATTERN clinical-trial-errors-1-->

   <!--RULE -->
   <xsl:template match="related-object[@content-type=('pre-results', 'results', 'post-results')]" priority="1002" mode="M17">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[@content-type=('pre-results', 'results', 'post-results')]"/>
      <xsl:variable name="registries" select="doc('clinical-trial-registries.xml')"/>
      <xsl:variable name="source-id" select="@source-id"/>
      <!--REPORT error-->
      <xsl:if test="@source-id-type='crossref-doi' and not(some $registry in $registries//*:registry satisfies ($registry/@doi = $source-id))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@source-id-type='crossref-doi' and not(some $registry in $registries//*:registry satisfies ($registry/@doi = $source-id))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a source-id attribute with a value which is either a WHO-approved registry DOI or name.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@source-id-type=('crossref-doi','registry-name')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@source-id-type=('crossref-doi','registry-name')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a source-id-type attribute with a value which is 'crossref-doi' or 'registry-name', depending what's in the source-id attribute.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a document-id attribute with a value which is the clinical trial number as provided in the clinical trial registry.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id-type=('clinical-trial-number','doi')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id-type=('clinical-trial-number','doi')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a document-id-type attribute with a value which is either 'clinical-trial-number' or 'doi'. '<xsl:text/>
                  <xsl:value-of select="@document-id-type"/>
                  <xsl:text/>' is not either of those.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="related-object[not(@content-type) and @source-id-type='crossref-doi']" priority="1001" mode="M17">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[not(@content-type) and @source-id-type='crossref-doi']"/>
      <xsl:variable name="registries" select="doc('clinical-trial-registries.xml')"/>
      <xsl:variable name="source-id" select="@source-id"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="some $registry in $registries//*:registry satisfies ($registry/@doi = $source-id)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $registry in $registries//*:registry satisfies ($registry/@doi = $source-id)">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial links in &lt;related-object source-id-type="crossref-doi"&gt; must have a source-id attribute with a value which is one of the WHO-approved registry DOIs. '<xsl:text/>
                  <xsl:value-of select="$source-id"/>
                  <xsl:text/>' is not one of the WHO-approved registry DOIs.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a document-id attribute with a value which is the clinical trial number as provided in the clinical trial registry.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id-type=('clinical-trial-number','doi')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id-type=('clinical-trial-number','doi')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a document-id-type attribute with a value which is either 'clinical-trial-number' or 'doi'. '<xsl:text/>
                  <xsl:value-of select="@document-id-type"/>
                  <xsl:text/>' is not either of those.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="count(tokenize($source-id,' ')) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(tokenize($source-id,' ')) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      source-id attribute on &lt;related-object source-id-type='crossref-doi'&gt; has more than 1 value "<xsl:text/>
               <xsl:value-of select="$source-id"/>
               <xsl:text/>". Each clinical trial number must be captured in its own &lt;related-object&gt; element.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="related-object[not(@content-type) and @source-id-type='registry-name']" priority="1000" mode="M17">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[not(@content-type) and @source-id-type='registry-name']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a document-id attribute with a value which is the clinical trial number as provided in the clinical trial registry.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id-type=('clinical-trial-number','doi')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id-type=('clinical-trial-number','doi')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Clinical trial &lt;related-object&gt; elements must have a document-id-type attribute with a value which is either 'clinical-trial-number' or 'doi'. '<xsl:text/>
                  <xsl:value-of select="@document-id-type"/>
                  <xsl:text/>' is not either of those.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M17"/>
   <xsl:template match="@*|node()" priority="-2" mode="M17">
      <xsl:apply-templates select="*" mode="M17"/>
   </xsl:template>
   <!--PATTERN clinical-trial-errors-2-->

   <!--RULE -->
   <xsl:template match="related-object[@document-id and @document-id-type='doi']" priority="1001" mode="M18">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[@document-id and @document-id-type='doi']"/>
      <xsl:variable name="document-id" select="@document-id"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="matches($document-id,'^10\.\d{4,9}/[-._;\+()#/:A-Za-z0-9&lt;&gt;\[\]]+$')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches($document-id,'^10\.\d{4,9}/[-._;\+()#/:A-Za-z0-9&lt;&gt;\[\]]+$')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      &lt;related-object&gt; has a document-id-type='doi' attribute, but the document-id attribute value is not a doi - <xsl:text/>
                  <xsl:value-of select="@document-id"/>
                  <xsl:text/>.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="count(tokenize(@document-id,' ')) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(tokenize(@document-id,' ')) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      document-id attribute on &lt;related-object&gt; has more than 1 value "<xsl:text/>
               <xsl:value-of select="$document-id"/>
               <xsl:text/>". Each object must be captured in its own &lt;related-object&gt; element.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="related-object[@document-id and (not(@document-id-type) or @document-id-type='clinical-trial-number')]" priority="1000" mode="M18">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[@document-id and (not(@document-id-type) or @document-id-type='clinical-trial-number')]"/>
      <xsl:variable name="document-id" select="@document-id"/>
      <!--REPORT error-->
      <xsl:if test="preceding::related-object[@document-id-type='clinical-trial-number' and (@document-id = $document-id)]">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="preceding::related-object[@document-id-type='clinical-trial-number' and (@document-id = $document-id)]">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      More than one &lt;related-object&gt; with the attribute document-id="<xsl:text/>
               <xsl:value-of select="$document-id"/>
               <xsl:text/>" exists in the document.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="count(tokenize(@document-id,' ')) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(tokenize(@document-id,' ')) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      document-id attribute on &lt;related-object&gt; has more than 1 value "<xsl:text/>
               <xsl:value-of select="$document-id"/>
               <xsl:text/>". Each clinical trial number must be captured in its own &lt;related-object&gt; element.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M18"/>
   <xsl:template match="@*|node()" priority="-2" mode="M18">
      <xsl:apply-templates select="*" mode="M18"/>
   </xsl:template>
   <!--PATTERN clinical-trial-warnings-->

   <!--RULE -->
   <xsl:template match="related-object[@source-id-type='registry-name']" priority="1001" mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[@source-id-type='registry-name']"/>
      <xsl:variable name="registries" select="doc('clinical-trial-registries.xml')"/>
      <xsl:variable name="source-id" select="@source-id"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="some $registry in $registries//*:registry satisfies (($registry/@title = $source-id) or ($registry/@other-title = $source-id) or ($registry/@subtitle = $source-id))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $registry in $registries//*:registry satisfies (($registry/@title = $source-id) or ($registry/@other-title = $source-id) or ($registry/@subtitle = $source-id))">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Clinical trial links in &lt;related-object source-id-type="registry-name"&gt; must have a source-id attribute with a value which is one of the WHO-approved registry names. '<xsl:text/>
                  <xsl:value-of select="$source-id"/>
                  <xsl:text/>' is not one of the WHO-approved registry names.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="@source-type='clinical-trials-registry'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@source-type='clinical-trials-registry'">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Clinical trial links in &lt;related-object&gt; should have source-type="clinical-trials-registry" attribute.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="related-object[@source-id]" priority="1000" mode="M19">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="related-object[@source-id]"/>
      <xsl:variable name="registries" select="doc('clinical-trial-registries.xml')"/>
      <xsl:variable name="source-id" select="@source-id"/>
      <!--REPORT warning-->
      <xsl:if test="not(@source-type='clinical-trials-registry') and (some $registry in $registries//*:registry satisfies (($registry/@title = $source-id) or ($registry/@doi = $source-id) or ($registry/@other-title = $source-id) or ($registry/@subtitle = $source-id)))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@source-type='clinical-trials-registry') and (some $registry in $registries//*:registry satisfies (($registry/@title = $source-id) or ($registry/@doi = $source-id) or ($registry/@other-title = $source-id) or ($registry/@subtitle = $source-id)))">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;related-object&gt; clinical trial links should have a source-type="clinical-trials-registry" attribute.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M19"/>
   <xsl:template match="@*|node()" priority="-2" mode="M19">
      <xsl:apply-templates select="*" mode="M19"/>
   </xsl:template>
   <!--PATTERN credit-errors-->

   <!--RULE -->
   <xsl:template match="article[number(replace(@dtd-version,'[^\d\.]','')) ge 1.2]//role[@vocab='credit' and parent::*/local-name()=('contrib','collab','contrib-group')]" priority="1002" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[number(replace(@dtd-version,'[^\d\.]','')) ge 1.2]//role[@vocab='credit' and parent::*/local-name()=('contrib','collab','contrib-group')]"/>
      <xsl:variable name="credit-roles" select="document('credit-roles.xml')"/>
      <xsl:variable name="vocab-term" select="@vocab-term"/>
      <xsl:variable name="vocab-term-id" select="lower-case(@vocab-term-identifier)"/>
      <xsl:variable name="credit-role" select="$credit-roles//*:item[(@term = $vocab-term) or (@uri = $vocab-term-id)]"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@vocab-identifier='https://credit.niso.org/'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@vocab-identifier='https://credit.niso.org/'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A CRediT taxonomy role must have a @vocab-identifier whose value is https://credit.niso.org/.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="not(@vocab-term-identifier) or ((count($credit-role) = 1) and ($vocab-term-id != $credit-role/@uri))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@vocab-term-identifier) or ((count($credit-role) = 1) and ($vocab-term-id != $credit-role/@uri))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            A CRediT taxonomy role must have a @vocab-term-identifier, the value of which must be the URL of the specific CRediT term. <xsl:text/>
               <xsl:value-of select="if (empty($credit-role)) then concat('It must be one of these - ',string-join($credit-roles//*:item/@uri,', '))                  else concat('In this case ',$credit-role/@uri,' (based on the @vocab-term of this role element)')"/>
               <xsl:text/>.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="not(@vocab-term) or ((count($credit-role) = 1) and ($vocab-term != $credit-role/@term))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@vocab-term) or ((count($credit-role) = 1) and ($vocab-term != $credit-role/@term))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            A CRediT taxonomy role must have a @vocab-term, the value of which must be one of the CRediT terms - <xsl:text/>
               <xsl:value-of select="if (empty($credit-role)) then string-join($credit-roles//*:item/@term,', ')                  else concat(' in this case ',$credit-role/@term,' (based on the @vocab-term-identifer of of this role element)')"/>
               <xsl:text/>.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="count($credit-role) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count($credit-role) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            A CRediT taxonomy role must have a @vocab-term, whose value is a specific CRediT taxonomy term, and a @vocab-term-identifier, whose value is the URL for that corresponding CRediT term. <xsl:text/>
               <xsl:value-of select="concat('Either the @vocab-term - ', $vocab-term, ' - is incorrect and must be ', $credit-role[@uri=$vocab-term-id]/@term, ', or the @vocab-term-identifier - ', $vocab-term-id,' - is incorrect and must be ', $credit-role[@term=$vocab-term]/@uri)"/>
               <xsl:text/>.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[number(replace(@dtd-version,'[^\d\.]','')) ge 1.2]//role[not(@vocab='credit') and (parent::*/local-name()=('contrib','collab','contrib-group')) and (@vocab-term or @vocab-term-identifier)]" priority="1001" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[number(replace(@dtd-version,'[^\d\.]','')) ge 1.2]//role[not(@vocab='credit') and (parent::*/local-name()=('contrib','collab','contrib-group')) and (@vocab-term or @vocab-term-identifier)]"/>
      <xsl:variable name="credit-roles" select="document('credit-roles.xml')"/>
      <xsl:variable name="vocab-term" select="@vocab-term"/>
      <xsl:variable name="vocab-term-id" select="lower-case(@vocab-term-identifier)"/>
      <!--REPORT error-->
      <xsl:if test="some $x in $credit-roles//*:item satisfies ($x/@uri=$vocab-term-id) or ($x/@term=$vocab-term)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $x in $credit-roles//*:item satisfies ($x/@uri=$vocab-term-id) or ($x/@term=$vocab-term)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            A CRediT taxonomy role must have a @vocab whose value is 'credit'.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) le 1.1)]//role[contains(@content-type,'credit.niso.org') and parent::*/local-name()=('contrib','collab','contrib-group')]" priority="1000" mode="M20">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) le 1.1)]//role[contains(@content-type,'credit.niso.org') and parent::*/local-name()=('contrib','collab','contrib-group')]"/>
      <xsl:variable name="credit-roles" select="document('credit-roles.xml')"/>
      <xsl:variable name="type" select="lower-case(@content-type)"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="some $item in $credit-roles//*:item satisfies $item/@uri = $type"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $item in $credit-roles//*:item satisfies $item/@uri = $type">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A CRediT taxonomy role must have a @content-type, whose value must be one of the specific CRediT term URLs. <xsl:text/>
                  <xsl:value-of select="@content-type"/>
                  <xsl:text/> is not one of <xsl:text/>
                  <xsl:value-of select="string-join($credit-roles//*:item/@uri,', ')"/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M20"/>
   <xsl:template match="@*|node()" priority="-2" mode="M20">
      <xsl:apply-templates select="*" mode="M20"/>
   </xsl:template>
   <!--PATTERN credit-warnings-->

   <!--RULE -->
   <xsl:template match="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) ge 1.2)]//role[not(@*/name()=('vocab','vocab-identifier','vocab-term','vocab-term-identifier')) and parent::*/local-name()=('contrib','collab','contrib-group')]" priority="1001" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) ge 1.2)]//role[not(@*/name()=('vocab','vocab-identifier','vocab-term','vocab-term-identifier')) and parent::*/local-name()=('contrib','collab','contrib-group')]"/>
      <xsl:variable name="credit-roles" select="document('credit-roles.xml')"/>
      <xsl:variable name="normalized-text" select="replace(replace(lower-case(.),'[—–-]','–'),'\s','')"/>
      <!--REPORT warning-->
      <xsl:if test="some $item in $credit-roles//*:item satisfies $item/@normalized-term = $normalized-text">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $item in $credit-roles//*:item satisfies $item/@normalized-term = $normalized-text">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            A CRediT taxonomy role should have the attributes vocab="credit" and vocab-identifier="https://credit.niso.org/", as well as the following attributes which correspond to a specific CRediT taxonomy term: vocab-term (whose value should possibly be '<xsl:text/>
               <xsl:value-of select="$credit-roles//*:item[@normalized-term = $normalized-text]/@term"/>
               <xsl:text/>'), and vocab-term-identifier (whose value should possibly be '<xsl:text/>
               <xsl:value-of select="$credit-roles//*:item[@normalized-term = $normalized-text]/@uri"/>
               <xsl:text/>').
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) le 1.1)]//role[not(@content-type) and parent::*/local-name()=('contrib','collab','contrib-group')]" priority="1000" mode="M21">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) le 1.1)]//role[not(@content-type) and parent::*/local-name()=('contrib','collab','contrib-group')]"/>
      <xsl:variable name="credit-roles" select="document('credit-roles.xml')"/>
      <xsl:variable name="normalized-text" select="replace(replace(lower-case(.),'[—–-]','–'),'\s','')"/>
      <!--REPORT warning-->
      <xsl:if test="some $item in $credit-roles//*:item satisfies $item/@normalized-term = $normalized-text">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $item in $credit-roles//*:item satisfies $item/@normalized-term = $normalized-text">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            A CRediT taxonomy role should have a @content-type, whose value should be one of the specific CRediT term URLs. Based on the content of this element (<xsl:text/>
               <xsl:value-of select="."/>
               <xsl:text/>), it should have a content-type="<xsl:text/>
               <xsl:value-of select="$credit-roles//*:item[@normalized-term = $normalized-text]/@uri"/>
               <xsl:text/>" attribute.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M21"/>
   <xsl:template match="@*|node()" priority="-2" mode="M21">
      <xsl:apply-templates select="*" mode="M21"/>
   </xsl:template>
   <!--PATTERN data-availability-errors-->

   <!--RULE -->
   <xsl:template match="sec[@sec-type='data-availability']" priority="1004" mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='data-availability']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="parent::back"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::back">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Data Availability Statements shoud be tagged as &lt;sec sec-type="data-availability"&gt; in the &lt;back&gt;.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec" priority="1003" mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec"/>
      <!--REPORT error-->
      <xsl:if test="j4r:data-avail-type(@sec-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="j4r:data-avail-type(@sec-type)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Data Availability Statements shoud be tagged as &lt;sec sec-type="data-availability"&gt; in the &lt;back&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="fn" priority="1002" mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fn"/>
      <!--REPORT error-->
      <xsl:if test="@content-type='data-availability' or @fn-type='data-availability' or j4r:data-avail-type(@content-type) or j4r:data-avail-type(@fn-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@content-type='data-availability' or @fn-type='data-availability' or j4r:data-avail-type(@content-type) or j4r:data-avail-type(@fn-type)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Data Availability Statements shoud be tagged as &lt;sec sec-type="data-availability"&gt; in the &lt;back&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="p" priority="1001" mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="p"/>
      <!--REPORT error-->
      <xsl:if test="@content-type='data-availability' or j4r:data-avail-type(@content-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@content-type='data-availability' or j4r:data-avail-type(@content-type)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Data Availability Statements shoud be tagged as &lt;sec sec-type="data-availability"&gt; in the &lt;back&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="notes" priority="1000" mode="M22">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="notes"/>
      <!--REPORT error-->
      <xsl:if test="@notes-type='data-availability' or j4r:data-avail-type(@notes-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@notes-type='data-availability' or j4r:data-avail-type(@notes-type)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Data Availability Statements shoud be tagged as &lt;sec sec-type="data-availability"&gt; in the &lt;back&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M22"/>
   <xsl:template match="@*|node()" priority="-2" mode="M22">
      <xsl:apply-templates select="*" mode="M22"/>
   </xsl:template>
   <!--PATTERN data-availability-warnings-->
   <xsl:template match="text()" priority="-1" mode="M23"/>
   <xsl:template match="@*|node()" priority="-2" mode="M23">
      <xsl:apply-templates select="*" mode="M23"/>
   </xsl:template>
   <!--PATTERN data-citations-errors-->

   <!--RULE -->
   <xsl:template match="mixed-citation | element-citation" priority="1003" mode="M24">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="mixed-citation | element-citation"/>
      <!--REPORT error-->
      <xsl:if test="data-title and not(@publication-type='data')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="data-title and not(@publication-type='data')">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
       When &lt;data-title&gt; element is present, the @citation-type must be set to "data". 
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="@publication-type='data' and        (not(source) and not(data-title))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@publication-type='data' and (not(source) and not(data-title))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      &lt;data-title&gt; and/or &lt;source&gt; must be present in data citations. 
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="@publication-type='data' and        (article-title and not(data-title))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@publication-type='data' and (article-title and not(data-title))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      &lt;data-title&gt; must be used in data citations, not &lt;article-title&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="@citation-type">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@citation-type">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
        Use @publication-type (and @publication-format and @publisher-type) rather than @citation-type.
      </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="year[(ancestor::mixed-citation or ancestor::element-citation) and not(parent::date)]" priority="1002" mode="M24">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="year[(ancestor::mixed-citation or ancestor::element-citation) and not(parent::date)]"/>
      <!--REPORT error-->
      <xsl:if test="matches(.,'[^\d]') and not(matches(@iso-8601-date,'^([1][4-9]|[2][0])[0-9][0-9]$'))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(.,'[^\d]') and not(matches(@iso-8601-date,'^([1][4-9]|[2][0])[0-9][0-9]$'))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      &lt;year&gt; in a citation must either contain a valid 4-digit year, or it must have an @iso-8601-date with a valid 4-digit year. "<xsl:text/>
               <xsl:value-of select="if (@iso-8601-date) then concat('&lt;year iso-8601-date=&#34;',@iso-8601-date,'&#34;&gt;',.,'&lt;/year&gt;') else (.)"/>
               <xsl:text/>" 
      was supplied 
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="version" priority="1001" mode="M24">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="version"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="normalize-space(@designator)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="normalize-space(@designator)">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      &lt;version&gt; must include a machine-readable version number in the @designator. 
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="ref" priority="1000" mode="M24">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="ref"/>
      <!--REPORT error-->
      <xsl:if test="nlm-citation">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="nlm-citation">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      &lt;nlm-citaiton&gt; has been deprecsted. Use &lt;element-citation&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="citation">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="citation">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Use &lt;mixed-citation&gt; rather than &lt;citation&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="not(@id)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(@id)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Each &lt;ref&gt; must have an @id.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M24"/>
   <xsl:template match="@*|node()" priority="-2" mode="M24">
      <xsl:apply-templates select="*" mode="M24"/>
   </xsl:template>
   <!--PATTERN display-object-errors-->

   <!--RULE -->
   <xsl:template match="fig-group" priority="1004" mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fig-group"/>
      <xsl:variable name="fig-count" select="count(fig[label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]])"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="$fig-count gt 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$fig-count gt 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must have more than 1 child &lt;fig&gt; with a label and/or caption. This one has <xsl:text/>
                  <xsl:value-of select="$fig-count"/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must have a &lt;label&gt; and/or a &lt;caption&gt; with a child &lt;title&gt; and/or &lt;p&gt; which is not empty.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="fig" priority="1003" mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fig"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="graphic or alternatives[graphic]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="graphic or alternatives[graphic]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Images in &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must be captured using &lt;graphic&gt;. This &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; does not have a &lt;graphic&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="table-wrap-group" priority="1002" mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="table-wrap-group"/>
      <xsl:variable name="table-count" select="count(table-wrap[label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]])"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="$table-count gt 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$table-count gt 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must have more than 1 child &lt;table-wrap&gt; with a label and/or caption. This one has <xsl:text/>
                  <xsl:value-of select="$table-count"/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must have a &lt;label&gt; and/or a &lt;caption&gt; with a child &lt;title&gt; and/or &lt;p&gt; which is not empty.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="disp-formula-group" priority="1001" mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="disp-formula-group"/>
      <xsl:variable name="formula-count" select="count(disp-formula)"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="$formula-count gt 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$formula-count gt 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must have more than 1 child &lt;disp-formula&gt;. This one has <xsl:text/>
                  <xsl:value-of select="$formula-count"/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="label[* or normalize-space(.)!=''] or caption[title[* or normalize-space(.)!=''] or p[* or normalize-space(.)!='']]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; must have a &lt;label&gt; and/or a &lt;caption&gt; with a child &lt;title&gt; and/or &lt;p&gt; which is not empty.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="object-id[@pub-id-type='doi' and parent::*/local-name()=('fig','fig-group','table-wrap','table-wrap-group','disp-formula','disp-formula-group','boxed-text')]" priority="1000" mode="M25">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="object-id[@pub-id-type='doi' and parent::*/local-name()=('fig','fig-group','table-wrap','table-wrap-group','disp-formula','disp-formula-group','boxed-text')]"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="matches(.,'10\.\d{4,9}/[-._;()/:A-Za-z0-9]+$')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(.,'10\.\d{4,9}/[-._;()/:A-Za-z0-9]+$')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> pub-id-type="doi"&gt; must contain a valid doi. '<xsl:text/>
                  <xsl:value-of select="."/>
                  <xsl:text/>' is not a valid doi.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M25"/>
   <xsl:template match="@*|node()" priority="-2" mode="M25">
      <xsl:apply-templates select="*" mode="M25"/>
   </xsl:template>
   <!--PATTERN display-object-warnings-1-->

   <!--RULE -->
   <xsl:template match="fig[(not(label) or label[not(*) and normalize-space(.)='']) and caption]|fig-group[not(label) and caption]" priority="1002" mode="M26">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fig[(not(label) or label[not(*) and normalize-space(.)='']) and caption]|fig-group[not(label) and caption]"/>
      <!--REPORT warning-->
      <xsl:if test="matches(lower-case(caption[1]),'^\s*fig(ure)?\.?\s*\d|^\s*scheme\.?\s*\d|^\s*supplement(al|ary)?\.?\s*\d|^\s*supplement(al|ary)?\s*fig(ure)?\.?\s*\d')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(lower-case(caption[1]),'^\s*fig(ure)?\.?\s*\d|^\s*scheme\.?\s*\d|^\s*supplement(al|ary)?\.?\s*\d|^\s*supplement(al|ary)?\s*fig(ure)?\.?\s*\d')">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; has no non-empty label, but its caption begins with what looks like a label '<xsl:text/>
               <xsl:value-of select="substring(caption[1],1,10)"/>
               <xsl:text/>'. 
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M26"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="table-wrap[(not(label) or label[not(*) and normalize-space(.)='']) and caption]|table-wrap-group[not(label) and caption]" priority="1001" mode="M26">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="table-wrap[(not(label) or label[not(*) and normalize-space(.)='']) and caption]|table-wrap-group[not(label) and caption]"/>
      <!--REPORT warning-->
      <xsl:if test="matches(lower-case(caption[1]),'^\s*table\.?\s*\d||^\s*supplement(al|ary)?\s*table\.?\s*\d')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(lower-case(caption[1]),'^\s*table\.?\s*\d||^\s*supplement(al|ary)?\s*table\.?\s*\d')">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; has no non-empty label, but its caption begins with what looks like a label '<xsl:text/>
               <xsl:value-of select="substring(caption[1],1,10)"/>
               <xsl:text/>'. 
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M26"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="boxed-text[(not(label) or label[not(*) and normalize-space(.)='']) and caption]" priority="1000" mode="M26">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="boxed-text[(not(label) or label[not(*) and normalize-space(.)='']) and caption]"/>
      <!--REPORT warning-->
      <xsl:if test="matches(lower-case(caption[1]),'^\s*box\.?\s*\d')">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(lower-case(caption[1]),'^\s*box\.?\s*\d')">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; has no non-empty label, but its caption begins with what looks like a label '<xsl:text/>
               <xsl:value-of select="substring(caption[1],1,10)"/>
               <xsl:text/>'. 
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M26"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M26"/>
   <xsl:template match="@*|node()" priority="-2" mode="M26">
      <xsl:apply-templates select="*" mode="M26"/>
   </xsl:template>
   <!--PATTERN display-object-warnings-2-->

   <!--RULE -->
   <xsl:template match="fig|fig-group[label or caption[title or p]]|table-wrap|table-wrap-group[label or caption[title or p]]|boxed-text|disp-formula-group[label or caption[title or p]]|chem-struct-wrap[label or caption[title or p]]" priority="1000" mode="M27">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fig|fig-group[label or caption[title or p]]|table-wrap|table-wrap-group[label or caption[title or p]]|boxed-text|disp-formula-group[label or caption[title or p]]|chem-struct-wrap[label or caption[title or p]]"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="@id"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@id">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; has no id attribute. 
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M27"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M27"/>
   <xsl:template match="@*|node()" priority="-2" mode="M27">
      <xsl:apply-templates select="*" mode="M27"/>
   </xsl:template>
   <!--PATTERN ethics-errors-->

   <!--RULE -->
   <xsl:template match="sec[@sec-type='ethics-statement']//sec[@sec-type]" priority="1003" mode="M28">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='ethics-statement']//sec[@sec-type]"/>
      <!--REPORT error-->
      <xsl:if test="@sec-type='ethics-statement'">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@sec-type='ethics-statement'">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> sec-type="ethics-statement"&gt; appears more than once in the document.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec[@sec-type='ethics-statement']" priority="1002" mode="M28">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='ethics-statement']"/>
      <!--REPORT error-->
      <xsl:if test="preceding::sec[@sec-type='ethics-statement']">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="preceding::sec[@sec-type='ethics-statement']">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> sec-type="ethics-statement"&gt; appears more than once in the document.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec[@sec-type!='ethics-statement']" priority="1001" mode="M28">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type!='ethics-statement']"/>
      <!--REPORT error-->
      <xsl:if test="lower-case(@sec-type) = 'ethics-statement'">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="lower-case(@sec-type) = 'ethics-statement'">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Ethics sections must have a sec-type="ethics-statement". This one has '<xsl:text/>
               <xsl:value-of select="@sec-type"/>
               <xsl:text/>'.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec[@sec-type='ethics-statement']//p[@content-type]|sec[@sec-type='ethics-statement']//named-content[@content-type]" priority="1000" mode="M28">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='ethics-statement']//p[@content-type]|sec[@sec-type='ethics-statement']//named-content[@content-type]"/>
      <!--REPORT error-->
      <xsl:if test="@content-type='ethics-statement'">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@content-type='ethics-statement'">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Ethics related information on &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; must be specified with a content-type attribute, whose value is 'ethics-' followed by publisher values, but this one is 'ethics-statement'.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M28"/>
   <xsl:template match="@*|node()" priority="-2" mode="M28">
      <xsl:apply-templates select="*" mode="M28"/>
   </xsl:template>
   <!--PATTERN ethics-warnings-->

   <!--RULE -->
   <xsl:template match="sec[@sec-type='ethics-statement']" priority="1002" mode="M29">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='ethics-statement']"/>
      <!--REPORT warning-->
      <xsl:if test="label and not(title)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="label and not(title)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> sec-type="ethics-statement"&gt; has a &lt;label&gt; but no &lt;title&gt;. A human-readable heading should be captured in &lt;title&gt; instead of &lt;label&gt;.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec[@sec-type='ethics-statement']//sec[@sec-type]" priority="1001" mode="M29">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='ethics-statement']//sec[@sec-type]"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="starts-with(@sec-type,'ethics-')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(@sec-type,'ethics-')">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            The value of @sec-type for a &lt;sec&gt; which is a child of &lt;sec sec-type='ethics-statement'&gt;, should start with 'ethics-'. '<xsl:text/>
                  <xsl:value-of select="@sec-type"/>
                  <xsl:text/>' does not.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sec[@sec-type='ethics-statement']/p[@content-type]|sec[@sec-type='ethics-statement']//named-content[@content-type]" priority="1000" mode="M29">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sec[@sec-type='ethics-statement']/p[@content-type]|sec[@sec-type='ethics-statement']//named-content[@content-type]"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="starts-with(@content-type,'ethics-')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(@content-type,'ethics-')">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Ethics related information on &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; should be specified with a content-type attribute, whose value starts with 'ethics-' followed by publisher values, but this one is '<xsl:text/>
                  <xsl:value-of select="@content-type"/>
                  <xsl:text/>'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M29"/>
   <xsl:template match="@*|node()" priority="-2" mode="M29">
      <xsl:apply-templates select="*" mode="M29"/>
   </xsl:template>
   <!--PATTERN funding-errors-->

   <!--RULE -->
   <xsl:template match="article-meta | front-stub" priority="1006" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article-meta | front-stub"/>
      <!--REPORT error-->
      <xsl:if test="count(descendant::funding-group) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(descendant::funding-group) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            There can only be 1 &lt;funding-group&gt; within &lt;<xsl:text/>
               <xsl:value-of select="local-name()"/>
               <xsl:text/>&gt;. This one has <xsl:text/>
               <xsl:value-of select="count(descendant::funding-group)"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="award-group" priority="1005" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="award-group"/>
      <!--REPORT error-->
      <xsl:if test="count(funding-source) gt 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(funding-source) gt 1">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            More than one (<xsl:text/>
               <xsl:value-of select="count(funding-source)"/>
               <xsl:text/>) &lt;funding-source&gt; found within &lt;award-group&gt;. 
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="funding-source or support-source"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="funding-source or support-source">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            No &lt;funding-source&gt; or &lt;support-source&gt; found within &lt;award-group&gt;. 
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="award-id[@award-id-type='doi']" priority="1004" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="award-id[@award-id-type='doi']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="starts-with(.,'10')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(.,'10')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            The value of &lt;award-id award-id-type='doi'&gt; starts with something other than "10", meaning that it is not a doi - <xsl:text/>
                  <xsl:value-of select="."/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="funding-source" priority="1003" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="funding-source"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="count(institution-wrap) = 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(institution-wrap) = 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;funding-source&gt; contains <xsl:text/>
                  <xsl:value-of select="count(institution-wrap)"/>
                  <xsl:text/> &lt;institution-wrap&gt; elements.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[number(replace(@dtd-version,'[^\d\.]','')) ge 1.2]//funding-group//institution-id[@vocab='open-funder-registry']" priority="1002" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[number(replace(@dtd-version,'[^\d\.]','')) ge 1.2]//funding-group//institution-id[@vocab='open-funder-registry']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@vocab-identifier='10.13039/open_funder_registry'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@vocab-identifier='10.13039/open_funder_registry'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;institution vocab="open-funder-registry"&gt; in JATS <xsl:text/>
                  <xsl:value-of select="ancestor::article/@dtd-version"/>
                  <xsl:text/> must have an @vocab-identifier="10.13039/open_funder_registry". 
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@institution-id-type='doi'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@institution-id-type='doi'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;institution vocab="open-funder-registry"&gt; in JATS <xsl:text/>
                  <xsl:value-of select="ancestor::article/@dtd-version"/>
                  <xsl:text/> must have @institution-id-type="doi". 
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="starts-with(.,'10.13039/')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(.,'10.13039/')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            The value of &lt;institution vocab="open-funder-registry"&gt; in JATS <xsl:text/>
                  <xsl:value-of select="ancestor::article/@dtd-version"/>
                  <xsl:text/> must start with '10.13039/'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) le 1.1)]//funding-group//institution-id[@institution-id-type='doi']" priority="1001" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[not(@dtd-version) or (number(replace(@dtd-version,'[^\d\.]','')) le 1.1)]//funding-group//institution-id[@institution-id-type='doi']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="starts-with(.,'10')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="starts-with(.,'10')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            The value of &lt;institution institution-id-type="doi"&gt; must start with "10", meaning that it has to be a doi. <xsl:text/>
                  <xsl:value-of select="."/>
                  <xsl:text/> does not.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="funding-group//principal-award-recipient" priority="1000" mode="M30">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="funding-group//principal-award-recipient"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="count(name) + count(string-name) + count(institution) + count(institution-wrap) = 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(name) + count(string-name) + count(institution) + count(institution-wrap) = 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Only 1 person or organisation is allowed in &lt;principal-award-recipient&gt;. This one contains more than 1 name, string-name, institution, or institution-wrap.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M30"/>
   <xsl:template match="@*|node()" priority="-2" mode="M30">
      <xsl:apply-templates select="*" mode="M30"/>
   </xsl:template>
   <!--PATTERN general-citations-errors-->

   <!--RULE -->
   <xsl:template match="element-citation|mixed-citation" priority="1002" mode="M31">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation|mixed-citation"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@publication-type"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@publication-type">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>&lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; does not have a publication-type attribute.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="elocation-id and (fpage or lpage or page-range)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="elocation-id and (fpage or lpage or page-range)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Either &lt;elocation-id&gt; or &lt;fpage&gt; (and possibly &lt;lpage&gt;) should be included in a reference. &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; has both &lt;elocation-id&gt; as well as <xsl:text/>
               <xsl:value-of select="if (fpage and lpage) then 'both &lt;fpage&gt; and &lt;lpage&gt;' else concat('&lt;',*[name()=('fpage','lpage')],'&gt;')"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="not(page-range) and lpage and (number(replace(fpage[1],'[^\d\.]','')) gt number(replace(lpage[1],'[^\d\.]','')))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(page-range) and lpage and (number(replace(fpage[1],'[^\d\.]','')) gt number(replace(lpage[1],'[^\d\.]','')))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;lpage&gt; must be larger than &lt;fpage&gt;, if present.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="element-citation/year|mixed-citation/year" priority="1001" mode="M31">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation/year|mixed-citation/year"/>
      <!--REPORT error-->
      <xsl:if test="not(matches(.,'^[1][0-9][0-9][0-9]$|[2]0[0-2][0-9]$')) and not(matches(@iso-8601-date,'^[1][0-9][0-9][0-9]$|[2]0[0-2][0-9]$'))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(matches(.,'^[1][0-9][0-9][0-9]$|[2]0[0-2][0-9]$')) and not(matches(@iso-8601-date,'^[1][0-9][0-9][0-9]$|[2]0[0-2][0-9]$'))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>&lt;year&gt; which does not contain a 4 digit year must have an iso-8601-date attribute which does contain a 4 digit year.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="element-citation/pub-id|mixed-citation/pub-id" priority="1000" mode="M31">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation/pub-id|mixed-citation/pub-id"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@pub-id-type"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@pub-id-type">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>&lt;year&gt; which does not contain a 4 digit year must have an iso-8601-date attribute which does contain a 4 digit year.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M31"/>
   <xsl:template match="@*|node()" priority="-2" mode="M31">
      <xsl:apply-templates select="*" mode="M31"/>
   </xsl:template>
   <!--PATTERN general-citations-warnings-->

   <!--RULE -->
   <xsl:template match="element-citation|mixed-citation" priority="1001" mode="M32">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation|mixed-citation"/>
      <!--REPORT warning-->
      <xsl:if test="@publication-type='other'">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@publication-type='other'">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; has the attribute publication-type="other". Avoid using this value.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="person-group[@person-group-type]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="person-group[@person-group-type]">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Where possible &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; should always have a child &lt;person-group&gt; which hold the contributors for that work, with their role being specified in the attribute person-group-type. This &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; does not have a &lt;person-group person-group-type="..."&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="name[ancestor::element-citation]|string-name[ancestor::mixed-citation]" priority="1000" mode="M32">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="name[ancestor::element-citation]|string-name[ancestor::mixed-citation]"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="parent::person-group[@person-group-type]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::person-group[@person-group-type]">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Where possible &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; should be captured in a parent &lt;person-group&gt;, with their role being specified in the attribute person-group-type on that element. This &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; is a child of &lt;<xsl:text/>
                  <xsl:value-of select="parent::*/local-name()"/>
                  <xsl:text/>&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M32"/>
   <xsl:template match="@*|node()" priority="-2" mode="M32">
      <xsl:apply-templates select="*" mode="M32"/>
   </xsl:template>
   <!--PATTERN kwd-warnings-->

   <!--RULE -->
   <xsl:template match="*[kwd-group]" priority="1002" mode="M33">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="*[kwd-group]"/>
      <xsl:variable name="vanilla-kwd-group-count" select="count(kwd-group[not(@xml:lang) and not(@kwd-group-type)])"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="$vanilla-kwd-group-count le 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$vanilla-kwd-group-count le 1">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>There should not be two or more &lt;kwd-group&gt;s without a @kwd-group-type or @xml:lang attribute. <xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> contains <xsl:text/>
                  <xsl:value-of select="$vanilla-kwd-group-count"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="kwd-group" priority="1001" mode="M33">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="kwd-group"/>
      <!--REPORT warning-->
      <xsl:if test="@xml:lang and (@xml:lang = ancestor::article/@xml:lang)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xml:lang and (@xml:lang = ancestor::article/@xml:lang)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
               <xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> has @xml:lang="<xsl:text/>
               <xsl:value-of select="@xml:lang"/>
               <xsl:text/>", which is the same as the @xml:lang value on the article. It is unnecessary.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="             (preceding-sibling::kwd-group or following-sibling::kwd-group)             and (count(kwd) gt 1)             and kwd[@content-type]             and (count(kwd) != count(kwd[@content-type]))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(preceding-sibling::kwd-group or following-sibling::kwd-group) and (count(kwd) gt 1) and kwd[@content-type] and (count(kwd) != count(kwd[@content-type]))">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
               <xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> has sibling <xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>s, <xsl:text/>
               <xsl:value-of select="count(kwd)"/>
               <xsl:text/> kwds, but only <xsl:text/>
               <xsl:value-of select="count(kwd[@content-type])"/>
               <xsl:text/> kwd(s) with the attribute content-type. under these conditions each kwd should have an attribute content-type.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="compound-kwd" priority="1000" mode="M33">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="compound-kwd"/>
      <!--REPORT warning-->
      <xsl:if test="count(compound-kwd-part) = 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(compound-kwd-part) = 1">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>There is only one  &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; in &lt;compound-kwd&gt; - <xsl:text/>
               <xsl:value-of select="."/>
               <xsl:text/>.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M33"/>
   <xsl:template match="@*|node()" priority="-2" mode="M33">
      <xsl:apply-templates select="*" mode="M33"/>
   </xsl:template>
   <!--PATTERN math-errors-->

   <!--RULE -->
   <xsl:template match="mml:math | tex-math" priority="1002" mode="M34">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="mml:math | tex-math"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="parent::disp-formula or parent::inline-formula or parent::alternatives[parent::disp-formula or parent::inline-formula]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::disp-formula or parent::inline-formula or parent::alternatives[parent::disp-formula or parent::inline-formula]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
      Math expressions must be in &lt;disp-formula&gt; or &lt;inline-formula&gt; elements. They must not appear directly
      in &lt;<xsl:text/>
                  <xsl:value-of select="name(parent::node())"/>
                  <xsl:text/>&gt;. 
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M34"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="disp-formula | inline-formula" priority="1001" mode="M34">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="disp-formula | inline-formula"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="         count(child::graphic) + count(child::tex-math) +         count(child::mml:math) &lt; 2"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(child::graphic) + count(child::tex-math) + count(child::mml:math) &lt; 2">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
      Formula element must contain only one expression. If these are alternate
      representations of the same expression, use &lt;alternatives&gt;. If they are different
      expressions, tag each in its own &lt;<xsl:text/>
                  <xsl:value-of select="name()"/>
                  <xsl:text/>&gt;. 
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M34"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="disp-formula/alternatives | inline-formula/alternatives" priority="1000" mode="M34">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="disp-formula/alternatives | inline-formula/alternatives"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="         count(child::graphic) + count(child::inline-graphic) &lt;= 1 and         count(child::tex-math) &lt;= 1 and         count(child::mml:math) &lt;= 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(child::graphic) + count(child::inline-graphic) &lt;= 1 and count(child::tex-math) &lt;= 1 and count(child::mml:math) &lt;= 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
      For alternate representations of the same expression, there can be at most one of
      each type of representation (graphic or inline-graphic, tex-math, and mml:math). 
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M34"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M34"/>
   <xsl:template match="@*|node()" priority="-2" mode="M34">
      <xsl:apply-templates select="*" mode="M34"/>
   </xsl:template>
   <!--PATTERN math-warnings-->

   <!--RULE -->
   <xsl:template match="disp-formula | inline-formula" priority="1000" mode="M35">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="disp-formula | inline-formula"/>
      <!--REPORT warning-->
      <xsl:if test="(graphic or inline-graphic) and not(mml:math or tex-math)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(graphic or inline-graphic) and not(mml:math or tex-math)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      All mathematical expressions should be provided in markup using either &lt;mml:math&gt; or
      &lt;tex-math&gt;. The only instance in which the graphic representation of a mathematical
      expression should be used outside of &lt;alternatives&gt; and without the equivalent markup is
      where that expression is so complicated that it cannot be represented in markup at all.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M35"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M35"/>
   <xsl:template match="@*|node()" priority="-2" mode="M35">
      <xsl:apply-templates select="*" mode="M35"/>
   </xsl:template>
   <!--PATTERN peer-review-errors-->

   <!--RULE -->
   <xsl:template match="article[not(@article-type=$peer-review-types)]|sub-article[not(@article-type=$peer-review-types)]" priority="1009" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[not(@article-type=$peer-review-types)]|sub-article[not(@article-type=$peer-review-types)]"/>
      <!--REPORT error-->
      <xsl:if test="matches(lower-case(@article-type),$unallowed-type-regex)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(lower-case(@article-type),$unallowed-type-regex)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            The article-type value on &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; is <xsl:text/>
               <xsl:value-of select="@article-type"/>
               <xsl:text/>. The permitted values for peer review materials are 'reviewer-report', 'editor-report', 'author-comment', 'community-comment' or 'aggregated-review-documents'.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta | sub-article[@article-type=$peer-review-types]/front-stub" priority="1008" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta | sub-article[@article-type=$peer-review-types]/front-stub"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="article-id[@pub-id-type='doi']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="article-id[@pub-id-type='doi']">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;article-id pub-id-type="doi"&gt; must be present in <xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="contrib-group/contrib"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="contrib-group/contrib">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;contrib&gt; (within &lt;contrib-group&gt;) is required.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="title-group/article-title"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="title-group/article-title">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Peer review material must have a title (&lt;article-title&gt;).
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="(name()='article-meta') and not(permissions)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(name()='article-meta') and not(permissions)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            Peer review articles must have permissions informaiton (&lt;permissions&gt;).
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="if (name()='article-meta') then (pub-date) else (ancestor::article//article-meta/pub-date or pub-date)"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="if (name()='article-meta') then (pub-date) else (ancestor::article//article-meta/pub-date or pub-date)">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Peer review material must have a publication date (&lt;pub-date&gt;).
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//contrib | sub-article[@article-type=$peer-review-types]/front-stub//contrib[not(ancestor::collab)]" priority="1007" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//contrib | sub-article[@article-type=$peer-review-types]/front-stub//contrib[not(ancestor::collab)]"/>
      <xsl:variable name="contrib-roles" select="('reviewer', 'reader', 'author', 'editor')"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="role[@specific-use=$contrib-roles]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="role[@specific-use=$contrib-roles]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;contrib&gt; for peer review material must have a child &lt;role&gt;, which has a specific-use attribute with one of the following values: 'reviewer', 'reader', 'author', or 'editor'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$types-with-related-object]//article-meta/related-object[@document-type=$peer-review-document-types]|         sub-article[@article-type=$types-with-related-object]/front-stub/related-object[@document-type=$peer-review-document-types]" priority="1006" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$types-with-related-object]//article-meta/related-object[@document-type=$peer-review-document-types]|         sub-article[@article-type=$types-with-related-object]/front-stub/related-object[@document-type=$peer-review-document-types]"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@document-id-type='doi'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@document-id-type='doi'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;related-object&gt; with the document-type '<xsl:text/>
                  <xsl:value-of select="@document-type"/>
                  <xsl:text/>' must have a document-id-type attribute with the value 'doi'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta/pub-history/event |          sub-article[@article-type=$peer-review-types]/front-stub/pub-history/event" priority="1005" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta/pub-history/event |          sub-article[@article-type=$peer-review-types]/front-stub/pub-history/event"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="count(date) = 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(date) = 1">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;event&gt; must contain one and only one &lt;date&gt;. This one has <xsl:text/>
                  <xsl:value-of select="count(date)"/>
                  <xsl:text/>.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@event-type"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@event-type">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;event&gt; must contain and event-type attribute. The suggested values for this attribute are: reviewer-report-received, author-comment-received, or editor-decision-sent.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-stage'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-stage']" priority="1004" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-stage'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-stage']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="meta-value = ('pre-publication','post-publication')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="meta-value = ('pre-publication','post-publication')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A &lt;custom-meta&gt; with a &lt;meta-name&gt; containing 'peer-review-stage', must have a &lt;meta-value&gt; containing either 'pre-publication', or 'post-publication'. This one has '<xsl:text/>
                  <xsl:value-of select="meta-value"/>
                  <xsl:text/>'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='transfer'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='transfer']" priority="1003" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='transfer'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='transfer']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="meta-value = 'yes'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="meta-value = 'yes'">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A &lt;custom-meta&gt; with a &lt;meta-name&gt; containing 'transfer', must have a &lt;meta-value&gt; containing 'yes'. This one has '<xsl:text/>
                  <xsl:value-of select="meta-value"/>
                  <xsl:text/>'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-revision-round'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-revision-round']" priority="1002" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-revision-round'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-revision-round']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="matches(meta-value,'^\d+$')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(meta-value,'^\d+$')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A &lt;custom-meta&gt; with a &lt;meta-name&gt; containing 'peer-review-revision-round', must have a &lt;meta-value&gt; containing a numerical value represented with digits. This one has '<xsl:text/>
                  <xsl:value-of select="meta-value"/>
                  <xsl:text/>'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-recommendation'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-recommendation']" priority="1001" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-recommendation'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-recommendation']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="meta-value = ('revision', 'major-revision', 'minor-revision', 'reject', 'reject-with-resubmit', 'accept', 'formal-accept', 'accept-in-principle')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="meta-value = ('revision', 'major-revision', 'minor-revision', 'reject', 'reject-with-resubmit', 'accept', 'formal-accept', 'accept-in-principle')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A &lt;custom-meta&gt; with a &lt;meta-name&gt; containing 'peer-review-recommendation', must have a &lt;meta-value&gt; containing one of the following values: 'revision', 'major-revision', 'minor-revision', 'reject', 'reject-with-resubmit', 'accept', 'formal-accept' or 'accept-in-principle'. This one has '<xsl:text/>
                  <xsl:value-of select="meta-value"/>
                  <xsl:text/>'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-identity-transparency'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-identity-transparency']" priority="1000" mode="M36">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-identity-transparency'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-identity-transparency']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="meta-value = ('all-identities-visible', 'single-anonymized', 'double-anonymized', 'triple-anonymized')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="meta-value = ('all-identities-visible', 'single-anonymized', 'double-anonymized', 'triple-anonymized')">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            A &lt;custom-meta&gt; with a &lt;meta-name&gt; containing 'peer-review-identity-transparency', must have a &lt;meta-value&gt; containing one of the following values: 'all-identities-visible', 'single-anonymized', 'double-anonymized' or 'triple-anonymized'. This one has '<xsl:text/>
                  <xsl:value-of select="meta-value"/>
                  <xsl:text/>'.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M36"/>
   <xsl:template match="@*|node()" priority="-2" mode="M36">
      <xsl:apply-templates select="*" mode="M36"/>
   </xsl:template>
   <!--PATTERN peer-review-errors-2-->

   <!--RULE -->
   <xsl:template match="article[@article-type=$types-with-related-object]//article-meta" priority="1000" mode="M37">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$types-with-related-object]//article-meta"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="related-object[@document-type=$peer-review-document-types]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="related-object[@document-type=$peer-review-document-types]">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Peer review articles with the article-type '<xsl:text/>
                  <xsl:value-of select="ancestor::article/@article-type"/>
                  <xsl:text/>' must contain a link to the article they pass judgement on, captured as a related-object element with the the appropriate document-type attribute value (one of: <xsl:text/>
                  <xsl:value-of select="string-join(for $y in $peer-review-document-types return $y,', ')"/>
                  <xsl:text/>).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M37"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M37"/>
   <xsl:template match="@*|node()" priority="-2" mode="M37">
      <xsl:apply-templates select="*" mode="M37"/>
   </xsl:template>
   <!--PATTERN peer-review-warnings-->

   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//contrib | sub-article[@article-type=$peer-review-types]/front-stub//contrib" priority="1004" mode="M38">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta//contrib | sub-article[@article-type=$peer-review-types]/front-stub//contrib"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="@contrib-type='author'"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@contrib-type='author'">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;contrib&gt; for peer review material should have the attribute contrib-type="author".
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="sub-article[@article-type=$types-with-related-object]//front-stub" priority="1003" mode="M38">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="sub-article[@article-type=$types-with-related-object]//front-stub"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="related-object[@document-type=$peer-review-document-types]"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="related-object[@document-type=$peer-review-document-types]">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            Peer review sub-articles with the article-type '<xsl:text/>
                  <xsl:value-of select="ancestor::article/@article-type"/>
                  <xsl:text/>' should contain a link to the article they pass judgement on, captured as a related-object element with the the appropriate document-type attribute value (one of: <xsl:text/>
                  <xsl:value-of select="string-join(for $y in $peer-review-document-types return $y,', ')"/>
                  <xsl:text/>).</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta/pub-history/event[@event-type] |          sub-article[@article-type=$peer-review-types]/front-stub/pub-history/event[@event-type]" priority="1002" mode="M38">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta/pub-history/event[@event-type] |          sub-article[@article-type=$peer-review-types]/front-stub/pub-history/event[@event-type]"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="@event-type = ('reviewer-report-received', 'author-comment-received', 'editor-decision-sent')"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@event-type = ('reviewer-report-received', 'author-comment-received', 'editor-decision-sent')">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            The suggested (but not required) values for the event-type attribute are: reviewer-report-received, author-comment-received, or editor-decision-sent.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta/history/date |          sub-article[@article-type=$peer-review-types]/front-stub/history/date" priority="1001" mode="M38">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$peer-review-types]//article-meta/history/date |          sub-article[@article-type=$peer-review-types]/front-stub/history/date"/>
      <xsl:variable name="isnt-jats-1.2" select="number(replace(ancestor::article/@dtd-version,'[^\d\.]','')) lt 1.2"/>
      <!--REPORT warning-->
      <xsl:if test="$isnt-jats-1.2 and not(@date-type = ('reviewer-report-received', 'author-comment-received', 'editor-decision-sent'))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$isnt-jats-1.2 and not(@date-type = ('reviewer-report-received', 'author-comment-received', 'editor-decision-sent'))">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            The suggested (but not required) values for the date-type attribute are: reviewer-report-received, author-comment-received, or editor-decision-sent.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$types-with-related-object]//article-meta/related-object[@document-type=$peer-review-document-types]|         sub-article[@article-type=$types-with-related-object]/front-stub/related-object[@document-type=$peer-review-document-types]" priority="1000" mode="M38">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article[@article-type=$types-with-related-object]//article-meta/related-object[@document-type=$peer-review-document-types]|         sub-article[@article-type=$types-with-related-object]/front-stub/related-object[@document-type=$peer-review-document-types]"/>
      <!--REPORT warning-->
      <xsl:if test="@source-id and not(@source-id-type)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@source-id and not(@source-id-type)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;related-object&gt; with a source-id attribute should have a source-id-type attribute with an appropriate value.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M38"/>
   <xsl:template match="@*|node()" priority="-2" mode="M38">
      <xsl:apply-templates select="*" mode="M38"/>
   </xsl:template>
   <!--PATTERN permissions-errors-->

   <!--RULE -->
   <xsl:template match="article-meta" priority="1005" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="article-meta"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="permissions"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="permissions">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      Missing top-level &lt;permissions&gt; element. JATS4R-compliant articles must include
      a &lt;permissions&gt; element within &lt;article-meta&gt;.. (See https://jats4r.org/permissions, Recommendation 1.)
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="permissions" priority="1004" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="permissions"/>
      <!--REPORT error-->
      <xsl:if test="(copyright-statement|copyright-holder) and not(copyright-year)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(copyright-statement|copyright-holder) and not(copyright-year)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      Missing &lt;copyright-year&gt;. When an article is under copyright (i.e. it is not in the public domain) a &lt;copyright-year&gt; must be given. (See https://jats4r.org/permissions, Recommendation 3.)
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="(copyright-statement|copyright-year) and not(copyright-holder)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(copyright-statement|copyright-year) and not(copyright-holder)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      Missing &lt;copyright-holder&gt;. When an article is under copyright
      (i.e. it is not in the public domain) a &lt;copyright-holder&gt; must be given.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="copyright-year" priority="1003" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="copyright-year"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="number() and number() &gt; 999 and number() &lt; 10000"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="number() and number() &gt; 999 and number() &lt; 10000">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text> 
      &lt;copyright-year&gt; must be a 4-digit year, not "<xsl:text/>
                  <xsl:value-of select="normalize-space()"/>
                  <xsl:text/>". 
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="normalize-space(string(.)) != string(.)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="normalize-space(string(.)) != string(.)">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      &lt;copyright-year&gt; must not contain whitespace. 
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="license" priority="1002" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="license"/>
      <!--REPORT error-->
      <xsl:if test="@xlink:href and child::node()[local-name()='license_ref'] and       string(@xlink:href) != string(child::node()[local-name()='license_ref'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xlink:href and child::node()[local-name()='license_ref'] and string(@xlink:href) != string(child::node()[local-name()='license_ref'])">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      If both @xlink:href and &lt;ali:license_ref&gt; are used to specify the licence
      URI of an article, their contents must match exactly.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT error-->
      <xsl:if test="count(child::node()[local-name()='license_ref']) &gt; 1 and child::node()[local-name()='license_ref'][not(@start_date)]">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(child::node()[local-name()='license_ref']) &gt; 1 and child::node()[local-name()='license_ref'][not(@start_date)]">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      If multiple &lt;ali:license_ref&gt; elements are tagged they must have @start_date to indicate when each license is applicable.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="child::node()[local-name()='free_to_read']" priority="1001" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="child::node()[local-name()='free_to_read']"/>
      <!--REPORT error-->
      <xsl:if test="@start_date and @end_date and @start_date gt @end_date">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@start_date and @end_date and @start_date gt @end_date">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      @end_date must be later than @start_date on &lt;ali:free_to_read&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="@start_date|@end_date" priority="1000" mode="M39">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="@start_date|@end_date"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="(matches(., '^\d{4}-\d{2}-\d{2}$') and (. castable as xs:date))"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="(matches(., '^\d{4}-\d{2}-\d{2}$') and (. castable as xs:date))">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
      @<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> must contain valid dates in ISO-8601 YYYY-MM-DD format.
    </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M39"/>
   <xsl:template match="@*|node()" priority="-2" mode="M39">
      <xsl:apply-templates select="*" mode="M39"/>
   </xsl:template>
   <!--PATTERN permissions-warnings-->

   <!--RULE -->
   <xsl:template match="license" priority="1002" mode="M40">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="license"/>
      <xsl:variable name="jurisdictions" select="'(am|at|au|az|br|ca|ch|cl|cn|cr|cz|de|ec|ee|eg|es|fr|ge|gr|gt|hk|hr|ie|igo|it|lu|nl|no|nz|ph|pl|pr|pt|ro|rs|sg|th|tw|ug|us|ve|vn|za)'"/>
      <xsl:variable name="p1" select="'https://creativecommons\.org/licenses/by(-sa|-nd|-nc|-nc-sa|-nc-nd)?/4\.0/'"/>
      <xsl:variable name="p2" select="concat('https://creativecommons\.org/licenses/by(-sa|-nd|-nc|-nc-sa|-nc-nd)?/(1|2|3)\.\d(/', $jurisdictions, ')?/')"/>
      <xsl:variable name="p3" select="'https://creativecommons\.org/publicdomain/(zero|mark)/1\.0/'"/>
      <xsl:variable name="li_check" select="if (child::node()[local-name()='license_ref']) then child::node()[local-name()='license_ref'] else @xlink:href"/>
      <!--REPORT warning-->
      <xsl:if test="contains($li_check, 'creativecommons.org') and not(matches($li_check, $p1) or matches($li_check, $p2) or matches($li_check, $p3))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="contains($li_check, 'creativecommons.org') and not(matches($li_check, $p1) or matches($li_check, $p2) or matches($li_check, $p3))">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      Creative Commons licenses should follow the recommended patterns. <xsl:text/>
               <xsl:value-of select="$li_check"/>
               <xsl:text/> is not a best practices pattern for a Creative Commons URL. Check that it uses https and a trailing slash.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="@xlink:href and normalize-space(@xlink:href) = ''">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xlink:href and normalize-space(@xlink:href) = ''">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      Whenever the @xlink:href attribute appears on the &lt;license&gt; element, its
      value must be the canonical URI of a valid license (such as a Creative Commons
      license). In this article, the attribute is empty.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="child::node()[local-name()='license_ref'] and normalize-space(string(child::node()[local-name()='license_ref'])) = ''">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="child::node()[local-name()='license_ref'] and normalize-space(string(child::node()[local-name()='license_ref'])) = ''">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      Whenever the ali:license_ref element appears, its
      content must be the canonical URI of a valid license (such as a Creative Commons
      license). In this article, the element is empty.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="j4r:jats-version-later-1d2(/article/@dtd-version) and  not(child::node()[local-name()='license_ref'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="j4r:jats-version-later-1d2(/article/@dtd-version) and not(child::node()[local-name()='license_ref'])">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      No licence URI.
      For JATS 1.1d3 and later, if the licence is defined by a canonical URI, then the
      &lt;license&gt; element should have an &lt;ali:license_ref&gt; child, that specifies
      that URI.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="j4r:jats-version-later-1d2(/article/@dtd-version) and        @xlink:href and not(child::node()[local-name()='license_ref'])">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="j4r:jats-version-later-1d2(/article/@dtd-version) and @xlink:href and not(child::node()[local-name()='license_ref'])">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      The license URI is given in @xlink:href.
      For JATS 1.1d3 and later, if the licence is defined by a canonical URI, then it
      should be specified in the &lt;ali:license_ref&gt; child element.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="not(j4r:jats-version-later-1d2(/article/@dtd-version)) and      not(@xlink:href)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="not(j4r:jats-version-later-1d2(/article/@dtd-version)) and not(@xlink:href)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text> 
      No licence URI.
      For JATS 1.1d2 and earlier, if the licence is defined by a canonical URI, then the
      &lt;license&gt; element should have an @xlink:href attribute, that specifies
      that URI.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="license-p" priority="1001" mode="M40">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="license-p"/>
      <xsl:variable name="li_check" select="if (parent::license/child::node()[local-name()='license_ref']) then parent::license/child::node()[local-name()='license_ref'] else parent::license/@xlink:href"/>
      <!--REPORT warning-->
      <xsl:if test="ext-link and ext-link/@xlink:href != $li_check">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ext-link and ext-link/@xlink:href != $li_check">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>URI in license-p (<xsl:text/>
               <xsl:value-of select="ext-link/@xlink:href"/>
               <xsl:text/>) does not match canonical license URI (<xsl:text/>
               <xsl:value-of select="$li_check"/>
               <xsl:text/>).</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="copyright-statement" priority="1000" mode="M40">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="copyright-statement"/>
      <!--REPORT warning-->
      <xsl:if test="parent::permissions/copyright-year and not(contains(., parent::permissions/copyright-year))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::permissions/copyright-year and not(contains(., parent::permissions/copyright-year))">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      The contents of &lt;copyright-statement&gt; should not conflict with &lt;copyright-year&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--REPORT warning-->
      <xsl:if test="parent::permissions/copyright-holder and not(contains(lower-case(.), lower-case(parent::permissions/copyright-holder)))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="parent::permissions/copyright-holder and not(contains(lower-case(.), lower-case(parent::permissions/copyright-holder)))">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
      The contents of &lt;copyright-statement&gt; should not conflict with &lt;copyright-holder&gt;.
    </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M40"/>
   <xsl:template match="@*|node()" priority="-2" mode="M40">
      <xsl:apply-templates select="*" mode="M40"/>
   </xsl:template>
   <!--PATTERN preprint-citations-errors-->

   <!--RULE -->
   <xsl:template match="element-citation[@publication-type='preprint']|mixed-citation[@publication-type='preprint']" priority="1003" mode="M41">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation[@publication-type='preprint']|mixed-citation[@publication-type='preprint']"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="person-group"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="person-group">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> publication-type="preprint"&gt; must include a &lt;person-group&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="article-title"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="article-title">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> publication-type="preprint"&gt; must include an &lt;article-title&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="year or date[@date-type='published']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="year or date[@date-type='published']">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> publication-type="preprint"&gt; must include either a &lt;year&gt; or a &lt;date&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--REPORT error-->
      <xsl:if test="year and date[@date-type='published']">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="year and date[@date-type='published']">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> publication-type="preprint"&gt; must not include both a &lt;year&gt; and a &lt;date&gt;.
        </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="source"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="source">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> publication-type="preprint"&gt; must include a &lt;source&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="ext-link or pub-id"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="ext-link or pub-id">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> publication-type="preprint"&gt; must include either an &lt;ext-link&gt; or a &lt;pub-id&gt;.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="element-citation[@publication-type='preprint']/person-group|mixed-citation[@publication-type='preprint']/person-group" priority="1002" mode="M41">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation[@publication-type='preprint']/person-group|mixed-citation[@publication-type='preprint']/person-group"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="@person-group-type"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@person-group-type">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;person-group&gt; in &lt;<xsl:text/>
                  <xsl:value-of select="parent::*/local-name()"/>
                  <xsl:text/> publication-type="preprint"&gt; must have the attribute person-group-type.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="element-citation[@publication-type='preprint']/year|mixed-citation[@publication-type='preprint']/year" priority="1001" mode="M41">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation[@publication-type='preprint']/year|mixed-citation[@publication-type='preprint']/year"/>
      <!--REPORT error-->
      <xsl:if test="matches(.,'[^\d]') and not(matches(@iso-8601-date,'^\d{4}$'))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(.,'[^\d]') and not(matches(@iso-8601-date,'^\d{4}$'))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;year&gt; which is a direct child of &lt;<xsl:text/>
               <xsl:value-of select="parent::*/local-name()"/>
               <xsl:text/> publication-type="preprint"&gt; must either be integer or have an @iso-8601-date with an iso-8601 date. <xsl:text/>
               <xsl:value-of select="if (@iso-8601-date and matches(.,'[^\d]')) then (concat('The @iso-8601-date, ',@iso-8601-date,' is not in the format 0000.')) else if (not(@iso-8601-date) and matches(.,'[^\d]')) then ('There is no @iso-8601-date and the &lt;year&gt; element is not an integer.') else ()"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="element-citation[@publication-type='preprint']/date|mixed-citation[@publication-type='preprint']/date" priority="1000" mode="M41">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation[@publication-type='preprint']/date|mixed-citation[@publication-type='preprint']/date"/>
      <!--REPORT error-->
      <xsl:if test="matches(year[1],'[^\d]') and not(matches(@iso-8601-date,'^\d{4}$|^\d{4}-\d{2}$|^\d{4}-\d{2}-\d{2}$'))">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="matches(year[1],'[^\d]') and not(matches(@iso-8601-date,'^\d{4}$|^\d{4}-\d{2}$|^\d{4}-\d{2}-\d{2}$'))">
            <xsl:attribute name="role">error</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
            &lt;date&gt; in &lt;<xsl:text/>
               <xsl:value-of select="parent::*/local-name()"/>
               <xsl:text/> publication-type="preprint"&gt; must either  have an @iso-8601-date with an iso-8601 date, or contain a &lt;year&gt; whose contents are an integer. <xsl:text/>
               <xsl:value-of select="if (@iso-8601-date and matches(year[1],'[^\d]')) then (concat('The @iso-8601-date, ',@iso-8601-date,' is not in one of the formats 0000, 0000-00, or 0000-00-00.')) else if (not(@iso-8601-date) and matches(.,'[^\d]')) then concat('There is no @iso-8601-date and the &lt;year&gt; element is not an integer. &lt;year&gt;',child::year[1],'&lt;/year&gt;') else ()"/>
               <xsl:text/>
            </svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M41"/>
   <xsl:template match="@*|node()" priority="-2" mode="M41">
      <xsl:apply-templates select="*" mode="M41"/>
   </xsl:template>
   <!--PATTERN preprint-citations-warnings-->

   <!--RULE -->
   <xsl:template match="element-citation[@publication-type='preprint']|mixed-citation[@publication-type='preprint']" priority="1000" mode="M42">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="element-citation[@publication-type='preprint']|mixed-citation[@publication-type='preprint']"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="date-in-citation[@content-type='access-date']"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="date-in-citation[@content-type='access-date']">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> publication-type="preprint"&gt; doesn't contain an accessed date (&lt;date-in-citation content-type="access-date"&gt;).
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M42"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M42"/>
   <xsl:template match="@*|node()" priority="-2" mode="M42">
      <xsl:apply-templates select="*" mode="M42"/>
   </xsl:template>
   <!--PATTERN subj-warnings-->

   <!--RULE -->
   <xsl:template match="*[subj-group]" priority="1002" mode="M43">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="*[subj-group]"/>
      <xsl:variable name="vanilla-subj-group-count" select="count(subj-group[not(@xml:lang) and not(@subj-group-type)])"/>
      <!--ASSERT warning-->
      <xsl:choose>
         <xsl:when test="$vanilla-subj-group-count le 1"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="$vanilla-subj-group-count le 1">
               <xsl:attribute name="role">warning</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>There should not be two or more &lt;subj-group&gt;s without a @subj-group-type or @xml:lang attribute. <xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/> contains <xsl:text/>
                  <xsl:value-of select="$vanilla-subj-group-count"/>
                  <xsl:text/>.</svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="subj-group" priority="1001" mode="M43">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="subj-group"/>
      <!--REPORT warning-->
      <xsl:if test="@xml:lang and (@xml:lang = ancestor::article/@xml:lang)">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="@xml:lang and (@xml:lang = ancestor::article/@xml:lang)">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>
               <xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/> has @xml:lang="<xsl:text/>
               <xsl:value-of select="@xml:lang"/>
               <xsl:text/>", which is the same as the @xml:lang value on the article. It is unnecessary.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="compound-subject" priority="1000" mode="M43">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="compound-subject"/>
      <!--REPORT warning-->
      <xsl:if test="count(compound-subject-part) = 1">
         <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="count(compound-subject-part) = 1">
            <xsl:attribute name="role">warning</xsl:attribute>
            <xsl:attribute name="location">
               <xsl:apply-templates select="." mode="schematron-select-full-path"/>
            </xsl:attribute>
            <svrl:text>There is only one  &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>-part&gt; in &lt;<xsl:text/>
               <xsl:value-of select="name(.)"/>
               <xsl:text/>&gt; - <xsl:text/>
               <xsl:value-of select="."/>
               <xsl:text/>.</svrl:text>
         </svrl:successful-report>
      </xsl:if>
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M43"/>
   <xsl:template match="@*|node()" priority="-2" mode="M43">
      <xsl:apply-templates select="*" mode="M43"/>
   </xsl:template>
   <!--PATTERN xml-lang-errors-->

   <!--RULE -->
   <xsl:template match="fig[@xml:lang]|fig-group[@xml:lang]|table-wrap[@xml:lang]|table-wrap-group[@xml:lang]|disp-formula[@xml:lang]|disp-formula-group[@xml:lang]|boxed-text[@xml:lang]" priority="1000" mode="M44">
      <svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="fig[@xml:lang]|fig-group[@xml:lang]|table-wrap[@xml:lang]|table-wrap-group[@xml:lang]|disp-formula[@xml:lang]|disp-formula-group[@xml:lang]|boxed-text[@xml:lang]"/>
      <xsl:variable name="object-lang" select="@xml:lang"/>
      <xsl:variable name="langs" select="doc('lang.xml')"/>
      <!--ASSERT error-->
      <xsl:choose>
         <xsl:when test="some $lang in $langs//*:lang satisfies $lang/@subtag = $object-lang"/>
         <xsl:otherwise>
            <svrl:failed-assert xmlns:svrl="http://purl.oclc.org/dsdl/svrl" test="some $lang in $langs//*:lang satisfies $lang/@subtag = $object-lang">
               <xsl:attribute name="role">error</xsl:attribute>
               <xsl:attribute name="location">
                  <xsl:apply-templates select="." mode="schematron-select-full-path"/>
               </xsl:attribute>
               <svrl:text>
            &lt;<xsl:text/>
                  <xsl:value-of select="name(.)"/>
                  <xsl:text/>&gt; has an xml:lang attribute, whose value (<xsl:text/>
                  <xsl:value-of select="$object-lang"/>
                  <xsl:text/>) is not one of the IETF RFC 5646 values.
        </svrl:text>
            </svrl:failed-assert>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:apply-templates select="*" mode="M44"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M44"/>
   <xsl:template match="@*|node()" priority="-2" mode="M44">
      <xsl:apply-templates select="*" mode="M44"/>
   </xsl:template>
   <xsl:param name="types-with-related-object" select="('reviewer-report', 'editor-report', 'author-comment')"/>
   <xsl:param name="peer-review-types" select="($types-with-related-object, 'community-comment', 'aggregated-review-documents')"/>
   <xsl:param name="peer-review-document-types" select="('peer-reviewed-article', 'reviewer-report', 'editor-report', 'author-comment', 'community-comment', 'aggregated-review-documents', 'peer-review-report')"/>
   <xsl:param name="unallowed-type-regex" select="string-join(for $value in $peer-review-types return concat('^',replace($value,'-','[\\s_–—\\-]?'),'$'),'|')"/>
</xsl:stylesheet>