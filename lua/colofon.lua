-- colofon.lua
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
  local body_latex = ""

  if #blocks > 0 and blocks[1].t == "Header" then
    local title = pandoc.utils.stringify(blocks[1].content)
    table.remove(blocks, 1)
    body_latex = pandoc.write(pandoc.Pandoc(blocks), "latex")

    local latex = [[
\AtEndDocument{
  \clearpage
  \chapter*{]] .. title .. [[}
  ]] .. body_latex .. [[

  \clearpage
  \thispagestyle{empty}
  \null
  \newpage
}
]]
    table.insert(doc.blocks, pandoc.RawBlock("latex", latex))
  else
    body_latex = pandoc.write(parsed, "latex")
    local latex = [[
\AtEndDocument{
  \clearpage
  \chapter*{Colofón}
  ]] .. body_latex .. [[

  \clearpage
  \thispagestyle{empty}
  \null
  \newpage
}
]]
    table.insert(doc.blocks, pandoc.RawBlock("latex", latex))
  end

  return doc
end
