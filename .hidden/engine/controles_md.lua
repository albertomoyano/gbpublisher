-- ============================================================================
-- Filtro     : controles_md.lua
-- Propósito  : Controles de corrección sobre un .md del proyecto: lo que el
--              Markdown deja pasar sin error y llega mal al impreso. NO
--              modifica el documento: solo informa.
-- Invocación : desde engine/generar_canonicos_capitulos.sh, en una pasada
--              propia, ANTES de la conversión y SIN los filtros de producción
--              (el criterio de SC-46: fenced-divs serializa los divs a XML
--              crudo y después ya no hay texto que revisar; otros frenan).
--                pandoc ARCHIVO.md --from markdown --to plain
--                       --lua-filter controles_md.lua
--                       --metadata gb-controles=RUTA
--                       --metadata gb-proyecto=RAIZ --output /dev/null
--              RAIZ es la raíz del proyecto: las imágenes se escriben en el
--              .md con ruta relativa a ella (media/fig-mapa.png, SC-32).
-- Salida     : en RUTA, un hallazgo por línea, tres campos separados por TAB:
--                nivel  control  mensaje
--              nivel: error (el capítulo no se genera) | aviso (se genera,
--              y el lote termina con código 3). El archivo se escribe siempre,
--              vacío si no hubo hallazgos: su ausencia es un fallo del control.
-- Ubicación  : engine/ — NO se copia a ~/.gbpublisher (SC-11): un control que
--              dice «este capítulo está bien» no se ajusta localmente.
--
-- CÓMO SE SUMA UN CONTROL
--   1. Una línea en CONTROLES con su nombre y su nivel.
--   2. Una función que llama a registrar(nombre, mensaje).
--   3. Su llamada en Pandoc(), al final del archivo.
--   El mensaje no lleva TAB ni salto de línea: contexto() los limpia.
-- ============================================================================

-- --- 1. CONTROLES Y SU NIVEL ---
-- CAMBIAR EL NIVEL DE UN CONTROL ES CAMBIAR ESTA TABLA, NADA MÁS
local CONTROLES = {
  -- [^3] SIN SU DEFINICIÓN: PANDOC LO DEJA COMO TEXTO LITERAL Y SALE ASÍ
  -- EN EL IMPRESO
  llamada_sin_nota = "error",
  -- [^3]: SIN NADA: UNA NOTA VACÍA, EL EQUIVALENTE DE \footnote{}
  nota_vacia = "error",
  -- [^3]: CON LA LÍNEA VACÍA: SI DEBAJO HAY UN PÁRRAFO, PANDOC LO TOMA
  -- COMO CONTENIDO DE LA NOTA Y DESAPARECE DEL TEXTO, SIN AVISO
  definicion_sin_texto = "error",
  -- « » QUE NO CIERRAN EN SU LISTA DE INLINES: guillemets-to-quoted-db.lua
  -- LAS DEJA LITERALES Y LA CITA NO LLEGA AL CANÓNICO COMO <quote>
  comillas_desbalanceadas = "aviso",
  -- UNA IMAGEN DEL .md QUE NO ESTÁ EN media/: BORRADA O RENOMBRADA POR
  -- ERROR. LAS SALIDAS FALLARÍAN MÁS TARDE, O SALDRÍAN SIN LA FIGURA
  imagen_inexistente = "error",
  -- UNA IMAGEN QUE APUNTA FUERA DE media/: EL EPUB Y EL HTML SOLO COPIAN
  -- media/, ASÍ QUE AUNQUE EXISTA NO LLEGA A ESAS SALIDAS
  imagen_fuera_de_media = "error",
  -- UNA ORDEN DE LaTeX EN EL TEXTO QUE NO ES \sptext{…}: PANDOC LA LEE COMO
  -- LaTeX CRUDO Y LOS ESCRITORES DE XML LA DESCARTAN; SE PIERDE EN LAS TRES
  -- SALIDAS, SIN AVISO (GV-116)
  latex_en_linea = "error",
  -- UNA ORDEN DE LaTeX SOLA ENTRE PÁRRAFOS, FUERA DE ::: espaciov: SE PIERDE
  -- IGUAL. LA QUE ESTÁ DENTRO DE espaciov LA VALIDA espacio-vertical.lua
  latex_suelto = "error",
  -- HTML ESCRITO EN EL .md (<sup>, <br>, PEGADO DE UNA WEB): LOS ESCRITORES
  -- DE XML LO DESCARTAN. LOS COMENTARIOS <!-- … --> NO CUENTAN: NO SON TEXTO
  html_crudo = "error",
}

