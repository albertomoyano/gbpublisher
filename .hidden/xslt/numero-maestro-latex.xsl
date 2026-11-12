<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================
  HOJA DE ESTILO : numero-maestro-latex.xsl
  VERSIÓN XSLT   : 3.0 (Saxon-HE)
  PROPÓSITO      : latex/maestro-numero.tex, EL MAESTRO DEL PDF DEL
                   NÚMERO (ETAPA B5, DECISIONES DE ALBERTO DEL 07/11
                   Y DEL 12/11/2026):
                     - LAS PRELIMINARES QUE EL NÚMERO DECLARA, EN EL
                       ORDEN DE SU NOMBRE (fm-0N, SC-44): TAPA (LA
                       IMAGEN DEL NÚMERO), PÁGINA LEGAL Y SUMARIO;
                     - DESPUÉS, EL PDF DE CADA ARTÍCULO, YA COMPUESTO Y
                       VALIDADO, INCLUIDO CON pdfpages (CONTRATO DE
                       REVISTA 4, 5.7).
                   LA PÁGINA LEGAL SALE DE <pagina-legal> DEL VOLCADO,
                   QUE YA VIENE FILTRADO A LA FECHA DE REFERENCIA DEL
                   NÚMERO: ESTA HOJA NO DECIDE QUIÉN ESTÁ VIGENTE.
                   EL FOLIO DEL SUMARIO SALE DE LA COMPOSICIÓN DE ESTA
                   CORRIDA (PARÁMETRO paginacion), NO DE LA BASE: ES EL
                   QUE TIENEN LOS PDF QUE SE INCLUYEN.
  ENTRADA        : {proyecto}/tmp/numero-datos.xml (VOLCADO 3)
  SALIDA         : -o:{proyecto}/latex/maestro-numero.tex
  PARÁMETROS     : paginacion  RUTA ABSOLUTA DEL TSV DE ESTA CORRIDA
                               (archivo inicio fin paginas elocation;
                               LA PRIMERA LÍNEA EMPIEZA CON #). REQUERIDO
                   dir_pdf     DÓNDE ESTÁN LOS PDF DE LOS ARTÍCULOS,
                               RELATIVO A LA RAÍZ DEL PROYECTO (DESDE
                               DONDE SE COMPILA); CADA UNO ES
                               {dir_pdf}{archivo}/main-{archivo}.pdf
  SIN MARCA DE TIEMPO: LOS MISMOS DATOS DAN EL MISMO ARCHIVO.
  ============================================================
-->
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:f="urn:gbpublisher:functions"
  xmlns:gbm="urn:gbpublisher:numero-maestro"
  exclude-result-prefixes="xs f gbm">

  <!-- f:latex (EL ESCAPE DE LOS CARACTERES ACTIVOS) Y f:titulo-tramos (EL
       TÍTULO PARTIDO EN SUS CORTES, SC-28) -->
  <xsl:import href="tex-comun.xsl"/>

  <xsl:output method="text" encoding="UTF-8"/>

  <xsl:param name="paginacion" as="xs:string" required="yes"/>
  <xsl:param name="dir_pdf" as="xs:string" select="'latex/compilacion/'"/>

  <!-- LA VERSIÓN DEL VOLCADO QUE ESTA HOJA SABE LEER: LA PRIMERA CON
       <preliminares> Y <pagina-legal> -->
  <xsl:variable name="gbm:version-datos" select="'3'"/>

  <!-- LA VERSIÓN DEL CONTRATO DE REVISTA QUE PIDE EL MAESTRO -->
  <xsl:variable name="gbm:contrato" select="'4'"/>

  <!-- LAS LÍNEAS DEL TSV, SIN LA DE LOS NOMBRES DE COLUMNA -->
  <xsl:variable name="gbm:filas" as="xs:string*"
    select="unparsed-text-lines($paginacion)[normalize-space(.) ne ''][not(starts-with(., '#'))]"/>

  <!-- ============================================
       Función   : gbm:tex
       Propósito : f:latex más los atajos de babel: con babel-spanish,
                   < > " son activos y rompen el marcador del PDF y el
                   sumario (MEDIDO: «Argument of \language@active@arg> has
                   an extra }» con un título que tenía «<»). Van como
                   comando de texto, que hyperref pasa a cadena
       Parámetros: t As xs:string — texto crudo
       Retorna   : xs:string — LaTeX
       ============================================ -->
  <xsl:function name="gbm:tex" as="xs:string">
    <xsl:param name="t" as="xs:string"/>
    <xsl:sequence select="replace(replace(replace(f:latex($t),
      '&lt;', '\\textless{}'), '&gt;', '\\textgreater{}'), '&quot;', '\\textquotedbl{}')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbm:titulo
       Propósito : El título en una línea (sin el corte del editor,
                   SC-28), escapado con gbm:tex
       Parámetros: titulo As node()? — el elemento del título
       Retorna   : xs:string — LaTeX
       ============================================ -->
  <xsl:function name="gbm:titulo" as="xs:string">
    <xsl:param name="titulo" as="node()?"/>
    <xsl:sequence select="gbm:tex(string-join(f:titulo-tramos($titulo), ' '))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbm:columna
       Propósito : Un dato del TSV de un artículo
       Parámetros: archivo As xs:string — el archivo del artículo
                   n As xs:integer — la columna (1 archivo, 2 inicio,
                     3 fin, 4 paginas, 5 elocation)
       Retorna   : xs:string — el valor; vacío si no está
       ============================================ -->
  <xsl:function name="gbm:columna" as="xs:string">
    <xsl:param name="archivo" as="xs:string"/>
    <xsl:param name="n" as="xs:integer"/>
    <xsl:variable name="fila" select="($gbm:filas[tokenize(., '&#9;')[1] eq $archivo])[1]"/>
    <xsl:sequence select="string(tokenize(string($fila), '&#9;')[$n])"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbm:conjuncion
       Propósito : Lo que va antes del último nombre de una lista, según
                   el idioma principal de la revista. En castellano, «e»
                   ante el sonido i (la regla de m_PrimerasLibro.Conjuncion,
                   DPD «y»): «Pérez e Ibáñez», pero «Ana y Iolanda». Un
                   idioma que esta hoja no conoce separa con coma
       Parámetros: idioma As xs:string — código de la revista (es, en…)
                   siguiente As xs:string — el último nombre
       Retorna   : xs:string — la conjunción con sus espacios
       ============================================ -->
  <xsl:function name="gbm:conjuncion" as="xs:string">
    <xsl:param name="idioma" as="xs:string"/>
    <xsl:param name="siguiente" as="xs:string"/>
    <xsl:variable name="base" select="substring-before(concat($idioma, '-'), '-')"/>
    <!-- LA h NO SUENA -->
    <xsl:variable name="palabra" select="replace(normalize-space($siguiente), '^[hH]', '')"/>
    <xsl:variable name="primera" select="substring($palabra, 1, 1)"/>
    <xsl:variable name="segunda" select="substring($palabra, 2, 1)"/>
    <xsl:choose>
      <xsl:when test="$base eq 'es'">
        <xsl:choose>
          <xsl:when test="not($primera = ('i', 'I', 'í', 'Í'))"> y </xsl:when>
          <!-- i SIN TILDE ANTE VOCAL: DIPTONGO, «y» -->
          <xsl:when test="$primera = ('i', 'I') and contains('aeiouáéíóúüAEIOUÁÉÍÓÚÜ', $segunda) and $segunda ne ''"> y </xsl:when>
          <xsl:otherwise> e </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$base = ('pt', 'gl', 'it')"> e </xsl:when>
      <xsl:when test="$base eq 'en'"> and </xsl:when>
      <xsl:when test="$base eq 'fr'"> et </xsl:when>
      <xsl:otherwise>, </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ============================================
       Función   : gbm:lista
       Propósito : Une nombres ya escapados: «A», «A y B», «A, B y C»
       Parámetros: nombres As xs:string* — en orden, sin escapar
                   idioma As xs:string — código de la revista
       Retorna   : xs:string — LaTeX
       ============================================ -->
  <xsl:function name="gbm:lista" as="xs:string">
    <xsl:param name="nombres" as="xs:string*"/>
    <xsl:param name="idioma" as="xs:string"/>
    <xsl:variable name="n" select="count($nombres)"/>
    <xsl:sequence select="string-join(
      for $i in 1 to $n return concat(
        if ($i eq 1) then ''
        else if ($i eq $n) then gbm:conjuncion($idioma, $nombres[$i])
        else ', ',
        gbm:tex($nombres[$i])), '')"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbm:persona
       Propósito : «Nombre Apellidos» de una persona del volcado, o el
                   nombre del colectivo
       Parámetros: e As element() — <persona>, <miembro> o <contribuyente>
       Retorna   : xs:string — sin escapar
       ============================================ -->
  <xsl:function name="gbm:persona" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:variable name="p" select="($e/persona, $e)[1]"/>
    <xsl:sequence select="if ($e/colectivo) then normalize-space($e/colectivo)
      else normalize-space(string-join(($p/nombre, $p/apellidos) ! normalize-space(.), ' '))"/>
  </xsl:function>

  <!-- ============================================
       Función   : gbm:titulo-idioma
       Propósito : El título de una sección o un dossier en el idioma
                   principal; si no lo tiene, el primero
       Parámetros: e As element()? — la sección o el dossier
                   idioma As xs:string — código principal
       Retorna   : xs:string — sin escapar; vacío si no hay
       ============================================ -->
  <xsl:function name="gbm:titulo-idioma" as="xs:string">
    <xsl:param name="e" as="element()?"/>
    <xsl:param name="idioma" as="xs:string"/>
    <xsl:sequence select="normalize-space(string(($e/titulo[@idioma eq $idioma], $e/titulo)[1]))"/>
  </xsl:function>

  <!-- ============================================================ -->
  <!-- PLANTILLA: /                                                 -->
  <!-- VALIDA Y ESCRIBE EL MAESTRO                                  -->
  <!-- ============================================================ -->
  <xsl:template match="/">
    <xsl:variable name="d" select="numero-datos"/>
    <xsl:variable name="principal" select="(tokenize(string($d/revista/idiomas), ',') ! normalize-space(.)[. ne ''])[1]"/>
    <xsl:variable name="piezas" select="$d/preliminares/pieza"/>

    <!-- 1. VALIDACIÓN: LO QUE FALTA FRENA ACÁ, CON UN MENSAJE -->
    <xsl:if test="string($d/@version) ne $gbm:version-datos">
      <xsl:message terminate="yes">ERROR: el volcado es versión «<xsl:value-of select="$d/@version"/>» y esta hoja lee la <xsl:value-of select="$gbm:version-datos"/>: actualizá gbpublisher</xsl:message>
    </xsl:if>
    <xsl:if test="empty($principal)">
      <xsl:message terminate="yes">ERROR: la revista no tiene idiomas de publicación. Cargalos en la ficha de la revista.</xsl:message>
    </xsl:if>
    <xsl:if test="$piezas[@tipo eq 'tapa'] and normalize-space($d/numero/imagen-tapa) eq ''">
      <xsl:message terminate="yes">ERROR: el número declara la tapa y no tiene imagen. Elegila en los metadatos del número.</xsl:message>
    </xsl:if>
    <xsl:if test="$piezas[@tipo eq 'legales'] and empty($d/pagina-legal)">
      <xsl:message terminate="yes">ERROR: el número declara la página legal y el volcado no la trae (¿falta el año del número?)</xsl:message>
    </xsl:if>
    <xsl:for-each select="$d/articulo">
      <xsl:if test="gbm:columna(string(@archivo), 1) eq ''">
        <xsl:message terminate="yes">ERROR: <xsl:value-of select="@archivo"/> no está en la paginación de esta corrida</xsl:message>
      </xsl:if>
    </xsl:for-each>

    <!-- 2. EL PREÁMBULO: LAS MISMAS CAPAS QUE UN ARTÍCULO, SIN MARCAS -->
    <xsl:text>% maestro-numero.tex — ARCHIVO DERIVADO (numero-maestro-latex.xsl): NO EDITAR A MANO&#10;</xsl:text>
    <xsl:text>\DocumentMetadata{pdfstandard=A-2u, lang=</xsl:text>
    <xsl:value-of select="$principal"/>
    <xsl:text>}&#10;\documentclass{article}&#10;\input{preambulo-numero}&#10;</xsl:text>
    <xsl:text>% EL PDF DEL NÚMERO SALE LIMPIO: LOS ARTÍCULOS YA TRAEN LO SUYO&#10;</xsl:text>
    <xsl:text>\gbshowframefalse&#10;\gbhomeoarchyfalse&#10;</xsl:text>
    <xsl:text>\input{preambulo-revista-contrato}&#10;\input{preambulo-revista-estetica}&#10;</xsl:text>
    <xsl:text>\gbRequiereContratoRevista{</xsl:text>
    <xsl:value-of select="$gbm:contrato"/>
    <xsl:text>}&#10;\usepackage{pdfpages}&#10;</xsl:text>

    <!-- 3. LOS DATOS DEL NÚMERO (CONTRATO 4, 5.2) Y LOS DEL PDF -->
    <xsl:text>\gbdatosnumero{</xsl:text>
    <xsl:value-of select="gbm:tex(normalize-space($d/revista/titulo))"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="gbm:tex(normalize-space($d/revista/@rotulo-volumen))"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="gbm:tex(normalize-space($d/numero/@volumen))"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="gbm:tex(normalize-space($d/numero/@numero))"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="gbm:tex(normalize-space($d/numero/@suplemento))"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="normalize-space($d/numero/@mes)"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="normalize-space($d/numero/@anio)"/>
    <xsl:text>}{</xsl:text>
    <xsl:value-of select="gbm:titulo($d/numero/titulo-especial)"/>
    <xsl:text>}&#10;\hypersetup{pdftitle={</xsl:text>
    <xsl:value-of select="gbm:tex(normalize-space($d/revista/titulo))"/>
    <xsl:text>}</xsl:text>
    <xsl:if test="normalize-space($d/pagina-legal/editorial/nombre) ne ''">
      <xsl:text>, pdfauthor={</xsl:text>
      <xsl:value-of select="gbm:tex(normalize-space($d/pagina-legal/editorial/nombre))"/>
      <xsl:text>}</xsl:text>
    </xsl:if>
    <xsl:text>}&#10;\begin{document}&#10;</xsl:text>

    <!-- 4. LAS PRELIMINARES, EN EL ORDEN DE SU NOMBRE -->
    <xsl:for-each select="$piezas">
      <xsl:sort select="@archivo"/>
      <xsl:text>% </xsl:text>
      <xsl:value-of select="@archivo"/>
      <xsl:text>&#10;</xsl:text>
      <xsl:choose>
        <xsl:when test="@tipo eq 'tapa'">
          <xsl:text>\gbtapanumero{media/</xsl:text>
          <xsl:value-of select="normalize-space($d/numero/imagen-tapa)"/>
          <xsl:text>}&#10;</xsl:text>
        </xsl:when>
        <xsl:when test="@tipo eq 'legales'">
          <xsl:call-template name="gbm:legales">
            <xsl:with-param name="d" select="$d"/>
            <xsl:with-param name="principal" select="$principal"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="@tipo eq 'sumario'">
          <xsl:call-template name="gbm:sumario">
            <xsl:with-param name="d" select="$d"/>
            <xsl:with-param name="principal" select="$principal"/>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
    </xsl:for-each>

    <!-- 5. LOS ARTÍCULOS, EN EL ORDEN DEL VOLCADO (EL MANIFIESTO) -->
    <xsl:for-each select="$d/articulo">
      <xsl:text>\gbarticulonumero{</xsl:text>
      <xsl:value-of select="@archivo"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="gbm:titulo(titulo)"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="concat($dir_pdf, @archivo, '/main-', @archivo, '.pdf')"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>\end{document}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbm:legales                                  -->
  <!-- LA PÁGINA LEGAL (CONTRATO 4, 5.5), EN EL ORDEN DEL CONTRATO  -->
  <!-- ============================================================ -->
  <xsl:template name="gbm:legales">
    <xsl:param name="d" as="element()"/>
    <xsl:param name="principal" as="xs:string"/>
    <xsl:variable name="pl" select="$d/pagina-legal"/>
    <xsl:variable name="ed" select="$pl/editorial"/>

    <xsl:text>\begin{gbpaginalegal}&#10;\gblegalrevista&#10;</xsl:text>
    <xsl:if test="$ed">
      <xsl:text>\gblegaleditorial{</xsl:text>
      <xsl:value-of select="gbm:tex(normalize-space($ed/nombre))"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="gbm:tex(normalize-space($ed/institucion))"/>
      <xsl:text>}&#10;</xsl:text>
      <!-- LOS CRÉDITOS DEL MISMO CARGO VAN JUNTOS, EN EL ORDEN EN QUE
           APARECE EL CARGO -->
      <xsl:for-each-group select="$ed/credito" group-by="normalize-space(@cargo)">
        <xsl:text>\gblegalcredito{</xsl:text>
        <xsl:value-of select="gbm:tex(current-grouping-key())"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="gbm:lista(current-group() ! normalize-space(.), $principal)"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:for-each-group>
    </xsl:if>
    <xsl:for-each select="$pl/organo">
      <xsl:text>\gblegalorgano{</xsl:text>
      <xsl:value-of select="gbm:tex(normalize-space(@nombre))"/>
      <xsl:text>}{</xsl:text>
      <xsl:value-of select="count(miembro)"/>
      <xsl:text>}{%&#10;</xsl:text>
      <xsl:for-each select="miembro">
        <xsl:text>  \gblegalmiembro{</xsl:text>
        <xsl:value-of select="gbm:tex(gbm:persona(.))"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="gbm:tex(normalize-space(afiliacion))"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:for-each>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
    <xsl:text>\gblegalbloque&#10;</xsl:text>
    <xsl:for-each select="$d/revista/issn[normalize-space(.) ne '']">
      <xsl:value-of select="if (@tipo eq 'impreso') then '\gblegalissnimpreso{' else '\gblegalissnelectronico{'"/>
      <xsl:value-of select="gbm:tex(normalize-space(.))"/>
      <xsl:text>}&#10;</xsl:text>
    </xsl:for-each>
    <xsl:if test="$ed">
      <!-- LA DIRECCIÓN EN UN RENGLÓN: CALLE, CIUDAD, REGIÓN, PAÍS -->
      <xsl:variable name="lugar" select="($ed/direccion, $ed/ciudad, $ed/region, $ed/pais) ! normalize-space(.)[. ne '']"/>
      <xsl:if test="exists($lugar)">
        <xsl:text>\gblegaldireccion{</xsl:text>
        <xsl:value-of select="gbm:tex(string-join($lugar, ', '))"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
      <xsl:if test="normalize-space($ed/url-portal) ne ''">
        <xsl:text>\gblegalportal{</xsl:text>
        <xsl:value-of select="f:latex-url(normalize-space($ed/url-portal))"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
      <!-- EL CORREO: EL PROPIO DE LA REVISTA SI LO TIENE (YA VIENE
           RESUELTO EN revista/email), SI NO EL DE LA EDITORIAL -->
      <xsl:variable name="correo" select="normalize-space(($d/revista/email, $ed/email)[normalize-space(.) ne ''][1])"/>
      <xsl:if test="$correo ne ''">
        <xsl:text>\gblegalcorreo{</xsl:text>
        <xsl:value-of select="gbm:tex($correo)"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
      <xsl:if test="normalize-space($ed/leyenda-distribucion) ne ''">
        <xsl:text>\gblegalleyenda{</xsl:text>
        <xsl:value-of select="gbm:tex(normalize-space($ed/leyenda-distribucion))"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
      <xsl:if test="normalize-space($ed/aviso-responsabilidad) ne ''">
        <xsl:text>\gblegalaviso{</xsl:text>
        <xsl:value-of select="gbm:tex(normalize-space($ed/aviso-responsabilidad))"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
    </xsl:if>
    <xsl:text>\end{gbpaginalegal}&#10;</xsl:text>
  </xsl:template>

  <!-- ============================================================ -->
  <!-- NAMED TEMPLATE: gbm:sumario                                  -->
  <!-- EL SUMARIO (CONTRATO 4, 5.6): LOS ARTÍCULOS EN EL ORDEN DEL  -->
  <!-- NÚMERO, CON EL TÍTULO DE LA SECCIÓN O DEL DOSSIER CADA VEZ   -->
  <!-- QUE CAMBIA                                                   -->
  <!-- ============================================================ -->
  <xsl:template name="gbm:sumario">
    <xsl:param name="d" as="element()"/>
    <xsl:param name="principal" as="xs:string"/>
    <xsl:variable name="modelo" select="string($d/revista/@modelo-paginacion)"/>

    <xsl:text>\begin{gbsumarionumero}&#10;</xsl:text>
    <!-- UN GRUPO POR TRAMO SEGUIDO DEL MISMO DOSSIER O, SIN DOSSIER, DE LA
         MISMA SECCIÓN -->
    <xsl:for-each-group select="$d/articulo"
      group-adjacent="if (@dossier) then concat('d', @dossier) else concat('s', @seccion)">
      <xsl:variable name="primero" select="current-group()[1]"/>
      <xsl:variable name="encabezado">
        <xsl:choose>
          <xsl:when test="$primero/@dossier">
            <xsl:variable name="dos" select="$d/dossier[@id eq $primero/@dossier]"/>
            <xsl:variable name="sec" select="gbm:titulo-idioma($d/seccion[@codigo eq $dos/@seccion], $principal)"/>
            <xsl:value-of select="string-join(($sec, gbm:titulo-idioma($dos, $principal))[. ne ''], '. ')"/>
          </xsl:when>
          <xsl:when test="$primero/@seccion">
            <xsl:value-of select="gbm:titulo-idioma($d/seccion[@codigo eq $primero/@seccion], $principal)"/>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="normalize-space($encabezado) ne ''">
        <xsl:text>\gbsumarioseccion{</xsl:text>
        <xsl:value-of select="gbm:tex(normalize-space($encabezado))"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:if>
      <xsl:for-each select="current-group()">
        <xsl:variable name="archivo" select="string(@archivo)"/>
        <xsl:variable name="folio" select="
          if ($modelo = ('por_numero', 'por_volumen')) then gbm:columna($archivo, 2)
          else if ($modelo eq 'continua') then gbm:columna($archivo, 5)
          else ''"/>
        <xsl:text>\gbsumarioarticulo{</xsl:text>
        <xsl:value-of select="$archivo"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="@idioma"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="gbm:titulo(titulo)"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="gbm:lista(contribuyente[@rol eq 'autor'] ! gbm:persona(.), $principal)"/>
        <xsl:text>}{</xsl:text>
        <xsl:value-of select="gbm:tex($folio)"/>
        <xsl:text>}&#10;</xsl:text>
      </xsl:for-each>
    </xsl:for-each-group>
    <xsl:text>\end{gbsumarionumero}&#10;</xsl:text>
  </xsl:template>

</xsl:stylesheet>
