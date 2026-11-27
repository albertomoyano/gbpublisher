# La base de datos de gbpublisher

Este documento explica cómo se instala la base de datos, por qué está
organizada así, y qué hay que hacer cuando el esquema cambie.

Está dirigido a quien instala gbpublisher en una institución y a quien
mantiene el proyecto. No hace falta conocer el código de la aplicación
para leerlo.

---

## 1. Qué se instala

Una instalación nueva parte de un único archivo, el **baseline**:

```
gbpublisher-baseline-2.0.0.sql
```

Ese archivo contiene la estructura completa de la base y los datos propios
de la aplicación: ayudas del manual (hasta la 2.5.0, que borra esa tabla), consultas predefinidas, tipos de
entrada y catálogo de campos de la bibliografía, formatos de página, roles
CRediT, idiomas, países, licencias y tipos de declaración. No contiene
datos editoriales de nadie: ni proyectos, ni artículos, ni usuarios, ni
credenciales.

Se instala con el asistente:

```bash
./instalar-gbpublisher.sh
```

El asistente busca el baseline en su misma carpeta, verifica que sea
válido, avisa que la operación es destructiva, pide confirmación explícita,
importa el archivo, crea el usuario de la aplicación y comprueba el
resultado antes de dar por buena la instalación.

Para una instalación cliente/servidor pregunta el rango de red de las
máquinas cliente, o se le puede indicar directamente:

```bash
./instalar-gbpublisher.sh -r '192.168.128.%'
```

**Desde la 2.0.0 el baseline es el esquema actual.** Incorpora las
actualizaciones 1.1.0 a 2.0.0: una instalación nueva no aplica ninguna de
ellas. El baseline 1.0.0 queda en el repositorio como punto de partida de
esa cadena, que es la que siguen las instalaciones anteriores (ver la
sección 5). Está previsto que un único instalador (`instalador.sh`) haga
todo esto; mientras tanto, la guía paso a paso está en [LEEME.md](LEEME.md).

---

## 2. Las capas de identidad

Es la confusión más frecuente en las instalaciones nuevas, así que conviene
dejarla clara de entrada. Hay tres cosas distintas que suelen mezclarse, y
una cuarta donde se usa gbWeb:

**El usuario de la aplicación (`app_user`).** Es una cuenta de MySQL, una
sola por instalación, con su clave propia. Es la que usa gbpublisher para
abrir la conexión. El usuario final nunca la ve ni la escribe.

Su clave no está escrita en el código ni en el repositorio. Cada
instalación genera la suya, al azar, y la guarda en el archivo de conexión
del usuario de la computadora:

```
~/.gbpublisher/conexion.conf
```

Es un archivo de opciones de MySQL (`[client]` con `user`, `password` y
`host`; `[mysql]` con `database`), con permisos 600: solo lo lee su dueño.
Lo leen la aplicación, `mysql` y `mysqldump` (`--defaults-extra-file`).
`database` va en `[mysql]` y no en `[client]` porque `mysqldump` la rechaza.
Sin ese archivo, la aplicación no se conecta y dice qué hacer.

Lo escribe `configurar-conexion.sh`, que se corre **sin sudo** (el archivo es
del usuario) y pide la contraseña de administrador con una ventana gráfica
solo para cambiar la clave en MySQL. Decide por el estado real: si el archivo
existe y abre una sesión, no toca nada; si no, genera una clave nueva, la
pone en todas las cuentas `app_user` del servidor y escribe el archivo.
`instalar-gbpublisher.sh` lo llama al final.

**Los usuarios de gbpublisher.** Viven en la tabla `usuarios` de la base.
Se dan de alta desde el formulario de administración de la aplicación. **No
son cuentas de MySQL**: crear un usuario nuevo no requiere ninguna acción
del lado del servidor de base de datos.

**La cuenta administrativa del servidor** (`root` o equivalente). Se usa
para instalar y para aplicar cambios de esquema. La aplicación nunca la
usa, y `app_user` no puede reemplazarla: no tiene permisos para modificar
estructuras.

