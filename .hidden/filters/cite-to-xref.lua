-- ~/.gbpublisher/filters/cite-to-xref.lua
-- =====================================================
-- FILTRO LUA PARA PANDOC - CONVERSIONES JATS
-- =====================================================
-- FUNCIONES:
--   Cite  → CONVIERTE CITAS PANDOC A <xref ref-type="bibr">
--           CON specific-use="modo" Y PREFIJO/SUFIJO COMO
--           named-content HIJOS (PRESERVA MARKUP INLINE)
--   Div   → MANEJA FIGURAS, TABLAS, EPÍGRAFES, VERSOS,
--           CÓDIGO, RECUADROS, FÓRMULAS, ENTREVISTAS
--           Y SECCIONES
--   Note  → CONVIERTE NOTAS AL PIE A <fn> INLINE
-- =====================================================

-- =====================================================
-- HELPERS DE ESCAPE XML
-- =====================================================
-- ESCAPADO XML PARA TEXTO DE ELEMENTO
-- ORDEN OBLIGATORIO: & PRIMERO PARA EVITAR DOBLE ESCAPE
local function escape_xml_text(s)
  if s == nil then return '' end
  s = s:gsub('&', '&amp;')
  s = s:gsub('<', '&lt;')
  s = s:gsub('>', '&gt;')
  return s
end

-- ESCAPADO XML PARA VALOR DE ATRIBUTO (CON COMILLAS DOBLES)
-- ORDEN OBLIGATORIO: & PRIMERO PARA EVITAR DOBLE ESCAPE
local function escape_xml_attr(s)
  if s == nil then return '' end
  s = s:gsub('&', '&amp;')
  s = s:gsub('<', '&lt;')
  s = s:gsub('>', '&gt;')
  s = s:gsub('"', '&quot;')
  return s
end

-- =====================================================
-- HELPERS PARA PRESERVAR MARKUP INLINE EN PREFIJO/SUFIJO DE CITAS
-- =====================================================

-- inlines_a_jats(inlines): SERIALIZA UNA LISTA DE INLINES PANDOC
-- A STRING JATS PRESERVANDO MARKUP (italic, bold, monospace, etc.).
-- USADO PARA EMITIR PREFIJO Y SUFIJO COMO HIJOS named-content DEL
-- <xref>, EN LUGAR DEL ANTIGUO TRANSPORTE pipe-separated POR ATRIBUTO
-- (QUE NO PERMITE SUBELEMENTOS).
local function inlines_a_jats(inlines)
  if not inlines or #inlines == 0 then return '' end
  -- ENVOLVER EN UN PANDOC DOC + Plain BLOCK PARA QUE pandoc.write
  -- LOS PROCESE Y GENERE EL MARKUP JATS APROPIADO
  local jats = pandoc.write(pandoc.Pandoc({pandoc.Plain(inlines)}), 'jats')
  -- pandoc.write CON UN Plain BLOCK ENVUELVE EL CONTENIDO EN <p>...</p>.
  -- REMOVERLO PARA QUEDARNOS SOLO CON EL MARKUP INLINE.
  jats = jats:gsub('^%s*<p[^>]*>', '')
  jats = jats:gsub('</p>%s*$', '')
  jats = jats:gsub('^%s+', ''):gsub('%s+$', '')
  return jats
end

