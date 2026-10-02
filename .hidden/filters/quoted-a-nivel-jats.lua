-- ============================================================================
-- FILTRO    : quoted-a-nivel-jats.lua
-- PROPÓSITO : RESUELVE EN CARACTERES EL NIVEL DE CADA CITA PARA EL JATS DE
--             REVISTAS (SC-30). ES LA MISMA REGLA DE quote.xsl PARA LIBROS:
--
--               NIVEL 1   « »     (Y CADA TERCER NIVEL: 4, 7…)
--               NIVEL 2   “ ”
--               NIVEL 3   ‘ ’
--
--             EN EL .md TODA CITA SE MARCA CON « », SIN IMPORTAR EL NIVEL:
--             LLEGA EL ANIDAMIENTO, NO EL CARÁCTER QUE ESCRIBIÓ EL EDITOR.
--
-- POR QUÉ ES OTRO FILTRO: EN LIBROS EL NIVEL LO DECIDE quote.xsl SOBRE EL
--             <quote> DEL DocBook. JATS 1.4 NO TIENE ELEMENTO DE CITA EN
--             LÍNEA, ASÍ QUE EL NIVEL SE RESUELVE ACÁ Y LLEGA AL CANÓNICO
--             COMO TEXTO. SIN ESTE FILTRO, «a «b»» SALÍA LITERAL, CON
--             ANGULARES EN LOS DOS NIVELES.
--
-- ORDEN     : DESPUÉS DE guillemets-to-quoted-db.lua, QUE ARMA LOS NODOS
--             Quoted, Y ANTES DE cite-to-xref.lua, QUE SERIALIZA EL
--             CONTENIDO DE LAS NOTAS CON pandoc.write: DESPUÉS DE ESO NO
--             QUEDAN Quoted QUE RESOLVER.
--
-- ALCANCE   : TODO Quoted, TAMBIÉN EL QUE ARMA PANDOC CON LAS COMILLAS
--             RECTAS (EXTENSIÓN smart), COMO EN LIBROS: quote.xsl TAMPOCO
--             DISTINGUE DE DÓNDE VINO EL <quote>.
--             UNA NOTA AL PIE DENTRO DE UNA CITA SIGUE CONTANDO LA
--             PROFUNDIDAD, IGUAL QUE ancestor::db:quote EN quote.xsl.
--
-- REQUIERE  : PANDOC >= 2.17 (walk CON traverse = 'topdown').
-- ============================================================================

-- PARES DE CADA NIVEL, EN EL ORDEN DE quote.xsl
local NIVELES = {
  { "«", "»" },
  { "“", "”" },
  { "‘", "’" },
}

-- ============================================================================
-- FUNCIÓN   : resolver
-- PROPÓSITO : REEMPLAZA CADA Quoted DE UNA LISTA DE INLINES POR SUS
--             CARACTERES DE NIVEL Y SU CONTENIDO, YA RESUELTO UN NIVEL MÁS
--             ADENTRO
-- PARÁMETROS: inlines — LISTA DE INLINES
--             nivel   — PROFUNDIDAD DE LAS CITAS QUE CONTIENE, DESDE 0
-- RETORNA   : LA LISTA TRANSFORMADA
-- ============================================================================
local function resolver(inlines, nivel)
  return inlines:walk({
    traverse = "topdown",
    Quoted = function(q)
      -- EL CICLO DE TRES: EL NIVEL 4 VUELVE A « »
      local par = NIVELES[(nivel % 3) + 1]
      local salida = pandoc.Inlines({ pandoc.Str(par[1]) })

      salida:extend(resolver(q.content, nivel + 1))
      salida:insert(pandoc.Str(par[2]))

      -- false: EL CONTENIDO YA SE RESOLVIÓ CON SU NIVEL; QUE EL RECORRIDO
      -- NO LO VUELVA A VISITAR CON EL NIVEL DE AFUERA
      return salida, false
    end,
  })
end

-- ============================================================================
-- FUNCIÓN   : Pandoc
-- PROPÓSITO : PUNTO DE ENTRADA. RECORRE EL DOCUMENTO DE ARRIBA HACIA ABAJO Y
--             RESUELVE CADA CITA DE PRIMER NIVEL CON TODO LO QUE CONTIENE
-- RETORNA   : EL DOCUMENTO TRANSFORMADO
-- ============================================================================
function Pandoc(doc)
  return doc:walk({
    traverse = "topdown",
    Inlines = function(inlines)
      return resolver(inlines, 0), false
    end,
  })
end
