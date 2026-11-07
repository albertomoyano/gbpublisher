-- ============================================================
-- FILTRO      : url.lua
-- PROPÓSITO   : CONVIERTE LAS DIRECCIONES ELECTRÓNICAS DEL TEXTO EN
--               ENLACES, PARA QUE CADA SALIDA LAS TRATE COMO TALES: EL PDF
--               LAS CORTA CON \url (LAS REGLAS DE \UrlBreaks DEL
--               PREÁMBULO), Y EL HTML Y EL EPUB LAS HACEN CLICABLES.
--               SIN ESTE FILTRO:
--                 - \url{…} ES LaTeX CRUDO, Y LOS ESCRITORES DE XML LO
--                   DESCARTAN: LA DIRECCIÓN DESAPARECÍA (GV-116);
--                 - UNA DIRECCIÓN SUELTA ES TEXTO COMÚN: EL PDF NO LA
--                   PUEDE CORTAR Y DESBORDA EL MARGEN (MEDIDO, NOTA 19 DE
--                   JENSEN, 7/11/2026).
-- ENTRADA     : \url{https://…}   LA FORMA DEL PROYECTO, LA MISMA QUE EN
--                                 LaTeX (DECISIÓN DE ALBERTO, 7/11)
--               https://…         SUELTA: SE CONVIERTE IGUAL, Y
--                                 controles_md.lua AVISA QUE VA CON \url
-- SALIDA      : UN Link CON LA CLASE uri Y LA DIRECCIÓN COMO TEXTO, EL MISMO
--               QUE PANDOC ARMA PARA <https://…>:
--                 DOCBOOK (LIBRO)  <link xlink:href="…" role="uri">…</link>
--                 JATS (REVISTA)   <ext-link ext-link-type="uri" xlink:href="…">…</ext-link>
--                 ODT              UN HIPERVÍNCULO
--               docbook-to-latex.xsl Y jats-to-latex.xsl LO VUELVEN A \url{…}.
-- EL %        : DENTRO DE \url{…} VA \%, COMO EN LaTeX DENTRO DE UNA NOTA.
--               SIN LA BARRA, EL LECTOR DE PANDOC TOMA EL % POR UN
--               COMENTARIO DE TeX Y SE TRAGA EL TEXTO QUE SIGUE (MEDIDO CON
--               pandoc 3.1.3: «\url{https://a.org/a%20b} sigue.» PIERDE
--               «sigue.»). ESE CASO FRENA ACÁ Y EN controles_md.lua. ADENTRO
--               SE ADMITEN \% \# \& \_ \~, QUE PASAN A % # & _ ~.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE LAS COMILLAS (UNA DIRECCIÓN ENTRE « » QUEDA
--               ADENTRO DEL Quoted) Y ANTES DE TODO FILTRO QUE SERIALICE
--               CON pandoc.write: LIBRO, DESPUÉS DE guillemets Y ANTES DE
--               volada; REVISTA, DESPUÉS DE quoted-a-nivel-jats Y ANTES DE
--               cite-to-xref; ODT, DESPUÉS DE espacio-fijo.
-- REGLA       : LO QUE NO SE PUEDE CONVERTIR SIN PERDER TEXTO FRENA LA
--               CONVERSIÓN CON UN MENSAJE: NUNCA SE DEGRADA EN SILENCIO.
-- ============================================================

-- LA ORDEN QUE ESTE FILTRO TRADUCE: EXACTAMENTE \url{…}, CON LAS LLAVES
-- BALANCEADAS Y NADA DESPUÉS
local PATRON_ORDEN = '^\\url(%b{})$'

-- EL COMIENZO DE UNA DIRECCIÓN SUELTA. SOLO http Y https: ES LO QUE APARECE
-- EN LOS TEXTOS, Y UN ESQUEMA MÁS AMPLIO TOMARÍA TEXTO QUE NO ES DIRECCIÓN
local PATRON_SUELTA = 'https?://'

-- LOS SIGNOS QUE CIERRAN LA ORACIÓN O EL PARÉNTESIS Y NO SON DE LA DIRECCIÓN
-- CUANDO VAN AL FINAL: «(https://a.org/x).» TERMINA EN x. LOS DE VARIOS
-- BYTES (» ” ’) SE TRATAN APARTE
local FINALES_ASCII = '[%.,;:!%?%)%]}\'"]'
local FINALES_UTF8 = { '»', '”', '’' }

-- LAS SECUENCIAS DE ESCAPE DE LaTeX QUE SE ADMITEN DENTRO DE \url{…}
local ESCAPES = { ['\\%'] = '%', ['\\#'] = '#', ['\\&'] = '&', ['\\_'] = '_', ['\\~'] = '~' }

-- ============================================
-- Función   : fallar
-- Propósito : Detiene la conversión con un mensaje que nombra el problema
-- Parámetros: motivo As String — qué está mal
-- Retorna   : no retorna: error() corta pandoc con código distinto de 0
-- ============================================
local function fallar(motivo)
  error('\nurl.lua: ' .. motivo ..
    '\n  Se escribe \\url{https://…}. Un % de la dirección va \\% (como en' ..
    '\n  LaTeX dentro de una nota): https://a.org/a\\%20b.\n', 0)
end

-- ============================================
-- Función   : enlace
-- Propósito : El Link de una dirección, con la forma que pandoc da a <…>
-- Parámetros: sUrl As String — la dirección
-- Retorna   : pandoc.Link
-- ============================================
local function enlace(sUrl)
  return pandoc.Link({ pandoc.Str(sUrl) }, sUrl, '', pandoc.Attr('', { 'uri' }))
end

-- ============================================
-- Función   : orden_url
-- Propósito : \url{…} a enlace
-- Parámetros: el As RawInline
-- Retorna   : pandoc.Link, o nil si no es \url
-- ============================================
local function orden_url(el)
  local sLlaves, sUrl

  -- --- 1. ¿ES \url? ---
  if el.format ~= 'tex' and el.format ~= 'latex' then return nil end
  if el.text:sub(1, 5) ~= '\\url{' then return nil end

  -- --- 2. LA FORMA: SI SIGUE TEXTO DESPUÉS DE LA LLAVE, EL LECTOR LO TRAGÓ ---
  -- ES EL CASO DEL % SIN BARRA: EL TEXTO QUE VENÍA DESPUÉS YA NO ESTÁ EN SU
  -- LUGAR, Y CONVERTIR ESTO LO PERDERÍA
  sLlaves = el.text:match(PATRON_ORDEN)
  if not sLlaves then
    -- SE MUESTRA HASTA LA PRIMERA LLAVE QUE CIERRA: LO QUE SIGUE ES EL TEXTO
    -- QUE EL LECTOR DESORDENÓ, Y NO LE DICE NADA AL EDITOR
    fallar('la dirección «' .. (el.text:match('^\\url%b{}') or el.text:sub(1, 80)) ..
      '» no se pudo leer: casi seguro tiene un % sin la barra, y el texto que la seguía se perdió.')
  end

  -- --- 3. EL CONTENIDO, SIN LOS ESCAPES ---
  sUrl = sLlaves:sub(2, -2):gsub('\\[%%#&_~]', ESCAPES)
  if sUrl:match('^%s*$') then fallar('hay un \\url{} vacío.') end
  if sUrl:find('%s') then fallar('la dirección «' .. sUrl .. '» tiene espacios.') end
  if sUrl:find('\\', 1, true) then
    fallar('la dirección «' .. sUrl .. '» tiene una barra invertida que no es de las admitidas (\\% \\# \\& \\_ \\~).')
  end

  return enlace(sUrl)
end

-- ============================================
-- Función   : quitar_final
-- Propósito : Separa del final de una dirección los signos que no son de
--             ella. Un ) se queda si la dirección abre más ( de los que
--             cierra: https://es.wikipedia.org/wiki/Gambas_(lenguaje)
-- Parámetros: sUrl As String — la dirección con lo que la seguía
-- Retorna   : String, String — la dirección y lo que sobra
-- ============================================
local function quitar_final(sUrl)
  local sResto = ''
  local bCambio = true
  local _, nAbre, nCierra, sFin

  while bCambio and #sUrl > 0 do
    bCambio = false
    -- LOS DE VARIOS BYTES
    for _, sFin in ipairs(FINALES_UTF8) do
      if sUrl:sub(-#sFin) == sFin then
        sResto = sFin .. sResto
        sUrl = sUrl:sub(1, -#sFin - 1)
        bCambio = true
      end
    end
    -- LOS ASCII. EL ) SOLO SI NO CIERRA UN ( DE LA DIRECCIÓN
    local sUltimo = sUrl:sub(-1)
    if sUltimo:match(FINALES_ASCII) then
      _, nAbre = sUrl:gsub('%(', '')
      _, nCierra = sUrl:gsub('%)', '')
      if sUltimo ~= ')' or nCierra > nAbre then
        sResto = sUltimo .. sResto
        sUrl = sUrl:sub(1, -2)
        bCambio = true
      end
    end
  end
  return sUrl, sResto
end

-- ============================================
-- Función   : suelta
-- Propósito : Una dirección suelta dentro de un Str a enlace, con lo que la
--             precede y lo que la sigue como Str aparte
-- Parámetros: el As Str
-- Retorna   : lista de inlines, o nil si el Str no tiene dirección
-- ============================================
local function suelta(el)
  local nInicio = el.text:find(PATRON_SUELTA)
  local sAntes, sUrl, sDespues
  local aSalida = {}

  if not nInicio then return nil end
  sAntes = el.text:sub(1, nInicio - 1)
  sUrl, sDespues = quitar_final(el.text:sub(nInicio))

  -- «https://» SOLO NO ES UNA DIRECCIÓN
  if sUrl:match('^https?://$') then return nil end

  if sAntes ~= '' then table.insert(aSalida, pandoc.Str(sAntes)) end
  table.insert(aSalida, enlace(sUrl))
  if sDespues ~= '' then table.insert(aSalida, pandoc.Str(sDespues)) end
  return aSalida
end

-- DE ARRIBA ABAJO: UN ENLACE YA ESCRITO ([texto](url) O <url>) NO SE MIRA
-- POR DENTRO, PORQUE SU TEXTO PUEDE SER LA MISMA DIRECCIÓN. DEVOLVER false
-- COMO SEGUNDO VALOR NO BAJA A LOS HIJOS DE LO QUE SE DEVUELVE
return {
  {
    traverse = 'topdown',
    Link = function(el) return el, false end,
    -- LO QUE ESTE FILTRO ARMA TAMPOCO SE VUELVE A RECORRER: EL TEXTO DEL
    -- ENLACE NUEVO ES LA DIRECCIÓN, Y SE CONVERTIRÍA OTRA VEZ SIN FIN
    RawInline = function(el)
      local oEnlace = orden_url(el)
      if oEnlace then return oEnlace, false end
      return nil
    end,
    Str = function(el)
      local aInlines = suelta(el)
      if aInlines then return aInlines, false end
      return nil
    end,
  }
}
