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
--                       --metadata gb-fuentes=RUTA_FUENTES
--                       --metadata gb-proyecto=RAIZ --output /dev/null
--              RAIZ es la raíz del proyecto: las imágenes se escriben en el
--              .md con ruta relativa a ella (media/fig-mapa.png, SC-32).
-- Salida     : en RUTA, un hallazgo por línea, tres campos separados por TAB:
--                nivel  control  mensaje
--              nivel: error (el capítulo no se genera) | aviso (se genera,
--              y el lote termina con código 3). El archivo se escribe siempre,
--              vacío si no hubo hallazgos: su ausencia es un fallo del control.
--              En RUTA_FUENTES, los cuadros que nombra el .md, uno por línea
--              y relativos a RAIZ (cuadros/tbl-nombre.md): con el .md, son
--              las fuentes cuya huella se anota en el canónico (SC-75). Se
--              escribe siempre, vacío si no hay cuadros, con el mismo
--              contrato que el informe. NO es un control: no registra nada.
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
  -- UNA ORDEN DE LaTeX EN EL TEXTO QUE NO ES DE LAS ADMITIDAS (\sptext,
  -- \num, \SI, \SIrange): PANDOC LA LEE COMO LaTeX CRUDO Y LOS ESCRITORES
  -- DE XML LA DESCARTAN; SE PIERDE EN LAS TRES SALIDAS, SIN AVISO (GV-116)
  latex_en_linea = "error",
  -- UNA ORDEN DE LaTeX SOLA ENTRE PÁRRAFOS, FUERA DE ::: espaciov: SE PIERDE
  -- IGUAL. LA QUE ESTÁ DENTRO DE espaciov LA VALIDA espacio-vertical.lua
  latex_suelto = "error",
  -- HTML ESCRITO EN EL .md (<sup>, <br>, PEGADO DE UNA WEB): LOS ESCRITORES
  -- DE XML LO DESCARTAN. LOS COMENTARIOS <!-- … --> NO CUENTAN: NO SON TEXTO
  html_crudo = "error",
  -- UNA \\ FUERA DE UN TÍTULO: EL CORTE SOLO VALE EN LOS TÍTULOS (SC-63);
  -- EN EL TEXTO SALE COMO UNA BARRA LITERAL EN LAS TRES SALIDAS. PARA UN
  -- SALTO FUERA DE UN TÍTULO ESTÁ espaciov (SC-39)
  corte_fuera_de_titulo = "error",
  -- UN PORCENTAJE ESCRITO SUELTO (88%, 88 %): SALE TAL CUAL, SIN EL ESPACIO
  -- QUE FIJA LA RECOMENDACIÓN (SC-64). VA \SI{88}{\percent}; CON UNA SOLA
  -- CIFRA, EN LETRAS («4 por ciento»). AVISO: INFORMA Y LA SALIDA SE GENERA
  porcentaje_suelto = "aviso",
  -- UNA CIFRA CON PUNTO O COMA DE MILES FUERA DE \num (1.500, 12,345): SALE
  -- TAL CUAL, SIN EL AGRUPAMIENTO DE SC-64. LOS NÚMEROS DE IDENTIDAD (LEY
  -- 34.555) SON CORRECTOS ASÍ: POR ESO ES AVISO Y NO ERROR
  cifra_fuera_de_num = "aviso",
  -- UN ¬ PEGADO A UN ESPACIO O AL BORDE DE UNA LÍNEA («siglo ¬XX»,
  -- «siglo¬ XX»): EL ESPACIO DURO QUEDA AL LADO DE UNO COMÚN Y LA LÍNEA SE
  -- PUEDE PARTIR IGUAL. ¬ VA ENTRE DOS PALABRAS, SIN ESPACIOS (SC-68)
  espacio_fijo_suelto = "aviso",
}

-- LARGO MÁXIMO DEL CONTEXTO QUE ACOMPAÑA A UN HALLAZGO, EN CARACTERES
local LARGO_CONTEXTO = 70

