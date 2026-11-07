-- ============================================================
-- gbCorpus — actualización 92: lanzadora neutra (m_Lanzadora), HTML del
--            libro integrado al portal (SC-85) y el marco en .xml
-- Esquema: 2
-- Origen: conversación del 07/11/2026. Decisiones de Alberto: la
--         lanzadora sale de m_GenerarSalidasLibro (etapa A0 de las
--         salidas de revistas); el HTML del libro integrado al portal de
--         gbWeb (lotes 1 a 3 del 05/11, que esperaban su implementación
--         para entrar al corpus) probado en Linux Mint; Netlify reescribe
--         los .html (Pretty URLs) y el marco pasa a .xml, con
--         netlify.toml en el despliegue.
-- Fecha:  2026-11-07
-- Aplicar: después de act-91
--
-- ALTAS:
--   SC-85   HTML del libro integrado al portal de gbWeb
--   GV-188  Netlify «Pretty URLs» reescribe los enlaces de los .html
--
-- MODIFICA:
--   SC-53   m_Lanzadora (UN MÓDULO NEUTRO); nombres
--   SC-67, SC-69, SC-75, SC-78   el nombre de la lanzadora
--   SC-80   cabecera completa en la obra integrada (corrige la mínima)
--   SC-81   1.22.0 en v_web_libro; título
--   SC-83   EL MARCO PARA LAS OBRAS INTEGRADAS (.xml)
--   SC-84   netlify.toml en el despliegue
--   SC-22   cadena hasta 1.22.0
--   SC-25   el HTML integrado en la matriz de las primeras
-- ============================================================

BEGIN TRANSACTION;

CREATE TEMP TABLE verificacion (paso TEXT, ok INTEGER CHECK (ok = 1));

