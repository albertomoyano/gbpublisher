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
gbpublisher-baseline-1.0.0.sql
```

Ese archivo contiene la estructura completa de la base y los datos propios
de la aplicación (shortcodes, ayudas del manual, consultas predefinidas,
tipos de entrada bibliográfica, formatos de página, roles CRediT). No
contiene datos editoriales de nadie: ni proyectos, ni artículos, ni
usuarios, ni credenciales.

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

---

## 2. Las tres capas de identidad

Es la confusión más frecuente en las instalaciones nuevas, así que conviene
dejarla clara de entrada. Hay tres cosas distintas que suelen mezclarse:

**El usuario de la aplicación (`app_user`).** Es una cuenta de MySQL, una
sola por instalación, con su clave propia. Es la que usa gbpublisher para
abrir la conexión. El usuario final nunca la ve ni la escribe.

**Los usuarios de gbpublisher.** Viven en la tabla `usuarios` de la base.
Se dan de alta desde el formulario de administración de la aplicación. **No
son cuentas de MySQL**: crear un usuario nuevo no requiere ninguna acción
del lado del servidor de base de datos.

**La cuenta administrativa del servidor** (`root` o equivalente). Se usa
para instalar y para aplicar cambios de esquema. La aplicación nunca la
usa, y `app_user` no puede reemplazarla: no tiene permisos para modificar
estructuras.

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

El baseline no se mantiene a mano. Lo produce un script a partir de la base
de desarrollo:

```bash
./generar-baseline.sh -u root -d gbpublisher -V 1.0.0 -o ./dist -v
```

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
quedar con `utf8mb4_0900_ai_ci`, que MariaDB no reconoce y hace fallar la
carga entera. El generador lo unifica a `utf8mb4_unicode_ci`.

**Elimina las cláusulas `DEFINER`.** Los disparadores y rutinas guardan el
usuario que los creó. Ese usuario no existe en el servidor de destino, así
que la referencia se quita para que hereden el usuario que importa.

**Declara `ROW_FORMAT=DYNAMIC` de forma explícita.** `mysqldump` omite el
formato de fila cuando coincide con el default del servidor de origen. Si
el servidor de destino tiene otro default, las tablas anchas no se pueden
crear. Al viajar explícito, la carga es independiente de la configuración
del destino.

**Relaja `innodb_strict_mode` durante la restauración.** Ver la sección
siguiente.

Además verifica lo que produjo: cuenta tablas, comprueba que ninguna tabla
de trabajo traiga datos, y con la opción `-v` carga el archivo en una base
temporal para confirmar que se restaura sin errores. Un baseline que no
pasa esas verificaciones no debería distribuirse.

---

## 4. La tabla `articulos` y el límite de fila

`articulos` tiene 220 columnas. Es una decisión deliberada: los metadatos
de un artículo académico son muchos y muy variados, y resolverlos en una
tabla ancha evita una decena de uniones en cada consulta a lo largo de toda
la producción editorial. La mayoría de esas columnas están vacías en
cualquier artículo concreto, y una columna vacía es más barata que una
unión repetida miles de veces.

Esa decisión tiene una consecuencia técnica que hay que conocer.

InnoDB limita el tamaño de fila a unos 8 KB. En el formato `DYNAMIC` los
campos de texto grandes se almacenan **fuera** de la fila, dejando solo un
puntero, así que en la práctica la tabla funciona sin problema. Pero al
**crear** la tabla, MySQL 8 aplica un chequeo estricto
(`innodb_strict_mode`, activo por omisión) que calcula el peor caso teórico
y rechaza la creación aunque en uso real la fila entre de sobra.

Por eso el baseline trae en su cabecera:

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

**Consecuencia práctica para el futuro:** al agregar columnas a `articulos`,
usar `TEXT` para texto libre y reservar `VARCHAR` para códigos cortos y
campos indexados. Cada `VARCHAR` grande nuevo acerca la tabla al límite; un
`TEXT` no.

---

## 5. Control de versión del esquema

Este es el punto que hace que un cambio futuro sea manejable en vez de un
problema de coordinación a distancia.

Toda instalación tiene una tabla `esquema_version`:

| parche | aplicado_en | descripcion |
|---|---|---|
| baseline-1.0.0 | 2026-07-23 00:12:29 | Esquema de distribución inicial |

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
una instalación nueva tendrá una sola fila (`baseline-1.1.0`), y una
actualizada tendrá dos (`baseline-1.0.0` y el script aplicado).

### La regla que se desprende

Como el historial difiere pero el esquema no, **un script de actualización
nunca debe decidir en función de qué scripts previos figuren registrados**.
Debe consultar el nivel de baseline y, sobre todo, **verificar el estado
real del esquema** antes de actuar: si la columna ya existe, no la agrega;
si la tabla ya tiene la forma esperada, no la toca.

Esto tiene un efecto valioso: los scripts se vuelven **idempotentes**. Se
pueden ejecutar más de una vez sin consecuencias, y se pueden ejecutar
sobre una base cuyo estado exacto no se conoce. Que es justamente la
situación de quien instala a mil kilómetros de distancia.

Tres propiedades que todo script de actualización debe tener:

1. **Respaldo previo verificado.** Antes de modificar nada, generar un
   volcado y comprobar que quedó completo. No alcanza con que el comando
   devuelva éxito: hay que verificar el archivo producido.
2. **Verificación posterior.** Comprobar que el resultado es el esperado
   —conteos, tipos de columna, filas preservadas— y avisar si no lo es.
3. **Salida sin efecto si ya está aplicado.** Detectar el estado y
   terminar sin tocar nada cuando no hay trabajo pendiente.

### Cuándo conviene rebasear

La cadena de actualizaciones crece. Llegado cierto punto, instalar sería
restaurar el baseline y correr una larga secuencia de scripts en orden.

Antes de llegar ahí conviene **rebasear**: regenerar el baseline con todos
los cambios ya incorporados y publicarlo como una versión mayor
(`baseline-2.0.0`). Las instalaciones nuevas parten de ahí; las existentes
siguen su cadena. Es un mantenimiento planificado, no una emergencia, y
hacerlo a tiempo evita que la instalación se vuelva un procedimiento largo.

---

## 6. Lo que no resuelve la base de datos

Dos cosas dependen del servidor y ningún script de la base puede
arreglarlas. Conviene conocerlas porque son la causa más frecuente de que
una instalación cliente/servidor no funcione.

**El servidor tiene que escuchar en la red.** MySQL y MariaDB vienen
configurados para aceptar solo conexiones locales
(`bind-address = 127.0.0.1`). Con esa configuración, ninguna otra máquina
puede conectarse, sin importar qué permisos tenga `app_user`. El síntoma es
un error de conexión rechazada (código 111): la conexión ni siquiera llega
al servidor de base de datos. Se corrige en la configuración de MySQL
(`bind-address = 0.0.0.0`) y reiniciando el servicio. El asistente de
instalación avisa cuando detecta esta situación.

**El puerto no debe quedar expuesto fuera del perímetro.** La aplicación se
conecta con una cuenta de base de datos cuyas credenciales son conocidas.
Eso significa que el control de acceso efectivo a los datos editoriales es
**el perímetro de red**: red interna de la institución, o VPN. Si el
servidor queda alcanzable desde una red más amplia, corresponde filtrar el
puerto 3306 con el cortafuegos. Por la misma razón, el asistente pide un
rango de red concreto en lugar de habilitar cualquier origen.

---

## 7. Archivos y responsabilidades

| Archivo | Para quién | Qué hace |
|---|---|---|
| `gbpublisher-baseline-X.Y.Z.sql` | Quien instala | Base completa, lista para usar |
| `instalar-gbpublisher.sh` | Quien instala | Asistente de instalación limpia |
| `generar-baseline.sh` | Mantenimiento | Regenera el baseline desde la base de desarrollo |

El baseline y el asistente viajan juntos: el asistente busca el archivo en
su misma carpeta. El generador es herramienta de mantenimiento y no se
distribuye a las instalaciones.

---

## 8. Verificación de una instalación

El asistente verifica automáticamente, pero estas consultas sirven para
comprobar el estado en cualquier momento:

```sql
-- Nivel de esquema
SELECT * FROM esquema_version ORDER BY aplicado_en;

-- Estructura completa
SELECT COUNT(*) FROM information_schema.tables
 WHERE table_schema='gbpublisher' AND table_type='BASE TABLE';   -- debe dar 30

-- Datos semilla presentes
SELECT
  (SELECT COUNT(*) FROM shortcodes)    AS shortcodes,      -- 77
  (SELECT COUNT(*) FROM manual_ayudas) AS ayudas,          -- 36
  (SELECT COUNT(*) FROM consultas)     AS consultas,       -- 82
  (SELECT COUNT(*) FROM cmb_biblatex)  AS biblatex,        -- 120
  (SELECT COUNT(*) FROM formatos_pdf)  AS formatos,        -- 45
  (SELECT COUNT(*) FROM credit_roles)  AS credit;          -- 14

-- Cuentas de acceso configuradas
SELECT user, host FROM mysql.user WHERE user='app_user';
```

Una instalación recién hecha debe tener las tablas de trabajo vacías
(`proyectos`, `articulos`, `libros_md`, `autores`, `usuarios`). Si alguna
trae datos, el baseline no era el correcto.
