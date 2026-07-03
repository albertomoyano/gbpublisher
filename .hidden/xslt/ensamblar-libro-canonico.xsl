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
            <!-- COPIAR EL NODO RAÍZ TAL CUAL (chapter/preface/bibliography/etc.) -->
            <!-- EL XSLT DE CAPÍTULO YA EMITIÓ EL ELEMENTO RAÍZ CORRECTO -->
            <!-- SEGÚN tipo_capitulo, ACÁ SOLO SE CONCATENA AL <book>       -->
            <xsl:copy-of select="doc($capituloPath)/*"
                         copy-namespaces="no"/>
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

    </book>

  </xsl:template>

</xsl:stylesheet>
