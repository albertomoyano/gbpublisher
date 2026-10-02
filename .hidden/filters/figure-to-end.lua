-- CONVIERTE FIGURAS CON CLASE .fullwidth A RAW JATS CON specific-use
-- NECESARIO PORQUE PANDOC IGNORA LOS ATRIBUTOS DEL DIV AL GENERAR <fig>

-- ESCAPADO XML: UN «&» EN EL PIE O EN EL NOMBRE DEL ARCHIVO DEJABA EL
-- JATS MAL FORMADO (MISMO CRITERIO QUE RC-GM-22 Y QUE cite-to-xref.lua).
-- ORDEN OBLIGATORIO: & PRIMERO PARA EVITAR DOBLE ESCAPE
local function escape_xml_text(s)
  if s == nil then return '' end
  s = s:gsub('&', '&amp;')
  s = s:gsub('<', '&lt;')
  s = s:gsub('>', '&gt;')
  return s
end

local function escape_xml_attr(s)
  s = escape_xml_text(s)
  s = s:gsub('"', '&quot;')
  return s
end

function Div(el)
  if not (el.classes:includes("fig") and el.classes:includes("fullwidth")) then
    return nil
  end

  -- EXTRAER IMAGEN Y CAPTION DEL INTERIOR DEL DIV
  local img_src  = ""
  local img_alt  = ""
  local fig_id   = (el.identifier ~= "") and el.identifier or "fig-fw"

  pandoc.walk_block(el, {
    Image = function(img)
      img_src = img.src
      img_alt = pandoc.utils.stringify(img.caption)
      return img
    end
  })

  -- DERIVAR mime-subtype DESDE LA EXTENSIÓN DEL ARCHIVO
  local ext = img_src:match("%.(%w+)$") or "png"

  -- EMITIR <fig specific-use="fullwidth"> COMO RAW JATS
  -- EL NAMESPACE xlink LO PROVEE EL <body xmlns:xlink="..."> DEL WRAPPER
  local jats =
    '<fig id="' .. escape_xml_attr(fig_id) .. '" specific-use="fullwidth">\n' ..
    '  <caption><p>' .. escape_xml_text(img_alt) .. '</p></caption>\n' ..
    '  <graphic mimetype="image" mime-subtype="' .. escape_xml_attr(ext) .. '"' ..
    ' xlink:href="' .. escape_xml_attr(img_src) .. '"/>\n' ..
    '</fig>'

  return pandoc.RawBlock("jats", jats)
end
