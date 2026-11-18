<?xml version="1.0" encoding="UTF-8"?><!--
  GENERADO POR generar-schematron-jats4r.sh. NO EDITAR A MANO: SE REGENERA
  DESDE LA VERSIÓN FIJADA DE jats-schematrons (SC-11, GV-26, SC-97).

  Un temático de JATS4R para el auditor de XML ajenos, compilado solo con
  un envoltorio derivado del maestro (jats4r.sch sin fases, con este único
  <include>) y el esqueleto ISO. Verificado contra el maestro.

  fuente     https://github.com/JATS4R/jats-schematrons.git
             v0.0.17, commit 6589a03abc87eedd1156b7dc8acc39d5cda4dd3a
  temático   schematrons/1.0/peer-review-errors.sch
             sha256 c9b5c7d514fb852826f1e024c39341be762229b8b4fb2e87827e382ce0474169
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
            <xsl:attribute name="id">peer-review-errors</xsl:attribute>
            <xsl:attribute name="name">peer-review-errors</xsl:attribute>
            <xsl:apply-templates/>
         </svrl:active-pattern>
         <xsl:apply-templates select="/" mode="M7"/>
      </svrl:schematron-output>
   </xsl:template>
   <!--SCHEMATRON PATTERNS-->

   <!--PATTERN peer-review-errors-->

   <!--RULE -->
   <xsl:template match="article[not(@article-type=$peer-review-types)]|sub-article[not(@article-type=$peer-review-types)]" priority="1009" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta | sub-article[@article-type=$peer-review-types]/front-stub" priority="1008" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//contrib | sub-article[@article-type=$peer-review-types]/front-stub//contrib[not(ancestor::collab)]" priority="1007" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$types-with-related-object]//article-meta/related-object[@document-type=$peer-review-document-types]|         sub-article[@article-type=$types-with-related-object]/front-stub/related-object[@document-type=$peer-review-document-types]" priority="1006" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta/pub-history/event |          sub-article[@article-type=$peer-review-types]/front-stub/pub-history/event" priority="1005" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-stage'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-stage']" priority="1004" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='transfer'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='transfer']" priority="1003" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-revision-round'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-revision-round']" priority="1002" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-recommendation'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-recommendation']" priority="1001" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <!--RULE -->
   <xsl:template match="article[@article-type=$peer-review-types]//article-meta//custom-meta[meta-name='peer-review-identity-transparency'] | sub-article[@article-type=$peer-review-types]/front-stub//custom-meta[meta-name='peer-review-identity-transparency']" priority="1000" mode="M7">
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
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <xsl:template match="text()" priority="-1" mode="M7"/>
   <xsl:template match="@*|node()" priority="-2" mode="M7">
      <xsl:apply-templates select="*" mode="M7"/>
   </xsl:template>
   <xsl:param name="types-with-related-object" select="('reviewer-report', 'editor-report', 'author-comment')"/>
   <xsl:param name="peer-review-types" select="($types-with-related-object, 'community-comment', 'aggregated-review-documents')"/>
   <xsl:param name="peer-review-document-types" select="('peer-reviewed-article', 'reviewer-report', 'editor-report', 'author-comment', 'community-comment', 'aggregated-review-documents', 'peer-review-report')"/>
   <xsl:param name="unallowed-type-regex" select="string-join(for $value in $peer-review-types return concat('^',replace($value,'-','[\\s_–—\\-]?'),'$'),'|')"/>
</xsl:stylesheet>