-- normalizar_inlines_sufijo(inlines): APLICA LAS NORMALIZACIONES DE
-- TEXTO DEL SUFIJO (STRIP COMA INICIAL, STRIP LLAVES DE LOCATOR,
-- LOCATOR IMPLÍCITO p./pp.) SOBRE LA LISTA DE INLINES.
-- OPERA SOBRE EL TEXTO DEL PRIMER Str CUANDO CORRESPONDE,
-- PRESERVANDO LOS DEMÁS INLINES (Emph, Strong, Code, etc.).
-- DEVUELVE UNA NUEVA LISTA DE INLINES.
local function normalizar_inlines_sufijo(inlines)
  if not inlines or #inlines == 0 then return inlines end
  -- COPIA MUTABLE
  local lista = {}
  for i, v in ipairs(inlines) do lista[i] = v end

  -- STRIP COMA INICIAL SOBRE EL PRIMER Str (PANDOC INCLUYE ", " EN EL SUFIJO)
  if lista[1] and lista[1].t == 'Str' then
    local nuevo = lista[1].text:gsub("^,%s*", "")
    if nuevo == '' then
      table.remove(lista, 1)
      while lista[1] and lista[1].t == 'Space' do
        table.remove(lista, 1)
      end
    else
      lista[1] = pandoc.Str(nuevo)
    end
  end

  -- STRIP LLAVES VACÍAS INICIAL: "{} X" O "{}, X" → "X"
  if lista[1] and lista[1].t == 'Str' then
    local nuevo = lista[1].text:gsub("^%{%}%s*,?%s*", "")
    if nuevo ~= lista[1].text then
      if nuevo == '' then
        table.remove(lista, 1)
        while lista[1] and lista[1].t == 'Space' do
          table.remove(lista, 1)
        end
      else
        lista[1] = pandoc.Str(nuevo)
      end
    end
  end

  -- STRIP LLAVES CON CONTENIDO EN TODOS LOS Str: "{X}" → "X"
  for i, inline in ipairs(lista) do
    if inline.t == 'Str' then
      lista[i] = pandoc.Str(inline.text:gsub("%{(.-)%}", "%1"))
    end
  end

  -- LOCATOR IMPLÍCITO: DÍGITOS AL INICIO SIN LETRAS EN NINGÚN INLINE
  -- SOLO APLICA SI TODA LA LISTA ES Str/Space (NO HAY MARKUP)
  local todos_texto = true
  local hay_letras = false
  for _, inline in ipairs(lista) do
    if inline.t ~= 'Str' and inline.t ~= 'Space' then
      todos_texto = false
      break
    end
    if inline.t == 'Str' and inline.text:match("%a") then
      hay_letras = true
    end
  end
  if todos_texto and not hay_letras and lista[1] and lista[1].t == 'Str'
     and lista[1].text:match("^%d") then
    -- DETECTAR RANGO O MÚLTIPLES (algún Str con '-' o ',')
    local tiene_rango = false
    for _, inline in ipairs(lista) do
      if inline.t == 'Str' and inline.text:match("[%-,]") then
        tiene_rango = true
        break
      end
    end
    local prefijo_pp = tiene_rango and "pp." or "p."
    table.insert(lista, 1, pandoc.Space())
    table.insert(lista, 1, pandoc.Str(prefijo_pp))
  end

  return lista
end

