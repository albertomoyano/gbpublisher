-- ============================================================================
-- Filtro     : limpiar_docx.lua
-- Propósito  : Normaliza el AST que produce el lector docx de pandoc según el
--              contrato de ingreso de gbpublisher. Es determinista: el mismo
--              .docx con la misma versión de pandoc produce el mismo .md.
-- Invocación : desde engine/convertir_docx.sh, con el directorio temporal de
--              la conversión como directorio de trabajo:
--                pandoc ... --lua-filter=limpiar_docx.lua -M gbp-prefijo=NOMBRE
-- Salida     : el AST transformado, y el archivo conteo.tsv en el directorio
--              de trabajo (clave TAB cantidad, claves ordenadas).
-- Ubicación  : engine/ — NO se copia a ~/.gbpublisher (SC-11): define el
--              contrato de ingreso y no se ajusta localmente.
-- ============================================================================

-- VERSIÓN DEL FILTRO: VA AL INFORME. CAMBIARLA CON CADA CAMBIO DE COMPORTAMIENTO
local VERSION_FILTRO = "1.0"

-- LAS MEDICIONES QUE SOSTIENEN ESTE FILTRO SE HICIERON CON 3.1.3.
-- EN UNA VERSIÓN MENOR, must_be_at_least ABORTA CON ERROR (PANDOC SALE CON 83)
PANDOC_VERSION:must_be_at_least("3.1.3")

local NBSP = "\u{00A0}"
local SHY  = "\u{00AD}"

-- ESTILOS DE WORD QUE EL LECTOR DOCX MANDA A METADATOS CUANDO ENCABEZAN EL
-- DOCUMENTO (Readers/Docx.hs, metaStyles). SIN -s EL TEXTO DESAPARECERÍA DEL
-- .md: SE REINSERTA COMO PÁRRAFO NORMAL, EN ESTE ORDEN FIJO
local CAMPOS_METADATO = { "title", "subtitle", "author", "date", "abstract" }

local cuenta = {}
local prefijo = ""
local renombradas = {}   -- src ORIGINAL -> src NUEVO (UNA IMAGEN PUEDE REFERIRSE VARIAS VECES)

-- ============================================
-- Función   : sumar
-- Propósito : Acumula un contador del informe
-- Parámetros: clave As string — nombre del concepto
--             n As number (opcional) — cantidad, 1 por defecto
-- Retorna   : nada
-- ============================================
local function sumar(clave, n)
  cuenta[clave] = (cuenta[clave] or 0) + (n or 1)
end

-- ============================================
-- Función   : es_blanco
-- Propósito : Indica si un inline es espacio en blanco
-- Parámetros: el As Inline
-- Retorna   : boolean
-- ============================================
local function es_blanco(el)
  return el.t == "Space" or el.t == "SoftBreak"
end

-- ============================================
-- Función   : compactar
-- Propósito : Colapsa espacios consecutivos y quita los de los extremos. Hace
--             falta porque convertir espacios duros o saltos de línea en Space
--             puede dejar dos seguidos, o uno al principio de un párrafo
-- Parámetros: inlines As List of Inline
-- Retorna   : List of Inline
-- ============================================
local function compactar(inlines)
  local salida = pandoc.List()
  for _, el in ipairs(inlines) do
    if es_blanco(el) then
      -- SOLO SE AGREGA SI HAY ALGO ANTES Y LO ANTERIOR NO ES BLANCO
      if #salida > 0 and not es_blanco(salida[#salida]) then
        salida:insert(pandoc.Space())
      end
    else
      salida:insert(el)
    end
  end
  -- QUITAR EL BLANCO FINAL
  while #salida > 0 and es_blanco(salida[#salida]) do
    salida:remove()
  end
  return salida
end

