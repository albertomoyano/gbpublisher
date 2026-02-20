-- ~/.gbpublisher/filters/cite-to-xref.lua
-- =====================================================
-- FILTRO LUA PARA PANDOC - CONVERSIONES JATS
-- =====================================================
-- FUNCIONES:
--   Cite  → CONVIERTE [@citekey] A <xref ref-type="bibr">
--   Div   → MANEJA FIGURAS, TABLAS, EPÍGRAFES, VERSOS,
--           CÓDIGO, RECUADROS Y SECCIONES
--   Note  → CONVIERTE NOTAS AL PIE A <fn> INLINE
-- =====================================================

-- CONVIERTE CITAS [@citekey] A <xref ref-type="bibr" rid="bib-citekey">
-- SIN USAR --citeproc NI NECESITAR ARCHIVO .bib
function Cite(el)
  local result = {}
  for i, citation in ipairs(el.citations) do
    local xref = pandoc.RawInline('jats',
      '<xref ref-type="bibr" rid="bib-' .. citation.id .. '">' ..
      citation.id .. '</xref>')
    table.insert(result, xref)
    if i < #el.citations then
      table.insert(result, pandoc.RawInline('jats', ', '))
    end
  end
  return result
end

-- CONTADOR GLOBAL DE FIGURAS
-- SE REINICIA EN CADA EJECUCIÓN DE PANDOC
-- GARANTIZA IDS ÚNICOS Y SECUENCIALES: fig-1, fig-2, ...
local fig_counter = 0

-- CONTADOR GLOBAL DE TABLAS
-- SE REINICIA EN CADA EJECUCIÓN DE PANDOC
-- GARANTIZA IDS ÚNICOS Y SECUENCIALES: tbl-1, tbl-2, ...
local table_counter = 0

