-- ============================================================
-- gbCorpus — actualización 48: notas internas (SC-60) y lo que dejó
--            verificado su desarrollo; SC-22 con la cadena hasta la
--            1.12.0 y el punto de ruptura del baseline 2.0.0
-- Esquema: 1
-- Origen: rediseño de las notas internas de gbpublisher (lotes 1.10.0,
--         versión pestaña, y 1.12.0), probado por Alberto en Mint el
--         20/10; banco gbPruebaChat (3.19 en el contenedor y 3.22.2 en
--         Mint); arnés de m_Notas; error 3823 remedido en MySQL 8.0.46.
--         Propuesta aprobada por Alberto el 20/10. Numerado contra la
--         carpeta local de gbCorpus (último aplicado: act-47) y
--         docs/corpus.md de gbpublisher (678005a).
-- Fecha:  2026-10-20
-- Aplicar: después de act-47
--
-- ALTAS:
--   GV-107  TextEdit.InsertRichText: fusiona con el párrafo del cursor
--   GV-108  HtmlView: Html no mueve la vista; Load con ancla sí
--   GV-109  WebView: SetHtml asíncrono; ExecJavascript deja correr eventos
--   GV-110  gb.db2 / MySQL: Exec, Timeout y READ_TIMEOUT
--   GV-111  MySQL 8: CHECK y acción referencial que modifica (error 3823)
--   GV-112  GridView: Rows.Count = 0 no borra el formato de las celdas
--   SC-60   Notas internas: temas con ciclo de vida
-- MODIFICA:
--   SC-22   la cadena hasta la 1.12.0; punto de ruptura del baseline
--           2.0.0 con el refactor de bibtex; relación con SC-60
-- ============================================================

BEGIN TRANSACTION;

CREATE TEMP TABLE verificacion (paso TEXT, ok INTEGER CHECK (ok = 1));

-- ------------------------------------------------------------
-- 1. ESTADO DE PARTIDA
-- ------------------------------------------------------------
INSERT INTO verificacion SELECT 'GV-106 última GV', MAX(numero) = 106 FROM entradas WHERE prefijo = 'GV';
INSERT INTO verificacion SELECT 'SC-59 última SC', MAX(numero) = 59 FROM entradas WHERE prefijo = 'SC';
INSERT INTO verificacion SELECT 'GV-107 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-107' OR (prefijo = 'GV' AND numero = 107);
INSERT INTO verificacion SELECT 'GV-108 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-108' OR (prefijo = 'GV' AND numero = 108);
INSERT INTO verificacion SELECT 'GV-109 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-109' OR (prefijo = 'GV' AND numero = 109);
INSERT INTO verificacion SELECT 'GV-110 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-110' OR (prefijo = 'GV' AND numero = 110);
INSERT INTO verificacion SELECT 'GV-111 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-111' OR (prefijo = 'GV' AND numero = 111);
INSERT INTO verificacion SELECT 'GV-112 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'GV-112' OR (prefijo = 'GV' AND numero = 112);
INSERT INTO verificacion SELECT 'SC-60 libre', COUNT(*) = 0 FROM entradas WHERE codigo = 'SC-60' OR (prefijo = 'SC' AND numero = 60);
INSERT INTO verificacion SELECT 'SC-22 ancla de la cadena (una vez)', (length(cuerpo) - length(replace(cuerpo, '1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (refactor de bibtex) pendiente.', ''))) = length('1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (refactor de bibtex) pendiente.') FROM entradas WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 sin la sección nueva', instr(cuerpo, 'PUNTO DE RUPTURA: BASELINE 2.0.0') = 0 FROM entradas WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 sin relación con SC-60', instr(relaciones, 'SC-60') = 0 FROM entradas WHERE codigo = 'SC-22';

-- ------------------------------------------------------------
-- 2. GV-107
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 107, 'GV-107', 'TextEdit.InsertRichText: fusiona el fragmento con el párrafo del cursor y no aplica el <style> del documento',
   '`InsertRichText(Text)` (`CTextEdit.cpp`, 3.22.1) inserta un fragmento HTML en la posición del cursor. Antes se lleva el cursor al final con `Select(posición, 0)`, nunca con `Pos` (GV-44).

