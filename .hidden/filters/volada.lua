-- ============================================================
-- FILTRO      : volada.lua
-- PROPÓSITO   : TRADUCE LA LETRA VOLADA \sptext{…} DEL TEXTO (SC-62)
--               A SU FORMA EN EL CANÓNICO, LA MISMA QUE SC-58 FIJÓ
--               PARA LAS REFERENCIAS: EL PUNTO Y LA VOLADA EN
--               SUPERÍNDICE. SIN ESTE FILTRO, PANDOC LEE \sptext{o}
--               COMO LaTeX CRUDO Y LOS ESCRITORES DE XML LO DESCARTAN:
--               «El n\sptext{o} 3» SALÍA «El n 3» (GV-116).
-- ENTRADA     : n\sptext{o}   1\sptext{a}   3\sptext{er}   C\sptext{ía}
-- SALIDA      : JATS (REVISTA)  n.<sup specific-use="volada">o</sup>
--               DOCBOOK (LIBRO) n.<superscript role="volada">o</superscript>
--               ODT             n. Y LA VOLADA EN SUPERÍNDICE
--               EL PUNTO ES EL QUE PONE \sptext (babel-spanish,
--               \es@orddot): EL CANÓNICO DICE LO MISMO QUE EL PDF.
--               docbook-to-latex.xsl Y jats-to-latex.xsl LO VUELVEN A
--               \sptext{o} (SC-62).
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : ANTES DE TODO FILTRO QUE SERIALICE CON pandoc.write: LIBRO,
--               SEGUNDO, DESPUÉS DE guillemets Y ANTES DE cite-to-biblioref-db
--               (SERIALIZA LAS NOTAS); REVISTA, DESPUÉS DE alinear.lua Y ANTES
--               DE cite-to-xref.lua; ODT, DESPUÉS DE alinear.lua.
-- REGLA       : REGLA ABIERTA (DECISIÓN DE ALBERTO). ADENTRO, UNA O MÁS
--               MINÚSCULAS, CON O SIN TILDE. ANTES, PEGADA, UNA LETRA O
--               UNA CIFRA, NUNCA UN PUNTO. SOLO EN TEXTO EN ESPAÑOL
--               (\sptext ES DE babel-spanish). LO QUE NO CUMPLE FRENA LA
--               CONVERSIÓN CON UN MENSAJE: NUNCA SE DEGRADA EN SILENCIO.
--               LAS OTRAS ÓRDENES DE LaTeX EN LÍNEA NO SON DE ESTE FILTRO.
-- ============================================================

-- LA ORDEN QUE ESTE FILTRO TRADUCE: EXACTAMENTE \sptext{…}
local PATRON_ORDEN = '^\\sptext{(.*)}$'

-- MINÚSCULAS ADMITIDAS FUERA DE a-z (UTF-8): LAS DEL ESPAÑOL CON TILDE,
-- DIÉRESIS O VIRGULILLA
local MINUSCULAS_EXTRA = {
  ['á'] = true, ['é'] = true, ['í'] = true, ['ó'] = true, ['ú'] = true,
  ['ü'] = true, ['ñ'] = true,
}

