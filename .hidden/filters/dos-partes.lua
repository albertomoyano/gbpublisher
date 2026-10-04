-- ============================================================
-- FILTRO      : dos-partes.lua
-- PROPÓSITO   : PARTE LOS BLOQUES DE DOS PARTES —HOY SOLO EL
--               EPÍGRAFE— EN SUS DOS MITADES, CON UNA SOLA REGLA
--               PARA LIBRO, REVISTA Y ODT.
-- ENTRADA     : ::: epigraph
--
--               {texto}{atribución}
--
--               [/epigraph]: # ()
--               :::
-- SALIDA      : EL MISMO Div epigraph CON DOS Div HIJOS:
--                 Div .epigrafe-texto  (UNO O MÁS Para)
--                 Div .epigrafe-atrib  (UN Para; FALTA SI LA
--                                       SEGUNDA PARTE ESTÁ VACÍA)
--               LOS FILTROS DE CADA SALIDA LEEN ESA FORMA.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE LOS FILTROS DE COMILLAS Y ANTES DE
--               cite-to-xref.lua (REVISTA), fenced-divs-to-elements-db.lua
--               (LIBRO) Y epigrafe-odt.lua (ODT).
-- REGLA       : LAS LLAVES SON EL SEMÁFORO DEL EPÍGRAFE. UN BLOQUE QUE
--               NO TIENE LA FORMA {…}{…} FRENA LA CONVERSIÓN CON UN
--               MENSAJE: NUNCA SE DEGRADA EN SILENCIO.
-- ============================================================

-- CLASES DE MODO dos-partes DEL CATÁLOGO DE gbShortcodes (RF-11)
local CLASES = { epigraph = true }

-- MARCAS INTERNAS DEL RECORRIDO: NO SON INLINES DE PANDOC
local ABRE = { marca = 'abre' }
local CIERRA = { marca = 'cierra' }
local PARRAFO = { marca = 'parrafo' }

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que ubica el bloque
-- Parámetros: el As Div — el bloque; motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(el, motivo)
  local inicio = pandoc.utils.stringify(el):sub(1, 60)
  error('\n[gbpublisher] Epígrafe mal formado: ' .. motivo ..
        '\n  Forma esperada: {texto}{atribución}' ..
        '\n  Comienzo del bloque: ' .. inicio .. '\n', 0)
end

