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
    <!-- @version VA EN LA RAÍZ, QUE ES DONDE DocBook LA ESPERA. LAS PIEZAS
         LA TRAEN EN SU PROPIA RAÍZ Y AL COPIARSE QUEDABA REDUNDANTE ADENTRO:
         SE LES QUITA EN LOS MODOS DE COPIA. -->
    <book version="5.2" xml:lang="{$idiomaPrincipal}">

      <!-- INSERTAR EL <info> DEL LIBRO, CON EL MODELO DE BIBLIOGRAFÍA
           INYECTADO COMO custom-meta.
           RC-XJ-02: EL DATO VIENE DE LA BASE Y NO DEL MANUSCRITO, ASÍ QUE SE
           ESCRIBE EN EL XML Y NO SE PASA COMO PARÁMETRO DE SAXON A LAS HOJAS
           DE SALIDA. ESTA HOJA SÍ LO RECIBE POR PARÁMETRO PORQUE ES LA QUE
           CONSTRUYE EL CANÓNICO; DE ACÁ EN ADELANTE VIAJA EN EL DOCUMENTO Y
           docbook-to-latex.xsl NO NECESITA SABER NADA DE LA LÍNEA DE COMANDOS. -->
      <xsl:choose>
        <xsl:when test="doc-available($infoLibroPath)">
          <info>
            <xsl:copy-of select="doc($infoLibroPath)/*/@*" copy-namespaces="no"/>
            <xsl:copy-of select="doc($infoLibroPath)/*/node()" copy-namespaces="no"/>
            <bibliomisc role="lugar-bibliografia">
              <xsl:value-of select="$lugar_bibliografia"/>
            </bibliomisc>
          </info>
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

        <!-- ==========================================================
             MARCADORES DE UBICACIÓN DE LA PIEZA
             ==========================================================
             seccion-libro Y orden-seccion SE DERIVAN DEL NOMBRE DE ARCHIVO,
             QUE ES DONDE VIVE ESE HECHO: LA CARPETA DA LA SECCIÓN Y EL NÚMERO
             DA EL ORDEN. HASTA AHORA ESO SE PERDÍA AL ENSAMBLAR Y EL CANÓNICO
             NO PODÍA DECIR SI UNA PIEZA ERA PRELIMINAR O POSLIMINAR: TODAS
             SALÍAN COMO <chapter> PLANOS.

             tipo-capitulo NO SE PUEDE DERIVAR DEL NOMBRE: SALE DE
             capitulos.tipo_capitulo Y TIENE QUE VENIR EN EL MANIFIESTO. SI
             FALTA, NO SE EMITE Y LAS HOJAS DE SALIDA CAEN AL CRITERIO DE
             CARPETA, QUE ES MÁS POBRE PERO NO ROMPE.
             ES EL DATO QUE DECIDE LA ZONA LaTeX, Y LA ZONA NO COINCIDE CON LA
             CARPETA: UNAS CONCLUSIONES VIVEN EN bm/ PERO VAN EN EL CUERPO,
             SIN NUMERAR, ANTES DE \appendix.
             ========================================================== -->
        <xsl:variable name="seccion" as="xs:string"
                      select="substring-before(@nombre_archivo, '-')"/>
        <xsl:variable name="orden" as="xs:string"
                      select="substring-before(substring-after(@nombre_archivo, '-'), '-')"/>
        <xsl:variable name="tipo" as="xs:string"
                      select="normalize-space(@tipo_capitulo)"/>

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
                  <xsl:with-param name="seccion" select="$seccion" tunnel="yes"/>
                  <xsl:with-param name="orden"   select="$orden"   tunnel="yes"/>
                  <xsl:with-param name="tipo"    select="$tipo"    tunnel="yes"/>
                </xsl:apply-templates>
              </xsl:when>
              <!-- MODELO consolidada: COPIAR EL CAPÍTULO SIN SU
                   <bibliography> (LA BIBLIO VA EN UNA LISTA ÚNICA AL
                   FINAL DEL LIBRO). LOS biblioref QUEDAN APUNTANDO AL
                   CITEKEY BASE (SIN PREFIJO), QUE ES EL xml:id DE LA
                   ENTRADA CONSOLIDADA. -->
              <xsl:otherwise>
                <xsl:apply-templates select="$raizCapitulo" mode="sin-biblio">
                  <xsl:with-param name="seccion" select="$seccion" tunnel="yes"/>
                  <xsl:with-param name="orden"   select="$orden"   tunnel="yes"/>
                  <xsl:with-param name="tipo"    select="$tipo"    tunnel="yes"/>
                </xsl:apply-templates>
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
            <!-- UNA <bibliography> CON SOLO EL <title> Y NINGUNA ENTRADA ES
                 INVÁLIDA EN DocBook 5.2: EL MODELO DE CONTENIDO EXIGE AL
                 MENOS UNA. Y EL DIAGNÓSTICO ES PÉSIMO, PORQUE RELAX NG NO
                 SEÑALA LA BIBLIOGRAFÍA SINO EL PRIMER ELEMENTO DESPUÉS DEL
                 <info>: "Element book has extra content: acknowledgements".
                 UNA BIBLIOGRAFÍA SIN ENTRADAS NO ES UNA BIBLIOGRAFÍA VACÍA:
                 ES UNA BIBLIOGRAFÍA QUE NO EXISTE. NO SE EMITE. -->
            <xsl:variable name="biblioDoc" select="doc($biblioLibroPath)/*"/>
            <xsl:choose>
              <xsl:when test="$biblioDoc/db:biblioentry
                              or $biblioDoc/db:bibliomixed
                              or $biblioDoc/db:bibliodiv">
                <xsl:copy-of select="$biblioDoc" copy-namespaces="no"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:message>
                  <xsl:text>AVISO: la bibliografía consolidada no tiene </xsl:text>
                  <xsl:text>entradas. No se emite el elemento, porque una </xsl:text>
                  <xsl:text>&lt;bibliography&gt; vacía invalida el canónico.</xsl:text>
                </xsl:message>
              </xsl:otherwise>
            </xsl:choose>
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
       RAÍZ DE LA PIEZA: INYECTAR LOS MARCADORES DE UBICACIÓN
       ==========================================================
       Vale para los dos modos de copia. Hace tres cosas:

       1. QUITA @version DE LA PIEZA. Cada canónico de capítulo la trae en su
          propia raíz, pero al copiarse dentro del <book> queda redundante:
          la versión de DocBook es del documento, no de cada pieza.

       2. INYECTA seccion-libro, orden-seccion y tipo-capitulo en el <info>.
          Si la pieza no tiene <info>, se crea.

       3. PRESERVA el resto del <info> tal como venía.

       SIN ESTOS MARCADORES EL CANÓNICO NO PUEDE DECIR SI UNA PIEZA ES
       PRELIMINAR, CUERPO O POSLIMINAR: TODAS SALEN COMO <chapter> PLANOS Y
       LAS TRES RAMAS DE SALIDA —LaTeX, HTML Y EPUB— TIENEN QUE ADIVINAR.
       ========================================================== -->
  <xsl:template match="*[not(parent::*)]" mode="prefijar-biblio sin-biblio">
    <xsl:param name="seccion" as="xs:string" tunnel="yes" select="''"/>
    <xsl:param name="orden"   as="xs:string" tunnel="yes" select="''"/>
    <xsl:param name="tipo"    as="xs:string" tunnel="yes" select="''"/>

    <xsl:copy copy-namespaces="no">
      <xsl:apply-templates select="@* except @version" mode="#current"/>

      <info>
        <xsl:apply-templates select="db:info/@* | db:info/node()" mode="#current"/>
        <xsl:if test="$seccion != ''">
          <bibliomisc role="seccion-libro">
            <xsl:value-of select="$seccion"/>
          </bibliomisc>
        </xsl:if>
        <xsl:if test="$orden != ''">
          <bibliomisc role="orden-seccion">
            <xsl:value-of select="$orden"/>
          </bibliomisc>
        </xsl:if>
        <xsl:if test="$tipo != ''">
          <bibliomisc role="tipo-capitulo">
            <xsl:value-of select="$tipo"/>
          </bibliomisc>
        </xsl:if>
      </info>

      <xsl:apply-templates select="node() except db:info" mode="#current"/>
    </xsl:copy>
  </xsl:template>

  <!-- ==========================================================
       BIBLIOGRAFÍA DE CAPÍTULO SIN ENTRADAS: NO SE EMITE
       ==========================================================
       Mismo motivo que la consolidada: DocBook 5.2 exige al menos una
       entrada, y una <bibliography> con solo el <title> invalida el
       canónico entero con un mensaje que señala el primer elemento
       después del <info>, no la bibliografía.
       En modo sin-biblio todas se omiten igual, así que esto solo
       aplica a por_capitulo. -->
  <xsl:template match="db:bibliography[not(db:biblioentry
                                           | db:bibliomixed
                                           | db:bibliodiv)]"
                mode="prefijar-biblio"/>

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