-- CONVIERTE CITAS PANDOC A <xref ref-type="bibr"> CON MODO DE CITA.
-- SIN USAR --citeproc NI NECESITAR ARCHIVO .bib.
-- PRESERVA EL MODO DEL AST DE PANDOC EN specific-use:
--   NormalCitation  → (sin atributo)    → \autocite{key}
--   SuppressAuthor  → "suppress"        → \autocite*{key}
--   AuthorInText    → "author-in-text"  → \textcite{key}
-- PREFIJO Y SUFIJO VIAJAN COMO HIJOS <named-content content-type="cite-prefix"/>
-- Y <named-content content-type="cite-suffix"/> DEL <xref>, LO QUE PERMITE
-- PRESERVAR MARKUP INLINE (italic, bold, monospace, super/subscript, etc.).
-- ESTRUCTURA RESULTANTE:
--   <xref ref-type="bibr" rid="bib-KEY" specific-use="MODO">
--     <named-content content-type="cite-prefix">PREFIJO</named-content>
--     KEY
--     <named-content content-type="cite-suffix">SUFIJO CON <italic>markup</italic></named-content>
--   </xref>
function Cite(el)
  local result = {}
  for i, citation in ipairs(el.citations) do

    -- DETERMINAR MODO DE CITA SEGÚN PANDOC AST
    local modo
    if citation.mode == "SuppressAuthor" then
      modo = "suppress"
    elseif citation.mode == "AuthorInText" then
      modo = "author-in-text"
    else
      modo = "normal"
    end

    -- NORMALIZAR INLINES DEL SUFIJO (strip coma, strip llaves, locator implícito)
    -- ESTAS NORMALIZACIONES OPERAN SOBRE EL TEXTO DEL PRIMER Str CUANDO
    -- APLICAN; LOS INLINES CON MARKUP (Emph, Strong, Code, ...) SE PRESERVAN.
    local sufijo_inlines = normalizar_inlines_sufijo(citation.suffix)

    -- SERIALIZAR INLINES A STRING JATS PRESERVANDO EL MARKUP
    local prefijo_jats = inlines_a_jats(citation.prefix)
    local sufijo_jats  = inlines_a_jats(sufijo_inlines)

    -- ATRIBUTO specific-use: SOLO EL MODO, Y SOLO SI NO ES "normal"
    -- (LA AUSENCIA DEL ATRIBUTO EQUIVALE A modo=normal EN LOS XSL)
    local specific_use = ""
    if modo ~= "normal" then
      specific_use = ' specific-use="' .. modo .. '"'
    end

    -- HIJOS named-content: SOLO SI HAY CONTENIDO QUE TRANSPORTAR
    local prefijo_nc = ""
    if prefijo_jats ~= "" then
      prefijo_nc = '<named-content content-type="cite-prefix">' ..
                   prefijo_jats .. '</named-content>'
    end
    local sufijo_nc = ""
    if sufijo_jats ~= "" then
      sufijo_nc = '<named-content content-type="cite-suffix">' ..
                  sufijo_jats .. '</named-content>'
    end

    -- ESCAPAR citation.id PARA AMBOS CONTEXTOS:
    -- ATRIBUTO rid (escape_xml_attr) Y TEXTO DEL ELEMENTO (escape_xml_text)
    local id_attr = escape_xml_attr(citation.id)
    local id_text = escape_xml_text(citation.id)
    local xref = pandoc.RawInline('jats',
      '<xref ref-type="bibr" rid="bib-' .. id_attr .. '"' .. specific_use .. '>' ..
      prefijo_nc .. id_text .. sufijo_nc .. '</xref>')
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

