-- ============================================================
-- FILTRO      : cuadro-armar.lua
-- PROPÓSITO   : ESCRIBE EN EL CANÓNICO EL CUADRO QUE TRAJO cuadro-leer.lua
--               (SC-66). LO ESCRIBE ESTE FILTRO Y NO PANDOC: EL ESCRITOR
--               DocBook DE PANDOC 3.1.3 PIERDE LAS CELDAS UNIDAS Y PASA LA
--               SEGUNDA FILA DEL ENCABEZADO AL CUERPO (GV-126), Y NINGUNO DE
--               LOS DOS ESCRITORES LLEVA LA NOTA NI LAS DECISIONES.
-- SALIDA      : DOCBOOK
--                 <table xml:id="tbl-…"><title>…</title>
--                 <?gb-cuadro cuerpo="…" separacion="…" columnas="…"?>
--                 <tgroup cols="N"> colspec (align left|center|char) …
--                 thead / tbody …</tgroup>
--                 <caption><para>LA NOTA</para></caption></table>
--               JATS
--                 <table-wrap id="tbl-…"><caption><title>…</title></caption>
--                 <?gb-cuadro …?><table> col … thead / tbody …</table>
--                 <table-wrap-foot><p>LA NOTA</p></table-wrap-foot></table-wrap>
--               ODT
--                 EL TÍTULO EN NEGRITA, LA TABLA Y LA NOTA, SIN NÚMERO
--               LA INSTRUCCIÓN gb-cuadro LLEVA LAS DECISIONES DE COMPOSICIÓN
--               SIN LaTeX (SC-38). LA COLUMNA DE CIFRAS VA ALINEADA POR EL
--               PUNTO (align="char" char=".").
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE LOS FILTROS QUE TRADUCEN EL CONTENIDO (cifras,
--               volada, LAS CITAS). LIBRO: JUSTO ANTES DE
--               fenced-divs-to-elements-db.lua, QUE SERIALIZA LOS BLOQUES
--               QUE CONTIENEN A OTROS. REVISTA Y ODT: AL FINAL.
-- ============================================================

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje
-- Parámetros: motivo As String
-- Retorna   : no retorna
-- ============================================
local function fallar(motivo)
  error('\n[cuadro] ' .. motivo .. '\n', 0)
end

-- ============================================
-- Función   : atributo
-- Propósito : Escapa un texto para un atributo XML
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function atributo(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('"', '&quot;'))
end

-- ============================================
-- Función   : sin_bordes
-- Propósito : Quita el espacio de los bordes de un texto serializado
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function sin_bordes(s)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- ============================================
-- Función   : en_linea
-- Propósito : Serializa bloques de una celda o del título como contenido en
--             línea. El escritor JATS envuelve un Plain en <p>: se lo quita
-- Parámetros: bloques As Blocks; formato As String — 'docbook5' o 'jats'
-- Retorna   : String
-- ============================================
local function en_linea(bloques, formato)
  local s

  -- --- 1. SOLO UN Plain (O NADA): UNA CELDA NO LLEVA PÁRRAFOS ---
  if #bloques == 0 then return '' end
  if #bloques > 1 or (bloques[1].t ~= 'Plain' and bloques[1].t ~= 'Para') then
    fallar('una celda o el título tiene más de un párrafo, o un bloque.')
  end

  -- --- 2. SERIALIZAR ---
  s = sin_bordes(pandoc.write(pandoc.Pandoc({ pandoc.Plain(bloques[1].content) }), formato, PANDOC_WRITER_OPTIONS))
  if formato == 'jats' then
    s = s:gsub('^<p>', ''):gsub('</p>$', '')
  end
  return s
end

-- ============================================
-- Función   : partes
-- Propósito : Separa el Div del cuadro en título, nota y tabla
-- Parámetros: div As Div
-- Retorna   : Blocks, Blocks, Table — el título, la nota (o nil) y la tabla
-- ============================================
local function partes(div)
  local titulo, nota, t
  for _, b in ipairs(div.content) do
    if b.t == 'Div' and b.classes:includes('cuadro-titulo') then titulo = b.content
    elseif b.t == 'Div' and b.classes:includes('cuadro-nota') then nota = b.content
    elseif b.t == 'Table' then t = b end
  end
  -- SIN ESTAS PARTES, cuadro-leer.lua NO CORRIÓ: ES UN ERROR DE CADENA
  if not titulo or not t then
    fallar(div.identifier .. ': el cuadro no está leído: cuadro-leer.lua tiene que correr antes.')
  end
  return titulo, nota, t
end

