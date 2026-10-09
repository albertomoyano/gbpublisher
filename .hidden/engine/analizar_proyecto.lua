-- ============================================================================
-- Filtro     : analizar_proyecto.lua
-- Propósito  : Recorre el AST de un .md del proyecto y emite REGISTROS DE
--              CONTEO para la solapa «Escanear» de FMain (gvAnalizarProyecto).
--              NO modifica el documento: solo cuenta. La agregación, el cruce
--              con el catálogo de shortcodes y con el .bib, y el armado de la
--              grilla los hace Gambas (m_AnalizarProyecto).
-- Invocación : desde m_AnalizarProyecto, con Exec y array (SC-05), SIN los
--              filtros de producción: varios serializan el contenido a XML
--              crudo (pandoc.write) y otros frenan ante un bloque mal formado.
--                pandoc ARCHIVO.md --from markdown --to plain
--                       --lua-filter analizar_proyecto.lua --output /dev/null
--              Modo bibliografía (un YAML con nocite: '@*' como entrada):
--                pandoc NOCITE.md --from markdown --to plain
--                       --bibliography ref-X.bib --metadata gb-analisis=bib
--                       --lua-filter analizar_proyecto.lua --output /dev/null
-- Salida     : por stdout (el documento va a /dev/null), un registro por
--              línea, campos separados por NUL. El primer campo es el tipo:
--                B  ctx clase parrafo palabras cc cs inicio   bloque de texto
--                H  nivel palabras cc cs                      título
--                N                                            nota al pie
--                G                                            cita (nodo Cite)
--                C  clave                                     clave citada
--                D  clase                                     div con clase
--                S  clase                                     span con clase
--                M  d|i                                       fórmula
--                F / T / I / L / Q / LI / CB                  figura, tabla,
--                     imagen, enlace, cita en bloque, ítem de lista, código
--                R  clave año                                 entrada del .bib
--              ctx: cuerpo, nota, cita, lista, leyenda, tabla.
--              cc / cs: caracteres con espacios / sin espacios (utf8.len).
-- Ubicación  : engine/ — NO se copia a ~/.gbpublisher (SC-11): es
--              infraestructura de la aplicación y no se ajusta localmente.
-- ============================================================================

-- LAS MEDICIONES QUE SOSTIENEN ESTE FILTRO SE HICIERON CON 3.1.3.
-- EN UNA VERSIÓN MENOR, must_be_at_least ABORTA CON ERROR (PANDOC SALE CON 83)
PANDOC_VERSION:must_be_at_least("3.1.3")

local NUL = "\0"

-- CANTIDAD DE PALABRAS DEL INICIO DE PÁRRAFO QUE VIAJAN COMO REFERENCIA
-- PARA UBICAR EL PÁRRAFO MÁS LARGO
local PALABRAS_INICIO = 8

-- ============================================================================
-- 1. PALABRAS Y CARACTERES
-- ============================================================================

-- PUNTUACIÓN NO ASCII QUE, SOLA, NO HACE PALABRA. LOS PATRONES DE LUA
-- TRABAJAN POR BYTES Y %a / %p NO RECONOCEN NADA FUERA DE ASCII: SE
-- RECORRE POR PUNTOS DE CÓDIGO CON utf8.codes Y SE CLASIFICA A MANO.
local PUNTUACION_UNICODE = {
  [0x00A1] = true,  -- ¡
  [0x00AB] = true,  -- «
  [0x00B7] = true,  -- ·
  [0x00BB] = true,  -- »
  [0x00BF] = true,  -- ¿
}

-- ============================================
-- Función   : EsPuntuacion
-- Propósito : DICE SI UN PUNTO DE CÓDIGO ES PUNTUACIÓN O ESPACIO
-- Parámetros: iCodigo — punto de código Unicode
-- Retorna   : boolean
-- ============================================
local function EsPuntuacion(iCodigo)

  -- ASCII: TODO LO QUE NO ES LETRA NI DÍGITO
  if iCodigo < 0x80 then
    local sCar = string.char(iCodigo)
    return not sCar:match("%w")
  end

  -- PUNTUACIÓN LATINA SUELTA Y EL BLOQUE «PUNTUACIÓN GENERAL»
  -- (U+2000–U+206F: RAYAS, COMILLAS, PUNTOS SUSPENSIVOS, ESPACIOS FINOS)
  if PUNTUACION_UNICODE[iCodigo] then return true end
  if iCodigo >= 0x2000 and iCodigo <= 0x206F then return true end
  if iCodigo == 0x00A0 then return true end

  return false