-- MANEJA NUEVE TIPOS DE DIVS:
--   :::{.fig #fig-cualquier-cosa}    → <fig id="fig-N">
--   :::{.table #tbl-cualquier-cosa}  → <table-wrap id="tbl-N">
--   ::: epigraph                     → <disp-quote specific-use="epigraph">
--   ::: verse                        → <verse-group> con <verse-line>
--   :::{.code language="python"}     → <code language="python">
--   :::{.box type="warning"}         → <boxed-text content-type="warning">
--   :::{.formula #eq-id}             → <disp-formula id="eq-id">
--   :::{.speech speaker="Nombre"}    → <speech><speaker>Nombre</speaker>
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
                -- ESCAPAR: href Y ext VAN A ATRIBUTO, alt VA A TEXTO DE ELEMENTO
                local raw  = '<fig id="fig-' .. fig_counter .. '">\n' ..
                             '  <caption><p>' .. escape_xml_text(alt) .. '</p></caption>\n' ..
                             '  <graphic mimetype="image" mime-subtype="' .. escape_xml_attr(ext) .. '"' ..
                             ' xlink:href="' .. escape_xml_attr(href) .. '"/>\n' ..
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
      -- ESCAPAR: texto Y attrib VAN A TEXTO DE ELEMENTO
      raw = '<disp-quote specific-use="epigraph">\n' ..
            '  <p>' .. escape_xml_text(texto) .. '</p>\n' ..
            '  <attrib>' .. escape_xml_text(attrib) .. '</attrib>\n' ..
            '</disp-quote>'
    else
      -- ESCAPAR: plain VA A TEXTO DE ELEMENTO
      raw = '<disp-quote specific-use="epigraph">\n' ..
            '  <p>' .. escape_xml_text(plain) .. '</p>\n' ..
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
            -- ESCAPAR: el texto va dentro de <verse-line>, contexto de texto de elemento
            table.insert(tokens, escape_xml_text(inline.text))
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
      -- ESCAPAR: language va a atributo
      lang_attr = ' language="' .. escape_xml_attr(language) .. '"'
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
      -- ESCAPAR: box_type va a atributo
      type_attr = ' content-type="' .. escape_xml_attr(box_type) .. '"'
    end
    local raw = '<boxed-text' .. type_attr .. '>\n' ..
                content_jats .. '\n' ..
                '</boxed-text>'
    return pandoc.RawBlock('jats', raw)
  end

  -- FÓRMULAS EN BLOQUE: <disp-formula id="..."><tex-math>
  -- EL id VIENE DEL IDENTIFICADOR DEL DIV (#eq-id)
  -- EL CONTENIDO LaTeX SE EXTRAE DEL ELEMENTO Math (DisplayMath)
  -- CDATA EVITA ESCAPAR CARACTERES ESPECIALES LATEX (^, _, \, etc.)
  -- ESTRUCTURA EN MD:
  --   ::: {.formula #eq-energia}
  --   $$E = mc^2$$
  --   :::
  if el.classes:includes('formula') then
    local eq_id = el.identifier or ''
    local math_text = ''
    for _, block in ipairs(el.content) do
      if block.t == 'Para' or block.t == 'Plain' then
        for _, inline in ipairs(block.content) do
          if inline.t == 'Math' then
            math_text = inline.text
          end
        end
      end
    end
    local id_attr = ''
    if eq_id ~= '' then
      -- ESCAPAR: eq_id va a atributo
      id_attr = ' id="' .. escape_xml_attr(eq_id) .. '"'
    end
    local raw = '<disp-formula' .. id_attr .. '>\n' ..
                '  <tex-math><![CDATA[' .. math_text .. ']]></tex-math>\n' ..
                '</disp-formula>'
    return pandoc.RawBlock('jats', raw)
  end

  -- DISCURSO/ENTREVISTA: <speech><speaker>...</speaker><p>...</p></speech>
  -- EL ATRIBUTO speaker LO PROVEE EL SHORTCODE
  -- CADA INTERVENCIÓN SE MARCA POR SEPARADO
  -- ESTRUCTURA EN MD:
  --   ::: {.speech speaker="Entrevistado A"}
  --   Texto de la intervención.
  --   :::
  if el.classes:includes('speech') then
    local speaker = el.attributes['speaker'] or ''
    local content_jats = pandoc.write(pandoc.Pandoc(el.content), 'jats')
    content_jats = content_jats:gsub("^%s+", ""):gsub("%s+$", "")
    local raw = '<speech>\n'
    if speaker ~= '' then
      -- ESCAPAR: speaker va a texto de elemento <speaker>
      raw = raw .. '  <speaker>' .. escape_xml_text(speaker) .. '</speaker>\n'
    end
    raw = raw .. content_jats .. '\n</speech>'
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
    materials                  = "materials",
    -- TIPOS DE 01_ESTRUCTURA
    ["case-report"]            = "case-report",
    ["review-article"]         = "review-article",
    abstract                   = "abstract",
    appendix                   = "appendix",
    ["conflict-of-interest"]   = "conflict-of-interest",
    editorial                  = "editorial",
    correspondence             = "correspondence",
    ["book-review"]            = "book-review",
    obituary                   = "obituary",
    oration                    = "oration",
    retraction                 = "retraction",
    correction                 = "correction"
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
