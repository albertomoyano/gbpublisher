<?xml version="1.0" encoding="UTF-8"?><!--
  GENERADO POR generar-schematron-jats4r.sh. NO EDITAR A MANO: SE REGENERA
  DESDE LA VERSIÓN FIJADA DE jats-schematrons (SC-11, GV-26, SC-97).

  Un temático de JATS4R para el auditor de XML ajenos, compilado solo con
  un envoltorio derivado del maestro (jats4r.sch sin fases, con este único
  <include>) y el esqueleto ISO. Verificado contra el maestro.

  fuente     https://github.com/JATS4R/jats-schematrons.git
             v0.0.17, commit 6589a03abc87eedd1156b7dc8acc39d5cda4dd3a
  temático   schematrons/1.0/abstract-errors.sch
             sha256 0758a1d4df1e5209e67ef02692f1e1f83042233f47732d45bcbe657c67669121
  maestro    sha256 2794d489060851f404e3cf69ed78f6f8edc2cf53d908ff1b4d8be3a6468d3cfd
  esqueleto  el mismo de jats4r.xsl (ver su cabecera)
  compilado  SaxonJ-HE 12.9, 2026-11-18
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
         <xsl:apply-templates select="/" mode="M7"/>
      </svrl:schematron-output>
   </xsl:template>
   <!--SCHEMATRON PATTERNS-->

   <!--PATTERN abstract-errors-->

   <!--RULE -->
   <xsl:template match="article-meta" priority="1004" mode="M7">
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
      <xsl:apply-templates select="*|comment()|processing-instruction()" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="abstract|trans-abstract" priority="1003" mode="M7">
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
      <xsl:apply-templates select="*|comment()|processing-instruction()" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="abstract//sec" priority="1002" mode="M7">
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
      <xsl:apply-templates select="*|comment()|processing-instruction()" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="graphic[ancestor::abstract or ancestor::trans-abstract]" priority="1001" mode="M7">
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
      <xsl:apply-templates select="*|comment()|processing-instruction()" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="media[ancestor::abstract or ancestor::trans-abstract]" priority="1000" mode="M7">
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
      <xsl:apply-templates select="*|comment()|processing-instruction()" mode="M7"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M7"/>
   <xsl:template match="@*|node()" priority="-2" mode="M7">
      <xsl:apply-templates select="*|comment()|processing-instruction()" mode="M7"/>
   </xsl:template>
   <xsl:param name="types-with-related-object" select="('reviewer-report', 'editor-report', 'author-comment')"/>
   <xsl:param name="peer-review-types" select="($types-with-related-object, 'community-comment', 'aggregated-review-documents')"/>
   <xsl:param name="peer-review-document-types" select="('peer-reviewed-article', 'reviewer-report', 'editor-report', 'author-comment', 'community-comment', 'aggregated-review-documents', 'peer-review-report')"/>
   <xsl:param name="unallowed-type-regex" select="string-join(for $value in $peer-review-types return concat('^',replace($value,'-','[\\s_–—\\-]?'),'$'),'|')"/>
</xsl:stylesheet>