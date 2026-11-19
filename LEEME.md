# Instalación de gbpublisher

## Guía paso a paso para editores científicos

---

> **Antes de empezar**
> Esta guía está escrita para personas que no tienen conocimientos técnicos de informática. Cada paso indica exactamente qué hacer y qué esperar ver en pantalla. Si algo no coincide con lo que describe la guía, no sigas adelante: contactá al responsable técnico de tu institución.

---

> **Plataforma requerida**
> gbpublisher funciona y es soportado exclusivamente en **Linux Mint con escritorio Cinnamon y servidor de pantalla X11**. No está soportado en otras distribuciones Linux ni ningún otro sistema operativo. Antes de instalar, verificá que tu sistema cumple este requisito.

---

> **Un solo instalador, próximamente**
> Hoy la instalación tiene varios pasos. Está previsto reemplazarlos por un único script que descarga e instala todo. Mientras tanto, seguí esta guía.

---

## ¿Qué trae cada versión?

Cada versión de gbpublisher (cada *release* en GitHub) trae estos archivos:

| Archivo | Para qué sirve |
|---|---|
| `gbpublisher_X.X.deb` | El instalador de la aplicación |
| `instalar-gbpublisher.sh` | Crea la base de datos en una instalación nueva |
| `gbpublisher-baseline-1.0.0.sql` | La estructura inicial de la base (no lo abrís directamente) |
| `actualizar-esquema-X.Y.Z.sh` | Las actualizaciones de la base, una por versión de esquema |

La nota de cada versión dice hasta qué actualización de la base corresponde aplicar: por ejemplo, «esquema 1.33.0».

---

## Instalación nueva

### Paso 1 — Instalar la aplicación

Hacé doble clic sobre el archivo `gbpublisher_X.X.deb`. El instalador del sistema va a pedir tu contraseña de usuario y completará la instalación automáticamente.

Una vez instalado, gbpublisher aparece en el menú de aplicaciones de tu sistema. **Todavía no lo abras**: falta la base de datos.

### Paso 2 — Crear la base de datos

Este paso crea la base de datos donde gbpublisher guarda toda la información de tus libros y revistas. **Es una operación destructiva**: si ya existía una base de gbpublisher en esta computadora (por ejemplo, de una prueba), se borra y se reemplaza por una nueva vacía.

Abrí una terminal en la carpeta donde están los archivos de la versión y escribí:

```
bash instalar-gbpublisher.sh
```

Te va a pedir tu contraseña de usuario una sola vez, al principio. Después, el asistente:

1. busca el archivo `gbpublisher-baseline-1.0.0.sql` en la misma carpeta;
2. pregunta si otras computadoras se van a conectar a esta base por la red (respondé **no** si gbpublisher se usa solo en esta computadora);
3. avisa que va a borrar la base existente y pide que escribas `SI`, en mayúsculas;
4. crea la base, el usuario de conexión de la aplicación, y comprueba el resultado.

Si todo salió bien, termina con:

```
Instalación completada.
Ya podés abrir gbpublisher.
```

### Paso 3 — Llevar la base a la versión actual

El baseline es la base tal como era en la versión 1.0.0. Las actualizaciones la llevan al día. Hay que aplicarlas **en orden**, desde la 1.1.0 hasta la que indica la nota de la versión:

```
sudo bash actualizar-esquema-1.1.0.sh
sudo bash actualizar-esquema-1.2.0.sh
...
sudo bash actualizar-esquema-1.34.0.sh
```

Cada actualización:

- dice qué va a cambiar y pide que escribas `SI` para continuar (si borra datos, muestra cuáles);
- comprueba que la anterior esté aplicada, y frena con un mensaje si no lo está;
- si cambia tablas o datos, hace un respaldo de la base en `~/gbpublisher-respaldos/` antes de empezar (la 1.34.0 solo da un permiso y no lo necesita);
- si ya estaba aplicada, lo dice y no toca nada.

