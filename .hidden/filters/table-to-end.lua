-- MARCA LA TABLA CON PREFIJO fw- EN SU PROPIO IDENTIFICADOR
-- PANDOC IGNORA EL ID DEL DIV CONTENEDOR PERO SÍ USA EL ID
-- DEL ELEMENTO TABLE PARA GENERAR <table-wrap id="...">
function Div(el)
  local is_fullwidth = el.classes:includes("fullwidth")
  local is_rotate    = el.classes:includes("rotate")
  if not (is_fullwidth or is_rotate) then return nil end

  -- PREFIJO SEGÚN CLASE: fw- → fullwidth, rot- → sidewaystable
  local prefijo = is_rotate and "rot-" or "fw-"

  local encontrada = false
  for _, b in ipairs(el.content) do
    if b.t == "Table" and not encontrada then
      encontrada = true
      local orig_id = (el.identifier ~= "") and el.identifier
                   or (b.attr.identifier ~= "" and b.attr.identifier)
                   or "tbl"
      b.attr.identifier = prefijo .. orig_id
    end
  end

  if not encontrada then return nil end
  return pandoc.Blocks(el.content)
end
