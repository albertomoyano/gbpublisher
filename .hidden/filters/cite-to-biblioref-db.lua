-- ~/.gbpublisher/filters/cite-to-biblioref-db.lua
-- =====================================================
-- FILTRO LUA PARA PANDOC - CONVERSIÓN DE CITAS A DOCBOOK 5.2
-- =====================================================
-- ADAPTADO DESDE cite-to-xref.lua (PIPELINE JATS).
-- DIFERENCIAS CLAVE CON LA VERSIÓN JATS:
--   1. EMITE TRES ELEMENTOS HERMANOS EN VEZ DE UNO ENVOLVENTE:
--      <phrase role="cite-prefix">PREFIJO</phrase>
--      <biblioref linkend="bib-KEY" role="modo">KEY</biblioref>
--      <phrase role="cite-suffix">SUFIJO</phrase>
--   2. EL TARGET DE pandoc.write ES 'docbook5' (NO 'jats').
--   3. EL ATRIBUTO DEL MODO ES role (NO specific-use).
--   4. EL ATRIBUTO DEL ID ES linkend (NO rid).
-- CONVENCIÓN DE MODO (IDÉNTICA A REVISTAS):
--   NormalCitation  → (SIN ATRIBUTO role)
--   SuppressAuthor  → role="suppress"
--   AuthorInText    → role="author-in-text"
-- CONVENCIÓN DE ID:
--   linkend="bib-{citekey_sanitizado}" — COINCIDE CON xml:id DEL
--   <biblioentry> GENERADO POR m_XML.GenerarBiblioCapituloXML.
-- FUNCIONES:
--   Cite  → CONVIERTE CITAS PANDOC A SECUENCIA DE INLINES DOCBOOK
--           CON role DEL MODO Y PREFIJO/SUFIJO COMO <phrase> HERMANOS
--           (PRESERVA MARKUP INLINE EN PREFIJO Y SUFIJO).
--   Note  → CONVIERTE NOTAS AL PIE A <footnote> INLINE EN DOCBOOK,
--           PERMITIENDO QUE LAS CITAS ANIDADAS SE PROCESEN.
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

-- inlines_a_docbook(inlines): SERIALIZA UNA LISTA DE INLINES PANDOC
-- A STRING DOCBOOK PRESERVANDO MARKUP (emphasis, role="strong",
-- literal, subscript, superscript, etc.). USADO PARA EMITIR PREFIJO
-- Y SUFIJO COMO CONTENIDO DE <phrase>.
local function inlines_a_docbook(inlines)
  if not inlines or #inlines == 0 then return '' end
  -- ENVOLVER EN UN PANDOC DOC + Plain BLOCK PARA QUE pandoc.write
  -- LOS PROCESE Y GENERE EL MARKUP DOCBOOK APROPIADO
  local docbook = pandoc.write(pandoc.Pandoc({pandoc.Plain(inlines)}), 'docbook5')
  -- pandoc.write CON UN Plain BLOCK ENVUELVE EL CONTENIDO EN <para>...</para>
  -- (DOCBOOK USA <para> EN LUGAR DEL <p> DE JATS).
  -- REMOVERLO PARA QUEDARNOS SOLO CON EL MARKUP INLINE.
  docbook = docbook:gsub('^%s*<para[^>]*>', '')
  docbook = docbook:gsub('</para>%s*$', '')
  docbook = docbook:gsub('^%s+', ''):gsub('%s+$', '')
  return docbook
end

-- normalizar_inlines_sufijo(inlines): APLICA LAS NORMALIZACIONES DE
-- TEXTO DEL SUFIJO (STRIP COMA INICIAL, STRIP LLAVES DE LOCATOR,
-- LOCATOR IMPLÍCITO p./pp.) SOBRE LA LISTA DE INLINES.
-- OPERA SOBRE EL TEXTO DEL PRIMER Str CUANDO CORRESPONDE,
-- PRESERVANDO LOS DEMÁS INLINES (Emph, Strong, Code, etc.).
-- DEVUELVE UNA NUEVA LISTA DE INLINES.
-- IDÉNTICA A LA VERSIÓN JATS: LA NORMALIZACIÓN ES INDEPENDIENTE
-- DEL TARGET DE SALIDA.
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
-- VÁLIDO PARA EL ATRIBUTO linkend DEL <biblioref>. REGLAS:
--   1. CARACTERES ASCII PERMITIDOS (a-zA-Z0-9.-_) SE MANTIENEN.
--   2. CUALQUIER OTRO CARÁCTER (URLs CON /, DOIs CON :, ESPACIOS,
--      PIPES, CARACTERES MULTIBYTE) SE REEMPLAZA POR '_'.
--   3. UNDERSCORES MÚLTIPLES SE COLAPSAN A UNO.
-- DETERMINÍSTICA: MISMO INPUT → MISMO OUTPUT.
-- LA MISMA LÓGICA ESTÁ IMPLEMENTADA EN m_XML.SanitizarCitekey EN EL
-- CÓDIGO GAMBAS QUE GENERA <biblioentry>, GARANTIZANDO QUE EL linkend
-- DEL biblioref EN EL CUERPO Y EL xml:id DEL <biblioentry> EN LA
-- BIBLIOGRAFÍA COINCIDAN EXACTAMENTE PARA CUALQUIER CITEKEY ORIGINAL.
local function sanitizar_citekey(s)
  if s == nil or s == '' then return '' end
  local r = s:gsub('[^a-zA-Z0-9._-]', '_')
  r = r:gsub('__+', '_')
  return r