**La cuenta de lectura de gbWeb (`gbweb_lector`).** Es una cuenta de
MySQL, como `app_user`, pero de otra aplicación: gbWeb, el portal estático
de la editorial. Solo puede leer las cuatro vistas `v_web_*` que crea la
actualización 1.19.0; cualquier tabla le está vedada. No la crea este
instalador: existe solo donde se usa gbWeb, y la crea
`crear-cuenta-gbweb.sh`, del repositorio de gbWeb, que guarda su clave en
`~/.gbweb/conexion.conf`.

La aplicación valida en dos etapas independientes: primero abre la conexión
con `app_user`, donde el usuario final no interviene; después valida usuario
y clave contra la tabla `usuarios`.

### Identidad por host en MySQL

`'app_user'@'localhost'` y `'app_user'@'192.168.128.%'` son **cuentas
distintas**, no un permiso que se extiende. Habilitar el acceso desde la red
no es ampliar un permiso existente: es crear otra cuenta.

Por eso el asistente crea las dos cuando se le indica un rango de red, y
por eso conserva siempre la de `localhost` aunque la instalación sea
servidor: las conexiones desde la propia máquina del servidor usan socket
Unix y necesitan esa cuenta.

---

## 3. Por qué el baseline se genera, no se edita

El baseline no se mantiene a mano. Lo produce un script a partir de una
base que ya está en el nivel que el baseline declara:

```bash
./generar-baseline.sh -u root -d gbnueva -V 2.0.0 -o ./dist -v
```

Desde la 2.0.0 el origen recomendado no es la base de trabajo sino una base
instalada desde cero con la cadena completa (baseline 1.0.0 y las
actualizaciones hasta la 2.0.0). Así el baseline coincide con lo que tiene
toda instalación actualizada, sin los ajustes de una instalación concreta.
El baseline 2.0.0 se generó así, y al cargarlo da el mismo esquema
(columnas, índices, claves, restricciones, vistas y disparadores) y los
mismos datos semilla que esa base.

La razón es simple: un archivo que alguien preparó una vez a mano no se
puede volver a preparar igual. Al ser generado, el baseline es
**reproducible** — cualquiera puede regenerarlo y obtener el mismo
resultado — y las decisiones sobre qué contiene quedan escritas en el
script en lugar de vivir en la memoria de quien lo armó.

El generador hace cinco cosas que un volcado corriente no hace:

**Separa datos semilla de datos de trabajo.** La lista de tablas semilla
está declarada explícitamente en el script. Toda tabla que no esté en esa
lista se instala vacía, incluidas las que se agreguen en el futuro. El
default seguro es "vacía": olvidarse de agregar una tabla a la lista
produce una tabla sin datos, no una fuga de información de la instalación
de origen.

**Normaliza el cotejamiento.** Las tablas creadas bajo MySQL 8 pueden
quedar con `utf8mb4_0900_ai_ci`, el default del servidor, y no con el del
proyecto: comparar una de esas columnas con una del proyecto da «Illegal
mix of collations». El generador lo unifica a `utf8mb4_unicode_ci`. Las
columnas `utf8mb4_0900_as_ci` y `_as_cs` de siglas e índices son
deliberadas y se conservan.

**Elimina las cláusulas `DEFINER`.** Los disparadores y rutinas guardan el
usuario que los creó. Ese usuario no existe en el servidor de destino, así
que la referencia se quita para que hereden el usuario que importa.

**Declara `ROW_FORMAT=DYNAMIC` de forma explícita.** `mysqldump` omite el
formato de fila cuando coincide con el default del servidor de origen. Si
el servidor de destino tiene otro default, las tablas anchas no se pueden
crear. Al viajar explícito, la carga es independiente de la configuración
del destino.

**Carga con `innodb_strict_mode` activo.** Hasta la 1.x el baseline lo
relajaba; desde la 2.0.0 no hace falta y el generador comprueba que no lo
haga. Ver la sección siguiente.

Además verifica lo que produjo: cuenta tablas, comprueba que ninguna tabla
de trabajo traiga datos, y con la opción `-v` carga el archivo en una base
temporal para confirmar que se restaura sin errores. Un baseline que no
pasa esas verificaciones no debería distribuirse.

