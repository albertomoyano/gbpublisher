-- ============================================================
-- FILTRO      : conversacion.lua
-- PROPÓSITO   : CONTROLA LA CONVERSACIÓN (SC-43) CON UNA SOLA REGLA
--               PARA LIBRO, REVISTA Y ODT. EN REVISTA ESCRIBE LA
--               ETIQUETA DE CADA TURNO, QUE <speaker> NECESITA; EN EL
--               ODT RESUELVE LA CONVERSACIÓN EN PÁRRAFOS. LA
--               SERIALIZACIÓN A JATS Y A DOCBOOK LA HACEN
--               cite-to-xref.lua Y fenced-divs-to-elements-db.lua,
--               QUE YA TIENEN LAS CITAS RESUELTAS.
-- ENTRADA     : ::: conversacion
--
--               ::: {.pregunta quien="Ana Pérez"}
--
--               ¿Cuándo empezó?
--
--               [/pregunta]: # ()
--               :::
--
--               ::: respuesta
--
--               En 1990.
--
--               [/respuesta]: # ()
--               :::
--
--               ::: acotacion
--
--               [Se interrumpe la grabación]
--
--               [/acotacion]: # ()
--               :::
--
--               [/conversacion]: # ()
--               :::
-- ETIQUETA    : quien= CUANDO EL TEXTO DA EL NOMBRE; SIN quien, LA
--               ETIQUETA POR OMISIÓN SEGÚN EL IDIOMA DEL DOCUMENTO, QUE
--               LLEGA COMO -M gb-idioma=xx. ESPAÑOL POR OMISIÓN: UN IDIOMA
--               QUE NO ESTÁ EN LA TABLA, O NINGUNO, DA P. Y R.
--               EL LIBRO NO LA NECESITA: SIN quien NO HAY <label> Y LA
--               HOJA PONE LA ETIQUETA (defaultlabel="qanda").
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : REVISTA, DESPUÉS DE unwrap-structural-divs.lua Y DE
--               recuadros.lua, ANTES DE cite-to-xref.lua. LIBRO, ANTES
--               DE fenced-divs-to-elements-db.lua. ODT, EN CUALQUIER
--               LUGAR.
-- REGLA       : FRENA LA CONVERSIÓN CON UN MENSAJE SI:
--               - QUEDA UN ::: {.speech}: SE RETIRÓ;
--               - UNA CONVERSACIÓN ESTÁ VACÍA, ESTÁ DENTRO DE OTRA O
--                 TIENE ALGO QUE NO ES UN TURNO NI UNA ACOTACIÓN;
--               - LA CONVERSACIÓN NO EMPIEZA CON UNA PREGUNTA
--                 (qandaentry EXIGE question, GV-82);
--               - UN TURNO O UNA ACOTACIÓN ESTÁ VACÍO, O VA FUERA DE
--                 UNA CONVERSACIÓN;
--               - quien ESTÁ ESCRITO PERO VACÍO;
--               - EN REVISTA, UN TURNO TIENE ALGO QUE NO ES UN PÁRRAFO
--                 (speech SOLO ADMITE p, GV-81);
--               - UNA ACOTACIÓN TIENE ALGO QUE NO ES UN PÁRRAFO.
-- GEMELOS     : LA TABLA DE ETIQUETAS ES LA DE conversacion-comun.xsl
--               (LIBROS). UN CAMBIO VA EN LOS DOS.
-- ============================================================

-- CLASES DEL CATÁLOGO DE gbShortcodes (RF-11)
local CONTENEDOR = 'conversacion'
local ACOTACION = 'acotacion'
local TURNOS = { pregunta = true, respuesta = true }

-- ETIQUETAS POR OMISIÓN POR IDIOMA (SC-43). LA CLAVE ES EL CÓDIGO
-- PRINCIPAL DEL IDIOMA, SIN REGIÓN: es-AR Y es DAN LO MISMO
local ETIQUETAS = {
  es = { pregunta = 'P.', respuesta = 'R.' },
  en = { pregunta = 'Q.', respuesta = 'A.' },
}
local IDIOMA_POR_OMISION = 'es'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que ubica el bloque
-- Parámetros: el As Block — el bloque; motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(el, motivo)
  local inicio = pandoc.utils.stringify(el):sub(1, 60)
  error('\n[conversación] ' .. motivo ..
        '\n  Comienzo del bloque: ' .. inicio .. '\n', 0)
end

-- ============================================
-- Función   : rol_de
-- Propósito : El papel de un bloque dentro de una conversación
-- Parámetros: el As Block
-- Retorna   : String — pregunta, respuesta, acotacion o conversacion;
--             nil si el bloque no es ninguno de ellos
-- ============================================
local function rol_de(el)
  if el.t ~= 'Div' then return nil end
  for _, c in ipairs(el.classes) do
    if TURNOS[c] or c == ACOTACION or c == CONTENEDOR then return c end
  end
  return nil
