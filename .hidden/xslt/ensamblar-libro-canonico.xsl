<?xml version="1.0" encoding="UTF-8"?>
<!--
=========================================================
ENSAMBLADOR DEL CANÓNICO DEL LIBRO COMPLETO — DocBook 5.2
=========================================================
UBICACIÓN: ~/.gbpublisher/xslt/ensamblar-libro-canonico.xsl

PROPÓSITO:
  Ensambla el canónico DocBook 5.2 del libro completo a partir de:
    - Fuente principal: tmp/manifiesto-libro-{nombre}.xml
    - <info> del libro: tmp/info-libro-{nombre}.xml (referenciado por atributo)
    - Canónicos de capítulos: jats/c-{nombre_archivo}.xml (uno por capítulo)

  Produce: jats/c-libro-{nombre}.xml, con estructura:
    <book xml:lang="{idioma_principal}">
      <info>...</info>                            <- del info-libro-*.xml
      <chapter|preface|appendix|bibliography>...  <- canónico del capítulo 1
      <chapter|preface|appendix|bibliography>...  <- canónico del capítulo 2
      ...
    </book>

VERIFICACIÓN CRUZADA:
  El manifiesto viene ordenado desde Gambas (query con CASE WHEN),
  pero el XSLT aplica su propio xsl:sort defensivo con dos claves:
    1. Peso del prefijo: fm=1, a=2, bm=3, otro=9
    2. Nombre de archivo alfabético
  Si el manifiesto está bien, el sort no cambia nada. Si viene
  desordenado por edición manual o bug futuro, se endereza silenciosamente.

RC APLICADAS:
  - RC-DB-08: copy-namespaces="no" para evitar re-declarar xmlns redundantes
    al copiar los nodos raíz de los canónicos individuales
  - RC-XJ-01: xml:lang cae en cascada al @idioma_principal, default 'es'

DOCUMENTACIÓN DE REFERENCIA:
  - xsl:sort: https://www.saxonica.com/html/documentation12/xsl-elements/sort.html
  - xsl:copy-of: https://www.saxonica.com/html/documentation12/xsl-elements/copy-of.html
  - document(): función XPath 2.0 estándar