---

## 4. Las tablas anchas y el límite de fila

> **Histórico.** Esta sección describe la tabla `articulos` del esquema viejo
> de revistas, que la actualización 1.32.0 borró junto con `revistas_md`,
> `articulo_autor` y `articulo_revisor`. Sigue importando por dos razones:
> el baseline 1.0.0 todavía la crea, y todo respaldo anterior a la 1.32.0 la
> trae. Restaurar uno de esos respaldos requiere
> `--init-command="SET SESSION innodb_strict_mode=0"`; sin eso, MySQL 8
> falla con el error 1118 al recrear la tabla. Un respaldo posterior a la
> 1.32.0 se restaura sin relajar nada (medido, GV-67), y el baseline 2.0.0
> ya no trae esa línea.
>
> La otra tabla ancha, `bibtex` (110 columnas, una por campo de biblatex),
> pasó en la 2.0.0 a un modelo de entrada y pares: `bibtex` guarda la
> entrada (proyecto, tipo, clave) y `bibtex_campo` un par campo/valor por
> cada dato que la referencia tiene. Los nombres de campo son los de
> biblatex y los valida el catálogo `bibtex_campo_catalogo`. En la base de
> trabajo, al migrar, una referencia usaba en promedio siete campos de 105:
> el resto de las columnas viajaba vacío.

`articulos` tenía 220 columnas. Es una decisión deliberada: los metadatos
de un artículo académico son muchos y muy variados, y resolverlos en una
tabla ancha evita una decena de uniones en cada consulta a lo largo de toda
la producción editorial. La mayoría de esas columnas están vacías en
cualquier artículo concreto, y una columna vacía es más barata que una
unión repetida miles de veces.

Esa decisión tenía una consecuencia técnica que conviene conocer.

InnoDB limita el tamaño de fila a unos 8 KB. En el formato `DYNAMIC` los
campos de texto grandes se almacenan **fuera** de la fila, dejando solo un
puntero, así que en la práctica la tabla funciona sin problema. Pero al
**crear** la tabla, MySQL 8 aplica un chequeo estricto
(`innodb_strict_mode`, activo por omisión) que calcula el peor caso teórico
y rechaza la creación aunque en uso real la fila entre de sobra.

Por eso el baseline 1.0.0 trae en su cabecera:

```sql
SET SESSION innodb_strict_mode=0;
```

y lo restaura al final. Es el mecanismo previsto para tablas anchas
legítimas y no altera el comportamiento posterior de la base. **Sin esa
línea, la restauración falla con el error 1118 en cualquier servidor MySQL
8**, que es la configuración habitual.

Complementariamente, las columnas de texto libre y URLs de `articulos`
están declaradas como `TEXT` y no como `VARCHAR` grande. Para un campo que
suele estar vacío, `TEXT` es más barato: no reserva espacio en el cálculo
de fila. Las columnas que participan en índices (`titulo_articulo`,
`nombre_archivo`, `tipo_articulo`, `doi`) siguen siendo `VARCHAR`, porque
un índice sobre `TEXT` requiere longitud de prefijo.

**Consecuencia práctica para el futuro:** en cualquier tabla ancha, usar
`TEXT` para texto libre y reservar `VARCHAR` para códigos cortos y campos
indexados. Cada `VARCHAR` grande nuevo acerca la tabla al límite; un `TEXT`
no. El esquema nuevo de revistas (`articulo`, desde la 1.13.0) reparte los
metadatos en tablas relacionadas en lugar de una sola tabla ancha.

---

## 5. Control de versión del esquema

Este es el punto que hace que un cambio futuro sea manejable en vez de un
problema de coordinación a distancia.

Toda instalación tiene una tabla `esquema_version`:

| parche | aplicado_en | descripcion |
|---|---|---|
| baseline-2.0.0 | 2026-11-20 20:41:09 | Esquema de distribución inicial |

La tabla viene **dentro del baseline**, con su fila puesta. No es un paso
aparte que alguien pueda olvidar: toda instalación nueva declara su nivel
desde el primer segundo.

### Por qué hace falta

