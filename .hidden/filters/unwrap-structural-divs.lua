-- ============================================================
-- FILTRO       : unwrap-structural-divs.lua
-- PROPÓSITO    : DESENVUELVE LOS DIVS FENCED QUE SON MARCADORES
--                ESTRUCTURALES DE TIPO DE ARTÍCULO O SECCIÓN.
--                SIN ESTE FILTRO, PANDOC --to jats LOS CONVIERTE
--                EN <boxed-text>, CUANDO EL ELEMENTO JATS CORRECTO
--                ES <sec> (O SIMPLEMENTE <p> SUELTOS EN BODY).
-- UBICACIÓN    : ~/.gbpublisher/filters/
-- DEBE CORRER  : ANTES QUE LOS DEMÁS FILTROS EN GenerarBodyXML()
-- ============================================================

-- LISTA DE CLASES PANDOC ESTRUCTURALES
-- DERIVADA DE shortcodes WHERE tipo_marcado='fenced' AND mapeo_revista='sec'.
-- ACTUALIZAR ESTA LISTA CUANDO SE AGREGUE/QUITE UN SHORTCODE FENCED QUE
-- MAPEE A <sec>. VERIFICAR CON:
--   SELECT nombre, sintaxis_apertura FROM shortcodes
--   WHERE tipo_marcado='fenced' AND mapeo_revista='sec' AND activo=1;
-- LA CLAVE DE LA TABLA ES LA CLASE PANDOC (lo que va en sintaxis_apertura),
-- NO EL nombre DEL SHORTCODE EN BD (que puede llevar prefijo "sec-").
local estructurales = {
  ["abstract"]             = true,
  ["acknowledgments"]      = true,
  ["appendix"]             = true,
  ["apparatus-physics"]    = true,
  ["book-review"]          = true,
  ["case-report"]          = true,
  ["conclusions"]          = true,
  ["conflict-of-interest"] = true,
  ["correction"]           = true,
  ["correspondence"]       = true,
  ["discussion"]           = true,
  ["editorial"]            = true,
  ["experimental-procedure"] = true,
  ["intro"]                = true,
  ["methods"]              = true,
  ["obituary"]             = true,
  ["oration"]              = true,
  ["results"]              = true,
  ["retraction"]           = true,
  ["review-article"]       = true,
  ["surgical-procedure"]   = true,
}

--- FUNCIÓN PRINCIPAL: SI EL DIV TIENE UNA CLASE ESTRUCTURAL,
--- DEVOLVER SU CONTENIDO SIN EL WRAPPER (UNWRAP).
--- ASÍ PANDOC EMITE <sec> O <p> DIRECTOS EN VEZ DE <boxed-text>.
function Div(el)
  for _, clase in ipairs(el.classes) do
    if estructurales[clase] then
      return el.content
    end
  end
end
