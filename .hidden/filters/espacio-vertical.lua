-- ============================================================
-- FILTRO      : espacio-vertical.lua
-- PROPÓSITO   : TRADUCE EL SHORTCODE espaciov, INSTRUCCIÓN DE
--               COMPOSICIÓN DEL PDF (SC-38, SC-39), A UNA FICHA EN
--               EL CANÓNICO. NO TOCA NINGUNA OTRA SALIDA.
-- ENTRADA     : ::: espaciov
--
--               \bigskip
--
--               [/espaciov]: # ()
--               :::
-- SALIDA      : JATS (REVISTA)  <?gb-espacio bigskip?>
--               DOCBOOK (LIBRO) <?gb-espacio bigskip?>
--               ODT             NADA: EL BLOQUE SE QUITA
--               LA FICHA LA TRADUCEN SOLO docbook-to-latex.xsl Y
--               jats-to-latex.xsl. LAS HOJAS DE HTML Y EPUB NO
--               ESCRIBEN NADA PARA UNA INSTRUCCIÓN DE PROCESAMIENTO.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : REVISTA, DESPUÉS DE unwrap-structural-divs.lua (LAS
--               SECCIONES ESTRUCTURALES YA NO SON Div) Y ANTES DE
--               cite-to-xref.lua. LIBRO, ANTES DE
--               fenced-divs-to-elements-db.lua. ODT, EN CUALQUIER LUGAR.
-- REGLA       : DICCIONARIO CERRADO. UN VALOR QUE NO ESTÁ EN ÉL, UN
--               BLOQUE VACÍO O CON MÁS DE UNA LÍNEA, O UN BLOQUE
--               DENTRO DE OTRO BLOQUE, FRENA LA CONVERSIÓN CON UN
--               MENSAJE: NUNCA SE DEGRADA EN SILENCIO.
-- ============================================================

-- CLASE DEL SHORTCODE EN EL CATÁLOGO DE gbShortcodes (RF-11)
local CLASE = 'espaciov'

-- NOMBRE DE LA INSTRUCCIÓN DE PROCESAMIENTO: PREFIJO gb- (SC-38)
local OBJETIVO = 'gb-espacio'

-- COMANDOS SIN ARGUMENTO: COMANDO DEL .md -> FICHA. EL VALOR TRUE
-- MARCA LOS QUE SOLO VALEN EN LIBROS
local SIN_ARGUMENTO = {
  ['\\smallskip']       = { ficha = 'smallskip' },
  ['\\medskip']         = { ficha = 'medskip' },
  ['\\bigskip']         = { ficha = 'bigskip' },
  ['\\newpage']         = { ficha = 'newpage' },
  ['\\clearpage']       = { ficha = 'clearpage' },
  ['\\cleardoublepage'] = { ficha = 'cleardoublepage', solo_libro = true },
}

-- COMANDOS CON UNA LONGITUD COMO ARGUMENTO: NOMBRE -> FICHA
local CON_LONGITUD = {
  ['vspace']          = 'vspace',
  ['vspace*']         = 'vspace*',
  ['enlargethispage'] = 'enlargethispage',
}

