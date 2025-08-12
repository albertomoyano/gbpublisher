<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0"
                exclude-result-prefixes="xsl">

  <xsl:output method="xml" encoding="utf-8" indent="yes"/>

  <xsl:template match="/">
    <Document DOMVersion="6.0" OriginalVersion="1.0" xmlns:xlink="http://www.w3.org/1999/xlink">
      <Stories>
        <xsl:call-template name="make-front-story"/>
        <xsl:call-template name="make-body-story"/>
        <xsl:call-template name="make-biblio-story"/>
      </Stories>
      <ParagraphStyleRangeList>
        <!-- Estructura jerárquica de 3 niveles -->
        <ParagraphStyleRange Self="Title" AppliedParagraphStyle="Title"/>
        <ParagraphStyleRange Self="Subtitle" AppliedParagraphStyle="Subtitle"/>
        <ParagraphStyleRange Self="Heading1" AppliedParagraphStyle="Heading1"/>
        <ParagraphStyleRange Self="Heading2" AppliedParagraphStyle="Heading2"/>
        <ParagraphStyleRange Self="Heading3" AppliedParagraphStyle="Heading3"/>
        <!-- Párrafos especializados -->
        <ParagraphStyleRange Self="Body" AppliedParagraphStyle="Body"/>
        <ParagraphStyleRange Self="BodyFirst" AppliedParagraphStyle="BodyFirst"/>
        <ParagraphStyleRange Self="Quote" AppliedParagraphStyle="Quote"/>
        <ParagraphStyleRange Self="Epigraph" AppliedParagraphStyle="Epigraph"/>
        <ParagraphStyleRange Self="Footnote" AppliedParagraphStyle="Footnote"/>
        <!-- Metadatos y referencias -->
        <ParagraphStyleRange Self="Author" AppliedParagraphStyle="Author"/>
        <ParagraphStyleRange Self="Date" AppliedParagraphStyle="Date"/>
        <ParagraphStyleRange Self="Publisher" AppliedParagraphStyle="Publisher"/>
        <ParagraphStyleRange Self="Bibliography" AppliedParagraphStyle="Bibliography"/>
      </ParagraphStyleRangeList>
    </Document>
  </xsl:template>

  <xsl:template name="make-front-story">
    <Story Self="story-front">
      <!-- Título principal como Title -->
      <xsl:for-each select="//front//article-title">
        <ParagraphStyleRange AppliedParagraphStyle="Title">
          <CharacterStyleRange>
            <xsl:value-of select="normalize-space(.)"/>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      </xsl:for-each>

      <!-- Subtítulo como Subtitle -->
      <xsl:for-each select="//front//subtitle">
        <ParagraphStyleRange AppliedParagraphStyle="Subtitle">
          <CharacterStyleRange>
            <xsl:value-of select="normalize-space(.)"/>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      </xsl:for-each>

      <!-- Autor con estilo específico -->
      <xsl:if test="//front//contrib">
        <ParagraphStyleRange AppliedParagraphStyle="Author">
          <CharacterStyleRange>
            <xsl:for-each select="//front//contrib">
              <xsl:variable name="name">
                <xsl:choose>
                  <xsl:when test="name/surname and name/given-names">
                    <xsl:value-of select="concat(normalize-space(name/surname), ', ', normalize-space(name/given-names))"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space(.)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:value-of select="$name"/>
              <xsl:if test="position() != last()">
                <xsl:text>; </xsl:text>
              </xsl:if>
            </xsl:for-each>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      </xsl:if>

      <!-- Editorial y fecha con estilos separados -->
      <xsl:if test="//front//publisher-name">
        <ParagraphStyleRange AppliedParagraphStyle="Publisher">
          <CharacterStyleRange>
            <xsl:value-of select="normalize-space(//front//publisher-name)"/>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      </xsl:if>

      <xsl:if test="//front//pub-date">
        <ParagraphStyleRange AppliedParagraphStyle="Date">
          <CharacterStyleRange>
            <xsl:value-of select="normalize-space(//front//pub-date)"/>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      </xsl:if>

      <!-- Abstract como párrafo normal -->
      <xsl:for-each select="//front//abstract | //front//description">
        <ParagraphStyleRange AppliedParagraphStyle="Body">
          <CharacterStyleRange>
            <xsl:value-of select="normalize-space(.)"/>
          </CharacterStyleRange>
        </ParagraphStyleRange>
      </xsl:for-each>
    </Story>
  </xsl:template>

  <xsl:template name="make-body-story">
    <Story Self="story-body">
      <!-- Procesar secciones con jerarquía de 3 niveles -->
      <xsl:for-each select="//body//sec">
        <xsl:call-template name="process-section">
          <xsl:with-param name="section" select="."/>
        </xsl:call-template>
      </xsl:for-each>

      <!-- Párrafos sueltos fuera de secciones -->
      <xsl:for-each select="//body/p[not(ancestor::sec)]">
        <xsl:call-template name="process-paragraph">
          <xsl:with-param name="para" select="."/>
          <xsl:with-param name="position" select="position()"/>
        </xsl:call-template>
      </xsl:for-each>
    </Story>
  </xsl:template>

  <!-- Template para procesar secciones jerárquicas -->
  <xsl:template name="process-section">
    <xsl:param name="section"/>

    <!-- Determinar nivel de encabezado -->
    <xsl:for-each select="$section/title">
      <xsl:variable name="section-type" select="../@sec-type"/>
      <xsl:variable name="heading-style">
        <xsl:choose>
          <xsl:when test="$section-type = 'level1' or contains($section-type, 'level1')">Heading1</xsl:when>
          <xsl:when test="$section-type = 'level2' or contains($section-type, 'level2')">Heading2</xsl:when>
          <xsl:when test="$section-type = 'level3' or contains($section-type, 'level3')">Heading3</xsl:when>
          <xsl:otherwise>Heading2</xsl:otherwise> <!-- Default -->
        </xsl:choose>
      </xsl:variable>

      <ParagraphStyleRange AppliedParagraphStyle="{$heading-style}">
        <CharacterStyleRange>
          <xsl:value-of select="normalize-space(.)"/>
        </CharacterStyleRange>
      </ParagraphStyleRange>
    </xsl:for-each>

    <!-- Procesar párrafos dentro de la sección -->
    <xsl:for-each select="$section/p | $section/para">
      <xsl:call-template name="process-paragraph">
        <xsl:with-param name="para" select="."/>
        <xsl:with-param name="position" select="position()"/>
      </xsl:call-template>
    </xsl:for-each>

    <!-- Procesar subsecciones recursivamente -->
    <xsl:for-each select="$section/sec">
      <xsl:call-template name="process-section">
        <xsl:with-param name="section" select="."/>
      </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Template para procesar párrafos con tipos especiales -->
  <xsl:template name="process-paragraph">
    <xsl:param name="para"/>
    <xsl:param name="position"/>

    <xsl:variable name="para-style">
      <xsl:choose>
        <!-- Detectar epígrafes (párrafos cortos, cursivos, al inicio de sección) -->
        <xsl:when test="$position = 1 and string-length(normalize-space(.)) &lt; 200 and (.//italic or .//i or .//em)">Epigraph</xsl:when>
        <!-- Detectar citas (párrafos que empiezan con comillas o son citas en bloque) -->
        <xsl:when test="starts-with(normalize-space(.), '&quot;') or starts-with(normalize-space(.), '&#8220;') or ancestor::blockquote">Quote</xsl:when>
        <!-- Primer párrafo de sección sin sangría -->
        <xsl:when test="$position = 1">BodyFirst</xsl:when>
        <!-- Párrafo normal -->
        <xsl:otherwise>Body</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <ParagraphStyleRange AppliedParagraphStyle="{$para-style}">
      <CharacterStyleRange>
        <xsl:call-template name="inline-to-text">
          <xsl:with-param name="node" select="."/>
        </xsl:call-template>
      </CharacterStyleRange>
    </ParagraphStyleRange>
  </xsl:template>

  <xsl:template name="make-biblio-story">
    <xsl:choose>
      <xsl:when test="//ref-list">
        <Story Self="story-biblio">
          <ParagraphStyleRange AppliedParagraphStyle="Heading2">
            <CharacterStyleRange>
              <xsl:choose>
                <xsl:when test="//ref-list/title">
                  <xsl:value-of select="normalize-space(//ref-list/title)"/>
                </xsl:when>
                <xsl:otherwise>Referencias</xsl:otherwise>
              </xsl:choose>
            </CharacterStyleRange>
          </ParagraphStyleRange>
          <xsl:for-each select="//ref-list/ref">
            <ParagraphStyleRange AppliedParagraphStyle="Bibliography">
              <CharacterStyleRange>
                <xsl:call-template name="inline-to-text">
                  <xsl:with-param name="node" select="."/>
                </xsl:call-template>
              </CharacterStyleRange>
            </ParagraphStyleRange>
          </xsl:for-each>
        </Story>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:template>

  <!-- Template mejorado para procesar texto inline -->
  <xsl:template name="inline-to-text">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="self::text() or name($node) = 'p' or name($node) = 'para' or name($node) = 'ref' or name($node) = 'title'">
        <xsl:for-each select="$node/node()">
          <xsl:choose>
            <xsl:when test="self::text()">
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:when>
            <!-- Cursivas -->
            <xsl:when test="self::italic or self::i or self::em">
              <xsl:text> [I] </xsl:text>
              <xsl:value-of select="normalize-space(.)"/>
              <xsl:text> [/I] </xsl:text>
            </xsl:when>
            <!-- Negritas -->
            <xsl:when test="self::bold or self::strong or self::b">
              <xsl:text> [B] </xsl:text>
              <xsl:value-of select="normalize-space(.)"/>
              <xsl:text> [/B] </xsl:text>
            </xsl:when>
            <!-- Notas al pie -->
            <xsl:when test="self::fn or self::footnote">
              <xsl:text> [NOTA: </xsl:text>
              <xsl:value-of select="normalize-space(.)"/>
              <xsl:text>] </xsl:text>
            </xsl:when>
            <!-- Otros elementos -->
            <xsl:otherwise>
              <xsl:value-of select="normalize-space(.)"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:if test="position() != last() and self::text() and normalize-space(.) != ''">
            <xsl:text> </xsl:text>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="normalize-space($node)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()">
    <xsl:value-of select="normalize-space(.)"/>
  </xsl:template>

</xsl:stylesheet>