-- UNA LLAMADA A NOTA: [^ETIQUETA], SIN ESPACIOS NI CORCHETE DE CIERRE ADENTRO
local PATRON_LLAMADA = "%[%^[^%]%s]+%]"

-- LAS ÓRDENES DE LaTeX ADMITIDAS EN EL TEXTO. SOLO LA FORMA: EL CONTENIDO LO
-- VALIDA EL FILTRO QUE LA TRADUCE, Y FRENA SI ESTÁ MAL
--   \sptext{…}                     volada.lua (SC-62)
--   \num{…} \SI{…}{…} \SIrange{…}  cifras.lua (SC-65)
local PATRONES_LATEX = {
  "^\\sptext{.*}$",
  "^\\num{.*}$",
  "^\\SI{.*}$",
  "^\\SIrange{.*}$",
}

-- UNA CIFRA CON SEPARADOR DE MILES: DÍGITO, PUNTO O COMA, TRES DÍGITOS
local PATRON_MILES = "%d[.,]%d%d%d"

-- UN DÍGITO PEGADO AL %, O SEPARADO POR UN ESPACIO DURO (U+00A0), FINO
-- (U+202F) O LA MARCA DE ESPACIO FIJO ¬ (U+00AC, SC-68): LOS TRES ÚLTIMOS
-- QUEDAN DENTRO DEL MISMO Str
local PATRONES_PORCENTAJE = {
  "%d%%",
  "%d\194\160%%",
  "%d\226\128\175%%",
  "%d\194\172%%",
}

-- LA MARCA DE ESPACIO FIJO (SC-68). SE BUSCA COMO CADENA LITERAL
local MARCA_ESPACIO_FIJO = "\u{00AC}"

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
-- Función   : latex_admitido
-- Propósito : Dice si una orden de LaTeX en línea es de las admitidas
-- Parámetros: sTexto — el texto de la orden
-- Retorna   : boolean
-- ============================================================================
local function latex_admitido(sTexto)
  for _, sPatron in ipairs(PATRONES_LATEX) do
    if sTexto:match(sPatron) then return true end
  end
  return false
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
      -- --- 1. LaTeX: SOLO LAS ADMITIDAS, QUE TRADUCEN volada.lua Y cifras.lua ---
      if el.format == "tex" or el.format == "latex" then
        if not latex_admitido(el.text) then
          registrar("latex_en_linea",
            "la orden de LaTeX «" .. contexto(el.text) .. "» se pierde en las tres salidas " ..
            "(las admitidas en el texto son \\sptext, \\num, \\SI y \\SIrange): «" ..
            contexto_crudo(bloque) .. "»")
        end
      -- --- 2. HTML: TODO, MENOS LOS COMENTARIOS ---
      elseif el.format == "html" then
        if not es_comentario(el) then
          registrar("html_crudo",
            "el HTML «" .. contexto(el.text) .. "» se pierde en el XML: «" .. contexto_crudo(bloque) .. "»")
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
-- Función   : revisar_cortes_inlines
-- Propósito : Busca la barra que deja \\ en una lista de inlines del texto,
--             bajando a los contenedores y, como revisar_inlines, sin bajar al
--             contenido de una nota (sus párrafos los visita el walk). El
--             código y la matemática no son Str: no se miran.
-- Parámetros: aInlines — lista de inlines; bloque — el bloque que los
--             contiene, para el contexto del mensaje
-- ============================================================================
local function revisar_cortes_inlines(aInlines, bloque)
  for _, el in ipairs(aInlines) do
    if el.t == "Str" then
      -- UNA BARRA SEGUIDA DE LETRAS ES UNA ORDEN QUE PANDOC NO LEYÓ COMO LaTeX
      -- PORQUE LE FALTAN ARGUMENTOS (\SI{3}, MEDIDO): NO ES UN CORTE
      if el.text:find("\\%a") then
        registrar("latex_en_linea",
          "la orden «" .. el.text .. "» está incompleta (le faltan argumentos o llaves) " ..
          "y sale como texto literal: «" .. contexto(bloque) .. "»")
      elseif el.text:find("\\", 1, true) then
        registrar("corte_fuera_de_titulo",
          "el corte \\\\ solo vale en un título; en el texto sale como una barra " ..
          "(para un salto, ::: espaciov): «" .. contexto(bloque) .. "»")
      end
    elseif el.t == "Note" then
      -- SUS PÁRRAFOS LOS VISITA EL WALK DE BLOQUES
    elseif el.t == "Image" then
      revisar_cortes_inlines(el.caption, bloque)
    elseif el.content then
      revisar_cortes_inlines(el.content, bloque)
    end
  end
