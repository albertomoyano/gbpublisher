-- ============================================================
-- FILTRO      : dos-partes.lua
-- PROPÓSITO   : PARTE LOS BLOQUES DE DOS PARTES —EL EPÍGRAFE (SC-35)
--               Y EL RECUADRO CON BARRA (SC-41)— EN SUS DOS MITADES,
--               CON UNA SOLA REGLA PARA LIBRO, REVISTA Y ODT. QUÉ
--               ADMITE CADA PARTE LO DICE LA CONFIGURACIÓN DE LA CLASE.
-- ENTRADA     : ::: epigraph
--
--               {texto}{atribución}
--
--               [/epigraph]: # ()
--               :::
-- SALIDA      : EL MISMO Div CON DOS Div HIJOS, CON LAS CLASES DE SU
--               CONFIGURACIÓN:
--                 epigraph   .epigrafe-texto (UNO O MÁS Para, O UN
--                                            SOLO Div verse, SC-49)
--                            .epigrafe-atrib (UN Para; FALTA SI LA
--                                            SEGUNDA PARTE ESTÁ VACÍA)
--                 recuadrob  .recuadro-barra (UN Para)
--                            .recuadro-texto (UNO O MÁS Para)
--               LOS FILTROS DE CADA SALIDA LEEN ESA FORMA.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE LOS FILTROS DE COMILLAS Y ANTES DE
--               cite-to-xref.lua (REVISTA), fenced-divs-to-elements-db.lua
--               (LIBRO) Y epigrafe-odt.lua (ODT).
-- REGLA       : LAS LLAVES SON EL SEMÁFORO DEL EPÍGRAFE. UN BLOQUE QUE
--               NO TIENE LA FORMA {…}{…} FRENA LA CONVERSIÓN CON UN
--               MENSAJE: NUNCA SE DEGRADA EN SILENCIO.
-- VERSO       : LA PRIMERA PARTE DEL EPÍGRAFE PUEDE SER UN VERSO
--               (SC-49), SOLO, SIN PROSA AL LADO. LA LLAVE DE APERTURA Y
--               LA DE CIERRE VAN EN SU PROPIO PÁRRAFO, CON LÍNEAS EN
--               BLANCO ALREDEDOR DEL VERSO (SIN ELLAS PANDOC NO LO LEE
--               COMO BLOQUE, GV-92):
--
--               {
--
--               ::: {.verse patron="01"}
--
--               Versos…
--
--               [/verse]: # ()
--               :::
--
--               }{Atribución}
--
--               EL VERSO SALE CON LA CLASE en-epigrafe: CON ELLA EL
--               SERIALIZADOR DE DOCBOOK NO LE PONE EL <blockquote>, QUE
--               <epigraph> NO ADMITE. LO CONTROLA verso.lua, QUE CORRE
--               DESPUÉS.
-- ============================================================

-- CLASES DE MODO dos-partes DEL CATÁLOGO DE gbShortcodes (RF-11), CON LO
-- QUE ADMITE CADA PARTE. m_Shortcodes.ProblemaDosPartes TIENE LA MISMA
-- TABLA PARA CONTROLAR LA SELECCIÓN AL INSERTAR: UN CAMBIO VA EN LAS DOS.
-- verso1 (SC-49) NO TIENE GEMELO ALLÁ: EL PANEL CONTROLA LAS LLAVES, NO
-- QUÉ BLOQUES HAY ENTRE ELLAS
local CLASES = {
  -- <attribution> (DOCBOOK) Y <attrib> (JATS) SOLO ADMITEN TEXTO EN LÍNEA.
  -- EL TEXTO PUEDE SER UN VERSO (SC-49)
  epigraph = {
    nombre = 'Epígrafe', forma = '{texto}{atribución}',
    clase1 = 'epigrafe-texto', clase2 = 'epigrafe-atrib',
    varios1 = true, varios2 = false, vacia2 = true, verso1 = true,
  },
  -- LA BARRA ES UNA LÍNEA; EL TEXTO, UNO O MÁS PÁRRAFOS (SC-41)
  recuadrob = {
    nombre = 'Recuadro con barra', forma = '{texto de la barra}{texto del recuadro}',
    clase1 = 'recuadro-barra', clase2 = 'recuadro-texto',
    varios1 = false, varios2 = true, vacia2 = false, verso1 = false,
  },
}

-- EL VERSO (SC-49) Y LA MARCA QUE LLEVA CUANDO ES EL TEXTO DE UN EPÍGRAFE
local CLASE_VERSO = 'verse'
local CLASE_EN_EPIGRAFE = 'en-epigrafe'

