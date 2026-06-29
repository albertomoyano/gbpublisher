<?xml version="1.0" encoding="UTF-8"?>
<!--
  =====================================================
  ensamblar-capitulo-canonico.xsl
  =====================================================
  DESCRIPCIÓN:
    ENSAMBLA EL CAPÍTULO DOCBOOK 5.2 CANÓNICO COMPLETO
    A PARTIR DE TRES FRAGMENTOS GENERADOS POR GBPUBLISHER:

    - FUENTE PRINCIPAL (-s):  info-cap-NN.xml
    - PARÁMETRO body:         body-cap-NN.xml
    - PARÁMETRO biblio:       biblio-cap-NN.xml (OPCIONAL,
                              SOLO SI lugar_bibliografia='por_capitulo')

    PARÁMETROS ADICIONALES:
    - tipo_capitulo:    VALOR DEL ENUM capitulos.tipo_capitulo
                        ('capitulo' POR DEFECTO).
    - xml_id_capitulo:  VALOR ASCII PARA EL xml:id DEL WRAPPER RAÍZ
                        (TÍPICAMENTE 'cap-{id_capitulo}').
    - idioma:           xml:lang DEL CAPÍTULO ('es' POR DEFECTO).

  USO:
    java -jar /opt/Saxon-HE/saxon-he-12.9.jar \
      -s:tmp/info-cap-01.xml \
      -xsl:~/.gbpublisher/xslt/ensamblar-capitulo-canonico.xsl \
      -o:c-cap-01.xml \
      body=tmp/body-cap-01.xml \
      biblio=tmp/biblio-cap-01.xml \
      tipo_capitulo=capitulo \
      xml_id_capitulo=cap-37 \
      idioma=es

  ESTRUCTURA DE SALIDA (EJEMPLO CAPÍTULO REGULAR):
    <chapter xmlns="http://docbook.org/ns/docbook"
             xmlns:xlink="http://www.w3.org/1999/xlink"
             xmlns:mml="http://www.w3.org/1998/Math/MathML"
             version="5.2"
             xml:lang="es"
             xml:id="cap-37">
      <info>...</info>          ← DESDE info-cap-NN.xml
      <section>...</section>    ← DESDE body-cap-NN.xml (HIJOS DEL section RAÍZ)
      <bibliography>...</bibliography>  ← DESDE biblio-cap-NN.xml (OPCIONAL)
    </chapter>

  MAPEO tipo_capitulo → ELEMENTO RAÍZ + role:
    SIMPLES (SIN role):
      capitulo        → <chapter>
      dedicatoria     → <dedication>
      agradecimientos → <acknowledgements>
      apendice        → <appendix>
      glosario        → <glossary>
      bibliografia    → <bibliography>
      colofon         → <colophon>
    CON role:
      prologo, prefacio, presentacion, palabras_preliminares,
      nota_traductor, nota_editor, posfacio, post_scriptum → <preface role="...">
      introduccion, conclusiones, epilogo                  → <chapter role="...">
      sobre_autores, cronologia                            → <appendix role="...">
    ESPECIALES:
      lista_figuras         → <toc role="lof">
      lista_tablas          → <toc role="lot">
      lista_abreviaturas    → <glossary role="abreviaturas">
      indice_onomastico     → <index type="onomastic">
      indice_tematico       → <index type="thematic">
      indice_analitico      → <index>
      otro                  → <chapter role="otro"> (FALLBACK)

  TRANSFORMACIONES APLICADAS:
    1. SLUGIFY xml:id CON CARACTERES NO-ASCII (TÍPICAMENTE LOS
       AUTOGENERADOS POR PANDOC DESDE TÍTULOS CON TILDES).
       SE ACTUALIZAN TAMBIÉN LOS xlink:href INTERNOS QUE LOS
       REFERENCIAN.
    2. ELIMINAR <textobject><phrase> DENTRO DE <figure> CUANDO
       SU CONTENIDO DUPLICA EL <title> DE LA FIGURA (RUIDO
       INTRODUCIDO POR PANDOC AL CONVERTIR IMÁGENES CON CAPTION).
    3. DESCARTAR EL <title> DEL <section> RAÍZ DEL BODY PANDOC
       (ES EL PRIMER HEADING DEL MARKDOWN, REDUNDANTE CON EL
       <title> QUE VIENE EN <info>).

  NOTAS:
    - SIN DOCTYPE: DOCBOOK 5.2 USA RELAX NG, NO DTD. EL DOCUMENTO
      SE VALIDA CONTRA docbook.rng-5.2 INSTALADO LOCALMENTE.
    - NAMESPACES DECLARADOS UNA SOLA VEZ EN EL ELEMENTO RAÍZ.
    - VERSIÓN XSLT: 2.0 (REQUIERE SAXON-HE 12.x).
  =====================================================
