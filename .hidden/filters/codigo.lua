-- ============================================================
-- FILTRO      : codigo.lua
-- PROPÓSITO   : CONTROLA EL CÓDIGO (SC-42) CON UNA SOLA REGLA PARA
--               LIBRO, REVISTA Y ODT, Y ESCRIBE EL BLOQUE EN EL XML
--               CANÓNICO. EL COLOR NO VA AL CANÓNICO: LO PONE CADA
--               SALIDA (colorear_codigo.sh).
-- ENTRADA     : UN BLOQUE CERCADO CON SU LENGUAJE:
--
--                 ~~~ python
--                 for i in range(3):
--                     print(i)
--                 ~~~
--
--               Y EL LISTADO, QUE LO ENVUELVE CON UN PIE NUMERADO:
--
--                 ::: {.listado #lst-factorial}
--
--                 ~~~ python
--                 def factorial(n): …
--                 ~~~
--
--                 Pie del listado, con *formato* y citas.
--
--                 [/listado]: # ()
--                 :::
--
--               UNA LÍNEA QUE TERMINA EN ↩ (U+21A9) ES UN CORTE MANUAL:
--               EL CARÁCTER PASA AL CANÓNICO TAL CUAL Y LO RESUELVEN LAS
--               SALIDAS (NÚMERO DE LÍNEA, GLIFO EN GRIS).
-- SALIDA      : JATS     <code language="python">…</code>
--               DOCBOOK  <programlisting language="python">…</programlisting>
--               (texto: SIN language). EL LISTADO QUEDA COMO UN Div
--               .listado CON DOS HIJOS —EL BLOQUE YA ESCRITO Y EL Para
--               DEL PIE— Y LO SERIALIZAN cite-to-xref.lua (<fig
--               fig-type="listado">) Y fenced-divs-to-elements-db.lua
--               (<example role="listado">), QUE TIENEN LAS CITAS DEL PIE
--               RESUELTAS.
--               ODT: EL BLOQUE QUEDA COMO CodeBlock (PANDOC LO RESALTA
--               CON SU ESTILO, EN CLARO); EL LISTADO, EL BLOQUE Y EL PIE.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN REVISTA, DESPUÉS DE unwrap-structural-divs.lua Y
--               recuadros.lua, Y ANTES DE cite-to-xref.lua. EN LIBRO,
--               DESPUÉS DE recuadros.lua Y ANTES DE
--               fenced-divs-to-elements-db.lua. EN EL ODT, CON LOS DEMÁS.
-- REGLA       : FRENA LA CONVERSIÓN CON UN MENSAJE SI:
--               - UN BLOQUE NO TIENE LENGUAJE, TIENE MÁS DE UNO O UNO
--                 FUERA DE LA LISTA;
--               - UN BLOQUE SUELTO TIENE #id (EL id ES DEL LISTADO);
--               - UN LISTADO NO TIENE #lst-…, NO TIENE UN BLOQUE Y UN
--                 PIE, O EL PIE QUEDÓ CON EL MARCADOR •;
--               - QUEDA UN ::: {.code}: EL BLOQUE VIEJO SE RETIRÓ.
--               NUNCA SE DEGRADA EN SILENCIO.
-- GEMELOS     : LA LISTA DE LENGUAJES ES LA DE codigo-comun.xsl (RÓTULOS)
--               Y LA DEL MODO codigo EN m_Shortcodes. UN CAMBIO VA EN
--               LOS TRES.
-- ============================================================

-- LENGUAJES ADMITIDOS. docbook Y jats SE COLOREAN COMO xml; texto VA
-- SIN COLOR. TODOS LOS DEMÁS ESTÁN EN EL RESALTADOR DE PANDOC (MEDIDO)
local LENGUAJES = {
  python = true, r = true, sql = true, bash = true, javascript = true,
  json = true, yaml = true, markdown = true, latex = true, html = true,
  xml = true, xslt = true, css = true, lua = true,
  docbook = true, jats = true, texto = true,
}
local LISTA = 'python, r, sql, bash, javascript, json, yaml, markdown, latex, ' ..
              'html, xml, xslt, css, lua, docbook, jats o texto'

-- EL MARCADOR DE LOS SNIPPETS (SC-21): UN PIE QUE LO CONSERVA NO SE ESCRIBIÓ
local MARCADOR = '•'

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que ubica el bloque
-- Parámetros: motivo As String; texto As String — comienzo del bloque
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo, texto)
  error('\n[código] ' .. motivo ..
        '\n  Comienzo del bloque: ' .. (texto or ''):sub(1, 60) .. '\n', 0)
end

