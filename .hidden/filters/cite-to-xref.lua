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

  -- STRIP LLAVES MULTI-TOKEN: SI EL PRIMER Str EMPIEZA CON "{" Y EL
  -- ÚLTIMO Str TERMINA CON "}", REMOVER AMBOS DELIMITADORES.
  -- ESTE CASO OCURRE CUANDO EL USUARIO ESCRIBE {libro IV, cap. 3} O
  -- {pp. iv, vi-xi, (xv)-(xvii)} — Pandoc TOKENIZA EL CONTENIDO POR
  -- ESPACIOS, DEJANDO LA "{" EN EL PRIMER Str Y LA "}" EN EL ÚLTIMO,
  -- INACCESIBLES PARA UN gsub LOCAL POR INLINE.
  if #lista >= 1 then
    local primero = lista[1]
    if primero and primero.t == 'Str' and primero.text:sub(1,1) == '{' then
      local ultimo = lista[#lista]
      if ultimo and ultimo.t == 'Str' and ultimo.text:sub(-1) == '}' then
        -- REMOVER "{" DEL PRIMER Str (Y EL Str COMPLETO SI ERA SOLO "{")
        if primero.text == '{' then
          table.remove(lista, 1)
          while lista[1] and lista[1].t == 'Space' do
            table.remove(lista, 1)
          end
        else
          lista[1] = pandoc.Str(primero.text:sub(2))
        end
        -- RE-CAPTURAR EL ÚLTIMO Str DESPUÉS DEL REMOVE (LA LISTA CAMBIÓ
        -- DE TAMAÑO Y EL PRIMER Y ÚLTIMO PUEDEN COINCIDIR EN LISTAS CORTAS).
        local nuevo_ultimo = lista[#lista]
        if nuevo_ultimo and nuevo_ultimo.t == 'Str' then
          if nuevo_ultimo.text == '}' then
            table.remove(lista, #lista)
            while lista[#lista] and lista[#lista].t == 'Space' do
              table.remove(lista, #lista)
            end
          else
            lista[#lista] = pandoc.Str(nuevo_ultimo.text:sub(1, -2))
          end
        end
      end
    end
  end

  -- STRIP LLAVES SINGLE-TOKEN: "{X}" DENTRO DE UN SOLO Str → "X"
  -- ESTO CUBRE CASOS COMO {p. xiv} O {99} DONDE PANDOC AGRUPA EL
  -- CONTENIDO COMPLETO EN UN ÚNICO Str. NO COLISIONA CON EL STRIP
  -- MULTI-TOKEN PORQUE ESE YA REMOVIÓ LAS DELIMITADORAS EXTERNAS.
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

-- sanitizar_citekey(s): CONVIERTE UN CITEKEY ARBITRARIO A NMTOKEN
-- VÁLIDO PARA EL ATRIBUTO rid DEL <xref>. REGLAS:
--   1. CARACTERES ASCII PERMITIDOS (a-zA-Z0-9.-_) SE MANTIENEN.
--   2. CUALQUIER OTRO CARÁCTER (URLs CON /, DOIs CON :, ESPACIOS,
--      PIPES, CARACTERES MULTIBYTE) SE REEMPLAZA POR '_'.
--   3. UNDERSCORES MÚLTIPLES SE COLAPSAN A UNO.
-- DETERMINÍSTICA: MISMO INPUT → MISMO OUTPUT.
-- LA MISMA LÓGICA ESTÁ IMPLEMENTADA EN m_XML.SanitizarCitekey EN EL
-- CÓDIGO GAMBAS QUE GENERA <ref-list>, GARANTIZANDO QUE EL rid DEL
-- xref EN EL CUERPO Y EL id DEL <ref> EN LA BIBLIOGRAFÍA COINCIDAN
-- EXACTAMENTE PARA CUALQUIER CITEKEY ORIGINAL POSIBLE.
local function sanitizar_citekey(s)
  if s == nil or s == '' then return '' end
  local r = s:gsub('[^a-zA-Z0-9._-]', '_')
  r = r:gsub('__+', '_')
  return r
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
-- PREFIJOS DE REFERENCIA CRUZADA DE LIBROS (cite-to-biblioref-db.lua). EN
-- REVISTA NO HAY REFERENCIA CRUZADA (SC-32): CADA ARTÍCULO ES AUTÓNOMO, Y
-- DENTRO DEL ARTÍCULO LA MENCIÓN «figura 2» ES TEXTO DEL AUTOR. UNA CLAVE
-- CON ESTOS PREFIJOS SALDRÍA COMO CITA BIBLIOGRÁFICA FALSA: SE FRENA.
-- NINGUNA CLAVE BIBLIOGRÁFICA EMPIEZA CON LETRA (EMPIEZAN CON EL id
-- NUMÉRICO DEL REGISTRO).
local prefijos_referencia = { 'fig-', 'tbl-', 'eq-', 'lst-' }

function Cite(el)
  local result = {}

  -- REFERENCIA CRUZADA EN UN ARTÍCULO: NO EXISTE EN REVISTAS
  for _, citation in ipairs(el.citations) do
    for _, prefijo in ipairs(prefijos_referencia) do
      if citation.id:sub(1, #prefijo) == prefijo then
        error('\n[referencia] @' .. citation.id .. ': en revistas no hay ' ..
              'referencias cruzadas. La mención a una figura, una tabla, una ' ..
              'ecuación o un listado se escribe como texto («figura 2»).', 0)
      end
    end
  end

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

    -- SANITIZAR EL CITEKEY PARA NMTOKEN-VALIDEZ EN EL rid (R-03).
    -- EL TEXTO DEL xref SIGUE MOSTRANDO EL CITEKEY ORIGINAL (PARA
    -- DEBUGGING Y EXPORTS), PERO EL rid USA LA FORMA SANITIZADA QUE
    -- TAMBIÉN APLICA m_XML.GenerarRefListXML AL id DEL <ref>.
    local citekey_sanitizado = sanitizar_citekey(citation.id)
    local id_attr = escape_xml_attr(citekey_sanitizado)
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

-- CONTADOR GLOBAL DE TABLAS
-- SE REINICIA EN CADA EJECUCIÓN DE PANDOC
-- GARANTIZA IDS ÚNICOS Y SECUENCIALES: tbl-1, tbl-2, ...
local table_counter = 0

-- MANEJA NUEVE TIPOS DE DIVS:
--   :::{.fig #fig-mapa}              → <fig id="fig-mapa"> (TAMBIÉN .fullwidth)
--   :::{.table #tbl-cualquier-cosa}  → <table-wrap id="tbl-N">
--   ::: epigraph {…}{…}              → <disp-quote specific-use="epigraph"> (VÍA dos-partes.lua)
--   ::: verse                        → <verse-group> con <verse-line>
--   ~~~ python … ~~~                 → <code language="python"> (codigo.lua, SC-42)
--   :::{.listado #lst-id}            → <fig id="lst-id" fig-type="listado"> CON EL
--                                      <code> Y EL PIE (VÍA codigo.lua)
--   ::: recuadro                     → <boxed-text content-type="recuadro"> (SC-41)
--   ::: recuadrob {…}{…}             → <boxed-text content-type="recuadro-barra">
--                                      CON LA BARRA EN <caption><title> (VÍA dos-partes.lua)
--                                      LOS DOS, CON .fullwidth → specific-use="fullwidth"
--   :::{.formula #eq-id}             → <disp-formula id="eq-id">
--   :::{.speech speaker="Nombre"}    → <speech><speaker>Nombre</speaker>
--   :::{.intro}                      → <sec sec-type="intro">
--   :::{.methods}                    → <sec sec-type="methods">
--   (etc.)
-- ESTRUCTURA INTERNA QUE GENERA PANDOC PARA FIGURAS:
--   Div.content → Figure → Plain → Image
function Div(el)

  -- FIGURAS: <fig> JATS ARMADO ACÁ, LA NORMAL Y LA DE ANCHO COMPLETO (SC-32)
  -- ESTRUCTURA EN MD (LA ÚNICA ADMITIDA, LA MISMA QUE EN LIBROS):
  --   ::: {.fig #fig-mapa}
  --   ![Pie de la figura, con *formato* y citas [@clave]](media/fig-mapa.png)
  --   :::
  -- CON TEXTO ALTERNATIVO PROPIO PARA EL EPUB ACCESIBLE: alt="..." EN EL DIV.
  -- .fullwidth → specific-use="fullwidth".
  -- EL PIE CONSERVA FORMATO Y CITAS: LOS Cite YA SON <xref> PORQUE LOS
  -- INLINES SE PROCESAN ANTES QUE LOS BLOQUES.
  -- TRES FALLAS DETIENEN LA CONVERSIÓN, IGUAL QUE EN LIBROS (GV-23): SIN #id,
  -- SIN PIE Y CON CONTENIDO ADEMÁS DE LA IMAGEN. EL id NO SIRVE PARA REFERIR
  -- (EN REVISTA NO HAY REFERENCIA CRUZADA, SC-32): ES EL ANCLA ESTABLE DE LA
  -- FIGURA EN EL HTML Y EL EPUB, Y LO ESCRIBE InsertarFigura.
  if el.classes:includes('fig') then
    local fig_id = el.identifier or ''
    local imagen = nil
    local pie = {}
    local otros = 0

    -- BUSCAR LA IMAGEN: Figure (IMAGEN CON PIE) O Para/Plain CON UNA SOLA
    -- Image (IMAGEN SIN PIE, PARA DAR EL MENSAJE CORRECTO)
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

    local ext = imagen.src:match("%.(%w+)$") or "png"
    local uso = ''
    if el.classes:includes('fullwidth') then uso = ' specific-use="fullwidth"' end

    -- TEXTO ALTERNATIVO SOLO SI SE DECLARÓ: SIN ÉL, LAS SALIDAS USAN EL PIE
    local alt_text = ''
    if el.attributes['alt'] and el.attributes['alt'] ~= '' then
      alt_text = '<alt-text>' .. escape_xml_text(el.attributes['alt']) .. '</alt-text>'
    end

    -- ESCAPAR: id, href Y ext VAN A ATRIBUTO; EL PIE YA ES MARCADO JATS
    local raw = '<fig id="' .. escape_xml_attr(fig_id) .. '"' .. uso .. '>\n' ..
                '  <caption><p>' .. inlines_a_jats(pie) .. '</p></caption>\n' ..
                '  <graphic mimetype="image" mime-subtype="' .. escape_xml_attr(ext) .. '"' ..
                ' xlink:href="' .. escape_xml_attr(imagen.src) .. '">' .. alt_text .. '</graphic>\n' ..
                '</fig>'
    return pandoc.RawBlock('jats', raw)
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

  -- FROUFROU: ES SOLO DE LIBROS (SC-36). EL PANEL NO LO OFRECE EN UNA
  -- REVISTA; UNO ESCRITO A MANO DETIENE LA CONVERSIÓN
  if el.classes:includes('froufrou') then
    error('\n[froufrou] El froufrou es un separador de libros: no se usa en ' ..
          'revistas. Quitar el bloque ::: froufrou del artículo.\n', 0)
  end

  -- EPÍGRAFES: <disp-quote specific-use="epigraph"> CON <attrib>
  -- dos-partes.lua YA PARTIÓ EL BLOQUE {texto}{atribución} EN DOS Div
  -- HIJOS (.epigrafe-texto, .epigrafe-atrib) Y CONTROLÓ LA FORMA. ACÁ
  -- SOLO SE SERIALIZA, CONSERVANDO BASTARDILLA, NEGRITA Y CITAS (LOS
  -- Cite YA SON <xref>: LOS INLINES SE PROCESAN ANTES QUE LOS BLOQUES).
  -- SIN SEGUNDA PARTE NO HAY <attrib>, Y LA SALIDA NO PONE FILETE.
  if el.classes:includes('epigraph') then
    local texto, atrib = nil, nil
    for _, hijo in ipairs(el.content) do
      if hijo.t == 'Div' and hijo.classes:includes('epigrafe-texto') then texto = hijo end
      if hijo.t == 'Div' and hijo.classes:includes('epigrafe-atrib') then atrib = hijo end
    end
    -- SIN LOS HIJOS, dos-partes.lua NO CORRIÓ ANTES: ES UN ERROR DE CADENA
    if not texto then
      error('\n[gbpublisher] epigraph sin partir: dos-partes.lua tiene que correr antes que cite-to-xref.lua\n', 0)
    end
    local raw = '<disp-quote specific-use="epigraph">\n'
    for _, parrafo in ipairs(texto.content) do
      raw = raw .. '  <p>' .. inlines_a_jats(parrafo.content) .. '</p>\n'
    end
    if atrib then
      raw = raw .. '  <attrib>' .. inlines_a_jats(atrib.content[1].content) .. '</attrib>\n'
    end
    raw = raw .. '</disp-quote>'
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

  -- LISTADO DE CÓDIGO (SC-42): <fig fig-type="listado"> CON EL <code> Y EL
  -- PIE. codigo.lua YA CONTROLÓ LA FORMA Y ESCRIBIÓ EL BLOQUE: EL Div LLEGA
  -- CON DOS HIJOS, EL RawBlock DEL <code> Y EL Para DEL PIE. EL PIE CONSERVA
  -- FORMATO Y CITAS: LOS Cite YA SON <xref>. EL BLOQUE SUELTO (~~~ python)
  -- LO ESCRIBE codigo.lua Y NO PASA POR ACÁ. EL VIEJO ::: {.code} LO FRENA
  -- codigo.lua.
  if el.classes:includes('listado') then
    local bloque, pie = el.content[1], el.content[2]
    if #el.content ~= 2 or bloque.t ~= 'RawBlock' or bloque.format ~= 'jats'
       or (pie.t ~= 'Para' and pie.t ~= 'Plain') then
      error('\n[código] listado #' .. el.identifier .. ' sin preparar: codigo.lua ' ..
            'tiene que correr antes que cite-to-xref.lua\n', 0)
    end
    local raw = '<fig id="' .. escape_xml_attr(el.identifier) .. '" fig-type="listado">\n' ..
                '  <caption><p>' .. inlines_a_jats(pie.content) .. '</p></caption>\n' ..
                '  ' .. bloque.text .. '\n' ..
                '</fig>'
    return pandoc.RawBlock('jats', raw)
  end

  -- RECUADROS (SC-41): <boxed-text content-type="recuadro" | "recuadro-barra">
  -- recuadros.lua YA CONTROLÓ LA FORMA: SOLO PÁRRAFOS, SIN NOTAS. LAS CITAS
  -- YA SON <xref>: Cite CORRE ANTES QUE Div EN ESTE FILTRO. EL ANCHO
  -- COMPLETO VA COMO EN LAS FIGURAS: specific-use="fullwidth".
  -- EL RECUADRO VIEJO ::: {.box} SE RETIRÓ: LO FRENA recuadros.lua.
  -- ESTRUCTURA EN MD:
  --   ::: recuadro                  ::: recuadrob
  --   Párrafos.                     {Barra}{Párrafos.}
  --   :::                           :::
  if el.classes:includes('recuadro') or el.classes:includes('recuadrob') then
    local uso = ''
    if el.classes:includes('fullwidth') then uso = ' specific-use="fullwidth"' end

    if el.classes:includes('recuadro') then
      local cuerpo = pandoc.write(pandoc.Pandoc(el.content), 'jats')
      cuerpo = cuerpo:gsub("^%s+", ""):gsub("%s+$", "")
      return pandoc.RawBlock('jats', '<boxed-text content-type="recuadro"' .. uso .. '>\n' ..
                                     cuerpo .. '\n</boxed-text>')
    end

    -- recuadrob: dos-partes.lua LO DEJÓ EN DOS Div, LA BARRA (UN PÁRRAFO) Y
    -- EL TEXTO. LA BARRA VA AL TÍTULO DEL caption, QUE ADMITE MARCAS EN
    -- LÍNEA (VALIDADO CONTRA LA DTD ARCHIVING 1.4)
    local barra, texto = '', ''
    for _, hijo in ipairs(el.content) do
      if hijo.classes:includes('recuadro-barra') then
        barra = inlines_a_jats(hijo.content[1].content)
      elseif hijo.classes:includes('recuadro-texto') then
        texto = pandoc.write(pandoc.Pandoc(hijo.content), 'jats')
        texto = texto:gsub("^%s+", ""):gsub("%s+$", "")
      end
    end
    if barra == '' then
      error('\n[gbpublisher] recuadrob sin partir: dos-partes.lua tiene que correr antes que cite-to-xref.lua\n', 0)
    end
    return pandoc.RawBlock('jats', '<boxed-text content-type="recuadro-barra"' .. uso .. '>\n' ..
                                   '<caption><title>' .. barra .. '</title></caption>\n' ..
                                   texto .. '\n</boxed-text>')
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