Sin ese registro, una base no puede decir qué versión de esquema tiene. Con
varias instituciones instalando en momentos distintos, la única forma de
averiguarlo sería inspeccionar tabla por tabla, o preguntar por correo. Con
el registro, cualquier script puede consultar el nivel y decidir solo si
corresponde actuar.

### Cómo se maneja un cambio de esquema

Cuando el esquema cambie —una columna nueva, una tabla nueva, un tipo
distinto— hay dos caminos según el destinatario:

**Instalaciones nuevas:** se regenera el baseline con la versión siguiente
(`generar-baseline.sh -V 1.1.0`). El cambio queda incorporado y quien
instale desde ese momento lo recibe de fábrica, sin pasos adicionales.

**Instalaciones existentes con datos:** se distribuye un script de
actualización que aplica el cambio sobre la base en uso, preservando el
contenido editorial, y registra su paso en `esquema_version`.

Los dos caminos llevan al mismo esquema. Lo que difiere es el historial:
una instalación nueva tendrá una sola fila (`baseline-2.0.0`), y una
actualizada tendrá una por paso (`baseline-1.0.0` y cada script aplicado).

Por eso todo script posterior a un baseline acepta como antecesor tanto la
actualización anterior como el baseline que la incluye: la 2.1.0 tendrá
que aceptar `actualizacion-2.0.0` o `baseline-2.0.0`. La 2.0.0 sobre una
base instalada desde el baseline 2.0.0 dice que no hay nada que hacer.

### La regla que se desprende

Un script de actualización **verifica el estado real del esquema** antes de
actuar: si la columna ya existe, no la agrega; si la tabla ya tiene la forma
esperada, no la toca.

Además, desde la 1.10.0 cada script **exige que la actualización anterior
esté registrada** en `esquema_version`, y frena si no lo está. Las dos
cosas no se contradicen: el registro asegura que la cadena se aplique en
orden, y la verificación del estado real asegura que aplicar un script dos
veces no cause daño.

Esto tiene un efecto valioso: los scripts se vuelven **idempotentes**. Se
pueden ejecutar más de una vez sin consecuencias, y se pueden ejecutar
sobre una base cuyo estado exacto no se conoce. Que es justamente la
situación de quien instala a mil kilómetros de distancia.

Las propiedades que todo script de actualización debe tener:

1. **Confirmación explícita.** Explica qué va a cambiar y pide que se
   escriba `SI`. Si borra datos, muestra cuáles antes de preguntar.
2. **Respaldo previo verificado.** Antes de modificar nada, generar un
   volcado y comprobar que quedó completo. No alcanza con que el comando
   devuelva éxito: hay que verificar el archivo producido.
3. **Verificación posterior.** Comprobar que el resultado es el esperado
   —conteos, tipos de columna, filas preservadas— y avisar si no lo es.
4. **Salida sin efecto si ya está aplicado.** Detectar el estado y
   terminar sin tocar nada cuando no hay trabajo pendiente.

### La cadena actual

| Caso | Paso | Script |
|---|---|---|
| Instalación nueva | Instalación | `gbpublisher-baseline-2.0.0.sql` con `instalar-gbpublisher.sh`, y después `actualizar-esquema-2.1.0.sh` … `actualizar-esquema-2.5.0.sh`, en orden |
| Instalación anterior a la 2.0.0 | Actualizaciones | `actualizar-esquema-1.1.0.sh` … `actualizar-esquema-1.34.0.sh` y `actualizar-esquema-2.0.0.sh` … `actualizar-esquema-2.5.0.sh`, en orden, desde la última que tenga registrada |

Para saber en qué punto está una base:

```sql
SELECT parche, aplicado_en FROM esquema_version ORDER BY aplicado_en;
```

Se corren con `sudo bash actualizar-esquema-X.Y.Z.sh`. Los respaldos quedan
en `~/gbpublisher-respaldos/`. Las actualizaciones que borran tablas o datos
(1.32.0, 1.33.0) no se deshacen con un parche: se vuelve atrás restaurando el
respaldo que hicieron antes de empezar, y cada una muestra el comando.

