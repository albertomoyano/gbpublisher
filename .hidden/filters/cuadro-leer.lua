-- ============================================================
-- FILTRO      : cuadro-leer.lua
-- PROPÓSITO   : TRAE AL DOCUMENTO EL ARCHIVO DE CADA CUADRO (SC-66) Y LO
--               CONTROLA. EL .md SOLO LO NOMBRA:
--                 ::: {.cuadro #tbl-procedencia}
--                 [/cuadro]: # ()
--                 :::
--               EL ARCHIVO ES cuadros/tbl-procedencia.md, EN LA RAÍZ DEL
--               PROYECTO: UN ENCABEZADO YAML CON LAS DECISIONES DE
--               COMPOSICIÓN Y, DEBAJO, LA TABLA.
-- SALIDA      : EL MISMO Div .cuadro, CON LAS DECISIONES EN SUS ATRIBUTOS
--               Y ADENTRO, EN ESTE ORDEN:
--                 Div .cuadro-titulo   UN Plain CON EL TÍTULO
--                 Div .cuadro-nota     LOS BLOQUES DE LA NOTA (SI HAY)
--                 Table                LA TABLA, SIN SU id
--               UNA CIFRA SOLA EN UNA CELDA DE UNA COLUMNA DE CIFRAS PASA A
--               \num{…}, QUE TRADUCE DESPUÉS cifras.lua (SC-65).
--               EL Div LO ESCRIBE EN XML cuadro-armar.lua.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : PRIMERO EN LAS TRES CADENAS: ASÍ EL CONTENIDO DEL CUADRO
--               PASA POR TODOS LOS FILTROS (COMILLAS, VOLADA, CIFRAS, CITAS)
--               COMO EL RESTO DEL TEXTO.
-- REQUIERE    : -M gb-proyecto=RAÍZ DEL PROYECTO.
-- ENTREGA 1   : CUADRO SIMPLE. LAS CELDAS UNIDAS, VARIAS FILAS DE
--               ENCABEZADO, agrupar, cortes Y rotar FRENAN CON UN MENSAJE
--               HASTA LA ENTREGA 2.
-- ============================================================

-- LAS CLAVES DEL ENCABEZADO: UNA QUE NO ESTÁ ACÁ ES UN ERROR DE TIPEO
local CLAVES = {
  titulo = true, nota = true, cuerpo = true, separacion = true,
  rotar = true, agrupar = true, cortes = true, columnas = true,
}

-- LOS VALORES ADMITIDOS DE LAS CLAVES CON LISTA CERRADA
local CUERPOS = { normal = true, chico = true }
local SEPARACIONES = { normal = true, estrecha = true }
local TIPOS = { texto = true, cifra = true }
local ALINEACIONES = { izq = true, centro = true }

-- LAS ÓRDENES DE LaTeX ADMITIDAS EN EL TEXTO, LAS MISMAS QUE EN EL .md
-- (controles_md.lua, SC-54): EL FILTRO QUE LAS TRADUCE VALIDA SU FORMA
local PATRONES_LATEX = {
  '^\\sptext{.*}$', '^\\num{.*}$', '^\\SI{.*}$', '^\\SIrange{.*}$',
}

-- UNA CIFRA DE ENTRADA EN UNA COLUMNA DE CIFRAS: SIGNO, DÍGITOS Y
-- DECIMALES. SIN EXPONENTE: EL table-format SE CALCULA SIN ÉL
local PATRON_CIFRA_COLUMNA = '^%-?%d+%.?%d*$'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el cuadro
-- Parámetros: id As String — el id del cuadro; motivo As String
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(id, motivo)
  error('\n[cuadro] ' .. id .. ': ' .. motivo .. '\n', 0)
end

-- ============================================
-- Función   : texto_de
-- Propósito : El valor de una clave como texto plano, sin espacios en los
--             bordes y en minúsculas
-- Parámetros: v — el valor del metadato
-- Retorna   : String — '' si no hay valor
-- ============================================
local function texto_de(v)
  if v == nil then return '' end
  if pandoc.utils.type(v) == 'boolean' then return v and 'sí' or 'no' end
  return pandoc.utils.stringify(v):gsub('^%s+', ''):gsub('%s+$', ''):lower()
end

-- ============================================
-- Función   : es_si
-- Propósito : Lee una clave de sí o no
-- Parámetros: id As String; clave As String; v — el valor
-- Retorna   : Boolean — false si falta
-- ============================================
local function es_si(id, clave, v)
  local s = texto_de(v)
  if s == '' or s == 'no' or s == 'false' then return false end
  if s == 'sí' or s == 'si' or s == 'true' then return true end
  fallar(id, clave .. ': «' .. s .. '» no es sí ni no.')
end

-- ============================================
-- Función   : leer_columnas
-- Propósito : Controla la lista de columnas y la pasa a la ficha que lleva
--             el canónico: un elemento por columna, separados por espacio
--             (texto, texto:2.4, texto:2.4:centro, texto::centro, cifra)
-- Parámetros: id As String; v — el metadato columnas; n As Integer — las
--             columnas de la tabla
-- Retorna   : String, Table — la ficha y la lista de tipos por columna
-- ============================================
local function leer_columnas(id, v, n)
  local fichas, tipos = {}, {}

  -- --- 1. UNA LISTA CON UNA ENTRADA POR COLUMNA ---
  if v == nil then fallar(id, 'falta columnas: una entrada por columna.') end
  if pandoc.utils.type(v) ~= 'List' then
    fallar(id, 'columnas es una lista: una línea «- {tipo: …}» por columna.')
  end
  if #v ~= n then
    fallar(id, 'columnas tiene ' .. #v .. ' entradas y la tabla ' .. n .. ' columnas.')
  end

  -- --- 2. CADA COLUMNA ---
  for i, c in ipairs(v) do
    if type(c) ~= 'table' or pandoc.utils.type(c) == 'List' or c.tipo == nil then
      fallar(id, 'la columna ' .. i .. ' no tiene tipo: {tipo: texto} o {tipo: cifra}.')
    end
    for k, _ in pairs(c) do
      -- «ancho: 2,4» LO LEE YAML COMO DOS CLAVES: LA SEGUNDA ES «4»
      if tostring(k):match('^%d+$') then
        fallar(id, 'la columna ' .. i .. ' tiene una coma en el ancho: va con punto decimal (2.4).')
      end
      if k ~= 'tipo' and k ~= 'ancho' and k ~= 'alinear' then
        fallar(id, 'la columna ' .. i .. ' tiene la clave «' .. k ..
          '»: solo van tipo, ancho y alinear.')
      end
    end
    local tipo, ancho, alinear = texto_de(c.tipo), texto_de(c.ancho), texto_de(c.alinear)
    if not TIPOS[tipo] then
      fallar(id, 'la columna ' .. i .. ' es de tipo «' .. tipo .. '»: texto o cifra.')
    end
    if tipo == 'cifra' then
      -- LA COLUMNA DE CIFRAS LA ALINEA siunitx EN EL PUNTO: SIN ANCHO NI ALINEACIÓN
      if ancho ~= '' or alinear ~= '' then
        fallar(id, 'la columna ' .. i .. ' es de cifras: no lleva ancho ni alinear.')
      end
      fichas[i] = 'cifra'
    else
      -- EL ANCHO, EN CENTÍMETROS: UN NÚMERO CON PUNTO DECIMAL
      if ancho ~= '' and not ancho:match('^%d+%.?%d*$') then
        fallar(id, 'la columna ' .. i .. ' tiene ancho «' .. ancho ..
          '»: en centímetros, con punto decimal (2.4).')
      end
      if ancho ~= '' and tonumber(ancho) == 0 then
        fallar(id, 'la columna ' .. i .. ' tiene ancho 0.')
      end
      if alinear ~= '' and not ALINEACIONES[alinear] then
        fallar(id, 'la columna ' .. i .. ' tiene alinear «' .. alinear .. '»: izq o centro.')
      end
      if alinear == 'izq' then alinear = '' end
      fichas[i] = 'texto' .. ((ancho ~= '' or alinear ~= '') and (':' .. ancho) or '') ..
                  (alinear ~= '' and (':' .. alinear) or '')
    end
    tipos[i] = tipo
  end
  return table.concat(fichas, ' '), tipos
end

-- ============================================
-- Función   : controlar_contenido
-- Propósito : Frena lo que no puede ir en un cuadro: notas, HTML crudo y
--             órdenes de LaTeX fuera de las admitidas
-- Parámetros: id As String; donde As String — para el mensaje; el — un
--             elemento o lista de pandoc
-- Retorna   : nada
-- ============================================
local function controlar_contenido(id, donde, el)
  el:walk({
    -- UNA NOTA AL PIE EN UN FLOTANTE NO FUNCIONA EN LaTeX (decisión de Alberto)
    Note = function()
      fallar(id, 'en ' .. donde .. ' hay una nota al pie: un cuadro no lleva notas; ' ..
        'lo que haga falta va en la nota del cuadro (nota:).')
    end,
    RawInline = function(r)
      if r.format == 'html' then
        fallar(id, 'en ' .. donde .. ' hay HTML («' .. r.text .. '»): se pierde.')
      end
      if r.format == 'tex' or r.format == 'latex' then
        for _, p in ipairs(PATRONES_LATEX) do
          if r.text:match(p) then return nil end
        end
        fallar(id, 'en ' .. donde .. ' la orden «' .. r.text .. '» se pierde ' ..
          '(se admiten \\sptext, \\num, \\SI y \\SIrange).')
      end
    end,
    RawBlock = function(r)
      fallar(id, 'en ' .. donde .. ' hay un bloque crudo («' .. r.text .. '»): se pierde.')
    end,
    -- UNA ORDEN QUE PANDOC DEJÓ COMO TEXTO: INCOMPLETA (GV-124) O, EN UNA
    -- CELDA DE pipe table, CUALQUIERA: SALDRÍA LITERAL
    Str = function(s)
      if s.text:find('\\%a') then
        fallar(id, 'en ' .. donde .. ' la orden «' .. s.text .. '» saldría como texto ' ..
          '(se admiten \\sptext, \\num, \\SI y \\SIrange, completas).')
      end
    end,
  })
end

-- ============================================
-- Función   : controlar_tabla
-- Propósito : Controla la forma de la tabla: una sola fila de encabezado,
--             sin celdas unidas, sin pie de Pandoc ni filas de pie
-- Parámetros: id As String; t As Table
-- Retorna   : nada
-- ============================================
local function controlar_tabla(id, t)
  -- --- 1. EL PIE VA EN titulo: Y nota:, NO COMO «: pie» DE PANDOC ---
  if #t.caption.long > 0 or (t.caption.short and #t.caption.short > 0) then
    fallar(id, 'la tabla tiene un pie «: …»: el título va en titulo: y la nota en nota:.')
  end

  -- --- 2. ENTREGA 1: UNA FILA DE ENCABEZADO, UN CUERPO, SIN PIE DE FILAS ---
  if #t.head.rows ~= 1 then
    fallar(id, 'la tabla tiene ' .. #t.head.rows .. ' filas de encabezado: ' ..
      'por ahora, una (el encabezado de dos niveles llega en la entrega 2).')
  end
  if #t.bodies ~= 1 or #t.bodies[1].head > 0 or #t.foot.rows > 0 then
    fallar(id, 'la tabla tiene una forma que todavía no se admite (cuerpos o pies de filas).')
  end
  if #t.bodies[1].body == 0 then fallar(id, 'la tabla no tiene filas.') end

  -- --- 3. ENTREGA 1: SIN CELDAS UNIDAS ---
  local filas = {}
  for _, f in ipairs(t.head.rows) do filas[#filas + 1] = f end
  for _, f in ipairs(t.bodies[1].body) do filas[#filas + 1] = f end
  for _, f in ipairs(filas) do
    for _, c in ipairs(f.cells) do
      if c.row_span ~= 1 or c.col_span ~= 1 then
        fallar(id, 'la tabla tiene celdas unidas: llegan en la entrega 2.')
      end
    end
  end
end

-- ============================================
-- Función   : convertir_cifras
-- Propósito : En una columna de cifras, la celda que es solo una cifra pasa
--             a \num{…}, que traduce cifras.lua; la que ya es \num{…} queda.
--             Lo demás queda como texto: el PDF lo pone entre llaves
-- Parámetros: id As String; t As Table; tipos As Table — por columna
-- Retorna   : nada (cambia la tabla)
-- ============================================
local function convertir_cifras(id, t, tipos)
  for nf, f in ipairs(t.bodies[1].body) do
    for i, c in ipairs(f.cells) do
      if tipos[i] == 'cifra' and #c.contents == 1 and c.contents[1].t == 'Plain'
         and #c.contents[1].content == 1 and c.contents[1].content[1].t == 'Str' then
        local s = c.contents[1].content[1].text
        -- UNA CIFRA CON COMA O CON PUNTO DE MILES NO ES DE ENTRADA (SC-64)
        if s:match('^%-?%d[%d.,]*$') and not s:match(PATRON_CIFRA_COLUMNA) then
          fallar(id, 'fila ' .. nf .. ', columna ' .. i .. ': la cifra «' .. s ..
            '» no tiene la forma de entrada (punto decimal, sin separador de miles).')
        end
        if s:match(PATRON_CIFRA_COLUMNA) then
          if s:match('%.$') then
            fallar(id, 'fila ' .. nf .. ', columna ' .. i .. ': la cifra «' .. s .. '» termina en punto.')
          end
          c.contents[1].content[1] = pandoc.RawInline('tex', '\\num{' .. s .. '}')
        end
      end
    end
  end
end

-- ============================================
-- Función   : leer_cuadro
-- Propósito : Lee el archivo de un cuadro, lo controla y arma el Div que
--             reemplaza a la referencia del .md
-- Parámetros: div As Div — la referencia; raiz As String — la raíz del proyecto
-- Retorna   : Div — el cuadro
-- ============================================
local function leer_cuadro(div, raiz)
  local id, ruta, h, texto, doc, meta, t, ficha_cols, tipos, atributos, hijos

  -- --- 1. LA REFERENCIA: EL id ES EL NOMBRE DEL ARCHIVO ---
  id = div.identifier
  if id == '' then
    fallar('(sin id)', 'el bloque ::: {.cuadro} necesita su id: ::: {.cuadro #tbl-nombre}.')
  end
  if not id:match('^tbl%-[%w%-]+$') then
    fallar(id, 'el id va con el prefijo tbl- y solo letras, cifras y guiones: #tbl-nombre.')
  end
  if #div.classes ~= 1 or #div.attributes > 0 then
    fallar(id, 'el bloque lleva solo la clase y el id: las decisiones van en el archivo del cuadro.')
  end
  if #div.content > 0 then
    fallar(id, 'el bloque ::: {.cuadro} va vacío: la tabla está en cuadros/' .. id .. '.md.')
  end

  -- --- 2. EL ARCHIVO ---
  ruta = raiz .. '/cuadros/' .. id .. '.md'
  h = io.open(ruta, 'r')
  if not h then fallar(id, 'no existe el archivo cuadros/' .. id .. '.md.') end
  texto = h:read('a')
  h:close()
  doc = pandoc.read(texto, 'markdown')
  meta = doc.meta

  -- --- 3. EL ENCABEZADO: CLAVES CONOCIDAS ---
  for k, _ in pairs(meta) do
    if not CLAVES[k] then
      fallar(id, 'el encabezado tiene la clave «' .. k .. '», que no existe.')
    end
  end
  if meta.titulo == nil then
    fallar(id, 'falta titulo: (puede ir vacío, titulo: "").')
  end
  local cuerpo = texto_de(meta.cuerpo)
  if cuerpo == '' then cuerpo = 'normal' end
  if not CUERPOS[cuerpo] then fallar(id, 'cuerpo: «' .. cuerpo .. '»: normal o chico.') end
  local separacion = texto_de(meta.separacion)
  if separacion == '' then separacion = 'normal' end
  if not SEPARACIONES[separacion] then
    fallar(id, 'separacion: «' .. separacion .. '»: normal o estrecha.')
  end
  -- ENTREGA 1: LO QUE LLEGA EN LA 2 FRENA SI SE PIDE
  if es_si(id, 'rotar', meta.rotar) then fallar(id, 'rotar llega en la entrega 2.') end
  if es_si(id, 'agrupar', meta.agrupar) then fallar(id, 'agrupar llega en la entrega 2.') end
  if meta.cortes ~= nil and #meta.cortes > 0 then fallar(id, 'cortes llega en la entrega 2.') end

  -- --- 4. EL CUERPO: UNA TABLA Y NADA MÁS ---
  if #doc.blocks ~= 1 or doc.blocks[1].t ~= 'Table' then
    fallar(id, 'debajo del encabezado va una tabla y nada más.')
  end
  t = doc.blocks[1]
  controlar_tabla(id, t)
  ficha_cols, tipos = leer_columnas(id, meta.columnas, #t.colspecs)

  -- --- 5. EL CONTENIDO: SIN NOTAS, HTML NI LaTeX PERDIDO ---
  controlar_contenido(id, 'la tabla', t)
  local titulo = pandoc.Inlines({})
  if pandoc.utils.type(meta.titulo) == 'Inlines' then
    titulo = meta.titulo
  elseif texto_de(meta.titulo) ~= '' then
    fallar(id, 'titulo va en una línea.')
  end
  controlar_contenido(id, 'el título', pandoc.Plain(titulo))
  local nota = nil
  if meta.nota ~= nil then
    if pandoc.utils.type(meta.nota) == 'Inlines' then
      nota = pandoc.Blocks({ pandoc.Para(meta.nota) })
    else
      nota = meta.nota
    end
    controlar_contenido(id, 'la nota', pandoc.Div(nota))
  end

  -- --- 6. LAS CIFRAS DE LAS COLUMNAS DE CIFRAS ---
  convertir_cifras(id, t, tipos)

  -- --- 7. EL Div QUE LEE cuadro-armar.lua ---
  t.attr = pandoc.Attr()
  hijos = { pandoc.Div({ pandoc.Plain(titulo) }, pandoc.Attr('', { 'cuadro-titulo' })) }
  if nota then
    hijos[#hijos + 1] = pandoc.Div(nota, pandoc.Attr('', { 'cuadro-nota' }))
  end
  hijos[#hijos + 1] = t
  atributos = { cuerpo = cuerpo, separacion = separacion, columnas = ficha_cols }
  return pandoc.Div(hijos, pandoc.Attr(id, { 'cuadro' }, atributos))
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Trae los cuadros del documento y frena el viejo ::: {.table}
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con los cuadros
-- ============================================
function Pandoc(doc)
  local raiz

  -- --- 1. LA RAÍZ DEL PROYECTO, PARA ENCONTRAR cuadros/ ---
  if doc.meta['gb-proyecto'] then
    raiz = pandoc.utils.stringify(doc.meta['gb-proyecto']):gsub('/$', '')
  end

  -- --- 2. CADA CUADRO; EL VIEJO ::: {.table} FRENA ---
  return doc:walk({ Div = function(el)
    if el.classes:includes('table') then
      error('\n[cuadro] ::: {.table} se retiró: el cuadro va en su archivo, ' ..
        'cuadros/tbl-nombre.md, y en el texto ::: {.cuadro #tbl-nombre} (SC-66).\n', 0)
    end
    if not el.classes:includes('cuadro') then return nil end
    if not raiz then
      error('\n[cuadro] falta -M gb-proyecto: la cadena no pasa la raíz del proyecto.\n', 0)
    end
    return leer_cuadro(el, raiz)
  end })
end
