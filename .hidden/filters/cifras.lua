-- ============================================================
-- FILTRO      : cifras.lua
-- PROPÓSITO   : TRADUCE LAS CIFRAS Y CANTIDADES DEL .md (\num, \SI,
--               \SIrange; SC-64, SC-65) A SU FORMA EN EL CANÓNICO: EL
--               TEXTO QUE SE VE Y UNA FICHA SIN LaTeX PARA QUE EL PDF
--               VUELVA A ESCRIBIR LA ORDEN Y LA COMPONGA siunitx.
--               SIN ESTE FILTRO, PANDOC LAS LEE COMO LaTeX CRUDO Y LOS
--               ESCRITORES DE XML LAS DESCARTAN (GV-116).
-- ENTRADA     : \num{1500}   \SI{2.5}{\hour}   \SI{48}{\kilo\metre\per\hour}
--               \SIrange{50}{51}{\degree}
-- SALIDA      : JATS     <named-content content-type="cantidad"
--                          specific-use="SI 2.5 hour">2.5 h</named-content>
--               DOCBOOK  <phrase role="cantidad" remap="SI 2.5 hour">2.5 h</phrase>
--               ODT      EL TEXTO QUE SE VE
--               EL TEXTO QUE SE VE SIGUE LA CONFIGURACIÓN DE siunitx DE
--               SC-64: PUNTO DECIMAL, GRUPOS DE A TRES DESDE CINCO DÍGITOS,
--               «× 10ⁿ», SIGNO MENOS, LA UNIDAD SEPARADA (SALVO EL GRADO) Y
--               LA BARRA PARA \per. EL ESPACIO ES U+202F: NO CORTA LA LÍNEA.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN LAS TRES CADENAS, DESPUÉS DE corte-titulo.lua Y ANTES DE
--               LOS FILTROS QUE SERIALIZAN (cite-to-biblioref-db.lua EN
--               LIBRO, cite-to-xref.lua EN REVISTA).
-- IDIOMA      : LA PALABRA DEL RANGO («a», «to») SALE DEL IDIOMA DE LA
--               PIEZA: -M gb-idioma (REVISTA) O -M gb-idioma-pieza (LIBRO).
-- REGLA       : DICCIONARIO CERRADO. UNA ORDEN, UNA CIFRA O UNA UNIDAD QUE NO
--               ESTÁ EN ÉL FRENA LA CONVERSIÓN CON UN MENSAJE.
-- ============================================================

-- ESPACIO FINO QUE NO CORTA LA LÍNEA (U+202F), EN LUGAR DEL DE siunitx
local FINO = '\u{202F}'

-- SIGNO MENOS (U+2212) Y SIGNO POR (U+00D7), COMO LOS COMPONE siunitx
local MENOS = '\u{2212}'
local POR = '\u{00D7}'

-- DÍGITOS VOLADOS PARA EL EXPONENTE DE «× 10ⁿ»
local VOLADOS = {
  ['0'] = '⁰', ['1'] = '¹', ['2'] = '²', ['3'] = '³', ['4'] = '⁴',
  ['5'] = '⁵', ['6'] = '⁶', ['7'] = '⁷', ['8'] = '⁸', ['9'] = '⁹',
  ['-'] = '⁻',
}

-- UNIDADES DEL DICCIONARIO: SÍMBOLO, SI ADMITE EL PREFIJO \kilo, SI ADMITE
-- \square Y \cubic, Y SI VA SOLA (SIN PREFIJO, POTENCIA NI \per)
local UNIDADES = {
  hour    = { simbolo = 'h' },
  metre   = { simbolo = 'm', prefijo = true, potencia = true },
  gram    = { simbolo = 'g', prefijo = true },
  tonne   = { simbolo = 't' },
  euro    = { simbolo = '€' },
  degree  = { simbolo = '°', sola = true, pegada = true },
  percent = { simbolo = '%', sola = true },
}

-- PREFIJOS Y POTENCIAS
local PREFIJOS = { kilo = 'k' }
local POTENCIAS = { square = '²', cubic = '³' }

-- PALABRA DEL RANGO POR IDIOMA: LA MISMA QUE siunitx TOMA DE translations.
-- LA TABLA COMPLETA DE siunitx.sty 3.3.10, CLAVE «to (numerical range)»;
-- Brazilian Y Portuguese DICEN LO MISMO. UN IDIOMA FUERA DE ELLA FRENA:
-- NO HAY PALABRA VERIFICADA QUE PONER EN EL HTML
local RANGO = {
  ca = 'a', de = 'bis', en = 'to', es = 'a', fr = 'à',
  it = 'a', pl = 'do', pt = 'a', sl = 'do',
}