-- ============================================
-- Función   : a_bloques
-- Propósito : Convierte un valor de metadatos en bloques de párrafo normal
-- Parámetros: valor As MetaValue
-- Retorna   : List of Block
-- ============================================
local function a_bloques(valor)
  local bloques = pandoc.List()
  local tipo = pandoc.utils.type(valor)
  if tipo == "Inlines" then
    bloques:insert(pandoc.Para(valor))
  elseif tipo == "Blocks" then
    bloques:extend(valor)
  elseif tipo == "List" then
    -- VARIOS PÁRRAFOS SEGUIDOS CON EL MISMO ESTILO (POR EJEMPLO, VARIOS AUTORES)
    for _, item in ipairs(valor) do
      bloques:extend(a_bloques(item))
    end
  elseif tipo == "string" then
    bloques:insert(pandoc.Para(pandoc.Inlines(valor)))
  end
  return bloques
end

-- --- 1. PRIMERA PASADA: LEER EL PREFIJO QUE PASA EL SCRIPT ---
-- VA EN SU PROPIA PASADA PORQUE Meta SE RECORRE DESPUÉS DE LOS ELEMENTOS
local pasada_parametros = {
  Meta = function(meta)
    if meta["gbp-prefijo"] then
      prefijo = pandoc.utils.stringify(meta["gbp-prefijo"])
    end
  end,
}

