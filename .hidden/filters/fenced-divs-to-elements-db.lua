-- ~/.gbpublisher/filters/fenced-divs-to-elements-db.lua
-- =====================================================
-- FILTRO LUA PARA PANDOC - FENCED DIVS A DOCBOOK 5.2
-- =====================================================
-- ANALOGÍA CON REVISTAS:
--   ESTE FILTRO REEMPLAZA DOS FILTROS DEL PIPELINE JATS:
--     - unwrap-structural-divs.lua  (PARCIAL)
--     - table-to-end.lua            (FUSIONA CASO fullwidth/rotate)
--   PLUS LA LÓGICA DE Div() EMBEBIDA EN cite-to-xref.lua.
--   CONSOLIDADO EN UN SOLO ARCHIVO PORQUE EN DOCBOOK LA
--   CASUÍSTICA ES MENOR Y EL MANTENIMIENTO DE 3-4 ARCHIVOS
--   QUE COMPARTEN HELPERS NO SE JUSTIFICA.
--
-- ORDEN DE EJECUCIÓN: ESTE FILTRO DEBE CORRER DESPUÉS DE
--   cite-to-biblioref-db.lua, PORQUE EL DIV puede contener
--   PÁRRAFOS CON CITAS YA PROCESADAS COMO RawInline.
--
-- COBERTURA:
--   1. ESTRUCTURALES (.intro, .methods, etc.) → <section role="X">
--   2. FIG (.fig)                              → <figure xml:id="X">
--   3. TABLE (.table)                          → <table xml:id="X">
--   4. EPIGRAPH (.epigraph)                    → <epigraph><attribution>
--                                                (PARTIDO ANTES POR
--                                                dos-partes.lua — VER 6.4)
--   5. VERSE (.verse, SC-49)                   → <blockquote role="verso"> CON UN
--                                                <literallayout role="verse"> POR
--                                                ESTROFA (EN UN EPÍGRAFE, SIN EL
--                                                <blockquote>; VÍA verso.lua)
--   6. LISTADO (.listado #lst-, SC-42)         → <example role="listado">
--      (EL BLOQUE SUELTO ~~~ python LO ESCRIBE codigo.lua)
--   7. RECUADROS (recuadro, recuadrob, SC-41)  → <sidebar role="recuadro" | "recuadro-barra">
--   8. FORMULA (.formula)                      → <equation xml:id="X">
--   9. CONVERSACIÓN (.conversacion, SC-43)      → <qandaset role="conversacion">
--  10. FORMAL (.theorem/.definition/.proof)    → <example role="X">
-- =====================================================

-- =====================================================
-- 1. HELPERS DE ESCAPE XML
-- =====================================================

-- ESCAPADO XML PARA TEXTO DE ELEMENTO
local function escape_xml_text(s)
  if s == nil then return '' end
  s = s:gsub('&', '&amp;')
  s = s:gsub('<', '&lt;')
  s = s:gsub('>', '&gt;')
  return s
end

-- ESCAPADO XML PARA VALOR DE ATRIBUTO
local function escape_xml_attr(s)
  if s == nil then return '' end
  s = s:gsub('&', '&amp;')
  s = s:gsub('<', '&lt;')
  s = s:gsub('>', '&gt;')
  s = s:gsub('"', '&quot;')
  return s
end

-- =====================================================
-- 2. HELPERS DE SERIALIZACIÓN
-- =====================================================

-- SERIALIZA UNA LISTA DE INLINES A STRING DOCBOOK PRESERVANDO MARKUP.
-- ENVUELVE EN Plain BLOCK PARA QUE pandoc.write GENERE EL DOCBOOK
-- CORRECTO; LUEGO REMUEVE EL <para>...</para> WRAPPER.
-- HEREDA PANDOC_WRITER_OPTIONS PARA PROPAGAR --mathml Y OTRAS
-- OPCIONES DEL COMANDO ORIGINAL A LA SERIALIZACIÓN INTERNA.
local function inlines_a_docbook(inlines)
  if not inlines or #inlines == 0 then return '' end
  local docbook = pandoc.write(
    pandoc.Pandoc({pandoc.Plain(inlines)}),
    'docbook5',
    PANDOC_WRITER_OPTIONS)
  docbook = docbook:gsub('^%s*<para[^>]*>', '')
  docbook = docbook:gsub('</para>%s*$', '')
  docbook = docbook:gsub('^%s+', ''):gsub('%s+$', '')
  return docbook
end

-- SERIALIZA UNA LISTA DE BLOCKS A STRING DOCBOOK (SIN WRAPPER).
-- USADO PARA INSERTAR CONTENIDO COMPLEJO DENTRO DE UN RawBlock.
-- HEREDA PANDOC_WRITER_OPTIONS (VER NOTA EN inlines_a_docbook).
local function blocks_a_docbook(blocks)
  if not blocks or #blocks == 0 then return '' end
  local docbook = pandoc.write(
    pandoc.Pandoc(blocks),
    'docbook5',
    PANDOC_WRITER_OPTIONS)
  return docbook:gsub('^%s+', ''):gsub('%s+$', '')
end

-- =====================================================
-- 3. CONFIGURACIÓN: CLASES ESTRUCTURALES
-- =====================================================
-- ESTAS CLASES SE EMITEN COMO <section role="X" xml:id="...">
-- CON EL HEADER INTERIOR CAPTURADO COMO <title>.
-- LISTA HEREDADA DE unwrap-structural-divs.lua (PIPELINE JATS),
-- COMPLEMENTADA CON CLASES PROPIAS DE LIBROS ACADÉMICOS.
-- ACTUALIZAR ESTA TABLA AL AGREGAR/QUITAR UN SHORTCODE ESTRUCTURAL
-- EN LA BD CON tipo_marcado='fenced' Y mapeo_libro='section' O
-- 'sec' (REVISTAS).
local estructurales = {
  ["abstract"]              = true,
  ["acknowledgments"]       = true,
  ["appendix"]              = true,
  ["apparatus-physics"]     = true,
  ["book-review"]           = true,
  ["case-report"]           = true,
  ["conclusions"]           = true,
  ["conflict-of-interest"]  = true,
  ["correction"]            = true,
  ["correspondence"]        = true,
  ["discussion"]            = true,
  ["editorial"]             = true,
  ["experimental-procedure"] = true,
  ["intro"]                 = true,
  ["methods"]               = true,
  ["obituary"]              = true,
  ["oration"]               = true,
  ["results"]               = true,
  ["retraction"]            = true,
  ["review-article"]        = true,
  ["surgical-procedure"]    = true,
}

-- =====================================================
-- 4. (RETIRADO) TIPOS DE ADMONICIÓN
-- =====================================================
-- LA TABLA QUE LLEVABA EL type DEL VIEJO ::: {.box} A LAS ADMONICIONES DE
-- DOCBOOK (note, warning…) SE RETIRÓ CON ESE RECUADRO (SC-41). LAS
-- PLANTILLAS DE ADMONICIÓN DE LAS HOJAS QUEDAN: LAS VAN A USAR LOS
-- CALLOUTS.

-- =====================================================
-- 5. HELPERS DE PROCESAMIENTO
-- =====================================================

-- EXTRAE EL PRIMER Header DE UNA LISTA DE BLOCKS Y LO RETORNA
-- COMO STRING DOCBOOK PARA USAR DENTRO DE <title>. DEVUELVE
-- (title_string, blocks_resto). SI NO HAY Header AL INICIO,
-- DEVUELVE ('', blocks).
local function extraer_title(blocks)
  if not blocks or #blocks == 0 then return '', blocks end
  if blocks[1].t == 'Header' then
    local title_db = inlines_a_docbook(blocks[1].content)
    local resto = {}
    for i = 2, #blocks do resto[#resto + 1] = blocks[i] end
    return title_db, resto
  end
  return '', blocks
end

-- =====================================================
-- 6. FUNCIÓN PRINCIPAL: Div(el)
-- =====================================================
-- DISPATCHER QUE EXAMINA LAS CLASES DEL DIV Y EMITE EL ELEMENTO
-- DOCBOOK CORRESPONDIENTE COMO RawBlock.
-- DEVUELVE nil SI NO HAY MATCH PARA QUE PANDOC PROCESE EL DIV
-- NORMALMENTE (CASO POR DEFECTO: <sidebar> O <para>).
function Div(el)

  -- =====================================================
  -- 6.1. ESTRUCTURALES (.intro, .methods, .results, etc.)
  -- =====================================================
  -- PRESERVA LA CLASE COMO role EN <section>. CAPTURA EL HEADER
  -- INTERIOR COMO <title>. EL xml:id SE TOMA DEL Div PROPIO SI
  -- TIENE; SINO, DEL HEADER INTERIOR.
  for _, clase in ipairs(el.classes) do
    if estructurales[clase] then
      local title_db, resto = extraer_title(el.content)

      -- DERIVAR xml:id: PRIORIDAD AL DIV, FALLBACK AL HEADER
      local xml_id = el.identifier
      if (xml_id == nil or xml_id == '') and #el.content > 0
         and el.content[1].t == 'Header' then
        xml_id = el.content[1].identifier or ''
      end

      local id_attr = ''
      if xml_id ~= '' then
        id_attr = ' xml:id="' .. escape_xml_attr(xml_id) .. '"'
      end

      local title_xml = ''
      if title_db ~= '' then
        title_xml = '  <title>' .. title_db .. '</title>\n'
      end

      local contenido_db = blocks_a_docbook(resto)

      local raw =
        '<section role="' .. escape_xml_attr(clase) .. '"' .. id_attr .. '>\n' ..
        title_xml ..
        contenido_db .. '\n' ..
        '</section>'

      return pandoc.RawBlock('docbook', raw)
    end
  end

  -- =====================================================
  -- 6.2. FIGURA (.fig)
  -- =====================================================
  -- ESTRUCTURA EN MD (LA ÚNICA ADMITIDA):
  --   ::: {.fig #fig-mapa}
  --   ![Pie de la figura, con *formato* y citas [@clave]](media/fig-mapa.png)
  --   :::
  -- CON TEXTO ALTERNATIVO PROPIO PARA EL EPUB ACCESIBLE:
  --   ::: {.fig #fig-mapa alt="Mapa de la provincia con las rutas"}
  --
  -- EL <figure> SE ARMA ACÁ Y NO CON EL ESCRITOR DE PANDOC: EN PANDOC
  -- 3.1 EL ESCRITOR DocBook DESCARTA EL identifier DE UN Figure, Y SIN
  -- xml:id NO HAY \label NI REFERENCIA CRUZADA (VERIFICADO).
  --
  -- TRES FALLAS DETIENEN LA CONVERSIÓN CON UN MENSAJE, EN VEZ DE DEJAR
  -- UNA FIGURA A MEDIAS QUE SE DESCUBRE EN LA SALIDA (GV-23):
  --   - SIN #id: NO SE PUEDE NUMERAR NI REFERIR.
  --   - SIN PIE: <figure> EXIGE <title> (RC-DB-03) Y SIN \caption
  --     LaTeX NO LA NUMERA.
  --   - CONTENIDO ADEMÁS DE LA IMAGEN: SE PERDERÍA EN SILENCIO, COMO
  --     LE PASABA AL PÁRRAFO «Figura 1. …» DEL EJEMPLO VIEJO.
  -- .fullwidth → pgwide="1" (DOCBOOK 5.2 NATIVO).
  if el.classes:includes('fig') then
    local fig_id = el.identifier or ''
    local es_fullwidth = el.classes:includes('fullwidth')
    local imagen = nil
    local pie = {}
    local otros = 0

    -- BUSCAR LA IMAGEN: Figure (IMAGEN CON PIE) O Para/Plain CON UNA
    -- SOLA Image (IMAGEN SIN PIE, PARA DAR EL MENSAJE CORRECTO)
    for _, block in ipairs(el.content) do
      if block.t == 'Figure' and not imagen then
        for _, interno in ipairs(block.content) do
          if (interno.t == 'Plain' or interno.t == 'Para')
             and #interno.content == 1 and interno.content[1].t == 'Image' then
            imagen = interno.content[1]
          end
        end
        -- EL PIE ES EL CAPTION LARGO: UN SOLO BLOQUE DE INLINES
        if block.caption.long[1] then
          pie = block.caption.long[1].content
        end
      elseif (block.t == 'Para' or block.t == 'Plain') and not imagen
             and #block.content == 1 and block.content[1].t == 'Image' then
        imagen = block.content[1]
        pie = imagen.caption
      else
        otros = otros + 1
      end
    end

    if fig_id == '' then
      error('\n[figura] Una figura no tiene identificador. Se escribe ' ..
            '::: {.fig #fig-nombre}' ..
            (imagen and (' (imagen: ' .. imagen.src .. ')') or ''), 0)
    end
    if not imagen then
      error('\n[figura #' .. fig_id .. '] No tiene imagen: dentro del bloque ' ..
            'va una sola línea ![Pie](media/archivo.png)', 0)
    end
    if #pie == 0 then
      error('\n[figura #' .. fig_id .. '] No tiene pie: va entre los corchetes ' ..
            'de la imagen, ![Pie](' .. imagen.src .. ')', 0)
    end
    if otros > 0 then
      error('\n[figura #' .. fig_id .. '] El bloque tiene contenido además de ' ..
            'la imagen. El pie va entre los corchetes de la imagen.', 0)
    end

    -- TEXTO ALTERNATIVO: EL DECLARADO, O EL PIE SIN FORMATO
    -- (UNA CITA DEL PIE YA ES MARCADO DocBook Y stringify LA DESCARTA:
    -- EL ESPACIO QUE QUEDA ANTES SE RECORTA)
    local alt = el.attributes['alt'] or
                pandoc.utils.stringify(pie):gsub('^%s+', ''):gsub('%s+$', '')

    local pgwide = ''
    if es_fullwidth then pgwide = ' pgwide="1"' end

    local raw =
      '<figure xml:id="' .. escape_xml_attr(fig_id) .. '"' .. pgwide .. '>\n' ..
      '  <title>' .. inlines_a_docbook(pie) .. '</title>\n' ..
      '  <mediaobject>\n' ..
      '    <imageobject><imagedata fileref="' .. escape_xml_attr(imagen.src) .. '"/></imageobject>\n' ..
      '    <textobject><phrase>' .. escape_xml_text(alt) .. '</phrase></textobject>\n' ..
      '  </mediaobject>\n' ..
      '</figure>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.3. TABLA (.table)
  -- =====================================================
  -- MISMO PATRÓN QUE FIG: PROMOVER identifier AL Table INTERNO.
  -- .fullwidth → pgwide="1", .rotate → orient="land" (AMBOS DOCBOOK 5.2).
  if el.classes:includes('table') then
    local es_fullwidth = el.classes:includes('fullwidth')
    local es_rotate    = el.classes:includes('rotate')
    for i, block in ipairs(el.content) do
      if block.t == 'Table' then
        if el.identifier ~= '' then
          block.identifier = el.identifier
        end
        if es_fullwidth or es_rotate then
          local tab_db = pandoc.write(
            pandoc.Pandoc({block}), 'docbook5', PANDOC_WRITER_OPTIONS)
          if es_fullwidth then
            tab_db = tab_db:gsub('<table', '<table pgwide="1"', 1)
          end
          if es_rotate then
            tab_db = tab_db:gsub('<table([^>]*)', '<table%1 orient="land"', 1)
          end
          return pandoc.RawBlock('docbook', tab_db)
        end
        return pandoc.Blocks({block})
      end
    end
    return nil
  end

  -- =====================================================
  -- 6.4. EPÍGRAFE (.epigraph)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: epigraph
  --
  --   {texto}{atribución}
  --
  --   [/epigraph]: # ()
  --   :::
  --
  -- dos-partes.lua YA PARTIÓ EL BLOQUE EN DOS Div HIJOS
  -- (.epigrafe-texto, .epigrafe-atrib) Y CONTROLÓ LA FORMA. ACÁ SOLO SE
  -- SERIALIZA. DOCBOOK 5.2: <epigraph> = info?, attribution?,
  -- paragraph_elements+; LA ATRIBUCIÓN VA PRIMERO. SIN SEGUNDA PARTE NO
  -- HAY <attribution>, Y LA SALIDA NO PONE FILETE.
  if el.classes:includes('epigraph') then
    local texto, atrib = nil, nil
    for _, hijo in ipairs(el.content) do
      if hijo.t == 'Div' and hijo.classes:includes('epigrafe-texto') then texto = hijo end
      if hijo.t == 'Div' and hijo.classes:includes('epigrafe-atrib') then atrib = hijo end
    end
    -- SIN LOS HIJOS, dos-partes.lua NO CORRIÓ ANTES: ES UN ERROR DE CADENA
    if not texto then
      error('\n[gbpublisher] epigraph sin partir: dos-partes.lua tiene que correr antes que fenced-divs-to-elements-db.lua\n', 0)
    end
    local raw = '<epigraph>\n'
    if atrib then
      raw = raw .. '  <attribution>' ..
            inlines_a_docbook(atrib.content[1].content) ..
            '</attribution>\n'
    end
    for _, parrafo in ipairs(texto.content) do
      if parrafo.t == 'RawBlock' then
        -- UN VERSO (SC-49): YA SERIALIZADO COMO <literallayout>, SIN EL
        -- <blockquote> (6.5). dos-partes.lua CONTROLÓ QUE VAYA SOLO
        raw = raw .. parrafo.text .. '\n'
      else
        raw = raw .. '  <para>' .. inlines_a_docbook(parrafo.content) .. '</para>\n'
      end
    end
    raw = raw .. '</epigraph>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.4.1. FROUFROU (.froufrou): SEPARADOR ORNAMENTAL (SC-36)
  -- =====================================================
  -- ESTRUCTURA EN MD (EL BLOQUE ES VACÍO; EL ANCLA LA CONSUME PANDOC):
  --   ::: froufrou
  --
  --   [/froufrou]: # ()
  --   :::
  -- SALE <para role="froufrou">* * *</para>: DOCBOOK NO TIENE UN ELEMENTO
  -- DE SEPARACIÓN, Y EL TEXTO HACE QUE UN LECTOR SIN NUESTRAS HOJAS IGUAL
  -- MUESTRE EL CORTE. UN BLOQUE CON CONTENIDO DETIENE LA CONVERSIÓN: LO
  -- QUE ESTÉ ADENTRO SE PERDERÍA.
  if el.classes:includes('froufrou') then
    if #el.content > 0 then
      error('\n[froufrou] El separador no lleva contenido: entre ::: froufrou ' ..
            'y el cierre solo va el ancla [/froufrou]: # (). Contenido: ' ..
            pandoc.utils.stringify(el):sub(1, 60), 0)
    end
    return pandoc.RawBlock('docbook', '<para role="froufrou">* * *</para>')
  end

  -- =====================================================
  -- 6.5. VERSO (.verse, SC-49)
  -- =====================================================
  -- verso.lua YA CONTROLÓ EL BLOQUE Y LO DEJÓ NORMALIZADO: UN Div
  -- .estrofa POR ESTROFA Y, ADENTRO, UN Div .linea POR VERSO, CON EL
  -- NIVEL DE SANGRÍA EN EL ATRIBUTO nivel. ACÁ SOLO SE SERIALIZA.
  --
  -- DOCBOOK 5.2 BASE NO TIENE <poetry> NI <line> (RC-DB-04):
  --   <blockquote role="verso">
  --     <literallayout role="verse"><phrase role="linea">…</phrase>
  --   <phrase role="linea">…</phrase></literallayout>
  --   </blockquote>
  -- UN <literallayout> POR ESTROFA; CADA VERSO EN UN <phrase role="linea">
  -- PARA QUE LAS HOJAS LO TOMEN CON SUS MARCAS. LA SANGRÍA VA COMO DOS
  -- ESPACIOS POR NIVEL DELANTE DEL <phrase>: <literallayout> REPRODUCE
  -- LOS ESPACIOS TAL CUAL, Y ASÍ UN PROCESADOR DOCBOOK CUALQUIERA LA
  -- MUESTRA. EN UN EPÍGRAFE (CLASE en-epigrafe, DE dos-partes.lua) VAN
  -- SOLO LOS <literallayout>: <epigraph> NO ADMITE <blockquote>.
  -- EL FIN DE VERSO SE ESCRIBE &#10; Y NO COMO SALTO: EL ESCRITOR DOCBOOK
  -- DE PANDOC SANGRA CADA LÍNEA DE UN RawBlock SEGÚN LA PROFUNDIDAD DE LA
  -- SECCIÓN, Y ESA SANGRÍA SE SUMARÍA A LA DEL VERSO (GV-95). CON LA
  -- REFERENCIA, EL <literallayout> ES UNA SOLA LÍNEA DEL ARCHIVO Y SUS
  -- ESPACIOS NO SE TOCAN; EL PARSER XML LA CONVIERTE EN EL SALTO.
  if el.classes:includes('verse') then
    local estrofas = {}
    for _, estrofa in ipairs(el.content) do
      local lineas = {}
      for _, linea in ipairs(estrofa.content) do
        local nivel = tonumber(linea.attributes['nivel']) or 0
        lineas[#lineas + 1] = string.rep('  ', nivel) ..
          '<phrase role="linea">' ..
          (inlines_a_docbook(linea.content[1].content)) ..
          '</phrase>'
      end
      estrofas[#estrofas + 1] = '<literallayout role="verse">' ..
        table.concat(lineas, '&#10;') .. '</literallayout>'
    end
    local raw = table.concat(estrofas, '\n')
    if not el.classes:includes('en-epigrafe') then
      raw = '<blockquote role="verso">\n' .. raw .. '\n</blockquote>'
    end
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.6. LISTADO DE CÓDIGO (.listado #lst-…, SC-42)
  -- =====================================================
  -- <example role="listado" xml:id="lst-…"><title>PIE</title>
  -- <programlisting language="…">…</programlisting></example>.
  -- codigo.lua YA CONTROLÓ LA FORMA Y ESCRIBIÓ EL BLOQUE: EL Div LLEGA
  -- CON DOS HIJOS, EL RawBlock DEL programlisting Y EL Para DEL PIE.
  -- <example> Y NO <figure>: SIGUE EL PATRÓN DE LOS FORMALES (6.10) Y NO
  -- SE MEZCLA CON LA NUMERACIÓN DE LAS FIGURAS. VALIDA CONTRA EL RNG DE
  -- DOCBOOK 5.2. EL BLOQUE SUELTO (~~~ python) LO ESCRIBE codigo.lua Y
  -- NO PASA POR ACÁ; EL VIEJO ::: {.code} LO FRENA codigo.lua.
  if el.classes:includes('listado') then
    local bloque, pie = el.content[1], el.content[2]
    if #el.content ~= 2 or bloque.t ~= 'RawBlock' or bloque.format ~= 'docbook'
       or (pie.t ~= 'Para' and pie.t ~= 'Plain') then
      error('\n[código] listado #' .. el.identifier .. ' sin preparar: codigo.lua ' ..
            'tiene que correr antes que fenced-divs-to-elements-db.lua\n', 0)
    end
    local raw = '<example role="listado" xml:id="' .. escape_xml_attr(el.identifier) .. '">\n' ..
                '  <title>' .. inlines_a_docbook(pie.content) .. '</title>\n' ..
                bloque.text .. '\n' ..
                '</example>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.7. RECUADROS (SC-41)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: recuadro                  ::: recuadrob
  --   Párrafos.                     {Barra}{Párrafos.}
  --   :::                           :::
  --
  -- recuadros.lua YA CONTROLÓ LA FORMA: SOLO PÁRRAFOS, SIN NOTAS Y SIN
  -- .fullwidth (EN LIBROS NO HAY COLUMNA LATERAL). LAS CITAS YA LLEGAN
  -- RESUELTAS POR cite-to-biblioref-db.lua. EL recuadrob LLEGA PARTIDO
  -- POR dos-partes.lua: LA BARRA VA AL <title> DEL sidebar, QUE ADMITE
  -- MARCAS EN LÍNEA (VALIDADO CONTRA EL RNG).
  -- EL VIEJO ::: {.box} SE RETIRÓ: LO FRENA recuadros.lua.
  if el.classes:includes('recuadro') then
    return pandoc.RawBlock('docbook', '<sidebar role="recuadro">\n' ..
                                      blocks_a_docbook(el.content) .. '\n</sidebar>')
  end

  if el.classes:includes('recuadrob') then
    local barra, texto = '', ''
    for _, hijo in ipairs(el.content) do
      if hijo.classes:includes('recuadro-barra') then
        barra = inlines_a_docbook(hijo.content[1].content)
      elseif hijo.classes:includes('recuadro-texto') then
        texto = blocks_a_docbook(hijo.content)
      end
    end
    if barra == '' then
      error('\n[gbpublisher] recuadrob sin partir: dos-partes.lua tiene que correr antes que fenced-divs-to-elements-db.lua\n', 0)
    end
    return pandoc.RawBlock('docbook', '<sidebar role="recuadro-barra">\n<title>' .. barra ..
                                      '</title>\n' .. texto .. '\n</sidebar>')
  end

  -- =====================================================
  -- 6.8. FÓRMULA (.formula)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.formula #eq-energia}
  --   $$E = mc^2$$
  --   :::
  --
  -- PANDOC POR DEFECTO EMITE <para xml:id="..."><informalequation>...
  -- ESTE FILTRO EXTRAE EL Math INLINE Y LO ENVUELVE EN
  -- <equation xml:id="..."> (PERMITE NUMERACIÓN AUTOMÁTICA).
  if el.classes:includes('formula') then
    local eq_id = el.identifier or ''
    -- BUSCAR EL Math DENTRO DEL PRIMER Para
    local math_inline = nil
    for _, block in ipairs(el.content) do
      if block.t == 'Para' or block.t == 'Plain' then
        for _, inline in ipairs(block.content) do
          if inline.t == 'Math' then
            math_inline = inline
            break
          end
        end
        if math_inline then break end
      end
    end
    if not math_inline then return nil end

    -- SERIALIZAR EL Math A DOCBOOK (PRODUCE <informalequation><mml:math>...)
    -- LUEGO REEMPLAZAR INFORMAL POR EQUATION CON EL ID.
    -- HEREDA PANDOC_WRITER_OPTIONS PARA PROPAGAR --mathml. SIN ESTO,
    -- PANDOC RENDERIZARÍA EL Math COMO MARKUP INLINE (italics + spaces)
    -- EN VEZ DE MathML, Y NO EMITIRÍA <informalequation>, ROMPIENDO EL
    -- WRAPPER <equation>.
    local serializado = pandoc.write(
      pandoc.Pandoc({pandoc.Para({math_inline})}),
      'docbook5',
      PANDOC_WRITER_OPTIONS)
    -- LIMPIAR EL WRAPPER <para>...</para>
    serializado = serializado:gsub('^%s*<para[^>]*>%s*', '')
    serializado = serializado:gsub('%s*</para>%s*$', '')
    -- REEMPLAZAR <informalequation> POR <equation xml:id="...">
    local id_attr = ''
    if eq_id ~= '' then
      id_attr = ' xml:id="' .. escape_xml_attr(eq_id) .. '"'
    end
    serializado = serializado:gsub(
      '<informalequation>', '<equation' .. id_attr .. '>')
    serializado = serializado:gsub(
      '</informalequation>', '</equation>')

    return pandoc.RawBlock('docbook', serializado)
  end

  -- =====================================================
  -- 6.9. CONVERSACIÓN (::: conversacion, SC-43)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: conversacion
  --   ::: {.pregunta quien="Ana Pérez"}   ::: respuesta   ::: acotacion
  --   (CADA UNO CON SU ANCLA DE CIERRE, SC-33)
  --
  -- DOCBOOK 5.2 BASE NO TIENE <dialogue> (RC-DB-04), PERO SÍ <qandaset>
  -- (GV-82). CADA PREGUNTA ABRE UNA <qandaentry>; LAS RESPUESTAS QUE LA
  -- SIGUEN SON <answer> DE ESA MISMA ENTRADA. quien → <label> DEL TURNO;
  -- SIN quien NO HAY <label>, Y LA HOJA PONE LA ETIQUETA SEGÚN
  -- defaultlabel="qanda" Y EL IDIOMA DEL LIBRO. LA ACOTACIÓN ES UN
  -- <para role="acotacion">: ANTES DE LA PRIMERA ENTRADA VA SUELTA EN EL
  -- qandaset; DESPUÉS, AL FINAL DEL TURNO ANTERIOR, PORQUE EL ESQUEMA NO
  -- LA ADMITE ENTRE ENTRADAS (GV-82).
  -- conversacion.lua YA CONTROLÓ LA FORMA: EL PRIMER TURNO ES UNA PREGUNTA,
  -- NADA VACÍO NI ANIDADO. EL VIEJO ::: {.speech} LO FRENA conversacion.lua.
  if el.classes:includes('conversacion') then
    local previas = {}
    local turnos = {}

    -- --- 1. RECORRER LOS HIJOS: TURNOS Y ACOTACIONES EN ORDEN ---
    for _, hijo in ipairs(el.content) do
      if hijo.classes:includes('acotacion') then
        local acotacion = {}
        for _, parrafo in ipairs(hijo.content) do
          acotacion[#acotacion + 1] = '<para role="acotacion">' ..
                                      inlines_a_docbook(parrafo.content) .. '</para>'
        end
        -- ANTES DEL PRIMER TURNO, SUELTA; DESPUÉS, DENTRO DEL TURNO ANTERIOR
        if #turnos == 0 then
          previas[#previas + 1] = table.concat(acotacion, '\n')
        else
          local t = turnos[#turnos]
          t.cuerpo[#t.cuerpo + 1] = table.concat(acotacion, '\n')
        end
      else
        turnos[#turnos + 1] = {
          tipo   = hijo.classes:includes('pregunta') and 'question' or 'answer',
          quien  = hijo.attributes['quien'],
          -- ENTRE PARÉNTESIS: blocks_a_docbook DEVUELVE LO QUE DEVUELVE gsub,
          -- LA CADENA Y LA CANTIDAD DE REEMPLAZOS; SIN ELLOS, LA CANTIDAD
          -- ENTRARÍA A LA TABLA COMO UN SEGUNDO ELEMENTO
          cuerpo = { (blocks_a_docbook(hijo.content)) },
        }
      end
    end

    -- SIN PREGUNTA PRIMERO NO HAY qandaentry VÁLIDA: conversacion.lua NO CORRIÓ
    if #turnos == 0 or turnos[1].tipo ~= 'question' then
      error('\n[gbpublisher] conversación sin controlar: conversacion.lua tiene que ' ..
            'correr antes que fenced-divs-to-elements-db.lua\n', 0)
    end

    -- --- 2. ARMAR EL qandaset ---
    local partes = { '<qandaset defaultlabel="qanda" role="conversacion">' }
    for _, previa in ipairs(previas) do partes[#partes + 1] = previa end
    for i, t in ipairs(turnos) do
      -- UNA PREGUNTA CIERRA LA ENTRADA ANTERIOR Y ABRE OTRA
      if t.tipo == 'question' then
        if i > 1 then partes[#partes + 1] = '</qandaentry>' end
        partes[#partes + 1] = '<qandaentry>'
      end
      local label = ''
      if t.quien then
        -- ESCAPAR: quien VA A TEXTO DE ELEMENTO
        label = '<label>' .. escape_xml_text(t.quien) .. '</label>\n'
      end
      partes[#partes + 1] = '<' .. t.tipo .. '>\n' .. label ..
                            table.concat(t.cuerpo, '\n') .. '\n</' .. t.tipo .. '>'
    end
    partes[#partes + 1] = '</qandaentry>'
    partes[#partes + 1] = '</qandaset>'
    return pandoc.RawBlock('docbook', table.concat(partes, '\n'))
  end

  -- =====================================================
  -- 6.10b. CITA DE FUENTE PRIMARIA (.source archivo= / .primary-source fuente=)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.source archivo="AGN, Sala IX, Legajo 23-5-6"}
  --   Texto de la cita documental.
  --   :::
  -- O:
  --   ::: {.primary-source fuente="BNE Ms. 1234, f. 23r"}
  --   Texto de la cita.
  --   :::
  --
  -- AMBAS SON CITAS DE FUENTE CON PROCEDENCIA. EN DOCBOOK 5.2 SE
  -- MODELAN COMO <blockquote> CON <attribution> (LA PROCEDENCIA) Y
  -- role="source" PARA DISTINGUIRLAS DE UNA CITA COMÚN.
  if el.classes:includes('source') or el.classes:includes('primary-source') then
    -- LA PROCEDENCIA VIENE DEL ATRIBUTO archivo= O fuente=
    local procedencia = el.attributes['archivo'] or el.attributes['fuente'] or ''
    local contenido_db = blocks_a_docbook(el.content)
    local raw = '<blockquote role="source">\n'
    if procedencia ~= '' then
      raw = raw .. '  <attribution>' ..
            escape_xml_text(procedencia) ..
            '</attribution>\n'
    end
    raw = raw .. contenido_db .. '\n</blockquote>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.10c. GLOSARIO (.glossary term=)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.glossary term="Hermenéutica"}
  --   Método de interpretación de textos.
  --   :::
  --
  -- SE MODELA COMO <variablelist role="glossary"> CON UNA ENTRADA
  -- (term + listitem), PARA REUSAR EL RENDER DE LISTA DE DEFINICIÓN.
  if el.classes:includes('glossary') then
    local term = el.attributes['term'] or ''
    local contenido_db = blocks_a_docbook(el.content)
    local raw = '<variablelist role="glossary">\n' ..
                '  <varlistentry>\n' ..
                '    <term>' .. escape_xml_text(term) .. '</term>\n' ..
                '    <listitem>\n' .. contenido_db .. '\n    </listitem>\n' ..
                '  </varlistentry>\n' ..
                '</variablelist>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.10d. MATERIAL SUPLEMENTARIO (.supplementary #id)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.supplementary #supp-datos}
  --   Descripción del material adicional.
  --   :::
  --
  -- DOCBOOK 5.2 BASE NO TIENE UN ELEMENTO NATIVO DE "MATERIAL
  -- SUPLEMENTARIO"; SE MODELA COMO <sidebar role="supplementary">
  -- CONSERVANDO EL xml:id PARA REFERENCIA CRUZADA.
  if el.classes:includes('supplementary') then
    local id_attr = ''
    if el.identifier ~= '' then
      id_attr = ' xml:id="' .. escape_xml_attr(el.identifier) .. '"'
    end
    local contenido_db = blocks_a_docbook(el.content)
    local raw = '<sidebar role="supplementary"' .. id_attr .. '>\n' ..
                contenido_db .. '\n</sidebar>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.10. FORMAL (.theorem, .definition, .proof, etc.)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.theorem #thm-pitagoras}
  --   ### Teorema de Pitágoras
  --
  --   Enunciado del teorema.
  --   :::
  --
  -- O TAMBIÉN SIN HEADER (FALLBACK AUTOMÁTICO POR CLASE):
  --   ::: {.theorem #thm-pitagoras}
  --   Enunciado del teorema.
  --   :::
  --
  -- EMITE <example role="X" xml:id="Y"><title>Z</title>...</example>.
  -- TÍTULO OBLIGATORIO: <example> EN DOCBOOK 5.2 ES UN FORMAL OBJECT
  -- Y REQUIERE <title>. EL FILTRO LO CAPTURA DEL Header INTERIOR SI
  -- EL AUTOR LO PUSO; SINO, GENERA UNO POR DEFECTO A PARTIR DE LA
  -- CLASE (Teorema, Definición, Demostración, ...).
  -- EL XSLT DE SALIDA (HTML/PDF) PUEDE OCULTAR VISUALMENTE EL <title>
  -- Y RENDERIZAR LA NUMERACIÓN AUTOMÁTICA ("Teorema 1.1") VÍA CSS/XSL.
  local formales = { theorem = true, definition = true, proof = true,
                     lemma = true, corollary = true, axiom = true,
                     proposition = true }
  local titulos_fallback = {
    theorem     = "Teorema",
    definition  = "Definición",
    proof       = "Demostración",
    lemma       = "Lema",
    corollary   = "Corolario",
    axiom       = "Axioma",
    proposition = "Proposición",
  }
  for _, clase in ipairs(el.classes) do
    if formales[clase] then
      local id_attr = ''
      if el.identifier ~= '' then
        id_attr = ' xml:id="' .. escape_xml_attr(el.identifier) .. '"'
      end

      -- CAPTURAR Header INICIAL COMO <title>; SI NO HAY, USAR FALLBACK
      local title_db, resto = extraer_title(el.content)
      if title_db == '' then
        title_db = escape_xml_text(titulos_fallback[clase])
      end

      local contenido_db = blocks_a_docbook(resto)
      local raw = '<example role="' .. clase .. '"' .. id_attr .. '>\n' ..
                  '  <title>' .. title_db .. '</title>\n' ..
                  contenido_db .. '\n' ..
                  '</example>'
      return pandoc.RawBlock('docbook', raw)
    end
  end

  -- =====================================================
  -- DEFAULT: NO MATCH
  -- =====================================================
  -- DEVOLVER nil PARA QUE PANDOC PROCESE EL DIV NORMALMENTE.
  -- COMPORTAMIENTO POR DEFECTO: PANDOC EMITE <sidebar> O <para>
  -- SEGÚN EL CONTENIDO. SI APARECE UN DIV NO RECONOCIDO EN UN
  -- ARCHIVO REAL, AGREGAR LA CLASE A LA SECCIÓN APROPIADA DE
  -- ESTE FILTRO O DECIDIR SU MAPEO.
  return nil
end