-- PATRÓN DE UNA CIFRA DE ENTRADA (SC-64): SIGNO, DÍGITOS, DECIMALES, EXPONENTE
local PATRON_CIFRA = '^(%-?)(%d+)%.?(%d*)([eE]?)(%-?%d*)$'

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  Se admiten \\num{cifra}, \\SI{cifra}{unidad} y \\SIrange{cifra}{cifra}{unidad}.' ..
  '\n  La cifra va con punto decimal y sin separador de miles: 1500, 2.5, 1.2e6.' ..
  '\n  Unidades: \\hour, \\metre, \\gram, \\tonne, \\euro, \\degree, \\percent;' ..
  '\n  \\kilo antes de \\metre o \\gram; \\square o \\cubic antes de \\metre;' ..
  '\n  un solo \\per entre dos unidades: \\kilo\\metre\\per\\hour.'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: orden As String — la orden escrita; motivo As String
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(orden, motivo)
  error('\n[cifras] «' .. orden .. '»: ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : agrupar
-- Propósito : Agrupa dígitos de a tres con el espacio fino, si son cinco o más
-- Parámetros: s As String — dígitos; desde_derecha As Boolean — true para la
--             parte entera, false para los decimales
-- Retorna   : String
-- ============================================
local function agrupar(s, desde_derecha)
  local grupos = {}

  -- --- 1. group-minimum-digits=5 (SC-64): CUATRO DÍGITOS NO SE AGRUPAN ---
  if #s < 5 then return s end

  -- --- 2. DE A TRES, DESDE EL SEPARADOR DECIMAL HACIA AFUERA ---
  if desde_derecha then
    local resto = #s % 3
    if resto > 0 then table.insert(grupos, s:sub(1, resto)) end
    for i = resto + 1, #s, 3 do table.insert(grupos, s:sub(i, i + 2)) end
  else
    for i = 1, #s, 3 do table.insert(grupos, s:sub(i, i + 2)) end
  end
  return table.concat(grupos, FINO)
end

-- ============================================
-- Función   : formatear_cifra
-- Propósito : La cifra de entrada con el formato de salida de SC-64
-- Parámetros: orden As String — para el mensaje; s As String — la cifra
-- Retorna   : String — p. ej. «1 234.5», «−3», «1.2 × 10⁶»
-- ============================================
local function formatear_cifra(orden, s)
  local signo, entera, decimales, e, exponente, texto

  -- --- 1. LA FORMA DE ENTRADA ---
  signo, entera, decimales, e, exponente = s:match(PATRON_CIFRA)
  if not signo then
    fallar(orden, 'la cifra «' .. s .. '» no tiene la forma de entrada.')
  end
  -- UN PUNTO SIN DECIMALES (12.) O UNA e SIN EXPONENTE (1e) NO SON CIFRAS
  if s:find('%.', 1) and decimales == '' then
    fallar(orden, 'la cifra «' .. s .. '» termina en punto.')
  end
  if (e ~= '') ~= (exponente ~= '' and exponente ~= '-') then
    fallar(orden, 'la cifra «' .. s .. '» tiene un exponente incompleto.')
  end

  -- --- 2. SIGNO, PARTE ENTERA Y DECIMALES ---
  texto = (signo == '-' and MENOS or '') .. agrupar(entera, true)
  if decimales ~= '' then texto = texto .. '.' .. agrupar(decimales, false) end

  -- --- 3. EXPONENTE: «× 10ⁿ» ---
  if e ~= '' then
    local volado = exponente:gsub('.', VOLADOS)
    texto = texto .. FINO .. POR .. FINO .. '10' .. volado
  end
  return texto
end

-- ============================================
-- Función   : formatear_unidad
-- Propósito : La unidad escrita con órdenes del diccionario, como texto y como
--             fichas sin barras
-- Parámetros: orden As String — para el mensaje; s As String — p. ej.
--             «\kilo\metre\per\hour»
-- Retorna   : String, String, Boolean — el texto («km/h»), las fichas
--             («kilo metre per hour») y si va pegada a la cifra (el grado)
-- ============================================
local function formatear_unidad(orden, s)
  local nombres, fichas, factores, actual, per, resto, texto

  -- --- 1. SOLO ÓRDENES \nombre, PEGADAS ---
  nombres = {}
  resto = s:gsub('\\(%a+)', function(n) table.insert(nombres, n); return '' end)
  if resto ~= '' or #nombres == 0 then
    fallar(orden, 'la unidad «' .. s .. '» no está escrita con órdenes del diccionario.')
  end

  -- --- 2. FACTORES: [\square|\cubic] [\kilo] unidad, CON UN \per COMO MÁXIMO ---
  factores = { {}, {} }
  per = 1
  actual = {}
  for _, n in ipairs(nombres) do
    if n == 'per' then
      if per == 2 or #factores[1] == 0 or next(actual) then
        fallar(orden, '\\per va una sola vez, entre dos unidades.')
      end
      per = 2
    elseif POTENCIAS[n] then
      if actual.potencia or actual.prefijo then
        fallar(orden, '\\' .. n .. ' va antes del prefijo y de la unidad.')
      end
      actual.potencia = n
    elseif PREFIJOS[n] then
      if actual.prefijo then fallar(orden, 'dos prefijos seguidos.') end
      actual.prefijo = n
    elseif UNIDADES[n] then
      local u = UNIDADES[n]
      if actual.prefijo and not u.prefijo then
        fallar(orden, '\\' .. actual.prefijo .. ' no va con \\' .. n .. '.')
      end
      if actual.potencia and not u.potencia then
        fallar(orden, '\\' .. actual.potencia .. ' no va con \\' .. n .. '.')
      end
      actual.unidad = n
      table.insert(factores[per], actual)
      actual = {}
    else
      fallar(orden, '\\' .. n .. ' no está en el diccionario.')
    end
  end
  if next(actual) then fallar(orden, 'falta la unidad después de un prefijo o una potencia.') end
  if per == 2 and #factores[2] ~= 1 then
    fallar(orden, 'después de \\per va una sola unidad.')
  end

  -- --- 3. EL GRADO, EL PORCENTAJE: SOLOS ---
  for _, lado in ipairs(factores) do
    for _, f in ipairs(lado) do
      if UNIDADES[f.unidad].sola and (#nombres > 1) then
        fallar(orden, '\\' .. f.unidad .. ' va sola, sin prefijo, potencia ni \\per.')
      end
    end
  end

  -- --- 4. TEXTO Y FICHAS ---
  -- per-mode=symbol: «km/h»; ENTRE UNIDADES DEL NUMERADOR, EL ESPACIO FINO
  local function factor_texto(f)
    return (f.prefijo and PREFIJOS[f.prefijo] or '') .. UNIDADES[f.unidad].simbolo ..
           (f.potencia and POTENCIAS[f.potencia] or '')
  end
  local numerador = {}
  for _, f in ipairs(factores[1]) do table.insert(numerador, factor_texto(f)) end
  texto = table.concat(numerador, FINO)
  if per == 2 then texto = texto .. '/' .. factor_texto(factores[2][1]) end
  fichas = table.concat(nombres, ' ')
  return texto, fichas, (#nombres == 1 and UNIDADES[nombres[1]].pegada) or false
end

-- ============================================
-- Función   : con_unidad
-- Propósito : Une cifra y unidad: separadas con el espacio fino, o pegadas
-- Parámetros: cifra As String; unidad As String; pegada As Boolean
-- Retorna   : String
-- ============================================
local function con_unidad(cifra, unidad, pegada)
  if pegada then return cifra .. unidad end
  return cifra .. FINO .. unidad
end

-- ============================================
-- Función   : leer_orden
-- Propósito : Reconoce \num{…}, \SI{…}{…} o \SIrange{…}{…}{…}
-- Parámetros: s As String — el texto de un RawInline tex
-- Retorna   : String, table — el nombre de la orden y sus argumentos; nil si
--             no es una de las tres
-- ============================================
local function leer_orden(s)
  local nombre, resto, args

  -- --- 1. EL NOMBRE ---
  nombre, resto = s:match('^\\(%a+)(.*)$')
  if nombre ~= 'num' and nombre ~= 'SI' and nombre ~= 'SIrange' then return nil end

  -- --- 2. LOS ARGUMENTOS ENTRE LLAVES, PEGADOS, SIN LLAVES ADENTRO ---
  args = {}
  while resto ~= '' do
    local arg, despues = resto:match('^{([^{}]*)}(.*)$')
    if not arg then return nombre, nil end
    table.insert(args, arg)
    resto = despues
  end
  return nombre, args
end

-- ============================================
-- Función   : escapar
-- Propósito : Escapa los caracteres especiales de XML
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function escapar(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

-- ============================================
-- Función   : traducir
-- Propósito : Una orden de cifra en el formato de salida
-- Parámetros: texto As String — la orden escrita; idioma As String
-- Retorna   : Inline — la cantidad; nil si no es una orden de cifra
-- ============================================
local function traducir(texto, idioma)
  local nombre, args, ver, ficha, u, fichas_u, pegada, palabra

  -- --- 1. ¿ES UNA DE LAS TRES? ---
  nombre, args = leer_orden(texto)
  if not nombre then return nil end
  if not args then fallar(texto, 'los argumentos van entre llaves, pegados.') end

  -- --- 2. CADA ORDEN CON SUS ARGUMENTOS ---
  if nombre == 'num' then
    if #args ~= 1 then fallar(texto, '\\num lleva un argumento.') end
    ver = formatear_cifra(texto, args[1])
    ficha = 'num ' .. args[1]
  elseif nombre == 'SI' then
    if #args ~= 2 then fallar(texto, '\\SI lleva dos argumentos.') end
    u, fichas_u, pegada = formatear_unidad(texto, args[2])
    ver = con_unidad(formatear_cifra(texto, args[1]), u, pegada)
    ficha = 'SI ' .. args[1] .. ' ' .. fichas_u
  else
    if #args ~= 3 then fallar(texto, '\\SIrange lleva tres argumentos.') end
    palabra = RANGO[idioma]
    if not palabra then
      fallar(texto, 'no hay palabra de rango para el idioma «' .. idioma .. '».')
    end
    -- range-units=repeat (VALOR POR OMISIÓN DE siunitx): «50° a 51°»
    u, fichas_u, pegada = formatear_unidad(texto, args[3])
    ver = con_unidad(formatear_cifra(texto, args[1]), u, pegada) .. ' ' .. palabra ..
          ' ' .. con_unidad(formatear_cifra(texto, args[2]), u, pegada)
    ficha = 'SIrange ' .. args[1] .. ' ' .. args[2] .. ' ' .. fichas_u
  end

  -- --- 3. SALIDA SEGÚN EL FORMATO ---
  if FORMAT == 'jats' then
    return pandoc.RawInline('jats', '<named-content content-type="cantidad" specific-use="' ..
      escapar(ficha) .. '">' .. escapar(ver) .. '</named-content>')
  end
  if FORMAT == 'docbook5' then
    return pandoc.RawInline('docbook', '<phrase role="cantidad" remap="' ..
      escapar(ficha) .. '">' .. escapar(ver) .. '</phrase>')
  end
  return pandoc.Str(ver)
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Traduce las cifras de todo el documento
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con las cifras traducidas
-- ============================================
function Pandoc(doc)
  local idioma

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[cifras] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end

  -- --- 2. EL IDIOMA DE LA PIEZA: SOLO LAS DOS PRIMERAS LETRAS (es-AR → es) ---
  idioma = 'es'
  if doc.meta['gb-idioma-pieza'] then
    idioma = pandoc.utils.stringify(doc.meta['gb-idioma-pieza'])
  elseif doc.meta['gb-idioma'] then
    idioma = pandoc.utils.stringify(doc.meta['gb-idioma'])
  end
  idioma = idioma:lower():sub(1, 2)

  -- --- 3. CADA RawInline DE LaTeX: SOLO LAS TRES ÓRDENES; EL RESTO NO ES DE ACÁ ---
  -- UNA ORDEN CON MENOS ARGUMENTOS DE LOS QUE PIDE (\SI{3}) PANDOC NO LA LEE
  -- COMO LaTeX: QUEDA COMO TEXTO (MEDIDO, Str "\\SI{3}."), Y SALDRÍA LITERAL.
  -- POR ESO TAMBIÉN SE MIRAN LOS Str
  return doc:walk({
    RawInline = function(el)
      if el.format ~= 'tex' and el.format ~= 'latex' then return nil end
      return traducir(el.text, idioma)
    end,
    Str = function(el)
      if el.text:find('\\num', 1, true) or el.text:find('\\SI', 1, true) then
        fallar(el.text, 'la orden está incompleta: le faltan argumentos o llaves.')
      end
      return nil
    end,
  })
end