-- ============================================
-- Función   : alineaciones
-- Propósito : La alineación de cada columna según la ficha de columnas
-- Parámetros: ficha As String — «texto texto:2.4:centro cifra»
-- Retorna   : Table — 'left', 'center' o 'char' por columna
-- ============================================
local function alineaciones(ficha)
  local a = {}
  for col in ficha:gmatch('%S+') do
    if col == 'cifra' then a[#a + 1] = 'char'
    elseif col:match(':centro$') then a[#a + 1] = 'center'
    else a[#a + 1] = 'left' end
  end
  return a
end

-- ============================================
-- Función   : instruccion
-- Propósito : La instrucción gb-cuadro con las decisiones de composición
-- Parámetros: div As Div
-- Retorna   : String
-- ============================================
local function instruccion(div)
  return '<?gb-cuadro cuerpo="' .. atributo(div.attributes.cuerpo) ..
         '" separacion="' .. atributo(div.attributes.separacion) ..
         '" columnas="' .. atributo(div.attributes.columnas) .. '"?>'
end

-- ============================================
-- Función   : docbook
-- Propósito : El cuadro en DocBook (tabla CALS)
-- Parámetros: div As Div
-- Retorna   : RawBlock
-- ============================================
local function docbook(div)
  local titulo, nota, t = partes(div)
  local al = alineaciones(div.attributes.columnas)
  local x = {}

  -- --- 1. TABLA, TÍTULO E INSTRUCCIÓN ---
  x[#x + 1] = '<table xml:id="' .. atributo(div.identifier) .. '">'
  x[#x + 1] = '<title>' .. en_linea(titulo, 'docbook5') .. '</title>'
  x[#x + 1] = instruccion(div)
  x[#x + 1] = '<tgroup cols="' .. #al .. '">'

  -- --- 2. COLUMNAS ---
  for i, a in ipairs(al) do
    x[#x + 1] = '<colspec colname="c' .. i .. '" align="' .. a .. '"' ..
                (a == 'char' and ' char="."' or '') .. '/>'
  end

  -- --- 3. ENCABEZADO Y CUERPO ---
  local function filas(lista)
    for _, f in ipairs(lista) do
      x[#x + 1] = '<row>'
      for _, c in ipairs(f.cells) do
        x[#x + 1] = '<entry>' .. en_linea(c.contents, 'docbook5') .. '</entry>'
      end
      x[#x + 1] = '</row>'
    end
  end
  x[#x + 1] = '<thead>'
  filas(t.head.rows)
  x[#x + 1] = '</thead>'
  x[#x + 1] = '<tbody>'
  filas(t.bodies[1].body)
  x[#x + 1] = '</tbody>'
  x[#x + 1] = '</tgroup>'

  -- --- 4. LA NOTA: <caption> AL FINAL DE LA TABLA (DocBook 5.2) ---
  if nota then
    x[#x + 1] = '<caption>' ..
      sin_bordes(pandoc.write(pandoc.Pandoc(nota), 'docbook5', PANDOC_WRITER_OPTIONS)) .. '</caption>'
  end
  x[#x + 1] = '</table>'
  return pandoc.RawBlock('docbook', table.concat(x, '\n'))
end

-- ============================================
-- Función   : jats
-- Propósito : El cuadro en JATS (table-wrap con tabla XHTML)
-- Parámetros: div As Div
-- Retorna   : RawBlock
-- ============================================
local function jats(div)
  local titulo, nota, t = partes(div)
  local al = alineaciones(div.attributes.columnas)
  local x = {}

  -- --- 1. ENVOLTORIO, TÍTULO E INSTRUCCIÓN ---
  x[#x + 1] = '<table-wrap id="' .. atributo(div.identifier) .. '">'
  x[#x + 1] = '<caption><title>' .. en_linea(titulo, 'jats') .. '</title></caption>'
  x[#x + 1] = instruccion(div)
  x[#x + 1] = '<table>'

  -- --- 2. COLUMNAS ---
  for _, a in ipairs(al) do
    x[#x + 1] = '<col align="' .. a .. '"' .. (a == 'char' and ' char="."' or '') .. '/>'
  end

  -- --- 3. ENCABEZADO Y CUERPO ---
  local function filas(lista, celda)
    for _, f in ipairs(lista) do
      x[#x + 1] = '<tr>'
      for i, c in ipairs(f.cells) do
        x[#x + 1] = '<' .. celda .. ' align="' .. al[i] .. '"' ..
          (al[i] == 'char' and ' char="."' or '') .. '>' ..
          en_linea(c.contents, 'jats') .. '</' .. celda .. '>'
      end
      x[#x + 1] = '</tr>'
    end
  end
  x[#x + 1] = '<thead>'
  filas(t.head.rows, 'th')
  x[#x + 1] = '</thead>'
  x[#x + 1] = '<tbody>'
  filas(t.bodies[1].body, 'td')
  x[#x + 1] = '</tbody>'
  x[#x + 1] = '</table>'

  -- --- 4. LA NOTA ---
  if nota then
    x[#x + 1] = '<table-wrap-foot>' ..
      sin_bordes(pandoc.write(pandoc.Pandoc(nota), 'jats', PANDOC_WRITER_OPTIONS)) .. '</table-wrap-foot>'
  end
  x[#x + 1] = '</table-wrap>'
  return pandoc.RawBlock('jats', table.concat(x, '\n'))
end

-- ============================================
-- Función   : odt
-- Propósito : El cuadro en el ODT: título en negrita, la tabla y la nota
-- Parámetros: div As Div
-- Retorna   : Blocks
-- ============================================
local function odt(div)
  local titulo, nota, t = partes(div)
  local b = {}
  if #titulo > 0 and #titulo[1].content > 0 then
    b[#b + 1] = pandoc.Para({ pandoc.Strong(titulo[1].content) })
  end
  b[#b + 1] = t
  if nota then
    for _, n in ipairs(nota) do b[#b + 1] = n end
  end
  return pandoc.Blocks(b)
end

-- ============================================
-- Función   : Div
-- Propósito : Escribe cada cuadro según el formato de salida
-- Parámetros: el As Div
-- Retorna   : RawBlock o Blocks; nil si no es un cuadro
-- ============================================
function Div(el)
  if not el.classes:includes('cuadro') then return nil end
  if FORMAT == 'docbook5' then return docbook(el) end
  if FORMAT == 'jats' then return jats(el) end
  if FORMAT == 'odt' then return odt(el) end
  fallar('formato de salida no previsto: ' .. FORMAT)
end