end

-- ============================================================================
-- Función   : revisar_cortes
-- Propósito : La barra de \\ en todo bloque con texto que no es un título.
--             En un título la traduce corte-titulo.lua (SC-63).
-- Parámetros: doc — el documento
-- ============================================================================
local function revisar_cortes(doc)
  doc:walk({
    Para = function(b) revisar_cortes_inlines(b.content, b) end,
    Plain = function(b) revisar_cortes_inlines(b.content, b) end,
    LineBlock = function(b)
      for _, aLinea in ipairs(b.content) do revisar_cortes_inlines(aLinea, b) end
    end,
  })
end

-- ============================================================================
-- Función   : revisar_cifras_inlines
-- Propósito : Busca porcentajes y cifras con separador de miles escritos
--             sueltos, fuera de las órdenes de siunitx (SC-64). Baja a los
--             contenedores pero no a una nota (sus párrafos los visita el
--             walk), ni a un enlace o una cita: un DOI (10.1016/…) o una URL
--             no son cifras. El código y la matemática no son Str.
-- Parámetros: aInlines — lista de inlines; bloque — el bloque que los
--             contiene, para el contexto del mensaje
-- ============================================================================
local function revisar_cifras_inlines(aInlines, bloque)
  local el, sig, sig2
  for i = 1, #aInlines do
    el = aInlines[i]
    if el.t == "Str" then
      -- --- 1. PORCENTAJE PEGADO, O CON ESPACIO DURO O FINO ---
      for _, sPatron in ipairs(PATRONES_PORCENTAJE) do
        if el.text:find(sPatron) then
          registrar("porcentaje_suelto",
            "el porcentaje «" .. el.text .. "» está escrito suelto: va \\SI{…}{\\percent} (con una sola cifra, " ..
            "en letras: «4 por ciento»): «" .. contexto_crudo(bloque) .. "»")
          break
        end
      end
      -- --- 2. PORCENTAJE SEPARADO POR UN ESPACIO COMÚN: «88 %» ---
      sig, sig2 = aInlines[i + 1], aInlines[i + 2]
      if el.text:find("%d$") and sig and sig.t == "Space" and sig2 and sig2.t == "Str"
         and sig2.text:find("^%%") then
        registrar("porcentaje_suelto",
          "el porcentaje «" .. el.text .. " " .. sig2.text .. "» está escrito suelto: va \\SI{…}{\\percent} (con una sola cifra, " ..
          "en letras: «4 por ciento»): «" .. contexto_crudo(bloque) .. "»")
      end
      -- --- 3. SEPARADOR DE MILES; CON BARRA ES UN NÚMERO DE IDENTIDAD O UN DOI ---
      if el.text:find(PATRON_MILES) and not el.text:find("/", 1, true) then
        registrar("cifra_fuera_de_num",
          "la cifra «" .. el.text .. "» no está en \\num{…} y sale sin el agrupamiento " ..
          "de la norma (si es un número de ley o de decreto, queda así): «" ..
          contexto_crudo(bloque) .. "»")
      end
    elseif el.t == "Note" or el.t == "Link" or el.t == "Cite" then
      -- LA NOTA LA VISITA EL WALK; EL ENLACE Y LA CITA NO SON TEXTO CON CIFRAS
    elseif el.t == "Image" then
      revisar_cifras_inlines(el.caption, bloque)
    elseif el.content then
      revisar_cifras_inlines(el.content, bloque)
    end
  end
