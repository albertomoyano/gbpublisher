-- ============================================================
-- ARCHIVO     : vista_cuadro_medir.lua
-- PROPÓSITO   : LAS MEDIDAS DE LA VISTA PREVIA DE UN CUADRO (SC-67). LO
--               CARGA EL MAESTRO DE LA VISTA (medir-vista.tex, QUE ESCRIBE
--               vista_cuadro.sh) Y ESCRIBE medidas.txt EN LA CARPETA DE LA
--               COMPILACIÓN, UNA LÍNEA POR MEDIDA, CAMPOS SEPARADOS POR TAB,
--               TODO EN sp (1 pt = 65536 sp):
--                 tramo     N  ANCHO  CAJA  ALTO  ALTO_DISPONIBLE
--                 desborde  N  EXCESO
--               EL ARCHIVO Y NO EL .log: EL .log CORTA LAS LÍNEAS EN 79
--               CARACTERES Y PARTE LAS MEDIDAS (MEDIDO).
-- POR QUÉ LUA : EL LIBRO CARGA linebreaker (preambulo-estetica.tex), QUE
--               TOMA EL CALLBACK hpack_quality Y CALLA TODOS LOS «Overfull
--               \hbox» (GV-128): UNA CELDA QUE SE SALE DE SU COLUMNA NO DEJA
--               RASTRO EN EL .log. ESTA MEDIDA NO DEPENDE DEL AVISO: MIRA
--               CADA RENGLÓN YA ARMADO Y COMPARA SU ANCHO REAL CON EL DE LA
--               COLUMNA. NO CAMBIA LA COMPOSICIÓN: EL CALLBACK DEVUELVE true.
-- UBICACIÓN   : /usr/share/gbpublisher/engine/ (INFRAESTRUCTURA, SC-11)
-- ============================================================

gbvista = {
  flotante = false,         -- ESTAMOS DENTRO DEL FLOTANTE DE UN TRAMO
  dentro = false,           -- ESTAMOS DENTRO DE UN tabular DEL CUADRO
  tramo = 0,                -- EL TRAMO EN CURSO: UN tabular POR TRAMO
  ancho_texto = nil,        -- \textwidth DEL DOCUMENTO, ANTES DE ROTAR
  salida = io.open('medidas.txt', 'w'),
}

local HLIST = node.id('hlist')

-- ============================================
-- Función   : anotar
-- Propósito : Escribe una línea en medidas.txt
-- Parámetros: campos As Table — los campos de la línea
-- Retorna   : nada
-- ============================================
local function anotar(campos)
  gbvista.salida:write(table.concat(campos, '\t'), '\n')
  -- flush: SI LA COMPILACIÓN SE CORTA, LO MEDIDO HASTA AHÍ QUEDA ESCRITO
  gbvista.salida:flush()
end

-- ============================================
-- Función   : desbordes
-- Propósito : En un párrafo de una celda, anota cada renglón más ancho
--             que su columna. node.rangedimensions MIDE EL RENGLÓN CON EL
--             ESTIRAMIENTO QUE TeX LE DIO: SI AUN ENCOGIDO AL MÁXIMO NO
--             ENTRA, EL REAL ES MAYOR QUE EL ANCHO DE LA CAJA
-- Parámetros: cabeza As Node — el párrafo ya cortado en renglones
-- Retorna   : true — EL PÁRRAFO QUEDA COMO ESTABA
-- ============================================
local function desbordes(cabeza)
  local real
  -- SOLO LAS CELDAS: EL PIE Y EL RESTO NO SON MATERIA DE ESTA MEDIDA
  if gbvista.dentro then
    for n in node.traverse_id(HLIST, cabeza) do
      real = node.rangedimensions(n, n.head)
      if real - n.width > tex.hfuzz then
        anotar({ 'desborde', gbvista.tramo, real - n.width })
      end
    end
  end
  return true
end

luatexbase.add_to_callback('post_linebreak_filter', desbordes, 'gb-vista-desborde')

-- ============================================
-- Función   : gbvista.empezar
-- Propósito : Al empezar un tabular: un tramo más
-- Parámetros: ninguno
-- Retorna   : nada
-- ============================================
function gbvista.empezar()
  -- UN tabular FUERA DE LOS FLOTANTES NO ES DEL CUADRO: EL DE UN
  -- ENCABEZADO DE PÁGINA, QUE SE ARMA EN LA RUTINA DE SALIDA
  if not gbvista.flotante then return end
  -- UN tabular POR TRAMO: gb-cuadro-latex (tex-comun.xsl) ABRE UNO EN CADA
  -- FLOTANTE, Y UNA CELDA NO PUEDE TRAER OTRO (cuadro-leer.lua FRENA EL LaTeX)
  gbvista.tramo = gbvista.tramo + 1
  gbvista.dentro = true
end

-- ============================================
-- Función   : gbvista.pagina
-- Propósito : Toma el \textwidth de la página, antes de cualquier rotación
-- Parámetros: ninguno
-- Retorna   : nada
-- ============================================
function gbvista.pagina()
  gbvista.ancho_texto = tex.dimen['textwidth']
end

-- ============================================
-- Función   : gbvista.medir
-- Propósito : Al terminar un tabular: su ancho contra el de la caja y su
--             alto contra el disponible. ROTADO, EL ALTO DISPONIBLE ES EL
--             ANCHO DE LA PÁGINA
-- Parámetros: ninguno
-- Retorna   : nada
-- ============================================
function gbvista.medir()
  local b, rotado, disponible
  if not gbvista.dentro then return end
  b = tex.box['gbvista']
  rotado = tex.dimen['textwidth'] ~= gbvista.ancho_texto
  disponible = rotado and gbvista.ancho_texto or tex.dimen['textheight']
  gbvista.dentro = false
  anotar({ 'tramo', gbvista.tramo, b.width, tex.dimen['linewidth'],
           b.height + b.depth, disponible })
end