-- UNIDADES ADMITIDAS DESPUÉS DEL NÚMERO
local UNIDADES = { pt = true, mm = true, cm = true, em = true, ex = true }

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  Valores admitidos: \\smallskip, \\medskip, \\bigskip, \\newpage,' ..
  '\n  \\clearpage, \\cleardoublepage (solo libros), \\vspace{L},' ..
  '\n  \\vspace*{L} y \\enlargethispage{L}, con L un número y una unidad' ..
  '\n  (pt, mm, cm, em, ex), o N\\baselineskip. El decimal va con punto.'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo)
  error('\n[espaciov] ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : es_espaciov
-- Propósito : Dice si un bloque es el shortcode
-- Parámetros: el As Block
-- Retorna   : boolean
-- ============================================
local function es_espaciov(el)
  return el.t == 'Div' and el.classes:includes(CLASE)
end

-- ============================================
-- Función   : longitud_a_ficha
-- Propósito : Valida una longitud de LaTeX y la escribe sin barras
-- Parámetros: s As String — lo que va entre las llaves, p. ej. «1.5cm»
-- Retorna   : String — la longitud para la ficha, p. ej. «1.5cm» o
--             «2baselineskip»; nil si no es válida
-- ============================================
local function longitud_a_ficha(s)
  local signo, numero, unidad

  -- --- 1. N\baselineskip: EL NÚMERO ES OPCIONAL Y VALE 1 ---
  signo, numero = s:match('^(%-?)([%d%.]*)\\baselineskip$')
  if signo then
    if numero == '' then numero = '1' end
    if not numero:match('^%d+%.?%d*$') and not numero:match('^%.%d+$') then return nil end
    return signo .. numero .. 'baselineskip'
  end

  -- --- 2. NÚMERO Y UNIDAD ---
  signo, numero, unidad = s:match('^(%-?)([%d%.]+)(%a%a)$')
  if not signo then return nil end
  if not numero:match('^%d+%.?%d*$') and not numero:match('^%.%d+$') then return nil end
  if not UNIDADES[unidad] then return nil end
  return signo .. numero .. unidad
end

-- ============================================
-- Función   : comando_a_ficha
-- Propósito : Traduce el comando escrito en el bloque a su ficha
-- Parámetros: comando As String — el contenido del bloque, sin blancos
--             en los bordes; es_libro As Boolean
-- Retorna   : String — la ficha; frena la conversión si no es válido
-- ============================================
local function comando_a_ficha(comando, es_libro)
  local entrada, nombre, argumento, ficha_longitud

  -- --- 1. COMANDOS SIN ARGUMENTO ---
  entrada = SIN_ARGUMENTO[comando]
  if entrada then
    if entrada.solo_libro and not es_libro then
      fallar(comando .. ' solo vale en libros.')
    end
    return entrada.ficha
  end

  -- --- 2. COMANDOS CON LONGITUD: \nombre{L} O \nombre*{L} ---
  nombre, argumento = comando:match('^\\(%a+%*?){(.*)}$')
  if not nombre or not CON_LONGITUD[nombre] then
    fallar('Valor no admitido: ' .. comando)
  end
  ficha_longitud = longitud_a_ficha(argumento)
  if not ficha_longitud then
    fallar('Longitud no admitida en ' .. comando .. ': «' .. argumento .. '».')
  end
  return CON_LONGITUD[nombre] .. ' ' .. ficha_longitud
end

-- ============================================
-- Función   : traducir
-- Propósito : Convierte un bloque espaciov en la salida del formato
-- Parámetros: el As Div — el bloque; es_libro As Boolean
-- Retorna   : Block o table vacía (ODT)
-- ============================================
local function traducir(el, es_libro)
  local bloque, comando, ficha, formato

  -- --- 1. EXACTAMENTE UN BLOQUE ---
  -- EL ANCLA [/espaciov]: # () LA CONSUME PANDOC AL LEER (SC-33)
  if #el.content == 0 then
    fallar('El bloque está vacío: falta el comando entre la apertura y el ancla.')
  end
  if #el.content > 1 then
    fallar('El bloque lleva un solo comando, en una sola línea.')
  end

  -- --- 2. EL BLOQUE ES LaTeX CRUDO ---
  -- PANDOC LEE \bigskip O \vspace{1cm} SOLOS EN SU LÍNEA COMO RawBlock tex
  -- (MEDIDO CON PANDOC 3.1.3). SIN LA BARRA, O CON TEXTO ALREDEDOR, ES UN
  -- PÁRRAFO
  bloque = el.content[1]
  if bloque.t ~= 'RawBlock' or (bloque.format ~= 'tex' and bloque.format ~= 'latex') then
    fallar('El contenido tiene que ser un comando de LaTeX solo en su línea, ' ..
           'con la barra. Se leyó: «' .. pandoc.utils.stringify(el):sub(1, 60) .. '».')
  end
  comando = bloque.text:match('^%s*(.-)%s*$')

  -- --- 3. FICHA ---
  ficha = comando_a_ficha(comando, es_libro)

  -- --- 4. SALIDA SEGÚN EL FORMATO ---
  if FORMAT == 'odt' then return {} end
  formato = es_libro and 'docbook' or 'jats'
  return pandoc.RawBlock(formato, '<?' .. OBJETIVO .. ' ' .. ficha .. '?>')
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Traduce los espaciov del primer nivel y frena si queda alguno
--             dentro de otro bloque, una lista, una tabla o una nota
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con los bloques traducidos
-- ============================================
function Pandoc(doc)
  local es_libro, bloques, resultado

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[espaciov] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end
  es_libro = (FORMAT == 'docbook5')

  -- --- 2. PRIMER NIVEL: ENTRE PÁRRAFOS, QUE ES DONDE EL COMANDO SIRVE ---
  -- EN REVISTA LAS SECCIONES ESTRUCTURALES YA LLEGAN DESENVUELTAS; EN LIBRO
  -- LAS SECCIONES SON TÍTULOS, QUE PANDOC AGRUPA RECIÉN AL ESCRIBIR
  bloques = pandoc.Blocks({})
  for _, bloque in ipairs(doc.blocks) do
    if es_espaciov(bloque) then
      resultado = traducir(bloque, es_libro)
      if resultado.t then bloques:insert(resultado) end
    else
      bloques:insert(bloque)
    end
  end
  doc.blocks = bloques

  -- --- 3. LO QUE QUEDÓ ADENTRO DE OTRA COSA FRENA ---
  -- EN ODT NO SE CONTROLA: ESA CADENA NO DESENVUELVE LAS SECCIONES
  -- ESTRUCTURALES. LA REVISTA YA LO CONTROLA EN LA CADENA DEL XML
  if FORMAT == 'odt' then
    return doc:walk({ Div = function(el)
      if es_espaciov(el) then return {} end
    end })
  end
  doc:walk({ Div = function(el)
    if es_espaciov(el) then
      fallar('El bloque va solo, entre párrafos: no puede ir dentro de otro ' ..
             'bloque, una lista, una tabla o una nota.')
    end
  end })
  return doc
end
