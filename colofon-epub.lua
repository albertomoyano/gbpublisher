-- colofon-epub.lua
local colofon_file = "articulos/99-colofon.md"

function Pandoc(doc)
  local fh = io.open(colofon_file, "r")
  if not fh then
    io.stderr:write("⚠ No se encontró el archivo de colofón: " .. colofon_file .. "\n")
    return doc
  end

  local content = fh:read("*all")
  fh:close()

  local parsed = pandoc.read(content, "markdown")
  local blocks = parsed.blocks

  -- Agregar salto de página para EPUB
  local page_break = pandoc.Div({}, {class = "page-break-before"})
  table.insert(doc.blocks, page_break)

  -- Si el primer bloque es un encabezado, usarlo tal como está
  -- Si no, agregar un encabezado "Colofón"
  if #blocks > 0 and blocks[1].t == "Header" then
    -- Ya tiene encabezado, agregar todos los bloques tal como están
    for _, block in ipairs(blocks) do
      table.insert(doc.blocks, block)
    end
  else
    -- No tiene encabezado, agregar uno y luego el contenido
    local colofon_header = pandoc.Header(1, {pandoc.Str("Colofón")}, {id = "colofón"})
    table.insert(doc.blocks, colofon_header)

    -- Agregar el contenido del colofón
    for _, block in ipairs(blocks) do
      table.insert(doc.blocks, block)
    end
  end

  io.stderr:write("✓ Colofón agregado al documento EPUB\n")

  return doc
end