La 1.34.0 no toca tablas ni datos: le da a `app_user` el permiso `SHOW VIEW`,
de solo lectura, que necesita el respaldo diario de la aplicación para copiar
las vistas de gbWeb. Por eso no hace respaldo, y se deshace con un `REVOKE`
que el script muestra.

La 2.0.0 pasa la bibliografía a pares campo/valor (sección 4):

- Copia cada valor no vacío a `bibtex_campo` con el nombre de biblatex.
- Corrige `eng` y `span` en los idiomas a `english` y `spanish`.
- Une `hyphenation` y `lang_id` en `langid`.
- Antes de borrar las columnas viejas, comprueba que el `.bib` de cada
  proyecto sale idéntico, byte a byte, armado desde las columnas y armado
  desde los pares. Si algún proyecto difiere, vacía los pares y no borra
  nada.
- Reescribe las consultas canónicas de bibliografía.
- Pasa `formatos_pdf` al cotejamiento del proyecto.
- Al final informa, sin tocar nada, los idiomas que no son nombres de
  babel, las claves que llegan al máximo de 32 caracteres y los valores con
  saltos de línea.

Se deshace borrando las dos tablas nuevas y restaurando el respaldo; el
script muestra los dos comandos. La aplicación de la 2.0.0 no funciona con
una base sin migrar, ni la 1.x con una migrada: hay que aplicar la
actualización antes de abrir la versión nueva.

La 2.5.0 borra `manual_ayudas`, la tabla de la ayuda contextual vieja: la
ayuda es ahora el manual de gbpublisher, un libro hecho con la propia
aplicación, que el menú «Acerca de…» abre en el navegador. Se aplica
**después** de instalar la aplicación nueva en todos los puestos: la
anterior no abre sin la tabla. Antes de borrarla deja, junto al respaldo
completo, un volcado solo de esa tabla; con él se repone sin restaurar toda
la base, y el script muestra el comando.

### El respaldo diario de la aplicación

Al abrirse, la aplicación respalda la base local en
`~/.gbpublisher/respaldo/gbpublisher_AAMMDD.sql`, uno por día, legible solo
por el usuario. El archivo del día se reemplaza solo por un respaldo
completo; si mysqldump falla, la aplicación lo avisa y deja el anterior.

Va **sin los disparadores** de `articulo_reapertura`: `app_user` no tiene el
permiso `TRIGGER`, a propósito, porque con él podría borrarlos. Después de
restaurar uno de estos respaldos hay que volver a correr
`actualizar-esquema-1.23.0.sh`, que repone los disparadores que falten.
Desde la 2.0.0 ese script también corre en una base instalada desde el
baseline 2.0.0.

### Cuándo conviene rebasear

La cadena de actualizaciones crece. Llegado cierto punto, instalar sería
restaurar el baseline y correr una larga secuencia de scripts en orden.

Antes de llegar ahí conviene **rebasear**: regenerar el baseline con todos
los cambios ya incorporados y publicarlo como una versión mayor. Las
instalaciones nuevas parten de ahí; las existentes siguen su cadena. Es un
mantenimiento planificado, no una emergencia, y hacerlo a tiempo evita que
la instalación se vuelva un procedimiento largo. El primer rebase es el
`baseline-2.0.0`, que reemplaza el baseline 1.0.0 más 35 actualizaciones.

---

## 6. Lo que no resuelve la base de datos

Dos cosas dependen del servidor y ningún script de la base puede
arreglarlas. Conviene conocerlas porque son la causa más frecuente de que
una instalación cliente/servidor no funcione.

**El servidor tiene que escuchar en la red.** MySQL viene configurado para aceptar solo conexiones locales
(`bind-address = 127.0.0.1`). Con esa configuración, ninguna otra máquina
puede conectarse, sin importar qué permisos tenga `app_user`. El síntoma es
un error de conexión rechazada (código 111): la conexión ni siquiera llega
al servidor de base de datos. Se corrige en la configuración de MySQL
(`bind-address = 0.0.0.0`) y reiniciando el servicio. El asistente de
instalación avisa cuando detecta esta situación.