end

-- ============================================================================
-- Función   : revisar_cifras
-- Propósito : Porcentajes y cifras sueltos en todo bloque con texto,
--             títulos incluidos (SC-64, SC-65)
-- Parámetros: doc — el documento
-- ============================================================================
local function revisar_cifras(doc)
  doc:walk({
    Para = function(b) revisar_cifras_inlines(b.content, b) end,
    Plain = function(b) revisar_cifras_inlines(b.content, b) end,
    Header = function(b) revisar_cifras_inlines(b.content, b) end,
    LineBlock = function(b)
      for _, aLinea in ipairs(b.content) do revisar_cifras_inlines(aLinea, b) end
    end,
  })
end

-- ============================================================================
-- Función   : es_espacio
-- Propósito : Dice si un inline es un espacio común, o si no hay inline (el
--             borde de la lista): lo que no puede tocar a un ¬
-- Parámetros: el — el inline vecino, o nil
-- Retorna   : boolean
-- ============================================================================
local function es_espacio(el)
  if el == nil then return true end
  return el.t == "Space" or el.t == "SoftBreak" or el.t == "LineBreak"
end

-- ============================================================================
-- Función   : revisar_espacio_fijo_inlines
-- Propósito : Busca un ¬ al borde de un Str que toca un espacio o el borde
--             de la lista (SC-68). Pegado a otro inline («siglo¬*XX*») está
--             bien. Baja a los contenedores, no a una nota (sus párrafos
--             los visita el walk). En una cita, el prefijo y el sufijo son
--             listas propias: se revisan igual.
-- Parámetros: aInlines — lista de inlines; bloque — el bloque que los
--             contiene, para el contexto del mensaje
-- ============================================================================
local function revisar_espacio_fijo_inlines(aInlines, bloque)
  local el, bSuelto
  for i = 1, #aInlines do
    el = aInlines[i]
    if el.t == "Str" then
      -- --- 1. UN SOLO HALLAZGO POR Str, AUNQUE TOQUE ESPACIOS DE LOS DOS LADOS ---
      bSuelto = false
      if el.text:sub(1, #MARCA_ESPACIO_FIJO) == MARCA_ESPACIO_FIJO and es_espacio(aInlines[i - 1]) then
        bSuelto = true
      end
      if el.text:sub(-#MARCA_ESPACIO_FIJO) == MARCA_ESPACIO_FIJO and es_espacio(aInlines[i + 1]) then
        bSuelto = true
      end
      if bSuelto then
        registrar("espacio_fijo_suelto",
          "el espacio fijo de «" .. el.text .. "» toca un espacio común o el borde de la línea: " ..
          "¬ va entre dos palabras, sin espacios (siglo¬XX): «" .. contexto_crudo(bloque) .. "»")
      end
    elseif el.t == "Note" then
      -- LA NOTA LA VISITA EL WALK
    elseif el.t == "Cite" then
      for _, oCita in ipairs(el.citations) do
        revisar_espacio_fijo_inlines(oCita.prefix, bloque)
        revisar_espacio_fijo_inlines(oCita.suffix, bloque)
      end
    elseif el.t == "Image" then
      revisar_espacio_fijo_inlines(el.caption, bloque)
    elseif el.content then
      revisar_espacio_fijo_inlines(el.content, bloque)
    end
  end
end

-- ============================================================================
-- Función   : revisar_espacio_fijo
-- Propósito : El ¬ suelto en todo bloque con texto, títulos incluidos
-- Parámetros: doc — el documento
-- ============================================================================
local function revisar_espacio_fijo(doc)
  doc:walk({
    Para = function(b) revisar_espacio_fijo_inlines(b.content, b) end,
    Plain = function(b) revisar_espacio_fijo_inlines(b.content, b) end,
    Header = function(b) revisar_espacio_fijo_inlines(b.content, b) end,
    LineBlock = function(b)
      for _, aLinea in ipairs(b.content) do revisar_espacio_fijo_inlines(aLinea, b) end
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
-- Función   : listar_cuadros
-- Propósito : Los archivos de cuadro que nombra el .md, en el orden en que
--             aparecen y sin repetir (SC-75). Son fuentes del canónico:
--             cuadro-leer.lua copia su contenido adentro, así que un cambio
--             en uno deja viejo al canónico aunque el .md no cambie.
-- Parámetros: doc — el documento
-- Retorna   : tabla de rutas relativas a la raíz (cuadros/tbl-nombre.md)
-- Nota      : LA MISMA REGLA QUE cuadro-leer.lua (leer_cuadro, apartado 2):
--             UN ::: {.cuadro #id} ES EL ARCHIVO cuadros/{id}.md. SI CAMBIA
--             ALLÁ, CAMBIA ACÁ. SE REPITE EN VEZ DE QUE LA LISTA LA ESCRIBA
--             cuadro-leer.lua PORQUE ESTE FILTRO ESTÁ EN engine/ Y NO SE
--             MODIFICA (SC-11): LA HUELLA NO PUEDE DEPENDER DE UNA COPIA LOCAL.
--             SOLO LOS id VÁLIDOS PARA cuadro-leer.lua (tbl- Y LETRAS, CIFRAS
--             Y GUIONES): UNO INVÁLIDO LO FRENA ESE FILTRO, Y ASÍ NINGUNA RUTA
--             LISTADA SALE DE cuadros/ NI TRAE COMILLAS
-- ============================================================================
local function listar_cuadros(doc)
  local aRutas = {}
  local hVistos = {}
  doc:walk({
    Div = function(el)
      if el.classes:includes("cuadro") and el.identifier:match("^tbl%-[%w%-]+$") then
        local sRuta = "cuadros/" .. el.identifier .. ".md"
        if not hVistos[sRuta] then
          hVistos[sRuta] = true
          table.insert(aRutas, sRuta)
        end
      end
      return nil
    end,
  })
  return aRutas
end

-- ============================================================================
-- Función   : Pandoc
-- Propósito : Corre los controles y escribe el informe y la lista de
--             cuadros. El documento no se toca.
-- ============================================================================
function Pandoc(doc)
  if not doc.meta["gb-controles"] then
    error("controles_md.lua: falta --metadata gb-controles=RUTA")
  end
  local sRuta = pandoc.utils.stringify(doc.meta["gb-controles"])
  if not doc.meta["gb-fuentes"] then
    error("controles_md.lua: falta --metadata gb-fuentes=RUTA")
  end
  local sRutaFuentes = pandoc.utils.stringify(doc.meta["gb-fuentes"])
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
  revisar_cortes(doc)
  revisar_cifras(doc)
  revisar_espacio_fijo(doc)

  -- --- EL INFORME: SIEMPRE SE ESCRIBE, VACÍO SI NO HUBO HALLAZGOS ---
  local h = io.open(sRuta, "w")
  if not h then
    error("controles_md.lua: no se pudo escribir " .. sRuta)
  end
  for _, a in ipairs(aHallazgos) do
    h:write(a[1], "\t", a[2], "\t", a[3], "\n")
  end
  h:close()

  -- --- LOS CUADROS: SIEMPRE SE ESCRIBE, VACÍO SI NO HAY (SC-75) ---
  h = io.open(sRutaFuentes, "w")
  if not h then
    error("controles_md.lua: no se pudo escribir " .. sRutaFuentes)
  end
  for _, sCuadro in ipairs(listar_cuadros(doc)) do
    h:write(sCuadro, "\n")
  end
  h:close()

  return nil
end