-- ============================================
-- Función   : escapar
-- Propósito : Escapa el texto del bloque para el XML
-- Parámetros: s As String
-- Retorna   : String
-- ============================================
local function escapar(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

-- ============================================
-- Función   : lenguaje_de
-- Propósito : Valida el lenguaje de un bloque y lo devuelve
-- Parámetros: cb As CodeBlock
-- Retorna   : String — el lenguaje, en minúsculas
-- ============================================
local function lenguaje_de(cb)
  if #cb.classes == 0 then
    fallar('el bloque no dice el lenguaje. Se escribe después de la cerca: ' ..
           '~~~ python. Para texto sin color: ~~~ texto. Admitidos: ' .. LISTA .. '.', cb.text)
  end
  if #cb.classes > 1 then
    fallar('el bloque tiene más de un lenguaje (' .. table.concat(cb.classes, ', ') ..
           '). Va uno solo.', cb.text)
  end
  local lenguaje = cb.classes[1]:lower()
  if not LENGUAJES[lenguaje] then
    fallar('el lenguaje «' .. cb.classes[1] .. '» no está en la lista. Admitidos: ' ..
           LISTA .. '.', cb.text)
  end
  return lenguaje
end

-- ============================================
-- Función   : bloque_xml
-- Propósito : Escribe un bloque de código en el vocabulario del canónico
-- Parámetros: cb As CodeBlock; formato As String — jats o docbook5
-- Retorna   : RawBlock
-- ============================================
local function bloque_xml(cb, formato)
  local lenguaje = lenguaje_de(cb)
  local atributo = (lenguaje == 'texto') and '' or (' language="' .. lenguaje .. '"')
  if formato == 'jats' then
    return pandoc.RawBlock('jats', '<code' .. atributo .. '>' .. escapar(cb.text) .. '</code>')
  end
  -- SIN SALTOS PEGADOS A LAS ETIQUETAS: EN UN programlisting SON CONTENIDO
  return pandoc.RawBlock('docbook', '<programlisting' .. atributo .. '>' ..
                         escapar(cb.text) .. '</programlisting>')
end

-- ============================================
-- Función   : bloque_odt
-- Propósito : Deja el bloque listo para el resaltador de Pandoc en el ODT
-- Parámetros: cb As CodeBlock
-- Retorna   : CodeBlock — con la clase que Pandoc conoce
-- ============================================
local function bloque_odt(cb)
  local lenguaje = lenguaje_de(cb)
  if lenguaje == 'docbook' or lenguaje == 'jats' then lenguaje = 'xml' end
  local clases = (lenguaje == 'texto') and {} or { lenguaje }
  return pandoc.CodeBlock(cb.text, pandoc.Attr('', clases))
end

-- ============================================
-- Función   : controlar_listado
-- Propósito : Controla la forma del listado
-- Parámetros: el As Div
-- Retorna   : CodeBlock, table — el bloque y los inlines del pie
-- ============================================
local function controlar_listado(el)
  local texto = pandoc.utils.stringify(el)
  if el.identifier == '' or el.identifier:sub(1, 4) ~= 'lst-' then
    fallar('un listado necesita su identificador, que empieza con lst-: ' ..
           '::: {.listado #lst-nombre}', texto)
  end
  if el.identifier:find(MARCADOR, 1, true) then
    fallar('el identificador del listado #' .. el.identifier .. ' conserva el marcador •: ' ..
           'hay que escribir el nombre.', texto)
  end
  if #el.content ~= 2 or el.content[1].t ~= 'CodeBlock'
     or (el.content[2].t ~= 'Para' and el.content[2].t ~= 'Plain') then
    fallar('el listado #' .. el.identifier .. ' lleva un bloque de código y, debajo, ' ..
           'un párrafo con el pie; nada más.', texto)
  end
  local pie = el.content[2].content
  if pandoc.utils.stringify(pie):gsub('%s', '') == MARCADOR then
    fallar('el pie del listado #' .. el.identifier .. ' conserva el marcador •: ' ..
           'hay que escribirlo.', texto)
  end
  return el.content[1], pie
end

-- ============================================
-- Función   : Pandoc
-- Propósito : Recorre el documento: primero los listados (que necesitan
--             ver el CodeBlock tal como lo leyó Pandoc), después cada
--             bloque suelto
-- Parámetros: doc As Pandoc
-- Retorna   : Pandoc — el documento con el código escrito
-- ============================================
function Pandoc(doc)
  local formato = FORMAT
  local es_odt = (formato == 'odt')
  if formato ~= 'jats' and formato ~= 'docbook5' and not es_odt then
    return nil
  end

  -- --- 1. LISTADOS Y BLOQUES VIEJOS ---
  doc = doc:walk({
    Div = function(el)
      -- EL BLOQUE VIEJO SE RETIRÓ (SC-42): SIN ESTE FRENO SALDRÍA COMO TEXTO
      if el.classes:includes('code') then
        fallar('el bloque ::: {.code language="…"} se retiró. El código va en un bloque ' ..
               'cercado con su lenguaje: ~~~ python … ~~~; con pie numerado, dentro de ' ..
               '::: {.listado #lst-nombre}.', pandoc.utils.stringify(el))
      end
      if not el.classes:includes('listado') then return nil end

      local cb, pie = controlar_listado(el)
      if es_odt then
        -- ODT: EL BLOQUE Y EL PIE, SIN NÚMERO. EL BLOQUE SE VALIDA ACÁ Y
        -- LO CONVIERTE EL PASO 2, COMO A UNO SUELTO
        lenguaje_de(cb)
        return { cb, pandoc.Para(pie) }
      end
      -- EL BLOQUE YA ESCRITO Y EL PIE: LOS ENVUELVE EL FILTRO QUE SERIALIZA
      return pandoc.Div({ bloque_xml(cb, formato), pandoc.Para(pie) },
                        pandoc.Attr(el.identifier, { 'listado' }))
    end
  })

  -- --- 2. BLOQUES SUELTOS ---
  return doc:walk({
    CodeBlock = function(cb)
      if cb.identifier ~= '' then
        fallar('un bloque de código no lleva identificador (#' .. cb.identifier .. '). ' ..
               'Para numerarlo con un pie, va dentro de ::: {.listado #lst-nombre}.', cb.text)
      end
      if es_odt then return bloque_odt(cb) end
      return bloque_xml(cb, formato)
    end
  })
end