**El puerto no debe quedar expuesto fuera del perímetro.** Hasta la
versión que introdujo el archivo de conexión, la clave de `app_user` era la
misma en todas las instalaciones y estaba publicada en el código. Desde
entonces cada instalación tiene la suya, pero el perímetro de red sigue
siendo la primera barrera: red interna de la institución, o VPN. Si el
servidor queda alcanzable desde una red más amplia, corresponde filtrar el
puerto 3306 con el cortafuegos. Por la misma razón, el asistente pide un
rango de red concreto en lugar de habilitar cualquier origen.

**Cada máquina cliente necesita su archivo de conexión.** En una
instalación cliente/servidor, `configurar-conexion.sh` se corre en el
servidor: cambia la clave de todas las cuentas `app_user` y escribe el
archivo del usuario del servidor. Cada máquina cliente necesita una copia
de ese archivo en `~/.gbpublisher/conexion.conf`, con permisos 600 y
`host` cambiado a la IP del servidor. Cada vez que el script cambia la
clave, hay que volver a copiarlo: las máquinas con el archivo viejo dejan
de conectarse.

---

## 7. Archivos y responsabilidades

| Archivo | Para quién | Qué hace |
|---|---|---|
| `gbpublisher-baseline-X.Y.Z.sql` | Quien instala | Base inicial, punto de partida de la cadena |
| `instalar-gbpublisher.sh` | Quien instala | Asistente de instalación limpia |
| `configurar-conexion.sh` | Quien instala o actualiza | Clave de `app_user` y archivo de conexión del usuario (sin sudo) |
| `actualizar-esquema-X.Y.Z.sh` | Quien instala o actualiza | Lleva la base a la versión siguiente |
| `generar-baseline.sh` | Mantenimiento | Regenera el baseline desde una base en el nivel que declara |

El baseline, el asistente y `configurar-conexion.sh` viajan juntos: el
asistente los busca en su misma carpeta. El generador es herramienta de mantenimiento y no se
distribuye a las instalaciones.

---

## 8. Verificación de una instalación

El asistente verifica automáticamente, pero estas consultas sirven para
comprobar el estado en cualquier momento. Los números corresponden a una
base recién instalada desde el baseline 2.0.0; la aplicación controla el
esquema actual al conectarse (`m_ConexionBD.ObtenerEsquemaEsperado`) y
avisa de cualquier diferencia.

```sql
-- Nivel de esquema
SELECT * FROM esquema_version ORDER BY aplicado_en;

-- Estructura completa
SELECT COUNT(*) FROM information_schema.tables
 WHERE table_schema='gbpublisher' AND table_type='BASE TABLE';   -- debe dar 68

-- Datos semilla presentes
SELECT
  (SELECT COUNT(*) FROM manual_ayudas)         AS ayudas,      -- 36 (la 2.5.0 borra la tabla)
  (SELECT COUNT(*) FROM consultas)             AS consultas,   -- 82
  (SELECT COUNT(*) FROM cmb_biblatex)          AS biblatex,    -- 120
  (SELECT COUNT(*) FROM bibtex_campo_catalogo) AS campos_bib,  -- 105
  (SELECT COUNT(*) FROM formatos_pdf)          AS formatos,    -- 45
  (SELECT COUNT(*) FROM credit_roles)          AS credit,      -- 14
  (SELECT COUNT(*) FROM credit_rol_nombre)     AS credit_nom,  -- 28
  (SELECT COUNT(*) FROM idiomas)               AS idiomas,     -- 386
  (SELECT COUNT(*) FROM pais)                  AS paises,      -- 249
  (SELECT COUNT(*) FROM licencias)             AS licencias,   -- 19
  (SELECT COUNT(*) FROM licencia_texto)        AS lic_texto,   -- 6
  (SELECT COUNT(*) FROM tipo_declaracion)      AS declar;      -- 3

-- Cuentas de acceso configuradas
SELECT user, host FROM mysql.user WHERE user='app_user';
```

Una instalación recién hecha debe tener las tablas de trabajo vacías
(`proyectos`, `libros_md`, `bibtex`, `bibtex_campo`, `usuarios`). Si alguna trae datos, el baseline no era el correcto.
