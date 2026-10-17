<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  cita-fragmentos.xsl
  ============================================================
  PROPÓSITO : LA LECTURA DE citas.html, EL PRODUCTO DE LA PASADA DE
              tex4ht (SC-57), POR LAS HOJAS DE HTML Y EPUB DE LIBROS:
              EL TEXTO DE CADA GRUPO DE CITAS, LAS ENTRADAS DE CADA
              BIBLIOGRAFÍA Y LA COPIA DE ESE MARCADO A LA SALIDA.
  USO       : SE INCLUYE CON xsl:include DESDE docbook-to-html.xsl Y
              docbook-to-epub.xsl, JUNTO CON cita-comun.xsl Y
              codigo-comun.xsl, DE LOS QUE DEPENDE.
  CONTRATO  : - EL PARÁMETRO bib_dir LO DECLARA ESTE MÓDULO. VACÍO: LA
                HOJA ARMA LAS CITAS CON SUS PLANTILLAS POR ESTILO, COMO
                ANTES. CON VALOR: LA CARPETA DE LA PASADA, CON
                citas.html, Y LAS CITAS Y LAS REFERENCIAS SALEN DE AHÍ.
              - CADA HOJA DEFINE LA PLANTILLA gbct:enlace-cita
                (PARÁMETROS rid Y contenido): EL ENLACE DE UNA CITA A SU
                REFERENCIA NO ES EL MISMO EN HTML (PANEL, onclick) Y EN
                EPUB (href). SI FALTA, SAXON NO COMPILA LA HOJA.
  LA SALIDA : EN EL ESPACIO DE NOMBRES DE XHTML, QUE ES EL DE LAS DOS
              HOJAS. citas.html NO TIENE ESPACIO DE NOMBRES: CADA
              ELEMENTO SE REHACE, NO SE COPIA.
  QUÉ PASA  : UNA LISTA CERRADA (DECISIÓN DE ALBERTO): em, strong,
              sup, del, u, span.versalitas-todas, LOS ENLACES EXTERNOS
              Y LOS DE CITA (#cite.N@clave), QUE SE VUELVEN
              gbct:enlace-cita. LAS ANCLAS DE tex4ht (x1-…, cite.N@…)
              SE DESCARTAN. CUALQUIER OTRA COSA CORTA LA HOJA (GV-23):
              ES UN CAMBIO DE tex4ht O DEL ESTILO QUE HAY QUE MIRAR.
  ETIQUETAS : EN UN ESTILO NUMÉRICO (IEEE) CADA <dt> TRAE «[n]»: SALE
              COMO span.ref-numero, CON LA SANGRÍA DE LA ETIQUETA MÁS
              ANCHA DE SU LISTA (gbct:clase-etiquetas).
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:db="http://docbook.org/ns/docbook"
  xmlns:gbc="urn:gbpublisher:codigo"
  xmlns:gbct="urn:gbpublisher:citas"
  exclude-result-prefixes="xs db gbc gbct">

  <!-- LA CARPETA DE LA PASADA DE CITAS, COMO RUTA ABSOLUTA:
       tmp/bib/html-libro-<nombre> O tmp/bib/epub-libro-<nombre>. LA PASA
       EL SCRIPT CUANDO GAMBAS LE PIDE EL MODO tex4ht -->
  <xsl:param name="bib_dir" as="xs:string" select="''"/>

  <!-- ¿LAS CITAS SALEN DE citas.html? -->
  <xsl:variable name="gbct:tex4ht" as="xs:boolean" select="normalize-space($bib_dir) != ''"/>

  <!-- citas.html. SI FALTA, LA HOJA SE CORTA AL PRIMER USO: SIN ÉL NO HAY
       NI UNA CITA, Y VOLVER A LAS PLANTILLAS POR ESTILO SERÍA ESCRIBIR OTRO
       TEXTO QUE EL DEL PDF SIN AVISAR (GV-23) -->
  <xsl:variable name="gbct:uri-citas" as="xs:string"
                select="if ($gbct:tex4ht) then concat(gbc:uri-carpeta($bib_dir), 'citas.html') else ''"/>
  <xsl:variable name="gbct:citas" as="document-node()?"
                select="if (not($gbct:tex4ht)) then ()
                        else if (doc-available($gbct:uri-citas)) then doc($gbct:uri-citas)
                        else error(QName('urn:gbpublisher:citas', 'sin-citas'),
                                   concat('[citas] No está ', $gbct:uri-citas,
                                          ': preparar_citas_libro.sh no corrió para esta salida.'))"/>

  <!-- LAS MARCAS DE citas.html POR id: gbcita-… Y gbbib-… -->
  <xsl:key name="gbct:por-id" match="*[@id]" use="@id"/>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:fragmento-cita                                -->
  <!-- PROPÓSITO: EL <span id="gbcita-{id}"> DE UN GRUPO DE CITAS.  -->
  <!-- PARÁMETROS: b     As element() — el primer biblioref del     -->
  <!--                                  grupo                        -->
  <!--             pieza As element() — la pieza que lo contiene    -->
  <!-- RETORNA  : element() — el span; SI FALTA, CORTA              -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:fragmento-cita" as="element()">
    <xsl:param name="b"     as="element()"/>
    <xsl:param name="pieza" as="element()"/>
    <xsl:variable name="id" select="concat('gbcita-', gbct:id-cita($b, $pieza))"/>
    <xsl:variable name="span" select="key('gbct:por-id', $id, $gbct:citas)"/>
    <xsl:sequence select="if (count($span) = 1) then $span
      else error(QName('urn:gbpublisher:citas', 'sin-cita'),
                 concat('[citas] citas.html no tiene ', $id, ' (cita a ', $b/@linkend,
                        '): el canónico cambió después de la pasada de citas.'))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:marca-bib                                     -->
  <!-- PROPÓSITO: LA MARCA DE LA BIBLIOGRAFÍA QUE LE TOCA A UNA     -->
  <!--            PIEZA: LA SUYA SI TRAE <bibliography> (LA MISMA   -->
  <!--            SEÑAL QUE LA refsection DEL PDF, GV-102); SI NO,  -->
  <!--            LA CONSOLIDADA.                                   -->
  <!-- PARÁMETROS: pieza As element() — la pieza                    -->
  <!-- RETORNA  : xs:string — sección-orden, o libro                -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:marca-bib" as="xs:string">
    <xsl:param name="pieza" as="element()"/>
    <xsl:sequence select="if (exists($pieza//db:bibliography))
                          then gbct:seccion-orden($pieza) else 'libro'"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:entradas-bib                                  -->
  <!-- PROPÓSITO: LAS ENTRADAS DE UNA BIBLIOGRAFÍA DE citas.html,   -->
  <!--            EN EL ORDEN DE biblatex: LOS <dd> DE LA PRIMERA   -->
  <!--            LISTA QUE SIGUE A SU MARCA, SI NO HAY OTRA MARCA  -->
  <!--            EN MEDIO (UNA refsection SIN CITAS NO IMPRIME     -->
  <!--            LISTA).                                           -->
  <!-- PARÁMETROS: marca    As xs:string  — sección-orden o libro   -->
  <!--             exigida  As xs:boolean — true(): SIN LA MARCA,   -->
  <!--                                      CORTA                   -->
  <!--             numerico As xs:boolean — gbct:estilo-numerico    -->
  <!--                                      DEL ESTILO DEL LIBRO    -->
  <!-- RETORNA  : element()* — los dd; vacío si no hay lista        -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:entradas-bib" as="element()*">
    <xsl:param name="marca"    as="xs:string"/>
    <xsl:param name="exigida"  as="xs:boolean"/>
    <xsl:param name="numerico" as="xs:boolean"/>
    <xsl:variable name="m" select="key('gbct:por-id', concat('gbbib-', $marca), $gbct:citas)"/>
    <xsl:variable name="dl" select="$m/following::dl[1]
                                    [preceding::span[starts-with(@id, 'gbbib-')][1] is $m]"/>
    <xsl:if test="$exigida and empty($m)">
      <xsl:sequence select="error(QName('urn:gbpublisher:citas', 'sin-bibliografia'),
        concat('[citas] citas.html no tiene la bibliografía gbbib-', $marca,
               ': el canónico cambió después de la pasada de citas.'))"/>
    </xsl:if>
    <!-- LA ETIQUETA DEL <dt> TIENE QUE SER LA DEL ESTILO: [n] EN UNO
         NUMÉRICO, NINGUNA EN UN AUTOR-AÑO. OTRA COSA (UN ESTILO ALFABÉTICO,
         UN citas.html DE OTRO ESTILO) NO SE MIDIÓ Y CORTA (GV-23, SC-57) -->
    <xsl:variable name="ajenas" select="if ($numerico)
                                        then $dl/dt[not(matches(normalize-space(), '^\[[0-9]+\]$'))]
                                        else $dl/dt[normalize-space() != '']"/>
    <xsl:if test="exists($ajenas)">
      <xsl:sequence select="error(QName('urn:gbpublisher:citas', 'etiqueta'),
        concat('[citas] La bibliografía gbbib-', $marca, ' de citas.html trae ',
               if (normalize-space($ajenas[1]) = '') then 'una entrada sin etiqueta'
               else concat('la etiqueta «', normalize-space($ajenas[1]), '»'),
               ' y el estilo del libro ',
               if ($numerico) then 'es numérico: espera [n].' else 'es autor-año: no lleva etiqueta.'))"/>
    </xsl:if>
    <xsl:sequence select="$dl/dd"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:etiqueta-entrada                              -->
  <!-- PROPÓSITO: LA ETIQUETA DE UNA ENTRADA DE citas.html, DEL     -->
  <!--            <dt> QUE LA PRECEDE: «[1]» EN UN ESTILO NUMÉRICO  -->
  <!-- PARÁMETROS: dd As element() — la entrada                     -->
  <!-- RETORNA  : xs:string — la etiqueta; vacía en un autor-año    -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:etiqueta-entrada" as="xs:string">
    <xsl:param name="dd" as="element()"/>
    <xsl:sequence select="normalize-space($dd/preceding-sibling::*[1][self::dt])"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:clase-etiquetas                               -->
  <!-- PROPÓSITO: LAS CLASES DE LA SANGRÍA DE UNA LISTA NUMÉRICA    -->
  <!--            (DECISIÓN DE ALBERTO, OPCIÓN B): EL TEXTO DE TODAS -->
  <!--            LAS LÍNEAS ARRANCA DESPUÉS DE LA ETIQUETA MÁS      -->
  <!--            ANCHA DE LA LISTA, COMO EN thebibliography DEL PDF -->
  <!-- PARÁMETROS: entradas As element()* — los dd de entradas-bib  -->
  <!-- RETORNA  : xs:string — « ref-biblatex-num ref-etiqueta-N»,   -->
  <!--            N = CIFRAS DE LA MÁS ANCHA (TOPE 3); VACÍA SI LA  -->
  <!--            LISTA NO TIENE ETIQUETAS                          -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:clase-etiquetas" as="xs:string">
    <xsl:param name="entradas" as="element()*"/>
    <xsl:variable name="cifras" as="xs:integer*"
                  select="for $d in $entradas
                          return string-length(translate(gbct:etiqueta-entrada($d), '[]', ''))"/>
    <!-- EL TOPE: 999 ENTRADAS EN UNA LISTA. MÁS ALLÁ, LA ETIQUETA SOLO
         EMPUJA EL TEXTO DE LA PRIMERA LÍNEA -->
    <xsl:sequence select="if (empty($cifras) or max($cifras) = 0) then ''
                          else concat(' ref-biblatex-num ref-etiqueta-', min((max($cifras), 3)))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: gbct:etiqueta                                     -->
  <!-- PROPÓSITO: LA ETIQUETA DE UNA ENTRADA A LA SALIDA, CON LA    -->
  <!--            MARCA DEL CAMINO POR PLANTILLAS (span.ref-numero) -->
  <!--            Y SU ESPACIO: UN LECTOR SIN CSS LEE «[1] P. Dalle» -->
  <!-- PARÁMETROS: dd As element() — la entrada                     -->
  <!-- RETORNA  : el span, o nada en un autor-año                   -->
  <!-- ============================================================ -->
  <xsl:template name="gbct:etiqueta">
    <xsl:param name="dd" as="element()"/>
    <xsl:variable name="etiqueta" select="gbct:etiqueta-entrada($dd)"/>
    <xsl:if test="$etiqueta != ''">
      <span xmlns="http://www.w3.org/1999/xhtml" class="ref-numero">
        <xsl:value-of select="concat($etiqueta, ' ')"/>
      </span>
    </xsl:if>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- FUNCIÓN : gbct:clave-entrada                                 -->
  <!-- PROPÓSITO: LA CLAVE DEL .bib DE UNA ENTRADA DE citas.html,   -->
  <!--            DE SU ANCLA cite.N@clave                          -->
  <!-- PARÁMETROS: dd As element() — la entrada                     -->
  <!-- RETORNA  : xs:string — la clave; SI NO TIENE ANCLA, CORTA    -->
  <!-- ============================================================ -->
  <xsl:function name="gbct:clave-entrada" as="xs:string">
    <xsl:param name="dd" as="element()"/>
    <xsl:variable name="a" select="($dd//a[starts-with(@id, 'cite.')])[1]"/>
    <xsl:sequence select="if (exists($a)) then substring-after($a/@id, '@')
      else error(QName('urn:gbpublisher:citas', 'sin-clave'),
                 concat('[citas] Una entrada de citas.html no tiene ancla cite.N@clave: ',
                        normalize-space($dd)))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- MODO gbct:fragmento: EL MARCADO DE citas.html, A LA SALIDA   -->
  <!-- PARÁMETRO DE TÚNEL grupo: LOS biblioref DEL GRUPO, PARA      -->
  <!-- TRADUCIR #cite.N@clave AL linkend DE LA CITA. VACÍO EN UNA   -->
  <!-- ENTRADA DE BIBLIOGRAFÍA: AHÍ UN ENLACE DE CITA CORTA.        -->
  <!-- ============================================================ -->

  <!-- EL CONTENEDOR DE LA CITA O DE LA ENTRADA: SOLO SU CONTENIDO -->
  <xsl:template match="span[starts-with(@id, 'gbcita-')] | dd | p" mode="gbct:fragmento">
    <xsl:apply-templates mode="gbct:fragmento"/>
  </xsl:template>

  <xsl:template match="text()" mode="gbct:fragmento">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- EL SALTO DE LÍNEA CON QUE tex4ht ABRE CADA <dd>, ANTES DE SU <p>, NO
       PASA: DETRÁS DE LA ETIQUETA [n] (UN inline-block) SE VERÍA COMO UN
       ESPACIO Y CORRERÍA LA PRIMERA LÍNEA RESPECTO DE LAS DEMÁS. EN UN
       AUTOR-AÑO NO CAMBIA NADA: A PRINCIPIO DE LÍNEA EL NAVEGADOR YA LO
       DESCARTABA -->
  <xsl:template match="dd/text()[not(normalize-space())][empty(preceding-sibling::*)]"
                mode="gbct:fragmento"/>

  <!-- EL COMENTARIO DE LÍNEA DE tex4ht (<!- - l. 22 - ->) NO PASA -->
  <xsl:template match="comment()" mode="gbct:fragmento"/>

  <!-- MARCADO EN LÍNEA: SE REHACE SIN ATRIBUTOS -->
  <xsl:template match="em | strong | sup | del | u" mode="gbct:fragmento">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates mode="gbct:fragmento"/>
    </xsl:element>
  </xsl:template>

  <!-- VERSALITAS: LAS PONE EL CSS (font-variant-caps, SC-56) -->
  <xsl:template match="span[@class = 'versalitas-todas']" mode="gbct:fragmento">
    <span xmlns="http://www.w3.org/1999/xhtml" class="versalitas-todas">
      <xsl:apply-templates mode="gbct:fragmento"/>
    </span>
  </xsl:template>

  <!-- ANCLAS DE tex4ht (x1-…, cite.N@…): SIN DESTINO EN LA SALIDA -->
  <xsl:template match="a[not(@href)]" mode="gbct:fragmento"/>

  <!-- ENLACE EXTERNO (URL, DOI): IGUAL QUE LOS DE LAS DOS HOJAS -->
  <xsl:template match="a[matches(@href, '^(https?|ftp|mailto):')]" mode="gbct:fragmento">
    <a xmlns="http://www.w3.org/1999/xhtml" href="{@href}" target="_blank" rel="noopener noreferrer">
      <xsl:apply-templates mode="gbct:fragmento"/>
    </a>
  </xsl:template>

  <!-- ENLACE DE CITA: #cite.N@clave → EL linkend DEL biblioref DEL GRUPO
       CON ESA CLAVE. EL ENLACE LO ARMA LA HOJA (gbct:enlace-cita) -->
  <xsl:template match="a[starts-with(@href, '#cite.')]" mode="gbct:fragmento">
    <xsl:param name="grupo" as="element()*" tunnel="yes"/>
    <xsl:variable name="clave" select="substring-after(@href, '@')"/>
    <xsl:variable name="b" select="$grupo[gbct:clave(@linkend) = $clave][1]"/>
    <xsl:if test="empty($b)">
      <xsl:message terminate="yes">
        <xsl:text>[citas] citas.html enlaza a la clave </xsl:text>
        <xsl:value-of select="$clave"/>
        <xsl:text>, que no está en el grupo de citas</xsl:text>
        <xsl:if test="exists($grupo)">
          <xsl:text> de </xsl:text>
          <xsl:value-of select="$grupo[1]/@linkend"/>
        </xsl:if>
        <xsl:text>.</xsl:text>
      </xsl:message>
    </xsl:if>
    <xsl:call-template name="gbct:enlace-cita">
      <xsl:with-param name="rid" select="string($b/@linkend)"/>
      <xsl:with-param name="contenido">
        <xsl:apply-templates mode="gbct:fragmento"/>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <!-- CUALQUIER OTRA COSA: FUERA DE LA LISTA, CORTA (GV-23) -->
  <xsl:template match="*" mode="gbct:fragmento" priority="-1">
    <xsl:message terminate="yes">
      <!-- SIN < NI >: xsl:message SERIALIZA COMO XML Y LOS ESCAPA -->
      <xsl:text>[citas] citas.html trae un elemento que la hoja no conoce: </xsl:text>
      <xsl:value-of select="local-name()"/>
      <xsl:for-each select="@*">
        <xsl:value-of select="concat(' ', local-name(), '=', .)"/>
      </xsl:for-each>
      <xsl:text>, en «</xsl:text>
      <xsl:value-of select="normalize-space(ancestor::*[@id][1])"/>
      <xsl:text>». Revisar cita-tex4ht.cfg o el estilo.</xsl:text>
    </xsl:message>
  </xsl:template>

</xsl:stylesheet>
