-- ============================================================
-- FILTRO      : verso.lua
-- PROPÓSITO   : CONTROLA EL VERSO (SC-49) CON UNA SOLA REGLA PARA
--               LIBRO, REVISTA Y ODT, Y LO DEJA NORMALIZADO: CADA
--               ESTROFA CON SUS VERSOS, Y CADA VERSO CON SU NIVEL DE
--               SANGRÍA YA RESUELTO. LA SERIALIZACIÓN A JATS Y A
--               DOCBOOK LA HACEN cite-to-xref.lua Y
--               fenced-divs-to-elements-db.lua, QUE YA NO SABEN DE
--               PATRONES; EN EL ODT EL VERSO SE RESUELVE ACÁ.
-- ENTRADA     : ::: {.verse patron="0101"}
--
--               Caminante, son tus *huellas*
--               el camino y nada más;
--
--               caminante, no hay camino,
--               se hace camino al andar.
--
--               [/verse]: # ()
--               :::
--               UN PÁRRAFO ES UNA ESTROFA; CADA SALTO DE LÍNEA, UN VERSO.
--               patron ES OPCIONAL: UN DÍGITO POR VERSO (CUÁNTAS SANGRÍAS
--               LLEVA). UN GRUPO VALE PARA TODAS LAS ESTROFAS; VARIOS,
--               SEPARADOS POR ESPACIO, VAN UNO POR ESTROFA. LOS VERSOS
--               QUE EXCEDEN SU GRUPO VAN SIN SANGRÍA. patron="alterno"
--               SANGRA LOS VERSOS PARES DE CADA ESTROFA. EL PRIMER
--               DÍGITO CUENTA (EL patverse DE LaTeX LO IGNORA; ACÁ NO).
-- SALIDA      : JATS Y DOCBOOK: EL MISMO Div verse, SIN ATRIBUTOS, CON
--               UN Div .estrofa POR ESTROFA Y, ADENTRO, UN Div .linea
--               POR VERSO CON EL ATRIBUTO nivel Y UN Plain. LA CLASE
--               en-epigrafe, QUE PONE dos-partes.lua, SE CONSERVA.
--               ODT: UN Para POR ESTROFA, CON LineBreak ENTRE VERSOS Y
--               LA SANGRÍA COMO ESPACIOS (1,5 em POR NIVEL, EL \vgap
--               DEL PDF).
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE dos-partes.lua (QUE MARCA EL VERSO DE UN
--               EPÍGRAFE) Y ANTES DE cite-to-xref.lua,
--               fenced-divs-to-elements-db.lua Y epigrafe-odt.lua.
-- REGLA       : FRENA LA CONVERSIÓN CON UN MENSAJE SI:
--               - EL VERSO TIENE ALGO QUE NO ES UN PÁRRAFO (UNA LISTA,
--                 UN TÍTULO, UNA CITA, OTRO BLOQUE), O ESTÁ DENTRO DE
--                 OTRO VERSO;
--               - EL VERSO ESTÁ VACÍO;
--               - LLEVA UN IDENTIFICADOR, OTRA CLASE U OTRO ATRIBUTO
--                 QUE patron: SE PERDERÍAN SIN AVISO;
--               - EL PATRÓN NO ES alterno NI GRUPOS DE DÍGITOS, O LA
--                 CANTIDAD DE GRUPOS NO ES UNO NI LA DE ESTROFAS.
-- ============================================================

local CLASE = 'verse'
-- LA PONE dos-partes.lua EN EL VERSO DE UN EPÍGRAFE (SC-35, SC-49)
local CLASE_EPIGRAFE = 'en-epigrafe'
local ATRIBUTO_PATRON = 'patron'
local PATRON_ALTERNO = 'alterno'

-- SANGRÍA DEL ODT POR NIVEL: UN ESPACIO EME Y UNO ENE, 1,5 em, EL \vgap
-- DEL PAQUETE verse. EL ODT ES PARA REVISAR: ALCANZA CON QUE SE VEA
local SANGRIA_ODT = '\u{2003}\u{2002}'