-- LARGO MÁXIMO DEL CONTEXTO QUE ACOMPAÑA A UN HALLAZGO, EN CARACTERES
local LARGO_CONTEXTO = 70

-- UNA LLAMADA A NOTA: [^ETIQUETA], SIN ESPACIOS NI CORCHETE DE CIERRE ADENTRO
local PATRON_LLAMADA = "%[%^[^%]%s]+%]"

-- LA ÚNICA ORDEN DE LaTeX ADMITIDA EN EL TEXTO: LA TRADUCE volada.lua (SC-62)
local PATRON_SPTEXT = "^\\sptext{.*}$"

-- UN COMENTARIO HTML, QUE PANDOC TAMBIÉN LEE COMO HTML CRUDO
local PATRON_COMENTARIO = "^%s*<!%-%-.*%-%->%s*$"

local aHallazgos = {}

-- ============================================================================
-- Función   : registrar
-- Propósito : Anota un hallazgo con el nivel que fija CONTROLES.
-- Parámetros: sControl — nombre en CONTROLES; sMensaje — texto para el editor
-- ============================================================================
local function registrar(sControl, sMensaje)
  local sNivel = CONTROLES[sControl]
  -- UN CONTROL SIN NIVEL ES UN ERROR DE PROGRAMACIÓN DE ESTE ARCHIVO: SE
  -- CORTA, PARA QUE NO PASE INADVERTIDO
  if not sNivel then
    error("controles_md.lua: el control «" .. sControl .. "» no está en CONTROLES")
  end
  table.insert(aHallazgos, { sNivel, sControl, sMensaje })
end

-- ============================================================================
-- Función   : contexto
-- Propósito : Texto de un elemento en una línea, recortado a LARGO_CONTEXTO
--             caracteres (no bytes: utf8) y sin TAB ni saltos.
-- Parámetros: el — elemento o lista de pandoc
-- Retorna   : string
-- ============================================================================
local function contexto(el)
  local s = pandoc.utils.stringify(el):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  if utf8.len(s) and utf8.len(s) > LARGO_CONTEXTO then
    s = s:sub(1, utf8.offset(s, LARGO_CONTEXTO + 1) - 1) .. "…"
  end
  return s
end

-- ============================================================================
-- Función   : revisar_inlines
-- Propósito : Busca llamadas sueltas y notas vacías en una lista de inlines,
--             bajando a los contenedores (énfasis, spans, enlaces, citas…)
--             pero NO al contenido de una nota: sus párrafos los recorre el
--             walk de bloques por su cuenta, y bajar acá los contaría dos
--             veces.
-- Parámetros: aInlines — lista de inlines; bloque — el bloque que los
--             contiene, para el contexto del mensaje
-- ============================================================================
local function revisar_inlines(aInlines, bloque)
  for _, el in ipairs(aInlines) do
    if el.t == "Str" then
      for sMarca in el.text:gmatch(PATRON_LLAMADA) do
        registrar("llamada_sin_nota",
          "llamada " .. sMarca .. " sin nota que la defina: «" .. contexto(bloque) .. "»")
      end
    elseif el.t == "Note" then
      if pandoc.utils.stringify(el.content):match("^%s*$") then
        registrar("nota_vacia", "nota sin texto en: «" .. contexto(bloque) .. "»")
      end
    elseif el.t == "Image" then
      revisar_inlines(el.caption, bloque)
    elseif el.content then
      revisar_inlines(el.content, bloque)
    end
  end
end