Medido en banco, con tres formas de armar el fragmento:

    <p> tal cual                     se pega al final del párrafo anterior: Qt fusiona
                                     el primer párrafo del fragmento con el del cursor
    salto de párrafo + <p>           queda separado, pero hereda el formato del anterior:
                                     un fondo se corre a todo lo que se inserta después
    <p> en una tabla de una celda    separado y sin herencia; el fondo va en la celda (GV-64)

Ningún fragmento insertado aplica las clases del `<style>` del documento: los estilos van en línea. Con la tabla de una celda y estilos en línea, un mensaje cuesta alrededor de 1 ms con 300 en pantalla.

En el proyecto, el hilo de una nota se carga entero por `RichText` (`m_Notas`, SC-60): un hilo es corto y se lee completo.',
   'vigente', 'empirica',
   'Gambas 3.19 / gb.qt5 / contenedor Ubuntu 24.04 (Xvfb, Fusion), banco gbPruebaChat; el mismo banco corrido por Alberto en Gambas 3.22.2 / Linux Mint',
   '2026-10', 'vinculo:GV-64,vinculo:GV-44,vinculo:GV-37,vinculo:GV-52,vinculo:SC-60',
   'En Mint, el banco confirmó que TextEdit es rápido; las tres variantes se compararon solo en 3.19.',
   1070, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-107 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-107';

-- ------------------------------------------------------------
-- 3. GV-108
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 108, 'GV-108', 'HtmlView: asignar Html no mueve la vista; solo Load con ancla desplaza',
   '- `Html`: `Html_Write` (`HtmlView.class`) reemplaza el documento y no toca el desplazamiento. MEDIDO: la vista se queda donde estaba. Con 300 mensajes, cada reasignación costó entre 45 y 120 ms.
- `Load(archivo#ancla)`: es lo único que procesa un ancla. Busca el elemento por `id` o `name` (`find_anchor`, `c_htmldocument.cpp`) y desplaza hasta él; el documento tiene que pasar por un archivo temporal. LEÍDO en el fuente.
- El control no expone su desplazamiento: no hay forma de «bajar solo si ya estaba al final».

Por eso se descartó para el hilo de las notas (SC-60), y es una razón más para retirar HtmlView del proyecto (pendiente de SC-24).',
   'vigente', 'empirica',
   'Gambas 3.19 / gb.form.htmlview / contenedor (banco gbPruebaChat); fuente de HtmlView.class y c_htmldocument.cpp (3.22.1); banco corrido por Alberto en Gambas 3.22.2 / Linux Mint',
   '2026-10', 'vinculo:SC-24,vinculo:GV-107,vinculo:SC-60',
   'Load con ancla no se midió en ejecución.',
   1080, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-108 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-108';

-- ------------------------------------------------------------
-- 4. GV-109
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 109, 'GV-109', 'WebView: SetHtml es asíncrono y ExecJavascript deja correr los eventos mientras espera',
   '- `SetHtml` vuelve enseguida: la página queda lista recién en el evento `Finish`. En el banco, `Finish` llegó a los 74 ms.
- `ExecJavascript` espera el resultado con `GB.Wait(-1)` (LEÍDO en `c_webview.cpp`): los eventos siguen corriendo durante la espera.
  - Un `Timer` puede volver a entrar a mitad de la llamada.
  - Una segunda llamada antes de que vuelva la primera da «Pending asynchronous method» (LEÍDO en el fuente).
  - Quien lo use desde un timer necesita una guarda de reentrada.
- Agregar un mensaje con `ExecJavascript` costó entre 2 y 12 ms, y la vista sigue al final.

