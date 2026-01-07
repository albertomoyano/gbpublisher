-- filtro-editorial.lua
-- Filtro para procesar marcas semánticas: comillas @q{} y rayas del medio @rdm{}
-- con soporte para múltiples párrafos

function Pandoc(doc)
  -- Convertir todo el documento a texto markdown para procesamiento global
  local contenido_completo = pandoc.write(doc, 'markdown')

  -- Procesar comillas que pueden atravesar párrafos
  contenido_completo = procesar_comillas_globales(contenido_completo)

  -- Reconvertir a documento Pandoc
  local nuevo_doc = pandoc.read(contenido_completo, 'markdown')
  return nuevo_doc
end

function procesar_comillas_globales(text)
  -- Primero procesar rayas del medio
  text = procesar_rayas_medio(text)

  -- Luego procesar comillas por nivel de anidamiento
  local comillas = {
    [1] = { "«", "»" },    -- Primer nivel: comillas españolas
    [2] = { """, """ },    -- Segundo nivel: comillas dobles curvas
    [3] = { "'", "'" }     -- Tercer nivel: comillas simples curvas
  }

  local function reemplazar_nivel(texto, nivel)
    if nivel > 3 then
      return texto -- Evitar más de 3 niveles
    end

    local abre, cierra = comillas[nivel][1], comillas[nivel][2]

    -- Patrón que captura contenido incluyendo saltos de línea y párrafos
    -- El .- es no-greedy para evitar capturar más de lo necesario
    local patron = "@q{(.-)}"

    -- Procesar todas las ocurrencias del nivel actual
    texto = texto:gsub(patron, function(contenido)
      -- Procesar recursivamente el contenido interno con el siguiente nivel
      contenido = reemplazar_nivel(contenido, nivel + 1)
      return abre .. contenido .. cierra
    end)

    return texto
  end

  return reemplazar_nivel(text, 1)
end

function procesar_rayas_medio(text)
  -- Procesar rayas del medio @rdm{contenido}
  -- Reemplaza con —contenido—
  text = text:gsub("@rdm{(.-)}", "—%1—")
  return text
end