-- ============================================================================
-- Función   : revisar_bloques
-- Propósito : Recorre todos los bloques con texto, incluidos los que están
--             dentro de notas, divs, citas en bloque, listas y tablas. Los
--             bloques de código no tienen inlines: quedan fuera solos.
-- Parámetros: doc — el documento
-- ============================================================================
local function revisar_bloques(doc)
  doc:walk({
    Para = function(b) revisar_inlines(b.content, b) end,
    Plain = function(b) revisar_inlines(b.content, b) end,
    Header = function(b) revisar_inlines(b.content, b) end,
    LineBlock = function(b)
      for _, aLinea in ipairs(b.content) do revisar_inlines(aLinea, b) end
    end,
  })
end

-- ============================================================================
-- Función   : revisar_comillas
-- Propósito : Busca las listas de inlines con « » desbalanceadas. Es el MISMO
--             criterio que guillemets-to-quoted-db.lua, que decide si arma la
--             cita o deja los caracteres literales: la lista se mira sola, solo
--             cuentan los « » de sus Str directos, y está mal si un » cierra
--             sin nada abierto o si al final queda un « abierto. Así el aviso
--             coincide con lo que el filtro de producción no pudo resolver,
--             incluida su limitación: «un *texto» citado* no cierra en
--             ninguna de las dos listas y se avisa.
--             SI CAMBIA EL CRITERIO DEL FILTRO, CAMBIA ACÁ.
-- Parámetros: doc — el documento
-- ============================================================================
local function revisar_comillas(doc)
  local ABRE, CIERRA = "«", "»"

  doc:walk({
    Inlines = function(aInlines)
      local iProfundidad = 0
      local bMal = false
      local bHay = false

      for _, el in ipairs(aInlines) do
        if el.t == "Str" then
          -- LAS MARCAS EN EL ORDEN EN QUE APARECEN DENTRO DEL Str. find CON
          -- plain = true COMPARA BYTES: CORRECTO EN UTF-8 VÁLIDO, COMO EN EL
          -- FILTRO DE PRODUCCIÓN
          local iPos = 1
          while true do
            local a = el.text:find(ABRE, iPos, true)
            local c = el.text:find(CIERRA, iPos, true)
            if not a and not c then break end
            bHay = true
            if a and (not c or a < c) then
              iProfundidad = iProfundidad + 1
              iPos = a + #ABRE
            else
              iProfundidad = iProfundidad - 1
              -- UN CIERRE SIN NADA ABIERTO YA ES DESBALANCE, AUNQUE DESPUÉS
              -- LA CUENTA SE COMPENSE
              if iProfundidad < 0 then bMal = true end
              iPos = c + #CIERRA
            end
          end
        end
      end

      if bHay and (bMal or iProfundidad ~= 0) then
        registrar("comillas_desbalanceadas",
          "comillas « » sin cerrar o sin abrir en: «" .. contexto(aInlines) .. "»")
      end
      return nil
    end,
  })
end

-- ============================================================================
-- Función   : revisar_imagenes
-- Propósito : Cada imagen que el .md usa tiene que estar en media/ del
--             proyecto. NO revisa lo contrario: que media/ tenga imágenes
--             que ningún .md usa es normal (la tapa, los logos, las que se
--             sacaron del texto) y no es asunto de este control.
--             Se mira el nodo Image, que es lo que llega a las salidas, esté
--             suelto o dentro de un ::: fig. Las direcciones con esquema
--             (http:, https:, data:) no son archivos del proyecto: se saltean.
-- Parámetros: doc — el documento; sRaiz — raíz del proyecto
-- ============================================================================
local function revisar_imagenes(doc, sRaiz)
  doc:walk({
    Image = function(el)
      local sRuta = el.src
      -- CON ESQUEMA: NO ES UN ARCHIVO DEL PROYECTO
      if sRuta:match("^%a[%w+.-]*:") then return nil end

      -- SOLO media/, Y SIN SUBIR DE CARPETA: «media/../x.png» TAMBIÉN SALE
      if sRuta:sub(1, 6) ~= "media/" or sRuta:find("..", 1, true) then
        registrar("imagen_fuera_de_media",
          "la imagen «" .. sRuta .. "» no está en media/ del proyecto")
        return nil
      end

      -- EXISTE: io.open DE LECTURA. LA COMPARACIÓN DEL NOMBRE ES EXACTA, CON
      -- MAYÚSCULAS: EN LINUX fig-Mapa.png Y fig-mapa.png SON DOS ARCHIVOS
      local h = io.open(sRaiz .. "/" .. sRuta, "r")
      if h then
        h:close()
      else
        registrar("imagen_inexistente",
          "la imagen «" .. sRuta .. "» no existe: ¿se borró o se renombró?")
      end
      return nil
    end,
  })
