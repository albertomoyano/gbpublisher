-- ============================================================
-- SCRIPT      : colorear_codigo.lua
-- PROPÓSITO   : SEGUNDO PASO DEL COLOREADO DE CÓDIGO (SC-42). COLOREA
--               CADA BLOQUE QUE EXTRAJO extraer-codigo.xsl CON EL
--               RESALTADOR DE PANDOC (skylighting) Y ESCRIBE SUS LÍNEAS,
--               NUMERADAS, LISTAS PARA QUE LA HOJA DE SALIDA LAS META EN
--               EL BLOQUE. EL CANÓNICO NO SE TOCA: EL COLOR ES DE LA
--               SALIDA, NO DE LA FUENTE.
-- USO         : pandoc lua colorear_codigo.lua <carpeta> <html|latex>
-- ENTRADA     : <carpeta>/indice.txt (N, TAB, LENGUAJE) Y
--               <carpeta>/codigo-N.txt
-- SALIDA      : <carpeta>/codigo-N.html — UN <span class="gb-l"> POR
--                 LÍNEA, CON data-n EN LAS NUMERADAS; LOS TOKENS SON LOS
--                 <span class="kw|st|co|…"> DE skylighting. ES XML BIEN
--                 FORMADO: LA HOJA LO LEE CON parse-xml-fragment.
--               <carpeta>/codigo-N.tex — UNA LÍNEA DE Verbatim POR LÍNEA,
--                 QUE EMPIEZA CON \gbnl{N} (NUMERADA) O \gbnc
--                 (CONTINUACIÓN) Y TERMINA CON \gbret SI TIENE CORTE.
--                 LOS TOKENS SON LOS \KeywordTok{…} DE skylighting; LAS
--                 MACROS LAS DEFINE EL PREÁMBULO.
-- REGLA DEL ↩ : UNA LÍNEA QUE TERMINA EN ↩ (U+21A9), CON BLANCOS DESPUÉS
--               O SIN ELLOS, ES UN CORTE MANUAL: LA SIGUIENTE ES SU
--               CONTINUACIÓN Y NO LLEVA NÚMERO. EL ↩ SE QUITA ANTES DE
--               COLOREAR Y SE DIBUJA DESPUÉS, EN EL GRIS DE LOS NÚMEROS.
--               GEMELA DE gbc:numeros EN codigo-comun.xsl: UN CAMBIO VA
--               EN LOS DOS.
-- ERRORES     : FRENA CON error() Y UN MENSAJE: UN BLOQUE QUE NO SE
--               PUEDE COLOREAR NO SE DEGRADA EN SILENCIO.
-- ============================================================

local RETORNO = '\u{21A9}'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene el script con un mensaje legible
-- Parámetros: motivo As String
-- Retorna   : no retorna
-- ============================================
local function fallar(motivo)
  error('\n[colorear_codigo] ' .. motivo .. '\n', 0)
end

-- ============================================
-- Función   : leer
-- Propósito : Lee un archivo entero
-- Parámetros: ruta As String
-- Retorna   : String — el contenido
-- ============================================
local function leer(ruta)
  local f = io.open(ruta, 'rb')
  if not f then fallar('no se pudo leer ' .. ruta) end
  local s = f:read('a')
  f:close()
  return s
end

-- ============================================
-- Función   : escribir
-- Propósito : Escribe un archivo entero
-- Parámetros: ruta As String; texto As String
-- Retorna   : nada
-- ============================================
local function escribir(ruta, texto)
  local f = io.open(ruta, 'wb')
  if not f then fallar('no se pudo escribir ' .. ruta) end
  f:write(texto)
  f:close()
end

