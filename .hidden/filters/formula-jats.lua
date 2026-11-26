-- ============================================================
-- FILTRO      : formula-jats.lua
-- PROPÓSITO   : LA FÓRMULA NUMERADA DE UN ARTÍCULO (SC-110, LOTE 2b):
--               [$$…$$]{#eq-nombre} PASA A <disp-formula id="eq-nombre">
--               CON SU NÚMERO EN <label>, «(1)», «(2)»…, EN EL ORDEN DEL
--               ARTÍCULO. LAS DEMÁS FÓRMULAS LAS ESCRIBE PANDOC SIN AYUDA:
--               EL ESCRITOR JATS YA PONE EL TeX Y EL MathML EN
--               <alternatives> (GV-229).
-- ENTRADA     : [$$E = mc^2$$]{#eq-energia}
-- SALIDA      : <disp-formula id="eq-energia"><label>(1)</label>
--               <alternatives><tex-math>…</tex-math><mml:math>…
-- POR QUÉ     : SIN ESTE FILTRO, EL CORCHETE CON id SALE COMO
--               <styled-content id> ALREDEDOR DEL <disp-formula>, Y LA
--               FÓRMULA QUEDA SIN NÚMERO. EL NÚMERO VA EN EL CANÓNICO Y NO
--               EN CADA SALIDA: ES EL MISMO EN EL PDF, EL HTML, EL EPUB Y
--               LOS SABORES (SciELO LEE EL <label>).
-- REMISIÓN    : NO HAY. UN ARTÍCULO ES AUTÓNOMO (SC-32): @eq- FRENA EN
--               cite-to-xref.lua Y LA MENCIÓN («la ecuación (2)») LA ESCRIBE
--               EL AUTOR. EL id QUEDA PARA LOS SABORES Y LOS ENLACES.
-- FRENA       : EL VIEJO ::: {.formula #eq-…} (CORTABA EL PÁRRAFO), UN id
--               QUE NO ES eq- CON LETRAS, CIFRAS O GUIONES, CLASES EN EL
--               CORCHETE, O ALGO DISTINTO DE UNA SOLA FÓRMULA EN BLOQUE.
--               LAS MISMAS REGLAS QUE formula.lua EN EL LIBRO.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN LA CADENA DE REVISTAS, DESPUÉS DE espacio-fijo Y ANTES
--               DE TODO FILTRO QUE SERIALICE (cite-to-xref, cuadro-armar).
-- ============================================================

-- DE ARRIBA HACIA ABAJO: EL NÚMERO SIGUE EL ORDEN DEL ARTÍCULO, Y EL
-- CORCHETE SE RESUELVE ANTES DE BAJAR A SU FÓRMULA
traverse = 'topdown'

-- EL id DE UNA FÓRMULA NUMERADA: eq- Y LETRAS ASCII, CIFRAS O GUIONES
local PATRON_ID = '^eq%-[%w%-]+$'

-- LA CUENTA DE NUMERADAS DEL ARTÍCULO
local iNumero = 0

-- ============================================
-- Función   : Frenar
-- Propósito : Corta la conversión con un mensaje para el editor
-- Parámetros: sMensaje As string — qué pasó y cómo se escribe
-- Retorna   : nada (error)
-- ============================================
local function Frenar(sMensaje)

  -- NIVEL 0: SIN EL NOMBRE DEL ARCHIVO NI LA LÍNEA DEL FILTRO (GV-23)
  error('\n[fórmula] ' .. sMensaje, 0)

end

-- ============================================
-- Función   : Div
-- Propósito : Frena el viejo bloque .formula
-- Parámetros: el As Div — el bloque
-- Retorna   : nil (frena si es un .formula)
-- ============================================
function Div(el)

  if el.classes:includes('formula') then
    Frenar('el bloque ::: {.formula …} ya no se usa: corta el párrafo. Una fórmula ' ..
           'numerada se escribe [$$…$$]{#eq-nombre}, pegada a la frase que la introduce (SC-110).')
  end
  return nil

end

-- ============================================
-- Función   : Span
-- Propósito : La fórmula numerada: [$$…$$]{#eq-nombre}. Un corchete con
--             otro id o con clases no es una fórmula y sigue de largo
-- Parámetros: el As Span — el corchete con atributos
-- Retorna   : RawInline jats y false (no se recorre adentro), o nil
-- ============================================
function Span(el)

  local aContenido = {}
  local doc, xml, etiqueta

  -- --- 1. SOLO EL id eq-…: LOS DEMÁS CORCHETES SON DE OTROS FILTROS ---
  if el.identifier:sub(1, 3) ~= 'eq-' then return nil end

  -- --- 2. VALIDACIÓN, COMO EN EL LIBRO (formula.lua) ---
  if not el.identifier:match(PATRON_ID) then
    Frenar('el id «' .. el.identifier .. '» no sirve: va eq- seguido de letras sin ' ..
           'acento, cifras o guiones (eq-energia, eq-ciclo-2).')
  end
  if #el.classes > 0 then
    Frenar('la fórmula numerada #' .. el.identifier .. ' lleva clases: va solo el id, ' ..
           '[$$…$$]{#' .. el.identifier .. '}.')
  end
  for _, hijo in ipairs(el.content) do
    -- LOS ESPACIOS ALREDEDOR DE LA FÓRMULA NO CUENTAN
    if hijo.t ~= 'Space' and hijo.t ~= 'SoftBreak' then
      table.insert(aContenido, hijo)
    end
  end
  if #aContenido ~= 1 or aContenido[1].t ~= 'Math'
     or aContenido[1].mathtype ~= 'DisplayMath' then
    Frenar('#' .. el.identifier .. ': adentro del corchete va una sola fórmula en bloque, ' ..
           '[$$…$$]{#' .. el.identifier .. '}: «' .. pandoc.utils.stringify(el.content):sub(1, 60) .. '».')
  end

  -- --- 3. EL <disp-formula> LO ESCRIBE PANDOC, CON SUS alternatives ---
  doc = pandoc.Pandoc({pandoc.Plain({aContenido[1]})})
  xml = pandoc.write(doc, 'jats', {wrap_text = 'none'})
  xml = xml:gsub('^%s+', ''):gsub('%s+$', '')
  -- EL ESCRITOR JATS ENVUELVE EL Plain EN <p> (MEDIDO, 3.1.3): SE QUITA
  xml = xml:gsub('^<p>', ''):gsub('</p>$', '')
  etiqueta = '<disp-formula>'
  if xml:sub(1, #etiqueta) ~= etiqueta then
    error('formula-jats.lua: pandoc no escribió <disp-formula> para #' .. el.identifier ..
          '; escribió: ' .. xml:sub(1, 80))
  end

  -- --- 4. EL id Y EL NÚMERO. EL <label> VA PRIMERO: LO PIDE EL ESQUEMA ---
  iNumero = iNumero + 1
  xml = '<disp-formula id="' .. el.identifier .. '"><label>(' .. iNumero .. ')</label>'
        .. xml:sub(#etiqueta + 1)

  return pandoc.RawInline('jats', xml), false

end
