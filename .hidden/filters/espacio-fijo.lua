-- ============================================================
-- FILTRO      : espacio-fijo.lua
-- PROPÓSITO   : TRADUCE LA MARCA DE ESPACIO FIJO DEL .md, ¬ (U+00AC),
--               AL ESPACIO DURO U+00A0. ES EL ~ DE LaTeX: siglo¬XX,
--               art.¬3,¬inc.¬b, Felipe¬II (SC-68).
-- ENTRADA     : siglo¬XX                  Str "siglo¬XX"
-- SALIDA      : siglo U+00A0 XX           Str "siglo\u{00A0}XX"
--               EL CANÓNICO (JATS O DOCBOOK), EL HTML Y EL EPUB LLEVAN EL
--               CARÁCTER; EL PDF, ~ (f:mapa-tex, tex-comun.xsl).
-- POR QUÉ ¬   : ~ ES EL SUBÍNDICE DE PANDOC (SC-30) Y ARMA UNO SIN AVISO
--               CON DOS ~ SIN ESPACIO ENTRE ELLOS (GV-130); \ (BARRA Y
--               ESPACIO) NO SE VE EN EL EDITOR; | CORTA LA CELDA DE UNA
--               TABLA (GV-131). ¬ NO ES SINTAXIS DE PANDOC EN NINGUNA
--               POSICIÓN, NO APARECE EN LA PROSA Y EL EDITOR LO CONSERVA
--               (GV-132). U+00A0 NO SE ESCRIBE EN EL .md (GV-47).
-- ALCANCE     : SOLO LOS Str. EL CÓDIGO, LA MATEMÁTICA, LAS URL Y EL
--               CRUDO NO SON Str: AHÍ ¬ QUEDA LITERAL, QUE ES LO QUE SE
--               QUIERE (EN LA MATEMÁTICA LA NEGACIÓN ES \neg). LOS Str DEL
--               SUFIJO Y EL PREFIJO DE UNA CITA TAMBIÉN SE TRADUCEN.
-- COMPAÑERO   : LAS ABREVIATURAS (pág. 22, cap. 3, n.º 5) NO LLEVAN
--               MARCA: LAS RESUELVE EL LECTOR CON --abbreviations=
--               ~/.gbpublisher/filters/abreviaturas-espacio-fijo.txt
-- UBICACIÓN   : ~/.gbpublisher/filters/
-- DEBE CORRER : EN TODAS LAS CADENAS QUE PRODUCEN UNA SALIDA, DESPUÉS DE
--               cuadro-leer.lua (QUE INSERTA EL CUADRO, CON SU TEXTO) Y
--               ANTES DE CUALQUIER FILTRO QUE SERIALICE (cite-to-xref,
--               cite-to-biblioref-db, cuadro-armar, fenced-divs).
-- ============================================================

-- LA MARCA Y LO QUE LA REEMPLAZA. find Y gsub VAN CON LA CADENA LITERAL:
-- EN LOS PATRONES DE LUA ¬ SON DOS BYTES SIN SIGNIFICADO ESPECIAL (GV-88)
local MARCA = '\u{00AC}'
local ESPACIO_DURO = '\u{00A0}'

-- ============================================
-- Función   : Str
-- Propósito : Reemplaza cada ¬ del Str por un espacio duro
-- Parámetros: el As Str — el elemento
-- Retorna   : Str — el elemento nuevo; nil si no tenía la marca
-- ============================================
function Str(el)

  -- --- 1. SIN LA MARCA, EL Str QUEDA COMO ESTÁ ---
  if not el.text:find(MARCA, 1, true) then return nil end

  -- --- 2. REEMPLAZO. LOS PARÉNTESIS DEJAN UN SOLO VALOR: gsub DEVUELVE
  --        TAMBIÉN LA CANTIDAD (GV-86) ---
  return pandoc.Str((el.text:gsub(MARCA, ESPACIO_DURO)))

end
