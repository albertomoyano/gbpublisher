-- ~/.gbpublisher/filters/fenced-divs-to-elements-db.lua
-- =====================================================
-- FILTRO LUA PARA PANDOC - FENCED DIVS A DOCBOOK 5.2
-- =====================================================
-- ANALOGÍA CON REVISTAS:
--   ESTE FILTRO REEMPLAZA TRES FILTROS DEL PIPELINE JATS:
--     - unwrap-structural-divs.lua  (PARCIAL)
--     - figure-to-end.lua           (FUSIONA CASO fullwidth)
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
--   4. EPIGRAPH (.epigraph)                    → <blockquote><attribution>
--                                                (DocBook 5.2 NO acepta
--                                                attribution en epigraph
--                                                directamente — VER NOTA EN 6.4)
--   5. VERSE (.verse)                          → <literallayout role="verse">
--   6. CODE (.code language=)                  → <programlisting language="X">
--   7. BOX (.box type=)                        → <warning>/<note>/etc.
--   8. FORMULA (.formula)                      → <equation xml:id="X">
--   9. SPEECH (.speech speaker=)               → <para role="speech">
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
-- 4. CONFIGURACIÓN: TIPOS DE ADMONICIÓN
-- =====================================================
-- MAPEO DEL ATRIBUTO type DEL DIV .box A LOS SEIS ELEMENTOS
-- DE ADMONICIÓN NATIVOS DE DOCBOOK 5.2. CUALQUIER OTRO VALOR
-- DE type CAE AL FALLBACK <sidebar role="{type}">.
local admoniciones = {
  ["warning"]   = "warning",
  ["caution"]   = "caution",
  ["note"]      = "note",
  ["important"] = "important",
  ["tip"]       = "tip",
  ["danger"]    = "danger",  -- NUEVO EN DOCBOOK 5.2
}

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