end

-- ============================================
-- Función   : EsPalabra
-- Propósito : UN Str ES PALABRA SI TIENE AL MENOS UN CARÁCTER QUE NO SEA
--             PUNTUACIÓN. ES EL CRITERIO DEL wordcount.lua DE LA
--             DOCUMENTACIÓN DE PANDOC, EXTENDIDO A UTF-8.
-- Parámetros: sTexto — el texto del Str
-- Retorna   : boolean
-- ============================================
local function EsPalabra(sTexto)

  for _, iCodigo in utf8.codes(sTexto) do
    if not EsPuntuacion(iCodigo) then return true end
  end
  return false

end

-- ============================================
-- Función   : NuevoContador
-- Propósito : ACUMULADOR DE UN BLOQUE DE TEXTO
-- Retorna   : table — palabras, cc, cs, inicio
-- ============================================
local function NuevoContador()

  return { palabras = 0, cc = 0, cs = 0, inicio = {} }

end

-- ============================================================================
-- 2. EMISIÓN
-- ============================================================================

-- ============================================
-- Función   : Emitir
-- Propósito : ESCRIBE UN REGISTRO EN stdout, CAMPOS SEPARADOS POR NUL
-- Parámetros: ... — los campos, el primero es el tipo
-- ============================================
local function Emitir(...)

  local aCampos = table.pack(...)
  local aTexto = {}
  for i = 1, aCampos.n do
    aTexto[i] = tostring(aCampos[i])
  end
  io.write(table.concat(aTexto, NUL), "\n")

end

-- DECLARACIÓN ADELANTADA: BLOQUES E INLINES SE LLAMAN ENTRE SÍ
local RecorrerBloques

-- ============================================================================
-- 3. INLINES
-- ============================================================================

-- ============================================
-- Función   : RecorrerInlines
-- Propósito : SUMA PALABRAS Y CARACTERES DE UNA LISTA DE INLINES EN EL
--             CONTADOR, Y EMITE LOS ELEMENTOS QUE SE CUENTAN APARTE
-- Parámetros: aInlines — lista de inlines
--             oCont — contador del bloque en curso
--             sClase — clase del div que contiene el bloque
-- ============================================
local function RecorrerInlines(aInlines, oCont, sClase)

  for _, el in ipairs(aInlines) do
    local t = el.t

    if t == "Str" then
      local iLargo = utf8.len(el.text) or #el.text
      oCont.cc = oCont.cc + iLargo
      oCont.cs = oCont.cs + iLargo
      if EsPalabra(el.text) then
        oCont.palabras = oCont.palabras + 1
        if #oCont.inicio < PALABRAS_INICIO then
          table.insert(oCont.inicio, el.text)
        end
      end

    elseif t == "Space" or t == "SoftBreak" or t == "LineBreak" then
      -- UN ESPACIO IMPRESO: SUMA SOLO A «CON ESPACIOS»
      oCont.cc = oCont.cc + 1

    elseif t == "Quoted" then
      -- CON smart, «"…"» LLEGA COMO Quoted Y LAS COMILLAS NO SON Str:
      -- SE SUMAN LAS DOS QUE SE VAN A IMPRIMIR
      oCont.cc = oCont.cc + 2
      oCont.cs = oCont.cs + 2
      RecorrerInlines(el.content, oCont, sClase)

    elseif t == "Cite" then
      -- EL TEXTO DEL Cite ES EL CRUDO ([@clave, p. 3]): NO SON PALABRAS
      -- DEL TEXTO. SE CUENTA LA CITA Y CADA CLAVE
      Emitir("G")
      for _, oCita in ipairs(el.citations) do
        Emitir("C", oCita.id)
      end

    elseif t == "Note" then
      -- LA NOTA SE MIDE APARTE: SUS PALABRAS NO SON DEL PÁRRAFO
      Emitir("N")
      RecorrerBloques(el.content, "nota", sClase)

    elseif t == "Math" then
      Emitir("M", el.mathtype == "DisplayMath" and "d" or "i")

    elseif t == "Image" then
      -- EL TEXTO ALTERNATIVO REPITE EL PIE DE LA FIGURA (PANDOC 3): NO SE
      -- CUENTA PARA NO DUPLICAR. EL PIE SE MIDE EN EL Figure
      Emitir("I")

    elseif t == "Link" then
      Emitir("L")
      RecorrerInlines(el.content, oCont, sClase)

    elseif t == "Span" then
      -- SHORTCODE DE LÍNEA: SE CUENTA POR SU PRIMERA CLASE
      if #el.classes > 0 then Emitir("S", el.classes[1]) end
      RecorrerInlines(el.content, oCont, sClase)

    elseif t == "Code" or t == "RawInline" then
      -- CÓDIGO Y CRUDO: NO SON PALABRAS DEL TEXTO

    elseif el.content then
      -- Emph, Strong, Underline, Strikeout, Superscript, Subscript,
      -- SmallCaps: SOLO ENVUELVEN TEXTO
      RecorrerInlines(el.content, oCont, sClase)
    end
  end

