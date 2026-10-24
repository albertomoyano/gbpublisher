-- ============================================================
-- FILTRO      : cuadro-leer.lua
-- PROPÓSITO   : TRAE AL DOCUMENTO EL ARCHIVO DE CADA CUADRO (SC-66) Y LO
--               CONTROLA. UNA TABLA ESCRITA EN EL .md FRENA: TODA TABLA VA
--               EN SU ARCHIVO (decisión de Alberto). EL .md SOLO LA NOMBRA:
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
--               CADA CELDA LLEVA EN EL ATRIBUTO gb-col LA COLUMNA DONDE
--               EMPIEZA (CON CELDAS UNIDAS, SU POSICIÓN EN LA FILA NO LO DICE).
--               UNA CIFRA SOLA EN UNA CELDA DE UNA COLUMNA DE CIFRAS PASA A
--               \num{…}, QUE TRADUCE DESPUÉS cifras.lua (SC-65).
--               EL Div LO ESCRIBE EN XML cuadro-armar.lua.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : PRIMERO EN LAS TRES CADENAS: ASÍ EL CONTENIDO DEL CUADRO
--               PASA POR TODOS LOS FILTROS (COMILLAS, VOLADA, CIFRAS, CITAS)
--               COMO EL RESTO DEL TEXTO.
-- REQUIERE    : -M gb-proyecto=RAÍZ DEL PROYECTO.
-- ENTREGA 2   : CELDAS UNIDAS (grid table), VARIAS FILAS DE ENCABEZADO,
--               agrupar, cortes, bloques, rotar Y, EN REVISTAS, ancho: total.
-- ============================================================

-- LAS CLAVES DEL ENCABEZADO: UNA QUE NO ESTÁ ACÁ ES UN ERROR DE TIPEO
local CLAVES = {
  titulo = true, nota = true, cuerpo = true, separacion = true,
  rotar = true, agrupar = true, cortes = true, columnas = true,
  bloques = true, ancho = true,
}

-- LOS VALORES ADMITIDOS DE LAS CLAVES CON LISTA CERRADA
local CUERPOS = { normal = true, chico = true }
local SEPARACIONES = { normal = true, estrecha = true }
local TIPOS = { texto = true, cifra = true }
local ALINEACIONES = { izq = true, centro = true }
local ANCHOS = { columna = true, total = true }

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
-- Propósito : Controla la forma de la tabla: sin pie de Pandoc, un solo
--             cuerpo, sin filas de pie
-- Parámetros: id As String; t As Table
-- Retorna   : nada
-- ============================================
local function controlar_tabla(id, t)
  -- --- 1. EL PIE VA EN titulo: Y nota:, NO COMO «: pie» DE PANDOC ---
  if #t.caption.long > 0 or (t.caption.short and #t.caption.short > 0) then
    fallar(id, 'la tabla tiene un pie «: …»: el título va en titulo: y la nota en nota:.')
  end

  -- --- 2. UN ENCABEZADO (UNA O MÁS FILAS), UN CUERPO, SIN PIE DE FILAS ---
  if #t.head.rows == 0 then
    fallar(id, 'la tabla no tiene fila de encabezado.')
  end
  if #t.bodies ~= 1 or #t.bodies[1].head > 0 or #t.foot.rows > 0 then
    fallar(id, 'la tabla tiene una forma que no se admite (varios cuerpos o filas de pie).')
  end
  if #t.bodies[1].body == 0 then fallar(id, 'la tabla no tiene filas.') end
end

-- ============================================
-- Función   : celda_vacia
-- Propósito : Dice si una celda no tiene contenido
-- Parámetros: c As Cell
-- Retorna   : Boolean
-- ============================================
local function celda_vacia(c)
  return #c.contents == 0 or pandoc.utils.stringify(c.contents):match('^%s*$') ~= nil
end

