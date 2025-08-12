-- jats-custom.lua
-- Filtro Lua para enriquecer salida JATS de Pandoc

local stringify = pandoc.utils.stringify

-- Variables para manejar secciones
local section_stack = {}

-- Convertir encabezados en secciones JATS anidadas
function Header(el)
  local level = el.level
  local title = stringify(el.content)

  local result = {}

  -- Cerrar secciones de nivel superior o igual
  while #section_stack > 0 and section_stack[#section_stack] >= level do
    table.insert(result, pandoc.RawBlock("jats", "</sec>"))
    table.remove(section_stack)
  end

  -- Agregar nuevo nivel
  table.insert(section_stack, level)

  -- Crear nueva sección con título
  table.insert(result, pandoc.RawBlock("jats", "<sec sec-type=\"level" .. level .. "\">"))
  table.insert(result, pandoc.RawBlock("jats", "<title>" .. title .. "</title>"))

  return result
end

-- Cerrar todas las secciones al final del documento
function Pandoc(doc)
  local new_blocks = {}

  -- Agregar todos los bloques existentes
  for _, block in ipairs(doc.blocks) do
    table.insert(new_blocks, block)
  end

  -- Cerrar todas las secciones abiertas
  for i = 1, #section_stack do
    table.insert(new_blocks, pandoc.RawBlock("jats", "</sec>"))
  end

  -- Crear nuevo documento
  return pandoc.Pandoc(new_blocks, doc.meta)
end

-- Procesar divisiones especiales (como referencias)
function Div(el)
  if el.classes and (el.classes:includes("references") or el.classes:includes("bibliography")) then
    local refs = {}
    table.insert(refs, pandoc.RawBlock("jats", "<ref-list>"))
    table.insert(refs, pandoc.RawBlock("jats", "<title>References</title>"))

    for _, item in ipairs(el.content) do
      if item.tag == "Para" then
        table.insert(refs, pandoc.RawBlock("jats", "<ref>"))
        table.insert(refs, item)
        table.insert(refs, pandoc.RawBlock("jats", "</ref>"))
      end
    end

    table.insert(refs, pandoc.RawBlock("jats", "</ref-list>"))
    return refs
  end
  return el
end
