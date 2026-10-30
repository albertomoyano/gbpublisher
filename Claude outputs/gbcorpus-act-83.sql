-- ============================================================
-- gbCorpus — actualización 83: los índices onomástico y de conceptos
-- Esquema: 2
-- Origen: conversación del 30/10. Decisiones de Alberto sobre la marca,
--         la nota («23 n.»), las remisiones (criterio de Valbusa), la
--         página principal, hyperindex=false, solo PDF, revistas sin
--         índices. Mediciones en el contenedor (Pandoc 3.1.3, TeX Live
--         2023, xindy de Ubuntu 24.04). El lote todavía no está escrito:
--         la SC lo lleva como pendiente.
-- Fecha:  2026-10-30
-- Aplicar: después de act-82
--
-- ALTAS:
--   SC-77   índices onomástico y de conceptos
--   GV-157  Pandoc: \index en el .md
--   GV-158  xindy: el orden español
--   GV-159  hyperref: hyperindex y xindy
--   GV-160  xindy: formatos declarados, número de nota, escapes
-- ============================================================

BEGIN TRANSACTION;

CREATE TEMP TABLE verificacion (paso TEXT, ok INTEGER CHECK (ok = 1));

-- ------------------------------------------------------------
-- 1. ESTADO DE PARTIDA: ÚLTIMOS NÚMEROS, CÓDIGOS LIBRES, RELACIONADAS
-- ------------------------------------------------------------
INSERT INTO verificacion SELECT 'SC-76 última SC', MAX(numero) = 76 FROM entradas WHERE prefijo = 'SC';
INSERT INTO verificacion SELECT 'GV-156 última GV', MAX(numero) = 156 FROM entradas WHERE prefijo = 'GV';
INSERT INTO verificacion SELECT 'SC-77 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'SC-77' OR (prefijo = 'SC' AND numero = 77);
INSERT INTO verificacion SELECT 'GV-157 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-157' OR (prefijo = 'GV' AND numero = 157);
INSERT INTO verificacion SELECT 'GV-158 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-158' OR (prefijo = 'GV' AND numero = 158);
INSERT INTO verificacion SELECT 'GV-159 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-159' OR (prefijo = 'GV' AND numero = 159);
INSERT INTO verificacion SELECT 'GV-160 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-160' OR (prefijo = 'GV' AND numero = 160);
INSERT INTO verificacion SELECT 'SC-31 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-31';
INSERT INTO verificacion SELECT 'SC-54 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-54';
INSERT INTO verificacion SELECT 'SC-55 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-55';
INSERT INTO verificacion SELECT 'SC-62 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-62';
INSERT INTO verificacion SELECT 'SC-65 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-65';
INSERT INTO verificacion SELECT 'GV-116 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-116';
INSERT INTO verificacion SELECT 'GV-124 existe', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-124';