-- INLINES CON CONTENIDO QUE NO SE PARTEN EN VERSOS: UNA NOTA TIENE
-- PÁRRAFOS PROPIOS, Y UN SALTO DENTRO DE UNA CITA, UN CÓDIGO O UNA
-- FÓRMULA NO ES UN FIN DE VERSO
local NO_PARTIR = { Note = true, Cite = true, Code = true, Math = true,
                    RawInline = true, Image = true }

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que ubica el bloque
-- Parámetros: el As Block — el bloque; motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(el, motivo)
  local inicio = pandoc.utils.stringify(el):sub(1, 60)
  error('\n[verso] ' .. motivo ..
        '\n  Comienzo del bloque: ' .. inicio .. '\n', 0)
end

-- ============================================
-- Función   : es_salto
-- Propósito : Dice si un inline es un fin de verso
-- Parámetros: inl As Inline
-- Retorna   : boolean — SoftBreak (salto común) o LineBreak (dos espacios
--             o barra invertida al final): los dos cierran el verso
-- ============================================
local function es_salto(inl)
  return inl.t == 'SoftBreak' or inl.t == 'LineBreak'
end

-- ============================================
-- Función   : contiene_salto
-- Propósito : Dice si un inline con contenido tiene un fin de verso adentro
-- Parámetros: inl As Inline
-- Retorna   : boolean
-- ============================================
local function contiene_salto(inl)
  -- SOLO LOS QUE TIENEN INLINES ADENTRO Y SE PUEDEN PARTIR
  if NO_PARTIR[inl.t] or inl.content == nil then return false end
  for _, x in ipairs(inl.content) do
    if es_salto(x) or contiene_salto(x) then return true end
  end
  return false
end