end

-- ============================================
-- Función   : solo_parrafos
-- Propósito : Dice si una lista de bloques tiene solo párrafos
-- Parámetros: bloques As Blocks
-- Retorna   : boolean
-- ============================================
local function solo_parrafos(bloques)
  for _, b in ipairs(bloques) do
    if b.t ~= 'Para' and b.t ~= 'Plain' then return false end
  end
  return true
end

-- ============================================
-- Función   : idioma_de
-- Propósito : El idioma del documento para la etiqueta por omisión
-- Parámetros: doc As Pandoc
-- Retorna   : String — una clave de ETIQUETAS
-- ============================================
local function idioma_de(doc)
  local codigo

  -- --- 1. SIN -M gb-idioma, ESPAÑOL ---
  -- CLAVE PROPIA Y NO lang: EN EL ODT, lang CAMBIARÍA ADEMÁS EL IDIOMA DE
  -- citeproc Y DEL DOCUMENTO, QUE ESTE FILTRO NO TIENE POR QUÉ TOCAR
  if not doc.meta['gb-idioma'] then return IDIOMA_POR_OMISION end

  -- --- 2. EL CÓDIGO PRINCIPAL, SIN REGIÓN ---
  codigo = pandoc.utils.stringify(doc.meta['gb-idioma']):lower():match('^(%a+)')
  if codigo and ETIQUETAS[codigo] then return codigo end

  -- --- 3. UN IDIOMA FUERA DE LA TABLA TAMBIÉN DA ESPAÑOL (SC-43) ---
  return IDIOMA_POR_OMISION
end

-- ============================================
-- Función   : controlar
-- Propósito : Aplica las reglas de SC-43 a una conversación
-- Parámetros: el As Div — la conversación; es_revista As Boolean
-- Retorna   : nada; frena si algo no se cumple
-- ============================================
local function controlar(el, es_revista)
  local hay_turno = false
  local rol, quien

  -- --- 1. NO VACÍA ---
  if #el.content == 0 then fallar(el, 'la conversación está vacía.') end

  -- --- 2. CADA HIJO ES UN TURNO O UNA ACOTACIÓN ---
  for _, hijo in ipairs(el.content) do
    rol = rol_de(hijo)
    if rol == CONTENEDOR then
      fallar(el, 'una conversación no puede ir dentro de otra.')
    end
    if not rol then
      fallar(el, 'dentro de una conversación solo van ::: pregunta, ::: respuesta ' ..
                 'y ::: acotacion. El texto suelto va dentro de un turno.')
    end

    -- --- 3. EL PRIMER TURNO ES UNA PREGUNTA ---
    -- EN EL LIBRO, qandaentry EXIGE question (GV-82); LA FORMA DEL .md ES
    -- UNA SOLA, ASÍ QUE LA REGLA VALE TAMBIÉN EN REVISTA
    if rol == 'respuesta' and not hay_turno then
      fallar(hijo, 'la conversación empieza con una respuesta: el primer turno ' ..
                   'es una pregunta. Una acotación sí puede ir antes.')
    end
    if TURNOS[rol] then hay_turno = true end

    -- --- 4. NADA VACÍO, NADA ANIDADO ---
    if #hijo.content == 0 then fallar(hijo, 'un ::: ' .. rol .. ' está vacío.') end
    pandoc.Blocks(hijo.content):walk({ Div = function(d)
      if rol_de(d) then
        fallar(hijo, 'un turno o una acotación no puede llevar adentro otro turno, ' ..
                     'otra acotación ni otra conversación.')
      end
    end })

    -- --- 5. quien ESCRITO, CON TEXTO ---
    quien = hijo.attributes['quien']
    if quien and quien:match('^%s*$') then
      fallar(hijo, 'quien="" está vacío: se escribe el nombre que da el texto, o se ' ..
                   'quita el atributo para que salga la etiqueta por omisión.')
    end
    if quien and rol == ACOTACION then
      fallar(hijo, 'una acotación no lleva quien: no es un turno.')
    end

    -- --- 6. CONTENIDO ---
    -- LA ACOTACIÓN, SIEMPRE PÁRRAFOS. EL TURNO, PÁRRAFOS EN REVISTA: speech
    -- SOLO ADMITE p (GV-81). EN LIBRO, CUALQUIER BLOQUE (question Y answer
    -- ADMITEN TODOS, GV-82)
    if rol == ACOTACION and not solo_parrafos(hijo.content) then
      fallar(hijo, 'una acotación solo admite párrafos.')
    end
    if TURNOS[rol] and es_revista and not solo_parrafos(hijo.content) then
      fallar(hijo, 'en una revista un turno solo admite párrafos (con bastardilla, ' ..
                   'negrita, citas y notas): JATS no admite listas ni citas dentro ' ..
                   'de un turno. Cortar el turno, o pasar el elemento a texto.')
    end
  end

  -- --- 7. AL MENOS UN TURNO ---
  if not hay_turno then
    fallar(el, 'la conversación no tiene ningún turno: solo acotaciones.')
  end
