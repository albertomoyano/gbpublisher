-- ============================================================
-- FILTRO      : glosario.lua
-- PROPÓSITO   : EL GLOSARIO DEL LIBRO (PIEZA glosario): LA LISTA DE
--               DEFINICIONES DEL .md PASA A LAS ENTRADAS NATIVAS DE DocBook,
--               ORDENADAS Y SEPARADAS POR LETRA (DECISIONES DE ALBERTO,
--               31/10). SIN ESTE FILTRO, PANDOC LA ESCRIBE COMO
--               <variablelist> Y DESCARTA EN SILENCIO LOS [x]{.vease}.
-- ENTRADA     : EN EL .md DE LA PIEZA glosario, UNA INTRODUCCIÓN OPCIONAL
--               Y DESPUÉS LAS ENTRADAS:
--                 *Travelling*
--                 :   Desplazamiento de la cámara. Véase también
--                     [plano secuencia]{.vease}.
--
--                 Traveling
--                 :   [Travelling]{.vease}
-- SALIDA      : DOCBOOK (LIBRO). EL CUERPO DE <glossary role="glosario">,
--               QUE ESCRIBE ensamblar-capitulo-canonico.xsl:
--                 <glossdiv><title>T</title>
--                   <glossentry xml:id="gl-travelling">
--                     <glossterm><emphasis>Travelling</emphasis></glossterm>
--                     <glossdef><para>… <glossterm linkend="gl-plano-secuencia">
--                       plano secuencia</glossterm>.</para></glossdef>
--                   </glossentry>
--                   <glossentry xml:id="gl-traveling">
--                     <glossterm>Traveling</glossterm>
--                     <glosssee otherterm="gl-travelling">Travelling</glosssee>
--                   </glossentry>
--                 </glossdiv>
--               UNA ENTRADA CUYA DEFINICIÓN ES SOLO UN [x]{.vease} ES UNA
--               REMISIÓN (<glosssee>): LA SALIDA ESCRIBE «véase». DENTRO DE
--               UNA DEFINICIÓN, EL [x]{.vease} ES UN ENLACE A LA ENTRADA, CON
--               LA REDACCIÓN DEL AUTOR.
-- ORDEN       : ALFABÉTICO, SIN DISTINGUIR MAYÚSCULAS NI TILDES; LA ñ VA
--               DESPUÉS DE LA n. LOS SIGNOS DEL COMIENZO (« ¿ ¡ " ' ( *) NO
--               CUENTAN. LAS CIFRAS VAN ANTES QUE LAS LETRAS, EN «0–9».
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : AL FINAL DE LA CADENA DEL LIBRO, DESPUÉS DE
--               fenced-divs-to-elements-db.lua: LAS DEFINICIONES SE
--               SERIALIZAN CON pandoc.write, Y LO QUE LLEVAN ADENTRO (CITAS,
--               SIGLAS, CIFRAS, VOLADAS) YA TIENE QUE ESTAR TRADUCIDO.
--               REQUIERE -M gb-tipo-pieza: SOLO ACTÚA EN LA PIEZA glosario.
--               EN LAS DEMÁS, UNA LISTA DE DEFINICIONES SIGUE SIENDO UNA
--               <variablelist>, Y UN [x]{.vease} FRENA.
-- REGLA       : LO QUE NO CUMPLE FRENA LA CONVERSIÓN CON UN MENSAJE: NUNCA
--               SE DEGRADA EN SILENCIO.
--               - EN EL GLOSARIO NO VAN TÍTULOS: LAS LETRAS LAS PONE EL
--                 FILTRO, Y <glossary> NO ADMITE SECCIONES.
--               - LA INTRODUCCIÓN VA ANTES DE LA PRIMERA ENTRADA; DESPUÉS,
--                 SOLO ENTRADAS.
--               - UN TÉRMINO NO SE REPITE.
--               - UN [x]{.vease} REMITE A UN TÉRMINO DEL GLOSARIO, Y A UNO
--                 SOLO.
--               - SIN ENTRADAS NO HAY GLOSARIO.
-- ============================================================

-- EL TIPO DE LA PIEZA (capitulos.tipo_capitulo)
local TIPO_GLOSARIO = 'glosario'

-- LA CLASE DE LA REMISIÓN
local CLASE_VEASE = 'vease'

-- EL PREFIJO DE LOS xml:id DE LAS ENTRADAS. ensamblar-capitulo-canonico.xsl
-- LE ANTEPONE EL id DE LA PIEZA, COMO A LOS DEMÁS
local PREFIJO_ID = 'gl-'

-- LAS VOCALES CON TILDE Y DIÉRESIS, SIN ELLAS. LA ñ NO: ES OTRA LETRA
local SIN_TILDE = {
  ['á'] = 'a', ['à'] = 'a', ['â'] = 'a', ['ä'] = 'a', ['ã'] = 'a',
  ['é'] = 'e', ['è'] = 'e', ['ê'] = 'e', ['ë'] = 'e',
  ['í'] = 'i', ['ì'] = 'i', ['î'] = 'i', ['ï'] = 'i',
  ['ó'] = 'o', ['ò'] = 'o', ['ô'] = 'o', ['ö'] = 'o', ['õ'] = 'o',
  ['ú'] = 'u', ['ù'] = 'u', ['û'] = 'u', ['ü'] = 'u',
  ['ç'] = 'c',
}

-- LOS SIGNOS QUE NO CUENTAN AL COMIENZO DE UN TÉRMINO, PARA ORDENAR
local SIGNOS_INICIALES = {
  ' ', '«', '»', '“', '”', '‘', '’', '"', "'", '¿', '¡', '(', '[', '*', '-', '—', '–',
}

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  El glosario es una lista de definiciones: el término en una línea y' ..
  '\n  la definición debajo, empezando con «:   ». Antes de la primera' ..
  '\n  entrada puede ir una introducción. Una remisión a otro término se' ..
  '\n  escribe [término]{.vease}: sola en la definición es un «véase»;' ..
  '\n  dentro de un texto, un enlace.'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo)
  error('\n[glosario] ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : es_vease
-- Propósito : Dice si un elemento es una remisión [x]{.vease}
-- Parámetros: el As Inline
-- Retorna   : boolean
-- ============================================
local function es_vease(el)
  return el.t == 'Span' and el.classes:includes(CLASE_VEASE)
end

-- ============================================
-- Función   : clave
-- Propósito : La forma de un término para ordenar, comparar y buscar: sin
--             mayúsculas, sin tildes, sin los signos del comienzo, con los
--             espacios simples. La ñ queda como «n~»: así va después de la
--             n y antes de la o (el ~ es mayor que las letras en ASCII)
-- Parámetros: sTexto As String — el término, en texto plano
-- Retorna   : String
-- ============================================
local function clave(sTexto)
  local aCar, s

  -- --- 1. MINÚSCULAS Y ESPACIOS ---
  s = pandoc.text.lower(sTexto):gsub('%s+', ' '):gsub('^ ', ''):gsub(' $', '')

  -- --- 2. CARÁCTER POR CARÁCTER: TILDES Y ñ ---
  aCar = {}
  for _, c in utf8.codes(s) do
    local ch = utf8.char(c)
    if ch == 'ñ' then
      table.insert(aCar, 'n~')
    else
      table.insert(aCar, SIN_TILDE[ch] or ch)
    end
  end
  s = table.concat(aCar)

  -- --- 3. LOS SIGNOS DEL COMIENZO NO CUENTAN ---
  -- UNO POR UNO HASTA QUE NO QUEDE NINGUNO: VARIOS SON DE MÁS DE UN BYTE
  local bCambio = true
  while bCambio do
    bCambio = false
    for _, sSigno in ipairs(SIGNOS_INICIALES) do
      if s:sub(1, #sSigno) == sSigno then
        s = s:sub(#sSigno + 1)
        bCambio = true
      end
    end
  end
  return s
end

-- ============================================
-- Función   : letra
-- Propósito : La letra de la división (glossdiv) de un término
-- Parámetros: sClave As String — la clave del término
-- Retorna   : String — «A»…«Z», «Ñ», o «0–9» para las cifras
-- ============================================
local function letra(sClave)
  local c = sClave:sub(1, 1)
  if c:match('%d') then return '0–9' end
  if sClave:sub(1, 2) == 'n~' then return 'Ñ' end
  if c:match('%a') then return c:upper() end
  return nil
end

-- ============================================
-- Función   : id_de
-- Propósito : El xml:id de una entrada, en ASCII: la clave con todo lo que
--             no es letra o cifra pasado a guiones
-- Parámetros: sClave As String
-- Retorna   : String
-- ============================================
local function id_de(sClave)
  local s = sClave:gsub('n~', 'n'):gsub('[^%w]+', '-'):gsub('^%-+', ''):gsub('%-+$', '')
  return PREFIJO_ID .. s
end

-- ============================================
-- Función   : xml
-- Propósito : Escapa un texto para un atributo del canónico
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function xml(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

-- ============================================
-- Función   : docbook_bloques
-- Propósito : Una lista de bloques en DocBook, con el escritor de pandoc
--             (lo crudo docbook pasa tal cual)
-- Parámetros: aBloques As Blocks
-- Retorna   : String
-- ============================================
local function docbook_bloques(aBloques)
  local s = pandoc.write(pandoc.Pandoc(aBloques), 'docbook5', PANDOC_WRITER_OPTIONS)
  return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- ============================================
-- Función   : docbook_linea
-- Propósito : Una lista de inlines en DocBook, sin el <para> que pone el
--             escritor
-- Parámetros: aInlines As Inlines
-- Retorna   : String
-- ============================================
local function docbook_linea(aInlines)
  local s = docbook_bloques({ pandoc.Para(aInlines) })
  s = s:gsub('^<para>%s*', ''):gsub('%s*</para>$', '')
  return s
end

-- ============================================
-- Función   : sola_remision
-- Propósito : Si una definición es solo un [x]{.vease} (con un punto final
--             como mucho), la devuelve
-- Parámetros: aDef As Blocks — los bloques de una definición
-- Retorna   : Span o nil
-- ============================================
local function sola_remision(aDef)
  local oSpan

  if #aDef ~= 1 then return nil end
  if aDef[1].t ~= 'Para' and aDef[1].t ~= 'Plain' then return nil end
  for _, el in ipairs(aDef[1].content) do
    if es_vease(el) and oSpan == nil then
      oSpan = el
    elseif el.t == 'Space' or el.t == 'SoftBreak' or (el.t == 'Str' and el.text == '.') then
      -- PERMITIDO ALREDEDOR DE LA REMISIÓN
    else
      return nil
    end
  end
  return oSpan
end

-- ============================================
-- Función   : controlar_fuera
-- Propósito : En una pieza que no es el glosario, un [x]{.vease} frena: el
--             escritor DocBook lo descartaría en silencio
-- Parámetros: doc As Pandoc
-- Retorna   : nada
-- ============================================
local function controlar_fuera(doc)
  doc:walk({ Span = function(s)
    if es_vease(s) then
      fallar('«[' .. pandoc.utils.stringify(s) .. ']{.vease}» está fuera del ' ..
             'glosario: la remisión solo va en la pieza glosario.')
    end
  end })
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Arma el glosario: introducción, entradas ordenadas y divididas
--             por letra, remisiones resueltas
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con el glosario en DocBook
-- ============================================
function Pandoc(doc)
  local sTipo, aIntro, aEntradas, tPorClave, bEntradas, oEntrada, sClave,
        aSalida, sLetraActual, aDiv, oRemision, oDestino, aHuellas

  -- --- 1. FORMATO Y PIEZA ---
  if FORMAT ~= 'docbook5' then
    error('\n[glosario] Formato de salida no previsto: ' .. FORMAT ..
          ' (el glosario es solo de libros)\n', 0)
  end
  sTipo = doc.meta['gb-tipo-pieza'] and pandoc.utils.stringify(doc.meta['gb-tipo-pieza']) or ''
  if sTipo ~= TIPO_GLOSARIO then
    controlar_fuera(doc)
    return doc
  end

  -- --- 2. INTRODUCCIÓN Y ENTRADAS ---
  aIntro, aEntradas, tPorClave, bEntradas, aHuellas = {}, {}, {}, false, {}
  for _, b in ipairs(doc.blocks) do
    if b.t == 'DefinitionList' then
      bEntradas = true
      for _, item in ipairs(b.content) do
        local aTermino, aDefs = item[1], item[2]
        local sPlano = pandoc.utils.stringify(aTermino)
        sClave = clave(sPlano)
        if sClave == '' then
          fallar('Un término vacío o hecho solo de signos: «' .. sPlano .. '».')
        end
        if not letra(sClave) then
          fallar('«' .. sPlano .. '» no empieza con una letra ni con una cifra: ' ..
                 'no hay en qué letra ponerlo.')
        end
        if tPorClave[sClave] then
          fallar('«' .. sPlano .. '» está dos veces (también como «' ..
                 tPorClave[sClave].plano .. '»): un término va una sola vez.')
        end
        oEntrada = { termino = aTermino, defs = aDefs, plano = sPlano,
                     clave = sClave, id = id_de(sClave) }
        tPorClave[sClave] = oEntrada
        table.insert(aEntradas, oEntrada)
      end
    elseif b.t == 'RawBlock' and b.format == 'docbook' and
           b.text:gsub('<%?gb%-[^?]*%?>', ''):match('^%s*$') then
      -- LAS HUELLAS QUE DEJAN OTROS FILTROS AL FINAL (siglas.lua): VAN
      -- AL FINAL DEL CUERPO, DESPUÉS DE LAS ENTRADAS
      table.insert(aHuellas, b)
    elseif b.t == 'Header' then
      fallar('El título «' .. pandoc.utils.stringify(b) .. '» está en el glosario: ' ..
             'no lleva títulos (las letras las pone la aplicación).')
    elseif bEntradas then
      fallar('Hay texto después de las entradas («' ..
             pandoc.utils.stringify(b):sub(1, 60) .. '…»): la introducción ' ..
             'va antes de la primera entrada, y después solo entradas.')
    else
      table.insert(aIntro, b)
    end
  end
  if #aEntradas == 0 then
    fallar('El glosario no tiene entradas.')
  end

  -- DOS CLAVES DISTINTAS NO PUEDEN DAR EL MISMO id
  local tIds = {}
  for _, e in ipairs(aEntradas) do
    if tIds[e.id] then
      fallar('«' .. e.plano .. '» y «' .. tIds[e.id] .. '» se escriben distinto ' ..
             'pero dan el mismo identificador: diferencialos.')
    end
    tIds[e.id] = e.plano
  end

  -- ============================================
  -- Función   : destino
  -- Propósito : La entrada a la que remite un [x]{.vease}
  -- Parámetros: oSpan As Span
  -- Retorna   : Table — la entrada; frena si no existe
  -- ============================================
  local function destino(oSpan)
    local sTexto = pandoc.utils.stringify(oSpan)
    local o = tPorClave[clave(sTexto)]
    if not o then
      fallar('«[' .. sTexto .. ']{.vease}» remite a un término que no está en ' ..
             'el glosario.')
    end
    return o
  end

  -- --- 3. LAS REMISIONES DENTRO DE LAS DEFINICIONES: ENLACES ---
  for _, e in ipairs(aEntradas) do
    oRemision = (#e.defs == 1) and sola_remision(e.defs[1]) or nil
    if oRemision then
      oDestino = destino(oRemision)
      if oDestino == e then
        fallar('«' .. e.plano .. '» remite a sí mismo.')
      end
      e.see = oDestino
      e.see_texto = docbook_linea(oRemision.content)
    else
      for k, aDef in ipairs(e.defs) do
        e.defs[k] = pandoc.Blocks(aDef):walk({ Span = function(s)
          if es_vease(s) then
            local o = destino(s)
            local aIn = pandoc.Inlines({ pandoc.RawInline('docbook',
              '<glossterm linkend="' .. o.id .. '">') })
            aIn:extend(s.content)
            aIn:insert(pandoc.RawInline('docbook', '</glossterm>'))
            return aIn
          end
        end })
      end
    end
  end

  -- --- 4. ORDEN ---
  table.sort(aEntradas, function(a, b)
    if a.clave ~= b.clave then return a.clave < b.clave end
    return a.plano < b.plano
  end)

  -- --- 5. EL DocBook: INTRODUCCIÓN Y UNA DIVISIÓN POR LETRA ---
  aSalida = {}
  for _, b in ipairs(aIntro) do table.insert(aSalida, b) end
  aDiv = {}
  sLetraActual = nil
  for _, e in ipairs(aEntradas) do
    local sLetra = letra(e.clave)
    if sLetra ~= sLetraActual then
      if sLetraActual then table.insert(aDiv, '</glossdiv>') end
      table.insert(aDiv, '<glossdiv><title>' .. xml(sLetra) .. '</title>')
      sLetraActual = sLetra
    end
    local aPartes = { '<glossentry xml:id="' .. e.id .. '">',
      '<glossterm>' .. docbook_linea(e.termino) .. '</glossterm>' }
    if e.see then
      table.insert(aPartes, '<glosssee otherterm="' .. e.see.id .. '">' ..
        e.see_texto .. '</glosssee>')
    else
      for _, aDef in ipairs(e.defs) do
        -- UNA LISTA COMPACTA TRAE Plain, QUE EL ESCRITOR SACA SIN <para>:
        -- <glossdef> PIDE BLOQUES
        aDef = pandoc.Blocks(aDef):walk({ Plain = function(p) return pandoc.Para(p.content) end })
        table.insert(aPartes, '<glossdef>' .. docbook_bloques(aDef) .. '</glossdef>')
      end
    end
    table.insert(aPartes, '</glossentry>')
    table.insert(aDiv, table.concat(aPartes, '\n'))
  end
  table.insert(aDiv, '</glossdiv>')
  table.insert(aSalida, pandoc.RawBlock('docbook', table.concat(aDiv, '\n')))
  for _, b in ipairs(aHuellas) do table.insert(aSalida, b) end

  doc.blocks = aSalida
  return doc
end
