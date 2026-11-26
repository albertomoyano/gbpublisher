-- ============================================================
-- FILTRO      : formula.lua
-- PROPÓSITO   : CADA FÓRMULA DEL .md ($…$ Y $$…$$) PASA AL CANÓNICO
--               DocBook CON SUS DOS FORMAS: EL TeX DEL AUTOR EN
--               <alt role="tex"> Y EL MathML QUE ESCRIBE PANDOC (SC-110).
-- ENTRADA     : $c_{ij}$                  Math InlineMath "c_{ij}"
--               $$q = f$$                 Math DisplayMath "q = f"
-- SALIDA      : <inlineequation><alt role="tex">c_{ij}</alt><mml:math>…
--               <informalequation><alt role="tex">q = f</alt><mml:math>…
--               EL PDF COMPONE DESDE EL alt (docbook-to-latex.xsl); EL
--               HTML Y EL EPUB COPIAN EL MathML (formula-comun.xsl).
-- POR QUÉ     : EL ESCRITOR DocBook DE PANDOC GUARDA SOLO EL MathML Y EL
--               TeX SE PIERDE (GV-229). CONVERTIR MathML A TeX EN XSLT
--               PIERDE LOS CORTES DEL AUTOR (aligned, \\), Y EL PDF ES
--               LA SALIDA DE REFERENCIA (SC-31). EL alt ANTES DEL MathML
--               VALIDA CONTRA DocBook 5.2 (GV-229).
-- EL PÁRRAFO  : LA FÓRMULA EN BLOQUE QUEDA ADENTRO DEL PÁRRAFO QUE LA
--               INTRODUCE: SIN LÍNEA EN BLANCO ANTES DEL $$, EL TEXTO QUE
--               SIGUE («donde», «siendo») CONTINÚA SIN SANGRÍA (SC-110).
-- NUMERADA   : [$$…$$]{#eq-nombre}, ADENTRO DEL PÁRRAFO COMO LA OTRA
--               (SC-110, LOTE 2). SALE <equation xml:id="eq-nombre"> CON EL
--               alt Y EL MathML. SE REFIERE CON @eq-nombre DESDE CUALQUIER
--               CAPÍTULO (cite-to-biblioref-db: «(9.1)»). FRENA SI EL
--               CORCHETE NO TIENE UNA SOLA FÓRMULA EN BLOQUE, SI EL id NO ES
--               eq- CON LETRAS, CIFRAS Y GUIONES, O SI LLEVA CLASES.
-- ALCANCE     : TODA Math, TAMBIÉN EN NOTAS Y CUADROS. EL VIEJO BLOQUE
--               ::: {.formula #eq-…} FRENA CON UN MENSAJE: CORTABA EL
--               PÁRRAFO Y SU <equation> NO TENÍA EL TeX.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN LA CADENA DEL LIBRO, DESPUÉS DE cuadro-leer (QUE TRAE
--               EL TEXTO DEL CUADRO) Y ANTES DE TODO FILTRO QUE
--               SERIALICE: cite-to-biblioref-db ESCRIBE LAS NOTAS CON
--               pandoc.write SIN --mathml, Y UNA FÓRMULA QUE LLEGUE AHÍ
--               SIN TRADUCIR PIERDE EL MathML Y EL TeX.
-- ============================================================

-- EL RECORRIDO DE ARRIBA HACIA ABAJO PERMITE NO ENTRAR EN UN .formula
traverse = 'topdown'

-- ============================================
-- Función   : Escapar
-- Propósito : Escapa el TeX para ponerlo como texto de un elemento XML
-- Parámetros: s As string — el TeX de la fórmula
-- Retorna   : string — el texto con &, < y > escapados
-- ============================================
local function Escapar(s)

  -- & PRIMERO: SI NO, ESCAPARÍA LOS & DE LAS ENTIDADES QUE AGREGA DESPUÉS.
  -- LOS PARÉNTESIS DEJAN UN SOLO VALOR: gsub DEVUELVE TAMBIÉN LA CANTIDAD
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))