-- DIVIDE UNA LISTA DE INLINES EN "LÍNEAS" SEPARADAS POR SoftBreak
-- O LineBreak. CADA LÍNEA ES UNA SUB-LISTA DE INLINES. USADO POR
-- VERSE Y EPIGRAPH.
local function dividir_por_break(inlines)
  local lineas = {}
  local actual = {}
  for _, inline in ipairs(inlines) do
    if inline.t == 'SoftBreak' or inline.t == 'LineBreak' then
      if #actual > 0 then
        lineas[#lineas + 1] = actual
        actual = {}
      end
    else
      actual[#actual + 1] = inline
    end
  end
  if #actual > 0 then lineas[#lineas + 1] = actual end
  return lineas
end

-- DETERMINA SI UNA LISTA DE INLINES REPRESENTA UNA LÍNEA DE
-- ATRIBUCIÓN EN UN EPIGRAPH. PATRÓN: EMPIEZA CON "—" (EM-DASH)
-- O "--" (DOBLE GUION INTERPRETADO COMO EN-DASH "–" POR PANDOC).
-- LA CHECK USA EL PRIMER Str DESPUÉS DE SALTAR Space INICIAL.
local function es_linea_atribucion(inlines)
  if not inlines or #inlines == 0 then return false end
  local i = 1
  while i <= #inlines and inlines[i].t == 'Space' do i = i + 1 end
  if i > #inlines then return false end
  local primer = inlines[i]
  if primer.t ~= 'Str' then return false end
  -- EM-DASH (—), EN-DASH (–), O DOBLE GUION LITERAL (--)
  return primer.text:sub(1,1) == '\xE2'  -- INICIO DE EM/EN-DASH UTF-8
         or primer.text:sub(1,2) == '--'
         or primer.text == '\xE2\x80\x94'  -- EM DASH EXACTO
         or primer.text == '\xE2\x80\x93'  -- EN DASH EXACTO
end

-- REMUEVE EL PREFIJO DE GUIONES Y ESPACIOS DE UNA LÍNEA DE
-- ATRIBUCIÓN. CONVIERTE "— Autor" / "-- Autor" / "– Autor" → "Autor"
-- OPERANDO SOBRE EL PRIMER Str DE LA LISTA.
local function limpiar_atribucion(inlines)
  local lista = {}
  for i, v in ipairs(inlines) do lista[i] = v end
  -- SALTAR Space INICIAL
  while #lista > 0 and lista[1].t == 'Space' do
    table.remove(lista, 1)
  end
  if #lista == 0 then return lista end
  if lista[1].t == 'Str' then
    local texto = lista[1].text
    -- REMOVER EM-DASH, EN-DASH O DOBLE GUION INICIAL
    texto = texto:gsub('^\xE2\x80\x94', '')  -- EM DASH
    texto = texto:gsub('^\xE2\x80\x93', '')  -- EN DASH
    texto = texto:gsub('^%-%-', '')          -- DOBLE GUION
    texto = texto:gsub('^%s+', '')           -- ESPACIOS RESTANTES
    if texto == '' then
      table.remove(lista, 1)
      while #lista > 0 and lista[1].t == 'Space' do
        table.remove(lista, 1)
      end
    else
      lista[1] = pandoc.Str(texto)
    end
  end
  return lista
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
  -- PROMUEVE EL identifier DEL Div AL Figure INTERNO Y ELIMINA
  -- EL WRAPPER. ASÍ PANDOC EMITE <figure xml:id="X"> DIRECTAMENTE,
  -- SIN EL <anchor> SEPARADO QUE GENERA POR DEFAULT.
  -- MANEJA TAMBIÉN .fullwidth → atributo pgwide="1" (DOCBOOK 5.2 NATIVO).
  if el.classes:includes('fig') then
    local es_fullwidth = el.classes:includes('fullwidth')
    -- BUSCAR EL Figure INTERNO Y PROMOVER ID
    for i, block in ipairs(el.content) do
      if block.t == 'Figure' then
        if el.identifier ~= '' then
          block.identifier = el.identifier
        end
        -- pgwide PARA FULLWIDTH: ATRIBUTO XML DIRECTO
        -- PANDOC NO LO RESPETA EN EL AST DE Figure, SE EMITE
        -- COMO RawBlock RECONSTRUYENDO EL <figure>
        if es_fullwidth then
          -- SERIALIZAR EL Figure A DOCBOOK, INYECTAR pgwide="1"
          local fig_db = pandoc.write(
            pandoc.Pandoc({block}), 'docbook5', PANDOC_WRITER_OPTIONS)
          fig_db = fig_db:gsub('<figure', '<figure pgwide="1"', 1)
          return pandoc.RawBlock('docbook', fig_db)
        end
        return pandoc.Blocks({block})
      end
    end
    -- FALLBACK: SI NO HAY Figure INTERNO, DEJAR QUE PANDOC PROCESE
    return nil
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
  -- ESTRUCTURA ESPERADA EN MD:
  --   ::: epigraph
  --   Texto de la cita.
  --   -- Autor   (O — Autor / – Autor)
  --   :::
  --
  -- NOTA SOBRE EL SCHEMA: EN DOCBOOK 5.2 BASE, <epigraph> ACEPTA
  -- <attribution> COMO HIJO (content model: info?, attribution?,
  -- paragraph_elements+). USAMOS <epigraph> DIRECTAMENTE.
  if el.classes:includes('epigraph') then
    -- ASUMIMOS UN ÚNICO Para CON SoftBreaks COMO SEPARADORES.
    -- (ES LO QUE PANDOC PRODUCE EN ESTE CASO; VERIFICADO EMPÍRICAMENTE.)
    local para = el.content[1]
    if not para or (para.t ~= 'Para' and para.t ~= 'Plain') then
      return nil
    end

    local lineas = dividir_por_break(para.content)
    if #lineas == 0 then return nil end

    -- DETECTAR LÍNEA DE ATRIBUCIÓN (ÚLTIMA QUE EMPIEZA CON --, — O –)
    local attribution_inlines = nil
    local texto_inlines = {}
    for i, linea in ipairs(lineas) do
      if i == #lineas and es_linea_atribucion(linea) then
        attribution_inlines = limpiar_atribucion(linea)
      else
        -- AGREGAR A texto, CON ESPACIO ENTRE LÍNEAS
        if #texto_inlines > 0 then
          texto_inlines[#texto_inlines + 1] = pandoc.Space()
        end
        for _, inl in ipairs(linea) do
          texto_inlines[#texto_inlines + 1] = inl
        end
      end
    end

    local texto_db = inlines_a_docbook(texto_inlines)
    local raw = '<epigraph>\n'
    if attribution_inlines then
      raw = raw .. '  <attribution>' ..
            inlines_a_docbook(attribution_inlines) ..
            '</attribution>\n'
    end
    raw = raw .. '  <para>' .. texto_db .. '</para>\n</epigraph>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.5. VERSO (.verse)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: verse
  --   Línea uno
  --   Línea dos
  --   :::
  --
  -- EMITE <literallayout role="verse"> CON LINE BREAKS LITERALES.
  -- ITERA SOBRE LOS INLINES PARA PRESERVAR SOFTBREAKS QUE
  -- pandoc.utils.stringify() COLAPSARÍA EN UNA SOLA LÍNEA.
  if el.classes:includes('verse') then
    local tokens = {}
    for _, block in ipairs(el.content) do
      if block.t == 'Para' or block.t == 'Plain' then
        for _, inline in ipairs(block.content) do
          if inline.t == 'Str' then
            tokens[#tokens + 1] = escape_xml_text(inline.text)
          elseif inline.t == 'SoftBreak' or inline.t == 'LineBreak' then
            tokens[#tokens + 1] = '\n'
          elseif inline.t == 'Space' then
            tokens[#tokens + 1] = ' '
          else
            -- MARKUP INLINE (Emph, Strong, Code, etc.): SERIALIZAR
            tokens[#tokens + 1] = inlines_a_docbook({inline})
          end
        end
      end
    end
    local raw = '<literallayout role="verse">' ..
                table.concat(tokens) ..
                '</literallayout>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.6. CÓDIGO (.code language=)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.code language="python"}
  --   ~~~
  --   def factorial(n):
  --       ...
  --   ~~~
  --   :::
  --
  -- PANDOC POR DEFECTO EMITE <programlisting> SIN EL ATRIBUTO
  -- language. ESTE FILTRO LO AGREGA. ATRIBUTO language ES NATIVO
  -- DE DOCBOOK 5.2 EN <programlisting>.
  if el.classes:includes('code') then
    local language = el.attributes['language'] or ''
    local contenido = ''
    for _, block in ipairs(el.content) do
      if block.t == 'CodeBlock' then
        contenido = block.text
      end
    end
    -- ESCAPAR XML EN EL CONTENIDO
    contenido = contenido:gsub('&', '&amp;')
    contenido = contenido:gsub('<', '&lt;')
    contenido = contenido:gsub('>', '&gt;')

    local lang_attr = ''
    if language ~= '' then
      lang_attr = ' language="' .. escape_xml_attr(language) .. '"'
    end
    local raw = '<programlisting' .. lang_attr .. '>' ..
                contenido .. '</programlisting>'
    return pandoc.RawBlock('docbook', raw)
  end

  -- =====================================================
  -- 6.7. RECUADRO (.box type=)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.box type="warning"}
  --   **Advertencia**: Texto del recuadro.
  --   :::
  --
  -- MAPEO DE type A ADMONICIÓN DOCBOOK NATIVA. SI type NO ESTÁ EN
  -- LA TABLA DE admoniciones, FALLBACK A <sidebar role="{type}">.
  if el.classes:includes('box') then
    local box_type = el.attributes['type'] or ''
    local contenido_db = blocks_a_docbook(el.content)

    local elemento = admoniciones[box_type]
    if elemento then
      local raw = '<' .. elemento .. '>\n' ..
                  contenido_db .. '\n' ..
                  '</' .. elemento .. '>'
      return pandoc.RawBlock('docbook', raw)
    else
      -- FALLBACK: SIDEBAR CON ROLE PRESERVANDO EL VALOR ORIGINAL
      local role_attr = ''
      if box_type ~= '' then
        role_attr = ' role="' .. escape_xml_attr(box_type) .. '"'
      end
      local raw = '<sidebar' .. role_attr .. '>\n' ..
                  contenido_db .. '\n' ..
                  '</sidebar>'
      return pandoc.RawBlock('docbook', raw)
    end
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
  -- 6.9. SPEECH (.speech speaker=)
  -- =====================================================
  -- ESTRUCTURA EN MD:
  --   ::: {.speech speaker="Entrevistado A"}
  --   Texto de la intervención.
  --   :::
  --
  -- DOCBOOK 5.2 BASE NO TIENE <dialogue>/<speech> (ESTÁN EN
  -- DOCBOOK PUBLISHERS V1, OTRO SCHEMA). EMITIMOS UN <para>
  -- CON role="speech" Y EL HABLANTE MARCADO TIPOGRÁFICAMENTE
  -- COMO <emphasis role="speaker">. PRESERVA LA SEMÁNTICA
  -- Y SE MANTIENE EN EL SCHEMA BASE.
  if el.classes:includes('speech') then
    local speaker = el.attributes['speaker'] or ''
    -- TOMAR EL CONTENIDO DEL PRIMER Para
    local contenido_db = ''
    for _, block in ipairs(el.content) do
      if block.t == 'Para' or block.t == 'Plain' then
        contenido_db = inlines_a_docbook(block.content)
        break
      end
    end

    local speaker_xml = ''
    if speaker ~= '' then
      speaker_xml = '<emphasis role="speaker">' ..
                    escape_xml_text(speaker) ..
                    ':</emphasis> '
    end
    local raw = '<para role="speech">' ..
                speaker_xml ..
                contenido_db ..
                '</para>'
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