-- LETRAS ADMITIDAS COMO BASE FUERA DE a-z Y A-Z: LAS MISMAS Y SUS MAYÚSCULAS
local LETRAS_EXTRA = {
  ['á'] = true, ['é'] = true, ['í'] = true, ['ó'] = true, ['ú'] = true,
  ['ü'] = true, ['ñ'] = true,
  ['Á'] = true, ['É'] = true, ['Í'] = true, ['Ó'] = true, ['Ú'] = true,
  ['Ü'] = true, ['Ñ'] = true,
}

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  Se escribe pegado a una letra o una cifra, sin punto: n\\sptext{o},' ..
  '\n  1\\sptext{a}, 3\\sptext{er}. El punto lo pone \\sptext. Adentro van' ..
  '\n  una o más minúsculas, con o sin tilde. Es del español: no va en un' ..
  '\n  texto en otro idioma.'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo)
  error('\n[sptext] ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : volada_de
-- Propósito : Dice si un elemento en línea es la orden \sptext{…}
-- Parámetros: el As Inline
-- Retorna   : String — lo que va entre las llaves; nil si no es la orden
-- ============================================
local function volada_de(el)

  -- --- 1. SOLO LaTeX CRUDO ---
  if el.t ~= 'RawInline' then return nil end
  if el.format ~= 'tex' and el.format ~= 'latex' then return nil end

  -- --- 2. EXACTAMENTE LA ORDEN ---
  return el.text:match(PATRON_ORDEN)
end

-- ============================================
-- Función   : es_volada_valida
-- Propósito : Dice si el contenido de la volada cumple la regla abierta
-- Parámetros: s As String — lo que va entre las llaves
-- Retorna   : boolean
-- ============================================
local function es_volada_valida(s)
  local cantidad = 0

  -- --- 1. CARÁCTER POR CARÁCTER (UTF-8): a-z O UNA MINÚSCULA DEL ESPAÑOL ---
  for _, codigo in utf8.codes(s) do
    local c = utf8.char(codigo)
    if not (c:match('^[a-z]$') or MINUSCULAS_EXTRA[c]) then return false end
    cantidad = cantidad + 1
  end

  -- --- 2. AL MENOS UNA ---
  return cantidad > 0
end

-- ============================================
-- Función   : ultimo_caracter
-- Propósito : El último carácter UTF-8 de una cadena
-- Parámetros: s As String
-- Retorna   : String — el carácter; '' si la cadena está vacía
-- ============================================
local function ultimo_caracter(s)
  local ultimo = ''
  for _, codigo in utf8.codes(s) do
    ultimo = utf8.char(codigo)
  end
  return ultimo
end

-- ============================================
-- Función   : controlar_base
-- Propósito : Frena si lo que precede a la volada no es una letra o una
--             cifra pegada
-- Parámetros: anterior As Inline — el elemento anterior (nil si no hay)
--             volada As String — para el mensaje
-- Retorna   : nada; frena la conversión si no cumple
-- ============================================
local function controlar_base(anterior, volada)
  local c

  -- --- 1. TIENE QUE HABER TEXTO PEGADO ---
  -- UN ESPACIO, UN COMIENZO DE PÁRRAFO O UNA MARCA (BASTARDILLA, NEGRITA)
  -- NO SON UNA BASE: LA HOJA LaTeX NO TENDRÍA DE DÓNDE SACAR EL PUNTO
  if not anterior or anterior.t ~= 'Str' then
    fallar('\\sptext{' .. volada .. '} no va pegado a una letra o una cifra.')
  end

  -- --- 2. EL ÚLTIMO CARÁCTER ---
  c = ultimo_caracter(anterior.text)
  if c == '.' then
    fallar('«' .. anterior.text .. '\\sptext{' .. volada .. '}» lleva un punto ' ..
           'antes: saldría con dos.')
  end
  if not (c:match('^[%w]$') or LETRAS_EXTRA[c]) then
    fallar('«' .. anterior.text .. '\\sptext{' .. volada .. '}»: antes de la ' ..
           'volada va una letra o una cifra.')
  end
end

-- ============================================
-- Función   : traducir
-- Propósito : La volada en el formato de salida
-- Parámetros: volada As String — lo que va entre las llaves (ya validado)
-- Retorna   : Inline o Inlines — el punto y la volada
-- ============================================
local function traducir(volada)

  -- --- 1. JATS: <sup> ADMITE specific-use, NO content-type (DTD 1.4) ---
  if FORMAT == 'jats' then
    return pandoc.RawInline('jats',
      '.<sup specific-use="volada">' .. volada .. '</sup>')
  end

  -- --- 2. DOCBOOK: role, COMO LOS DEMÁS MATICES DEL PROYECTO ---
  if FORMAT == 'docbook5' then
    return pandoc.RawInline('docbook',
      '.<superscript role="volada">' .. volada .. '</superscript>')
  end

  -- --- 3. ODT: EL PUNTO Y EL SUPERÍNDICE COMÚN ---
  return { pandoc.Str('.'), pandoc.Superscript({ pandoc.Str(volada) }) }
end

-- ============================================
-- Función   : procesar_inlines
-- Propósito : Traduce cada \sptext{…} de una lista de elementos en línea
-- Parámetros: inlines As Inlines
-- Retorna   : Inlines — la lista con las voladas traducidas
-- ============================================
local function procesar_inlines(inlines)
  local resultado, volada, anterior, traduccion

  resultado = pandoc.Inlines({})
  for i, el in ipairs(inlines) do
    volada = volada_de(el)
    if volada then
      -- --- 1. LA REGLA ABIERTA ---
      if volada == '' then
        fallar('«\\sptext{}» está vacía.')
      end
      if not es_volada_valida(volada) then
        fallar('«\\sptext{' .. volada .. '}»: adentro van solo minúsculas.')
      end
      -- --- 2. LA BASE: EL ELEMENTO ORIGINAL ANTERIOR, NO LA TRADUCCIÓN ---
      anterior = (i > 1) and inlines[i - 1] or nil
      controlar_base(anterior, volada)
      -- --- 3. LA TRADUCCIÓN ---
      traduccion = traducir(volada)
      if traduccion.t then
        resultado:insert(traduccion)
      else
        resultado:extend(traduccion)
      end
    else
      resultado:insert(el)
    end
  end
  return resultado
end

-- ============================================
-- Función   : es_espanol
-- Propósito : Dice si una etiqueta de idioma es del español
-- Parámetros: s As String — es, es-AR, en…
-- Retorna   : boolean
-- ============================================
local function es_espanol(s)
  s = s:lower()
  return s == 'es' or s:sub(1, 3) == 'es-'
end

-- ============================================
-- Función   : contiene_volada
-- Propósito : Dice si un elemento tiene alguna \sptext adentro
-- Parámetros: el As Inline o Block
-- Retorna   : boolean
-- ============================================
local function contiene_volada(el)
  local hay = false
  el:walk({ RawInline = function(r)
    if volada_de(r) then hay = true end
  end })
  return hay
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Controla el idioma y traduce las voladas de todo el documento
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con las voladas traducidas
-- ============================================
function Pandoc(doc)
  local idioma

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[sptext] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end

  -- --- 2. EL IDIOMA DEL DOCUMENTO, CUANDO LA CADENA LO DICE ---
  -- LA REVISTA PASA -M gb-idioma (m_XML.ArgumentoIdiomaPandoc). EL LIBRO
  -- NO: EL IDIOMA DEL CAPÍTULO LO CONTROLA LA HOJA LaTeX SOBRE xml:lang
  -- (SC-62), Y NO SE PASA gb-idioma PORQUE conversacion.lua LO USA PARA
  -- OTRA COSA
  if doc.meta['gb-idioma'] then
    idioma = pandoc.utils.stringify(doc.meta['gb-idioma'])
    if not es_espanol(idioma) and contiene_volada(doc) then
      fallar('El artículo está en «' .. idioma .. '» y lleva \\sptext.')
    end
  end

  -- --- 3. UN TRAMO MARCADO EN OTRO IDIOMA ([texto]{lang=en}) ---
  doc:walk({ Span = function(el)
    if el.attributes.lang and not es_espanol(el.attributes.lang)
       and contiene_volada(el) then
      fallar('Un tramo en «' .. el.attributes.lang .. '» lleva \\sptext.')
    end
  end })

  -- --- 4. LA TRADUCCIÓN, EN TODO EL DOCUMENTO ---
  -- TÍTULOS, PÁRRAFOS, NOTAS, PIES, CELDAS: DONDE HAYA UNA LISTA DE INLINES
  return doc:walk({ Inlines = procesar_inlines })
end