-- ============================================
-- Función   : partir_lineas
-- Propósito : Parte un texto en líneas, conservando las vacías
-- Parámetros: texto As String
-- Retorna   : table — las líneas, sin el salto
-- ============================================
local function partir_lineas(texto)
  local lineas = {}
  for l in (texto .. '\n'):gmatch('(.-)\n') do lineas[#lineas + 1] = l end
  return lineas
end

-- ============================================
-- Función   : analizar
-- Propósito : Quita el ↩ de cada línea y calcula su número
-- Parámetros: lineas As table
-- Retorna   : table, table, table — las líneas sin ↩; si cada una tiene
--             corte; su número (0 en una continuación)
-- ============================================
local function analizar(lineas)
  local limpias, cortes, numeros = {}, {}, {}
  local n = 0
  for i, l in ipairs(lineas) do
    local s, fin = l:find(RETORNO .. '%s*$')
    cortes[i] = (s ~= nil)
    limpias[i] = s and l:sub(1, s - 1) or l
    -- LA LÍNEA QUE SIGUE A UN CORTE ES SU CONTINUACIÓN: NO SE NUMERA
    if i > 1 and cortes[i - 1] then
      numeros[i] = 0
    else
      n = n + 1
      numeros[i] = n
    end
  end
  return limpias, cortes, numeros
end

-- ============================================
-- Función   : escapar_html
-- Propósito : Escapa un texto para el fragmento XML
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function escapar_html(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

-- ============================================
-- Función   : escapar_verbatim
-- Propósito : Escapa un texto para un Verbatim con commandchars=\\\{\}:
--             SOLO LA BARRA Y LAS LLAVES SON ESPECIALES ADENTRO
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function escapar_verbatim(s)
  return (s:gsub('[\\{}]', { ['\\'] = '\\textbackslash{}', ['{'] = '\\{', ['}'] = '\\}' }))
end

-- ============================================
-- Función   : tokens_html
-- Propósito : Colorea un texto y devuelve el contenido de cada línea
-- Parámetros: texto As String; lenguaje As String ('' = sin color)
-- Retorna   : table — una cadena HTML por línea
-- ============================================
local function tokens_html(texto, lenguaje, cantidad)
  local salida = {}
  if lenguaje == '' then
    for i, l in ipairs(partir_lineas(texto)) do salida[i] = escapar_html(l) end
    return salida
  end
  local html = pandoc.write(pandoc.Pandoc({ pandoc.CodeBlock(texto, { class = lenguaje }) }), 'html')
  -- EL CUERPO ESTÁ ENTRE <code …> Y </code></pre>; UNA LÍNEA POR SALTO
  local cuerpo = html:match('<code[^>]*>(.*)</code></pre>')
  if not cuerpo or not html:find('class="sourceCode', 1, true) then
    fallar('Pandoc no coloreó un bloque en ' .. lenguaje .. ': el lenguaje no está en su resaltador')
  end
  for _, l in ipairs(partir_lineas(cuerpo)) do
    -- CADA LÍNEA ES <span id="cbX-Y"><a …></a>TOKENS</span>
    local t = l:gsub('^<span id="cb%d+%-%d+"><a [^>]*></a>', ''):gsub('</span>$', '')
    salida[#salida + 1] = t
  end
  if #salida ~= cantidad then
    fallar('el bloque coloreado tiene ' .. #salida .. ' líneas y el original ' .. cantidad)
  end
  return salida
end

-- ============================================
-- Función   : tokens_latex
-- Propósito : Colorea un texto y devuelve el contenido de cada línea
-- Parámetros: texto As String; lenguaje As String ('' = sin color)
-- Retorna   : table — una cadena LaTeX por línea
-- ============================================
local function tokens_latex(texto, lenguaje, cantidad)
  local salida = {}
  if lenguaje == '' then
    -- SIN COLOR: EL MISMO MACRO QUE skylighting USA PARA EL TEXTO COMÚN
    for i, l in ipairs(partir_lineas(texto)) do
      salida[i] = (l == '') and '' or ('\\NormalTok{' .. escapar_verbatim(l) .. '}')
    end
    return salida
  end
  local tex = pandoc.write(pandoc.Pandoc({ pandoc.CodeBlock(texto, { class = lenguaje }) }), 'latex')
  local cuerpo = tex:match('\\begin{Highlighting}%[%]\n(.*)\n\\end{Highlighting}')
  if not cuerpo then
    fallar('Pandoc no coloreó un bloque en ' .. lenguaje .. ': el lenguaje no está en su resaltador')
  end
  salida = partir_lineas(cuerpo)
  if #salida ~= cantidad then
    fallar('el bloque coloreado tiene ' .. #salida .. ' líneas y el original ' .. cantidad)
  end
  return salida
end

-- ============================================
-- Función   : armar
-- Propósito : Arma el archivo de un bloque en el formato pedido
-- Parámetros: texto As String; lenguaje As String; formato As String
-- Retorna   : String — el contenido del archivo
-- ============================================
local function armar(texto, lenguaje, formato)
  local limpias, cortes, numeros = analizar(partir_lineas(texto))
  local fuente = table.concat(limpias, '\n')
  local partes = {}

  if formato == 'html' then
    local t = tokens_html(fuente, lenguaje, #limpias)
    for i = 1, #limpias do
      -- EL NÚMERO Y EL ↩ VAN COMO ATRIBUTO Y CLASE: LOS DIBUJA EL CSS CON
      -- ::before Y ::after, Y ASÍ NO SE COPIAN CON EL CÓDIGO
      local abre = (numeros[i] > 0)
        and ('<span class="gb-l" data-n="' .. numeros[i] .. '">')
        or '<span class="gb-l gb-cont">'
      local ret = cortes[i] and '<span class="gb-ret"></span>' or ''
      partes[i] = abre .. t[i] .. ret .. '</span>'
    end
    -- UN ELEMENTO RAÍZ PARA QUE parse-xml-fragment LO LEA ENTERO
    return '<lineas>' .. table.concat(partes, '\n') .. '</lineas>'
  end

  local t = tokens_latex(fuente, lenguaje, #limpias)
  for i = 1, #limpias do
    local num = (numeros[i] > 0) and ('\\gbnl{' .. numeros[i] .. '}') or '\\gbnc'
    partes[i] = num .. t[i] .. (cortes[i] and '\\gbret' or '')
  end
  return table.concat(partes, '\n') .. '\n'
end

-- ============================================
-- PROGRAMA
-- ============================================
local carpeta, formato = arg[1], arg[2]
if not carpeta or (formato ~= 'html' and formato ~= 'latex') then
  fallar('uso: pandoc lua colorear_codigo.lua <carpeta> <html|latex>')
end

local extension = (formato == 'html') and '.html' or '.tex'
local cantidad = 0
for linea in leer(carpeta .. '/indice.txt'):gmatch('[^\n]+') do
  local n, lenguaje = linea:match('^(%d+)\t(.*)$')
  if not n then fallar('línea del índice mal formada: ' .. linea) end
  local texto = leer(carpeta .. '/codigo-' .. n .. '.txt')
  escribir(carpeta .. '/codigo-' .. n .. extension, armar(texto, lenguaje, formato))
  cantidad = cantidad + 1
end
io.stdout:write(cantidad .. '\n')