=========================================================
-->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:db="http://docbook.org/ns/docbook"
                xmlns="http://docbook.org/ns/docbook"
                xmlns:mml="http://www.w3.org/1998/Math/MathML"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs db">

  <xsl:output method="xml"
              encoding="UTF-8"
              indent="yes"
              omit-xml-declaration="no"/>

  <!-- ==========================================================
       DIRECTORIO BASE PARA RESOLVER LOS PATHS RELATIVOS DEL
       MANIFIESTO. SAXON RECIBE ESTE PARÁMETRO DESDE EL HANDLER
       CON LA RUTA ABSOLUTA DEL PROYECTO.
       ========================================================== -->
  <xsl:param name="proyecto_dir" as="xs:string" required="yes"/>

  <!-- ==========================================================
       MODELO DE BIBLIOGRAFÍA: 'por_capitulo' | 'consolidada'.
       Lo pasa el handler desde libros_md.lugar_bibliografia.
       EN 'por_capitulo' LA MISMA OBRA SE LISTA EN CADA CAPÍTULO
       QUE LA CITA, GENERANDO xml:id DUPLICADOS ENTRE CAPÍTULOS.
       PARA EVITAR LA COLISIÓN DE ID (INVÁLIDA EN XML), SE PREFIJAN
       LOS xml:id DE <biblioentry> Y LOS linkend DE <biblioref> CON
       EL xml:id DEL CAPÍTULO CONTENEDOR, DE FORMA COORDINADA.
       DEFAULT 'por_capitulo' (EL MÁS COMÚN Y EL DEL LIBRO DE PRUEBA). -->
  <xsl:param name="lugar_bibliografia" as="xs:string" select="'por_capitulo'"/>

  <!-- ==========================================================
       RUTA (RELATIVA A proyecto_dir) DEL FRAGMENTO DE BIBLIOGRAFÍA
       CONSOLIDADA QUE GENERA GenerarBiblioLibroXML EN GAMBAS. SOLO
       SE USA CUANDO lugar_bibliografia = 'consolidada'. EL FRAGMENTO
       ES UN <bibliography> CON TODAS LAS ENTRADAS DEL LIBRO, YA
       DEDUPLICADAS Y EN ORDEN, DERIVADAS DEL .bib ÚNICO.
       VACÍO EN por_capitulo (NO SE USA). -->
  <xsl:param name="biblio_libro" as="xs:string" select="''"/>

  <!-- ==========================================================
       PLANTILLA PRINCIPAL: MATCH /manifiesto-libro
       ========================================================== -->
  <xsl:template match="/manifiesto-libro">

    <!-- CARGAR EL <libro> Y CAPTURAR SUS ATRIBUTOS -->
    <xsl:variable name="libro" select="libro"/>
    <xsl:variable name="idiomaPrincipal" as="xs:string">
      <xsl:choose>
        <xsl:when test="normalize-space($libro/@idioma_principal) != ''">
          <xsl:value-of select="$libro/@idioma_principal"/>
        </xsl:when>
        <xsl:otherwise>es</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- RUTA COMPLETA AL info-libro-*.xml -->
    <xsl:variable name="infoLibroPath"
                  select="concat($proyecto_dir, '/', $libro/@info_libro)"/>

    <!-- ==========================================================
         EMITIR EL <book> RAÍZ CON xml:lang
         ========================================================== -->
    <book xml:lang="{$idiomaPrincipal}">

      <!-- INSERTAR EL <info> DEL LIBRO -->
      <!-- copy-namespaces="no" EVITA RE-DECLARAR NAMESPACES REDUNDANTES -->
      <xsl:choose>
        <xsl:when test="doc-available($infoLibroPath)">
          <xsl:copy-of select="doc($infoLibroPath)/*"
                       copy-namespaces="no"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message terminate="yes">
            <xsl:text>ERROR: No se pudo cargar el info-libro en: </xsl:text>
            <xsl:value-of select="$infoLibroPath"/>
          </xsl:message>
        </xsl:otherwise>
      </xsl:choose>

      <!-- ==========================================================
           ITERAR CAPÍTULOS EN ORDEN CANÓNICO (fm → a → bm),
           APLICANDO xsl:sort DEFENSIVO PARA GARANTIZAR EL ORDEN
           INDEPENDIENTEMENTE DE CÓMO VENGAN EN EL MANIFIESTO.
           ========================================================== -->
      <xsl:for-each select="capitulos/capitulo">

        <!-- SORT PRIMARIO: PESO DEL PREFIJO (fm=1, a=2, bm=3, otro=9) -->
        <!-- SE USA data-type="number" PARA EVITAR SORT LEXICOGRÁFICO -->
        <xsl:sort data-type="number">
          <xsl:choose>
            <xsl:when test="starts-with(@nombre_archivo, 'fm-')">1</xsl:when>
            <xsl:when test="starts-with(@nombre_archivo, 'a-')">2</xsl:when>
            <xsl:when test="starts-with(@nombre_archivo, 'bm-')">3</xsl:when>
            <xsl:otherwise>9</xsl:otherwise>
          </xsl:choose>
        </xsl:sort>

        <!-- SORT SECUNDARIO: NOMBRE DE ARCHIVO ALFABÉTICO -->
        <!-- LA NUMERACIÓN NN GARANTIZA EL ORDEN CORRECTO -->
        <xsl:sort select="@nombre_archivo" data-type="text"/>

        <!-- CARGAR EL CANÓNICO DEL CAPÍTULO -->
        <xsl:variable name="capituloPath"
                      select="concat($proyecto_dir, '/', @path)"/>

        <xsl:choose>
          <xsl:when test="doc-available($capituloPath)">
            <!-- CARGAR EL NODO RAÍZ DEL CAPÍTULO (chapter/preface/appendix/...) -->
            <xsl:variable name="raizCapitulo" select="doc($capituloPath)/*"/>

            <xsl:choose>
              <!-- MODELO por_capitulo: PREFIJAR IDs DE BIBLIOGRAFÍA CON EL
                   xml:id DEL CAPÍTULO PARA EVITAR COLISIONES ENTRE CAPÍTULOS.
                   EL PREFIJO SE PASA POR TÚNEL PARA LLEGAR A biblioentry Y
                   biblioref AUNQUE ESTÉN ANIDADOS. -->
              <xsl:when test="$lugar_bibliografia = 'por_capitulo'">
                <xsl:apply-templates select="$raizCapitulo" mode="prefijar-biblio">
                  <xsl:with-param name="prefijo-cap"
                                  select="string($raizCapitulo/@xml:id)"
                                  tunnel="yes"/>
                </xsl:apply-templates>
              </xsl:when>
              <!-- MODELO consolidada: COPIAR EL CAPÍTULO SIN SU
                   <bibliography> (LA BIBLIO VA EN UNA LISTA ÚNICA AL
                   FINAL DEL LIBRO). LOS biblioref QUEDAN APUNTANDO AL
                   CITEKEY BASE (SIN PREFIJO), QUE ES EL xml:id DE LA
                   ENTRADA CONSOLIDADA. -->
              <xsl:otherwise>
                <xsl:apply-templates select="$raizCapitulo" mode="sin-biblio"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">
              <xsl:text>ERROR: No se pudo cargar el canónico del capítulo en: </xsl:text>
              <xsl:value-of select="$capituloPath"/>
              <xsl:text>&#10;Verifique que btnGenerarDocBookcanonico se corrió sobre </xsl:text>
              <xsl:value-of select="@nombre_archivo"/>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>

      </xsl:for-each>

      <!-- ==========================================================
           BIBLIOGRAFÍA CONSOLIDADA (solo si lugar_bibliografia =
           'consolidada'): SE INSERTA EL <bibliography> ÚNICO QUE
           GENERÓ GenerarBiblioLibroXML (GAMBAS) EN tmp/biblio-libro-*.xml,
           CON TODAS LAS ENTRADAS DEL LIBRO YA DEDUPLICADAS Y ORDENADAS
           (DERIVADAS DEL .bib ÚNICO, UNIENDO referencias_citadas DE
           TODOS LOS CAPÍTULOS). LA NUMERACIÓN DEL DRAWER SALE CORRIDA
           POR LA POSICIÓN EN ESTA LISTA. LOS CAPÍTULOS YA SE COPIARON
           SIN SU <bibliography> (MODO sin-biblio).
           ========================================================== -->
      <xsl:if test="$lugar_bibliografia = 'consolidada'">
        <xsl:variable name="biblioLibroPath"
                      select="concat($proyecto_dir, '/', $biblio_libro)"/>
        <xsl:choose>
          <xsl:when test="$biblio_libro != '' and doc-available($biblioLibroPath)">
            <!-- INSERTAR EL <bibliography> DEL FRAGMENTO TAL CUAL -->
            <xsl:copy-of select="doc($biblioLibroPath)/*" copy-namespaces="no"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:message terminate="yes">
              <xsl:text>ERROR: bibliografía consolidada no disponible en: </xsl:text>
              <xsl:value-of select="$biblioLibroPath"/>
              <xsl:text>&#10;Verifique que GenerarBiblioLibroXML se ejecutó antes del ensamblado.</xsl:text>
            </xsl:message>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>

    </book>

  </xsl:template>

  <!-- ==========================================================
       MODO sin-biblio: COPIA IDENTIDAD QUE OMITE EL <bibliography>
       ==========================================================
       Solo se usa cuando lugar_bibliografia = 'consolidada'. Copia
       el capítulo entero SALVO su <bibliography> (que se consolida
       en una lista única al final del libro). Los biblioref quedan
       intactos, apuntando al citekey base. -->
  <xsl:template match="@* | node()" mode="sin-biblio">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="sin-biblio"/>
    </xsl:copy>
  </xsl:template>

  <!-- OMITIR EL <bibliography> DEL CAPÍTULO (NO SE COPIA) -->
  <xsl:template match="db:bibliography" mode="sin-biblio"/>

  <!-- ==========================================================
       MODO prefijar-biblio: COPIA IDENTIDAD QUE PREFIJA LOS IDs
       DE BIBLIOGRAFÍA CON EL xml:id DEL CAPÍTULO.
       ==========================================================
       Solo se usa cuando lugar_bibliografia = 'por_capitulo'.
       - biblioentry/@xml:id → prefijado con "{cap}-"
       - biblioref/@linkend  → prefijado igual (coordinado)
       El resto del árbol se copia sin cambios. El prefijo llega
       por parámetro de túnel desde la plantilla principal.
       RC-DB-08: copy-namespaces implícito controlado por xsl:copy. -->

  <!-- IDENTIDAD GENERAL: COPIAR CADA NODO Y SUS ATRIBUTOS -->
  <xsl:template match="@* | node()" mode="prefijar-biblio">
    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* | node()" mode="prefijar-biblio"/>
    </xsl:copy>
  </xsl:template>

  <!-- OVERRIDE: xml:id DE biblioentry → PREFIJAR CON EL CAPÍTULO -->
  <xsl:template match="db:biblioentry/@xml:id" mode="prefijar-biblio">
    <xsl:param name="prefijo-cap" tunnel="yes"/>
    <xsl:attribute name="xml:id">
      <xsl:value-of select="concat($prefijo-cap, '-', .)"/>
    </xsl:attribute>
  </xsl:template>

  <!-- OVERRIDE: linkend DE biblioref → PREFIJAR IGUAL (COORDINADO) -->
  <xsl:template match="db:biblioref/@linkend" mode="prefijar-biblio">
    <xsl:param name="prefijo-cap" tunnel="yes"/>
    <xsl:attribute name="linkend">
      <xsl:value-of select="concat($prefijo-cap, '-', .)"/>
    </xsl:attribute>
  </xsl:template>

</xsl:stylesheet>
