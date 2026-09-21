-- ============================================================================
-- FILTRO    : guillemets-to-quoted-db.lua
-- PROPÓSITO : CONVIERTE LAS COMILLAS LATINAS « » DEL .md EN NODOS Quoted DEL
--             AST DE PANDOC, ANIDADOS SEGÚN APARECEN. EL WRITER docbook5 LOS
--             EMITE COMO <quote>, Y EL NIVEL TIPOGRÁFICO LO DECIDE DESPUÉS
--             quote.xsl POR PROFUNDIDAD, IGUAL EN LAS TRES SALIDAS.
--
--             MODELO DEL PROYECTO: EN EL .md TODA CITA SE MARCA CON « »,
--             SIN IMPORTAR EL NIVEL. EL NIVEL QUE EL EDITOR ESCRIBE NO LLEGA
--             A LA SALIDA: LLEGA EL ANIDAMIENTO.
--
--             POR QUÉ HACE FALTA: PANDOC SOLO SEMANTIZA LAS COMILLAS RECTAS
--             (EXTENSIÓN smart). LOS GUILLEMETS PASAN COMO TEXTO LITERAL, Y
--             SIN ESTE FILTRO EL CANÓNICO NO SABE QUE AHÍ HAY UNA CITA.
--
-- ORDEN     : DEBE CORRER ANTES QUE fenced-divs-to-elements-db.lua, QUE
--             SERIALIZA EL CONTENIDO DE LOS DIVS CON pandoc.write (RC-DB-07):
--             DESPUÉS DE ESO NO QUEDAN Str QUE PROCESAR.
--
-- DESBALANCE: NO ADIVINA. SI UNA LISTA DE INLINES NO CIERRA, LA DEJA
--             INTACTA —CON LOS CARACTERES LITERALES— Y AVISA POR STDERR.
--             LA PUERTA DE VALIDACIÓN ES EL PANEL DE PARES (m_Pares); ESTE
--             FILTRO CONFÍA Y FALLA VISIBLE.
--
-- LIMITACIÓN: UNA CITA QUE ABRE FUERA DE UNA CURSIVA Y CIERRA DENTRO DE ELLA
--             —«un *texto» citado*— NO TIENE REPRESENTACIÓN COMO ÁRBOL. LAS
--             DOS LISTAS QUEDAN DESBALANCEADAS Y SE AVISA. EL PANEL NO LO
--             DETECTA PORQUE A NIVEL DE TEXTO EL PAR CIERRA.
--
-- REQUIERE  : PANDOC >= 2.17 (FUNCIÓN DE FILTRO Inlines).
-- ============================================================================

local ABRE = "«"
local CIERRA = "»"

-- MARCAS CENTINELA. SE COMPARAN POR IDENTIDAD: UNA TABLA LUA NUNCA ES IGUAL
-- A UN ELEMENTO DE PANDOC, ASÍ QUE NO HAY RIESGO DE CONFUNDIRLAS
local MARCA_ABRE = {}
local MARCA_CIERRA = {}

-- LARGO DEL AVISO POR STDERR, EN CARACTERES
local LARGO_AVISO = 80

-- ============================================================================
-- FUNCIÓN   : tiene_marcas
-- PROPÓSITO : RESPONDE SI UN ELEMENTO ES UN Str QUE CONTIENE ALGÚN GUILLEMET.
--             find CON plain = true BUSCA LA SECUENCIA DE BYTES LITERAL: ES
--             CORRECTO EN UTF-8 VÁLIDO, PORQUE LOS BYTES DE UN CARÁCTER
--             MULTIBYTE NUNCA APARECEN DENTRO DE OTRO (MISMO ARGUMENTO QUE
--             RC-GM-12 PARA InStr)
-- ============================================================================
local function tiene_marcas(el)
  if el.t ~= "Str" then return false end
  if el.text:find(ABRE, 1, true) then return true end
  if el.text:find(CIERRA, 1, true) then return true end
  return false
end

