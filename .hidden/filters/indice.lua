-- ============================================================
-- FILTRO      : indice.lua
-- PROPÓSITO   : TRADUCE LAS MARCAS DE ÍNDICE DEL .md (SC-77) A
--               <indexterm> EN EL CANÓNICO DEL LIBRO. SIN ESTE FILTRO,
--               PANDOC LEE \index COMO LaTeX CRUDO Y EL ESCRITOR
--               DocBook LO DESCARTA SIN AVISO (GV-116).
-- ENTRADA     : \index[onomastico]{Borges, Jorge Luis!infancia}
--               \index[concepto]{democracia!liberal|(} … |)}
--               \index[concepto]{universidad|see{educación superior}}
--               \index[concepto]{educación superior|seealso{universidad}}
--               \index[concepto]{educación superior|textbf}
--               \index[onomastico]{Torre Lisandro@Torre, Lisandro de la}
--               PANDOC LA LEE COMO UN RawInline tex ENTERO, EN CUALQUIER
--               LUGAR, SIN INTERPRETAR LO DE ADENTRO (GV-157).
-- SALIDA      : DOCBOOK (LIBRO)
--               <indexterm type="onomastico" xml:id="idx-1">
--                 <primary>Borges, Jorge Luis</primary>
--                 <secondary>infancia</secondary></indexterm>
--               RANGO: class="startofrange" CON SU xml:id, Y AL CIERRE
--               <indexterm class="endofrange" startref="idx-N"/>.
--               PRINCIPAL: significance="preferred". REMISIONES: <see>
--               Y <seealso>. CLAVE DE ORDEN: @sortas DEL NIVEL.
--               CADA indexterm LLEVA SU xml:id AUNQUE HOY NADA LO USE:
--               DEJA ABIERTO UN ÍNDICE CON ENLACES EN EPUB Y HTML (SC-77).
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : SOLO EN LA CADENA DEL LIBRO (LAS REVISTAS NO USAN ÍNDICES,
--               SC-77), DESPUÉS DE cifras.lua Y ANTES DE
--               cite-to-biblioref-db.lua, QUE SERIALIZA LAS NOTAS CON
--               pandoc.write Y DESCARTARÍA LAS MARCAS QUE ESTÉN ADENTRO
--               (COMO CON LA VOLADA, SC-62).
-- REGLA       : LO QUE NO CUMPLE FRENA LA CONVERSIÓN CON UN MENSAJE:
--               NUNCA SE DEGRADA EN SILENCIO.
--               - EL NOMBRE DEL ÍNDICE ES OBLIGATORIO Y DE LA LISTA CERRADA.
--               - HASTA TRES NIVELES, NINGUNO VACÍO.
--               - UN ! @ | LITERAL SE ESCRIBE \! \@ \|. TAMBIÉN \% \& \#
--                 \_ \$ \{ \}. LA ÚNICA ORDEN ADMITIDA ADENTRO ES \emph{…}.
--               - NO VA EN UN TÍTULO, NI EN EL PIE O LA IMAGEN DE UNA
--                 FIGURA, NI EN EL PIE DE UN CUADRO: PASARÍA AL SUMARIO, A
--                 LOS MARCADORES O A LA LISTA DE FIGURAS, Y DE AHÍ AL
--                 ÍNDICE OTRA VEZ.
--               - NO VA SOLA EN UN PÁRRAFO: VA PEGADA A LA PALABRA QUE
--                 SEÑALA.
--               - UN RANGO SE ABRE Y SE CIERRA EN LA MISMA PIEZA, CON LA
--                 ENTRADA IDÉNTICA, Y NO VA EN UNA NOTA.
--               - UNA PÁGINA PRINCIPAL NO VA EN UNA NOTA: CADA ENTRADA
--                 LLEVA UN SOLO FORMATO, Y EL DE LA NOTA ES «23 n.».
-- ============================================================

-- LOS ÍNDICES QUE CARGA EL EDITOR: LOS DEL \makeindex DE LA ESTÉTICA
local NOMBRES = { onomastico = true, concepto = true }

