-- ============================================================
-- FILTRO      : nota-simbolo.lua
-- PROPÓSITO   : TRADUCE LA NOTA CON SÍMBOLO DE UN TÍTULO DE SECCIÓN
--               (## Título\footnote{*}{Texto de la nota.}) A UNA NOTA
--               DE PANDOC MARCADA CON SU SÍMBOLO. EL SÍMBOLO LO ELIGE
--               QUIEN EDITA, DE UN DICCIONARIO CERRADO (LA SECUENCIA
--               DE LA AMS SIN ‖), Y NO CONSUME NÚMERO: LAS NOTAS
--               NUMERADAS SIGUEN 1, 2, 3 (SC-86).
-- ENTRADA     : ## Título\footnote{*}{Texto con *cursiva* y [@cita].}
--               PANDOC LEE \footnote{*} COMO LaTeX CRUDO Y EL SEGUNDO
--               PAR DE LLAVES COMO MARKDOWN, CON LAS LLAVES COMO TEXTO
--               (GV-189): RawInline "\footnote{*}", Str "{Texto", …,
--               Str "y", Cite, Str ".}"
-- SALIDA      : Note [Para [RawInline docbook "<?gb-nota-simbolo ast?>",
--               …el texto…]]. cite-to-biblioref-db.lua, QUE SERIALIZA LAS
--               NOTAS, LEE LA MARCA Y ESCRIBE <footnote label="ast">
--               (DocBook 5.2: label ES NMTOKEN, Y «*» NO VALIDA, GV-191).
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN LA CADENA DEL LIBRO, DESPUÉS DE volada.lua Y ANTES DE
--               corte-titulo.lua: UNA \\ DEL TEXTO DE LA NOTA NO ES UN
--               CORTE DEL TÍTULO. ANTES DE cite-to-biblioref-db.lua, QUE
--               SERIALIZA LAS NOTAS, Y DE cifras, indice Y siglas, QUE ASÍ
--               ENCUENTRAN EL TEXTO ADENTRO DE LA NOTA.
-- REGLA       : SOLO EN UN TÍTULO DE SECCIÓN (## Y SIGUIENTES: EL # DEL
--               CAPÍTULO SALE DE LA BASE, SC-28). UNA SOLA NOTA POR TÍTULO,
--               NUMERADA O CON SÍMBOLO: titlesec GUARDA UNA SOLA (GV-190).
--               FRENA CON UN SÍMBOLO FUERA DEL DICCIONARIO, SIN EL SEGUNDO
--               PAR DE LLAVES, CON UN ESPACIO ENTRE LOS DOS, SIN LA LLAVE
--               DE CIERRE, CON EL TEXTO VACÍO O CON UNA NOTA ADENTRO.
-- GEMELOS     : EL DICCIONARIO ES EL DE nota-simbolo-comun.xsl Y EL DE
--               \gbSimboloNota (preambulo-contrato.tex). UN CAMBIO VA EN
--               LOS TRES, EN EL MISMO ORDEN.
-- ============================================================

-- EL DICCIONARIO: LO QUE SE ESCRIBE ENTRE LAS PRIMERAS LLAVES → EL NOMBRE
-- QUE VA AL label DE DocBook. EL ORDEN DEL ÍNDICE (1 A 8) LO FIJA
-- nota-simbolo-comun.xsl
local DICCIONARIO = {
  ['*']            = 'ast',
  ['\\dag']        = 'dag',
  ['\\ddag']       = 'ddag',
  ['\\S']          = 'S',
  ['\\P']          = 'P',
  ['**']           = 'ast2',
  ['\\dag\\dag']   = 'dag2',
  ['\\ddag\\ddag'] = 'ddag2',
}

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  La nota con símbolo va en un título de sección, pegada al texto:' ..
  '\n  «## Título\\footnote{*}{Texto de la nota.}». Los símbolos son' ..
  '\n  *  \\dag  \\ddag  \\S  \\P  **  \\dag\\dag  \\ddag\\ddag.' ..
  '\n  Una nota numerada se escribe [^1] o ^[texto].'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: donde As Inlines|nil — el título, para el mensaje
--             motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(donde, motivo)
  local sDonde = ''
  if donde then sDonde = ' «' .. pandoc.utils.stringify(donde) .. '»' end
  error('\n[nota-simbolo]' .. sDonde .. ': ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : simbolo_de
-- Propósito : Dice si un elemento es la apertura \footnote{…} y da lo que
--             está entre las llaves
-- Parámetros: el As Inline
-- Retorna   : string|nil — el contenido de las llaves; nil si no es apertura
-- ============================================
local function simbolo_de(el)
  if not el or el.t ~= 'RawInline' then return nil end
  if el.format ~= 'tex' and el.format ~= 'latex' then return nil end
  -- CON EL SEGUNDO PAR DE LLAVES VACÍO, PANDOC LEE LAS DOS COMO LaTeX
  -- CRUDO: «\footnote{*}{}» LLEGA ENTERO EN UN RawInline (GV-189)
  if el.text:match('^\\footnote%b{}%b{}$') then
    fallar(nil, '«' .. el.text .. '»: el texto de la nota está vacío.')
  end
  return el.text:match('^\\footnote(%b{})$') and el.text:match('^\\footnote{(.*)}$')
end

-- ============================================
-- Función   : recortar
-- Propósito : Quita los espacios del principio y del final de un texto
--             de nota
-- Parámetros: aInlines As Inlines
-- Retorna   : Inlines — los mismos, sin espacios en los bordes
-- ============================================
local function recortar(aInlines)
  while #aInlines > 0 and (aInlines[1].t == 'Space' or aInlines[1].t == 'SoftBreak') do
    aInlines:remove(1)
  end
  while #aInlines > 0 and (aInlines[#aInlines].t == 'Space' or aInlines[#aInlines].t == 'SoftBreak') do
    aInlines:remove(#aInlines)
  end
  return aInlines
end

-- ============================================
-- Función   : traducir_titulo
-- Propósito : Reemplaza cada \footnote{símbolo}{texto} de un título por
--             una nota de Pandoc con la marca del símbolo
-- Parámetros: titulo As Inlines — el contenido del Header
-- Retorna   : Inlines|nil — el título traducido; nil si no tenía ninguna
-- ============================================
local function traducir_titulo(titulo)
  local resultado, contenido, i, j, el, x, sSimbolo, sNombre
  local iNivel, bCerrado, sBuf, sResto, iDesde, c, bHubo

  resultado = pandoc.Inlines({})
  bHubo = false
  i = 1
  while i <= #titulo do
    el = titulo[i]
    sSimbolo = simbolo_de(el)
    if not sSimbolo then
      resultado:insert(el)
      i = i + 1
    else
      bHubo = true

      -- --- 1. EL SÍMBOLO, DEL DICCIONARIO ---
      sNombre = DICCIONARIO[sSimbolo]
      if not sNombre then
        fallar(titulo, '«' .. sSimbolo .. '» no es un símbolo de nota.')
      end

      -- --- 2. EL TEXTO EMPIEZA EN LA LLAVE QUE SIGUE, PEGADA ---
      x = titulo[i + 1]
      if x and (x.t == 'Space' or x.t == 'SoftBreak') then
        fallar(titulo, 'hay un espacio entre \\footnote{' .. sSimbolo .. '} y el texto de la nota.')
      end
      if not x or x.t ~= 'Str' or x.text:sub(1, 1) ~= '{' then
        fallar(titulo, 'a \\footnote{' .. sSimbolo .. '} le falta el texto de la nota entre llaves.')
      end

      -- --- 3. HASTA LA LLAVE QUE CIERRA, CONTANDO LAS QUE SE ABREN ---
      -- LAS LLAVES SOLO SE CUENTAN EN LOS Str DEL PRIMER NIVEL: SON LAS QUE
      -- PANDOC DEJÓ COMO TEXTO (GV-189). SE RECORRE POR BYTES: LA LLAVE ES
      -- ASCII Y LOS TRAMOS QUE QUEDAN SIGUEN SIENDO UTF-8 VÁLIDO
      contenido = pandoc.Inlines({})
      iNivel = 0
      bCerrado = false
      sResto = ''
      j = i + 1
      while j <= #titulo and not bCerrado do
        x = titulo[j]
        if x.t == 'Str' then
          sBuf = ''
          iDesde = 1
          if j == i + 1 then
            iNivel = 1
            iDesde = 2
          end
          for k = iDesde, #x.text do
            c = x.text:sub(k, k)
            if c == '{' then
              iNivel = iNivel + 1
            elseif c == '}' then
              iNivel = iNivel - 1
              if iNivel == 0 then
                sResto = x.text:sub(k + 1)
                bCerrado = true
                break
              end
            end
            sBuf = sBuf .. c
          end
          if sBuf ~= '' then contenido:insert(pandoc.Str(sBuf)) end
        elseif x.t == 'Note' then
          -- DocBook NO ADMITE UNA NOTA DENTRO DE OTRA (RNG, Schematron)
          fallar(titulo, 'hay una nota dentro del texto de la nota.')
        else
          contenido:insert(x)
        end
        j = j + 1
      end

      -- --- 4. LO QUE FALTA O SOBRA ---
      -- UN TÍTULO ES UNA SOLA LÍNEA: UNA NOTA QUE SIGUE EN EL RENGLÓN DE
      -- ABAJO QUEDA SIN LA LLAVE DE CIERRE (GV-189)
      if not bCerrado then
        fallar(titulo, 'falta la llave que cierra el texto de la nota (la nota va entera en la línea del título).')
      end
      contenido = recortar(contenido)
      if #contenido == 0 then
        fallar(titulo, 'el texto de la nota está vacío.')
      end

      -- --- 5. LA NOTA, CON LA MARCA DEL SÍMBOLO AL COMIENZO ---
      contenido:insert(1, pandoc.RawInline('docbook', '<?gb-nota-simbolo ' .. sNombre .. '?>'))
      resultado:insert(pandoc.Note({ pandoc.Para(contenido) }))
      if sResto ~= '' then resultado:insert(pandoc.Str(sResto)) end
      i = j
    end
  end

  if not bHubo then return nil end
  return resultado
end

-- ============================================
-- Función   : identificador_auto
-- Propósito : El identificador que Pandoc arma solo para un título
--             (extensión auto_identifiers): sin formato ni notas, solo
--             letras, cifras, _ - y ., espacios a guiones, en minúsculas,
--             desde la primera letra. Sirve para saber si el que trae el
--             título lo armó Pandoc con el texto de la nota adentro.
--             No reproduce los sufijos -1, -2 de los repetidos: en ese
--             caso no coincide y el identificador se deja como está.
-- Parámetros: aInlines As Inlines
-- Retorna   : string
-- ============================================
local function identificador_auto(aInlines)
  local s, sSalida, c

  -- --- 1. EL TEXTO, SIN NOTAS NI LaTeX CRUDO (stringify LOS DESCARTA) ---
  s = pandoc.text.lower(pandoc.utils.stringify(aInlines))

  -- --- 2. CARÁCTER POR CARÁCTER: LETRAS Y CIFRAS DE CUALQUIER ALFABETO ---
  -- utf8.codes DA CADA CARÁCTER; UNO DE MÁS DE UN BYTE SE CONSERVA COMO
  -- LETRA. SI NO LO ERA, EL RESULTADO NO COINCIDE CON EL DE PANDOC Y EL
  -- IDENTIFICADOR QUEDA COMO ESTABA: EL ERROR ES SEGURO
  sSalida = ''
  for _, cp in utf8.codes(s) do
    c = utf8.char(cp)
    if c:match('^[%w_%-%.]$') or cp > 127 then
      sSalida = sSalida .. c
    elseif c:match('^%s$') then
      sSalida = sSalida .. '-'
    end
  end

  -- --- 3. DESDE LA PRIMERA LETRA ---
  sSalida = sSalida:gsub('^[^%a\128-\255]+', '')
  if sSalida == '' then return 'section' end
  return sSalida
end

-- ============================================
-- Función   : contar_notas
-- Propósito : Cuántas notas tiene el primer nivel de un título
-- Parámetros: aInlines As Inlines
-- Retorna   : number
-- ============================================
local function contar_notas(aInlines)
  local n = 0
  for _, el in ipairs(aInlines) do
    if el.t == 'Note' then n = n + 1 end
  end
  return n
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Traduce las notas con símbolo de los títulos y frena las
--             que están fuera de un título de sección
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con las notas traducidas
-- ============================================
function Pandoc(doc)

  -- --- 1. FORMATO: SOLO LA CADENA DEL LIBRO (LAS REVISTAS, MÁS ADELANTE) ---
  if FORMAT ~= 'docbook5' then
    error('\n[nota-simbolo] Formato de salida no previsto: ' .. FORMAT ..
          ' (la nota con símbolo es, por ahora, solo de libros)\n', 0)
  end

  -- --- 2. LOS TÍTULOS ---
  doc = doc:walk({ Header = function(h)
    local nuevo, sAntes

    -- EL # DEL CAPÍTULO NO LLEGA AL CANÓNICO: SU TÍTULO SALE DE LA BASE (SC-28)
    if h.level == 1 then
      for _, el in ipairs(h.content) do
        if simbolo_de(el) then
          fallar(h.content, 'la nota con símbolo va en los títulos de sección (## y siguientes), no en el del capítulo.')
        end
      end
    end

    nuevo = traducir_titulo(h.content)

    -- UNA SOLA NOTA POR TÍTULO, NUMERADA O CON SÍMBOLO: titlesec GUARDA
    -- UNA SOLA Y LA OTRA SE PIERDE SIN AVISO (GV-190, SC-29)
    if contar_notas(nuevo or h.content) > 1 then
      fallar(h.content, 'el título tiene más de una nota: va una sola por título.')
    end
    if not nuevo then return nil end

    -- EL IDENTIFICADOR QUE ARMÓ PANDOC INCLUYE EL TEXTO DE LA NOTA, QUE
    -- PARA ÉL ERA TEXTO DEL TÍTULO. SI ES EL AUTOMÁTICO, SE REARMA SIN ELLA
    sAntes = identificador_auto(h.content)
    if h.identifier == sAntes then
      h.identifier = identificador_auto(nuevo)
    end
    h.content = nuevo
    return h
  end })

  -- --- 3. FUERA DE UN TÍTULO: LAS QUE QUEDAN SIN TRADUCIR ---
  -- LAS DE LOS TÍTULOS YA SON NOTAS; UNA APERTURA QUE QUEDA ESTÁ EN EL TEXTO
  doc:walk({ RawInline = function(r)
    if (r.format == 'tex' or r.format == 'latex') and r.text:sub(1, 10) == '\\footnote{' then
      simbolo_de(r)
      fallar(nil, '«' .. r.text .. '» está fuera de un título: la nota con símbolo va solo en un título de sección.')
    end
  end })

  return doc
end