end

-- EL id DE UNA FÓRMULA NUMERADA: eq- Y LETRAS ASCII, CIFRAS O GUIONES. ES
-- UN xml:id Y EL \label DEL PDF: SIN ACENTOS NI ESPACIOS
local PATRON_ID = '^eq%-[%w%-]+$'

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
-- Función   : Ecuacion
-- Propósito : Escribe la ecuación DocBook de una fórmula: el elemento que
--             arma Pandoc con el MathML, con el TeX en <alt role="tex">
--             antes del contenido. Con id, la numerada: <equation xml:id>
-- Parámetros: el As Math — la fórmula
--             sId As string — el id de la numerada, o nil
-- Retorna   : string — la ecuación en DocBook
-- ============================================
local function Ecuacion(el, sId)

  local doc, xml, etiqueta, alt

  -- --- 1. EL MathML LO ESCRIBE PANDOC: MISMO ESCRITOR Y MISMA OPCIÓN QUE
  --        LA CADENA (--mathml), PARA QUE EL CANÓNICO NO CAMBIE ---
  doc = pandoc.Pandoc({pandoc.Plain({el})})
  xml = pandoc.write(doc, 'docbook5',
                     {html_math_method = 'mathml', wrap_text = 'none'})
  xml = xml:gsub('^%s+', ''):gsub('%s+$', '')

  -- --- 2. LA ETIQUETA ESPERADA SEGÚN EL TIPO ---
  if el.mathtype == 'DisplayMath' then
    etiqueta = '<informalequation>'
  else
    etiqueta = '<inlineequation>'
  end

  -- --- 3. EL alt VA PRIMERO: EL ESQUEMA LO PIDE ANTES DEL CONTENIDO.
  --        SI PANDOC ESCRIBIÓ OTRA COSA, SE FRENA: UNA FÓRMULA SIN SU TeX
  --        NO SE PUEDE COMPONER EN EL PDF ---
  if xml:sub(1, #etiqueta) ~= etiqueta then
    error('formula.lua: pandoc no escribió ' .. etiqueta .. ' para la fórmula «'
          .. el.text:sub(1, 60) .. '»; escribió: ' .. xml:sub(1, 80))
  end
  alt = '<alt role="tex">' .. Escapar(el.text) .. '</alt>'
  xml = xml:sub(#etiqueta + 1)

  -- --- 4. LA NUMERADA CAMBIA EL ELEMENTO: equation CON SU id ---
  if sId then
    xml = xml:gsub('</informalequation>$', '</equation>')
    return '<equation xml:id="' .. sId .. '">' .. alt .. xml
  end
  return etiqueta .. alt .. xml

end

-- ============================================
-- Función   : Div
-- Propósito : Frena el viejo bloque .formula, reemplazado por la numerada
--             adentro del párrafo
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
-- Retorna   : RawInline docbook y false (no se recorre adentro), o nil
-- ============================================
function Span(el)

  local aContenido = {}

  -- --- 1. SOLO EL id eq-…: LOS DEMÁS CORCHETES SON DE OTROS FILTROS ---
  if el.identifier:sub(1, 3) ~= 'eq-' then return nil end

  -- --- 2. VALIDACIÓN: UN id PROLIJO, SIN CLASES, UNA SOLA FÓRMULA EN BLOQUE ---
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

  -- --- 3. LA ECUACIÓN NUMERADA ---
  return pandoc.RawInline('docbook', Ecuacion(aContenido[1], el.identifier)), false

end

-- ============================================
-- Función   : Math
-- Propósito : Reemplaza la fórmula por su ecuación DocBook con el TeX
--             en <alt role="tex"> antes del MathML
-- Parámetros: el As Math — la fórmula
-- Retorna   : RawInline docbook — la ecuación completa
-- ============================================
function Math(el)

  return pandoc.RawInline('docbook', Ecuacion(el, nil))

end