-- ============================================================================
-- FUNCIÓN   : tokenizar
-- PROPÓSITO : PARTE LOS Str QUE CONTIENEN GUILLEMETS. «Hola LLEGA COMO UN
--             SOLO Str Y HAY QUE SEPARAR LA MARCA DEL TEXTO. LOS CORTES SE
--             HACEN JUSTO ANTES Y JUSTO DESPUÉS DE LA SECUENCIA COMPLETA, ASÍ
--             QUE NUNCA PARTEN UN CARÁCTER MULTIBYTE
-- RETORNA   : LISTA MEZCLADA DE ELEMENTOS DE PANDOC Y MARCAS CENTINELA
-- ============================================================================
local function tokenizar(inlines)
  local salida = {}

  for _, el in ipairs(inlines) do
    if tiene_marcas(el) then
      local texto = el.text
      local pos = 1

      while pos <= #texto do
        local a = texto:find(ABRE, pos, true)
        local c = texto:find(CIERRA, pos, true)
        local sig

        -- LA MARCA MÁS CERCANA, SEA CUAL SEA
        if a and c then
          sig = math.min(a, c)
        else
          sig = a or c
        end

        -- NO QUEDAN MARCAS: EL RESTO ES TEXTO
        if not sig then
          table.insert(salida, pandoc.Str(texto:sub(pos)))
          break
        end

        -- TEXTO ANTERIOR A LA MARCA
        if sig > pos then
          table.insert(salida, pandoc.Str(texto:sub(pos, sig - 1)))
        end

        if sig == a then
          table.insert(salida, MARCA_ABRE)
          pos = sig + #ABRE
        else
          table.insert(salida, MARCA_CIERRA)
          pos = sig + #CIERRA
        end
      end
    else
      table.insert(salida, el)
    end
  end

  return salida
end

-- ============================================================================
-- FUNCIÓN   : construir
-- PROPÓSITO : RECONSTRUYE LA LISTA CON UNA PILA DE LISTAS. CADA APERTURA
--             EMPIEZA UNA LISTA NUEVA; CADA CIERRE LA ENVUELVE EN UN Quoted Y
--             LA AGREGA A LA LISTA DE ABAJO. TODAS COMO DoubleQuote: EL NIVEL
--             NO SE DECIDE ACÁ SINO EN quote.xsl
-- RETORNA   : LA LISTA NUEVA, O nil SI HAY DESBALANCE
-- ============================================================================
local function construir(tokens)
  local pila = { {} }

  for _, t in ipairs(tokens) do
    if t == MARCA_ABRE then
      table.insert(pila, {})
    elseif t == MARCA_CIERRA then
      -- CIERRE SIN NADA ABIERTO EN ESTA LISTA
      if #pila == 1 then return nil end
      local contenido = table.remove(pila)
      table.insert(pila[#pila], pandoc.Quoted("DoubleQuote", contenido))
    else
      table.insert(pila[#pila], t)
    end
  end

  -- APERTURA QUE NUNCA CERRÓ EN ESTA LISTA
  if #pila ~= 1 then return nil end

  return pila[1]
end

-- ============================================================================
-- FUNCIÓN   : Inlines
-- PROPÓSITO : PUNTO DE ENTRADA. PANDOC LA INVOCA SOBRE CADA LISTA DE INLINES
--             DEL DOCUMENTO: PÁRRAFOS, TÍTULOS, NOTAS AL PIE, CONTENIDO DE
--             CURSIVAS. UNA CITA CON CURSIVA ADENTRO —«un *texto* citado»—
--             SE RESUELVE EN LA LISTA DEL PÁRRAFO, QUE TIENE LA APERTURA Y EL
--             CIERRE; LA LISTA DE LA CURSIVA NO TIENE MARCAS Y NO SE TOCA.
--             UNA NOTA AL PIE EN MEDIO DE UNA CITA ES UN INLINE MÁS DE LA
--             LISTA; LAS CITAS DENTRO DE LA NOTA SE PROCESAN APARTE
-- RETORNA   : LA LISTA TRANSFORMADA, O nil PARA DEJARLA COMO ESTÁ
-- ============================================================================
function Inlines(inlines)
  local hay = false
  local resultado

  -- LA INMENSA MAYORÍA DE LAS LISTAS NO TIENE GUILLEMETS: SALIR SIN TOCAR
  for _, el in ipairs(inlines) do
    if tiene_marcas(el) then
      hay = true
      break
    end
  end

  if not hay then return nil end

  resultado = construir(tokenizar(inlines))

  if not resultado then
    -- SE AVISA Y SE DEJA INTACTO. pandoc.text.sub CORTA POR CARACTERES Y NO
    -- POR BYTES, ASÍ QUE EL AVISO NO TERMINA EN MEDIO DE UNA TILDE
    io.stderr:write("guillemets-to-quoted: comillas sin cerrar en: " ..
      pandoc.text.sub(pandoc.utils.stringify(inlines), 1, LARGO_AVISO) .. "\n")
    return nil
  end

  return resultado
end