end

-- ============================================================================
-- 4. BLOQUES
-- ============================================================================

-- ============================================
-- Función   : EmitirTexto
-- Propósito : MIDE UN BLOQUE DE INLINES Y EMITE SU REGISTRO B
-- Parámetros: aInlines — contenido del bloque
--             sCtx — contexto (cuerpo, nota, cita, lista, leyenda, tabla)
--             sClase — clase del div que lo contiene ("" si ninguno)
--             bParrafo — true si es un Para (no Plain ni LineBlock)
-- ============================================
local function EmitirTexto(aInlines, sCtx, sClase, bParrafo)

  local oCont = NuevoContador()
  RecorrerInlines(aInlines, oCont, sClase)

  -- UN BLOQUE SIN NADA MEDIBLE (UNA FIGURA SOLA, POR EJEMPLO) NO SE EMITE
  if oCont.cc == 0 then return end

  Emitir("B", sCtx, sClase, bParrafo and "1" or "0",
    oCont.palabras, oCont.cc, oCont.cs,
    bParrafo and table.concat(oCont.inicio, " ") or "")

end

-- ============================================
-- Función   : RecorrerFilas
-- Propósito : MIDE LAS CELDAS DE UNA LISTA DE FILAS DE TABLA
-- Parámetros: aFilas — lista de Row
--             sClase — clase del div que contiene la tabla
-- ============================================
local function RecorrerFilas(aFilas, sClase)

  for _, oFila in ipairs(aFilas) do
    for _, oCelda in ipairs(oFila.cells) do
      RecorrerBloques(oCelda.contents, "tabla", sClase)
    end
  end

end

