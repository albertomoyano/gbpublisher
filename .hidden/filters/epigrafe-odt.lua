-- ============================================================
-- FILTRO      : epigrafe-odt.lua
-- PROPÓSITO   : DA FORMATO AL EPÍGRAFE EN EL ODT (SC-35). EL ODT SE
--               GENERA DIRECTO DEL .md, SIN EL XML CANÓNICO: SIN ESTE
--               FILTRO LAS LLAVES {texto}{atribución} SALDRÍAN COMO TEXTO.
-- ENTRADA     : EL Div epigraph YA PARTIDO POR dos-partes.lua, CON SUS
--               HIJOS .epigrafe-texto Y .epigrafe-atrib.
-- SALIDA      : LOS DOS HIJOS CON custom-style: PANDOC ESCRIBE ESE
--               NOMBRE COMO ESTILO DE PÁRRAFO EN EL ODT. LOS ESTILOS
--               gbEpigrafe Y gbEpigrafeAtrib ESTÁN DEFINIDOS EN
--               ott/reference.ott: BLOQUE A LA DERECHA, 60 % DE LA CAJA,
--               SIN CORTE DE PALABRA; LA ATRIBUCIÓN A LA DERECHA CON EL
--               FILETE DE 0,6 PT COMO BORDE SUPERIOR.
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : DESPUÉS DE dos-partes.lua.
-- ============================================================

-- ESTILOS DE PÁRRAFO DE ott/reference.ott
local ESTILO_TEXTO = 'gbEpigrafe'
local ESTILO_ATRIB = 'gbEpigrafeAtrib'

-- ============================================
-- Función   : Div
-- Propósito : Reemplaza el epígrafe por sus dos partes con estilo propio
-- Parámetros: el As Div
-- Retorna   : table — lista de Div con custom-style; nil si no es epígrafe
-- ============================================
function Div(el)
  if not el.classes:includes('epigraph') then return nil end

  local salida = {}
  for _, hijo in ipairs(el.content) do
    if hijo.t == 'Div' and hijo.classes:includes('epigrafe-texto') then
      salida[#salida + 1] = pandoc.Div(hijo.content, pandoc.Attr('', {}, {['custom-style'] = ESTILO_TEXTO}))
    elseif hijo.t == 'Div' and hijo.classes:includes('epigrafe-atrib') then
      salida[#salida + 1] = pandoc.Div(hijo.content, pandoc.Attr('', {}, {['custom-style'] = ESTILO_ATRIB}))
    end
  end

  -- SIN HIJOS, dos-partes.lua NO CORRIÓ ANTES: ES UN ERROR DE CADENA
  if #salida == 0 then
    error('\n[gbpublisher] epigraph sin partir: dos-partes.lua tiene que correr antes que epigrafe-odt.lua\n', 0)
  end
  return salida
end