-- ============================================
-- Función   : tokenizar
-- Propósito : Aplana los párrafos del bloque en una sola secuencia,
--             separando las llaves del nivel del párrafo de sus Str
-- Parámetros: el As Div — el bloque
-- Retorna   : table — inlines, marcas ABRE/CIERRA y PARRAFO entre párrafos
-- ============================================
local function tokenizar(el)
  local tokens = {}
  for i, bloque in ipairs(el.content) do
    -- SOLO PÁRRAFOS: UNA LISTA O UNA TABLA NO ENTRA EN UN EPÍGRAFE
    if bloque.t ~= 'Para' and bloque.t ~= 'Plain' then
      fallar(el, 'solo admite párrafos (hay un ' .. bloque.t .. ')')
    end
    if i > 1 then tokens[#tokens + 1] = PARRAFO end
    for _, inl in ipairs(bloque.content) do
      if inl.t == 'Str' then
        -- UNA LLAVE PUEDE VENIR PEGADA AL TEXTO: «.}{Francis» ES UN Str
        local resto = inl.text
        while resto ~= '' do
          local pos = resto:find('[{}]')
          if not pos then
            tokens[#tokens + 1] = pandoc.Str(resto)
            break
          end
          if pos > 1 then tokens[#tokens + 1] = pandoc.Str(resto:sub(1, pos - 1)) end
          tokens[#tokens + 1] = (resto:sub(pos, pos) == '{') and ABRE or CIERRA
          resto = resto:sub(pos + 1)
        end
      else
        tokens[#tokens + 1] = inl
      end
    end
  end
  return tokens
end

-- ============================================
-- Función   : es_blanco
-- Propósito : Dice si un token es espacio entre palabras o salto de línea
-- Parámetros: t As token
-- Retorna   : boolean
-- ============================================
local function es_blanco(t)
  return t.t == 'Space' or t.t == 'SoftBreak' or t.t == 'LineBreak'
end

-- ============================================
-- Función   : a_parrafos
-- Propósito : Arma los párrafos de una parte, sin blancos en los bordes
-- Parámetros: tokens As table — los de una parte, con PARRAFO entre párrafos
-- Retorna   : table — lista de listas de inlines; los párrafos vacíos no entran
-- ============================================
local function a_parrafos(tokens)
  local parrafos, actual = {}, {}
  local function cerrar()
    while #actual > 0 and es_blanco(actual[1]) do table.remove(actual, 1) end
    while #actual > 0 and es_blanco(actual[#actual]) do table.remove(actual) end
    if #actual > 0 then parrafos[#parrafos + 1] = actual end
    actual = {}
  end
  for _, t in ipairs(tokens) do
    if t == PARRAFO then cerrar() else actual[#actual + 1] = t end
  end
  cerrar()
  return parrafos
end

-- ============================================
-- Función   : partir
-- Propósito : Separa las dos partes contando llaves. Solo las del nivel
--             de afuera delimitan; las de adentro, balanceadas, son texto
-- Parámetros: el As Div — el bloque
-- Retorna   : table, table — los tokens de la primera y de la segunda parte
-- ============================================
local function partir(el)
  local tokens = tokenizar(el)
  local partes = {}
  local actual = nil
  local nivel = 0

  for _, t in ipairs(tokens) do
    if t == ABRE then
      nivel = nivel + 1
      if nivel == 1 then
        -- UNA PARTE NUEVA: LA ANTERIOR TIENE QUE HABER TERMINADO PEGADA
        if #partes == 2 then fallar(el, 'hay más de dos partes entre llaves') end
        actual = {}
        partes[#partes + 1] = actual
      else
        actual[#actual + 1] = pandoc.Str('{')
      end
    elseif t == CIERRA then
      if nivel == 0 then fallar(el, 'hay una llave de cierre sin su apertura') end
      nivel = nivel - 1
      if nivel == 0 then
        actual = nil
      else
        actual[#actual + 1] = pandoc.Str('}')
      end
    elseif actual then
      actual[#actual + 1] = t
    elseif not (es_blanco(t) or t == PARRAFO) or #partes == 1 then
      -- FUERA DE LAS LLAVES SOLO HAY BLANCOS ANTES Y DESPUÉS DEL TODO;
      -- ENTRE LAS DOS PARTES, NADA: }{ VAN PEGADAS
      fallar(el, 'hay texto fuera de las llaves, o las dos partes no van pegadas (}{)')
    end
  end

  if nivel ~= 0 then fallar(el, 'hay una llave de apertura sin cerrar') end
  if #partes ~= 2 then fallar(el, 'tiene que tener dos partes entre llaves') end
  return partes[1], partes[2]
end

-- ============================================
-- Función   : Div
-- Propósito : Reescribe cada bloque de dos partes en su forma con hijos
-- Parámetros: el As Div
-- Retorna   : Div — el bloque partido; nil si no es de dos partes
-- ============================================
function Div(el)
  local clase = nil
  for _, c in ipairs(el.classes) do
    if CLASES[c] then clase = c end
  end
  if not clase then return nil end

  local t1, t2 = partir(el)
  local texto = a_parrafos(t1)
  local atrib = a_parrafos(t2)

  -- LA PRIMERA PARTE ES OBLIGATORIA; LA SEGUNDA PUEDE ESTAR VACÍA Y
  -- ENTONCES NO HAY FILETE
  if #texto == 0 then fallar(el, 'la primera parte está vacía') end
  -- <attribution> (DOCBOOK) Y <attrib> (JATS) SOLO ADMITEN TEXTO EN LÍNEA
  if #atrib > 1 then fallar(el, 'la segunda parte tiene que ser un solo párrafo') end

  local bloques_texto = {}
  for _, inl in ipairs(texto) do bloques_texto[#bloques_texto + 1] = pandoc.Para(inl) end

  local hijos = { pandoc.Div(bloques_texto, pandoc.Attr('', {'epigrafe-texto'})) }
  if #atrib == 1 then
    hijos[#hijos + 1] = pandoc.Div({ pandoc.Para(atrib[1]) }, pandoc.Attr('', {'epigrafe-atrib'}))
  end

  return pandoc.Div(hijos, el.attr)
end
