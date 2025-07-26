-- figure-bold-filter.lua
-- Filtro de Pandoc para procesar figuras después de pandoc-crossref

function Figure(elem)
    -- pandoc-crossref maneja los captions de manera especial
    -- Necesitamos procesarlos de forma diferente

    if elem.caption then
        -- Obtener el texto completo del caption
        local caption_text = pandoc.utils.stringify(elem.caption)

        if caption_text and caption_text ~= "" then
            -- Buscar el patrón "Figura N:" al inicio
            local figura_part, rest = caption_text:match("^(Figura%s+%d+:)%s*(.*)")

            if figura_part and rest then
                -- Crear un nuevo caption con la estructura correcta
                local new_caption = {}

                -- Agregar "Figura N:" en negrita
                table.insert(new_caption, pandoc.Strong({pandoc.Str(figura_part)}))

                -- Agregar espacio
                table.insert(new_caption, pandoc.Space())

                -- Agregar el resto del texto
                if rest ~= "" then
                    table.insert(new_caption, pandoc.Str(rest))
                end

                -- Reemplazar el caption
                elem.caption = new_caption
            end
        end
    end

    return elem
end

-- Función para procesar después de que todo esté renderizado
function Pandoc(doc)
    -- Recorrer todos los bloques del documento
    local function process_blocks(blocks)
        for i, block in ipairs(blocks) do
            if block.t == "Figure" then
                blocks[i] = Figure(block)
            elseif block.content then
                process_blocks(block.content)
            end
        end
    end

    process_blocks(doc.blocks)
    return doc
end