-- ============================================
-- Función   : partir_en_lineas
-- Propósito : Parte los inlines de una estrofa en versos. Una marca que
--             cruza un fin de verso (una bastardilla de dos versos) se
--             parte en dos marcas iguales, una en cada verso: así ningún
--             elemento del canónico cruza un fin de verso
-- Parámetros: inlines As Inlines
-- Retorna   : table — lista de versos; cada uno, una lista de inlines
-- ============================================
local function partir_en_lineas(inlines)
  local lineas = { {} }

  for _, inl in ipairs(inlines) do
    if es_salto(inl) then
      -- UN VERSO NUEVO
      lineas[#lineas + 1] = {}
    elseif contiene_salto(inl) then
      -- LA MARCA SE PARTE: CADA TROZO VA EN UNA COPIA CON EL MISMO TIPO Y
      -- ATRIBUTOS; EL PRIMERO CONTINÚA EL VERSO EN CURSO
      for k, trozo in ipairs(partir_en_lineas(inl.content)) do
        if k > 1 then lineas[#lineas + 1] = {} end
        if #trozo > 0 then
          local copia = inl:clone()
          copia.content = trozo
          table.insert(lineas[#lineas], copia)
        end
      end
    else
      table.insert(lineas[#lineas], inl)
    end
  end

  return lineas
end

-- ============================================
-- Función   : recortar
-- Propósito : Quita los espacios de los bordes de un verso
-- Parámetros: linea As table — lista de inlines
-- Retorna   : table — la misma lista, sin Space al principio ni al final
-- ============================================
local function recortar(linea)
  while #linea > 0 and linea[1].t == 'Space' do table.remove(linea, 1) end
  while #linea > 0 and linea[#linea].t == 'Space' do table.remove(linea) end
  return linea
end

-- ============================================
-- Función   : controlar_atributos
-- Propósito : Frena si el bloque trae algo que la salida perdería
-- Parámetros: el As Div — el verso
-- Retorna   : nada; frena con fallar() si hay algo de más
-- ============================================
local function controlar_atributos(el)
  -- --- 1. IDENTIFICADOR: LA REMISIÓN A UN VERSO QUEDÓ DIFERIDA (SC-49) ---
  if el.identifier ~= '' then
    fallar(el, 'el verso no lleva identificador (#' .. el.identifier .. ')')
  end

  -- --- 2. CLASES: SOLO verse Y LA MARCA DEL EPÍGRAFE ---
  for _, c in ipairs(el.classes) do
    if c ~= CLASE and c ~= CLASE_EPIGRAFE then
      fallar(el, 'el verso no admite la clase .' .. c)
    end
  end

  -- --- 3. ATRIBUTOS: SOLO patron (UN «patrón» CON TILDE TAMBIÉN FRENA) ---
  for clave, _ in pairs(el.attributes) do
    if clave ~= ATRIBUTO_PATRON then
      fallar(el, 'el verso no admite el atributo ' .. clave ..
                 ' (el único es ' .. ATRIBUTO_PATRON .. ')')
    end
  end
end

-- ============================================
-- Función   : leer_patron
-- Propósito : Interpreta el atributo patron y devuelve la regla de sangría
-- Parámetros: el As Div — el verso; n_estrofas As Integer
-- Retorna   : function(estrofa, verso) → Integer — nivel de 0 a 9
-- ============================================
local function leer_patron(el, n_estrofas)
  local texto = el.attributes[ATRIBUTO_PATRON]
  local grupos = {}

  -- --- 1. SIN PATRÓN, TODO A CERO ---
  if texto == nil then
    return function(_, _) return 0 end
  end
  texto = texto:gsub('^%s+', ''):gsub('%s+$', '')

  -- --- 2. alterno: LOS VERSOS PARES, UNA SANGRÍA (EL altverse DE LaTeX) ---
  if texto == PATRON_ALTERNO then
    return function(_, v) return (v % 2 == 0) and 1 or 0 end
  end

  -- --- 3. GRUPOS DE DÍGITOS ---
  for g in texto:gmatch('%S+') do
    if not g:match('^%d+$') then
      fallar(el, 'el patrón «' .. texto .. '» no es «' .. PATRON_ALTERNO ..
                 '» ni grupos de dígitos separados por espacio')
    end
    grupos[#grupos + 1] = g
  end
  if #grupos == 0 then fallar(el, 'el patrón está vacío') end

  -- UN GRUPO PARA TODAS LAS ESTROFAS, O UNO POR ESTROFA: OTRA CANTIDAD ES
  -- UN ERROR DE QUIEN MARCA, Y ADIVINAR QUÉ QUISO SERÍA DEGRADAR EN SILENCIO
  if #grupos ~= 1 and #grupos ~= n_estrofas then
    fallar(el, 'el patrón tiene ' .. #grupos .. ' grupos y el verso ' ..
               n_estrofas .. ' estrofas: tiene que haber un grupo para ' ..
               'todas o uno por estrofa')
  end

  -- --- 4. LA REGLA: EL DÍGITO DEL VERSO; MÁS ALLÁ DEL GRUPO, CERO ---
  return function(e, v)
    local g = (#grupos == 1) and grupos[1] or grupos[e]
    if v > #g then return 0 end
    return tonumber(g:sub(v, v))
  end
end

-- ============================================
-- Función   : estrofas_de
-- Propósito : Controla el contenido y lo parte en estrofas y versos
-- Parámetros: el As Div — el verso
-- Retorna   : table — lista de estrofas; cada una, una lista de versos
-- ============================================
local function estrofas_de(el)
  local estrofas = {}

  for _, b in ipairs(el.content) do
    -- --- 1. SOLO PÁRRAFOS ---
    if b.t == 'Div' and b.classes:includes(CLASE) then
      fallar(el, 'hay un verso dentro de otro verso')
    end
    if b.t ~= 'Para' and b.t ~= 'Plain' then
      -- EL CASO TÍPICO: EL PRIMER VERSO DE UNA ESTROFA EMPIEZA COMO UNA
      -- LISTA, UN TÍTULO O UNA CITA (EN MEDIO DE LA ESTROFA NO PASA: PANDOC
      -- NO ABRE UNA LISTA DENTRO DE UN PÁRRAFO)
      fallar(el, 'solo admite estrofas, párrafos separados por una línea ' ..
                 'en blanco (hay un ' .. b.t .. '). Si una estrofa empieza ' ..
                 'con «- », «# », «> » o «1. », Pandoc la lee como lista, ' ..
                 'título o cita: escribir \\- , \\# , \\> o 1\\. ')
    end

    -- --- 2. LOS VERSOS DE LA ESTROFA, SIN LOS VACÍOS ---
    local versos = {}
    for _, linea in ipairs(partir_en_lineas(b.content)) do
      linea = recortar(linea)
      if #linea > 0 then versos[#versos + 1] = linea end
    end
    if #versos > 0 then estrofas[#estrofas + 1] = versos end
  end

  if #estrofas == 0 then fallar(el, 'el verso está vacío') end
  return estrofas
end

-- ============================================
-- Función   : salida_xml
-- Propósito : Arma la forma normalizada que leen los serializadores
-- Parámetros: el As Div; estrofas As table; nivel_de As function
-- Retorna   : Div — verse, con .estrofa y .linea (nivel) adentro
-- ============================================
local function salida_xml(el, estrofas, nivel_de)
  local hijos = {}
  local clases = { CLASE }

  for e, versos in ipairs(estrofas) do
    local lineas = {}
    for v, inlines in ipairs(versos) do
      lineas[#lineas + 1] = pandoc.Div({ pandoc.Plain(inlines) },
        pandoc.Attr('', { 'linea' }, { nivel = tostring(nivel_de(e, v)) }))
    end
    hijos[#hijos + 1] = pandoc.Div(lineas, pandoc.Attr('', { 'estrofa' }))
  end

  -- LA MARCA DEL EPÍGRAFE PASA: CON ELLA EL SERIALIZADOR DE DOCBOOK
  -- EMITE LAS ESTROFAS SIN EL <blockquote>, QUE <epigraph> NO ADMITE
  if el.classes:includes(CLASE_EPIGRAFE) then clases[#clases + 1] = CLASE_EPIGRAFE end
  return pandoc.Div(hijos, pandoc.Attr('', clases))
end

-- ============================================
-- Función   : salida_odt
-- Propósito : Resuelve el verso en párrafos para el ODT
-- Parámetros: estrofas As table; nivel_de As function
-- Retorna   : table — un Para por estrofa
-- ============================================
local function salida_odt(estrofas, nivel_de)
  local parrafos = {}

  for e, versos in ipairs(estrofas) do
    local inlines = {}
    for v, linea in ipairs(versos) do
      if v > 1 then inlines[#inlines + 1] = pandoc.LineBreak() end
      local n = nivel_de(e, v)
      if n > 0 then inlines[#inlines + 1] = pandoc.Str(SANGRIA_ODT:rep(n)) end
      for _, inl in ipairs(linea) do inlines[#inlines + 1] = inl end
    end
    parrafos[#parrafos + 1] = pandoc.Para(inlines)
  end

  return parrafos
end

-- ============================================
-- Función   : Div
-- Propósito : Controla y normaliza cada verso
-- Parámetros: el As Div
-- Retorna   : Div (XML) o lista de Para (ODT); nil si no es un verso
-- ============================================
function Div(el)
  local estrofas, nivel_de

  if not el.classes:includes(CLASE) then return nil end

  -- --- 1. FORMATO: SOLO LAS TRES CADENAS DEL PROYECTO ---
  if FORMAT ~= 'jats' and FORMAT ~= 'docbook5' and FORMAT ~= 'odt' then
    error('\n[verso] Formato de salida no previsto: ' .. FORMAT .. '\n', 0)
  end

  -- --- 2. CONTROLES ---
  controlar_atributos(el)
  estrofas = estrofas_de(el)
  nivel_de = leer_patron(el, #estrofas)

  -- --- 3. SALIDA SEGÚN EL FORMATO ---
  if FORMAT == 'odt' then return salida_odt(estrofas, nivel_de) end
  return salida_xml(el, estrofas, nivel_de)
end