-- ------------------------------------------------------------
-- 1. ESTADO DE PARTIDA: act-91 APLICADA, CÓDIGOS LIBRES, TEXTOS UNA VEZ
-- ------------------------------------------------------------
INSERT INTO verificacion SELECT 'act-91 importada', COUNT(*) = 1 FROM importaciones WHERE numero = 91;
INSERT INTO verificacion SELECT 'SC-84 última SC', MAX(numero) = 84 FROM entradas WHERE prefijo = 'SC';
INSERT INTO verificacion SELECT 'GV-187 última GV', MAX(numero) = 187 FROM entradas WHERE prefijo = 'GV';
INSERT INTO verificacion SELECT 'SC-85 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'SC-85' OR (prefijo = 'SC' AND numero = 85);
INSERT INTO verificacion SELECT 'GV-188 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-188' OR (prefijo = 'GV' AND numero = 188);
INSERT INTO verificacion SELECT 'SC-81 título', titulo = 'Contrato gbpublisher → gbWeb: cinco VIEW, una cuenta de solo lectura y la tapa web en la base (esquemas 1.19.0 a 1.21.0)' FROM entradas WHERE codigo = 'SC-81';
INSERT INTO verificacion SELECT 'SC-53 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, 'pasa por `m_GenerarSalidasLibro.EjecutarScriptSalida`. Es el contrato', ''))) = length('pasa por `m_GenerarSalidasLibro.EjecutarScriptSalida`. Es el contrato') FROM entradas WHERE codigo = 'SC-53';
INSERT INTO verificacion SELECT 'SC-53 texto 2 una vez', (length(cuerpo) - length(replace(cuerpo, 'el parámetro opcional `sQue` de `EjecutarScriptSalida`, o el nombre', ''))) = length('el parámetro opcional `sQue` de `EjecutarScriptSalida`, o el nombre') FROM entradas WHERE codigo = 'SC-53';
INSERT INTO verificacion SELECT 'SC-53 texto 3 una vez', (length(cuerpo) - length(replace(cuerpo, 'Los fija `engine/comun.sh` y los replica `m_GenerarSalidasLibro`:', ''))) = length('Los fija `engine/comun.sh` y los replica `m_GenerarSalidasLibro`:') FROM entradas WHERE codigo = 'SC-53';
INSERT INTO verificacion SELECT 'SC-53 texto 4 una vez', (length(cuerpo) - length(replace(cuerpo, 'CÓDIGOS

', ''))) = length('CÓDIGOS

') FROM entradas WHERE codigo = 'SC-53';
INSERT INTO verificacion SELECT 'SC-67 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, '(SC-13, lanzado por `EjecutarScriptSalida`, SC-53)', ''))) = length('(SC-13, lanzado por `EjecutarScriptSalida`, SC-53)') FROM entradas WHERE codigo = 'SC-67';
INSERT INTO verificacion SELECT 'SC-69 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, '(SC-13, lanzado por `EjecutarScriptSalida`, SC-53)', ''))) = length('(SC-13, lanzado por `EjecutarScriptSalida`, SC-53)') FROM entradas WHERE codigo = 'SC-69';
INSERT INTO verificacion SELECT 'SC-75 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, 'con «-», por `EjecutarScriptSalida` (SC-53)', ''))) = length('con «-», por `EjecutarScriptSalida` (SC-53)') FROM entradas WHERE codigo = 'SC-75';
INSERT INTO verificacion SELECT 'SC-75 texto 2 una vez', (length(cuerpo) - length(replace(cuerpo, '- En Gambas, `m_GenerarSalidasLibro`: `HabilitarValidacion` (apartado 20 de `FMain.AbrirProyectoMD`), `ValidarCanonico`', ''))) = length('- En Gambas, `m_GenerarSalidasLibro`: `HabilitarValidacion` (apartado 20 de `FMain.AbrirProyectoMD`), `ValidarCanonico`') FROM entradas WHERE codigo = 'SC-75';
INSERT INTO verificacion SELECT 'SC-78 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, 'Lo escribe `m_Siglas.EscribirParaFiltro` desde `EjecutarScriptSalida`, la única lanzadora (SC-13), antes de los scripts que lo leen.', ''))) = length('Lo escribe `m_Siglas.EscribirParaFiltro` desde `EjecutarScriptSalida`, la única lanzadora (SC-13), antes de los scripts que lo leen.') FROM entradas WHERE codigo = 'SC-78';
INSERT INTO verificacion SELECT 'SC-80 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, '- El sitio de cada obra lleva una cabecera mínima (logo y vuelta al catálogo); el diseño fuerte queda en el portal. Si la cabecera de las obras siguiera la del portal, cambiar el portal obligaría a reconstruir cada obra.', ''))) = length('- El sitio de cada obra lleva una cabecera mínima (logo y vuelta al catálogo); el diseño fuerte queda en el portal. Si la cabecera de las obras siguiera la del portal, cambiar el portal obligaría a reconstruir cada obra.') FROM entradas WHERE codigo = 'SC-80';
INSERT INTO verificacion SELECT 'SC-81 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, 'Queda con 32 columnas.', ''))) = length('Queda con 32 columnas.') FROM entradas WHERE codigo = 'SC-81';
INSERT INTO verificacion SELECT 'SC-22 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, '1.21.0 (el libro en tres idiomas, `libro_venta` y el contrato con gbWeb, SC-81).', ''))) = length('1.21.0 (el libro en tres idiomas, `libro_venta` y el contrato con gbWeb, SC-81).') FROM entradas WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-25 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, '- Las blancas las ponen `\gbclearrecto` y `\gbclearverso`; nunca `\newpage\hbox{}` a mano.', ''))) = length('- Las blancas las ponen `\gbclearrecto` y `\gbclearverso`; nunca `\newpage\hbox{}` a mano.') FROM entradas WHERE codigo = 'SC-25';
INSERT INTO verificacion SELECT 'SC-83 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, 'EL ESQUEMA gbweb

', ''))) = length('EL ESQUEMA gbweb

') FROM entradas WHERE codigo = 'SC-83';
INSERT INTO verificacion SELECT 'SC-84 texto 1 una vez', (length(cuerpo) - length(replace(cuerpo, '- Se suben el `.md`, `media/` y `docs/`; `tmp/` no. Durante el desarrollo el repositorio es público; después, privado, con Netlify publicando `docs/`.', ''))) = length('- Se suben el `.md`, `media/` y `docs/`; `tmp/` no. Durante el desarrollo el repositorio es público; después, privado, con Netlify publicando `docs/`.') FROM entradas WHERE codigo = 'SC-84';

-- ------------------------------------------------------------
-- 2. SC-85
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('SC', 85, 'SC-85', 'HTML del libro integrado al portal de gbWeb: el destino, el marco descargado y la página (modelo 2)',
   'Decisiones de Alberto, 05 y 07/11/2026; documento de trabajo `claude/gbweb.md`. El sitio de una obra es una salida HTML de gbpublisher (SC-80). Desde la 1.22.0 tiene dos destinos.

EL DESTINO, DATO DEL LIBRO

- `libros_md.destino_html` ENUM(''autonomo'',''portal''), NOT NULL, ''autonomo'' por omisión: lo que la salida HTML hacía hasta entonces. `url_portal`: la dirección del portal, con su `/` final, como `gbweb.portal.url_base`. Dos CHECK: la forma de la URL, y que el destino portal tenga su URL. Sin catálogo de portales: el portal es estable y es una sola URL por libro. Se cargan en FMetadatosLibro (`m_Metadatos.UrlPortalValida`: obligatoria con portal, forma, agrega la `/`).
- La vista del contrato (`v_web_libro`, SC-81) lleva las dos columnas: gbWeb avisa al construir si un libro integrado declara otro portal. La asociación de gbWeb decide qué libros aparecen en el portal; la URL del libro decide solo su cabecera.
- Revistas: el mismo par va en la revista, no en el número (decisión de Alberto, 07/11/2026, `claude/salidas-revistas.md`).

LA CABECERA DEL PORTAL, COPIADA AL GENERAR

gbWeb publica el marco (SC-83); `generar_html_libro.sh`, con destino portal, lo baja de `<url_portal>marco/`, controla cada sha256 y recién entonces reemplaza `docs/assets/marco/`. El libro no depende de que el portal responda después: sin red, usa el marco anterior si sigue íntegro y es del mismo portal, con aviso (código 3). Si el `url-base` del manifiesto no es la URL del libro, frena: el portal se mudó y hay que corregir el formulario. Con destino autónomo, el marco y la hoja integrada se borran de `docs/`: un libro que deja el portal no conserva restos.

POR QUÉ COPIADA: el sitio del libro es otro repositorio y otra dirección, y en un sitio estático nada junta dos sitios al mostrar una página; copiada, el libro funciona solo (sin JavaScript para la cabecera, aunque el portal esté caído, sin pedidos al portal ni CORS); es determinista (la cabecera queda fechada con la edición del libro); y al libro se llega seguido sin pasar por el portal (Google Scholar, el DOI, un enlace compartido), y la cabecera le da a ese lector el camino al catálogo. Descartadas: armarla al abrir con JavaScript (salto visible, sin cabecera si falla el portal o no hay JavaScript) y armarla en el servidor con funciones de Netlify (lo más complejo de montar). La primera se puede sumar después sin rehacer nada.

LA PÁGINA (MODELO 2)

- La hoja `docbook-to-html-portal.xsl` importa la autónoma y reemplaza solo la raíz y las plantillas de página: la salida autónoma no la lee y no puede cambiar. De la autónoma se extrajeron plantillas compartidas con salida idéntica byte a byte.
- Una sola familia, Noto Serif 400 y 600 con sus cursivas, y Noto Sans Mono para el código y «Cómo citar»; nada de IBM Plex (`gbpublisher-integrado.css`).
- Cabecera y pie del marco. El idioma del marco es el del libro si el portal lo publica (se compara la primera parte del código: `pt-BR` es `pt`); si no, el castellano.
- Barra del libro fija al desplazar: «Índice» abre un menú de 600 px sobre el texto (tapa chica, título, autoría y la lista, con la pieza actual en negrita; sin JavaScript, con una casilla; Esc lo cierra), dónde se está, y Anterior / Siguiente, que se repiten al final de la pieza.
- Dos columnas fijas en el ancho útil del portal (1168 px): texto 600 | calle 24 | panel 544 (notas, referencias, figuras), siempre a la vista. Debajo de 1232 px, el panel es un cajón.
- En la cabeza del texto, «Cómo citar» y el PDF del capítulo.
- Portada (`index.html`, adonde lleva «Leer en línea»), créditos (`creditos.html`) y dedicatoria son pasos de la lectura, en páginas separadas y fuera del menú (SC-25). «Cómo citar» del libro, a la derecha, en las tres; los metadatos para indexadores, solo en la portada.
- ORCID como en la ficha del portal: el nombre sin enlace y el ícono enlazado.
- Compartir: la URL de cada página es `url_libro` + su archivo; sin `url_libro` no hay botones de compartir.
- La validación HTML5 (vnu) recibe todos los .html de `docs/` menos los de `assets/marco/`: los fragmentos no son páginas.

PROBADO por Alberto en Linux Mint (07/11/2026): el libro de Duek integrado al portal L-IMAGO, publicado en Netlify. Abrir el portal, ir al libro, navegarlo y volver desde el libro al inicio y al catálogo, sin errores. Antes, en el contenedor: cero enlaces rotos, cero errores de vnu y la misma salida en dos generaciones.',
   'vigente', 'empirica', 'gbpublisher 1.22.0 / Saxon-HE 12.5 / vnu / contenedor Ubuntu 24.04; Gambas 3.22 y Netlify, Linux Mint',
   '2026-11', 'vinculo:SC-80,vinculo:SC-81,vinculo:SC-83,vinculo:SC-84,vinculo:SC-25,vinculo:SC-53,vinculo:SC-22,apoya:GV-188', 'El HTML integrado de las revistas (etapa A de las salidas de revistas): la ficha del número y «Archivos» en gbWeb. Las figuras en el panel con el pie completo y uno corto en el texto (pedido de Alberto).', 850, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'SC-85 alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-85';

-- ------------------------------------------------------------
-- 3. GV-188
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 188, 'GV-188', 'Netlify, con «Pretty URLs», reescribe los enlaces de los .html que publica: …/index.html pasa a …/ y las comillas a simples',
   'MEDIDO el 07/11/2026 con curl sobre el portal L-IMAGO publicado en Netlify (https://monumental-tapioca-7b0eaf.netlify.app/), construido por gbWeb con enlaces internos a `…/index.html` y comillas dobles (GV-179):

- Las páginas llegan con `href=''/en/''` y `href=''/en/catalogo/''`: sin `index.html`, y con comillas simples donde `portal.xsl` escribió dobles.
- Del marco (SC-83), en ese momento con extensión .html: `marco.xml`, los `pie.html` (sin enlaces internos), `marco.css`, el logo y las fuentes coinciden con el sha256 de `marco.xml`; las `cabecera.html`, con enlaces al menú del portal, no.

Es el post-procesado «Pretty URLs» de Netlify. Se apaga desde el repositorio con `netlify.toml` (`[build.processing.html] pretty_urls = false`), que pisa el interruptor del panel según la documentación de Netlify («File-based configuration»). Con eso y los fragmentos del marco en `.xml`, Alberto volvió a construir y desplegar el portal y a generar el libro integrado, y el flujo anduvo sin errores (07/11/2026).

CONSECUENCIA: un archivo que se verifica por su huella después de publicarse no puede ser un .html servido por un host que reescribe páginas.',
   'vigente', 'empirica', 'Netlify (sitio estático desde un repositorio privado de GitHub) / curl / Linux Mint',
   '2026-11', 'vinculo:GV-179,vinculo:SC-83,vinculo:SC-84,vinculo:SC-85', NULL, 1880, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-188 alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-188';

-- ------------------------------------------------------------
-- 4. SC-53
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(replace(replace(replace(cuerpo, 'pasa por `m_GenerarSalidasLibro.EjecutarScriptSalida`. Es el contrato', 'pasa por `m_Lanzadora.EjecutarScript`. Es el contrato'), 'el parámetro opcional `sQue` de `EjecutarScriptSalida`, o el nombre', 'el parámetro opcional `sQue` de `EjecutarScript`, o el nombre'), 'Los fija `engine/comun.sh` y los replica `m_GenerarSalidasLibro`:', 'Los fija `engine/comun.sh` y los replica `m_Lanzadora`:'), 'CÓDIGOS

', 'UN MÓDULO NEUTRO (decisión de Alberto, 07/11/2026)

La lanzadora nació en `m_GenerarSalidasLibro`, con las salidas del libro, y el resto de la aplicación llamaba ahí para lanzar algo que no era un libro: cuadros, gráficos, la tapa web. Con las salidas de revistas pasó a un módulo propio, `m_Lanzadora`, sin cambiar su comportamiento (el código es el mismo, comparado función por función). Los nombres son los de la lanzadora de gbWeb (SC-50, SC-84): `EjecutarScript`, `InformarResultado`, `HayScriptEnCurso`, `HabilitarValidacion` y `ValidacionHabilitada`, que lee el guard de `m_GenerarSalidasLibro.ValidarCanonico`.

Lo que es de un tipo de proyecto queda en su módulo. Las siglas que leen algunos scripts del libro las prepara `m_Siglas.PrepararParaScript`, dueño de la lista de esos scripts (`SCRIPTS_CON_SIGLAS`): la lanzadora la llama antes de cada lanzamiento y no sabe nada de libros (SC-78).

CÓDIGOS

'),
       relaciones = CASE WHEN relaciones = '' THEN 'vinculo:SC-78,vinculo:SC-84' ELSE relaciones || ',vinculo:SC-78,vinculo:SC-84' END,
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-53';
INSERT INTO verificacion SELECT 'SC-53 con m_Lanzadora', instr(cuerpo, 'UN MÓDULO NEUTRO') > 0 AND instr(cuerpo, 'EjecutarScriptSalida') = 0 FROM entradas WHERE codigo = 'SC-53';

-- ------------------------------------------------------------
-- 5. SC-67
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '(SC-13, lanzado por `EjecutarScriptSalida`, SC-53)', '(SC-13, lanzado por `m_Lanzadora.EjecutarScript`, SC-53)'),
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-67';
INSERT INTO verificacion SELECT 'SC-67 lanzadora', instr(cuerpo, 'EjecutarScriptSalida') = 0 FROM entradas WHERE codigo = 'SC-67';

-- ------------------------------------------------------------
-- 6. SC-69
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '(SC-13, lanzado por `EjecutarScriptSalida`, SC-53)', '(SC-13, lanzado por `m_Lanzadora.EjecutarScript`, SC-53)'),
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-69';
INSERT INTO verificacion SELECT 'SC-69 lanzadora', instr(cuerpo, 'EjecutarScriptSalida') = 0 FROM entradas WHERE codigo = 'SC-69';

-- ------------------------------------------------------------
-- 7. SC-75
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(replace(cuerpo, 'con «-», por `EjecutarScriptSalida` (SC-53)', 'con «-», por `m_Lanzadora.EjecutarScript` (SC-53)'), '- En Gambas, `m_GenerarSalidasLibro`: `HabilitarValidacion` (apartado 20 de `FMain.AbrirProyectoMD`), `ValidarCanonico`', '- En Gambas: `m_Lanzadora.HabilitarValidacion` (apartado 20 de `FMain.AbrirProyectoMD`); en `m_GenerarSalidasLibro`, `ValidarCanonico`'),
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-75';
INSERT INTO verificacion SELECT 'SC-75 lanzadora', instr(cuerpo, 'EjecutarScriptSalida') = 0 AND instr(cuerpo, 'm_Lanzadora.HabilitarValidacion') > 0 FROM entradas WHERE codigo = 'SC-75';

-- ------------------------------------------------------------
-- 8. SC-78
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, 'Lo escribe `m_Siglas.EscribirParaFiltro` desde `EjecutarScriptSalida`, la única lanzadora (SC-13), antes de los scripts que lo leen.', 'Lo escribe `m_Siglas.EscribirParaFiltro`, llamada por `m_Siglas.PrepararParaScript` desde `m_Lanzadora.EjecutarScript`, la única lanzadora (SC-53), antes de los scripts que lo leen.'),
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-78';
INSERT INTO verificacion SELECT 'SC-78 lanzadora', instr(cuerpo, 'EjecutarScriptSalida') = 0 FROM entradas WHERE codigo = 'SC-78';

-- ------------------------------------------------------------
-- 9. SC-80
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '- El sitio de cada obra lleva una cabecera mínima (logo y vuelta al catálogo); el diseño fuerte queda en el portal. Si la cabecera de las obras siguiera la del portal, cambiar el portal obligaría a reconstruir cada obra.', '- El sitio de cada obra lleva la cabecera y el pie COMPLETOS del portal cuando la obra se integra a él (SC-85). Corrige lo decidido el 02/11 (una cabecera mínima, para no reconstruir las obras al cambiar el portal): el costo se acepta porque el portal es estable (decisión de Alberto, 05/11/2026). Una obra autónoma conserva su propia cabecera.'),
       relaciones = CASE WHEN relaciones = '' THEN 'vinculo:SC-85' ELSE relaciones || ',vinculo:SC-85' END,
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-80';
INSERT INTO verificacion SELECT 'SC-80 cabecera completa', instr(cuerpo, 'El sitio de cada obra lleva una cabecera mínima') = 0 AND instr(cuerpo, 'cabecera y el pie COMPLETOS') > 0 FROM entradas WHERE codigo = 'SC-80';

-- ------------------------------------------------------------
-- 10. SC-81
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, 'Queda con 32 columnas.', 'Queda con 32 columnas.
- 1.22.0, `v_web_libro`: `destino_html` y `url_portal` (SC-85). Queda con 34 columnas. gbWeb avisa al construir si un libro integrado declara otro portal.'),
       relaciones = CASE WHEN relaciones = '' THEN 'vinculo:SC-85' ELSE relaciones || ',vinculo:SC-85' END,
       titulo = 'Contrato gbpublisher → gbWeb: cinco VIEW, una cuenta de solo lectura y la tapa web en la base (esquemas 1.19.0 a 1.22.0)',
       entorno = replace(entorno, 'gbpublisher 1.19.0 a 1.21.0 (esquema)', 'gbpublisher 1.19.0 a 1.22.0 (esquema)'),
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-81';
INSERT INTO verificacion SELECT 'SC-81 con 1.22.0', instr(cuerpo, '1.22.0, `v_web_libro`') > 0 FROM entradas WHERE codigo = 'SC-81';

-- ------------------------------------------------------------
-- 11. SC-22
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '1.21.0 (el libro en tres idiomas, `libro_venta` y el contrato con gbWeb, SC-81).', '1.21.0 (el libro en tres idiomas, `libro_venta` y el contrato con gbWeb, SC-81); 1.22.0 (el destino del HTML del libro, SC-85).'),
       relaciones = CASE WHEN relaciones = '' THEN 'vinculo:SC-85' ELSE relaciones || ',vinculo:SC-85' END,
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 con 1.22.0', instr(cuerpo, '1.22.0 (el destino del HTML del libro') > 0 FROM entradas WHERE codigo = 'SC-22';

-- ------------------------------------------------------------
-- 12. SC-25
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '- Las blancas las ponen `\gbclearrecto` y `\gbclearverso`; nunca `\newpage\hbox{}` a mano.', '- HTML integrado al portal (SC-85): la portadilla se omite; la portada es `index.html`, adonde lleva «Leer en línea» desde el portal, y los créditos son `creditos.html`, con las mismas páginas que el EPUB (portada mínima si el libro no la declara). Son pasos de la lectura y no entran en el menú. El HTML autónomo sigue la matriz.
- Las blancas las ponen `\gbclearrecto` y `\gbclearverso`; nunca `\newpage\hbox{}` a mano.'),
       relaciones = CASE WHEN relaciones = '' THEN 'vinculo:SC-85' ELSE relaciones || ',vinculo:SC-85' END,
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-25';
INSERT INTO verificacion SELECT 'SC-25 HTML integrado', instr(cuerpo, 'HTML integrado al portal (SC-85)') > 0 FROM entradas WHERE codigo = 'SC-25';

-- ------------------------------------------------------------
-- 13. SC-83
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, 'EL ESQUEMA gbweb

', 'EL MARCO PARA LAS OBRAS INTEGRADAS (05/11/2026; .xml desde el 07/11/2026)

Con la dirección del sitio, `portal.xsl` escribe además la cabecera y el pie de cada idioma como fragmentos XML, `marco/<idioma>/cabecera.xml` y `pie.xml`, con `marco` en verdadero: enlaces absolutos a `url_base`, el logo relativo al fragmento (`../media/…`) y los botones de compartir con los patrones `{u}` y `{t}`, que gbpublisher completa en cada página de la obra. Sin banderas: la obra está en un idioma. El paso 7b de `construir_sitio.sh` suma la hoja con nombre fijo (`marco.css`), las fuentes con su licencia y el logo, y escribe `marco/marco.xml`: el portal (`codigo`, `url-base`) y cada archivo con su sha256, en orden fijo. Lo baja y lo verifica gbpublisher (SC-85).

POR QUÉ .xml: un servidor puede reescribir los .html que publica. Netlify, con «Pretty URLs», cambia los enlaces `…/index.html` por `…/` (GV-188): la cabecera llegaba con otros bytes y gbpublisher la rechazaba por su sha256, mientras el pie, sin enlaces internos, pasaba. Los fragmentos ya eran XML (gbpublisher los lee con `doc()`); con la extensión `.xml` se sirven tal cual. Además el despliegue apaga Pretty URLs (SC-84), para que lo publicado sea lo construido.

EL ESQUEMA gbweb

'),
       relaciones = CASE WHEN relaciones = '' THEN 'vinculo:SC-85,apoya:GV-188' ELSE relaciones || ',vinculo:SC-85,apoya:GV-188' END,
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-83';
INSERT INTO verificacion SELECT 'SC-83 con el marco', instr(cuerpo, 'EL MARCO PARA LAS OBRAS INTEGRADAS') > 0 FROM entradas WHERE codigo = 'SC-83';

-- ------------------------------------------------------------
-- 14. SC-84
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '- Se suben el `.md`, `media/` y `docs/`; `tmp/` no. Durante el desarrollo el repositorio es público; después, privado, con Netlify publicando `docs/`.', '- Se suben el `.md`, `media/` y `docs/`; `tmp/` no. Durante el desarrollo el repositorio es público; después, privado, con Netlify publicando `docs/`.
- `netlify.toml` en la raíz del repositorio, al lado de `docs/`, con `[build.processing.html] pretty_urls = false` (decisión de Alberto, 07/11/2026): Netlify no reescribe lo que publica (GV-188). Lo escribe el script si falta; si existe y no apaga Pretty URLs, avisa y no lo pisa. El archivo pisa el interruptor del panel de Netlify (documentación de Netlify, «File-based configuration»).'),
       relaciones = CASE WHEN relaciones = '' THEN 'apoya:GV-188' ELSE relaciones || ',apoya:GV-188' END,
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-84';
INSERT INTO verificacion SELECT 'SC-84 con netlify.toml', instr(cuerpo, 'pretty_urls = false') > 0 FROM entradas WHERE codigo = 'SC-84';

COMMIT;

SELECT codigo, estado, titulo FROM entradas
 WHERE codigo IN ('SC-22','SC-25','SC-53','SC-67','SC-69','SC-75','SC-78','SC-80','SC-81','SC-83','SC-84','SC-85','GV-188')
 ORDER BY prefijo, numero;