-->
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://docbook.org/ns/docbook"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:mml="http://www.w3.org/1998/Math/MathML"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="db xs xlink mml"
  version="2.0">

  <!-- ================================================
       PARÁMETROS DE ENTRADA
       ================================================ -->
  <xsl:param name="body" as="xs:string"/>
  <xsl:param name="biblio" as="xs:string" select="''"/>
  <xsl:param name="tipo_capitulo" as="xs:string" select="'capitulo'"/>
  <xsl:param name="xml_id_capitulo" as="xs:string" select="''"/>
  <xsl:param name="idioma" as="xs:string" select="'es'"/>

  <!-- ================================================
       SALIDA: DOCBOOK 5.2 SIN DOCTYPE
       VALIDACIÓN POSTERIOR CON RELAX NG (jing / Saxon NG).
       ================================================ -->
  <xsl:output
    method="xml"
    encoding="UTF-8"
    indent="yes"
    omit-xml-declaration="no"/>

  <!-- ================================================
       FUNCIÓN UTILITARIA: SLUGIFY
       CONVIERTE UN STRING CON CARACTERES NO-ASCII A SU
       EQUIVALENTE ASCII APROXIMADO. ETAPA 1: TRADUCE
       VOCALES CON TILDES, DIÉRESIS, ETC. ETAPA 2:
       REEMPLAZA CUALQUIER CARÁCTER NO-ASCII RESTANTE
       POR GUIÓN PARA EVITAR IDs INVÁLIDOS.
       ================================================ -->
  <xsl:function name="db:slugify" as="xs:string">
    <xsl:param name="s" as="xs:string"/>
    <!-- ETAPA 1: ROMANCE COMMON (ESPAÑOL, PORTUGUÉS, FRANCÉS, CATALÁN) -->
    <xsl:variable name="t1" select="translate($s,
      'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ',
      'aaaaaeeeeiiiiooooouuuuncAAAAAEEEEIIIIOOOOOUUUUNC')"/>
    <!-- ETAPA 2: CUALQUIER OTRO NO-ASCII → '-' (GUARDIA PARA
         CARACTERES DE OTROS ALFABETOS QUE EVENTUALMENTE APAREZCAN).
         USA \p{IsBasicLatin} EN VEZ DE \x00-\x7F PORQUE XPATH 2.0
         SIGUE XSD REGEX, QUE NO ACEPTA ESCAPES HEX LITERALES. EL
         BLOQUE UNICODE IsBasicLatin EQUIVALE EXACTAMENTE A U+0000
         HASTA U+007F (RANGO ASCII COMPLETO). -->
    <xsl:sequence select="replace($t1, '[^\p{IsBasicLatin}]', '-')"/>
  </xsl:function>

  <!-- ================================================
       TEMPLATE RAÍZ
       PUNTO DE ENTRADA: PROCESA info-cap-NN.xml
       ================================================ -->
  <xsl:template match="/">

    <!-- DERIVAR elementoRaiz Y roleAtributo SEGÚN tipo_capitulo -->
    <xsl:variable name="elementoRaiz">
      <xsl:choose>
        <xsl:when test="$tipo_capitulo = 'capitulo'">chapter</xsl:when>
        <xsl:when test="$tipo_capitulo = 'introduccion'">chapter</xsl:when>
        <xsl:when test="$tipo_capitulo = 'conclusiones'">chapter</xsl:when>
        <xsl:when test="$tipo_capitulo = 'epilogo'">chapter</xsl:when>
        <xsl:when test="$tipo_capitulo = 'prologo'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'prefacio'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'presentacion'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'palabras_preliminares'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'nota_traductor'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'nota_editor'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'posfacio'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'post_scriptum'">preface</xsl:when>
        <xsl:when test="$tipo_capitulo = 'dedicatoria'">dedication</xsl:when>
        <xsl:when test="$tipo_capitulo = 'agradecimientos'">acknowledgements</xsl:when>
        <xsl:when test="$tipo_capitulo = 'apendice'">appendix</xsl:when>
        <xsl:when test="$tipo_capitulo = 'sobre_autores'">appendix</xsl:when>
        <xsl:when test="$tipo_capitulo = 'cronologia'">appendix</xsl:when>
        <xsl:when test="$tipo_capitulo = 'glosario'">glossary</xsl:when>
        <xsl:when test="$tipo_capitulo = 'lista_abreviaturas'">glossary</xsl:when>
        <xsl:when test="$tipo_capitulo = 'bibliografia'">bibliography</xsl:when>
        <xsl:when test="$tipo_capitulo = 'colofon'">colophon</xsl:when>
        <xsl:when test="$tipo_capitulo = 'lista_figuras'">toc</xsl:when>
        <xsl:when test="$tipo_capitulo = 'lista_tablas'">toc</xsl:when>
        <xsl:when test="$tipo_capitulo = 'indice_onomastico'">index</xsl:when>
        <xsl:when test="$tipo_capitulo = 'indice_tematico'">index</xsl:when>
        <xsl:when test="$tipo_capitulo = 'indice_analitico'">index</xsl:when>
        <xsl:otherwise>chapter</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- DERIVAR roleAtributo: VACÍO PARA CAPÍTULOS NEUTROS,
         NOMBRE DEL tipo PARA TIPOS QUE COMPARTEN ELEMENTO -->
    <xsl:variable name="roleAtributo">
      <xsl:choose>
        <xsl:when test="$tipo_capitulo = 'introduccion'">introduccion</xsl:when>
        <xsl:when test="$tipo_capitulo = 'conclusiones'">conclusiones</xsl:when>
        <xsl:when test="$tipo_capitulo = 'epilogo'">epilogo</xsl:when>
        <xsl:when test="$tipo_capitulo = 'prologo'">prologo</xsl:when>
        <xsl:when test="$tipo_capitulo = 'prefacio'">prefacio</xsl:when>
        <xsl:when test="$tipo_capitulo = 'presentacion'">presentacion</xsl:when>
        <xsl:when test="$tipo_capitulo = 'palabras_preliminares'">palabras-preliminares</xsl:when>
        <xsl:when test="$tipo_capitulo = 'nota_traductor'">nota-traductor</xsl:when>
        <xsl:when test="$tipo_capitulo = 'nota_editor'">nota-editor</xsl:when>
        <xsl:when test="$tipo_capitulo = 'posfacio'">posfacio</xsl:when>
        <xsl:when test="$tipo_capitulo = 'post_scriptum'">post-scriptum</xsl:when>
        <xsl:when test="$tipo_capitulo = 'sobre_autores'">sobre-autores</xsl:when>
        <xsl:when test="$tipo_capitulo = 'cronologia'">cronologia</xsl:when>
        <xsl:when test="$tipo_capitulo = 'lista_abreviaturas'">abreviaturas</xsl:when>
        <xsl:when test="$tipo_capitulo = 'lista_figuras'">lof</xsl:when>
        <xsl:when test="$tipo_capitulo = 'lista_tablas'">lot</xsl:when>
        <xsl:when test="$tipo_capitulo = 'otro'">otro</xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- DERIVAR ATRIBUTO type PARA <index> -->
    <xsl:variable name="indexType">
      <xsl:choose>
        <xsl:when test="$tipo_capitulo = 'indice_onomastico'">onomastic</xsl:when>
        <xsl:when test="$tipo_capitulo = 'indice_tematico'">thematic</xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- CARGAR FRAGMENTO body (OBLIGATORIO) -->
    <xsl:variable name="bodyDoc" select="document($body)"/>

    <!-- ELEMENTO RAÍZ DINÁMICO -->
    <xsl:element name="{$elementoRaiz}">
      <!-- DECLARAR EXPLÍCITAMENTE LOS NAMESPACES QUE USARÁN LOS
           DESCENDIENTES, PARA QUE SAXON NO LOS RE-EMITA EN CADA
           NODO HIJO COPIADO DESDE EL document() DEL BODY. -->
      <xsl:namespace name="xlink" select="'http://www.w3.org/1999/xlink'"/>
      <xsl:namespace name="mml" select="'http://www.w3.org/1998/Math/MathML'"/>
      <xsl:attribute name="version" select="'5.2'"/>
      <xsl:attribute name="xml:lang" select="$idioma"/>
      <xsl:if test="$xml_id_capitulo != ''">
        <xsl:attribute name="xml:id" select="$xml_id_capitulo"/>
      </xsl:if>
      <xsl:if test="$roleAtributo != ''">
        <xsl:attribute name="role" select="$roleAtributo"/>
      </xsl:if>
      <xsl:if test="$indexType != ''">
        <xsl:attribute name="type" select="$indexType"/>
      </xsl:if>

      <!-- PASO 1: INSERTAR <info> DESDE EL ARCHIVO PRINCIPAL -->
      <xsl:apply-templates select="//db:info | //info"/>

      <!-- PASO 2: INSERTAR CONTENIDO DEL BODY
           DESCARTANDO EL <title> DEL section RAÍZ (REDUNDANTE
           CON EL <title> DE <info>). TOMA TODOS LOS HIJOS DEL
           ROOT EXCEPTO TITLE. -->
      <xsl:apply-templates
        select="$bodyDoc/*/node()[not(self::db:title) and not(self::title)]"/>

      <!-- PASO 3: INSERTAR <bibliography> SI EL FRAGMENTO EXISTE.
           NO APLICA SI tipo_capitulo='bibliografia' (EL CAPÍTULO
           ENTERO ES LA BIBLIOGRAFÍA, EL CONTENIDO YA VINO EN body). -->
      <xsl:if test="$biblio != '' and $tipo_capitulo != 'bibliografia'">
        <xsl:variable name="biblioDoc" select="document($biblio)"/>
        <xsl:if test="$biblioDoc/db:bibliography/db:biblioentry
                      or $biblioDoc/bibliography/biblioentry">
          <xsl:apply-templates
            select="$biblioDoc/db:bibliography | $biblioDoc/bibliography"/>
        </xsl:if>
      </xsl:if>

    </xsl:element>
  </xsl:template>

  <!-- ================================================
       TEMPLATE DE IDENTIDAD
       COPIA TODOS LOS NODOS TAL CUAL, EXCEPTO LOS
       QUE TIENEN TEMPLATES ESPECÍFICOS MÁS ABAJO.
       USA copy-namespaces="no" PARA EVITAR QUE LOS
       ELEMENTOS DESCENDIENTES RE-DECLAREN xmlns:mml Y
       xmlns:xlink QUE YA ESTÁN EN EL ELEMENTO RAÍZ.
       ================================================ -->
  <xsl:template match="@*|node()">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- ================================================
       SLUGIFY xml:id CON CARACTERES NO-ASCII
       LOS xml:id AUTOGENERADOS POR PANDOC DESDE TÍTULOS
       (TÍPICAMENTE CON TILDES Y ñ) SE NORMALIZAN A ASCII
       PARA COMPATIBILIDAD CON HERRAMIENTAS EXTERNAS
       (CROSSREF, EPUB VALIDATORS, ETC.).
       LOS xml:id YA ASCII (TÍPICAMENTE LOS EXPLÍCITOS DEL
       AUTOR: fig-N, tbl-N, eq-N, cap-N) SE PRESERVAN.
       ================================================ -->
  <xsl:template match="@xml:id">
    <xsl:choose>
      <xsl:when test="matches(., '[^\p{IsBasicLatin}]')">
        <xsl:attribute name="xml:id" select="db:slugify(.)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       SLUGIFY xlink:href INTERNO (FRAGMENTOS #X)
       SE APLICA SOLO A xlink:href QUE EMPIEZAN CON '#'
       (REFERENCIAS INTERNAS); LAS URLs EXTERNAS SE
       PRESERVAN INTACTAS.
       MANTIENE LA CONSISTENCIA ENTRE EL xml:id NORMALIZADO
       Y LAS REFERENCIAS QUE LO USAN.
       ================================================ -->
  <xsl:template match="@xlink:href[starts-with(., '#')]">
    <xsl:variable name="targetId" select="substring-after(., '#')"/>
    <xsl:choose>
      <xsl:when test="matches($targetId, '[^\p{IsBasicLatin}]')">
        <xsl:attribute name="xlink:href"
          select="concat('#', db:slugify($targetId))"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ================================================
       ELIMINAR <textobject><phrase> REDUNDANTE EN FIGURAS
       PANDOC AGREGA UN <textobject> CON EL TEXTO DEL alt
       DE LA IMAGEN, QUE COINCIDE CON EL <title> DE LA
       <figure>. ES RUIDO VISUAL Y REDUNDANTE; SE OMITE.
       ================================================ -->
  <xsl:template match="db:figure/db:mediaobject/db:textobject[
      normalize-space(db:phrase) = normalize-space(ancestor::db:figure[1]/db:title)
   or normalize-space(db:phrase) = normalize-space(ancestor::db:figure[1]/db:info/db:title)]"/>

  <!-- ================================================
       PRESERVAR ELEMENTOS MathML SIN PERDER NAMESPACE
       LA IDENTIDAD POR DEFAULT YA LOS COPIA CORRECTAMENTE
       PORQUE EL NAMESPACE mml: ESTÁ DECLARADO EN EL
       STYLESHEET. NO HACE FALTA TEMPLATE ESPECÍFICO.
       (DOCUMENTADO POR CLARIDAD.)
       ================================================ -->

</xsl:stylesheet>
