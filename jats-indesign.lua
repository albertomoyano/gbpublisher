-- jats-indesign.lua
local stringify = require("pandoc.utils").stringify

function Header(el)
  -- Abrimos una sección con título, no gestionamos cierres para simplificar
  return pandoc.RawBlock("xml", string.format("<sec><title>%s</title>", stringify(el.content)))
end

function Para(el)
  return pandoc.RawBlock("xml", "<p>" .. pandoc.text.escape(stringify(el.content)) .. "</p>")
end

function Plain(el)
  -- Para evitar perder texto suelto fuera de parrafos
  return Para(el)
end

function RawBlock(el)
  if el.format == "jats" or el.format == "xml" then
    return el
  end
end

function Doc(body, metadata, variables)
  local blocks = {}

  table.insert(blocks, pandoc.RawBlock("xml", '<?xml version="1.0" encoding="UTF-8"?>'))
  table.insert(blocks, pandoc.RawBlock("xml", '<article xmlns="http://jats.nlm.nih.gov">'))

  -- Insertar todo el contenido aquí, sin secciones abiertas sin cerrar
  for _, block in ipairs(body) do
    table.insert(blocks, block)
  end

  table.insert(blocks, pandoc.RawBlock("xml", '</article>'))

  return pandoc.Pandoc(blocks, metadata)
end
