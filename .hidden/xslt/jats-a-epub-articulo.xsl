<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : jats-a-epub-articulo.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : EL XHTML DE UN ARTÍCULO PARA EL EPUB DEL NÚMERO (E2,
                   DECISIONES DE ALBERTO DEL 14/11/2026). IMPORTA
                   jats-to-epub.xsl Y USA SU CUERPO (SECCIONES, FIGURAS,
                   CUADROS, LISTAS, CÓDIGO, VERSO, CONVERSACIÓN, MARCAS
                   EN LÍNEA: LA MATRIZ DE SC-30). REEMPLAZA LO QUE LA HOJA
                   VIEJA ARMABA PARA EL FRONT VIEJO, COMO
                   jats-a-latex-articulo.xsl HIZO CON EL PDF:
                     - LA CABECERA: TIPO, TÍTULO, SUBTÍTULO, TÍTULOS
                       TRADUCIDOS;
                     - LOS RESÚMENES CON SUS PALABRAS CLAVE;
                     - EL BLOQUE DE DATOS DESPUÉS DEL RESUMEN (DECISIÓN DE
                       ALBERTO): LO QUE EL PDF PONE EN LA COLUMNA, EN SU
                       ORDEN, SIN «COMPARTIR»;
                     - LAS DECLARACIONES AL FINAL, COMO EN EL PDF;
                     - LAS NOTAS: SOLO LAS DEL TEXTO (LAS DE author-notes
                       VAN EN EL BLOQUE DE DATOS O EN LAS DECLARACIONES);
                     - LAS CITAS, LAS REFERENCIAS Y EL «CÓMO CITAR»:
                       DESDE citas.html (SC-57, E1), CON EL MISMO TEXTO
                       QUE EL PDF.
  POR QUÉ IMPORTA: m_GenerarEpub (EL CAMINO VIEJO, HASTA SU RETIRO) SIGUE
                   USANDO jats-to-epub.xsl: CAMBIARLA ROMPÍA EL CAMINO
                   VIEJO.
  REFERENCIA     : SC-31: EL PDF. LOS RÓTULOS, LOS TIPOS, LAS FECHAS Y LOS
                   NOMBRES SALEN DE revista-comun.xsl, COMO EN EL PDF; EL
                   AGRUPAMIENTO DE LAS CITAS, DE cita-jats-comun.xsl.
  ENTRADA        : {proyecto}/jats/c-{archivo}.xml (CANÓNICO)
  SALIDA         : chapters/{archivo}.xhtml DEL PAQUETE (LO DECIDE E3)
  PARÁMETROS     : archivo   EL ARCHIVO DEL ARTÍCULO (a-01-…): PREFIJO DE
                             LOS id DE CITA Y MARCA DE SU BIBLIOGRAFÍA
                   bib_dir   LA CARPETA DE LA PASADA DE CITAS
                             (preparar_citas_revista.sh), RUTA ABSOLUTA.
                             OBLIGATORIA: SIN ELLA NO HAY CITAS
                   estilo_cita  EL ESTILO DE LA REVISTA (EL DEL VOLCADO):
                             DECIDE SI LA BIBLIOGRAFÍA LLEVA [n]
                   css       LA HOJA DE ESTILOS, RELATIVA AL XHTML
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:ali="http://www.niso.org/schemas/ali/1.0/"
  xmlns:epub="http://www.idpf.org/2007/ops"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:gbc="urn:gbpublisher:codigo"
  xmlns:gbct="urn:gbpublisher:citas"
  xmlns:gbcj="urn:gbpublisher:citas-jats"
  xmlns:gbrc="urn:gbpublisher:revista-comun"
  xmlns:gbfj="urn:gbpublisher:formula-jats"
  xmlns:gbe="urn:gbpublisher:revista-epub"
  exclude-result-prefixes="xs xlink ali gbc gbct gbcj gbrc gbe gbfj">

  <!-- EL CUERPO ES EL DE LA HOJA VIEJA. xsl:import VA PRIMERO; LO QUE
       ESTA HOJA DEFINE GANA POR PRECEDENCIA DE IMPORTACIÓN -->
  <xsl:import href="jats-to-epub.xsl"/>

  <!-- EL AGRUPAMIENTO DE CITAS: EL MISMO QUE EL PDF Y LA PASADA -->
  <xsl:include href="cita-jats-comun.xsl"/>
  <!-- RÓTULOS, TIPOS, FECHAS, NOMBRES: LOS DEL PDF -->
  <xsl:include href="revista-comun.xsl"/>
  <!-- gbct:clave Y gbct:estilo-numerico (COMUNES CON LIBROS) Y LA LECTURA
       DE citas.html -->
  <xsl:include href="cita-comun.xsl"/>
  <xsl:include href="cita-fragmentos.xsl"/>

  <!-- LAS FÓRMULAS COMO MathML (SC-110): GANAN A LAS DE LA HOJA VIEJA,
       QUE ESCRIBÍAN EL TeX COMO CÓDIGO -->
  <xsl:include href="formula-jats-comun.xsl"/>

  <!-- EL ESPACIO DE NOMBRES DE LOS span QUE ARMA formula-jats-comun.xsl:
       XHTML, COMO TODO EL EPUB -->
  <xsl:variable name="gbfj:ns-html" as="xs:string" select="'http://www.w3.org/1999/xhtml'"/>

  <xsl:output method="xml" encoding="UTF-8" indent="no" omit-xml-declaration="no"/>

  <xsl:param name="archivo" as="xs:string" select="''"/>
  <xsl:param name="css" as="xs:string" select="'../css/gbpublisher-epub-revista.css'"/>

  <!-- EL IDIOMA DEL ARTÍCULO (EL DEL CANÓNICO) Y EL DE SUS RÓTULOS -->
  <xsl:variable name="gbe:xml-lang" as="xs:string"
    select="(normalize-space(/article/@xml:lang)[. ne ''], 'es')[1]"/>
  <xsl:variable name="gbe:lang" as="xs:string" select="gbrc:lang($gbe:xml-lang)"/>

  <!-- ============================================
       Función   : gbe:rotulo
       Propósito : El rótulo de una clave en el idioma del artículo
       Parámetros: clave As xs:string — la @k de revista-comun.xsl
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbe:rotulo" as="xs:string">
    <xsl:param name="clave" as="xs:string"/>
    <xsl:sequence select="gbrc:rotulo($clave, $gbe:lang)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbe:en-idioma
       Propósito : ¿El elemento está en el idioma del artículo? Sin
                   xml:lang, sí: el canónico solo lo pone en los otros
       Parámetros: e As element()
       Retorna   : xs:boolean
       ============================================ -->
  <xsl:function name="gbe:en-idioma" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="normalize-space($e/@xml:lang) = ('', $gbe:xml-lang)"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbe:marca
       Propósito : Un elemento de citas.html por su id (gbcita-… o
                   gbbib-…); si falta, corta (GV-23): el canónico cambió
                   después de la pasada de citas
       Parámetros: id As xs:string — el id completo
       Retorna   : element()
       ============================================ -->
  <xsl:function name="gbe:marca" as="element()">
    <xsl:param name="id" as="xs:string"/>
    <xsl:variable name="e" select="key('gbct:por-id', $id, $gbct:citas)"/>
    <xsl:sequence select="if (count($e) = 1) then $e
      else error(QName('urn:gbpublisher:revista-epub', 'sin-marca'),
                 concat('[epub] citas.html no tiene ', $id,
                        ': el canónico cambió después de la pasada de citas.'))"/>
  </xsl:function>

  <!-- ============================================
       Función   : / (plantilla)
       Propósito : El XHTML del artículo, en el orden del PDF
       Parámetros: (nodo de contexto) — el documento
       Retorna   : el documento XHTML
       ============================================ -->
  <xsl:template match="/">
    <xsl:variable name="meta" select="article/front/article-meta"/>

    <!-- APARTADO 1. LOS PARÁMETROS OBLIGATORIOS: SIN ELLOS NO HAY id NI CITAS -->
    <xsl:if test="normalize-space($archivo) eq ''">
      <xsl:message terminate="yes">ERROR: falta el parámetro archivo (el nombre del artículo)</xsl:message>
    </xsl:if>
    <xsl:if test="not($gbct:tex4ht)">
      <xsl:message terminate="yes">ERROR: falta el parámetro bib_dir (la carpeta de preparar_citas_revista.sh)</xsl:message>
    </xsl:if>

    <!-- APARTADO 2. EL DOCUMENTO -->
    <html xmlns:epub="http://www.idpf.org/2007/ops" lang="{$gbe:xml-lang}" xml:lang="{$gbe:xml-lang}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="gbe:titulo-plano($meta/title-group/article-title)"/></title>
        <link rel="stylesheet" type="text/css" href="{$css}"/>
      </head>
      <body>
        <section epub:type="chapter" role="doc-chapter" class="articulo" id="{$archivo}">
          <xsl:call-template name="gbe:cabecera"/>
          <xsl:call-template name="gbe:resumenes"/>
          <xsl:call-template name="gbe:datos"/>

          <!-- EL CUERPO Y LOS AGRADECIMIENTOS: LAS PLANTILLAS DE LA HOJA VIEJA -->
          <xsl:apply-templates select="article/body"/>
          <xsl:apply-templates select="article/back/ack"/>

          <!-- LAS DECLARACIONES, ANTES DE LAS REFERENCIAS, COMO EN EL PDF -->
          <xsl:call-template name="gbe:declaraciones"/>
          <xsl:apply-templates select="article/back/app-group"/>

          <xsl:call-template name="gbe:notas"/>
          <xsl:call-template name="gbe:referencias"/>
        </section>
      </body>
    </html>
  </xsl:template>

  <!-- ============================================
       Función   : gbe:titulo-plano
       Propósito : Un título como texto, para <title>: el corte de línea
                   (SC-28) es un espacio
       Parámetros: t As element()? — article-title, subtitle…
       Retorna   : xs:string
       ============================================ -->
  <xsl:function name="gbe:titulo-plano" as="xs:string">
    <xsl:param name="t" as="element()?"/>
    <xsl:sequence select="normalize-space(string-join(
      for $n in $t/node() return (if ($n/self::break) then ' ' else string($n)), ''))"/>
  </xsl:function>

  <!-- EL CORTE DE LÍNEA DE UN TÍTULO NO TIENE SENTIDO FUERA DE LA PÁGINA
       (SC-31, SEGUNDA EXCEPCIÓN): ES UN ESPACIO -->
  <xsl:template match="break">
    <xsl:text> </xsl:text>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbe:cabecera
       Propósito : Tipo de artículo, título, subtítulo y títulos
                   traducidos (los del PDF, sin la franja ni el logo)
       Contexto  : el documento
       ============================================ -->
  <xsl:template name="gbe:cabecera">
    <xsl:variable name="tg" select="article/front/article-meta/title-group"/>
    <header class="articulo-cabecera">
      <p class="article-type"><xsl:value-of select="gbrc:tipo(string(article/@article-type), $gbe:lang)"/></p>
      <h1 class="article-title"><xsl:apply-templates select="$tg/article-title/node()"/></h1>
      <xsl:for-each select="$tg/subtitle">
        <p class="article-subtitle"><xsl:apply-templates select="node()"/></p>
      </xsl:for-each>
      <xsl:for-each select="$tg/trans-title-group">
        <p class="article-trans-title" lang="{@xml:lang}" xml:lang="{@xml:lang}">
          <xsl:apply-templates select="trans-title/node()"/>
          <xsl:for-each select="trans-subtitle">
            <xsl:text>: </xsl:text>
            <xsl:apply-templates select="node()"/>
          </xsl:for-each>
        </p>
      </xsl:for-each>
    </header>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbe:resumenes
       Propósito : El resumen del artículo y los traducidos, cada uno
                   con el rótulo en su idioma (sin tabla, en inglés, como
                   el PDF) y sus palabras clave: las del autor primero,
                   después cada vocabulario con su nombre
       Contexto  : el documento
       ============================================ -->
  <xsl:template name="gbe:resumenes">
    <xsl:variable name="meta" select="article/front/article-meta"/>
    <xsl:for-each select="$meta/abstract | $meta/trans-abstract">
      <xsl:variable name="lang" select="(normalize-space(@xml:lang)[. ne ''], $gbe:xml-lang)[1]"/>
      <xsl:variable name="l2" select="lower-case(substring($lang, 1, 2))"/>
      <xsl:variable name="r" select="$gbrc:rotulos[@k = 'resumen']"/>
      <xsl:variable name="p" select="$gbrc:rotulos[@k = 'palabras']"/>
      <xsl:variable name="grupos" select="$meta/kwd-group[normalize-space((@xml:lang, $gbe:xml-lang)[1]) = $lang][kwd]"/>
      <section class="resumen" lang="{$lang}" xml:lang="{$lang}">
        <p class="resumen-rotulo"><xsl:value-of select="($r/@*[local-name() = $l2], $r/@en)[1]"/></p>
        <!-- EL ESTRUCTURADO: CADA SECCIÓN, UN PÁRRAFO QUE ABRE CON SU TÍTULO -->
        <xsl:for-each select="p | sec">
          <xsl:choose>
            <xsl:when test="self::sec">
              <xsl:for-each select="p">
                <p class="resumen-sec">
                  <xsl:if test="position() = 1">
                    <strong class="resumen-sec-titulo"><xsl:apply-templates select="../title/node()"/><xsl:text>. </xsl:text></strong>
                  </xsl:if>
                  <xsl:apply-templates select="node()"/>
                </p>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <p><xsl:apply-templates select="node()"/></p>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="$grupos">
          <xsl:sort select="if (not(@kwd-group-type) or @kwd-group-type = 'author') then 0 else 1"/>
          <p class="palabras-clave">
            <strong>
              <xsl:value-of select="if (not(@kwd-group-type) or @kwd-group-type = 'author')
                                    then ($p/@*[local-name() = $l2], $p/@en)[1]
                                    else (@vocab, @kwd-group-type)[1]"/>
              <xsl:text>: </xsl:text>
            </strong>
            <xsl:value-of select="string-join(kwd ! normalize-space(.), '; ')"/>
          </p>
        </xsl:for-each>
      </section>
    </xsl:for-each>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbe:datos
       Propósito : El bloque de datos después del resumen (decisión de
                   Alberto, 14/11): lo de la columna derecha del PDF, en
                   su orden, sin «compartir»: autores, notas de autor,
                   edición y traducción, fechas, DOI o e-id, cómo citar,
                   licencia
       Contexto  : el documento
       ============================================ -->
  <xsl:template name="gbe:datos">
    <xsl:variable name="meta" select="article/front/article-meta"/>
    <xsl:variable name="perm" select="$meta/permissions"/>
    <xsl:variable name="doi" select="normalize-space($meta/article-id[@pub-id-type = 'doi'])"/>
    <xsl:variable name="eid" select="normalize-space($meta/elocation-id)"/>
    <xsl:variable name="licencia" select="normalize-space(($perm/license[1]/ali:license_ref, $perm/license[1]/@xlink:href)[1])"/>
    <xsl:variable name="eventos" select="$meta/pub-history/event/date | $meta/history/date"/>
    <xsl:variable name="pub" select="$meta/pub-date[@date-type = 'pub']"/>
    <xsl:variable name="notas" select="$meta/author-notes/fn[@fn-type = 'other']"/>

    <aside class="articulo-datos">

      <!-- APARTADO 1. AUTORES: NOMBRE, ORCID, AFILIACIONES Y CORREO -->
      <xsl:for-each select="$meta/contrib-group/contrib[@contrib-type = 'author']">
        <xsl:variable name="c" select="."/>
        <xsl:variable name="orcid" select="normalize-space(contrib-id[@contrib-id-type = 'orcid'])"/>
        <div class="autor">
          <p class="autor-nombre"><xsl:value-of select="gbrc:nombre(.)"/></p>
          <xsl:if test="$orcid ne ''">
            <p class="autor-orcid"><a href="{$orcid}"><xsl:value-of select="$orcid"/></a></p>
          </xsl:if>
          <xsl:for-each select="(//aff[@id = $c/xref[@ref-type = 'aff']/@rid], aff)">
            <p class="autor-afil"><xsl:value-of select="gbrc:afiliacion(.)"/></p>
          </xsl:for-each>
          <xsl:for-each select="email[normalize-space(.) ne '']">
            <p class="autor-correo">
              <xsl:if test="$c/@corresp = 'yes'">
                <span class="dato-rotulo"><xsl:value-of select="gbe:rotulo('correspondencia')"/><xsl:text>: </xsl:text></span>
              </xsl:if>
              <a href="mailto:{normalize-space(.)}"><xsl:value-of select="normalize-space(.)"/></a>
            </p>
          </xsl:for-each>
        </div>
      </xsl:for-each>

      <!-- APARTADO 2. NOTAS DE AUTOR (C2), PEGADAS A LAS PERSONAS -->
      <xsl:if test="$notas">
        <div class="dato-bloque">
          <p class="dato-rotulo"><xsl:value-of select="gbe:rotulo('notas')"/></p>
          <xsl:for-each select="$notas/p">
            <p class="dato-texto"><xsl:apply-templates select="node()"/></p>
          </xsl:for-each>
        </div>
      </xsl:if>

      <!-- APARTADO 3. EDICIÓN Y TRADUCCIÓN (SCIELO §5.2.4) -->
      <xsl:for-each-group select="$meta/contrib-group/contrib[@contrib-type = ('editor', 'translator')]"
                          group-by="@contrib-type">
        <xsl:sort select="if (current-grouping-key() eq 'editor') then 1 else 2"/>
        <div class="dato-bloque">
          <p class="dato-rotulo">
            <xsl:value-of select="gbe:rotulo(if (current-grouping-key() eq 'editor') then 'editor' else 'traductor')"/>
          </p>
          <xsl:for-each select="current-group()">
            <p class="dato-texto"><xsl:value-of select="gbrc:nombre(.)"/></p>
          </xsl:for-each>
        </div>
      </xsl:for-each-group>

      <!-- APARTADO 4. FECHAS: EL PROCESO Y LA PUBLICACIÓN -->
      <xsl:if test="$eventos or $pub">
        <div class="dato-bloque">
          <xsl:for-each select="$eventos[@date-type = ('received', 'rev-recd', 'accepted')]">
            <xsl:sort select="index-of(('received', 'rev-recd', 'accepted'), string(@date-type))"/>
            <xsl:sort select="@iso-8601-date"/>
            <xsl:call-template name="gbe:dato">
              <xsl:with-param name="rotulo" select="gbe:rotulo(@date-type)"/>
              <xsl:with-param name="valor" select="gbrc:fecha(., $gbe:lang)"/>
            </xsl:call-template>
          </xsl:for-each>
          <xsl:for-each select="$pub[1]">
            <xsl:call-template name="gbe:dato">
              <xsl:with-param name="rotulo" select="gbe:rotulo('pub')"/>
              <xsl:with-param name="valor" select="gbrc:fecha(., $gbe:lang)"/>
            </xsl:call-template>
          </xsl:for-each>
        </div>
      </xsl:if>

      <!-- APARTADO 5. IDENTIFICADORES -->
      <xsl:if test="$doi ne '' or $eid ne ''">
        <div class="dato-bloque">
          <xsl:if test="$doi ne ''">
            <p class="dato">
              <span class="dato-rotulo">DOI: </span>
              <a href="https://doi.org/{$doi}"><xsl:value-of select="concat('https://doi.org/', $doi)"/></a>
            </p>
          </xsl:if>
          <xsl:if test="$eid ne ''">
            <xsl:call-template name="gbe:dato">
              <xsl:with-param name="rotulo" select="gbe:rotulo('eid')"/>
              <xsl:with-param name="valor" select="$eid"/>
            </xsl:call-template>
          </xsl:if>
        </div>
      </xsl:if>

      <!-- APARTADO 6. CÓMO CITAR: EL TEXTO DE biblatex (E1) -->
      <div class="dato-bloque como-citar">
        <p class="dato-rotulo"><xsl:value-of select="gbe:rotulo('comocitar')"/></p>
        <p class="dato-texto">
          <xsl:apply-templates select="gbe:marca(concat('gbcita-', $archivo, '-comocitar'))" mode="gbct:fragmento"/>
        </p>
      </div>

      <!-- APARTADO 7. DERECHOS Y LICENCIA -->
      <xsl:if test="$perm/copyright-statement or $perm/license">
        <div class="dato-bloque">
          <p class="dato-rotulo"><xsl:value-of select="gbe:rotulo('licencia')"/></p>
          <p class="dato-texto">
            <xsl:value-of select="string-join((
              normalize-space($perm/copyright-statement)[. ne ''],
              normalize-space($perm/license[1]/license-p)[. ne '']), '. ')"/>
            <xsl:if test="$licencia ne ''">
              <xsl:text> </xsl:text>
              <a href="{$licencia}"><xsl:value-of select="$licencia"/></a>
            </xsl:if>
          </p>
        </div>
      </xsl:if>
    </aside>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbe:dato
       Propósito : Una línea «Rótulo: valor» del bloque de datos
       Parámetros: rotulo, valor As xs:string
       ============================================ -->
  <xsl:template name="gbe:dato">
    <xsl:param name="rotulo" as="xs:string"/>
    <xsl:param name="valor" as="xs:string"/>
    <p class="dato">
      <span class="dato-rotulo"><xsl:value-of select="$rotulo"/><xsl:text>: </xsl:text></span>
      <xsl:value-of select="$valor"/>
    </p>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbe:declaraciones
       Propósito : Las declaraciones, como en el PDF: contribuciones
                   (CRediT, con los nombres en el idioma del artículo),
                   financiamiento, conflicto de intereses y disponibilidad
                   de datos
       Contexto  : el documento
       ============================================ -->
  <xsl:template name="gbe:declaraciones">
    <xsl:variable name="meta" select="article/front/article-meta"/>
    <xsl:variable name="con-roles" select="$meta/contrib-group/contrib[@contrib-type = 'author'][role]"/>
    <xsl:variable name="fg" select="$meta/funding-group"/>
    <xsl:variable name="fin-texto" select="$fg/funding-statement[gbe:en-idioma(.)][1]"/>
    <xsl:variable name="coi" select="$meta/author-notes/fn[@fn-type = 'coi-statement'][gbe:en-idioma(.)][1]"/>
    <xsl:variable name="datos" select="article/back/sec[@sec-type = 'data-availability'][gbe:en-idioma(.)][1]"/>

    <xsl:if test="$con-roles or $fg/award-group or $fin-texto or $coi or $datos">
      <section class="declaraciones">
        <h2><xsl:value-of select="gbe:rotulo('declaraciones')"/></h2>

        <!-- APARTADO 1. CONTRIBUCIONES: «Nombre: rol, rol.» POR AUTOR -->
        <xsl:if test="$con-roles">
          <p class="declaracion">
            <strong><xsl:value-of select="gbe:rotulo('contribuciones')"/><xsl:text>. </xsl:text></strong>
            <xsl:for-each select="$con-roles">
              <xsl:value-of select="gbrc:nombre(.)"/>
              <xsl:text>: </xsl:text>
              <!-- EL CONTENIDO DE <role> ES EL NOMBRE EN EL IDIOMA (C2) -->
              <xsl:value-of select="string-join(role ! normalize-space((string(.)[normalize-space(.) ne ''], @vocab-term)[1]), ', ')"/>
              <xsl:text>. </xsl:text>
            </xsl:for-each>
          </p>
        </xsl:if>

        <!-- APARTADO 2. FINANCIAMIENTO: LA DECLARACIÓN; SIN ELLA, FUENTES Y PROYECTOS -->
        <xsl:if test="$fin-texto or $fg/award-group">
          <p class="declaracion">
            <strong><xsl:value-of select="gbe:rotulo('financiamiento')"/><xsl:text>. </xsl:text></strong>
            <xsl:choose>
              <xsl:when test="$fin-texto">
                <xsl:value-of select="normalize-space($fin-texto)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="string-join($fg/award-group ! (
                  normalize-space(string-join(funding-source//institution, ' '))
                  || (if (award-id) then ' (' || string-join(award-id ! normalize-space(.), ', ') || ')' else '')
                  ), '; ')"/>
                <xsl:text>.</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </p>
        </xsl:if>

        <!-- APARTADO 3. CONFLICTO DE INTERESES -->
        <xsl:if test="$coi">
          <p class="declaracion">
            <strong><xsl:value-of select="gbe:rotulo('coi')"/><xsl:text>. </xsl:text></strong>
            <xsl:for-each select="$coi/p">
              <xsl:if test="position() gt 1"><xsl:text> </xsl:text></xsl:if>
              <xsl:apply-templates select="node()"/>
            </xsl:for-each>
          </p>
        </xsl:if>

        <!-- APARTADO 4. DISPONIBILIDAD DE DATOS, CON EL TÍTULO DE SU SECCIÓN -->
        <xsl:if test="$datos">
          <p class="declaracion">
            <strong>
              <xsl:value-of select="if (normalize-space($datos/title) ne '')
                                    then normalize-space($datos/title) else gbe:rotulo('datos')"/>
              <xsl:text>. </xsl:text>
            </strong>
            <xsl:for-each select="$datos/p">
              <xsl:if test="position() gt 1"><xsl:text> </xsl:text></xsl:if>
              <xsl:apply-templates select="node()"/>
            </xsl:for-each>
          </p>
        </xsl:if>
      </section>
    </xsl:if>
  </xsl:template>

  <!-- LA DISPONIBILIDAD DE DATOS SALE EN LAS DECLARACIONES, NO DOS VECES -->
  <xsl:template match="back/sec[@sec-type = 'data-availability']"/>

  <!-- ============================================
       Función   : fn (plantilla)
       Propósito : La llamada de una nota del texto. Las de author-notes
                   no son notas del texto: no cuentan
       Parámetros: (nodo de contexto) — la nota
       Retorna   : el superíndice con el enlace
       ============================================ -->
  <xsl:template match="fn">
    <xsl:variable name="n" select="gbe:numero-nota(.)"/>
    <sup><a id="fnref-{$n}" href="#fn-{$n}" epub:type="noteref" role="doc-noteref"><xsl:value-of select="$n"/></a></sup>
  </xsl:template>

  <!-- ============================================
       Función   : gbe:numero-nota
       Propósito : El número de una nota del texto
       Parámetros: f As element() — la nota
       Retorna   : xs:integer
       ============================================ -->
  <xsl:function name="gbe:numero-nota" as="xs:integer">
    <xsl:param name="f" as="element()"/>
    <xsl:sequence select="count($f/preceding::fn[not(ancestor::author-notes)]) + 1"/>
  </xsl:function>

  <!-- ============================================
       Plantilla : gbe:notas
       Propósito : Las notas del texto al final del artículo, con su
                   formato y sus citas (la hoja vieja las aplanaba)
       Contexto  : el documento
       ============================================ -->
  <xsl:template name="gbe:notas">
    <xsl:variable name="notas" select="article//fn[not(ancestor::author-notes)]"/>
    <xsl:if test="$notas">
      <section epub:type="endnotes" role="doc-endnotes" class="notas">
        <h2><xsl:value-of select="gbe:rotulo('notas')"/></h2>
        <xsl:for-each select="$notas">
          <xsl:variable name="n" select="gbe:numero-nota(.)"/>
          <div role="doc-endnote" id="fn-{$n}" class="fn-item">
            <xsl:for-each select="p">
              <p>
                <xsl:if test="position() = 1">
                  <sup><xsl:value-of select="$n"/></sup>
                  <xsl:text> </xsl:text>
                </xsl:if>
                <xsl:apply-templates select="node()"/>
                <xsl:if test="position() = last()">
                  <xsl:text> </xsl:text>
                  <a href="#fnref-{$n}" role="doc-backlink" class="fn-backlink">&#x21A9;</a>
                </xsl:if>
              </p>
            </xsl:for-each>
          </div>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Función   : xref[@ref-type='bibr'] (plantilla)
       Propósito : Un grupo de citas con el texto que escribió biblatex
                   (citas.html, E1); las citas absorbidas por el grupo
                   anterior no emiten nada. El agrupamiento es el del PDF
                   (cita-jats-comun.xsl): así el id es el de la pasada
       Parámetros: (nodo de contexto) — el xref
       Retorna   : el texto de la cita, con sus enlaces
       ============================================ -->
  <xsl:template match="xref[@ref-type = 'bibr']" mode="#default text-only">
    <xsl:if test="gbcj:inicia-grupo(.)">
      <xsl:apply-templates select="gbe:marca(concat('gbcita-', gbcj:id-cita(., $archivo)))" mode="gbct:fragmento">
        <xsl:with-param name="grupo" select="gbcj:grupo-desde(.)" tunnel="yes"/>
      </xsl:apply-templates>
    </xsl:if>
  </xsl:template>

  <!-- EL ENLACE DE UNA CITA A SU REFERENCIA (CONTRATO DE
       cita-fragmentos.xsl): AL id DE LA REFERENCIA EN ESTE ARCHIVO, QUE ES
       EL DEL CANÓNICO (bib-clave) -->
  <xsl:template name="gbct:enlace-cita">
    <xsl:param name="rid" as="xs:string"/>
    <xsl:param name="contenido"/>
    <a class="xref-bibr" href="#{$rid}"><xsl:copy-of select="$contenido"/></a>
  </xsl:template>

  <!-- EL SEPARADOR ENTRE DOS CITAS: SE SUPRIME SOLO SI LA SEGUNDA QUEDÓ EN
       EL GRUPO DE LA PRIMERA (EL DELIMITADOR LO PUSO biblatex); SI NO, ES
       TEXTO. LA MISMA REGLA QUE EL PDF. GANA AL SUPRESOR DE LA HOJA VIEJA,
       QUE SUPRIMÍA TODO SEPARADOR ENTRE DOS CITAS -->
  <xsl:template match="text()[gbcj:es-separador(.)]
                             [preceding-sibling::node()[1][self::xref[@ref-type = 'bibr']]]
                             [following-sibling::node()[1][self::xref[@ref-type = 'bibr']]]"
                mode="#default text-only" priority="10">
    <xsl:if test="not(gbcj:agrupables(preceding-sibling::node()[1], following-sibling::node()[1]))">
      <xsl:value-of select="."/>
    </xsl:if>
  </xsl:template>

  <!-- ============================================
       Plantilla : gbe:referencias
       Propósito : Las referencias que imprimió biblatex para el
                   artículo, en su orden: las mismas que el PDF. Cada una
                   se une con su ref del canónico por la clave: su id es
                   el destino de los enlaces de cita. Un artículo sin
                   citas no tiene lista
       Contexto  : el documento
       ============================================ -->
  <xsl:template name="gbe:referencias">
    <xsl:variable name="entradas" select="gbct:entradas-bib($archivo, true(), gbct:estilo-numerico($estilo_cita))"/>
    <xsl:variable name="refs" select="article/back/ref-list//ref"/>
    <xsl:if test="exists($entradas)">
      <!-- EN UN ESTILO NUMÉRICO, LA SANGRÍA DE LA ETIQUETA MÁS ANCHA -->
      <xsl:variable name="clase-num" select="gbct:clase-etiquetas($entradas)"/>
      <section epub:type="bibliography" role="doc-bibliography" class="ref-list">
        <h2><xsl:value-of select="gbe:rotulo('referencias')"/></h2>
        <xsl:for-each select="$entradas">
          <xsl:variable name="clave" select="gbct:clave-entrada(.)"/>
          <xsl:variable name="ref" select="$refs[gbct:clave(@id) = $clave][1]"/>
          <xsl:if test="empty($ref)">
            <xsl:message terminate="yes">
              <xsl:text>[epub] biblatex imprimió </xsl:text>
              <xsl:value-of select="$clave"/>
              <xsl:text> y la lista de referencias del canónico no la tiene (</xsl:text>
              <xsl:value-of select="$archivo"/>
              <xsl:text>).</xsl:text>
            </xsl:message>
          </xsl:if>
          <div class="ref-item ref-biblatex{$clase-num}" id="{$ref/@id}">
            <xsl:call-template name="gbct:etiqueta">
              <xsl:with-param name="dd" select="."/>
            </xsl:call-template>
            <xsl:apply-templates select="." mode="gbct:fragmento"/>
          </div>
        </xsl:for-each>
      </section>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
