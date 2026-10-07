-- ============================================================
-- FILTRO      : recuadros.lua
-- PROPÓSITO   : CONTROLA LOS RECUADROS (SC-41) CON UNA SOLA REGLA
--               PARA LIBRO, REVISTA Y ODT, Y LOS RESUELVE EN EL ODT.
--               LA SERIALIZACIÓN A JATS Y A DOCBOOK LA HACEN
--               cite-to-xref.lua Y fenced-divs-to-elements-db.lua,
--               QUE YA TIENEN LAS CITAS RESUELTAS.
-- ENTRADA     : ::: recuadro              ::: recuadrob
--
--               Párrafos.                 {Barra}{Párrafos.}
--
--               [/recuadro]: # ()         [/recuadrob]: # ()
--               :::                       :::
--               EN REVISTAS, CON .fullwidth: ::: {.recuadro .fullwidth}
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE dos-partes.lua (QUE PARTE EL recuadrob) Y,
--               EN REVISTA, DESPUÉS DE unwrap-structural-divs.lua.
--               ANTES DE cite-to-xref.lua Y fenced-divs-to-elements-db.lua.
-- REGLA       : FRENA LA CONVERSIÓN CON UN MENSAJE SI:
--               - QUEDA UN ::: {.box}: EL RECUADRO VIEJO SE RETIRÓ;
--               - UN RECUADRO TIENE UNA NOTA AL PIE: EN EL PDF QUEDARÍA
--                 DENTRO DEL RECUADRO CON LETRA (MEDIDO CON tcolorbox), Y
--                 EN HTML Y EPUB SE NUMERARÍA CON LAS DEMÁS;
--               - UN RECUADRO TIENE ALGO QUE NO ES UN PÁRRAFO, O ESTÁ
--                 DENTRO DE OTRO RECUADRO;
--               - UN LIBRO PIDE .fullwidth: EL LIBRO NO TIENE COLUMNA
--                 LATERAL, COMO EN LAS FIGURAS (SC-32);
--               - UN recuadro ESTÁ VACÍO.
-- ============================================================

local CLASES = { recuadro = true, recuadrob = true }

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que ubica el bloque
-- Parámetros: el As Div — el bloque; motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(el, motivo)
  local inicio = pandoc.utils.stringify(el):sub(1, 60)
  error('\n[recuadro] ' .. motivo ..
        '\n  Comienzo del bloque: ' .. inicio .. '\n', 0)
end

-- ============================================
-- Función   : clase_de
-- Propósito : La clase de recuadro de un bloque, si la tiene
-- Parámetros: el As Block
-- Retorna   : String — recuadro o recuadrob; nil si no es un recuadro
-- ============================================
local function clase_de(el)
  if el.t ~= 'Div' then return nil end
  for _, c in ipairs(el.classes) do
    if CLASES[c] then return c end
  end
  return nil
end

-- ============================================
-- Función   : solo_parrafos
-- Propósito : Dice si una lista de bloques tiene solo párrafos
-- Parámetros: bloques As Blocks
-- Retorna   : boolean
-- ============================================
local function solo_parrafos(bloques)
  for _, b in ipairs(bloques) do
    if b.t ~= 'Para' and b.t ~= 'Plain' then return false end
  end
  return true
end

-- ============================================
-- Función   : controlar
-- Propósito : Aplica las reglas comunes a un recuadro
-- Parámetros: el As Div; clase As String; es_libro As Boolean
-- Retorna   : nada; frena si algo no se cumple
-- ============================================
local function controlar(el, clase, es_libro)
  local hay_nota = false

  -- --- 1. ANCHO COMPLETO: SOLO EN REVISTAS ---
  if es_libro and el.classes:includes('fullwidth') then
    fallar(el, 'el ancho completo (.fullwidth) es solo de revistas: el libro no tiene columna lateral.')
  end

  -- --- 2. SIN NOTAS AL PIE ---
  el:walk({ Note = function() hay_nota = true end })
  if hay_nota then
    fallar(el, 'un recuadro no admite notas al pie. En el PDF quedarían dentro del ' ..
               'recuadro y numeradas aparte; la nota va en el párrafo, fuera del recuadro.')
  end

  -- --- 3. SIN RECUADROS ADENTRO ---
  -- SE RECORRE EL CONTENIDO Y NO EL BLOQUE: EL BLOQUE MISMO ES UN RECUADRO
  pandoc.Blocks(el.content):walk({ Div = function(d)
    if clase_de(d) then fallar(el, 'un recuadro no puede ir dentro de otro.') end
  end })

  -- --- 4. CONTENIDO ---
  -- recuadrob YA LLEGA PARTIDO POR dos-partes.lua EN DOS Div: BARRA Y TEXTO
  if clase == 'recuadro' then
    if #el.content == 0 then fallar(el, 'el recuadro está vacío.') end
    if not solo_parrafos(el.content) then
      fallar(el, 'un recuadro solo admite párrafos (con bastardilla, negrita, citas y demás marcas en línea).')
    end
  else
    for _, hijo in ipairs(el.content) do
      if hijo.t ~= 'Div' then
        fallar(el, 'recuadrob sin partir: dos-partes.lua tiene que correr antes que recuadros.lua')
      end
    end
  end
end

-- ============================================
-- Función   : odt
-- Propósito : Conversión mínima del recuadro para el ODT: los párrafos
--             tal cual y, en el recuadrob, la barra como un párrafo en
--             negrita y mayúsculas antes del texto
-- Parámetros: el As Div; clase As String
-- Retorna   : Blocks — lo que reemplaza al recuadro
-- ============================================
local function odt(el, clase)
  local salida = pandoc.Blocks({})
  local barra

  if clase == 'recuadro' then return el.content end

  for _, hijo in ipairs(el.content) do
    if hijo.classes:includes('recuadro-barra') then
      -- pandoc.text.upper TRABAJA SOBRE UTF-8: «ñ» Y LOS ACENTOS PASAN BIEN
      barra = pandoc.text.upper(pandoc.utils.stringify(hijo))
      salida:insert(pandoc.Para({ pandoc.Strong({ pandoc.Str(barra) }) }))
    else
      salida:extend(hijo.content)
    end
  end
  return salida
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Recorre el documento: frena el recuadro viejo y controla los
--             nuevos; en el ODT, además, los resuelve
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento (cambiado solo en el ODT)
-- ============================================
function Pandoc(doc)
  local es_libro = (FORMAT == 'docbook5')
  local es_odt = (FORMAT == 'odt')

  return doc:walk({
    Div = function(el)
      local clase

      -- EL RECUADRO VIEJO SE RETIRÓ (SC-41). SIN ESTE FRENO PANDOC LO
      -- CONVERTIRÍA SOLO EN UN RECUADRO GENÉRICO, SIN AVISO
      if el.classes:includes('box') then
        fallar(el, 'el recuadro ::: {.box} se retiró. Usar ::: recuadro, o ::: recuadrob ' ..
                   'si lleva barra con título: {texto de la barra}{texto del recuadro}.')
      end

      clase = clase_de(el)
      if not clase then return nil end
      controlar(el, clase, es_libro)
      if es_odt then return odt(el, clase) end
      return nil
    end
  })
end