-- --- 2. SEGUNDA PASADA: REINSERTAR EN EL CUERPO LO QUE EL LECTOR MANDÓ A METADATOS ---
local pasada_metadatos = {
  Pandoc = function(doc)
    local cabecera = pandoc.List()
    for _, campo in ipairs(CAMPOS_METADATO) do
      if doc.meta[campo] then
        local bloques = a_bloques(doc.meta[campo])
        sumar("estilo_metadato:" .. campo, #bloques)
        cabecera:extend(bloques)
        doc.meta[campo] = nil
      end
    end
    if #cabecera > 0 then
      cabecera:extend(doc.blocks)
      doc.blocks = cabecera
    end
    return doc
  end,
}

-- --- 3. TERCERA PASADA: LIMPIEZA DE INLINES E IMÁGENES ---
local pasada_limpieza = {

  -- SUBRAYADO, VERSALITAS Y RESALTADO PASAN A TEXTO NORMAL.
  -- SE DEVUELVE EL CONTENIDO: ASÍ LAS VERSALITAS CONSERVAN LA CAJA ORIGINAL
  Underline = function(el)
    sumar("subrayado")
    return el.content
  end,

  SmallCaps = function(el)
    sumar("versalitas")
    return el.content
  end,

  Span = function(el)
    if el.classes:includes("mark") then
      sumar("resaltado")
      return el.content
    end
  end,

  -- GUION BLANDO DESAPARECE; ESPACIO DURO SE CONVIERTE EN Space DEL AST
  -- (UN " " DENTRO DE UN Str NO ES UN ESPACIO PARA EL ESCRITOR)
  Str = function(el)
    local texto, n_shy = el.text:gsub(SHY, "")
    if n_shy > 0 then sumar("guion_blando", n_shy) end

    if not texto:find(NBSP, 1, true) then
      if n_shy > 0 then return pandoc.Str(texto) end
      return nil
    end

    local _, n_nbsp = texto:gsub(NBSP, "")
    sumar("espacio_duro", n_nbsp)

    local salida = pandoc.List()
    local primero = true
    for trozo in (texto .. NBSP):gmatch("(.-)" .. NBSP) do
      if not primero then salida:insert(pandoc.Space()) end
      if trozo ~= "" then salida:insert(pandoc.Str(trozo)) end
      primero = false
    end
    return salida
  end,

  -- IMÁGENES: NOMBRE ÚNICO POR PIEZA Y SIN ATRIBUTOS DE TAMAÑO.
  -- EL RENOMBRE SE HACE EN EL MEDIABAG: CAMBIAR SOLO src HACE QUE PANDOC NO
  -- ENCUENTRE EL RECURSO Y REEMPLACE LA IMAGEN POR SU TEXTO ALTERNATIVO
  Image = function(el)
    local viejo = el.src
    local nuevo = renombradas[viejo]

    if not nuevo then
      local mime, contenido = pandoc.mediabag.lookup(viejo)
      if not contenido then
        -- IMAGEN VINCULADA, NO EMBEBIDA: NO HAY ARCHIVO QUE EXTRAER
        sumar("imagen_no_embebida")
        el.attributes = {}
        return el
      end
      -- EL "_" NO ESTÁ PERMITIDO EN LOS NOMBRES DE PIEZA: ASÍ EL PREFIJO
      -- a-01-X_ NUNCA COINCIDE CON LAS IMÁGENES DE a-01-X-Y
      nuevo = prefijo .. "_" .. viejo:match("[^/]+$")
      pandoc.mediabag.delete(viejo)
      pandoc.mediabag.insert(nuevo, mime, contenido)
      renombradas[viejo] = nuevo
      sumar("imagenes")
    end

    el.src = nuevo
    el.attributes = {}
    return el
  end,
}

-- --- 4. CUARTA PASADA: SALTOS DE LÍNEA DONDE UN PÁRRAFO NUEVO CAMBIARÍA LA ESTRUCTURA ---
-- EN TÍTULOS, CELDAS DE TABLA E ÍTEMS DE LISTA EL SALTO PASA A ESPACIO.
-- Header, Table Y LAS LISTAS SE PROCESAN ACÁ, ANTES DE PARTIR PÁRRAFOS
local function salto_a_espacio(bloque)
  return bloque:walk({
    LineBreak = function()
      sumar("salto_linea_a_espacio")
      return pandoc.Space()
    end,
  })
end

local pasada_saltos_estructura = {
  traverse = "topdown",
  Header      = function(el) return salto_a_espacio(el), false end,
  Table       = function(el) return salto_a_espacio(el), false end,
  BulletList  = function(el) return salto_a_espacio(el), false end,
  OrderedList = function(el) return salto_a_espacio(el), false end,
}

-- --- 5. QUINTA PASADA: EN PÁRRAFOS, EL SALTO DE LÍNEA ABRE UN PÁRRAFO NUEVO ---
local pasada_saltos_parrafo = {
  Para = function(el)
    local hay_salto = false
    for _, inl in ipairs(el.content) do
      if inl.t == "LineBreak" then hay_salto = true; break end
    end
    if not hay_salto then return nil end

    local parrafos = pandoc.List()
    local actual = pandoc.List()
    for _, inl in ipairs(el.content) do
      if inl.t == "LineBreak" then
        sumar("salto_linea_a_parrafo")
        actual = compactar(actual)
        -- SHIFT+ENTER JUSTO ANTES DEL ENTER DEJARÍA UN PÁRRAFO VACÍO: SE DESCARTA
        if #actual > 0 then parrafos:insert(pandoc.Para(actual)) end
        actual = pandoc.List()
      else
        actual:insert(inl)
      end
    end
    actual = compactar(actual)
    if #actual > 0 then parrafos:insert(pandoc.Para(actual)) end
    return parrafos
  end,
}

-- --- 6. SEXTA PASADA: COMPACTAR ESPACIOS Y ESCRIBIR EL CONTEO ---
local pasada_final = {
  Para   = function(el) el.content = compactar(el.content); return el end,
  Plain  = function(el) el.content = compactar(el.content); return el end,
  Header = function(el) el.content = compactar(el.content); return el end,

  Pandoc = function(doc)
    local claves = {}
    for clave in pairs(cuenta) do claves[#claves + 1] = clave end
    -- pairs NO GARANTIZA ORDEN: SIN ORDENAR, EL CONTEO NO SERÍA DETERMINISTA
    table.sort(claves)

    local f = assert(io.open("conteo.tsv", "w"))
    f:write("version_filtro\t", VERSION_FILTRO, "\n")
    for _, clave in ipairs(claves) do
      f:write(clave, "\t", cuenta[clave], "\n")
    end
    f:close()
  end,
}

return {
  pasada_parametros,
  pasada_metadatos,
  pasada_limpieza,
  pasada_saltos_estructura,
  pasada_saltos_parrafo,
  pasada_final,
}