-- ------------------------------------------------------------
-- 2. ALTAS
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('SC', 77, 'SC-77', 'Índices onomástico y de conceptos: la marca en el .md, el canónico y el PDF',
   'DECISIÓN CERRADA (decisión de Alberto, 30/10/2026). Los dos índices que carga el editor —onomástico y de conceptos— se marcan en el .md con la orden completa de LaTeX, como en el flujo legacy, y salen solo en el PDF de los libros. El tercero, el de autores de la bibliografía (`names`), lo sigue llenando biblatex con esindex y no lleva marca.

LA PIEZA

Ya existía: `tipo_capitulo` `indice_onomastico` e `indice_concepto`, pieza sin cuerpo en el espacio `bm-` (SC-55), `\gbIndice` en el contrato y `\makeindex[name=onomastico]` / `[name=concepto]` en la estética. Lo que faltaba era la marca: `controles_md.lua` frenaba `\index` como `latex_en_linea`, el escritor DocBook lo descartaba (GV-116) y `docbook-to-latex.xsl` no tenía plantilla de `indexterm`. Sin plantilla, la regla por omisión de XSLT copiaría el texto del término en el cuerpo.

LA MARCA

    \index[onomastico]{Borges, Jorge Luis!infancia}
    \index[onomastico]{Torre Lisandro de la@Torre, Lisandro de la}
    \index[concepto]{democracia!liberal|(}   …   \index[concepto]{democracia!liberal|)}
    \index[concepto]{universidad|see{educación superior}}
    \index[concepto]{educación superior|seealso{universidad}}
    \index[concepto]{educación superior|textbf}

- `!` nivel (hasta tres), `@` clave de orden, `|(` y `|)` rango, `|see{…}` y `|seealso{…}` remisiones, `|textbf` página principal. Es la sintaxis de makeindex y xindy, pero la lee `indice.lua`, no xindy: el canónico guarda el texto limpio y la hoja LaTeX lo vuelve a armar.
- El nombre del índice es obligatorio y de la lista cerrada: `onomastico` y `concepto`, los del `\makeindex` de la estética. Sin nombre, o con otro, frena: con dos índices manuales, un `\index{…}` sin nombre es ambiguo.
- Un `!`, `@` o `|` literal se escribe `\!`, `\@`, `\|`. La hoja LaTeX lo reescribe con la comilla de xindy (GV-160). No se usa la comilla en el .md: con babel-spanish es un atajo activo.
- Un `%` se escribe `\%` y las llaves van cerradas: si no, Pandoc parte la orden en texto común (GV-157). El filtro la busca también en el texto común y frena.
- Va pegada a la palabra que señala.
- No va en un título: pasaría al sumario y a los marcadores. Se escribe al comienzo del primer párrafo. Frena.
- Un rango se abre y se cierra en la misma pieza, con la entrada idéntica. Frena.
- Una marca dentro de una nota da «23 n.» (decisión de Alberto, 30/10/2026). Una página principal dentro de una nota frena: cada entrada lleva un solo formato.
- `indice.lua` corre antes de `cite-to-biblioref-db.lua`, que serializa las notas y borraría las marcas que estén adentro (como con la volada, SC-62).

POR QUÉ LA ORDEN DE LaTeX Y NO UN SPAN

Sigue el camino de `\sptext` (SC-62) y de las cifras (SC-65): Pandoc la lee como LaTeX en línea en cualquier lugar, sin interpretar lo de adentro (GV-157), y un filtro la traduce antes de que la descarte el escritor DocBook (GV-116). Un span `[Borges]{.indice …}` envuelve texto, y una entrada muchas veces señala algo que no está escrito tal cual: un pronombre, una paráfrasis. Además m_Hunspell saltea el texto entre corchetes.

EL CANÓNICO

`<indexterm type="onomastico|concepto" xml:id="…">` con `primary`, `secondary` y `tertiary`, `@sortas`, `class="startofrange"` / `class="endofrange"` con `startref`, `see`, `seealso` y `significance="preferred"` para la principal (DocBook 5.2, RNG del repo). Cada uno lleva su id aunque hoy nada lo use: es lo que deja abierto un índice con enlaces en EPUB y HTML.

EL PDF

- `docbook-to-latex.xsl` vuelve a escribir `\index[nombre]{…}` con el formato explícito: `|hyperpage`; `|(hyperpage` y `|)hyperpage`; `|gbIndNota` dentro de una nota (lo sabe por el ancestro `footnote`); `|gbIndPrincipal`; `|see{…}` y `|seealso{…}`.
- hyperref con `hyperindex=false` (GV-159). El índice `names` agrega `|hyperpage` desde su formato de nombre y conserva los enlaces.
- `\gbIndNota` y `\gbIndPrincipal` son del contrato: los escribe la hoja.
- xindy corre con `-L spanish-modern -C utf8` (GV-158) y con el módulo `gbindice.xdy`, que declara los dos formatos (GV-160). El script avisa también las páginas descartadas por un formato desconocido.

Presentación, con el criterio de Valbusa (decisión de Alberto, 30/10/2026: coma y minúscula siempre que se pueda):

    Alberdi, Juan Bautista, 1 n., 3
    democracia
       liberal, 1–3
    educación superior, 2, véase también universidad
    universidad, véase educación superior

La página principal, en negrita.

EPUB Y HTML

No llevan índices (decisión de Alberto, 30/10/2026): la plantilla de `indexterm` es vacía y la pieza se omite (matriz de `m_PiezasLibro`: «no se hace todavía»). Caminos estudiados para el día que se hagan con enlaces: anclas propias, con el orden calculado por Saxon y no por xindy (dos órdenes posibles para el mismo índice), o las páginas del PDF enlazadas, con el EPUB dependiendo de compilar antes el PDF y sin lista de páginas del impreso.

REVISTAS

No se usan índices (decisión de Alberto, 30/10/2026): `no_aplica` en gbShortcodes. JATS 1.4 Archiving tendría `<index-term>`.

FUERA DE ESTA DECISIÓN

- «23 n. 45», con el número de nota. DESCARTADO por costo (decisión de Alberto, 30/10/2026): las notas se reinician por pieza (SC-31), así que «nota 45» sola es ambigua, y xindy no lo da de forma nativa (GV-160).
- El código muerto de `ensamblar-capitulo-canonico.xsl` (`indice_tematico`, `indice_analitico`, quitados en el esquema 1.11.0): se limpia en el lote. Las piezas de índice no pasan por esa hoja.', 'vigente', 'empirica',
   'gbpublisher / Pandoc 3.1.3 / LuaHBTeX 1.17.0, TeX Live 2023, babel-spanish, imakeidx, esindex, biblatex + biber, hyperref / xindy (Ubuntu 24.04) / qpdf / contenedor Ubuntu 24.04',
   '2026-10', 'vinculo:SC-62,vinculo:SC-65,vinculo:SC-54,vinculo:SC-31,vinculo:SC-55,vinculo:GV-116,vinculo:GV-124,apoya:GV-157,apoya:GV-158,apoya:GV-159,apoya:GV-160', 'Lote 1: indice.lua, controles_md.lua (SC-54 suma las dos órdenes admitidas), docbook-to-latex.xsl, plantillas vacías en las hojas HTML y EPUB del libro, contrato (\gbIndNota, \gbIndPrincipal), preambulo-hyperref (hyperindex=false) y formato de nombre del índice names, compilar_latex_comun.sh, gbindice.xdy, limpieza de ensamblar-capitulo-canonico.xsl y dos filas de gbShortcodes (borrador en libros, no_aplica en revistas). Probarlo en Mint con un libro real, incluido el orden de xindy (GV-158).',
   770, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 157, 'GV-157', 'Pandoc: \index[…]{…} en el .md es LaTeX en línea entero; solo lo rompen un % y una llave sin cerrar',
   'Medido con Pandoc 3.1.3 (`-f markdown -t native`).

1. `\index[onomastico]{Borges, Jorge Luis!infancia}` es un RawInline tex entero en un párrafo, dentro de una nota, dentro de una bastardilla y al final de un título. Partida en dos líneas también: el salto queda adentro.
2. En un título, el RawInline no entra en el id que Pandoc deriva del texto.
3. Adentro de las llaves no interpreta `! @ | & # _ ~ $ ^`, `"` ni « »; `\!`, `\&` y `\%` quedan tal cual.
4. Dos cosas rompen la lectura. Un `%` sin barra abre un comentario de LaTeX y una llave sin cerrar deja el grupo abierto: en los dos casos la orden no se reconoce y queda partida en Str (`F\index[concepto]{I+D`, `&`, `50`, `%`, …). Es el comportamiento de GV-124.', 'vigente', 'empirica',
   'Pandoc 3.1.3 / contenedor Ubuntu 24.04',
   '2026-10', 'apoya:SC-77,vinculo:GV-116,vinculo:GV-124', NULL,
   1570, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 158, 'GV-158', 'xindy: el módulo español cargado por ruta con -M no ordena en español; -L spanish-modern -C utf8 sí',
   'Medido con el xindy de Ubuntu 24.04 (TeX Live 2023) y la invocación de `compilar_latex_comun.sh`: `-M texindy -M page-ranges -M word-order -M /usr/share/xindy/lang/spanish/modern-utf8.xdy -I latex`.

1. Con el módulo por ruta el orden no es el español: «Ávila» va antes que «Absalón» y «Alberdi», y «Ñandú» cae primero, en el grupo A.
2. Con `-L spanish-modern -C utf8` en lugar de `-M …/modern-utf8.xdy`: Absalón, Alberdi, Avellaneda, Ávila; Ñandú en su grupo Ñ, después de la N.
3. `-L spanish -C utf8` no existe: «Cannot locate xindy module for language spanish in codepage utf8».
4. El índice `names` no lo sufre con las tildes: esindex escribe la clave sin ellas (`Avila, Juan@Ávila, Juan`). Lo sufren los índices sin esindex: los que carga el editor.', 'vigente', 'empirica',
   'xindy (paquete de Ubuntu 24.04, TeX Live 2023) / contenedor Ubuntu 24.04',
   '2026-10', 'apoya:SC-77', 'Confirmar en Linux Mint con un índice real.',
   1580, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 159, 'GV-159', 'hyperref: hyperindex rompe los índices de xindy; con hyperindex=false y |hyperpage explícito no',
   'Medido con LuaLaTeX, imakeidx con la opción `xindy`, babel-spanish y hyperref con `hyperindex` encendido, que es el valor por omisión y el de `preambulo-hyperref.tex`.

1. hyperref reescribe el formato en el .idx. `|(` pasa a `|(hyperpage` y `|)` queda `|)`: xindy no cierra el rango («Found no :close-range matching an already opened one»).
2. Un formato propio pasa a `|hyperindexformat{\gbIndNota}`: xindy lo trata como otro atributo y la página sale vacía (`\hyperindexformat{\gbIndNota}{}`).
3. `|see{…}` y `|seealso{…}` pasan a `|hyperindexformat{\see{…}}` y se mezclan con el formato de otra página de la misma entrada: «educación superior» perdió su página 2.
4. Con `hyperindex=false` y el formato escrito explícito (`|hyperpage`, `|(hyperpage` y `|)hyperpage`, `|see{…}`) los tres casos salen bien, con enlace.
5. esindex acepta `|formato`. Con el formato de nombre de biblatex llamando a una orden que hace `\esindex[names]{#1|hyperpage}`, el índice de autores conserva los enlaces con `hyperindex=false`: seis anotaciones Link a `page.N`, contadas con qpdf, una por página de cada autor.', 'vigente', 'empirica',
   'LuaHBTeX 1.17.0, TeX Live 2023 / babel-spanish / imakeidx / esindex / biblatex + biber / hyperref / xindy (Ubuntu 24.04) / qpdf / contenedor Ubuntu 24.04',
   '2026-10', 'apoya:SC-77', NULL,
   1590, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 160, 'GV-160', 'xindy: un formato no declarado descarta la página; un formato por número de nota no ordena',
   'Medido con xindy (texindy, `-I latex`) y LuaLaTeX con babel-spanish.

1. Una página con un formato que xindy no tiene declarado se descarta con un «WARNING: unknown attribute» y nada más: «Alberdi» perdió la página de su nota. `compilar_latex_comun.sh` solo cuenta «did not match any location-class».
2. Un módulo propio lo declara: `(define-attributes (("default" "textbf" "textit" "hyperpage" "gbIndPrincipal" "gbIndNota")))` y un `markup-locref` por formato. xindy avisa que ignora la redefinición de los cuatro que ya tenía, sin efecto. Resultado: «Alberdi, Juan Bautista, 1 n., 3» y la principal en negrita.
3. Número de nota («23 n. 45»). Con un atributo por número (`gbIndNota1` a `gbIndNota999`) y la orden armada con `\edef` y `\detokenize`, el número llega bien al .idx usando solo `\index`. Pero cada atributo en su grupo: xindy pone las notas después de todas las páginas y sin separador («1, 2 1 nota 2 1 nota 3 2 nota 4»). Todos en un grupo: funde la página y las notas de esa página, y las notas se pierden. Ordenaría bien una clase de ubicación de dos capas (página y nota), que exige escribir el localizador por dentro de imakeidx (`\imki@wrindexentry…`, no es interfaz documentada). No probado.
4. Escape. `"!` y `"@` dentro de `\index` llegan como `!` y `@` literales con babel-spanish activo, también con el `\index` dentro de `\emph` y de `\footnote`: «¡Absalón, Absalón!», «Twitter @jlb».
5. Rango `|(hyperpage` … `|)hyperpage` de la página 1 a la 3: «1–3».', 'vigente', 'empirica',
   'LuaHBTeX 1.17.0, TeX Live 2023 / babel-spanish / imakeidx / esindex / biblatex + biber / hyperref / xindy (Ubuntu 24.04) / qpdf / contenedor Ubuntu 24.04',
   '2026-10', 'apoya:SC-77', NULL,
   1600, datetime('now','localtime'), datetime('now','localtime'));

-- ------------------------------------------------------------
-- 3. RESULTADO
-- ------------------------------------------------------------
INSERT INTO verificacion SELECT 'cinco altas', COUNT(*) = 5 FROM entradas WHERE codigo IN ('SC-77', 'GV-157', 'GV-158', 'GV-159', 'GV-160');
INSERT INTO verificacion SELECT 'SC-77 con sus cuatro GV', instr(relaciones, 'apoya:GV-160') > 0 FROM entradas WHERE codigo = 'SC-77';

COMMIT;

SELECT codigo, estado, evidencia, titulo FROM entradas
 WHERE codigo IN ('SC-77', 'GV-157', 'GV-158', 'GV-159', 'GV-160')
 ORDER BY prefijo, numero;