end

-- =====================================================
-- FUNCIÓN PRINCIPAL: Cite
-- =====================================================
-- CONVIERTE CITAS PANDOC A SECUENCIA DE INLINES DOCBOOK CON MODO
-- DE CITA. SIN USAR --citeproc NI NECESITAR ARCHIVO .bib.
-- PRESERVA EL MODO DEL AST DE PANDOC EN role:
--   NormalCitation  → (SIN ATRIBUTO role)        → \autocite{key}
--   SuppressAuthor  → role="suppress"            → \autocite*{key}
--   AuthorInText    → role="author-in-text"      → \textcite{key}
-- PREFIJO Y SUFIJO VIAJAN COMO <phrase role="cite-prefix"/> Y
-- <phrase role="cite-suffix"/> HERMANOS DEL <biblioref/>, LO QUE
-- PERMITE PRESERVAR MARKUP INLINE (emphasis, strong, literal,
-- super/subscript, etc.).
-- ESTRUCTURA RESULTANTE:
--   <phrase role="cite-prefix">PREFIJO CON <emphasis>markup</emphasis></phrase>
--   <biblioref linkend="bib-KEY" role="MODO">KEY</biblioref>
--   <phrase role="cite-suffix">SUFIJO CON <emphasis>markup</emphasis></phrase>
-- EL TEXTO DEL <biblioref> SIGUE MOSTRANDO EL CITEKEY ORIGINAL (PARA
-- DEBUGGING Y EXPORTS), PERO EL linkend USA LA FORMA SANITIZADA QUE
-- TAMBIÉN APLICA m_XML.GenerarBiblioCapituloXML AL xml:id DEL
-- <biblioentry>.
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

    -- SERIALIZAR INLINES A STRING DOCBOOK PRESERVANDO EL MARKUP
    local prefijo_db = inlines_a_docbook(citation.prefix)
    local sufijo_db  = inlines_a_docbook(sufijo_inlines)

    -- ATRIBUTO role: SOLO EL MODO, Y SOLO SI NO ES "normal"
    -- (LA AUSENCIA DEL ATRIBUTO EQUIVALE A modo=normal EN LOS XSL)
    local role_attr = ""
    if modo ~= "normal" then
      role_attr = ' role="' .. modo .. '"'
    end

    -- ELEMENTO HERMANO <phrase role="cite-prefix">: SOLO SI HAY PREFIJO
    if prefijo_db ~= "" then
      local pref = pandoc.RawInline('docbook',
        '<phrase role="cite-prefix">' .. prefijo_db .. '</phrase>')
      table.insert(result, pref)
      -- ESPACIO ENTRE PREFIJO Y biblioref
      table.insert(result, pandoc.RawInline('docbook', ' '))
    end

    -- SANITIZAR EL CITEKEY PARA NMTOKEN-VALIDEZ EN EL linkend.
    -- EL TEXTO DEL biblioref SIGUE MOSTRANDO EL CITEKEY ORIGINAL.
    local citekey_sanitizado = sanitizar_citekey(citation.id)
    local linkend_attr = escape_xml_attr(citekey_sanitizado)
    local id_text = escape_xml_text(citation.id)

    -- ELEMENTO CENTRAL <biblioref linkend="..." role="...">CITEKEY</biblioref>
    local biblioref = pandoc.RawInline('docbook',
      '<biblioref linkend="bib-' .. linkend_attr .. '"' .. role_attr .. '>' ..
      id_text .. '</biblioref>')
    table.insert(result, biblioref)

    -- ELEMENTO HERMANO <phrase role="cite-suffix">: SOLO SI HAY SUFIJO
    if sufijo_db ~= "" then
      -- ESPACIO ENTRE biblioref Y SUFIJO
      table.insert(result, pandoc.RawInline('docbook', ' '))
      local suf = pandoc.RawInline('docbook',
        '<phrase role="cite-suffix">' .. sufijo_db .. '</phrase>')
      table.insert(result, suf)
    end

    -- SEPARADOR ENTRE CITAS MÚLTIPLES (e.g. [@a; @b])
    if i < #el.citations then
      table.insert(result, pandoc.RawInline('docbook', ', '))
    end
  end
  return result
end

-- =====================================================
-- FUNCIÓN Note: NOTAS AL PIE INLINE
-- =====================================================
-- CONVIERTE NOTAS AL PIE A <footnote> INLINE EN DOCBOOK.
-- MODELO DOCBOOK 5.2: <footnote> SE INSERTA DONDE OCURRE LA
-- LLAMADA, CON SU CONTENIDO COMO HIJOS INLINE/BLOCK.
-- PANDOC POR DEFAULT YA EMITE <footnote> EN DOCBOOK5, PERO LO
-- INTERCEPTAMOS AQUÍ PARA ASEGURAR QUE LAS CITAS ANIDADAS SEAN
-- PROCESADAS POR Cite() (PANDOC PROCESA EL AST EN ORDEN: LAS
-- CITAS DENTRO DE NOTAS YA HAN PASADO POR Cite ANTES DE LLEGAR
-- AQUÍ, POR LO QUE EL CONTENIDO YA TIENE EL MARKUP CORRECTO).
function Note(el)
  local content = pandoc.write(pandoc.Pandoc(el.content), 'docbook5')
  content = content:gsub("^%s+", ""):gsub("%s+$", "")
  return pandoc.RawInline('docbook', '<footnote>' .. content .. '</footnote>')
end