En Mint fue el que mejor se vio. No se adoptó para las notas (SC-60): el hilo es corto y TextEdit alcanza, sin otro componente ni otro motor.',
   'vigente', 'empirica',
   'Gambas 3.19 / gb.qt5.webview / contenedor (banco gbPruebaChat); fuente de c_webview.cpp (3.22.1); banco corrido por Alberto en Gambas 3.22.2 / Linux Mint',
   '2026-10', 'vinculo:GV-107,vinculo:GV-108,vinculo:SC-60',
   'La reentrada no se provocó: con un mensaje automático por segundo no apareció.',
   1090, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-109 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-109';

-- ------------------------------------------------------------
-- 5. GV-110
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 110, 'GV-110', 'gb.db2 / MySQL: Exec congela la interfaz; Timeout solo acota la apertura; READ_TIMEOUT acota la lectura y deja la conexión muerta',
   '- `Connection.Exec` es sincrónico: la interfaz no se redibuja hasta que vuelve. MEDIDO en Mint: con `SELECT SLEEP(2)`, el reloj del banco se congeló y el tick siguiente se corrió un segundo.
- `Connection.Timeout` acota solo `Open`. Una consulta lenta sobre una conexión abierta no tiene plazo.
- `Options["READ_TIMEOUT"]` acota cada lectura. El driver la pasa a `MYSQL_OPT_READ_TIMEOUT` (`options.h`). Se asigna ANTES de `Open`: las opciones se leen al abrir.
  - MEDIDO en 3.19 con `READ_TIMEOUT = 2`: `SELECT SLEEP(5)` falla a los 2,00 s con «Lost connection».
  - La conexión queda muerta: la consulta siguiente también falla. Hay que descartarla y abrir otra.
- Las claves de `Options` no distinguen mayúsculas, y una clave desconocida se ignora sin aviso (LEÍDO en el fuente del driver). Un `READ_TIMOUT` mal escrito deja la conexión sin plazo y nadie avisa.

PATRÓN EN EL PROYECTO

`m_ConexionBD.AbrirConexionSondeo` abre una conexión aparte, con plazo de lectura, para el sondeo periódico de las notas (`m_Notas`, SC-60).

- La consulta del sondeo no pasa por `mConn`, que no tiene plazo.
- Tras un fallo, `m_Notas` descarta esa conexión y el tick siguiente abre otra.
- Con el semáforo de red en rojo, ni siquiera consulta.',
   'vigente', 'empirica',
   'Gambas 3.22.2 / gb.db2.mysql / Linux Mint (banco gbPruebaChat, Alberto); Gambas 3.19 / gb.db.mysql / MySQL 8.0.46 / contenedor; fuente de gb.db2.mysql (options.h)',
   '2026-10', 'vinculo:GV-23,vinculo:SC-60',
   'El plazo se midió con gb.db en 3.19; en Mint, con gb.db2, el sondeo funciona pero el vencimiento no se provocó. Mini-test: abrir con AbrirConexionSondeo(2) y ejecutar SELECT SLEEP(5); debe fallar a los 2 s.',
   1100, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-110 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-110';

-- ------------------------------------------------------------
-- 6. GV-111
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 111, 'GV-111', 'MySQL 8: una columna con CHECK no admite una acción referencial que la modifique (error 3823)',
   'Una columna que aparece en un `CHECK` no puede llevar, en su clave foránea, una acción que cambie su valor. Medido:

    ON UPDATE CASCADE      ERROR 3823
    ON UPDATE SET NULL     ERROR 3823
    ON DELETE SET NULL     ERROR 3823
    ON DELETE SET DEFAULT  ERROR 3823
    ON DELETE CASCADE      aceptada (borra la fila, no cambia la columna)
    RESTRICT / NO ACTION   aceptadas

    Column ''pid'' cannot be used in a check constraint ''chk'': needed in a foreign key constraint ''fk'' referential action.

Un `CHECK` sobre OTRA columna de la misma tabla no tiene restricción.

CASO EN EL PROYECTO: la 1.10.0 (notas, SC-60) tiene `CHECK` sobre columnas con clave foránea (`chk_notas_destino` sobre `id_destinatario` e `id_grupo`). Por eso sus catorce claves son `ON DELETE RESTRICT ON UPDATE RESTRICT`. En el proyecto ningún id cambia, así que `ON UPDATE CASCADE` no aporta nada.',
   'vigente', 'empirica',
   'MySQL 8.0.46 / contenedor Ubuntu 24.04',
   '2026-10', 'vinculo:SC-22,vinculo:SC-60',
   NULL,
   1110, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-111 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-111';

