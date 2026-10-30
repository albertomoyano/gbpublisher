<?xml version="1.0" encoding="UTF-8"?>
<!--
  ============================================================================
  gbpublisher.sch — reglas propias de gbpublisher sobre el canónico DocBook
  ============================================================================
  Las reglas que el esquema de DocBook no conoce: las que dependen de cómo
  gbpublisher arma y consume sus canónicos (SC-75, entrega 2). Se compilan
  junto con el Schematron del RNG de DocBook en una sola hoja,
  schemas/schematron-canonico.xsl, con generar-schematron-canonico.sh; el
  validador (engine/validar_canonicos.sh) la corre una vez por lote.

  NO SE EDITA EN ~/.gbpublisher: vive en los recursos del sistema y no se
  copia (SC-11). Un informe que dice «cumple» solo se sostiene con las reglas
  del paquete.

  CONVENCIONES
  - Cada patrón y cada aserción llevan un @id con el prefijo gbp-: el
    validador separa por ese prefijo estas reglas de las de DocBook, que no
    traen @id.
  - El nivel lo declara la aserción en @role: aviso (el validador sale con
    código 3) o tenue (informa). No hay error: el validador no genera nada
    que frenar; si una regla tiene que frenar, frena el consumidor.
  - El alcance lo da el contexto de la regla: /db:book para el libro; la
    raíz de una pieza, o una pieza dentro del libro, para las piezas. Sin
    fases.
  - Las reglas sobre instrucciones de procesamiento se escriben sobre la
    raíz del documento: con el esqueleto ISO, una regla cuyo contexto es
    una PI solo se dispara para las del prólogo (GV-XML-04).
  - Las raíces de pieza son las que escribe ensamblar-capitulo-canonico.xsl
    según tipo_capitulo: chapter, preface, dedication, acknowledgements,
    appendix, glossary, bibliography, colophon, toc e index. Si esa hoja
    suma una, se suma acá, en cada predicado que las nombra, y en
    RAICES_PIEZA de validar_canonicos.sh.
  ============================================================================
