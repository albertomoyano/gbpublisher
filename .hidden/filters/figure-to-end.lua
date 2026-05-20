-- CONVIERTE FIGURAS CON CLASE .fullwidth A RAW JATS CON specific-use
-- NECESARIO PORQUE PANDOC IGNORA LOS ATRIBUTOS DEL DIV AL GENERAR <fig>
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
    '<fig id="' .. fig_id .. '" specific-use="fullwidth">\n' ..
    '  <caption><p>' .. img_alt .. '</p></caption>\n' ..
    '  <graphic mimetype="image" mime-subtype="' .. ext .. '"' ..
    ' xlink:href="' .. img_src .. '"/>\n' ..
    '</fig>'

  return pandoc.RawBlock("jats", jats)
end