-- MARCAS INTERNAS DEL RECORRIDO: NO SON INLINES DE PANDOC. EL VERSO VA
-- COMO UNA MARCA PROPIA QUE LLEVA SU Div
local ABRE = { marca = 'abre' }
local CIERRA = { marca = 'cierra' }
local PARRAFO = { marca = 'parrafo' }

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que ubica el bloque
-- Parámetros: el As Div — el bloque; motivo As String — qué está mal;
--             cfg As table — la configuración de la clase
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(el, motivo, cfg)
  local inicio = pandoc.utils.stringify(el):sub(1, 60)
  error('\n[gbpublisher] ' .. cfg.nombre .. ' mal formado: ' .. motivo ..
        '\n  Forma esperada: ' .. cfg.forma ..
        '\n  Comienzo del bloque: ' .. inicio .. '\n', 0)
end

-- ============================================
-- Función   : tokenizar
-- Propósito : Aplana los párrafos del bloque en una sola secuencia,
--             separando las llaves del nivel del párrafo de sus Str
-- Parámetros: el As Div — el bloque
-- Retorna   : table — inlines, marcas ABRE/CIERRA y PARRAFO entre párrafos,
--             y una marca { marca = 'verso', div = … } por cada verso
-- ============================================
local function tokenizar(el, cfg)
  local tokens = {}
  for i, bloque in ipairs(el.content) do
    if i > 1 then tokens[#tokens + 1] = PARRAFO end
    if cfg.verso1 and bloque.t == 'Div' and bloque.classes:includes(CLASE_VERSO) then
      -- UN VERSO (SC-49): DÓNDE QUEDÓ LO DECIDE Div, CON LAS LLAVES YA CONTADAS
      tokens[#tokens + 1] = { marca = 'verso', div = bloque }
      goto siguiente
    end
    -- SOLO PÁRRAFOS: UNA LISTA O UNA TABLA NO ENTRA EN UN EPÍGRAFE
    if bloque.t ~= 'Para' and bloque.t ~= 'Plain' then
      fallar(el, 'solo admite párrafos (hay un ' .. bloque.t .. ')', cfg)
    end
    for _, inl in ipairs(bloque.content) do
      if inl.t == 'Str' then
        -- UNA LLAVE PUEDE VENIR PEGADA AL TEXTO: «.}{Francis» ES UN Str
        local resto = inl.text
        while resto ~= '' do
          local pos = resto:find('[{}]')
          if not pos then
            tokens[#tokens + 1] = pandoc.Str(resto)
            break
          end
          if pos > 1 then tokens[#tokens + 1] = pandoc.Str(resto:sub(1, pos - 1)) end
          tokens[#tokens + 1] = (resto:sub(pos, pos) == '{') and ABRE or CIERRA
          resto = resto:sub(pos + 1)
        end
      else
        tokens[#tokens + 1] = inl
      end
    end
    ::siguiente::
  end
  return tokens
end


-- ============================================
-- Función   : es_blanco
-- Propósito : Dice si un token es espacio entre palabras o salto de línea
-- Parámetros: t As token
-- Retorna   : boolean
-- ============================================
local function es_blanco(t)
  return t.t == 'Space' or t.t == 'SoftBreak' or t.t == 'LineBreak'
end

-- ============================================
-- Función   : es_verso
-- Propósito : Dice si un token es la marca de un verso
-- Parámetros: t As token
-- Retorna   : boolean
-- ============================================
local function es_verso(t)
  return type(t) == 'table' and t.marca == 'verso'
end

-- ============================================
-- Función   : verso_de
-- Propósito : El verso de una parte, si lo tiene, controlando que vaya solo
-- Parámetros: el As Div; tokens As table — los de la parte; cfg As table
-- Retorna   : Div — el verso; nil si la parte no tiene verso
-- ============================================
local function verso_de(el, tokens, cfg)
  local verso = nil
  local otra_cosa = false

  for _, t in ipairs(tokens) do
    if es_verso(t) then
      if verso then fallar(el, 'la primera parte tiene más de un verso', cfg) end
      verso = t.div
    elseif not (t == PARRAFO or (t.t and es_blanco(t))) then
      otra_cosa = true
    end
  end

  -- EL VERSO VA SOLO: UN EPÍGRAFE ES PROSA O VERSO, NO LAS DOS COSAS
  if verso and otra_cosa then
    fallar(el, 'la primera parte tiene el verso y además texto: el verso va solo', cfg)
  end
  return verso
end

-- ============================================
-- Función   : a_parrafos
-- Propósito : Arma los párrafos de una parte, sin blancos en los bordes
-- Parámetros: tokens As table — los de una parte, con PARRAFO entre párrafos
-- Retorna   : table — lista de listas de inlines; los párrafos vacíos no entran
-- ============================================
local function a_parrafos(tokens)
  local parrafos, actual = {}, {}
  local function cerrar()
    while #actual > 0 and es_blanco(actual[1]) do table.remove(actual, 1) end
    while #actual > 0 and es_blanco(actual[#actual]) do table.remove(actual) end
    if #actual > 0 then parrafos[#parrafos + 1] = actual end
    actual = {}
  end
  for _, t in ipairs(tokens) do
    if t == PARRAFO then cerrar() else actual[#actual + 1] = t end
  end
  cerrar()
  return parrafos
end

-- ============================================
-- Función   : partir
-- Propósito : Separa las dos partes contando llaves. Solo las del nivel
--             de afuera delimitan; las de adentro, balanceadas, son texto
-- Parámetros: el As Div — el bloque
-- Retorna   : table, table — los tokens de la primera y de la segunda parte
-- ============================================
local function partir(el, cfg)
  local tokens = tokenizar(el, cfg)
  local partes = {}
  local actual = nil
  local nivel = 0

  for _, t in ipairs(tokens) do
    if t == ABRE then
      nivel = nivel + 1
      if nivel == 1 then
        -- UNA PARTE NUEVA: LA ANTERIOR TIENE QUE HABER TERMINADO PEGADA
        if #partes == 2 then fallar(el, 'hay más de dos partes entre llaves', cfg) end
        actual = {}
        partes[#partes + 1] = actual
      else
        actual[#actual + 1] = pandoc.Str('{')
      end
    elseif t == CIERRA then
      if nivel == 0 then fallar(el, 'hay una llave de cierre sin su apertura', cfg) end
      nivel = nivel - 1
      if nivel == 0 then
        actual = nil
      else
        actual[#actual + 1] = pandoc.Str('}')
      end
    elseif actual then
      actual[#actual + 1] = t
    elseif es_verso(t) then
      -- EL VERSO FUERA DE LAS LLAVES: LAS LLAVES VAN EN SU PROPIO PÁRRAFO
      fallar(el, 'el verso quedó fuera de las llaves: la llave de apertura y ' ..
                 'la de cierre van en su propio párrafo, con una línea en ' ..
                 'blanco antes y después del verso', cfg)
    elseif not (es_blanco(t) or t == PARRAFO) or #partes == 1 then
      -- FUERA DE LAS LLAVES SOLO HAY BLANCOS ANTES Y DESPUÉS DEL TODO;
      -- ENTRE LAS DOS PARTES, NADA: }{ VAN PEGADAS
      fallar(el, 'hay texto fuera de las llaves, o las dos partes no van pegadas (}{)', cfg)
    end
  end

  if nivel ~= 0 then fallar(el, 'hay una llave de apertura sin cerrar', cfg) end
  if #partes ~= 2 then fallar(el, 'tiene que tener dos partes entre llaves', cfg) end
  return partes[1], partes[2]
end

-- ============================================
-- Función   : Div
-- Propósito : Reescribe cada bloque de dos partes en su forma con hijos
-- Parámetros: el As Div
-- Retorna   : Div — el bloque partido; nil si no es de dos partes
-- ============================================
function Div(el)
  local cfg = nil
  for _, c in ipairs(el.classes) do
    if CLASES[c] then cfg = CLASES[c] end
  end
  if not cfg then return nil end

  local t1, t2 = partir(el, cfg)
  local verso = verso_de(el, t1, cfg)
  local parte1, parte2

  -- EL VERSO SOLO PUEDE SER LA PRIMERA PARTE: LA ATRIBUCIÓN ES TEXTO EN LÍNEA
  for _, t in ipairs(t2) do
    if es_verso(t) then fallar(el, 'la segunda parte no admite un verso', cfg) end
  end

  -- LA PRIMERA PARTE ES EL VERSO SOLO (YA CONTROLADO) O PÁRRAFOS
  if verso then
    parte1 = { verso }
  else
    parte1 = a_parrafos(t1)
  end
  parte2 = a_parrafos(t2)

  -- LA PRIMERA PARTE ES SIEMPRE OBLIGATORIA. LA SEGUNDA, SEGÚN LA CLASE:
  -- EN EL EPÍGRAFE PUEDE ESTAR VACÍA, Y ENTONCES NO HAY FILETE
  if #parte1 == 0 then fallar(el, 'la primera parte está vacía', cfg) end
  if #parte1 > 1 and not cfg.varios1 then
    fallar(el, 'la primera parte tiene que ser un solo párrafo', cfg)
  end
  if #parte2 == 0 and not cfg.vacia2 then fallar(el, 'la segunda parte está vacía', cfg) end
  if #parte2 > 1 and not cfg.varios2 then
    fallar(el, 'la segunda parte tiene que ser un solo párrafo', cfg)
  end

  local bloques1 = {}
  if verso then
    -- EL VERSO SE MARCA PARA QUE SU SERIALIZADOR SEPA QUE ESTÁ EN UN EPÍGRAFE
    verso.classes:insert(CLASE_EN_EPIGRAFE)
    bloques1[1] = verso
  else
    for _, inl in ipairs(parte1) do bloques1[#bloques1 + 1] = pandoc.Para(inl) end
  end
  local hijos = { pandoc.Div(bloques1, pandoc.Attr('', {cfg.clase1})) }

  if #parte2 > 0 then
    local bloques2 = {}
    for _, inl in ipairs(parte2) do bloques2[#bloques2 + 1] = pandoc.Para(inl) end
    hijos[#hijos + 1] = pandoc.Div(bloques2, pandoc.Attr('', {cfg.clase2}))
  end

  return pandoc.Div(hijos, el.attr)
end
