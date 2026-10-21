-- ============================================================
-- FILTRO      : corte-titulo.lua
-- PROPÓSITO   : TRADUCE EL CORTE DE LÍNEA \\ DE UN TÍTULO DEL .md
--               (## Corte de\\ subtítulo) A LA MARCA DE SC-28 EN EL
--               CANÓNICO. EL CORTE SE CUMPLE SOLO EN LA APERTURA DEL
--               PDF; EN EL SUMARIO, LOS MARCADORES, EL HTML, EL EPUB Y
--               LOS INDEXADORES ES UN ESPACIO (SC-63).
-- ENTRADA     : ## Corte de\\ subtítulo
--               PANDOC LEE \\ COMO UNA BARRA ESCAPADA: Str "de\" (GV-121)
-- SALIDA      : JATS (REVISTA)  <title>Corte de <break/>subtítulo</title>
--               DOCBOOK (LIBRO) <title>Corte de <?gb-corte?>subtítulo</title>
--               ODT             «Corte de subtítulo»
--               UN SOLO ESPACIO, ANTES DE LA MARCA: EL VALOR DE TEXTO DE LA
--               MARCA ES VACÍO, ASÍ QUE QUIEN LEE EL TÍTULO COMO CADENA VE
--               «Corte de subtítulo», Y UNA PLANTILLA VACÍA PARA LA MARCA NO
--               DEJA DOS ESPACIOS (SC-63).
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN LAS TRES CADENAS, JUSTO DESPUÉS DE volada.lua.
-- REGLA       : VARIOS CORTES POR TÍTULO (DECISIÓN DE ALBERTO). FRENA SI UN
--               CORTE QUEDA AL PRINCIPIO O AL FINAL DEL TÍTULO, SI HAY DOS
--               SEGUIDOS, O SI VA DENTRO DE UNA MARCA (BASTARDILLA, NEGRITA,
--               UN SPAN). FUERA DE LOS TÍTULOS NO HACE NADA: UNA \\ EN EL
--               TEXTO LA INFORMA corte_fuera_de_titulo EN controles_md.lua
--               (SC-54); PARA CORTAR FUERA DE UN TÍTULO ESTÁ espaciov.
-- ============================================================

-- LA BARRA QUE QUEDA DE \\ EN EL .md
local BARRA = '\\'

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  El corte de un título se escribe \\\\ entre dos palabras:' ..
  '\n  «## Corte de\\\\ subtítulo». Puede haber varios, nunca dos' ..
  '\n  seguidos, ni al principio o al final del título, ni dentro de' ..
  '\n  una bastardilla, una negrita u otra marca.'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: titulo As Inlines — el título, para el mensaje
--             motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(titulo, motivo)
  error('\n[corte-titulo] «' .. pandoc.utils.stringify(titulo) .. '»: ' ..
        motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : marca
-- Propósito : La marca de corte en el formato de salida
-- Parámetros: ninguno
-- Retorna   : Inline — la marca; nil en el ODT, donde el corte es un espacio
-- ============================================
local function marca()
  if FORMAT == 'jats' then return pandoc.RawInline('jats', '<break/>') end
  if FORMAT == 'docbook5' then return pandoc.RawInline('docbook', '<?gb-corte?>') end
  return nil
end

-- ============================================
-- Función   : partir_str
-- Propósito : Parte el texto de un Str en las barras
-- Parámetros: s As String — el texto del Str
-- Retorna   : table — los tramos, en orden; un tramo vacío es un corte
--             pegado a otro, al borde del Str o a un espacio
-- ============================================
local function partir_str(s)
  local tramos, inicio, pos

  -- --- 1. find CON plain = true: LA BARRA ES UN CARÁCTER, NO UN PATRÓN ---
  tramos = {}
  inicio = 1
  while true do
    pos = s:find(BARRA, inicio, true)
    if not pos then break end
    table.insert(tramos, s:sub(inicio, pos - 1))
    inicio = pos + 1
  end
  table.insert(tramos, s:sub(inicio))
  return tramos
end

-- ============================================
-- Función   : es_texto
-- Propósito : Dice si un elemento en línea cuenta como texto a los lados
--             de un corte (no un espacio ni otra marca de corte)
-- Parámetros: el As Inline
-- Retorna   : boolean
-- ============================================
local function es_texto(el)
  if not el then return false end
  if el.t == 'Space' or el.t == 'SoftBreak' or el.t == 'LineBreak' then return false end
  if el.t == 'RawInline' and (el.text == '<break/>' or el.text == '<?gb-corte?>') then return false end
  if el.t == 'Str' and el.text == '' then return false end
  return true
end

-- ============================================
-- Función   : traducir_titulo
-- Propósito : Reemplaza cada barra del primer nivel de un título por un
--             espacio y la marca, y controla dónde quedó cada corte
-- Parámetros: titulo As Inlines — el contenido del Header
-- Retorna   : Inlines — el título con las marcas
-- ============================================
local function traducir_titulo(titulo)
  local resultado, tramos, cortes, el, anterior, siguiente, m

  -- --- 1. NINGUNA BARRA DENTRO DE UNA MARCA ---
  -- <break/> NO SIEMPRE ES VÁLIDO DENTRO DE <italic> O <bold>, Y EL CORTE
  -- PARTIRÍA LA MARCA EN EL PDF. SE ESCRIBE AFUERA. UNA NOTA DEL TÍTULO NO
  -- SE MIRA: SU TEXTO NO ES EL TÍTULO, Y UNA \\ AHÍ LA INFORMA controles_md.lua
  for _, hijo in ipairs(titulo) do
    if hijo.t ~= 'Str' and hijo.t ~= 'Note' and hijo.content then
      hijo:walk({ Str = function(s)
        if s.text:find(BARRA, 1, true) then
          fallar(titulo, 'el corte está dentro de una bastardilla, una negrita u otra marca.')
        end
      end })
    end
  end

  -- --- 2. CADA BARRA DEL PRIMER NIVEL: ESPACIO Y MARCA ---
  resultado = pandoc.Inlines({})
  cortes = 0
  for _, hijo in ipairs(titulo) do
    if hijo.t == 'Str' and hijo.text:find(BARRA, 1, true) then
      tramos = partir_str(hijo.text)
      for i, tramo in ipairs(tramos) do
        if i > 1 then
          -- UN ESPACIO ANTES DE LA MARCA, NINGUNO DESPUÉS (VER CABECERA).
          -- EL QUE HAYA ESCRITO EL EDITOR DESPUÉS DE \\ SE QUITA EN EL 3
          cortes = cortes + 1
          if resultado[#resultado] and resultado[#resultado].t ~= 'Space' then
            resultado:insert(pandoc.Space())
          end
          m = marca()
          resultado:insert(m or pandoc.Str(''))
        end
        if tramo ~= '' then resultado:insert(pandoc.Str(tramo)) end
      end
    else
      resultado:insert(hijo)
    end
  end
  if cortes == 0 then return nil end

  -- --- 3. DESPUÉS DE LA MARCA NO VA ESPACIO ---
  local limpio = pandoc.Inlines({})
  for i, x in ipairs(resultado) do
    anterior = resultado[i - 1]
    if x.t == 'Space' and anterior
       and ((anterior.t == 'RawInline' and (anterior.text == '<break/>' or anterior.text == '<?gb-corte?>'))
            or (anterior.t == 'Str' and anterior.text == '')) then
      -- SE SALTEA
    else
      limpio:insert(x)
    end
  end

  -- --- 4. CADA CORTE ENTRE DOS TRAMOS DE TEXTO ---
  for i, x in ipairs(limpio) do
    if (x.t == 'RawInline' and (x.text == '<break/>' or x.text == '<?gb-corte?>'))
       or (x.t == 'Str' and x.text == '') then
      -- ANTES: EL ESPACIO QUE PUSO EL 2, Y ANTES DE ÉL TEXTO
      anterior = limpio[i - 2]
      siguiente = limpio[i + 1]
      if not es_texto(anterior) then
        fallar(titulo, 'un corte al principio del título o pegado a otro corte.')
      end
      if not es_texto(siguiente) then
        fallar(titulo, 'un corte al final del título o pegado a otro corte.')
      end
    end
  end

  -- --- 5. EN EL ODT, LA MARCA VACÍA SE VA: QUEDA EL ESPACIO ---
  if FORMAT == 'odt' then
    return limpio:filter(function(x) return not (x.t == 'Str' and x.text == '') end)
  end
  return limpio
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Traduce los cortes de todos los títulos del documento
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con los títulos traducidos
-- ============================================
function Pandoc(doc)

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[corte-titulo] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end

  -- --- 2. TODOS LOS TÍTULOS, TAMBIÉN DENTRO DE UN BLOQUE ---
  return doc:walk({ Header = function(h)
    local nuevo = traducir_titulo(h.content)
    if nuevo then
      h.content = nuevo
      return h
    end
  end })
end