end

-- ============================================================================
-- Función   : es_comentario
-- Propósito : Dice si un elemento crudo de HTML es un comentario <!-- … -->
-- Parámetros: el — RawInline o RawBlock
-- Retorna   : boolean
-- ============================================================================
local function es_comentario(el)
  -- EL COMENTARIO PUEDE OCUPAR VARIAS LÍNEAS: SE COMPARA SIN LOS SALTOS
  return (el.format == "html") and (el.text:gsub("\n", " "):match(PATRON_COMENTARIO) ~= nil)
end

-- ============================================================================
-- Función   : contexto_crudo
-- Propósito : Como contexto, pero con el texto crudo a la vista: stringify
--             descarta el LaTeX y el HTML crudos, y el contexto quedaba con
--             huecos («Mal: , y o y .»)
-- Parámetros: bloque — el bloque del hallazgo
-- Retorna   : string
-- ============================================================================
local function contexto_crudo(bloque)
  return contexto(bloque:walk({
    RawInline = function(r) return pandoc.Str(r.text) end,
  }))
end

-- ============================================================================
-- Función   : revisar_crudo_inlines
-- Propósito : Busca LaTeX y HTML crudo en una lista de inlines, bajando a los
--             contenedores como revisar_inlines y, como ella, SIN bajar al
--             contenido de una nota: sus párrafos los recorre el walk de
--             bloques, y bajar acá los informaría dos veces.
-- Parámetros: aInlines — lista de inlines; bloque — el bloque que los
--             contiene, para el contexto del mensaje
-- ============================================================================
local function revisar_crudo_inlines(aInlines, bloque)
  for _, el in ipairs(aInlines) do
    if el.t == "RawInline" then
      -- --- 1. LaTeX: SOLO \sptext{…}, QUE TRADUCE volada.lua ---
      if el.format == "tex" or el.format == "latex" then
        if not el.text:match(PATRON_SPTEXT) then
          registrar("latex_en_linea",
            "la orden de LaTeX «" .. el.text .. "» se pierde en las tres salidas " ..
            "(la única admitida en el texto es \\sptext{…}): «" .. contexto_crudo(bloque) .. "»")
        end
      -- --- 2. HTML: TODO, MENOS LOS COMENTARIOS ---
      elseif el.format == "html" then
        if not es_comentario(el) then
          registrar("html_crudo",
            "el HTML «" .. el.text .. "» se pierde en el XML: «" .. contexto_crudo(bloque) .. "»")
        end
      end
    elseif el.t == "Note" then
      -- SUS PÁRRAFOS LOS VISITA EL WALK DE BLOQUES
    elseif el.t == "Image" then
      revisar_crudo_inlines(el.caption, bloque)
    elseif el.content then
      revisar_crudo_inlines(el.content, bloque)
    end
  end
end