-- ============================================
-- Función   : RecorrerBloques
-- Propósito : RECORRE UNA LISTA DE BLOQUES EN UN CONTEXTO DADO
-- Parámetros: aBloques — lista de bloques
--             sCtx — contexto heredado
--             sClase — clase del div más cercano
-- ============================================
RecorrerBloques = function(aBloques, sCtx, sClase)

  for _, el in ipairs(aBloques) do
    local t = el.t

    if t == "Para" then
      -- SOLO ES PÁRRAFO EL Para DEL CUERPO; EN NOTAS, CITAS Y LISTAS
      -- CUENTA PALABRAS PERO NO PÁRRAFOS
      EmitirTexto(el.content, sCtx, sClase, sCtx == "cuerpo")

    elseif t == "Plain" then
      EmitirTexto(el.content, sCtx, sClase, false)

    elseif t == "LineBlock" then
      for _, aLinea in ipairs(el.content) do
        EmitirTexto(aLinea, sCtx, sClase, false)
      end

    elseif t == "Header" then
      local oCont = NuevoContador()
      RecorrerInlines(el.content, oCont, sClase)
      Emitir("H", el.level, oCont.palabras, oCont.cc, oCont.cs)

    elseif t == "BlockQuote" then
      Emitir("Q")
      RecorrerBloques(el.content, "cita", sClase)

    elseif t == "BulletList" or t == "OrderedList" then
      for _, aItem in ipairs(el.content) do
        Emitir("LI")
        RecorrerBloques(aItem, sCtx == "cuerpo" and "lista" or sCtx, sClase)
      end

    elseif t == "DefinitionList" then
      -- CADA ÍTEM ES {TÉRMINO, {DEFINICIONES}}
      for _, oItem in ipairs(el.content) do
        Emitir("LI")
        local sCtxLista = sCtx == "cuerpo" and "lista" or sCtx
        EmitirTexto(oItem[1], sCtxLista, sClase, false)
        for _, aDef in ipairs(oItem[2]) do
          RecorrerBloques(aDef, sCtxLista, sClase)
        end
      end

    elseif t == "Div" then
      -- SHORTCODE DE BLOQUE: SE CUENTA POR SU PRIMERA CLASE, Y SU
      -- CONTENIDO SE MIDE CON ESA CLASE PARA QUE GAMBAS DECIDA, CON EL
      -- CATÁLOGO, SI ES CUERPO, LEYENDA O BLOQUE ESPECIAL
      local sClaseDiv = sClase
      if #el.classes > 0 then
        sClaseDiv = el.classes[1]
        Emitir("D", sClaseDiv)
      end
      RecorrerBloques(el.content, sCtx, sClaseDiv)

    elseif t == "Figure" then
      Emitir("F")
      RecorrerBloques(el.content, sCtx, sClase)
      RecorrerBloques(el.caption.long, "leyenda", sClase)

    elseif t == "Table" then
      Emitir("T")
      RecorrerBloques(el.caption.long, "leyenda", sClase)
      RecorrerFilas(el.head.rows, sClase)
      for _, oCuerpo in ipairs(el.bodies) do
        RecorrerFilas(oCuerpo.head, sClase)
        RecorrerFilas(oCuerpo.body, sClase)
      end
      RecorrerFilas(el.foot.rows, sClase)

    elseif t == "CodeBlock" then
      Emitir("CB")

    end
    -- RawBlock Y HorizontalRule: NO TIENEN TEXTO QUE MEDIR
  end

end

-- ============================================================================
-- 5. BIBLIOGRAFÍA
-- ============================================================================

-- ============================================
-- Función   : EmitirReferencias
-- Propósito : EMITE CLAVE Y AÑO DE CADA ENTRADA DEL .bib. pandoc.utils.references
--             SOLO DEVUELVE LAS CITADAS: LA ENTRADA DEBE TRAER nocite: '@*'
--             EN SU YAML (COMO -M LLEGA COMO TEXTO Y NO COMO CITA, NO SIRVE)
-- Parámetros: doc — el documento
-- ============================================
local function EmitirReferencias(doc)

  for _, oRef in ipairs(pandoc.utils.references(doc)) do
    local sAnio = ""
    -- date={2018/2020} TRAE DOS FECHAS: VALE LA PRIMERA. SIN date NI year
    -- NO HAY issued Y EL AÑO VA VACÍO
    if oRef.issued and oRef.issued["date-parts"] and oRef.issued["date-parts"][1] then
      sAnio = tostring(oRef.issued["date-parts"][1][1] or "")
    end
    Emitir("R", oRef.id, sAnio)
  end

end

-- ============================================================================
-- 6. ENTRADA
-- ============================================================================

-- ============================================
-- Función   : Pandoc
-- Propósito : PUNTO DE ENTRADA DEL FILTRO. NO DEVUELVE NADA: EL DOCUMENTO
--             QUEDA INTACTO
-- Parámetros: doc — el documento
-- ============================================
function Pandoc(doc)

  -- MODO BIBLIOGRAFÍA: SOLO LAS ENTRADAS DEL .bib
  if doc.meta["gb-analisis"] and pandoc.utils.stringify(doc.meta["gb-analisis"]) == "bib" then
    EmitirReferencias(doc)
    return nil
  end

  -- MODO NORMAL: EL CUERPO DEL ARCHIVO
  RecorrerBloques(doc.blocks, "cuerpo", "")
  return nil

end