-- ------------------------------------------------------------
-- 7. GV-112
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('GV', 112, 'GV-112', 'GridView: volver Rows.Count a 0 no borra el formato de las celdas',
   'Una grilla se vació con `Rows.Count = 0` y se volvió a llenar. Las celdas a las que no se les asignó `Background` en la carga nueva mostraron el fondo de la carga anterior: una nota cerrada heredaba el verde del índice de días.

REGLA: una carga que pinta celdas asigna el fondo en TODAS las celdas de la columna, también `Color.Default` en las que no llevan color. Aplicado en `m_Notas.CargarLista` y en `FSysAdmin.CargarNotasAdmin`.',
   'vigente', 'empirica',
   'Gambas 3.19 / gb.qt5 / contenedor (arnés de m_Notas)',
   '2026-10', 'vinculo:GV-58,vinculo:SC-60',
   'No se miró si pasa lo mismo con Foreground, Font y Alignment, ni si Clear lo evita. Falta confirmarlo en 3.22.',
   1120, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'GV-112 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'GV-112';

-- ------------------------------------------------------------
-- 8. SC-60
-- ------------------------------------------------------------
INSERT INTO entradas
  (prefijo, numero, codigo, titulo, cuerpo, estado, evidencia, entorno,
   fecha_verificacion, relaciones, pendiente, orden, fecha_alta, fecha_modificacion)
VALUES
  ('SC', 60, 'SC-60', 'Notas internas: temas con ciclo de vida, por proyecto o 1 a 1',
   'DECISIÓN CERRADA (Alberto, octubre de 2026). Reemplaza a `postits`, retirada en la 1.12.0. Se evaluó un chat al estilo Zulip y se descartó: el equipo necesita temas que se notifican, se siguen y se cierran, no conversación en caliente.

MODELO

- Una nota es 1 a 1 (a otro usuario o a uno mismo) o de proyecto (al grupo del proyecto). Tiene una cosa o la otra (`CHECK chk_notas_destino`).
- El grupo de un proyecto es único (`notas_grupos`).
  - Lo crea un usuario con el proyecto abierto, y queda como creador y miembro.
  - Solo el creador suma y da de baja miembros. La baja es lógica, y cada alta y cada baja queda registrada.
  - Un miembro nuevo ve todo lo activo del grupo, pero no lo archivado antes de su alta.
- Las respuestas van dentro de la nota, como hilo. El texto de una nota no se edita.
- Cerrar = archivar: lo hace solo el autor, y nada se borra. La hora de despacho opcional (`desde`) oculta la nota a los destinatarios hasta esa hora.
- Archivadas: las ve quien participó, es decir, autor, destinatario, quien respondió o quien la abrió (`notas_vistas`). Leer cuenta como participar.
- Sin roles en `usuarios`: el administrador actúa desde FSysAdmin (pestaña «Notas», `hConnServidor`).
  - Transfiere el rol de creador de un grupo con creador inactivo.
  - Cierra las notas de un usuario inactivo.
  - Al archivar un proyecto, cierra las notas de su grupo en la misma transacción.
  - Lo que cierra queda firmado en `cierre_sistema`.

INTERFAZ

- La pestaña «Notas» de FMain (`TabStrip1`, índice 8), con `m_Notas` como módulo dueño. Los handlers de FMain solo delegan.
- El indicador: `pbNotas` más `lblNotas` en `HBox3`.
- Alcance común: pestaña e indicador solo existen con sesión y proyecto abierto. Muestran las notas 1 a 1 del usuario más las del grupo del proyecto abierto.
- Índice de días corridos sin actividad: 0–3 verde, 4–6 ámbar, 7 o más rojo. En el indicador, rojo gana sobre verde.

SONDEO

- Lo dispara el latido de `TimerRed` (30 s), y solo con la red en verde.
- Usa una conexión propia, con plazo de lectura (GV-110).
- Hace una consulta por tick. Su firma incluye las notas, las respuestas, los cierres y el estado del grupo; la pestaña se recarga solo si cambió.
- Horas: las fechas viajan como segundos transcurridos según el servidor y se muestran con el reloj local. La hora de despacho viaja como segundos desde ahora, así que sirve con usuarios en otro huso horario (Argentina–Colombia).

ESQUEMA

- La 1.10.0 crea `notas`, `notas_grupos`, `notas_miembros`, `notas_respuestas` y `notas_vistas`, con claves `RESTRICT` (GV-111), y migra `postits` con el mismo id.
- La 1.12.0 retira `postits`.',
   'vigente', 'empirica',
   'gbpublisher / MySQL 8.0.46 / Gambas 3.22 / Linux Mint (prueba de Alberto, 20/10)',
   '2026-10', 'vinculo:SC-22,vinculo:GV-110,vinculo:GV-111,vinculo:GV-112,vinculo:GV-107,vinculo:GV-78,vinculo:GV-57',
   NULL,
   600, datetime('now','localtime'), datetime('now','localtime'));
INSERT INTO verificacion SELECT 'SC-60 dado de alta', COUNT(*) = 1 FROM entradas WHERE codigo = 'SC-60';

-- ------------------------------------------------------------
-- 9. SC-22: CADENA, PUNTO DE RUPTURA Y RELACIÓN
-- ------------------------------------------------------------
UPDATE entradas
   SET cuerpo = replace(cuerpo, '1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (refactor de bibtex) pendiente.',
         '1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (valores de los formatos de sistema Estudio 2A); 1.9.0 (`libros_md.estilo_cita` al identificador del estilo biblatex); 1.10.0 (notas internas, SC-60); 1.11.0 (tipos de pieza `indice_concepto` e `indice_autores`); 1.12.0 (retiro de la tabla `postits`, SC-60). El refactor de bibtex tomará el número que le corresponda.') || '

PUNTO DE RUPTURA: BASELINE 2.0.0 CON EL REFACTOR DE BIBTEX

Decisión de Alberto (20/10). El baseline no se regenera con cada versión de la cadena. El 2.0.0 se genera junto con el refactor de bibtex y lo incorpora: las instalaciones nuevas parten de ahí. Las existentes siguen su cadena hasta ese mismo punto. Hasta entonces, una instalación nueva restaura `baseline-1.0.0` y corre la cadena completa (BBDD_LEEME.md §5, «Cuándo conviene rebasear»).',
       relaciones = relaciones || ',vinculo:SC-60',
       fecha_modificacion = datetime('now','localtime')
 WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 con la cadena nueva', instr(cuerpo, '1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (valores de los formatos de sistema Estudio 2A); 1.9.0 (`libros_md.estilo_cita` al identificador del estilo biblatex); 1.10.0 (notas internas, SC-60); 1.11.0 (tipos de pieza `indice_concepto` e `indice_autores`); 1.12.0 (retiro de la tabla `postits`, SC-60). El refactor de bibtex tomará el número que le corresponda.') > 0 FROM entradas WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 sin la cadena vieja', instr(cuerpo, '1.7.0 (retiro de la tabla shortcodes, SC-34); 1.8.0 (refactor de bibtex) pendiente.') = 0 FROM entradas WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 con el punto de ruptura', instr(cuerpo, 'PUNTO DE RUPTURA: BASELINE 2.0.0') > 0 FROM entradas WHERE codigo = 'SC-22';
INSERT INTO verificacion SELECT 'SC-22 con relación a SC-60', instr(relaciones, ',vinculo:SC-60') > 0 FROM entradas WHERE codigo = 'SC-22';

COMMIT;

SELECT codigo, estado, titulo FROM entradas
 WHERE codigo IN ('GV-107', 'GV-108', 'GV-109', 'GV-110', 'GV-111', 'GV-112', 'SC-60', 'SC-22')
 ORDER BY prefijo, numero;
