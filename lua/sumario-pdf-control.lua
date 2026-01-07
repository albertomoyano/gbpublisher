-- Filtro para controlar el sumario manualmente
function Meta(meta)
  io.stderr:write("FILTRO: Procesando Meta\n")
  -- FORZAR desactivación del TOC automático
  meta.toc = false
  io.stderr:write("FILTRO: TOC FORZADO a false\n")
  return meta
end

function Div(div)
  io.stderr:write("FILTRO: Procesando Div con clases: ")
  for i, class in ipairs(div.classes) do
    io.stderr:write(class .. " ")
  end
  io.stderr:write("\n")

  if div.classes:includes("sumario") then
    io.stderr:write("FILTRO: ¡Encontrado div.sumario! Generando TOC controlado\n")
    return {
      pandoc.RawBlock('latex', '\\hypersetup{linkcolor=black}'),
      pandoc.RawBlock('latex', '\\setcounter{tocdepth}{0}'),  -- Solo capítulos (nivel 1)
      pandoc.RawBlock('latex', '\\tableofcontents')
    }
  end
  return div
end

-- Función para excluir secciones del TOC
function Header(header)
  -- Excluir portadilla del índice (nivel 1 sin numeración)
  if header.level == 1 and header.classes:includes("unnumbered") then
    io.stderr:write("FILTRO: Excluyendo header unnumbered del TOC: " .. pandoc.utils.stringify(header.content) .. "\n")
    -- Agregar clase para que no aparezca en TOC
    header.attr.classes:insert("unlisted")
  end
  return header
end
