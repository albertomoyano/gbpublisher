<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : numero-a-epub.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : EL ARMAZÓN DEL EPUB DEL NÚMERO (E3, DECISIONES DE
                   ALBERTO DEL 14/11/2026), DESDE EL VOLCADO:
                     - content.opf: METADATOS, MANIFIESTO Y RECORRIDO;
                     - nav.xhtml: LA TABLA DE CONTENIDOS DEL LECTOR, CON
                       LOS ARTÍCULOS AGRUPADOS POR SECCIÓN O DOSSIER, Y
                       LOS PUNTOS DE REFERENCIA (landmarks). NO VA EN EL
                       RECORRIDO, COMO EN LIBROS;
                     - LAS PRELIMINARES QUE EL NÚMERO DECLARA (DECISIÓN
                       DE ALBERTO: LAS MISMAS QUE EL PDF), EN EL ORDEN DE
                       SU NOMBRE: TAPA, PÁGINA LEGAL Y SUMARIO. EL SUMARIO
                       ES UNA PÁGINA PROPIA, SIN FOLIOS, CON CADA
                       ARTÍCULO ENLAZADO.
                   LOS ARTÍCULOS LOS ESCRIBE jats-a-epub-articulo.xsl
                   (chapters/{archivo}.xhtml): ESTA HOJA SOLO LOS DECLARA.
  POR QUÉ UNA XSLT Y NO GAMBAS (DECISIÓN DE ALBERTO, 14/11): EN LIBROS
                   ESTAS PÁGINAS LAS ESCRIBE m_GenerarEpubLibro. EN
                   REVISTAS EL PDF YA LAS ARMA DESDE EL VOLCADO
                   (numero-maestro-latex.xsl), Y EL AGRUPAMIENTO DEL
                   SUMARIO, LA CONJUNCIÓN Y LA PERSONA SON LOS MISMOS
                   (revista-comun.xsl): ESCRITOS DOS VECES PODÍAN
                   DIVERGIR. LA FRONTERA CON LA BASE NO CAMBIA: GAMBAS
                   ESCRIBE EL VOLCADO Y EL SCRIPT NO TOCA LA BASE.
  LAS IMÁGENES   : LAS QUE USAN LOS ARTÍCULOS (fig/graphic DE CADA
                   CANÓNICO) Y LA DE LA TAPA SI EL NÚMERO LA DECLARA, SIN
                   REPETIR (EL CRITERIO DE SC-76). EL MANIFIESTO ES LA
                   ÚNICA LISTA: generar_epub_revista.sh COPIA EXACTAMENTE
                   LAS QUE DECLARA EN images/.
  ENTRADA        : {proyecto}/tmp/numero-datos.xml (VOLCADO 4)
  SALIDA         : -o:{OEBPS}/content.opf; Y, AL LADO, nav.xhtml Y
                   chapters/{pieza}.xhtml (xsl:result-document)
  PARÁMETROS     : dir_canonicos  RUTA ABSOLUTA DE LA CARPETA CON LOS
                                  CANÓNICOS SIN DOCTYPE (c-{archivo}.xml):
                                  SAXON NO BAJA LA DTD (GV-25). REQUERIDO
                   modificado     dcterms:modified (AAAA-MM-DDThh:mm:ssZ).
                                  LO PASA EL SCRIPT; VACÍO, LA HORA ACTUAL
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns:gbrc="urn:gbpublisher:revista-comun"
  xmlns:gbn="urn:gbpublisher:numero-epub"
  exclude-result-prefixes="xs xlink epub gbrc gbn">

  <!-- LA CONJUNCIÓN, LA PERSONA, LOS TRAMOS DEL SUMARIO, LA
       IDENTIFICACIÓN DEL NÚMERO Y LOS RÓTULOS: LOS MISMOS QUE EL PDF -->
  <xsl:include href="revista-comun.xsl"/>

  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
  <xsl:output name="xhtml" method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="no"/>

  <xsl:param name="dir_canonicos" as="xs:string" required="yes"/>
  <xsl:param name="modificado" as="xs:string" select="''"/>

  <!-- LA VERSIÓN DEL VOLCADO QUE ESTA HOJA SABE LEER -->
  <xsl:variable name="gbn:version-datos" select="'4'"/>

  <!-- NOMBRES FIJOS DEL PAQUETE. DEBEN COINCIDIR CON generar_epub_revista.sh
       (FUENTES, CSS_EPUB) Y CON EL PARÁMETRO css DE jats-a-epub-articulo.xsl:
       SI DIVERGEN, LA VERIFICACIÓN DEL OPF DEL SCRIPT LO ATRAPA -->
  <xsl:variable name="gbn:css" select="'css/gbpublisher-epub-revista.css'"/>
  <xsl:variable name="gbn:fuentes" select="('NotoSerif-Regular.ttf', 'NotoSerif-Bold.ttf',
                                            'NotoSerif-Italic.ttf', 'NotoSerif-BoldItalic.ttf')"/>

  <xsl:variable name="d" select="/numero-datos"/>
  <xsl:variable name="principal" as="xs:string?"
    select="(tokenize(string($d/revista/idiomas), ',') ! normalize-space(.)[. ne ''])[1]"/>
  <xsl:variable name="lang" select="gbrc:lang(string($principal))"/>
  <xsl:variable name="piezas" as="element()*">
    <xsl:perform-sort select="$d/preliminares/pieza">
      <xsl:sort select="@archivo"/>
    </xsl:perform-sort>
  </xsl:variable>
  <xsl:variable name="tapa" select="if ($piezas[@tipo eq 'tapa']) then normalize-space($d/numero/imagen-tapa) else ''"/>
  <xsl:variable name="hay-sumario" select="exists($piezas[@tipo eq 'sumario'])"/>

  <!-- LAS IMÁGENES DE LOS ARTÍCULOS, SIN REPETIR, EN ORDEN DE APARICIÓN.
       EL NOMBRE ES EL ÚLTIMO TRAMO DEL href: EL MISMO QUE ESCRIBE LA
       PLANTILLA fig DE jats-to-epub.xsl (../images/{nombre}) -->
  <xsl:variable name="imagenes-articulos" as="xs:string*" select="distinct-values(
    for $a in $d/articulo
    return doc(gbn:uri-archivo(concat($dir_canonicos, '/c-', $a/@archivo, '.xml')))//fig/graphic/@xlink:href
           ! tokenize(normalize-space(.), '/')[last()][. ne ''])"/>
  <!-- LOS ARTÍCULOS CON FÓRMULAS (SC-110): SU XHTML LLEVA MathML Y EL
       OPF TIENE QUE DECLARARLO CON properties="mathml"; SIN ESO,
       epubcheck DA OPF-014. SE MIRA EL CANÓNICO, COMO LAS IMÁGENES:
       jats-a-epub-articulo.xsl ESCRIBE UN <math> POR CADA FÓRMULA -->
  <xsl:variable name="articulos-con-formulas" as="xs:string*" select="
    for $a in $d/articulo
    return string($a/@archivo)[exists(doc(gbn:uri-archivo(concat($dir_canonicos, '/c-', $a/@archivo, '.xml')))
                                      //(inline-formula | disp-formula))]"/>

  <!-- LA TAPA VA PRIMERO: ES LA cover-image -->
  <xsl:variable name="imagenes" as="xs:string*" select="distinct-values(($tapa[. ne ''], $imagenes-articulos))"/>

  <!-- ============================================
       Función   : gbn:uri-archivo
       Propósito : Una ruta absoluta de Unix como URI file:. iri-to-uri
                   escapa los espacios y lo que no es ASCII: una carpeta de
                   proyecto con tildes no rompe doc(). La misma receta que
                   gbc:uri-carpeta (codigo-comun.xsl), para un archivo
       Parámetros: ruta As xs:string — absoluta
       Retorna   : xs:string — el URI
       ============================================ -->
  <xsl:function name="gbn:uri-archivo" as="xs:string">
    <xsl:param name="ruta" as="xs:string"/>
    <xsl:sequence select="iri-to-uri(concat('file://', $ruta))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbn:tipo-imagen
       Propósito : El media-type de una imagen por su extensión; vacío
                   si el EPUB no la admite (los de EsImagenEpub de libros)
       Parámetros: nombre As xs:string
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbn:tipo-imagen" as="xs:string">
    <xsl:param name="nombre" as="xs:string"/>
    <xsl:variable name="ext" select="lower-case(tokenize($nombre, '\.')[last()])"/>
    <xsl:sequence select="if ($ext = ('jpg', 'jpeg')) then 'image/jpeg'
      else if ($ext eq 'png') then 'image/png'
      else if ($ext eq 'gif') then 'image/gif'
      else if ($ext eq 'svg') then 'image/svg+xml'
      else if ($ext eq 'webp') then 'image/webp'
      else ''"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbn:titulo
       Propósito : Un título del volcado en una línea: el corte del
                   editor (SC-28) es un espacio
       Parámetros: t As element()? — titulo, titulo-especial
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbn:titulo" as="xs:string">
    <xsl:param name="t" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join(
      for $n in $t/node() return (if ($n/self::break) then ' ' else string($n)), ''))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbn:href-pieza
       Propósito : La ruta de una preliminar desde la raíz de OEBPS
       Parámetros: p As element() — <pieza>
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbn:href-pieza" as="xs:string">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="concat('chapters/', $p/@archivo, '.xhtml')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbn:rotulo-pieza
       Propósito : El nombre de una preliminar, para el nav y su <title>
       Parámetros: p As element() — <pieza>
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbn:rotulo-pieza" as="xs:string">
    <xsl:param name="p" as="element()"/>
    <xsl:sequence select="gbrc:rotulo(if ($p/@tipo eq 'legales') then 'legal' else string($p/@tipo), $lang)"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: /                                                 -->
  <!-- VALIDA, ESCRIBE LAS PÁGINAS Y EL nav, Y DEVUELVE EL OPF      -->
  <!-- ============================================================ -->
  <xsl:template match="/">

    <!-- APARTADO 1. VALIDACIÓN: LO QUE FALTA FRENA ACÁ, CON UN MENSAJE.
         LAS MISMAS CONDICIONES QUE EL MAESTRO DEL PDF -->
    <xsl:if test="string($d/@version) ne $gbn:version-datos">
      <xsl:message terminate="yes">ERROR: el volcado es versión «<xsl:value-of select="$d/@version"/>» y esta hoja lee la <xsl:value-of select="$gbn:version-datos"/>: actualizá gbpublisher</xsl:message>
    </xsl:if>
    <xsl:if test="empty($principal)">
      <xsl:message terminate="yes">ERROR: la revista no tiene idiomas de publicación. Cargalos en la ficha de la revista.</xsl:message>
    </xsl:if>
    <xsl:if test="empty($d/articulo)">
      <xsl:message terminate="yes">ERROR: el número no tiene artículos con metadatos</xsl:message>
    </xsl:if>
    <xsl:if test="$piezas[@tipo eq 'tapa'] and $tapa eq ''">
      <xsl:message terminate="yes">ERROR: el número declara la tapa y no tiene imagen. Elegila en los metadatos del número.</xsl:message>
    </xsl:if>
    <xsl:if test="$piezas[@tipo eq 'legales'] and empty($d/pagina-legal)">
      <xsl:message terminate="yes">ERROR: el número declara la página legal y el volcado no la trae (¿falta el año del número?)</xsl:message>
    </xsl:if>
    <!-- UNA IMAGEN QUE EL EPUB NO ADMITE DEJARÍA EL PAQUETE INVÁLIDO -->
    <xsl:for-each select="$imagenes[gbn:tipo-imagen(.) eq '']">
      <xsl:message terminate="yes">ERROR: el EPUB no admite el formato de la imagen «<xsl:value-of select="."/>» (jpg, png, gif, svg o webp)</xsl:message>
    </xsl:for-each>

    <!-- APARTADO 2. LAS PRELIMINARES QUE EL NÚMERO DECLARA -->
    <xsl:for-each select="$piezas">
      <xsl:result-document href="{gbn:href-pieza(.)}" format="xhtml">
        <xsl:call-template name="gbn:pagina">
          <xsl:with-param name="titulo" select="gbn:rotulo-pieza(.)"/>
          <xsl:with-param name="css" select="concat('../', $gbn:css)"/>
          <xsl:with-param name="contenido">
            <xsl:choose>
              <xsl:when test="@tipo eq 'tapa'"><xsl:call-template name="gbn:tapa"/></xsl:when>
              <xsl:when test="@tipo eq 'legales'"><xsl:call-template name="gbn:legales"/></xsl:when>
              <xsl:when test="@tipo eq 'sumario'"><xsl:call-template name="gbn:sumario"/></xsl:when>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:result-document>
    </xsl:for-each>

    <!-- APARTADO 3. EL nav -->
    <xsl:result-document href="nav.xhtml" format="xhtml">
      <xsl:call-template name="gbn:pagina">
        <xsl:with-param name="titulo" select="gbrc:rotulo('sumario', $lang)"/>
        <xsl:with-param name="css" select="$gbn:css"/>
        <xsl:with-param name="contenido">
          <xsl:call-template name="gbn:nav"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:result-document>

    <!-- APARTADO 4. EL OPF, A LA SALIDA PRINCIPAL -->
    <xsl:call-template name="gbn:opf"/>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:pagina
       Propósito : El documento XHTML de una página del paquete
       Parámetros: titulo As xs:string — su <title>
                   css As xs:string — la hoja, relativa a la página
                   contenido — el cuerpo
       ============================================ -->
  <xsl:template name="gbn:pagina">
    <xsl:param name="titulo" as="xs:string"/>
    <xsl:param name="css" as="xs:string"/>
    <xsl:param name="contenido"/>
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"
          lang="{$principal}" xml:lang="{$principal}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="$titulo"/></title>
        <link rel="stylesheet" type="text/css" href="{$css}"/>
      </head>
      <body>
        <xsl:copy-of select="$contenido"/>
      </body>
    </html>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:tapa
       Propósito : La tapa: la imagen del número a pantalla completa
                   (\gbtapanumero del PDF)
       ============================================ -->
  <xsl:template name="gbn:tapa">
    <section xmlns="http://www.w3.org/1999/xhtml" epub:type="cover" class="tapa">
      <img class="tapa-img" src="../images/{$tapa}"
           alt="{string-join((normalize-space($d/revista/titulo), gbrc:identificacion($d, $lang))[. ne ''], ', ')}"/>
    </section>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:legales
       Propósito : La página legal, con los datos y en el orden del
                   maestro del PDF (gbm:legales; contrato de revista 4,
                   5.5). El volcado ya viene filtrado a la fecha de
                   referencia: esta hoja no decide quién está vigente
       ============================================ -->
  <xsl:template name="gbn:legales">
    <xsl:variable name="pl" select="$d/pagina-legal"/>
    <xsl:variable name="ed" select="$pl/editorial"/>
    <section xmlns="http://www.w3.org/1999/xhtml" epub:type="copyright-page" class="legal">

      <!-- APARTADO 1. LA REVISTA Y EL NÚMERO (\gblegalrevista) -->
      <div class="legal-bloque">
        <p class="legal-revista"><xsl:value-of select="normalize-space($d/revista/titulo)"/></p>
        <p><xsl:value-of select="gbrc:identificacion($d, $lang)"/></p>
        <xsl:if test="gbn:titulo($d/numero/titulo-especial) ne ''">
          <p class="legal-especial"><xsl:value-of select="gbn:titulo($d/numero/titulo-especial)"/></p>
        </xsl:if>
      </div>

      <!-- APARTADO 2. LA EDITORIAL Y SUS CRÉDITOS: LOS DEL MISMO CARGO
           JUNTOS, EN EL ORDEN EN QUE APARECE EL CARGO -->
      <xsl:if test="$ed">
        <div class="legal-bloque">
          <p class="legal-editorial"><xsl:value-of select="normalize-space($ed/nombre)"/></p>
          <xsl:if test="normalize-space($ed/institucion) ne ''">
            <p><xsl:value-of select="normalize-space($ed/institucion)"/></p>
          </xsl:if>
          <xsl:for-each-group select="$ed/credito" group-by="normalize-space(@cargo)">
            <p>
              <span class="legal-rotulo"><xsl:value-of select="current-grouping-key()"/>:</span>
              <xsl:text> </xsl:text>
              <xsl:value-of select="gbrc:lista(current-group() ! normalize-space(.), $principal)"/>
            </p>
          </xsl:for-each-group>
        </div>
      </xsl:if>

      <!-- APARTADO 3. LOS ÓRGANOS: UNO DE UN SOLO MIEMBRO EN LÍNEA; CON
           VARIOS, UNO POR RENGLÓN (\gblegalorgano) -->
      <xsl:for-each select="$pl/organo">
        <div class="legal-bloque">
          <xsl:choose>
            <xsl:when test="count(miembro) eq 1">
              <p>
                <span class="legal-rotulo"><xsl:value-of select="normalize-space(@nombre)"/>:</span>
                <xsl:text> </xsl:text>
                <xsl:value-of select="string-join((gbrc:persona(miembro), normalize-space(miembro/afiliacion))[. ne ''], ', ')"/>
              </p>
            </xsl:when>
            <xsl:otherwise>
              <p class="legal-rotulo"><xsl:value-of select="normalize-space(@nombre)"/></p>
              <xsl:for-each select="miembro">
                <p class="legal-miembro">
                  <xsl:value-of select="gbrc:persona(.)"/>
                  <xsl:if test="normalize-space(afiliacion) ne ''">
                    <xsl:value-of select="concat(' (', normalize-space(afiliacion), ')')"/>
                  </xsl:if>
                </p>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </xsl:for-each>

      <!-- APARTADO 4. ISSN, DIRECCIÓN, PORTAL Y CORREO (\gblegalbloque) -->
      <div class="legal-bloque">
        <xsl:for-each select="$d/revista/issn[normalize-space(.) ne '']">
          <p>
            <xsl:value-of select="gbrc:rotulo(if (@tipo eq 'impreso') then 'issn' else 'eissn', $lang)"/>
            <xsl:text>: </xsl:text>
            <xsl:value-of select="normalize-space(.)"/>
          </p>
        </xsl:for-each>
        <xsl:if test="$ed">
          <!-- LA DIRECCIÓN EN UN RENGLÓN: CALLE, CIUDAD, REGIÓN, PAÍS -->
          <xsl:variable name="lugar" select="($ed/direccion, $ed/ciudad, $ed/region, $ed/pais) ! normalize-space(.)[. ne '']"/>
          <xsl:if test="exists($lugar)">
            <p class="legal-direccion"><xsl:value-of select="string-join($lugar, ', ')"/></p>
          </xsl:if>
          <xsl:if test="normalize-space($ed/url-portal) ne ''">
            <p><a href="{normalize-space($ed/url-portal)}"><xsl:value-of select="normalize-space($ed/url-portal)"/></a></p>
          </xsl:if>
          <!-- EL CORREO: EL DE LA REVISTA SI LO TIENE, SI NO EL DE LA EDITORIAL -->
          <xsl:variable name="correo" select="normalize-space(($d/revista/email, $ed/email)[normalize-space(.) ne ''][1])"/>
          <xsl:if test="$correo ne ''">
            <p><a href="mailto:{$correo}"><xsl:value-of select="$correo"/></a></p>
          </xsl:if>
        </xsl:if>
      </div>

      <!-- APARTADO 5. LEYENDA Y AVISO -->
      <xsl:if test="normalize-space($ed/leyenda-distribucion) ne ''">
        <p class="legal-bloque"><xsl:value-of select="normalize-space($ed/leyenda-distribucion)"/></p>
      </xsl:if>
      <xsl:if test="normalize-space($ed/aviso-responsabilidad) ne ''">
        <p class="legal-bloque legal-aviso"><xsl:value-of select="normalize-space($ed/aviso-responsabilidad)"/></p>
      </xsl:if>
    </section>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:sumario
       Propósito : El sumario (decisión de Alberto: página propia, sin
                   folios): los artículos en el orden del número, con el
                   encabezado del tramo cada vez que cambia, como el PDF
                   (gbm:sumario)
       ============================================ -->
  <xsl:template name="gbn:sumario">
    <section xmlns="http://www.w3.org/1999/xhtml" class="sumario">
      <h1 class="sumario-titulo"><xsl:value-of select="gbrc:rotulo('sumario', $lang)"/></h1>
      <p class="sumario-numero"><xsl:value-of select="gbrc:identificacion($d, $lang)"/></p>
      <xsl:for-each-group select="$d/articulo" group-adjacent="gbrc:tramo-sumario(.)">
        <xsl:variable name="encabezado" select="gbrc:encabezado-tramo($d, current-group()[1], $principal)"/>
        <xsl:if test="$encabezado ne ''">
          <h2 class="sumario-seccion"><xsl:value-of select="$encabezado"/></h2>
        </xsl:if>
        <xsl:for-each select="current-group()">
          <xsl:variable name="autores" select="gbrc:lista(contribuyente[@rol eq 'autor'] ! gbrc:persona(.), $principal)"/>
          <div class="sumario-articulo">
            <p class="sumario-art-titulo" lang="{@idioma}" xml:lang="{@idioma}">
              <a href="{@archivo}.xhtml"><xsl:value-of select="gbn:titulo(titulo)"/></a>
            </p>
            <xsl:if test="$autores ne ''">
              <p class="sumario-autores"><xsl:value-of select="$autores"/></p>
            </xsl:if>
          </div>
        </xsl:for-each>
      </xsl:for-each-group>
    </section>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:nav
       Propósito : La tabla de contenidos del lector: la página legal y
                   el sumario, y los artículos agrupados por tramo. Los
                   puntos de referencia: tapa, sumario y comienzo del
                   texto
       ============================================ -->
  <xsl:template name="gbn:nav">
    <nav xmlns="http://www.w3.org/1999/xhtml" epub:type="toc" id="toc">
      <h1><xsl:value-of select="gbrc:rotulo('sumario', $lang)"/></h1>
      <ol>
        <!-- LA TAPA NO VA: ES LA PRIMERA PÁGINA DEL RECORRIDO -->
        <xsl:for-each select="$piezas[@tipo ne 'tapa']">
          <li><a href="{gbn:href-pieza(.)}"><xsl:value-of select="gbn:rotulo-pieza(.)"/></a></li>
        </xsl:for-each>
        <xsl:for-each-group select="$d/articulo" group-adjacent="gbrc:tramo-sumario(.)">
          <xsl:variable name="encabezado" select="gbrc:encabezado-tramo($d, current-group()[1], $principal)"/>
          <xsl:choose>
            <!-- CON ENCABEZADO: EL TRAMO ES UN NIVEL, SIN DESTINO PROPIO -->
            <xsl:when test="$encabezado ne ''">
              <li>
                <span><xsl:value-of select="$encabezado"/></span>
                <ol>
                  <xsl:for-each select="current-group()">
                    <xsl:call-template name="gbn:item-nav"/>
                  </xsl:for-each>
                </ol>
              </li>
            </xsl:when>
            <xsl:otherwise>
              <xsl:for-each select="current-group()">
                <xsl:call-template name="gbn:item-nav"/>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </ol>
    </nav>
    <nav xmlns="http://www.w3.org/1999/xhtml" epub:type="landmarks" id="landmarks" hidden="hidden">
      <ol>
        <xsl:for-each select="$piezas[@tipo eq 'tapa']">
          <li><a epub:type="cover" href="{gbn:href-pieza(.)}"><xsl:value-of select="gbn:rotulo-pieza(.)"/></a></li>
        </xsl:for-each>
        <xsl:for-each select="$piezas[@tipo eq 'sumario']">
          <li><a epub:type="toc" href="{gbn:href-pieza(.)}"><xsl:value-of select="gbn:rotulo-pieza(.)"/></a></li>
        </xsl:for-each>
        <li>
          <a epub:type="bodymatter" href="chapters/{$d/articulo[1]/@archivo}.xhtml">
            <xsl:value-of select="gbn:titulo($d/articulo[1]/titulo)"/>
          </a>
        </li>
      </ol>
    </nav>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:item-nav
       Propósito : Un artículo en el nav
       Contexto  : <articulo> del volcado
       ============================================ -->
  <xsl:template name="gbn:item-nav">
    <li xmlns="http://www.w3.org/1999/xhtml">
      <a href="chapters/{@archivo}.xhtml" lang="{@idioma}" xml:lang="{@idioma}">
        <xsl:value-of select="gbn:titulo(titulo)"/>
      </a>
    </li>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbn:opf
       Propósito : content.opf: metadatos, manifiesto y recorrido
       ============================================ -->
  <xsl:template name="gbn:opf">
    <xsl:variable name="ahora" select="adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration('PT0H'))"/>
    <xsl:variable name="mes" select="normalize-space($d/numero/@mes)"/>
    <xsl:variable name="anio" select="normalize-space($d/numero/@anio)"/>
    <!-- LOS OTROS IDIOMAS DE LOS ARTÍCULOS, DESPUÉS DEL PRINCIPAL -->
    <xsl:variable name="idiomas" select="distinct-values(($principal, $d/articulo/@idioma ! normalize-space(.)[. ne '']))"/>

    <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="{$principal}">

      <!-- APARTADO 1. METADATOS -->
      <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
        <!-- UN URN PROPIO, COMO EL DE LIBROS SIN ISBN NI DOI: EL ISSN ES
             DE LA REVISTA, NO DEL NÚMERO -->
        <dc:identifier id="pub-id"><xsl:value-of select="concat('urn:gbpublisher:numero-', $d/numero/@id)"/></dc:identifier>
        <dc:title>
          <xsl:value-of select="string-join((normalize-space($d/revista/titulo), gbrc:identificacion($d, $lang))[. ne ''], ', ')"/>
        </dc:title>
        <xsl:for-each select="$idiomas">
          <dc:language><xsl:value-of select="."/></dc:language>
        </xsl:for-each>
        <xsl:variable name="editorial" select="normalize-space(($d/pagina-legal/editorial/nombre, $d/revista/editorial)[normalize-space(.) ne ''][1])"/>
        <xsl:if test="$editorial ne ''">
          <dc:publisher><xsl:value-of select="$editorial"/></dc:publisher>
        </xsl:if>
        <!-- W3CDTF: AÑO, O AÑO Y MES -->
        <xsl:if test="$anio ne ''">
          <dc:date>
            <xsl:value-of select="if ($mes castable as xs:integer and xs:integer($mes) = 1 to 12)
              then concat($anio, '-', format-number(xs:integer($mes), '00')) else $anio"/>
          </dc:date>
        </xsl:if>
        <meta property="dcterms:modified">
          <xsl:value-of select="if (normalize-space($modificado) ne '') then normalize-space($modificado)
            else format-dateTime($ahora, '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z')"/>
        </meta>
        <xsl:if test="$tapa ne ''">
          <meta name="cover" content="cover-image"/>
        </xsl:if>
      </metadata>

      <!-- APARTADO 2. MANIFIESTO -->
      <manifest>
        <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
        <item id="css" href="{$gbn:css}" media-type="text/css"/>
        <xsl:for-each select="$gbn:fuentes">
          <item id="font-{lower-case(substring-before(., '.ttf'))}" href="fonts/{.}" media-type="font/ttf"/>
        </xsl:for-each>
        <!-- EL id DE CADA IMAGEN ES SU POSICIÓN: UN NOMBRE DE ARCHIVO NO
             SIEMPRE ES UN NCName -->
        <xsl:for-each select="$imagenes">
          <xsl:choose>
            <xsl:when test=". eq $tapa">
              <item id="cover-image" href="images/{.}" media-type="{gbn:tipo-imagen(.)}" properties="cover-image"/>
            </xsl:when>
            <xsl:otherwise>
              <item id="img-{position()}" href="images/{.}" media-type="{gbn:tipo-imagen(.)}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="$piezas">
          <item id="{@archivo}" href="{gbn:href-pieza(.)}" media-type="application/xhtml+xml"/>
        </xsl:for-each>
        <xsl:for-each select="$d/articulo">
          <item id="{@archivo}" href="chapters/{@archivo}.xhtml" media-type="application/xhtml+xml">
            <!-- EL ARTÍCULO CON FÓRMULAS: MathML (SC-110) -->
            <xsl:if test="string(@archivo) = $articulos-con-formulas">
              <xsl:attribute name="properties">mathml</xsl:attribute>
            </xsl:if>
          </item>
        </xsl:for-each>
      </manifest>

      <!-- APARTADO 3. RECORRIDO: LAS PRELIMINARES Y LOS ARTÍCULOS, EN EL
           ORDEN DEL NÚMERO. EL nav NO VA: LO MUESTRA EL LECTOR -->
      <spine>
        <xsl:for-each select="$piezas, $d/articulo">
          <itemref idref="{@archivo}"/>
        </xsl:for-each>
      </spine>
    </package>
  </xsl:template>

</xsl:stylesheet>
