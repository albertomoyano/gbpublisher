-- ============================================================
-- FILTRO      : alinear.lua
-- PROPÓSITO   : TRADUCE LOS SHORTCODES alinear-izq, alinear-centro
--               Y alinear-der, INSTRUCCIÓN DE COMPOSICIÓN DEL PDF
--               (SC-38, SC-61), A UNA FICHA AL COMIENZO DE CADA
--               PÁRRAFO DEL BLOQUE. NO TOCA NINGUNA OTRA SALIDA.
-- ENTRADA     : ::: alinear-der
--
--               19 de octubre de 2026, Ciudad de México
--
--               [/alinear-der]: # ()
--               :::
-- SALIDA      : JATS (REVISTA)  <p><?gb-alinear der?>19 de …</p>
--               DOCBOOK (LIBRO) <para><?gb-alinear der?>19 de …</para>
--               ODT             LOS PÁRRAFOS, SIN EL BLOQUE NI LA FICHA
--               LA FICHA LA TRADUCEN SOLO docbook-to-latex.xsl Y
--               jats-to-latex.xsl (CON tex-comun.xsl). LAS HOJAS DE
--               HTML Y EPUB NO ESCRIBEN NADA PARA UNA INSTRUCCIÓN DE
--               PROCESAMIENTO: EL PÁRRAFO SALE COMO CUALQUIER OTRO.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : REVISTA, DESPUÉS DE unwrap-structural-divs.lua (LAS
--               SECCIONES ESTRUCTURALES YA NO SON Div) Y ANTES DE
--               cite-to-xref.lua. LIBRO, ANTES DE
--               fenced-divs-to-elements-db.lua. ODT, EN CUALQUIER LUGAR.
--               EN LAS TRES, JUSTO DESPUÉS DE espacio-vertical.lua.
-- REGLA       : DICCIONARIO CERRADO. UN BLOQUE VACÍO, CON ALGO QUE NO
--               SEA UN PÁRRAFO, CON UN SALTO DE LÍNEA MANUAL, CON
--               ATRIBUTOS, CON DOS ALINEACIONES O DENTRO DE OTRO
--               BLOQUE, FRENA LA CONVERSIÓN CON UN MENSAJE: NUNCA SE
--               DEGRADA EN SILENCIO.
-- ============================================================

-- CLASES DEL CATÁLOGO DE gbShortcodes (RF-11) -> FICHA DEL CANÓNICO.
-- LA FICHA ES LA MISMA EN JATS Y EN DOCBOOK
local CLASES = {
  ['alinear-izq']    = 'izq',
  ['alinear-centro'] = 'centro',
  ['alinear-der']    = 'der',
}

-- NOMBRE DE LA INSTRUCCIÓN DE PROCESAMIENTO: PREFIJO gb- (SC-38)
local OBJETIVO = 'gb-alinear'

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  Se admiten ::: alinear-izq, ::: alinear-centro y ::: alinear-der,' ..
  '\n  sin atributos, solos entre párrafos y con uno o más párrafos' ..
  '\n  adentro. Cada renglón va en su propio párrafo, separado por una' ..
  '\n  línea en blanco.'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: clase As String — la clase del bloque, para el prefijo