-- ============================================================================
-- Función   : revisar_crudo
-- Propósito : LaTeX y HTML crudo en todo el documento: en línea, dentro de
--             cada bloque con texto, y suelto entre bloques. El contenido de
--             ::: espaciov no se mira: ahí el LaTeX es el valor del
--             shortcode, y lo valida espacio-vertical.lua (SC-39).
-- Parámetros: doc — el documento
-- ============================================================================
local function revisar_crudo(doc)

  -- --- 1. EN LÍNEA: LOS MISMOS BLOQUES QUE revisar_bloques ---
  doc:walk({
    Para = function(b) revisar_crudo_inlines(b.content, b) end,
    Plain = function(b) revisar_crudo_inlines(b.content, b) end,
    Header = function(b) revisar_crudo_inlines(b.content, b) end,
    LineBlock = function(b)
      for _, aLinea in ipairs(b.content) do revisar_crudo_inlines(aLinea, b) end
    end,
  })

  -- --- 2. SUELTO: DE ARRIBA ABAJO, PARA SALTEAR EL CONTENIDO DE espaciov ---
  -- CON traverse = "topdown", DEVOLVER false COMO SEGUNDO VALOR NO BAJA A LOS
  -- HIJOS DEL ELEMENTO
  doc:walk({
    traverse = "topdown",
    Div = function(d)
      if d.classes:includes("espaciov") then return d, false end
      return nil
    end,
    RawBlock = function(b)
      if b.format == "tex" or b.format == "latex" then
        registrar("latex_suelto",
          "la orden de LaTeX «" .. contexto(b.text) .. "», sola entre párrafos, " ..
          "se pierde en las tres salidas: si es un espacio o un salto de página, va dentro de ::: espaciov")
      elseif b.format == "html" and not es_comentario(b) then
        registrar("html_crudo",
          "el HTML «" .. contexto(b.text) .. "» se pierde en el XML")
      end
      return nil
    end,
  })
end

-- ============================================================================
-- Función   : revisar_definiciones
-- Propósito : Busca definiciones de nota con la línea vacía. Se hace sobre el
--             TEXTO FUENTE porque en el AST ya no están: la definición se
--             tragó el párrafo siguiente, o quedó una nota vacía. Saltea los
--             bloques de código cercados, donde un «[^3]:» es literal.
-- Parámetros: ninguno (lee PANDOC_STATE.input_files)
-- ============================================================================
local function revisar_definiciones()
  local sArchivo = PANDOC_STATE.input_files[1]
  if not sArchivo or sArchivo == "-" then
    error("controles_md.lua: necesita el .md como archivo de entrada, no por stdin")
  end

  local h = io.open(sArchivo, "r")
  if not h then
    error("controles_md.lua: no se pudo leer " .. sArchivo)
  end

  local iLinea = 0
  local bEnCodigo = false
  for sLinea in h:lines() do
    iLinea = iLinea + 1
    sLinea = sLinea:gsub("\r$", "")
    -- UNA CERCA ``` O ~~~ ABRE O CIERRA UN BLOQUE DE CÓDIGO
    if sLinea:match("^%s*```") or sLinea:match("^%s*~~~") then
      bEnCodigo = not bEnCodigo
    elseif not bEnCodigo then
      local sMarca = sLinea:match("^(" .. PATRON_LLAMADA .. "):%s*$")
      if sMarca then
        registrar("definicion_sin_texto",
          "línea " .. iLinea .. ": la nota " .. sMarca ..
          " no tiene texto en su línea; si debajo hay un párrafo, Pandoc lo mete en la nota y lo saca del texto")
      end
    end
  end
  h:close()
end

-- ============================================================================
-- Función   : Pandoc
-- Propósito : Corre los controles y escribe el informe. El documento no se
--             toca.
-- ============================================================================
function Pandoc(doc)
  if not doc.meta["gb-controles"] then
    error("controles_md.lua: falta --metadata gb-controles=RUTA")
  end
  local sRuta = pandoc.utils.stringify(doc.meta["gb-controles"])
  if not doc.meta["gb-proyecto"] then
    error("controles_md.lua: falta --metadata gb-proyecto=RAIZ")
  end
  local sRaiz = pandoc.utils.stringify(doc.meta["gb-proyecto"]):gsub("/$", "")

  -- --- LOS CONTROLES ---
  revisar_definiciones()
  revisar_bloques(doc)
  revisar_comillas(doc)
  revisar_imagenes(doc, sRaiz)
  revisar_crudo(doc)

  -- --- EL INFORME: SIEMPRE SE ESCRIBE, VACÍO SI NO HUBO HALLAZGOS ---
  local h = io.open(sRuta, "w")
  if not h then
    error("controles_md.lua: no se pudo escribir " .. sRuta)
  end
  for _, a in ipairs(aHallazgos) do
    h:write(a[1], "\t", a[2], "\t", a[3], "\n")
  end
  h:close()

  return nil
end