-- ============================================
-- Función   : agrupar_filas
-- Propósito : agrupar: sí. La celda vacía de la primera columna continúa el
--             grupo de la fila anterior: la primera celda del grupo pasa a
--             ocupar sus filas (row_span) y la vacía se quita. Es la
--             práctica de la casa: el valor solo en la primera fila del
--             grupo, y \cmidrule{2-n} entre las filas del grupo
-- Parámetros: id As String; t As Table
-- Retorna   : nada (cambia la tabla)
-- ============================================
local function agrupar_filas(id, t)
  local cabeza = nil
  for nf, f in ipairs(t.bodies[1].body) do
    local c = f.cells[1]
    -- LA PRIMERA COLUMNA NO PUEDE TRAER YA CELDAS UNIDAS: SERÍAN DOS REGLAS
    if c.row_span ~= 1 or c.col_span ~= 1 then
      fallar(id, 'con agrupar: sí, la primera columna no lleva celdas unidas (fila ' .. nf .. ').')
    end
    if celda_vacia(c) and cabeza then
      cabeza.row_span = cabeza.row_span + 1
      f.cells:remove(1)
    else
      -- UNA FILA CON VALOR ABRE UN GRUPO; LA PRIMERA VACÍA QUEDA COMO CELDA VACÍA
      cabeza = (not celda_vacia(c)) and c or nil
    end
  end
end

-- ============================================
-- Función   : mapear
-- Propósito : Ubica cada celda en su columna, con las celdas unidas que
--             vienen de filas anteriores, y guarda la columna en gb-col.
--             Dice además qué columnas siguen unidas al pasar de cada fila
--             a la siguiente: ahí no va filete, ni se puede cortar
-- Parámetros: id As String; filas As List — las filas (Row); n As Integer —
--             las columnas; donde As String — para el mensaje
-- Retorna   : Table — por fila, el conjunto de columnas que siguen unidas
--             después de ella
-- ============================================
local function mapear(id, filas, n, donde)
  local resto, cruza = {}, {}
  for j = 1, n do resto[j] = 0 end

  for nf, f in ipairs(filas) do
    local ocupada, nuevo, col = {}, {}, 1
    -- --- 1. LAS COLUMNAS QUE OCUPA UNA CELDA DE UNA FILA ANTERIOR ---
    for j = 1, n do ocupada[j] = resto[j] > 0 end
    -- --- 2. CADA CELDA, EN LA PRIMERA COLUMNA LIBRE ---
    for _, c in ipairs(f.cells) do
      while col <= n and ocupada[col] do col = col + 1 end
      if col + c.col_span - 1 > n then
        fallar(id, donde .. ', fila ' .. nf .. ': las celdas no entran en las ' .. n .. ' columnas.')
      end
      c.attr.attributes['gb-col'] = tostring(col)
      for j = col, col + c.col_span - 1 do
        ocupada[j] = true
        nuevo[j] = c.row_span - 1
      end
      col = col + c.col_span
    end
    -- --- 3. LO QUE SIGUE UNIDO AL PASAR A LA FILA SIGUIENTE ---
    cruza[nf] = {}
    for j = 1, n do
      if not ocupada[j] then
        fallar(id, donde .. ', fila ' .. nf .. ': falta la celda de la columna ' .. j .. '.')
      end
      resto[j] = (resto[j] > 0) and (resto[j] - 1) or (nuevo[j] or 0)
      if resto[j] > 0 then cruza[nf][j] = true end
    end
  end
  return cruza
end