Si una actualización frena, no sigas con la siguiente: pasá el mensaje al responsable técnico.

### Paso 4 — Primer acceso y creación de usuarios

**Abrir gbpublisher por primera vez.** Aparece la pantalla de aviso legal. Leé los términos y aceptá para continuar. La pantalla principal se abre sin datos cargados.

**Acceder al panel de administración.** En la esquina inferior derecha de la pantalla principal hay un ícono con una mano abierta y tres cubos. Hacé clic para abrir el panel de Administración. La primera vez, la aplicación crea la cuenta del administrador y muestra sus datos:

- **Usuario:** `admin`
- **Contraseña:** `admin123`

> **Importante:** estas credenciales son públicamente conocidas. Cambiá la contraseña del administrador inmediatamente después de este primer acceso. La cuenta del administrador vive solo en esta computadora; no es un usuario de la base de datos.

**Crear el primer usuario operativo.** Desde el panel de Administración creá al menos un usuario con el que vas a trabajar normalmente. Completá los campos requeridos y guardá.

**Conectarse.** Cerrá el panel de Administración. En la pantalla principal abrí el formulario de conexión, ingresá la IP del servidor (si es la misma computadora: `127.0.0.1`), el usuario y la contraseña que acabás de crear, y conectate.

### Paso 5 — Controlar la integridad del sistema

gbpublisher usa versiones fijas de algunas herramientas (Pandoc, Saxon-HE, epubcheck, veraPDF, packtools). Este paso las instala o las repara.

1. Abrí o creá un proyecto.
2. Elegí el menú **Acerca de → Controlar integridad del sistema**.
3. Si falta algo, aparece una ventana que pide tu contraseña: es la de tu usuario de la computadora.

La terminal de la aplicación muestra cada herramienta en verde (está bien), en ámbar (aviso) o en rojo (problema), y dice qué hizo con cada una. Si al final queda algo en rojo, pasá ese texto al responsable técnico.

Este control se puede repetir cuando quieras: no rompe nada que esté bien.

---

## Actualizar una instalación existente

Cuando sale una versión nueva:

1. Instalá el `.deb` nuevo con doble clic, como en el Paso 1.
2. Aplicá, en orden, las actualizaciones de la base que todavía no tengas, hasta la que indica la nota de la versión. Para saber cuál fue la última aplicada:
   ```
   sudo mysql gbpublisher -e "SELECT parche FROM esquema_version ORDER BY aplicado_en DESC LIMIT 1;"
   ```
   Si dice `actualizacion-1.31.0`, empezás por `actualizar-esquema-1.32.0.sh`.
3. Abrí un proyecto y controlá la integridad del sistema, como en el Paso 5.

---

## Verificación final

Para confirmar que la instalación está completa y funcional, verificá que podés:

- [x] Abrir gbpublisher sin mensajes de error
- [x] Conectarte con el usuario creado
- [x] Ver el menú principal habilitado
- [x] Controlar la integridad del sistema sin elementos en rojo

---

## Información técnica de la instalación

Esta sección es para el responsable técnico de la institución. El detalle de la base de datos está en [BBDD_LEEME.md](BBDD_LEEME.md).

| Parámetro | Valor |
|---|---|
| Base de datos | MySQL 8.0+ |
| Nombre de la BD | `gbpublisher` |
| Usuario de aplicación | `app_user` |
| Puerto | 3306 |
| Codificación | utf8mb4 / utf8mb4_unicode_ci |
| Herramientas fijadas | `/opt/pandoc`, `/opt/Saxon-HE`, `/opt/epubcheck`, `/opt/verapdf`, `/opt/packtools`, `/opt/vnu` |
| Respaldos de las actualizaciones | `~/gbpublisher-respaldos/` |
| Respaldo diario de la aplicación | `~/.gbpublisher/respaldo/`, uno por día, al abrir la aplicación |

La contraseña del usuario `app_user` está configurada en el archivo de conexión de la aplicación. No se muestra en esta guía por razones de seguridad.