end

-- ============================================
-- Función   : etiquetar
-- Propósito : Escribe en cada turno la etiqueta que va a <speaker>:
--             quien, o la de la tabla según el idioma
-- Parámetros: el As Div — la conversación; idioma As String
-- Retorna   : Div — la conversación con el atributo etiqueta en cada turno
-- ============================================
local function etiquetar(el, idioma)
  local rol

  -- RECORRE LOS HIJOS DIRECTOS: controlar YA VERIFICÓ LA FORMA
  for _, hijo in ipairs(el.content) do
    rol = rol_de(hijo)
    if TURNOS[rol] then
      hijo.attributes['etiqueta'] = hijo.attributes['quien'] or ETIQUETAS[idioma][rol]
    end
  end
  return el
end

-- ============================================
-- Función   : odt
-- Propósito : Resuelve la conversación en párrafos para el ODT: la
--             etiqueta en negrita y mayúsculas abre el primer párrafo de
--             cada turno; la acotación queda tal cual
-- Parámetros: el As Div — la conversación ya etiquetada
-- Retorna   : Blocks — lo que reemplaza a la conversación
-- ============================================
local function odt(el)
  local salida = pandoc.Blocks({})
  local etiqueta, primero, resto

  for _, hijo in ipairs(el.content) do
    if rol_de(hijo) == ACOTACION then
      salida:extend(hijo.content)
    else
      -- pandoc.text.upper TRABAJA SOBRE UTF-8: «Ñ» Y LOS ACENTOS PASAN BIEN
      etiqueta = pandoc.Strong({ pandoc.Str(pandoc.text.upper(hijo.attributes['etiqueta'])) })
      primero = hijo.content[1]
      resto = pandoc.Blocks({})
      for i = 2, #hijo.content do resto:insert(hijo.content[i]) end

      -- LA ETIQUETA VA EN LÍNEA CON EL PRIMER PÁRRAFO
      local inlines = pandoc.Inlines({ etiqueta, pandoc.Space() })
      inlines:extend(primero.content)
      salida:insert(pandoc.Para(inlines))
      salida:extend(resto)
    end
  end
  return salida
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Recorre el documento: frena el .speech retirado y los
--             turnos sueltos, controla cada conversación; en revista
--             etiqueta los turnos, en el ODT resuelve la conversación
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento
-- ============================================
function Pandoc(doc)
  local es_revista, es_odt, idioma

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[conversación] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end
  es_revista = (FORMAT == 'jats')
  es_odt = (FORMAT == 'odt')

  -- EL IDIOMA SE LEE ACÁ, CON EL DOCUMENTO ENTERO: EN UNA FUNCIÓN Div DE
  -- LA MISMA TABLA, Meta TODAVÍA NO HABRÍA CORRIDO (GV-84)
  idioma = idioma_de(doc)

  -- --- 2. LO QUE ESTÁ FUERA DE UNA CONVERSACIÓN ---
  -- DE ARRIBA HACIA ABAJO, SIN ENTRAR EN LAS CONVERSACIONES: UN TURNO QUE
  -- APARECE ACÁ ESTÁ SUELTO. LO DE ADENTRO LO CONTROLA controlar
  doc:walk({ traverse = 'topdown', Div = function(el)
    local rol = rol_de(el)

    -- EL BLOQUE VIEJO SE RETIRÓ (SC-43). SIN ESTE FRENO PANDOC LO
    -- CONVERTIRÍA EN UN BLOQUE GENÉRICO, SIN AVISO
    if el.classes:includes('speech') then
      fallar(el, 'el bloque ::: {.speech} se retiró. Usar ::: conversacion, con ' ..
                 '::: pregunta y ::: respuesta adentro (quien="Nombre" cuando el ' ..
                 'texto da el nombre).')
    end
    if rol == CONTENEDOR then return el, false end
    if rol then fallar(el, 'un ::: ' .. rol .. ' va dentro de un ::: conversacion.') end
    return nil
  end })

  -- --- 3. CADA CONVERSACIÓN ---
  return doc:walk({ Div = function(el)
    if rol_de(el) ~= CONTENEDOR then return nil end
    controlar(el, es_revista)
    if es_revista or es_odt then el = etiquetar(el, idioma) end
    if es_odt then return odt(el) end
    return el
  end })
end