-- ============================================
-- Función   : leer_filas_lista
-- Propósito : Lee cortes: o bloques: — números de fila del cuerpo, tras las
--             que corta el cuadro o va el filete doble — y los controla
-- Parámetros: id As String; clave As String; v — el metadato; nfilas As
--             Integer — las filas del cuerpo; cruza As Table — de mapear
-- Retorna   : Table — los números, en orden
-- ============================================
local function leer_filas_lista(id, clave, v, nfilas, cruza)
  local lista = {}
  if v == nil then return lista end
  if pandoc.utils.type(v) ~= 'List' then
    fallar(id, clave .. ' es una lista de números de fila: ' .. clave .. ': [12].')
  end
  for _, x in ipairs(v) do
    local s = texto_de(x)
    local k = tonumber(s)
    if not s:match('^%d+$') or not k then
      fallar(id, clave .. ': «' .. s .. '» no es un número de fila.')
    end
    -- DESPUÉS DE LA ÚLTIMA FILA NO HAY NADA QUE CORTAR NI SEPARAR
    if k < 1 or k >= nfilas then
      fallar(id, clave .. ': la fila ' .. k .. ' no deja filas después (el cuerpo tiene ' .. nfilas .. ').')
    end
    if #lista > 0 and k <= lista[#lista] then
      fallar(id, clave .. ': los números van en orden y sin repetir.')
    end
    -- UNA CELDA UNIDA QUE PASA DE ESA FILA A LA SIGUIENTE QUEDARÍA PARTIDA
    if next(cruza[k]) then
      fallar(id, clave .. ': después de la fila ' .. k .. ' sigue una celda unida (o un grupo).')
    end
    lista[#lista + 1] = k
  end
  return lista
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
    for _, c in ipairs(f.cells) do
      -- LA COLUMNA LA DICE gb-col (mapear): CON CELDAS UNIDAS, LA POSICIÓN NO.
      -- UNA CELDA QUE UNE VARIAS COLUMNAS NO ES DE LA COLUMNA S: QUEDA COMO TEXTO
      local i = tonumber(c.attr.attributes['gb-col'])
      if tipos[i] == 'cifra' and c.col_span == 1 and #c.contents == 1 and c.contents[1].t == 'Plain'
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
  -- LA LISTA DE ABREVIATURAS DE LA LÍNEA DE ÓRDENES (SC-68): pandoc.read NO
  -- LA TOMA SOLO. SE PASA ESA OPCIÓN Y NINGUNA OTRA: CON TODO
  -- PANDOC_READER_OPTIONS CAMBIA columns Y EL ANCHO RELATIVO DE LAS
  -- COLUMNAS DE UNA GRID TABLE (GV-133)
  doc = pandoc.read(texto, 'markdown', { abbreviations = PANDOC_READER_OPTIONS.abbreviations })
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
  local rotar = es_si(id, 'rotar', meta.rotar)
  local agrupar = es_si(id, 'agrupar', meta.agrupar)
  -- EL ANCHO TOTAL ES DE LA REVISTA (COLUMNA, CALLE Y COLUMNA DERECHA): EN EL
  -- LIBRO HAY UN SOLO ANCHO, EL DE LA CAJA (decisión de Alberto)
  local ancho = texto_de(meta.ancho)
  if ancho == '' then ancho = 'columna' end
  if not ANCHOS[ancho] then fallar(id, 'ancho: «' .. ancho .. '»: columna o total.') end
  if ancho == 'total' and FORMAT == 'docbook5' then
    fallar(id, 'ancho: total es de las revistas: en el libro hay un solo ancho, el de la caja.')
  end
  -- EL CUADRO APAISADO OCUPA LA PÁGINA: EL ANCHO TOTAL NO SUMA NADA
  if ancho == 'total' and rotar then
    fallar(id, 'rotar y ancho: total no van juntos: el cuadro apaisado ya ocupa la página.')
  end

  -- --- 4. EL CUERPO: UNA TABLA Y NADA MÁS ---
  if #doc.blocks ~= 1 or doc.blocks[1].t ~= 'Table' then
    fallar(id, 'debajo del encabezado va una tabla y nada más.')
  end
  t = doc.blocks[1]
  controlar_tabla(id, t)
  ficha_cols, tipos = leer_columnas(id, meta.columnas, #t.colspecs)

  -- --- 4b. GRUPOS, COLUMNAS DE CADA CELDA, CORTES Y BLOQUES ---
  if agrupar then agrupar_filas(id, t) end
  mapear(id, t.head.rows, #t.colspecs, 'el encabezado')
  local cruza = mapear(id, t.bodies[1].body, #t.colspecs, 'el cuerpo')
  local nfilas = #t.bodies[1].body
  local cortes = leer_filas_lista(id, 'cortes', meta.cortes, nfilas, cruza)
  local bloques = leer_filas_lista(id, 'bloques', meta.bloques, nfilas, cruza)
  -- EN UN CORTE EL TRAMO TERMINA: EL FILETE DOBLE NO TENDRÍA DÓNDE IR
  for _, k in ipairs(bloques) do
    for _, c in ipairs(cortes) do
      if k == c then fallar(id, 'la fila ' .. k .. ' está en cortes y en bloques.') end
    end
  end

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
  atributos = { cuerpo = cuerpo, separacion = separacion, columnas = ficha_cols,
                rotar = rotar and 'si' or 'no', ancho = ancho,
                cortes = table.concat(cortes, ' '), bloques = table.concat(bloques, ' ') }
  return pandoc.Div(hijos, pandoc.Attr(id, { 'cuadro' }, atributos))
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Trae los cuadros del documento; frena el viejo ::: {.table}
--             y la tabla escrita en el .md
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con los cuadros
-- ============================================
function Pandoc(doc)
  local raiz

  -- --- 1. LA RAÍZ DEL PROYECTO, PARA ENCONTRAR cuadros/ ---
  if doc.meta['gb-proyecto'] then
    raiz = pandoc.utils.stringify(doc.meta['gb-proyecto']):gsub('/$', '')
  end

  -- --- 2. EL VIEJO ::: {.table} FRENA ---
  -- ANTES QUE LA TABLA SUELTA: LA TABLA DE ADENTRO DARÍA EL OTRO MENSAJE
  doc:walk({ Div = function(el)
    if el.classes:includes('table') then
      error('\n[cuadro] ::: {.table} se retiró: el cuadro va en su archivo, ' ..
        'cuadros/tbl-nombre.md, y en el texto ::: {.cuadro #tbl-nombre} (SC-66).\n', 0)
    end
  end })

  -- --- 3. UNA TABLA ESCRITA EN EL .md FRENA ---
  -- RIGIDEZ ESTRUCTURAL (decisión de Alberto): TODA TABLA VA EN SU ARCHIVO.
  -- SE MIRA ANTES DE TRAER LOS CUADROS, QUE SÍ SON TABLAS
  doc:walk({ Table = function(t)
    -- EL ENCABEZADO, PARA QUE EL EDITOR ENCUENTRE LA TABLA EN EL .md
    local partes = {}
    for _, f in ipairs(t.head.rows) do
      for _, c in ipairs(f.cells) do partes[#partes + 1] = pandoc.utils.stringify(c.contents) end
    end
    local muestra = table.concat(partes, ' | '):gsub('%s+', ' ')
    if utf8.len(muestra) and utf8.len(muestra) > 60 then
      muestra = muestra:sub(1, utf8.offset(muestra, 61) - 1) .. '…'
    end
    error('\n[cuadro] hay una tabla escrita en el texto (encabezado: «' .. muestra ..
      '»). Toda tabla va en su archivo, cuadros/tbl-nombre.md, y en el texto ' ..
      '::: {.cuadro #tbl-nombre} (SC-66).\n', 0)
  end })

  -- --- 4. CADA CUADRO ---
  return doc:walk({ Div = function(el)
    if not el.classes:includes('cuadro') then return nil end
    if not raiz then
      error('\n[cuadro] falta -M gb-proyecto: la cadena no pasa la raíz del proyecto.\n', 0)
    end
    return leer_cuadro(el, raiz)
  end })
end