-->
<s:schema xmlns:s="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">

  <s:title>Reglas de gbpublisher para el canónico DocBook</s:title>

  <s:ns prefix="db" uri="http://docbook.org/ns/docbook"/>

  <!-- ==========================================================================
       1. UBICACIÓN DE LA PIEZA
       seccion-libro y orden-seccion los escribe m_XML.GenerarInfoCapituloXML
       (bloque 2b) desde el nombre de archivo; tipo-capitulo, desde la base.
       ensamblar-libro-canonico.xsl los descarta y los vuelve a escribir desde
       el manifiesto. Un duplicado frena las hojas de salida:
       normalize-space() sobre dos nodos.
       tipo-capitulo se controla solo en cantidad: el catálogo de tipos está
       en la base, y el validador no la toca (SC-13). Puede faltar: con NULL
       en la base no se emite, y las hojas caen al elemento y su role.
       ========================================================================== -->
  <s:pattern id="gbp-ubicacion">
    <s:rule id="gbp-ubicacion-info" context="db:info[parent::db:chapter or parent::db:preface or parent::db:dedication or parent::db:acknowledgements or parent::db:appendix or parent::db:glossary or parent::db:colophon or parent::db:toc or parent::db:index][not(../parent::*) or ../parent::db:book]">
      <s:let name="pieza" value="concat('&lt;', local-name(..), '&gt;', if (../@xml:id) then concat(' ', ../@xml:id) else '')"/>
      <s:assert id="gbp-seccion-una" role="aviso" test="count(db:bibliomisc[@role = 'seccion-libro']) = 1"><s:value-of select="$pieza"/>: tiene <s:value-of select="count(db:bibliomisc[@role = 'seccion-libro'])"/> bibliomisc seccion-libro y debe tener uno; las hojas de salida frenan con más de uno</s:assert>
      <s:assert id="gbp-seccion-valor" role="aviso" test="every $s in db:bibliomisc[@role = 'seccion-libro'] satisfies normalize-space($s) = ('fm', 'a', 'bm')"><s:value-of select="$pieza"/>: seccion-libro vale «<s:value-of select="string-join(db:bibliomisc[@role = 'seccion-libro'], ', ')"/>» y tiene que ser fm, a o bm</s:assert>
      <s:assert id="gbp-orden-uno" role="aviso" test="count(db:bibliomisc[@role = 'orden-seccion']) = 1"><s:value-of select="$pieza"/>: tiene <s:value-of select="count(db:bibliomisc[@role = 'orden-seccion'])"/> bibliomisc orden-seccion y debe tener uno</s:assert>
      <s:assert id="gbp-orden-valor" role="aviso" test="every $o in db:bibliomisc[@role = 'orden-seccion'] satisfies matches(normalize-space($o), '^[0-9]{2}$')"><s:value-of select="$pieza"/>: orden-seccion vale «<s:value-of select="string-join(db:bibliomisc[@role = 'orden-seccion'], ', ')"/>» y tiene que ser de dos cifras</s:assert>
      <s:assert id="gbp-tipo-uno" role="aviso" test="count(db:bibliomisc[@role = 'tipo-capitulo']) le 1"><s:value-of select="$pieza"/>: tiene <s:value-of select="count(db:bibliomisc[@role = 'tipo-capitulo'])"/> bibliomisc tipo-capitulo y puede tener uno como mucho</s:assert>
      <s:assert id="gbp-tipo-vacio" role="aviso" test="every $t in db:bibliomisc[@role = 'tipo-capitulo'] satisfies normalize-space($t) != ''"><s:value-of select="$pieza"/>: el bibliomisc tipo-capitulo está vacío</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       2. ESTILO DE CITA Y MODELO DE BIBLIOGRAFÍA
       estilo-cita (SC-57): uno en cada pieza suelta, porque el PDF y la
       pasada de citas transforman la pieza y lo cotejan con el preámbulo;
       en el libro, uno solo, en su propio <info>, y ninguno en los
       capítulos, que ensamblar-libro-canonico.xsl descarta al copiar.
       lugar-bibliografia: uno en el <info> del libro.
       ========================================================================== -->
  <s:pattern id="gbp-estilo">
    <s:rule id="gbp-estilo-pieza" context="/*[not(self::db:book)]/db:info">
      <s:assert id="gbp-estilo-pieza-uno" role="aviso" test="count(db:bibliomisc[@role = 'estilo-cita']) = 1">la pieza tiene <s:value-of select="count(db:bibliomisc[@role = 'estilo-cita'])"/> bibliomisc estilo-cita y debe tener uno: sin él, el PDF frena la pieza (SC-57)</s:assert>
    </s:rule>
    <s:rule id="gbp-estilo-libro" context="/db:book/db:info">
      <s:assert id="gbp-estilo-libro-uno" role="aviso" test="count(db:bibliomisc[@role = 'estilo-cita']) = 1">el libro tiene <s:value-of select="count(db:bibliomisc[@role = 'estilo-cita'])"/> bibliomisc estilo-cita en su &lt;info&gt; y debe tener uno</s:assert>
      <s:assert id="gbp-lugar-bib-uno" role="aviso" test="count(db:bibliomisc[@role = 'lugar-bibliografia']) = 1">el libro tiene <s:value-of select="count(db:bibliomisc[@role = 'lugar-bibliografia'])"/> bibliomisc lugar-bibliografia y debe tener uno</s:assert>
      <s:assert id="gbp-lugar-bib-valor" role="aviso" test="every $l in db:bibliomisc[@role = 'lugar-bibliografia'] satisfies normalize-space($l) = ('por_capitulo', 'consolidada')">lugar-bibliografia vale «<s:value-of select="string-join(db:bibliomisc[@role = 'lugar-bibliografia'], ', ')"/>» y tiene que ser por_capitulo o consolidada</s:assert>
    </s:rule>
    <s:rule id="gbp-estilo-capitulo" context="/db:book/*/db:info">
      <s:assert id="gbp-estilo-capitulo-ninguno" role="aviso" test="empty(db:bibliomisc[@role = 'estilo-cita'])">&lt;<s:value-of select="local-name(..)"/>&gt; <s:value-of select="../@xml:id"/>: trae su propio estilo-cita dentro del libro; el ensamblado lo descarta, y el libro lo declara una sola vez</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       3. INSTRUCCIONES DE PROCESAMIENTO gb-*
       Las que el proyecto escribe y alguna hoja lee: gb-alinear (SC-61),
       gb-corte (SC-63), gb-cuadro (SC-66), gb-espacio (SC-39) y gb-fuente
       (SC-75). Una gb-* desconocida es un error de un filtro o una hoja
       vieja: ninguna salida la entiende. gb-fuente va en el prólogo: ahí la
       lee vigencia_canonico, y adentro de un elemento la copiaría la
       transformación identidad de alguna hoja.
       Sobre la raíz del documento (GV-XML-04).
       ========================================================================== -->
  <s:pattern id="gbp-pi">
    <s:rule id="gbp-pi-documento" context="/">
      <s:let name="desconocidas" value="//processing-instruction()[starts-with(name(), 'gb-')][not(name() = ('gb-alinear', 'gb-corte', 'gb-cuadro', 'gb-espacio', 'gb-fuente'))]"/>
      <s:let name="fuentes-adentro" value="//processing-instruction('gb-fuente')[parent::*]"/>
      <s:assert id="gbp-pi-conocida" role="aviso" test="empty($desconocidas)"><s:value-of select="count($desconocidas)"/> instrucción(es) de procesamiento desconocida(s): <s:value-of select="string-join(distinct-values(for $p in $desconocidas return name($p)), ', ')"/>; ninguna salida las interpreta</s:assert>
      <s:assert id="gbp-pi-fuente-prologo" role="aviso" test="empty($fuentes-adentro)"><s:value-of select="count($fuentes-adentro)"/> gb-fuente dentro del documento: van solo en el prólogo, antes de la raíz</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       4. CITAS BIBLIOGRÁFICAS
       Un biblioref cuyo destino está en el documento apunta a una entrada
       de bibliografía. Si el destino no está, no se dice nada acá: en una
       pieza es una remisión a la bibliografía consolidada, que se verifica
       en el libro (SC-53), y en el libro el IDREF colgado ya lo informa
       jing.
       ========================================================================== -->
  <s:pattern id="gbp-cita">
    <s:rule id="gbp-cita-destino" context="db:biblioref[@linkend]">
      <s:let name="destino" value="//*[@xml:id = current()/@linkend]"/>
      <s:assert id="gbp-cita-a-entrada" role="aviso" test="empty($destino) or $destino[1][self::db:biblioentry or self::db:bibliomixed]">la cita a «<s:value-of select="@linkend"/>» apunta a un &lt;<s:value-of select="local-name($destino[1])"/>&gt; y no a una entrada de bibliografía</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       5. ENTRADAS SIN CITAR (SOLO EN EL LIBRO)
       Una entrada de bibliografía que ningún biblioref cita. En la pieza no
       se mira: con bibliografía consolidada sus entradas no están en ella.
       Tenue: una bibliografía puede incluir obras consultadas sin cita.
       ========================================================================== -->
  <s:pattern id="gbp-bib">
    <s:rule id="gbp-bib-entrada" context="/db:book//db:biblioentry[@xml:id]">
      <s:assert id="gbp-bib-citada" role="tenue" test="@xml:id = //db:biblioref/@linkend">la entrada «<s:value-of select="@xml:id"/>» no se cita en el libro</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       6. FIGURAS Y CUADROS SIN REMITIR (SOLO EN EL LIBRO)
       Una figura o un cuadro con id que ningún xref nombra. En la pieza no
       se mira: la remisión puede estar en otra pieza (los fig-* y tbl-* son
       globales, SC-32, SC-66). Tenue: remitir es política editorial.
       ========================================================================== -->
  <s:pattern id="gbp-remision">
    <s:rule id="gbp-remision-objeto" context="/db:book//db:figure[@xml:id] | /db:book//db:table[@xml:id]">
      <s:assert id="gbp-remision-remitido" role="tenue" test="@xml:id = //db:xref/@linkend">&lt;<s:value-of select="local-name()"/>&gt; «<s:value-of select="@xml:id"/>» no se remite desde el texto</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       7. TEXTO ALTERNATIVO
       Toda imagen del texto lleva un texto alternativo no vacío: el EPUB
       accesible lo exige y el HTML lo usa. fenced-divs-to-elements-db.lua
       lo escribe en textobject/phrase con el declarado o, si no hay, con el
       pie sin formato: vacío solo si el pie también lo es. Los de <info>
       (la tapa) no entran: los arma cada salida.
       ========================================================================== -->
  <s:pattern id="gbp-alt">
    <s:rule id="gbp-alt-imagen" context="db:mediaobject[db:imageobject][not(ancestor::db:info)]">
      <s:assert id="gbp-alt-presente" role="aviso" test="normalize-space(string-join((db:textobject, db:alt), ' ')) != ''">la imagen «<s:value-of select="(db:imageobject/db:imagedata/@fileref)[1]"/>» no tiene texto alternativo<s:value-of select="if (ancestor::db:figure[1]/@xml:id) then concat(' (', ancestor::db:figure[1]/@xml:id, ')') else ''"/>: el EPUB accesible lo exige</s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       8. IDIOMA
       La raíz y cada pieza dentro del libro declaran xml:lang con forma de
       etiqueta de idioma (BCP 47: dos o tres letras, subetiquetas
       opcionales). Lo usan la división silábica del PDF, las comillas y el
       lector de pantalla. Solo la forma: el catálogo de idiomas está en la
       base (m_Idiomas), y el validador no la toca (SC-13).
       ========================================================================== -->
  <s:pattern id="gbp-idioma">
    <s:rule id="gbp-idioma-pieza" context="/* | /db:book/*[self::db:chapter or self::db:preface or self::db:dedication or self::db:acknowledgements or self::db:appendix or self::db:glossary or self::db:colophon or self::db:toc or self::db:index]">
      <s:assert id="gbp-idioma-presente" role="aviso" test="matches(string(@xml:lang), '^[a-z]{2,3}(-[A-Za-z0-9]{1,8})*$')">&lt;<s:value-of select="local-name()"/>&gt;<s:value-of select="if (@xml:id) then concat(' ', @xml:id) else ''"/>: xml:lang <s:value-of select="if (@xml:lang) then concat('vale «', @xml:lang, '» y no tiene forma de etiqueta de idioma') else 'falta'"/></s:assert>
    </s:rule>
  </s:pattern>

  <!-- ==========================================================================
       9. ANCHO DE LA IMAGEN
       El @width de un imagedata, si está, es la forma que escribe el filtro
       desde ancho=NN del shortcode: un entero de 1 a 100 seguido de %. El RNG
       de DocBook acepta cualquier texto en @width (medido: width="abc"
       valida), y las tres hojas de salida solo entienden esa forma: otra la
       ignoran y la figura sale al ancho de la columna. Se señala para que un
       canónico editado a mano no pierda el ancho en silencio (SC-76).
       ========================================================================== -->
  <s:pattern id="gbp-ancho">
    <s:rule id="gbp-ancho-imagen" context="db:imagedata[@width]">
      <s:assert id="gbp-ancho-forma" role="aviso" test="matches(string(@width), '^([1-9][0-9]?|100)%$')">la imagen «<s:value-of select="@fileref"/>» tiene width="<s:value-of select="@width"/>" y tiene que ser un porcentaje entero de 1 a 100 (60%); las salidas lo ignoran y la figura sale al ancho de la columna</s:assert>
    </s:rule>
  </s:pattern>

</s:schema>