-- HASTA TRES NIVELES: primary, secondary, tertiary (DocBook 5.2)
local NIVELES = { 'primary', 'secondary', 'tertiary' }

-- LO QUE SE ESCRIBE CON BARRA PARA QUE CUENTE COMO LETRA (SC-77)
local ESCAPES = {
  ['!'] = true, ['@'] = true, ['|'] = true, ['%'] = true, ['&'] = true,
  ['#'] = true, ['_'] = true, ['$'] = true, ['{'] = true, ['}'] = true,
}

-- TEXTO DE AYUDA QUE ACOMPAÑA A TODO MENSAJE DE ERROR
local ADMITIDOS =
  '\n  Se escribe \\index[onomastico]{…} o \\index[concepto]{…}, pegada a' ..
  '\n  la palabra que señala. Adentro: ! separa niveles (hasta tres), @ la' ..
  '\n  clave de orden, |( y |) abren y cierran un rango, |see{…} y' ..
  '\n  |seealso{…} remiten, |textbf marca la página principal. Un ! @ |' ..
  '\n  literal se escribe \\! \\@ \\|, y un % siempre \\%.'

-- CONTADOR DE xml:id DE LA PIEZA, Y LOS RANGOS ABIERTOS
local iSiguienteId = 0
local aRangosAbiertos = {}

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo)
  error('\n[indice] ' .. motivo .. ADMITIDOS .. '\n', 0)
end

-- ============================================
-- Función   : es_marca
-- Propósito : Dice si un elemento es una orden \index
-- Parámetros: el As Inline o Block
-- Retorna   : boolean
-- ============================================
local function es_marca(el)

  -- --- 1. SOLO LaTeX CRUDO ---
  if el.t ~= 'RawInline' and el.t ~= 'RawBlock' then return false end
  if el.format ~= 'tex' and el.format ~= 'latex' then return false end

  -- --- 2. LA ORDEN, CON O SIN ARGUMENTO OPCIONAL ---
  return el.text:match('^\\index[%[{]') ~= nil
end

-- ============================================
-- Función   : contiene_marca
-- Propósito : Dice si un elemento tiene alguna \index adentro
-- Parámetros: el As Inline o Block (o una lista)
-- Retorna   : boolean
-- ============================================
local function contiene_marca(el)
  local bHay = false
  local function mirar(r)
    if es_marca(r) then bHay = true end
  end
  el:walk({ RawInline = mirar, RawBlock = mirar })
  return bHay
end

