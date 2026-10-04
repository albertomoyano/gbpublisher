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
-- CLASES PANDOC DE LOS SHORTCODES DE BLOQUE QUE MAPEAN A <sec>: LAS DEL
-- GRUPO estructura DEL CATÁLOGO DE gbShortcodes (shortcodes/_catalogo.tsv,
-- RF-11) Y TRES DISCIPLINARES (apparatus-physics, experimental-procedure,
-- surgical-procedure). EL CATÁLOGO NO TRAE EL MAPEO A JATS: ESTA LISTA SE
-- MANTIENE A MANO. LA TABLA shortcodes DE MYSQL SE RETIRÓ EN LA 1.7.0.
-- LA CLAVE ES LA CLASE PANDOC (COLUMNA clase), NO EL nombre DEL SHORTCODE
-- (QUE PUEDE LLEVAR PREFIJO "sec-").
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