--             motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(clase, motivo)
  error('\n[' .. clase .. '] ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : clase_de
-- Propósito : Dice si un bloque es uno de los tres shortcodes y cuál
-- Parámetros: el As Block
-- Retorna   : String — la clase; nil si no es un shortcode de alineación
-- ============================================
local function clase_de(el)
  local encontrada

  -- --- 1. SOLO UN Div PUEDE SERLO ---
  if el.t ~= 'Div' then return nil end

  -- --- 2. LA PRIMERA CLASE DEL DICCIONARIO QUE APARECE ---
  for _, clase in ipairs(el.classes) do
    if CLASES[clase] then
      encontrada = clase
      break
    end
  end
  return encontrada
end

-- ============================================
-- Función   : tiene_salto_manual
-- Propósito : Dice si un párrafo lleva un salto de línea manual (barra
--             invertida o dos espacios al final de la línea)
-- Parámetros: parrafo As Para
-- Retorna   : boolean
-- ============================================
local function tiene_salto_manual(parrafo)
  local hay = false

  -- EL SALTO MANUAL HOY NO SIRVE EN PROSA (SC-49): EN LIBRO VUELVE EL
  -- PÁRRAFO UN <literallayout> Y LA FICHA QUEDARÍA FUERA DE UN <para>
  parrafo:walk({ LineBreak = function()
    hay = true
  end })
  return hay
end

-- ============================================
-- Función   : traducir
-- Propósito : Convierte un bloque de alineación en sus párrafos, cada uno
--             con la ficha al comienzo (o sin ella, en el ODT)
-- Parámetros: el As Div — el bloque; clase As String — su clase
-- Retorna   : Blocks — los párrafos del bloque
-- ============================================
local function traducir(el, clase)
  local formato, ficha, bloques

  -- --- 1. UNA SOLA ALINEACIÓN, SIN NADA MÁS EN LA APERTURA ---
  -- EL BLOQUE NO TIENE IDENTIFICADOR NI ATRIBUTOS QUE TRANSMITIR: LO QUE SE
  -- ESCRIBA AHÍ SE PERDERÍA SIN AVISO
  if #el.classes > 1 then
    fallar(clase, 'La apertura lleva una sola clase: se leyó «' ..
           table.concat(el.classes, ' ') .. '».')
  end
  if el.identifier ~= '' or #el.attributes > 0 then
    fallar(clase, 'La apertura no lleva identificador ni atributos.')
  end

  -- --- 2. AL MENOS UN PÁRRAFO ---
  -- EL ANCLA [/alinear-…]: # () LA CONSUME PANDOC AL LEER (SC-33)
  if #el.content == 0 then
    fallar(clase, 'El bloque está vacío: falta el texto entre la apertura y el ancla.')
  end

  -- --- 3. SOLO PÁRRAFOS, SIN SALTOS MANUALES ---
  -- UN TÍTULO, UNA LISTA, UNA FIGURA U OTRO BLOQUE NO SE ALINEAN: LA FICHA
  -- VA SOLO EN UN PÁRRAFO
  for _, bloque in ipairs(el.content) do
    if clase_de(bloque) then
      fallar(clase, 'Un bloque de alineación no puede ir dentro de otro.')
    end
    if bloque.t ~= 'Para' then
      fallar(clase, 'Solo admite párrafos; se encontró: «' ..
             pandoc.utils.stringify(bloque):sub(1, 60) .. '» (' .. bloque.t .. ').')
    end
    if tiene_salto_manual(bloque) then
      fallar(clase, 'Un párrafo lleva un salto de línea manual: «' ..
             pandoc.utils.stringify(bloque):sub(1, 60) .. '».')
    end
  end

  -- --- 4. ODT: LOS PÁRRAFOS TAL CUAL ---
  -- EL ODT ES PARA REVISAR: LA ALINEACIÓN ES DEL PDF (SC-38)
  if FORMAT == 'odt' then return el.content end

  -- --- 5. LA FICHA AL COMIENZO DE CADA PÁRRAFO ---
  -- UNA FICHA POR PÁRRAFO Y NO UN PAR APERTURA/CIERRE: EL GRUPO DE LaTeX
  -- ABRE Y CIERRA DENTRO DEL MISMO PÁRRAFO Y NUNCA QUEDA DESBALANCEADO
  -- (SC-61). MEDIDO CON PANDOC 3.1.3 (GV-115): EL RawInline LLEGA INTACTO AL
  -- <para> Y AL <p>
  formato = (FORMAT == 'docbook5') and 'docbook' or 'jats'
  ficha = '<?' .. OBJETIVO .. ' ' .. CLASES[clase] .. '?>'
  bloques = pandoc.Blocks({})
  for _, bloque in ipairs(el.content) do
    bloque.content:insert(1, pandoc.RawInline(formato, ficha))
    bloques:insert(bloque)
  end
  return bloques
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Traduce los bloques de alineación del primer nivel y frena
--             si queda alguno dentro de otro bloque, una lista, una tabla
--             o una nota
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con los bloques traducidos
-- ============================================
function Pandoc(doc)
  local bloques, clase

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[alinear] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end

  -- --- 2. PRIMER NIVEL: ENTRE PÁRRAFOS, COMO espaciov (SC-39) ---
  -- EN REVISTA LAS SECCIONES ESTRUCTURALES YA LLEGAN DESENVUELTAS; EN LIBRO
  -- LAS SECCIONES SON TÍTULOS, QUE PANDOC AGRUPA RECIÉN AL ESCRIBIR
  bloques = pandoc.Blocks({})
  for _, bloque in ipairs(doc.blocks) do
    clase = clase_de(bloque)
    if clase then
      bloques:extend(traducir(bloque, clase))
    else
      bloques:insert(bloque)
    end
  end
  doc.blocks = bloques

  -- --- 3. LO QUE QUEDÓ ADENTRO DE OTRA COSA ---
  -- EN ODT NO SE CONTROLA: ESA CADENA NO DESENVUELVE LAS SECCIONES
  -- ESTRUCTURALES. SE DEJAN LOS PÁRRAFOS SIN EL BLOQUE; LA REVISTA YA LO
  -- CONTROLA EN LA CADENA DEL XML
  if FORMAT == 'odt' then
    return doc:walk({ Div = function(el)
      if clase_de(el) then return el.content end
    end })
  end
  doc:walk({ Div = function(el)
    clase = clase_de(el)
    if clase then
      fallar(clase, 'El bloque va solo, entre párrafos: no puede ir dentro de ' ..
             'otro bloque, una lista, una tabla o una nota.')
    end
  end })
  return doc
end