-- ============================================
-- Función   : xml
-- Propósito : Escapa un texto para ponerlo en el XML del canónico
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function xml(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

-- ============================================
-- Función   : partir
-- Propósito : Parte un texto en el separador, solo en el nivel de llaves 0 y
--             salteando lo escapado con barra
-- Parámetros: s As String — el texto
--             sep As String — un carácter ASCII: ! @ |
--             iMax As Integer — cuántos cortes como máximo (nil: todos)
-- Retorna   : Table — los tramos
-- Nota      : POR BYTE ES CORRECTO EN UTF-8: LOS BYTES DE UN CARÁCTER
--             MULTIBYTE NUNCA COINCIDEN CON UN CARÁCTER ASCII.
-- ============================================
local function partir(s, sep, iMax)
  local aTramos, iDesde, iProf, i, c, iCortes

  aTramos = {}
  iDesde, iProf, i, iCortes = 1, 0, 1, 0
  while i <= #s do
    c = s:sub(i, i)
    if c == '\\' then
      -- LO QUE SIGUE A LA BARRA NO SEPARA NI ABRE LLAVES
      i = i + 1
    elseif c == '{' then
      iProf = iProf + 1
    elseif c == '}' then
      iProf = iProf - 1
    elseif c == sep and iProf == 0 and (not iMax or iCortes < iMax) then
      table.insert(aTramos, s:sub(iDesde, i - 1))
      iDesde = i + 1
      iCortes = iCortes + 1
    end
    i = i + 1
  end
  table.insert(aTramos, s:sub(iDesde))
  return aTramos
end

-- ============================================
-- Función   : llaves_balanceadas
-- Propósito : Dice si las llaves sin escapar de un texto cierran bien
-- Parámetros: s As String
-- Retorna   : boolean
-- ============================================
local function llaves_balanceadas(s)
  local iProf, i, c

  iProf, i = 0, 1
  while i <= #s do
    c = s:sub(i, i)
    if c == '\\' then
      i = i + 1
    elseif c == '{' then
      iProf = iProf + 1
    elseif c == '}' then
      iProf = iProf - 1
      if iProf < 0 then return false end
    end
    i = i + 1
  end
  return iProf == 0
end

-- ============================================
-- Función   : convertir
-- Propósito : Pasa un tramo de la entrada a contenido del canónico: resuelve
--             los escapes y \emph{…}; frena con cualquier otra orden o con
--             llaves sueltas
-- Parámetros: s As String — el tramo
--             bMarcas As Boolean — si admite \emph (la clave de orden no)
--             sOrden As String — la orden completa, para el mensaje
-- Retorna   : String — XML; String — el mismo texto, plano
-- ============================================
local function convertir(s, bMarcas, sOrden)
  local aXml, aPlano, i, c, sSig, sCmd, iFin, iProf, sDentro, sX, sP

  aXml, aPlano, i = {}, {}, 1
  while i <= #s do
    c = s:sub(i, i)

    -- --- 1. UNA BARRA: UN ESCAPE O UNA ORDEN ---
    if c == '\\' then
      sSig = s:sub(i + 1, i + 1)
      if ESCAPES[sSig] then
        table.insert(aXml, xml(sSig))
        table.insert(aPlano, sSig)
        i = i + 2
      else
        sCmd = s:match('^\\(%a+)', i)
        if sCmd == 'emph' and bMarcas and s:sub(i + 5, i + 5) == '{' then
          -- EL GRUPO DE \emph: HASTA SU LLAVE DE CIERRE
          iProf, iFin = 0, i + 5
          while iFin <= #s do
            local ch = s:sub(iFin, iFin)
            if ch == '\\' then
              iFin = iFin + 1
            elseif ch == '{' then
              iProf = iProf + 1
            elseif ch == '}' then
              iProf = iProf - 1
              if iProf == 0 then break end
            end
            iFin = iFin + 1
          end
          sDentro = s:sub(i + 6, iFin - 1)
          sX, sP = convertir(sDentro, bMarcas, sOrden)
          table.insert(aXml, '<emphasis>' .. sX .. '</emphasis>')
          table.insert(aPlano, sP)
          i = iFin + 1
        elseif sCmd == 'emph' then
          fallar('«' .. sOrden .. '»: \\emph no va en la clave de orden, que es ' ..
                 'texto plano.')
        elseif sCmd then
          fallar('«' .. sOrden .. '»: la orden \\' .. sCmd .. ' no va en una ' ..
                 'entrada de índice (la única admitida es \\emph{…}).')
        elseif sSig ~= '' then
          fallar('«' .. sOrden .. '»: «\\' .. sSig .. '» no va en una entrada ' ..
                 'de índice. Se escapan con barra solo ! @ | % & # _ $ { }.')
        else
          fallar('«' .. sOrden .. '»: termina en una barra.')
        end
      end

    -- --- 2. UNA LLAVE QUE NO ES DE \emph ---
    elseif c == '{' or c == '}' then
      fallar('«' .. sOrden .. '»: una llave suelta. Una llave literal se ' ..
             'escribe \\{ o \\}.')

    -- --- 3. TEXTO ---
    else
      table.insert(aXml, xml(c))
      table.insert(aPlano, c)
      i = i + 1
    end
  end
  return table.concat(aXml), table.concat(aPlano)
end

-- ============================================
-- Función   : leer_orden
-- Propósito : Lee una orden \index y la deja en sus partes, validada
-- Parámetros: sOrden As String — el texto del RawInline
-- Retorna   : Table — { nombre, cuerpo, niveles = { {xml, sortas} },
--             formato = '' | '(' | ')' | 'textbf' | 'see' | 'seealso',
--             remision = xml }
-- ============================================
local function leer_orden(sOrden)
  local sNombre, sContenido, aPartes, sCuerpo, sFormato, aNiveles, aNivel,
        sX, sP, sClaveX, sClaveP, sRemite, oOrden

  -- --- 1. LA FORMA Y EL NOMBRE ---
  if sOrden:match('^\\index{') then
    fallar('«' .. sOrden .. '» no dice a qué índice va: \\index[onomastico]{…} ' ..
           'o \\index[concepto]{…}.')
  end
  sNombre, sContenido = sOrden:match('^\\index%[([^%]]*)%]{(.*)}$')
  if not sNombre then
    fallar('«' .. sOrden .. '» no tiene la forma \\index[nombre]{entrada}.')
  end
  if not NOMBRES[sNombre] then
    fallar('«' .. sOrden .. '»: no hay un índice «' .. sNombre .. '». Los ' ..
           'índices que carga el editor son onomastico y concepto.')
  end
  if not llaves_balanceadas(sContenido) then
    fallar('«' .. sOrden .. '»: las llaves no cierran.')
  end

  -- --- 2. LA ENTRADA Y EL FORMATO (EL PRIMER | DEL NIVEL 0) ---
  aPartes = partir(sContenido, '|', 1)
  sCuerpo = aPartes[1]
  sFormato = aPartes[2]
  oOrden = { nombre = sNombre, cuerpo = sCuerpo, niveles = {}, formato = '' }

  if sFormato then
    if sFormato == '(' or sFormato == ')' or sFormato == 'textbf' then
      oOrden.formato = sFormato
    else
      sRemite = sFormato:match('^see{(.*)}$')
      if sRemite then
        oOrden.formato = 'see'
      else
        sRemite = sFormato:match('^seealso{(.*)}$')
        if sRemite then oOrden.formato = 'seealso' end
      end
      if not sRemite then
        fallar('«' .. sOrden .. '»: «|' .. sFormato .. '» no es un formato ' ..
               'admitido (|( |) |see{…} |seealso{…} |textbf).')
      end
      if sRemite:match('^%s*$') then
        fallar('«' .. sOrden .. '»: la remisión está vacía.')
      end
      oOrden.remision = convertir(sRemite, true, sOrden)
    end
  end

  -- --- 3. LOS NIVELES ---
  aNiveles = partir(sCuerpo, '!')
  if #aNiveles > #NIVELES then
    fallar('«' .. sOrden .. '» tiene ' .. #aNiveles .. ' niveles: el máximo ' ..
           'es tres.')
  end
  for _, sNivel in ipairs(aNiveles) do
    aNivel = partir(sNivel, '@', 1)
    if #aNivel == 2 then
      -- CLAVE@TEXTO, COMO EN makeindex Y xindy
      sClaveX, sClaveP = convertir(aNivel[1], false, sOrden)
      sX, sP = convertir(aNivel[2], true, sOrden)
      if sClaveP:match('^%s*$') then
        fallar('«' .. sOrden .. '»: la clave de orden antes de @ está vacía.')
      end
    else
      sX, sP = convertir(aNivel[1], true, sOrden)
      sClaveX = nil
    end
    if sP:match('^%s*$') then
      fallar('«' .. sOrden .. '» tiene un nivel vacío.')
    end
    table.insert(oOrden.niveles, { xml = sX, sortas = sClaveX })
  end

  return oOrden
end

-- ============================================
-- Función   : nuevo_id
-- Propósito : El próximo xml:id de la pieza. ensamblar-capitulo-canonico.xsl
--             le antepone el id del capítulo.
-- Parámetros: ninguno
-- Retorna   : String
-- ============================================
local function nuevo_id()
  iSiguienteId = iSiguienteId + 1
  return 'idx-' .. iSiguienteId
end

-- ============================================
-- Función   : traducir
-- Propósito : El <indexterm> de una orden ya leída
-- Parámetros: sOrden As String — el texto, para los mensajes
--             bEnNota As Boolean — si la marca está dentro de una nota
-- Retorna   : Inline — RawInline docbook
-- ============================================
local function traducir(sOrden, bEnNota)
  local oOrden, aXml, sId, sClave, sAtributos

  -- --- 1. LEER Y VALIDAR ---
  oOrden = leer_orden(sOrden)
  sClave = oOrden.nombre .. '\0' .. oOrden.cuerpo

  -- --- 2. LO QUE NO VA EN UNA NOTA ---
  if bEnNota and oOrden.formato == 'textbf' then
    fallar('«' .. sOrden .. '» está en una nota: la página principal no va ' ..
           'en una nota (su página sale «23 n.»).')
  end
  if bEnNota and (oOrden.formato == '(' or oOrden.formato == ')') then
    fallar('«' .. sOrden .. '» está en una nota: un rango no se abre ni se ' ..
           'cierra en una nota.')
  end

  -- --- 3. EL CIERRE DE UN RANGO: SOLO LA REFERENCIA AL COMIENZO ---
  if oOrden.formato == ')' then
    sId = aRangosAbiertos[sClave]
    if not sId then
      fallar('«' .. sOrden .. '» cierra un rango que no se abrió antes en esta ' ..
             'pieza con la misma entrada.')
    end
    aRangosAbiertos[sClave] = nil
    return pandoc.RawInline('docbook',
      '<indexterm class="endofrange" startref="' .. sId .. '"/>')
  end

  -- --- 4. EL COMIENZO DE UN RANGO O UNA MARCA SIMPLE ---
  sId = nuevo_id()
  sAtributos = ' type="' .. oOrden.nombre .. '" xml:id="' .. sId .. '"'
  if oOrden.formato == '(' then
    if aRangosAbiertos[sClave] then
      fallar('«' .. sOrden .. '» abre un rango que ya estaba abierto.')
    end
    aRangosAbiertos[sClave] = sId
    sAtributos = sAtributos .. ' class="startofrange"'
  elseif oOrden.formato == 'textbf' then
    sAtributos = sAtributos .. ' significance="preferred"'
  end

  aXml = { '<indexterm' .. sAtributos .. '>' }
  for i, oNivel in ipairs(oOrden.niveles) do
    table.insert(aXml, '<' .. NIVELES[i] ..
      (oNivel.sortas and (' sortas="' .. oNivel.sortas .. '"') or '') .. '>' ..
      oNivel.xml .. '</' .. NIVELES[i] .. '>')
  end
  if oOrden.formato == 'see' or oOrden.formato == 'seealso' then
    table.insert(aXml, '<' .. oOrden.formato .. '>' .. oOrden.remision ..
      '</' .. oOrden.formato .. '>')
  end
  table.insert(aXml, '</indexterm>')
  return pandoc.RawInline('docbook', table.concat(aXml))
end

-- ============================================
-- Función   : traducir_en
-- Propósito : Traduce las marcas de un elemento o documento
-- Parámetros: el As Pandoc, Block o Inline
--             bEnNota As Boolean
-- Retorna   : el mismo tipo, con las marcas traducidas
-- ============================================
local function traducir_en(el, bEnNota)
  return el:walk({ RawInline = function(r)
    if es_marca(r) then return traducir(r.text, bEnNota) end
  end })
end

-- ============================================
-- Función   : controlar_lugares
-- Propósito : Frena con una marca en un lugar donde no va
-- Parámetros: doc As Pandoc
-- Retorna   : nada; frena la conversión si encuentra una
-- ============================================
local function controlar_lugares(doc)

  doc:walk({
    -- --- 1. TÍTULOS: PASARÍAN AL SUMARIO Y A LOS MARCADORES ---
    Header = function(h)
      if contiene_marca(h) then
        fallar('El título «' .. pandoc.utils.stringify(h) .. '» lleva una ' ..
               'marca de índice: va al comienzo del primer párrafo.')
      end
    end,
    -- --- 2. FIGURAS: EL PIE VA A LA LISTA DE FIGURAS ---
    Figure = function(f)
      if contiene_marca(f) then
        fallar('La figura «' .. pandoc.utils.stringify(f.caption.long) ..
               '» lleva una marca de índice en el pie o en la imagen: va en ' ..
               'el texto que la nombra.')
      end
    end,
    Image = function(img)
      if contiene_marca(img) then
        fallar('Una imagen lleva una marca de índice: va en el texto que la ' ..
               'nombra.')
      end
    end,
    -- --- 3. CUADROS: EL PIE VA A LA LISTA DE CUADROS ---
    Table = function(t)
      if contiene_marca(pandoc.Div(t.caption.long)) then
        fallar('Un cuadro lleva una marca de índice en el pie: va en el texto ' ..
               'que lo nombra.')
      end
    end,
    -- --- 4. SOLA, COMO BLOQUE O COMO ÚNICO CONTENIDO DE UN PÁRRAFO ---
    RawBlock = function(b)
      if es_marca(b) then
        fallar('«' .. b.text .. '» está sola en un párrafo: va pegada a la ' ..
               'palabra que señala.')
      end
    end,
    Para = function(p)
      local bSoloMarcas = #p.content > 0
      for _, el in ipairs(p.content) do
        if not (es_marca(el) or el.t == 'Space' or el.t == 'SoftBreak') then
          bSoloMarcas = false
        end
      end
      if bSoloMarcas then
        fallar('«' .. p.content[1].text .. '» está sola en un párrafo: va ' ..
               'pegada a la palabra que señala.')
      end
    end,
    -- --- 5. UNA ORDEN QUE PANDOC PARTIÓ: UN % SIN BARRA O UNA LLAVE ---
    -- QUEDA COMO TEXTO COMÚN (GV-157) Y SALDRÍA LITERAL EN EL LIBRO
    Str = function(s)
      if s.text:find('\\index', 1, true) then
        fallar('«' .. s.text .. '…»: la marca quedó partida. Un % se escribe ' ..
               '\\% y las llaves tienen que cerrar.')
      end
    end,
  })
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Controla los lugares y traduce las marcas de todo el documento
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con las marcas traducidas
-- ============================================
function Pandoc(doc)
  local aAbiertos

  -- --- 1. FORMATO: SOLO LA CADENA DEL LIBRO ---
  if FORMAT ~= 'docbook5' then
    error('\n[indice] Formato de salida no previsto: ' .. FORMAT ..
          ' (los índices son solo de libros, SC-77)\n', 0)
  end

  -- --- 2. LUGARES DONDE NO VA ---
  controlar_lugares(doc)

  -- --- 3. PRIMERO LAS NOTAS: SU PÁGINA SALE «23 n.» ---
  -- LAS MARCAS TRADUCIDAS YA NO SON LaTeX, ASÍ QUE EL PASO 4 NO LAS VUELVE A VER
  doc = doc:walk({ Note = function(n) return traducir_en(n, true) end })

  -- --- 4. DESPUÉS EL RESTO, EN EL ORDEN DEL TEXTO (LOS RANGOS) ---
  doc = traducir_en(doc, false)

  -- --- 5. NINGÚN RANGO QUEDA ABIERTO ---
  aAbiertos = {}
  for sClave, _ in pairs(aRangosAbiertos) do
    table.insert(aAbiertos, (sClave:gsub('%z', ': ')))
  end
  if #aAbiertos > 0 then
    table.sort(aAbiertos)
    fallar('Rango abierto con |( que no se cierra con |) en esta pieza: ' ..
           table.concat(aAbiertos, '; ') .. '.')
  end

  return doc
end