-- MANEJA SIETE TIPOS DE DIVS:
--   :::{.fig #fig-cualquier-cosa}    → <fig id="fig-N">
--   :::{.table #tbl-cualquier-cosa}  → <table-wrap id="tbl-N">
--   ::: epigraph                     → <disp-quote specific-use="epigraph">
--   ::: verse                        → <verse-group> con <verse-line>
--   :::{.code language="python"}     → <code language="python">
--   :::{.box type="warning"}         → <boxed-text content-type="warning">
--   :::{.intro}                      → <sec sec-type="intro">
--   :::{.methods}                    → <sec sec-type="methods">
--   (etc.)
-- ESTRUCTURA INTERNA QUE GENERA PANDOC PARA FIGURAS:
--   Div.content → Figure → Plain → Image
function Div(el)

  -- FIGURAS: GENERAR <fig> JATS DIRECTAMENTE COMO RawBlock
  -- SE EVITA EL DOBLE <fig> QUE PANDOC GENERA AL CONVERTIR EL DIV
  if el.classes:includes('fig') then
    fig_counter = fig_counter + 1
    for _, block in ipairs(el.content) do
      if block.t == 'Figure' then
        for _, inner in ipairs(block.content) do
          if inner.t == 'Plain' then
            for _, inline in ipairs(inner.content) do
              if inline.t == 'Image' then
                local href = inline.src
                local alt  = pandoc.utils.stringify(inline.caption)
                local ext  = href:match("%.(%w+)$") or "png"
                local raw  = '<fig id="fig-' .. fig_counter .. '">\n' ..
                             '  <caption><p>' .. alt .. '</p></caption>\n' ..
                             '  <graphic mimetype="image" mime-subtype="' .. ext .. '"' ..
                             ' xlink:href="' .. href .. '"/>\n' ..
                             '</fig>'
                return pandoc.RawBlock('jats', raw)
              end
            end
          end
        end
      end
    end
    -- FALLBACK: SI NO ENCUENTRA IMAGEN RETORNA EL DIV CON id ACTUALIZADO
    el.identifier = 'fig-' .. fig_counter
    return el
  end

  -- TABLAS: SERIALIZAR A JATS E INYECTAR id SECUENCIAL
  -- PANDOC GENERA <table-wrap> SIN id, SE REEMPLAZA VÍA gsub
  if el.classes:includes('table') then
    table_counter = table_counter + 1
    for _, block in ipairs(el.content) do
      if block.t == 'Table' then
        local table_jats = pandoc.write(pandoc.Pandoc({block}), 'jats')
        table_jats = table_jats:gsub('<table%-wrap>', '<table-wrap id="tbl-' .. table_counter .. '">', 1)
        return pandoc.RawBlock('jats', table_jats)
      end
    end
    -- FALLBACK: SI NO ENCUENTRA TABLA RETORNA EL DIV CON id ACTUALIZADO
    el.identifier = 'tbl-' .. table_counter
    return el
  end

  -- EPÍGRAFES: <disp-quote specific-use="epigraph"> CON ATRIBUCIÓN SEPARADA
  -- SEPARA TEXTO DE ATRIBUCIÓN POR — (guión em) O -- (dos guiones)
  -- ESTRUCTURA EN MD:
  --   ::: epigraph
  --   Texto de la cita.
  --   -- Autor   (o — Autor)
  --   :::
  if el.classes:includes('epigraph') then
    local plain = pandoc.utils.stringify(el)
    local texto, attrib = plain:match('^(.-)%s*%—%s*(.+)$')
    if not attrib then
      texto, attrib = plain:match('^(.-)%s*%-%-%s*(.+)$')
    end
    local raw
    if attrib then
      raw = '<disp-quote specific-use="epigraph">\n' ..
            '  <p>' .. texto .. '</p>\n' ..
            '  <attrib>' .. attrib .. '</attrib>\n' ..
            '</disp-quote>'
    else
      raw = '<disp-quote specific-use="epigraph">\n' ..
            '  <p>' .. plain .. '</p>\n' ..
            '</disp-quote>'
    end
    return pandoc.RawBlock('jats', raw)
  end

  -- VERSOS: <verse-group> CON CADA LÍNEA EN <verse-line>
  -- ITERA SOBRE LOS INLINES PARA PRESERVAR SALTOS DE LÍNEA
  -- QUE pandoc.utils.stringify() COLAPSA EN UNA SOLA LÍNEA
  -- ESTRUCTURA EN MD:
  --   ::: verse
  --   Línea uno
  --   Línea dos
  --   :::
  if el.classes:includes('verse') then
    local tokens = {}
    for _, block in ipairs(el.content) do
      if block.t == 'Para' or block.t == 'Plain' then
        for _, inline in ipairs(block.content) do
          if inline.t == 'Str' then
            table.insert(tokens, inline.text)
          elseif inline.t == 'SoftBreak' or inline.t == 'LineBreak' then
            table.insert(tokens, '\n')
          elseif inline.t == 'Space' then
            table.insert(tokens, ' ')
          end
        end
      end
    end
    local verse_lines = {}
    local current = {}
    for _, token in ipairs(tokens) do
      if token == '\n' then
        if #current > 0 then
          table.insert(verse_lines, '  <verse-line>' .. table.concat(current) .. '</verse-line>')
          current = {}
        end
      else
        table.insert(current, token)
      end
    end
    -- ÚLTIMA LÍNEA SIN SALTO FINAL
    if #current > 0 then
      table.insert(verse_lines, '  <verse-line>' .. table.concat(current) .. '</verse-line>')
    end
    local raw = '<verse-group>\n' .. table.concat(verse_lines, '\n') .. '\n</verse-group>'
    return pandoc.RawBlock('jats', raw)
  end

  -- CÓDIGO DE PROGRAMACIÓN: <code language="...">
  -- EL ATRIBUTO language LO PROVEE EL SHORTCODE
  -- EL CONTENIDO DEBE IR EN BLOQUE ~~~ DENTRO DEL DIV
  -- PARA QUE PANDOC LO GENERE COMO CodeBlock
  -- ESTRUCTURA EN MD:
  --   ::: {.code language="python"}
  --   ~~~
  --   def factorial(n):
  --       ...
  --   ~~~
  --   :::
  -- ESCAPADO XML: & PRIMERO, LUEGO < Y > PARA EVITAR DOBLE ESCAPE
  if el.classes:includes('code') then
    local language = el.attributes['language'] or ''
    local content = ''
    for _, block in ipairs(el.content) do
      if block.t == 'CodeBlock' then
        content = block.text
      end
    end
    content = content:gsub('&', '&amp;')
    content = content:gsub('<', '&lt;')
    content = content:gsub('>', '&gt;')
    local lang_attr = ''
    if language ~= '' then
      lang_attr = ' language="' .. language .. '"'
    end
    local raw = '<code' .. lang_attr .. '>' .. content .. '</code>'
    return pandoc.RawBlock('jats', raw)
  end

  -- RECUADROS: <boxed-text content-type="...">
  -- EL ATRIBUTO type LO PROVEE EL SHORTCODE
  -- PANDOC SERIALIZA EL CONTENIDO CORRECTAMENTE (TEXTO, BOLD, ETC.)
  -- ESTRUCTURA EN MD:
  --   ::: {.box type="warning"}
  --   **Advertencia**: Texto del recuadro.
  --   :::
  if el.classes:includes('box') then
    local box_type = el.attributes['type'] or ''
    local content_jats = pandoc.write(pandoc.Pandoc(el.content), 'jats')
    content_jats = content_jats:gsub("^%s+", ""):gsub("%s+$", "")
    local type_attr = ''
    if box_type ~= '' then
      type_attr = ' content-type="' .. box_type .. '"'
    end
    local raw = '<boxed-text' .. type_attr .. '>\n' ..
                content_jats .. '\n' ..
                '</boxed-text>'
    return pandoc.RawBlock('jats', raw)
  end

  -- SECCIONES: MAPEAR CLASE CSS A ATRIBUTO sec-type DE JATS
  local sec_types = {
    intro                      = "intro",
    methods                    = "methods",
    results                    = "results",
    discussion                 = "discussion",
    conclusions                = "conclusions",
    acknowledgments            = "acknowledgments",
    ["supplementary-material"] = "supplementary-material",
    cases                      = "cases",
    findings                   = "findings",
    materials                  = "materials"
  }
  for _, class in ipairs(el.classes) do
    if sec_types[class] then
      el.attributes["sec-type"] = sec_types[class]
      return el
    end
  end

end

-- CONVIERTE NOTAS AL PIE A <fn> INLINE EN JATS
-- MODELO LATEX: LA NOTA VA EN EL PUNTO DONDE OCURRE
-- EN LUGAR DE <xref rid="fn1"> + <fn-group> SEPARADO AL FINAL
-- PANDOC YA GENERA <p> DENTRO DEL CONTENIDO, NO SE AGREGA OTRO
function Note(el)
  local content = pandoc.write(pandoc.Pandoc(el.content), 'jats')
  content = content:gsub("^%s+", ""):gsub("%s+$", "")
  return pandoc.RawInline('jats', '<fn>' .. content .. '</fn>')
end
